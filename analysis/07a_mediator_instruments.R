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


# Keep only variants below a p threshold. read_genome() leaves p as a string so
# that to_common() can recover -log10(p) exactly; as.numeric() here is only for
# the comparison. A file reporting -log10(p) needs that comparison inverted.
read_significant <- function(cfg) {
    df <- read_genome(cfg)
    if (isTRUE(cfg$neglog10_p)) {
        filter(df, as.numeric(p) > -log10(MED_CLUMP_P))
    } else {
        filter(df, as.numeric(p) < MED_CLUMP_P)
    }
}

# plink2 --clump ranks on its P column and cannot break ties at P = 0, where
# the 24 strongest ApoB variants all land.
clump_key <- function(nlog10) {
    bad <- !is.finite(nlog10)
    if (any(bad)) {
        stop(sprintf(
            "clump_key(): %d variant(s) have no finite -log10(p). A file writing the literal \"0\" or \"0.0\" loses the magnitude entirely - declare nlog10_col for it in config.R, or the clump order at that locus would be arbitrary.",
            sum(bad)
        ))
    }
    r <- rank(-nlog10, ties.method = "first")
    r / (length(r) + 1) * MED_CLUMP_P
}


## ---- select instruments per mediator ---------------------------------------------
instruments <- lapply(names(MEDIATORS), function(k) {
    cfg <- MEDIATORS[[k]]
    sig <- read_significant(cfg) %>% to_common(cfg)
    message(sprintf("%s: %s variants at p < %g", cfg$label,
                    format(nrow(sig), big.mark = ","), MED_CLUMP_P))

    # Clump against INTERVAL, which names variants chr1:POS:A1:A2. Variants the
    # panel does not carry cannot be clumped and are dropped.
    sig <- sig %>% arrange(desc(nlog10))
    clumped <- ld_clump_local(
        variants = tibble(SNP = to_panel_id(sig$SNPid), p = clump_key(sig$nlog10)),
        bfile = ld_panel, r2 = MED_CLUMP_R2, kb = MED_CLUMP_KB
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
# `chrom`/`pos` are what lookup_at() joins on, SNPid what it filters to.
union_snps <- instruments %>% distinct(SNPid, chrom = chr, pos)

med_at_union <- lapply(names(MEDIATORS), function(k) {
    cfg <- MEDIATORS[[k]]
    d <- lookup_at(cfg, union_snps)
    message(sprintf("%s at the union: %s / %s variants present", cfg$label,
                    format(nrow(d), big.mark = ","), format(nrow(union_snps), big.mark = ",")))
    d %>% transmute(SNPid, mediator = k, beta, se, eaf, n)
}) %>% bind_rows()


## ---- standardise the traits reported in native units -------------------------------
# So that alpha * beta is unit-consistent with the cis-MR alpha, which is per SD.
sd_scales <- sapply(names(MEDIATORS), function(k) {
    cfg <- MEDIATORS[[k]]
    if (!isTRUE(cfg$standardise_sd)) return(1)
    d <- med_at_union %>% filter(mediator == k, !is.na(eaf), !is.na(n))
    s <- coloc:::sdY.est(vbeta = d$se^2, maf = pmin(d$eaf, 1 - d$eaf),
                         n = round(median(d$n)))
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

cad <- lapply(available, function(k) {
    cfg <- CAD_STUDIES[[k]]
    d <- lookup_at(cfg, union_snps) %>%
        transmute(SNPid, beta, se, study = k)
    message(sprintf("%s at the union: %s variants", cfg$label,
                    format(nrow(d), big.mark = ",")))
    d
}) %>% bind_rows()


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


## ---- MVMR design matrix ------------------------------------------------------------
design <- med_at_union %>%
    select(SNPid, mediator, beta_sd, se_sd) %>%
    pivot_wider(names_from = mediator, values_from = c(beta_sd, se_sd)) %>%
    inner_join(cad_meta %>% select(SNPid, beta_cad, se_cad, n_studies, I2), by = "SNPid")

# Every exposure must be measured at every instrument. Losses here are variants
# one GWAS simply does not carry; a large drop would mean a harmonisation
# problem rather than genuine absence.
design <- design %>% drop_na(starts_with("beta_sd_"), starts_with("se_sd_"))

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
