## 11 - Sensitivity of the cis-NLRP3 -> CAD estimate
##
## Against the CAD meta-analysis of step 05: instruments re-selected at LD
## clumping thresholds r2 < 0.1 to 0.6, the single colocalising variant (Wald
## ratio), and leave-one-out. Writes results/11_mr_sensitivity/.

suppressPackageStartupMessages(library(MendelianRandomization))
source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("11_mr_sensitivity")
COLOC_SNP <- "1_247438293_C_T" # rs12239046

cad <- lapply(CAD_STUDIES, read_cad)
names(cad) <- sapply(CAD_STUDIES, `[[`, "label")

# The four studies at an instrument set, meta-analysed per variant. The score
# is negated: per one-unit LOWER activity, as in Figure 3A.
cad_meta_for <- function(ex) {
    ex <- transmute(ex, SNP, pos_hg38, A1, A2, bx = -beta, bxse = se)
    per_study <- lapply(cad, cad_at, ex = ex)
    list(meta = meta_snp(bind_rows(per_study)), coverage = sapply(per_study, nrow))
}

# Correlated IVW, weighted median and the MR-Egger intercept.
mr_for <- function(meta, label) {
    mi <- mr_input(bx = meta$bx, bxse = meta$bxse, by = meta$by, byse = meta$byse,
                   snps = meta$SNP, correlation = interval_ld_matrix(meta$SNP))
    iv <- mr_ivw(mi)
    wm <- mr_median(mi, weighting = "weighted")
    eg <- mr_egger(mi)
    tibble(label = label, n_snps = nrow(meta),
           egger_intercept = eg$Intercept, egger_intercept_p = eg$Pvalue.Int,
           method = c("IVW", "Weighted median"),
           estimate = c(iv$Estimate, wm$Estimate), se = c(iv$StdError, wm$StdError),
           ci_lower = c(iv$CILower, wm$CILower), ci_upper = c(iv$CIUpper, wm$CIUpper),
           p = c(iv$Pvalue, wm$Pvalue),
           het_q = c(iv$Heter.Stat[1], NA), het_p = c(iv$Heter.Stat[2], NA))
}


## ---- A. the r2 sweep ------------------------------------------------------------
sweep <- lapply(c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6), function(r2) {
    sel <- select_instruments(READOUTS, CHR, INSTRUMENT_START, INSTRUMENT_END, r2)
    ex <- sel$score %>%
        mutate(pos_hg38 = as.integer(snp_field(SNP, 2)), A1 = snp_field(SNP, 3),
               A2 = snp_field(SNP, 4), pc1_var_explained = sel$pc1_var, r2_threshold = r2) %>%
        arrange(pos_hg38)
    cm <- cad_meta_for(ex)
    res <- mr_for(cm$meta, sprintf("r2 < %.1f", r2)) %>%
        mutate(r2_threshold = r2, pc1_var_explained = sel$pc1_var, n_selected = nrow(ex),
               n_aragam = cm$coverage[["Aragam et al."]], n_mvp = cm$coverage[["MVP"]],
               n_finngen = cm$coverage[["FinnGen"]], n_allofus = cm$coverage[["All of Us"]])
    list(ex = ex, meta = cm$meta, res = res,
         spec = mutate(sel$specificity, r2_threshold = r2))
})
write_tsv(map_dfr(sweep, "res"), file.path(out_dir, "r2_sweep.tsv"))
write_tsv(map_dfr(sweep, "ex"), file.path(out_dir, "r2_sweep_instruments.tsv"))
write_tsv(map_dfr(sweep, "spec"), file.path(out_dir, "r2_sweep_specificity.tsv"))
print(as.data.frame(map_dfr(sweep, "res") %>%
    filter(method == "IVW") %>%
    transmute(label, n_snps, OR = exp(estimate), p, egger_intercept_p)), row.names = FALSE, digits = 3)

# At r2 < 0.1 these are the instruments of step 00.
ex01 <- sweep[[1]]$ex
meta01 <- sweep[[1]]$meta


## ---- B. the single colocalising variant -----------------------------------------
# Wald ratio with the first-order SE: the exposure is estimated on 4,732 to
# 575,531 people and is far more precise than the outcome.
one <- filter(meta01, SNP == COLOC_SNP)
wald_beta <- one$by / one$bx
wald_se <- abs(one$byse / one$bx)
single <- tibble(
    label = "rs12239046 only", method = "Wald ratio", n_snps = 1,
    estimate = wald_beta, se = wald_se,
    ci_lower = wald_beta - qnorm(0.975) * wald_se,
    ci_upper = wald_beta + qnorm(0.975) * wald_se,
    p = 2 * pnorm(-abs(wald_beta / wald_se)),
    bx = one$bx, bxse = one$bxse, by = one$by, byse = one$byse,
    n_studies = one$n_studies)
write_tsv(single, file.path(out_dir, "single_variant.tsv"))


## ---- C. leave-one-out -------------------------------------------------------------
loo <- bind_rows(
    mutate(mr_for(meta01, "All instruments"), dropped = "none"),
    lapply(ex01$SNP, function(s) {
        mutate(mr_for(filter(meta01, SNP != s), sprintf("without %s", s)), dropped = s)
    })
)
write_tsv(loo, file.path(out_dir, "leave_one_out.tsv"))


## ---- rsIDs for the figures -----------------------------------------------------------
# From the mapping file, by variant in either allele order; it misses the two
# rarest instruments, which take the readouts' own rsID columns by position.
rsid_map <- fread(rsid_map_file, data.table = FALSE)
fallback <- lapply(READOUTS[c("Neutrophil_count", "CRP", "GlycA")], function(cfg) {
    read_region(cfg, CHR, INSTRUMENT_START, INSTRUMENT_END) %>% transmute(pos_hg38 = pos, rsid2 = rsid)
}) %>%
    bind_rows() %>%
    filter(grepl("^rs", rsid2)) %>%
    distinct(pos_hg38, .keep_all = TRUE)
ann <- ex01 %>%
    transmute(SNP, pos_hg38, rsid = sapply(SNP, function(s) {
        f <- strsplit(s, "_")[[1]]
        ids <- sprintf("chr%s:%s:%s:%s", f[1], f[2], c(f[3], f[4]), c(f[4], f[3]))
        rsid_map$rsid[rsid_map$variant_id %in% ids][1]
    })) %>%
    left_join(fallback, by = "pos_hg38") %>%
    transmute(SNP, rsid = coalesce(rsid, rsid2))
write_tsv(ann, file.path(out_dir, "instrument_rsids.tsv"))
