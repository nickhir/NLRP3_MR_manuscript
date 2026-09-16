## 03 - Instrument strength and variance explained
##
## Reports LD-aware joint F for the activity score and R2 for each measured
## readout. Writes results/03_instrument_strength/.

suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(here)
})

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("03_instrument_strength")

# The aligned readouts from step 02.
table_file <- file.path(results_dir, "02_instrument_table",
                        "instrument_table_aligned.tsv")
if (!file.exists(table_file)) stop("run analysis/02_instrument_table.R first")

aligned     <- fread(table_file, data.table = FALSE)
instruments <- aligned$SNP
K           <- length(instruments)


## ---- LD matrix -------------------------------------------------------------------
message("Computing the INTERVAL LD matrix ...")
ld <- interval_ld_matrix(instruments)

ld_eigen <- eigen(ld, symmetric = TRUE)$values
message(sprintf("  max off-diagonal r2 = %.4f | kappa = %.2f | lambda_min = %.3f",
                max((ld^2)[upper.tri(ld)]), kappa(ld), min(ld_eigen)))

# Inversion noise would only start to matter as lambda_min approached
# K/sqrt(n_ref) ~ 8/109 ~ 0.07, so no ridge or PCA projection is needed.
stopifnot(kappa(ld) < 30, min(ld_eigen) > 0.1)
ld_inv <- solve(ld)


## ---- compute -----------------------------------------------------------------------
message("Computing instrument strength ...")

inputs <- c(
    lapply(names(READOUTS), function(k) list(
        label = k,
        beta  = aligned[[paste0("beta_", k)]],
        se    = aligned[[paste0("se_",   k)]],
        n     = READOUTS[[k]]$n)),
    list(list(label = "cis_NLRP3_activity_score",
              beta  = aligned$beta_exposure,
              se    = aligned$se_exposure,
              n     = NULL))
)

strength <- lapply(inputs, function(x) {
    c(list(label = x$label, n = if (is.null(x$n)) NA_real_ else x$n),
      joint_F_R2(x$beta, x$se, ld_inv, x$n))
})
names(strength) <- vapply(inputs, function(x) x$label, character(1))


## ---- tables --------------------------------------------------------------------------
joint_tbl <- lapply(strength, function(s) data.frame(
    trait = s$label, n_snps = K, n_samples = s$n,
    chi2 = s$chi2, F_joint = s$F_joint, F_mean = s$F_mean, F_min = s$F_min,
    R2_joint = s$R2_joint, R2_rho = s$R2_rho, R2_adj = s$R2_adj
)) |> bind_rows()

print(joint_tbl, row.names = FALSE, digits = 4)

per_snp_tbl <- lapply(inputs, function(x) {
    s <- strength[[x$label]]
    data.frame(SNP = instruments, trait = x$label,
               beta = x$beta, se = x$se, z = s$z,
               F = s$F_per_snp, R2 = s$R2_per_snp)
}) |> bind_rows()


## ---- effective sample size check --------------------------------------------------------
# Ntilde = 1/(2*MAF*(1-MAF)*SE^2) should track the stated N for a phenotype on
# a unit-variance scale. It does for CRP, GlycA and neutrophils.
eff_n <- lapply(names(READOUTS), function(k) {
    ne <- effective_n(aligned[[paste0("se_", k)]], aligned$eaf_exposure)
    data.frame(trait = k, n_stated = READOUTS[[k]]$n,
               n_effective = ne, ratio = ne / READOUTS[[k]]$n)
}) |> bind_rows()

print(eff_n, row.names = FALSE, digits = 4)


## ---- write ------------------------------------------------------------------------------
fwrite(joint_tbl,   file.path(out_dir, "instrument_strength_joint.tsv"),   sep = "\t")
fwrite(per_snp_tbl, file.path(out_dir, "instrument_strength_per_snp.tsv"), sep = "\t")
fwrite(eff_n,       file.path(out_dir, "effective_n_check.tsv"),           sep = "\t")
saveRDS(ld,         file.path(out_dir, "instrument_ld_matrix.rds"))

message("\nDone -> ", out_dir)
