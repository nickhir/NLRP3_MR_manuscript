## 01 - Multi-trait colocalisation at the NLRP3 locus
##
## Conditions NLRP3 expression on its lead eQTL, which lies upstream of the
## gene, with GCTA-COJO, then colocalises the in-gene signal against CRP, GlycA
## and neutrophil count with HyPrColoc, and repeats the test in the flanks
## 200 kb to 1 Mb either side. Writes results/01_colocalisation/.

suppressPackageStartupMessages(library(hyprcoloc))
source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("01_colocalisation")

# Every trait is read once over +/-1 Mb; the locus is the +/-200 kb window.
read_trait <- function(cfg) {
    read_region(cfg, CHR, FLANK_START, FLANK_END) %>%
        harmonise(cfg) %>%
        select(SNPid, chrom = chr, pos, A1, A2, beta, se, p)
}
in_locus <- function(d) filter(d, pos >= LOCUS_START, pos <= LOCUS_END)

eqtl_wide <- read_trait(READOUTS$NLRP3_expression)
eqtl <- in_locus(eqtl_wide)
biomarkers_wide <- lapply(READOUTS[c("CRP", "GlycA", "Neutrophil_count")], read_trait)
biomarkers <- lapply(biomarkers_wide, in_locus)

top_snp <- slice_min(eqtl, p, n = 1, with_ties = FALSE)
cond_snp <- top_snp$SNPid


## ---- NLRP3 expression conditioned on the lead eQTL ------------------------------
# GCTA needs a PLINK1 fileset, cut from the panel over start-end at `bfile`.
cojo_condition <- function(d, start, end, bfile) {
    system2(plink2_bin, c("--bfile", ld_panel, "--chr", CHR, "--from-bp", start,
                          "--to-bp", end, "--make-bed", "--out", bfile, "--threads", 4),
            stdout = FALSE)
    system2(plink2_bin, c("--bfile", bfile, "--freq", "--out", bfile, "--threads", 4),
            stdout = FALSE)
    afreq <- fread(paste0(bfile, ".afreq"), data.table = FALSE)
    # A1, the ASCII-first allele, is REF in this panel
    a1 <- sub("^chr[^:]+:[0-9]+:([^:]+):.*$", "\\1", afreq$ID)
    panel_freq <- tibble(SNPid = from_panel_id(afreq$ID),
                         A1_freq = ifelse(a1 != afreq$ALT, 1 - afreq$ALT_FREQS, afreq$ALT_FREQS))
    d %>%
        inner_join(panel_freq, by = "SNPid") %>%
        filter(A1_freq > 0, A1_freq < 1) %>%
        transmute(SNP = to_panel_id(SNPid), A1, A2, freq = A1_freq, b = beta, se, p,
                  N = READOUTS$NLRP3_expression$n) %>%
        write.table(paste0(bfile, ".ma"), sep = "\t", quote = FALSE, row.names = FALSE)
    writeLines(to_panel_id(cond_snp), paste0(bfile, ".cond"))
    system2(gcta_bin, c("--bfile", bfile, "--cojo-file", paste0(bfile, ".ma"),
                        "--cojo-cond", paste0(bfile, ".cond"), "--out", bfile,
                        "--thread-num", 4), stdout = FALSE)
    fread(paste0(bfile, ".cma.cojo"), data.table = FALSE) %>%
        transmute(SNPid = from_panel_id(SNP), chrom = as.integer(Chr), pos = as.integer(bp),
                  beta = bC, se = bC_se, p = pC) %>%
        filter(!is.na(beta), !is.na(se), se > 0, !is.na(p))
}

# The locus keeps a COJO run of its own, so its result does not move with the flanks.
eqtl_cond <- cojo_condition(eqtl, LOCUS_START, LOCUS_END, tempfile())


## ---- HyPrColoc -------------------------------------------------------------------
colocalise <- function(traits) {
    common <- Reduce(intersect, lapply(traits, `[[`, "SNPid"))
    aligned <- lapply(traits, function(d) d %>% filter(SNPid %in% common) %>% arrange(SNPid))
    betas <- sapply(aligned, `[[`, "beta")
    ses <- sapply(aligned, `[[`, "se")
    rownames(betas) <- rownames(ses) <- aligned[[1]]$SNPid
    hypr <- hyprcoloc(
        effect.est = betas, effect.se = ses,
        trait.names = colnames(betas), snp.id = rownames(betas),
        binary.outcomes = rep(0, ncol(betas)),
        prior.1 = HYPR_PRIOR_1, prior.c = HYPR_PRIOR_C
    )
    list(hypr = hypr, common = common, aligned = aligned)
}

locus <- colocalise(c(list(NLRP3_expression = eqtl_cond), biomarkers))
print(locus$hypr$results)


## ---- the flanks, 200 kb to 1 Mb either side --------------------------------------
# HyPrColoc gives each trait one causal variant per region, so a second shared
# signal would go unseen in the locus. The margin is the locus window itself:
# nearer in, the tail of the NLRP3 signals still makes CRP and GlycA
# "colocalise" inside GCSAML.
flank_bfile <- tempfile()
eqtl_cond_wide <- cojo_condition(eqtl_wide, FLANK_START, FLANK_END, flank_bfile)
wide <- c(list(NLRP3_expression = eqtl_cond_wide), biomarkers_wide)

# How far the instruments' LD reaches into the flanks (Methods 3.4).
ld_prefix <- tempfile()
writeLines(to_panel_id(fread(instrument_file)$SNP), paste0(ld_prefix, ".snplist"))
system2(plink2_bin, c("--bfile", flank_bfile, "--r2-unphased",
                      "--ld-snp-list", paste0(ld_prefix, ".snplist"),
                      "--ld-window-kb", ceiling((FLANK_END - FLANK_START) / 1e3),
                      "--ld-window", 999999, "--ld-window-r2", 0,
                      "--out", ld_prefix, "--threads", 4), stdout = FALSE)
instrument_r2 <- fread(paste0(ld_prefix, ".vcor"), data.table = FALSE) %>%
    group_by(SNPid = from_panel_id(ID_B)) %>%
    summarise(r2 = max(UNPHASED_R2), .groups = "drop")

FLANKS <- list(upstream = c(FLANK_START, LOCUS_START - 1L),
               downstream = c(LOCUS_END + 1L, FLANK_END))
flanks <- lapply(names(FLANKS), function(side) {
    rng <- FLANKS[[side]]
    f <- colocalise(lapply(wide, function(d) filter(d, pos >= rng[1], pos <= rng[2])))
    f$hypr$results %>%
        mutate(flank = side, start = rng[1], end = rng[2], n_variants = length(f$common),
               max_instrument_r2 = max(instrument_r2$r2[instrument_r2$SNPid %in% f$common]),
               .before = 1)
}) %>% bind_rows()
print(flanks)


## ---- write -----------------------------------------------------------------------
# Regional statistics for the Fig 2A panels; the eQTL unconditioned too.
for (k in names(locus$aligned)) {
    fwrite(locus$aligned[[k]], file.path(out_dir, sprintf("regional_%s.tsv", k)), sep = "\t")
}
fwrite(eqtl, file.path(out_dir, "regional_NLRP3_expression_unconditioned.tsv"), sep = "\t")
fwrite(locus$hypr$results, file.path(out_dir, "hyprcoloc_results.tsv"), sep = "\t")
fwrite(flanks, file.path(out_dir, "hyprcoloc_flanks.tsv"), sep = "\t")
saveRDS(list(hyprcoloc_result = locus$hypr, conditioned_on = cond_snp,
             top_eqtl = top_snp, common_snps = locus$common,
             ld_reference = ld_panel, pp_threshold = PP_THRESHOLD,
             region = c(chr = CHR, start = LOCUS_START, end = LOCUS_END),
             gene_body = c(start = GENE_START, end = GENE_END),
             datasets = locus$aligned, flanks = flanks),
        file.path(out_dir, "colocalisation.rds"))
