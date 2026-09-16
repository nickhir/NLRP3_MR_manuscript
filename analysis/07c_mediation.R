## 07c - Mediation of NLRP3 -> CAD by SBP, ApoB and T2D
##
## Product-of-coefficients mediation, with MVMR among the three mediators for
## their mutually adjusted effects on CAD. Writes results/07c_mediation/.

suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(here)
})

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("07c_mediation")
set.seed(20260907)
N_DRAWS <- 100000L

med_dir <- file.path(results_dir, "07a_mediator_instruments")
ovl_dir <- file.path(results_dir, "07b_sample_overlap")
# 05_mr_cad.R writes into its own step directory. Reading results_dir instead picked up
# an orphan left by the retired 03_cad_meta_studies.R, so re-running 05 could not
# reach 07c. If 05 has not been run, the existence check below now fails loudly.
cad_dir <- file.path(results_dir, "05_mr_cad")

MEDS <- names(MEDIATORS)            # SBP, ApoB, T2D - the order used throughout


## ---- instruments and LD --------------------------------------------------------------
# negate = TRUE flips beta onto the LOWER-activity scale, so every downstream
# effect is per one unit DECREASE in the activity score.
ex <- load_instruments(negate = TRUE)
R  <- interval_ld_matrix(ex$SNP)
R  <- R[ex$SNP, ex$SNP]

bx <- ex$beta_exposure
message(sprintf("8 cis instruments loaded, LD matrix %d x %d\n", nrow(R), ncol(R)))


## ---- a single correlated-IVW engine ---------------------------------------------------
# One function for tau and for every alpha, so the total and the mediator paths
# cannot drift apart. Returns the estimate, its variance, and the information
# I = bx' Omega^-1 bx that 07b's rho formula also needs.
correlated_ivw <- function(bx, by, se_y, R) {
    S     <- diag(se_y, nrow = length(se_y))
    Omega <- S %*% R %*% S
    Oi    <- solve(Omega)
    info  <- as.numeric(t(bx) %*% Oi %*% bx)
    list(est  = as.numeric(t(bx) %*% Oi %*% by) / info,
         var  = 1 / info,
         info = info,
         Sinv = solve(S))
}


## ---- 1. total effect ------------------------------------------------------------------
# tau and beta MUST rest on the same CAD studies.
.prov_cad <- readRDS(file.path(med_dir, "selection_summary.rds"))$cad_included
TAU_STUDIES <- unname(sapply(CAD_STUDIES[.prov_cad], `[[`, "label"))
message(sprintf("1. CAD studies taken from 07a provenance: %s",
                paste(TAU_STUDIES, collapse = ", ")))

cad_per_study <- fread(file.path(cad_dir, "cad_meta_studies_per_snp.tsv"),
                       data.table = FALSE) %>%
    filter(study %in% TAU_STUDIES)
missing_study <- setdiff(TAU_STUDIES, unique(cad_per_study$study))
if (length(missing_study) > 0)
    stop("CAD study absent from cad_meta_studies_per_snp.tsv: ",
         paste(missing_study, collapse = ", "))

# Fixed effect, on the same A1 orientation 05_mr_cad.R already applied.
cad <- cad_per_study %>%
    group_by(SNP) %>%
    summarise(by   = sum(by / byse^2) / sum(1 / byse^2),
              byse = sqrt(1 / sum(1 / byse^2)),
              .groups = "drop")
cad <- cad[match(ex$SNP, cad$SNP), ]


tau_fit <- correlated_ivw(bx, cad$by, cad$byse, R)
tau     <- tau_fit$est
var_tau <- tau_fit$var

message(sprintf("   Total effect tau = %.4f (SE %.4f), OR %.3f (%.3f, %.3f), P = %.3g",
                tau, sqrt(var_tau), exp(tau),
                exp(tau - 1.96 * sqrt(var_tau)), exp(tau + 1.96 * sqrt(var_tau)),
                2 * pnorm(-abs(tau / sqrt(var_tau)))))


## ---- 2. NLRP3 -> mediator ---------------------------------------------------------------
prov <- readRDS(file.path(med_dir, "selection_summary.rds"))
sd_scales <- prov$sd_scales
message(sprintf("\n2. Mediator SD scales from 07a: %s",
                paste(sprintf("%s=%.3f", names(sd_scales), sd_scales), collapse = ", ")))

alpha_fits <- lapply(MEDS, function(k) {
    cfg <- MEDIATORS[[k]]
    d <- lookup_at(cfg, ex$SNP, ex$chr, ex$pos_hg38, cfg$label)
    miss <- setdiff(ex$SNP, d$SNPid)
    if (length(miss) > 0)
        stop(sprintf("[%s] %d of 8 cis instruments absent: %s",
                     cfg$label, length(miss), paste(miss, collapse = ", ")))
    d <- d[match(ex$SNP, d$SNPid), ]

    # The same SD scaling 07a applied before fitting the MVMR.
    fit <- correlated_ivw(bx, d$beta / sd_scales[[k]], d$se / sd_scales[[k]], R)
    fit$Sinv_med <- fit$Sinv
    fit$label <- cfg$label
    fit
})
names(alpha_fits) <- MEDS

alpha     <- sapply(alpha_fits, `[[`, "est")
var_alpha <- sapply(alpha_fits, `[[`, "var")
info      <- sapply(alpha_fits, `[[`, "info")

for (k in MEDS)
    message(sprintf("   alpha[%s] = %+.4f (SE %.4f) SD per unit lower activity",
                    k, alpha[[k]], sqrt(var_alpha[[k]])))


## ---- 3. mediators -> CAD, mutually adjusted ---------------------------------------------
design <- fread(file.path(med_dir, "mvmr_design.tsv"), data.table = FALSE)
BX  <- as.matrix(design[, paste0("beta_sd_", MEDS)])
SEX <- as.matrix(design[, paste0("se_sd_",   MEDS)])
by  <- design$beta_cad; byse <- design$se_cad

message(sprintf("\n3. MVMR over %s variants", format(nrow(design), big.mark = ",")))

# IVW-style MVMR: outcome betas on exposure betas, no intercept, weighted by the
# inverse outcome variance. Fitting with lm gives the full vcov directly.
mvmr_df <- as.data.frame(BX); names(mvmr_df) <- MEDS; mvmr_df$by <- by
mvmr_fit <- lm(reformulate(MEDS, response = "by", intercept = FALSE),
               data = mvmr_df, weights = 1 / byse^2)

beta <- coef(mvmr_fit)[MEDS]

# Multiplicative random effects, the MendelianRandomization default: the
# residual scale is kept when there is over-dispersion (sigma > 1), floored at
# 1 so standard errors are never pulled below their nominal value.
sig      <- summary(mvmr_fit)$sigma
Sigma_bb <- vcov(mvmr_fit)[MEDS, MEDS] * (max(sig, 1) / sig)^2
message(sprintf("   residual scale sigma = %.2f (SEs inflated %.2fx for heterogeneity)",
                sig, max(sig, 1)))

for (k in MEDS)
    message(sprintf("   beta[%s]  = %+.4f (SE %.4f) log-OR CAD per SD",
                    k, beta[[k]], sqrt(Sigma_bb[k, k])))

# Conditional F, so weak-instrument bias in this step is visible rather than
# assumed away. Needs the per-SNP covariance between exposure estimates, which
# is where rho enters a second time (Sanderson et al. 2021).
rho <- readRDS(file.path(ovl_dir, "rho.rds"))[MEDS, MEDS]
ut <- which(upper.tri(rho), arr.ind = TRUE)
message(sprintf("\n4. rho (from 07b): %s",
                paste(sprintf("%s~%s=%+.3f", MEDS[ut[, 1]], MEDS[ut[, 2]], rho[ut]),
                      collapse = ", ")))

fmt <- MVMR::format_mvmr(BXGs = BX, BYG = by, seBXGs = SEX, seBYG = byse,
                         RSID = design$SNPid)
cv  <- MVMR::phenocov_mvmr(pcor = rho, seBXGs = SEX)
cond_F <- as.numeric(MVMR::strength_mvmr(r_input = fmt, gencov = cv))
if (!is.null(cond_F))
    message(sprintf("   conditional F: %s",
                    paste(sprintf("%s=%.1f", MEDS, cond_F), collapse = ", ")))

Q_stat <- sum(residuals(mvmr_fit)^2 / byse^2)
message(sprintf("   Q = %.0f on %d df (P = %.3g)", Q_stat, nrow(design) - length(MEDS),
                pchisq(Q_stat, nrow(design) - length(MEDS), lower.tail = FALSE)))


## ---- 5. assemble Sigma_theta --------------------------------------------------------
# Cov(alpha_m, alpha_m') = rho_mm' * C_mm' / (I_m * I_m'),  C = bx' S_m^-1 R^-1 S_m'^-1 bx
# using Omega^-1 S = S^-1 R^-1. Setting rho = 0 makes the off-diagonals vanish,
# which is the bound check at the end.
Ri <- solve(R)

sigma_alpha <- function(rho_mat) {
    S <- diag(var_alpha, nrow = length(MEDS)); dimnames(S) <- list(MEDS, MEDS)
    for (i in seq_along(MEDS)) for (j in seq_along(MEDS)) {
        if (j <= i) next
        C <- as.numeric(t(bx) %*% alpha_fits[[i]]$Sinv %*% Ri %*% alpha_fits[[j]]$Sinv %*% bx)
        S[i, j] <- S[j, i] <- rho_mat[i, j] * C / (info[i] * info[j])
    }
    S
}

# Sigma_alpha_beta = 0: alpha uses the 8 cis SNPs, beta uses genome-wide
# instruments elsewhere, and effect estimates at unlinked variants from the same
# GWAS are uncorrelated.
K  <- length(MEDS)
iA <- seq_len(K); iB <- K + iA

build_sigma <- function(rho_mat) {
    nm <- c(paste0("a_", MEDS), paste0("b_", MEDS))
    S  <- matrix(0, 2 * K, 2 * K, dimnames = list(nm, nm))
    S[iA, iA] <- sigma_alpha(rho_mat)
    S[iB, iB] <- Sigma_bb
    S
}

Sigma_theta <- build_sigma(rho)


## ---- 6. indirect effects, proportion mediated ----------------------------------------
# Per mediator: only the diagonal, so unaffected by rho.
per_mediator <- tibble(
    mediator = MEDS,
    label    = sapply(MEDIATORS[MEDS], `[[`, "label"),
    alpha = alpha, se_alpha = sqrt(var_alpha),
    beta  = beta,  se_beta  = sqrt(diag(Sigma_bb)),
    indirect = alpha * beta,
    se_indirect = sqrt(beta^2 * var_alpha + alpha^2 * diag(Sigma_bb))
) %>%
    mutate(or = exp(indirect),
           or_lower = exp(indirect - 1.96 * se_indirect),
           or_upper = exp(indirect + 1.96 * se_indirect),
           p = 2 * pnorm(-abs(indirect / se_indirect)),
           pm_alone = indirect / tau)

joint_indirect <- function(Sigma) {
    ie   <- sum(alpha * beta)
    grad <- c(beta, alpha)
    list(ie = ie, var = as.numeric(t(grad) %*% Sigma %*% grad))
}

J      <- joint_indirect(Sigma_theta)
ie     <- J$ie
se_ie  <- sqrt(J$var)
direct <- tau - ie
se_dir <- sqrt(var_tau + J$var)     # Cov(tau, IE) = 0, as in the manuscript

# Proportion mediated by Monte Carlo. PM is a ratio whose denominator is an
# imprecise total effect, so its distribution is skewed and a delta-method
# interval on it would be too narrow.
draw_theta <- MASS::mvrnorm(N_DRAWS, mu = c(alpha, beta), Sigma = Sigma_theta)
draw_tau   <- rnorm(N_DRAWS, tau, sqrt(var_tau))
draw_ie    <- rowSums(draw_theta[, iA, drop = FALSE] * draw_theta[, iB, drop = FALSE])
draw_pm    <- draw_ie / draw_tau

pm_ci <- quantile(draw_pm, c(0.025, 0.975), names = FALSE)

message(sprintf("\n6. Joint indirect effect = %.4f (SE %.4f), OR %.3f (%.3f, %.3f)",
                ie, se_ie, exp(ie), exp(ie - 1.96 * se_ie), exp(ie + 1.96 * se_ie)))
message(sprintf("   Direct effect          = %.4f (SE %.4f), OR %.3f (%.3f, %.3f)",
                direct, se_dir, exp(direct),
                exp(direct - 1.96 * se_dir), exp(direct + 1.96 * se_dir)))
message(sprintf("   Proportion mediated    = %.1f%%  (95%% CI %.1f%% to %.1f%%, Monte Carlo)",
                100 * ie / tau, 100 * pm_ci[1], 100 * pm_ci[2]))

message("\n   Per mediator:")
for (i in seq_len(nrow(per_mediator))) with(per_mediator[i, ],
    message(sprintf("     %-28s indirect OR %.3f (%.3f, %.3f), %4.1f%% of total",
                    label, or, or_lower, or_upper, 100 * pm_alone)))


## ---- checks --------------------------------------------------------------------------
# (a) Bounds on rho. The estimated result must sit between rho = 0 and rho = 1;
#     rho = 1 is the conservative convention already used for the activity
#     score's own standard errors. Printed as a diagnostic, not reported.
bound <- sapply(list(zero = diag(1, K), est = rho, one = matrix(1, K, K)), function(m) {
    dimnames(m) <- list(MEDS, MEDS)
    sqrt(joint_indirect(build_sigma(m))$var)
})
message(sprintf("\nCheck - SE of the joint indirect effect: rho=0 %.4f | estimated %.4f | rho=1 %.4f",
                bound[["zero"]], bound[["est"]], bound[["one"]]))
# rho = 1 is an upper bound; rho = 0 is a lower bound only when every estimated
# rho is non-negative. A negative rho legitimately puts the SE below the rho = 0
# value, so only the upper bound is asserted.
if (bound[["est"]] > bound[["one"]] + 1e-9)
    warning("the estimated SE exceeds the rho = 1 bound")
if (any(rho[upper.tri(rho)] < 0))
    message("      (rho is negative for at least one pair, so the estimate may sit below the rho=0 value)")

# (b) Difference method. IVW is linear in the outcome betas, so subtracting the
# mediator-explained part of each SNP's CAD effect and re-running must
# reproduce tau - IE.
med_at_cis <- sapply(MEDS, function(k) {
    cfg <- MEDIATORS[[k]]
    d <- lookup_at(cfg, ex$SNP, ex$chr, ex$pos_hg38, cfg$label)
    d <- d[match(ex$SNP, d$SNPid), ]
    d$beta / sd_scales[[k]]
})
by_adj  <- cad$by - as.numeric(med_at_cis %*% beta)
direct2 <- correlated_ivw(bx, by_adj, cad$byse, R)$est
# The two agree exactly only under common weights; alpha uses per-mediator
# Omega_m while tau uses Omega_Y, so a small discrepancy is expected.
message(sprintf("Check - direct effect: product of coefficients %.4f | difference method %.4f | diff %.4f (%.1f%% of SE(tau))",
                direct, direct2, abs(direct - direct2),
                100 * abs(direct - direct2) / sqrt(var_tau)))


## ---- output ---------------------------------------------------------------------------
summary_tbl <- tibble(
    quantity = c("Total effect", "Joint indirect", "Direct effect"),
    estimate = c(tau, ie, direct),
    se       = c(sqrt(var_tau), se_ie, se_dir)) %>%
    mutate(or = exp(estimate),
           or_lower = exp(estimate - 1.96 * se),
           or_upper = exp(estimate + 1.96 * se),
           p = 2 * pnorm(-abs(estimate / se)))

pm_tbl <- tibble(proportion_mediated = ie / tau,
                 ci_lower = pm_ci[1], ci_upper = pm_ci[2],
                 method = "Monte Carlo", n_draws = N_DRAWS)

fwrite(summary_tbl,  file.path(out_dir, "mediation_summary.tsv"), sep = "\t")
fwrite(per_mediator, file.path(out_dir, "mediation_per_mediator.tsv"), sep = "\t")
fwrite(pm_tbl,       file.path(out_dir, "proportion_mediated.tsv"), sep = "\t")

saveRDS(list(tau = tau, var_tau = var_tau, alpha = alpha, var_alpha = var_alpha,
             beta = beta, Sigma_bb = Sigma_bb, rho = rho, Sigma_theta = Sigma_theta,
             ie = ie, var_ie = J$var, direct = direct, se_direct = se_dir,
             pm = ie / tau, pm_ci = pm_ci, pm_draws = draw_pm,
             cond_F = cond_F, Q = Q_stat, n_mvmr = nrow(design),
             se_bounds = bound, direct_difference_method = direct2,
             exposure_direction = EXPOSURE_DIRECTION),
        file.path(out_dir, "mediation.rds"))

message(sprintf("\n-> \"Jointly, %s mediated %.0f%% (95%% CI %.0f-%.0f%%) of the association",
                paste(rev(sapply(MEDIATORS[MEDS], `[[`, "label")), collapse = ", "),
                100 * ie / tau, 100 * pm_ci[1], 100 * pm_ci[2]))
message("    between genetically lowered NLRP3 activity and CAD risk.\"")
message("\nDone -> ", out_dir)
