# Manuscript pre-submission audit — working log (Codex v2)

Started 22 September 2026. Independent sequential review of the supplied PDF, DOCX, supplementary workbook, original code, analysis outputs, and primary references. Other review reports are not evidence and are not read. Source files are read-only. Scope follows the user’s explicit instructions.

## Input record

- `NLRP3_manuscript_WIP.pdf`: SHA256 `cefa1f813dc92aac589de686dc83f0259c8ac3f55227cc4e79d1e0d2606ef117`
- `NLRP3_manuscript_WIP.docx`: SHA256 `d55e832c07de26db600b2c6687a5fddfe8f5ec82a45e216d100575b25eb44b7d`
- `SuppTables_completed_DRAFT.xlsx`: SHA256 `6c412fccd9bb79d7194d47bd4bbc232da58df12488923975bf7d0c501e8f51b5`

Temporary audit extractions: `/rds/user/nh608/hpc-work/trashtmp/manuscript_codex_v2_20260922`.

## Audit progress

Initial extraction completed. Paragraph identifiers below refer to top-level DOCX paragraphs, including blank paragraphs in the numbering. All review areas are complete. Final retained findings and decisions are recorded in section 7.

## 1. References and citation support — completed

Checked all 65 bibliography entries and embedded citation records. Local PDF collection was searched first; 123 PDFs were extracted to the audit temporary directory. Missing papers and publication-version differences were checked using publisher-deposited Crossref records, original journal pages, PubMed article records, and official software documentation. The per-reference source ledger is `reference_verification.json` in the temporary directory. No fabricated reference, broken citation-to-bibliography mapping, or major bibliographic corruption was identified.

Key claim checks:
- CANTOS, CLEAR-SYNERGY, IL1RN genetic evidence, IL-18 metabolic effects, NLRP3 blood-pressure experiments, Schunk et al., imaging phenotype definitions, and recurrent-pericarditis evidence were checked against local papers. Their main cited claims are supported.
- The local Yao 2026 paper explicitly describes neutral ZEUS results. The sponsor's original 31 July 2026 announcement independently confirms HR 0.99 (95% CI 0.88–1.11): https://www.novonordisk.com/news-and-media/news-and-ir-materials/news-details.html?id=916587. This is not an outdated or unsupported trial claim.
- Reference 7 supports IL-18-induced IL-6 in the experimental system studied (https://pubmed.ncbi.nlm.nih.gov/15161979/). Reference 9 supports NLRP3-dependent post-MI granulopoiesis (https://pubmed.ncbi.nlm.nih.gov/34788059/).
- The published 2025 Tokolyi paper and 2024 Senkevich paper match the manuscript references; the local collection contains their earlier preprints. This version difference is resolved and is not a finding.
- P086 correctly calls the CANTOS TET2 analysis exploratory. The source's treatment-interaction P value is 0.14, so it supports a subgroup hypothesis, not a proven differential response. In this context this does not warrant a separate major finding.
- General methods references were checked for relevance, including multivariable MR and multiple-mediator analysis. Mathematical implementation is assessed separately below.

**Reportable major citation findings:** none at this stage. No important citation identity remains unresolved.

## 2. Methods versus code — completed

Read the analysis scripts for selection, colocalisation, instrument strength, biomarker and CAD MR, cardiometabolic MR, mediator construction, MVMR, positive control, proteome analysis, enrichment, sensitivity analyses and exploratory indications; checked shared harmonisation and LD functions and the data-source registry. The supplementary equations were read from Word equation XML, not inferred from plain-text extraction.

Verified implementation:
- NLRP3 selection uses ±150 kb, within-trait clumping at r²=0.1 over 250 kb, high-LD blocks at 0.95 over 40 kb, cross-trait component merging, availability-first representatives and proxy replacement. Eight final SNPs have maximum pairwise r²=0.06108 in the saved signed LD matrix.
- PCA uses centred/scaled columns to derive weights, then applies those weights to the original trait effect estimates as specified by the supplementary formula. The main text's compressed selection description is clarified in the supplement.
- Colocalisation conditions the upstream expression signal and uses four inflammatory/expression traits, with the stated priors and posterior threshold. It does not include CAD or the cardiometabolic outcomes; implications are evaluated in the scientific pass.
- MR uses signed LD, harmonised effect alleles, log-odds conversion where necessary, and random-effects IVW. Outcome-specific instrument availability and pericarditis proxy use are retained in the outputs.
- Mediation uses genome-wide instruments clumped within and across traits, a mutually adjusted regression without an intercept, and multiplicative random effects. The actual final model has 1,265 instruments. Four CAD studies contribute at 1,240 variants; three contribute at 20 and two at 5. The All of Us extract contains mediator instruments as well as the NLRP3 region. The potential concern that All of Us was absent from mediation is resolved.
- The effective-protein-test script records 1,821 tests from 95% variance explained. Underlying individual-level correlation data are not included; the calculation cannot be independently reproduced from this repository. The arithmetic of its threshold is checkable and is evaluated below.

Additional implementation observations not currently retained as final findings:
- For six proteins assayed on four panels each, the code selects the smallest IVW P value (`04_mr_biomarkers.R`, lines 152–158; `09_proteome_mr.R`, lines 277–284). This rule is omitted from the Methods. All four IL-6 assays independently pass the stated proteome threshold, and none of the other repeated proteins passes it, so this does not change the reported discovery set. The selected IL-6 assay and estimate must still match the reported results.
- Proteome metadata contain an old all-ancestry comment, but the configured directory is `Combined_European` and recorded sample sizes agree with the European release. Do not infer a manuscript ancestry error from that stale comment.

**Reportable major methods/code discrepancies:** none confirmed in this pass. Statistical interpretation and numerical reproduction follow.

## 3. Numerical results against code and outputs — completed, figure rendering checked separately

Independently reconstructed the PCA score, its scaling constant, joint F statistic, LD-aware IVW matrix estimator, SNP-level CAD meta-analysis, MVMR coefficients, conditional F statistics and mediation point estimates. The independent GLS implementation reproduced 2,969 IVW fits (including all 2,940 protein assays) to floating-point precision: maximum absolute discrepancies in estimates, standard errors and P values were 1.12e-15, 2.23e-16 and 6.67e-16 respectively. Evidence: temporary `recompute_results.R`, `recompute_results.log` and `numerical_recomputation.tsv`.

Verified quantities include PC1 variance explained 96.76758%, joint F=92.0066, CAD OR=1.21271, conditional F statistics 36.67343/15.39224/37.24040, summed indirect log-OR=0.1674491, fraction=0.8682394 and remaining OR=1.025737. The manuscript's rounding is consistent. The CAD Egger intercept is 0.008907893 (SE 0.003754381, P=0.01766022), also consistent with the Results. The reported regional association peaks and posterior probability were verified from the saved regional data and a fresh HyPrColoc fit (PP=0.9671).

Regenerated the supplementary workbook into the temporary audit directory using the original build script, then compared the supplied workbook with that reconstruction for ST05–ST09 and ST11–ST15. All dimensions, labels and numerical values in those sheets match, including 43,830 numerical cells in ST12. This is supplemented by the independent calculations above, so it does not rely solely on the build script agreeing with itself. Proteome counts are 27 lower and 7 higher at 0.05/1,821; the named enriched pathways and contributing amino-acid enzymes match the enrichment output.

**Verified reportable finding N1 — IL-6 effect has the wrong sign.** DOCX Results P065 (section 4.2, second paragraph) prints “IL-6 (β = 0.72; 95% CI −0.95 to −0.48; P = 2.8×10⁻⁹)”. The selected assay output is β=−0.7167893772, SE=0.1206044948, P=2.7933086e-9; ST06 is correctly negative. The point estimate printed in the text is outside its own confidence interval and reverses the effect direction. The supplied PDF page 8 already prints the correct β=−0.72. Correct the DOCX and regenerate the submission PDF from the corrected source. The original file hashes are unchanged; this is a difference between the supplied formats, not a change during the audit.

Resolved checks:
- HyPrColoc nominates rs58546652, whereas the single-variant sensitivity analysis uses rs12239046. A fresh calculation from the actual reference panel gives r²=0.9821999 between them. This is a strong proxy for the same signal, so the label does not warrant a major finding.
- The Discussion's maximum r²=0.26 between rs10754555 and the eight instruments is reproduced (0.2566831).
- Source-count checks were completed in the table pass (section 5); the temporary API rate limit was resolved.

## 4. Scientific and statistical interpretation — completed

Reviewed the full causal argument, instrument biology, selection strategy, sensitivity analyses, two-step mediation, multiple testing, interpretation of binary outcomes, and clinical extrapolation against the manuscript's cited methods papers. The independent numerical checks do not identify an algebraic error in the main MR or mediator model. Mutually adjusted mediator-to-CAD coefficients are used when the indirect effects are summed. The exploratory disease analysis is explicitly labelled exploratory and its lack of multiplicity adjustment is disclosed; this is not by itself a separate finding. The Discussion appropriately distinguishes lifelong genetic perturbation from treatment, general-population incidence from secondary prevention, and lack of clear evidence from proof of no effect.

**Verified concern S1 — the claim of a single regional shared signal goes beyond the analysis performed.** Results P062 says there were no additional colocalising signals within ±1 Mb and that the biomarker associations therefore arise from a single shared signal. The actual HyPrColoc input spans ±200 kb (`config.R`, lines 45–55; `analysis/01_colocalisation.R`, lines 98–126). Supplementary Figure 2 is a ±1 Mb association plot; its script performs no colocalisation, secondary-signal conditioning or exhaustive signal search. HyPrColoc partitions traits into clusters and does not establish absence of additional signals once it finds a shared dominant signal. The eight retained variants are also not all explained by the dominant variant: as a diagnostic only, approximate conditional z-tests using the saved reference LD retain genome-wide significant CRP associations for six of the seven other variants after conditioning on rs12239046 (smallest P about 3e-20). This diagnostic is not a substitute for formal fine-mapping, but makes the exclusivity statement particularly unsafe. The PP=0.9671 supports a shared signal; it does not demonstrate that it is the only one across ±1 Mb. Action: either document an appropriate search/conditional analysis or remove the unsupported exclusivity claim. Evidence: `signal_structure.tsv` and the original scripts; Foley et al. 2021, DOI 10.1038/s41467-020-20885-8.

**Interpretation concern S2 — reviewed and not retained as a separate final finding.** Colocalisation covers expression and inflammatory biomarkers, not CAD or the proposed mediators. The non-zero Egger intercept and possible horizontal cardiometabolic effects warrant care, but the Discussion explicitly acknowledges this ambiguity. The shared-signal proxy gives CAD OR=1.047 (95% CI 0.889–1.233; P=0.583), which is compatible with the main estimate; its lack of significance does not itself invalidate the result. Similarly, the remaining CAD effect is the net of all unmodelled pathways and does not isolate inflammation. However, the manuscript's statement that the data provide no genetic support for protection is not a claim to have proved the absence of protection, and it explicitly acknowledges a compatible modest benefit or harm. These points do not provide a sufficiently definite additional error to justify a separate must-fix item under the user's selective reporting threshold. Methodological context: Gill et al. 2024, https://link.springer.com/article/10.1186/s12916-024-03700-9, and Burgess et al. 2023 (local PDF).

## 5. Figures, tables, captions and cross-references — completed

Rendered the supplied PDF and inspected Figures 1–5, all four supplementary figures and their captions. Checked the displayed MR estimates against the corresponding tables and outputs. Checked all manuscript figure/table callouts, workbook Contents mappings and supplementary sheet numbering. No missing figure, wrong numbering, switched panel, broken equation in a caption, or major cross-reference error was found. The UpSet plot's ten eligible components versus eight final instruments is explained by data availability in the supplementary Methods. The single-variant and leave-one-out forest plots agree with their numerical outputs.

**Verified reportable finding F1 — Figure 3E clips error bars at the null.** The waterfall x-axis starts at OR=1, and the plotting code explicitly replaces each lower endpoint with `max(or_lower, 1.0)` (`figures/fig03e_mediation_waterfall.py`, around lines 92–116). The three adjusted lower bounds are 0.936, 0.880 and 0.852, so none is actually drawn. This makes the plot visually show only the side above the null, despite the correctly printed numerical interval on the final row. Extend the axis below the smallest lower bound and draw the complete intervals. This is a plotting problem, not a calculation problem.

**Verified reportable finding F2 — smoking and alcohol sample sizes describe a larger release than the one analysed.** Figure 3C and ST04 give smoking 557,337 cases/674,754 controls (total 1,232,091) and alcohol n=941,280. The actual local GWAS files used by the code have N=632,802 for smoking and N=535,425 for alcohol at every one of the eight instruments. These are substantial differences, not variant-level rounding. The full-study GWAS Catalog metadata reproduce the larger manuscript numbers, but the analysed public releases exclude the restricted component. Correct Figure 3C and ST04 to the actual analysed release; use its source-specific case/control split only if available. Evidence: `release_sample_sizes.json`, source files `datasets/smoking_initiation_GCST007474.NLRP3region.tsv.gz` and `datasets/alcohol_consumption_GCST007461.NLRP3region.tsv.gz`. The original GSCAN publication and consortium page distinguish publicly available summary statistics from restricted data: https://genome.psych.umn.edu/research/gscan and https://doi.org/10.1038/s41588-018-0307-5.

**Verified reportable finding F3 — Parkinson's proxy cases are labelled as diagnosed cases.** ST03 and Figure 5 report 33,674 Parkinson's cases. The primary record for the exact analysed accession, GCST009325, specifies **15,056 cases plus 18,618 proxy cases**, with 449,056 controls; the phenotype includes having a first-degree relative with Parkinson's disease. Thus more than half the reported “cases” are proxy cases. Correct the sample description and Figure 5 label/caption and make the outcome definition explicit in Methods/ST03. This does not establish that the effect estimate is wrong; it corrects what outcome population was analysed. Source: https://www.ebi.ac.uk/gwas/rest/api/studies/GCST009325, saved as `source_GCST009325.json`; original study https://pubmed.ncbi.nlm.nih.gov/31701892/.

Additional checks:
- Completed source metadata checks for all 29 unique GWAS Catalog accessions considered in ST01–ST04. Aside from the release/sample-description findings above, no major discrepancy was identified. BMI varies by SNP as expected and does not warrant a separate finding.
- The checked supplementary worksheets contain no Excel error cells, broken formulas, hidden results sheets or missing header mappings. Download URLs are plain text, which does not itself constitute broken citation support.
- All 38 distinct ClinicalTrials.gov records cited in ST16 were checked through the primary registry API. Disease mappings, reported maximum phases and dates are compatible with the stated 28 April 2026 search. NCT04015076 includes a CAPS cohort in its full protocol despite its abbreviated condition field saying healthy participants. No finding is retained from that apparent discrepancy. The selnoflast/IZD334 naming is confirmed by the original USAN record. No major trial-reference error was identified.
- Figure 5 has tight spacing around some labels, but the results are readable; this is not retained as a separate major issue.

## 6. Internal consistency, terminology and document integrity — completed

Visually inspected all 31 PDF pages, including the bibliography and both displayed score-construction equations. Checked DOCX XML for tracked insertions/deletions, comments, hidden text, style/font anomalies, hyperlinks and section breaks. There are no tracked changes, comments or hidden-text runs. The equations and mathematical symbols render correctly. A main-text DOCX/PDF comparison found one substantive difference: the IL-6 minus sign described in N1. Other differences were extraction artefacts around line-end hyphens and superscripts. The original input SHA256 hashes still match the initial record.

**Verified reportable finding D1 — unfinished author list.** The title page (P002; PDF page 1) contains a long dotted placeholder between Nick Hirschmüller and Stephen Burgess. Replace it with the final author list and check affiliations before submission.

**Verified reportable finding D2 — unfinished Funding statement.** P100 (PDF page 14) reads “This work was funded by [will be added].” Replace the placeholder with the actual funders and relevant grant details.

**Verified reportable finding D3 — missing UK Biobank data-use declarations.** The manuscript describes analyses using individual-level UK Biobank data but contains no ethics/consent statement, approved application number, or UK Biobank resource acknowledgement. This is a reporting omission; there is no inference that approvals were absent. Add the applicable ethics approval/consent statement and the approved application acknowledgement. UK Biobank's publication guidance explicitly requires the resource/application acknowledgement: https://community.ukbiobank.ac.uk/hc/en-gb/articles/16594178325277-Submitting-publications-and-use-of-UK-Biobank-images.

Other checks not promoted to final findings:
- PDF page 13 is entirely blank. Remove it when regenerating the final PDF, but this does not need a separate high-priority checklist item.
- The Figure 4 caption continues onto the following page without lost text. This is not a substantive document-integrity error.
- Paragraph styles in the trial-search supplement include Heading2 assignments, but their rendered appearance is normal. No formatting finding is retained.
- The stated public GitHub code URL and its unauthenticated repository API both return HTTP 200. The initial browser cache failure is resolved and does not indicate a broken manuscript link.
- No pervasive or scientifically misleading gene/protein naming, abbreviation, significant-digit, italicisation or statistical-symbol problem was found beyond issues already recorded.


## 7. Structure, narrative and final reviewer-style pass — completed

Re-read the Abstract, Methods-to-Results transitions, principal findings, sensitivity interpretation and full Discussion as a clinical cardiovascular reviewer. The study question, analysis sequence and main results form a coherent narrative. There is no substantial missing result, major repetition, unsupported new conclusion introduced only at the end, or additional major citation problem. The reported primary CAD association and mediation arithmetic are internally consistent. S2 above was explicitly reconsidered and removed from the final finding set because the manuscript already gives the relevant qualifications and the audit did not demonstrate an additional definite analytical error.

Retained final checklist items: N1 (DOCX IL-6 sign/version mismatch), S1 (regional colocalisation overstatement), F1 (waterfall interval clipping), F2 (smoking/alcohol release sample sizes), F3 (Parkinson proxy-case definition), D1 (author placeholder), D2 (funding placeholder), and D3 (ethics/consent/application acknowledgement). Minor layout, style and wording observations are not promoted to final findings. The complete working log was reviewed against the requested scope before drafting the final report.

**Important remaining verification U1 — effective number of protein tests.** The repository's step 09b records the method and the answer 1,821, but its source variables `ukb_ppp` and `protein_cols` are not populated by a reproducible input-loading step, and no saved protein correlation matrix or eigenvalue output is supplied. Consequently, the exact effective-test count was not independently verified. The stated threshold arithmetic and resulting discovery count were checked. For a conclusive audit of this multiplicity correction, verify 1,821 against the original saved eigenvalues/correlation calculation; no individual-level data need be placed in the publication package. This is the only unresolved item retained in the concise final report.

Additional reporting guidance for D3: ICMJE recommends reporting the relevant human-research protections and consent; https://www.icmje.org/recommendations/browse/roles-and-responsibilities/protection-of-research-participants.html. The manuscript's omission is a disclosure issue, not evidence about whether approval exists.

Review output only: originals and analysis files were not edited. Temporary scripts, calculations, API records and page renders remain under the requested audit temporary directory. The final concise checklist is `manuscript_review_codex_v2.md`.
