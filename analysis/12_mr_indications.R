## 12 - Additional indications
##
## MR of the activity score against the imaging traits and the candidate
## indications in the OUTCOMES registry. Writes results/12_mr_indications/.

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("12_mr_indications")

exposure <- load_instruments()

# One outcome at the instruments, joined on position (a GRCh37 release on the
# instruments' GRCh37 positions) and turned onto A1. An instrument the release
# lacks stays as an NA row, unless the registry names an LD proxy for it.
prepare_outcome <- function(cfg) {
    std <- read_region(cfg, CHR, LOCUS_START, LOCUS_END) %>%
        transmute(join_pos = pos, outcome_ea = toupper(ea), outcome_oa = toupper(oa),
                  beta_raw = if (cfg$effect_type == "OR") log(as.numeric(beta)) else as.numeric(beta),
                  eaf_outcome = if (is.null(cfg$eaf_col)) NA_real_ else as.numeric(eaf),
                  p_outcome = as.numeric(p),
                  se_raw = switch(cfg$se_source,
                                  column = as.numeric(se),
                                  ci = se_from_ci(as.numeric(ci_lower), as.numeric(ci_upper)),
                                  p = se_from_p(beta_raw, p_outcome)))

    harmonised <- exposure %>%
        mutate(join_pos = if (cfg$build == "GRCh37") pos_hg19 else pos_hg38) %>%
        left_join(std, by = "join_pos") %>%
        mutate(forward = outcome_ea == A1 & outcome_oa == A2,
               reverse = outcome_ea == A2 & outcome_oa == A1,
               beta_outcome = case_when(forward ~ beta_raw, reverse ~ -beta_raw),
               eaf_outcome = case_when(forward ~ eaf_outcome, reverse ~ 1 - eaf_outcome),
               se_outcome = se_raw,
               palindromic = (A1 == "C" & A2 == "G") | (A1 == "A" & A2 == "T"),
               proxy_used = NA_character_, proxy_r = NA_real_, proxy_r2 = NA_real_)

    if (!is.null(cfg$proxies)) {
        # the proxy's effect onto its A1, then signed by r onto the instrument's A1
        px <- cfg$proxies %>%
            inner_join(std, by = c(proxy_pos = "join_pos")) %>%
            mutate(forward = outcome_ea == proxy_a1 & outcome_oa == proxy_a2) %>%
            transmute(SNP, beta_px = sign(r) * ifelse(forward, beta_raw, -beta_raw),
                      se_px = se_raw, p_px = p_outcome,
                      label_px = sprintf("chr1:%s:%s:%s", proxy_pos, proxy_a1, proxy_a2),
                      r_px = r, r2_px = r^2)
        harmonised <- harmonised %>%
            left_join(px, by = "SNP") %>%
            mutate(use_px = is.na(beta_outcome) & !is.na(beta_px),
                   proxy_used = ifelse(use_px, label_px, proxy_used),
                   proxy_r = ifelse(use_px, r_px, proxy_r),
                   proxy_r2 = ifelse(use_px, r2_px, proxy_r2),
                   beta_outcome = ifelse(use_px, beta_px, beta_outcome),
                   se_outcome = ifelse(use_px, se_px, se_outcome),
                   p_outcome = ifelse(use_px, p_px, p_outcome))
    }

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
    n_usable = sapply(outcomes, function(d) sum(!is.na(d$beta_outcome)))
)

ld_full <- interval_ld_matrix(exposure$SNP)
mr_results <- lapply(outcomes, run_mr, ld_full = ld_full) %>% bind_rows()
print(as.data.frame(mr_results), row.names = FALSE, digits = 3)

write_tsv(mr_results, file.path(out_dir, "additional_indications_mr_results.tsv"))
write_tsv(bind_rows(outcomes), file.path(out_dir, "additional_indications_harmonised.tsv"))
write_tsv(coverage, file.path(out_dir, "additional_indications_coverage.tsv"))
saveRDS(ld_full, file.path(out_dir, "additional_indications_ld_matrix.rds"))
