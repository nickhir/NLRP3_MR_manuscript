## 06 - Cardiometabolic and lifestyle risk factors
##
## MR of the activity score against eleven lipid, blood-pressure, adiposity and
## lifestyle traits. Writes results/06_mr_cardiometabolic/.

suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(here)
})

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("06_mr_cardiometabolic")

exposure    <- load_instruments(negate = TRUE)
instruments <- exposure$SNP

ld_full <- interval_ld_matrix(instruments)

# The eight instruments in both builds. This doubles as the GRCh37 -> GRCh38
# position map harmonise_region() wants, and restricting it to the instruments
# is the point: nothing else is needed at this locus.
pos_map <- exposure |> select(pos_hg19, pos_hg38)

# The locus in each build. GRCh37 coordinates come from the instruments, so the
# window is centred on them rather than on a hardcoded offset.
WINDOW <- 200000L
REGION <- list(
    GRCh38 = c(LOCUS_START, LOCUS_END),
    GRCh37 = c(min(exposure$pos_hg19) - WINDOW, max(exposure$pos_hg19) + WINDOW)
)


## ---- run one trait -----------------------------------------------------------
run_trait <- function(key) {
    cfg <- CARDIOMETABOLIC[[key]]
    message(sprintf("  %-14s (%s, %s) ...", cfg$label, cfg$accession, cfg$build))

    rng <- REGION[[cfg$build]]
    raw <- read_region(cfg, CHR, rng[1], rng[2])

    # Confirm the file is on the build it claims before trusting any match.
    verify_build(raw, cfg$build, cfg$label, exposure)

    harmonised <- harmonise_region(raw, cfg, CHR, pos_map = pos_map)

    # Traits reported in native units are put on an SD scale, exactly as
    # analysis/07a_mediator_instruments.R does it, so that this panel shares
    # one axis and SBP here matches the mediation alpha.
    sd_scale <- 1
    if (isTRUE(cfg$standardise_sd)) {
        d <- tibble(se = as.numeric(raw$se),
                    eaf = as.numeric(raw$eaf),
                    n = as.numeric(raw$n)) |>
            filter(!is.na(se), !is.na(eaf), !is.na(n))
        s <- coloc:::sdY.est(vbeta = d$se^2,
                             maf = pmin(d$eaf, 1 - d$eaf),
                             n = round(median(d$n)))
        sd_scale <- if (is.finite(s) && s > 2) s else 1
        harmonised <- harmonised |> mutate(beta = beta / sd_scale,
                                           se   = se   / sd_scale)
    }

    outcome <- harmonised |> filter(SNPid %in% instruments)

    dat <- exposure |>
        select(SNP, beta_exposure, se_exposure) |>
        left_join(outcome |> select(SNP = SNPid,
                                    beta_outcome = beta, se_outcome = se),
                  by = "SNP") |>
        mutate(outcome = cfg$label)

    run_mr(dat, ld_full) |>
        mutate(trait    = key,
               group    = cfg$group,
               n_label  = cfg$n_label,
               binary   = !is.null(cfg$n_cases),
               sd_scale = sd_scale,
               .before  = 1)
}

results <- lapply(names(CARDIOMETABOLIC), run_trait) |> bind_rows()


## ---- assemble ------------------------------------------------------------------
results <- results |>
    mutate(method = recode(method, "IVW (LD-corrected)" = "IVW"),
           ld_corrected = method == "IVW") |>
    select(group, trait, outcome, method, estimate, se, ci_lower, ci_upper, p,
           nsnp, n_label, binary, sd_scale, ld_corrected) |>
    arrange(match(trait, names(CARDIOMETABOLIC)),
            match(method, c("IVW", "Weighted median")))


## ---- report --------------------------------------------------------------------
ivw <- results |> filter(method == "IVW")
message("\nIVW:")
for (i in seq_len(nrow(ivw))) {
    message(sprintf("  %-14s %2d SNPs  %7.3f (%7.3f, %7.3f)  P=%8.3g",
                    ivw$outcome[i], ivw$nsnp[i], ivw$estimate[i],
                    ivw$ci_lower[i], ivw$ci_upper[i], ivw$p[i]))
}

fwrite(results, file.path(out_dir, "cardiometabolic_mr.tsv"), sep = "\t")
message("\nDone -> ", file.path(out_dir, "cardiometabolic_mr.tsv"))
