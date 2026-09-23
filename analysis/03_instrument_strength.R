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

aligned     <- fread(table_file, data.table = FALSE)
instruments <- aligned$SNP
K           <- length(instruments)


## ---- LD matrix -------------------------------------------------------------------
ld <- interval_ld_matrix(instruments)

# Inversion noise would only start to matter as lambda_min approached
# K/sqrt(n_ref) ~ 8/109 ~ 0.07, so no ridge or PCA projection is needed.
ld_inv <- solve(ld)


## ---- compute -----------------------------------------------------------------------
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

# LD-aware instrument strength from marginal summary statistics.
joint_F_R2 <- function(beta, se, LD_inv, n = NULL) {
    z <- beta / se
    k <- length(z)
    chi2 <- as.numeric(t(z) %*% LD_inv %*% z)

    out <- list(
        z = z,
        chi2 = chi2,
        F_joint = chi2 / k,
        F_mean = mean(z^2),
        F_min = min(z^2),
        F_per_snp = z^2
    )

    if (is.null(n)) {
        out$R2_joint <- out$R2_rho <- out$R2_adj <- NA_real_
        out$R2_per_snp <- rep(NA_real_, k)
        return(out)
    }

    # Primary: invert the first-stage F relation. Bounded in [0,1] by
    # construction and the most conservative of the three.
    out$R2_joint <- out$F_joint / (out$F_joint + (n - k - 1) / k)

    # Marginal correlations combined through the LD matrix; identical in exact
    # arithmetic, reported so the agreement is visible.
    rho <- sign(z) * sqrt(z^2 / (z^2 + n - 2))
    out$R2_rho <- as.numeric(t(rho) %*% LD_inv %*% rho)

    # Adjusted for the K degrees of freedom spent (E[chi2] = K under the null).
    out$R2_adj <- (chi2 - k) / (chi2 - k + n - k - 1)

    out$R2_per_snp <- z^2 / (z^2 + n - 2)
    out
}

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
)) %>% bind_rows()

print(joint_tbl, row.names = FALSE, digits = 4)

per_snp_tbl <- lapply(inputs, function(x) {
    s <- strength[[x$label]]
    data.frame(SNP = instruments, trait = x$label,
               beta = x$beta, se = x$se, z = s$z,
               F = s$F_per_snp, R2 = s$R2_per_snp)
}) %>% bind_rows()


## ---- effective sample size check --------------------------------------------------------
# Effective sample size implied by the standard errors (the Genomic SEM
# identity).
effective_n <- function(se, eaf) {
    stats::median(
        1 / (2 * pmin(eaf, 1 - eaf) * (1 - pmin(eaf, 1 - eaf)) * se^2)
    )
}

# Ntilde = 1/(2*MAF*(1-MAF)*SE^2) should track the stated N for a phenotype on
# a unit-variance scale. It does for CRP, GlycA and neutrophils.
eff_n <- lapply(names(READOUTS), function(k) {
    ne <- effective_n(aligned[[paste0("se_", k)]], aligned$eaf_exposure)
    data.frame(trait = k, n_stated = READOUTS[[k]]$n,
               n_effective = ne, ratio = ne / READOUTS[[k]]$n)
}) %>% bind_rows()

print(eff_n, row.names = FALSE, digits = 4)


## ---- write ------------------------------------------------------------------------------
fwrite(joint_tbl,   file.path(out_dir, "instrument_strength_joint.tsv"),   sep = "\t")
fwrite(per_snp_tbl, file.path(out_dir, "instrument_strength_per_snp.tsv"), sep = "\t")
fwrite(eff_n,       file.path(out_dir, "effective_n_check.tsv"),           sep = "\t")
saveRDS(ld,         file.path(out_dir, "instrument_ld_matrix.rds"))

message("\nDone -> ", out_dir)
