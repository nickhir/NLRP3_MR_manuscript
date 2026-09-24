## 06 - Cardiometabolic and lifestyle risk factors
##
## MR of the activity score against eleven lipid, blood-pressure, adiposity and
## lifestyle traits. Writes results/06_mr_cardiometabolic/.

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("06_mr_cardiometabolic")

exposure <- load_instruments()
ld_full <- interval_ld_matrix(exposure$SNP)

run_trait <- function(key) {
    cfg <- CARDIOMETABOLIC[[key]]
    raw <- read_region(cfg, CHR, LOCUS_START, LOCUS_END)
    # Blood pressure is put on an SD scale, as step 07a does for SBP, so the
    # panel shares one axis and SBP here matches the mediation alpha.
    sd_scale <- if (isTRUE(cfg$standardise_sd)) {
        sd_from_se(as.numeric(raw$se), as.numeric(raw$eaf), as.numeric(raw$n))
    } else {
        1
    }
    # a GRCh37 release is matched on the instruments' GRCh37 positions
    if (cfg$build == "GRCh37") {
        raw$pos <- exposure$pos_hg38[match(raw$pos, exposure$pos_hg19)]
    }
    outcome <- harmonise(filter(raw, !is.na(pos)), cfg)

    exposure %>%
        select(SNP, beta_exposure, se_exposure) %>%
        left_join(transmute(outcome, SNP = SNPid, beta_outcome = beta / sd_scale,
                            se_outcome = se / sd_scale), by = "SNP") %>%
        mutate(outcome = cfg$label) %>%
        run_mr(ld_full) %>%
        mutate(trait = key, group = cfg$group, n_label = cfg$n_label,
               binary = isTRUE(cfg$binary), sd_scale = sd_scale, .before = 1)
}

results <- lapply(names(CARDIOMETABOLIC), run_trait) %>%
    bind_rows() %>%
    mutate(method = recode(method, "IVW (LD-corrected)" = "IVW"),
           ld_corrected = method == "IVW") %>%
    select(group, trait, outcome, method, estimate, se, ci_lower, ci_upper, p,
           nsnp, n_label, binary, sd_scale, ld_corrected)

print(as.data.frame(filter(results, method == "IVW")), row.names = FALSE, digits = 3)
fwrite(results, file.path(out_dir, "cardiometabolic_mr.tsv"), sep = "\t")
