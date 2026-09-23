## 09b - Effective number of independent protein tests (UKB-PPP)
##
## NOT RUNNABLE FROM THIS REPOSITORY. It needs individual-level UK Biobank
## proteomics and covariate data, which cannot be redistributed, so the number
## it produces is hardcoded as N_EFFECTIVE_TESTS in 09_proteome_mr.R rather
## than recomputed there. This file records how that number was obtained.
##
## Result: 1,821 of 2,922 proteins (Gao's simpleM, 95% of the total variance).

library(tidyverse)

## ---- 1. residualise each protein on the UKB-PPP covariates ----------------------
COVARIATES <- paste(
    "age + sex + age_squared + age_x_sex + age_squared_x_sex",
    "assessment_centre",
    "genotype_batch",
    "olink_batch",
    paste(sprintf("genetic_PC_%d", 1:20), collapse = " + "),
    sep = " + "
)

residualise <- function(protein, d) {
    f <- as.formula(paste(protein, "~", COVARIATES))
    keep <- d %>% select(ID, all_of(all.vars(f))) %>% drop_na()
    out <- data.frame(keep$ID, residuals(lm(f, data = keep)))
    setNames(out, c("ID", protein))
}

eur <- ukb_ppp %>% filter(genetic_ancestry_superpopulation == "EUR")
adjusted <- reduce(lapply(protein_cols, residualise, d = eur), full_join, by = "ID")

## ---- 2. Gao's simpleM on the protein correlation matrix -------------------------
# Every protein is tested with the same eight cis-instruments in the same
# sample, so the correlation between the MR estimates is carried by the
# phenotypic correlation between the proteins themselves.
eigenvalues <- eigen(
    cor(column_to_rownames(adjusted, "ID"), use = "pairwise.complete.obs")
)$values

gao <- function(ev, C) which(cumsum(sort(ev, decreasing = TRUE)) / sum(ev) > C)[1]

gao(eigenvalues, 0.95)   # 1821 -> N_EFFECTIVE_TESTS in 09_proteome_mr.R
