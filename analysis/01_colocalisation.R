## 01 - Multi-trait colocalisation at the NLRP3 locus
##
## Conditions NLRP3 expression on the upstream lead eQTL with GCTA-COJO, then
## colocalises the in-gene signal against CRP, GlycA and neutrophil count.
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
exposure <- load_instruments()


## ---- 1. NLRP3 expression over the locus --------------------------------------
message("Loading NLRP3 expression (INTERVAL, GRCh38) ...")

cfg  <- READOUTS$NLRP3_expression
eqtl <- read_region(cfg$file, cfg$chr_col, cfg$pos_col,
                    CHR, LOCUS_START, LOCUS_END,
                    extra_filter = cfg$extra_filter) |>
    harmonise_region(cfg, CHR)

message(sprintf("  %d variants", nrow(eqtl)))


## ---- 2. identify the variant to condition on ----------------------------------
# The top NLRP3 expression association in the locus.
top_snp <- eqtl |> slice_min(p, n = 1, with_ties = FALSE)
in_gene <- top_snp$pos >= GENE_START & top_snp$pos <= GENE_END

message(sprintf("\nTop NLRP3 expression variant: %s (pos %d, p = %.2e)",
                top_snp$SNPid, top_snp$pos, top_snp$p))
message(sprintf("  location: %s the gene body (%d-%d)",
                ifelse(in_gene, "INSIDE", "outside"), GENE_START, GENE_END))

# If the top variant were inside the gene, conditioning on it would remove the
# very cluster this analysis isolates. Stop rather than silently invert intent.
if (in_gene) {
    stop(sprintf(paste0("top eQTL variant %s lies inside the NLRP3 gene body; ",
                        "conditioning on it would remove the in-gene cluster ",
                        "rather than isolate it."), top_snp$SNPid))
}
cond_snp <- top_snp$SNPid


## ---- 3. GCTA-COJO conditional analysis -----------------------------------------
# GCTA needs a PLINK1 fileset, so the locus is cut out of the genome-wide panel
# first. Variant IDs are translated to the panel's convention and back.
work_dir     <- scratch_path("nlrp3_cojo")
dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)
region_bfile <- file.path(work_dir, "interval_nlrp3_region")

message("\nCutting the locus out of the INTERVAL panel ...")
system2(plink2_bin, c("--bfile", ld_panel, "--chr", CHR,
                      "--from-bp", LOCUS_START, "--to-bp", LOCUS_END,
                      "--make-bed", "--out", region_bfile,
                      "--threads", 4), stdout = FALSE)

afreq_prefix <- file.path(work_dir, "region_freq")
system2(plink2_bin, c("--bfile", region_bfile, "--freq",
                      "--out", afreq_prefix, "--threads", 4), stdout = FALSE)

afreq <- fread(paste0(afreq_prefix, ".afreq"), data.table = FALSE)
names(afreq)[names(afreq) == "#CHROM"] <- "CHROM"

# A1 is the ASCII-first allele, stored as REF in this alpha-sorted panel, so
# the A1 frequency is 1 - ALT_FREQS wherever A1 != ALT.
panel_freq <- afreq |>
    transmute(SNPid    = from_panel_id(ID),
              panel_a1 = sub("^chr[^:]+:[0-9]+:([^:]+):.*$", "\\1", ID),
              A1_freq  = ifelse(panel_a1 != ALT, 1 - ALT_FREQS, ALT_FREQS)) |>
    select(SNPid, A1_freq)

cojo_input <- eqtl |>
    inner_join(panel_freq, by = "SNPid") |>
    filter(!is.na(A1_freq), A1_freq > 0, A1_freq < 1) |>
    transmute(SNP = to_panel_id(SNPid), A1, A2, freq = A1_freq,
              b = beta, se = se, p = p, N = READOUTS$NLRP3_expression$n)

message(sprintf("  %d eQTL variants present in the panel -> COJO input",
                nrow(cojo_input)))
stopifnot(to_panel_id(cond_snp) %in% cojo_input$SNP)

ma_path   <- file.path(work_dir, "nlrp3_eqtl.ma")
cond_path <- file.path(work_dir, "cond.snplist")
cojo_out  <- file.path(work_dir, "nlrp3_eqtl_cond")

write.table(cojo_input, ma_path, sep = "\t", quote = FALSE, row.names = FALSE)
writeLines(to_panel_id(cond_snp), cond_path)

message(sprintf("Running GCTA-COJO conditional analysis on %s ...", cond_snp))
system2(gcta_bin, c("--bfile", region_bfile, "--cojo-file", ma_path,
                    "--cojo-cond", cond_path, "--out", cojo_out,
                    "--thread-num", 4), stdout = FALSE)

cma_path <- paste0(cojo_out, ".cma.cojo")
if (!file.exists(cma_path)) {
    stop("GCTA-COJO produced no .cma.cojo output; check ", cojo_out, ".log")
}

eqtl_cond <- fread(cma_path, data.table = FALSE) |>
    transmute(SNPid = from_panel_id(SNP), chrom = as.integer(Chr),
              pos = as.integer(bp), beta = bC, se = bC_se, p = pC) |>
    filter(!is.na(beta), !is.na(se), se > 0, !is.na(p))

# The conditioning worked if the in-gene cluster survives while the upstream
# peak is flattened.
cluster  <- eqtl_cond |> filter(pos >= GENE_START, pos <= GENE_END)
upstream <- eqtl_cond |> filter(pos < GENE_START)
message(sprintf("  %d conditioned variants | min p in gene = %.2e | min p upstream = %.2e",
                nrow(eqtl_cond), min(cluster$p, na.rm = TRUE),
                min(upstream$p, na.rm = TRUE)))


## ---- 4. the three biomarkers, unconditioned -------------------------------------
message("\nLoading the biomarkers (GRCh38, unconditioned):")

biomarkers <- lapply(c("CRP", "GlycA", "Neutrophil_count"), function(k) {
    cfg <- READOUTS[[k]]
    message(sprintf("  %s ...", cfg$label))
    d <- read_region(cfg$file, cfg$chr_col, cfg$pos_col,
                     CHR, LOCUS_START, LOCUS_END) |>
        harmonise_region(cfg, CHR)
    message(sprintf("    %d variants", nrow(d)))
    d
})
names(biomarkers) <- c("CRP", "GlycA", "Neutrophil_count")


## ---- 5. harmonise and run HyPrColoc ----------------------------------------------
traits <- c(list(NLRP3_expression = eqtl_cond), biomarkers)

common <- Reduce(intersect, lapply(traits, function(d) d$SNPid))
message(sprintf("\n%d variants shared by all four traits", length(common)))
stopifnot(length(common) > 100)

aligned <- lapply(traits, function(d) d |> filter(SNPid %in% common) |> arrange(SNPid))
stopifnot(length(unique(lapply(aligned, function(d) d$SNPid))) == 1L)

betas <- do.call(cbind, lapply(aligned, function(d) d$beta))
ses   <- do.call(cbind, lapply(aligned, function(d) d$se))
colnames(betas) <- colnames(ses) <- names(traits)
rownames(betas) <- rownames(ses) <- aligned[[1]]$SNPid

message("Running HyPrColoc ...")
hypr <- hyprcoloc(
    effect.est = betas, effect.se = ses,
    trait.names = colnames(betas), snp.id = rownames(betas),
    binary.outcomes = rep(0, ncol(betas)),
    prior.1 = HYPR_PRIOR_1, prior.c = HYPR_PRIOR_C
)
print(hypr$results)

pp <- suppressWarnings(as.numeric(hypr$results$posterior_prob[1]))
if (!is.na(pp)) {
    message(sprintf("\n  PP = %.3f | candidate SNP = %s | traits = %s\n  %s (threshold %.1f)",
                    pp, hypr$results$candidate_snp[1], hypr$results$traits[1],
                    ifelse(pp > PP_THRESHOLD,
                           "STRONG evidence the traits share a causal variant",
                           "not strong evidence at the stated threshold"),
                    PP_THRESHOLD))
}


## ---- 6. write results --------------------------------------------------------------
# Regional statistics for all four traits, for the Fig 2A locuszoom panels.
lapply(names(aligned), function(k) {
    fwrite(aligned[[k]], file.path(out_dir, sprintf("regional_%s.tsv", k)), sep = "\t")
})
# Unconditioned eQTL too, so the locuszoom can show both signals.
fwrite(eqtl, file.path(out_dir, "regional_NLRP3_expression_unconditioned.tsv"), sep = "\t")

fwrite(hypr$results, file.path(out_dir, "hyprcoloc_results.tsv"), sep = "\t")
saveRDS(list(hyprcoloc_result = hypr, conditioned_on = cond_snp,
             top_eqtl = top_snp, common_snps = common,
             ld_reference = ld_panel, pp_threshold = PP_THRESHOLD,
             region = c(chr = CHR, start = LOCUS_START, end = LOCUS_END),
             gene_body = c(start = GENE_START, end = GENE_END),
             datasets = aligned),
        file.path(out_dir, "colocalisation.rds"))

message("\nDone -> ", out_dir)
