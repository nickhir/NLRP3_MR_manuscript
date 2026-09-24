## 09 - Proteome-wide cis-MR
##
## MR of the activity score against every UKB-PPP plasma assay. Writes
## results/09_proteome_mr/, read by steps 04 and 10.

suppressPackageStartupMessages(library(MendelianRandomization))
source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("09_proteome_mr")

exposure <- load_instruments()
ld_full <- interval_ld_matrix(exposure$SNP)

assays <- tibble(protein_id = readLines(ppp_manifest)) %>%
    filter(protein_id != "") %>%
    mutate(
        path = file.path(ppp_dir, paste0(protein_id, ".bgz")),
        gene_name = sub("_.*$", "", protein_id),
        uniprot = map_chr(str_split(protein_id, "_"), 2, .default = NA_character_),
        olink_id = map_chr(str_split(protein_id, "_"), 3, .default = NA_character_),
        panel = sub("^[^_]+_[^_]+_[^_]+_[^_]+_", "", protein_id)
    )

# IVW and MR-Egger use the correlation matrix; the weighted median treats the
# instruments as independent.
run_one <- function(i) {
    a <- assays[i, ]
    dat <- read_ppp(a$path, exposure)
    mr_in <- mr_input(bx = dat$beta_exposure, bxse = dat$se_exposure,
                      by = dat$beta_outcome, byse = dat$se_outcome,
                      snps = dat$SNP, correlation = ld_full[dat$SNP, dat$SNP])
    ivw <- mr_ivw(mr_in, correl = TRUE)
    egger <- mr_egger(mr_in, correl = TRUE)
    median <- mr_median(mr_in, weighting = "weighted")
    list(
        res = tibble(
            protein_id = a$protein_id, gene_name = a$gene_name, uniprot = a$uniprot,
            olink_id = a$olink_id, panel = a$panel,
            n_snps = nrow(dat), n_ppp = max(dat$n_outcome), min_info = min(dat$info),
            ivw_beta = ivw$Estimate, ivw_se = ivw$StdError, ivw_pval = ivw$Pvalue,
            ivw_het_q = ivw$Heter.Stat[1], ivw_het_p = ivw$Heter.Stat[2],
            egger_beta = egger$Estimate, egger_se = egger$StdError.Est,
            egger_pval = egger$Pvalue.Est, egger_intercept = egger$Intercept,
            egger_intercept_se = egger$StdError.Int, egger_intercept_pval = egger$Pvalue.Int,
            median_beta = median$Estimate, median_se = median$StdError,
            median_pval = median$Pvalue
        ),
        harm = dat %>%
            select(SNP, A1, A2, beta_exposure, se_exposure, beta_outcome, se_outcome,
                   eaf_outcome, p_outcome, info, n_outcome) %>%
            mutate(protein_id = a$protein_id, gene_name = a$gene_name, .before = 1)
    )
}
results_list <- lapply(seq_len(nrow(assays)), run_one)
mr_all <- map_dfr(results_list, "res")
harmonised <- map_dfr(results_list, "harm")

# A protein on more than one Olink panel (IL6 has four) keeps its most
# significant assay. N_EFFECTIVE_TESTS comes from an eigendecomposition of the
# covariate-adjusted UKB proteome correlation matrix, which needs
# individual-level data; see 09b_effective_number_of_tests.R.
N_EFFECTIVE_TESTS <- 1821
mr_dedup <- mr_all %>%
    group_by(gene_name) %>%
    slice_min(order_by = ivw_pval, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    arrange(ivw_pval) %>%
    mutate(ivw_pval_bonf = pmin(ivw_pval * N_EFFECTIVE_TESTS, 1))

print(mr_dedup %>%
          filter(ivw_pval_bonf < 0.05) %>%
          select(gene_name, n_snps, ivw_beta, ivw_se, ivw_pval, ivw_pval_bonf),
      n = 50)

run_metadata <- tibble(
    key = c("exposure_direction", "cohort", "cohort_note", "ld_panel",
            "n_effective_tests", "ppp_dir", "generated"),
    value = c(EXPOSURE_DIRECTION, "UKB-PPP Combined (Synapse syn51365308)",
              "all ancestries, not European-only; ~3-5% non-European", ld_panel,
              as.character(N_EFFECTIVE_TESTS), ppp_dir, format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
)

write_tsv(mr_all, file.path(out_dir, "ukb_ppp_proteome_mr_all_assays.tsv"))
write_tsv(mr_dedup, file.path(out_dir, "ukb_ppp_proteome_mr_results.tsv"))
write_tsv(harmonised, file.path(out_dir, "ukb_ppp_proteome_harmonised.tsv"))
write_tsv(run_metadata, file.path(out_dir, "ukb_ppp_proteome_run_metadata.tsv"))
saveRDS(ld_full, file.path(out_dir, "ukb_ppp_proteome_ld_matrix.rds"))
