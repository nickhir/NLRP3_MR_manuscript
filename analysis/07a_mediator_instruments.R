## 07a - Genome-wide instruments for the mediators
##
## Selects instruments for SBP, ApoB and T2D and assembles the MVMR design
## matrix with CAD effects at the same variants.
## Writes results/07a_mediator_instruments/.

suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(here)
})

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("07a_mediator_instruments")



## ---- select instruments per mediator ---------------------------------------------
instruments <- lapply(names(MEDIATORS), function(k) {
    cfg <- MEDIATORS[[k]]
    message(sprintf("\n=== %s ===", cfg$label))

    sig <- read_significant(cfg) %>% to_common(cfg)
    message(sprintf("  %s variants at p < %g",
                    format(nrow(sig), big.mark = ","), MED_CLUMP_P))

    # Clump against INTERVAL, which names variants chr1:POS:A1:A2. Variants the
    # panel does not carry cannot be clumped and are dropped.
    sig <- sig %>% arrange(desc(nlog10))
    clumped <- ld_clump_local(
        dat = tibble(SNP = to_panel_id(sig$SNPid), p = clump_key(sig$nlog10)),
        clump_kb = MED_CLUMP_KB, clump_r2 = MED_CLUMP_R2, clump_p = MED_CLUMP_P,
        bfile = ld_panel, plink_bin = plink2_bin, verbose = FALSE
    )

    # plink2 writes "#CHROM POS ID P TOTAL ..."; the index variant is ID. Reading
    # column 1 instead yields chromosome numbers and silently zero matches.
    idcol <- intersect(c("ID", "SNP"), names(clumped))
    if (length(idcol) == 0) {
        stop("no ID/SNP column in the PLINK .clumps output; got: ",
             paste(names(clumped), collapse = ", "))
    }
    keep <- from_panel_id(as.character(clumped[[idcol[1]]]))

    out <- sig %>% filter(SNPid %in% keep) %>% mutate(mediator = k, .before = 1)
    message(sprintf("  -> %d independent instruments", nrow(out)))
    if (nrow(out) < 10) stop(sprintf("[%s] only %d instruments - too few for MVMR", k, nrow(out)))
    out
}) %>% bind_rows()


## ---- every instrument measured in every mediator -------------------------------
# MVMR requires each instrument's association with ALL exposures, not only the
# one it was selected for.
union_snps <- instruments %>% distinct(SNPid, chr, pos)
message(sprintf("\nUnion of instruments: %s variants", format(nrow(union_snps), big.mark = ",")))

message("Measuring every mediator at the union:")
med_at_union <- lapply(names(MEDIATORS), function(k) {
    cfg <- MEDIATORS[[k]]
    message(sprintf("  %s ...", cfg$label))
    d <- lookup_at(cfg, union_snps$SNPid, union_snps$chr, union_snps$pos, cfg$label)
    message(sprintf("    %s / %s variants present",
                    format(nrow(d), big.mark = ","), format(nrow(union_snps), big.mark = ",")))
    d %>% transmute(SNPid, mediator = k, beta, se, eaf, n)
}) %>% bind_rows()


## ---- standardise the traits reported in native units -------------------------------
# So that alpha * beta is unit-consistent with the cis-MR alpha, which is per SD.
sd_scales <- sapply(names(MEDIATORS), function(k) {
    cfg <- MEDIATORS[[k]]
    if (!isTRUE(cfg$standardise_sd)) return(1)
    d <- med_at_union %>% filter(mediator == k, !is.na(eaf), !is.na(n))
    s <- suppressWarnings(coloc:::sdY.est(vbeta = d$se^2, maf = pmin(d$eaf, 1 - d$eaf),
                                          n = round(median(d$n))))
    message(sprintf("%s: sdY = %.3f native units per SD", k, s))
    # A trait already on an SD scale returns ~1; scaling by that would be a
    # no-op at best and a distortion at worst, so leave it alone.
    if (s > 2) s else 1
})

med_at_union <- med_at_union %>%
    mutate(beta_sd = beta / sd_scales[mediator],
           se_sd   = se   / sd_scales[mediator])


## ---- CAD at those variants ----------------------------------------------------------
# Studies absent from disk are skipped and reported, so All of Us joins with no
# code change once its genome-wide data arrives.
available <- Filter(function(k) file.exists(CAD_STUDIES[[k]]$file), names(CAD_STUDIES))
skipped   <- setdiff(names(CAD_STUDIES), available)
if (length(skipped) > 0) {
    message(sprintf("\nCAD studies skipped (no file): %s",
                    paste(sapply(skipped, function(k) CAD_STUDIES[[k]]$label), collapse = ", ")))
}
stopifnot(length(available) >= 2)

message(sprintf("Looking up %s instruments across %d CAD studies ...",
                format(nrow(union_snps), big.mark = ","), length(available)))

cad <- lapply(available, function(k) {
    cfg <- CAD_STUDIES[[k]]
    message(sprintf("  %s ...", cfg$label))
    lookup_at(cfg, union_snps$SNPid, union_snps$chr, union_snps$pos, cfg$label) %>%
        transmute(SNPid, beta, se, study = k)
}) %>% bind_rows()

message(sprintf("  %s study-variant rows", format(nrow(cad), big.mark = ",")))


## ---- fixed-effect meta-analysis of CAD ------------------------------------------------
# Both effects are already oriented onto A1 by to_common(), so no further
# harmonisation is needed - the ASCII-sorted ID encodes the alleles.
cad_meta <- cad %>%
    group_by(SNPid) %>%
    summarise(
        beta_cad  = sum(beta / se^2) / sum(1 / se^2),
        se_cad    = sqrt(1 / sum(1 / se^2)),
        n_studies = n(),
        # Cochran's Q, so heterogeneity between studies is visible rather than
        # assumed away by the fixed-effect model.
        Q         = sum((beta - sum(beta / se^2) / sum(1 / se^2))^2 / se^2),
        .groups   = "drop"
    ) %>%
    mutate(Q_df = n_studies - 1,
           Q_p  = ifelse(Q_df > 0, pchisq(Q, Q_df, lower.tail = FALSE), NA_real_),
           I2   = ifelse(Q_df > 0, pmax(0, (Q - Q_df) / Q) * 100, NA_real_))

message(sprintf("  meta over %s variants | median I2 = %.1f%% | %.1f%% with Q p < 0.05",
                format(nrow(cad_meta), big.mark = ","),
                median(cad_meta$I2, na.rm = TRUE),
                100 * mean(cad_meta$Q_p < 0.05, na.rm = TRUE)))


## ---- MVMR design matrix ------------------------------------------------------------
design <- med_at_union %>%
    select(SNPid, mediator, beta_sd, se_sd) %>%
    pivot_wider(names_from = mediator, values_from = c(beta_sd, se_sd)) %>%
    inner_join(cad_meta %>% select(SNPid, beta_cad, se_cad, n_studies, I2), by = "SNPid")

# Every exposure must be measured at every instrument. Losses here are variants
# one GWAS simply does not carry; a large drop would mean a harmonisation
# problem rather than genuine absence.
before <- nrow(design)
design <- design %>% drop_na(starts_with("beta_sd_"), starts_with("se_sd_"))
message(sprintf("\nMVMR design: %d variants (%d dropped, not present in all three mediator GWAS)",
                nrow(design), before - nrow(design)))
stopifnot(nrow(design) >= 20)

fwrite(instruments,  file.path(out_dir, "mediator_instruments.tsv"), sep = "\t")
fwrite(med_at_union, file.path(out_dir, "mediators_at_union.tsv"), sep = "\t")
fwrite(design,   file.path(out_dir, "mvmr_design.tsv"), sep = "\t")
fwrite(cad_meta, file.path(out_dir, "cad_meta_at_instruments.tsv"), sep = "\t")
saveRDS(list(sd_scales = sd_scales,
             n_instruments = table(instruments$mediator),
             clump = c(p = MED_CLUMP_P, r2 = MED_CLUMP_R2, kb = MED_CLUMP_KB),
             ld_panel = ld_panel,
             cad_included = available, cad_skipped = skipped),
        file.path(out_dir, "selection_summary.rds"))

message("\nDone -> ", out_dir)
