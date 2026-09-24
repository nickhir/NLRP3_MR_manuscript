## 07a - Genome-wide instruments for the mediators
##
## Selects instruments for SBP, ApoB and T2D, assembles the MVMR design with CAD
## effects at the same variants, and re-clumps the pooled instruments for each
## nested mediator model. Writes results/07a_mediator_instruments/.

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("07a_mediator_instruments")
MEDS <- names(MEDIATORS)

# plink2 --clump ranks on its P column and cannot break ties at P = 0, where
# the strongest ApoB variants land, so it is handed ranks built from the exact
# -log10(p) instead.
clump_ranked <- function(snps, nlog10, ...) {
    p <- rank(-nlog10, ties.method = "first") / (length(nlog10) + 1) * MED_CLUMP_P
    clumped <- ld_clump_local(data.frame(SNP = to_panel_id(snps), p = p),
                              ld_panel, MED_CLUMP_R2, MED_CLUMP_KB, ...)
    from_panel_id(clumped$ID)
}


## ---- instruments per mediator --------------------------------------------------
# Genome-wide significant variants, clumped against INTERVAL; variants the
# panel lacks drop out.
instruments <- lapply(MEDS, function(k) {
    cfg <- MEDIATORS[[k]]
    sig <- read_genome(cfg) %>%
        filter(as.numeric(p) < MED_CLUMP_P) %>%
        harmonise(cfg) %>%
        arrange(desc(nlog10))
    keep <- clump_ranked(sig$SNPid, sig$nlog10)
    sig %>% filter(SNPid %in% keep) %>% mutate(mediator = k, .before = 1)
}) %>% bind_rows()


## ---- every instrument in every mediator, and in CAD ------------------------------
# MVMR needs each instrument's association with all the exposures.
union_snps <- distinct(instruments, SNPid, chrom = chr, pos)

med_at_union <- lapply(MEDS, function(k) {
    lookup_at(MEDIATORS[[k]], union_snps) %>% transmute(SNPid, mediator = k, beta, se, eaf, n)
}) %>% bind_rows()

# SBP is in mmHg: onto an SD scale, so alpha * beta is on the per-SD scale of
# the cis-MR alpha.
sd_scales <- sapply(MEDS, function(k) {
    if (!isTRUE(MEDIATORS[[k]]$standardise_sd)) return(1)
    d <- filter(med_at_union, mediator == k)
    sd_from_se(d$se, d$eaf, d$n)
})
med_at_union <- mutate(med_at_union, beta_sd = beta / sd_scales[mediator],
                       se_sd = se / sd_scales[mediator])

# All of Us is an extract, so a variant it lacks is meta-analysed without it.
cad <- lapply(names(CAD_STUDIES), function(k) {
    lookup_at(CAD_STUDIES[[k]], union_snps) %>% transmute(SNPid, beta, se, study = k)
}) %>% bind_rows()

# Fixed effect, with Cochran's Q so the heterogeneity between studies is visible.
cad_meta <- cad %>%
    group_by(SNPid) %>%
    summarise(
        beta_cad = sum(beta / se^2) / sum(1 / se^2),
        se_cad = sqrt(1 / sum(1 / se^2)),
        n_studies = n(),
        Q = sum((beta - sum(beta / se^2) / sum(1 / se^2))^2 / se^2),
        .groups = "drop"
    ) %>%
    mutate(Q_df = n_studies - 1,
           Q_p = ifelse(Q_df > 0, pchisq(Q, Q_df, lower.tail = FALSE), NA_real_),
           I2 = ifelse(Q_df > 0, pmax(0, (Q - Q_df) / Q) * 100, NA_real_))


## ---- the MVMR design -------------------------------------------------------------
# Every exposure must be measured at every instrument.
design <- med_at_union %>%
    select(SNPid, mediator, beta_sd, se_sd) %>%
    pivot_wider(names_from = mediator, values_from = c(beta_sd, se_sd)) %>%
    inner_join(select(cad_meta, SNPid, beta_cad, se_cad, n_studies, I2), by = "SNPid") %>%
    drop_na(starts_with("beta_sd_"), starts_with("se_sd_"))

# The pooled instruments re-clumped for each nested waterfall model (SBP,
# SBP+ApoB, SBP+ApoB+T2D), the strongest association across the lists winning.
# The full design stays, so a smaller model keeps variants that another
# mediator displaces only in a larger one.
mvmr_instrument_sets <- lapply(seq_along(MEDS), function(i) {
    ins <- filter(instruments, mediator %in% MEDS[1:i], SNPid %in% design$SNPid)
    priority <- tapply(ins$nlog10, ins$SNPid, max)
    clump_ranked(names(priority), priority, extra = c("--threads", 1, "--memory", 2048))
})
names(mvmr_instrument_sets) <- sapply(seq_along(MEDS), function(i) paste(MEDS[1:i], collapse = "+"))


## ---- write -----------------------------------------------------------------------
saveRDS(mvmr_instrument_sets, file.path(out_dir, "mvmr_instrument_sets.rds"))
fwrite(instruments, file.path(out_dir, "mediator_instruments.tsv"), sep = "\t")
fwrite(med_at_union, file.path(out_dir, "mediators_at_union.tsv"), sep = "\t")
fwrite(design, file.path(out_dir, "mvmr_design.tsv"), sep = "\t")
fwrite(cad_meta, file.path(out_dir, "cad_meta_at_instruments.tsv"), sep = "\t")
saveRDS(list(sd_scales = sd_scales,
             n_instruments = table(instruments$mediator),
             clump = c(p = MED_CLUMP_P, r2 = MED_CLUMP_R2, kb = MED_CLUMP_KB),
             ld_panel = ld_panel),
        file.path(out_dir, "selection_summary.rds"))
