## 05 - CAD and coronary atherosclerosis
##
## MR of the activity score against four independent CAD cohorts and their
## fixed-effect meta-analysis. Writes results/05_mr_cad/.

suppressMessages({
    library(tidyverse)
    library(here)
    library(MendelianRandomization)
})

analysis_dir <- here::here()
dataset_dir  <- file.path(analysis_dir, "datasets")
output_dir   <- file.path(analysis_dir, "results", "05_mr_cad")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# CAD_STUDIES names the file and column spelling of each cohort; helpers.R
# supplies read_region() and load_instruments().
source(file.path(analysis_dir, "config.R"))
source(file.path(analysis_dir, "helpers.R"))

# The eight cis-NLRP3 instruments and the activity score, selected on the
# INTERVAL panel by analysis/00_instrument_selection.R. Run that step first.
instrument_file <- file.path(analysis_dir, "results", "00_instrument_selection",
                             "nlrp3_instruments.tsv")
ld_panel <- paste0(
    "/rds/user/nh608/hpc-work/oxLDL/data/oxLDL_data/INTERVAL_reference/",
    "WGS_reference/ld_panels/INTERVAL_allchr.GRCh38.alpha_sorted_alleles"
)
plink2_bin <- "/rds/user/nh608/hpc-work/software/plink2/plink2"

CHR          <- 1L
REGION_START <- 247390000L
REGION_END   <- 247650000L

# ---- exposure, oriented to LOWER NLRP3 activity ---------------------------
# negate = TRUE: per one-unit DECREASE in the activity score
exposure <- load_instruments(path = instrument_file, negate = TRUE) %>%
    select(SNP, pos_hg38, A1, A2, beta_exposure, se_exposure)

harmonise <- function(std, label) {
    h <- exposure %>%
        mutate(join_pos = pos_hg38) %>%
        left_join(std, by = "join_pos") %>%
        mutate(by = case_when(ea == A1 & oa == A2 ~ b,
                              ea == A2 & oa == A1 ~ -b,
                              TRUE ~ NA_real_))
    message(sprintf("[%s] %d/8 instruments usable", label, sum(!is.na(h$by))))
    h %>% transmute(SNP, bx = beta_exposure, bxse = se_exposure, by, byse = se)
}

# ---- LD from the INTERVAL WGS panel ---------------------------------------
interval_ld <- function(snp_ids) {
    ids <- paste0("chr", gsub("_", ":", snp_ids))
    tmp <- scratch_file()
    writeLines(ids, paste0(tmp, ".extract"))
    write.table(
        data.frame(id = ids, a1 = sub("^chr[^:]+:[0-9]+:([^:]+):.*$", "\\1", ids)),
        paste0(tmp, ".ref"), sep = "\t", quote = FALSE,
        row.names = FALSE, col.names = FALSE
    )
    system2(plink2_bin, c("--bfile", ld_panel, "--extract", paste0(tmp, ".extract"),
                          "--ref-allele", "force", paste0(tmp, ".ref"), "2", "1",
                          "--make-pgen", "--out", tmp, "--threads", 2), stdout = FALSE)
    system2(plink2_bin, c("--pfile", tmp, "--r-unphased", "square", "ref-based",
                          "--out", tmp, "--threads", 2), stdout = FALSE)
    ld <- as.matrix(read.table(paste0(tmp, ".unphased.vcor1"), header = FALSE))
    v  <- gsub(":", "_", sub("^chr", "", read.table(paste0(tmp, ".unphased.vcor1.vars"))[, 1]))
    rownames(ld) <- colnames(ld) <- v
    ld[snp_ids, snp_ids]
}
ld_full <- interval_ld(exposure$SNP)

# ---- the three studies ----------------------------------------------------
aragam <- read_region(CAD_STUDIES$aragam, CHR, REGION_START, REGION_END) %>%
    transmute(join_pos = as.integer(pos),
              ea = toupper(ea), oa = toupper(oa),
              b = as.numeric(beta), se = as.numeric(se)) %>%
    harmonise("Aragam et al.")

# MVP reports an odds ratio with a confidence interval; standard_error is NA
mvp <- read_region(CAD_STUDIES$mvp, CHR, REGION_START, REGION_END) %>%
    transmute(join_pos = as.integer(pos),
              ea = toupper(ea), oa = toupper(oa),
              b  = log(as.numeric(beta)),
              se = (log(as.numeric(ci_upper)) - log(as.numeric(ci_lower))) / (2 * qnorm(0.975))) %>%
    harmonise("MVP")

# All of Us: long format, already subset to the instruments. MarkerID is
# chr:pos_OTHER/EFFECT, so the allele after the slash is SAIGE's Allele2 and
# the one BETA refers to.
finngen <- read_region(CAD_STUDIES$finngen, CHR, REGION_START, REGION_END) %>%
    transmute(join_pos = as.integer(pos),
              ea = toupper(ea), oa = toupper(oa),
              b = as.numeric(beta), se = as.numeric(se)) %>%
    harmonise("FinnGen")

aou <- read_tsv(file.path(dataset_dir, "coronary_atherosclerosis_allofus_CV_404_2.tsv"),
                show_col_types = FALSE) %>%
    mutate(across(where(is.character), ~ sub("\r$", "", .x))) %>%
    filter(phenoname == "CV_404.2") %>%
    transmute(join_pos = as.integer(POS),
              oa = toupper(sub("^.*_([ACGT]+)/[ACGT]+$", "\\1", MarkerID)),
              ea = toupper(sub("^.*_[ACGT]+/([ACGT]+)$", "\\1", MarkerID)),
              b  = as.numeric(BETA), se = as.numeric(SE)) %>%
    harmonise("All of Us")

studies <- list("Aragam et al." = aragam, "MVP" = mvp,
                "All of Us" = aou, "FinnGen" = finngen)

# ---- per-SNP fixed-effect inverse-variance meta ---------------------------
meta_of <- function(dfs) {
    bind_rows(dfs) %>%
        group_by(SNP) %>%
        summarise(bx = first(bx), bxse = first(bxse),
                  by = sum(by / byse^2) / sum(1 / byse^2),
                  byse = sqrt(1 / sum(1 / byse^2)), .groups = "drop")
}

# Not helpers.R::run_mr(): this takes bx/bxse/by/byse and emits the
# study/beta/pval schema Figure 3A reads.
run_mr_study <- function(d, label) {
    mi <- mr_input(bx = d$bx, bxse = d$bxse, by = d$by, byse = d$byse,
                   snps = d$SNP, correlation = ld_full[d$SNP, d$SNP])
    iv <- mr_ivw(mi)
    wm <- mr_median(mi, weighting = "weighted")
    bind_rows(
        tibble(study = label, method = "IVW",
               beta = iv$Estimate, se = iv$StdError,
               ci_lower = iv$CILower, ci_upper = iv$CIUpper, pval = iv$Pvalue),
        tibble(study = label, method = "Weighted Median",
               beta = wm$Estimate, se = wm$StdError,
               ci_lower = wm$CILower, ci_upper = wm$CIUpper, pval = wm$Pvalue)
    ) %>% mutate(n_snps = nrow(d))
}

meta_all <- meta_of(studies)

# sensitivity: drop the one instrument whose Finnish frequency diverges
# sharply from the INTERVAL panel
DROP <- "1_247460342_C_G"
meta_sens <- meta_of(lapply(studies, function(d) d %>% filter(SNP != DROP)))

results <- bind_rows(
    lapply(names(studies), function(n) run_mr_study(studies[[n]], n)),
    run_mr_study(meta_all,  "Meta-analysis"),
    run_mr_study(meta_sens, sprintf("Meta-analysis (excl. %s)", DROP))
)

# per-SNP data, for the beta-beta scatter
per_snp <- bind_rows(
    lapply(names(studies), function(n) studies[[n]] %>% mutate(study = n)),
    meta_all %>% mutate(study = "Meta-analysis")
) %>%
    select(study, SNP, bx, bxse, by, byse)

cat("\n=== four-study results (per 1-unit LOWER cis-NLRP3 activity) ===\n")
print(as.data.frame(results %>% transmute(
    study, method, n_snps,
    OR = sprintf("%.2f (%.2f, %.2f)", exp(beta), exp(ci_lower), exp(ci_upper)),
    p = signif(pval, 3))), row.names = FALSE)

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
write_tsv(results, file.path(output_dir, "cad_meta_studies.tsv"))
write_tsv(per_snp, file.path(output_dir, "cad_meta_studies_per_snp.tsv"))
cat(sprintf("\nwrote %s\n", file.path(output_dir, "cad_meta_studies.tsv")))
