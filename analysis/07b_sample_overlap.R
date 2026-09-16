## 07b - Sampling correlation between the mediator GWAS
##
## Estimates the correlation of the SBP, ApoB and T2D sampling errors from
## z-scores at variants null for both traits. Writes results/07b_sample_overlap/.

suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(here)
})

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("07b_sample_overlap")

GRID_BP <- 100000L   # one variant per 100 kb - wider than most European LD blocks
NULL_P  <- 0.05      # "null for both traits"
GRID_TRAIT <- "SBP"  # whose variant set defines the grid


## ---- 1. the grid ------------------------------------------------------------------
stopifnot(GRID_TRAIT %in% names(MEDIATORS))
message(sprintf("Building a 1-per-%d kb grid from %s ...",
                GRID_BP / 1000L, MEDIATORS[[GRID_TRAIT]]$label))

grid <- thin_genome(MEDIATORS[[GRID_TRAIT]], bin_bp = GRID_BP)
message(sprintf("  %s variants\n", format(nrow(grid), big.mark = ",")))
stopifnot(nrow(grid) > 5000)


## ---- 2. the same variants in every mediator ----------------------------------------
z_at_grid <- lapply(names(MEDIATORS), function(k) {
    cfg <- MEDIATORS[[k]]
    message(sprintf("  %s ...", cfg$label))

    d <- if (identical(k, GRID_TRAIT)) grid else
        lookup_at(cfg, grid$SNPid, grid$chr, grid$pos, cfg$label)

    message(sprintf("    %s / %s present", format(nrow(d), big.mark = ","),
                    format(nrow(grid), big.mark = ",")))
    # beta and se are already oriented onto A1 by to_common(), so z is directly
    # comparable across traits without further harmonisation.
    d %>% transmute(SNPid, mediator = k, z = beta / se, p)
}) %>% bind_rows()

wide <- z_at_grid %>%
    pivot_wider(names_from = mediator, values_from = c(z, p)) %>%
    drop_na()
message(sprintf("\n%s variants present in all %d mediators\n",
                format(nrow(wide), big.mark = ","), length(MEDIATORS)))


## ---- 3. pairwise correlation at variants null for both ------------------------------
keys  <- names(MEDIATORS)
rho   <- diag(1, length(keys)); dimnames(rho) <- list(keys, keys)
pairs_tbl <- list()

for (i in seq_along(keys)) for (j in seq_along(keys)) {
    if (j <= i) next
    a <- keys[i]; b <- keys[j]

    sub <- wide %>% filter(.data[[paste0("p_", a)]] > NULL_P,
                           .data[[paste0("p_", b)]] > NULL_P)
    za <- sub[[paste0("z_", a)]]; zb <- sub[[paste0("z_", b)]]

    ct <- cor.test(za, zb)
    rho[a, b] <- rho[b, a] <- unname(ct$estimate)

    pairs_tbl[[length(pairs_tbl) + 1]] <- tibble(
        trait_1 = a, trait_2 = b, n_null = nrow(sub),
        rho = unname(ct$estimate),
        ci_lower = ct$conf.int[1], ci_upper = ct$conf.int[2], p = ct$p.value,
        # A sanity read on the sample: null z-scores should be roughly standard
        # normal. A markedly inflated sd points at residual association signal
        # or at stratification, either of which contaminates rho.
        sd_z_1 = sd(za), sd_z_2 = sd(zb))
}

pairs_tbl <- bind_rows(pairs_tbl)

message("Sampling correlation at variants null for both traits (p > ", NULL_P, "):\n")
print(as.data.frame(pairs_tbl %>%
    mutate(across(c(rho, ci_lower, ci_upper, sd_z_1, sd_z_2), ~ round(.x, 3)))),
    row.names = FALSE)

message("\nrho matrix:")
print(round(rho, 3))

if (any(pairs_tbl$sd_z_1 > 1.3 | pairs_tbl$sd_z_2 > 1.3)) {
    message("\nNOTE: sd of the null z-scores exceeds 1.3 for at least one trait.")
    message("      The 'null' set still carries association signal; rho will be")
    message("      biased away from the pure sample-overlap term.")
}


## ---- output -------------------------------------------------------------------------
saveRDS(rho, file.path(out_dir, "rho.rds"))
fwrite(pairs_tbl, file.path(out_dir, "rho_pairs.tsv"), sep = "\t")
saveRDS(list(rho = rho, pairs = pairs_tbl, grid_bp = GRID_BP, null_p = NULL_P,
             grid_trait = GRID_TRAIT, n_grid = nrow(grid), n_complete = nrow(wide)),
        file.path(out_dir, "sample_overlap_provenance.rds"))

message("\nDone -> ", out_dir)
