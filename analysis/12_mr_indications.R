## 12 - Additional indications
##
## MR of the activity score against the imaging traits and the candidate
## indications in the OUTCOMES registry. Writes results/12_mr_indications/.

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("12_mr_indications")

exposure <- load_instruments()
proxies <- proxy_candidates(exposure$SNP)

# One outcome at the instruments, joined on GRCh38 position (a GRCh37 release is
# lifted first) and turned onto A1. An instrument the release lacks is taken from
# its strongest LD proxy that the release carries (config.R PROXY_R2, PROXY_KB):
# the proxy's effect onto its own A1, then signed by r onto the instrument's A1.
# With no proxy it stays as an NA row.
prepare_outcome <- function(cfg) {
    std <- read_region_grch38(cfg, CHR, LOCUS_START, LOCUS_END) %>%
        transmute(join_pos = pos, outcome_ea = toupper(ea), outcome_oa = toupper(oa),
                  beta_raw = if (cfg$effect_type == "OR") log(as.numeric(beta)) else as.numeric(beta),
                  eaf_outcome = if (is.null(cfg$eaf_col)) NA_real_ else as.numeric(eaf),
                  p_outcome = as.numeric(p),
                  se_raw = switch(cfg$se_source,
                                  column = as.numeric(se),
                                  ci = se_from_ci(as.numeric(ci_lower), as.numeric(ci_upper)),
                                  p = se_from_p(beta_raw, p_outcome)))

    harmonised <- exposure %>%
        mutate(join_pos = pos_hg38) %>%
        left_join(std, by = "join_pos") %>%
        mutate(forward = outcome_ea == A1 & outcome_oa == A2,
               reverse = outcome_ea == A2 & outcome_oa == A1,
               beta_outcome = case_when(forward ~ beta_raw, reverse ~ -beta_raw),
               eaf_outcome = case_when(forward ~ eaf_outcome, reverse ~ 1 - eaf_outcome),
               se_outcome = se_raw,
               palindromic = (A1 == "C" & A2 == "G") | (A1 == "A" & A2 == "T")) %>%
        # one row per instrument: a matching row wins over another allele pair
        # at the same position
        filter(!is.na(beta_outcome) | !SNP %in% SNP[!is.na(beta_outcome)]) %>%
        distinct(SNP, .keep_all = TRUE)

    px <- proxies %>%
        filter(SNP %in% harmonised$SNP[is.na(harmonised$beta_outcome)]) %>%
        mutate(join_pos = as.integer(snp_field(proxy, 2)),
               proxy_a1 = snp_field(proxy, 3), proxy_a2 = snp_field(proxy, 4)) %>%
        inner_join(std, by = "join_pos") %>%
        filter((outcome_ea == proxy_a1 & outcome_oa == proxy_a2) |
                   (outcome_ea == proxy_a2 & outcome_oa == proxy_a1)) %>%
        arrange(desc(r2), kb) %>%
        distinct(SNP, .keep_all = TRUE) %>%
        transmute(SNP, proxy_used = to_panel_id(proxy), proxy_r = r, proxy_r2 = r2,
                  beta_px = sign(r) * ifelse(outcome_ea == proxy_a1, beta_raw, -beta_raw),
                  se_px = se_raw, p_px = p_outcome)
    harmonised <- harmonised %>%
        left_join(px, by = "SNP") %>%
        mutate(beta_outcome = coalesce(beta_outcome, beta_px),
               se_outcome = if_else(is.na(proxy_used), se_outcome, se_px),
               p_outcome = if_else(is.na(proxy_used), p_outcome, p_px))

    harmonised %>%
        transmute(outcome = cfg$label, SNP, chr, pos_hg38, A1, A2,
                  eaf_exposure, beta_exposure, se_exposure,
                  eaf_outcome, beta_outcome, se_outcome, p_outcome,
                  palindromic, proxy_used, proxy_r, proxy_r2,
                  n_cases = if (is.null(cfg$n_cases)) NA_integer_ else cfg$n_cases,
                  n_controls = if (is.null(cfg$n_controls)) NA_integer_ else cfg$n_controls,
                  build_used = cfg$build)
}

outcomes <- lapply(OUTCOMES, prepare_outcome)
coverage <- tibble(
    key = names(outcomes),
    outcome = sapply(outcomes, function(d) d$outcome[1]),
    build_used = sapply(outcomes, function(d) d$build_used[1]),
    n_usable = sapply(outcomes, function(d) sum(!is.na(d$beta_outcome))),
    n_proxy = sapply(outcomes, function(d) sum(!is.na(d$proxy_used)))
)

ld_full <- interval_ld_matrix(exposure$SNP)
mr_results <- lapply(outcomes, run_mr, ld_full = ld_full) %>% bind_rows()
print(as.data.frame(mr_results), row.names = FALSE, digits = 3)

write_tsv(mr_results, file.path(out_dir, "additional_indications_mr_results.tsv"))
write_tsv(bind_rows(outcomes), file.path(out_dir, "additional_indications_harmonised.tsv"))
write_tsv(coverage, file.path(out_dir, "additional_indications_coverage.tsv"))
saveRDS(ld_full, file.path(out_dir, "additional_indications_ld_matrix.rds"))
