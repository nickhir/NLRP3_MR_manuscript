## 03 - Instrument strength and variance explained
##
## LD-aware joint F for the activity score and each readout, and the variance
## each readout's instruments explain. Writes results/03_instrument_strength/.

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("03_instrument_strength")

aligned <- fread(file.path(results_dir, "02_instrument_table", "instrument_table_aligned.tsv"),
                 data.table = FALSE)
K <- nrow(aligned)

ld <- interval_ld_matrix(aligned$SNP)
# Inversion noise would matter only as lambda_min approached K/sqrt(n_ref)
# ~ 0.07, so no ridge is needed.
ld_inv <- solve(ld)

# Joint F and R2 from marginal summary statistics. The activity score has no
# sample size (n = NA), so its R2 are NA.
joint_F_R2 <- function(beta, se, n) {
    z <- beta / se
    chi2 <- as.numeric(t(z) %*% ld_inv %*% z)
    F_joint <- chi2 / K
    rho <- sign(z) * sqrt(z^2 / (z^2 + n - 2))
    list(
        z = z, chi2 = chi2, F_joint = F_joint, F_mean = mean(z^2), F_min = min(z^2),
        F_per_snp = z^2,
        # the first-stage F relation inverted: bounded in [0, 1], the most conservative
        R2_joint = F_joint / (F_joint + (n - K - 1) / K),
        # the marginal correlations combined through the LD; equal in exact arithmetic
        R2_rho = as.numeric(t(rho) %*% ld_inv %*% rho),
        # adjusted for the K degrees of freedom spent
        R2_adj = (chi2 - K) / (chi2 - K + n - K - 1),
        R2_per_snp = z^2 / (z^2 + n - 2)
    )
}

strength <- c(
    lapply(names(READOUTS), function(k) list(
        label = k, n = READOUTS[[k]]$n,
        beta = aligned[[paste0("beta_", k)]], se = aligned[[paste0("se_", k)]])),
    list(list(label = "cis_NLRP3_activity_score", n = NA_real_,
              beta = aligned$beta_exposure, se = aligned$se_exposure))
) %>% lapply(function(x) c(x, joint_F_R2(x$beta, x$se, x$n)))

joint_tbl <- lapply(strength, function(s) data.frame(
    trait = s$label, n_snps = K, n_samples = s$n,
    chi2 = s$chi2, F_joint = s$F_joint, F_mean = s$F_mean, F_min = s$F_min,
    R2_joint = s$R2_joint, R2_rho = s$R2_rho, R2_adj = s$R2_adj
)) %>% bind_rows()
print(joint_tbl, row.names = FALSE, digits = 4)

per_snp_tbl <- lapply(strength, function(s) data.frame(
    SNP = aligned$SNP, trait = s$label, beta = s$beta, se = s$se, z = s$z,
    F = s$F_per_snp, R2 = s$R2_per_snp
)) %>% bind_rows()

# Ntilde = 1/(2*MAF*(1-MAF)*SE^2), which should track the stated N for a
# phenotype on a unit-variance scale (the Genomic SEM identity).
maf <- pmin(aligned$eaf_exposure, 1 - aligned$eaf_exposure)
eff_n <- lapply(names(READOUTS), function(k) {
    ne <- median(1 / (2 * maf * (1 - maf) * aligned[[paste0("se_", k)]]^2))
    data.frame(trait = k, n_stated = READOUTS[[k]]$n, n_effective = ne,
               ratio = ne / READOUTS[[k]]$n)
}) %>% bind_rows()

fwrite(joint_tbl, file.path(out_dir, "instrument_strength_joint.tsv"), sep = "\t")
fwrite(per_snp_tbl, file.path(out_dir, "instrument_strength_per_snp.tsv"), sep = "\t")
fwrite(eff_n, file.path(out_dir, "effective_n_check.tsv"), sep = "\t")
saveRDS(ld, file.path(out_dir, "instrument_ld_matrix.rds"))
