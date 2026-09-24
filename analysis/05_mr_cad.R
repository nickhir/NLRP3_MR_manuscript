## 05 - CAD and coronary atherosclerosis
##
## MR of the activity score against four CAD cohorts and their fixed-effect
## meta-analysis. Writes results/05_mr_cad/.

suppressPackageStartupMessages(library(MendelianRandomization))
source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("05_mr_cad")

ex <- load_instruments() %>%
    transmute(SNP, pos_hg38, A1, A2, bx = beta_exposure, bxse = se_exposure)
ld_full <- interval_ld_matrix(ex$SNP)

cohorts <- CAD_STUDIES[c("aragam", "mvp", "allofus", "finngen")]
studies <- lapply(cohorts, function(cfg) cad_at(read_cad(cfg), ex))
names(studies) <- sapply(cohorts, `[[`, "label")

# Correlated IVW and weighted median, in the schema Figure 3A reads.
run_mr_study <- function(d, label) {
    mi <- mr_input(bx = d$bx, bxse = d$bxse, by = d$by, byse = d$byse,
                   snps = d$SNP, correlation = ld_full[d$SNP, d$SNP])
    iv <- mr_ivw(mi)
    wm <- mr_median(mi, weighting = "weighted")
    tibble(study = label, method = c("IVW", "Weighted Median"),
           beta = c(iv$Estimate, wm$Estimate), se = c(iv$StdError, wm$StdError),
           ci_lower = c(iv$CILower, wm$CILower), ci_upper = c(iv$CIUpper, wm$CIUpper),
           pval = c(iv$Pvalue, wm$Pvalue), n_snps = nrow(d))
}

meta_all <- meta_snp(bind_rows(studies))
# sensitivity: without the one instrument whose Finnish frequency diverges
# sharply from the INTERVAL panel
DROP <- "1_247460342_C_G"
meta_sens <- meta_snp(filter(bind_rows(studies), SNP != DROP))

results <- bind_rows(
    lapply(names(studies), function(n) run_mr_study(studies[[n]], n)),
    run_mr_study(meta_all, "Meta-analysis"),
    run_mr_study(meta_sens, sprintf("Meta-analysis (excl. %s)", DROP))
)

# per-SNP data, for the meta-analysis of step 07c and supplementary table ST07
per_snp <- bind_rows(bind_rows(studies, .id = "study"),
                     mutate(meta_all, study = "Meta-analysis")) %>%
    select(study, SNP, bx, bxse, by, byse)

print(as.data.frame(results %>% transmute(
    study, method, n_snps,
    OR = sprintf("%.2f (%.2f, %.2f)", exp(beta), exp(ci_lower), exp(ci_upper)),
    p = signif(pval, 3))), row.names = FALSE)

write_tsv(results, file.path(out_dir, "cad_meta_studies.tsv"))
write_tsv(per_snp, file.path(out_dir, "cad_meta_studies_per_snp.tsv"))
