## 10 - Over-representation analysis of the proteome MR
##
## Splits the significant proteins into those raised and those lowered by NLRP3
## inhibition and tests each set for pathway enrichment.
## Writes results/10_proteome_ora/.

suppressPackageStartupMessages({
    library(tidyverse)
    library(data.table)
    library(here)
    library(clusterProfiler)
    library(msigdbr)
})


## ----paths--------------------------------------------------------------------
analysis_dir <- here::here()
output_dir   <- file.path(analysis_dir, "results", "10_proteome_ora")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Read step 09's output, not this step's own directory.
mr_file <- file.path(analysis_dir, "results", "09_proteome_mr",
                     "ukb_ppp_proteome_mr_results.tsv")

mr <- fread(mr_file, data.table = FALSE)
message(sprintf("loaded %d proteins", nrow(mr)))


## ----split_by_direction-------------------------------------------------------
sig <- mr %>% filter(ivw_pval_bonf < 0.05)

raised  <- sig %>% filter(ivw_beta > 0) %>% pull(gene_name)
lowered <- sig %>% filter(ivw_beta < 0) %>% pull(gene_name)
background <- unique(mr$gene_name)

message(sprintf("significant: %d  |  raised by inhibition: %d  |  lowered by inhibition: %d",
                nrow(sig), length(raised), length(lowered)))
message(sprintf("background universe: %d proteins", length(background)))

message("raised by inhibition:  ", paste(sort(raised), collapse = ", "))
message("lowered by inhibition: ", paste(sort(lowered), collapse = ", "))


## ----gene_sets----------------------------------------------------------------
# msigdbr 25.1.1 (MSigDB 2025.1.Hs), the version Supplementary Information
# 10.3 documents. The version matters more than it looks.
hallmark_term2gene <- msigdbr(species = "Homo sapiens", collection = "H") %>%
    select(gs_name, gene_symbol)

go_bp_term2gene <- msigdbr(species = "Homo sapiens",
                           collection = "C5", subcollection = "GO:BP") %>%
    select(gs_name, gene_symbol)

message(sprintf("%d Hallmark sets, %d GO BP sets",
                n_distinct(hallmark_term2gene$gs_name),
                n_distinct(go_bp_term2gene$gs_name)))


## ----ora----------------------------------------------------------------------
run_ora <- function(genes, term2gene, direction, collection) {
    if (length(genes) < 3) {
        message(sprintf("[%s / %s] only %d genes, skipping",
                        direction, collection, length(genes)))
        return(NULL)
    }

    res <- enricher(
        gene       = genes,
        pvalueCutoff = 1,        # keep everything; filter on p.adjust below
        qvalueCutoff = 1,
        universe   = background,
        TERM2GENE  = term2gene
    )

    if (is.null(res) || nrow(res@result) == 0) {
        message(sprintf("[%s / %s] no terms returned", direction, collection))
        return(NULL)
    }

    res@result %>%
        as_tibble() %>%
        mutate(direction = direction, collection = collection, .before = 1)
}

ora <- bind_rows(
    run_ora(raised,  go_bp_term2gene,    "raised_by_inhibition",  "GO:BP"),
    run_ora(lowered, go_bp_term2gene,    "lowered_by_inhibition", "GO:BP"),
    run_ora(raised,  hallmark_term2gene, "raised_by_inhibition",  "Hallmark"),
    run_ora(lowered, hallmark_term2gene, "lowered_by_inhibition", "Hallmark")
)

for (d in unique(ora$direction)) {
    for (cl in unique(ora$collection)) {
        n <- sum(ora$direction == d & ora$collection == cl & ora$p.adjust < 0.05)
        message(sprintf("[%s / %s] %d terms at adj. P < 0.05", d, cl, n))
    }
}

message("\ntop GO BP terms, proteins RAISED by NLRP3 inhibition:")
print(ora %>%
          filter(direction == "raised_by_inhibition", collection == "GO:BP") %>%
          arrange(p.adjust) %>%
          select(Description, GeneRatio, BgRatio, pvalue, p.adjust) %>%
          head(15))

message("\ntop GO BP terms, proteins LOWERED by NLRP3 inhibition:")
print(ora %>%
          filter(direction == "lowered_by_inhibition", collection == "GO:BP") %>%
          arrange(p.adjust) %>%
          select(Description, GeneRatio, BgRatio, pvalue, p.adjust) %>%
          head(15))


## ----write_results------------------------------------------------------------
# A single tidy file with an explicit direction column, rather than the old
# pair of ora_upregulated_* / ora_downregulated_* files whose names encoded the
# now-inverted convention.
write_tsv(ora %>% filter(p.adjust < 0.5),
          file.path(output_dir, "ukb_ppp_proteome_ora.tsv"))

write_tsv(sig %>%
              mutate(direction = if_else(ivw_beta > 0,
                                         "raised_by_inhibition",
                                         "lowered_by_inhibition")) %>%
              select(gene_name, direction, n_snps, ivw_beta, ivw_se,
                     ivw_pval, ivw_pval_bonf) %>%
              arrange(ivw_pval),
          file.path(output_dir, "ukb_ppp_proteome_significant.tsv"))

message("results written to ", output_dir)


## ----session_info-------------------------------------------------------------
sessionInfo()
