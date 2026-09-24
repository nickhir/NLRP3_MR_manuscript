## config.R - paths, locus constants, sample sizes and the dataset registry.
##
## Declares where everything lives and does no work. Sourced by every analysis
## step and by the two locuszoom figures.

analysis_dir <- here::here()
dataset_dir <- file.path(analysis_dir, "datasets")
results_dir <- file.path(analysis_dir, "results")

# Each analysis step writes only into its own results/<step>/.
step_dir <- function(step) {
    d <- file.path(results_dir, step)
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
    d
}


## ---- external tools and data -------------------------------------------------
plink2_bin <- "/rds/user/nh608/hpc-work/software/plink2/plink2"
gcta_bin <- "/rds/user/nh608/hpc-work/software/gcta/gcta-1.94.1"
tabix_bin <- "/rds/user/nh608/hpc-work/software/micromamba/envs/sambcfenv/bin/tabix"

# UCSC chain lifting a GRCh37 release onto GRCh38, the build of the LD panel
# (also used by datasets/liftover_t2d_to_grch38.R).
hg19_to_hg38_chain <- "/rds/user/nh608/hpc-work/software/UCSC_liftOver/hg19ToHg38.over.chain"

# UKB-PPP plasma proteomics, access-controlled and kept outside this folder. One
# bgzipped, tabix-indexed file per assay, plus a .lst manifest of assay IDs.
ppp_dir <- paste0(
    "/rds/project/rds-C1Ph08tkaOA/public/proteomics/UKB-PPP/sun23/",
    "UKB-PPP pGWAS summary statistics (reformatted)/Combined_European"
)
ppp_manifest <- paste0(ppp_dir, ".lst")

# INTERVAL WGS LD panel, GRCh38, 11,863 European-ancestry genomes. Variants are
# named chr1:POS:A1:A2 with the alleles ASCII-sorted. The sibling copy under
# WGS_reference/results/ uses a different ID convention.
ld_panel <- paste0(
    "/rds/user/nh608/hpc-work/oxLDL/data/oxLDL_data/INTERVAL_reference/",
    "WGS_reference/ld_panels/INTERVAL_allchr.GRCh38.alpha_sorted_alleles"
)


## ---- the NLRP3 locus (GRCh38) ------------------------------------------------
CHR <- 1
GENE_START <- 247416156 # NLRP3 gene body
GENE_END <- 247449108

# +/-150 kb: the instrument window of Methods 3.3.
INSTRUMENT_START <- as.integer(GENE_START - 150e3)
INSTRUMENT_END <- as.integer(GENE_END + 150e3)

# +/-200 kb: colocalisation and COJO conditioning, and the window every outcome
# is read over. It holds the GRCh37 positions of the eight instruments too.
LOCUS_START <- as.integer(GENE_START - 200e3)
LOCUS_END <- as.integer(GENE_END + 200e3)

# +/-1 Mb: step 01 tests the flanks between this and the locus window.
FLANK_START <- as.integer(GENE_START - 1e6)
FLANK_END <- as.integer(GENE_END + 1e6)

NLRP3_ENSG <- "ENSG00000162711"

# IL1RN, the positive-control locus of step 08 (Ensembl 111 gene body).
IL1RN_CHR <- 2
IL1RN_START <- 113099315
IL1RN_END <- 113134016
IL1RN_ENSG <- "ENSG00000136689"

# Gene-specificity rule for instruments (helpers.R eqtl_specificity()): a
# variant is dropped if it is associated with expression of another gene at
# this P, both before and after conditioning on that gene's lead eQTL.
EQTL_SPECIFICITY_P <- 1e-3

# LD proxy rule, for a variant missing from a readout (instrument selection) or
# from an outcome release (step 12): INTERVAL r2 >= PROXY_R2 within PROXY_KB kb.
PROXY_R2 <- 0.9
PROXY_KB <- 50


## ---- instruments -------------------------------------------------------------
# Written by analysis/00_instrument_selection.R; every later step reads it.
instrument_file <- file.path(
    results_dir,
    "00_instrument_selection",
    "nlrp3_instruments.tsv"
)

# Variant ID -> rsID, for labelling instruments.
rsid_map_file <- file.path(dataset_dir, "rsid_mapping.tsv.gz")

# Every estimate is per one-unit DECREASE in the activity score, the direction
# an NLRP3 inhibitor moves a patient. load_instruments() negates the score.
EXPOSURE_DIRECTION <- "1-unit DECREASE in cis-NLRP3 activity score"


## ---- the GWAS Catalog harmonised schema --------------------------------------
# Most releases share it; the registry entries below start from it.
GWAS_CATALOG <- list(
    build = "GRCh38",
    chr_col = "chromosome",
    pos_col = "base_pair_location",
    ea_col = "effect_allele",
    oa_col = "other_allele",
    effect_col = "beta",
    effect_type = "beta",
    se_source = "column",
    se_col = "standard_error",
    eaf_col = "effect_allele_frequency",
    p_col = "p_value"
)
# ... reporting an odds ratio and its 95% CI, the SE taken from the CI
GWAS_CATALOG_OR <- modifyList(GWAS_CATALOG, list(
    effect_col = "odds_ratio",
    effect_type = "OR",
    se_source = "ci",
    se_col = NULL,
    ci_lower_col = "ci_lower",
    ci_upper_col = "ci_upper"
))
# ... and its older, hm_-prefixed form
GWAS_CATALOG_HM <- modifyList(GWAS_CATALOG, list(
    chr_col = "hm_chrom",
    pos_col = "hm_pos",
    ea_col = "hm_effect_allele",
    oa_col = "hm_other_allele",
    effect_col = "hm_beta",
    eaf_col = "hm_effect_allele_frequency"
))

# T2DGGI (the source misspells its chromosome column "Chromsome")
T2DGGI <- list(
    chr_col = "Chromsome",
    pos_col = "Position",
    ea_col = "EffectAllele",
    oa_col = "NonEffectAllele",
    effect_col = "Beta",
    se_col = "SE",
    eaf_col = "EAF",
    p_col = "Pval"
)
# GSCAN: "Beta based on the alternate allele" (its README), so ALT is the
# effect allele. No allele frequency is distributed.
GSCAN <- list(
    build = "GRCh37",
    chr_col = "CHROM",
    pos_col = "POS",
    ea_col = "ALT",
    oa_col = "REF",
    effect_col = "BETA",
    se_col = "SE",
    p_col = "PVALUE"
)


## ---- the four readouts used to build the score -------------------------------
READOUTS <- list(
    NLRP3_expression = list(
        label = "NLRP3 expression",
        file = file.path(dataset_dir, "nlrp3_eqtl_interval_chr1.tsv"),
        n = 4732,
        chr_col = "chr",
        pos_col = "pos_b38",
        ea_col = "effect_allele",
        oa_col = "other_allele",
        effect_col = "slope",
        se_col = "slope_se",
        p_col = "pval_nominal",
        eaf_col = "af",
        # the release holds every gene tested in the window
        gene_col = "phenotype_id",
        gene = NLRP3_ENSG
    ),
    CRP = modifyList(GWAS_CATALOG_HM, list(
        label = "CRP concentration",
        file = file.path(dataset_dir, "crp_GCST90029070.h.tsv.gz"),
        n = 575531,
        eaf_col = NULL,
        rsid_col = "hm_rsid"
    )),
    GlycA = modifyList(GWAS_CATALOG, list(
        label = "GlycA concentration",
        file = file.path(dataset_dir, "glyca_GCST90497330.h.tsv.gz"),
        n = 434646,
        p_col = "neg_log_10_p_value",
        neglog10_p = TRUE,
        rsid_col = "rsid"
    )),
    # the reference for the panel-vs-GWAS frequency filter
    Neutrophil_count = modifyList(GWAS_CATALOG_HM, list(
        label = "Neutrophil count",
        file = file.path(dataset_dir, "neutrophil_count_GCST90002351.h.tsv.gz"),
        n = 519288,
        rsid_col = "hm_rsid"
    ))
)

# The same readouts at IL1RN (step 08): the chr2 eQTL release, and GlycA's
# p_value column rather than its -log10 P.
IL1RN_READOUTS <- list(
    modifyList(READOUTS$NLRP3_expression, list(
        label = "IL1RN expression",
        file = file.path(dataset_dir, "il1rn_eqtl_interval_chr2.tsv"),
        gene = IL1RN_ENSG,
        rsid_col = "variant_id"
    )),
    READOUTS$CRP,
    modifyList(READOUTS$GlycA, list(p_col = "p_value", neglog10_p = NULL)),
    READOUTS$Neutrophil_count
)

# The IL1Ra assay, the protein outcome of step 08.
ppp_il1rn_assay <- file.path(ppp_dir, "IL1RN_P18510_OID20700_v1_Inflammation.bgz")


## ---- disease and trait outcomes ----------------------------------------------
# One entry per outcome: the three imaging traits first, then the disease
# outcomes, in the order the results table uses. Step 08 reads `gout` and
# `ra_ishigaki` from here too.
outcome_entry <- function(template, label, file, ...) {
    modifyList(template, list(label = label, file = file.path(dataset_dir, file), ...))
}
OUTCOMES <- list(
    cac = outcome_entry(GWAS_CATALOG, "Coronary artery calcification (Agatston, CT)",
                  "coronary_artery_calcification_GCST90503074.h.tsv.gz"),
    sis = outcome_entry(GWAS_CATALOG, "Coronary plaque burden (SIS, CTA)",
                  "coronary_plaque_burden_GCST90503075.h.tsv.gz"),
    carotid = outcome_entry(GWAS_CATALOG, "Carotid plaque (ultrasound)",
                      "carotid_plaque_burden_GCST90503076.h.tsv.gz"),
    allergic_rhinitis = outcome_entry(GWAS_CATALOG_OR, "Allergic rhinitis",
                                "allergic_rhinitis_GCST90476021.h.tsv.gz",
                                n_cases = 92310, n_controls = 311377),
    als = outcome_entry(GWAS_CATALOG_HM, "Amyotrophic lateral sclerosis",
                  "amyotrophic_lateral_sclerosis_GCST90027164.h.tsv.gz",
                  n_cases = 27205, n_controls = 110881),
    asthma = outcome_entry(GWAS_CATALOG, "Asthma", "asthma_GCST90399686.h.tsv.gz",
                     n_cases = 121940, n_controls = 1254131),
    chronic_airway_obstruction = outcome_entry(GWAS_CATALOG_OR, "Chronic airway obstruction",
                                         "chronic_airway_obstruction_GCST90476027.h.tsv.gz",
                                         n_cases = 103054, n_controls = 315450),
    gout = outcome_entry(GWAS_CATALOG_OR, "Gout", "gout_GCST90475735.h.tsv.gz",
                   n_cases = 42034, n_controls = 397989),
    hfref = outcome_entry(GWAS_CATALOG_OR, "Heart failure (reduced EF)",
                    "heart_failure_reduced_ef_GCST90475983.h.tsv.gz",
                    n_cases = 31220, n_controls = 407213),
    # GRCh38 because of the b38_* columns, not the filename
    covid19 = outcome_entry(GWAS_CATALOG, "Hospitalized COVID-19",
                      "hospitalized_covid19_HGI_B2_release7_GRCh37.tsv.gz",
                      chr_col = "b38_chr", pos_col = "b38_pos", ea_col = "b38_alt",
                      oa_col = "b38_ref", effect_col = "all_inv_var_meta_beta",
                      se_col = "all_inv_var_meta_sebeta", eaf_col = "all_meta_AF",
                      p_col = "all_inv_var_meta_p",
                      n_cases = 32519, n_controls = 2062805),
    # UK Biobank WGS, ICD-10 M17 gonarthrosis, non-Finnish European only
    # (REGENIE: a log-odds beta with its own SE). The release does not carry two
    # of the eight instruments; step 12 takes both from LD proxies.
    knee_oa = outcome_entry(GWAS_CATALOG, "Knee osteoarthritis",
                      "knee_osteoarthritis_GCST90474022.h.tsv.gz",
                      n_cases = 44190, n_controls = 414250),
    mi = outcome_entry(GWAS_CATALOG_OR, "Myocardial infarction",
                 "myocardial_infarction_GCST90475932.h.tsv.gz",
                 n_cases = 39074, n_controls = 392979),
    obesity = outcome_entry(GWAS_CATALOG_OR, "Obesity", "obesity_GCST90475762.h.tsv.gz",
                      n_cases = 169600, n_controls = 244254),
    parkinsons = outcome_entry(GWAS_CATALOG, "Parkinson's disease", "parkinsons_disease_GCST009325.tsv",
                         build = "GRCh37", n_cases = 33674, n_controls = 449056),
    # deCODE reports neither SE nor CI, so the SE comes from the p-value
    pericarditis = outcome_entry(GWAS_CATALOG_OR, "Pericarditis", "pericarditis_decode.txt.gz",
                           chr_col = "Chrom", pos_col = "Pos", ea_col = "Effect_Allele",
                           oa_col = "Other_allele", # lower-case 'a' in the actual header
                           effect_col = "comb_Effect", se_source = "p",
                           ci_lower_col = NULL, ci_upper_col = NULL, eaf_col = NULL,
                           p_col = "comb_Pval", n_cases = 4894, n_controls = 1457822),
    ra_ishigaki = outcome_entry(GWAS_CATALOG, "Rheumatoid arthritis",
                          "rheumatoid_arthritis_ishigaki_GCST90132223.h.tsv.gz",
                          n_cases = 22350, n_controls = 74823),
    t2d = outcome_entry(T2DGGI, "Type 2 diabetes", "type2_diabetes_T2DGGI_EUR_GRCh37.sumstats.zip",
                  build = "GRCh37", effect_type = "beta", se_source = "column",
                  n_cases = 242283, n_controls = 1569734),
    uc = outcome_entry(GWAS_CATALOG_HM, "Ulcerative colitis", "ulcerative_colitis_GCST004133.h.tsv.gz",
                 n_cases = 12366, n_controls = 33609)
)


## ---- mediators for the CAD mediation analysis --------------------------------
# SBP, ApoB and T2D, in the order used throughout steps 07a-07d.
MEDIATORS <- list(
    SBP = modifyList(GWAS_CATALOG, list(
        label = "Systolic blood pressure",
        file = file.path(dataset_dir, "systolic_bp_GCST90310294.h.tsv.gz"),
        n_col = "n",
        # reported in mmHg, so put on an SD scale
        standardise_sd = TRUE
    )),
    ApoB = modifyList(GWAS_CATALOG, list(
        label = "Apolipoprotein B",
        file = file.path(dataset_dir, "apolipoprotein_b_GCST90497142.h.tsv.gz"),
        n_col = "n",
        # p_value is the literal string "0.0" at APOE (30 variants); this column
        # carries the true magnitude (1370.89 at rs7412) and sets the clump rank.
        nlog10_col = "neg_log_10_p_value"
    )),
    # lifted GRCh37 -> GRCh38 by datasets/liftover_t2d_to_grch38.R
    T2D = modifyList(T2DGGI, list(
        label = "Type 2 diabetes",
        file = file.path(dataset_dir, "type2_diabetes_T2DGGI_EUR_GRCh38.tsv.gz"),
        n_col = "Neff"
    ))
)

# Instrument selection for the mediators; these are the TwoSampleMR defaults,
# clumped against the INTERVAL panel.
MED_CLUMP_P <- 5e-8
MED_CLUMP_R2 <- 0.001
MED_CLUMP_KB <- 10000


## ---- the cardiometabolic panel of Figure 3C ----------------------------------
# Every trait in supplementary table ST03, in the order Figure 3C shows them.
# Blood pressure is reported in mmHg and put on an SD scale (standardise_sd).
# The GSCAN public files exclude 23andMe, so their Ns are the README's, not the
# paper's 23andMe-inclusive totals; the smoking split sums cohort N x % ever
# smokers from Liu et al. 2019 Suppl. Table 7 without 23andMe.
trait_entry <- function(template, label, group, n_label, file, ...) {
    modifyList(template, list(label = label, group = group, n_label = n_label,
                              file = file.path(dataset_dir, file), ...))
}
CARDIOMETABOLIC <- list(
    Triglycerides = trait_entry(GWAS_CATALOG, "Triglycerides", "Lipids", "1,320,016",
                          "triglycerides_GCST90239664.h.tsv.gz"),
    Lpa = trait_entry(GWAS_CATALOG, "Lp(a)", "Lipids", "343,821",
                "lipoprotein_a_GCST90474389.NLRP3region.tsv.gz"),
    ApoB = trait_entry(GWAS_CATALOG, "ApoB", "Lipids", "434,646",
                 "apolipoprotein_b_GCST90497142.h.tsv.gz"),
    non_HDL_C = trait_entry(GWAS_CATALOG, "Non-HDL-C", "Lipids", "1,320,016",
                      "non_hdl_cholesterol_GCST90239670.h.tsv.gz"),
    LDL_C = trait_entry(GWAS_CATALOG, "LDL-C", "Lipids", "1,320,016",
                  "ldl_cholesterol_GCST90239658.h.tsv.gz"),
    DBP = trait_entry(GWAS_CATALOG, "DBP", "Blood pressure", "1,028,980",
                "diastolic_bp_GCST90310295.h.tsv.gz", n_col = "n", standardise_sd = TRUE),
    SBP = trait_entry(GWAS_CATALOG, "SBP", "Blood pressure", "1,028,980",
                "systolic_bp_GCST90310294.h.tsv.gz", n_col = "n", standardise_sd = TRUE),
    Alcohol = trait_entry(GSCAN, "Alcohol", "Lifestyle", "537,349",
                    "alcohol_consumption_GCST007461.NLRP3region.tsv.gz"),
    Smoking = trait_entry(GSCAN, "Smoking", "Lifestyle", "311,629 / 321,173",
                    "smoking_initiation_GCST007474.NLRP3region.tsv.gz", binary = TRUE),
    BMI = trait_entry(GSCAN, "BMI", "Metabolic", "806,834", "bmi_GCST009004.NLRP3region.tsv.gz",
                chr_col = "CHR", ea_col = "Tested_Allele", oa_col = "Other_Allele",
                p_col = "P", sep = " "),
    T2D = trait_entry(T2DGGI, "T2D", "Metabolic", "242,283 / 1,569,734",
                "type2_diabetes_T2DGGI_EUR_GRCh38.tsv.gz", build = "GRCh38", binary = TRUE)
)


## ---- CAD outcome studies for the meta-analysis -------------------------------
# Aragam, MVP and FinnGen are genome-wide; All of Us is an extract.
CAD_STUDIES <- list(
    aragam = modifyList(GWAS_CATALOG, list(
        label = "Aragam et al.",
        file = file.path(dataset_dir, "coronary_artery_disease_aragam_GCST90132314.h.tsv.gz")
    )),
    # standard_error is NA throughout; the SE comes from the odds-ratio CI
    mvp = modifyList(GWAS_CATALOG_OR, list(
        label = "MVP",
        file = file.path(dataset_dir, "coronary_atherosclerosis_mvp_GCST90475936.h.tsv.gz")
    )),
    finngen = list(
        label = "FinnGen",
        file = file.path(dataset_dir, "coronary_atherosclerosis_finngen_R12.gz"),
        chr_col = "#chrom",
        pos_col = "pos",
        ea_col = "alt",
        oa_col = "ref",
        effect_col = "beta",
        se_col = "sebeta",
        eaf_col = "af_alt",
        p_col = "pval"
    ),
    # All of Us cannot be downloaded genome-wide. A collaborator extracted the
    # variants this pipeline reads - the NLRP3 window and every mediator
    # instrument - from SAIGE output: phecode CV_404.2, ACAF callset, EUR.
    # There are no allele columns. MarkerID is chr:pos_Allele1/Allele2, and
    # BETA and AF_Allele2 refer to Allele2.
    allofus = list(
        label = "All of Us",
        file = file.path(dataset_dir, "coronary_atherosclerosis_allofus_CV_404_2.instruments.tsv"),
        chr_col = "CHR",
        pos_col = "POS",
        marker_col = "MarkerID",
        effect_col = "BETA",
        se_col = "SE",
        eaf_col = "AF_Allele2",
        p_col = "Pvalue"
    )
)


## ---- analysis constants -------------------------------------------------------
PP_THRESHOLD <- 0.8 # HyPrColoc posterior probability for "strong evidence"
HYPR_PRIOR_1 <- 1e-4 # variant-specific prior, trait association
HYPR_PRIOR_C <- 0.02 # conditional colocalisation prior
