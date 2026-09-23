#!/usr/bin/env Rscript
# Build the supplementary-table workbook.
# Run: Rscript tables/build_supplementary_tables.R [template.xlsx] [output.xlsx] [results_dir]
#
# One flat table per sheet, header in row 1, no panels and no notes blocks.
# A "Contents" sheet is written first. The manual source tables are carried across
# from the template unchanged, apart from dropping their title and blank rows so
# the header lands in row 1.
#
# Sheet numbers are the manuscript's, in the template as well as here: nothing is
# renamed or renumbered on the way through.
#
# Nothing confidential is exported: no LD matrices, no per-variant panels for the
# genome-wide mediator instruments, no individual-level data. Nothing is invented:
# where a result has not been produced the sheet carries its header and a single
# "not yet available" row.

suppressPackageStartupMessages({
    library(openxlsx)
    library(MendelianRandomization)
})


## ---- where everything lives ---------------------------------------------------
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
root <- dirname(dirname(normalizePath(script, mustWork = TRUE)))
args <- commandArgs(trailingOnly = TRUE)
template <- normalizePath(if (length(args) >= 1L) args[1] else
    file.path(root, "SuppTables_new.xlsx"), mustWork = TRUE)
output <- if (length(args) >= 2L) args[2] else file.path(root, "SuppTables_completed_DRAFT.xlsx")
output <- file.path(normalizePath(dirname(output), mustWork = TRUE), basename(output))
results <- normalizePath(if (length(args) >= 3L) args[3] else file.path(root, "results"),
                         mustWork = TRUE)


## ---- reading results ----------------------------------------------------------
read_result <- function(path) {
    file <- file.path(results, path)
    if (!file.exists(file)) stop("Required result missing: ", file)
    read.delim(file, check.names = FALSE, stringsAsFactors = FALSE,
               na.strings = c("", "NA"), quote = "\"", comment.char = "")
}
read_result_rds <- function(path) readRDS(file.path(results, path))


## ---- formatting ---------------------------------------------------------------
# "(1.02, 1.45)" at three significant figures, as in the exemplar workbook.
ci <- function(lo, hi) {
    f <- function(v) trimws(formatC(signif(v, 3), format = "g", digits = 3))
    ifelse(is.na(lo) | is.na(hi), NA_character_, sprintf("(%s, %s)", f(lo), f(hi)))
}

# Every IVW estimate in the pipeline is LD-corrected: each step builds
# mr_input(..., correlation = ...) and mr_ivw() switches correl on whenever a
# correlation matrix is present. Only the string written into the `method`
# column differs between steps, so normalise it here.
method_label <- function(x) {
    x <- sub("^IVW \\(LD-corrected\\)$", "IVW", x)
    sub("^Weighted Median$", "Weighted median", x)
}

# Pull a column that only some of the inputs carry.
optional <- function(d, name) if (name %in% names(d)) d[[name]] else NA_real_

P_FMT <- "0.00E+00"
INT_FMT <- "#,##0"


## ---- the sheet register --------------------------------------------------------
# One entry per sheet, holding everything that sheet needs: its table, its column
# formats, and the one line describing it on the Contents sheet. Contents is built
# from this at the end rather than maintained as a second list that can drift.
sheets <- list()
add <- function(id, contents, table, fmt = character()) {
    sheets[[id]] <<- list(contents = contents, table = table, fmt = fmt)
    invisible(NULL)
}


## ---- ST01-ST04, ST16  manual source tables, carried across ----------------------
# The template puts a title in row 1, a blank row 2 and the header in row 3. The
# sheet name is the same on both sides, so this is a straight copy.
MANUAL <- c(
    ST01 = "GWAS data sources for the traits used to construct and validate the NLRP3 activity score.",
    ST02 = "GWAS data sources for coronary artery disease and imaging-defined atherosclerosis.",
    ST03 = "GWAS data sources for the diseases under clinical investigation for NLRP3 inhibition.",
    ST04 = "GWAS data sources for the cardiometabolic and lifestyle traits.",
    ST16 = "Clinical trials of selective NLRP3 inhibitors and the disease indications extracted from them."
)
for (id in names(MANUAL)) {
    # colNames = FALSE: read.xlsx() would otherwise run the header through
    # make.names() and turn "First Author" into "First.Author".
    raw <- read.xlsx(template, sheet = id, startRow = 3,
                     colNames = FALSE, skipEmptyRows = TRUE, skipEmptyCols = TRUE,
                     detectDates = FALSE)
    header_row <- trimws(as.character(unlist(raw[1, ], use.names = FALSE)))
    named <- !is.na(header_row) & nzchar(header_row)
    x <- raw[-1, named, drop = FALSE]
    names(x) <- header_row[named]
    rownames(x) <- NULL

    # Reading the header as data made every column character; restore the numbers
    # and give whole-number columns a thousands separator.
    fmt <- character()
    for (j in names(x)) {
        text <- trimws(as.character(x[[j]]))
        text[text %in% c("", "NA")] <- NA_character_
        as_number <- suppressWarnings(as.numeric(text))
        numeric_column <- !all(is.na(as_number[!is.na(text)]))
        x[[j]] <- if (numeric_column) as_number else text
        if (numeric_column && all(is.na(as_number) | as_number == floor(as_number))) {
            fmt[j] <- INT_FMT
        }
    }
    add(id, MANUAL[[id]], x, fmt)
}


## ---- inputs shared by several sheets --------------------------------------------
inst <- read_result("00_instrument_selection/nlrp3_instruments.tsv")
readouts_long <- read_result("02_instrument_table/instrument_readouts_long.tsv")
rsid <- read_result("11_mr_sensitivity/instrument_rsids.tsv")
proteome <- read_result("09_proteome_mr/ukb_ppp_proteome_mr_results.tsv")
leave_one_out <- read_result("11_mr_sensitivity/leave_one_out.tsv")

# The exposure on the scale every MR in the paper uses: per one-unit LOWER score.
bx <- -inst$beta_exposure
ld_inst <- read_result_rds("03_instrument_strength/instrument_ld_matrix.rds")[inst$SNP, inst$SNP]

TRAIT <- c(NLRP3_expression = "NLRP3 expression", CRP = "CRP",
           GlycA = "GlycA", Neutrophil_count = "Neutrophil count")

# Step 12 holds the three SCAPIS imaging traits and the exploratory diseases in one
# file; ST07 takes the imaging rows and ST15 takes the rest.
indications <- read_result("12_mr_indications/additional_indications_mr_results.tsv")
coverage <- read_result("12_mr_indications/additional_indications_coverage.tsv")
indication_key <- coverage$key[match(indications$outcome, coverage$outcome)]
IMAGING <- c("cac", "sis", "carotid")


## ---- ST05  cis-NLRP3 instruments -------------------------------------------------
# Oriented exactly as Figure 2B: the reported allele is the one that LOWERS the
# NLRP3 activity score. `beta_exposure` is stored on the score-raising scale, so a
# variant whose A1 raises the score is flipped onto A2, and its frequency and every
# readout beta are flipped with it. SEs and P values are unaffected.
flip_snp <- setNames(inst$beta_exposure > 0, inst$SNP)

score_rows <- data.frame(SNP = inst$SNP, trait = "NLRP3 activity score",
                         beta = inst$beta_exposure, se = inst$se_exposure,
                         p = NA_real_, stringsAsFactors = FALSE)
st05_rows <- rbind(readouts_long[c("SNP", "trait", "beta", "se", "p")], score_rows)
st05_rows$trait <- ifelse(st05_rows$trait %in% names(TRAIT),
                          TRAIT[st05_rows$trait], st05_rows$trait)

variant <- match(st05_rows$SNP, inst$SNP)     # row of `inst` each output row describes
flipped <- unname(flip_snp[st05_rows$SNP])

st05 <- data.frame(
    SNP = st05_rows$SNP,
    rsID = rsid$rsid[match(st05_rows$SNP, rsid$SNP)],
    Chromosome = inst$chr[variant],
    `Position hg38` = inst$pos_hg38[variant],
    `Effect allele` = ifelse(flipped, inst$A2[variant], inst$A1[variant]),
    `Other allele` = ifelse(flipped, inst$A1[variant], inst$A2[variant]),
    `Effect allele frequency` = ifelse(flipped, 1 - inst$eaf[variant], inst$eaf[variant]),
    Trait = st05_rows$trait,
    Beta = ifelse(flipped, -st05_rows$beta, st05_rows$beta),
    SE = st05_rows$se, `P value` = st05_rows$p,
    check.names = FALSE, stringsAsFactors = FALSE)

TRAIT_ORDER <- c(unname(TRAIT), "NLRP3 activity score")
st05 <- st05[order(st05$`Position hg38`, match(st05$Trait, TRAIT_ORDER)), ]
add("ST05",
    "The eight cis-NLRP3 instruments and their per-trait associations, oriented to the allele that lowers NLRP3 activity.",
    st05, c(Chromosome = "0", `Position hg38` = "0", `P value` = P_FMT))


## ---- ST06  NLRP3 activity score validation ----------------------------------------
biomarkers <- read_result("04_mr_biomarkers/mr_biomarkers.tsv")

# MR-Egger intercepts. The three construction readouts are refitted here from the
# saved per-variant effects; the three cytokines come from the proteome step, which
# already ran MR-Egger on the same Olink assay step 04 selected.
READOUT_OF <- c(`CRP concentration` = "CRP", `GlycA concentration` = "GlycA",
                `Neutrophil count` = "Neutrophil_count")
egger_intercept_for <- function(outcome) {
    if (outcome %in% names(READOUT_OF)) {
        y <- readouts_long[readouts_long$trait == READOUT_OF[[outcome]], ]
        y <- y[match(inst$SNP, y$SNP), ]
        fit <- mr_egger(mr_input(bx = bx, bxse = inst$se_exposure,
                                 by = y$beta, byse = y$se,
                                 snps = inst$SNP, correlation = ld_inst))
        c(fit$Intercept, fit$Pvalue.Int)
    } else {
        assay <- proteome[proteome$gene_name == outcome, ]
        c(assay$egger_intercept, assay$egger_intercept_pval)
    }
}
egger <- t(vapply(biomarkers$outcome, egger_intercept_for, numeric(2)))
# The intercept belongs to the IVW fit, not to the weighted median beside it.
egger[biomarkers$method != "IVW", ] <- NA

add("ST06",
    "Mendelian randomization estimates for the NLRP3 activity score on the inflammatory biomarkers and cytokines.",
    data.frame(
        Exposure = "cis-NLRP3 activity score (lower)",
        Outcome = biomarkers$outcome,
        `# of Instruments` = biomarkers$nsnp,
        Method = method_label(biomarkers$method),
        `Effect estimate (beta)` = biomarkers$estimate,
        SE = biomarkers$se,
        `95% CI` = ci(biomarkers$ci_lower, biomarkers$ci_upper),
        `P value` = biomarkers$p,
        `Egger intercept` = unname(egger[, 1]),
        `Egger intercept P` = unname(egger[, 2]),
        `Outcome GWAS N` = biomarkers$n_total,
        check.names = FALSE, stringsAsFactors = FALSE),
    c(`# of Instruments` = INT_FMT, `Outcome GWAS N` = INT_FMT, `P value` = P_FMT,
      `Egger intercept P` = P_FMT))


## ---- ST07  CAD and imaging-defined atherosclerosis -------------------------------
cad <- read_result("05_mr_cad/cad_meta_studies.tsv")
meta_ivw <- leave_one_out[leave_one_out$dropped == "none" &
                          leave_one_out$method == "IVW", ]

# MR-Egger for the meta-analysis. Step 11 fits it but stores only the intercept,
# so it is refitted here from the saved per-SNP effects and the saved LD matrix.
per_snp <- read_result("05_mr_cad/cad_meta_studies_per_snp.tsv")
per_snp <- per_snp[per_snp$study == "Meta-analysis", ]
per_snp <- per_snp[match(inst$SNP, per_snp$SNP), ]
cad_egger <- mr_egger(mr_input(bx = bx, bxse = inst$se_exposure,
                               by = per_snp$by, byse = per_snp$byse,
                               snps = inst$SNP, correlation = ld_inst))

cad_rows <- data.frame(
    Outcome = "Coronary artery disease",
    `GWAS source` = cad$study, Method = method_label(cad$method),
    `# of Instruments` = cad$n_snps,
    Scale = "OR",
    `Effect estimate (beta or OR)` = exp(cad$beta),
    `95% CI` = ci(exp(cad$ci_lower), exp(cad$ci_upper)),
    `SE (beta or log OR)` = cad$se, `P value` = cad$pval,
    `Egger intercept` = NA_real_, `Egger intercept P` = NA_real_,
    `Heterogeneity Q` = NA_real_, `Heterogeneity P` = NA_real_,
    check.names = FALSE, stringsAsFactors = FALSE)

# Heterogeneity is reported for the meta-analysis IVW row only.
meta_row <- cad_rows$`GWAS source` == "Meta-analysis" & cad_rows$Method == "IVW"
cad_rows$`Heterogeneity Q`[meta_row] <- meta_ivw$het_q
cad_rows$`Heterogeneity P`[meta_row] <- meta_ivw$het_p

cad_egger_row <- data.frame(
    Outcome = "Coronary artery disease", `GWAS source` = "Meta-analysis",
    Method = "MR-Egger", `# of Instruments` = nrow(inst), Scale = "OR",
    `Effect estimate (beta or OR)` = exp(cad_egger$Estimate),
    `95% CI` = ci(exp(cad_egger$CILower.Est), exp(cad_egger$CIUpper.Est)),
    `SE (beta or log OR)` = cad_egger$StdError.Est, `P value` = cad_egger$Pvalue.Est,
    `Egger intercept` = cad_egger$Intercept, `Egger intercept P` = cad_egger$Pvalue.Int,
    `Heterogeneity Q` = NA_real_, `Heterogeneity P` = NA_real_,
    check.names = FALSE, stringsAsFactors = FALSE)

imaging <- indications[indication_key %in% IMAGING, ]
# CAC is a rank-inverse-normalised continuous trait; the two plaque scores are
# ordinal and their estimates are proportional odds ratios.
proportional_or <- indication_key[indication_key %in% IMAGING] != "cac"
imaging_rows <- data.frame(
    Outcome = imaging$outcome, `GWAS source` = "SCAPIS",
    Method = method_label(imaging$method),
    `# of Instruments` = imaging$nsnp,
    Scale = ifelse(proportional_or, "Proportional OR", "Beta (SD)"),
    `Effect estimate (beta or OR)` = ifelse(proportional_or, exp(imaging$estimate),
                                            imaging$estimate),
    `95% CI` = ifelse(proportional_or, ci(exp(imaging$ci_lower), exp(imaging$ci_upper)),
                      ci(imaging$ci_lower, imaging$ci_upper)),
    `SE (beta or log OR)` = imaging$se, `P value` = imaging$p,
    `Egger intercept` = NA_real_, `Egger intercept P` = NA_real_,
    `Heterogeneity Q` = NA_real_, `Heterogeneity P` = NA_real_,
    check.names = FALSE, stringsAsFactors = FALSE)

add("ST07",
    "Mendelian randomization estimates for the NLRP3 activity score on coronary artery disease and imaging-defined atherosclerosis.",
    rbind(cad_rows, cad_egger_row, imaging_rows),
    c(`# of Instruments` = INT_FMT, `P value` = P_FMT,
      `Heterogeneity P` = P_FMT, `Egger intercept P` = P_FMT))


## ---- ST08  cardiometabolic and lifestyle traits ----------------------------------
cardio <- read_result("06_mr_cardiometabolic/cardiometabolic_mr.tsv")
binary_outcome <- cardio$binary %in% c(TRUE, "TRUE")
add("ST08",
    "Mendelian randomization estimates for the NLRP3 activity score on cardiometabolic and lifestyle traits.",
    data.frame(
        Outcome = cardio$outcome, Method = method_label(cardio$method),
        `# of Instruments` = cardio$nsnp,
        `Effect estimate (beta or OR)` = ifelse(binary_outcome, exp(cardio$estimate),
                                                cardio$estimate),
        `95% CI` = ifelse(binary_outcome, ci(exp(cardio$ci_lower), exp(cardio$ci_upper)),
                          ci(cardio$ci_lower, cardio$ci_upper)),
        `SE (beta or log OR)` = cardio$se, `P value` = cardio$p,
        check.names = FALSE, stringsAsFactors = FALSE),
    c(`# of Instruments` = INT_FMT, `P value` = P_FMT))


## ---- ST09  mediation of the CAD association --------------------------------------
mediation <- read_result("07c_mediation/mediation_summary.tsv")
per_mediator <- read_result("07c_mediation/mediation_per_mediator.tsv")
proportion <- read_result("07c_mediation/proportion_mediated.tsv")
conditional_f <- read_result_rds("07c_mediation/mediation.rds")$cond_F

# One row per quantity, in the order the sheet reads.
total <- mediation[mediation$quantity == "Total effect", ]
joint <- mediation[mediation$quantity == "Joint indirect", ]
direct <- mediation[mediation$quantity == "Direct effect", ]
n_mediators <- nrow(per_mediator)

pct_ci <- sprintf("(%s, %s)",
                  formatC(100 * proportion$ci_lower, format = "f", digits = 1),
                  formatC(100 * proportion$ci_upper, format = "f", digits = 1))

add("ST09",
    "Mediation of the coronary artery disease association by systolic blood pressure, apolipoprotein B and type 2 diabetes.",
    data.frame(
        `Effect component` = c("Total effect", paste("Indirect via", per_mediator$label),
                               "Joint indirect effect", "Residual direct effect"),
        # The mediator-to-CAD columns apply to the per-mediator rows only.
        `Mediator to CAD log OR` = c(NA, per_mediator$beta, NA, NA),
        SE = c(NA, per_mediator$se_beta, NA, NA),
        `Conditional F` = c(NA, conditional_f, NA, NA),
        `Effect (log OR)` = c(total$estimate, per_mediator$indirect,
                              joint$estimate, direct$estimate),
        `SE (log OR)` = c(total$se, per_mediator$se_indirect, joint$se, direct$se),
        OR = c(total$or, per_mediator$or, joint$or, direct$or),
        `95% CI (OR)` = c(ci(total$or_lower, total$or_upper),
                          ci(per_mediator$or_lower, per_mediator$or_upper),
                          ci(joint$or_lower, joint$or_upper),
                          ci(direct$or_lower, direct$or_upper)),
        `Proportion mediated (%)` = 100 * c(NA, per_mediator$pm_alone,
                                            proportion$proportion_mediated, NA),
        # Only the joint row carries the Monte Carlo interval.
        `Proportion mediated 95% CI (%)` = c(rep(NA_character_, 1 + n_mediators),
                                             pct_ci, NA),
        `P value` = c(total$p, per_mediator$p, joint$p, direct$p),
        check.names = FALSE, stringsAsFactors = FALSE),
    c(`P value` = P_FMT))


## ---- ST10  rare-variant burden ----------------------------------------------------
BURDEN <- "rare_variant_burden/gene_burden.tsv"
st10 <- if (file.exists(file.path(results, BURDEN))) {
    burden <- read_result(BURDEN)
    data.frame(Gene = burden$gene, `# pLOF carriers` = burden$n_carriers,
               `# non-carriers` = burden$n_noncarriers, Biomarker = burden$trait,
               Beta = burden$beta, SE = burden$se,
               `95% CI` = ci(burden$ci_lower, burden$ci_upper), `P value` = burden$p,
               check.names = FALSE, stringsAsFactors = FALSE)
} else {
    message("NOTE: ", BURDEN, " not found - ST10 written as a header with a ",
            "'not yet available' row. No values are invented.")
    data.frame(Gene = "Not yet available", `# pLOF carriers` = NA_integer_,
               `# non-carriers` = NA_integer_,
               Biomarker = "SAIGE-GENE+ burden export pending", Beta = NA_real_,
               SE = NA_real_, `95% CI` = NA_character_, `P value` = NA_real_,
               check.names = FALSE, stringsAsFactors = FALSE)
}
add("ST10",
    "Rare-variant predicted loss-of-function burden associations for NLRP3 and its neighbouring genes.",
    st10, c(`# pLOF carriers` = INT_FMT, `# non-carriers` = INT_FMT, `P value` = P_FMT))


## ---- ST11  IL1RN positive control ---------------------------------------------------
il1rn <- read_result("08_il1rn_positive_control/il1rn_mr_results.tsv")
add("ST11",
    "Mendelian randomization estimates for the IL1Ra activity score (positive control).",
    data.frame(
        Exposure = "cis-IL1RN / IL1Ra activity score (higher)",
        Outcome = il1rn$outcome, `# of Instruments` = il1rn$n_snps,
        Method = method_label(il1rn$method),
        Scale = il1rn$scale,
        # Already on the OR scale in results/; not exponentiated again.
        `Effect estimate (beta or OR)` = il1rn$estimate,
        `95% CI` = ci(il1rn$ci_lower, il1rn$ci_upper),
        `SE (beta or log OR)` = il1rn$se, `P value` = il1rn$p,
        `Egger intercept` = il1rn$egger_intercept,
        `Egger intercept P` = il1rn$egger_intercept_p,
        `Heterogeneity Q` = il1rn$het_stat, `Heterogeneity P` = il1rn$het_p,
        check.names = FALSE, stringsAsFactors = FALSE),
    c(`# of Instruments` = INT_FMT, `P value` = P_FMT, `Egger intercept P` = P_FMT,
      `Heterogeneity P` = P_FMT))


## ---- ST12  proteome-wide MR ----------------------------------------------------------
ranked <- proteome[order(proteome$ivw_pval), ]
add("ST12",
    "Proteome-wide Mendelian randomization estimates across all tested UK Biobank plasma proteins.",
    data.frame(
        `Protein Id` = ranked$protein_id, `Gene Name` = ranked$gene_name,
        `# of Instruments` = ranked$n_snps,
        `IVW Beta` = ranked$ivw_beta, `IVW SE` = ranked$ivw_se,
        `IVW P` = ranked$ivw_pval, `IVW P Bonferroni` = ranked$ivw_pval_bonf,
        `Weighted Median Beta` = ranked$median_beta,
        `Weighted Median SE` = ranked$median_se,
        `Weighted Median P` = ranked$median_pval,
        `Egger Beta` = ranked$egger_beta, `Egger SE` = ranked$egger_se,
        `Egger P` = ranked$egger_pval,
        `Egger Intercept` = ranked$egger_intercept,
        `Egger Intercept P` = ranked$egger_intercept_pval,
        `Heterogeneity Q` = ranked$ivw_het_q, `Heterogeneity P` = ranked$ivw_het_p,
        check.names = FALSE, stringsAsFactors = FALSE),
    c(`# of Instruments` = INT_FMT, `IVW P` = P_FMT, `IVW P Bonferroni` = P_FMT,
      `Weighted Median P` = P_FMT, `Egger P` = P_FMT, `Egger Intercept P` = P_FMT,
      `Heterogeneity P` = P_FMT))


## ---- ST13  over-representation analysis ------------------------------------------------
# Step 10 keeps every term at adjusted P < 0.5, both directions and both
# collections, and all of it ships: Methods 3.10 says the two directions were
# tested separately, so the raised set belongs here even though Results 4.5
# discusses only the lowered one. Shipping the whole table also puts the real
# background on the page - BgRatio's denominator is 2,745, not the 2,922 supplied,
# because the rest carry no GO annotation.
ora <- read_result("10_proteome_ora/ukb_ppp_proteome_ora.tsv")
DIRECTION <- c(lowered_by_inhibition = "Lower with lower NLRP3 activity",
               raised_by_inhibition  = "Higher with lower NLRP3 activity")
ora <- ora[order(match(ora$direction, names(DIRECTION)), ora$collection, ora$p.adjust), ]
add("ST13",
    "Over-representation analysis of the proteins altered by lower NLRP3 activity, for the lowered and raised sets separately.",
    data.frame(
        Direction = unname(DIRECTION[ora$direction]), Collection = ora$collection,
        `Term ID` = ora$ID, Description = ora$Description,
        # Left as text; Excel reads "3/4" and "66/2745" as dates otherwise.
        `Gene ratio` = ora$GeneRatio, `Background ratio` = ora$BgRatio,
        `# Genes` = ora$Count,
        `P value` = ora$pvalue, `Adjusted P value` = ora$p.adjust,
        `Q value` = ora$qvalue,
        Genes = gsub("/", ", ", ora$geneID),
        check.names = FALSE, stringsAsFactors = FALSE, row.names = NULL),
    c(`# Genes` = INT_FMT, `P value` = P_FMT, `Adjusted P value` = P_FMT,
      `Q value` = P_FMT))


## ---- ST14  CAD sensitivity analyses ----------------------------------------------------
sweep <- read_result("11_mr_sensitivity/r2_sweep.tsv")
single_variant <- read_result("11_mr_sensitivity/single_variant.tsv")

# One block per analysis, all on the same columns. The single-variant Wald ratio
# has no diagnostics, so optional() leaves those four columns empty for it.
sensitivity_block <- function(analysis, d) data.frame(
    Analysis = analysis, Method = method_label(d$method),
    `# of Instruments` = d$n_snps,
    OR = exp(d$estimate), `95% CI (OR)` = ci(exp(d$ci_lower), exp(d$ci_upper)),
    `SE (log OR)` = d$se, `P value` = d$p,
    `Egger intercept` = ifelse(d$method == "IVW", optional(d, "egger_intercept"), NA),
    `Egger intercept P` = ifelse(d$method == "IVW", optional(d, "egger_intercept_p"), NA),
    `Heterogeneity Q` = optional(d, "het_q"),
    `Heterogeneity P` = optional(d, "het_p"),
    check.names = FALSE, stringsAsFactors = FALSE)

add("ST14",
    "Sensitivity analyses for the coronary artery disease association: LD thresholds, leave-one-out and single variant.",
    rbind(
        sensitivity_block(sprintf("LD clumping r2 < %.1f", sweep$r2_threshold), sweep),
        sensitivity_block(ifelse(leave_one_out$dropped == "none", "All instruments",
                                 paste("Leave-one-out: excluding", leave_one_out$dropped)),
                          leave_one_out),
        sensitivity_block("Shared colocalising variant only (rs12239046)", single_variant)),
    c(`# of Instruments` = INT_FMT, `P value` = P_FMT,
      `Egger intercept P` = P_FMT, `Heterogeneity P` = P_FMT))


## ---- ST15  exploratory disease indications ------------------------------------------------
exploratory <- indications[!indication_key %in% IMAGING, ]
add("ST15",
    "Mendelian randomization estimates for the NLRP3 activity score across the exploratory disease indications.",
    data.frame(
        Outcome = exploratory$outcome, Method = method_label(exploratory$method),
        `# of Instruments` = exploratory$nsnp,
        OR = exp(exploratory$estimate),
        `95% CI (OR)` = ci(exp(exploratory$ci_lower), exp(exploratory$ci_upper)),
        `SE (log OR)` = exploratory$se, `P value` = exploratory$p,
        check.names = FALSE, stringsAsFactors = FALSE),
    c(`# of Instruments` = INT_FMT, `P value` = P_FMT))


## ---- write ----------------------------------------------------------------------------
# Sheet ids are zero-padded, so sorting them gives ST01 ... ST16 in order.
ids <- sort(names(sheets))
contents <- data.frame(
    Sheet = ids,
    Contents = vapply(sheets[ids], `[[`, character(1), "contents"),
    check.names = FALSE, stringsAsFactors = FALSE, row.names = NULL)

header_style <- createStyle(textDecoration = "bold", valign = "top", wrapText = TRUE)
body_style <- createStyle(valign = "top")

# A column's format is the one the sheet asked for; otherwise four decimals for
# numbers and nothing for text.
column_format <- function(name, values, fmt) {
    if (name %in% names(fmt)) fmt[[name]] else if (is.numeric(values)) "0.0000" else NULL
}
# Wide enough for the header and the longest value, within reason.
column_width <- function(name, values) {
    longest_value <- if (is.character(values)) {
        suppressWarnings(max(nchar(values), na.rm = TRUE)) + 2
    } else {
        12
    }
    width <- min(46, max(11, nchar(name) + 2, longest_value))
    if (is.finite(width)) width else 14
}

wb <- createWorkbook()
write_sheet <- function(id, x, fmt = character(), widths = NULL) {
    addWorksheet(wb, id)
    writeData(wb, id, x, headerStyle = header_style, keepNA = TRUE, na.string = "NA",
              withFilter = FALSE)
    data_rows <- seq_len(nrow(x)) + 1L
    addStyle(wb, id, body_style, rows = data_rows, cols = seq_along(x), gridExpand = TRUE)

    for (j in seq_along(x)) {
        name <- names(x)[j]
        values <- x[[j]]

        f <- column_format(name, values, fmt)
        if (!is.null(f)) {
            addStyle(wb, id, createStyle(numFmt = f), data_rows, j,
                     gridExpand = TRUE, stack = TRUE)
            # A fixed-decimal format must not display a small nonzero value as 0.
            if (f == "0.0000") {
                tiny <- which(!is.na(values) & values != 0 & abs(values) < 5e-5)
                if (length(tiny)) {
                    addStyle(wb, id, createStyle(numFmt = P_FMT), data_rows[tiny], j,
                             stack = TRUE)
                }
            }
        }
        setColWidths(wb, id, j,
                     if (!is.null(widths)) widths[j] else column_width(name, values))
    }
    freezePane(wb, id, firstActiveRow = 2)
}

write_sheet("Contents", contents, widths = c(10, 120))
for (id in ids) write_sheet(id, sheets[[id]]$table, sheets[[id]]$fmt)

tmp <- tempfile("supp_", tmpdir = dirname(output), fileext = ".xlsx")
saveWorkbook(wb, tmp, overwrite = TRUE)

# openxlsx 4.2.8 writes a relationship to xl/drawings/drawingN.xml for every sheet
# even when no drawing exists, which makes the file unreadable by openpyxl/pandas.
# Strip those dangling relationships.
strip_drawing_rels <- function(path) {
    dir <- tempfile("xlsxfix_"); dir.create(dir)
    on.exit(unlink(dir, recursive = TRUE), add = TRUE)
    utils::unzip(path, exdir = dir)
    for (f in list.files(file.path(dir, "xl", "worksheets", "_rels"), full.names = TRUE)) {
        txt <- paste(readLines(f, warn = FALSE), collapse = "\n")
        writeLines(gsub('<Relationship[^>]*Target="\\.\\./drawings/[^"]*"[^>]*/>', "", txt), f)
    }
    old <- setwd(dir); on.exit(setwd(old), add = TRUE)
    unlink(path)
    utils::zip(path, list.files(".", recursive = TRUE, all.files = TRUE), flags = "-qX")
}
strip_drawing_rels(tmp)

invisible(file.rename(tmp, output))
message(sprintf("Wrote %s\n  %d sheets, %d data rows, no synthetic values.",
                output, length(sheets) + 1L,
                sum(vapply(sheets, function(s) nrow(s$table), integer(1)))))
