## 08 - IL1RN positive control
##
## Builds cis-IL1RN instruments and an IL1Ra activity score from scratch by the
## same method used at NLRP3, then runs the MR.
## Writes results/08_il1rn_positive_control/.

suppressPackageStartupMessages({
    library(AnnotationHub)
    library(ensembldb)
    library(tidyverse)
    library(data.table)
    library(igraph)
    library(here)
    library(MendelianRandomization)
})

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("08_il1rn_positive_control")

# NOTE: do not name any variable `T` or `F` in a script that sources
# helpers.R - calculate_maf() calls system(..., ignore.stdout = T) and
# a shadowed T fails with "'ignore.stdout' must be TRUE or FALSE".
scratch <- scratch_path("il1rn_ld")
dir.create(scratch, recursive = TRUE, showWarnings = FALSE)

## ----paths--------------------------------------------------------------------
# All from config.R. IL1RN is on chromosome 2, so the readouts here are the
# chr2 eQTL release and the IL1Ra assay, not the NLRP3 set.
eqtl_file   <- il1rn_eqtl_file
ppp_il1rn   <- ppp_il1rn_assay
crp_file    <- READOUTS$CRP$file
glyca_file  <- READOUTS$GlycA$file
neutro_file <- READOUTS$Neutrophil_count$file

stopifnot(file.exists(eqtl_file), file.exists(crp_file), file.exists(glyca_file),
          file.exists(neutro_file), file.exists(rsid_map_file),
          file.exists(plink2_bin), file.exists(paste0(ld_panel, ".fam")))

## ----parameters---------------------------------------------------------------
IL1RN_ENSG <- "ENSG00000136689"
CHR        <- 2L

R2_THRESHOLD      <- 0.1        # the threshold the manuscript reports
CLUMP_KB          <- 250
CLUMP_P           <- 5e-8
HIGH_LD_THRESHOLD <- 0.95
HIGH_LD_WINDOW_KB <- 40
PROXY_R2          <- 0.9
PROXY_WINDOW_KB   <- 50
FREQ_TOL          <- 0.05       # panel vs GWAS A1 frequency

N_INTERVAL <- 4732L
N_CRP      <- 575531L
N_NEUTRO   <- 519288L
N_GLYCA    <- 434646L

## ----region-------------------------------------------------------------------
coords <- get_gene_coordinates_hg38("IL1RN")
GENE_START <- as.integer(coords$start)
GENE_END   <- as.integer(coords$stop)
LOCUS_START <- as.integer(GENE_START - 150e3)
LOCUS_END   <- as.integer(GENE_END + 150e3)

# The LD panel subset is cut wider than the analysis window, so clumping (250 kb)
# and the friend search (40 kb) are not truncated at the edges.
PANEL_START <- as.integer(LOCUS_START - 300e3)
PANEL_END   <- as.integer(LOCUS_END + 300e3)

message(sprintf("IL1RN chr%d:%d-%d | analysis window %d-%d | panel %d-%d",
                CHR, GENE_START, GENE_END, LOCUS_START, LOCUS_END,
                PANEL_START, PANEL_END))

## ----helper_readers-----------------------------------------------------------
# get_high_ld_snps() with the plink2 binary taken from config.R rather than
# hardcoded.
high_ld_snps_local <- function(index_variants, reference, ld_threshold,
                               window_kb, plink2 = plink2_bin, threads = 4) {
    snps_file <- scratch_file(fileext = ".snps")
    out_file  <- scratch_file()
    writeLines(index_variants, snps_file)

    system2(plink2, c("--pfile", reference, "--r2-unphased",
                      "--ld-snp-list", snps_file,
                      "--ld-window-r2", ld_threshold,
                      "--ld-window-kb", window_kb,
                      "--threads", threads,
                      "--out", out_file), stdout = FALSE, stderr = FALSE)

    vcor <- paste0(out_file, ".vcor")
    if (!file.exists(vcor)) {
        stop("plink2 --r2-unphased produced no output for: ",
             paste(head(index_variants), collapse = ", "))
    }
    data.table::fread(vcor, data.table = FALSE)
}

# One readout on the project's ASCII-sorted IDs, beta oriented onto A1. NOTE:
# align_ASCII_sort()'s `ld_reference` argument is deliberately NOT used.
prepare_readout <- function(path, label, chr_col, pos_col, ea_col, oa_col,
                            beta_col, se_col, p_col, n_value,
                            eaf_col = NULL, rsid_col = NULL,
                            extra_filter = NULL, panel_ids = NULL) {
    message("  ", label, " ...")
    # read_region()'s 7th positional argument is `sep`, so extra_filter must be
    # passed by name.
    df <- read_region(path, chr_col, pos_col, CHR, LOCUS_START, LOCUS_END,
                      extra_filter = extra_filter)

    df$.chr  <- sub("^chr", "", as.character(df[[chr_col]]))
    df$SNPid <- create_SNPid_vectorized(df, chr = ".chr", pos = pos_col,
                                        other_allele = oa_col, effect_allele = ea_col)
    df <- df %>% filter(!grepl("D|I", SNPid))
    df$.raw_eaf <- if (is.null(eaf_col))  NA_real_      else as.numeric(df[[eaf_col]])
    df$.rsid    <- if (is.null(rsid_col)) NA_character_ else as.character(df[[rsid_col]])

    df <- align_ASCII_sort(df, effect_allele = ea_col, other_allele = oa_col,
                           beta = beta_col, ld_reference = NULL, status = TRUE)

    out <- df %>%
        transmute(SNP = SNPid,
                  position_hg38 = as.integer(.data[[pos_col]]),
                  A1 = .data[[ea_col]], A2 = .data[[oa_col]],
                  A1_freq = ifelse(flipped, 1 - .raw_eaf, .raw_eaf),
                  beta = as.numeric(.data[[beta_col]]),
                  se   = as.numeric(.data[[se_col]]),
                  p    = as.numeric(.data[[p_col]]),
                  rsid_source = .rsid,
                  n = n_value) %>%
        filter(!is.na(beta), !is.na(se), se > 0, !is.na(p)) %>%
        distinct(SNP, .keep_all = TRUE)

    if (!is.null(panel_ids)) out <- out %>% filter(SNP %in% panel_ids)

    message("    ", nrow(out), " variants")
    out
}

## ----ld_panel_subset----------------------------------------------------------
# The INTERVAL panel names variants chr2:POS:A1:A2 and this project uses
# 2_POS_A1_A2, so the subset is rewritten with plink2's own ID template:
# $1/$2 are the ASCII-sorted alleles, which is exactly the project convention.
panel_raw <- file.path(scratch, "il1rn_region_raw")
message("Cutting the INTERVAL panel to the locus ...")
system2(plink2_bin, c("--bfile", ld_panel,
                      "--chr", CHR, "--from-bp", PANEL_START, "--to-bp", PANEL_END,
                      # shQuote is essential: system2() goes through a shell,
                      # where the unquoted '#' would comment out the rest of the
                      # command line and '$1'/'$2' would expand to nothing.
                      "--set-all-var-ids", shQuote("@_#_$1_$2"),
                      "--new-id-max-allele-len", 200,
                      "--rm-dup", "force-first",
                      "--make-pgen", "--out", panel_raw,
                      "--threads", 4), stdout = FALSE, stderr = FALSE)
stopifnot(file.exists(paste0(panel_raw, ".pgen")))

## ----frequency_concordance----------------------------------------------------
# Drop variants where the panel and the summary statistics disagree about which
# variant an ID names. See the overview for why this matters.
system2(plink2_bin, c("--pfile", panel_raw, "--freq",
                      "--out", file.path(scratch, "raw_freq"), "--threads", 4),
        stdout = FALSE, stderr = FALSE)
panel_freq <- read.table(file.path(scratch, "raw_freq.afreq"), header = TRUE,
                         comment.char = "")
names(panel_freq)[1] <- "CHROM"
panel_freq$.A1 <- vapply(strsplit(panel_freq$ID, "_", fixed = TRUE),
                         `[`, character(1), 3L)
panel_freq$freq_panel <- ifelse(panel_freq$.A1 != panel_freq$ALT,
                                1 - panel_freq$ALT_FREQS, panel_freq$ALT_FREQS)

# The neutrophil GWAS is the densest of the four over this locus.
neut_for_freq <- prepare_readout(neutro_file, "neutrophils (frequency check)",
    "hm_chrom", "hm_pos", "hm_effect_allele", "hm_other_allele", "hm_beta",
    "standard_error", "p_value", N_NEUTRO, eaf_col = "hm_effect_allele_frequency")

freq_cmp <- inner_join(panel_freq[, c("ID", "freq_panel")],
                       neut_for_freq %>% transmute(ID = SNP, freq_gwas = A1_freq),
                       by = "ID") %>%
    mutate(delta = abs(freq_panel - freq_gwas))

n_bad <- sum(freq_cmp$delta > FREQ_TOL, na.rm = TRUE)
message(sprintf("frequency check: %d variants in both, %d discordant (|df| > %.2f), %d kept",
                nrow(freq_cmp), n_bad, FREQ_TOL, nrow(freq_cmp) - n_bad))

keep_file <- file.path(scratch, "concordant.txt")
writeLines(freq_cmp %>% filter(delta <= FREQ_TOL) %>% pull(ID), keep_file)

ld_reference <- file.path(scratch, "il1rn_region")
system2(plink2_bin, c("--pfile", panel_raw, "--extract", keep_file,
                      "--make-pgen", "--out", ld_reference, "--threads", 4),
        stdout = FALSE, stderr = FALSE)
stopifnot(file.exists(paste0(ld_reference, ".pgen")))

panel_ids <- freq_cmp %>% filter(delta <= FREQ_TOL) %>% pull(ID)
panel_eaf <- panel_freq %>% transmute(SNP = ID, eaf_panel = freq_panel) %>%
    filter(SNP %in% panel_ids)

write_tsv(freq_cmp %>% filter(delta > FREQ_TOL) %>% arrange(desc(delta)),
          file.path(out_dir, "il1rn_frequency_discordant_variants.tsv"))

## ----readouts-----------------------------------------------------------------
message("Loading readouts (chr", CHR, ":", LOCUS_START, "-", LOCUS_END, "):")
eQTLs <- prepare_readout(eqtl_file, "IL1RN expression", "chr", "pos_b38",
                         "effect_allele", "other_allele", "slope", "slope_se",
                         "pval_nominal", N_INTERVAL, eaf_col = "af",
                         rsid_col = "variant_id",
                         extra_filter = sprintf('$1=="%s"', IL1RN_ENSG),
                         panel_ids = panel_ids)
CRP <- prepare_readout(crp_file, "CRP concentration", "hm_chrom", "hm_pos",
                       "hm_effect_allele", "hm_other_allele", "hm_beta",
                       "standard_error", "p_value", N_CRP, rsid_col = "hm_rsid",
                       panel_ids = panel_ids)
GlycA <- prepare_readout(glyca_file, "GlycA concentration", "chromosome",
                         "base_pair_location", "effect_allele", "other_allele",
                         "beta", "standard_error", "p_value", N_GLYCA,
                         eaf_col = "effect_allele_frequency", rsid_col = "rsid",
                         panel_ids = panel_ids)
neutro <- prepare_readout(neutro_file, "Neutrophil count", "hm_chrom", "hm_pos",
                          "hm_effect_allele", "hm_other_allele", "hm_beta",
                          "standard_error", "p_value", N_NEUTRO,
                          eaf_col = "hm_effect_allele_frequency",
                          rsid_col = "hm_rsid", panel_ids = panel_ids)

summary_stats <- list(eQTLs = eQTLs, CRP = CRP, GlycA = GlycA, neutro = neutro)
availability <- function(snp) sum(vapply(summary_stats,
                                         function(x) snp %in% x$SNP, logical(1)))

## ----step1_clumping-----------------------------------------------------------
message("\nSTEP 1  LD clumping per trait (r2 < ", R2_THRESHOLD, ")")
clumped <- list()
for (tn in names(summary_stats)) {
    cl <- ld_clump_local(dat = summary_stats[[tn]], clump_kb = CLUMP_KB,
                         clump_r2 = R2_THRESHOLD, clump_p = CLUMP_P,
                         bfile = ld_reference, plink_bin = plink2_bin,
                         verbose = FALSE)
    clumped[[tn]] <- cl$ID
    message(sprintf("  %-7s -> %d lead SNP(s)", tn, length(cl$ID)))
}
stopifnot(sum(vapply(clumped, length, 1L)) > 0)

## ----step2_high_ld_friends----------------------------------------------------
# Standard clumping is greedy and per trait, so two traits can pick different
# lead SNPs that tag the same signal. Expanding each lead into its high-LD
# neighbourhood lets those be recognised as one block.
message("STEP 2  high-LD friends (r2 > ", HIGH_LD_THRESHOLD, ", ",
        HIGH_LD_WINDOW_KB, " kb)")
friends <- lapply(names(clumped), function(tn) {
    lead <- clumped[[tn]]
    if (length(lead) == 0) return(NULL)
    res <- high_ld_snps_local(lead, reference = ld_reference,
                              ld_threshold = HIGH_LD_THRESHOLD,
                              window_kb = HIGH_LD_WINDOW_KB) %>%
        select(ID_A, ID_B, UNPHASED_R2)
    rbind(res, data.frame(ID_A = lead, ID_B = lead, UNPHASED_R2 = 1))
})
names(friends) <- names(clumped)

blocks <- sapply(names(friends), simplify = FALSE, function(tn) {
    x <- friends[[tn]]
    if (is.null(x)) return(list())
    x %>% group_by(ID_A) %>% group_split() %>%
        purrr::map(~ pull(.x, ID_B)) %>%
        purrr::set_names(paste0("LD_block", seq_along(.)))
})

flat <- list()
for (tn in names(blocks)) for (b in names(blocks[[tn]])) {
    flat[[paste0(tn, "_", b)]] <- blocks[[tn]][[b]]
}
stopifnot(length(flat) > 0)

## ----step3_shared_components--------------------------------------------------
message("STEP 3  merging blocks that share a variant")
block_snps <- lapply(flat, unique)
block_names <- names(flat)
adj <- sapply(block_names, function(i)
    sapply(block_names, function(j)
        length(intersect(block_snps[[i]], block_snps[[j]])) > 0))
diag(adj) <- FALSE
membership <- components(graph_from_adjacency_matrix(adj, mode = "undirected",
                                                     diag = FALSE))$membership

comp_list <- split(names(membership), membership)
comp_list <- comp_list[vapply(comp_list, length, 1L) > 1]
stopifnot(length(comp_list) > 0)

shared <- lapply(names(comp_list), function(id) {
    b <- comp_list[[id]]
    tibble(comp_id = as.integer(id),
           eQTLs  = any(grepl("^eQTLs",  b)),
           CRP    = any(grepl("^CRP",    b)),
           GlycA  = any(grepl("^GlycA",  b)),
           neutro = any(grepl("^neutro", b)),
           LD_blocks = paste(b, collapse = ", "))
}) %>% bind_rows() %>%
    mutate(num_traits = eQTLs + CRP + GlycA + neutro) %>%
    filter(num_traits >= 2)

message("  components spanning >= 2 traits: ", nrow(shared))
stopifnot(nrow(shared) >= 2)

shared$SNPs <- vapply(seq_len(nrow(shared)), function(i) {
    bl <- str_trim(unlist(str_split(shared$LD_blocks[i], ",")))
    paste(unique(unlist(block_snps[bl])), collapse = ",")
}, character(1))

## ----step4_representatives----------------------------------------------------
# One instrument per signal: prefer variants present in all four readouts (so
# the PCA has no missing cells), then take the lowest CRP p-value.
message("STEP 4  one representative per component")
pick_best <- function(snps) {
    av <- vapply(snps, availability, 1L)
    best <- snps[av == max(av)]
    summary_stats$CRP %>% filter(SNP %in% best) %>%
        slice_min(p, n = 1, with_ties = FALSE)
}
instruments <- lapply(shared$SNPs,
                      function(s) pick_best(unlist(str_split(s, ",")))) %>%
    bind_rows() %>% pull(SNP)

## ----step5_proxies------------------------------------------------------------
need_proxy <- instruments[vapply(instruments, availability, 1L) != 4]
proxy_log <- tibble(original = character(), replacement = character(),
                    r2 = numeric())
if (length(need_proxy) > 0) {
    message("STEP 5  proxying ", length(need_proxy), " instrument(s) missing from a readout")
    hl <- high_ld_snps_local(need_proxy, reference = ld_reference,
                             ld_threshold = PROXY_R2,
                             window_kb = PROXY_WINDOW_KB)
    if (nrow(hl) > 0) {
        reps <- lapply(unique(hl$ID_A), function(s) {
            cand <- hl %>% filter(ID_A == s) %>% arrange(desc(UNPHASED_R2))
            cand$av <- vapply(cand$ID_B, availability, 1L)
            cand <- cand %>% filter(av == 4)
            if (nrow(cand) == 0) NULL else
                tibble(original = s, replacement = cand$ID_B[1],
                       r2 = cand$UNPHASED_R2[1])
        }) %>% bind_rows()
        if (nrow(reps) > 0) {
            proxy_log <- reps
            lk <- setNames(reps$replacement, reps$original)
            instruments <- ifelse(instruments %in% names(lk), lk[instruments],
                                  instruments)
        }
    }
} else {
    message("STEP 5  every instrument present in all four readouts, no proxies needed")
}
instruments <- unique(instruments)
message("  instruments: ", length(instruments))

## ----step6_pca----------------------------------------------------------------
message("STEP 6  PCA over the 4-trait effect matrix")
effect_matrix <- function(field) {
    map_dfr(names(summary_stats), ~ summary_stats[[.x]] %>%
                filter(SNP %in% instruments) %>% mutate(trait = .x)) %>%
        select(SNP, trait, all_of(field)) %>%
        pivot_wider(names_from = trait, values_from = all_of(field)) %>%
        column_to_rownames("SNP") %>% drop_na() %>% as.matrix()
}
beta_m <- effect_matrix("beta")
se_m   <- effect_matrix("se")
se_m   <- se_m[rownames(beta_m), colnames(beta_m), drop = FALSE]
stopifnot(nrow(beta_m) >= 2, identical(dim(beta_m), dim(se_m)))

# drop_na() above removes any instrument still missing from a readout after
# proxying, so the matrix can be smaller than the candidate list. Reported
# rather than silent.
if (nrow(beta_m) < length(instruments)) {
    message(sprintf("  %d of %d candidates dropped for incomplete readout coverage: %s",
                    length(instruments) - nrow(beta_m), length(instruments),
                    paste(setdiff(instruments, rownames(beta_m)), collapse = ", ")))
}
message("  instruments entering the PCA: ", nrow(beta_m))

pca <- prcomp(beta_m, center = TRUE, scale. = TRUE)
loadings <- pca$rotation[, 1]
if (all(sign(loadings) < 0)) loadings <- -loadings
beta_latent <- as.numeric(beta_m %*% loadings)
pc1_var <- summary(pca)$importance[2, 1]

message(sprintf("  PC1 explains %.1f%% of variance", 100 * pc1_var))
message("  loadings: ",
        paste(sprintf("%s = %+.3f", names(loadings), loadings), collapse = "   "))

## ----step7_standard_errors----------------------------------------------------
# Worst case: the eQTL is an independent cohort, but CRP, GlycA and neutrophil
# count share UK Biobank participants, so their errors are taken as perfectly
# correlated. That inflates the SE and keeps inference conservative.
idx <- match(c("eQTLs", "CRP", "GlycA", "neutro"), colnames(se_m))
stopifnot(!any(is.na(idx)))
se_latent <- apply(se_m, 1, function(row) {
    w <- loadings[idx]
    var_eqtl  <- (w[1]^2) * row[idx[1]]^2
    var_blood <- (w[2] * row[idx[2]] + w[3] * row[idx[3]] + w[4] * row[idx[4]])^2
    sqrt(var_eqtl + var_blood)
})

## ----step8_crp_anchoring------------------------------------------------------
anchor <- tibble(SNP = rownames(beta_m), beta_latent, se_latent) %>%
    inner_join(summary_stats$CRP %>% select(SNP, beta_CRP = beta, se_CRP = se),
               by = "SNP") %>%
    mutate(w = 1 / se_CRP^2)
k <- coef(lm(beta_CRP ~ 0 + beta_latent, data = anchor, weights = w))[["beta_latent"]]

score <- tibble(SNP = rownames(beta_m),
                beta = beta_latent * k,
                se   = se_latent * abs(k))

# PC1's sign is arbitrary, so fix it: a higher IL1Ra activity score must mean
# higher IL1RN expression. Without this the whole score vector flips between
# runs depending on which way prcomp happens to orient PC1.
eqtl_at_instruments <- summary_stats$eQTLs %>%
    filter(SNP %in% score$SNP) %>%
    select(SNP, beta_eqtl = beta)
sign_check <- score %>% inner_join(eqtl_at_instruments, by = "SNP")
score_flipped <- cor(sign_check$beta, sign_check$beta_eqtl) < 0
if (score_flipped) {
    score$beta <- -score$beta
    k <- -k
}
message(sprintf("  scaling constant k = %.4f%s", k,
                if (score_flipped) "  (score sign flipped so higher = more IL1Ra)" else ""))

## ----rsids--------------------------------------------------------------------
variants <- tibble(SNP = rownames(beta_m)) %>%
    mutate(position_hg38 = as.integer(vapply(strsplit(SNP, "_", fixed = TRUE),
                                             `[`, character(1), 2L)),
           A1 = vapply(strsplit(SNP, "_", fixed = TRUE), `[`, character(1), 3L),
           A2 = vapply(strsplit(SNP, "_", fixed = TRUE), `[`, character(1), 4L)) %>%
    arrange(position_hg38)

rsid_map <- fread(
    cmd = sprintf("zcat %s | awk -F'\\t' 'NR==1 || $3==\"chr%d\"'",
                  shQuote(rsid_map_file), CHR),
    data.table = FALSE, showProgress = FALSE) %>%
    filter(pos %in% variants$position_hg38) %>%
    transmute(position_hg38 = as.integer(pos), rsid_map = rsid)

from_sumstats <- bind_rows(eQTLs, CRP, GlycA, neutro) %>%
    filter(SNP %in% variants$SNP, !is.na(rsid_source), grepl("^rs", rsid_source)) %>%
    distinct(SNP, rsid_source) %>%
    group_by(SNP) %>% slice_head(n = 1) %>% ungroup()

variants <- variants %>%
    left_join(rsid_map, by = "position_hg38") %>%
    left_join(from_sumstats, by = "SNP") %>%
    left_join(panel_eaf %>% rename(eaf = eaf_panel), by = "SNP") %>%
    mutate(rsid = coalesce(rsid_map, rsid_source))

disagree <- variants %>% filter(!is.na(rsid_map), !is.na(rsid_source),
                                rsid_map != rsid_source)
if (nrow(disagree) > 0) {
    print(as.data.frame(disagree), row.names = FALSE)
    stop("the rsID mapping file and the summary statistics disagree")
}
stopifnot(!any(is.na(variants$rsid)))
message(sprintf("rsIDs: %d from the mapping file, %d from the summary statistics",
                sum(!is.na(variants$rsid_map)),
                sum(is.na(variants$rsid_map) & !is.na(variants$rsid_source))))

## ----write--------------------------------------------------------------------
# Long, one row per variant x readout, all on A1. Orientation for the figure is
# applied by the plotting script, not baked in here.
readout_labels <- c(eQTLs = "IL1RN expression", CRP = "CRP concentration",
                    GlycA = "GlycA concentration", neutro = "Neutrophil count")

readout_long <- map_dfr(names(summary_stats), function(tn) {
    summary_stats[[tn]] %>%
        filter(SNP %in% variants$SNP) %>%
        transmute(SNP, readout = readout_labels[[tn]], beta, se, p)
})

effects <- bind_rows(readout_long,
                     score %>% mutate(readout = "IL1Ra activity score",
                                      p = NA_real_) %>%
                         select(SNP, readout, beta, se, p)) %>%
    left_join(variants %>% select(SNP, rsid, position_hg38, A1, A2, eaf),
              by = "SNP") %>%
    arrange(position_hg38, readout) %>%
    select(SNP, rsid, position_hg38, A1, A2, eaf, readout, beta, se, p)

instrument_table <- variants %>%
    select(SNP, rsid, position_hg38, A1, A2, eaf) %>%
    left_join(score %>% rename(beta_score = beta, se_score = se), by = "SNP") %>%
    mutate(r2_threshold = R2_THRESHOLD,
           scaling_constant_k = k,
           pc1_var_explained = pc1_var,
           score_sign_flipped = score_flipped)

loading_table <- tibble(trait = names(loadings), pc1_loading = as.numeric(loadings),
                        pc1_var_explained = pc1_var)

write_tsv(effects,          file.path(out_dir, "il1rn_instrument_effects.tsv"))
write_tsv(instrument_table, file.path(out_dir, "il1rn_instruments.tsv"))
write_tsv(loading_table,    file.path(out_dir, "il1rn_pca_loadings.tsv"))
write_tsv(proxy_log,        file.path(out_dir, "il1rn_proxy_replacements.tsv"))

message("\nwrote ", file.path(out_dir, "il1rn_instrument_effects.tsv"))
print(as.data.frame(instrument_table %>%
    transmute(rsid, SNP, eaf = round(eaf, 4),
              beta_score = round(beta_score, 5), se_score = round(se_score, 5))),
    row.names = FALSE)


## ----mr_validation------------------------------------------------------------
# The second half of the positive control, and the input to Figure 4D: does the
# score predict the protein it proxies, and does more IL1Ra activity lower risk
# of the diseases anakinra treats?

message("\n--- MR validation ---")
ld_il1rn <- interval_ld_matrix(variants$SNP)
message("LD matrix (signed, A1-oriented):")
print(round(ld_il1rn, 3))

exposure <- variants %>%
    select(SNP, rsid) %>%
    left_join(score %>% rename(beta_exposure = beta, se_exposure = se), by = "SNP") %>%
    mutate(pos = as.integer(vapply(strsplit(SNP, "_", fixed = TRUE), `[`, character(1), 2L)),
           A1 = vapply(strsplit(SNP, "_", fixed = TRUE), `[`, character(1), 3L),
           A2 = vapply(strsplit(SNP, "_", fixed = TRUE), `[`, character(1), 4L))

# one registry outcome, restricted to the instruments
read_outcome_cfg <- function(key) {
    cfg <- OUTCOMES[[key]]
    stopifnot(!is.null(cfg), identical(cfg$build, "GRCh38"))
    raw <- read_region(cfg$file, cfg$chr_col, cfg$pos_col, CHR,
                       min(exposure$pos) - 1000, max(exposure$pos) + 1000)
    harmonise_region(raw, cfg, CHR) %>%
        transmute(SNP = SNPid, beta_outcome = beta, se_outcome = se, p_outcome = p) %>%
        inner_join(exposure, by = "SNP") %>%
        mutate(outcome = cfg$label,
               n_cases = cfg$n_cases, n_controls = cfg$n_controls, binary = TRUE)
}

# UKB-PPP: GENPOS is GRCh38; the ID string carries the legacy GRCh37 position
# and must not be parsed.
read_il1ra_protein <- function() {
    regions <- sprintf("%d:%d-%d", CHR, exposure$pos, exposure$pos)
    txt <- system2(tabix_bin, c(shQuote(ppp_il1rn), regions), stdout = TRUE, stderr = FALSE)
    stopifnot(length(txt) > 0)
    df <- data.table::fread(text = paste(txt, collapse = "\n"), sep = "\t",
                            header = FALSE, colClasses = "character")
    names(df) <- c("CHROM","GENPOS","ID","ALLELE0","ALLELE1","A1FREQ","INFO","N",
                   "TEST","BETA","SE","CHISQ","LOG10P","EXTRA")
    exposure %>%
        left_join(df %>% transmute(pos = as.integer(GENPOS),
                                   ea = toupper(ALLELE1), oa = toupper(ALLELE0),
                                   eff = as.numeric(BETA), se_o = as.numeric(SE),
                                   p_o = 10^(-as.numeric(LOG10P)),
                                   n_ppp = as.integer(N)),
                  by = "pos", relationship = "one-to-many") %>%
        mutate(beta_outcome = case_when(ea == A1 & oa == A2 ~ eff,
                                        ea == A2 & oa == A1 ~ -eff,
                                        TRUE ~ NA_real_),
               se_outcome = se_o, p_outcome = p_o,
               outcome = "IL1Ra concentration",
               n_cases = NA_integer_, n_controls = NA_integer_,
               n_total = n_ppp, binary = FALSE) %>%
        filter(!is.na(beta_outcome), !is.na(se_outcome), se_outcome > 0) %>%
        distinct(SNP, .keep_all = TRUE)
}

run_mr_outcome <- function(dat) {
    ld <- ld_il1rn[dat$SNP, dat$SNP]
    mi <- mr_input(bx = dat$beta_exposure, bxse = dat$se_exposure,
                   by = dat$beta_outcome,  byse = dat$se_outcome,
                   exposure = "cis-IL1RN trait", outcome = dat$outcome[1],
                   snps = dat$SNP, correlation = ld)
    # mr_ivw()'s default switches to random effects under heterogeneity, and
    # with heterogeneous instruments the fixed and random SEs can differ widely.
    ivw <- mr_ivw(mi, correl = TRUE)
    eg  <- mr_egger(mi, correl = TRUE)
    wm  <- mr_median(mi, weighting = "weighted")
    tr  <- function(x) if (dat$binary[1]) exp(x) else x

    bind_rows(
        tibble(method = "IVW", estimate = tr(ivw$Estimate), se = ivw$StdError,
               ci_lower = tr(ivw$CILower), ci_upper = tr(ivw$CIUpper), p = ivw$Pvalue,
               egger_intercept = NA_real_, egger_intercept_p = NA_real_,
               het_stat = ivw$Heter.Stat[1], het_p = ivw$Heter.Stat[2]),
        tibble(method = "MR-Egger", estimate = tr(eg$Estimate), se = eg$StdError.Est,
               ci_lower = tr(eg$CILower.Est), ci_upper = tr(eg$CIUpper.Est),
               p = eg$Pvalue.Est, egger_intercept = eg$Intercept,
               egger_intercept_p = eg$Pvalue.Int,
               het_stat = eg$Heter.Stat[1], het_p = eg$Heter.Stat[2]),
        tibble(method = "Weighted median", estimate = tr(wm$Estimate), se = wm$StdError,
               ci_lower = tr(wm$CILower), ci_upper = tr(wm$CIUpper), p = wm$Pvalue,
               egger_intercept = NA_real_, egger_intercept_p = NA_real_,
               het_stat = NA_real_, het_p = NA_real_)
    ) %>%
        mutate(outcome = dat$outcome[1], scale = if (dat$binary[1]) "OR" else "beta",
               n_snps = nrow(dat),
               n_cases = dat$n_cases[1], n_controls = dat$n_controls[1],
               n_total = if ("n_total" %in% names(dat)) dat$n_total[1] else NA_integer_,
               .before = 1)
}

il1ra <- read_il1ra_protein()
gout  <- read_outcome_cfg("gout")
ra    <- read_outcome_cfg("ra_ishigaki")
for (d in list(il1ra, gout, ra)) {
    message(sprintf("  %-34s %d/%d instruments", d$outcome[1], nrow(d), nrow(exposure)))
    stopifnot(nrow(d) >= 3)
}

mr_results <- bind_rows(run_mr_outcome(il1ra), run_mr_outcome(gout), run_mr_outcome(ra))
mr_harmonised <- bind_rows(il1ra, gout, ra) %>%
    select(SNP, rsid, outcome, beta_exposure, se_exposure,
           beta_outcome, se_outcome, p_outcome)

write_tsv(mr_results,    file.path(out_dir, "il1rn_mr_results.tsv"))
write_tsv(mr_harmonised, file.path(out_dir, "il1rn_mr_harmonised.tsv"))
saveRDS(ld_il1rn,        file.path(out_dir, "il1rn_ld_matrix.rds"))

print(as.data.frame(mr_results %>%
    transmute(outcome = substr(outcome, 1, 26), method, scale,
              est = signif(estimate, 3),
              CI = sprintf("(%.3g, %.3g)", ci_lower, ci_upper),
              p = signif(p, 3), Q = signif(het_stat, 3))), row.names = FALSE)

## ----session_info-------------------------------------------------------------
sessionInfo()
