## config.R - paths, locus constants, sample sizes and the dataset registry.
##
## Declares where everything lives and nothing more: it opens no file and does
## no work. Sourced by every script in analysis/.

analysis_dir <- here::here()
dataset_dir <- file.path(analysis_dir, "datasets")
results_dir <- file.path(analysis_dir, "results")
figures_dir <- file.path(analysis_dir, "figures_out")

# Per-step result directories. Each analysis/NN_*.R writes only into its own.
step_dir <- function(step) {
    d <- file.path(results_dir, step)
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
    d
}


## ---- external binaries -------------------------------------------------------
plink2_bin <- "/rds/user/nh608/hpc-work/software/plink2/plink2"
gcta_bin <- "/rds/user/nh608/hpc-work/software/gcta/gcta-1.94.1"
tabix_bin <- "/rds/user/nh608/hpc-work/software/micromamba/envs/sambcfenv/bin/tabix"


## ---- UKB-PPP plasma proteomics -----------------------------------------------
# Access-controlled, so it stays outside this folder by design. One bgzipped,
# tabix-indexed file per assay, plus a .lst manifest of assay IDs.
ppp_dir <- paste0(
    "/rds/project/rds-C1Ph08tkaOA/public/proteomics/UKB-PPP/sun23/",
    "UKB-PPP pGWAS summary statistics (reformatted)/Combined_European"
)
ppp_manifest <- paste0(ppp_dir, ".lst")


## ---- LD reference ------------------------------------------------------------
# INTERVAL WGS, GRCh38, 11,863 European-ancestry whole genomes. Use the
# ld_panels/ copy: the sibling under WGS_reference/results/ uses a different
# variant ID convention and silently drops variants on an ID join.
ld_panel <- paste0(
    "/rds/user/nh608/hpc-work/oxLDL/data/oxLDL_data/INTERVAL_reference/",
    "WGS_reference/ld_panels/INTERVAL_allchr.GRCh38.alpha_sorted_alleles"
)


## ---- the NLRP3 locus (GRCh38) ------------------------------------------------
CHR <- 1L
GENE_START <- 247416156L # NLRP3 gene body, negative strand
GENE_END <- 247449108L

# +/-200 kb: the window used for colocalisation and COJO conditioning.
LOCUS_START <- as.integer(GENE_START - 200e3)
LOCUS_END <- as.integer(GENE_END + 200e3)

# +/-150 kb: the window the manuscript specifies for instrument construction.
INSTRUMENT_START <- as.integer(GENE_START - 150e3)
INSTRUMENT_END <- as.integer(GENE_END + 150e3)

NLRP3_ENSG <- "ENSG00000162711"
IL1RN_ENSG <- "ENSG00000136689" # chr2, positive control locus


## ---- instruments -------------------------------------------------------------
# The eight variants and the cis-NLRP3 activity score, selected from scratch on
# the INTERVAL panel by analysis/00_instrument_selection.R.
# Variant id -> rsID lookup, for labelling instruments in Figures 4C and the
# leave-one-out supplement. It omits the rarest variants, so both callers fall
# back to the readouts' own rsID columns.
rsid_map_file <- file.path(dataset_dir, "rsid_mapping.tsv.gz")

# IL1RN positive control (step 08): IL1RN is on chromosome 2, so it needs the
# chr2 eQTL release and the IL1Ra assay rather than the NLRP3 readouts.
il1rn_eqtl_file <- file.path(dataset_dir, "il1rn_eqtl_interval_chr2.tsv")
ppp_il1rn_assay <- file.path(ppp_dir, "IL1RN_P18510_OID20700_v1_Inflammation.bgz")

instrument_file <- file.path(
    results_dir,
    "00_instrument_selection",
    "nlrp3_instruments.tsv"
)

# The exposure is negated so every estimate reads per one-unit DECREASE in the
# activity score - the direction a pharmacological NLRP3 inhibitor moves a
# patient. Flip this in one place only.
EXPOSURE_DIRECTION <- "1-unit DECREASE in cis-NLRP3 activity score"


## ---- the four readouts used to build the score -------------------------------
# All GRCh38. See README.md for provenance of each file.
READOUTS <- list(
    NLRP3_expression = list(
        label = "NLRP3 expression",
        file = file.path(dataset_dir, "nlrp3_eqtl_interval_chr1.tsv"),
        n = 4732L,
        build = "GRCh38",
        chr_col = "chr",
        pos_col = "pos_b38",
        ea_col = "effect_allele",
        oa_col = "other_allele",
        effect_col = "slope",
        se_col = "slope_se",
        p_col = "pval_nominal",
        eaf_col = "af",
        # The release holds every gene tested in the window, so the rows are
        # restricted to NLRP3 on the way in.
        gene_col = "phenotype_id",
        gene = NLRP3_ENSG
    ),
    CRP = list(
        label = "CRP concentration",
        file = file.path(dataset_dir, "crp_GCST90029070.h.tsv.gz"),
        n = 575531L,
        build = "GRCh38",
        chr_col = "hm_chrom",
        pos_col = "hm_pos",
        ea_col = "hm_effect_allele",
        oa_col = "hm_other_allele",
        effect_col = "hm_beta",
        se_col = "standard_error",
        p_col = "p_value",
        rsid_col = "hm_rsid"
    ),
    GlycA = list(
        label = "GlycA concentration",
        file = file.path(dataset_dir, "glyca_GCST90497330.h.tsv.gz"),
        n = 434646L,
        build = "GRCh38",
        chr_col = "chromosome",
        pos_col = "base_pair_location",
        ea_col = "effect_allele",
        oa_col = "other_allele",
        effect_col = "beta",
        se_col = "standard_error",
        p_col = "neg_log_10_p_value",
        neglog10_p = TRUE,
        eaf_col = "effect_allele_frequency",
        rsid_col = "rsid"
    ),
    Neutrophil_count = list(
        label = "Neutrophil count",
        file = file.path(dataset_dir, "neutrophil_count_GCST90002351.h.tsv.gz"),
        n = 519288L,
        build = "GRCh38",
        chr_col = "hm_chrom",
        pos_col = "hm_pos",
        ea_col = "hm_effect_allele",
        oa_col = "hm_other_allele",
        effect_col = "hm_beta",
        se_col = "standard_error",
        p_col = "p_value",
        # the reference for the panel-vs-GWAS frequency guard in step 00:
        # the largest readout that ships an effect-allele frequency.
        # CRP is deliberately left without one - it is never used for that.
        eaf_col = "hm_effect_allele_frequency",
        rsid_col = "hm_rsid"
    )
)


## ---- disease and trait outcomes ----------------------------------------------
# Minimum proxy r2, and the INTERVAL proxies standing in for the two
# instruments the deCODE pericarditis release does not carry. LD is signed
# against each variant's ASCII-sorted A1.
PROXY_R2_MIN <- 0.9
PERICARDITIS_PROXIES <- tibble::tribble(
    ~SNP              , ~proxy_pos , ~proxy_a1 , ~proxy_a2 , ~r        ,
    "1_247438293_C_T" , 247442974L , "C"       , "T"       , -0.992093 , # r2 = 0.984
    "1_247452478_A_G" , 247457731L , "A"       , "G"       ,  0.831290 # r2 = 0.691
)
PERICARDITIS_PROXIES <-
    PERICARDITIS_PROXIES[PERICARDITIS_PROXIES$r^2 >= PROXY_R2_MIN, ]

# The window every outcome is read over.
INDICATION_REGION_START <- 247390000L
INDICATION_REGION_END <- 247650000L

# One entry per outcome: the three imaging traits first, then the disease
# outcomes, in the order the results table and the Figure 5 forest use. Each
# entry names a summary-statistics file and its column spelling. Step 08 reads
# `gout` and `ra_ishigaki` from here too.
OUTCOMES <- list(
    cac = list(
        label = "Coronary artery calcification (Agatston, CT)",
        file = file.path(
            dataset_dir,
            "coronary_artery_calcification_GCST90503074.h.tsv.gz"
        ),
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
    ),
    sis = list(
        label = "Coronary plaque burden (SIS, CTA)",
        file = file.path(
            dataset_dir,
            "coronary_plaque_burden_GCST90503075.h.tsv.gz"
        ),
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
    ),
    carotid = list(
        label = "Carotid plaque (ultrasound)",
        file = file.path(
            dataset_dir,
            "carotid_plaque_burden_GCST90503076.h.tsv.gz"
        ),
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
    ),
    allergic_rhinitis = list(
        label = "Allergic rhinitis",
        file = file.path(
            dataset_dir,
            "allergic_rhinitis_GCST90476021.h.tsv.gz"
        ),
        build = "GRCh38",
        chr_col = "chromosome",
        pos_col = "base_pair_location",
        ea_col = "effect_allele",
        oa_col = "other_allele",
        effect_col = "odds_ratio",
        effect_type = "OR",
        se_source = "ci",
        ci_lower_col = "ci_lower",
        ci_upper_col = "ci_upper",
        eaf_col = "effect_allele_frequency",
        p_col = "p_value",
        n_cases = 92310,
        n_controls = 311377
    ),
    als = list(
        label = "Amyotrophic lateral sclerosis",
        file = file.path(
            dataset_dir,
            "amyotrophic_lateral_sclerosis_GCST90027164.h.tsv.gz"
        ),
        build = "GRCh38",
        chr_col = "hm_chrom",
        pos_col = "hm_pos",
        ea_col = "hm_effect_allele",
        oa_col = "hm_other_allele",
        effect_col = "hm_beta",
        effect_type = "beta",
        se_source = "column",
        se_col = "standard_error",
        eaf_col = "hm_effect_allele_frequency",
        p_col = "p_value",
        n_cases = 27205,
        n_controls = 110881
    ),
    asthma = list(
        label = "Asthma",
        file = file.path(dataset_dir, "asthma_GCST90399686.h.tsv.gz"),
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
        p_col = "p_value",
        n_cases = 121940,
        n_controls = 1254131
    ),
    chronic_airway_obstruction = list(
        label = "Chronic airway obstruction",
        file = file.path(
            dataset_dir,
            "chronic_airway_obstruction_GCST90476027.h.tsv.gz"
        ),
        build = "GRCh38",
        chr_col = "chromosome",
        pos_col = "base_pair_location",
        ea_col = "effect_allele",
        oa_col = "other_allele",
        effect_col = "odds_ratio",
        effect_type = "OR",
        se_source = "ci",
        ci_lower_col = "ci_lower",
        ci_upper_col = "ci_upper",
        eaf_col = "effect_allele_frequency",
        p_col = "p_value",
        n_cases = 103054,
        n_controls = 315450
    ),
    gout = list(
        label = "Gout",
        file = file.path(dataset_dir, "gout_GCST90475735.h.tsv.gz"),
        build = "GRCh38",
        chr_col = "chromosome",
        pos_col = "base_pair_location",
        ea_col = "effect_allele",
        oa_col = "other_allele",
        effect_col = "odds_ratio",
        effect_type = "OR",
        se_source = "ci",
        ci_lower_col = "ci_lower",
        ci_upper_col = "ci_upper",
        eaf_col = "effect_allele_frequency",
        p_col = "p_value",
        n_cases = 42034,
        n_controls = 397989
    ),
    hfref = list(
        label = "Heart failure (reduced EF)",
        file = file.path(
            dataset_dir,
            "heart_failure_reduced_ef_GCST90475983.h.tsv.gz"
        ),
        build = "GRCh38",
        chr_col = "chromosome",
        pos_col = "base_pair_location",
        ea_col = "effect_allele",
        oa_col = "other_allele",
        effect_col = "odds_ratio",
        effect_type = "OR",
        se_source = "ci",
        ci_lower_col = "ci_lower",
        ci_upper_col = "ci_upper",
        eaf_col = "effect_allele_frequency",
        p_col = "p_value",
        n_cases = 31220,
        n_controls = 407213
    ),
    covid19 = list(
        label = "Hospitalized COVID-19",
        file = file.path(
            dataset_dir,
            "hospitalized_covid19_HGI_B2_release7_GRCh37.tsv.gz"
        ),
        # GRCh38 because of the b38_* columns below, not the filename
        build = "GRCh38",
        chr_col = "b38_chr",
        pos_col = "b38_pos",
        ea_col = "b38_alt",
        oa_col = "b38_ref",
        effect_col = "all_inv_var_meta_beta",
        effect_type = "beta",
        se_source = "column",
        se_col = "all_inv_var_meta_sebeta",
        eaf_col = "all_meta_AF",
        p_col = "all_inv_var_meta_p",
        n_cases = 32519,
        n_controls = 2062805
    ),
    knee_oa = list(
        label = "Knee osteoarthritis",
        file = file.path(
            dataset_dir,
            "knee_osteoarthritis_GCST90566800.h.tsv.gz"
        ),
        build = "GRCh38",
        chr_col = "chromosome",
        pos_col = "base_pair_location",
        ea_col = "effect_allele",
        oa_col = "other_allele",
        effect_col = "odds_ratio",
        effect_type = "OR",
        se_source = "ci",
        ci_lower_col = "ci_lower",
        ci_upper_col = "ci_upper",
        eaf_col = "effect_allele_frequency",
        p_col = "p_value",
        n_cases = 172256,
        n_controls = 1144244
    ),
    mi = list(
        label = "Myocardial infarction",
        file = file.path(
            dataset_dir,
            "myocardial_infarction_GCST90475932.h.tsv.gz"
        ),
        build = "GRCh38",
        chr_col = "chromosome",
        pos_col = "base_pair_location",
        ea_col = "effect_allele",
        oa_col = "other_allele",
        effect_col = "odds_ratio",
        effect_type = "OR",
        se_source = "ci",
        ci_lower_col = "ci_lower",
        ci_upper_col = "ci_upper",
        eaf_col = "effect_allele_frequency",
        p_col = "p_value",
        n_cases = 39074,
        n_controls = 392979
    ),
    obesity = list(
        label = "Obesity",
        file = file.path(dataset_dir, "obesity_GCST90475762.h.tsv.gz"),
        build = "GRCh38",
        chr_col = "chromosome",
        pos_col = "base_pair_location",
        ea_col = "effect_allele",
        oa_col = "other_allele",
        effect_col = "odds_ratio",
        effect_type = "OR",
        se_source = "ci",
        ci_lower_col = "ci_lower",
        ci_upper_col = "ci_upper",
        eaf_col = "effect_allele_frequency",
        p_col = "p_value",
        n_cases = 169600,
        n_controls = 244254
    ),
    parkinsons = list(
        label = "Parkinson's disease (Nalls 2019)",
        file = file.path(dataset_dir, "parkinsons_disease_GCST009325.tsv"),
        build = "GRCh37",
        chr_col = "chromosome",
        pos_col = "base_pair_location",
        ea_col = "effect_allele",
        oa_col = "other_allele",
        effect_col = "beta",
        effect_type = "beta",
        se_source = "column",
        se_col = "standard_error",
        eaf_col = "effect_allele_frequency",
        p_col = "p_value",
        n_cases = 33674,
        n_controls = 449056
    ),
    pericarditis = list(
        label = "Pericarditis",
        file = file.path(dataset_dir, "pericarditis_decode.txt.gz"),
        build = "GRCh38",
        chr_col = "Chrom",
        pos_col = "Pos",
        ea_col = "Effect_Allele",
        oa_col = "Other_allele", # lower-case 'a' in the actual header
        effect_col = "comb_Effect",
        effect_type = "OR",
        se_source = "p",
        p_col = "comb_Pval",
        proxies = PERICARDITIS_PROXIES,
        n_cases = 4894,
        n_controls = 1457822
    ),
    ra_ishigaki = list(
        label = "Rheumatoid arthritis (Ishigaki)",
        file = file.path(
            dataset_dir,
            "rheumatoid_arthritis_ishigaki_GCST90132223.h.tsv.gz"
        ),
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
        p_col = "p_value",
        n_cases = 22350,
        n_controls = 74823
    ),
    t2d = list(
        label = "Type 2 diabetes",
        file = file.path(
            dataset_dir,
            "type2_diabetes_T2DGGI_EUR_GRCh37.sumstats.zip"
        ),
        build = "GRCh37",
        chr_col = "Chromsome",
        pos_col = "Position",
        ea_col = "EffectAllele",
        oa_col = "NonEffectAllele",
        effect_col = "Beta",
        effect_type = "beta",
        se_source = "column",
        se_col = "SE",
        eaf_col = "EAF",
        p_col = "Pval",
        n_cases = 242283,
        n_controls = 1569734
    ),
    uc = list(
        label = "Ulcerative colitis",
        file = file.path(dataset_dir, "ulcerative_colitis_GCST004133.h.tsv.gz"),
        build = "GRCh38",
        chr_col = "hm_chrom",
        pos_col = "hm_pos",
        ea_col = "hm_effect_allele",
        oa_col = "hm_other_allele",
        effect_col = "hm_beta",
        effect_type = "beta",
        se_source = "column",
        se_col = "standard_error",
        eaf_col = "hm_effect_allele_frequency",
        p_col = "p_value",
        n_cases = 12366,
        n_controls = 33609
    )
)

# Outcomes that are not plain case/control disease risk.
ORDINAL_KEYS <- c("cac", "sis", "carotid")
## ---- mediators for the CAD mediation analysis --------------------------------
# SBP, ApoB and T2D.
MEDIATORS <- list(
    SBP = list(
        label = "Systolic blood pressure",
        file = file.path(dataset_dir, "systolic_bp_GCST90310294.h.tsv.gz"),
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
        p_col = "p_value",
        rsid_col = "rsid",
        n_col = "n",
        standardise_sd = TRUE,
        binary = FALSE
    ),
    ApoB = list(
        label = "Apolipoprotein B",
        # GWAS Catalog harmonised release, GRCh38.
        file = file.path(dataset_dir, "apolipoprotein_b_GCST90497142.h.tsv.gz"),
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
        p_col = "p_value",
        # p_value is the literal string "0.0" at APOE (30 variants); this column
        # carries the true magnitude (1370.89 at rs7412) and supplies the clump rank.
        nlog10_col = "neg_log_10_p_value",
        rsid_col = "rsid",
        n_col = "n",
        standardise_sd = FALSE,
        binary = FALSE
    ),
    # Same release as OUTCOMES$t2d; note the misspelled "Chromsome" header and
    # the absence of any rsID column - 07a maps CHR:POS(b37) -> rsID.
    T2D = list(
        label = "Type 2 diabetes",
        # Lifted GRCh37 -> GRCh38 by datasets/liftover_t2d_to_grch38.R.
        file = file.path(
            dataset_dir,
            "type2_diabetes_T2DGGI_EUR_GRCh38.tsv.gz"
        ),
        build = "GRCh38",
        chr_col = "Chromsome",
        pos_col = "Position",
        ea_col = "EffectAllele",
        oa_col = "NonEffectAllele",
        effect_col = "Beta",
        effect_type = "beta",
        se_source = "column",
        se_col = "SE",
        eaf_col = "EAF",
        p_col = "Pval",
        rsid_col = NULL,
        n_col = "Neff",
        standardise_sd = FALSE,
        binary = TRUE
    )
)

# Instrument selection for the mediators; these are the TwoSampleMR defaults.
MED_CLUMP_P <- 5e-8
MED_CLUMP_R2 <- 0.001
MED_CLUMP_KB <- 10000

# Mediator clumping runs against the INTERVAL panel (ld_panel), the same one
# every other step uses - see analysis/07a_mediator_instruments.R.

# All except T2D are GWAS Catalog harmonised releases and share one schema, so
# the column mapping is stated once instead of eleven times.
HARMONISED_COLS <- list(
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
    p_col = "p_value",
    rsid_col = "rsid",
    n_col = "n"
)

## ---- the cardiometabolic panel of Figure 3C ------------------------------------
# Every trait in supplementary table ST03, in the order Figure 3C shows them.
CARDIOMETABOLIC <- list(
    Triglycerides = utils::modifyList(
        HARMONISED_COLS,
        list(
            label = "Triglycerides",
            group = "Lipids",
            accession = "GCST90239664",
            n = 1320016L,
            n_label = "1,320,016",
            file = file.path(dataset_dir, "triglycerides_GCST90239664.h.tsv.gz")
        )
    ),
    Lpa = utils::modifyList(
        HARMONISED_COLS,
        list(
            label = "Lp(a)",
            group = "Lipids",
            accession = "GCST90474389",
            n = 343821L,
            n_label = "343,821",
            file = file.path(
                dataset_dir,
                "lipoprotein_a_GCST90474389.NLRP3region.tsv.gz"
            )
        )
    ),
    ApoB = utils::modifyList(
        HARMONISED_COLS,
        list(
            label = "ApoB",
            group = "Lipids",
            accession = "GCST90497142",
            n = 434646L,
            n_label = "434,646",
            file = file.path(
                dataset_dir,
                "apolipoprotein_b_GCST90497142.h.tsv.gz"
            )
        )
    ),
    non_HDL_C = utils::modifyList(
        HARMONISED_COLS,
        list(
            label = "Non-HDL-C",
            group = "Lipids",
            accession = "GCST90239670",
            n = 1320016L,
            n_label = "1,320,016",
            file = file.path(
                dataset_dir,
                "non_hdl_cholesterol_GCST90239670.h.tsv.gz"
            )
        )
    ),
    LDL_C = utils::modifyList(
        HARMONISED_COLS,
        list(
            label = "LDL-C",
            group = "Lipids",
            accession = "GCST90239658",
            n = 1320016L,
            n_label = "1,320,016",
            file = file.path(
                dataset_dir,
                "ldl_cholesterol_GCST90239658.h.tsv.gz"
            )
        )
    ),
    DBP = utils::modifyList(
        HARMONISED_COLS,
        list(
            label = "DBP",
            group = "Blood pressure",
            accession = "GCST90310295",
            n = 1028980L,
            n_label = "1,028,980",
            standardise_sd = TRUE,
            file = file.path(dataset_dir, "diastolic_bp_GCST90310295.h.tsv.gz")
        )
    ),
    SBP = utils::modifyList(
        HARMONISED_COLS,
        list(
            label = "SBP",
            group = "Blood pressure",
            accession = "GCST90310294",
            n = 1028980L,
            n_label = "1,028,980",
            standardise_sd = TRUE,
            file = file.path(dataset_dir, "systolic_bp_GCST90310294.h.tsv.gz")
        )
    ),
    # GSCAN: "Beta based on the alternate allele" (its README), so ALT is the
    # effect allele. No allele frequency is distributed, by design.
    Alcohol = list(
        label = "Alcohol",
        group = "Lifestyle",
        accession = "GCST007461",
        n = 941280L,
        n_label = "941,280",
        build = "GRCh37",
        chr_col = "CHROM",
        pos_col = "POS",
        ea_col = "ALT",
        oa_col = "REF",
        effect_col = "BETA",
        effect_type = "beta",
        se_source = "column",
        se_col = "SE",
        p_col = "PVALUE",
        file = file.path(
            dataset_dir,
            "alcohol_consumption_GCST007461.NLRP3region.tsv.gz"
        )
    ),
    Smoking = list(
        label = "Smoking",
        group = "Lifestyle",
        accession = "GCST007474",
        n_cases = 557337L,
        n_controls = 674754L,
        n_label = "557,337 / 674,754",
        build = "GRCh37",
        chr_col = "CHROM",
        pos_col = "POS",
        ea_col = "ALT",
        oa_col = "REF",
        effect_col = "BETA",
        effect_type = "beta",
        se_source = "column",
        se_col = "SE",
        p_col = "PVALUE",
        file = file.path(
            dataset_dir,
            "smoking_initiation_GCST007474.NLRP3region.tsv.gz"
        )
    ),
    BMI = list(
        label = "BMI",
        group = "Metabolic",
        accession = "GCST009004",
        n = 806834L,
        n_label = "806,834",
        build = "GRCh37",
        chr_col = "CHR",
        pos_col = "POS",
        ea_col = "Tested_Allele",
        oa_col = "Other_Allele",
        effect_col = "BETA",
        effect_type = "beta",
        se_source = "column",
        se_col = "SE",
        p_col = "P",
        sep = "whitespace",
        file = file.path(dataset_dir, "bmi_GCST009004.NLRP3region.tsv.gz")
    ),
    # The source spells the column "Chromsome"; that typo is upstream.
    T2D = list(
        label = "T2D",
        group = "Metabolic",
        accession = "T2DGGI",
        n_cases = 242283L,
        n_controls = 1569734L,
        n_label = "242,283 / 1,569,734",
        build = "GRCh38",
        chr_col = "Chromsome",
        pos_col = "Position",
        ea_col = "EffectAllele",
        oa_col = "NonEffectAllele",
        effect_col = "Beta",
        effect_type = "beta",
        se_source = "column",
        se_col = "SE",
        p_col = "Pval",
        file = file.path(dataset_dir, "type2_diabetes_T2DGGI_EUR_GRCh38.tsv.gz")
    )
)
## ---- CAD outcome studies for the meta-analysis -------------------------------
# Only these two are available genome-wide.
CAD_STUDIES <- list(
    aragam = list(
        label = "Aragam et al.",
        file = file.path(
            dataset_dir,
            "coronary_artery_disease_aragam_GCST90132314.h.tsv.gz"
        ),
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
        p_col = "p_value",
        rsid_col = "rsid",
        n_cases = 181522L,
        n_controls = 984168L
    ),
    mvp = list(
        label = "MVP",
        file = file.path(
            dataset_dir,
            "coronary_atherosclerosis_mvp_GCST90475936.h.tsv.gz"
        ),
        build = "GRCh38",
        chr_col = "chromosome",
        pos_col = "base_pair_location",
        ea_col = "effect_allele",
        oa_col = "other_allele",
        # standard_error is NA throughout; SE comes from the odds-ratio CI.
        effect_col = "odds_ratio",
        effect_type = "OR",
        se_source = "ci",
        ci_lower_col = "ci_lower",
        ci_upper_col = "ci_upper",
        eaf_col = "effect_allele_frequency",
        p_col = "p_value",
        rsid_col = "rsid",
        n_cases = 124302L,
        n_controls = 300039L
    ),
    finngen = list(
        label = "FinnGen",
        file = file.path(
            dataset_dir,
            "coronary_atherosclerosis_finngen_R12.gz"
        ),
        build = "GRCh38",
        chr_col = "#chrom",
        pos_col = "pos",
        ea_col = "alt",
        oa_col = "ref",
        effect_col = "beta",
        effect_type = "beta",
        se_source = "column",
        se_col = "sebeta",
        eaf_col = "af_alt",
        p_col = "pval",
        rsid_col = "rsids",
        n_cases = 63307L,
        n_controls = 416171L
    ),
    # All of Us: awaiting genome-wide data.
    allofus = list(
        label = "All of Us",
        file = file.path(
            dataset_dir,
            "coronary_atherosclerosis_allofus_genomewide.tsv.gz"
        ),
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
        p_col = "p_value",
        rsid_col = "rsid",
        n_cases = 19856L,
        n_controls = 150307L
    )
)

## ---- analysis constants -------------------------------------------------------
PP_THRESHOLD <- 0.8 # HyPrColoc posterior probability for "strong evidence"
HYPR_PRIOR_1 <- 1e-4 # variant-specific prior, trait association
HYPR_PRIOR_C <- 0.02 # conditional colocalisation prior
