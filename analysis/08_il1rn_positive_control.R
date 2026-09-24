## 08 - IL1RN positive control
##
## Builds cis-IL1RN instruments and an IL1Ra activity score by the method used
## at NLRP3, then runs the MR against IL1Ra, gout and rheumatoid arthritis.
## Writes results/08_il1rn_positive_control/.

suppressPackageStartupMessages(library(MendelianRandomization))
source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("08_il1rn_positive_control")

start <- as.integer(IL1RN_START - 150e3)
end <- as.integer(IL1RN_END + 150e3)
sel <- select_instruments(IL1RN_READOUTS, IL1RN_CHR, start, end)


## ---- the instruments, with rsIDs ------------------------------------------------
# rsIDs from the mapping file by position, else from the readouts' own columns
rsid_map <- fread(rsid_map_file, data.table = FALSE) %>%
    filter(chr == paste0("chr", IL1RN_CHR)) %>%
    transmute(position_hg38 = as.integer(pos), rsid_map = rsid)
from_sumstats <- bind_rows(sel$stats) %>%
    filter(SNP %in% sel$score$SNP, grepl("^rs", rsid_source)) %>%
    distinct(SNP, rsid_source) %>%
    group_by(SNP) %>%
    slice_head(n = 1) %>%
    ungroup()

variants <- sel$score %>%
    transmute(SNP, position_hg38 = as.integer(snp_field(SNP, 2)),
              A1 = snp_field(SNP, 3), A2 = snp_field(SNP, 4)) %>%
    arrange(position_hg38) %>%
    left_join(rsid_map, by = "position_hg38") %>%
    left_join(from_sumstats, by = "SNP") %>%
    left_join(rename(sel$panel_eaf, eaf = eaf_panel), by = "SNP") %>%
    mutate(rsid = coalesce(rsid_map, rsid_source))

# Long, one row per variant and readout, all on A1; the figure orients them.
readout_long <- map2_dfr(sel$stats, IL1RN_READOUTS, function(s, cfg) {
    s %>% filter(SNP %in% variants$SNP) %>% transmute(SNP, readout = cfg$label, beta, se, p)
})
effects <- bind_rows(readout_long,
                     transmute(sel$score, SNP, readout = "IL1Ra activity score", beta, se,
                               p = NA_real_)) %>%
    left_join(select(variants, SNP, rsid, position_hg38, A1, A2, eaf), by = "SNP") %>%
    arrange(position_hg38, readout) %>%
    select(SNP, rsid, position_hg38, A1, A2, eaf, readout, beta, se, p)

instrument_table <- variants %>%
    select(SNP, rsid, position_hg38, A1, A2, eaf) %>%
    left_join(rename(sel$score, beta_score = beta, se_score = se), by = "SNP") %>%
    mutate(r2_threshold = 0.1, scaling_constant_k = sel$k,
           pc1_var_explained = sel$pc1_var, score_sign_flipped = sel$flipped)

write_tsv(effects, file.path(out_dir, "il1rn_instrument_effects.tsv"))
write_tsv(instrument_table, file.path(out_dir, "il1rn_instruments.tsv"))
write_tsv(tibble(trait = names(sel$loadings), pc1_loading = as.numeric(sel$loadings),
                 pc1_var_explained = sel$pc1_var),
          file.path(out_dir, "il1rn_pca_loadings.tsv"))
write_tsv(sel$proxies, file.path(out_dir, "il1rn_proxy_replacements.tsv"))
write_tsv(sel$specificity, file.path(out_dir, "il1rn_specificity.tsv"))
write_tsv(filter(sel$freq_cmp, delta > 0.05) %>% arrange(desc(delta)),
          file.path(out_dir, "il1rn_frequency_discordant_variants.tsv"))


## ---- MR: does the score predict IL1Ra, and the diseases anakinra treats? ----------
ld_il1rn <- interval_ld_matrix(variants$SNP)

exposure <- variants %>%
    select(SNP, rsid, pos_hg38 = position_hg38, A1, A2) %>%
    left_join(rename(sel$score, beta_exposure = beta, se_exposure = se), by = "SNP") %>%
    mutate(chr = IL1RN_CHR)

read_outcome <- function(key) {
    cfg <- OUTCOMES[[key]]
    read_region(cfg, IL1RN_CHR, start, end) %>%
        harmonise(cfg) %>%
        transmute(SNP = SNPid, beta_outcome = beta, se_outcome = se, p_outcome = p) %>%
        inner_join(exposure, by = "SNP") %>%
        mutate(outcome = cfg$label, n_cases = cfg$n_cases, n_controls = cfg$n_controls,
               n_total = NA_integer_, binary = TRUE)
}
il1ra <- read_ppp(ppp_il1rn_assay, exposure) %>%
    mutate(outcome = "IL1Ra concentration", n_cases = NA_integer_, n_controls = NA_integer_,
           n_total = n_outcome, binary = FALSE)
gout <- read_outcome("gout")
ra <- read_outcome("ra_ishigaki")

# IVW only: three instruments leave the weighted median and MR-Egger nothing to
# work with. Random effects explicitly, since mr_ivw() falls back to fixed
# effects at three variants or fewer.
run_mr_outcome <- function(dat) {
    mi <- mr_input(bx = dat$beta_exposure, bxse = dat$se_exposure,
                   by = dat$beta_outcome, byse = dat$se_outcome,
                   snps = dat$SNP, correlation = ld_il1rn[dat$SNP, dat$SNP])
    ivw <- mr_ivw(mi, model = "random", correl = TRUE)
    tr <- function(x) if (dat$binary[1]) exp(x) else x
    tibble(outcome = dat$outcome[1], scale = if (dat$binary[1]) "OR" else "beta",
           n_snps = nrow(dat), n_cases = dat$n_cases[1], n_controls = dat$n_controls[1],
           n_total = dat$n_total[1], method = "IVW",
           estimate = tr(ivw$Estimate), se = ivw$StdError,
           ci_lower = tr(ivw$CILower), ci_upper = tr(ivw$CIUpper), p = ivw$Pvalue)
}

mr_results <- bind_rows(run_mr_outcome(il1ra), run_mr_outcome(gout), run_mr_outcome(ra))
mr_harmonised <- bind_rows(il1ra, gout, ra) %>%
    select(SNP, rsid, outcome, beta_exposure, se_exposure, beta_outcome, se_outcome, p_outcome)

print(as.data.frame(select(mr_results, outcome, scale, estimate, ci_lower, ci_upper, p)),
      row.names = FALSE, digits = 3)

write_tsv(mr_results, file.path(out_dir, "il1rn_mr_results.tsv"))
write_tsv(mr_harmonised, file.path(out_dir, "il1rn_mr_harmonised.tsv"))
saveRDS(ld_il1rn, file.path(out_dir, "il1rn_ld_matrix.rds"))
