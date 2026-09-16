## 02 - The instrument table
##
## Re-derives each instrument's effect on the four readouts from source and
## puts them on the ASCII-sorted A1. Writes results/02_instrument_table/.

suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(here)
})

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("02_instrument_table")

# negate = FALSE: this table reports the variants on their own allele, not on
# the inhibition-oriented scale the MR uses.
exposure    <- load_instruments(negate = FALSE)
instruments <- exposure$SNP


## ---- the four readouts at the eight instruments --------------------------------
message("Re-deriving readout effect sizes from source (all GRCh38):")

readouts <- lapply(names(READOUTS), function(k) {
    cfg <- READOUTS[[k]]
    message(sprintf("  %s ...", cfg$label))

    d <- read_region(cfg$file, cfg$chr_col, cfg$pos_col,
                     CHR, LOCUS_START, LOCUS_END,
                     extra_filter = cfg$extra_filter) |>
        harmonise_region(cfg, CHR) |>
        filter(SNPid %in% instruments) |>
        transmute(SNP = SNPid, trait = k, beta, se, p, n = cfg$n) |>
        arrange(match(SNP, instruments))

    found <- sum(instruments %in% d$SNP)
    message(sprintf("    %d/8 instruments recovered", found))
    if (found != 8) {
        stop(sprintf("[%s] only %d/8 instruments found at GRCh38 positions", k, found))
    }
    d
}) |> bind_rows()


## ---- cross-check the eQTL against the pre-made extract ---------------------------
# nlrp3_eqtl_interval_110kb_crosscheck.tsv is an allele-sorted copy of the raw tensorQTL
# output. Aligning the raw file must reproduce it exactly - this catches a
# silently stale or mismatched eQTL release.
extract_file <- file.path(dataset_dir, "nlrp3_eqtl_interval_110kb_crosscheck.tsv")

if (file.exists(extract_file)) {
    chk <- fread(extract_file, data.table = FALSE) |>
        transmute(SNP = paste(CHR, pos_b38, pmin(effect_allele, other_allele),
                              pmax(effect_allele, other_allele), sep = "_"),
                  beta_ref = ifelse(effect_allele < other_allele, beta, -beta),
                  se_ref = se) |>
        filter(SNP %in% instruments)

    cmp <- readouts |>
        filter(trait == "NLRP3_expression") |>
        inner_join(chk, by = "SNP")

    stopifnot(nrow(cmp) == 8,
              all(abs(cmp$beta - cmp$beta_ref) < 1e-6),
              all(abs(cmp$se   - cmp$se_ref)   < 1e-6))
    message("  eQTL agrees with the allele-sorted extract on all 8 instruments")
}


## ---- assemble and verify --------------------------------------------------------
aligned <- readouts |>
    select(SNP, trait, beta, se) |>
    pivot_wider(names_from = trait, values_from = c(beta, se)) |>
    inner_join(exposure |> select(SNP, chr, pos_hg38, pos_hg19, A1, A2,
                                  eaf_exposure, beta_exposure, se_exposure),
               by = "SNP") |>
    arrange(match(SNP, instruments))

# Once every readout is on A1, all four must agree in sign with each other and
# with the activity score. Using the unaligned S4 betas instead, no SNP reaches
# 4/4 - so this is a real test rather than a tautology.
sign_agreement <- rowSums(
    sign(as.matrix(aligned[, paste0("beta_", names(READOUTS))])) ==
        sign(aligned$beta_exposure)
)
message(sprintf("\nSign agreement with the activity score: %s",
                paste(sprintf("%d/4", sign_agreement), collapse = " ")))

if (any(sign_agreement != length(READOUTS))) {
    stop(sprintf("allele alignment failed at: %s",
                 paste(aligned$SNP[sign_agreement != length(READOUTS)],
                       collapse = ", ")))
}


## ---- write -----------------------------------------------------------------------
fwrite(readouts, file.path(out_dir, "instrument_readouts_long.tsv"), sep = "\t")
fwrite(aligned,  file.path(out_dir, "instrument_table_aligned.tsv"), sep = "\t")

message("\nDone -> ", out_dir)
