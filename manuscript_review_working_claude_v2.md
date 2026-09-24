# Pre-submission audit — working log (Claude, v2)

Started 2026-09-23. Target journal: European Heart Journal (Clinical Research).

Inputs reviewed:
- `NLRP3_manuscript_WIP.docx` / `.pdf` (both modified 2026-09-23 18:28; PDF 32 pages)
- `SuppTables_completed_DRAFT.xlsx` (sheets Contents, ST01–ST16)
- Code/results snapshot taken 2026-09-23 18:40 at `trashtmp/claude_review_v3/snapshot_20260923_1840` (concurrent sessions edit this repo; later changes to `results/` may not be reflected)
- Extracted text: `trashtmp/claude_review_v3/paragraphs_marked.txt` (DOCX, P-numbered paragraphs with italics/super/subscript markup), `ms_layout.txt` (PDF text), `pages/p-NN.png` (PDF page images), `supp_dump.txt` (xlsx dump)

Paragraph references below use the DOCX paragraph numbers (P1…P210) from `paragraphs_marked.txt` plus the section name.

Explicit exclusions from the brief are not logged here.

## EHJ benchmark summary (Step 0B)

The full table is at `/rds/user/nh608/hpc-work/trashtmp/ehj_mr_benchmark_claude.md`. It has a separate name from the brief's path because the other LLM review writes `ehj_mr_benchmark.md`, and I did not open that file.

**Papers covered:**
- 52 EHJ (main journal) papers from 2019–2026 were screened.
- 51 were read in full:
  - 40 PMC full texts (with an adversarial second check)
  - 11 read through OUP pages or PDFs.
- 1 was read in part (non-linear MR vitamin D re-analysis, 2025).
- Supplements were checked for 20 core papers (Europe PMC API).

**Core set: 33 papers** where MR is the primary analysis or a major component.
- 11 are drug-target/cis.
- 14 have some mediation component.
- 5 have an inflammation exposure.
- 30 have a CV outcome.

Other papers:
- 7 have MR only as a minor component; 11 have no MR on reading.
- These count towards the structure and declarations totals only.

EHJ publishes few drug-target MR papers, and none uses a multi-trait composite score.

| Item (core set) | Reported / applicable | In main text |
|---|---|---|
| Heterogeneity statistic (Q, I² or het. P) | 8 / 31 (cis 2 / 9) | 6 |
| MR-Egger intercept | 19 / 30 (cis 4 / 8) | 15 |
| Weighted median | 19 / 30 | 18 |
| MR-PRESSO | 8 / 30 | 7 |
| F-statistic | 15 / 33 (cis 6 / 11) | 15 |
| Variance explained (R²) | 13 / 33 | 13 |
| Colocalisation | 6 / 33 (cis 4 / 11) | 6 |
| Steiger / reverse MR | 4 / 33 and 5 / 33 | – |
| Positive control | 5 / 33 (cis 3 / 11) | 5 |
| Negative control | 4 / 33 | 3 |
| STROBE-MR cited or checklist provided | 3 / 33 | 3 |
| Mediation analysis of any kind | 14 / 33 | 12 |
| Formal MR mediation (indirect effect or proportion) | 6 / 33; CI given in 4 / 6 | – |
| Multiple-testing correction | 14 / 33 | 12 |
| LD-matrix handling of correlated cis variants | 5 / 7 cis papers | – |
| Sample overlap discussed | 17 / 29 | 15 |
| Leave-one-out | 7 / 30 | 7 |
| Causal language | strong 15, moderate 16, cautious 2 (of 33) | – |

Limitations acknowledged (of 33):
- ancestry: 30
- pleiotropy: 28
- measurement: 25
- power: 18
- sample overlap: 17
- lifelong vs drug effect: 16
- weak instruments: 10
- survival bias: 9
- canalisation: 4
- tissue specificity: 1

Structure of all full-text papers published 2024–2026 (n = 24):
- Structured Graphical Abstract: 22/24
- Data Availability: 23/24
- Separate Ethical Approval section: 22/24
- Pre-registered Clinical Trial Number section: 22/24
- Author contributions in the text: 3/24
- Translational Perspective: 6/24
- Keywords: present in every paper.

Sex considered (SAGER), from a text scan: 5 of 22 core PMC papers mention sex-stratified analyses.

Published EHJ house style, after copy-editing:
- superscript citations placed after punctuation
- italic P
- 2024 onwards, no leading zero ("P = .03")
- "Supplementary data online, Table S1"
- Oxford -ize spelling (e.g. randomization, characterized, haematopoiesis).

## Step 0A — EHJ guideline checklist

Saved at `/rds/user/nh608/hpc-work/trashtmp/ehj_author_guidelines_checklist_claude.md`. That is not the path in the brief, because the other LLM review writes to the brief's path (`trashtmp/ehj_author_guidelines_checklist.md`, created 18:41). Using a separate file keeps the two reviews independent and stops either overwriting the other.

How it was built:
- Five scoped readers covered the current General Instructions (GI), the statistics page (ST), the 2021 Quality Standards editorial (QS), the Declarations Form (DF), the graphical-abstract guidance PDF (GAP) and the OUP figure/alt-text guides.
- A merge agent combined their output, then a completeness critic checked it.
- The result is 211 rules with verbatim quotes and URLs, plus 37 ambiguities (A17.x).
- I re-checked the key rules myself against the live GI page with WebFetch: word limit, abstract, SGA, keywords, legends, abbreviations and line numbers.

Rules most relevant to this manuscript (IDs from the checklist):
- **R1.4, R1.5:** at most 100 references and 6 panels per figure.
- **R2.1:** the title page needs the corresponding author's postal and email address.
- **R2.5:** SAGER, i.e. the title/abstract should say which sex(es) the study applies to.
- **R2.6:** up to 6 keywords.
- **R3.3:** abstract headings are Background and Aims / Methods / Results / Conclusions.
- **R4.1–R4.9:** a Structured Graphical Abstract is required:
  - Key Question, Key Finding and Take-home Message, each at most 40 words
  - a graphic of 11 × 18 cm
  - a legend of at most 80 words.
- **R5.1:** section order is title page, abstract and keywords, SGA, Introduction, Methods, Results, Discussion, Acknowledgements, Funding, Disclosure of interest, Data availability, References, Figure legends, Appendices.
- **R5.4, R13.x:** figures, tables and supplementary material are uploaded as separate files. Figures may be embedded at the initial format-free submission (R16.2).
- **R6.1, R8.2:** define non-standard abbreviations at first use and in every legend.
- **R8.1:** legends go after the References under "Figure Legends".
- **R8.3, R8.4:** a legend for a graph gives n and the statistical test; exact P values are preferred.
- **R8.5:** alt text goes under every main figure legend, starting "Alt text:".
- **R10.x:** references:
  - Vancouver style, with superscript numbers per the linked EndNote style
  - six authors, then "et al."
  - MEDLINE journal abbreviations
  - preprints tagged "[Preprint]"
  - datasets cited with an accession number (R10.13–14).
- **R11.26:** numbers one to ten are written in words.
- **R11.28:** "multivariable" vs "multivariate".
- **R12.1:** Oxford English spelling (-ize with British spelling otherwise).
- **R14.1–R14.4:** a Declarations Form with five declarations.
- **R14.45:** any use of AI (including writing code) is disclosed in the cover letter and in Methods or Acknowledgements.
- **R15.1–R15.4:** follow STROBE/STREGA and EQUATOR. STROBE-MR is not named, and no checklist upload is required.
- **R15.6–R15.8:** SAGER, i.e. how sex was considered, or the rationale if it was not.
- **R16.5–R16.11:** double spacing, page numbers, line numbers restarting on each page, unjustified text, paragraphs indented with one TAB.

Ambiguities the checklist records:
- A17.12: Oxford spelling is not defined.
- A17.13: P-value format.
- A17.17: gene italics.
- A17.18: citation placement.
- A17.19: whether supplementary items are called "Supplementary Table 1" or "Table S1".
- A17.24: whether causal language is allowed for MR.

For these I use the benchmark (published EHJ practice) to judge.


## Review order used

- **Numbers and code first:** Area 4 (Results vs outputs), then Area 3 (Methods vs code).
- **Then interpretation:** Area 2 (science and statistics), Area 5 (internal consistency), Areas 6/9 (figures, tables, captions, cross-references), Area 1 (references), Area 11 (declarations).
- **Then language:** Area 8 (conventions and abbreviations), Area 12 (typos), Area 13 (consistency).
- **Last:** Area 10 (document integrity), Area 7 (structure and narrative), Area 14 (final reviewer pass).

How the work was done:
- Scoped finder agents covered each area, and each finder batch then had an adversarial verifier.
- I checked the key numbers myself against the snapshot outputs.
- Workflow run IDs: numbers `wf_4310c0df-bad`, methods `wf_2328a271-d72`, science `wf_0e5626a5-b1a`, figures `wf_3c03da1c-179`, references `wf_62b650f2-6df`, language `wf_46ba80a5-fb4` and `wf_515595e3-a91`.
- Collected findings: `trashtmp/claude_review_v3/findings/findings.md`.

## Area 4 — Results vs code and outputs

**What was checked:**
- Every number in the Abstract, Results 4.1–4.6, the Discussion, the figure panels (PDF pages and `figures_out`) and ST05–ST09, ST11 and ST14–ST15, recomputed from the 18:40 snapshot outputs.
- Out of scope, and not checked: the pLoF values and the Figure 4A/4B data.

**What I confirmed myself** (these match the outputs):
- **Instruments and score:** lead-variant P values (P59), PC1 96.8%, R² (8.3%, 0.11%, 0.046%, 0.064%) and joint F 92.0.
- **Biomarkers and cytokines:** all estimates.
  - The IL-6 β prints as −0.72 in the PDF.
  - In the DOCX, that minus sign is a Word non-breaking hyphen, which my first extraction dropped, so it is not an error.
- **CAD:**
  - 1.21 (1.02–1.45), P = 0.032; weighted median 1.23 (1.06–1.42), P = 0.005.
  - Egger intercept 0.009 (0.002–0.016), P = 0.018.
  - Cases and controls: 388,987 / 1,850,685.
- **Imaging:** CAC 0.31; SIS POR 2.55; carotid POR 1.88.
- **Cardiometabolic traits:** ApoB, SBP and T2D all match.
- **Mediation:**
  - Conditional F 36.7 / 15.4 / 37.2.
  - Indirect ORs 1.080 / 1.047 / 1.045; 87%; direct OR 1.026 (0.85–1.24), P = 0.79.
- **Exploratory indications:** gout, pericarditis and Parkinson's disease all match, and 15 other indications is the correct count.
- **Proteome:** 27 lower and 7 higher proteins; 2,922 tested; 0.05/1821 = 2.7×10⁻⁵.
- **IL1Ra protein and gout estimates:** both match.

**Discrepancies (verified by me):**
1. **MAJOR, RA estimate out of date (P72).**
   - The text says OR = 0.26, 95% CI 0.07–0.94, P = 0.04.
   - The output, ST11 and Figure 4D all say OR 0.22 (0.11–0.41), P = 3×10⁻⁶. The step 08 outputs were regenerated on 23 Sep at 15:26.
   - Not a reporting-norm issue.
2. **MAJOR, Figure 3E is built differently from the text and Methods.**
   - The waterfall comes from three separately refitted nested MVMR models, not from the joint model the text describes:
     - SBP only: 833 variants
     - SBP + ApoB: 876 variants
     - all three: 1,265 variants.
   - As a result:
     - Figure 3E shows ΔOR 0.09 / 0.06 / 0.03, so ApoB looks about twice T2D.
     - The text cites Figure 3E for the joint-model indirect ORs, where ApoB 1.047 and T2D 1.045 are almost equal.
     - The nested models are not described anywhere in the Methods.
   - Redrawing Figure 3E from the joint model gives 1.21 → 1.12 → 1.07 → 1.03 (ΔOR 0.09 / 0.05 / 0.05).
   - Found independently by four agents.
3. **MUST FIX, direct-effect precision (P68).**
   - P68 has OR 1.026 with a two-decimal CI, while the Abstract and Figure 3E have 1.03.
4. **MUST FIX, "shared colocalising variant (rs12239046)".**
   - Appears in P41, P74, the Supp Fig 4 caption and label, and ST14.
   - The HyPrColoc candidate is actually rs58546652 (1_247438476). rs12239046 is its near-perfect proxy (r² 0.98), and the two are tied for the CRP lead.
5. **MUST FIX, displays of "−0.00".**
   - Figure 2C, IL-1β upper CI: the text says −0.004.
   - Figure 3C, Lp(a) weighted-median upper CI.
6. **MUST FIX, Figure 3C header and axis.**
   - Both say "β", but the T2D and smoking rows are log ORs (0.23 is shown for the OR of 1.26 quoted in the text).
7. **MAJOR, Cochran's Q.**
   - Methods P41 says heterogeneity was assessed with Cochran's Q, but no Q appears in the text or any ST (grep finds 0 hits).
   - Values available from the outputs or recomputation:
     - CAD: Q 13.9, 7 df, P = 0.053.
     - CRP: P = 0.004.
     - Neutrophil count: P = 2×10⁻⁵.
     - SBP / ApoB / T2D: P 0.93 / 0.94 / 0.68.
     - MVMR: Q/df about 16.
   - EHJ norm: heterogeneity statistics are reported in 8 of 31 core EHJ MR papers (6 in the main text).
   - The fix is needed because the Methods claim an analysis that is never reported (EHJ R11.27: no statement without data).
8. **MUST FIX, IL-6 assay chosen by significance, undisclosed.**
   - IL-6 is measured by four Olink assays. The step 04 code keeps the smallest-P one (Oncology, P 2.8×10⁻⁹).
   - The others give β −0.58 to −0.70, all P ≤ 1.6×10⁻⁵.
   - The same rule is applied in ST12 (six proteins).
   - Disclose it in the Supplement.
9. **MUST FIX, unexplained ST07 rows R12–R13.**
   - The rows are labelled "Meta-analysis (excl. 1_247460342_C_G)", with no mention in the text.
   - The code dropped this variant because of a FinnGen allele-frequency discrepancy.
   - The rows duplicate the ST14 leave-one-out.
10. **MUST FIX, flank colocalisation not reported.**
    - "No additional colocalising signals… 200 kb–1 Mb" is cited to Supp Fig 2, which shows no colocalisation output and no expression panel.
    - The HyPrColoc flank result (all posterior probabilities ≤ 0.13) appears nowhere.
11. **MUST FIX, supplementary table formatting.**
    - CI strings drop trailing zeros, e.g. "(1.04, 1.7)" and "(0.8, 1.33)".
    - P values use E-notation even for P = 0.816.
    - Affects ST06, ST07, ST08, ST14 and ST15.
    - Cause: the `ci()` function in `build_supplementary_tables.R`.
12. **MUST FIX, ST08 scale.**
    - ST08 mixes ORs (smoking, T2D) and SD betas under one header, with no Scale column (ST07 has one).

**Interpretive points from this pass:**
- These are carried to Area 2: the null-ish Wald ratio for rs12239046, the upstream eQTL rs6689545 and the null MI estimate.
- Leave-one-out: the CAD IVW P value rises above 0.05 in 4 of 8 leave-one-out analyses (P = 0.053–0.063), but every estimate stays above 1. "Directionally consistent" is therefore the right word, and "robust" would overclaim.

## Area 3 — Methods vs code (finders M1–M4, all verified)

**What was checked:**
- Methods 3.2–3.11, SI 14.1–14.4 and the captions, line by line against the snapshot code (00–12, 09b, helpers.R, config.R, the table builder).
- The M1 agent reran step 00 in scratch and reproduced the 8 instruments, PC1 96.8% and k 0.306.

**These match the text:** windows, clumping parameters, block merging ("ten" components), specificity filter, CRP scaling, delta-method SE (conservative), joint F, HyPrColoc inputs and priors (defaults), COJO on rs6689545, random-effects IVW with the LD matrix, SNP-level fixed-effect CAD meta-analysis, leave-one-out and Wald ratio, full re-selection in the r² sweep, mediator clumping, multiplicative random-effects MVMR, delta method, and the conditional F computation (MVMR::strength_mvmr).

**Verified discrepancies:**
1. **MUST FIX, P37 selection rule.**
   - P37 says "retained variants associated at genome-wide significance with at least two traits".
   - The code applies the two-trait rule to merged signals (r² > 0.95).
   - rs74154640 is a proxy for rs10925024 and is genome-wide significant only for CRP (GlycA 1.2×10⁻⁷; neutrophil 9×10⁻⁸; ST05 shows this).
   - Two of the ten multi-trait signals were dropped because they were missing from some datasets. P37 doesn't say this, so a reader can't reconcile the 10 signals in the UpSet plot with the 8 variants.
   - The Supp Fig 1 caption says intersections count "variants"; they count signals.
   - Fix: reword P37, add a pointer to the SI, and correct the Supp Fig 1 caption.
2. **MUST FIX, SI P127 proxy rule.**
   - The SI says "the variant in highest LD".
   - The code treats proxies within 0.05 of the top r² as ties and breaks the tie by lowest CRP P. The chosen proxy (r² 0.911) was not the highest-LD one (0.920).
3. **MUST FIX, SI P127 frequency filter.**
   - The filter was applied against the neutrophil GWAS only.
   - It also restricted all traits to SNVs present in that file, which dropped every indel, including 16 genome-wide significant CRP indels.
   - The SI describes a different rule.
4. **MUST FIX, PCA centring.**
   - Centred PCA on allele-coding-dependent effect signs makes "96.8%" depend on the arbitrary ASCII allele coding: across codings it ranges 86.8–98.5%.
   - Uncentred PCA gives 97.1% for any coding, and the score betas stay within 0.06%.
   - Fix: rerun with center = FALSE (P62 would then say 97.1%), or disclose the coding in the Supplement.
5. **MUST FIX, SI P132 orientation.**
   - The SI says scores are oriented to CRP.
   - The code orients them to target-gene expression, so the IL1Ra score runs opposite to CRP. The SI wording is wrong for IL1Ra.
6. **MUST FIX, positive-control data sources.**
   - The sources are not stated.
   - The IL1Ra protein (UKB-PPP Olink Inflammation, n 50,898) and the INTERVAL IL1RN eQTL have no row in ST01.
7. **MUST FIX, Cochran's Q** (with Area 4): computed only in steps 09 and 11, and reported nowhere.
8. **MUST FIX, MR-Egger.**
   - The Methods say MR-Egger is not a causal estimator, yet ST07 row R14 shows an MR-Egger OR 0.93 (0.72–1.20), and ST12 has Egger columns.
   - The Egger intercept is computed only for biomarkers, CAD and the proteome, not for the mediators or the indications.
   - Fix: label the ST07 row "shown for completeness" or remove it.
9. **MUST FIX, IL-6 assay chosen by smallest P** (with Area 4). The same rule applies to 6 proteins in ST12.
10. **MUST FIX, reporting scales in P41.**
    - P41 names only betas and ORs.
    - The proportional ORs for the ordinal plaque scores are introduced only in the Figure 3 caption.
11. **MUST FIX, outcome proxies and missing variants.**
    - Pericarditis uses 5 of 8 variants, one via an LD proxy (r² 0.98), with SEs derived from P values.
    - Knee OA uses 6 of 8.
    - None of this is stated, though pericarditis is highlighted in the Abstract.
12. **MUST FIX, ST13.**
    - ST13 contains MSigDB Hallmark results, which the Methods never describe.
    - It also applies an undisclosed adjusted-P < 0.5 display filter.
13. **MUST FIX, SI P138.**
    - The covariate list omits age² and age² × sex.
    - The European-only restriction of the correlation matrix is not stated.
14. **MUST FIX, software versions.** Versions are missing for HyPrColoc (0.0.2), GCTA (1.94.1) and PLINK 2 (v2.00a6), while other tools have them (EHJ QS R11.25).
15. **MUST FIX, mediator selection (P35).**
    - P35 says traits "showing evidence of association were carried forward to mediation".
    - Only 3 of 7 associated traits were carried forward. TG, non-HDL-C, LDL-C and DBP were also associated, and DBP's exclusion is never explained.
16. **MUST FIX, MVMR instrument count.** The number of variants (1,265 after pooled clumping; 848 SBP / 130 ApoB / 738 T2D before) is not reported. STROBE-MR basic item.
17. **MAJOR, Figure 3E nested models** (with Area 4): the sequential models are undescribed in the Methods.
18. **MUST FIX, unexplained ST07 rows R12–R13** (with Area 4).

**Refuted and dropped:**
- M1-0: the score uses the unconditioned eQTL for rs61838754. MR correctly pairs marginal exposure and outcome estimates, and the CAD result is unchanged without this variant. At most an optional clause.
- M2-3 / M4-15: the IL-6 minus sign (Word non-breaking hyphen).
- M4-4: the ST16 indications not analysed. P55 gives the criterion; 5, not 6, were not analysed.

## Area 1 — References (REF1–REF4, all verified; 65 references, all 72 citation fields mapped correctly, first-citation order monotonic)

**Citation-support problems:**
1. **MAJOR, SI P144 (ref 65).**
   - The SI says the MCC950/CP-456773 phase 2 trial was "terminated due to off-target hepatotoxicity rather than lack of efficacy".
   - Mangan 2018 says only that it "was not developed further as it was found to elevate serum liver enzyme levels", and that the cause is unclear. It says nothing on efficacy or termination.
   - This is the only stated reason for including RA.
2. **MUST FIX, ref 24.**
   - Ref 24 (Rietveld 2023, MA-GREML) is cited for the delta method (P37, P133) and for the multivariate delta method in the mediation analysis (P45). It does not describe these.
   - Replace with Carter et al., Eur J Epidemiol 2021;36:465–478 (reference count unchanged).
3. **MUST FIX, ref 29.**
   - Ref 29 (Sanderson 2019) is cited for the MVMR package and the conditional F.
   - The package's citation, and the covariance-adjusted conditional F with phenocov_mvmr, come from Sanderson, Spiller & Bowden, Stat Med 2021;40:5434–5452.
4. **MUST FIX, ref 22.**
   - Ref 22 (Kurki 2023) describes FinnGen release 5 (224,737 participants).
   - The counts in the text (63,307 / 416,171) are from release 12 (I9_CORATHER), and the release is never stated.
5. **MUST FIX, ref 40.**
   - Ref 40 (Sham & Purcell 2014) does not describe the 95%-variance rule for the effective number of tests.
   - The code uses Gao's simpleM at 95%; the standard simpleM cut-off is 99.5%.
   - Fix: cite Gao 2008 and add a robustness line. Plain Bonferroni over 2,922 proteins would keep about 30 of 34 (agent's figure; verify).
6. **MUST FIX, ZEUS (ref 5).**
   - The ZEUS result is a top-line press release (HR 0.99, 0.88–1.11), cited via a pre-proof commentary.
   - The trial population was ASCVD plus CKD plus high hsCRP.
   - P19 and P80 present it as a general null for IL-6 inhibition.
   - Fix: say "top-line results" and add the population in one clause. Add the DOI, since ref 5 has no volume.
7. **MUST FIX, P31 CRP assay.**
   - "With CRP measured using immunoturbidimetric assays" applies only to the UK Biobank part (the CHARGE component is 26%).
   - Delete the clause.
8. **MUST FIX, P31 neutrophil sample size.**
   - "Meta-analysis including 519,288 individuals": 519,288 is the European subset, and the meta-analysis had 746,667 (as the ref 16 title says).
9. **MUST FIX, P82 TET2 subgroup (ref 52).**
   - P82 says "showed a greater reduction", but the interaction was P = 0.14 ("equivocal").
   - Fix: "a numerically greater reduction".
10. **Dropped:** REF1-0, refs 7 and 8 for IL-6 → acute phase. The verifier showed that Bartlett 2016 does mention it. Adding ref 1 is optional.

**Bibliography problems (MUST FIX):**
- Ref 21 lacks the "[Preprint]" tag (R10.11).
- Refs 28 and 63 (software) lack version and URL (R10.4).
- Non-MEDLINE journal abbreviations (R10.6):
  - ref 56: "NPJ Park Dis" → NPJ Parkinsons Dis
  - ref 62: "The Innovation" → Innovation (Camb)
  - ref 43: "Rheumatology" → Rheumatology (Oxford)
  - ref 24: "PLOS Genet" → PLoS Genet.
- Ref 52 is missing its subtitle ("…: An Exploratory Analysis of the CANTOS Randomized Clinical Trial").
- Ref 56 omits the group author GP2.
- Refs 16 and 61 use a hyphen in their page ranges; everywhere else uses an en dash.
- The ref 13 title lacks the Lp-PLA₂ subscript.
- Author initials: ref 43 "Jansen TLThA" should be "Jansen TLTA".
- ST01 has "Sun B" and "Chen MH" where the references have "Sun BB" and "Chen M-H".
- The ST02 All of Us row has no DOI.
- Article titles mix Title Case (18 refs) and sentence case (low priority; copy-editing fixes this).

**EHJ data-citation rule (R10.13–R10.14):**
- Public datasets are not cited in the reference list with an accession number and "[dataset]" tag. The accessions are only in ST01–ST04.
- Main analyses need about 15 entries (about 80 references in total).
- Binding at revision at the latest.

**Not issues:**
- DOIs: not required by EHJ; the examples only show them.
- Refs 59–65 cited only in the SI: they will need an SI reference list when the SI is split out.

**EHJ norm:** none of these depends on reporting norms. They are errors or EHJ rules.

## Area 2 — Scientific and statistical review (S1, S2 verified; S3/C1 overlapping points folded in)

**Sanity checks done (all consistent):**
- 87% = 0.1674 / 0.1929 on the log-odds scale.
- F and R² agree: 660.8 / (660.8 + 575,522) = 0.11%.
- Egger intercept CI from its SE.
- Every OR, CI and P triple is internally consistent.
- Between-study heterogeneity for CAD: Q = 2.58 on 3 df, P = 0.46.
- Max r² between rs10754555 (the Schunk variant) and the instruments = 0.26.
- Delta-method SE is conservative (1.09× the independence SE).
- Conditional F values reproduce.

**Verified issues:**

1. **MAJOR, the colocalising-signal result is under-reported (P74–P75).**
   - The Wald ratio for rs12239046, the only signal with colocalisation support, is OR 1.05 (0.89–1.23), P = 0.58. P74 calls it "directionally consistent" and gives no number.
   - Without rs12239046 the IVW OR is 1.34 (1.13–1.59), P = 7×10⁻⁴, and Q drops from 13.9 (P = 0.053) to 7.8.
   - Leave-one-out estimates are all > 1, but 4 of 8 have P 0.053–0.063. So "directionally consistent" is the right wording for leave-one-out; "robust" would overclaim.
   - The r² sweep is consistently significant: OR 1.16–1.22, all P ≤ 0.024.
   - Fix: give the Wald ratio number in P74, call the r² sweep "consistent" and leave-one-out "directionally consistent". Optionally add one clause to Limitations.
   - EHJ norm: accurate reporting, not a norm issue.

2. **MAJOR, the pleiotropy rebuttal answers the wrong question and undersells the paper (P90, P65).**
   - The Limitations counter horizontal pleiotropy of the cardiometabolic associations with the rare-variant evidence. But the rare variants were tested only for CRP, GlycA and neutrophils, so they support NLRP3 as the causal gene for the inflammatory signal, not for SBP, ApoB or T2D.
   - The data that do address it are unreported, and they are supportive:
     - Cochran's Q across the 8 variants: SBP 2.46 (P 0.93), ApoB 2.36 (P 0.94), T2D 4.84 (P 0.68).
     - Egger intercept P: 0.22 / 0.81 / 0.13.
     - The CAD Egger intercept is non-zero only at r² < 0.1. At r² < 0.2 to 0.6 its P is 0.86, 0.46, 0.20, 0.20 and 0.31.
   - Fix: rewrite the P90 sentence and add Q and intercept columns to ST08.
   - EHJ norm: pleiotropy is acknowledged in 28/33 papers; heterogeneity statistics are reported in 8/31. The specific reason to act here is that the current text is a non sequitur, and the fix strengthens the paper.

3. **MAJOR, the null MI estimate is never mentioned (Figure 5 / P77).**
   - MI in MVP: OR 1.01 (0.70–1.45), P = 0.98, shown directly under "Cardiovascular".
   - It is compatible with the CAD OR (z for the difference 0.91, P 0.36).
   - A one-clause fix prevents a reviewer doubting the headline.
   - Not a norm issue.

4. **MAJOR, exposure–outcome sample overlap is not mentioned.**
   - UK Biobank is in all three biomarker GWAS and in the Aragam CAD meta-analysis.
   - The text states "no sample overlap" only for SCAPIS, which draws attention to the silence elsewhere.
   - With F = 92, the bias is small, and it would push towards the observational (null/protective) direction.
   - Fix: one sentence in Limitations or the Supplement.
   - EHJ norm: discussed in 17/29 core papers, i.e. the majority.
   - This is not the excluded mediation-overlap point.

5. **MUST FIX, mediation wording.**
   - P81 says "almost all"; P79 says "no evidence of a residual direct association". Everywhere else the wording is "largely / most (87%)" and P68 says "little evidence".
   - Align P81 and P79.

6. **MUST FIX, ZEUS (P19, P80).** Say "top-line results" and name the population (ASCVD + CKD + high hsCRP). See Area 1.

7. **MUST FIX, CANTOS TET2 subgroup (P82).** Interaction P = 0.14, so use "numerically greater". See Area 1.

8. **MUST FIX, RA called "suggestive" at P = 0.14 (P77).**
   - Knee OA (weighted median P 0.027) and HFrEF (weighted median P 0.074) are not singled out.
   - Fix: delete the sentence, which saves 15 words.
   - This is a wording point only (the no-correction position is respected).

9. **MUST FIX, PCA centring depends on allele coding** (Area 3, item 4).

10. **MUST FIX, effective number of tests.**
    - The 95%-variance simpleM cut-off is credited to ref 40, but the standard simpleM cut-off is 99.5%.
    - Fix: cite Gao 2008 and add one robustness line: plain Bonferroni over 2,922 proteins keeps 30 of 34 (24 lower, 6 higher). I verified this count.

11. **MUST FIX, IL-6 assay chosen by minimum P** (Area 4, item 8).

12. **MUST FIX, ST07 MR-Egger slope row (OR 0.93).** Methods say MR-Egger was not used as a causal estimator. Delete the row or footnote it.

**Considered and dropped (verifier-refuted or below the bar):**
- S2-4: IL-1 genetics vs CANTOS. Ref 48 models dual IL-1α/β inhibition and itself says it doesn't predict canakinumab.
- S1-12: PC1 loadings applied to unstandardised betas. Negligible impact, and the SI formula already describes it.
- S1-11: SI "increased specificity" sentence. MINOR; optionally change to "no primary instrument was excluded".
- IL1Ra positive-control heterogeneity: Q = 54.5 on 2 df. Random-effects IVW still gives P = 10⁻¹⁰. Only needs a footnote if Q columns are added.

## Area 5 — Internal consistency (finder C1; its points overlap with Areas 2–4 and are merged there)

Verified contradictions between sections:
- **P72 vs Figure 4D / ST11:** the RA estimate differs (Area 4).
- **P68 vs Figure 3E:** the mediator contributions differ (Area 4).
- **P41 / P74 / Supp Fig 4 / ST14 vs HyPrColoc output:** the "shared colocalising variant" is labelled with the wrong variant.
- **P59 vs Figure 2A:** the text calls rs58546652 the expression lead, but the panel shows a taller unconditioned upstream peak. The caption should say the panel is unconditioned.
- **P37 vs ST05 / Supp Fig 1:** the selection rule wording doesn't match the selected variants (Area 3).
- **P35 vs P45:** the text implies all associated traits went into the mediation analysis; only 3 of 7 did.
- **Mediation wording:** P81 says "almost all" and P79 says "no evidence", while the Results say "87%" and "little evidence".
- **Direct-effect OR:** 1.026 (P68) vs 1.03 (Abstract, Figure 3E).
- **CAD weighted-median P:** 0.005 (P65, Figure 3A) vs 0.0047 (Figure 4F, Supp Fig 4).
- **P41 vs ST07:** the Methods say MR-Egger is not a causal estimator, yet ST07 shows an Egger slope OR.
- **Search date:** P55 "28 of April" vs P141 "28th of April".
- **Trial phases:** "phase 3" / "phase 2a" in the main text vs "Phase II" in P144 vs "Phase 2" in ST16.
- **P73 wording:** "raised by inhibition" and "downregulated" describe a genetic association as a drug effect, against the paper's own caveat.
- **Discussion P79:** calls ApoB a "proatherogenic lipid".

**Refuted:** C1-10, "All of Us data are not public". The All by All public browser exists (Lu et al.), so the Data availability wording is defensible.

## Areas 6 and 9 — Figures, tables, captions and cross-references (F1–F3 verified; my own image checks)

**Numbers:** every printed value in Figures 2C, 3A–E, 4C–F and 5 matches the outputs. The pLoF/GoF panels were not checked.

**Cross-references:**
- First citations run in order.
- Every figure panel is cited.
- ST16 is cited only in the SI (EHJ R13.4).

**Verified problems:**
1. **Figure 3E:** see Area 4 (MAJOR).
2. **Figure 3C:** the header and axis say "β", but the T2D and smoking rows are log ORs. The text quotes OR 1.26 while the panel shows 0.23.
3. **"−0.00" CI bounds:** Figure 2C (IL-1β) and Figure 3C (Lp(a) weighted median).
4. **Figure 2A:**
   - The y-axis reads "−log10(P − value)" (plotmath minus); Supp Fig 2 has the same.
   - The NLRP3 expression panel is unconditioned, and this is unexplained.
   - The index variant (rs12239046), dashed line, grey NA and recombination line are not explained in the legend.
5. **Figure 2B:** tick labels are rounded values placed at unrounded positions (up to 9% off). Units and error bars are undefined.
6. **Figure 1:**
   - The panel title "Causal Effects on CAD" contradicts the association wording used everywhere else.
   - The caption lists pericarditis, but the graphic doesn't show it.
7. **Figure 3 legend:** doesn't say that red = IVW and blue = weighted median, or that the bars are 95% CIs. ΔOR is undefined.
8. **Figure 3 text size:** the panels are shrunk to 74%, so body text prints at about 5 pt.
9. **Figure 4C:** the legend doesn't say which allele is shown, what the error bars are, or the units.
10. **Figure 4E:** GO labels are in Title Case ("To"); the legend title "Adj. P-value" doesn't match the caption's "adjusted P value".
11. **Figure 5:**
    - The pericarditis (5/8) and knee OA (6/8) variant counts are not given.
    - The arrowheads are unexplained.
    - "Hospitalized" uses US spelling; "Parkinson's" has a straight apostrophe.
12. **All figures:** P values in e-notation, with 1–3 significant figures ("1e-10", "7e-4"). "Weighted Median" is capitalised; axes say "per one unit" where the captions say "one-unit".
13. **Supp Fig 1:** the embedded version is an older render (bar order and font differ from figures_out). "Neutrophil Count" is capitalised.
14. **Supp Fig 2:** about 75% of grey (no LD value), non-significant neutrophil variants were randomly dropped from the plot (`thin_grey()` keeps a random quarter), and this is undisclosed (figure integrity). The "Index SNP" key has no symbol, and the legend text is about 4.7 pt.
15. **Supp Fig 3:** a 187-ppi raster.
16. **Supp Fig 3 caption:** says "all protein-coding genes within ±150 kb", but OR2G2 lies in that window and is not shown. Could not be verified (depends on the pLoF pipeline window).
17. **Supplementary tables:**
    - PMIDs display with thousands separators ("35,459,240").
    - CI strings drop trailing zeros.
    - All P values are in E-notation.
    - There are no notes on scale, direction or abbreviations.
    - ST08 has no Scale column.
    - ST06 uses gene symbols for the cytokines.
    - ST07 has unexplained exclusion rows and an Egger slope row.
    - ST13: Hallmark results undisclosed, Description = Term ID, and the adjusted P < 0.5 display filter is unstated.
    - ST14: 'All instruments' rows duplicate the r² < 0.1 rows, and variants are labelled by chr_pos.
    - ST12 "Bonferroni" column is P × 1,821, unlabelled.
    - ST16: a COPD EudraCT number is labelled CTIS.
    - ST01/ST02: "Sun B" / "Chen MH" author forms; All of Us DOI missing.
    - Mixed NA / N/A / – markers; non-breaking spaces; "International Parkinson Disease Genomics Consortium" missing the possessive; hg38 vs GRCh38.
    - Contents sheet says "ST01" where the text says "Supplementary Table 1".

**Refuted:** R4c-14, legend abbreviations. EHJ R8.2's second sentence says abbreviations defined in the text need not be redefined, and the legends apply that rule consistently. What remains valid is undefined symbols, plus abbreviations defined nowhere (SD, OR, CI, SNP, ΔOR).

## Area 11 — Declarations and end matter (X1 verified)

1. **MAJOR, no AI-use disclosure.**
   - The public GitHub repository linked in Data availability shows 16 of 23 commits co-authored by Claude models.
   - EHJ R14.45 requires disclosure in the cover letter and in Methods or Acknowledgements.
   - EHJ norm: EHJ rule.
2. **MAJOR, Disclosure of interest.**
   - It covers N.H., S.B. and D.S.P. only. There is no statement for A.S.B. and no "none declared" for the others.
   - This is not the excluded author-list point: it is the content of the statement for listed authors.
   - EHJ R14.5–R14.7.
3. **MUST FIX, public code repository.**
   - The repository is behind the snapshot: 09b, the table builder and some figure scripts are missing.
   - "Code used for all analyses" is not true for the rare-variant analyses.
   - Warning: the local unpushed HEAD commit contains the manuscript and review files. Don't push it as is.
4. **MUST FIX, datasets not in the reference list.**
   - 11 source GWAS behind reported results are not cited: RA (Ishigaki), PD (Nalls), pericarditis (Thorolfsdottir/deCODE, whose readme asks users to cite it), lipids (GLGC), BMI, smoking (GSCAN), ALS, asthma (GBMI), COVID (HGI), UC, UKB WGS.
   - EHJ R10.13 also wants a [dataset] entry with accession.
5. **Check, INTERVAL acknowledgement.** INTERVAL has only a generic thank-you. Its standard acknowledgement text may be a data-use condition (PLAUSIBLE; could not verify).
6. **MUST FIX, headings "10. Ethical Approval" and "11. Pre-registered Clinical Trial Number".** These are Title Case; the EHJ Declarations Form uses sentence case.
7. **MUST FIX, spelling.** "authorized" in P100 is the only -ize word outside the fixed term "Mendelian randomization" (spelling consistency).
8. **Not raised:** STROBE-MR statement. EHJ doesn't require it (A17.6), and only 3/33 benchmark papers cite it.
9. **Refuted:** All of Us "not public".

## Area 7 — Structure and narrative (S3 verified: S3-0 confirmed, S3-5 plausible, S3-7 title refuted)

1. **MAJOR (undersell), Abstract Conclusions (P16).**
   - They end on a caveat ("should not be interpreted as equivalent to … pharmacological inhibition") rather than the clinical take-home.
   - The take-home appears only at the end of P81 and in P91: no genetic support for cardioprotection; trials should monitor BP, lipids and glycaemia.
   - P79 also ends with a qualified negative.
   - The caveat already sits in the Limitations and P91.
   - EHJ norm: EHJ abstracts put the take-home in the Conclusions (the SGA Take-home Message field requires one anyway).
2. **MAJOR-low (undersell), Introduction (P23).**
   - The aim is generic and novelty is never stated.
   - The prior human genetic evidence (Schunk et al., EHJ 2021) and the reason for a composite score (no single biomarker captures NLRP3 activity) appear only later, in P62/P79/P88.
   - Fix: a ~45-word P23 rewrite, offset by cutting the repetition in P81 (sentence 2, −21 words) and P89 (sentences 1–2, −39 words).
3. **MUST FIX, blank block.** Five empty paragraphs (P83–P87) leave five numbered blank lines in the Discussion.
4. **Not raised:** the proteome-wide MR is not mentioned in the Discussion (optional).

## Areas 3 and 4, addendum (R4d verified; some items I checked myself)

1. **MUST FIX: the pLOF neighbouring-gene window in the text doesn't match the code.**
   - P48, P71 and the Supp Fig 3 caption (P123) say "all protein-coding genes within ±150 kb".
   - The RAP pipeline (`NLRP3_project/analysis/NLRP3_UKB_RAP/LOF_analysis/scripts/01_identify_LOF_mutations.Rmd` l95–101) uses ±110 kb, so OR2G2 (inside ±150 kb) was not tested. I checked this myself.
   - This is about which genes were tested, not the pLOF results, so it is not excluded.
   - Fix: "±150 kb" → "±110 kb" in all three places (no extra words).
   - This resolves the earlier "OR2G2 could not be verified" item.
2. **MAJOR: missing outcome instruments are undescribed.**
   - Pericarditis uses 5 of 8 variants, one via an INTERVAL LD proxy (r² 0.98); a second proxy (r² 0.69) was rejected. Knee OA uses 6 of 8.
   - The only proxy rule in the paper (P127) covers instrument construction.
   - Fix: a half-sentence in Methods 3.5/3.11 plus a ST15 footnote.
   - EHJ norm: not a reporting-norm issue (transparency for a headline Abstract result).
3. **Correction to an earlier item: ST07 R12–R13 are not an undescribed analysis.**
   - "excl. 1_247460342_C_G" (IVW 1.23, 1.02–1.48) is the rs188628429 leave-one-out estimate, the same as ST14 R30–R31 and Supp Fig 4.
   - Fix: delete the duplicate ST07 rows, and relabel the ST14 leave-one-out rows by rsID.
4. **MUST FIX: ORA details in P139 and ST13.**
   - ST13 has 10 MSigDB Hallmark rows (background /1,236) that Methods/SI never describe.
   - The GO:BP background is effectively 2,745 annotated proteins, not 2,922.
   - Fix: add "and MSigDB Hallmark gene sets" (or delete those rows). Optionally add "(2,745 with a GO:BP annotation)".
5. **Confirmed:**
   - P81 "almost all" → "most (87%)".
   - SI proxy rule (0.05 r² tie then lowest CRP P; the chosen proxy has r² 0.911, while two variants have 0.92).
   - P138 covariates (age², age²×sex).
   - P31 neutrophil n, attached to the wrong noun (reorder, zero words).
   - P31 assay clause (Said et al. describe immunoturbidimetry only for UKB).
   - ST16 COPD EudraCT label.
   - ST01–ST04: mixed N/A / NA / – missing-value markers; bare DOI strings.
   - Heading case.
   - Gene-italic list: roman only in P45, P71, P89, P90 and P119.
   - P/r² notation; also P77 "P=0.0052" has no spaces.
   - -ise/-ize: also P22 "randomised" and P90 "generalisability".
   - Apostrophes; P142 straight double quotes around "NLRP3".
   - P144 "Phase II" → "phase 2".

## Area 10: Formatting and document integrity (D1 finder; sectPr, hyperlinks, indents and empty paragraphs checked myself in document.xml)

EHJ R16.1 allows a format-free initial submission, but R16.2/R16.10 page and line numbering are used by reviewers, and broken structure is visible to the editor.

1. **Page numbering (MUST FIX).**
   - A section break before the References restarts page numbering at 1, so there are two sets of pages numbered 1–5 (PDF pp. 28–32).
   - Line numbering is also switched off in the References.
   - The main text numbers lines 1–708 continuously; EHJ R16.10 wants them to restart on each page.
   - Fix: replace the section break with a page break, and set line numbers to "Restart Each Page".
2. **Legend order and placement (MUST FIX, EHJ R8.1/R5.1).**
   - Figure legends sit under "12. Figures", interleaved with embedded images, before the References.
   - EHJ puts them after the References under "Figure Legends", with the figures uploaded as separate files.
3. **Supplement inside the main file (MUST FIX, EHJ R5.4).** The supplementary figures and Supplementary Information (P117–P144) are inside the main manuscript.
4. **Alt text missing (MUST FIX, EHJ R8.5).** None of the main-figure legends has alt text.
5. **Title page (MUST FIX, EHJ R2.1/R2.6).** There is no corresponding-author block and no keywords.
6. **Heading styles (MUST FIX).**
   - SI P141–P144 are styled Heading 2, so body text prints as headings and ref 65 prints bold.
   - The Abstract paragraphs are styled "Normal (Web)".
7. **Heading numbering (MUST FIX).**
   - "Supplementary Information" has no number, but its subsections are 14.1–14.4.
   - "References" is unnumbered.
   - Title Case is used in headings 3.8, 3.9, 10, 11 and 13 (see Area 13).
8. **Equation objects for inline statistics (MUST FIX, consistency).**
   - Found in P77 "P=0.0052" (Cambria Math next to Times New Roman), the Fig 4 legend, the Supp Fig 2 legend and P127.
   - Fix: retype as text.
9. **Stale internal hyperlinks (MUST FIX).**
   - Anchors fgps8o4xcr6m (P63), mbyqv5lscmu9 (P71/P72) and l882s0qv1hoh (empty, P144) point to bookmarks that don't exist.
   - The "Supplementary Table" links in P55/P59 cover only the word, not the number, and jump to the in-document supplement.
   - Fix: remove all internal hyperlinks.
10. **Indents (MUST FIX).** First-line indents are 0 / 0.21 / 0.25 / 0.5 inch. P81 and P82 start with a typed tab.
11. **Empty paragraphs (MUST FIX).** P83–P87 give five numbered blank lines in the Discussion. Also P18, P46, P49, P60, P98 and P114.
12. **Figure glitches (MUST FIX).**
    - The Fig 3 legend title's full stop is not bold.
    - The Supp Fig 4 picture floats (square wrap, anchored to the margin); all others are inline.
    - The Supp Fig 3 picture's embedded description is stale.
13. **Main-text layout (not raised separately; mentioned in the compliance section).** Single spacing and justified text; allowed at first submission (R16.1).

## Area 8: Terminology and abbreviations (L1–L6 finders; L1–L5 verified; gene italics re-verified by me against the Emphasis character style)

**Abbreviations (MUST FIX; EHJ R6.1: define at first use in Abstract and in text; R8.2 legends define abbreviations)**
- **GWAS:** used from P29 (also P31, P33 and P35) but defined only in P45.
- **LD:** "LD-clumped" comes before "linkage disequilibrium (LD)" in the same sentence (P37).
- **SNP:** only use is P33 ("SNP–CAD"). It is undefined, and the paper says "variant" everywhere else. Fix: → "variant–CAD".
- **InSIDE (P41):** undefined, single use. Fix: spell out or rephrase.
- **ASC (P20):** undefined, single use.
- **CHARGE (P31):** undefined.
- **eQTL (SI P127):** used before it is spelled out in P133; never defined in the main text.
- **OR / CI:** P41 spells out "odds ratios … 95% confidence intervals" without the abbreviations. The abbreviations are used from the Abstract onward.
- **SD:** undefined in the Fig 2–4 legends and axes.
- **ΔOR (Fig 3E):** undefined.
- **PC1 (Fig 2 legend):** defined wrongly as "principal component". Fix: "first principal component".
- **GlycA:** defined in the Abstract, never expanded in the main text. Expanded two different ways: "glycoprotein acetylation" vs ST01 "Glycoprotein Acetyl concentration".
- **IL1Ra:** defined twice (P37 and P72).
- **PD:** defined in P77, spelled out again in P79, abbreviated in P89.
- **T2D:** spelled out again in P77 (optional).
- **IL-1 / IL-1α:** undefined; "interleukin-1" and "IL-1" both used.
- **TNF (P81):** undefined, single use.
- **Trial acronyms:** CANTOS, LoDoCo2, CLEAR-SYNERGY and ZEUS are unexpanded (pending L6 verdict).
- **Supplementary tables:** no abbreviation key anywhere in ST01–ST16.

**Terminology (MUST FIX, consistency)**
- **Exposure name:**
  - "NLRP3 activity score" dominates.
  - Variants: "genetically proxied NLRP3 activity", "NLRP3 score" (ST06/ST11), and Fig 1/Fig 2 title wording.
  - Fix: pick one.
- **P73 (and Fig 4E legend, Contents B14):** "raised by inhibition" and "downregulated" describe a genetic association as a drug effect. Fix: "higher/lower with lower genetically proxied NLRP3 activity".
- **Biomarker names:**
  - CRP "levels" vs "concentration".
  - "neutrophil levels" in P71 (the trait is a count).
  - GlycA "levels" vs "concentrations".
- **CAD and plaque outcome names:** differ between the text, Fig 3B, ST02 and ST07.
- **IL1Ra vs IL-1Ra:** the paper hyphenates IL-1β, IL-18 and IL-6. "IL1Ra" is used consistently (15×), so this is optional; ST06 gene symbols IL1B/IL18/IL6 is the real mismatch.
- **Figure 1:** "Causal Effects on CAD" conflicts with the association wording.
- **Heading 3.9:** "Predicted Gain-of-Function" (the GoF variant is known, not predicted). Pending check.
- **Genome build and variant IDs:** "hg38" (ST05) vs "GRCh38" (P51); chr_pos IDs in ST07/ST14 vs rsIDs in Supp Fig 4.

**Gene/cis italics (MUST FIX, consistency; EHJ has no rule, A17.17)**
- Dominant form: italic gene symbol.
- Deviations: P45 "cis-acting NLRP3 variants", P71 "driven by NLRP3 itself", P89 "at the NLRP3 locus", P90 "cis-restriction", P119 "±150 kb of NLRP3" and "whole-blood NLRP3 expression", Fig 4A axis "NLRP3 pLOF status", Fig 4B key "NLRP3 GOF carrier", and Supp Fig 3 panel titles.
- "cis" is italic in P27, P72 and Fig 1, but roman in P45 and P90.
- **Refuted:** P37, P75, P79 and P82 are already italic.

## Area 12: Typo pass (L1–L6 and D1; every item verified in the DOCX markup or the PDF)

**Main text and SI**
- P39: "blood neutrophil count , using" → "blood neutrophil count, using"
- P39: "(prior.1 = 1×10⁻⁴, prior.c = 0.02. Evidence" → "… prior.c = 0.02). Evidence"
- P41: double space "MendelianRandomization²⁸  (version" → single space
- P51: "Cosson et al. ³⁹" → "Cosson et al.³⁹" (space before the superscript)
- P51: "Supplementary Information″." → "Supplementary Information."
- P55: "on the 28 of April 2026" → "on 28 April 2026"
- P141: "on the 28th of April 2026" → "on 28 April 2026" (same date written two ways)
- P59: "support coherent NLRP3-linked inflammatory signal" → "support a coherent NLRP3-linked inflammatory signal"
- P71: "pLOF variants in NLRP3 were associated with significantly lower CRP … than non-carriers" → "Carriers of pLOF variants in NLRP3 had significantly lower CRP … than non-carriers"
- P73: "after multiple-testing" → "after multiple-testing correction"
- P73: "higher levels of 7" → "higher levels of seven" (then "the seven proteins")
- P88: "…in the INTERVAL reference panel and was additionally associated" → "…reference panel, and was additionally associated"
- P97: "during the duration of" → "during"
- P50: heading "Predicted Gain-of-Function" → "Gain-of-function" (P51: the variants are known pathogenic variants from INFEVERS)
- P125: leading space in " Supplementary Information"
- P136: "assessment centre" vs "recruitment centre" for the same covariate → one term
- P127: "Components represented in …" → "Merged blocks represented in …" ("Components" is never introduced)
- P144: citation 65 prints bold (Heading 2 style)

**Figures**
- Fig 2A and Supp Fig 2 y-axis: "−log10(P − value)" → "−log10(P)"
- Fig 4E: "Defense Response To Symbiont" etc. → sentence case; "Complement Activation Alternative Pathway" → "Complement activation, alternative pathway"; "Acute Phase Response" → "Acute-phase response"; "Adj. P-value" → "Adjusted P"
- Fig 2C / Fig 3C: "−0.00" CI bounds → "0.00" (or more decimals)

**References**
- Ref 43: "Jansen TLThA" → "Jansen TLTA"
- Ref 13: "Lp-PLA2" → "Lp-PLA₂"
- Refs 16 and 61: "1198-1213", "1415-1429" hyphens → en dashes
- Ref 56: "NPJ Park Dis" → "NPJ Parkinsons Dis"
- Refs 62, 43 and 24: non-MEDLINE journal abbreviations

**Supplementary tables**
- ST03 C12: "International Parkinson Disease Genomics Consortium" → "International Parkinson's Disease Genomics Consortium"
- ST09 A3–A5: "Indirect via Systolic blood pressure / Apolipoprotein B / Type 2 diabetes" → lower case after "via"
- ST04 A11: "Body Mass Index (BMI)" → "Body mass index (BMI)"
- ST04 A2: "Low density" → "Low-density"
- ST01 A4: "Glycoprotein Acetyl concentration" → "Glycoprotein acetylation (GlycA)"
- ST16 COPD: "CTIS 2021-000558-25" → "EudraCT 2021-000558-25"
- ST04 G11: bare "10.5281/zenodo.1251813" in the link column → URL
- ST12 headers: "Protein Id" → "Protein ID"

## Area 13: Consistency pass (dominant form → deviations)

1. **Spelling (EHJ R12.1 Oxford = -ize).**
   - Dominant form in the manuscript: -ise (colocalisation ×6, colocalising ×5, summarised, characterise ×4, prioritised, visualisation ×2, normalisation ×2, maximise ×2, generalisability).
   - Deviations: "randomization" ×13, "authorized" (P100), "Hospitalized" (Fig 5, ST03, ST15), and P22 "randomised … Mendelian randomization" in one sentence.
   - Fix: switch every -ise to -ize (Oxford spelling; keep "analyse", "haematopoiesis", "centre", "colour").
2. **P notation.**
   - Dominant: italic *P*, spaced "=" / "<", Word superscript exponent.
   - Deviations:
     - roman P in P45 "(P > 0.05)", P127 "(P < 1×10⁻³)" ×2 and the P123 "P values"
     - unspaced P37 "(*P*<5×10⁻⁸)" and P77 "P=0.0052"
     - Unicode ⁻⁸ in P37/P127
     - equation objects in P77, P113, P121 and P127
     - "P-value" in P127 vs "P value" elsewhere.
3. **P-value precision.**
   - Dominant: 2 significant figures.
   - Deviations: P59 "1.04×10⁻⁵⁸, 1.34×10⁻⁸⁷, 1.93×10⁻⁴³" (3 significant figures, next to 4.7×10⁻²⁸).
   - Weighted-median P: 0.005 (P65, Fig 3A) vs 0.0047 (Fig 4F, Supp Fig 4).
   - Gout: P 0.0052 (P77) vs 0.005 (Fig 5).
4. **Figure P values:** e-notation ("1e-10", "7e-4") in Figs 2C, 3A–C, 4D–F, 5 and Supp Fig 4, vs "×10⁻ⁿ" in the text.
5. **r².**
   - Dominant: italic *r* with superscript.
   - Deviations: roman r² in P119 and P127; unspaced "r²<0.1" in P119/P121; equation objects in P121/P127; "r2" in ST14 labels. Four encodings in total.
6. **n:** italic spaced "*n* = 4,732" (P59) vs roman unspaced "(n=26,000)" in P33 (×3).
7. **β:** italic dominant; roman in P68 "(β = 0.14".
8. **CI format:** en dash "1.02–1.45" in the Abstract vs "1.02 to 1.45" in the text. EHJ practice uses both; pick one per document.
9. **Direct OR:** 1.026 (0.85 to 1.24) in P68 vs 1.03 (Abstract, Fig 3E).
10. **Minus/negative zero:** "−0.00" in Figs 2C/3C.
11. **Gene italics:** see Area 8 (P45, P71, P89, P119 ×2, Fig 4A/4B labels, Supp Fig 3 titles). "cis" is roman in P45 and P90.
12. **IL naming:** IL-1β / IL-18 / IL-6 in the text vs IL1B / IL18 / IL6 in ST06. Also "interleukin-1" vs "IL-1".
13. **Apostrophes and quotes:**
    - Curly dominant (P13, P62, P63, P65, P77, P79, P107).
    - Straight in P41 "Cochran's", P93 "Health's", P102 "participants'", P116 and Fig 5 "Parkinson's", P127 "gene's", and P142 "NLRP3" (double quotes).
14. **Serial comma.**
    - Dominant: serial comma (P13, P43, P79 IL list, P89, P107).
    - Missing in P63 "IL-18 (…) and IL-6", P79 "gout, pericarditis and Parkinson's disease", P80 "IL-1β, IL-18 and IL-6", P93 "SCAPIS and deCODE genetics", P141.
15. **Trial phase:** "phase 3" / "phase 2a" (P19, P21, P82) vs "Phase II" (P144). ST16's "Phase 2" registry category may stay.
16. **Numbers 1–10 in words (EHJ R11.26):** "7" in P73.
17. **Hyphenation.**
    - Dominant: hyphenated compound modifiers.
    - Deviations: "whole exome sequencing" (P48) vs "whole-genome sequences" (P37/P39); "European ancestry individuals" (35 ST cells) vs "European-ancestry" (text); "per one unit" (figure axes) vs "per one-unit" (captions); "weighted-median" (Fig 4 legend) vs "weighted median"; "Low density" (ST04).
18. **Capitalisation.**
    - "Weighted Median" in the figure legends of Figs 2C, 3A–C, 4F, 5 and Supp Fig 4 vs "weighted median" in the text.
    - "Neutrophil Count" (Supp Fig 1).
    - GO terms in Title Case (Fig 4E).
    - ST12 headers in title case vs sentence case elsewhere.
19. **Headings.**
    - Dominant: sentence case.
    - Deviations: 3.8 "Predicted Loss-of-Function Analysis", 3.9 "Predicted Gain-of-Function Analysis", 10 "Ethical Approval", 11 "Pre-registered Clinical Trial Number", 13 "Supplementary Data".
20. **Date format:** "28 of April 2026" (P55) vs "28th of April 2026" (P141).
21. **Supplementary Table labels:** "Supplementary Table 1" (text) vs sheet tabs and Contents "ST01".
22. **Variant IDs:** rsIDs (text, Supp Fig 4) vs chr_pos (ST07 R12–R13, ST14 A16–A31).
23. **Genome build:** "GRCh38" (P51) vs "hg38" (ST05).
24. **Missing-value markers:** NA / N/A / – across ST01–ST05.
25. **"et al." italics:** "*et al*." (P51, P88 first) vs "*et al.*" (P88 later).
26. **Figure labels vs text:**
    - Fig 4C "IL1RN expr.", "CRP conc." vs "expression" / "concentration".
    - Supp Fig 4 "w/o rs…" vs ST14 "excluding".
    - Figure 1 "CRP levels" vs Figure 2 "CRP concentration".
27. **Indents and empty paragraphs:** see Area 10.

## Area 8/12/13, corrections from the last verifiers (L5, L6, D1)

**Dropped:**
- **P125 "leading space":** the XML shows only a page break (`w:br type="page"`) before the heading text. Not a typo.
- **P79 "ApoB is not a lipid":** downgraded to MINOR, because the paper groups ApoB under "Lipids" (Fig 3C). Dropped.
- **TNF undefined (P81):** MINOR, a standard abbreviation. Dropped.
- **Stale internal hyperlinks (D1-9):** MINOR, invisible in print. Dropped.
- **Fig 3 legend full stop not bold, Supp Fig 4 floating picture, stale Supp Fig 3 embedded description (D1-14):** MINOR. Dropped.
- **Abstract "Normal (Web)" style:** invisible. Dropped.

**Trial acronyms:**
- CANTOS is used 4× unexpanded and must be expanded at first use (R6.1).
- LoDoCo2, CLEAR-SYNERGY and ZEUS: expand them, or accept them as trial names. Keep the names; don't delete them.

**Exposure name (L4-1):**
- Fig 1 legend uses two names in one sentence.
- Fig 2 title: "genetic score for NLRP3 activity".
- ST06: "cis-NLRP3 activity score (lower)".
- ST11: "cis-IL1RN / IL1Ra activity score".
- Word order: "genetically proxied lower" in P16/P79.
- "reduced" in P79.
- Heading 4.6: "inhibitors" vs "inhibition" in heading 3.11 and the Fig 5 title.

**Workbook labels (L5-6):** the workbook labels tables ST01–ST16 while the text cites "Supplementary Table N". MUST FIX (consistency).

**Precision:** gout *P* is 0.0052 in P77 but 0.005 in Fig 5 (L5-2).

## Area 14: Final reviewer-style pass (two lenses; editor-clinician done and verified; I checked both confirmed items myself)

1. **MAJOR: colchicine is framed selectively (P19, P80). CONFIRMED.**
   - "Colchicine" appears only in P19. COLCOT appears nowhere in the text, SI or tables.
   - P19 pairs LoDoCo2 (benefit) with CLEAR-SYNERGY (no benefit, acute MI) to argue that benefit depends on context. It omits COLCOT (benefit after MI), which ref 4 calls "the previous trial most comparable".
   - Ref 53 (Schunk) says that modulating NLRP3 is one mechanism of colchicine. The Discussion never reconciles "lower NLRP3 → higher CAD" with colchicine.
   - Fix:
     - P19: "with benefit in COLCOT and LoDoCo2 but not in CLEAR-SYNERGY" (+ Tardif, NEJM 2019).
     - P80: add one sentence (~35 words).
   - EHJ norm: not a reporting-norm issue; this is a likely cardiologist-reviewer question.
2. **MAJOR: the T2D direction is not discussed (P89, P81). CONFIRMED.**
   - T2D (OR 1.26, P 0.002) is a mediator and the only trial indication where the genetics points against benefit. Dapansutrile has a phase 2 T2D trial with an HbA1c primary endpoint (NCT06047262; ST16).
   - P81 supports the direction only with IL-18-knockout mice. It omits that NLRP3 deficiency protects against obesity-induced insulin resistance (Vandanmagsar 2011), and that ref 48 found no genetic IL-1–T2D association.
   - Fix: one sentence in P89, offset by cutting P89's last sentence.
   - EHJ norm: not a reporting-norm issue.
3. **Refuted: a clinical translation of "per one unit" compared with canakinumab.**
   - It is a presentation preference.
   - The comparison sets a lifelong genetic effect against a short drug effect.
   - The P90 caveat is standard. Dropped.

## Area 14: MR-statistics lens (verified after the session-limit resume)

1. **MAJOR, merged with the editor-clinician T2D item: the T2D finding gets one-sided support (P81, P89). CONFIRMED.**
   - T2D carries 22.7% of the mediated effect (ST09 R5).
   - P81's only support is Netea 2006 (ref 49). Its abstract says insulin resistance was "secondary to obesity induced by increased food intake". I checked this in the local PDF.
   - The score is null for BMI (ST08 R20: β −0.029, P 0.41) and for obesity (OR 0.92, P 0.47).
   - Not cited: Vandanmagsar 2011 (NLRP3-deficient mice protected from diet-induced insulin resistance) and Everett 2018 (canakinumab did not reduce incident diabetes in CANTOS).
   - **Verifier caveats:**
     - Schunk 2021 is mixed. I checked it: higher diabetes prevalence in UK Biobank G-allele carriers, but a LURIC trend towards lower prevalence. So it is not cited as contrary evidence.
     - Ref 49 also reports a hepatic mechanism, so the finding is phrased as "mainly secondary to obesity".
     - Don't call T2D "pleiotropy"; that goes beyond the evidence.
   - **Fix:** replace the P81 IL-18 sentence with an "unexpected" sentence citing Vandanmagsar and Everett plus the BMI null. Add a dapansutrile sentence to P89 and cut P89's last sentence.
2. **Refuted: "validated against IL-1β" is borderline** (IVW P 0.046; weighted median P 0.079). IL-18 and IL-6 are robust, P63 reports the IL-1β CI in full, and "validated" vs "tested" is a wording preference. Dropped.

## Final report quality check (workflow `wf_f178974f-1b3`, five checkers: scope/format, facts ×2, wording, coverage)

The checkers raised 111 points. I checked them at source; all were accepted except where noted below. The corrections now in the report:

**Scope:**
- Removed word counts from proposed edits (an excluded topic).
- Removed the "(proteome)" qualifier on multiple testing (indirectly about exploratory indications).
- Removed "keywords 24/24" and "sex 5/22" from the report: neither count is in the benchmark file.

**Benchmark wording:**
- Counts now read "X of Y applicable EHJ MR papers".
- LD-matrix row: 9/16 cis papers (drug-target 5/7).
- Sample overlap: "Partly (SCAPIS, mediators); not exposure–CAD".
- Coverage: 51 read in full (33 core + 7 minor + 11 no MR), 1 read in part and not counted.

**Rule IDs:**
- SGA Take-home is R4.2, not R4.1.
- SAGER: R2.5 (abstract) plus R15.6–R15.8 (Methods, with rationale). The location now includes the Abstract.
- Software refs: R10.10. Reference style binds at revision (R10.15).
- Page numbering is R16.2 (now). Line-number restart and References line numbers are R16.7 (at revision).
- Figure text size: R7.17/R7.22, not R7.12 (which is line art only). Vector is "best", R7.14.
- The declaration-heading case item was dropped from compliance: R14.4 is about the form, and published EHJ uses Title Case. It is kept as an internal-consistency item.

**Facts corrected:**
- The flank-colocalisation citation to Supp Fig 2 is in P59 (P39 only describes the method).
- Proportional ORs appear in P66 and the Fig 3 legend; only the Methods omit them.
- rs6689545 is named in Methods P39. It is missing only from P59 and the caption.
- PCA: the per-variant score effects change <0.1%. The loadings change up to 0.38%.
- The drug-effect wording is in P73 only. The Fig 4E legend and Contents B14 were wrongly listed.
- The r² sweep gives P ≤ 0.032 (the primary r² < 0.1 is 0.032).
- T2D is 22.7% of the total CAD association (26% of the mediated effect).
- Gao simpleM: cite Gao and state "95% rather than the default 99.5%", in P138.
- E-notation figures: 2C, 3C, 4D–F and Supp Fig 4 (not 3A, 3B or 5).
- "interleukin-1" in P43/P72 vs "IL-1" in P81/P89.
- "et al." dominant form is "*et al.*" (P88 second use, P111, P136).
- Biomarkers: "CRP levels" is the majority text form, and the "GlycA levels" deviations are listed.
- r²: target is Word superscript (P62, P74). Unicode ² appears in P37, P41, P45, P88, P119 and P127; roman r also in Fig 4F.
- Spelling counts are corrected to exclude references. Added "recognised" (P19) and "prioritising" (P127); "randomization" ×6 in the text.
- ST02 uses "-" (plus one "NA").
- Supp Fig 2 thinning affects only grey (no-LD) non-significant points.
- The Supp Fig 2 gene track is also roman.
- Serial comma is also missing in P141.
- Indent lists completed (P133, P134, P139, P142–P144; none in P141).
- 1-significant-figure P values listed (P68, P72).

**Wording of the proposed fixes:**
- Removed "colocalizing variant" for rs12239046.
- P23 text: italic *NLRP3* expression; "an NLRP3 activity score"; "have been or are being evaluated"; citation shown as [ref]. I also changed "the largest study" to "a study" because it can't be verified.
- P19: keeps the populations and the citations.
- P80: the colchicine sentence is now cited.
- ZEUS: define hsCRP, and keep "interleukin-6 (IL-6) inhibition".
- P31: keeps the measurement clause.
- PCA fix also edits P37/P128.
- Flank result: add to P59 or the Supp Fig 2 caption, not ST14.
- Q columns: ST06–ST09, ST11 and ST14. MR-Egger intercept columns go in ST08, plus a footnote on the IL1Ra Q. The "or delete" option was removed, because P90 depends on Q.
- P41 scale wording is spelled out.
- Outcome proxies: only one pericarditis proxy. The pericarditis SEs were derived from OR/P (deCODE has no SE).
- P73 shortened ("the 27 proteins with lower levels").
- P77: MI clause merged with the ST16 citation.
- P79: replace its last sentence and delete P81's last sentence (no duplicate).
- P89: T2D sentence without "By contrast". The last sentence is shortened, not deleted.
- P90: serial comma, italic *P*, "Tables 8 and 14".
- Overlap sentence: "would act against our finding".
- SI P144 grammar fixed.
- Fig 2B units: no ST05 unit column exists.
- Typos: P50 heading case; P71 wording; P127 "block" in both sentences.
- SGA drafts: word order, CAD defined, ApoB expanded, serial comma.
- AI template names Claude Opus 5 and Claude Sonnet 5 (git: 10 and 6 commits) and asks the authors to confirm.

**Coverage restored:**
- SI P144 is MAJOR (the only rationale for including RA).
- ST02 All of Us DOI.
- Ref 5 has no volume or DOI. I didn't insert the checker's suggested DOI because it is unverified.
- "[dataset]" entries for already-cited datasets.
- OR and CI undefined in the main text.
- Disclosure item added to the compliance section.
- Outcome-name item (ST07 "Coronary artery disease"; axis titles).
- "References" heading unnumbered.
- Supp Fig 2 LD key about 4.7 pt.
- P37 cross-reference to the positive-control sources.
- Fig 1 raster moved to an upload note: embedding is allowed at first submission (R16.2).

**Order:**
- SI P144 moved to the SI section.
- The assay-selection item now comes before P45; T2D before P82.
- Duplicates across sections removed ("7", Fig 4E case, equation objects, Fig 4C labels, gout P, Fig 5 counts).

**Not accepted:**
- Adding the Abstract's empty paragraphs P5, P8, P11 and P14 to the empty-paragraph list. They are regular spacing between Abstract headings, not deviations.

## Combined report with codex (24 Sep 2026): `manuscript_review_final_combined_v2.md`

The user asked for the two reports to be merged, so I read codex's final report and evidence files for the first time.

**Built on the verified Claude report.** Items both reviews found are marked "(both)".

**Codex-only items re-verified** (workflow `wf_4566daaf-d84`) and merged:
- ref 9 "Ho Park K" → "Park KH"
- ref 59 → Gigascience
- FCAS (ST16!A9)
- pLOF defined twice in the Supp Fig 3 legend
- gene italics in the tables
- table-header case
- 2-dp OR precision in P68
- Fig 2A/Supp Fig 2 LD reference (rs12239046) and dashed line
- Fig 4E test description, and n pointers (including Fig 4B)
- accessibility (colour-only estimator cue; contrast), R7.15
- Supp Fig 1 and 4 embedded as 300-ppi rasters (vectors exist)
- lowercase "p" in Fig 4A and Supp Fig 3.

**Codex items dropped:**
- IL-6 sign: `w:noBreakHyphen` precedes 0.72 in the DOCX, so it displays as a minus.
- PDF page 14: normal pagination.
- Abbreviations defined but not reused: EHJ requires only definition at first use.
- Supplementary-table centring: R9.4 covers main-text tables.
- Ref 21 DOI: required for preprints.
- Fig 3E axis/whisker item: user decision, omitted.

**Coverage and dedup check** (`wf_570aeaee-347`) corrected the following:
- ST07 R14 holds the CAD Egger intercept cited in P65, so the fix moves it instead of deleting the row. Also fixed in the Claude report.
- The Fig 4E background is 2,745 GO-annotated proteins.
- The P41 sentence now also defines OR and CI.
- Ref 24 no longer gets both a replacement and an abbreviation fix.
- The caption does not name rs58546652.
- ΔOR rounding note added.
- Label, both-mark and cell-reference fixes.
- Codex's "waived at format-free submission" view is noted for legend order, numbers and figure files.
- The benchmark table now has both columns.

## Combined report, second revision (24 Sep 2026)

**Line numbers.** All paragraph references were replaced with printed PDF line numbers (1–708).
- A script mapped paragraphs to lines first. Six agents then refined each reference to the exact line (workflow `wf_f3b8ec63-986`).
- A mechanical diff confirmed that only location references changed.

**EHJ practice check** (workflow `wf_be367e42-f12`, Sonnet agents over the 38–50 benchmark full texts; key counts re-checked by me). Changes:
- **Abstract Conclusions:** no semicolon (0 of 37 use one) and no "trials should" (0 of 37). Now uses "These findings … highlight the need to monitor …".
- **SGA Take-home:** same change.
- **Keywords:** separated by commas (37 of 37).
- **P23:** colon replaced by a full stop.
- **Other proposed sentences:** semicolons split into plain sentences.
- **CI format flipped** to an en dash for positive bounds (229 CIs in 19 papers vs "to" 3 in 2); "to" kept only for negative bounds.
- **Supplementary labels flipped** to "Supplementary data online, Table S1" (37 of 38 papers; "Supplementary Table N" 0).
- **P-value flipped** to hyphenated (27 vs 6 papers).
- **P59 precision item dropped:** 3 significant figures is common for exponent P values.
- **Trial-acronym expansion dropped:** CANTOS is never expanded in EHJ.
- **Disclosure closing sentence:** "All other authors declare no disclosure of interest for this contribution."
- **Code:** stays in Data availability as a GitHub URL; the Zenodo DOI is no longer asked for.
- **"[dataset]" entries dropped:** 0 of 38 papers use them. The 11 missing source papers are still to be cited.
- **Preprint:** either "[Preprint]" (instructions) or "preprint: not peer reviewed" (practice).
- **New:** IL1Ra → IL-1Ra, by analogy with IL-1β and ref 48.
- **EHJ counts added** to the consistency items.
- **House-style note added** (no leading zero; thin-space thousands separators; applied at copy-editing).

## Combined report, third revision: remaining rephrasings checked against EHJ (24 Sep 2026, done solo, no workflow)

Every proposed wording not covered by `wf_be367e42-f12` was checked against the benchmark texts. This covered 336 figure captions from 37 papers, plus headings and word-order/terminology counts. Changes:

- **Headings (direction flipped):**
  - EHJ never numbers headings: 0 of 2,249. So drop the heading numbers (this also resolves the SI/References numbering mismatch).
  - EHJ prints declaration headings in Title Case ("Disclosure of Interest" 19 vs 1, "Data Availability" 48 vs 8, "Ethical Approval" 20 vs 1). So change lines 494 and 498 to Title Case and keep 504 and 515.
  - Body headings stay sentence case, including "Supplementary data" (21 vs 1).
- **P35:** removed "(Section 3.7)"; EHJ has 0 numbered-section cross-references.
- **Figure legends:**
  - Fig 2A uses "colour coded by pairwise r² with …" (PMC12461605) and "The dashed line represents the threshold for genome-wide significance" (PMC10148738).
  - CI bars: "Lines represent 95% confidence intervals".
  - Fig 3: "Points represent … and lines represent 95% confidence intervals" (PMC10148738).
  - Fig 5 arrowheads and the Supp Fig 2 thinning now have explicit sentences.
  - The legend-definitions item cites "CI, confidence interval" in 21 of 37 papers.
- **Typo P73:** "after correction for multiple testing"; EHJ has "after correction for multiple comparisons" and never "multiple-testing correction".
- **Abbreviations:**
  - InSIDE spelled out as in PMC10849320.
  - ASC spelled out as in the closest EHJ NLRP3 paper, PMC8244638.
- **"European ancestry":** no clear EHJ preference ("of European ancestry" 15 papers; unhyphenated modifier in 3 vs hyphenated in 2). Recommend changing the 13 hyphenated text uses to match the tables.
- **"Supplementary Information" in the text** (lines 226, 235–236, 245, 250) → "(see Supplementary data online, Methods)". EHJ uses this in 14 papers and never "Supplementary Information".
- **Evidence notes added:**
  - exposure word order: direction word first, 6 vs 3 papers
  - biomarkers: EHJ uses both "levels" and "concentration"; "neutrophil count(s)" 111 vs 2
  - "et al.": 41 vs 35, no preference.

**Follow-up from a concurrent session with the user** (memories `ref24-delta-method-keep`, `zeus-reference-status`):
- Removed the "ref 24 misattributed" item. Rietveld 2023 derives the delta-method SEs in S1 Text C.4; Carter 2021 only mentions the method. It is now listed under "Checked and dropped".
- The ZEUS item now recommends replacing the ref 5 commentary with the Novo Nordisk announcement No 45/2026 plus the Ridker JAMA Cardiol 2026 design paper, until the primary report (AHA LBS, 7 Nov 2026).

## Co-author comments on the first draft (added 24 Sep 2026)

**Inputs** (uploaded by the user): `NLRP3_manuscript_google_version_210826_plus_mails.docx`, `NLRP3_manuscript_SB.docx` and `NLRP3_manuscript_ziad.docx`.
- Extracted with `trashtmp/claude_review_v3/coauthors/extract.py`: comments with anchors, replies and tracked changes.
- All unique comments are in `coauthors/all_comments.txt` (128 unique, 100 by co-authors):

| Co-author | Comments |
|---|---|
| Paul Carter | 22 |
| James Peters | 18 |
| Stephen Burgess | 16 |
| Murray Clarke | 13 |
| Dirk Paul | 12 |
| Ziad Mallat | 10 |
| Liam | 9 |

**Result**, now the last section of the combined report:

| Status | Count |
|---|---|
| Addressed | 45 |
| Partly addressed | 17 |
| Open | 25 |
| Superseded | 4 |
| Approvals or offers | 4 |
| Not re-assessed (mediator units, a user decision) | 2 |
| Preferences not adopted | 2 |
| Not valid | 1 |

**Checks done at source:**
- **Expression-only weighting vs score** (James Peters #235): r = 0.99 across the 8 variants. The CAD z-scores were 4.07 vs 4.06 in a simplified fixed-effect check on the per-SNP meta-analysis (results/05).
- **TNF in the proteome MR** (Murray Clarke #267): β −0.21, P = 0.089, vs IL-6 −0.72, P = 2.8e-9.
- **Proteome hits:** none of the 34 is encoded near NLRP3 (Liam #261).
- **MR scatter plots:** 7 of 38 EHJ MR texts show one.
- **References verified via PubMed E-utilities:** Menu 2011 (Cell Death Dis 2:e137), Alexander 2012 (JCI 122:70–9), Gomez 2018 (Nat Med 24:1418–29) and Chen 2020 (JACC BTS 5:582–98).
- **EHJ colchicine meta-analysis:** Samuel et al. 2025 (EHJ 46:2552–63, doi 10.1093/eurheartj/ehaf174) found via WebSearch/OUP.
- **Luo et al. EHJ 2023** (neutrophil MR) is in the benchmark corpus.
