## 02 - The instrument table
##
## Re-derives each instrument's effect on the four readouts from source, on the
## ASCII-sorted A1. Writes results/02_instrument_table/.

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("02_instrument_table")

# negate = FALSE: the variants on their own allele, not the inhibition scale
exposure <- load_instruments(negate = FALSE)

readouts <- lapply(names(READOUTS), function(k) {
    cfg <- READOUTS[[k]]
    read_region(cfg, CHR, LOCUS_START, LOCUS_END) %>%
        harmonise(cfg) %>%
        filter(SNPid %in% exposure$SNP) %>%
        transmute(SNP = SNPid, trait = k, beta, se, p, n = cfg$n) %>%
        arrange(match(SNP, exposure$SNP))
}) %>% bind_rows()

aligned <- readouts %>%
    select(SNP, trait, beta, se) %>%
    pivot_wider(names_from = trait, values_from = c(beta, se)) %>%
    inner_join(select(exposure, SNP, chr, pos_hg38, pos_hg19, A1, A2,
                      eaf_exposure, beta_exposure, se_exposure),
               by = "SNP") %>%
    arrange(match(SNP, exposure$SNP))

fwrite(readouts, file.path(out_dir, "instrument_readouts_long.tsv"), sep = "\t")
fwrite(aligned, file.path(out_dir, "instrument_table_aligned.tsv"), sep = "\t")
