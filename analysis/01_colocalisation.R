## 01 - Multi-trait colocalisation at the NLRP3 locus
##
## Conditions NLRP3 expression on the upstream lead eQTL with GCTA-COJO, then
## colocalises the in-gene signal against CRP, GlycA and neutrophil count, and
## repeats the test in the flanks 200 kb to 1 Mb either side of NLRP3.
## Writes results/01_colocalisation/.

suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(here)
    library(hyprcoloc)
})

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir  <- step_dir("01_colocalisation")

# Every trait is read once over +/-1 Mb. Sections 2-5 work on the +/-200 kb
# window cut from it; section 6 tests the flanks outside that window.
in_locus <- function(d) filter(d, pos >= LOCUS_START, pos <= LOCUS_END)


## ---- 1. NLRP3 expression over the locus --------------------------------------
cfg       <- READOUTS$NLRP3_expression
eqtl_wide <- read_region(cfg, CHR, FLANK_START, FLANK_END) %>%
    harmonise_region(cfg, CHR)
eqtl      <- in_locus(eqtl_wide)

message(sprintf("NLRP3 expression (INTERVAL, GRCh38): %d variants, %d in the locus",
                nrow(eqtl_wide), nrow(eqtl)))


## ---- 2. identify the variant to condition on ----------------------------------
# The top NLRP3 expression association in the locus.
top_snp <- eqtl %>% slice_min(p, n = 1, with_ties = FALSE)
in_gene <- top_snp$pos >= GENE_START & top_snp$pos <= GENE_END

# If the top variant were inside the gene, conditioning on it would remove the
# very cluster this analysis isolates. Stop rather than silently invert intent.
if (in_gene) {
    stop(sprintf(paste0("top eQTL variant %s lies inside the NLRP3 gene body; ",
                        "conditioning on it would remove the in-gene cluster ",
                        "rather than isolate it."), top_snp$SNPid))
}
cond_snp <- top_snp$SNPid


## ---- 3. GCTA-COJO conditional analysis -----------------------------------------
# GCTA needs a PLINK1 fileset, so the window is cut out of the genome-wide panel
# first. Variant IDs are translated to the panel's convention and back. A
# function, because section 6 conditions on cond_snp over the full +/-1 Mb too;
# the locus keeps its own run, so its result does not move with the flanks.
work_dir <- scratch_path("nlrp3_cojo")
dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)

cojo_condition <- function(d, start, end, tag) {
    region_bfile <- file.path(work_dir, paste0("interval_nlrp3_", tag))

    system2(plink2_bin, c("--bfile", ld_panel, "--chr", CHR,
                          "--from-bp", start, "--to-bp", end,
                          "--make-bed", "--out", region_bfile,
                          "--threads", 4), stdout = FALSE)

    afreq_prefix <- paste0(region_bfile, "_freq")
    system2(plink2_bin, c("--bfile", region_bfile, "--freq",
                          "--out", afreq_prefix, "--threads", 4), stdout = FALSE)

    afreq <- fread(paste0(afreq_prefix, ".afreq"), data.table = FALSE)
    names(afreq)[names(afreq) == "#CHROM"] <- "CHROM"

    # A1 is the ASCII-first allele, stored as REF in this alpha-sorted panel, so
    # the A1 frequency is 1 - ALT_FREQS wherever A1 != ALT.
    panel_freq <- afreq %>%
        transmute(SNPid    = from_panel_id(ID),
                  panel_a1 = sub("^chr[^:]+:[0-9]+:([^:]+):.*$", "\\1", ID),
                  A1_freq  = ifelse(panel_a1 != ALT, 1 - ALT_FREQS, ALT_FREQS)) %>%
        select(SNPid, A1_freq)

    cojo_input <- d %>%
        inner_join(panel_freq, by = "SNPid") %>%
        filter(!is.na(A1_freq), A1_freq > 0, A1_freq < 1) %>%
        transmute(SNP = to_panel_id(SNPid), A1, A2, freq = A1_freq,
                  b = beta, se = se, p = p, N = READOUTS$NLRP3_expression$n)

    ma_path   <- paste0(region_bfile, ".ma")
    cond_path <- paste0(region_bfile, "_cond.snplist")
    cojo_out  <- paste0(region_bfile, "_cond")

    write.table(cojo_input, ma_path, sep = "\t", quote = FALSE, row.names = FALSE)
    writeLines(to_panel_id(cond_snp), cond_path)

    system2(gcta_bin, c("--bfile", region_bfile, "--cojo-file", ma_path,
                        "--cojo-cond", cond_path, "--out", cojo_out,
                        "--thread-num", 4), stdout = FALSE)

    fread(paste0(cojo_out, ".cma.cojo"), data.table = FALSE) %>%
        transmute(SNPid = from_panel_id(SNP), chrom = as.integer(Chr),
                  pos = as.integer(bp), beta = bC, se = bC_se, p = pC) %>%
        filter(!is.na(beta), !is.na(se), se > 0, !is.na(p))
}

eqtl_cond <- cojo_condition(eqtl, LOCUS_START, LOCUS_END, "locus")


## ---- 4. the three biomarkers, unconditioned -------------------------------------
biomarkers_wide <- lapply(c("CRP", "GlycA", "Neutrophil_count"), function(k) {
    cfg <- READOUTS[[k]]
    d <- read_region(cfg, CHR, FLANK_START, FLANK_END) %>%
        harmonise_region(cfg, CHR)
    message(sprintf("%s (GRCh38, unconditioned): %d variants, %d in the locus",
                    cfg$label, nrow(d), nrow(in_locus(d))))
    d
})
names(biomarkers_wide) <- c("CRP", "GlycA", "Neutrophil_count")
biomarkers <- lapply(biomarkers_wide, in_locus)


## ---- 5. harmonise and run HyPrColoc ----------------------------------------------
# A function, because section 6 runs the same test on the flanks.
colocalise <- function(traits) {
    common <- Reduce(intersect, lapply(traits, function(d) d$SNPid))

    aligned <- lapply(traits, function(d) d %>% filter(SNPid %in% common) %>% arrange(SNPid))

    betas <- do.call(cbind, lapply(aligned, function(d) d$beta))
    ses   <- do.call(cbind, lapply(aligned, function(d) d$se))
    colnames(betas) <- colnames(ses) <- names(traits)
    rownames(betas) <- rownames(ses) <- aligned[[1]]$SNPid

    hypr <- hyprcoloc(
        effect.est = betas, effect.se = ses,
        trait.names = colnames(betas), snp.id = rownames(betas),
        binary.outcomes = rep(0, ncol(betas)),
        prior.1 = HYPR_PRIOR_1, prior.c = HYPR_PRIOR_C
    )
    list(hypr = hypr, common = common, aligned = aligned)
}

locus   <- colocalise(c(list(NLRP3_expression = eqtl_cond), biomarkers))
hypr    <- locus$hypr
common  <- locus$common
aligned <- locus$aligned
print(hypr$results)

pp <- as.numeric(hypr$results$posterior_prob[1])
if (!is.na(pp)) {
    message(sprintf("\n  PP = %.3f | candidate SNP = %s | traits = %s\n  %s (threshold %.1f)",
                    pp, hypr$results$candidate_snp[1], hypr$results$traits[1],
                    ifelse(pp > PP_THRESHOLD,
                           "STRONG evidence the traits share a causal variant",
                           "not strong evidence at the stated threshold"),
                    PP_THRESHOLD))
}


## ---- 6. the flanks, 200 kb to 1 Mb either side ----------------------------------
# HyPrColoc gives each trait one causal variant per region, so the locus can only
# ever report its lead signal, and a second shared signal would go unseen. The
# flanks are tested on their own, with the same inputs and priors. The margin is
# the locus window itself: nearer in, the tail of the NLRP3 signals still makes
# CRP and GlycA "colocalise" inside GCSAML, 78 kb downstream of the gene.
eqtl_cond_wide <- cojo_condition(eqtl_wide, FLANK_START, FLANK_END, "flanks")
wide <- c(list(NLRP3_expression = eqtl_cond_wide), biomarkers_wide)

# How far the instruments' LD reaches into the flanks - the r2 Methods 3.4
# cites - from the +/-1 Mb fileset cojo_condition() has just cut.
ld_prefix <- file.path(work_dir, "instrument_ld")
writeLines(to_panel_id(fread(instrument_file, data.table = FALSE)$SNP),
           paste0(ld_prefix, ".snplist"))
system2(plink2_bin, c("--bfile", file.path(work_dir, "interval_nlrp3_flanks"),
                      "--r2-unphased", "--ld-snp-list", paste0(ld_prefix, ".snplist"),
                      "--ld-window-kb", ceiling((FLANK_END - FLANK_START) / 1e3),
                      "--ld-window", 999999, "--ld-window-r2", 0,
                      "--out", ld_prefix, "--threads", 4), stdout = FALSE)
instrument_r2 <- fread(paste0(ld_prefix, ".vcor"), data.table = FALSE) %>%
    group_by(SNPid = from_panel_id(ID_B)) %>%
    summarise(r2 = max(UNPHASED_R2), .groups = "drop")

FLANKS <- list(upstream   = c(FLANK_START, LOCUS_START - 1L),
               downstream = c(LOCUS_END + 1L, FLANK_END))

flanks <- lapply(names(FLANKS), function(side) {
    rng    <- FLANKS[[side]]
    f      <- colocalise(lapply(wide, function(d) filter(d, pos >= rng[1], pos <= rng[2])))
    res    <- f$hypr$results
    hit    <- !is.na(res$posterior_prob)
    max_r2 <- max(instrument_r2$r2[instrument_r2$SNPid %in% f$common])

    message(sprintf("%s flank (%d-%d, %d variants, instrument r2 <= %.3f): %s",
                    side, rng[1], rng[2], length(f$common), max_r2,
                    if (any(hit)) {
                        paste(sprintf("%s, PP = %.3f", res$traits[hit],
                                      res$posterior_prob[hit]), collapse = "; ")
                    } else {
                        sprintf("no colocalisation (regional PP <= %.3f)",
                                max(res$regional_prob, na.rm = TRUE))
                    }))

    res %>% mutate(flank = side, start = rng[1], end = rng[2],
                   n_variants = length(f$common), max_instrument_r2 = max_r2,
                   .before = 1)
}) %>% bind_rows()


## ---- 7. write results --------------------------------------------------------------
# Regional statistics for all four traits, for the Fig 2A locuszoom panels.
lapply(names(aligned), function(k) {
    fwrite(aligned[[k]], file.path(out_dir, sprintf("regional_%s.tsv", k)), sep = "\t")
})
# Unconditioned eQTL too, so the locuszoom can show both signals.
fwrite(eqtl, file.path(out_dir, "regional_NLRP3_expression_unconditioned.tsv"), sep = "\t")

fwrite(hypr$results, file.path(out_dir, "hyprcoloc_results.tsv"), sep = "\t")
fwrite(flanks, file.path(out_dir, "hyprcoloc_flanks.tsv"), sep = "\t")
saveRDS(list(hyprcoloc_result = hypr, conditioned_on = cond_snp,
             top_eqtl = top_snp, common_snps = common,
             ld_reference = ld_panel, pp_threshold = PP_THRESHOLD,
             region = c(chr = CHR, start = LOCUS_START, end = LOCUS_END),
             gene_body = c(start = GENE_START, end = GENE_END),
             datasets = aligned, flanks = flanks),
        file.path(out_dir, "colocalisation.rds"))

message("\nDone -> ", out_dir)
