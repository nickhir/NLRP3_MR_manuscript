## 00 - cis-NLRP3 instrument selection
##
## Selects the eight cis-NLRP3 instruments on the INTERVAL WGS panel and
## aggregates them into an activity score by PCA over the four readouts.
## Writes results/00_instrument_selection/ - every other step reads it.

suppressPackageStartupMessages({
    library(tidyverse)
    library(igraph)
    library(here)
})

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("00_instrument_selection")
# do not name anything `T`/`F` here: calculate_maf() calls system(ignore.stdout = T)
scratch <- scratch_path("nlrp3_selection")
dir.create(scratch, recursive = TRUE, showWarnings = FALSE)


## ---- parameters ----------------------------------------------------------------
R2_THRESHOLD <- 0.1 # LD clumping, the manuscript's value
CLUMP_KB <- 250
CLUMP_P <- 5e-8
HIGH_LD_THRESHOLD <- 0.95 # "friends" of a lead variant
HIGH_LD_WINDOW_KB <- 40
PROXY_R2 <- 0.9 # a usable stand-in for a missing representative
PROXY_WINDOW_KB <- 50
PROXY_R2_TIE <- 0.05 # proxies within this r2 of the best count as tied
FREQ_TOL <- 0.05 # panel vs GWAS A1 frequency

# The window is config.R's +/-150 kb, the one Methods 3.3 specifies. The panel is
# cut wider so LD at the window edges is computed from complete flanks.
PANEL_START <- as.integer(INSTRUMENT_START - 300e3)
PANEL_END <- as.integer(INSTRUMENT_END + 300e3)

message(sprintf(
    "NLRP3 chr%d:%d-%d | window %d-%d | panel %d-%d",
    CHR,
    GENE_START,
    GENE_END,
    INSTRUMENT_START,
    INSTRUMENT_END,
    PANEL_START,
    PANEL_END
))


## ---- the panel, cut to the locus -----------------------------------------------
panel_raw <- file.path(scratch, "nlrp3_region_raw")
message("Cutting the INTERVAL panel to the locus ...")
system2(
    plink2_bin,
    c(
        "--bfile",
        ld_panel,
        "--chr",
        CHR,
        "--from-bp",
        PANEL_START,
        "--to-bp",
        PANEL_END,
        # shQuote is essential: an unquoted '#' comments out the rest
        "--set-all-var-ids",
        shQuote("@_#_$1_$2"),
        "--new-id-max-allele-len",
        200,
        "--rm-dup",
        "force-first",
        "--make-pgen",
        "--out",
        panel_raw,
        "--threads",
        4
    ),
    stdout = FALSE,
    stderr = FALSE
)


## ---- readouts ------------------------------------------------------------------
# READOUTS comes from config.R, so this script and step 02 cannot drift apart on
# which file, column or sample size each readout uses.
prepare_readout <- function(key, panel_ids = NULL) {
    cfg <- READOUTS[[key]]
    message("  ", cfg$label, " ...")

    df <- read_region(
        cfg$file,
        cfg$chr_col,
        cfg$pos_col,
        CHR,
        INSTRUMENT_START,
        INSTRUMENT_END,
        extra_filter = cfg$extra_filter
    )
    df$.chr <- sub("^chr", "", as.character(df[[cfg$chr_col]]))
    df$SNPid <- create_SNPid_vectorized(
        df,
        chr = ".chr",
        pos = cfg$pos_col,
        other_allele = cfg$oa_col,
        effect_allele = cfg$ea_col
    )
    df <- df %>% filter(!grepl("D|I", SNPid))

    eaf_col <- cfg$eaf_col
    df$.raw_eaf <- if (is.null(eaf_col)) NA_real_ else as.numeric(df[[eaf_col]])

    # align_ASCII_sort() flips beta onto the ASCII-first allele; the frequency
    # has to follow it, which is what `flipped` is for.
    df <- align_ASCII_sort(
        df,
        effect_allele = cfg$ea_col,
        other_allele = cfg$oa_col,
        beta = cfg$effect_col,
        ld_reference = NULL,
        status = TRUE
    )

    p <- as.numeric(df[[cfg$p_col]])
    if (isTRUE(cfg$neglog10_p)) {
        p <- 10^(-p)
    }

    out <- df %>%
        transmute(
            SNP = SNPid,
            position_hg38 = as.integer(.data[[cfg$pos_col]]),
            A1 = .data[[cfg$ea_col]],
            A2 = .data[[cfg$oa_col]],
            A1_freq = ifelse(flipped, 1 - .raw_eaf, .raw_eaf),
            beta = as.numeric(.data[[cfg$effect_col]]),
            se = as.numeric(.data[[cfg$se_col]]),
            p = p,
            n = cfg$n
        ) %>%
        filter(!is.na(beta), !is.na(se), se > 0, !is.na(p)) %>%
        distinct(SNP, .keep_all = TRUE)

    if (!is.null(panel_ids)) {
        out <- out %>% filter(SNP %in% panel_ids)
    }
    message("    ", nrow(out), " variants")
    out
}


## ---- frequency concordance -----------------------------------------------------
# Neutrophil count is the reference: it is the largest readout that ships an
# effect-allele frequency, and it covers the window most completely.
system2(
    plink2_bin,
    c(
        "--pfile",
        panel_raw,
        "--freq",
        "--out",
        file.path(scratch, "raw_freq"),
        "--threads",
        4
    ),
    stdout = FALSE,
    stderr = FALSE
)
panel_freq <- read.table(
    file.path(scratch, "raw_freq.afreq"),
    header = TRUE,
    comment.char = ""
)
names(panel_freq)[1] <- "CHROM"
panel_freq$.A1 <- vapply(
    strsplit(panel_freq$ID, "_", fixed = TRUE),
    `[`,
    character(1),
    3L
)
panel_freq$freq_panel <- ifelse(
    panel_freq$.A1 != panel_freq$ALT,
    1 - panel_freq$ALT_FREQS,
    panel_freq$ALT_FREQS
)

message("Frequency concordance (INTERVAL vs the neutrophil GWAS):")
neut_for_freq <- prepare_readout("Neutrophil_count")

freq_cmp <- inner_join(
    panel_freq[, c("ID", "freq_panel")],
    neut_for_freq %>% transmute(ID = SNP, freq_gwas = A1_freq),
    by = "ID"
) %>%
    mutate(delta = abs(freq_panel - freq_gwas))
n_bad <- sum(freq_cmp$delta > FREQ_TOL, na.rm = TRUE)
message(sprintf(
    "  %d in both, %d discordant (|d| > %.2f), %d kept",
    nrow(freq_cmp),
    n_bad,
    FREQ_TOL,
    nrow(freq_cmp) - n_bad
))
write_tsv(
    freq_cmp %>% filter(delta > FREQ_TOL) %>% arrange(desc(delta)),
    file.path(out_dir, "nlrp3_frequency_discordant_variants.tsv")
)

keep_file <- file.path(scratch, "concordant.txt")
writeLines(freq_cmp %>% filter(delta <= FREQ_TOL) %>% pull(ID), keep_file)
ld_reference <- file.path(scratch, "nlrp3_region")
system2(
    plink2_bin,
    c(
        "--pfile",
        panel_raw,
        "--extract",
        keep_file,
        "--make-pgen",
        "--out",
        ld_reference,
        "--threads",
        4
    ),
    stdout = FALSE,
    stderr = FALSE
)
panel_ids <- freq_cmp %>% filter(delta <= FREQ_TOL) %>% pull(ID)
panel_eaf <- panel_freq %>%
    transmute(SNP = ID, eaf_panel = freq_panel) %>%
    filter(SNP %in% panel_ids)

message("Loading readouts:")
summary_stats <- list(
    eQTLs = prepare_readout("NLRP3_expression", panel_ids = panel_ids),
    CRP = prepare_readout("CRP", panel_ids = panel_ids),
    GlycA = prepare_readout("GlycA", panel_ids = panel_ids),
    neutro = prepare_readout("Neutrophil_count", panel_ids = panel_ids)
)
availability <- function(snp) {
    sum(vapply(summary_stats, function(x) snp %in% x$SNP, logical(1)))
}


## ---- step 1  LD clumping per readout -------------------------------------------
message(
    "\nSTEP 1  LD clumping per readout (r2 < ",
    R2_THRESHOLD,
    ", p < ",
    CLUMP_P,
    ")"
)
clumped <- list()
for (tn in names(summary_stats)) {
    cl <- ld_clump_local(
        dat = summary_stats[[tn]],
        clump_kb = CLUMP_KB,
        clump_r2 = R2_THRESHOLD,
        clump_p = CLUMP_P,
        bfile = ld_reference,
        plink_bin = plink2_bin,
        verbose = FALSE
    )
    clumped[[tn]] <- cl$ID
    message(sprintf("  %-7s -> %d lead SNP(s)", tn, length(cl$ID)))
}


## ---- step 2  high-LD blocks ----------------------------------------------------
message(
    "STEP 2  high-LD friends (r2 > ",
    HIGH_LD_THRESHOLD,
    ", ",
    HIGH_LD_WINDOW_KB,
    " kb)"
)
friends <- lapply(names(clumped), function(tn) {
    lead <- clumped[[tn]]
    if (length(lead) == 0) {
        return(NULL)
    }
    res <- get_high_ld_snps(
        lead,
        reference = ld_reference,
        ld_threshold = HIGH_LD_THRESHOLD,
        window_kb = HIGH_LD_WINDOW_KB,
        verbose = FALSE
    ) %>%
        select(ID_A, ID_B, UNPHASED_R2)
    # a lead is always its own friend, which plink2 does not report
    rbind(res, data.frame(ID_A = lead, ID_B = lead, UNPHASED_R2 = 1))
})
names(friends) <- names(clumped)

blocks <- sapply(names(friends), simplify = FALSE, function(tn) {
    x <- friends[[tn]]
    if (is.null(x)) {
        return(list())
    }
    x %>%
        group_by(ID_A) %>%
        group_split() %>%
        purrr::map(~ pull(.x, ID_B)) %>%
        purrr::set_names(paste0("LD_block", seq_along(.)))
})
flat <- list()
for (tn in names(blocks)) {
    for (b in names(blocks[[tn]])) {
        flat[[paste0(tn, "_", b)]] <- blocks[[tn]][[b]]
    }
}


## ---- step 3  merge blocks that share a variant ---------------------------------
message("STEP 3  merging blocks that share a variant")
block_snps <- lapply(flat, unique)
block_names <- names(flat)
adj <- sapply(block_names, function(i) {
    sapply(block_names, function(j) {
        length(intersect(block_snps[[i]], block_snps[[j]])) > 0
    })
})
diag(adj) <- FALSE
membership <- components(graph_from_adjacency_matrix(
    adj,
    mode = "undirected",
    diag = FALSE
))$membership
comp_list <- split(names(membership), membership)
comp_list <- comp_list[vapply(comp_list, length, 1L) > 1]

shared <- lapply(names(comp_list), function(id) {
    b <- comp_list[[id]]
    tibble(
        comp_id = as.integer(id),
        eQTLs = any(grepl("^eQTLs", b)),
        CRP = any(grepl("^CRP", b)),
        GlycA = any(grepl("^GlycA", b)),
        neutro = any(grepl("^neutro", b)),
        LD_blocks = paste(b, collapse = ", ")
    )
}) %>%
    bind_rows() %>%
    mutate(num_traits = eQTLs + CRP + GlycA + neutro) %>%
    filter(num_traits >= 2)
message("  components spanning >= 2 readouts: ", nrow(shared))
shared$SNPs <- vapply(
    seq_len(nrow(shared)),
    function(i) {
        bl <- str_trim(unlist(str_split(shared$LD_blocks[i], ",")))
        paste(unique(unlist(block_snps[bl])), collapse = ",")
    },
    character(1)
)


## ---- step 4  one representative per component ----------------------------------
message(
    "STEP 4  one representative per component (most readouts, then lowest CRP p)"
)
pick_best <- function(snps) {
    av <- vapply(snps, availability, 1L)
    best <- snps[av == max(av)]
    summary_stats$CRP %>%
        filter(SNP %in% best) %>%
        slice_min(p, n = 1, with_ties = FALSE)
}
instruments <- lapply(shared$SNPs, function(s) {
    pick_best(unlist(str_split(s, ",")))
}) %>%
    bind_rows() %>%
    pull(SNP)


## ---- step 5  proxy replacement -------------------------------------------------
need_proxy <- instruments[vapply(instruments, availability, 1L) != 4]
proxy_log <- tibble(
    original = character(),
    replacement = character(),
    r2 = numeric()
)
if (length(need_proxy) > 0) {
    message(
        "STEP 5  proxying ",
        length(need_proxy),
        " representative(s) missing from a readout"
    )
    hl <- get_high_ld_snps(
        need_proxy,
        reference = ld_reference,
        ld_threshold = PROXY_R2,
        window_kb = PROXY_WINDOW_KB,
        verbose = FALSE
    )
    if (nrow(hl) > 0) {
        reps <- lapply(unique(hl$ID_A), function(s) {
            cand <- hl %>% filter(ID_A == s)
            cand$av <- vapply(cand$ID_B, availability, 1L)
            cand <- cand %>% filter(av == 4)
            if (nrow(cand) == 0) {
                return(NULL)
            }
            # see PROXY_R2_TIE in the header: near-ties in panel r2 are broken on
            # the panel-independent quantity, so the choice does not depend on
            # which LD reference happens to be available.
            cand <- cand %>%
                filter(UNPHASED_R2 >= max(UNPHASED_R2) - PROXY_R2_TIE)
            best <- summary_stats$CRP %>%
                filter(SNP %in% cand$ID_B) %>%
                slice_min(p, n = 1, with_ties = FALSE) %>%
                pull(SNP)
            if (length(best) == 0) {
                return(NULL)
            }
            if (nrow(cand) > 1) {
                message(sprintf(
                    "    %s: %d proxies within %.2f r2 -> CRP p picks %s (r2 %.4f; best r2 %.4f)",
                    s,
                    nrow(cand),
                    PROXY_R2_TIE,
                    best,
                    cand$UNPHASED_R2[match(best, cand$ID_B)],
                    max(cand$UNPHASED_R2)
                ))
            }
            tibble(
                original = s,
                replacement = best,
                r2 = cand$UNPHASED_R2[match(best, cand$ID_B)]
            )
        }) %>%
            bind_rows()
        if (nrow(reps) > 0) {
            proxy_log <- reps
            lk <- setNames(reps$replacement, reps$original)
            instruments <- ifelse(
                instruments %in% names(lk),
                lk[instruments],
                instruments
            )
        }
    }
} else {
    message(
        "STEP 5  every representative present in all four readouts, no proxies needed"
    )
}
instruments <- unique(instruments)
message("  candidate instruments: ", length(instruments))


## ---- step 6  PCA ---------------------------------------------------------------
message("STEP 6  PCA over the 4-readout effect matrix")
effect_matrix <- function(field) {
    lapply(names(summary_stats), function(tn) {
        summary_stats[[tn]] %>%
            filter(SNP %in% instruments) %>%
            mutate(trait = tn)
    }) %>%
        bind_rows() %>%
        select(SNP, trait, all_of(field)) %>%
        pivot_wider(names_from = trait, values_from = all_of(field)) %>%
        column_to_rownames("SNP") %>%
        drop_na() %>%
        as.matrix()
}
beta_m <- effect_matrix("beta")
se_m <- effect_matrix("se")[rownames(beta_m), colnames(beta_m), drop = FALSE]

# drop_na() removes any candidate still missing from a readout after proxying.
# Reported rather than silent.
if (nrow(beta_m) < length(instruments)) {
    message(sprintf(
        "  %d dropped for incomplete readout coverage: %s",
        length(instruments) - nrow(beta_m),
        paste(setdiff(instruments, rownames(beta_m)), collapse = ", ")
    ))
}
message("  instruments entering the PCA: ", nrow(beta_m))

pca <- prcomp(beta_m, center = TRUE, scale. = TRUE)
loadings <- pca$rotation[, 1]
if (all(sign(loadings) < 0)) {
    loadings <- -loadings
}
beta_latent <- as.numeric(beta_m %*% loadings)
pc1_var <- summary(pca)$importance[2, 1]
message(sprintf("  PC1 explains %.1f%% of variance", 100 * pc1_var))
message(
    "  loadings: ",
    paste(sprintf("%s = %+.3f", names(loadings), loadings), collapse = "   ")
)


## ---- step 7  worst-case standard errors ----------------------------------------
# The three blood-based readouts are measured in largely the same participants,
# so their sampling errors are correlated; the eQTL is an independent cohort.
# Treating the three as perfectly correlated is the conservative bound.
idx <- match(c("eQTLs", "CRP", "GlycA", "neutro"), colnames(se_m))
se_latent <- apply(se_m, 1, function(row) {
    w <- loadings[idx]
    sqrt(
        (w[1]^2) *
            row[idx[1]]^2 +
            (w[2] * row[idx[2]] + w[3] * row[idx[3]] + w[4] * row[idx[4]])^2
    )
})


## ---- step 8  CRP anchoring and sign --------------------------------------------
anchor <- tibble(SNP = rownames(beta_m), beta_latent, se_latent) %>%
    inner_join(
        summary_stats$CRP %>% select(SNP, beta_CRP = beta, se_CRP = se),
        by = "SNP"
    ) %>%
    mutate(w = 1 / se_CRP^2)
k <- coef(lm(beta_CRP ~ 0 + beta_latent, data = anchor, weights = w))[[
    "beta_latent"
]]
score <- tibble(
    SNP = rownames(beta_m),
    beta = beta_latent * k,
    se = se_latent * abs(k)
)

# PC1's sign is arbitrary, so fix it: a higher score must mean higher NLRP3
# expression. Downstream scripts negate this once, in load_instruments().
sign_check <- score %>%
    inner_join(
        summary_stats$eQTLs %>%
            filter(SNP %in% score$SNP) %>%
            select(SNP, beta_eqtl = beta),
        by = "SNP"
    )
score_flipped <- cor(sign_check$beta, sign_check$beta_eqtl) < 0
if (score_flipped) {
    score$beta <- -score$beta
    k <- -k
}
message(sprintf(
    "  scaling constant k = %.4f%s",
    k,
    if (score_flipped) "  (sign flipped so higher = more NLRP3)" else ""
))


## ---- output --------------------------------------------------------------------
# eaf is the GWAS A1 frequency, NOT the panel's. helpers.R::check_panel_freq()
# compares the two, and seeding it from the panel would make that check vacuous.
gwas_eaf <- summary_stats$neutro %>% select(SNP, eaf = A1_freq)

out <- score %>%
    transmute(
        SNP,
        chr = CHR,
        pos_hg38 = as.integer(vapply(
            strsplit(SNP, "_", fixed = TRUE),
            `[`,
            character(1),
            2L
        )),
        A1 = vapply(strsplit(SNP, "_", fixed = TRUE), `[`, character(1), 3L),
        A2 = vapply(strsplit(SNP, "_", fixed = TRUE), `[`, character(1), 4L),
        beta_exposure = beta,
        se_exposure = se
    ) %>%
    left_join(gwas_eaf, by = "SNP") %>%
    left_join(panel_eaf, by = "SNP") %>%
    mutate(
        r2_threshold = R2_THRESHOLD,
        pc1_var_explained = pc1_var,
        scaling_constant_k = k,
        score_sign_flipped = score_flipped
    ) %>%
    select(
        SNP,
        chr,
        pos_hg38,
        A1,
        A2,
        eaf,
        beta_exposure,
        se_exposure,
        eaf_panel,
        r2_threshold,
        pc1_var_explained,
        scaling_constant_k,
        score_sign_flipped
    ) %>%
    arrange(pos_hg38)

write_tsv(out, file.path(out_dir, "nlrp3_instruments.tsv"))
write_tsv(proxy_log, file.path(out_dir, "nlrp3_proxy_replacements.tsv"))
message("\nwrote ", file.path(out_dir, "nlrp3_instruments.tsv"))

print(
    as.data.frame(
        out %>% select(SNP, pos_hg38, A1, A2, eaf, beta_exposure, se_exposure)
    ),
    row.names = FALSE
)
