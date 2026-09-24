## 07d - Sequential attenuation of the NLRP3 -> CAD effect
##
## What is left of the total effect after SBP, then SBP + ApoB, then all three,
## each model fitted on its own pooled clump. Writes
## results/07d_mediation_waterfall/.

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("07d_mediation_waterfall")
med_dir <- file.path(results_dir, "07a_mediator_instruments")
ORDER <- names(MEDIATORS) # SBP, ApoB, T2D: the order the panel reads

# tau, alpha and the alpha covariances from 07c, whose off-diagonals carry the
# sample overlap between the mediator GWAS
m <- readRDS(file.path(results_dir, "07c_mediation", "mediation.rds"))
tau <- m$tau
var_tau <- m$var_tau
alpha <- m$alpha[ORDER]
Sigma_alpha <- m$Sigma_theta[paste0("a_", ORDER), paste0("a_", ORDER), drop = FALSE]
dimnames(Sigma_alpha) <- list(ORDER, ORDER)

design <- fread(file.path(med_dir, "mvmr_design.tsv"), data.table = FALSE)
instrument_sets <- readRDS(file.path(med_dir, "mvmr_instrument_sets.rds"))

# Row 0 is the total effect; row k removes the indirect effect of the first k
# mediators, with the betas of the k-mediator model.
steps <- list(list(meds = character(0), effect = tau, var = var_tau, fit = NULL,
                   label = "Total effect"))
for (i in seq_along(ORDER)) {
    meds <- ORDER[seq_len(i)]
    f <- fit_mvmr(design, instrument_sets[[paste(meds, collapse = "+")]], meds)
    a <- alpha[meds]
    Sig <- matrix(0, 2 * i, 2 * i)
    Sig[seq_len(i), seq_len(i)] <- Sigma_alpha[meds, meds, drop = FALSE]
    Sig[i + seq_len(i), i + seq_len(i)] <- f$V
    g <- c(f$beta, a)
    steps[[i + 1]] <- list(
        meds = meds,
        effect = tau - sum(a * f$beta),
        var = var_tau + as.numeric(t(g) %*% Sig %*% g),
        fit = f,
        label = paste0("after accounting\nfor ", paste(meds, collapse = " + "))
    )
}

res <- lapply(seq_along(steps), function(i) {
    s <- steps[[i]]
    tibble(step = i - 1,
           label = s$label,
           accounted = if (length(s$meds) == 0) NA_character_ else paste(s$meds, collapse = "+"),
           n_variants = if (is.null(s$fit)) NA_integer_ else s$fit$n,
           effect = s$effect,
           se = sqrt(s$var),
           or = exp(s$effect),
           or_lower = exp(s$effect - 1.96 * sqrt(s$var)),
           or_upper = exp(s$effect + 1.96 * sqrt(s$var)),
           p = 2 * pnorm(-abs(s$effect / sqrt(s$var))))
}) %>%
    bind_rows() %>%
    # what each mediator removed, on the OR scale the panel's axis is drawn on
    mutate(added = c(NA_character_, ORDER),
           added_label = c(NA_character_, unname(sapply(MEDIATORS[ORDER], `[[`, "label"))),
           delta_or = c(NA_real_, -diff(or)))

print(as.data.frame(select(res, accounted, or, or_lower, or_upper, p, delta_or)),
      row.names = FALSE, digits = 3)

fwrite(res, file.path(out_dir, "waterfall.tsv"), sep = "\t")
saveRDS(list(steps = steps, order = ORDER, tau = tau, var_tau = var_tau,
             alpha = alpha, Sigma_alpha = Sigma_alpha),
        file.path(out_dir, "waterfall.rds"))
