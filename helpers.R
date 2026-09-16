## helpers.R - the shared function library.
##
## Region readers, INTERVAL LD, harmonisation, instrument loading, joint F/R2,
## correlated MR and theme_Publication(). Sourced with config.R by analysis/.

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
scratch_file <- function(pattern = "file", fileext = "") {
    tempfile(pattern = pattern, tmpdir = nlrp3_scratch(), fileext = fileext)
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

# Stream a file regardless of compression. Used to pipe into awk so that the
# region filter happens before anything reaches R - the neutrophil file is 2 GB
# gzipped and reading it whole is pointless.
reader_cmd <- function(path) {
    # .bgzip / .bgz are the Zoodsma metabolite releases: bgzip output, which is
    # gzip-compatible, so zcat reads them. Without this they fall through to
    # cat and R sees binary ("embedded nul", "invalid in this locale").
    if (grepl("\\.(gz|bgz|bgzip)$", path)) {
        return(sprintf("zcat %s", shQuote(path)))
    }
    if (grepl("\\.zip$", path)) {
        return(sprintf("unzip -p %s", shQuote(path)))
    }
    sprintf("cat %s", shQuote(path))
}

header_of <- function(path, sep = c("tab", "whitespace")) {
    sep <- match.arg(sep)
    con <- pipe(paste(reader_cmd(path), "| head -n 1"), open = "r")
    on.exit(close(con))
    line <- readLines(con, n = 1)
    if (sep == "tab") {
        strsplit(line, "\t", fixed = TRUE)[[1]]
    } else {
        strsplit(trimws(line), "[ \t]+")[[1]]
    }
}

col_index <- function(header, name, path) {
    idx <- match(name, header)
    if (is.na(idx)) {
        stop(sprintf(
            "column '%s' not found in %s\navailable: %s",
            name,
            basename(path),
            paste(header, collapse = ", ")
        ))
    }
    idx
}

# Read one chromosome-1 window out of a summary-statistics file.
read_region <- function(
    path,
    chr_col,
    pos_col,
    chr,
    start,
    end,
    sep = c("tab", "whitespace"),
    extra_filter = NULL
) {
    sep <- match.arg(sep)
    # `chr` is required, not defaulted to 1. The silent chromosome assumption
    # this replaces is what made the function unusable at the chr2 IL1RN locus
    # and forced analysis/08 to carry a private copy. Accepts 2L, "2" or "chr2".
    stopifnot(length(chr) == 1L, !is.na(chr))
    chr <- sub("^chr", "", as.character(chr))

    header <- header_of(path, sep)
    ci <- col_index(header, chr_col, path)
    pi <- col_index(header, pos_col, path)

    region <- sprintf(
        '(($%d=="%s" || $%d=="chr%s") && $%d>=%d && $%d<=%d)',
        ci,
        chr,
        ci,
        chr,
        pi,
        start,
        pi,
        end
    )
    if (!is.null(extra_filter)) {
        region <- paste(extra_filter, "&&", region)
    }

    awk <- if (sep == "tab") {
        sprintf("awk -F'\\t' 'NR==1 || %s'", region)
    } else {
        sprintf("awk 'BEGIN{OFS=\"\\t\"} NR==1 || %s {$1=$1; print}'", region)
    }

    df <- data.table::fread(
        cmd = paste(reader_cmd(path), "|", awk),
        data.table = FALSE,
        showProgress = FALSE
    )

    # fread can mangle a leading '#' in the first column name; restore the true
    # header so lookups by name always work.
    if (ncol(df) == length(header)) {
        names(df) <- header
    }

    # Some releases - the INTERVAL eQTL files among them - carry unnamed
    # trailing columns. Name them so downstream lookups never hit a "" name.
    nm <- names(df)
    blank <- is.na(nm) | nm == ""
    if (any(blank)) {
        nm[blank] <- paste0("unnamed", seq_len(sum(blank)))
        names(df) <- nm
    }
    df
}


## ---- genome build -------------------------------------------------------------

# Confirm a file is on the build it claims, by counting how many of the eight
# instruments land at GRCh38 vs GRCh37 coordinates. Cheap, and it has caught
# real mislabelling.
verify_build <- function(df, pos_col, declared_build, label, exposure) {
    pos <- as.integer(df[[pos_col]])
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
harmonise_region <- function(df, cfg, chr, pos_map = NULL, drop_indels = TRUE) {
    pos_col <- cfg$pos_col

    std <- df
    std$.pos <- as.integer(std[[pos_col]])
    std$.ea <- toupper(std[[cfg$ea_col]])
    std$.oa <- toupper(std[[cfg$oa_col]])
    std$.eff <- as.numeric(std[[cfg$effect_col]])

    if (identical(cfg$effect_type, "OR")) {
        std$.eff <- log(std$.eff)
    }

    std$.se <- switch(
        if (is.null(cfg$se_source)) "column" else cfg$se_source,
        column = as.numeric(std[[cfg$se_col]]),
        ci = se_from_ci(
            as.numeric(std[[cfg$ci_lower_col]]),
            as.numeric(std[[cfg$ci_upper_col]])
        ),
        p = se_from_p(std$.eff, as.numeric(std[[cfg$p_col]]))
    )

    std$.p <- if (is.null(cfg$p_col)) {
        NA_real_
    } else {
        raw <- as.numeric(std[[cfg$p_col]])
        if (isTRUE(cfg$neglog10_p)) 10^(-raw) else raw
    }

    std <- std[!is.na(std$.eff) & !is.na(std$.se) & std$.se > 0, , drop = FALSE]
    if (drop_indels) {
        std <- std[
            std$.ea %in%
                c("A", "C", "G", "T") &
                std$.oa %in% c("A", "C", "G", "T"),
            ,
            drop = FALSE
        ]
    }
    if (nrow(std) == 0) {
        return(NULL)
    }

    # onto GRCh38
    if (identical(cfg$build, "GRCh37")) {
        if (is.null(pos_map)) {
            stop("a GRCh37 input needs pos_map")
        }
        m <- match(std$.pos, pos_map$pos_hg19)
        std <- std[!is.na(m), , drop = FALSE]
        std$.pos38 <- pos_map$pos_hg38[m[!is.na(m)]]
    } else {
        std$.pos38 <- std$.pos
    }
    if (nrow(std) == 0) {
        return(NULL)
    }

    A1 <- pmin(std$.ea, std$.oa)
    A2 <- pmax(std$.ea, std$.oa)

    tibble::tibble(
        SNPid = paste(chr, std$.pos38, A1, A2, sep = "_"),
        chrom = chr,
        pos = std$.pos38,
        A1 = A1,
        A2 = A2,
        beta = ifelse(std$.ea == A1, std$.eff, -std$.eff),
        se = std$.se,
        p = std$.p
    ) |>
        dplyr::distinct(SNPid, .keep_all = TRUE)
}


## ---- instruments ----------------------------------------------------------------

# The eight frozen instruments plus the cis-NLRP3 activity score, oriented so
# that estimates read per one-unit DECREASE in the score. Only the "cis-NLRP3
# trait" rows are read.
load_instruments <- function(
    path = instrument_file,
    negate = TRUE,
    check_freq = TRUE
) {
    if (!file.exists(path)) {
        stop(
            "instrument table not found:\n  ",
            path,
            "\nRun analysis/00_instrument_selection.R first."
        )
    }
    ex <- data.table::fread(path, data.table = FALSE) |>
        dplyr::transmute(
            SNP = SNP,
            chr = as.integer(chr),
            pos_hg38 = as.integer(pos_hg38),
            A1 = toupper(A1),
            A2 = toupper(A2),
            eaf_exposure = as.numeric(eaf),
            beta_exposure = as.numeric(beta_exposure),
            se_exposure = as.numeric(se_exposure)
        ) |>
        dplyr::arrange(pos_hg38)

    stopifnot(
        nrow(ex) == 8,
        all(ex$SNP == paste(ex$chr, ex$pos_hg38, ex$A1, ex$A2, sep = "_")),
        all(ex$A1 < ex$A2),
        !any(is.na(ex$beta_exposure))
    )

    # GRCh37 positions for the same eight variants, for the outcome files still
    # released on that build. Produced with UCSC liftOver and cross-checked
    # against the Parkinson's, T2D and COVID-19 files, all natively GRCh37.
    hg19 <- tibble::tribble(
        ~SNP              , ~pos_hg19  ,
        "1_247406019_C_T" , 247569321L ,
        "1_247432548_C_T" , 247595850L ,
        "1_247433558_A_C" , 247596860L ,
        "1_247438293_C_T" , 247601595L ,
        "1_247442302_A_G" , 247605604L ,
        "1_247452478_A_G" , 247615780L ,
        "1_247459572_C_T" , 247622874L ,
        "1_247460342_C_G" , 247623644L
    )
    ex <- dplyr::left_join(ex, hg19, by = "SNP")
    stopifnot(!any(is.na(ex$pos_hg19)))

    # Every instrument goes on to be paired with an INTERVAL LD matrix, so the
    # panel and the workbook must agree on which variant each ID names. See
    # check_panel_freq() for what goes wrong when they do not.
    if (check_freq) {
        check_panel_freq(
            ex$SNP,
            ex$eaf_exposure,
            label = "cis-NLRP3 instruments"
        )
    }

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
    stopifnot(length(snp_ids) >= 2)

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


# Panel allele frequency, oriented onto the ASCII-first allele of the variant
# ID, so it is directly comparable with an `A1 frequency` from summary
# statistics.
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

    if (!file.exists(paste0(tmp, ".afreq"))) {
        stop("plink2 --freq produced no output for the requested variants")
    }
    fr <- utils::read.table(
        paste0(tmp, ".afreq"),
        header = TRUE,
        comment.char = "",
        check.names = FALSE
    )
    names(fr)[1] <- "CHROM"

    SNP <- from_panel_id(fr$ID)
    A1 <- vapply(strsplit(SNP, "_", fixed = TRUE), `[`, character(1), 3L)

    tibble::tibble(
        SNP = SNP,
        # --freq reports the ALT frequency; ALT is A1 only when the panel's REF
        # happens to be A2, which nothing guarantees.
        freq_panel = ifelse(A1 == fr$ALT, fr$ALT_FREQS, 1 - fr$ALT_FREQS)
    )
}

# Guard against the LD panel and the summary statistics meaning different
# variants by the same CHR_POS_A1_A2 name. Nothing downstream notices when they
# disagree.
check_panel_freq <- function(
    snp_ids,
    eaf,
    label = "instruments",
    tol = 0.05,
    panel = ld_panel,
    plink2 = plink2_bin,
    action = c("stop", "warn")
) {
    action <- match.arg(action)
    stopifnot(length(snp_ids) == length(eaf))

    fr <- panel_allele_freq(snp_ids, panel = panel, plink2 = plink2)
    cmp <- tibble::tibble(SNP = snp_ids, freq_data = as.numeric(eaf)) |>
        dplyr::inner_join(fr, by = "SNP") |>
        dplyr::mutate(delta = abs(freq_panel - freq_data))

    if (nrow(cmp) == 0) {
        warning(sprintf(
            "[%s] no variant found in the panel; frequency check skipped",
            label
        ))
        return(invisible(cmp))
    }

    bad <- cmp[!is.na(cmp$delta) & cmp$delta > tol, , drop = FALSE]
    if (nrow(bad) > 0) {
        msg <- sprintf(
            paste0(
                "[%s] %d variant(s) disagree with the LD panel on A1 ",
                "frequency by more than %.2f - the panel and the summary ",
                "statistics are naming different variants:\n%s"
            ),
            label,
            nrow(bad),
            tol,
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
        )
        if (identical(action, "stop")) stop(msg) else warning(msg)
    } else {
        message(sprintf(
            "[%s] panel/data A1 frequency agree for %d variant(s), max |d| = %.4f",
            label,
            nrow(cmp),
            max(cmp$delta, na.rm = TRUE)
        ))
    }
    invisible(cmp)
}


## ---- instrument strength -----------------------------------------------------------

# LD-aware instrument strength from marginal summary statistics.
joint_F_R2 <- function(beta, se, LD_inv, n = NULL) {
    stopifnot(length(beta) == length(se), nrow(LD_inv) == length(beta))

    z <- beta / se
    k <- length(z)
    chi2 <- as.numeric(t(z) %*% LD_inv %*% z)

    out <- list(
        z = z,
        chi2 = chi2,
        F_joint = chi2 / k,
        F_mean = mean(z^2),
        F_min = min(z^2),
        F_per_snp = z^2
    )

    if (is.null(n)) {
        out$R2_joint <- out$R2_rho <- out$R2_adj <- NA_real_
        out$R2_per_snp <- rep(NA_real_, k)
        return(out)
    }

    # Primary: invert the first-stage F relation. Bounded in [0,1] by
    # construction and the most conservative of the three.
    out$R2_joint <- out$F_joint / (out$F_joint + (n - k - 1) / k)

    # Marginal correlations combined through the LD matrix; identical in exact
    # arithmetic, reported so the agreement is visible.
    rho <- sign(z) * sqrt(z^2 / (z^2 + n - 2))
    out$R2_rho <- as.numeric(t(rho) %*% LD_inv %*% rho)

    # Adjusted for the K degrees of freedom spent (E[chi2] = K under the null).
    out$R2_adj <- (chi2 - k) / (chi2 - k + n - k - 1)

    out$R2_per_snp <- z^2 / (z^2 + n - 2)
    out
}

# Effective sample size implied by the standard errors (the Genomic SEM
# identity).
effective_n <- function(se, eaf) {
    stats::median(
        1 / (2 * pmin(eaf, 1 - eaf) * (1 - pmin(eaf, 1 - eaf)) * se^2)
    )
}


## ---- Mendelian randomization ----------------------------------------------------

# Correlated IVW plus weighted median for one harmonised outcome table.
# ld_full must be the signed LD matrix over all instruments; it is subset to
# whichever ones the outcome actually carries.
run_mr <- function(dat, ld_full, min_snps = 3L) {
    label <- dat$outcome[1]
    usable <- dat |>
        dplyr::filter(!is.na(beta_outcome), !is.na(se_outcome), se_outcome > 0)

    if (nrow(usable) < min_snps) {
        message(sprintf(
            "[%s] only %d usable instruments, skipping",
            label,
            nrow(usable)
        ))
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
    ) |>
        dplyr::mutate(outcome = label, nsnp = nrow(usable), .before = 1)
}


## ---- reporting -------------------------------------------------------------------

# Say plainly which instruments a study is missing and why, rather than letting
# them vanish into an NA.
report_missing <- function(harmonised, label) {
    absent <- harmonised |> dplyr::filter(is.na(beta_raw))
    mismatch <- harmonised |>
        dplyr::filter(!is.na(beta_raw) & is.na(beta_outcome))
    palin <- harmonised |> dplyr::filter(!is.na(beta_outcome) & palindromic)

    if (nrow(absent) > 0) {
        warning(sprintf(
            "[%s] %d/8 instruments absent from the file: %s",
            label,
            nrow(absent),
            paste(absent$SNP, collapse = ", ")
        ))
    }
    if (nrow(mismatch) > 0) {
        warning(sprintf(
            "[%s] %d/8 instruments present but alleles do not match: %s",
            label,
            nrow(mismatch),
            paste(mismatch$SNP, collapse = ", ")
        ))
    }
    if (nrow(palin) > 0) {
        message(sprintf(
            "  note: %d palindromic instrument(s) matched on allele identity only: %s",
            nrow(palin),
            paste(palin$SNP, collapse = ", ")
        ))
    }
    message(sprintf(
        "  -> %d/8 instruments usable",
        sum(!is.na(harmonised$beta_outcome))
    ))
}


## ---- genome-wide summary statistics ------------------------------------------------
## Three readers shared by the mediation steps (07a, 07a2, 07b, 07c).

# -log10(p) recovered from the RAW STRING, so exponents past the double-
# precision floor survive.
nlog10_from_p <- function(x) {
    x <- trimws(as.character(x))
    out <- suppressWarnings(-log10(as.numeric(x)))
    m <- regmatches(x, regexec("^([0-9.]+)[eE]([+-]?[0-9]+)$", x))
    hit <- lengths(m) == 3
    if (any(hit)) {
        out[hit] <- -log10(as.numeric(vapply(m[hit], `[`, "", 2))) -
            as.numeric(vapply(m[hit], `[`, "", 3))
    }
    out
}

# Stream a file, keeping only variants below a p threshold. A file reporting
# -log10(p) needs the comparison inverted.
read_significant <- function(cfg, p_threshold = MED_CLUMP_P) {
    header <- header_of(cfg$file)
    pi <- col_index(header, cfg$p_col, cfg$file)

    cond <- if (isTRUE(cfg$neglog10_p)) {
        sprintf(
            "$%d != \"NA\" && $%d != \"\" && $%d+0 > %.10f",
            pi,
            pi,
            pi,
            -log10(p_threshold)
        )
    } else {
        sprintf(
            "$%d != \"NA\" && $%d != \"\" && ($%d+0 < %g || $%d+0 <= 0)",
            pi,
            pi,
            pi,
            p_threshold,
            pi
        )
    }

    keep_chr <- unique(c(cfg$p_col, cfg$nlog10_col))
    df <- data.table::fread(
        cmd = sprintf(
            "%s | awk -F'\\t' 'NR==1 || (%s)'",
            reader_cmd(cfg$file),
            cond
        ),
        data.table = FALSE,
        showProgress = FALSE,
        colClasses = stats::setNames(
            rep("character", length(keep_chr)),
            keep_chr
        )
    )
    if (ncol(df) == length(header)) {
        names(df) <- header
    }
    df
}

# Put any registry file on the shared schema: ASCII-sorted GRCh38 variant ID with
# beta, eaf and se oriented onto A1.
to_common <- function(df, cfg) {
    stopifnot(identical(cfg$build, "GRCh38"))

    chr <- as.integer(sub("^chr", "", as.character(df[[cfg$chr_col]])))
    pos <- as.integer(df[[cfg$pos_col]])
    ea <- toupper(as.character(df[[cfg$ea_col]]))
    oa <- toupper(as.character(df[[cfg$oa_col]]))
    eff <- as.numeric(df[[cfg$effect_col]])
    if (identical(cfg$effect_type, "OR")) {
        eff <- log(eff)
    }

    se <- switch(
        if (is.null(cfg$se_source)) "column" else cfg$se_source,
        column = as.numeric(df[[cfg$se_col]]),
        ci = se_from_ci(
            as.numeric(df[[cfg$ci_lower_col]]),
            as.numeric(df[[cfg$ci_upper_col]])
        ),
        p = se_from_p(eff, as.numeric(df[[cfg$p_col]]))
    )

    p <- if (is.null(cfg$p_col)) {
        NA_real_
    } else {
        raw <- as.numeric(df[[cfg$p_col]])
        if (isTRUE(cfg$neglog10_p)) 10^(-raw) else raw
    }

    # Exact -log10(p), immune to the double-precision floor that makes `p` itself
    # zero at the strongest loci. Prefer a dedicated column where the release
    # ships one (cfg$nlog10_col); otherwise parse the p string.
    nlog10 <- if (is.null(cfg$p_col)) {
        NA_real_
    } else if (isTRUE(cfg$neglog10_p)) {
        as.numeric(df[[cfg$p_col]])
    } else {
        nlog10_from_p(df[[cfg$p_col]])
    }
    if (!is.null(cfg$nlog10_col) && cfg$nlog10_col %in% names(df)) {
        alt <- suppressWarnings(as.numeric(df[[cfg$nlog10_col]]))
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
            f <- as.numeric(df[[cfg$eaf_col]])
            ifelse(ea == A1, f, 1 - f)
        },
        n = if (is.null(cfg$n_col)) NA_real_ else as.numeric(df[[cfg$n_col]])
    ) |>
        dplyr::filter(
            !is.na(beta),
            !is.na(se),
            se > 0,
            A1 %in% c("A", "C", "G", "T"),
            A2 %in% c("A", "C", "G", "T")
        ) |>
        dplyr::distinct(SNPid, .keep_all = TRUE)
}

# Pull a fixed set of variants out of a genome-wide file.
lookup_at <- function(cfg, snpids, chr, pos, label = cfg$label) {
    header <- header_of(cfg$file)
    ci <- col_index(header, cfg$chr_col, cfg$file)
    pi <- col_index(header, cfg$pos_col, cfg$file)

    pos_file <- scratch_file()
    writeLines(unique(paste(chr, pos, sep = "\t")), pos_file)
    on.exit(unlink(pos_file), add = TRUE)

    df <- data.table::fread(
        cmd = sprintf(
            "%s | awk -F'\\t' 'NR==FNR{keep[$1\"\\t\"$2];next} {c=$%d; sub(/^chr/,\"\",c)} FNR==1 || ((c\"\\t\"$%d) in keep)' %s -",
            reader_cmd(cfg$file),
            ci,
            pi,
            shQuote(pos_file)
        ),
        data.table = FALSE,
        showProgress = FALSE
    )
    if (ncol(df) == length(header)) {
        names(df) <- header
    }
    if (nrow(df) == 0) {
        stop(sprintf("[%s] no rows matched", label))
    }

    to_common(df, cfg) |> dplyr::filter(SNPid %in% snpids)
}

# plink2 --clump ranks on its P column and cannot break ties at P = 0, where
# the 24 strongest ApoB variants all land.
clump_key <- function(nlog10, p_threshold = MED_CLUMP_P) {
    bad <- !is.finite(nlog10)
    if (any(bad)) {
        stop(sprintf(
            "clump_key(): %d variant(s) have no finite -log10(p). A file writing the literal \"0\" or \"0.0\" loses the magnitude entirely - declare nlog10_col for it in config.R, or the clump order at that locus would be arbitrary.",
            sum(bad)
        ))
    }
    r <- rank(-nlog10, ties.method = "first")
    r / (length(r) + 1) * p_threshold
}

# One variant per `bin_bp` window, genome-wide.
thin_genome <- function(cfg, bin_bp = 100000L) {
    header <- header_of(cfg$file)
    ci <- col_index(header, cfg$chr_col, cfg$file)
    pi <- col_index(header, cfg$pos_col, cfg$file)

    df <- data.table::fread(
        cmd = sprintf(
            "%s | awk -F'\\t' 'NR==1{print; next} {c=$%d; sub(/^chr/,\"\",c); k=c\"_\"int($%d/%d); if(!(k in seen)){seen[k]=1; print}}'",
            reader_cmd(cfg$file),
            ci,
            pi,
            bin_bp
        ),
        data.table = FALSE,
        showProgress = FALSE
    )
    if (ncol(df) == length(header)) {
        names(df) <- header
    }
    to_common(df, cfg)
}

## -----------------------------------------------------------------------------
## PART 2 - general-purpose genetics helpers
## -----------------------------------------------------------------------------

# uses plink to quickly calculate LD from a reference panel.
# its important that the two alleles are ASCII sorted (i.e. --set-all-variant-ids @_#_\$1_\$2)

local_ld_calculation <- function(
    index_variant,
    all_variants,
    reference,
    ...
) {
    message(paste(
        "Calculating LD using the following reference panel:",
        basename(reference)
    ))
    out_file <- scratch_file()
    plink_exe <- "/rds/user/nh608/hpc-work/software/plink2/plink2"

    # extract all variants in that locus -> speeds up computation
    tmp_variants_file <- scratch_file("variants")
    data.table::fwrite(
        data.frame(all_variants),
        file = tmp_variants_file,
        row.names = FALSE,
        col.names = F
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
    tmp_plink <- scratch_file("tmp_plink")
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
            "${plink_exe} --chr ${chr_} --extract ${tmp_variants_file} --pfile ${reference} --make-pgen --out ${tmp_plink}"
        )
    } else {
        cmd <- stringr::str_interp(
            "${plink_exe} --chr ${chr_} --extract ${tmp_variants_file} --bfile ${reference} --make-pgen --out ${tmp_plink}"
        )
    }
    system(cmd, ignore.stdout = T)

    # run plink
    system(
        paste(
            plink_exe,
            "--pfile",
            tmp_plink,
            "--r2-unphased --ld-snp",
            index_variant,
            "--ld-window-r2 0 --ld-window-kb 99999 --ld-window 99999 --out",
            out_file
        ),
        ignore.stdout = T
    )
    if (file.exists(paste0(out_file, ".vcor"))) {
        out <- data.table::fread(input = paste0(out_file, ".vcor")) %>%
            as.data.frame()
        system(str_interp("rm ${tmp_plink}*"))
        return(out)
    } else {
        message(
            "Initial calculation failed, because SNP was not found in the dataset"
        )
        system(str_interp("rm ${tmp_plink}*"))
        stop(
            "Make sure the index SNP exists in the reference panel. Otherwise select a different one using index_snp=''"
        )
    }
}


get_high_ld_snps <- function(
    index_variant,
    reference,
    ld_threshold = 0.8,
    window_kb = 100,
    verbose = TRUE,
    chr = NULL,
    start = NULL,
    stop = NULL,
    ...
) {
    message(paste(
        "Calculating LD using the following reference panel:",
        basename(reference)
    ))
    out_file <- scratch_file()
    plink_exe <- "/rds/user/nh608/hpc-work/software/plink2/plink2"

    # If chr, start, and stop are specified, first filter the reference to the region
    # This massively reduces allele freq calculation time
    filtered_reference <- NULL
    if (!is.null(chr) && !is.null(start) && !is.null(stop)) {
        message(paste(
            "Filtering reference to region:",
            chr,
            ":",
            start,
            "-",
            stop
        ))
        filtered_reference <- scratch_file()
        filter_cmd <- paste(
            plink_exe,
            "--pfile",
            reference,
            "--chr",
            chr,
            "--from-bp",
            start,
            "--to-bp",
            stop,
            "--make-pgen",
            "--threads",
            4,
            "--out",
            filtered_reference
        )
        system(filter_cmd, ignore.stdout = !verbose)
        reference <- filtered_reference
    }

    # Create a temporary file to write the SNP(s) to
    snps_file <- scratch_file(fileext = ".snps")
    writeLines(index_variant, snps_file)

    cmd <- paste(
        plink_exe,
        "--pfile",
        reference,
        "--r2-unphased",
        "--ld-snp-list",
        snps_file,
        "--ld-window-r2",
        ld_threshold,
        "--ld-window-kb",
        window_kb,
        "--threads",
        4, # Use multiple threads for speed
        "--out",
        out_file
    )

    system(cmd, ignore.stdout = !verbose)

    # Clean up filtered reference files if they were created
    if (!is.null(filtered_reference)) {
        unlink(paste0(filtered_reference, c(".pgen", ".pvar", ".psam", ".log")))
    }

    return(data.table::fread(paste0(out_file, ".vcor"), data.table = FALSE))
}


## This function "aligns" alleles so that they are ASCII sorted.
## If it detects a SNPid which is not ASCII sorted, it will correct it and change the sign of the beta
## Optionally, if you provide an LD reference, it will calculate the allele frequency.

# A1 WILL BE THE EFFECT ALLELE WHICH WILL CORRESPOND TO ALLELE WHICH IS ALPHABETICALLY FIRST
align_ASCII_sort <- function(
    data,
    effect_allele,
    other_allele,
    ld_reference = NULL,
    beta = "beta",
    status = FALSE
) {
    A1 <- str_split_fixed(data[["SNPid"]], "_", 4)[, 3]
    data[[beta]] <- ifelse(
        A1 == data[[effect_allele]],
        data[[beta]],
        data[[beta]] * -1
    )

    if (status) {
        data$flipped <- ifelse(A1 == data[[effect_allele]], FALSE, TRUE)
    }

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
    stopifnot(all(data[[effect_allele]] == A1))

    # calculate MAF
    if (!is.null(ld_reference)) {
        tmp_maf <- calculate_maf(data[["SNPid"]], reference = ld_reference) %>%
            arrange(ID) %>%
            mutate(ALT_FREQS = as.numeric(ALT_FREQS))
        # now make sure that the  allele frequency correspond to the A1 frequency.
        # if A1 is not "ALT", then we have to do 1-ALT_freqs
        A1 <- str_split_fixed(tmp_maf$ID, "_", 4)[, 3]
        tmp_maf$ALT_FREQS <- ifelse(
            A1 != tmp_maf$ALT,
            1 - tmp_maf$ALT_FREQS,
            tmp_maf$ALT_FREQS
        )

        # filter out snps that do not occur in our reference dataset
        data <- data %>%
            dplyr::filter(SNPid %in% tmp_maf$ID)

        data <- data %>%
            left_join(
                .,
                tmp_maf %>% dplyr::select(A1_freq = ALT_FREQS, ID),
                by = c("SNPid" = "ID")
            )
    }
    return(data)
}


# if the reference is has sorted alleles we have to do something different
add_LD <- function(
    locus,
    SNPid_col = "SNPid",
    index_snp = NA,
    available_snps = NULL,
    ...
) {
    dataset <- locus[["data"]]

    # this checks if the SNP exists in the reference bim. if not, take SNP with the next lowest P Value
    if (!is.null(available_snps) & is.na(index_snp)) {
        # if we have manually specified an index snp dont do this step
        for (z in 1:nrow(dataset)) {
            print(z)
            index_snp <- slice_min(
                dataset,
                order_by = !!sym(locus$p),
                n = z,
                with_ties = FALSE
            ) %>%
                pull(locus$labs)
            index_snp <- index_snp[z]
            if (index_snp %in% available_snps) {
                print(index_snp)
                break
            }
        }
    }

    index_snp <- ifelse(
        is.na(index_snp),
        slice_min(
            dataset,
            order_by = !!sym(locus$p),
            n = 1,
            with_ties = FALSE
        ) %>%
            pull(locus$labs),
        index_snp
    )

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


calculate_maf <- function(
    variants,
    reference,
    plink2_bin = "/rds/user/nh608/hpc-work/software/plink2/plink2"
) {
    # Make textfile
    fn <- scratch_file()
    write.table(
        data.frame(variants),
        file = fn,
        row.names = F,
        col.names = F,
        quote = F
    )

    fun1 <- paste0(
        plink2_bin,
        " --pfile ",
        reference,
        " --extract ",
        fn,
        " --freq ",
        " --out ",
        fn
    )
    system(fun1, ignore.stdout = T)
    res <- data.table::fread(paste0(fn, ".afreq"), header = T)
}


# LIFTOVER_CHAIN_DIR is overridable from config.R.
if (!exists("LIFTOVER_CHAIN_DIR")) {
    LIFTOVER_CHAIN_DIR <- "/rds/user/nh608/hpc-work/software/UCSC_liftOver"
}

ld_clump_local <- function(
    dat,
    id_col = "SNP",
    p_col = "p",
    clump_kb,
    clump_r2,
    clump_p,
    bfile,
    plink_bin,
    verbose = TRUE
) {
    # Make textfile
    shell <- ifelse(Sys.info()["sysname"] == "Windows", "cmd", "sh")
    fn <- scratch_file()
    write.table(
        data.frame(SNP = dat[[id_col]], P = dat[[p_col]]),
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
        shQuote(plink_bin, type = shell),
        " ",
        panel_flag,
        " ",
        shQuote(bfile, type = shell),
        " --clump ",
        shQuote(fn, type = shell),
        " --clump-p1 ",
        clump_p,
        " --clump-r2 ",
        clump_r2,
        " --clump-kb ",
        clump_kb,
        " --out ",
        shQuote(fn, type = shell)
    )
    if (!verbose) {
        null_device <- ifelse(
            Sys.info()["sysname"] == "Windows",
            "NUL",
            "/dev/null"
        )
        fun2 <- paste(fun2, ">", null_device, "2>&1")
    }

    system(fun2)

    # Check if PLINK output file exists
    clumps_file <- paste(fn, ".clumps", sep = "")
    if (!file.exists(clumps_file)) {
        # Surface what PLINK actually said, rather than guessing at the cause.
        log_file <- paste0(fn, ".log")
        detail <- if (file.exists(log_file)) {
            paste(
                utils::tail(readLines(log_file, warn = FALSE), 15),
                collapse = "\n"
            )
        } else {
            "(no PLINK log written)"
        }
        stop(
            "PLINK clumping failed - no output at: ",
            clumps_file,
            "\ncommand: ",
            fun2,
            "\nPLINK log tail:\n",
            detail
        )
    }

    res <- data.table::fread(clumps_file, header = TRUE)
    return(res)
}


get_gene_coordinates_hg38 <- function(gene_symbol, ensDb = NULL) {
    if (is.null(ensDb)) {
        ah <- AnnotationHub()
        hg38_annotations <- ah[["AH116291"]]
    } else {
        hg38_annotations <- ensDb
    }

    gene_coords_hg38 <- genes(hg38_annotations) %>%
        as.data.frame() %>%
        filter(symbol == gene_symbol) %>%
        filter(grepl("ENSG", gene_id))

    if (nrow(gene_coords_hg38) == 0) {
        warning(paste("No coordinates found for gene symbol:", gene_symbol))
        return(NULL)
    }

    # Filter for integer chromosomes only (exclude unusual chromosome names)
    chr_levels <- as.character(gene_coords_hg38$seqnames)
    integer_chr_indices <- which(grepl("^[0-9]+$", chr_levels))

    if (length(integer_chr_indices) == 0) {
        stop(paste(
            "No integer chromosome coordinates found for gene symbol:",
            gene_symbol,
            ". Found chromosomes:",
            paste(unique(chr_levels), collapse = ", ")
        ))
    }

    # Filter data to only include integer chromosomes
    gene_coords_filtered <- gene_coords_hg38[integer_chr_indices, ]

    # Check if multiple chromosomes remain after filtering
    unique_chr <- unique(gene_coords_filtered$seqnames)
    if (length(unique_chr) > 1) {
        stop(paste(
            "Multiple integer chromosomes found for gene symbol:",
            gene_symbol,
            ". Chromosomes:",
            paste(unique_chr, collapse = ", "),
            ". Please check gene annotation."
        ))
    }

    chr <- as.integer(as.character(unique_chr[1]))
    start_hg38 <- gene_coords_filtered$start
    stop_hg38 <- gene_coords_filtered$end

    list(chromosome = chr, start = start_hg38, stop = stop_hg38)
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
