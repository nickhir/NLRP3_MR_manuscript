# Independent pre-submission audit — Codex v2

Started 23 September 2026. Sources: user-specified manuscript PDF and DOCX, supplementary XLSX, primary analysis code/outputs, local cited-paper PDFs and primary online evidence. No other LLM review has been read or used. Source documents and analyses are read-only. Temporary work is confined to `/rds/user/nh608/hpc-work/trashtmp`.

## EHJ benchmark summary

21 full main texts from the main European Heart Journal; 0 abstract-only/part-only papers counted. Relevant supplements checked for 20/21; the 2019 body-composition/AF supplement was inaccessible. Counts describe this purposive sample, not journal mandates. A missing accessible supplement is unknown, not a negative.

| Item | Reported / applicable assessable papers | Qualification |
|---|---:|---|
| Between-instrument MR heterogeneity Q/I² | 5/18 | Excludes single-variant studies, inaccessible supplement and Q for cohorts/nonlinearity |
| MR-Egger | 19/19 | Applicable multi-variant analyses; sometimes supporting polygenic stages, not cis target stage |
| MR-Egger intercept | 17/19 | Same applicable analyses |
| Weighted/penalized median | 17/19 | Same applicable analyses |
| F statistic or explicit F threshold | 10/20 | Includes thresholds rather than numeric distributions |
| Exact instrument R² evidence | 9/20 | Excludes generic education-score/source R² |
| Colocalisation in contemporary cis studies | 3/5 | ANGPTL3/4, ANGPTL3, plasma proteins/MI, GIP, BP-protein study |
| STROBE-MR cited/included after checklist publication | 2/12 | Excludes 2021 papers published before checklist and earlier papers |
| Quantitative proportion mediated | 4/5 | Applicable MR mediation studies; fifth uses qualitative MVMR attenuation |
| Structured abstract | 21/21 | Historical headings differ from current instructions |
| Graphical abstract or take-home figure | 20/21 | Includes historical take-home figures |
| Standalone Data Availability/Data Sharing statement | 16/21 | Older papers sometimes put source access in Methods |
| Funding statement | 21/21 | Presence only |
| Conflict-of-interest statement | 21/21 | Presence only |
| Separate Acknowledgements | 18/21 | Conditional contributions; integrated acknowledgements excluded |
| Separate Author Contributions | 3/21 | Current CRediT submission fields distinct from manuscript section |

Technical sensitivity details commonly reside in Methods/Supplement; causal language is often used but linked to genetic evidence and limitations. Legend abbreviation practice is mixed; repeated definitions in every legend are not universal. Full per-paper evidence: [ehj_mr_benchmark.md](/rds/user/nh608/hpc-work/trashtmp/ehj_mr_benchmark.md).


## Step 0A — current EHJ submission instructions

Completed detailed reading of the current author instructions, Clinical Research and Translational Science requirements, linked quality standards/statistical guidance, graphical abstract and accessibility/alt-text guidance. Checklist: [ehj_author_guidelines_checklist.md](/rds/user/nh608/hpc-work/trashtmp/ehj_author_guidelines_checklist.md), 72 checkable groups, with mandatory/recommended/conditional distinctions.

Key interpretive decisions: format-free initial submission is permitted; Oxford English is required; structured abstracts may use defined abbreviations; no universal abbreviation-list requirement was found; figure-legend definitions and end-matter order contain contradictory wording, so benchmark evidence is needed before alleging a breach. Current main-article limit is 5,000 words and fixes will be designed to replace/cut or use the Supplement. No word-count finding will be raised. Current required alt text is assessed separately from older published practice. Direct declarations-form and EndNote downloads were inaccessible, but the instructions specify applicable requirements.

## Review-area tracking

Planned reporting sequence: 3 Methods/code; 4 Results/outputs; 2 scientific/statistical; 1 references; 5 internal consistency; 6 figures/tables; 9 captions/cross-references; 7 structure/narrative; 11 declarations; 8 terminology; 10 document integrity; 12 dedicated typo pass; 13 dedicated consistency pass; 14 holistic reviewer pass. Findings are appended only after root verification; unresolved questions are labelled, and duplicates consolidated.
## Step 0B — completed

All 21 main texts were read before beginning manuscript review. Root checked the three agent records, denominator qualifications, and primary-source passages for key counts. Benchmark omissions do not establish mandatory reporting. Guidelines take priority where explicit and current.

## Area 3 — Methods versus code (complete)

Root read the manuscript Methods/Supplement and independently checked the output rows and shared-component selection code underlying the two findings below. Full implementation coverage and cleared checks: [codex_v2_methods_audit.md](/rds/user/nh608/hpc-work/trashtmp/codex_v2_methods_audit.md). No critical implementation error verified; no important unresolved Methods/code item.

**M1 — MUST FIX: shared-signal selection is described as variant-level significance.** Methods3.3 (P037; PDFp5 lines139–141) and Supplementary Figure1 caption(P119; PDFp21) say retained variants are individually significant for two traits. Code analysis/00_instrument_selection.R:267–337 selects shared LD components then representative/proxy variants; rs74154640 passes5×10⁻⁸ for CRP only (expression3.50×10⁻⁶, GlycA1.15×10⁻⁷, neutrophils9.01×10⁻⁸). results/00_instrument_selection/nlrp3_proxy_replacements.tsv gives its substitution at r²=.910596. Supplementary Figure1 plots27 signal components, of which10 are shared, not27 individual variants. Fix main wording: “We identified signals shared by at least two traits and selected eight representative variants.” Correct the supplementary figure title/count descriptions to signals, and explain10 shared signals→8 representatives with complete effects. Existing Supplementary Methods largely gives the correct procedure. EHJ norm: Not a reporting-norm issue.

**M2 — MUST FIX: wrong colocalisation-candidate label.** Methods3.5(P041), Results4.5(P074), Supplementary Figure4 heading/caption(P124), ST14 A32 call rs12239046 the shared colocalising variant. HyPrColoc nominates1_247438476_C_T=rs58546652 (PP.9671, fraction explained.9857); single-variant MR uses1_247438293_C_T=rs12239046. Independent same-panel PLINK check gives r²=.9822. The sensitivity result remains useful. Replace label by “a variant tagging the shared signal (rs12239046)” consistently; identify the actual candidate in the Supplement if needed. EHJ norm: Not a reporting-norm issue.

## Area 4 — Results versus outputs (complete)

Root independently checked the primary IL6 and IL1RN/RA result rows, corresponding manuscript paragraphs, Figure2C/Figure4D rendering and PDFp8. Full audit evidence: [codex_v2_results_audit.md](/rds/user/nh608/hpc-work/trashtmp/codex_v2_results_audit.md). All checked workbook result cells matched outputs, including2,922 proteomics rows and190 enrichment rows. Independent generalized-least-squares calculations reproduced2,948 IVW results. Main CAD totals, effect estimates, mediation arithmetic, variance percentages, instrument strength and sensitivity directions matched. No important unresolved numerical item.

**N1 — MUST FIX: DOCX-only IL6 sign.** Results4.2 second paragraph(P063) gives beta+0.72 despite wholly negative CI; primary estimate−.7167894, ST06E12 and Figure2C give−0.72. Supplied PDFp8 line287 already gives−0.72. Correct Word and regenerate a consistent submission PDF. EHJ norm: Not a reporting-norm issue.

**N2 — MUST FIX: stale RA positive-control estimate.** Results4.5 positive-control paragraph(P072; PDFp10 lines351–352) says OR.26(.07–.94), P.04. Primary results/08_il1rn_positive_control/il1rn_mr_results.tsv and ST11F4/G4/I4/Figure4D give OR.2160585(.1133156–.4119579), P3.26764×10⁻⁶. Replace text in both versions with “OR =0.22, 95% CI0.11 to0.41, P =3.3×10⁻⁶”. EHJ norm: Not a reporting-norm issue.

M2 independently confirmed; consolidate rather than repeat. GoutP is present as a Word equation and correct, not a missing-number finding. Main and supplementary formula omissions in the initial plain extraction were artefacts; math-aware extraction and visual checks resolve them.

## Area 2 — Scientific and statistical review (complete)

Read Abstract, all main sections and supplementary methods; considered target validity, genetic versus pharmacological interpretation, biological validation, direction/scaling, mediation arithmetic, sensitivity evidence and multiplicity. Main conclusions are qualified as genetic evidence; limitations acknowledge pleiotropy, treatment timescale, population/tissue relevance and power. No additional critical scientific/statistical problem verified. Reporting norms do not justify adding a generic methods wish list: between-instrument heterogeneity is located in5/18 applicable assessable benchmark papers; STROBE-MR in2/12 post-checklist papers. Code performs stated heterogeneity assessment. Broad failure to add those outputs/checklists is not itself a final-report finding. Two specific external-evidence interpretations are handled under Area1 after primary-source verification. Statistical reporting of sidedness/default significance is assessed under guidelineG50.


## Area 1 — References (complete)

All 65 entries and 72 citation fields checked for identity, numbering and support, using local PDFs first. Root verified the four findings below against the primary papers and exact manuscript paragraphs. Full per-reference access/evidence ledger: [codex_v2_references_ledger.md](/rds/user/nh608/hpc-work/trashtmp/codex_v2_references_ledger.md). No fabricated reference, unused entry, broken citation mapping or important unresolved support question found.

**R1 — MAJOR: differential treatment benefit overstated.** Discussion paragraph beginning “Although our findings…” (P082; ref52) says TET2 carriers “showed a greater reduction”. The cited exploratory CANTOS analysis reports interaction P=.14 and characterises the difference as equivocal. Replace with “showed a numerically greater reduction”; one word preserves the supported subgroup rationale. Primary evidence: [Svensson et al., Results](https://pmc.ncbi.nlm.nih.gov/articles/PMC8988022/). EHJ norm: Not a reporting-norm issue (interpretation of cited evidence).

**R2 — MUST FIX: unsupported toxicity mechanism.** Supplementary Information14.4, final paragraph(P144; ref65): delete “off-target” from “off-target hepatotoxicity”. Mangan2018 p599 explicitly says the cause of the liver toxicity signal is unclear. Root read the primary PDF extraction, lines1362–1371. [Primary source](https://doi.org/10.1038/nrd.2018.97). EHJ norm: Not a reporting-norm issue.

**R3 — MUST FIX: incorrect author-name parsing.** Ref9(P154): “Ho Park K”→“Park KH”. Primary article p31 gives Ki Ho Park and contributions p43 say Dr Park; official institutional laboratory also confirms surname. Correct reference-manager name fields before refreshing. EHJ norm: Not a reporting-norm issue.

**R4 — MUST FIX: incomplete published title.** Ref52(P197): restore “: An Exploratory Analysis of the CANTOS Randomized Clinical Trial”. Root verified primary article heading. EHJ norm: Not a reporting-norm issue.

Reference-format details are reserved for guideline/consistency sections: MEDLINE abbreviations at refs24,43,56,59,62; DOI display differs at ref21 versus all other entries; page-range hyphens at refs16/61 versus dominant en dashes. DOI inclusion derives from EHJ examples rather than an unambiguous prose mandate, so record as an internal inconsistency, not an unconditional submission breach. Format-free initial submission waives reference-format requirements. Other substantive clinical/preclinical claims checked against their sources were supported at the stated scope.

## Area 5 — Internal consistency (complete)

Compared Abstract, main text, figures, captions, supplementary methods/workbook and primary outputs. Verified discrepancies are consolidated as N1 (Word/PDF IL6 sign), N2 (RA positive control), M1 (signal versus variant selection) and M2 (candidate versus tagging variant). Exposure directions, CAD totals, sample descriptions and main conclusions otherwise agree. Terminology/format conventions receive a separate exhaustive pass below. No new major inconsistency or important unresolved item.

## Area 6 — Figures and tables (complete)

Root visually inspected all five main figures and four supplementary figures at full-page resolution, compared labels/estimates with text and source outputs, and read the relevant plotting code. Supplementary workbook structure/result cells were checked in Area4; trial registry labels/IDs were checked against 38 ClinicalTrials.gov records plus the applicable European/ISRCTN records. No further trial identity/phase/indication error verified.

**F1 — MAJOR: Figure3E hides existing confidence intervals.** The axis starts at1.0 and opaque bars cover the left whiskers. The existing three adjusted intervals extend below1 (lower bounds .9364,.8801,.8517), but the graphic does not display those crossings. Primary evidence: results/07d_mediation_waterfall/waterfall.tsv; figures/fig03e_mediation_waterfall.py:81,102–112. Extend the axis below .85 and draw the full existing whiskers above the bars. This is a display correction requiring no new calculation. EHJ norm: Not a reporting-norm issue.

Technical/accessibility corrections for the guideline list: supplied raster line-art Figure1 is300ppi; Supplementary Figures1/3/4 are300/187/300ppi at embedded size, below600ppi line-art requirement(G31). Other main panels retain vectors; do not infer raster resolution from EMF headers. Source vector files exist for several affected figures. Use source vectors or regenerate at required resolution, without merely upsampling. The two-estimator forests distinguish IVW/weighted median using colour with the same diamond/line: Figure2C,3A–C,4F,5 and Supplementary Figure4; add a second cue, such as differing marker shapes(G34). No general aesthetic criticism warranted. Existing M1/M2/N2 corrections consolidated above.

## Area 9 — Captions and cross-references (complete)

All Figure1–5, Supplementary Figure1–4 and Supplementary Table1–15 citations map correctly. Table16 is reached through the main-text Supplementary Information referral and explicitly cited there; no missing-object criticism. Panel labels match figures. No broken/duplicated object numbering found.

Definite caption corrections for guideline list: Figure2B and4C whiskers are beta±1.96SE in plotting code but are not identified as95% CIs; identify them. Figure2A/Supplementary Figure2 omit explanation of dashed genome-wide significance line(P=5×10⁻⁸) and identity of the LD reference variant(rs12239046); add one short sentence. Figure4E does not name the enrichment test/BH correction or27-protein input; add “Hypergeometric enrichment of27 proteins against2,922 tested proteins; Benjamini–Hochberg-adjusted P values.” The Supplement already gives the background and correction. Missing alt text under all main legends is a separate G33 rule. PC1 expansion and duplicate abbreviation definitions are consolidated under terminology. Repeating common/earlier-defined abbreviations in every legend is not imposed because EHJ explicitly exempts these.

## Area 7 — Structure and narrative (complete)

Read the title, Abstract, Introduction, first/last Discussion paragraphs and Results summary as a clinical-journal reader, against21 full EHJ MR main texts. The clinical question, unexpected direction, mechanistic interpretation and implications for trials are clear. Genetic-versus-treatment limitations are concentrated in the appropriate Discussion material. No additional major narrative gap, conspicuous underselling or unnecessary technical barrier verified. R1 is the specific wording correction needed, already recorded; no optional rewriting proposed.

## Area 11 — Declarations and end matter (complete)

Data Availability, Disclosure of Interest, Acknowledgements and ethics/consent/Helsinki statements are present. Root checked public GitHub access by unauthenticated HTML and API(HTTP200); source/access routes are identified in Tables1–4 and the text. Source-link verification is complete:40 cells/37 routes checked; all30 GCST accession/phenotype/PMID mappings matched official metadata. No meaningful wrong destination or mapping verified. Some EBI file requests timed out, but the datasets were correctly identified; this is an access limitation, not a manuscript finding. No separate manuscript Author Contributions heading required by EHJ; only3/21 benchmark papers have one, versus16/21 standalone data statements and21/21 COI statements. Submission-system forms/CRediT/attestations cannot be inferred missing from this document. No verified end-matter correction at this point.

## Area 8 — Terminology and manuscript conventions (complete)

Root checked the abbreviation locations in the original text and workbook, mathematical notation in the math-aware extraction/rendering, and relevant run formatting with inherited styles. Detailed verified inventory is included under Area13 below to avoid repeating fixes. Nonstandard first-use problems are GWAS, LD, SNP, ASC, InSIDE, eQTL and FCAS. PC1 needs “first” in its expansion. No general abbreviation list or arbitrary abbreviation limit is imposed. Common clinical/statistical abbreviations and proper study/software names are not automatically treated as nonstandard. GlycA is explained in the main Introduction; this is adequate first-use context. No additional major terminology error.

## Area 10 — Formatting and document integrity (complete)

All32 PDF pages visually inspected, with figure pages examined at full size; DOCX run/paragraph/section/footer settings and math objects checked. No lost text, overlap, broken equation or corrupt figure verified. The recoverable PDF cross-reference warning is not a visible submission error.

**D1 — MUST FIX/G19: page numbering restarts.** PDF physical pages28–32 (references) are numbered1–5 after page27. The second Word section explicitly has pgNumType start=1. Set numbering to continue from the previous section. Consecutive pagination is required even for format-free submission. EHJ norm: EHJ rule.

**D2 — MUST FIX: orphaned declaration page.** PDFp14 contains only “Pre-registered Clinical Trial Number / Not applicable.” Reflow this short statement with the other declarations to remove the almost-empty standalone page. Root verified the layout visually. EHJ norm: Not a reporting-norm issue.

Other formatting differences are consolidated under guideline compliance, explicitly subject to format-free initial-submission waiver: single-spaced/justified body, first-line indentation through style rather than one tab, continuous line numbering and absent reference-page line numbers, legends preceding references. No unsupported demand for a running title or separate author-contribution heading is made.

## Area 12 — Dedicated typo pass (complete)

Separate full-text read, all65 bibliography entries, all figure/caption text and461 distinct narrative/header/source/drug workbook strings checked; protein/ontology identifiers compared with primary outputs. Root verified every listed typo against the source paragraphs. No additional genuine typo found.

All six below occur in both versions; all are MUST FIX and Not a reporting-norm issue:

- Methods3.4/P039/PDFline155: “blood neutrophil count ,”→“blood neutrophil count,”.
- Methods3.4/P039/PDFline162: “(prior.1 =1×10⁻⁴, prior.c =0.02.”→“(prior.1 =1×10⁻⁴, prior.c =0.02).”.
- Methods3.9/P051/PDFline236: “Supplementary Information″.”→“Supplementary Information.”.
- Methods3.11/P055/PDFline250: “on the28 of April2026”→“on28 April2026” (or28th, matching Supplement).
- Results4.1/P059/PDFline267: “support coherent NLRP3-linked inflammatory signal”→“support a coherent NLRP3-linked inflammatory signal”.
- Results4.5/P073/PDFline356: “after multiple-testing”→“after correction for multiple testing”.

The separate version comparison anchored142 paragraphs/entries, including all65 references. N1 is the only substantive Word/PDF text difference found. Double space after citation28 belongs in consistency below. Full evidence: [codex_v2_typos_audit.md](/rds/user/nh608/hpc-work/trashtmp/codex_v2_typos_audit.md).

## Area 13 — Dedicated consistency pass (complete)

Root verified paragraph/cell locations, original workbook headers/font flags, relevant DOCX styles and figure labels. The following inventory is accepted after verification; severity MUST FIX and EHJ norm Not a reporting-norm issue unless a specific abbreviation rule is invoked. The final report groups each convention into one checkbox with all locations.

## Certain abbreviation fixes

1. **GWAS defined too late:** first main-text use P029, Methods 3.2; expansion appears only in P045, Methods 3.7, after many uses. Move “genome-wide association studies (GWAS)” to P029 and use GWAS alone in P045. This simultaneously fixes late definition and avoids a redundant later introduction.
2. **LD used before definition:** P037 first says “LD-clumped”, then defines “linkage disequilibrium (LD)” later in the same sentence. Move the expansion to that first occurrence, e.g. “clumped for linkage disequilibrium (LD) … using … as the reference panel.”
3. **SNP never expanded:** P033 “SNP–CAD association estimates”; Figure 2A/Supplementary Figure 2 colour keys use “Index SNP”; ST05!A1 is SNP. Define single-nucleotide polymorphism at the initial main-text occurrence, or use “variant–CAD” in the main text and define SNP where it first appears in the figure/table material.
4. **ASC never expanded:** P020, Introduction para 2, “the adaptor ASC”. This is a nonstandard inflammasome abbreviation. Shortest main-text fix is “an adaptor protein”; if retaining ASC, expand it once (apoptosis-associated speck-like protein containing a caspase recruitment domain).
5. **InSIDE never expanded:** P041, Methods 3.5. Short plain replacement: “its key independence assumption” in place of “its InSIDE assumption”, retaining the existing cited explanation. The technical expansion can be used in Supplement if wanted, but there is no need to add a paragraph.
6. **IL1Ra defined again:** P072, Results 4.5, repeats “interleukin-1 receptor antagonist (IL1Ra)” after the first main-text definition in P037. Use IL1Ra in P072. The separate supplementary-methods definition P134 need not be treated as a breach merely for being repeated across files/sections intended to stand alone.
7. **PC1 expansion incomplete:** P109, Figure 2 legend, “PC1, principal component” → “PC1, first principal component”.
8. **pLOF defined twice within one legend:** P123, Supplementary Figure 3, first prose sentence and final abbreviation list. Keep one definition within that legend.
9. **eQTL abbreviation not formally introduced:** first abbreviated use is ST01!A5 “NLRP3 eQTLs”; prose first abbreviated use is P127, Supplementary Methods 14.1. P031 previously writes out the full term but does not introduce the abbreviation. Spell it out in ST01!A5, and define “expression quantitative trait locus (eQTL)” in P127. This can be confined to Supplement.
10. **FCAS undefined:** ST16!A9 “including FCAS”. Replace with “including familial cold autoinflammatory syndrome”.

## Defined abbreviations that are not reused in their relevant text/table

- Abstract P010: GlycA is introduced but not reused anywhere else in the Abstract. Remove “(GlycA)” there; the body should introduce it independently if retained there.
- ST03!C4: GBMI introduced after the full consortium name, but not used elsewhere in the supplied text/tables. Delete the parenthetical abbreviation.
- ST03!C15: T2DGGI introduced after the full consortium name, but not used elsewhere. Delete the parenthetical abbreviation.
- ST16!A4, A6, A9, A10: ALS, COPD, CAPS and HFrEF are introduced but not reused in that table or elsewhere outside bibliographic titles. Delete those four parenthetical abbreviations. Do not delete full disease names.

## Certain presentation and convention fixes

### Gene italics

Dominant prose convention: italic gene symbols, roman protein/activity-score names. The following clear gene uses are roman after inherited-style resolution:

- P045, Methods 3.7: “cis-acting NLRP3 variants”.
- P089, Discussion disease-indications paragraph: “variants at the NLRP3 locus”.
- P119, Supplementary Figure 1 legend: “within ±150 kb of NLRP3” and “whole-blood NLRP3 expression”.
- ST01!A5, “NLRP3 eQTLs”; ST05!H2,H7,H12,H17,H22,H27,H32,H37, “NLRP3 expression”. Italicise only the gene name, not the surrounding text.
- Contents!B6, the first NLRP3 in “cis-NLRP3 instruments”; Contents!B11, “for NLRP3 and its neighbouring genes”.
- ST11!A2:A4, the IL1RN gene symbol in “cis-IL1RN / IL1Ra activity score”; keep IL1Ra roman.

Do not flag P037, P075, P079 or TET2/DNMT3A in P082: inherited Emphasis correctly supplies italics. Do not italicise NLRP3 when it denotes the protein, inhibition, inflammasome or activity score. P071 “driven by NLRP3 itself” could refer to the protein and is not counted as a certain error.

### Statistical notation

- **Italic P in prose:** dominant form is italic. Deviations: P045 null-variant threshold; P123 “P values”; P127 both P < 1×10⁻³ specificity thresholds. Italicise these four occurrences. Math-object P in P077/P113/P127 already renders italic: do not flag it from raw XML.
- **P capitalization in figures:** dominant figure symbol is uppercase P. Figure 4A's three comparison annotations and Supplementary Figure 3's twelve comparison annotations use lowercase p. Change the symbol only; no numerical change is implied.
- **Italic r:** P119 plain-text r²<0.1 and P127 “provided r² was at least 0.9” have roman r. Match the italic r used elsewhere. The other apparent plain “r2” strings in DOCX are either real superscripts or math objects and render correctly.
- **Superscript2 in workbook:** ST14!A2:A13 uses literal baseline “r2”; use r² in all twelve cells.
- **Operator spacing in ordinary prose:** use P < and r² <, matching the dominant form. P037 has “P<5×10⁻⁸”; P119 has “r²<0.1”. P033 has three “n=” sample sizes, whereas P059 uses “n =”. Math-object relation spacing in P077/P113/P121/P127 is typeset correctly and is not an error.
- **P value hyphen:** prose uses “P value(s)”; P127 alone has “P-value” in “lowest CRP association P-value”. Remove that hyphen. Compact graph labels may use a different convention without being a separate error.
- **CI separators in running text:** all main-text intervals use “to”; Abstract P013 uses en dashes in its two CIs. Use the same separator for those two running-text intervals. Compact table/forest-plot interval punctuation is not counted as a breach.
- **Odds-ratio precision in running text:** two decimal places dominate. P068 uses three decimals for the SBP, ApoB and T2D indirect ORs and their CIs, and for the residual direct OR while its CI has two decimals. Standardise those four estimates/three indirect intervals to the selected precision; two decimals matches the Abstract and remaining text. This is a formatting inconsistency, not a numerical discrepancy. Do not round a small nonzero continuous-effect CI boundary to zero merely to force two decimals.

### Citation and reference style

- Citation superscripts consistently precede sentence punctuation with no preceding space. P051 “Cosson et al. 39” has an extra space before superscript 39; remove it.
- Bibliography page ranges predominantly use en dashes. References 16 (P161, 1198-1213.e14) and 61 (P206, 1415-1429.e19) use hyphens; use en dashes. Reference-title spelling/capitalisation was not treated as manuscript house style.
- P041 has two spaces after the MendelianRandomization citation and before “(version 0.10.0)”; reduce to one.

### Capitalisation and naming

- **Subheadings:** sentence case dominates the numbered Methods subheadings. P047 “Predicted Loss-of-Function Analysis” and P050 “Predicted Gain-of-Function Analysis” use title case; convert the ordinary words to sentence case.
- **Neutrophil label:** “Neutrophil count” dominates labels. Supplementary Figure 1 alone says “Neutrophil Count”; lowercase Count.
- **Cytokine protein labels:** use the protein forms IL-1β, IL-18, IL-6 matching Figure 2C and the text. ST06!B8:B9 says IL1B; B10:B11 says IL18; B12:B13 says IL6. These outcome labels describe measured proteins. Retain genuine assay IDs/gene-symbol identifiers in ST12/ST13.
- **ID abbreviation:** ST12!A1 “Protein Id” → “Protein ID”, matching “Term ID” and “Trial ID(s)” elsewhere.
- **Workbook column-heading case:** sentence case is dominant, but these ordinary words are title-cased: ST01!B1,C1,D1; ST02!A1,B1,C1,D1; ST03!A1,B1,C1,D1; ST04!A1,B1,C1,D1; ST06!C1; ST07!D1; ST08!C1; ST11!C1; ST12!B1,C1,D1,H1,I1,J1,K1,N1,O1; ST13!G1; ST14!C1; ST15!C1. Lowercase noninitial ordinary words (Author, Consortium, Size, Outcomes, Number, Risk Factors, Instruments, Name, Beta, Median, Intercept, Genes), retaining actual acronyms/proper names.
- **Workbook trait-label case:** ST01!A4 “Glycoprotein Acetyl concentration” capitalises Acetyl; ST04!A11 “Body Mass Index (BMI)” capitalises Mass/Index. Other analogous trait labels use sentence case. Separately verify the preferred full GlycA name in the terminology pass.
- **Weighted median hyphen:** the method name is “weighted median” throughout prose; P113 alone uses “weighted-median analysis”. Remove the hyphen there.
- **Trial phase notation:** Arabic phase numbers dominate the prose (phase 3 and phase 2a) and ST16. P144 alone says “Phase II”; use “phase 2”.


### Root additions and decisions

- **Heading case:** sentence case dominates Methods/Results subheadings. At top level, four multiword headings use title case and two sentence case; do not incorrectly claim a sentence-case majority at that level. To harmonise the document's headings, use sentence case in3.8,3.9,10 “Ethical Approval”,11 “Pre-registered Clinical Trial Number”,13 “Supplementary Data”, and the unnumbered “Supplementary Information”. Add14 to the latter to match14.1–14.4, unless separating supplementary files removes this numbering.
- **Spelling:** Oxford English is otherwise consistent. For same-root consistency, IntroductionP022 “randomised”→“randomized” to match12 occurrences of randomization outside reference titles. Both are British variants; this is not an American-English error. Retain quoted/reference-title spelling and source ontology identifiers.
- **Hyphenation:** ST04!A2 “Low density lipoprotein cholesterol levels”→“Low-density…” to match IntroductionP019. “Whole exome” occurs only once outside reference titles and is not a mixed convention. Do not invent one.
- **DOI display:** reference21 alone includes a DOI;1–20 and22–65 omit theirs. Standardise using available DOIs, consistent with EHJ examples. This is an internal inconsistency; the examples are not an unambiguous prose mandate.
- **Gene symbols in graphs:** roman gene-symbol labels are used as graph identifiers; the main source-track format alone is not treated as a mandatory scientific error. Clear gene-use prose/cell deviations above are accepted. Protein/assay identifiers in enrichment data are retained.
- **Readability:** occasional full disease names after definition, particularly the first Discussion summary, serve clinical readability and are not flagged as unexplained inconsistencies.
- **Precision:** mixed three-decimal mediation ORs versus two-decimal ORs elsewhere is a real presentation difference. Standardise reported OR precision without interpreting rounding as a new numerical discrepancy.
- **GuidelineG22:** Results4.5/P073 “higher levels of7”→“higher levels of seven”. Counts in structured tables, phase/trait names and mathematical quantities are not mechanically spelled out.

No important unresolved terminology, typo or convention question remains. Direct original-file verification took precedence over extraction artefacts and agent suggestions; borderline expansions for TNF, PD-1 and common statistical/clinical abbreviations were not promoted into findings.

## Completion of the EHJ compliance pass

All72 checklist groups now have an assessment/evidence entry, including conditional and nonapplicable rules. Source: [completed checklist](/rds/user/nh608/hpc-work/trashtmp/ehj_author_guidelines_checklist.md). The final compliance list will consolidate overlapping rules, especially missing graphical abstract and alt text, and qualify format-free initial-submission exceptions.

Additional confirmed items: keywords absent; structured graphical abstract/Key Question/Key Finding/Take-home Message absent from the supplied package; main-figure alt text absent. For G50, replace/add one sentence in Methods3.5: “MR tests were two-sided, with nominal significance at P <0.05.” Existing multiplicity descriptions remain applicable. Do not say every test was two-sided, because enrichment tests are directional.

G28 sample-size pointers missing in Figure2A–B and SupplementaryFigure2(sourceTable1); Figure4C(source samples for IL1RN expression and blood traits); Figure4F and SupplementaryFigure4(shared CAD samples inFigure3A). Other forest panels already show sample sizes and do not need duplicated prose. G38: original supplementary sheets all use general/default alignment rather than centred columns, a format-only correction. No colour/shading found in the workbook.

G34 root independently recalculated contrast ratios from the specified source colours. Small #8A8A8A text on white is3.452:1 (below4.5) in Figure2C sampleNs,4D sampleNs,4F instrumentNs and SupplementaryFigure4 section headings; darken to#767676 or darker. Informative marks below3:1: green neutrophil point/CIs in2B/4C(#7CAE00,2.654); zero lines2B/4C(#A9A9A9,2.350); gold instrument rings2A/Sup2(#DAA520,2.238); Sup2 significance line(#999999,2.849). Decorative separators are not findings. The separate colour-only estimator cue is already recorded. Full source lines and primary guideline links are in [figure audit](/rds/user/nh608/hpc-work/trashtmp/codex_v2_figures_audit.md).

## Area 14 — Final reviewer-style pass (complete)

Reread the title, full Abstract, study question, key figures, first/last Discussion paragraphs, clinical-context comparisons and Limitations. No new critical scientific error or major narrative weakness was verified. The report retains the two incorrect text estimates, two analysis-description/label corrections, clipped confidence-interval display, two source-interpretation corrections, bibliography errors, document-integrity errors and complete verified typo/consistency/guideline lists. Findings that were only optional wording changes or unverified conjectures were dropped. All changes proposed for the main text are replacements or one short methods sentence; technical figure/source details stay in captions/Supplement.

Final applicability decision: journal-format differences are explicitly distinguished from initial-submission blockers because EHJ permits format-free first submission. The complete checklist still records every difference. No assertion that a waived layout/reference-style difference invalidates an initial submission will be made. All current-rule items in the final report cite checklist IDs; error/convention items use “Not a reporting-norm issue”.

## Audit closure

Root reread the complete working log before drafting the final checklist and screened every retained issue against the instructed scope. No important unresolved scientific, numerical or citation-support item remains within that scope. Source-route evidence: [codex_v2_source_links.md](/rds/user/nh608/hpc-work/trashtmp/codex_v2_source_links.md). All original manuscript DOCX/PDF/XLSX SHA256 hashes match the hashes captured before the audit. Original analyses/results/figures were not modified. Supporting scratch evidence remains under the specified temporary directory.
