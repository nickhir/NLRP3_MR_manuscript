## 04 - Inflammatory readouts and effector cytokines
##
## MR of the activity score against CRP, GlycA and neutrophil count, and
## against IL1B, IL18 and IL6. Writes results/04_mr_biomarkers/.

suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(here)
    library(MendelianRandomization)
})

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("04_mr_biomarkers")

# The activity score, oriented so every estimate reads per one-unit DECREASE -
# the direction a pharmacological NLRP3 inhibitor moves a patient.
exposure    <- load_instruments(negate = TRUE)
instruments <- exposure$SNP

ld_full <- interval_ld_matrix(instruments)
stopifnot(identical(rownames(ld_full), instruments))


## ---- block 1: the systemic inflammation proxies ------------------------------
# NLRP3 expression is the fourth construction trait but is not plotted: it is a
# molecular readout in 4,732 people rather than a circulating inflammatory
# marker, and Figure 2B already shows it per variant.
PROXIES <- c("CRP", "GlycA", "Neutrophil_count")

message("Systemic inflammation proxies (re-derived from source, all GRCh38):")

proxy_mr <- lapply(PROXIES, function(k) {
    cfg <- READOUTS[[k]]
    message(sprintf("  %s ...", cfg$label))

    outcome <- read_region(cfg$file, cfg$chr_col, cfg$pos_col,
                           CHR, LOCUS_START, LOCUS_END,
                           extra_filter = cfg$extra_filter) |>
        harmonise_region(cfg, CHR) |>
        filter(SNPid %in% instruments)

    found <- sum(instruments %in% outcome$SNPid)
    message(sprintf("    %d/8 instruments recovered", found))
    if (found != 8) {
        stop(sprintf("[%s] only %d/8 instruments found at GRCh38 positions",
                     cfg$label, found))
    }

    # harmonise_region() puts beta on the ASCII-first allele, and
    # load_instruments() asserts the exposure is on the same one, so the two
    # are aligned by construction rather than by a merge on alleles.
    dat <- exposure |>
        select(SNP, beta_exposure, se_exposure) |>
        left_join(outcome |> select(SNP = SNPid,
                                    beta_outcome = beta, se_outcome = se),
                  by = "SNP") |>
        mutate(outcome = cfg$label)

    run_mr(dat, ld_full) |>
        mutate(block = "Systemic inflammation proxies", n_total = cfg$n)
}) |> bind_rows()


## ---- block 2: the effector cytokines, re-derived from UKB-PPP ----------------
CYTOKINES <- c("IL1B", "IL18", "IL6")

stopifnot(dir.exists(ppp_dir), file.exists(ppp_manifest), file.exists(tabix_bin))

# IL6 is assayed on four Olink panels, IL1B and IL18 on one each: six assays.
assays <- tibble(protein_id = readLines(ppp_manifest)) |>
    filter(nzchar(protein_id)) |>
    mutate(gene_name = sub("_.*$", "", protein_id),
           path      = file.path(ppp_dir, paste0(protein_id, ".bgz"))) |>
    filter(gene_name %in% CYTOKINES)

stopifnot(setequal(assays$gene_name, CYTOKINES), all(file.exists(assays$path)))

message(sprintf("\nNLRP3 inflammasome-associated cytokines (UKB-PPP, %d assays):",
                nrow(assays)))

PPP_COLS <- c("CHROM", "GENPOS", "ID", "ALLELE0", "ALLELE1", "A1FREQ",
              "INFO", "N", "TEST", "BETA", "SE", "CHISQ", "LOG10P", "EXTRA")

# Ask tabix only for the eight instrument positions. GENPOS is GRCh38; the ID
# string carries GRCh37, which is why the join is on GENPOS.
regions <- sprintf("%d:%d-%d", exposure$chr, exposure$pos_hg38, exposure$pos_hg38)

read_assay <- function(path) {
    txt <- suppressWarnings(
        system2(tabix_bin, c(shQuote(path), regions), stdout = TRUE, stderr = FALSE))
    if (length(txt) == 0) return(NULL)
    df <- data.table::fread(text = paste(txt, collapse = "\n"), sep = "\t",
                            header = FALSE, colClasses = "character")
    if (ncol(df) != length(PPP_COLS)) return(NULL)
    setNames(df, PPP_COLS)
}

# ALLELE1 is the REGENIE effect allele and is not guaranteed to be the
# ASCII-first allele, so the outcome is flipped onto A1 the same way step 09
# does it.
harmonise_assay <- function(df) {
    std <- df |>
        transmute(join_pos   = as.integer(GENPOS),
                  outcome_ea = toupper(ALLELE1),
                  outcome_oa = toupper(ALLELE0),
                  beta_raw   = as.numeric(BETA),
                  se_outcome = as.numeric(SE),
                  info       = as.numeric(INFO),
                  n_outcome  = as.integer(N))

    exposure |>
        left_join(std, by = c("pos_hg38" = "join_pos"),
                  relationship = "one-to-many") |>
        mutate(forward = outcome_ea == A1 & outcome_oa == A2,
               reverse = outcome_ea == A2 & outcome_oa == A1,
               beta_outcome = case_when(forward ~ beta_raw,
                                        reverse ~ -beta_raw,
                                        TRUE    ~ NA_real_)) |>
        filter(!is.na(beta_outcome), !is.na(se_outcome), se_outcome > 0) |>
        distinct(SNP, .keep_all = TRUE)
}

ppp_mr <- lapply(seq_len(nrow(assays)), function(i) {
    row <- assays[i, ]
    raw <- read_assay(row$path)
    if (is.null(raw) || nrow(raw) == 0) stop("tabix returned no rows for ", row$protein_id)

    dat <- harmonise_assay(raw)
    if (nrow(dat) < 3) stop(sprintf("[%s] only %d instrument(s) after harmonisation",
                                    row$protein_id, nrow(dat)))

    mr_in <- mr_input(bx = dat$beta_exposure, bxse = dat$se_exposure,
                      by = dat$beta_outcome,  byse = dat$se_outcome,
                      exposure = "cis-NLRP3 activity (lower)",
                      outcome = row$protein_id, snps = dat$SNP,
                      correlation = ld_full[dat$SNP, dat$SNP])

    # As in step 09: IVW uses the correlation matrix, mr_median() has no
    # correlation argument and treats the instruments as independent.
    ivw <- mr_ivw(mr_in, correl = TRUE)
    med <- mr_median(mr_in, weighting = "weighted")

    tibble(protein_id = row$protein_id, gene_name = row$gene_name,
           n_snps = nrow(dat), n_ppp = max(dat$n_outcome, na.rm = TRUE),
           ivw_beta = ivw$Estimate, ivw_se = ivw$StdError, ivw_pval = ivw$Pvalue,
           median_beta = med$Estimate, median_se = med$StdError,
           median_pval = med$Pvalue)
}) |> bind_rows()

# Step 09's rule for proteins on more than one panel: keep the most significant
# IVW result per gene.
proteome <- ppp_mr |>
    group_by(gene_name) |>
    slice_min(order_by = ivw_pval, n = 1, with_ties = FALSE) |>
    ungroup()

stopifnot(nrow(proteome) == length(CYTOKINES), !any(duplicated(proteome$gene_name)))

cytokine_mr <- lapply(CYTOKINES, function(k) {
    r <- proteome |> filter(gene_name == k)
    message(sprintf("  %-5s beta=%7.3f  n=%s  snps=%s  [%s]",
                    k, r$ivw_beta, format(r$n_ppp, big.mark = ","), r$n_snps,
                    r$protein_id))

    bind_rows(
        tibble(method = "IVW",
               estimate = r$ivw_beta, se = r$ivw_se, p = r$ivw_pval),
        tibble(method = "Weighted median",
               estimate = r$median_beta, se = r$median_se, p = r$median_pval)
    ) |>
        mutate(outcome  = k,
               nsnp     = as.integer(r$n_snps),
               ci_lower = estimate - 1.96 * se,
               ci_upper = estimate + 1.96 * se,
               block    = "NLRP3 inflammasome-associated cytokines",
               n_total  = as.integer(r$n_ppp),
               .before  = 1)
}) |> bind_rows()


## ---- assemble ----------------------------------------------------------------
# run_mr() names the LD-corrected estimator "IVW (LD-corrected)"; block 2 calls
# the same quantity plain "IVW".
results <- bind_rows(proxy_mr, cytokine_mr) |>
    mutate(
        method       = recode(method, "IVW (LD-corrected)" = "IVW"),
        ld_corrected = method == "IVW",
        n_cases      = NA_integer_,      # every outcome here is continuous
        n_controls   = NA_integer_
    ) |>
    select(block, outcome, method, estimate, se, ci_lower, ci_upper, p,
           nsnp, n_total, n_cases, n_controls, ld_corrected) |>
    arrange(match(block, c("Systemic inflammation proxies",
                           "NLRP3 inflammasome-associated cytokines")),
            match(outcome, c("CRP concentration", "GlycA concentration",
                             "Neutrophil count", "IL1B", "IL18", "IL6")),
            match(method, c("IVW", "Weighted median")))

stopifnot(nrow(results) == 12, !any(is.na(results$estimate)))


## ---- sanity checks -----------------------------------------------------------
# Lower NLRP3 activity must lower every one of these readouts. The three proxies
# are negative by construction; the cytokines are not, and are the real test.
ivw <- results |> filter(method == "IVW")

message("\nIVW, per one-unit decrease in the activity score:")
for (i in seq_len(nrow(ivw))) {
    message(sprintf("  %-20s %6.2f (%6.2f, %6.2f)  P=%9.2g",
                    ivw$outcome[i], ivw$estimate[i],
                    ivw$ci_lower[i], ivw$ci_upper[i], ivw$p[i]))
}

if (any(ivw$estimate > 0)) {
    stop("an IVW estimate is positive, which inverts the paper's direction: ",
         paste(ivw$outcome[ivw$estimate > 0], collapse = ", "))
}

# The score was scaled to CRP so that one unit is about one SD of CRP. A CRP
# estimate far from -1 means the frozen exposure and this CRP release have
# drifted apart, which would invalidate the scale printed on the figure axis.
crp <- ivw$estimate[ivw$outcome == "CRP concentration"]
message(sprintf("\nCRP scaling check: IVW = %.3f (expected near -1.00)", crp))
if (abs(crp + 1) > 0.25) {
    warning(sprintf("CRP IVW is %.3f, further from -1.00 than expected", crp))
}


## ---- write -------------------------------------------------------------------
fwrite(results, file.path(out_dir, "mr_biomarkers.tsv"), sep = "\t")

message("\nDone -> ", file.path(out_dir, "mr_biomarkers.tsv"))
