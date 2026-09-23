## 11 - Sensitivity of the cis-NLRP3 -> CAD estimate
##
## Three analyses against the same outcome as step 05: an r2 clumping sweep, a
## single-variant Wald ratio, and leave-one-out.
## Writes results/11_mr_sensitivity/.

suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(igraph)
    library(here)
    library(MendelianRandomization)
})

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("11_mr_sensitivity")
scratch <- scratch_path("nlrp3_sweep")
dir.create(scratch, recursive = TRUE, showWarnings = FALSE)

## ---- parameters ----------------------------------------------------------------
R2_GRID           <- c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6)
COLOC_SNP         <- "1_247438293_C_T"      # rs12239046
CLUMP_KB          <- 250
HIGH_LD_THRESHOLD <- 0.95
HIGH_LD_WINDOW_KB <- 40
PROXY_R2          <- 0.9
PROXY_WINDOW_KB   <- 50
PROXY_R2_TIE      <- 0.05
FREQ_TOL          <- 0.05

PANEL_START <- as.integer(INSTRUMENT_START - 300e3)
PANEL_END   <- as.integer(INSTRUMENT_END   + 300e3)

# The CAD window must cover the whole instrument window, not just where the
# published eight happen to sit.
CAD_START <- INSTRUMENT_START
CAD_END   <- INSTRUMENT_END

## ---- one-time: panel, frequency filter, readouts --------------------------------
panel_raw <- file.path(scratch, "region_raw")
system2(plink2_bin, c("--bfile", ld_panel, "--chr", CHR,
                      "--from-bp", PANEL_START, "--to-bp", PANEL_END,
                      "--set-all-var-ids", shQuote("@_#_$1_$2"),
                      "--new-id-max-allele-len", 200, "--rm-dup", "force-first",
                      "--make-pgen", "--out", panel_raw, "--threads", 4),
        stdout = FALSE, stderr = FALSE)

prepare_readout <- function(key, panel_ids = NULL) {
    cfg <- READOUTS[[key]]
    df <- read_region(cfg, CHR, INSTRUMENT_START, INSTRUMENT_END)
    df$.chr  <- sub("^chr", "", as.character(df$chrom))
    df$SNPid <- create_SNPid_vectorized(df, chr = ".chr", pos = "pos",
                                        other_allele = "oa",
                                        effect_allele = "ea")
    df <- df %>% filter(!grepl("D|I", SNPid))
    df$.raw_eaf <- if (is.null(cfg$eaf_col)) NA_real_ else as.numeric(df$eaf)
    df <- align_ASCII_sort(df, effect_allele = "ea", other_allele = "oa",
                           beta = "beta")
    out <- df %>%
        mutate(p = if (isTRUE(cfg$neglog10_p)) 10^(-as.numeric(p)) else as.numeric(p)) %>%
        transmute(SNP = SNPid,
                  position_hg38 = as.integer(pos),
                  A1 = ea, A2 = oa,
                  A1_freq = ifelse(flipped, 1 - .raw_eaf, .raw_eaf),
                  beta = as.numeric(beta),
                  se = as.numeric(se), p = p, n = cfg$n) %>%
        filter(!is.na(beta), !is.na(se), se > 0, !is.na(p)) %>%
        distinct(SNP, .keep_all = TRUE)
    if (!is.null(panel_ids)) out <- out %>% filter(SNP %in% panel_ids)
    out
}

system2(plink2_bin, c("--pfile", panel_raw, "--freq",
                      "--out", file.path(scratch, "raw_freq"), "--threads", 4),
        stdout = FALSE, stderr = FALSE)
panel_freq <- read.table(file.path(scratch, "raw_freq.afreq"), header = TRUE,
                         comment.char = "")
names(panel_freq)[1] <- "CHROM"
panel_freq$.A1 <- vapply(strsplit(panel_freq$ID, "_", fixed = TRUE), `[`, character(1), 3)
panel_freq$freq_panel <- ifelse(panel_freq$.A1 != panel_freq$ALT,
                                1 - panel_freq$ALT_FREQS, panel_freq$ALT_FREQS)

neut_for_freq <- prepare_readout("Neutrophil_count")
freq_cmp <- inner_join(panel_freq[, c("ID", "freq_panel")],
                       neut_for_freq %>% transmute(ID = SNP, freq_gwas = A1_freq),
                       by = "ID") %>% mutate(delta = abs(freq_panel - freq_gwas))

keep_file <- file.path(scratch, "concordant.txt")
writeLines(freq_cmp %>% filter(delta <= FREQ_TOL) %>% pull(ID), keep_file)
ld_reference <- file.path(scratch, "region")
system2(plink2_bin, c("--pfile", panel_raw, "--extract", keep_file,
                      "--make-pgen", "--out", ld_reference, "--threads", 4),
        stdout = FALSE, stderr = FALSE)
panel_ids <- freq_cmp %>% filter(delta <= FREQ_TOL) %>% pull(ID)

summary_stats <- list(
    eQTLs  = prepare_readout("NLRP3_expression", panel_ids),
    CRP    = prepare_readout("CRP",              panel_ids),
    GlycA  = prepare_readout("GlycA",            panel_ids),
    neutro = prepare_readout("Neutrophil_count", panel_ids)
)
availability <- function(snp) sum(vapply(summary_stats,
                                         function(x) snp %in% x$SNP, logical(1)))

## ---- selection, parameterised on the clumping threshold -------------------------
select_instruments <- function(clump_r2) {
    clumped <- lapply(names(summary_stats), function(tn)
        ld_clump_local(variants = summary_stats[[tn]], bfile = ld_reference,
                       r2 = clump_r2, kb = CLUMP_KB)$ID)
    names(clumped) <- names(summary_stats)

    friends <- lapply(names(clumped), function(tn) {
        lead <- clumped[[tn]]
        if (length(lead) == 0) return(NULL)
        res <- get_high_ld_snps(lead, reference = ld_reference,
                                r2 = HIGH_LD_THRESHOLD,
                                kb = HIGH_LD_WINDOW_KB) %>%
            select(ID_A, ID_B, UNPHASED_R2)
        rbind(res, data.frame(ID_A = lead, ID_B = lead, UNPHASED_R2 = 1))
    })
    names(friends) <- names(clumped)

    flat <- list()
    for (tn in names(friends)) {
        x <- friends[[tn]]
        if (is.null(x)) next
        bl <- x %>% group_by(ID_A) %>% group_split() %>% purrr::map(~ pull(.x, ID_B))
        for (i in seq_along(bl)) flat[[sprintf("%s_LD_block%d", tn, i)]] <- bl[[i]]
    }

    block_snps  <- lapply(flat, unique)
    block_names <- names(flat)
    adj <- sapply(block_names, function(i)
        sapply(block_names, function(j)
            length(intersect(block_snps[[i]], block_snps[[j]])) > 0))
    diag(adj) <- FALSE
    membership <- components(graph_from_adjacency_matrix(adj, mode = "undirected",
                                                         diag = FALSE))$membership
    comp_list <- split(names(membership), membership)
    comp_list <- comp_list[vapply(comp_list, length, 1) > 1]

    shared <- lapply(names(comp_list), function(id) {
        b <- comp_list[[id]]
        tibble(eQTLs = any(grepl("^eQTLs", b)), CRP = any(grepl("^CRP", b)),
               GlycA = any(grepl("^GlycA", b)), neutro = any(grepl("^neutro", b)),
               LD_blocks = paste(b, collapse = ", "))
    }) %>% bind_rows() %>%
        mutate(num_traits = eQTLs + CRP + GlycA + neutro) %>% filter(num_traits >= 2)
    shared$SNPs <- vapply(seq_len(nrow(shared)), function(i) {
        bl <- str_trim(unlist(str_split(shared$LD_blocks[i], ",")))
        paste(unique(unlist(block_snps[bl])), collapse = ",")
    }, character(1))

    pick_best <- function(snps) {
        av   <- vapply(snps, availability, 1)
        best <- snps[av == max(av)]
        summary_stats$CRP %>% filter(SNP %in% best) %>% slice_min(p, n = 1, with_ties = FALSE)
    }
    instruments <- lapply(shared$SNPs, function(s) pick_best(unlist(str_split(s, ",")))) %>%
        bind_rows() %>% pull(SNP)

    need_proxy <- instruments[vapply(instruments, availability, 1) != 4]
    if (length(need_proxy) > 0) {
        hl <- get_high_ld_snps(need_proxy, reference = ld_reference,
                               r2 = PROXY_R2, kb = PROXY_WINDOW_KB)
        if (nrow(hl) > 0) {
            reps <- lapply(unique(hl$ID_A), function(s) {
                cand <- hl %>% filter(ID_A == s)
                cand$av <- vapply(cand$ID_B, availability, 1)
                cand <- cand %>% filter(av == 4)
                if (nrow(cand) == 0) return(NULL)
                cand <- cand %>% filter(UNPHASED_R2 >= max(UNPHASED_R2) - PROXY_R2_TIE)
                best <- summary_stats$CRP %>% filter(SNP %in% cand$ID_B) %>%
                    slice_min(p, n = 1, with_ties = FALSE) %>% pull(SNP)
                if (length(best) == 0) return(NULL)
                tibble(original = s, replacement = best)
            }) %>% bind_rows()
            if (nrow(reps) > 0) {
                lk <- setNames(reps$replacement, reps$original)
                instruments <- ifelse(instruments %in% names(lk), lk[instruments], instruments)
            }
        }
    }
    instruments <- unique(instruments)

    effect_matrix <- function(field) {
        lapply(names(summary_stats), function(tn)
            summary_stats[[tn]] %>% filter(SNP %in% instruments) %>% mutate(trait = tn)) %>%
            bind_rows() %>% select(SNP, trait, all_of(field)) %>%
            pivot_wider(names_from = trait, values_from = all_of(field)) %>%
            column_to_rownames("SNP") %>% drop_na() %>% as.matrix()
    }
    beta_m <- effect_matrix("beta")
    se_m   <- effect_matrix("se")[rownames(beta_m), colnames(beta_m), drop = FALSE]

    pca <- prcomp(beta_m, center = TRUE, scale. = TRUE)
    loadings <- pca$rotation[, 1]
    if (all(sign(loadings) < 0)) loadings <- -loadings
    beta_latent <- as.numeric(beta_m %*% loadings)

    idx <- match(c("eQTLs", "CRP", "GlycA", "neutro"), colnames(se_m))
    se_latent <- apply(se_m, 1, function(row) {
        w <- loadings[idx]
        sqrt((w[1]^2) * row[idx[1]]^2 +
             (w[2]*row[idx[2]] + w[3]*row[idx[3]] + w[4]*row[idx[4]])^2)
    })

    anchor <- tibble(SNP = rownames(beta_m), beta_latent, se_latent) %>%
        inner_join(summary_stats$CRP %>% select(SNP, beta_CRP = beta, se_CRP = se),
                   by = "SNP") %>% mutate(w = 1 / se_CRP^2)
    k <- coef(lm(beta_CRP ~ 0 + beta_latent, data = anchor, weights = w))[["beta_latent"]]
    score <- tibble(SNP = rownames(beta_m), beta = beta_latent * k, se = se_latent * abs(k))

    sc <- score %>% inner_join(summary_stats$eQTLs %>% select(SNP, beta_eqtl = beta), by = "SNP")
    if (cor(sc$beta, sc$beta_eqtl) < 0) score$beta <- -score$beta

    score %>%
        mutate(pos_hg38 = as.integer(vapply(strsplit(SNP, "_", fixed = TRUE), `[`, character(1), 2)),
               A1 = vapply(strsplit(SNP, "_", fixed = TRUE), `[`, character(1), 3),
               A2 = vapply(strsplit(SNP, "_", fixed = TRUE), `[`, character(1), 4),
               pc1_var_explained = summary(pca)$importance[2, 1],
               r2_threshold = clump_r2) %>%
        arrange(pos_hg38)
}

## ---- the CAD outcome: Aragam + MVP + FinnGen + All of Us ------------------------
cad_raw <- list(
    "Aragam et al." = read_region(CAD_STUDIES$aragam, CHR, CAD_START, CAD_END) %>%
        transmute(join_pos = as.integer(pos),
                  ea = toupper(ea), oa = toupper(oa),
                  b = as.numeric(beta), se = as.numeric(se)),
    # MVP reports an odds ratio with a CI; standard_error is NA
    "MVP" = read_region(CAD_STUDIES$mvp, CHR, CAD_START, CAD_END) %>%
        transmute(join_pos = as.integer(pos),
                  ea = toupper(ea), oa = toupper(oa),
                  b  = log(as.numeric(beta)),
                  se = (log(as.numeric(ci_upper)) - log(as.numeric(ci_lower))) / (2 * qnorm(0.975))),
    "FinnGen" = read_region(CAD_STUDIES$finngen, CHR, CAD_START, CAD_END) %>%
        transmute(join_pos = as.integer(pos),
                  ea = toupper(ea), oa = toupper(oa),
                  b = as.numeric(beta), se = as.numeric(se)),
    # All of Us is an extract, not genome-wide; read_region() takes its alleles
    # from SAIGE's MarkerID (see config.R).
    "All of Us" = read_region(CAD_STUDIES$allofus, CHR, CAD_START, CAD_END) %>%
        transmute(join_pos = as.integer(pos),
                  ea = toupper(ea), oa = toupper(oa),
                  b = as.numeric(beta), se = as.numeric(se))
)
for (n in names(cad_raw))
    message(sprintf("%-14s over chr%d:%d-%d: %d variants",
                    n, CHR, CAD_START, CAD_END, nrow(cad_raw[[n]])))

# Harmonise one exposure set against the four studies and meta-analyse per SNP.
# The exposure is NEGATED here: every estimate reads per one-unit LOWER
# cis-NLRP3 activity, matching Figure 3A.
cad_meta_for <- function(exposure) {
    ex <- exposure %>% transmute(SNP, join_pos = pos_hg38, A1, A2,
                                 bx = -beta, bxse = se)
    per_study <- lapply(names(cad_raw), function(label) {
        ex %>% left_join(cad_raw[[label]], by = "join_pos") %>%
            mutate(by = case_when(ea == A1 & oa == A2 ~ b,
                                  ea == A2 & oa == A1 ~ -b,
                                  TRUE ~ NA_real_)) %>%
            filter(!is.na(by), !is.na(se), se > 0) %>%
            transmute(study = label, SNP, bx, bxse, by, byse = se)
    })
    names(per_study) <- names(cad_raw)
    coverage <- vapply(per_study, nrow, 1)

    meta <- bind_rows(per_study) %>%
        group_by(SNP) %>%
        summarise(bx = first(bx), bxse = first(bxse),
                  by = sum(by / byse^2) / sum(1 / byse^2),
                  byse = sqrt(1 / sum(1 / byse^2)),
                  n_studies = n(), .groups = "drop")
    list(meta = meta, coverage = coverage, per_study = bind_rows(per_study))
}

# Correlated IVW + weighted median + Egger for one harmonised set.
mr_for <- function(meta, label, extra = list()) {
    snps <- meta$SNP
    if (length(snps) < 2) return(NULL)
    ld <- interval_ld_matrix(snps)
    mi <- mr_input(bx = meta$bx, bxse = meta$bxse, by = meta$by, byse = meta$byse,
                   snps = snps, correlation = ld[snps, snps])
    iv <- mr_ivw(mi)
    wm <- mr_median(mi, weighting = "weighted")
    eg <- if (length(snps) >= 3) mr_egger(mi) else NULL

    out <- bind_rows(
        tibble(method = "IVW", estimate = iv$Estimate, se = iv$StdError,
               ci_lower = iv$CILower, ci_upper = iv$CIUpper, p = iv$Pvalue,
               het_q = iv$Heter.Stat[1], het_p = iv$Heter.Stat[2]),
        tibble(method = "Weighted median", estimate = wm$Estimate, se = wm$StdError,
               ci_lower = wm$CILower, ci_upper = wm$CIUpper, p = wm$Pvalue,
               het_q = NA_real_, het_p = NA_real_)
    ) %>%
        mutate(label = label, n_snps = length(snps),
               egger_intercept   = if (is.null(eg)) NA_real_ else eg$Intercept,
               egger_intercept_p = if (is.null(eg)) NA_real_ else eg$Pvalue.Int,
               .before = 1)
    for (nm in names(extra)) out[[nm]] <- extra[[nm]]
    out
}

## ---- A. the r2 sweep ------------------------------------------------------------
sweep_rows <- list(); sweep_inst <- list()
for (r2 in R2_GRID) {
    ex <- select_instruments(r2)
    cm <- cad_meta_for(ex)
    res <- mr_for(cm$meta, sprintf("r2 < %.1f", r2),
                  extra = list(r2_threshold = r2,
                               pc1_var_explained = ex$pc1_var_explained[1],
                               n_selected = nrow(ex),
                               n_aragam  = unname(cm$coverage["Aragam et al."]),
                               n_mvp     = unname(cm$coverage["MVP"]),
                               n_finngen = unname(cm$coverage["FinnGen"]),
                               n_allofus = unname(cm$coverage["All of Us"])))
    sweep_rows[[length(sweep_rows) + 1]] <- res
    sweep_inst[[length(sweep_inst) + 1]] <- ex %>% mutate(r2_threshold = r2)
    message(sprintf("  r2 < %.1f : %2d selected, %2d in the meta (AoU covers %2d) | IVW OR %.3f (%.3f, %.3f) p %.3g | Egger int p %.3g",
                    r2, nrow(ex), nrow(cm$meta), unname(cm$coverage["All of Us"]),
                    exp(res$estimate[1]), exp(res$ci_lower[1]), exp(res$ci_upper[1]),
                    res$p[1], res$egger_intercept_p[1]))
}
sweep <- bind_rows(sweep_rows)
write_tsv(sweep, file.path(out_dir, "r2_sweep.tsv"))
write_tsv(bind_rows(sweep_inst), file.path(out_dir, "r2_sweep_instruments.tsv"))

## ---- the r2 = 0.1 selection must match step 00 -----------------------------------
# If these ever diverge, this panel's anchor point no longer describes the
# instruments the rest of the pipeline uses, and the figure quietly becomes a
# different analysis. Fail loudly instead.
step00 <- file.path(results_dir, "00_instrument_selection", "nlrp3_instruments.tsv")
frozen <- fread(step00, data.table = FALSE)
mine   <- sweep_inst[[which(R2_GRID == 0.1)]]
if (!setequal(frozen$SNP, mine$SNP)) {
    stop("the r2 = 0.1 selection here no longer matches ", step00,
         "\n  only step 00 : ", paste(setdiff(frozen$SNP, mine$SNP), collapse = ", "),
         "\n  only step 11 : ", paste(setdiff(mine$SNP, frozen$SNP), collapse = ", "))
}


## ---- B. the single colocalising variant -----------------------------------------
ex01 <- select_instruments(0.1)
cm01 <- cad_meta_for(ex01)
one  <- cm01$meta %>% filter(SNP == COLOC_SNP)

# Wald ratio with the first-order (NOME) standard error: the exposure is
# estimated on 4,732-575,531 people and is far more precise than the outcome,
# so the bx uncertainty is negligible. Reported anyway for transparency.
wald_beta <- one$by / one$bx
wald_se   <- abs(one$byse / one$bx)
single <- tibble(
    label = "rs12239046 only", method = "Wald ratio", n_snps = 1,
    estimate = wald_beta, se = wald_se,
    ci_lower = wald_beta - qnorm(0.975) * wald_se,
    ci_upper = wald_beta + qnorm(0.975) * wald_se,
    p = 2 * pnorm(-abs(wald_beta / wald_se)),
    bx = one$bx, bxse = one$bxse, by = one$by, byse = one$byse,
    n_studies = one$n_studies)
write_tsv(single, file.path(out_dir, "single_variant.tsv"))
message(sprintf("rs12239046 alone: OR %.3f (%.3f, %.3f)  p = %.3g   [%d studies contribute]",
                exp(single$estimate), exp(single$ci_lower), exp(single$ci_upper),
                single$p, single$n_studies))

## ---- C. leave-one-out at r2 = 0.1 -----------------------------------------------
loo <- bind_rows(
    mr_for(cm01$meta, "All instruments", extra = list(dropped = "none")),
    lapply(ex01$SNP, function(s)
        mr_for(cm01$meta %>% filter(SNP != s), sprintf("without %s", s),
               extra = list(dropped = s))) %>% bind_rows()
)
write_tsv(loo, file.path(out_dir, "leave_one_out.tsv"))
print(as.data.frame(loo %>% filter(method == "IVW") %>%
    transmute(dropped, n_snps,
              OR = sprintf("%.3f (%.3f, %.3f)", exp(estimate), exp(ci_lower), exp(ci_upper)),
              p = signif(p, 3), Q = signif(het_q, 3))), row.names = FALSE)

## ---- rsID annotation for the figures --------------------------------------------
rsid_map <- fread(rsid_map_file,
                  data.table = FALSE)
key <- function(snp) {
    p <- strsplit(snp, "_", fixed = TRUE)[[1]]
    c(sprintf("chr%s:%s:%s:%s", p[1], p[2], p[3], p[4]),
      sprintf("chr%s:%s:%s:%s", p[1], p[2], p[4], p[3]))
}
ann <- tibble(SNP = ex01$SNP, rsid = vapply(ex01$SNP, function(s) {
    hit <- rsid_map$rsid[rsid_map$variant_id %in% key(s)]
    if (length(hit)) hit[1] else NA_character_
}, character(1)))

# The mapping file misses the two rarest instruments, so fall back to the
# summary statistics' own rsID columns - the same two-source approach
# analysis/08_il1rn_positive_control.R uses.
if (any(is.na(ann$rsid))) {
    fallback <- bind_rows(lapply(
        READOUTS[c("Neutrophil_count", "CRP", "GlycA")],
        function(cfg) read_region(cfg, CHR, INSTRUMENT_START, INSTRUMENT_END) %>%
            transmute(pos_hg38 = as.integer(pos), rsid2 = as.character(rsid))
    )) %>% filter(!is.na(rsid2), grepl("^rs", rsid2)) %>% distinct(pos_hg38, .keep_all = TRUE)
    ann <- ann %>%
        mutate(pos_hg38 = as.integer(vapply(strsplit(SNP, "_", fixed = TRUE), `[`, character(1), 2))) %>%
        left_join(fallback, by = "pos_hg38") %>%
        mutate(rsid = coalesce(rsid, rsid2)) %>% select(SNP, rsid)
}
write_tsv(ann, file.path(out_dir, "instrument_rsids.tsv"))
message("\nwrote ", out_dir)
