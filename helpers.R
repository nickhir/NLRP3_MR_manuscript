## helpers.R - the shared function library.
##
## Region readers, INTERVAL LD, harmonisation, instrument loading, joint F/R2,
## correlated MR and theme_Publication(). Sourced by the analysis/ steps; most
## also source config.R, but 09_proteome_mr.R does not, which is why it
## defines ld_panel and plink2_bin itself.

nlrp3_scratch <- function() {
    d <- getOption("nlrp3.scratch")
    if (is.null(d)) {
        root <- Sys.getenv(
            "NLRP3_SCRATCH",
            unset = "/rds/user/nh608/hpc-work/trashtmp"
        )
        d <- file.path(
            root,
            sprintf(
                "run_%d_%s",
                Sys.getpid(),
                format(Sys.time(), "%Y%m%d_%H%M%S")
            )
        )
        dir.create(d, recursive = TRUE, showWarnings = FALSE)
        if (!dir.exists(d)) {
            stop("cannot create scratch directory: ", d)
        }
        options(nlrp3.scratch = d)
    }
    d
}

# Drop-in replacements for tempfile() and file.path(tempdir(), ...).
scratch_file <- function(fileext = "") {
    tempfile(pattern = "file", tmpdir = nlrp3_scratch(), fileext = fileext)
}

scratch_path <- function(...) {
    d <- file.path(nlrp3_scratch(), ...)
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
    d
}

# Loud, early, and actionable: a full /tmp otherwise surfaces as "No space left
# on device" or "database or disk is full" several minutes into a step, from
# inside data.table or DBI, with nothing pointing at the real cause.
if (startsWith(tempdir(), "/tmp")) {
    warning(
        "R's session temp directory is ",
        tempdir(),
        " - on a compute node ",
        "/tmp is a small shared tmpfs and large steps will fail there.\n",
        "  Run from the project root so its .Renviron is picked up, ",
        "or start R with TMPDIR set:\n",
        "    TMPDIR=/rds/user/nh608/hpc-work/trashtmp Rscript analysis/00_instrument_selection.R",
        call. = FALSE,
        immediate. = TRUE
    )
}


## -----------------------------------------------------------------------------
## PART 1 - pipeline helpers
## -----------------------------------------------------------------------------

## ---- reading summary statistics ----------------------------------------------

# SAIGE output has no allele columns, only MarkerID = chr:pos_Allele1/Allele2,
# with BETA and AF_Allele2 referring to Allele2. A registry entry names that
# column as marker_col, and both readers below split it into the usual oa/ea.
alleles_from_marker <- function(df) {
    if (!"marker" %in% names(df)) {
        return(df)
    }
    df$oa <- sub("^.*_([^/]+)/.*$", "\\1", df$marker)
    df$ea <- sub("^.*/", "", df$marker)
    df$marker <- NULL
    df
}

# Read one chromosome window out of a summary-statistics file, given its
# registry entry from config.R. Column names are standardised on the way in -
# chrom, pos, ea, oa, beta, se, eaf, p, plus rsid, n, gene, ci_lower and
# ci_upper wherever the entry names them - so every caller downstream works in
# plain dplyr instead of df[[cfg$chr_col]]. Accepts 2, "2" or "chr2" for `chr`.
read_region <- function(cfg, chr, start, end) {
    chr <- sub("^chr", "", as.character(chr))

    # c() drops the NULL entries, so a config without eaf_col simply yields no
    # eaf column and nothing asks fread for one.
    cols <- c(
        chrom = cfg$chr_col,
        pos = cfg$pos_col,
        ea = cfg$ea_col,
        oa = cfg$oa_col,
        marker = cfg$marker_col,
        beta = cfg$effect_col,
        se = cfg$se_col,
        eaf = cfg$eaf_col,
        p = cfg$p_col,
        rsid = cfg$rsid_col,
        n = cfg$n_col,
        gene = cfg$gene_col,
        ci_lower = cfg$ci_lower_col,
        ci_upper = cfg$ci_upper_col
    )

    # fread does not stream a .gz: data.table decompresses the whole file into
    # TMPDIR first, so a 2 GB gzipped input needs several GB of scratch for the
    # duration of the call (unlinked on exit, so it does not accumulate across
    # a loop). That is why the project's .Renviron points TMPDIR at RDS rather
    # than /tmp, which is a small shared tmpfs on a compute node.
    raw <- data.table::fread(
        cfg$file,
        # One registry entry - CARDIOMETABOLIC$BMI - is space-delimited.
        sep = if (identical(cfg$sep, "whitespace")) " " else "\t",
        select = unname(cols),
        # chrom as text: "1" and "chr1" both occur, and comparing as text works
        # for either. pos as numeric so that the window comparison below is
        # arithmetic rather than lexical ("9" >= "10" is TRUE as text; 9 >= 10
        # is not). Note the limit of that pin: data.table's colClasses only
        # UPGRADES a type, so it lifts an integer or an all-NA/blank position
        # column to double, but a column whose values force character - a
        # literal "." in a position field - is left as character and fread does
        # not complain. No registry file has one; closing that hole would need
        # na.strings, which would rewrite the allele columns too.
        colClasses = list(character = cfg$chr_col, numeric = cfg$pos_col),
        data.table = FALSE,
        showProgress = FALSE
    )

    df <- raw %>%
        # all_of(), not any_of()/select(): a mistyped *_col must be an error
        # here. fread(select=) only warns about a column it cannot find.
        dplyr::select(dplyr::all_of(cols)) %>%
        dplyr::filter(
            chrom %in% c(chr, paste0("chr", chr)),
            pos >= start,
            pos <= end
        )
    if (!is.null(cfg$gene)) {
        df <- dplyr::filter(df, gene == cfg$gene)
    }
    df <- alleles_from_marker(df)

    # Back to integer once the window comparison is done. A double position is
    # pasted into the variant ID by create_SNPid_vectorized(), and R renders a
    # double in whichever of fixed or scientific notation is shorter:
    # as.character(113000000) is "1.13e+08", and chr2:113,000,000 sits inside
    # step 08's window. Assembly coordinates are integers well under 2^31.
    df$pos <- as.integer(df$pos)

    # The whole-file read is the largest object any step holds. Drop it here
    # rather than leaving it for the next iteration of a caller's loop.
    rm(raw)
    gc(verbose = FALSE, full = TRUE)
    df
}

# Read a whole genome-wide file on the same standard names, for the three
# mediation readers that select variants by something other than a window:
# read_significant() (07a, a p threshold), thin_genome() (07b, one variant per
# bin) and lookup_at() (below, an explicit variant list). Every one of them
# feeds to_common(), so the column set is exactly what to_common() reads -
# no rsid and no gene, because a genome-wide rsID column alone costs most of a
# gigabyte and nothing downstream of these three looks at it.
read_genome <- function(cfg) {
    # Before the read, not after it: the caller's previous file is garbage by
    # now, and collecting it here means it is gone before this fread allocates
    # rather than while both are resident.
    gc(verbose = FALSE, full = TRUE)

    cols <- c(
        chrom = cfg$chr_col,
        pos = cfg$pos_col,
        ea = cfg$ea_col,
        oa = cfg$oa_col,
        marker = cfg$marker_col,
        beta = cfg$effect_col,
        se = cfg$se_col,
        eaf = cfg$eaf_col,
        p = cfg$p_col,
        n = cfg$n_col,
        nlog10 = cfg$nlog10_col,
        ci_lower = cfg$ci_lower_col,
        ci_upper = cfg$ci_upper_col
    )

    raw <- data.table::fread(
        cfg$file,
        sep = if (identical(cfg$sep, "whitespace")) " " else "\t",
        select = unname(cols),
        # chrom as text and pos as numeric for the same reasons as
        # read_region(). p stays a STRING: to_common() recovers -log10(p) from
        # the raw text, so an exponent past the double-precision floor (the
        # strongest loci in a genome-wide file) survives instead of collapsing
        # to zero.
        colClasses = list(
            character = c(cfg$chr_col, cfg$p_col),
            numeric = cfg$pos_col
        ),
        data.table = FALSE,
        showProgress = FALSE
    )

    df <- raw %>%
        dplyr::select(dplyr::all_of(cols)) %>%
        # Stripped once here rather than at each of the three call sites; the
        # shell filters these replaced did the same before comparing or binning.
        dplyr::mutate(chrom = sub("^chr", "", chrom), pos = as.integer(pos)) %>%
        alleles_from_marker()

    rm(raw)
    df
}


## ---- genome build -------------------------------------------------------------

# Confirm a file is on the build it claims, by counting how many of the eight
# instruments land at GRCh38 vs GRCh37 coordinates. Cheap, and it has caught
# real mislabelling.
verify_build <- function(df, declared_build, label, exposure) {
    pos <- as.integer(df[["pos"]])
    n38 <- sum(exposure$pos_hg38 %in% pos)
    n19 <- sum(exposure$pos_hg19 %in% pos)

    message(sprintf("  build check: %d/8 at GRCh38, %d/8 at GRCh37", n38, n19))

    winner <- if (n38 > n19) {
        "GRCh38"
    } else if (n19 > n38) {
        "GRCh37"
    } else {
        NA_character_
    }
    if (is.na(winner)) {
        stop(sprintf(
            "[%s] cannot determine build: %d GRCh38 vs %d GRCh37 hits",
            label,
            n38,
            n19
        ))
    }
    if (winner != declared_build) {
        stop(sprintf(
            "[%s] declared %s but the data look like %s (%d vs %d hits)",
            label,
            declared_build,
            winner,
            n38,
            n19
        ))
    }
    invisible(winner)
}

## ---- effect sizes --------------------------------------------------------------

# Standard error of a log odds ratio recovered from its 95% CI.
se_from_ci <- function(ci_lower, ci_upper) {
    (log(ci_upper) - log(ci_lower)) / (2 * qnorm(0.975))
}

# Standard error implied by an effect size and its two-sided p-value, for
# sources reporting neither SE nor CI (the deCODE releases). Exact under the
# normal approximation that produced the p-value in the first place.
se_from_p <- function(beta, p) {
    abs(beta) / qnorm(p / 2, lower.tail = FALSE)
}


## ---- harmonisation --------------------------------------------------------------

# Put a regional dataset on the project's ASCII-sorted variant IDs
# (CHR_POS_A1_A2 with A1 < A2) and flip beta onto A1.
harmonise_region <- function(df, cfg, chr, pos_map = NULL) {
    # read_region() has already standardised the column names; cfg is still
    # needed for effect_type, se_source, neglog10_p and build.
    std <- dplyr::mutate(
        df,
        pos = as.integer(pos),
        ea = toupper(ea),
        oa = toupper(oa),
        beta = as.numeric(beta)
    )
    if (identical(cfg$effect_type, "OR")) {
        std$beta <- log(std$beta)
    }

    std$se <- switch(
        if (is.null(cfg$se_source)) "column" else cfg$se_source,
        column = as.numeric(std$se),
        ci = se_from_ci(as.numeric(std$ci_lower), as.numeric(std$ci_upper)),
        p = se_from_p(std$beta, as.numeric(std$p))
    )

    std$p <- if (is.null(cfg$p_col)) {
        NA_real_
    } else {
        raw <- as.numeric(std$p)
        if (isTRUE(cfg$neglog10_p)) 10^(-raw) else raw
    }

    std <- dplyr::filter(
        std,
        !is.na(beta),
        !is.na(se),
        se > 0,
        ea %in% c("A", "C", "G", "T"),
        oa %in% c("A", "C", "G", "T")
    )
    if (nrow(std) == 0) {
        return(NULL)
    }

    # onto GRCh38
    if (identical(cfg$build, "GRCh37")) {
        if (is.null(pos_map)) {
            stop("a GRCh37 input needs pos_map")
        }
        m <- match(std$pos, pos_map$pos_hg19)
        std <- std[!is.na(m), , drop = FALSE]
        std$pos <- pos_map$pos_hg38[m[!is.na(m)]]
    }
    if (nrow(std) == 0) {
        return(NULL)
    }

    A1 <- pmin(std$ea, std$oa)
    A2 <- pmax(std$ea, std$oa)

    tibble::tibble(
        SNPid = paste(chr, std$pos, A1, A2, sep = "_"),
        chrom = chr,
        pos = std$pos,
        A1 = A1,
        A2 = A2,
        beta = ifelse(std$ea == A1, std$beta, -std$beta),
        se = std$se,
        p = std$p
    ) %>%
        dplyr::distinct(SNPid, .keep_all = TRUE)
}


## ---- instruments ----------------------------------------------------------------

# The eight frozen instruments plus the cis-NLRP3 activity score, oriented so
# that estimates read per one-unit DECREASE in the score. Only the "cis-NLRP3
# trait" rows are read.
load_instruments <- function(path = instrument_file, negate = TRUE) {
    # Panel allele frequency, oriented onto the ASCII-first allele of the
    # variant ID, so it is directly comparable with an `A1 frequency` from
    # summary statistics.
    panel_allele_freq <- function(
        snp_ids,
        panel = ld_panel,
        plink2 = plink2_bin,
        threads = 2
    ) {
        tmp <- scratch_file()
        writeLines(to_panel_id(snp_ids), paste0(tmp, ".extract"))

        system2(
            plink2,
            c(
                "--bfile",
                panel,
                "--extract",
                paste0(tmp, ".extract"),
                "--freq",
                "--out",
                tmp,
                "--threads",
                threads
            ),
            stdout = FALSE
        )

        fr <- utils::read.table(
            paste0(tmp, ".afreq"),
            header = TRUE,
            comment.char = "",
            check.names = FALSE
        )
        names(fr)[1] <- "CHROM"

        SNP <- from_panel_id(fr$ID)
        A1 <- vapply(strsplit(SNP, "_", fixed = TRUE), `[`, character(1), 3)

        tibble::tibble(
            SNP = SNP,
            # --freq reports the ALT frequency; ALT is A1 only when the panel's
            # REF happens to be A2, which nothing guarantees.
            freq_panel = ifelse(A1 == fr$ALT, fr$ALT_FREQS, 1 - fr$ALT_FREQS)
        )
    }

    # Guard against the LD panel and the summary statistics meaning different
    # variants by the same CHR_POS_A1_A2 name. Nothing downstream notices when
    # they disagree.
    check_panel_freq <- function(
        snp_ids,
        eaf,
        label = "instruments",
        panel = ld_panel,
        plink2 = plink2_bin
    ) {
        fr <- panel_allele_freq(snp_ids, panel = panel, plink2 = plink2)
        cmp <- tibble::tibble(SNP = snp_ids, freq_data = as.numeric(eaf)) %>%
            dplyr::inner_join(fr, by = "SNP") %>%
            dplyr::mutate(delta = abs(freq_panel - freq_data))

        if (nrow(cmp) == 0) {
            warning(sprintf(
                "[%s] no variant found in the panel; frequency check skipped",
                label
            ))
            return(invisible(cmp))
        }

        bad <- cmp[!is.na(cmp$delta) & cmp$delta > 0.05, , drop = FALSE]
        if (nrow(bad) > 0) {
            stop(sprintf(
                "[%s] %d variant(s) disagree with the LD panel on A1 frequency by more than %.2f - the panel and the summary statistics are naming different variants:\n%s",
                label,
                nrow(bad),
                0.05,
                paste(
                    sprintf(
                        "  %s  panel %.4f  data %.4f  (d = %.4f)",
                        bad$SNP,
                        bad$freq_panel,
                        bad$freq_data,
                        bad$delta
                    ),
                    collapse = "\n"
                )
            ))
        }
        invisible(cmp)
    }

    ex <- data.table::fread(path, data.table = FALSE) %>%
        dplyr::transmute(
            SNP = SNP,
            chr = as.integer(chr),
            pos_hg38 = as.integer(pos_hg38),
            A1 = toupper(A1),
            A2 = toupper(A2),
            eaf_exposure = as.numeric(eaf),
            beta_exposure = as.numeric(beta_exposure),
            se_exposure = as.numeric(se_exposure)
        ) %>%
        dplyr::arrange(pos_hg38)

    # GRCh37 positions for the same eight variants, for the outcome files still
    # released on that build. Produced with UCSC liftOver and cross-checked
    # against the Parkinson's, T2D and COVID-19 files, all natively GRCh37.
    hg19 <- tibble::tribble(
        ~SNP              , ~pos_hg19 ,
        "1_247406019_C_T" , 247569321 ,
        "1_247432548_C_T" , 247595850 ,
        "1_247433558_A_C" , 247596860 ,
        "1_247438293_C_T" , 247601595 ,
        "1_247442302_A_G" , 247605604 ,
        "1_247452478_A_G" , 247615780 ,
        "1_247459572_C_T" , 247622874 ,
        "1_247460342_C_G" , 247623644
    )
    ex <- dplyr::left_join(ex, hg19, by = "SNP")

    # Every instrument goes on to be paired with an INTERVAL LD matrix, so the
    # panel and the workbook must agree on which variant each ID names. See
    # check_panel_freq() for what goes wrong when they do not.
    check_panel_freq(
        ex$SNP,
        ex$eaf_exposure,
        label = "cis-NLRP3 instruments"
    )

    if (negate) {
        ex$beta_exposure <- -ex$beta_exposure
    }
    ex
}


## ---- linkage disequilibrium -------------------------------------------------------

# Signed, A1-oriented LD from the INTERVAL panel. The panel names variants
# chr1:POS:A1:A2 while this project uses 1_POS_A1_A2, so IDs are translated on
# the way in and back on the way out.
to_panel_id <- function(x) paste0("chr", gsub("_", ":", x))
from_panel_id <- function(x) gsub(":", "_", sub("^chr", "", x))

interval_ld_matrix <- function(
    snp_ids,
    panel = ld_panel,
    plink2 = plink2_bin,
    threads = 2
) {
    panel_ids <- to_panel_id(snp_ids)
    tmp <- scratch_file()
    writeLines(panel_ids, paste0(tmp, ".extract"))

    ref_tbl <- data.frame(
        id = panel_ids,
        a1 = sub("^chr[^:]+:[0-9]+:([^:]+):.*$", "\\1", panel_ids)
    )
    write.table(
        ref_tbl,
        paste0(tmp, ".ref"),
        sep = "\t",
        quote = FALSE,
        row.names = FALSE,
        col.names = FALSE
    )

    system2(
        plink2,
        c(
            "--bfile",
            panel,
            "--extract",
            paste0(tmp, ".extract"),
            "--ref-allele",
            "force",
            paste0(tmp, ".ref"),
            "2",
            "1",
            "--make-pgen",
            "--out",
            tmp,
            "--threads",
            threads
        ),
        stdout = FALSE
    )

    system2(
        plink2,
        c(
            "--pfile",
            tmp,
            "--r-unphased",
            "square",
            "ref-based",
            "--out",
            tmp,
            "--threads",
            threads
        ),
        stdout = FALSE
    )

    ld <- as.matrix(read.table(paste0(tmp, ".unphased.vcor1"), header = FALSE))
    vars <- from_panel_id(read.table(
        paste0(tmp, ".unphased.vcor1.vars"),
        header = FALSE
    )[, 1])
    rownames(ld) <- colnames(ld) <- vars

    missing <- setdiff(snp_ids, vars)
    if (length(missing) > 0) {
        stop(sprintf(
            "not found in the INTERVAL panel: %s",
            paste(missing, collapse = ", ")
        ))
    }
    ld[snp_ids, snp_ids]
}


## ---- instrument gene specificity -------------------------------------------------

# An instrument must act on its target gene, not on a neighbour. On INTERVAL
# whole-blood eQTL summary statistics (one release per chromosome, every gene
# tested in cis), a variant fails if it is associated with expression of another
# gene at P < p_threshold AND that association persists at P < p_threshold after
# GCTA-COJO conditioning on that gene's lead eQTL. The conditioning separates a
# variant's own effect on a neighbour from the echo of a very strong eQTL for
# that neighbour reaching it through weak LD.
#
# A variant that is itself the other gene's lead, or too collinear with it for
# COJO to separate the two, fails: there is nothing else to attribute the
# association to.
#
# Returns list(excluded = the failing SNP ids, detail = one row per variant and
# off-target gene at P < p_threshold). The releases are whole chromosomes of
# 1-1.4 GB, so they are scanned with awk rather than read by read_region().
eqtl_specificity <- function(
    snps,
    eqtl_file,
    target_gene,
    chr,
    n,
    p_threshold = EQTL_SPECIFICITY_P,
    panel = ld_panel,
    plink2 = plink2_bin,
    gcta = gcta_bin
) {
    header <- strsplit(readLines(eqtl_file, n = 1), "\t", fixed = TRUE)[[1]]

    # every row whose `column` is one of `keys`
    scan_rows <- function(keys, column) {
        key_file <- scratch_file(fileext = ".keys")
        writeLines(as.character(unique(keys)), key_file)
        data.table::fread(
            cmd = sprintf(
                "awk -F'\\t' 'NR==FNR {k[$1]; next} FNR==1 || ($%d in k)' %s %s",
                match(column, header),
                shQuote(key_file),
                shQuote(eqtl_file)
            ),
            sep = "\t",
            data.table = FALSE,
            select = c("phenotype_id", "pos_b38", "effect_allele",
                       "other_allele", "slope", "slope_se", "pval_nominal")
        )
    }

    # onto project IDs one gene at a time: harmonise_region() keeps one row per
    # variant, and a variant is tested against many genes
    harmonise_genes <- function(rows) {
        dplyr::bind_rows(lapply(split(rows, rows$phenotype_id), function(g) {
            h <- harmonise_region(
                data.frame(pos = g$pos_b38, ea = g$effect_allele,
                           oa = g$other_allele, beta = g$slope,
                           se = g$slope_se, p = g$pval_nominal),
                list(p_col = "pval_nominal"),
                chr
            )
            if (!is.null(h)) h$gene <- g$phenotype_id[1]
            h
        }))
    }

    pos <- as.integer(vapply(strsplit(snps, "_", fixed = TRUE), `[`, character(1), 2))
    hits <- harmonise_genes(scan_rows(pos, "pos_b38")) %>%
        dplyr::filter(SNPid %in% snps,
                      sub("\\..*$", "", gene) != target_gene,
                      p < p_threshold)

    detail <- tibble::tibble(SNP = character(), gene = character(),
                             p = numeric(), lead = character(),
                             p_lead = numeric(), p_conditional = numeric(),
                             excluded = logical())
    if (nrow(hits) == 0) {
        return(list(excluded = character(), detail = detail))
    }

    gene_rows <- harmonise_genes(scan_rows(unique(hits$gene), "phenotype_id"))
    work <- scratch_path("eqtl_specificity")
    for (g in unique(hits$gene)) {
        rows <- gene_rows[gene_rows$gene == g, ]
        tag <- file.path(work, g)

        # PLINK1 fileset over the gene's cis window for COJO; its frequencies
        # double as the check that a variant is in the panel at all
        system2(plink2, c("--bfile", panel, "--chr", chr,
                          "--from-bp", min(rows$pos), "--to-bp", max(rows$pos),
                          "--make-bed", "--out", tag, "--threads", 4),
                stdout = FALSE, stderr = FALSE)
        system2(plink2, c("--bfile", tag, "--freq", "--out", tag, "--threads", 4),
                stdout = FALSE, stderr = FALSE)
        afreq <- data.table::fread(paste0(tag, ".afreq"), data.table = FALSE)

        # A1 is the ASCII-first allele, REF in this alpha-sorted panel
        a1 <- sub("^chr[^:]+:[0-9]+:([^:]+):.*$", "\\1", afreq$ID)
        freq <- data.frame(
            SNPid = from_panel_id(afreq$ID),
            freq = ifelse(a1 != afreq$ALT, 1 - afreq$ALT_FREQS, afreq$ALT_FREQS)
        )
        ma <- dplyr::inner_join(rows, freq, by = "SNPid") %>%
            dplyr::filter(freq > 0, freq < 1) %>%
            # from the z-score: the release underflows to 0 for the strongest eQTLs
            dplyr::mutate(p = pmax(2 * pnorm(-abs(beta / se)), 1e-300))

        snps_g <- hits$SNPid[hits$gene == g]
        if (nrow(ma) == 0) {
            lead <- NA_character_
            cma <- data.frame(SNP = character(), pC = numeric())
        } else {
            lead <- ma$SNPid[which.max(abs(ma$beta / ma$se))]
            write.table(
                dplyr::transmute(ma, SNP = to_panel_id(SNPid), A1, A2, freq,
                                 b = beta, se, p, N = n),
                paste0(tag, ".ma"), sep = "\t", quote = FALSE, row.names = FALSE
            )
            writeLines(to_panel_id(lead), paste0(tag, ".cond"))
            system2(gcta, c("--bfile", tag, "--cojo-file", paste0(tag, ".ma"),
                            "--cojo-cond", paste0(tag, ".cond"),
                            "--out", tag, "--thread-num", 4),
                    stdout = FALSE, stderr = FALSE)
            cma_file <- paste0(tag, ".cma.cojo")
            cma <- if (file.exists(cma_file)) {
                data.table::fread(cma_file, data.table = FALSE)
            } else {
                data.frame(SNP = character(), pC = numeric())
            }
        }

        for (s in snps_g) {
            p_c <- if (identical(s, lead)) {
                NA_real_
            } else {
                cma$pC[match(to_panel_id(s), cma$SNP)]
            }
            detail <- dplyr::bind_rows(detail, tibble::tibble(
                SNP = s,
                gene = g,
                p = hits$p[hits$SNPid == s & hits$gene == g],
                lead = lead,
                p_lead = if (is.na(lead)) NA_real_ else ma$p[ma$SNPid == lead],
                p_conditional = p_c,
                excluded = is.na(p_c) || p_c < p_threshold
            ))
        }
    }
    list(excluded = unique(detail$SNP[detail$excluded]), detail = detail)
}


## ---- regional plots -------------------------------------------------------------

# Recombination for a locuszoomr gg_scatter() drawn with recomb_col = NA: a thin
# light-grey step line under the points, on a secondary axis in cM/Mb (the unit
# of the UCSC map link_recomb() fetches; locuszoomr's own axis says "%"). As in
# locuszoomr, 100 cM/Mb reaches the top of the data. Replaces the y scale, so
# the -log10 P axis name and headroom are set here too.
add_recomb_line <- function(p, loc, scale_max = 100,
                            ylab = expression(-log[10](P - value))) {
    rec <- loc$recomb
    f <- max(loc$data[[loc$yvar]], na.rm = TRUE) / scale_max
    step <- data.frame(x = c(rbind(rec$start, rec$end)) / 1e6,
                       y = rep(rec$value, each = 2) * f)
    p$layers <- c(list(ggplot2::geom_line(
        data = step, ggplot2::aes(x = x, y = y), inherit.aes = FALSE,
        colour = "grey65", linewidth = 0.25)), p$layers)
    p +
        ggplot2::scale_y_continuous(
            name = ylab, limits = c(0, NA),
            expand = ggplot2::expansion(mult = c(0, 0.18)),
            sec.axis = ggplot2::sec_axis(~ . / f, name = "Recombination rate (cM/Mb)")
        ) +
        ggplot2::theme(
            axis.title.y.right = ggplot2::element_text(colour = "grey45"),
            axis.text.y.right = ggplot2::element_text(colour = "grey45")
        )
}


## ---- Mendelian randomization ----------------------------------------------------

# Correlated IVW plus weighted median for one harmonised outcome table.
# ld_full must be the signed LD matrix over all instruments; it is subset to
# whichever ones the outcome actually carries.
run_mr <- function(dat, ld_full) {
    label <- dat$outcome[1]
    usable <- dat %>%
        dplyr::filter(!is.na(beta_outcome), !is.na(se_outcome), se_outcome > 0)

    if (nrow(usable) < 3) {
        return(NULL)
    }

    mr_in <- MendelianRandomization::mr_input(
        bx = usable$beta_exposure,
        bxse = usable$se_exposure,
        by = usable$beta_outcome,
        byse = usable$se_outcome,
        exposure = "cis-NLRP3 activity (lower)",
        outcome = label,
        snps = usable$SNP,
        correlation = ld_full[usable$SNP, usable$SNP]
    )

    ivw <- MendelianRandomization::mr_ivw(mr_in)
    med <- MendelianRandomization::mr_median(mr_in, weighting = "weighted")

    dplyr::bind_rows(
        tibble::tibble(
            method = "IVW (LD-corrected)",
            estimate = ivw$Estimate,
            se = ivw$StdError,
            ci_lower = ivw$CILower,
            ci_upper = ivw$CIUpper,
            p = ivw$Pvalue
        ),
        tibble::tibble(
            method = "Weighted median",
            estimate = med$Estimate,
            se = med$StdError,
            ci_lower = med$CILower,
            ci_upper = med$CIUpper,
            p = med$Pvalue
        )
    ) %>%
        dplyr::mutate(outcome = label, nsnp = nrow(usable), .before = 1)
}


## ---- genome-wide summary statistics ------------------------------------------------
## Shared by the mediation steps (07a, 07a2, 07b, 07c).

# Put any registry file on the shared schema: ASCII-sorted GRCh38 variant ID with
# beta, eaf and se oriented onto A1. `df` comes from read_genome(), so it is
# already on the standard names; `cfg` is still needed for effect_type,
# se_source, neglog10_p and for the presence tests - a registry entry without
# eaf_col yields no eaf column at all.
to_common <- function(df, cfg) {
    chr <- as.integer(sub("^chr", "", as.character(df[["chrom"]])))
    pos <- as.integer(df[["pos"]])
    ea <- toupper(as.character(df[["ea"]]))
    oa <- toupper(as.character(df[["oa"]]))
    eff <- as.numeric(df[["beta"]])
    if (identical(cfg$effect_type, "OR")) {
        eff <- log(eff)
    }

    se <- switch(
        if (is.null(cfg$se_source)) "column" else cfg$se_source,
        column = as.numeric(df[["se"]]),
        ci = se_from_ci(
            as.numeric(df[["ci_lower"]]),
            as.numeric(df[["ci_upper"]])
        ),
        p = se_from_p(eff, as.numeric(df[["p"]]))
    )

    p <- if (is.null(cfg$p_col)) {
        NA_real_
    } else {
        raw <- as.numeric(df[["p"]])
        if (isTRUE(cfg$neglog10_p)) 10^(-raw) else raw
    }

    # -log10(p) recovered from the RAW STRING, so exponents past the double-
    # precision floor survive.
    nlog10_from_p <- function(x) {
        x <- trimws(as.character(x))
        out <- -log10(as.numeric(x))
        m <- regmatches(x, regexec("^([0-9.]+)[eE]([+-]?[0-9]+)$", x))
        hit <- lengths(m) == 3
        if (any(hit)) {
            out[hit] <- -log10(as.numeric(vapply(m[hit], `[`, "", 2))) -
                as.numeric(vapply(m[hit], `[`, "", 3))
        }
        out
    }

    # Exact -log10(p), immune to the double-precision floor that makes `p` itself
    # zero at the strongest loci. Prefer a dedicated column where the release
    # ships one (cfg$nlog10_col); otherwise parse the p string.
    nlog10 <- if (is.null(cfg$p_col)) {
        NA_real_
    } else if (isTRUE(cfg$neglog10_p)) {
        as.numeric(df[["p"]])
    } else {
        nlog10_from_p(df[["p"]])
    }
    if (!is.null(cfg$nlog10_col) && "nlog10" %in% names(df)) {
        alt <- as.numeric(df[["nlog10"]])
        nlog10 <- ifelse(
            is.finite(alt) & (!is.finite(nlog10) | alt > nlog10),
            alt,
            nlog10
        )
    }

    A1 <- pmin(ea, oa)
    A2 <- pmax(ea, oa)

    tibble::tibble(
        SNPid = paste(chr, pos, A1, A2, sep = "_"),
        chr = chr,
        pos = pos,
        A1 = A1,
        A2 = A2,
        beta = ifelse(ea == A1, eff, -eff),
        se = se,
        p = p,
        nlog10 = nlog10,
        eaf = if (is.null(cfg$eaf_col)) {
            NA_real_
        } else {
            f <- as.numeric(df[["eaf"]])
            ifelse(ea == A1, f, 1 - f)
        },
        n = if (is.null(cfg$n_col)) NA_real_ else as.numeric(df[["n"]])
    ) %>%
        dplyr::filter(
            !is.na(beta),
            !is.na(se),
            se > 0,
            A1 %in% c("A", "C", "G", "T"),
            A2 %in% c("A", "C", "G", "T")
        ) %>%
        dplyr::distinct(SNPid, .keep_all = TRUE)
}

# Pull a fixed set of variants out of a genome-wide file. `want` names them:
# one row per wanted variant, with SNPid, chrom and pos. The join is on
# position alone - a file spells its alleles its own way, and to_common()
# settles the orientation afterwards - so `want` is made distinct first,
# otherwise two instruments at one multi-allelic position would duplicate every
# row the file has there. SNPid then keeps only the alleles actually wanted.
lookup_at <- function(cfg, want) {
    keep <- dplyr::distinct(
        want,
        chrom = as.character(chrom),
        pos = as.integer(pos)
    )

    genome <- read_genome(cfg)
    df <- dplyr::inner_join(genome, keep, by = c("chrom", "pos"))
    # The join keeps a handful of rows out of tens of millions; release the
    # whole-genome table here rather than at the end of the caller's iteration.
    rm(genome)
    gc(verbose = FALSE, full = TRUE)
    if (nrow(df) == 0) {
        stop(sprintf("[%s] no rows matched", cfg$label))
    }

    to_common(df, cfg) %>% dplyr::filter(SNPid %in% want$SNPid)
}

## -----------------------------------------------------------------------------
## PART 2 - general-purpose genetics helpers
## -----------------------------------------------------------------------------

get_high_ld_snps <- function(leads, reference, r2, kb) {
    out_file <- scratch_file()

    # Create a temporary file to write the SNP(s) to
    snps_file <- scratch_file(fileext = ".snps")
    writeLines(leads, snps_file)

    cmd <- paste(
        plink2_bin,
        "--pfile",
        reference,
        "--r2-unphased",
        "--ld-snp-list",
        snps_file,
        "--ld-window-r2",
        r2,
        "--ld-window-kb",
        kb,
        "--threads",
        4, # Use multiple threads for speed
        "--out",
        out_file
    )

    system(cmd, ignore.stdout = TRUE)

    return(data.table::fread(paste0(out_file, ".vcor"), data.table = FALSE))
}


## This function "aligns" alleles so that they are ASCII sorted.
## If it detects a SNPid which is not ASCII sorted, it will correct it and change the sign of the beta

# A1 WILL BE THE EFFECT ALLELE WHICH WILL CORRESPOND TO ALLELE WHICH IS ALPHABETICALLY FIRST
align_ASCII_sort <- function(
    data,
    effect_allele,
    other_allele,
    beta = "beta"
) {
    A1 <- str_split_fixed(data[["SNPid"]], "_", 4)[, 3]
    data[[beta]] <- ifelse(
        A1 == data[[effect_allele]],
        data[[beta]],
        data[[beta]] * -1
    )

    data$flipped <- ifelse(A1 == data[[effect_allele]], FALSE, TRUE)

    # also switch the alleles
    new_effect_allele <- ifelse(
        A1 == data[[effect_allele]],
        data[[effect_allele]],
        data[[other_allele]]
    )
    new_other_allele <- ifelse(
        A1 == data[[effect_allele]],
        data[[other_allele]],
        data[[effect_allele]]
    )
    data[[effect_allele]] <- new_effect_allele
    data[[other_allele]] <- new_other_allele

    return(data)
}


# if the reference is has sorted alleles we have to do something different
add_LD <- function(
    locus,
    SNPid_col = "SNPid",
    index_snp = NA,
    ...
) {
    # uses plink to quickly calculate LD from a reference panel.
    # its important that the two alleles are ASCII sorted (i.e. --set-all-variant-ids @_#_\$1_\$2)
    local_ld_calculation <- function(
        index_variant,
        all_variants,
        reference,
        ...
    ) {
        out_file <- scratch_file()

        # extract all variants in that locus -> speeds up computation
        tmp_variants_file <- scratch_file()
        data.table::fwrite(
            data.frame(all_variants),
            file = tmp_variants_file,
            row.names = FALSE,
            col.names = FALSE
        )

        # get the chromosome, of the index snp Accepts both naming conventions in
        # use here: the project's 1_POS_A1_A2 and the INTERVAL panel's
        # chr1:POS:A1:A2.
        chr_ <- sub(
            "^chr",
            "",
            str_split_fixed(gsub(":", "_", index_variant), "_", 4)[, 1]
        )

        # run plink to only extract the ones that we need
        tmp_plink <- scratch_file()
        # implement dynamic switch between plink1 and plink2 because reasonss
        # check if plink2 files exist
        if (
            length(list.files(
                dirname(reference),
                pattern = paste0(basename(reference), ".pgen")
            )) ==
                1
        ) {
            cmd <- stringr::str_interp(
                "${plink2_bin} --chr ${chr_} --extract ${tmp_variants_file} --pfile ${reference} --make-pgen --out ${tmp_plink}"
            )
        } else {
            cmd <- stringr::str_interp(
                "${plink2_bin} --chr ${chr_} --extract ${tmp_variants_file} --bfile ${reference} --make-pgen --out ${tmp_plink}"
            )
        }
        system(cmd, ignore.stdout = TRUE)

        # run plink
        system(
            paste(
                plink2_bin,
                "--pfile",
                tmp_plink,
                "--r2-unphased --ld-snp",
                index_variant,
                "--ld-window-r2 0 --ld-window-kb 99999 --ld-window 99999 --out",
                out_file
            ),
            ignore.stdout = TRUE
        )
        if (file.exists(paste0(out_file, ".vcor"))) {
            out <- data.table::fread(input = paste0(out_file, ".vcor")) %>%
                as.data.frame()
            system(str_interp("rm ${tmp_plink}*"))
            return(out)
        } else {
            system(str_interp("rm ${tmp_plink}*"))
            stop(
                "Make sure the index SNP exists in the reference panel. Otherwise select a different one using index_snp=''"
            )
        }
    }

    dataset <- locus[["data"]]

    # calculate LD
    output <- local_ld_calculation(
        index_variant = index_snp,
        all_variants = dataset[[SNPid_col]],
        ...
    )
    new_df <- dataset %>%
        dplyr::left_join(
            .,
            output %>% dplyr::select(ID_B, ld = UNPHASED_R2),
            by = setNames(c("ID_B"), c(SNPid_col))
        )

    locus[["data"]] <- new_df
    locus[["index_snp"]] <- index_snp
    return(locus)
}


create_SNPid_vectorized <- function(
    dataset,
    chr,
    pos,
    other_allele,
    effect_allele
) {
    # Extract columns as vectors
    chr_vec <- dataset[[chr]]
    pos_vec <- dataset[[pos]]
    other_vec <- dataset[[other_allele]]
    effect_vec <- dataset[[effect_allele]]

    # Compare alleles without sorting (much faster)
    first_allele <- ifelse(other_vec < effect_vec, other_vec, effect_vec)
    second_allele <- ifelse(other_vec < effect_vec, effect_vec, other_vec)

    # Create allele part with underscore separator
    allele_part <- paste0(first_allele, "_", second_allele)

    # Combine everything in one vectorized operation
    SNPid <- paste(chr_vec, pos_vec, allele_part, sep = "_")

    return(SNPid)
}


ld_clump_local <- function(
    variants,
    bfile,
    r2,
    kb,
    threads = NULL,
    memory = NULL
) {
    # Make textfile
    shell <- ifelse(Sys.info()["sysname"] == "Windows", "cmd", "sh")
    fn <- scratch_file()
    write.table(
        data.frame(SNP = variants[["SNP"]], P = variants[["p"]]),
        file = fn,
        row.names = FALSE,
        col.names = TRUE,
        quote = FALSE
    )
    # The original hardcoded --pfile, which silently fails on a PLINK1
    # bed/bim/fam panel such as 1000G EUR. Pick the flag from what is on disk.
    panel_flag <- if (file.exists(paste0(bfile, ".pgen"))) {
        "--pfile"
    } else {
        "--bfile"
    }

    fun2 <- paste0(
        shQuote(plink2_bin, type = shell),
        " ",
        panel_flag,
        " ",
        shQuote(bfile, type = shell),
        " --clump ",
        shQuote(fn, type = shell),
        " --clump-p1 ",
        5e-8,
        " --clump-r2 ",
        r2,
        " --clump-kb ",
        kb,
        " --out ",
        shQuote(fn, type = shell)
    )
    if (!is.null(threads)) {
        fun2 <- paste(fun2, "--threads", threads)
    }
    if (!is.null(memory)) {
        fun2 <- paste(fun2, "--memory", memory)
    }
    null_device <- ifelse(
        Sys.info()["sysname"] == "Windows",
        "NUL",
        "/dev/null"
    )
    fun2 <- paste(fun2, ">", null_device, "2>&1")

    system(fun2)

    # Check if PLINK output file exists
    clumps_file <- paste(fn, ".clumps", sep = "")

    res <- data.table::fread(clumps_file, header = TRUE)
    return(res)
}

# Re-clump the pooled, available instruments separately for each existing
# waterfall model. Keeping the full design lets a smaller model retain SNPs
# displaced by another mediator only in the larger model.
clump_mediator_sets <- function(instruments, snp_ids, panel = ld_panel) {
    order <- c("SBP", "ApoB", "T2D")
    sets <- lapply(seq_along(order), function(i) {
        meds <- order[seq_len(i)]
        ins <- instruments[
            instruments$mediator %in% meds & instruments$SNPid %in% snp_ids,
        ]
        priority <- tapply(ins$nlog10, ins$SNPid, max)
        # As in 07a's within-trait clumps, ranks preserve tiny-P ordering
        # without numerical underflow; strongest association across lists wins.
        p <- rank(-priority, ties.method = "first") /
            (length(priority) + 1) *
            MED_CLUMP_P
        clumped <- ld_clump_local(
            variants = data.frame(SNP = to_panel_id(names(priority)), p = p),
            bfile = panel,
            r2 = MED_CLUMP_R2,
            kb = MED_CLUMP_KB,
            threads = 1,
            memory = 2048
        )
        keep <- from_panel_id(clumped$ID)
        stopifnot(length(keep) > length(meds), all(keep %in% snp_ids))
        message(sprintf(
            "%s pooled clump: %d -> %d instruments",
            paste(meds, collapse = "+"),
            length(priority),
            length(keep)
        ))
        keep
    })
    names(sets) <- vapply(
        seq_along(order),
        function(i) {
            paste(order[seq_len(i)], collapse = "+")
        },
        character(1)
    )
    sets
}

## =============================================================================
## PART 3 - plotting theme. Only theme_Publication() is used (analysis/12
## draws one forest plot with it).
## =============================================================================

theme_Publication <- function(base_size = 14, base_family = "sans") {
    library(grid)
    library(ggthemes)
    (theme_foundation(base_size = base_size, base_family = base_family) +
        theme(
            plot.title = element_text(
                face = "bold",
                size = rel(1.2),
                hjust = 0.5
            ),
            text = element_text(family = base_family),
            panel.background = element_rect(fill = "white", colour = NA),
            plot.background = element_rect(fill = "white", colour = NA),
            panel.border = element_rect(colour = NA),
            axis.title = element_text(face = "bold", size = rel(1)),
            axis.title.y = element_text(angle = 90, vjust = 2),
            axis.title.x = element_text(vjust = -0.2),
            axis.text = element_text(),
            axis.line = element_line(colour = "black"),
            axis.ticks = element_line(),
            panel.grid.major = element_line(colour = "#f0f0f0"),
            panel.grid.minor = element_blank(),
            legend.key = element_rect(colour = NA),
            legend.position = "bottom",
            legend.direction = "horizontal",
            legend.key.size = unit(0.3, "cm"),
            legend.spacing = unit(0, "cm"),
            legend.title = element_text(face = "bold", size = 13),
            legend.text = element_text(size = 12),
            plot.margin = unit(c(3, 3, 3, 3), "mm"),
            strip.background = element_rect(
                colour = "#f0f0f0",
                fill = "#f0f0f0"
            ),
            strip.text = element_text(face = "bold")
        ))
}
