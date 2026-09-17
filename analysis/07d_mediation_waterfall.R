## 07d - Sequential attenuation of the NLRP3 -> CAD effect
##
## Refits the mediator models one at a time to show what is left of the total
## effect after SBP, then SBP + ApoB, then all three.
## Writes results/07d_mediation_waterfall/.

suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(here)
})

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("07d_mediation_waterfall")

med_dir <- file.path(results_dir, "07a_mediator_instruments")
mdn_dir <- file.path(results_dir, "07c_mediation")

## The sequence the panel reads top to bottom.
ORDER <- c("SBP", "ApoB", "T2D")

LABELS <- sapply(MEDIATORS[ORDER], `[[`, "label")


## ---- 1. what 07c already settled --------------------------------------------------
m <- readRDS(file.path(mdn_dir, "mediation.rds"))

tau     <- m$tau
var_tau <- m$var_tau
alpha   <- m$alpha[ORDER]

# The alpha block of 07c's 6 x 6. Its off-diagonals carry the sample-overlap
# correlation between the mediator GWAS, so a sub-model's variance keeps them.
Sigma_alpha <- m$Sigma_theta[paste0("a_", ORDER), paste0("a_", ORDER), drop = FALSE]
dimnames(Sigma_alpha) <- list(ORDER, ORDER)


## ---- 2. the design, and which variants instrument what -----------------------------
design <- fread(file.path(med_dir, "mvmr_design.tsv"), data.table = FALSE)
ins    <- fread(file.path(med_dir, "mediator_instruments.tsv"), data.table = FALSE)

# Instrument membership, restricted to variants that survived into the design.
own <- lapply(ORDER, function(k)
    intersect(design$SNPid, ins$SNPid[ins$mediator == k]))
names(own) <- ORDER


## ---- 3. one MVMR fitter, used for every step ---------------------------------------
# Identical to 07c's: weighted least squares with no intercept, then the
# multiplicative random-effects correction with sigma floored at 1 so standard
# errors are never pulled below their nominal.
fit_mvmr <- function(meds) {
    rows <- design$SNPid %in% unlist(own[meds], use.names = FALSE)
    d    <- design[rows, , drop = FALSE]

    df <- as.data.frame(d[, paste0("beta_sd_", meds), drop = FALSE])
    names(df) <- meds
    df$by <- d$beta_cad

    f   <- lm(reformulate(meds, response = "by", intercept = FALSE),
              data = df, weights = 1 / d$se_cad^2)
    sig <- summary(f)$sigma
    V   <- vcov(f)[meds, meds, drop = FALSE] * (max(sig, 1) / sig)^2
    dimnames(V) <- list(meds, meds)

    list(beta  = coef(f)[meds],
         V     = V,
         sigma = sig,
         n     = nrow(d),
         Q     = sum(residuals(f)^2 / d$se_cad^2))
}

## ---- 4. walk the sequence ------------------------------------------------------------
# Row 0 is the total effect with nothing removed; row k removes the indirect
# effect carried by the first k mediators, using betas from the k-exposure
# model.
steps <- list(list(meds = character(0), effect = tau, var = var_tau,
                   fit = NULL, label = "Total effect"))

for (i in seq_along(ORDER)) {
    meds <- ORDER[seq_len(i)]
    f    <- fit_mvmr(meds)

    a  <- alpha[meds]
    b  <- f$beta[meds]
    ie <- sum(a * b)

    Sig <- matrix(0, 2 * i, 2 * i)
    Sig[seq_len(i), seq_len(i)]         <- Sigma_alpha[meds, meds, drop = FALSE]
    Sig[i + seq_len(i), i + seq_len(i)] <- f$V
    g <- c(b, a)

    steps[[i + 1]] <- list(
        meds   = meds,
        effect = tau - ie,
        var    = var_tau + as.numeric(t(g) %*% Sig %*% g),
        fit    = f,
        label  = paste0("after accounting\nfor ", paste(meds, collapse = " + ")))

}


## ---- 5. assemble ---------------------------------------------------------------------
res <- lapply(seq_along(steps), function(i) {
    s <- steps[[i]]
    tibble(step        = i - 1L,
           label       = s$label,
           accounted   = if (length(s$meds) == 0) NA_character_
                         else paste(s$meds, collapse = "+"),
           n_variants  = if (is.null(s$fit)) NA_integer_ else s$fit$n,
           effect      = s$effect,
           se          = sqrt(s$var),
           or          = exp(s$effect),
           or_lower    = exp(s$effect - 1.96 * sqrt(s$var)),
           or_upper    = exp(s$effect + 1.96 * sqrt(s$var)),
           p           = 2 * pnorm(-abs(s$effect / sqrt(s$var))))
}) %>% bind_rows()

# The arrow between two rows: how much of the odds ratio that mediator removed,
# ON THE OR SCALE, which is the scale the axis is drawn on.
res <- res %>%
    mutate(added      = c(NA_character_, ORDER),
           added_label = c(NA_character_, unname(LABELS)),
           delta_or   = c(NA_real_, -diff(or)))


## ---- 6. report, including the ways this can look wrong -------------------------------
message("Waterfall:")
for (i in seq_len(nrow(res))) {
    message(sprintf("  %-28s OR %.3f (%.3f, %.3f)  P = %.3g%s",
                    gsub("\n", " ", res$label[i]), res$or[i],
                    res$or_lower[i], res$or_upper[i], res$p[i],
                    if (is.na(res$delta_or[i])) ""
                    else sprintf("   [%s: dOR %+.3f]", res$added[i], res$delta_or[i])))
}

# A negative delta means that mediator INCREASED the residual effect - the bar
# grows instead of shrinking and the arrow points the wrong way.
back <- res %>% filter(!is.na(delta_or), delta_or < 0)
if (nrow(back) > 0)
    warning("delta_or < 0 for ", paste(back$added, collapse = ", "),
            " - the waterfall is not monotone; check the panel before using it",
            call. = FALSE)

# The bars are drawn from OR = 1. One below 1 would point the other way.
if (any(res$or < 1))
    warning("a residual OR is below 1; the panel draws bars rightward from 1",
            call. = FALSE)

fwrite(res, file.path(out_dir, "waterfall.tsv"), sep = "\t")
saveRDS(list(steps = steps, order = ORDER, tau = tau, var_tau = var_tau,
             alpha = alpha, Sigma_alpha = Sigma_alpha),
        file.path(out_dir, "waterfall.rds"))
message("\nDone -> ", file.path(out_dir, "waterfall.tsv"))
