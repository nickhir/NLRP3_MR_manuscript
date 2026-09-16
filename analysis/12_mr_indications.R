## 12 - Additional indications
##
## MR of the activity score against the candidate indication and imaging
## outcomes. Writes results/12_mr_indications/.

library(tidyverse)
library(data.table)
library(here)
library(MendelianRandomization)


## ----setup--------------------------------------------------------------------
source(here::here("config.R"))
source(here::here("helpers.R"))

output_dir <- step_dir("12_mr_indications")


## ----exposure-----------------------------------------------------------------
exposure <- fread(instrument_file, data.table = FALSE) %>%
    transmute(
        SNP = SNP,
        chr = as.integer(chr),
        pos_hg38 = as.integer(pos_hg38),
        A1 = toupper(A1),
        A2 = toupper(A2),
        eaf_exposure = as.numeric(eaf),
        beta_exposure = as.numeric(beta_exposure),
        se_exposure = as.numeric(se_exposure)
    )


## ----exposure_hg19_positions--------------------------------------------------
# GRCh37 positions for the same eight variants, needed to join the studies that
# were never lifted over.
hg19_lookup <- tribble(
    ~SNP              , ~pos_hg19  ,
    "1_247406019_C_T" , 247569321L ,
    "1_247432548_C_T" , 247595850L ,
    "1_247433558_A_C" , 247596860L ,
    "1_247438293_C_T" , 247601595L ,
    "1_247442302_A_G" , 247605604L ,
    "1_247452478_A_G" , 247615780L ,
    "1_247459572_C_T" , 247622874L ,
    "1_247460342_C_G" , 247623644L
)

exposure <- exposure %>% left_join(hg19_lookup, by = "SNP")

exposure


## ----flip_exposure_direction--------------------------------------------------
exposure <- exposure %>%
    mutate(beta_exposure = -beta_exposure)

exposure_direction <- "1-unit DECREASE in cis-NLRP3 activity score"


## ----helper_region------------------------------------------------------------
read_nlrp3_region <- function(
    path,
    chr_col,
    pos_col,
    sep = "tab"
) {
    header <- header_of(path, sep)
    ci <- col_index(header, chr_col, path)
    pi <- col_index(header, pos_col, path)

    # Whitespace-delimited inputs (the deCODE releases) are re-emitted with
    # tab separators by awk, so fread always sees the same shape.
    awk <- if (sep == "tab") {
        sprintf(
            "awk -F'\\t' 'NR==1 || (($%d==\"1\" || $%d==\"chr1\") && $%d>=%d && $%d<=%d)'",
            ci,
            ci,
            pi,
            INDICATION_REGION_START,
            pi,
            INDICATION_REGION_END
        )
    } else {
        sprintf(
            "awk 'BEGIN{OFS=\"\\t\"} NR==1 || (($%d==\"1\" || $%d==\"chr1\") && $%d>=%d && $%d<=%d) {$1=$1; print}'",
            ci,
            ci,
            pi,
            INDICATION_REGION_START,
            pi,
            INDICATION_REGION_END
        )
    }
    df <- fread(
        cmd = paste(reader_cmd(path), "|", awk),
        data.table = FALSE,
        showProgress = FALSE
    )

    # fread can mangle a leading '#' in the first column name; restore
    # the true header so that lookups by name always work.
    if (ncol(df) == length(header)) {
        names(df) <- header
    }
    df
}


## ----helper_proxies-----------------------------------------------------------
resolve_proxies <- function(std, proxies, label) {
    lapply(seq_len(nrow(proxies)), function(i) {
        px <- proxies[i, ]
        row <- std %>% dplyr::filter(join_pos == px$proxy_pos)

        if (nrow(row) != 1) {
            warning(sprintf(
                "[%s] proxy for %s not found at position %s",
                label,
                px$SNP,
                px$proxy_pos
            ))
            return(NULL)
        }
        forward <- row$outcome_ea == px$proxy_a1 & row$outcome_oa == px$proxy_a2
        reverse <- row$outcome_ea == px$proxy_a2 & row$outcome_oa == px$proxy_a1
        if (!forward && !reverse) {
            warning(sprintf(
                "[%s] proxy %s alleles (%s/%s) do not match the study (%s/%s)",
                label,
                px$SNP,
                px$proxy_a1,
                px$proxy_a2,
                row$outcome_ea,
                row$outcome_oa
            ))
            return(NULL)
        }

        beta_on_proxy_a1 <- if (forward) row$beta_raw else -row$beta_raw

        tibble(
            SNP = px$SNP,
            beta_px = sign(px$r) * beta_on_proxy_a1,
            se_px = row$se_raw,
            p_px = row$p_outcome,
            label_px = sprintf(
                "chr1:%s:%s:%s",
                px$proxy_pos,
                px$proxy_a1,
                px$proxy_a2
            ),
            r_px = px$r,
            r2_px = px$r^2
        )
    }) %>%
        bind_rows()
}


## ----helper_report_missing------------------------------------------------------
# Say plainly which instruments a study is missing and why, rather than letting
# them vanish into an NA.
report_missing <- function(harmonised, label) {
    absent <- harmonised |> dplyr::filter(is.na(beta_raw))
    mismatch <- harmonised |>
        dplyr::filter(!is.na(beta_raw) & is.na(beta_outcome))
    palin <- harmonised |> dplyr::filter(!is.na(beta_outcome) & palindromic)

    if (nrow(absent) > 0) {
        warning(sprintf(
            "[%s] %d/8 instruments absent from the file: %s",
            label,
            nrow(absent),
            paste(absent$SNP, collapse = ", ")
        ))
    }
    if (nrow(mismatch) > 0) {
        warning(sprintf(
            "[%s] %d/8 instruments present but alleles do not match: %s",
            label,
            nrow(mismatch),
            paste(mismatch$SNP, collapse = ", ")
        ))
    }
    if (nrow(palin) > 0) {
        message(sprintf(
            "  note: %d palindromic instrument(s) matched on allele identity only: %s",
            nrow(palin),
            paste(palin$SNP, collapse = ", ")
        ))
    }
    message(sprintf(
        "  -> %d/8 instruments usable",
        sum(!is.na(harmonised$beta_outcome))
    ))
}


## ----helper_prepare_outcome---------------------------------------------------
prepare_outcome <- function(
    label,
    file,
    build, # "GRCh38" or "GRCh37"
    chr_col,
    pos_col,
    ea_col,
    oa_col,
    effect_col,
    effect_type = "beta",
    se_source = "column",
    se_col = NULL, # when se_source = "column"
    ci_lower_col = NULL, # when se_source = "ci"
    ci_upper_col = NULL,
    # se_source = "p" needs only p_col
    eaf_col = NULL,
    p_col = NULL,
    eaf_scale = 1, # 100 when EAF is a percentage
    sep = "tab",
    proxies = NULL, # see resolve_proxies()
    n_cases = NA_integer_,
    n_controls = NA_integer_
) {
    message(sprintf("[%s] %s", label, basename(file)))

    raw <- read_nlrp3_region(file, chr_col, pos_col, sep)
    verify_build(raw, pos_col, build, label, exposure)

    pos_key <- if (build == "GRCh38") "pos_hg38" else "pos_hg19"

    std <- raw %>%
        transmute(
            join_pos = as.integer(.data[[pos_col]]),
            outcome_ea = toupper(.data[[ea_col]]),
            outcome_oa = toupper(.data[[oa_col]]),
            effect_raw = as.numeric(.data[[effect_col]]),
            se_column = if (se_source == "column") {
                as.numeric(.data[[se_col]])
            } else {
                NA_real_
            },
            ci_lower = if (se_source == "ci") {
                as.numeric(.data[[ci_lower_col]])
            } else {
                NA_real_
            },
            ci_upper = if (se_source == "ci") {
                as.numeric(.data[[ci_upper_col]])
            } else {
                NA_real_
            },
            eaf_outcome = if (is.null(eaf_col)) {
                NA_real_
            } else {
                as.numeric(.data[[eaf_col]]) / eaf_scale
            },
            p_outcome = if (is.null(p_col)) {
                NA_real_
            } else {
                as.numeric(.data[[p_col]])
            }
        ) %>%
        mutate(
            beta_raw = if (effect_type == "OR") log(effect_raw) else effect_raw,
            se_raw = switch(
                se_source,
                column = se_column,
                ci = se_from_ci(ci_lower, ci_upper),
                p = se_from_p(beta_raw, p_outcome)
            )
        )

    joined <- exposure %>%
        mutate(join_pos = .data[[pos_key]]) %>%
        left_join(std, by = "join_pos")

    # Keep only rows whose alleles match the instrument, in either
    # orientation, then flip the outcome onto A1.
    harmonised <- joined %>%
        mutate(
            forward = outcome_ea == A1 & outcome_oa == A2,
            reverse = outcome_ea == A2 & outcome_oa == A1,
            beta_outcome = case_when(
                forward ~ beta_raw,
                reverse ~ -beta_raw,
                TRUE ~ NA_real_
            ),
            eaf_outcome = case_when(
                forward ~ eaf_outcome,
                reverse ~ 1 - eaf_outcome,
                TRUE ~ NA_real_
            ),
            se_outcome = se_raw,
            palindromic = (A1 == "C" & A2 == "G") | (A1 == "A" & A2 == "T"),
            proxy_used = NA_character_,
            proxy_r = NA_real_,
            proxy_r2 = NA_real_
        )

    # fill instruments the study does not carry with an LD proxy
    if (!is.null(proxies)) {
        px <- resolve_proxies(std, proxies, label)
        if (nrow(px) > 0) {
            harmonised <- harmonised %>%
                left_join(px, by = "SNP") %>%
                mutate(
                    use_px = is.na(beta_outcome) & !is.na(beta_px),
                    proxy_used = ifelse(use_px, label_px, proxy_used),
                    proxy_r = ifelse(use_px, r_px, proxy_r),
                    proxy_r2 = ifelse(use_px, r2_px, proxy_r2),
                    beta_raw = ifelse(use_px, beta_px, beta_raw),
                    beta_outcome = ifelse(use_px, beta_px, beta_outcome),
                    se_outcome = ifelse(use_px, se_px, se_outcome),
                    p_outcome = ifelse(use_px, p_px, p_outcome)
                ) %>%
                select(
                    -beta_px,
                    -se_px,
                    -p_px,
                    -label_px,
                    -r_px,
                    -r2_px,
                    -use_px
                )
        }
    }

    report_missing(harmonised, label)

    harmonised %>%
        transmute(
            outcome = label,
            SNP,
            chr,
            pos_hg38,
            A1,
            A2,
            eaf_exposure,
            beta_exposure,
            se_exposure,
            eaf_outcome,
            beta_outcome,
            se_outcome,
            p_outcome,
            palindromic,
            proxy_used,
            proxy_r,
            proxy_r2,
            n_cases = n_cases,
            n_controls = n_controls,
            build_used = build
        )
}


## ----build_outcomes-----------------------------------------------------------
outcomes <- lapply(OUTCOMES, function(cfg) do.call(prepare_outcome, cfg))
names(outcomes) <- names(OUTCOMES)

outcome_scale <- tibble(
    key = names(outcomes),
    scale = case_when(
        names(outcomes) %in% ORDINAL_KEYS ~
            "Subclinical atherosclerosis (proportional-odds ratio)",
        TRUE ~ "Disease risk (odds ratio)"
    )
)

# drop studies whose data are not available (pericarditis)
outcomes <- outcomes[!sapply(outcomes, is.null)]

# instrument coverage per study, before anything is fitted
coverage <- lapply(names(outcomes), function(nm) {
    d <- outcomes[[nm]]
    tibble(
        key = nm,
        outcome = d$outcome[1],
        build_used = d$build_used[1],
        n_usable = sum(!is.na(d$beta_outcome))
    )
}) %>%
    bind_rows()

coverage


## ----ld_matrix----------------------------------------------------------------
ld_full <- interval_ld_matrix(exposure$SNP)
round(ld_full, 3)


mr_results <- lapply(
    names(outcomes),
    function(nm) run_mr(outcomes[[nm]], ld_full)
) %>%
    bind_rows()

mr_results %>%
    mutate(
        across(c(estimate, se, ci_lower, ci_upper), ~ round(.x, 4)),
        p = signif(p, 3)
    ) %>%
    arrange(outcome, method)


## ----write_results------------------------------------------------------------
harmonised_all <- bind_rows(outcomes)

write_tsv(
    mr_results,
    file.path(output_dir, "additional_indications_mr_results.tsv")
)
write_tsv(
    harmonised_all,
    file.path(output_dir, "additional_indications_harmonised.tsv")
)
write_tsv(
    coverage,
    file.path(output_dir, "additional_indications_coverage.tsv")
)
saveRDS(ld_full, file.path(output_dir, "additional_indications_ld_matrix.rds"))


## ----forest_plot, fig.width = 9, fig.height = 9-------------------------------
plot_df <- mr_results %>%
    left_join(
        outcome_scale %>%
            left_join(coverage %>% select(key, outcome), by = "key") %>%
            select(outcome, scale),
        by = "outcome"
    ) %>%
    mutate(
        or = exp(estimate),
        or_lower = exp(ci_lower),
        or_upper = exp(ci_upper),
        # registry order, so the CAD positive control sits at the top
        outcome = fct_rev(factor(outcome, levels = unique(mr_results$outcome))),
        scale = factor(
            scale,
            levels = c(
                "Disease risk (odds ratio)",
                "Subclinical atherosclerosis (proportional-odds ratio)",
                "Glycaemic traits (trait units, NOT an odds ratio)",
                "Instrument validation, NOT causal (SD per unit)"
            )
        )
    )

forest <- ggplot(plot_df, aes(x = or, y = outcome, colour = method)) +
    geom_vline(xintercept = 1, linetype = "dashed", colour = "grey40") +
    geom_errorbar(
        aes(xmin = or_lower, xmax = or_upper),
        orientation = "y",
        width = 0.2,
        position = position_dodge(width = 0.6)
    ) +
    geom_point(size = 2, position = position_dodge(width = 0.6)) +
    scale_x_continuous(trans = "log", breaks = scales::log_breaks(n = 7)) +
    scale_colour_manual(
        values = c(
            "IVW (LD-corrected)" = "#1F4E79",
            "Weighted median" = "#C0504D"
        )
    ) +
    facet_grid(
        scale ~ .,
        scales = "free_y",
        space = "free_y",
        labeller = labeller(scale = label_wrap_gen(38))
    ) +
    labs(
        x = "Effect (95% CI) per 1-unit lower cis-NLRP3 activity",
        y = NULL,
        colour = NULL
    ) +
    theme_Publication() +
    theme(
        legend.position = "top",
        strip.text.y = element_text(size = 8, angle = 0)
    )

forest


## ----save_forest--------------------------------------------------------------
ggsave(
    file.path(output_dir, "additional_indications_forest.pdf"),
    forest,
    width = 9,
    height = 9
)


## ----session_info-------------------------------------------------------------
sessionInfo()
