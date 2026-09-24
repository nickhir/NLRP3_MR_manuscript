## 04 - Inflammatory readouts and effector cytokines
##
## MR of the activity score against CRP, GlycA and neutrophil count, and
## against IL1B, IL18 and IL6 from UKB-PPP. Writes results/04_mr_biomarkers/.

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("04_mr_biomarkers")

exposure <- load_instruments()
ld_full <- interval_ld_matrix(exposure$SNP)

# NLRP3 expression, the fourth readout, is not a circulating marker; Figure 2B
# shows it per variant.
proxy_mr <- lapply(c("CRP", "GlycA", "Neutrophil_count"), function(k) {
    cfg <- READOUTS[[k]]
    outcome <- read_region(cfg, CHR, LOCUS_START, LOCUS_END) %>% harmonise(cfg)
    exposure %>%
        select(SNP, beta_exposure, se_exposure) %>%
        left_join(select(outcome, SNP = SNPid, beta_outcome = beta, se_outcome = se), by = "SNP") %>%
        mutate(outcome = cfg$label) %>%
        run_mr(ld_full) %>%
        mutate(block = "Systemic inflammation proxies", n_total = cfg$n)
}) %>% bind_rows()

# IL6 is assayed on four Olink panels; as in step 09, a gene keeps its most
# significant assay.
cytokines <- tibble(protein_id = readLines(ppp_manifest)) %>%
    mutate(gene_name = sub("_.*$", "", protein_id)) %>%
    filter(gene_name %in% c("IL1B", "IL18", "IL6")) %>%
    mutate(mr = map(protein_id, function(id) {
        mr_ppp_assay(file.path(ppp_dir, paste0(id, ".bgz")), exposure, ld_full)$res
    })) %>%
    unnest(mr) %>%
    group_by(gene_name) %>%
    slice_min(ivw_pval, n = 1, with_ties = FALSE) %>%
    ungroup()
cytokine_mr <- lapply(c("IL1B", "IL18", "IL6"), function(k) {
    r <- cytokines[cytokines$gene_name == k, ]
    tibble(outcome = k, nsnp = r$n_snps, method = c("IVW", "Weighted median"),
           estimate = c(r$ivw_beta, r$median_beta), se = c(r$ivw_se, r$median_se),
           p = c(r$ivw_pval, r$median_pval),
           ci_lower = estimate - 1.96 * se, ci_upper = estimate + 1.96 * se,
           block = "NLRP3 inflammasome-associated cytokines", n_total = r$n_ppp)
}) %>% bind_rows()

# run_mr() calls the LD-corrected estimator "IVW (LD-corrected)"; here it is "IVW".
results <- bind_rows(proxy_mr, cytokine_mr) %>%
    mutate(method = recode(method, "IVW (LD-corrected)" = "IVW"),
           ld_corrected = method == "IVW",
           n_cases = NA_integer_,
           n_controls = NA_integer_) %>%
    select(block, outcome, method, estimate, se, ci_lower, ci_upper, p,
           nsnp, n_total, n_cases, n_controls, ld_corrected)

print(as.data.frame(results), row.names = FALSE, digits = 3)
fwrite(results, file.path(out_dir, "mr_biomarkers.tsv"), sep = "\t")
