# Pre-submission audit — working log (Claude, v2)

Started 2026-09-23. Audit only; no project files changed.

Inputs audited:
- `NLRP3_manuscript_WIP.pdf` (31 pages, md5 d673780545de9cd88029bcdee0b605d2)
- `NLRP3_manuscript_WIP.docx` (md5 a8eac1a0a15dbcd23ac127efb275e23a)
- `SuppTables_completed_DRAFT.xlsx` (md5 ec531b2ac58760b7112936ce6ce42bf4)
- Code: `config.R`, `helpers.R`, `analysis/*.R`, `figures/*`, `tables/build_supplementary_tables.R`
- Outputs: `results/*`, `figures_out/*`
- Reference PDFs: `/rds/user/nh608/hpc-work/NLRP3_project/references_pdfs`

Scratch work: `/rds/user/nh608/hpc-work/trashtmp/claude_review_v2/`

Repo state at start: no SLURM jobs regenerating results (only an interactive shell). Working tree has
uncommitted edits in 24 tracked files (another session's work; treated as current state).

Not used as evidence: other-LLM review files in the project root and `tables/VALIDATION.md`.

Order of review areas (chosen for dependency: understand what was done before judging it):
1. Methods vs code
2. Results vs code and outputs (numbers)
3. Figures and tables (incl. supplementary tables)
4. Captions and cross-references
5. Internal consistency
6. Scientific and statistical review
7. References
8. Structure and narrative
9. Terminology and conventions
10. Formatting and document integrity
11. Final reviewer-style pass

---

## Early observations from first read (to be confirmed in the relevant area)

- PDF page 13 is completely blank (between Discussion and Data availability).
- Placeholders: author list "……………………", Funding "[will be added]".
- No UK Biobank application number / ethics statement / acknowledgements, although the rare-variant
  and proteome effective-test analyses use individual-level UK Biobank data.
- Supp Fig 4: rs12239046-only Wald ratio OR 1.05 (0.89–1.23, P = 0.58); leaving rs12239046 out raises
  IVW OR to 1.34. Main text calls this "directionally consistent" — check heterogeneity reporting.
- "eight approximately independent variants (r² < 0.1)" — check actual pairwise r² among the 8.
- Citation numbering in DOCX is sequential and every Zotero field maps to the intended item.

---

## Area 1 — Methods versus code (done)

Read every script in `analysis/` (00–12, 09b), `config.R`, `helpers.R`, and the Supp Fig 1/2 scripts.
Independently recomputed the PCA/score (exact match: loadings 0.487/0.508/0.504/0.502, PC1 96.8%,
k = 0.306) and the CAD MR/Egger/Q from the per-variant file (exact match). Step 05's per-variant file
uses exactly the current instrument betas, so the 19:26 re-run of step 00 did not change the instruments.

### Confirmed findings

**M1. UKB-PPP data are the all-ancestry "Combined" release, not European-only. (MAJOR)**
- Evidence: `analysis/04`, `08`, `09` read `.../UKB-PPP pGWAS summary statistics (reformatted)/Combined_European`.
  The folder name is misleading: `reformat_pqtl_cw.sh` in that directory sets `population="Combined"` and
  reads from `.../UKB-PPP pGWAS summary statistics/Combined`. Step 09's own run metadata says
  "UKB-PPP Combined ... all ancestries, not European-only; ~3-5% non-European".
- Sun et al. 2023 (local PDF): full cohort n = 52,363 = 34,557 EUR discovery + replication (10,840 EUR,
  931 AFR, 920 CSA, 308 ME, 262 EAS, 97 AMR). European total ≈ 45,400.
- Max per-assay N in the data is 51,637 — larger than the European total — yet Methods 3.2.1 says
  "up to 51,637 European-ancestry individuals". ST01 says "49,843/50,808/50,779 European ancestry
  individuals" for IL-1β/IL-18/IL-6. Discussion: "all analyses were restricted to European-ancestry
  populations". Methods 3.2 claims ancestry consistency with the (European) instrument datasets.
- Affects: IL-1β/IL-18/IL-6 validation (Fig 2C, ST06), IL1Ra positive control (Fig 4D, ST11),
  proteome-wide MR (ST12, Fig 4E). Effective-test count (09b) was computed in EUR only.
- Impact on estimates probably small (~5% non-European) but the data description is wrong.

**M2. GSCAN alcohol and smoking sample sizes do not match the files analysed. (MUST FIX)**
- Files used: `alcohol_consumption_GCST007461...` (N = 535,425 at every instrument) and
  `smoking_initiation_GCST007474...` (N = 632,802). These are the public GSCAN releases without 23andMe.
- Fig 3C and ST04 give 941,280 (alcohol) and 557,337 cases / 674,754 controls (smoking), i.e. the
  23andMe-inclusive totals from Liu et al. 2019. ST04 download links point to the public files.

**M3. "No additional colocalising ... signals within ±1 Mb" is a visual claim, not a test. (minor–moderate)**
- Colocalisation (step 01) was run over gene ±200 kb only. Supp Fig 2 is a regional plot. Results 4.1
  wording ("No additional colocalising inflammatory biomarker signals ... indicating ... a single shared
  signal") implies a formal analysis. See also C-item on "single shared signal" (internal consistency).

### Checked and consistent (not reportable)
- Clumping ±150 kb, r² < 0.1, 250 kb, P < 5e-8; r² > 0.95/40 kb blocks; 10 multi-trait components →
  1 proxy (r² 0.91) → 2 dropped → 8 variants. Max pairwise r² among the 8 = 0.061 (claim "r² < 0.1" holds).
- Delta-method SE with perfectly correlated biomarker errors; CRP anchoring; orientation (k > 0, so lower
  score = lower CRP). Joint F 92.0; R² 8.3% / 0.11% / 0.046% / 0.064%.
- COJO conditioned on rs6689545 (top eQTL, P = 3.4e-69). HyPrColoc priors 1e-4 / 0.02; PP = 0.967.
  HyPrColoc candidate is rs58546652, r² = 0.98 with rs12239046 (label acceptable).
- Random-effects IVW with INTERVAL LD (MendelianRandomization 0.10.0), WM, Egger intercept.
- CAD: fixed-effect per-variant meta of 4 studies; case/control totals sum correctly (388,987 / 1,850,685).
  Aragam et al. does not include FinnGen or MVP (checked cohort list in local PDF).
- Mediation: within-trait then pooled clumping (r² 0.001, 10 Mb, INTERVAL), multiplicative RE floored
  at 1, conditional F via MVMR::strength_mvmr, null-variant z-score correlation, 1 per 100 kb, P > 0.05.
- SCAPIS scales: CACS rank-inverse-normal (SD change correct); SIS and carotid plaque ordinal/POLMM
  (proportional odds correct) — confirmed in Gummesson et al. 2025 Methods.
- Outcome ancestry: MVP files single-population EUR (direction/I² NA); HGI COVID file is
  B2_ALL_eur_leave_23andme (32,519/2,062,805, confirmed on covid19hg.org R7 page); GBMI asthma 14
  biobanks (EUR subset); knee OA non-Finnish European; GlycA metadata British/European.
- Bonferroni threshold 0.05/1821 = 2.7e-5; 27 lower / 7 higher proteins; 2,922 proteins tested.
- rs10754555 max r² with the 8 instruments = 0.257 (Discussion "0.26" correct).

### Minor, not for final report
- 09b covariates also include age² and age²×sex (SI 11.3 omits them).
- Proteins on several Olink panels: the most significant assay is kept (IL-6 = 4 assays; all four
  P ≤ 1.6e-5, so conclusions unchanged). Not described in Methods.
- ST07 contains an undocumented "Meta-analysis (excl. 1_247460342_C_G)" sensitivity row.
- Proxy selection breaks near-ties (Δr² ≤ 0.05) on CRP P — SI says "highest LD".
- PCA loadings (from centred/scaled betas) are applied to raw-scale betas, so the eQTL contributes ~64% of
  the unscaled composite. This matches the SI formula; raw-weighted and standardised PC1 scores
  correlate 0.99. Not reportable.
---

## Area 2 — Results versus code and outputs (done)

Checked every number in the Abstract, Results 4.1–4.6, Discussion and captions against `results/*`
(areas placed out of scope by the brief were skipped). Also checked Figs 2B/2C, 3A–3E, 4C–4F, 5
and Supp Fig 4 at 220 dpi against the result files, and ST05–ST09, ST11, ST14, ST15 cell by cell.

Result: **no numerical discrepancies.** All estimates, CIs, P values, counts (388,987/1,850,685;
27/7 proteins; 2,922 proteins; 15 indications; 8/13/17/22/24 instruments), percentages (96.8%, 8.3%,
0.11%, 0.046%, 0.064%, 87%), conditional F (15.4/36.7/37.2) and Fig 3D path coefficients
(0.14/0.11/0.23; 0.33/0.73/0.19) match. Per-mediator log-ORs sum to the joint indirect (0.1674) and the
waterfall ΔORs (0.09/0.06/0.03) sum to total − direct. ApoB GWAS is on an SD scale (implied N 449k vs
435k), so "per SD ApoB" in Fig 3D is right.

Minor (not for final report):
- Results 4.4 cites Figure 3E for the per-mediator indirect ORs (1.080/1.047/1.045); Fig 3E shows
  sequential ΔORs from nested models, not these ORs (they are in ST09).
- Fig 2C prints the IL-1β upper CI as "-0.00" (text: -0.004).
- Results 4.6 calls RA (OR 0.61, 0.31–1.18, P = 0.14) a "suggestive association".
- Heterogeneity for the main CAD IVW (Q = 13.88, P = 0.053) is in ST07/ST14 but not in the main text.
---

## Area 3 — Figures and tables (done)

Viewed every figure page at 220 dpi and every supplementary sheet in full.

**F1. Supp Fig 2 (and Fig 2A) recombination trace can be read as association peaks. (MUST FIX, presentation)**
- The recombination-rate line is a thick, saturated blue trace with tall spikes (reaching the height of
  the CRP peak on the left axis) in the same blue as the r² 0–0.2 points. Right axis is labelled
  "Recombination rate (%)" (usual unit is cM/Mb). In Supp Fig 2 the spikes at ~247.9–248.2 Mb look like
  extra signals — which undercuts the very point the figure is cited for (no other signals within ±1 Mb).
  Gold rings on clumped leads are very small and hard to see.

Also confirmed from tables:
- ST01 labels IL-1β/IL-18/IL-6 (UKB-PPP) as European → part of M1.
- ST04 alcohol/smoking N → part of M2 (same numbers in Fig 3C).
- All total-N arithmetic in ST02/ST03 checks out (cases + controls).

Minor (not for final report):
- Fig 1 panel title "Causal Effects on CAD" vs "association" wording elsewhere.
- Fig 3E bars start at OR = 1, so the lower CI bounds (e.g. 0.85 for the direct effect) are not drawn.
- Fig 2C "-0.00"; small inconsistencies in CI decimals in the supp tables; stray non-breaking spaces.

## Area 4 — Captions and cross-references (done)

All Figure 1–5, Supp Fig 1–4 and ST1–ST16 citations point to the right object; numbering is complete and
in order; each supplementary table's title matches its content. Captions describe the displayed panels
and scales correctly (checked CAC = SD, SIS/carotid = POR, T2D/smoking log-OR in Fig 3C, per-SD ApoB/SBP
in Fig 3D).

Minor only:
- Results 4.4 cites Fig 3E for the per-mediator indirect ORs (they are in ST09; Fig 3E shows ΔORs).
- SI subsections are numbered 11.1–11.4 with no "11." heading (the preceding section is "10.
  Supplementary Data").
- Results 4.3 imaging paragraph cites no supplementary table (the numbers are in ST07).
---

## Area 5 — Internal consistency (done)

**C1. "Single shared signal" contradicts the paper's own multi-signal instrument. (MAJOR)**
- Results 4.1: "No additional colocalising inflammatory biomarker signals were observed within the
  surrounding ±1 Mb region (Supplementary Figure 2), indicating that the inflammatory biomarker
  associations in this region arise from a single shared signal at the NLRP3 locus."
- But: Methods 3.4 says the NLRP3 expression association "contained two distinct signals"; Results 4.2
  and Supp Fig 1 show 10 distinct multi-trait signals within ±150 kb (CRP alone has 13 independent
  genome-wide significant signals), from which 8 variants with pairwise r² < 0.1 were taken.
- HyPrColoc (single-causal-variant model) supports only the lead signal (candidate rs58546652 ≈
  rs12239046). It says nothing about the other 7 instruments — which are the ones that carry the CAD
  association (rs12239046 alone: OR 1.05; without it: OR 1.34). See S1.
- Fix: say the biomarker signals map to NLRP3 rather than to neighbouring genes, and that the lead
  signal colocalises; do not call it a single signal. Also make clear the ±1 Mb statement is based on
  inspection of regional plots (M3).

**C2. "All analyses were restricted to European-ancestry populations" is not true for UKB-PPP** → M1.

Checked and consistent: Abstract ↔ Results numbers; mediator list and direction of every effect across
Abstract/Results/Discussion/Fig 1/Fig 3D; "15 other diseases" ↔ Fig 5/ST15; data-source counts across
Methods/ST01–ST04; exposure orientation ("per one-unit lower score") in all figures and tables; MR-Egger
intercept statement in Results ↔ Discussion; conclusion wording ↔ Results (direct OR 1.03, CI 0.85–1.24,
with the Discussion noting the CI is compatible with a modest effect either way).

Minor (not for final report):
- "Validated against IL-1β" (Abstract, Methods, Fig 1) while IL-1β evidence is weak (P = 0.046; upper
  CI −0.004; WM P = 0.079). Consider "supported by" for IL-1β.
- Methods 3.5 says binary outcomes are reported as ORs; Fig 3C shows T2D/smoking as log-ORs (caption
  explains).
- Colocalisation window (gene ± 200 kb) is not stated in Methods 3.4.
- "raised by inhibition" (4.5) mixes drug language into the genetic-proxy wording.
---

## Area 6 — Scientific and statistical review (done)

**S1. The CAD result is modest and its robustness is described too favourably. (MAJOR)**
- Primary IVW OR 1.21 (1.02–1.45), P = 0.032. Cochran's Q = 13.9 on 7 df (P = 0.053; I² ≈ 50%) —
  in ST07/ST14 only, never mentioned in the text.
- The variant with the best evidence of acting through NLRP3 (rs12239046, the colocalising lead, also
  the strongest instrument) gives OR 1.05 (0.89–1.23), P = 0.58 — about a quarter of the pooled log-OR.
  Dropping it raises the OR to 1.34 (1.13–1.59) and removes most heterogeneity (Q 7.8, P = 0.25).
  So the CAD signal is carried by the other seven variants, which the colocalisation does not cover (C1).
- Leave-one-out: 4 of 8 IVW estimates have P > 0.05 (0.053–0.063).
- Supportive: WM OR 1.23 (P = 0.005); r² sweep all P ≤ 0.024 with 8–24 instruments; the four CAD
  datasets agree (between-study Q ≈ 2.6, P ≈ 0.46, my calculation from ST07).
- Manuscript wording: section 4.5 title "...robustness of the coronary artery disease association";
  "directionally consistent ... in a single-variant analysis restricted to the shared colocalising variant";
  closing sentence "the CAD association is directionally consistent across sensitivity analyses".
  True for the direction only; a reviewer reading Supp Fig 4 will see OR 1.05 (P = 0.58).
- Fix: report Q/I² in 4.3; state plainly that the colocalising variant alone gives a near-null estimate and
  that removing it strengthens the association; soften "robustness"; add to the limitations.

**S2. Exploratory disease results are over-read in the Discussion. (MAJOR-lite; decide in final pass)**
- 15 exploratory outcomes. Bonferroni (0.0033): none pass. BH-FDR: only T2D and gout.
  Pericarditis P = 0.012; PD P = 0.036 (WM P = 0.098).
- Abstract and 4.6 say "nominally" (fine). But Discussion para 1 drops "nominally"; 4.6 ends with
  "provide human genetic evidence consistent with potential benefit ... in selected inflammatory and
  neurodegenerative indications" (plural, from one nominal PD result; ALS null); the PD paragraph
  frames the P = 0.036 result as contrasting with Senkevich et al.

Checked and NOT a problem (supports the paper):
- Cardiometabolic associations are homogeneous across the 8 variants: SBP Q P = 0.93, ApoB 0.94,
  T2D 0.68; Egger intercepts null; no strong independent SBP/ApoB/T2D signal in the window (regional
  lead P ≈ 1e-3). This argues against pleiotropy from a neighbouring gene and could be added as support
  for the mediation interpretation.
- ZEUS "no reduction in cardiovascular events": Yao et al. 2026 reports top-line HR 0.99 (0.88–1.11).
- Mediation arithmetic, conditional F, scales: consistent (Area 2).

Minor (not for final report):
- Exposure–outcome sample overlap (UK Biobank in CRP/GlycA/neutrophil GWAS and in Aragam CAD,
  pericarditis, knee OA) is not discussed. With joint F = 92 the bias is small; one sentence would do.
- Product-of-coefficients with a binary mediator (T2D) and binary outcome on the log-odds scale is
  approximate (non-collapsibility); CAD is not rare in these datasets.
- "Validated against IL-1β" is strong for P = 0.046 (WM P = 0.079).
- MI (OR 1.01, 0.70–1.45) vs CAD (1.21) not discussed; CIs overlap.
---

## Area 7 — References (done)

Citation mechanics: 71 Zotero fields, 65 unique items, numbered 1–65 in order of first citation, each
field maps to the intended item; bibliography has 65 entries, none uncited. URLs are plain text (no
hyperlink fields), not broken.

Claims checked against sources (local PDF unless stated):
- [53] Schunk 2021: single intronic rs10754555; higher CAD prevalence <60 y (age interaction); higher CV
  mortality in primary (HR 1.06) and secondary (HR 1.14) prevention; lipids did not differ; ApoC3/TG/urate
  modulate → all supported.
- [56] Senkevich (local = medRxiv 2023 version): SMR with expression QTLs + rare variants + PRS, no
  evidence for NLRP3 in PD → supported.
- [48] IL-1 Genetics Consortium 2015: IL1RN score lowers IL-6/CRP, raises LDL-C and CHD risk → supported.
- [5] Yao 2026: ZEUS top-line HR 0.99 (0.88–1.11) for 3-point MACE → "no reduction" supported.
- [27] Burgess 2023 guidelines: robust methods (incl. MR-Egger/InSIDE) problematic for single-gene-region
  analyses → supported.
- [25] Foley 2021: HyPrColoc defaults p = 1e-4, pc = 0.02 → supported.
- [21] Lu 2026: DOI 10.64898/2026.05.08.26350964 is the DOI printed on the preprint (new medRxiv prefix).
- [7] Lee 2004 (PubMed abstract): IL-18 increased IL-6 in IL-18Rβ-transfected epithelial cells → adequate.
- [24] Rietveld 2023: MA-GREML paper; applies the delta method for mediation SEs → unusual but defensible.
- [44] Zhou 2021: "lack of reliable measurement techniques" for NLRP3 activation → adequate.
- [11] Jiang 2025 (Europe PMC full text): discusses NLRP3 inhibitors in clinical trials → supported.
- [65] Mangan 2018 (web): RA phase II halted for raised liver enzymes. SI 11.4 adds "off-target" and
  "rather than lack of efficacy" — not stated in sources (minor).

Bibliography formatting glitches (MUST FIX, low priority; one clean-up pass):
- Ref 4 "Entremont M-A d’", ref 10 "Heijden T van der ... Duijn J van, Santbrink PJ van", ref 24
  "Vlaming R de" (Zotero particle handling); ref 58 "Smith GD" (should be Davey Smith G, as in refs 27/29);
  ref 26 pages "369-S3" (369–375); ref 59 "4:s13742-015-0047–0048" (4:7); refs 39 and 47 lack article
  numbers; refs 28/63 (software) lack URL/version.
- Ref 36 (Chen 2024, gnomAD v3 constraint paper) cited for gnomAD v4.1 annotations — minor.

No reference was found that fails to support an important claim.
---

## Area 8 — Structure and narrative (done)

**N1. Sensitivity and positive-control analyses are missing from the Methods. (MAJOR, reporting)**
- Methods 3.5 covers IVW, weighted median and the Egger intercept only. Not described anywhere in
  Methods/SI: the LD-threshold sweep (r² 0.1–0.6, with instruments re-selected and the score re-derived
  at each threshold — only the Fig 4F caption says so), leave-one-out, the single-variant Wald ratio,
  Cochran's Q (reported in ST07/ST14), and the IL1Ra positive-control outcome analyses (UKB-PPP IL1Ra
  protein, gout, RA; SI 11.1 only covers score construction). STROBE-MR expects these in Methods.

**N2. Journal requirements (EHJ assumed from the "Background and Aims" abstract format). (MUST FIX)**
- Official EHJ page (academic.oup.com/eurheartj/pages/general_instructions): abstract ≤ 250 words; body
  ≤ 5,000 words (excl. title, abstracts, legends, references); Structured Graphical Abstract mandatory;
  line numbers and page numbers required; ethics statement; Data Availability Statement; acknowledgements;
  ≤ 8 figures + tables; ≤ 100 references.
- Manuscript: abstract ≈ 271 words; body ≈ 5,310 words (whitespace tokens, headings and citation
  superscripts excluded); no Structured Graphical Abstract; no line or page numbers (no footer, no
  lnNumType in any sectPr); no ethics statement; no acknowledgements. 5 figures, 0 tables, 65 refs (OK).

Narrative otherwise coherent: Abstract conclusion reflects the Results; Introduction → aims → Methods →
Results → Discussion flow is logical; limitations section is candid about pleiotropy, lifelong vs drug
exposure, tissue specificity and power.

Minor (not for final report):
- The homogeneous cardiometabolic Wald ratios (Area 6) are unused evidence for the on-target story.
- Results 4.5 bundles five different analyses under one heading; readable but long.
---

### Update to M1 (UKB-PPP ancestry) — consequence for the IL-1β claim

Re-ran the step-04 cytokine MR (same instruments, INTERVAL LD, correlated IVW + WM) on the
European-only UKB-PPP **discovery** release (`.../UKB-PPP pGWAS summary statistics/European (discovery)`,
chr1 extracted to `trashtmp/claude_review_v2/ppp_eur/`; script `r/check_ppp_eur.R`):

| Protein | Combined (paper) | European discovery only (n ≈ 33k) |
|---|---|---|
| IL-1β | −0.25 (−0.49 to −0.004), P = 0.046 | −0.22 (−0.52 to 0.08), P = 0.14 (WM P = 0.30) |
| IL-18 | −0.52 (−0.79 to −0.25), P = 1.6e-4 | −0.62 (−0.98 to −0.25), P = 9.0e-4 |
| IL-6 (best of 4 assays) | −0.72, P = 2.8e-9 | −0.74 to −0.88 on all 4 assays, P ≤ 4.1e-5 |

So the IL-1β association (Abstract, Results 4.2, Discussion, Fig 1, Fig 2C) depends on using the larger
all-ancestry release; the point estimate is similar, so this is mostly power, not ancestry. Either keep
the Combined data and describe it correctly (and soften "validated against IL-1β"), or switch to the
European release and report IL-1β as not significant. M1 stays MAJOR.

---

## Area 9 — Terminology and conventions (done)

Consistent throughout: "NLRP3 activity score", "genetically proxied", pLOF, colocalisation (UK) with
Mendelian randomization (conventional US), gene italics (NLRP3, IL1RN, PCSK9, TET2), exposure direction.
Nothing reportable.

Minor (not for final report): Methods 3.7 "apolipoprotein (ApoB)" (missing "B"); unclosed parenthesis
in Methods 3.4 ("(prior.1 = 1×10-4, prior.c = 0.02."); mixed P formats (0.00016 vs 5.7×10-3); two P's
set in Cambria Math italic (4.6); "IL1Ra" vs conventional "IL-1Ra"; SD not defined as an abbreviation;
"S.B" missing full stop; "28 of April" vs "28th of April".

## Area 10 — Formatting and document integrity (done)

DOCX has no tracked changes, comments, visible highlights or hidden text; fonts/sizes consistent
(title 17 pt, affiliations 10 pt, body 11 pt Times New Roman); equations render correctly in the PDF.

**D1. Blank PDF page 13 and stray empty paragraphs. (MUST FIX)**
- Para 95 is an empty paragraph holding a manual page break; after the Discussion fills page 12 it
  spills onto page 13, leaving it blank. Five more empty paragraphs (86–90) after "Although our findings…"
  leave ~¼ of page 11 empty. Paragraphs 84–85 are indented with a literal TAB (different indent from the
  rest).
- SI 11.4 body paragraphs (DOCX paragraphs 139–142) are styled "Heading 2" with manual overrides to
  look like body text; an empty "Heading 1" paragraph carries the section break before References. Invisible
  in the PDF, but they will show as headings in the navigation pane and in any style-based conversion.

**D2. No line or page numbers.** → part of N2 (EHJ requires both).

**D3. Placeholders and incomplete front/back matter. (MUST FIX)**
- Author list "……………………"; Funding "[will be added]"; COI covers N.H., S.B., D.S.P. only (none for
  A.S.B. or the missing authors).

**D4. No ethics statement, UK Biobank application number or acknowledgements; Data availability not
accurate. (MAJOR/MUST FIX)**
- Individual-level UK Biobank data are used (rare-variant analyses, proteomic effective-test count);
  All of Us data were extracted for this study. No application number, ethics/consent statement or
  acknowledgement of UK Biobank, All of Us, FinnGen, MVP, INTERVAL, SCAPIS or the GWAS consortia.
- "No new data were generated" — new association results were generated from UK Biobank individual data,
  and the All of Us extract is not public.
- "The code used to perform all analyses ... is available at github.com/nickhir/NLRP3_MR_manuscript": the
  repo is public but at commit cadef7e; the 24 modified files (e.g. pooled cross-trait clumping in
  helpers.R/07a/07c, random-effects total effect in 07c) and untracked scripts (09b, Supp Fig 1/2,
  table builder) are not pushed. As it stands the public code does not reproduce the reported mediation.

Minor: pdftotext reports "xref num 306 not found" (PDF cross-reference table slightly damaged; renders
fine); Supplementary Information sits inside the manuscript file (EHJ wants separate supplementary files).
---

## Area 11 — Final reviewer-style pass (done)

New finding:
**X1. Discussion describes NCT06097663 as ongoing; it finished in Nov 2024 and has posted results. (MUST FIX)**
- Text: "A phase 2a trial is now evaluating the NLRP3 inhibitor DFV890 in patients with coronary heart
  disease and TET2- or DNMT3A-associated clonal haematopoiesis (NCT06097663)."
- ClinicalTrials.gov API (checked 2026-09-23): status COMPLETED (primary completion 2024-10-27, study
  completion 2024-11-04), hasResults = true; eligibility "CHIP ... driver mutations in TET2 or DNMT3A with a
  VAF ≥2%"; arms DFV890 (10–100 mg) and MAS825. Posted primary outcomes at week 3: IL-6 ratio vs placebo
  0.77 (10 mg, P = 0.08), 0.67 (25 mg), 0.62 (50 mg), 0.59 (100 mg); IL-18 ratio 0.93 (P = 0.007).
- Fix: past tense, and consider citing the posted results — they show IL-6 lowering by an NLRP3 inhibitor,
  which also fits the score's IL-6 finding.

Reviewer questions considered and judged not reportable (no clear error): alternative weighting of the
score (eQTL-only or CRP-only); colocalisation of the NLRP3 signal with CAD itself (no CAD signal strong
enough in the window to test); IL1Ra score against CAD as a second positive control; PCA on 8 variants.

Consolidation for the final report:
- M3 merged into C1 (same Results 4.1 sentence).
- ST01 merged into M1; ST04 merged into M2.
- D1 (blank page) and the SI 11.4 heading-style paragraphs combined into one formatting clean-up item.
- D4 split into (a) ethics / UK Biobank application number / acknowledgements and (b) Data availability
  wording + pushing the final code.
- N2 split into three journal-requirement items (word limits; Structured Graphical Abstract; line/page
  numbers), flagged as applying if the target is EHJ.
- S2 kept as MAJOR (over-read secondary claims).
- Severity: nothing rated CRITICAL — no finding overturns the main estimates; S1, M1, C1, N1, S2, D4a are
  MAJOR; the rest MUST FIX.

Could not be fully verified (for the report):
- N_EFFECTIVE_TESTS = 1,821 (hard-coded; needs individual-level UKB-PPP data; 09b documents the method).
- Target journal (EHJ assumed from abstract headings) and All of Us publication/acknowledgement rules.
