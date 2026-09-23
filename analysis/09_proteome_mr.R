## 09 - Proteome-wide cis-MR
##
## Runs the activity-score MR against every UKB-PPP plasma assay, one assay at
## a time. Writes results/09_proteome_mr/ and feeds step 10.

suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(here)
    library(parallel)
    library(MendelianRandomization)
})

options(datatable.fread.datatable = FALSE)


## ----paths--------------------------------------------------------------------
analysis_dir <- here::here()

source(file.path(analysis_dir, "helpers.R"))
output_dir <- file.path(analysis_dir, "results", "09_proteome_mr")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# The eight cis-NLRP3 instruments and the activity score, selected on the
# INTERVAL panel by analysis/00_instrument_selection.R. Run that step first.
instrument_file <- file.path(analysis_dir, "results", "00_instrument_selection",
                             "nlrp3_instruments.tsv")

# UKB-PPP Combined, reformatted to one bgzipped, tabix-indexed file per assay.
ppp_dir <- paste0(
    "/rds/project/rds-C1Ph08tkaOA/public/proteomics/UKB-PPP/sun23/",
    "UKB-PPP pGWAS summary statistics (reformatted)/Combined_European"
)
ppp_manifest <- paste0(ppp_dir, ".lst")

# Use the ld_panels/ copy. The sibling copy under WGS_reference/results/ is
# not allele-sorted and silently drops about half of all variants on an ID
# join, despite its README claiming the only difference is a "chr" prefix.
ld_panel <- paste0(
    "/rds/user/nh608/hpc-work/oxLDL/data/oxLDL_data/INTERVAL_reference/",
    "WGS_reference/ld_panels/INTERVAL_allchr.GRCh38.alpha_sorted_alleles"
)

plink2_bin <- "/rds/user/nh608/hpc-work/software/plink2/plink2"
tabix_bin  <- "/rds/user/nh608/hpc-work/software/micromamba/envs/sambcfenv/bin/tabix"

n_cores <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", unset = "1"))


## ----exposure-----------------------------------------------------------------
# Variant IDs follow the project convention CHR_POS_A1_A2 with ASCII-sorted
# alleles, so A1 is simply the alphabetically first allele and carries no
# biological meaning. The exposure betas are already oriented to A1.
exposure <- fread(instrument_file, data.table = FALSE) %>%
    transmute(
        SNP           = SNP,
        chr           = as.integer(chr),
        pos_hg38      = as.integer(pos_hg38),
        A1            = toupper(A1),
        A2            = toupper(A2),
        eaf_exposure  = as.numeric(eaf),
        beta_exposure = as.numeric(beta_exposure),
        se_exposure   = as.numeric(se_exposure)
    )


## ----flip_exposure_direction--------------------------------------------------
# The spreadsheet reports effects per one-unit INCREASE in the cis-NLRP3
# activity score. Every result here is instead expressed per one-unit DECREASE.
exposure <- exposure %>% mutate(beta_exposure = -beta_exposure)

exposure_direction <- "1-unit DECREASE in cis-NLRP3 activity score"
print(exposure)


ld_full <- interval_ld_matrix(exposure$SNP)
print(round(ld_full, 3))


## ----protein_list-------------------------------------------------------------
assays <- readLines(ppp_manifest) %>%
    discard(~ .x == "") %>%
    tibble(protein_id = .) %>%
    mutate(
        path      = file.path(ppp_dir, paste0(protein_id, ".bgz")),
        gene_name = sub("_.*$", "", protein_id),
        uniprot   = map_chr(str_split(protein_id, "_"), 2, .default = NA_character_),
        olink_id  = map_chr(str_split(protein_id, "_"), 3, .default = NA_character_),
        panel     = sub("^[^_]+_[^_]+_[^_]+_[^_]+_", "", protein_id)
    )

message(sprintf("%d assays, %d unique gene symbols",
                nrow(assays), n_distinct(assays$gene_name)))

# Smoke-test hook: PPP_MR_LIMIT=n runs only the first n assays and diverts the
# output somewhere harmless, so a truncated run can never overwrite the real
# results. Unset for the real run.
ppp_limit <- as.integer(Sys.getenv("PPP_MR_LIMIT", unset = ""))
smoke_test <- !is.na(ppp_limit) && ppp_limit > 0
if (smoke_test) {
    assays <- head(assays, ppp_limit)
    output_dir <- scratch_path("ppp_smoke_test")
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
}


## ----readers------------------------------------------------------------------
PPP_COLS <- c("CHROM", "GENPOS", "ID", "ALLELE0", "ALLELE1", "A1FREQ",
              "INFO", "N", "TEST", "BETA", "SE", "CHISQ", "LOG10P", "EXTRA")

# One tabix call per assay, asking only for the eight instrument positions
# rather than the whole NLRP3 window. GENPOS is the GRCh38 coordinate.
regions <- sprintf("%d:%d-%d", exposure$chr, exposure$pos_hg38, exposure$pos_hg38)

read_assay <- function(path) {
    txt <- system2(tabix_bin, c(shQuote(path), regions),
                   stdout = TRUE, stderr = FALSE)
    if (length(txt) == 0) return(NULL)
    df <- data.table::fread(text = paste(txt, collapse = "\n"),
                            sep = "\t", header = FALSE,
                            colClasses = "character")
    if (ncol(df) != length(PPP_COLS)) return(NULL)
    setNames(df, PPP_COLS)
}

# The released files carry GRCh38 in GENPOS and GRCh37 inside the ID string.
# Assert that, so a future release with a different convention fails here
# rather than joining nothing and reporting "0 overlapping instruments".
# Not helpers.R::verify_build(): this checks the UKB-PPP GENPOS/ID build
# convention rather than matching positions against the instrument table.
verify_ppp_build <- function(df, label) {
    id_pos <- as.integer(
        sub("^[^:]+:([0-9]+):.*$", "\\1", df$ID)
    )
    genpos <- as.integer(df$GENPOS)
    ok <- all(genpos %in% exposure$pos_hg38)
    if (!ok) {
        stop(sprintf(
            "[%s] GENPOS is not on GRCh38 - got %s, expected values among %s",
            label, paste(head(genpos), collapse = ","),
            paste(exposure$pos_hg38, collapse = ",")
        ))
    }
    # informational: the ID really should be the other build
    if (any(id_pos == genpos, na.rm = TRUE)) {
        warning(sprintf("[%s] ID position equals GENPOS; check the release", label))
    }
    invisible(TRUE)
}


## ----harmonise_and_mr---------------------------------------------------------
# Keep only rows whose alleles match the instrument, in either orientation,
# then flip the outcome onto A1. ALLELE1 is the REGENIE effect allele and
# A1FREQ is its frequency; neither is guaranteed to be the ASCII-first allele.
harmonise_assay <- function(df) {
    std <- df %>%
        transmute(
            join_pos    = as.integer(GENPOS),
            outcome_ea  = toupper(ALLELE1),
            outcome_oa  = toupper(ALLELE0),
            beta_raw    = as.numeric(BETA),
            se_outcome  = as.numeric(SE),
            eaf_raw     = as.numeric(A1FREQ),
            info        = as.numeric(INFO),
            n_outcome   = as.integer(N),
            p_outcome   = 10^(-as.numeric(LOG10P))
        )

    exposure %>%
        left_join(std, by = c("pos_hg38" = "join_pos"),
                  relationship = "one-to-many") %>%
        mutate(
            forward = outcome_ea == A1 & outcome_oa == A2,
            reverse = outcome_ea == A2 & outcome_oa == A1,
            beta_outcome = case_when(forward ~ beta_raw,
                                     reverse ~ -beta_raw,
                                     TRUE    ~ NA_real_),
            eaf_outcome  = case_when(forward ~ eaf_raw,
                                     reverse ~ 1 - eaf_raw,
                                     TRUE    ~ NA_real_)
        ) %>%
        filter(!is.na(beta_outcome), !is.na(se_outcome), se_outcome > 0) %>%
        # a position can carry several alleles; keep the instrument's own
        distinct(SNP, .keep_all = TRUE)
}

run_one <- function(i) {
    row   <- assays[i, ]
    label <- row$protein_id

    out <- {
        raw <- read_assay(row$path)
        if (is.null(raw) || nrow(raw) == 0) {
            return(list(res = NULL, fail = tibble(
                protein_id = label, reason = "tabix returned no rows")))
        }
        verify_ppp_build(raw, label)

        dat <- harmonise_assay(raw)
        if (nrow(dat) < 3) {
            return(list(res = NULL, fail = tibble(
                protein_id = label,
                reason = sprintf("only %d instrument(s) after harmonisation",
                                 nrow(dat)))))
        }

        ld <- ld_full[dat$SNP, dat$SNP]

        mr_in <- mr_input(
            bx = dat$beta_exposure, bxse = dat$se_exposure,
            by = dat$beta_outcome,  byse = dat$se_outcome,
            exposure = "cis-NLRP3 activity (lower)", outcome = label,
            snps = dat$SNP, correlation = ld
        )

        # mr_ivw()/mr_egger() use the correlation matrix carried by the
        # MRInput; correl = TRUE is passed explicitly so the intent is on the
        # page.
        ivw    <- mr_ivw(mr_in, correl = TRUE)
        egger  <- mr_egger(mr_in, correl = TRUE)
        median <- mr_median(mr_in, weighting = "weighted")

        res <- tibble(
            protein_id = label,
            gene_name  = row$gene_name,
            uniprot    = row$uniprot,
            olink_id   = row$olink_id,
            panel      = row$panel,
            n_snps     = nrow(dat),
            n_ppp      = max(dat$n_outcome, na.rm = TRUE),
            min_info   = min(dat$info, na.rm = TRUE),

            ivw_beta   = ivw$Estimate,
            ivw_se     = ivw$StdError,
            ivw_pval   = ivw$Pvalue,
            ivw_het_q  = if (length(ivw$Heter.Stat) >= 1) ivw$Heter.Stat[1] else NA_real_,
            ivw_het_p  = if (length(ivw$Heter.Stat) >= 2) ivw$Heter.Stat[2] else NA_real_,

            egger_beta          = egger$Estimate,
            egger_se            = egger$StdError.Est,
            egger_pval          = egger$Pvalue.Est,
            egger_intercept     = egger$Intercept,
            egger_intercept_se  = egger$StdError.Int,
            egger_intercept_pval= egger$Pvalue.Int,

            median_beta = median$Estimate,
            median_se   = median$StdError,
            median_pval = median$Pvalue
        )

        list(res = res,
             harm = dat %>%
                 select(SNP, A1, A2, beta_exposure, se_exposure,
                        beta_outcome, se_outcome, eaf_outcome, p_outcome,
                        info, n_outcome) %>%
                 mutate(protein_id = label, gene_name = row$gene_name,
                        .before = 1),
             fail = NULL)
    }

    out
}

results_list <- mclapply(seq_len(nrow(assays)), run_one,
                         mc.cores = n_cores, mc.preschedule = TRUE)

# mclapply reports a worker crash as a try-error rather than throwing
bad <- which(!vapply(results_list, is.list, logical(1)))
if (length(bad) > 0) {
    stop(sprintf("%d worker(s) failed hard, first at assay %s",
                 length(bad), assays$protein_id[bad[1]]))
}

mr_all     <- map_dfr(results_list, "res")
harmonised <- map_dfr(results_list, "harm")
failures   <- map_dfr(results_list, "fail")

if (nrow(failures) > 0) print(count(failures, reason, sort = TRUE))


## ----deduplicate--------------------------------------------------------------
# Proteins measured on more than one Olink panel appear once per assay (IL6
# has four). Keep the most significant IVW result per gene.
mr_dedup <- mr_all %>%
    group_by(gene_name) %>%
    slice_min(order_by = ivw_pval, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    arrange(ivw_pval)

# 1,821 effective tests, from the eigenvalue decomposition of the covariate-
# adjusted UKB proteome correlation matrix. Hardcoded because recomputing it
# needs individual-level UK Biobank data; see 09b_effective_number_of_tests.R.
N_EFFECTIVE_TESTS <- 1821

mr_dedup <- mr_dedup %>%
    mutate(ivw_pval_bonf = pmin(ivw_pval * N_EFFECTIVE_TESTS, 1))

sig <- mr_dedup %>% filter(ivw_pval_bonf < 0.05)
message(sprintf(
    "Bonferroni (n_eff = %d) significant: %d  |  raised by inhibition: %d  |  lowered: %d",
    N_EFFECTIVE_TESTS, nrow(sig),
    sum(sig$ivw_beta > 0), sum(sig$ivw_beta < 0)
))
print(sig %>%
          select(gene_name, n_snps, ivw_beta, ivw_se, ivw_pval, ivw_pval_bonf) %>%
          head(30))


## ----write_results------------------------------------------------------------
attr_note <- tibble(
    key = c("exposure_direction", "cohort", "cohort_note", "ld_panel",
            "n_effective_tests", "ppp_dir", "generated"),
    value = c(
        exposure_direction,
        "UKB-PPP Combined (Synapse syn51365308)",
        "all ancestries, not European-only; ~3-5% non-European",
        ld_panel,
        as.character(N_EFFECTIVE_TESTS),
        ppp_dir,
        format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    )
)

write_tsv(mr_all,     file.path(output_dir, "ukb_ppp_proteome_mr_all_assays.tsv"))
write_tsv(mr_dedup,   file.path(output_dir, "ukb_ppp_proteome_mr_results.tsv"))
write_tsv(harmonised, file.path(output_dir, "ukb_ppp_proteome_harmonised.tsv"))
write_tsv(failures,   file.path(output_dir, "ukb_ppp_proteome_failures.tsv"))
write_tsv(attr_note,  file.path(output_dir, "ukb_ppp_proteome_run_metadata.tsv"))
saveRDS(ld_full,      file.path(output_dir, "ukb_ppp_proteome_ld_matrix.rds"))

message("results written to ", output_dir)


## ----session_info-------------------------------------------------------------
sessionInfo()
