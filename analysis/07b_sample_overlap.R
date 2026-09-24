## 07b - Sampling correlation between the mediator GWAS
##
## Estimates the correlation of the SBP, ApoB and T2D sampling errors from
## z-scores at variants null for both traits. Writes results/07b_sample_overlap/.

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("07b_sample_overlap")

GRID_BP <- 100000 # one variant per 100 kb, wider than most European LD blocks
NULL_P <- 0.05 # "null for both traits"

# The grid: the first SBP variant of each 100 kb bin, genome-wide, left in file
# order, which sets the order cor.test() sums in.
grid <- read_genome(MEDIATORS$SBP) %>%
    mutate(row = row_number(), bin = floor(pos / GRID_BP)) %>%
    group_by(chrom, bin) %>%
    slice(1) %>%
    ungroup() %>%
    arrange(row) %>%
    harmonise(MEDIATORS$SBP)

# The same variants in every mediator; beta and se are on A1, so the z-scores
# compare directly.
want <- transmute(grid, SNPid, chrom = chr, pos)
wide <- lapply(names(MEDIATORS), function(k) {
    d <- if (k == "SBP") grid else lookup_at(MEDIATORS[[k]], want)
    transmute(d, SNPid, mediator = k, z = beta / se, p)
}) %>%
    bind_rows() %>%
    pivot_wider(names_from = mediator, values_from = c(z, p)) %>%
    drop_na()

keys <- names(MEDIATORS)
rho <- diag(1, length(keys))
dimnames(rho) <- list(keys, keys)
pairs_tbl <- list()
for (pair in combn(keys, 2, simplify = FALSE)) {
    a <- pair[1]
    b <- pair[2]
    sub <- wide[wide[[paste0("p_", a)]] > NULL_P & wide[[paste0("p_", b)]] > NULL_P, ]
    za <- sub[[paste0("z_", a)]]
    zb <- sub[[paste0("z_", b)]]
    ct <- cor.test(za, zb)
    rho[a, b] <- rho[b, a] <- unname(ct$estimate)
    # null z-scores should be about standard normal; an inflated sd points at
    # residual signal or stratification, either of which contaminates rho
    pairs_tbl[[length(pairs_tbl) + 1]] <- tibble(
        trait_1 = a, trait_2 = b, n_null = nrow(sub), rho = unname(ct$estimate),
        ci_lower = ct$conf.int[1], ci_upper = ct$conf.int[2], p = ct$p.value,
        sd_z_1 = sd(za), sd_z_2 = sd(zb))
}
pairs_tbl <- bind_rows(pairs_tbl)
print(as.data.frame(pairs_tbl), row.names = FALSE, digits = 3)

saveRDS(rho, file.path(out_dir, "rho.rds"))
fwrite(pairs_tbl, file.path(out_dir, "rho_pairs.tsv"), sep = "\t")
saveRDS(list(rho = rho, pairs = pairs_tbl, grid_bp = GRID_BP, null_p = NULL_P,
             grid_trait = "SBP", n_grid = nrow(grid), n_complete = nrow(wide)),
        file.path(out_dir, "sample_overlap_provenance.rds"))
