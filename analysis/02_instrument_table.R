## 02 - The instrument table
##
## Re-derives each instrument's effect on the four readouts from source, on the
## ASCII-sorted A1, and looks up the instruments' rsIDs.
## Writes results/02_instrument_table/.

source(here::here("config.R"))
source(here::here("helpers.R"))

out_dir <- step_dir("02_instrument_table")

# negate = FALSE: the variants on their own allele, not the inhibition scale
exposure <- load_instruments(negate = FALSE)
raw <- lapply(READOUTS, read_region, chr = CHR, start = LOCUS_START, end = LOCUS_END)

readouts <- lapply(names(READOUTS), function(k) {
    harmonise(raw[[k]], READOUTS[[k]]) %>%
        filter(SNPid %in% exposure$SNP) %>%
        transmute(SNP = SNPid, trait = k, beta, se, p, n = READOUTS[[k]]$n) %>%
        arrange(match(SNP, exposure$SNP))
}) %>% bind_rows()

aligned <- readouts %>%
    select(SNP, trait, beta, se) %>%
    pivot_wider(names_from = trait, values_from = c(beta, se)) %>%
    inner_join(select(exposure, SNP, chr, pos_hg38, pos_hg19, A1, A2,
                      eaf_exposure, beta_exposure, se_exposure),
               by = "SNP") %>%
    arrange(match(SNP, exposure$SNP))

# rsIDs, for the figures and tables: from the mapping file by variant, in either
# allele order. It misses the two rarest instruments, which take the readouts'
# own rsID columns by position.
rsid_map <- fread(rsid_map_file, data.table = FALSE)
fallback <- lapply(raw[c("Neutrophil_count", "CRP", "GlycA")], transmute,
                   pos_hg38 = pos, rsid2 = rsid) %>%
    bind_rows() %>%
    filter(grepl("^rs", rsid2)) %>%
    distinct(pos_hg38, .keep_all = TRUE)
rsids <- exposure %>%
    transmute(SNP, pos_hg38, rsid = sapply(SNP, function(s) {
        f <- strsplit(s, "_")[[1]]
        ids <- sprintf("chr%s:%s:%s:%s", f[1], f[2], c(f[3], f[4]), c(f[4], f[3]))
        rsid_map$rsid[rsid_map$variant_id %in% ids][1]
    })) %>%
    left_join(fallback, by = "pos_hg38") %>%
    transmute(SNP, rsid = coalesce(rsid, rsid2))

fwrite(readouts, file.path(out_dir, "instrument_readouts_long.tsv"), sep = "\t")
fwrite(aligned, file.path(out_dir, "instrument_table_aligned.tsv"), sep = "\t")
fwrite(rsids, file.path(out_dir, "instrument_rsids.tsv"), sep = "\t")
