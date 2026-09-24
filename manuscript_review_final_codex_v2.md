# EHJ pre-submission checklist

No CRITICAL issue was verified. The main corrections concern two reported estimates, instrument descriptions, Figure 3E and two interpretations of cited evidence. All verified typos and convention problems are included below.

Checked against **21 full EHJ MR papers**, with supplements available for 20; no abstract-only papers counted. Evidence: [working log](/rds/user/nh608/hpc-work/NLRP3_MR_manuscript/manuscript_review_working_codex_v2.md), [72-rule checklist](/rds/user/nh608/hpc-work/trashtmp/ehj_author_guidelines_checklist.md). Original files are unchanged. `STxx!A1` identifies an Excel sheet and cell.

## Methods

### 3.3 — Instrument construction

- [ ] **MUST FIX — Correct the instrument-selection description.** **Problem:** The text and Supplementary Figure 1 say each retained variant was significant for at least two traits. The code selects shared LD signals and representative/proxy variants; rs74154640 is genome-wide significant only for CRP. **Why:** The stated selection rule is inaccurate. **EHJ norm:** Not a reporting-norm issue. **Action:** Replace with “We identified signals shared by at least two traits and selected eight representative variants.” In Supplementary Figure 1, change variant-count descriptions to signal counts and explain 10 shared signals → eight representatives with complete effects.

### 3.5 — Single-variant sensitivity analysis

- [ ] **MUST FIX — Distinguish the colocalisation candidate from its proxy.** **Problem:** HyPrColoc nominates rs58546652; the sensitivity analysis uses rs12239046, which tags it (r² = 0.982). **Why:** The current label misidentifies the analysed variant. **EHJ norm:** Not a reporting-norm issue. **Action:** Use “a variant tagging the shared signal (rs12239046)” in Methods 3.5, Results 4.5, Supplementary Figure 4 heading/caption and ST14!A32.

## Results

### 4.2 — IL-6 estimate

- [ ] **MUST FIX — Restore the minus sign in Word.** **Problem:** DOCX gives β = 0.72; the output, Figure 2C, ST06!E12 and PDF give **−0.72**. **Why:** It reverses the reported direction. **EHJ norm:** Not a reporting-norm issue. **Action:** Correct DOCX and regenerate the submission PDF.

### 4.5 — IL1Ra positive control

- [ ] **MUST FIX — Replace the stale rheumatoid arthritis result.** **Problem:** Both manuscript versions report OR 0.26, CI 0.07–0.94, P 0.04; the output, Figure 4D and ST11 give a different result. **Why:** The text understates the association. **EHJ norm:** Not a reporting-norm issue. **Action:** Use **OR = 0.22, 95% CI 0.11 to 0.41, P = 3.3×10⁻⁶**.

## Discussion

### Paragraph beginning “Although our findings…”

- [ ] **MAJOR — Qualify the TET2 subgroup comparison.** **Problem:** “Showed a greater reduction” implies established greater benefit; the cited CANTOS analysis found interaction P = 0.14. **Why:** The subgroup contrast was inconclusive. **EHJ norm:** Not a reporting-norm issue. **Action:** Write “showed a **numerically** greater reduction”; no extra caveat is needed. [Primary study](https://pmc.ncbi.nlm.nih.gov/articles/PMC8988022/).

## Figures

### Figure 3E

- [ ] **MAJOR — Show the complete existing confidence intervals.** **Problem:** The axis starts at 1 and the bars cover the lower whiskers. The three adjusted intervals cross 1, but the graphic hides this. **Why:** It can make those estimates look clearly positive. **EHJ norm:** Not a reporting-norm issue. **Action:** Extend the axis below 0.85 and draw the existing whiskers above the bars. No new calculation is required.

## Supplementary Information

### 14.4 — Final paragraph

- [ ] **MUST FIX — Remove the unsupported toxicity mechanism.** **Problem:** Reference 65 does not establish “off-target hepatotoxicity”; it says the cause was unclear. **Why:** This asserts an unsupported mechanism. **EHJ norm:** Not a reporting-norm issue. **Action:** Delete **“off-target”**. [Primary source](https://doi.org/10.1038/nrd.2018.97).

## References

- [ ] **MUST FIX — Reference 9 author name.** **Problem:** “Ho Park K” incorrectly splits Ki Ho Park’s name. **Why:** Incorrect attribution. **EHJ norm:** Not a reporting-norm issue. **Action:** Change to **Park KH** in the reference-manager record and refresh.
- [ ] **MUST FIX — Reference 52 title.** **Problem:** The published subtitle is missing. **Why:** It identifies the exploratory study design. **EHJ norm:** Not a reporting-norm issue. **Action:** Append **“: An Exploratory Analysis of the CANTOS Randomized Clinical Trial”**. [Published title](https://pmc.ncbi.nlm.nih.gov/articles/PMC8988022/).

## Document layout

- [ ] **MUST FIX — Almost empty PDF page 14.** **Problem:** Only the trial-registration heading and “Not applicable” appear. **Why:** Conspicuous layout artefact. **EHJ norm:** Not a reporting-norm issue. **Action:** Reflow this statement with the preceding declarations.

## Typos

All are MUST FIX; **EHJ norm: Not a reporting-norm issue**. Locations apply to both versions.

- [ ] Methods 3.4: “blood neutrophil count ,” → “blood neutrophil count,”.
- [ ] Methods 3.4: “(prior.1 = 1×10⁻⁴, prior.c = 0.02.” → “(prior.1 = 1×10⁻⁴, prior.c = 0.02).”.
- [ ] Methods 3.9: “Supplementary Information″.” → “Supplementary Information.”.
- [ ] Methods 3.11: “on the 28 of April 2026” → “on the 28th of April 2026”, matching Supplement 14.4.
- [ ] Results 4.1: “support coherent NLRP3-linked inflammatory signal” → “support a coherent NLRP3-linked inflammatory signal”.
- [ ] Results 4.5, proteomics paragraph: “after multiple-testing” → “after correction for multiple testing”.

## EHJ guideline compliance

**EHJ norm: EHJ rule** for each item. Rule IDs link to the [source-linked checklist](/rds/user/nh608/hpc-work/trashtmp/ehj_author_guidelines_checklist.md). **† Formatting requirements are waived for initial format-free submission**; these are journal-format corrections, not initial-submission blockers. [EHJ instructions](https://academic.oup.com/eurheartj/pages/General_Instructions).

- [ ] **G03 — Keywords:** None supplied. Add up to six after the abstract.
- [ ] **G05–08 — Structured graphical abstract:** Supply the missing graphic plus **Key Question, Key Finding and Take-home Message** text. Figure 1 is a study-design diagram. Use the dimensions/typography in the checklist.
- [ ] **G15 — First-use abbreviations:** Move **GWAS** expansion to Methods 3.2 and **LD** expansion before “LD-clumped” in 3.3; define **SNP** at 3.2.2. In Introduction paragraph 2, replace “the adaptor ASC” with “an adaptor protein”; in Methods 3.5 replace “its InSIDE assumption” with “its key independence assumption”, or expand the technical term. Define **eQTL** in Supplement 14.1 and spell it out in ST01!A5. Expand **FCAS** to “familial cold autoinflammatory syndrome” in ST16!A9.
- [ ] **G19 — Pagination:** References on physical PDF pages 28–32 restart at 1–5. Set the second Word section to continue numbering.
- [ ] **G27 — Figure keys:** In Figure 2A and Supplementary Figure 2 captions add: “Colours indicate LD (r²) with rs12239046; dashed lines mark P = 5×10⁻⁸.”
- [ ] **G28 — Graph legends:** Identify Figure 2B/4C bars as **95% CIs**. For Figure 4E state **hypergeometric enrichment of 27 proteins against 2,922 tested proteins, with Benjamini–Hochberg adjustment**. Add source-sample pointers for Figure 2A–B/Supplementary Figure 2 (Supplementary Table 1), Figure 4C (IL1RN-expression and biomarker source samples), and Figure 4F/Supplementary Figure 4 (CAD samples in Figure 3A).
- [ ] **G33 — Alt text:** Add an **“Alt text:”** description directly below each main Figure 1–5 legend.
- [ ] **G34 — Figure accessibility:** Give IVW/weighted median different marker shapes in Figures 2C, 3A–C, 4F and 5 and Supplementary Figure 4. Darken gray text in Figures 2C, 4D and 4F and Supplementary Figure 4 to **#767676 or darker**. Darken the green neutrophil estimates and gray zero-lines in Figures 2B/4C, gold rings in Figure 2A/Supplementary Figure 2, and the latter’s gray significance line to meet 3:1 contrast. Current small gray text is 3.45:1 against a 4.5:1 requirement; listed marks are 2.24–2.85:1. [Exact locations/colours](/rds/user/nh608/hpc-work/trashtmp/codex_v2_figures_audit.md).
- [ ] **G50 — Test sidedness/significance:** Add to Methods 3.5: **“MR tests were two-sided, with nominal significance at P < 0.05.”** Existing multiplicity descriptions can remain. [Statistical guidance](https://academic.oup.com/eurheartj/pages/Statistics).
- [ ] **G31† — Raster resolution:** Figure 1 and Supplementary Figures 1, 3 and 4 are 300, 300, 187 and 300 ppi respectively. Supply vectors or source renders of at least 600 dpi; do not merely upscale.
- [ ] **G18† — Text formatting:** Change the single-spaced, justified body to double-spaced, left-aligned text; use the specified tab indentation.
- [ ] **G20† — Line numbering:** Restart each page and include the reference pages, which currently lack line numbers.
- [ ] **G26† — Legend placement:** Group legends after the references on a new page.
- [ ] **G38† — Table alignment:** Centre supplementary-table columns beneath their headers in ST01–ST16; they currently use Excel’s default alignment.
- [ ] **G45† — Journal abbreviations:** Ref 24 **PLoS Genet**; 43 **Rheumatology (Oxford)**; 56 **NPJ Parkinsons Dis**; 59 **Gigascience**; 62 **Innovation (Camb)**.
- [ ] **G22† — Small integer in prose:** Results 4.5 “higher levels of 7” → “higher levels of seven”.

## Consistency

All are MUST FIX under the requested consistency pass; **EHJ norm: Not a reporting-norm issue**. Quoted source titles and formal assay/ontology identifiers retain their source spelling.

- [ ] **Unused abbreviations:** Remove parenthetical **GlycA** from Abstract Methods; **GBMI** from ST03!C4; **T2DGGI** from ST03!C15; **ALS/COPD/CAPS/HFrEF** from ST16!A4/A6/A9/A10. Their full names are already supplied; the abbreviations are not reused in the relevant text/table.
- [ ] **Repeated definitions:** Use IL1Ra without re-expanding it in Results 4.5 after its Methods 3.3 definition. In Supplementary Figure 3, retain one pLOF definition rather than both the opening sentence and closing list.
- [ ] **PC1:** Figure 2 legend “principal component” → **“first principal component”**.
- [ ] **Gene italics:** Match the dominant italic-gene/roman-protein convention for NLRP3 in Methods 3.7 “cis-acting…variants”; Discussion disease-indications paragraph “…locus”; Supplementary Figure 1 “within ±150 kb…” and “…expression”; ST01!A5; ST05!H2,H7,H12,H17,H22,H27,H32,H37; Contents!B6 (first occurrence), B11. Italicise IL1RN in ST11!A2:A4; keep IL1Ra roman.
- [ ] **Protein labels:** Match IL-1β/IL-18/IL-6 elsewhere: change ST06!B8:B9 **IL1B→IL-1β**, B10:B11 **IL18→IL-18**, B12:B13 **IL6→IL-6**.
- [ ] **Italic P:** Italicise the null-variant threshold in Methods 3.7, “P values” in Supplementary Figure 3, and both specificity thresholds in Supplement 14.1.
- [ ] **Uppercase P:** Change lowercase statistical p labels in Figure 4A and Supplementary Figure 3 to match the other figures.
- [ ] **r² typography:** Italicise r in Supplementary Figure 1’s clumping threshold and Supplement 14.1’s “provided r²…” clause. Change baseline **r2→r²** in ST14!A2:A13.
- [ ] **Operator spacing:** Match spaces elsewhere in Methods 3.3 **P < 5×10⁻⁸**, Supplementary Figure 1 **r² < 0.1**, and all three Methods 3.2.2 **n =** sample sizes.
- [ ] **CI separators:** Main prose uses “to”; change the two dash-separated intervals in Abstract Results to match.
- [ ] **OR precision:** Two decimals dominate. Standardise the three indirect ORs/their CIs and the residual direct OR in Results 4.4, using the unrounded outputs.
- [ ] **Citation spacing:** Remove the space before superscript 39 after “Cosson et al.” in Methods 3.9; other citations immediately follow the text.
- [ ] **Extra space:** Methods 3.5 has two spaces after citation 28 before “(version 0.10.0)”; use one.
- [ ] **Reference ranges:** Use en dashes in refs 16 **1198–1213.e14** and 61 **1415–1429.e19**, matching the other page ranges.
- [ ] **DOIs:** Ref 21 alone prints its DOI. Apply one reference style consistently; adding available DOIs to refs 1–20 and 22–65 follows EHJ’s examples. Values are in the [reference ledger](/rds/user/nh608/hpc-work/trashtmp/codex_v2_references_ledger.json).
- [ ] **Spelling:** Oxford/British usage is otherwise consistent. Change Introduction paragraph 4 **randomised→randomized** to match the 12 “randomization” uses outside reference titles. Both variants are British; this is a same-root consistency fix.
- [ ] **Heading case:** Methods/Results subheadings favour sentence case; top-level headings are mixed. Harmonise headings 3.8, 3.9, 10 **Ethical Approval**, 11 **Pre-registered Clinical Trial Number**, 13 **Supplementary Data**, and **Supplementary Information** to sentence case.
- [ ] **Heading numbering:** Add **14.** before Supplementary Information to match 14.1–14.4, or renumber consistently when separating the Supplement.
- [ ] **Label case:** Supplementary Figure 1 **Neutrophil Count→Neutrophil count**; ST12!A1 **Protein Id→Protein ID**; ST01!A4 **Acetyl→acetyl**; ST04!A11 **Body Mass Index→Body mass index**.
- [ ] **Table-header case:** Match the prevailing sentence case at ST01!B1:D1; ST02!A1:D1; ST03!A1:D1; ST04!A1:D1; ST06!C1; ST07!D1; ST08!C1; ST11!C1; ST12!B1:D1,H1:K1,N1:O1; ST13!G1; ST14!C1; ST15!C1. Lowercase noninitial ordinary words; retain acronyms/proper names.
- [ ] **Hyphenation:** Supplement 14.1 **P-value→P value**; Figure 4 legend **weighted-median analysis→weighted median analysis**; ST04!A2 **Low density→Low-density**, matching the corresponding prose conventions.
- [ ] **Trial phases:** Supplement 14.4 **Phase II→phase 2**, matching Arabic phase numbering elsewhere.

## EHJ benchmark summary

Counts use applicable, assessable papers; they are not journal requirements. [Full 21-paper benchmark and evidence](/rds/user/nh608/hpc-work/trashtmp/ehj_mr_benchmark.md).

| Item | Reported / applicable |
|---|---:|
| Between-instrument Q/I² |5/18|
| MR-Egger / intercept |19/19;17/19|
| F statistic or explicit threshold |10/20|
| Colocalisation, contemporary cis studies |3/5|
| STROBE-MR after checklist publication |2/12|
| Quantitative proportion mediated |4/5|
| Structured abstract |21/21|
| Graphical abstract/take-home figure |20/21|
| Standalone Data Availability |16/21|
| Conflict of Interest / separate Author Contributions |21/21;3/21|

MR-Egger counts include supporting polygenic stages where present. Most applicable papers did **not** report inter-instrument heterogeneity or cite STROBE-MR; their omission alone was not treated as a required fix.

## Highest-priority pre-submission fixes

- [ ] Correct the IL-6 sign and rheumatoid arthritis estimate.
- [ ] Correct shared-signal selection and colocalisation-proxy descriptions.
- [ ] Restore the full existing confidence intervals in Figure 3E.
- [ ] Qualify the TET2 comparison and remove “off-target”.
- [ ] Complete the graphical abstract, keywords and main-figure alt text.

## Could not be fully verified

None within the agreed audit scope.
