# Pre-submission checklist — NLRP3 MR manuscript

Checked on 2026-09-23 against `NLRP3_manuscript_WIP.pdf/.docx`, `SuppTables_completed_DRAFT.xlsx`, the code in
`analysis/`, `results/` and the cited papers. Full evidence is in `manuscript_review_working_claude_v2.md`.

**Good news first:** every number in the abstract, text, captions, figures and supplementary tables matches the
analysis outputs. The problems below are about how the data are described, how the CAD result is framed, gaps
in the Methods, and submission paperwork.

---

## Methods

### 3.2.1 Datasets (UK Biobank Pharma Proteomics Project) — also ST01 and the Discussion limitations

- [ ] **MAJOR — The protein data come from the all-ancestry UKB-PPP release, not a European-only one**
  - **Problem:** Steps 04, 08 and 09 read UKB-PPP's "Combined" release (all ancestries, n = 52,363). The local
    folder is named `Combined_European`, but its reformatting script reads `Combined`. The paper says "up to
    51,637 European-ancestry individuals", ST01 calls the cytokine data European, and the Discussion says all
    analyses were European-only. UKB-PPP has only about 45,400 Europeans.
  - **Why it matters:** It's a factual error, and it touches a headline claim. On the European-only discovery
    release (n ≈ 33,000), IL-1β is no longer associated: β −0.22 (−0.52 to 0.08), P = 0.14, against P = 0.046
    in the paper. IL-18 and IL-6 hold up. Affects Fig 2C, Fig 4D/4E, ST06, ST11 and ST12.
  - **Action:** Either keep the Combined data and describe them correctly (Methods 3.2.1, ST01, limitations),
    or switch to European-only data and report IL-1β as not significant. Either way, tone down "validated
    against IL-1β" in the Abstract, Methods 3.1 and Figure 1.

### 3.5 Mendelian randomization analyses

- [ ] **MAJOR — The sensitivity and positive-control analyses are not described in the Methods**
  - **Problem:** The Methods cover only IVW, weighted median and the Egger intercept. The following appear only
    in Results, figure captions and supplementary tables:
    - the LD-threshold sweep (r² 0.1–0.6, with instruments re-selected and the score rebuilt at each threshold);
    - leave-one-out;
    - the single-variant Wald ratio;
    - Cochran's Q;
    - the IL1Ra positive-control outcome MR (IL1Ra protein, gout, RA).
  - **Why it matters:** Readers can't tell how these analyses were done, and STROBE-MR expects them in the
    Methods. Reviewers will ask.
  - **Action:** Add a short "Sensitivity analyses" paragraph to 3.5. Describe the IL1Ra outcome analyses in 3.3
    or SI 11.1.

---

## Results

### 4.1, paragraph 1 — "a single shared signal"

- [ ] **MAJOR — The "single shared signal" claim contradicts the paper's own instrument**
  - **Problem:** Results 4.1 says the biomarker associations "arise from a single shared signal at the NLRP3
    locus". But Methods 3.4 says the expression association has two distinct signals, and the score uses 8
    independent variants from 10 multi-trait signals (Supp Fig 1: CRP alone has 13 within ±150 kb). The ±1 Mb
    check was done by eye on regional plots; colocalisation was only run over gene ±200 kb.
  - **Why it matters:** A reviewer will spot the contradiction. HyPrColoc supports only the lead signal, not
    the other seven instruments, and those seven carry the CAD association (next item).
  - **Action:** Say the lead signal colocalises across the four traits and the biomarker signals map to NLRP3
    rather than neighbouring genes. Say the ±1 Mb check is visual. Drop "single shared signal".

### 4.3 and the last paragraph of 4.5 — robustness of the CAD association

- [ ] **MAJOR — The CAD result is presented as more robust than it is**
  - **Problem:** The main estimate is OR 1.21 (1.02–1.45), P = 0.032, with borderline heterogeneity (Q = 13.9
    on 7 df, P = 0.053, I² ≈ 50%) that appears only in ST07/ST14. The colocalising lead variant rs12239046, also
    the strongest instrument, gives OR 1.05 (0.89–1.23), P = 0.58, on its own; dropping it gives OR 1.34
    (1.13–1.59). Four of eight leave-one-out estimates have P = 0.053–0.063. The text calls this "directionally
    consistent", and the 4.5 heading promises "robustness".
  - **Why it matters:** Supp Fig 4 shows these numbers, so a reviewer will see the gap and ask whether the CAD
    effect runs through NLRP3. The weighted median, r² sweep and all four CAD datasets support the direction,
    so the result stands, but it needs honest framing.
  - **Action:** Report Q and I² in 4.3. In 4.5, say plainly that the lead variant alone gives a near-null
    estimate and the other variants carry the association. Soften "robustness" in the heading and closing
    sentence, and add the point to the limitations.

---

## Discussion

### Paragraphs 1 and 6, plus the last sentence of Results 4.6 — exploratory indications

- [ ] **MAJOR — The exploratory disease findings are over-read**
  - **Problem:** Fifteen exploratory outcomes were tested. None pass a Bonferroni correction (0.05/15), and
    with FDR only T2D and gout would survive. Pericarditis has P = 0.012. Parkinson's has P = 0.036 (weighted
    median P = 0.098), and ALS is null. Despite this:
    - Discussion paragraph 1 states the gout, pericarditis and PD associations without "nominal".
    - Results 4.6 ends with "evidence consistent with potential benefit … in selected inflammatory and
      neurodegenerative indications" (plural, based on one nominal PD result).
    - The PD paragraph presents P = 0.036 as contradicting a dedicated genetic study (Senkevich et al.).
  - **Why it matters:** These are unsupported claims on a secondary aim. They are an easy target for reviewers
    and weaken the main message.
  - **Action:**
    - Say "nominal" throughout, and state that none of these results survive correction for 15 tests.
    - Drop "neurodegenerative indications".
    - Present the PD result as hypothesis-generating rather than as contradicting Senkevich et al.

### Paragraph 4 (clonal haematopoiesis) — NCT06097663

- [ ] **MUST FIX — A trial described as ongoing has finished and posted results**
  - **Problem:** The text says "A phase 2a trial is now evaluating the NLRP3 inhibitor DFV890…". NCT06097663
    completed in November 2024, and its results are posted on ClinicalTrials.gov. At week 3, DFV890 25–100 mg
    lowered IL-6 by about a third versus placebo (ratio 0.59–0.67) and IL-18 by about 7%.
  - **Why it matters:** This is an outdated fact in a paper about NLRP3 inhibitors, and clinical reviewers may
    know the trial.
  - **Action:** Change the sentence to past tense. Consider citing the posted results, which also fit the
    score's IL-6 finding.

---

## Figures and supplementary tables

### Figure 3C and Supplementary Table 4 — alcohol and smoking sample sizes

- [ ] **MUST FIX — The sample sizes don't match the files that were analysed**
  - **Problem:** Fig 3C and ST04 show 941,280 for alcohol and 557,337 cases / 674,754 controls for smoking.
    These are the GSCAN totals including 23andMe. The files analysed are the public releases without 23andMe,
    with N = 535,425 (alcohol) and N = 632,802 (smoking) at every instrument.
  - **Why it matters:** These are wrong numbers in a figure and a table.
  - **Action:** Use the public-release N in both places.

### Supplementary Figure 2 (and Figure 2A) — recombination-rate trace

- [ ] **MUST FIX — The recombination trace looks like extra association peaks**
  - **Problem:**
    - The recombination line is drawn as thick spikes in the same blue as the r² 0–0.2 points, and it reaches
      the height of the real CRP peak.
    - The right axis reads "Recombination rate (%)"; the usual unit is cM/Mb.
    - The gold rings marking the clumped leads are tiny.
  - **Why it matters:** Supp Fig 2 is cited to show that there are no other signals within ±1 Mb. At a glance
    the spikes suggest the opposite.
  - **Action:** Draw the recombination line thin and light grey, fix the axis unit, and enlarge the gold rings.

---

## References

- [ ] **MUST FIX — Several reference entries are garbled**
  - **Problem:** Zotero has mangled name particles and page fields:
    - ref 4: "Entremont M-A d’";
    - ref 10: "Heijden T van der … Duijn J van, Santbrink PJ van";
    - ref 24: "Vlaming R de";
    - ref 58: "Smith GD" (should be "Davey Smith G", as in refs 27 and 29);
    - ref 26: pages "369-S3" (should be 369–375);
    - ref 59: "4:s13742-015-0047–0048" (should be 4:7);
    - refs 39 and 47: article numbers missing.
  - **Why it matters:** It looks careless and misnames authors. (No reference failed to support its claim.)
  - **Action:** Fix the name-particle and page fields in Zotero and regenerate the bibliography.

---

## Front and back matter

### Title page, Funding, Conflicts of interest

- [ ] **MUST FIX — Placeholders remain and the COI section is incomplete**
  - **Problem:** The author list is still "……………………" and Funding says "[will be added]". The COI covers
    only N.H., S.B. and D.S.P. There is nothing for A.S.B. or the missing authors.
  - **Action:** Complete all three sections, with a COI line for every author.

### Ethics, approvals and acknowledgements (section missing)

- [ ] **MAJOR — There is no ethics statement, UK Biobank application number or data acknowledgement**
  - **Problem:** The study uses individual-level UK Biobank data and an All of Us extract, as well as FinnGen,
    MVP, INTERVAL, SCAPIS and consortium GWAS. The manuscript has none of the following:
    - an ethics or consent statement;
    - the UK Biobank application number;
    - acknowledgements.
  - **Why it matters:** UK Biobank and All of Us require these in publications. EHJ also requires ethics and
    acknowledgement statements, so the editorial check will stop the submission.
  - **Action:** Add an ethics statement and the UK Biobank application number. Add the standard acknowledgement
    for each of UK Biobank, All of Us, FinnGen, MVP, INTERVAL and SCAPIS, using each resource's required
    wording.

### 6. Data availability

- [ ] **MUST FIX — The statement is inaccurate and the public code is out of date**
  - **Problem:**
    - "No new data were generated" is not true: the study generated new association results from UK Biobank
      individual-level data, and the All of Us extract is not public.
    - "The code used to perform all analyses … is available" is not true of the public GitHub repo, which is
      at commit `cadef7e`. None of the following are pushed:
      - the 24 locally modified files, which include the pooled cross-trait clumping and random-effects changes
        behind the reported mediation;
      - the untracked scripts (09b, Supp Fig 1/2, the supplementary-table builder).
  - **Why it matters:** Someone who clones the repo cannot reproduce the reported mediation results.
  - **Action:** State how each dataset can be accessed: public summary statistics as listed in ST1–ST4, and UK
    Biobank and All of Us by application. Commit and push the final code, and tag the submitted version.

---

## Whole document

### Layout

- [ ] **MUST FIX — Blank page 13 and stray formatting in the DOCX**
  - **Problem:** PDF page 13 is blank because an empty paragraph with a manual page break, after the
    conclusion, spills onto a new page. Five more empty paragraphs leave a quarter of page 11 blank, and two
    Discussion paragraphs are indented with a TAB. The SI 11.4 body paragraphs use the "Heading 2" style, so
    they show up as headings in the navigation pane and in style-based conversions.
  - **Action:** Delete the empty paragraphs and the manual break (use "page break before" on the heading).
    Fix the two indents. Reset SI 11.4 to the body style.

### Journal requirements (if the target is EHJ — the abstract headings follow EHJ's format)

- [ ] **MUST FIX — The abstract and main text are over the word limits**
  - **Problem:** The abstract is about 271 words (EHJ limit 250). The main text is about 5,300 words (limit
    5,000, excluding abstract, legends and references).
  - **Action:** Cut about 25 words from the abstract and about 300 from the body. Moving Methods detail into the
    SI is the easiest route.
- [ ] **MUST FIX — There is no Structured Graphical Abstract**
  - **Problem:** EHJ requires one for clinical research articles.
  - **Action:** Prepare one; Figure 1 is a good starting point.
- [ ] **MUST FIX — There are no line or page numbers**
  - **Problem:** The DOCX has neither. EHJ requires both.
  - **Action:** Add continuous line numbering and page numbers.

---

### Highest-priority pre-submission fixes

- [ ] Fix the UKB-PPP ancestry description and decide how to present IL-1β (European-only data: P = 0.14).
- [ ] Reframe the CAD robustness: report Q, show that the lead variant alone gives OR 1.05, and soften
  "robustness".
- [ ] Remove the "single shared signal" claim from Results 4.1.
- [ ] Add the sensitivity and positive-control analyses to the Methods.
- [ ] Add the ethics statement, UK Biobank application number and acknowledgements; fix the Data availability
  statement and push the final code.
- [ ] Correct the Fig 3C/ST04 sample sizes and the NCT06097663 tense.

### Could not be fully verified

- [ ] Verify the 1,821 effective protein tests. The number is hard-coded, and recomputing it needs
  individual-level UKB-PPP data; 09b documents the method. It sets the proteome threshold (27 lower / 7 higher
  proteins).
- [ ] Confirm the target journal. The word-limit, graphical-abstract and line-number items assume EHJ.
- [ ] Check All of Us publication rules for the extract your coworker supplied (required acknowledgement wording
  and any notification step).
