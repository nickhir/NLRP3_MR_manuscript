# Pre-submission audit, combined report: NLRP3 cis-MR manuscript, *European Heart Journal* (Clinical Research)

**Source:** two independent reviews, Claude (v2) and codex (v2), merged and deduplicated on 24 September 2026.
- Items that both reviews found independently are marked **(both)**. About half of the typos (16 of 32) were also found by both; typo lines are not marked individually.
- Every item found only by codex was checked again at source before inclusion. Claude-only items carry over from the Claude review, which verified them at source.

**What was reviewed:**
- `NLRP3_manuscript_WIP.docx` / `.pdf` and `SuppTables_completed_DRAFT.xlsx`, unchanged since the reviews.
- Code and outputs via a snapshot taken on 23 Sep at 18:40, identical to the current `results/`.

**Supporting files:**
- Working logs: `manuscript_review_working_claude_v2.md`, `manuscript_review_working_codex_v2.md`.
- EHJ rules (the rule IDs below): `trashtmp/ehj_author_guidelines_checklist_claude.md`. Codex's list is `trashtmp/ehj_author_guidelines_checklist.md`.
- Benchmarks: `trashtmp/ehj_mr_benchmark_claude.md`, `trashtmp/ehj_mr_benchmark.md`.
- Original single-review reports: `manuscript_review_claude_v2.md`, `manuscript_review_final_codex_v2.md`.

**How to read the items:**
- Line numbers are the ones printed in `NLRP3_manuscript_WIP.pdf` (continuous 1–708 on pp. 1–27). The reference pages (pp. 28–32) have no line numbers, so references are cited by number (ref N). "SI" marks lines in the Supplementary Information part of the same PDF.
- Each item gives **P** (problem), **W** (why it matters), **N** (EHJ norm) and **A** (action).
- Quoted text is the proposed manuscript wording. "[ref]" marks a new or renumbered citation.
- No item is **CRITICAL**: nothing overturns the CAD or mediation conclusions.
- EHJ format rules, typos and consistency points are collected in their own sections. The rule-based disclosure item (lines 495–496) also appears under Declarations.

---

## Highest-priority pre-submission fixes

- [ ] **MAJOR:**
  - lines 351–352 RA estimate.
  - Fig 3E vs the joint model.
  - lines 362–363 rs12239046 Wald ratio and label.
  - lines 455–457 pleiotropy rebuttal.
  - Cochran's Q (line 175).
  - Short additions: the MI null (lines 376–377), UK Biobank overlap (lines 451–473), COLCOT/colchicine (lines 51–56, lines 393–402), T2D (lines 409–411, lines 441–450).
  - Clinical take-home (lines 39–42, lines 391–392).
  - Novelty and prior genetic evidence (lines 78–80).
  - Pericarditis variants and proxy (lines 168–180/lines 248–254, ST15).
  - Disclosure of interest (lines 495–496).
  - SI lines 705–707 RA rationale.
  - lines 420–421 TET2 subgroup.
- [ ] **MUST FIX:**
  - EHJ package: SGA, keywords, corresponding author, AI disclosure, alt text, legend order, separate supplement, page numbers.
  - pLOF window ±110 kb.
  - lines 139–141 selection rule.
  - Oxford (-ize) spelling throughout.

---

## Title page and Abstract

- [x] **MAJOR — lines 39–42, the Conclusions undersell the paper.**
  - **P:** They end on a caveat. The take-home appears only in lines 414–415 and lines 478–479.
  - **W:** Editors read this first.
  - **N:** Not a reporting-norm issue. The SGA Take-home Message (R4.2) needs this point anyway. EHJ Conclusions are short plain sentences (median 2 sentences, 30 words). None of 37 in the benchmark papers uses a semicolon or tells trials what they "should" do. The EHJ form is "These findings highlight the need for …" (e.g. PMC10499547).
  - **A:** Replace lines 39–42 with:
    > "Lifelong lower genetically proxied NLRP3 activity was associated with higher CAD risk, largely through adverse cardiometabolic effects. These findings provide no genetic support for cardioprotection from lower NLRP3 activity and highlight the need to monitor blood pressure, lipids, and glycaemia in trials of NLRP3 inhibitors."

    The lifelong-vs-drug caveat stays in lines 457–461, 476–478.

## Introduction

- [x] **MAJOR — lines 78–80 states neither novelty nor prior genetic evidence.**
  - **P:** Schunk et al. (EHJ 2021, ref 53) appears only in lines 429–440. The reason for a composite score appears only in lines 271–273 and lines 381–383.
  - **W:** Novelty drives editorial triage. **N:** Not a reporting-norm issue.
  - **A:** Replace lines 78–80 and offset it by deleting lines 441–443, which repeat lines 369–373 and lines 389–390:
    > "Human genetic evidence on NLRP3 is limited. A study based on a single *NLRP3* expression variant linked higher NLRP3 activity to higher cardiovascular mortality [ref: Schunk]. Because no single biomarker captures NLRP3 activity, we combined variant effects on *NLRP3* expression and downstream inflammatory biomarkers into an NLRP3 activity score, validated it against IL-1β and IL-18, and used drug-target MR to test its association with CAD, the pathways involved, and diseases for which NLRP3 inhibitors have been or are being evaluated."
    - EHJ practice: Introductions end with a "we … to test" aim sentence like this one (e.g. PMC6945523). Colons appear in only 5 of 37 Introductions, and then only before a list.
- [ ] **MAJOR — lines 51–56/lines 393–402, colchicine is framed selectively.**
  - **P:**
    - lines 51–56 contrasts LoDoCo2 with CLEAR-SYNERGY to argue that benefit depends on clinical context. It omits COLCOT (benefit after MI), which ref 4 calls the most comparable trial.
    - The paper never says that colchicine acts partly through NLRP3 (ref 53).
  - **W:** This is a cardiologist reviewer's first question. **N:** Not a reporting-norm issue.
  - **A:**
    - lines 52–53: "…with benefit in COLCOT [ref: Tardif, *N Engl J Med* 2019;381:2497–505] (recent myocardial infarction) and LoDoCo2³ (chronic coronary disease) but not in CLEAR-SYNERGY⁴ (acute myocardial infarction)". Then soften "and the clinical context" in lines 55–56, since COLCOT and CLEAR-SYNERGY enrolled similar patients.
    - lines 393–402, add: "Colchicine, which inhibits NLRP3 inflammasome activation among broader anti-inflammatory effects⁵³, reduced cardiovascular events in COLCOT [ref] and LoDoCo2³. This may reflect actions beyond NLRP3 or short-term effects not captured by lifelong genetic variation."
    - Alternative that also answers Ziad Mallat's first-draft comment: cite the EHJ meta-analysis of six colchicine trials (Samuel M et al., *Eur Heart J* 2025;46:2552–63), which covers COLCOT, LoDoCo2 and CLEAR-SYNERGY. See the co-author section.
- [ ] **MUST FIX — lines 53–54/lines 398–399, ZEUS is overstated.**
  - **P:** The claim rests on top-line results (ref 5 is a commentary), from a population with ASCVD, CKD and high hsCRP.
  - **W:** It reads as a general IL-6 null. **N:** Not a reporting-norm issue.
  - **A:**
    - lines 48, 53–54: define "high-sensitivity C-reactive protein (hsCRP)" at first use, then write "Recently, in top-line results, the phase 3 ZEUS trial of interleukin-6 (IL-6) inhibition in patients with atherosclerotic disease, chronic kidney disease, and elevated hsCRP found no reduction in cardiovascular events⁵."
    - lines 398–399: add the same population and "top-line".
    - Replace ref 5, a commentary, until the primary paper appears. There is none yet; results are due at the AHA Late-Breaking Science session on 7 Nov 2026. Cite instead:
      - the Novo Nordisk company announcement No 45/2026 (31 Jul 2026; MACE HR 0.99, 95% CI 0.88–1.11), as a web reference with access date (R10.10)
      - the design paper: Ridker PM et al., *JAMA Cardiol* 2026;11:89–97, doi 10.1001/jamacardio.2025.4491.

## Methods

- [ ] **MUST FIX — lines 99, 101–104, data sources.**
  - **P:**
    - The immunoturbidimetry clause applies only to the UK Biobank part.
    - "meta-analysis including 519,288 individuals": the meta-analysis had 746,667 participants; 519,288 is the European subset.
  - **W:** Both are factual errors. **N:** Not a reporting-norm issue.
  - **A:** Delete the assay clause. Write "Neutrophil count summary statistics were obtained from 519,288 European-ancestry participants of a multi-ancestry blood-cell trait meta-analysis, in which counts were measured by automated haematology analysers in contributing cohorts¹⁶."
- [ ] **MUST FIX — lines 117–118, FinnGen release.**
  - **P:** The counts are from release 12 (I9_CORATHER); ref 22 describes release 5.
  - **W:** The source is untraceable. **N:** Not a reporting-norm issue.
  - **A:** "…FinnGen (release 12)…".
- [ ] **MUST FIX — lines 131–132, mediator selection.**
  - **P:** "Those showing evidence of association were carried forward", but only 3 of 7 were. DBP's exclusion is unexplained.
  - **W:** The text doesn't match the analysis. **N:** Not a reporting-norm issue.
  - **A:** "…and a subset was carried forward to the mediation analysis described below." EHJ papers never cross-reference numbered sections (0 of 38), so this wording avoids one. Add to lines 191–196 why SBP, not DBP, was used as the blood pressure mediator (authors to supply the reason).
- [ ] **MUST FIX — lines 139–141, selection rule (both).**
  - **P:** The code applies the "≥2 traits" rule to merged signal blocks. rs74154640 is genome-wide significant for CRP only (ST05). Ten signals became 8 because 2 were missing from some datasets. The Supp Fig 1 caption says "variants" where it counts signals.
  - **W:** A reader can't reconcile the 10 signals with the 8 instruments. **N:** Not a reporting-norm issue.
  - **A:** "…retained independent signals associated at genome-wide significance with at least two traits and available in all datasets, yielding eight variants". Supp Fig 1 caption: count "signals", not "variants", and add "Ten signals were associated with at least two traits. The eight with effect estimates in all four datasets were used as instruments."
- [ ] **MUST FIX — line 142/lines 275–276/SI lines 644–645, PCA depends on allele coding.**
  - **P:** Centred PCA of signed effects gives PC1 86.8–98.5% depending on the arbitrary effect-allele coding. Uncentred PCA gives 97.1% for any coding, and the per-variant score effects change by <0.1%.
  - **W:** A reviewer reproducing the score gets a different number. **N:** Not a reporting-norm issue.
  - **A:** Use `center = FALSE` and report 97.1% in line 276. Change line 142 "were centred and scaled" to "were scaled (not centred)", and SI lines 644–645 to "scaled to unit root mean square, without centring". Otherwise, keep centring and state the allele coding in the SI.
- [ ] **MAJOR — line 175, Cochran's Q claimed but not reported.**
  - **P:** The values exist but are not shown:
    - CAD: Q 13.9 on 7 df, *P* = 0.053
    - CRP: *P* = 0.004
    - neutrophil count: *P* = 2×10⁻⁵
    - SBP / ApoB / T2D: *P* 0.93 / 0.94 / 0.68
    - MVMR: Q/df ≈ 16
    - IL1Ra protein: Q 54.5 on 2 df.
  - **W:** A stated method with no result, and the lines 455–457 fix depends on it.
  - **N:** Reported in 8 of 31 applicable EHJ MR papers (a minority). The reason to act is the Methods claim.
  - **A:**
    - Add Cochran's Q columns to ST06–ST09, ST11 and ST14.
    - Add MR-Egger intercept columns to ST08.
    - Footnote ST11: the IL1Ra Q is high, but random-effects IVW gives *P* = 1×10⁻¹⁰.
- [ ] **MUST FIX — "shared colocalising variant (rs12239046)" (lines 176–177, lines 362–363, Supp Fig 4, ST14 R32) (both).**
  - **P:** The HyPrColoc candidate is rs58546652; rs12239046 is its proxy (r² 0.98).
  - **W:** It mislabels the result. **N:** Not a reporting-norm issue.
  - **A:** lines 176–177: "…estimated a Wald ratio using only rs12239046, which tags the colocalizing signal (*r*² = 0.98 with the HyPrColoc candidate rs58546652)". Relabel the others to match.
- [ ] **MUST FIX — lines 178–179, reporting scales.**
  - **P:** Proportional odds ratios for the ordinal imaging outcomes (lines 303–305, Fig 3 legend) are not in the Methods.
  - **W:** The Methods are incomplete. **N:** Not a reporting-norm issue.
  - **A:** "Estimates are reported as betas for continuous outcomes, odds ratios (ORs) for binary outcomes, and proportional odds ratios for ordinal outcomes, with 95% confidence intervals (CIs)." This also defines OR and CI (EHJ compliance, abbreviations).
- [ ] **MAJOR — lines 168–180/lines 248–254, ST15, Fig 5: missing and proxied outcome variants unexplained.**
  - **P:** ST15 shows 5 instruments for pericarditis (an Abstract result) and 6 for knee OA, with no explanation. One pericarditis variant is an LD proxy (r² 0.98), and the pericarditis SEs were derived from ORs and *P* values because the deCODE file has no SE. The only proxy rule in the paper (SI lines 635–636) covers instrument construction.
  - **W:** Transparency about a headline result. **N:** Not a reporting-norm issue.
  - **A:** Add to lines 168–180: "Missing outcome variants were omitted, except one pericarditis variant, which was replaced by an LD proxy (*r*² = 0.98; Supplementary data online, Table S15)." Add an ST15 footnote naming the missing and proxied variants and the SE derivation. Add the counts to the Fig 5 legend.
- [ ] **MUST FIX — lines 184–185/lines 238–240, ST06, ST12: assays chosen by smallest *P*.**
  - **P:** IL-6 has four Olink assays and the most significant is reported; the others give β −0.58 to −0.70, *P* ≤ 1.6×10⁻⁵. Six ST12 proteins are affected.
  - **W:** Undisclosed selection. **N:** Not a reporting-norm issue.
  - **A:** Add an ST06/ST12 footnote giving the rule and the IL-6 range.
- [ ] **MUST FIX — lines 199–203, 209–210, MVMR details.**
  - **P:** The instrument count (1,265) is missing. The MVMR package and conditional F need Sanderson, Spiller & Bowden, *Stat Med* 2021;40:5434–52.
  - **W:** A basic reporting item, and the wrong source is cited. **N:** Not a reporting-norm issue.
  - **A:** Add both.
- [ ] **MUST FIX — line 226, lines 338–339, Supp Fig 3 caption: pLOF window.**
  - **P:** The text says "within ±150 kb", but the pipeline uses ±110 kb (`01_identify_LOF_mutations.Rmd` l.95–101), so OR2G2 was not tested.
  - **W:** The Methods are wrong. **N:** Not a reporting-norm issue.
  - **A:** Change to "±110 kb" in all three places.
- [ ] **MUST FIX — lines 241–242/SI lines 683–684, test-count rule.**
  - **P:** The 95%-variance rule is Gao's simpleM at a non-default cut-off (the standard is 99.5%), but it is credited to ref 40.
  - **W:** A wrong citation. Plain Bonferroni over 2,922 tests still keeps 30 of 34 proteins, which pre-empts the question.
  - **N:** Not a reporting-norm issue (wrong citation). Multiple-testing correction is reported in 14 of 33 applicable EHJ MR papers.
  - **A:** In SI lines 683–684, cite Gao 2008 and write "95% (rather than the default 99.5%)". Add to the SI: "Bonferroni correction for 2,922 tests retained 30 of the 34 proteins."
## Results

- [ ] **MUST FIX — line 259/Fig 2A, tallest expression peak unexplained.**
  - **P:** Fig 2A shows unconditioned expression. Its tallest peak (rs6689545, *P* = 3.4×10⁻⁶⁹; CRP *P* = 0.04) is explained only in Methods lines 156–159 (conditioned out). line 259 names rs58546652 as the expression lead without mentioning it, and the caption does not mention it either.
  - **W:** It is the first thing a reader of Fig 2A will ask about. **N:** Not a reporting-norm issue.
  - **A:** Caption: "*NLRP3* expression is shown unconditioned. The upstream signal (rs6689545) was conditioned out before colocalization."
- [ ] **MUST FIX — lines 264–266 (method in lines 164–166), flank colocalization.**
  - **P:** lines 264–266 cites Supp Fig 2 for "no additional colocalising signals" between 200 kb and 1 Mb. The figure doesn't show this, and the result (regional probability ≤0.13) is reported nowhere.
  - **W:** An unsupported statement. **N:** Not a reporting-norm issue.
  - **A:** line 266: "(HyPrColoc regional probability ≤ 0.13; Supplementary data online, Figure S2)", or add the result to the Supp Fig 2 caption.
- [ ] **MAJOR — lines 321–323/Fig 3E, the figure shows different models from the text.**
  - **P:** Fig 3E comes from three nested, separately refitted MVMR models (833 / 876 / 1,265 variants), giving ΔOR 0.09 / 0.06 / 0.03. The text cites it for the joint-model indirect ORs 1.080 / 1.047 / 1.045, where ApoB ≈ T2D. The nested models are not in the Methods.
  - **W:** The key mechanism figure contradicts the text. **N:** Not a reporting-norm issue.
  - **A:** Redraw from the joint model: 1.21 → 1.12 → 1.07 → 1.03 (ΔOR 0.09 / 0.05 / 0.05, from unrounded ORs, so printed steps may differ by 0.01). Otherwise, label it "sequential, order-dependent", cite ST09 for the ORs, and add one Methods sentence.
- [ ] **MAJOR — lines 351–352, RA estimate out of date (both).**
  - **P:** The text says 0.26 (0.07 to 0.94), *P* = 0.04. The output, ST11 and Fig 4D say 0.22 (0.11 to 0.41), *P* = 3.3×10⁻⁶.
  - **W:** The text contradicts the figure it cites. **N:** Not a reporting-norm issue.
  - **A:** "(OR = 0.22, 95% CI 0.11–0.41, *P* = 3.3 × 10⁻⁶)". EHJ writes CIs with an en dash (see Consistency, CI).
- [ ] **MUST FIX — lines 357, 359, drug-effect wording.**
  - **P:** "The downregulated proteins" and "the seven proteins raised by inhibition" describe genetic associations as drug effects.
  - **W:** It contradicts the paper's own caveat. **N:** Not a reporting-norm issue.
  - **A:** "the 27 proteins with lower levels" and "the seven proteins with higher levels".
- [ ] **MAJOR — lines 361–363/line 366, colocalising-variant result not given.**
  - **P:**
    - The rs12239046 Wald ratio, OR 1.05 (0.89 to 1.23), *P* = 0.58, is given without its numbers.
    - Leave-one-out: all ORs > 1, but 4 of 8 have *P* 0.053–0.063.
    - The r² sweep is consistently significant (ORs 1.16–1.22, *P* ≤ 0.032).
  - **W:** Better disclosed than found by a reviewer, and the r² sweep helps the paper.
  - **N:** Leave-one-out is reported in 7 of 30 applicable EHJ MR papers; the issue here is accuracy.
  - **A:** lines 361–363: "…consistent across LD clumping thresholds (ORs 1.16–1.22), directionally consistent in leave-one-out analyses, and attenuated when restricted to rs12239046, which tags the colocalizing signal (OR = 1.05, 95% CI 0.89–1.23)".
- [ ] **MUST FIX — lines 373–374, RA called "suggestive" at *P* = 0.14.**
  - **P:** Other borderline results (knee OA weighted median *P* 0.027) are not singled out.
  - **W:** It reads as selective emphasis. **N:** Not a reporting-norm issue.
  - **A:** Delete the sentence.
- [ ] **MAJOR — lines 376–377/Fig 5, null MI estimate not mentioned.**
  - **P:** MI in MVP gives OR 1.01 (0.70 to 1.45), shown under "Cardiovascular". It is compatible with the CAD estimate (difference *P* = 0.36).
  - **W:** An unexplained null next to the headline invites doubt. **N:** Not a reporting-norm issue.
  - **A:** lines 376–377: "No clear associations were observed for the other indications examined, including myocardial infarction (OR = 1.01, 95% CI 0.70–1.45), whose wide interval is compatible with the CAD estimate (Supplementary data online, Tables S15 and S16)." This also cites ST16 (EHJ compliance).

## Discussion

- [ ] **MUST FIX — line 389/line 405, mediation overstated.**
  - **P:** "Almost all" (line 405) and "no evidence of a residual direct association" (line 389), against 87% and "little evidence" in the Results.
  - **W:** Overclaim. **N:** Not a reporting-norm issue.
  - **A:**
    - Change to "most (an estimated 87%)" and "little evidence".
    - Replace the last sentence (lines 391–392) with "Overall, our data provide no genetic support for cardioprotection from lower NLRP3 activity. Trials of NLRP3 inhibitors should monitor blood pressure, lipids, and glycaemia." (EHJ Discussions use this "trials should" phrasing, e.g. PMC7982288.)
    - Delete the last sentence (lines 414–415), which then duplicates it.
- [ ] **MAJOR — lines 409–411/lines 441–450, the T2D finding gets one-sided support.**
  - **P:**
    - T2D (OR 1.26, *P* = 0.002) accounts for 22.7% of the total CAD association (ST09). It is the only trial indication where the genetics points against benefit, yet dapansutrile is in a phase 2 T2D trial (NCT06047262, ST16).
    - lines 403–415's only support is IL-18-knockout mice (ref 49), whose insulin resistance was mainly secondary to hyperphagic obesity. The score shows no BMI association (β −0.03, *P* = 0.41).
    - Not mentioned: NLRP3-deficient mice are protected from diet-induced insulin resistance, and canakinumab did not reduce incident diabetes in CANTOS.
  - **W:** A metabolic reviewer will see selective support for a key mediator, and trialists need the implication. **N:** Not a reporting-norm issue.
  - **A:**
    - lines 409–411: replace the IL-18 sentence with "The T2D association was less expected. NLRP3 deficiency protects mice against diet-induced insulin resistance [ref: Vandanmagsar, *Nat Med* 2011], canakinumab did not reduce incident diabetes [ref: Everett, *J Am Coll Cardiol* 2018], and we found no association with BMI."
    - lines 441–450: add "The higher T2D risk with lower genetically proxied NLRP3 activity is relevant to a phase 2 trial of dapansutrile in T2D (NCT06047262), in which glycaemic effects need close attention."
    - Shorten the last sentence (lines 449–450) to "These exploratory associations require replication."
- [ ] **MAJOR — lines 420–421, TET2 subgroup (both).**
  - **P:** "A greater reduction", but the interaction *P* was 0.14 (ref 52: "equivocal").
  - **W:** Overclaim. **N:** Not a reporting-norm issue.
  - **A:** "a numerically greater reduction".
- [ ] **MAJOR — lines 455–457, the pleiotropy rebuttal is a non sequitur.**
  - **P:** Rare variants were tested only for CRP, GlycA and neutrophils, so they say nothing about pleiotropy for SBP, ApoB or T2D. The data that do are unreported and supportive:
    - Q *P* 0.93 / 0.94 / 0.68
    - MR-Egger intercept *P* 0.22 / 0.81 / 0.13
    - CAD intercept null at r² 0.2–0.6 (*P* 0.20–0.86).
  - **W:** A statistical reviewer will notice, and the real evidence helps the paper.
  - **N:** Not a reporting-norm issue (the argument does not follow). Pleiotropy is acknowledged as a limitation in 28 of 33 EHJ MR papers.
  - **A:** Replace the "However, rare…" sentence with the text below, and add the columns named in the line 175 item:
    > "However, variant effects on SBP, ApoB, and T2D were homogeneous (Cochran's Q *P* ≥ 0.68) with null MR-Egger intercepts, and the CAD intercept was null at relaxed clumping thresholds (Supplementary data online, Tables S8 and S14), consistent with a shared pathway."
- [ ] **MAJOR — lines 451–473, exposure–outcome sample overlap not discussed.**
  - **P:** UK Biobank is in the biomarker GWAS and in the Aragam CAD GWAS. "No sample overlap" is stated only for SCAPIS (line 124).
  - **W:** A standard reviewer question, and the answer favours the paper.
  - **N:** Discussed in 17 of 29 applicable EHJ MR papers (the majority).
  - **A:** Add: "UK Biobank contributed to both the exposure and the CAD GWAS. With strong instruments (F = 92), any resulting bias is small and would act against our finding." (Same structure as EHJ overlap statements, e.g. PMC7544540.)

## Declarations and end matter

- [ ] **MAJOR — lines 495–496, disclosure of interest incomplete.**
  - **P:** It covers only N.H., S.B. and D.S.P.: nothing for A.S.B., and nothing for the remaining authors.
  - **W:** AstraZeneca relationships matter for an NLRP3 paper.
  - **N:** EHJ rule R14.5–R14.7.
  - **A:** Add A.S.B.'s statement, then close with "All other authors declare no disclosure of interest for this contribution." That is the wording in recent EHJ papers (e.g. PMC10906986, PMC12461605); none of the 50 papers uses "none declared" after named disclosures.
- [ ] **MUST FIX — lines 502–503, the code claim isn't true yet.**
  - **P:** The public repository lacks 09b, the table builder, some figure scripts, and all rare-variant and trial-search code. The local unpushed commit also contains the manuscript and review files; don't push it as is.
  - **W:** The availability claim is false. **N:** Not a reporting-norm issue.
  - **A:** Push the complete final code with a README. Keep the code link inside Data availability as a plain GitHub URL, as EHJ papers do (e.g. PMC12461605, PMC10906986; none gives code its own section or a Zenodo DOI). If the RAP scripts stay unpublished, write "…available at https://github.com/nickhir/NLRP3_MR_manuscript (summary-statistic analyses and figures)."

## References

- [ ] **MUST FIX — incomplete or wrong entries (ref 52: both).**
  - **P:**
    - Ref 52 lacks its subtitle ("…: An Exploratory Analysis of the CANTOS Randomized Clinical Trial").
    - Ref 9 prints "Ho Park K" for Ki Ho Park; it should be "Park KH". Fix the reference-manager record, because a PubMed re-import brings the error back.
    - Ref 56 omits the group author GP2.
    - ST01 "Sun B" and "Chen MH" vs refs "Sun BB" and "Chen M-H".
    - The ST02 All of Us PMID/DOI cell reads "NA", although ref 21 has a DOI.
  - **W:** Citation accuracy. **N:** Not a reporting-norm issue.
  - **A:** Correct each.
## Figures

- [ ] **MUST FIX — Fig 1.**
  - **P:** The title "Causal Effects on CAD" contradicts the paper's association wording. Pericarditis is in the caption but not in the graphic.
  - **W:** Overclaim, and the caption doesn't match the figure. **N:** Not a reporting-norm issue.
  - **A:** "Associations with CAD"; add the icon or remove the word.
- [ ] **MUST FIX — Fig 2 (both).**
  - **P:**
    - 2A: the index marker, dashed line, grey NA and recombination line are unexplained.
    - 2B: ticks sit at unrounded positions (up to 9% off); units and error bars are undefined.
    - 2C: the IL-1β upper CI prints "−0.00".
  - **W:** Misleading or unreadable in places. **N:** Not a reporting-norm issue.
  - **A:**
    - 2A: "Variants are colour coded by pairwise *r*² with rs12239046 (purple diamond). Grey indicates variants without linkage disequilibrium information. The dashed line represents the threshold for genome-wide significance (*P* = 5 × 10⁻⁸)." Also explain the recombination line. This follows EHJ legend wording ("colour coded based on pairwise r2 with rs1412444", PMC12461605; "dashed line represents the threshold for genome-wide significance", PMC10148738).
    - 2B: use round ticks. Add "Lines represent 95% confidence intervals." (the usual EHJ legend wording, e.g. PMC10148738, PMC11212828) and each panel's unit, or add a Units column to ST05 and cite it.
    - 2C: print 3 decimals.
- [ ] **MUST FIX — Fig 3.**
  - **P:**
    - The legend doesn't say that red = IVW, blue = weighted median, and bars are 95% CIs.
    - The 3C "β" header covers log-OR rows (T2D shows 0.23 against OR 1.26 in the text).
    - The Lp(a) upper CI prints "−0.00".
  - **W:** Values are misread. **N:** Not a reporting-norm issue.
  - **A:** Add to the legend "Points represent inverse-variance weighted (red) and weighted median (blue) estimates, and lines represent 95% confidence intervals." (EHJ pattern: "points represent the odds ratios (ORs) and lines represent 95% confidence intervals", PMC10148738; colours are named in legends in 27 of 37 papers.) Mark the log-OR rows or plot them as ORs; print more decimals.
- [ ] **MUST FIX — Fig 4 (4C: both).**
  - **P:**
    - 4C: the allele shown, the error bars and the units are undefined.
    - 4E: the key reads "Adj. P-value", while the legend says "adjusted P value". The legend gives no test, correction or input number.
  - **W:** Readers can't interpret 4C. **N:** Not a reporting-norm issue.
  - **A:** Define the 4C elements ("Lines represent 95% confidence intervals", plus the allele shown and the units). 4E: use "Adjusted *P*-value" and write "Over-representation analysis of the 27 proteins lower with a lower genetically proxied NLRP3 activity score, using a one-sided hypergeometric test against the 2,745 of 2,922 tested proteins with a Gene Ontology Biological Process annotation. *P*-values were adjusted by the Benjamini–Hochberg method.".
- [ ] **MUST FIX — Fig 5.**
  - **P:** The arrowheads are unexplained.
  - **W:** Incomplete legend. **N:** Not a reporting-norm issue.
  - **A:** Add "Arrows indicate confidence intervals that extend beyond the axis limits."
- [ ] **MUST FIX — Supp Fig 1, stale render.**
  - **P:** The embedded image is older than `figures_out`.
  - **W:** It is not the current figure. **N:** Not a reporting-norm issue.
  - **A:** Re-embed the current vector, `figures_out/SupFig1_variant_overlap.pdf`. This also fixes the 300-ppi raster (EHJ compliance, figure format).
- [ ] **MUST FIX — Supp Fig 2, undisclosed point thinning.**
  - **P:** A random ~75% of the non-significant neutrophil variants that lack LD data (grey points) are not plotted. The "Index SNP" key has no symbol.
  - **W:** Figure integrity. **N:** Not a reporting-norm issue.
  - **A:** Plot all points, or state in the legend "For clarity, a random 25% of non-significant neutrophil-count variants without linkage disequilibrium information are shown." Fix the key. Add to lines 595–601 the same colour and dashed-line sentences as for Fig 2A.

## Supplementary Information and Tables

- [ ] **MUST FIX — SI lines 627–628, 636, procedure misdescribed.**
  - **P:**
    - Proxies within 0.05 r² of the best are tied and chosen by lowest CRP *P*, not "highest LD" (chosen proxy r² 0.911 vs best 0.920).
    - The frequency filter used only the neutrophil GWAS and dropped all indels, including 16 genome-wide significant CRP indels.
  - **W:** Not reproducible as written. **N:** Not a reporting-norm issue.
  - **A:** Describe both as coded.
- [ ] **MUST FIX — SI line 656, orientation.**
  - **P:** Scores are oriented to target-gene expression, not CRP; the two are opposite for IL1Ra.
  - **W:** Wrong for the positive control. **N:** Not a reporting-norm issue.
  - **A:** "oriented to lower target-gene expression".
- [ ] **MUST FIX — SI lines 679–680, covariates.**
  - **P:** Age² and age²×sex are missing (SI line 670 lists them), and the European-only restriction is unstated.
  - **W:** Incomplete Methods. **N:** Not a reporting-norm issue.
  - **A:** Add both.
- [ ] **MUST FIX — SI lines 690–692 and ST13.**
  - **P:**
    - 10 MSigDB Hallmark rows are undescribed.
    - The GO:BP background is effectively 2,745.
    - The adjusted-*P* < 0.5 display filter is unstated.
    - The Description column repeats Term ID.
  - **W:** The table doesn't match the Methods. **N:** Not a reporting-norm issue.
  - **A:** Describe or delete the Hallmark rows; add "(2,745 with a GO:BP annotation)"; state the filter; add the term names.
- [ ] **MUST FIX — SI lines 694–708 styled Heading 2.**
  - **P:** Body text is formatted as a heading, so citation 65 prints bold.
  - **W:** Visible formatting error. **N:** Not a reporting-norm issue.
  - **A:** Apply the Normal style.
- [ ] **MAJOR — SI lines 705–707, RA rationale (both).**
  - **P:** "A Phase II trial that was terminated due to off-target hepatotoxicity rather than lack of efficacy" goes beyond ref 65, which reports only raised liver enzymes of unclear cause.
  - **W:** It is the only stated reason for including RA, and the citation does not support it. **N:** Not a reporting-norm issue.
  - **A:** "…a selective NLRP3 inhibitor (MCC950/CP-456773) was evaluated in a phase 2 trial but was not developed further after it raised serum liver enzyme levels⁶⁵".
- [ ] **MUST FIX — ST01, positive-control sources.**
  - **P:** There is no row for the IL1Ra protein GWAS (UKB-PPP, n = 50,898). The eQTL row reads "NLRP3 eQTLs" but also supplied the IL1RN eQTLs. The main text never points to either source.
  - **W:** Data source undocumented. **N:** Not a reporting-norm issue.
  - **A:** Add the row. Relabel as "Whole-blood *cis*-expression quantitative trait loci (eQTLs) for *NLRP3* and *IL1RN*". In line 150, add "(Supplementary data online, Tables S1 and S3)" after "gout and rheumatoid arthritis".
- [ ] **MUST FIX — ST07.**
  - **P:** R12–R13 "excl. 1_247460342_C_G" duplicate the rs188628429 leave-one-out estimate (ST14 R30–R31). R14 shows an MR-Egger slope, which lines 173–174 says is not used.
  - **W:** Redundant and contradictory rows. **N:** Not a reporting-norm issue.
  - **A:** Delete R12–R13. R14 is the only row with the CAD MR-Egger intercept (0.0089, *P* = 0.018) that lines 297–299 cites. Either move the intercept into the IVW meta-analysis row R10 (columns J–K, as in ST06 and ST14) and then delete R14, or keep R14 with a footnote that the slope is not used as an estimator.
- [ ] **MUST FIX — ST08, no Scale column.**
  - **P:** ORs (T2D, smoking) and SD betas share one column.
  - **W:** Values are misread. **N:** Not a reporting-norm issue.
  - **A:** Add a Scale column, as in ST07.
- [ ] **MUST FIX — ST12, "IVW P Bonferroni".**
  - **P:** The column is *P* × 1,821, not × 2,922, and doesn't say so.
  - **W:** Readers can't tell what the correction is. **N:** Not a reporting-norm issue.
  - **A:** "IVW *P* × 1,821 (capped at 1)".
- [ ] **MUST FIX — ST14, duplicate rows.**
  - **P:** The "All instruments" rows duplicate the primary r² < 0.1 rows.
  - **W:** Redundant. **N:** Not a reporting-norm issue.
  - **A:** Keep one set: "All 8 instruments (primary)".
- [ ] **MUST FIX — ST16, COPD trial ID.**
  - **P:** "CTIS 2021-000558-25" is a EudraCT number.
  - **W:** Wrong registry label. **N:** Not a reporting-norm issue.
  - **A:** "EudraCT 2021-000558-25".
- [ ] **MUST FIX — all sheets, display.**
  - **P:**
    - PMIDs show as "35,459,240".
    - CIs drop trailing zeros ("(1.04, 1.7)", from `ci()` in `build_supplementary_tables.R`).
    - *P* is in E-notation even for 0.816.
    - There are no scale, direction or abbreviation notes.
  - **W:** Hard to read or misleading. **N:** Not a reporting-norm issue.
  - **A:** Format PMIDs as text; keep trailing zeros; show decimal *P* ≥ 0.001. Add a notes block to Contents that also expands the abbreviations the workbook never defines: SIS and CTA (ST07!A17:A18), UKIBDGC/IIBDGC (ST03!C16), NMR (ST01!C4, ST04!C4), UKB (ST04!A5) and EF (ST03!A7, ST15!A12:A13; in the manuscript EF is defined only in the Fig 5 legend).

---

## Typos (all MUST FIX)

**Main text and SI**
- [ ] line 155: "blood neutrophil count , using" → "blood neutrophil count, using"
- [ ] line 162: "prior.c = 0.02. Evidence" → "prior.c = 0.02). Evidence"
- [ ] line 179: "MendelianRandomization²⁸  (version" → single space
- [ ] line 229: "*NLRP3* Predicted Gain-of-Function Analysis" → "*NLRP3* gain-of-function analysis" (line 230: these are known pathogenic variants)
- [ ] line 231: "Cosson et al. ³⁹" → "Cosson et al.³⁹"
- [ ] lines 235–236: "Supplementary Information″." → "Supplementary Information."
- [ ] line 250: "on the 28 of April 2026" → "on 28 April 2026"
- [ ] line 267: "support coherent NLRP3-linked inflammatory signal" → "support a coherent NLRP3-linked inflammatory signal"
- [ ] lines 333–335: "pLOF variants in NLRP3 were associated with significantly lower CRP … than non-carriers" → "Carriers of pLOF variants in NLRP3 had significantly lower CRP … than non-carriers"
- [ ] line 337: "higher GlycA and neutrophil levels" → "higher GlycA concentrations and neutrophil counts"
- [ ] line 356: "after multiple-testing" → "after correction for multiple testing" (EHJ: "after correction for multiple comparisons", PMC6837161; "multiple-testing correction" occurs in none of the 38 papers)
- [ ] line 436: "…reference panel and was additionally associated" → "…reference panel, and was additionally associated"
- [ ] line 496: "during the duration of this work" → "during this work"
- [ ] Fig 2 legend, lines 536–537: "PC1, principal component" → "PC1, first principal component"
- [ ] SI lines 632–633: "Components represented in…" / "For each retained component" → "Merged blocks represented in…" / "For each retained block"
- [ ] SI line 675: "recruitment centre" → "assessment centre" (the same covariate is named both ways)
- [ ] SI line 696: "on the 28th of April 2026" → "on 28 April 2026"

**Figures**
- [ ] Fig 2A and Supp Fig 2 y-axes: "−log10(P − value)" → "−log₁₀(*P*)" (`fig02a_locuszoom.R:180`, `fig_s2_regional_plots.R:117`)
- [ ] Fig 4E: "Complement Activation Alternative Pathway" → "Complement activation, alternative pathway"
- [ ] Fig 4E: "Acute Phase Response" → "Acute-phase response"
- [ ] Fig 4E: "Defense Response To Symbiont" / "…To Other Organism" → "Defense response to symbiont" / "…to other organism"

**References**
- [ ] Ref 13: "Lp-PLA2" → "Lp-PLA₂"
- [ ] Ref 16: "1198-1213.e14" → "1198–1213.e14"
- [ ] Ref 61: "1415-1429.e19" → "1415–1429.e19"
- [ ] Ref 43: "Jansen TLThA" → "Jansen TLTA"

**Supplementary tables**
- [ ] ST01 A4: "Glycoprotein Acetyl concentration" → "Glycoprotein acetylation (GlycA)"
- [ ] ST03 C12: "International Parkinson Disease Genomics Consortium" → "International Parkinson's Disease Genomics Consortium"
- [ ] ST04 A2: "Low density" → "Low-density"
- [ ] ST04 A11: "Body Mass Index (BMI)" → "Body mass index (BMI)"
- [ ] ST04 G11: "10.5281/zenodo.1251813" → "https://doi.org/10.5281/zenodo.1251813"
- [ ] ST09 A3–A5: "Indirect via Systolic blood pressure / Apolipoprotein B / Type 2 diabetes" → lower case after "via"
- [ ] ST12: "Protein Id" → "Protein ID"

---

## EHJ guideline compliance

Rule IDs are from `ehj_author_guidelines_checklist_claude.md`. For every item, the problem is a breach of an EHJ rule, and the editorial office can return a submission for that. Items marked "at revision" bind only then (R16.1 allows a format-free first submission).

- [ ] **MUST FIX — Structured Graphical Abstract missing (both).**
  - **EHJ rule:** R4.1–R4.9 (present in 22 of 24 EHJ papers from 2024–26).
  - **Location:** Absent.
  - **Action:** Add an 11 × 18 cm graphic and three text fields of ≤40 words. Draft:
    - *Key Question:* "Does lower genetically proxied NLRP3 activity, mimicking NLRP3 inhibition, reduce coronary artery disease (CAD) risk?"
    - *Key Finding:* "A genetic score for lower NLRP3 activity was associated with lower IL-1β and IL-18 but higher CAD risk (OR 1.21), an estimated 87% mediated by higher blood pressure, apolipoprotein B, and type 2 diabetes risk."
    - *Take-home Message:* "Human genetic evidence does not support cardioprotection from lower NLRP3 activity and highlights the need to monitor blood pressure, lipids, and glycaemia in trials of NLRP3 inhibitors."
    - EHJ practice: Key Question is phrased as a question, and Take-home is plain sentences without semicolons (the only text-readable SGA in the benchmark, PMC11842968). Most SGAs are image-only, so there is little other evidence.
- [ ] **MUST FIX — keywords missing (both).**
  - **EHJ rule:** R2.6.
  - **Location:** After the Abstract.
  - **Action:** Add up to 6, separated by commas as in all 37 benchmark papers, e.g. NLRP3 inflammasome, Mendelian randomization, Drug targets, Coronary artery disease, Inflammation, Cardiometabolic risk factors. "Mendelian randomization" is the most common EHJ MR keyword (19 of 37 papers), and "Drug targets" follows the drug-target MR paper PMC7982288. The closest EHJ paper uses "Cardiovascular diseases, Coronary artery disease, Inflammation, Inflammasome, NLRP3" (PMC8244638).
- [ ] **MUST FIX — corresponding author missing.**
  - **EHJ rule:** R2.1.
  - **Location:** Title page.
  - **Action:** Add postal address and email.
- [ ] **MUST FIX — AI-use disclosure missing.**
  - **EHJ rule:** R14.45 (cover letter AND Methods/Acknowledgements).
  - **Location:** Absent. The repository linked in line 503 shows 16 of 23 commits co-authored by Claude Opus 5 or Claude Sonnet 5.
  - **Action:** Template (authors to confirm the uses): "Claude Opus 5 and Claude Sonnet 5 (Anthropic) were used to assist with analysis and figure code. All outputs were checked by the authors, who take full responsibility for the content." Repeat in the cover letter. No benchmark paper has an AI statement yet (0 of 50), so there is no EHJ wording to copy.
- [ ] **MAJOR — disclosure of interest incomplete (see Declarations).**
  - **EHJ rule:** R14.5–R14.7.
  - **Location:** lines 495–496.
  - **Action:** See Declarations.
- [ ] **MUST FIX — sex/gender reporting missing.**
  - **EHJ rule:** R2.5 (abstract); R15.6–R15.8 (Methods, with rationale).
  - **Location:** Abstract Methods (lines 22–28) and Methods.
  - **Action:** Abstract: say the data are sex-combined. Methods: "All summary statistics were from sex-combined analyses of men and women. Sex-stratified analyses were not performed because sex-specific data were not available for most sources." (authors to confirm the reason). Published EHJ summary-statistics MR papers rarely include this (0 of 10 checked), but the rule is explicit and it costs one sentence.
- [ ] **MUST FIX — document order and packaging (legend order: both).**
  - **EHJ rule:** R5.1, R5.4, R8.1.
  - **Location:**
    - Legends sit under "12. Figures", interleaved with the images, before the References (lines 517–583).
    - The supplementary figures and SI are inside the main file (lines 584–708).
    - SI-only refs 59–65 are in the main list.
  - **Action:**
    - Now: move lines 584–708 to a separate file with its own references.
    - At revision at the latest (codex rated legend placement as waived for a format-free first submission): put the legends after the References under "Figure Legends".
- [ ] **MUST FIX — alt text missing (both).**
  - **EHJ rule:** R8.5.
  - **Location:** Fig 1–5 legends (lines 519–526, 528–537, 539–554, 556–575, 578–583).
  - **Action:** Add "Alt text: …" under each.
- [ ] **MUST FIX — page numbering (both).**
  - **EHJ rule:** R16.2.
  - **Location:** A section break restarts page numbering, so PDF pp. 28–32 read 1–5.
  - **Action:** Use a page break instead.
- [ ] **MUST FIX — legends missing n and definitions (both).**
  - **EHJ rule:** R8.2, R8.3.
  - **Location:**
    - No n: Fig 2A/2B, Supp Fig 2, Fig 4B, Fig 4C, Fig 4F and Supp Fig 4.
    - No test: Fig 4E (see Figures).
    - Defined nowhere: SD (Figs 2–4), OR (Figs 3–5), CI (Figs 2–5), ΔOR (Fig 3E), SNP and cM/Mb (Fig 2A, Supp Fig 2).
  - **Action:**
    - Fig 2A/2B, Supp Fig 2 and Fig 4C: add n, or "GWAS sample sizes are given in Supplementary data online, Table S1".
    - Fig 4F and Supp Fig 4: "CAD sample sizes are given in Figure 3A and Supplementary data online, Table S2".
    - Fig 4B: give the number of UK Biobank participants and of gain-of-function carriers.
    - Define the terms above in the legends that use them. EHJ legends routinely do this ("CI, confidence interval" in 21 of 37 papers), and 11 papers give sample sizes in legends.
- [ ] **MUST FIX — figure format (both).**
  - **EHJ rule:** R7.11, R7.14, R7.17, R7.22.
  - **Location:**
    - Fig 3 panels are shrunk to 74%, giving text of about 5 pt.
    - The Fig 2A and Supp Fig 2 LD keys are about 4.7 pt.
    - Embedded rasters: Fig 1 (300 ppi), Supp Fig 1 (300 ppi), Supp Fig 3 (187 ppi) and Supp Fig 4 (300 ppi). Graphs and diagrams should be vector; raster line art needs ≥600 dpi (R7.11).
  - **Action:**
    - Rebuild Fig 3 near 1:1 or split out D–E.
    - Enlarge both LD keys.
    - Embed the existing vector for Supp Fig 4 (`figures_out/SupFig_leave_one_out.pdf`), and for Supp Fig 1 (see Figures, stale render).
    - Supply Fig 1 and Supp Fig 3 as vector PDFs, or re-render them at ≥600 dpi from source (don't upscale).
    - File type and resolution bind at upload of the figure files and at revision (R16.2 allows embedded figures at first submission). The Fig 3 text size needs fixing now.
- [ ] **MUST FIX — figure accessibility.**
  - **EHJ rule:** R7.15: avoid pale colours and combinations that colour-blind readers struggle with. Details come from the OUP accessibility guidance (R7.21, R7.26): meaning is not carried by colour alone; contrast is at least 4.5:1 for text and 3:1 for marks.
  - **Location:**
    - IVW and weighted median differ only in colour (#C0392B vs #2C6FB5, same diamond marker) in Figs 2C, 3A–C, 4F, 5 and Supp Fig 4.
    - Grey #8A8A8A small text (3.45:1) in Fig 2C (n), Fig 4D (n, cases/controls), Fig 4F (instrument counts) and the Supp Fig 4 group headings.
    - Marks below 3:1: neutrophil green #7CAE00 and darkgrey zero lines (Figs 2B, 4C); gold rings #DAA520 (Fig 2A, Supp Fig 2); the *P* = 5×10⁻⁸ dashed lines (Fig 2A #BEBEBE, Supp Fig 2 grey60); recombination traces (grey65, `helpers.R:740`).
  - **Action:** Give IVW and weighted median different markers (e.g. filled vs open) in plots and keys. Darken the text to #767676 or darker, and the marks to at least 3:1 against white.
- [ ] **MUST FIX — ST16 not cited in the main text.**
  - **EHJ rule:** R13.4.
  - **Location:** line 708 only.
  - **Action:** Cite it in lines 376–377 (text in the MI item).
- [ ] **MUST FIX (at revision at the latest) — datasets not cited.**
  - **EHJ rule:** R10.13–R10.14.
  - **Location:**
    - 11 source GWAS are missing from the reference list: RA (Ishigaki), PD (Nalls), pericarditis (deCODE, whose readme asks to be cited), GLGC lipids, BMI, GSCAN smoking, ALS, GBMI asthma, HGI COVID-19, UC, UK Biobank WGS.
    - EHJ practice: GWAS sources are cited as ordinary numbered references to their papers, with accessions in the supplementary tables. None of the 38 benchmark papers uses a "[dataset]" tag, so the manuscript's ST01–ST04 accession tables already match practice.
  - **Action:** Cite the 11 papers as ordinary references (about 76 references in total, within the 100 limit). Keep accessions in the supplementary tables.
- [ ] **MUST FIX (at revision) — reference style (both).**
  - **EHJ rule:** R10.6, R10.10, R10.11 (style binds at revision, R10.15).
  - **Location:**
    - Ref 21 is a preprint but isn't marked as one. The EHJ instructions use "[Preprint]"; recent EHJ papers print "medRxiv, [DOI], [date], preprint: not peer reviewed" (2 of 2 in 2026), and none uses "[Preprint]". Either marks it.
    - Software refs 28 and 63 lack version and URL.
    - Journal abbreviations: ref 56 "NPJ Park Dis" → NPJ Parkinsons Dis; ref 62 → Innovation (Camb); ref 43 → Rheumatology (Oxford); ref 59 "GigaScience" → Gigascience.
  - **Action:** Correct each.
- [ ] **MUST FIX — statistics statement (both).**
  - **EHJ rule:** R11.32, R11.25.
  - **Location:**
    - lines 168–180 gives no significance level, sidedness or R version.
    - Versions are missing for HyPrColoc (0.0.2), GCTA (1.94.1) and PLINK 2 (v2.00a6).
  - **Action:** "Statistical significance was set at *P* < 0.05 (two-sided) unless stated otherwise. Analyses used R version [x]." Recent EHJ papers use this phrasing (e.g. PMC12682380, PMC11842968). Add the three software versions.
- [ ] **MUST FIX — abbreviations (both).**
  - **EHJ rule:** R6.1.
  - **Location:**
    - Used before definition: GWAS (line 92; defined in lines 210–211); LD (lines 138–139).
    - Never defined: OR and CI (lines 178–179 spells them out without the abbreviations; use the lines 178–179 sentence in the Methods reporting-scales item); SNP (line 118; use "variant"); ASC (line 59; spell it out as the closest EHJ NLRP3 paper does, "apoptosis-associated speck-like protein containing a caspase recruitment domain (ASC)", PMC8244638, or write "an adaptor protein"); CHARGE (line 98); InSIDE (line 173; spell it out as EHJ MR papers do: "…the instrument strength independent of direct effect (InSIDE) assumption…", cf. PMC10849320); IL-1 and IL-1α (lines 408, 444–445); eQTL (SI lines 639, 641; ST01!A5).
    - Not needed: trial acronyms (CANTOS, ZEUS, LoDoCo2, CLEAR-SYNERGY, COLCOT) can stay unexpanded. EHJ papers use them as names and never spell them out (CANTOS appears in 3 benchmark papers, never expanded).
    - Defined twice: IL1Ra (lines 149, 343); pLOF in the Supp Fig 3 legend (lines 605, 609), in the second sentence and in the closing list. Change "non-carriers of predicted loss-of-function (pLOF) variants" to "non-carriers of pLOF variants" and keep the closing-list definition.
    - Supplementary tables: FCAS (ST16!A9) is never expanded → "familial cold autoinflammatory syndrome".
    - PD is defined in line 372, spelled out in line 390, then used in lines 443, 446–447.
    - GlycA is expanded only in the Abstract. line 61 introduces it without its full name, although the main text redefines CAD (lines 46–47).
  - **Action:** Define each once at first use, or spell out single uses.
- [ ] **MUST FIX — Word formatting.**
  - **EHJ rule:** R12.4.
  - **Location:**
    - Equation objects: line 372 "P=0.0052" (Cambria Math), lines 561, 571–572, 598, 625–626, 630, 635.
    - Unicode superscripts: lines 138, 140, 178, 202, 436, 589, 636, 640–641.
  - **Action:** Retype as text with Word superscripts.
- [ ] **MUST FIX — Oxford spelling (line 70 "randomised": both).**
  - **EHJ rule:** R12.1.
  - **Location:**
    - -ise forms: colocalisation/colocalising ×11, recognised (line 48), summarised, characterise (×3), prioritised, prioritising (line 634), visualisation, normalisation, maximise, generalisability, line 70 "randomised".
    - -ize forms alongside them: "randomization" ×6 in the text, "authorized" (line 502), "Hospitalized" (Fig 5, ST03, ST15).
  - **Action:** Change every -ise to -ize in the text, figures and tables; keep analyse, haematopoiesis, centre and colour. This matches EHJ practice: "randomization" 473 vs "randomisation" 64; "colocalization" 57 vs 18; "characterized" 36 vs 4; "analysed" is dominant.
- [ ] **MUST FIX (at revision) — numbers one to ten (both).**
  - **EHJ rule:** R11.26.
  - **Location:** line 356 "higher levels of 7".
  - **Action:** "seven".
- [ ] **MUST FIX at revision — layout (both).**
  - **EHJ rule:** R16.5, R16.7, R16.9, R16.11.
  - **Location:**
    - Single-spaced and justified.
    - Line numbers don't restart each page and are missing from the References.
    - Indents are set by style instead of one TAB, and lines 403, 416 add a typed tab on top of the style indent.
  - **Action:** Double spacing, unjustified text, line numbers on every page restarting each page, one-TAB indents.

---
## Consistency (all MUST FIX; target form → deviations)

The target is the form published EHJ papers use, with counts from the 38 benchmark full texts. Where EHJ gives no evidence, the target is the manuscript's own majority form.

- [ ] **P notation (both).** Target (EHJ): italic *P* (863 of 863), spaced operators (771 of 771), Word-superscript exponent, hyphenated "P-value" (27 of 38 papers vs 6 unhyphenated). Deviations: roman in lines 212, 608, 640–641; unspaced in line 140 "(*P*<5×10⁻⁸)" and line 372 "P=0.0052"; unhyphenated "P value(s)" in lines 253–254, 561, 572–573, 608, 691 (line 635 is already "P-value").
- [ ] **P precision.** Target (EHJ): 2 significant figures for decimal *P* values (30 of 52); exponent forms with 3 significant figures are equally common, so lines 259–261 can stay. Deviations: 1 significant figure in line 314 "0.002" and lines 350, 352 "1×10⁻¹⁰", "3×10⁻¹⁰"; CAD weighted median 0.005 (line 297, Fig 3A) vs 0.0047 (Fig 4F, Supp Fig 4); gout 0.0052 (line 372) vs 0.005 (Fig 5).
- [ ] **P in figures.** Dominant: uppercase P with ×10⁻ⁿ (text). Deviations: e-notation ("1e-10") in Figs 2C, 3C, 4A, 4D–F and Supp Fig 4; lowercase "p =" in Fig 4A ("p = 9.4e-08", `fig04a_plof_violins.py:36–42`) and Supp Fig 3 (all 12 labels).
- [ ] **r² (both).** Target (EHJ): italic *r* with a roman superscript 2 (54 of 55) (lines 274, 362); Unicode ² in lines 138, 178, 202, 436, 589, 636; roman r in lines 589, 636, Fig 4F; unspaced line 589; "r2" in ST14!A2:A13.
- [ ] **n (both).** Target (EHJ): italic, spaced "*n* = 4,732", as in line 260 (spaced 264 of 264; italic 249 of 256). Deviations: lines 122–124 "(n=26,000)" ×3.
- [ ] **β.** Dominant: italic. Deviations: roman in lines 312–313 "(β = 0.14".
- [ ] **CI (both).** Target (EHJ): en dash for two positive bounds, "95% CI 1.02–1.45" (229 CIs in 19 papers); "to" only when a bound is negative (3 CIs in 2 papers). The Abstract (lines 32, 35) already follows this. Deviations: "to" with positive bounds in the Results, lines 295, 297, 302, 304–305, 313–314, 321–322, 325, 350, 352, 371–373. Keep "to" where a bound is negative (lines 286–287, 334–335).
- [ ] **OR precision (both).** Target (EHJ): 2 decimals (78 of 79 ORs; also 10 of 14 ORs in the manuscript, Fig 3E and ST09). Deviations: lines 321–324 give 3 decimals. Use "SBP (OR = 1.08, 95% CI 1.04–1.13) … ApoB (OR = 1.05, 95% CI 1.02–1.08) and T2D (OR = 1.04, 95% CI 1.02–1.07) … (OR = 1.03, 95% CI 0.85–1.24, *P* = 0.79)".
- [ ] **Gene italics (both).** Target (EHJ): gene italic, protein and inflammasome roman ("*NLRP3* gene expression" vs "the NLRP3 inflammasome", e.g. PMC8244638). Deviations: roman in line 201, line 332 "driven by NLRP3 itself", line 448 "at the NLRP3 locus", lines 587–588, the Fig 2A and Supp Fig 2 gene tracks, Fig 4A "NLRP3 pLOF status", Fig 4B "NLRP3 GOF carrier" and the Supp Fig 3 titles; supplementary tables never italicise genes (ST01!A5, ST05!H2/H7/H12/H17/H22/H27/H32/H37, Contents!B6 and B11 for NLRP3; ST11!A2:A4 for IL1RN), so use rich-text italics there (keep IL1Ra and "NLRP3 activity" roman).
- [ ] **cis.** Dominant: italic (lines 85, 341, Fig 1). Deviations: roman in lines 200 and 451.
- [ ] **Cytokines (both).** Dominant: IL-1β / IL-18 / IL-6. Deviations: ST06!B8:B13 "IL1B / IL18 / IL6"; "interleukin-1" (lines 187, 344) vs "IL-1" (lines 408, 444–445). Also write "IL-1Ra" instead of "IL1Ra" (lines 149–151, 343–351, 554, 565–566, 621, 666; Fig 4C/4D; ST11; Contents): EHJ papers and the manuscript hyphenate the IL-1 family (IL-1β in 38 of 38 benchmark uses), and cited ref 48 writes "IL-1Ra".
- [ ] **Exposure name.** Target: "NLRP3 activity score" (about 70 uses) and "lower genetically proxied NLRP3 activity". EHJ puts the direction word first ("higher genetically predicted …" in 6 papers vs "genetically predicted higher …" in 3), as the manuscript mostly does. Deviations: Fig 1 legend has two names in one sentence; Fig 2 title "genetic score for NLRP3 activity"; ST06 "cis-NLRP3 activity score (lower)"; ST11 "cis-IL1RN / IL1Ra activity score"; Fig 4C "IL1Ra score"; "genetically proxied lower" (lines 39, 380); "reduced" (line 384); heading 4.6: "inhibitors" vs "inhibition" (heading 3.11, Fig 5 title).
- [ ] **Biomarkers** (pick one form per trait; EHJ uses both "levels" and "concentration(s)" for CRP, 2 vs 2 uses, but "neutrophil count(s)" 111 vs "neutrophil levels" 2). "CRP levels" (lines 96, 97, 155, 183, 220, 234, 260, 669) vs "CRP concentration" (lines 529, 596, Fig 2A/2B, Supp Fig 2, ST06); "GlycA concentrations" (lines 96–97, 155, 183–184, 220, 234, 260, 669–670) vs "GlycA levels" (lines 137, 557, 562, 588, 604, 623, Fig 1); "neutrophil count" vs "neutrophil counts" (lines 234, 335); "IL1RN expr.", "CRP conc." (Fig 4C); "Neutrophil Count" (Supp Fig 1).
- [ ] **Outcome names.** Dominant: "coronary atherosclerosis" for MVP, All of Us and FinnGen (lines 115–117, ST02); "coronary plaque burden", "carotid plaque". Deviations: ST07 R4–R9 "Coronary artery disease"; ST02 "Coronary/Carotid artery plaque burden"; ST07 "Coronary plaque burden (SIS, CTA)", "Carotid plaque (ultrasound)"; axis titles: Fig 3E "…CAD…" vs Fig 4F and Supp Fig 4 "…coronary artery disease…".
- [ ] **Apostrophes.** Dominant: curly. Deviations: straight in line 175, line 483, line 506, line 582 and Fig 5 "Parkinson's", and line 641; straight double quotes in line 697.
- [ ] **Serial comma.** Target (EHJ): used (dominant in 43 of 45 EHJ papers and in the manuscript, lines 36, 184, 443, 525–526). Deviations: missing in line 286, line 390 "gout, pericarditis and Parkinson's disease", line 400 "IL-1β, IL-18 and IL-6", line 486, line 696 "(CTIS) and ISRCTN".
- [ ] **Trial phase (both).** Target (EHJ): Arabic numerals, "phase 2" (19 vs 3 Roman; "Phase II" 0 times), as in lines 49/69 "phase 3" and "phase 2a". Deviations: line 706 "Phase II" (fixed by the SI lines 705–707 rewrite).
- [ ] **Hyphenation (both).** Target: hyphenated compound modifiers where EHJ hyphenates them ("genome-wide" 320 vs 2; "weighted median" never hyphenated). Deviations: line 221 "whole exome sequencing" (EHJ evidence thin: 4 vs 3); axes "per one unit" (captions "one-unit", as in EHJ "per 1-unit … change"); Fig 4 legend "weighted-median". "European ancestry" has no clear EHJ preference: EHJ mostly writes "of European ancestry" (15 papers), and as a modifier "European ancestry participants" (3 papers) vs "European-ancestry" (2). Use one form. Changing the 13 hyphenated text uses (lines 93, 98, 100, 102, 105, 114, 126, 129, 138, 157, 292, 473, 626) to "European ancestry" matches the tables and is the smaller edit.
- [ ] **Capitalisation (both).** Dominant: sentence case. Deviations: "Weighted Median" in Figs 2C, 3A–C, 4F, 5 and Supp Fig 4; table headers, where sentence case dominates (43 vs 31): title case in ST01!B1:D1, ST02!A1:D1, ST03!A1:D1, ST04!A1:D1, "# of Instruments" (ST06!C1, ST07!D1, ST08!C1, ST11!C1, ST12!C1, ST14!C1, ST15!C1), ST12!B1, D1, H1:K1, N1:O1 and ST13!G1 "# Genes"; reference titles: 18 in Title Case, the rest in sentence case.
- [ ] **Headings (both).** Target (EHJ): no heading numbers, body headings in sentence case, and declaration headings in the Title Case EHJ prints. None of 2,249 headings in 38 EHJ papers is numbered. Declaration forms: "Disclosure of Interest" (19 vs 1), "Data Availability" (48 vs 8), "Ethical Approval" (20 vs 1), "Pre-registered Clinical Trial Number" (20). Deviations: every heading is numbered (drop the numbers, which also removes the unnumbered "Supplementary Information"/"References" mismatch); body headings in Title Case at line 218 "Predicted Loss-of-Function Analysis" (line 229 is in the typo list) and line 584 "Supplementary Data" (EHJ: "Supplementary data", 21 vs 1); declaration headings in sentence case at line 494 "Disclosure of interest" and line 498 "Data availability". Lines 504 "Ethical Approval" and 515 "Pre-registered Clinical Trial Number" already match EHJ.
- [ ] **Supplementary material labels.** Target (EHJ): "Supplementary data online, Table S1" at first mention, then "Table S1"; figures "Figure S1". 37 of 38 benchmark papers do this, and none writes "Supplementary Table 1". Deviations: the manuscript writes "Supplementary Table N" and "Supplementary Figure N" (lines 112, 125, 127, 133, 141, 253, 258, 266, 288, 299, 315, 325, 339–340, 353, 360, 363–364, 377, 500, 586, 595, 603, 610, 638, 708), and the workbook tabs and Contents use "ST01"–"ST16" (rename to "Table S1"–"Table S16"). The text also refers to "the Supplementary Information" (lines 226, 235–236, 245, 250). EHJ never uses that name and writes "(see Supplementary data online, Methods)" (14 papers) instead.
- [ ] **Variant IDs.** Dominant: rsIDs. Deviations: chr_pos in ST07 R12–R13, ST14 A16–A31 and the ST05 "SNP" column.
- [ ] **"Excluding".** Dominant: "excluding" (ST14). Deviations: "w/o" (Supp Fig 4).
- [ ] **Genome build.** Dominant: "GRCh38" (line 233). Deviations: "hg38" (ST05).
- [ ] **Missing values.** Dominant: "NA". Deviations: "N/A" (ST01, ST03, ST04); "-" (ST02).
- [ ] **"et al."** Dominant: "*et al.*" (line 439 second use, line 541, line 673). Deviations: "*et al*." with roman full stop: line 231, line 429 first use. EHJ uses both forms (full stop outside the italics 41, inside 35), so keep whichever is the manuscript majority.
- [ ] **Paragraph layout.** Dominant: 0.25-inch first-line indent (Normal style). Deviations: 0.5 inch in lines 57–80, lines 393–402, lines 643–648, lines 697–708; 0.21 inch in lines 281–289, lines 332–366, lines 429–479, lines 658–664, lines 665–667, lines 686–692; no indent in lines 694–696; typed tabs in lines 403, 416; empty paragraphs lines 424–428 (five blank numbered lines in the Discussion), plus line 44, line 217, line 228, line 269, line 497 and line 576.

---

## EHJ benchmark summary (both reviews)

The two benchmarks sampled main-journal EHJ MR papers independently:
- **Claude:** [`trashtmp/ehj_mr_benchmark_claude.md`](/rds/user/nh608/hpc-work/trashtmp/ehj_mr_benchmark_claude.md). 52 screened, 51 read in full; core set of 33 in which MR is primary or major (11 cis/drug-target).
- **Codex:** [`trashtmp/ehj_mr_benchmark.md`](/rds/user/nh608/hpc-work/trashtmp/ehj_mr_benchmark.md). 21 read in full, supplements for 20.

Counts are applicable papers reporting the item; they are not journal requirements.

| Item | Claude benchmark | Codex benchmark | This manuscript |
|---|---|---|---|
| Heterogeneity (Q / I²) | 8 / 31 (cis 2 / 9) | 5 / 18 | Claimed, not reported |
| MR-Egger intercept | 19 / 30 | 17 / 19 (MR-Egger of any kind: 19 / 19) | Yes |
| Weighted median | 19 / 30 | 17 / 19 | Yes |
| F-statistic | 15 / 33 (cis 6 / 11) | 10 / 20 | Yes |
| Colocalisation | 6 / 33 (cis 4 / 11) | 3 / 5 recent cis | Yes |
| Positive control | 5 / 33 | 2 / 7 cis | Yes |
| Leave-one-out | 7 / 30 | – | Yes |
| Formal mediation | 6 / 33 | 4 / 5 give a proportion | Yes |
| Multiple testing | 14 / 33 | 4 / 6 cis | Yes |
| LD-matrix handling (cis) | 9 / 16 (drug-target 5 / 7) | – | Yes |
| Sample overlap discussed | 17 / 29 | – | Partly (SCAPIS, mediators); not exposure–CAD |
| STROBE-MR cited | 3 / 33 | 2 / 12 after its publication | No |
| SGA or take-home figure | 22 / 24 (2024–26) | 20 / 21 | No |
| Data availability section | 23 / 24 (2024–26) | 16 / 21 | Yes |
| Structured abstract | – | 21 / 21 | Yes |
| Disclosure of interest | 23 / 24 (2024–26) | 21 / 21 | Yes |
| Separate author contributions | 3 / 24 (2024–26) | 3 / 21 | No |
| Causal language | strong 15, moderate 16, cautious 2 | – | Moderate |

Most papers reported neither between-instrument heterogeneity nor STROBE-MR, so their absence alone was not treated as a required fix.

**House style applied by EHJ at copy-editing (no action needed at submission):**
- *P* without a leading zero (*P* < .05), in most 2024–26 papers.
- Thin spaces as thousands separators ("519 288"), with 641 space-grouped numbers vs 43 comma-grouped.
- Proposed wording in this report keeps the manuscript's current forms for these.
---

## Checked and dropped from one review

- **IL-6 sign (line 287):** the DOCX has a Word non-breaking hyphen before "0.72", which displays as a minus, and the PDF shows −0.72. Not an error.
- **Near-empty PDF page 14:** normal pagination, and it will change when the document is repackaged. No rule applies.
- **Abbreviations defined but not reused (Abstract GlycA; ST03/ST16 terms):** EHJ requires only a definition at first use.
- **Centring supplementary-table columns:** the EHJ table rule covers typeset main-text tables, not the supplement.
- **Ref 24 (Rietveld 2023) for the delta method:** it does derive delta-method standard errors for direct and indirect effects (S1 Text, Section C.4), so keep it. The suggested replacement, Carter 2021, only mentions the method.
- **Ref 21 as the only reference with a DOI:** preprints must carry a DOI (R10.11), so this is not an inconsistency. EHJ does not require DOIs for journal articles, although its examples show them (A17.18), so adding them is optional.

## Could not be fully verified

- **INTERVAL acknowledgement:** lines 485–486 thanks INTERVAL only generically. I couldn't confirm whether its standard acknowledgement is a data-use condition; check the data access agreement.
- **ZEUS:** the primary report is due at AHA on 7 Nov 2026. If it is published before submission, cite it instead of the interim sources in the ZEUS item.
- **Public code repository:** its final state at submission is unknown (see Declarations).

---

## Co-author comments on the first draft: were they addressed, and did they have a point?

**Sources.**
- Three copies of the first draft: the exported Google version with e-mailed comments (Aug 2026), Stephen Burgess's copy, and Ziad Mallat's copy.
- They hold 100 co-author comments plus tracked edits. Your own notes to yourself (UKB updates, GitHub, figure to-dos) are left out.

**Method.** Each comment was checked against the current PDF (line numbers as above) and, where it asked a question, against the outputs.
- **Point?**: Yes / Partly / Preference / No.
- **Now**: Addressed / Partly / Open / Superseded (the text it referred to is gone).
- Two of Stephen's comments (#75, #105) are about the units of the mediator estimates, which you have already decided; they are not re-assessed.

**Overall.** Of the 100 comments:

| Status | Count |
|---|---|
| Addressed | 45 |
| Partly addressed | 17 |
| Open | 25 |
| Superseded | 4 |
| Approvals or offers | 4 |
| Not re-assessed | 2 |
| Preferences not adopted | 2 |
| Point not valid | 1 |

The first-draft revisions took up most suggestions on wording, structure, title and datasets. What remains open is mainly biology and interpretation, where the co-authors' points match weaknesses a reviewer is likely to raise. The list below collects them.

### Still worth doing (raised by co-authors, open or partly open)

- [ ] **MAJOR — balance the preclinical evidence (Paul Carter #314; Murray Clarke, tracked insertion; Ziad Mallat #116).**
  - **P:** Line 64 cites only benefit from pharmacological NLRP3 inhibition. Three co-authors pointed to evidence the other way:
    - NLRP3-, ASC- and caspase-1-deficient ApoE⁻/⁻ mice develop the same atherosclerosis (Menu P et al., *Cell Death Dis* 2011;2:e137).
    - IL-1 signalling stabilises advanced plaques, and IL-1R1 loss or IL-1β blockade makes them less stable (Alexander MR et al., *J Clin Invest* 2012;122:70–9; Gomez D et al., *Nat Med* 2018;24:1418–29).
  - **W:** This is the evidence that makes "lower NLRP3, higher CAD" plausible. Without it, reviewers will side with Murray's "your score must be wrong" (#37).
  - **A:** One sentence in the Introduction (after line 64) or in the Discussion before line 413: "However, NLRP3 deficiency did not reduce atherosclerosis in ApoE-deficient mice [Menu], and IL-1 signalling promotes fibrous-cap stability in advanced plaques [Alexander, Gomez]."
- [ ] **MAJOR — sex (Murray Clarke #117; Ziad Mallat #116; Paul Carter #314).**
  - **P:** Three co-authors asked about sex differences. NLRP3 deficiency protected female but not male Ldlr⁻/⁻ mice (Chen S et al., *JACC Basic Transl Sci* 2020;5:582–98). The manuscript has no sex-specific analysis or statement.
  - **W:** EHJ requires sex to be addressed (R2.5, R15.6–R15.8). The EHJ neutrophil MR paper reported men and women separately (Luo et al. 2023, PMC10719495).
  - **A:**
    - At minimum, add the SAGER statement (EHJ compliance item). Only use "sex-specific data were not available" if that is true.
    - Better: add a sex-stratified CAD estimate if sex-specific CAD GWAS are available for any of the four sources.
- [ ] **MAJOR — test the insulin-resistance explanation (Ziad Mallat #232, #304, #312, #319).**
  - **P:** Ziad's IL-18/insulin-resistance explanation is now in the text (line 409), but it is untested. He suggested fasting insulin, HOMA-IR, ISI and TG/HDL.
  - **W:** The cited mechanism (ref 49) works through hyperphagia and obesity, yet the score shows no BMI association (see the T2D item).
  - **A:** Run the score against glycaemic-trait GWAS (e.g. MAGIC fasting insulin and HOMA-IR).
    - A positive result supports the IL-18 route and strengthens the T2D item.
    - A null result means the T2D sentence should be worded as unexplained.
- [ ] **MAJOR — "purer score" (James Peters #235, #404).**
  - **P:** James asked whether including CRP, GlycA and neutrophils (non-specific markers) drives the cardiometabolic associations. The manuscript's own data answer this, but the answer isn't in the paper:
    - across the 8 variants, effects on NLRP3 expression alone correlate r = 0.99 with the score weights
    - so an expression-only instrument weights the variants almost identically
    - in a simplified fixed-effect check, it gave the same CAD result (z = 4.06 vs 4.07).
  - **W:** It pre-empts an obvious reviewer question at almost no cost.
  - **A:**
    - Add to lines 276–277: "Variant effects on *NLRP3* expression alone were almost perfectly correlated with the score weights (*r* = 0.99), so an expression-only instrument gave the same results."
    - Add the formal expression-only estimate as a sensitivity row in ST14, run with your pipeline (random effects, LD).
- [ ] **MAJOR — colchicine evidence (Ziad Mallat #99; Murray Clarke #97).**
  - **P:**
    - Ziad asked you to cite the recent meta-analysis. Murray asked for CLEAR-SYNERGY.
    - Adding CLEAR-SYNERGY while removing COLCOT produced the selective framing flagged in the Introduction item.
  - **A:** Cite the EHJ meta-analysis: Samuel M, Berry C, Dubé M-P, et al., *Eur Heart J* 2025;46:2552–63, doi 10.1093/eurheartj/ehaf174. It covers six trials, including COLCOT, LoDoCo2 and CLEAR-SYNERGY, with major adverse cardiovascular events HR 0.75.
    - Lines 51–53 can then read: "Colchicine reduced major cardiovascular events by about a quarter in a meta-analysis of six trials [Samuel], although CLEAR-SYNERGY, the largest trial after myocardial infarction, showed no benefit [4]."
    - This resolves both comments and the COLCOT item with one EHJ reference.
- [ ] **MUST FIX — other sources of IL-1β (Paul Carter #103; James Peters #311).**
  - **P:** Lines 396–397 argue that NLRP3 inhibition should beat IL-1β blockade because it also lowers IL-18. But IL-1β is also made through other inflammasomes (e.g. AIM2, NLRC4) and caspase-8, which NLRP3 inhibition would spare.
  - **W:** This helps explain why NLRP3 inhibition need not reproduce CANTOS.
  - **A:** Add to line 397: "…although IL-1β generated through other inflammasomes and caspase-8 would be spared". Ref 65 (Mangan 2018) may do as the citation; check.
- [ ] **MUST FIX — why IL-1β and IL-18 were not used to build the score (Paul Carter #144; Ziad Mallat #163; James Peters #404).**
  - **P:** The hold-out design shows in lines 87 and 284, but the reason is never stated.
  - **A:** Add to line 271: "IL-1β and IL-18 were not used for construction, so that they could serve as independent validation outcomes. Their GWAS are also an order of magnitude smaller (about 50,000 vs 575,531 participants for CRP)."
- [ ] **MUST FIX — the conclusion still hedges (Dirk Paul #369).**
  - **P:** Dirk asked for the "do not exclude benefit… in selected patients" clause to be removed, for a clear message. Lines 476–477 still say "do not preclude benefit from pharmacological inhibition in selected patients".
  - **A:** Delete the clause. The subgroup point stays in lines 416–423. This fits the Abstract take-home item.
- [ ] **MUST FIX — the IL-6R/TNF analogy works against you (Paul Carter #313).**
  - **P:** Lines 406–407 cite IL-6R blockade and TNF inhibition changing lipids. Both are net cardioprotective, so the analogy undercuts the argument. The IL-1 genetics example (ref 48, lines 407–409) is the apt one.
  - **A:** Delete the IL-6R/TNF sentence, or add "although their net cardiovascular effect is protective".
- [ ] **MUST FIX — "contrast with the CANTOS trial" (Liam #305).**
  - **P:** CANTOS tested IL-1β, not NLRP3, in secondary prevention.
  - **A:** Line 393: "Our findings differ from what the CANTOS trial would predict…".
- [ ] **MUST FIX — say which variant colocalises (Stephen Burgess #59).**
  - **A:** Lines 262–263: "…a shared causal variant between the four traits (rs58546652, in near-complete linkage disequilibrium with rs12239046, *r*² = 0.98; posterior probability = 0.97)". This also fixes the "shared colocalising variant" item.
- [ ] **MUST FIX — Figure 2 panel order (Stephen Burgess #101, #102).**
  - **P:** The panels read A (top left), C (top right), B (bottom).
  - **A:** Relabel so they read A, B, C, and reorder the legend.
- [ ] **MUST FIX — scope of the IL1RN positive control (James Peters #259).**
  - **P:** James called it a leap: the same readouts working for IL1RN doesn't prove they capture NLRP3.
  - **A:** Add to the Limitations: "The IL1RN positive control shows that the approach can recover known biology for a related target. Evidence that the score captures NLRP3 activity comes from the IL-1β and IL-18 associations, colocalization and the rare-variant analyses."
- [ ] **MUST FIX — say what rare variants show, and no more (James Peters #244).**
  - **P:** The Results framing is right (line 332). The Discussion (lines 455–457) still uses the rare variants to rebut cardiometabolic pleiotropy.
  - **A:** See the P90 pleiotropy item.
- [ ] **MUST FIX — IL-6 vs TNF (Murray Clarke #267).**
  - **P:** Murray asked whether the lower IL-6 is IL-1-driven rather than TNF-driven. Your proteome results already answer it: TNF barely changes (β −0.21, *P* = 0.09) while IL-6 falls (β −0.72, *P* = 2.8 × 10⁻⁹) per unit lower score (ST12).
  - **A:** Add to line 287: "whereas TNF was not clearly associated (Supplementary data online, Table S12)".
- [ ] **MUST FIX — polygenic context for the readouts (Paul Carter #241).**
  - **P:** Existing MR shows that genetically higher neutrophil counts raise ischaemic heart disease risk (Luo et al., *Eur Heart J* 2023; PMC10719495). So lower readouts should lower, not raise, CAD. That supports the cardiometabolic explanation.
  - **A:** Cite it in one clause near line 413. No new analysis is needed.
- [ ] **MUST FIX — myocardial infarction (Paul Carter #129).** MI was analysed (Fig 5) but is not mentioned in the text. See the MI item in Results.

### Dirk Paul (12 comments)

| # | Concern | Point? | Now | Where / action |
|---|---|---|---|---|
| 6 | Title too definitive; proposed "Dissecting … genetically proxied NLRP3 inflammasome activity" | Yes | Addressed | Title (lines 1–3) adopts it |
| 25 | Abstract: add gout/RA/PD results | Yes | Addressed | Lines 35–36 (RA dropped, now null) |
| 102 | Mention the IVORY trial | Preference | Open | Not needed: IVORY tested low-dose IL-2 (not NLRP3) with an imaging endpoint |
| 106 | "Upstream of IL-1β is only NLRP3?" | No (IL-1β has other sources) | Superseded | Phrase removed; see IL-1β sources item |
| 121 | "Actionable target": focus on causality | Yes | Addressed | Lines 64–69 |
| 147 | How neutrophil counts were measured | Yes | Addressed | Lines 103–104 |
| 191 | Summary sentence at the end of each Results section | Yes | Addressed | E.g. lines 266–267, 288–289, 365–366, 377–378 |
| 287 | Repetition in the Discussion opening | Yes | Addressed | Line 381 rewritten |
| 366 | "Imprecision of what? This is power" | Yes | Addressed | Line 464 |
| 369 | Remove "do not exclude benefit … selected patients" | Yes | Open | Lines 476–477 (see above) |
| 419 | Add All of Us and FinnGen to CAD | Yes | Addressed | Lines 114–119 |
| 447 | Indications across several biobanks | Partly | Partly | One source per indication (ST03). Not needed now |

His tracked edit "(mimicking NLRP3 inhibition)" is covered by lines 169–170.

### Stephen Burgess (16 comments)

| # | Concern | Point? | Now | Where / action |
|---|---|---|---|---|
| 9 | "Further explored clinical indications" unclear | Yes | Addressed | Lines 78–80 |
| 14 | Approves the reworded aim | — | — | — |
| 26 | Say the imaging data are independent | Yes | Addressed | Line 124 |
| 30 | Where are the datasets for other diseases? | Yes | Addressed | Lines 125–127, ST03 |
| 43 | "Cardiometabolic trait screen" used before it is introduced | Yes | Addressed | Lines 131–132 (see P35 item on wording) |
| 44 | Which GWAS were used for the mediators? | Yes | Addressed | Line 200 (refs 15, 33, 34), ST04 |
| 59 | Which variant is shared? | Yes | Open | Lines 262–263 (see above) |
| 63 | "Evaluate" vs "validate" | Partly | Addressed | Line 281, now followed by explicit validation steps |
| 69 | *P* in the Abstract vs the text | Yes | Addressed | Both *P* = 0.032 |
| 75 | Scale of the mediator effects | — | Not re-assessed | Your decision |
| 85 | "Same direction" is ambiguous | Yes | Open | Lines 373–374. Deleting the RA sentence (Results item) removes it |
| 101, 102 | Figure 2 panel order | Yes | Open | See above |
| 105 | Units in the Figure 3 legend (mediators) | — | Not re-assessed | Your decision |
| 107 | Figure 4 carries too much (IL1Ra) | Preference | Kept | Six panels is EHJ's maximum (R7.4). Acceptable |
| 111 | Figure 5: how were outcomes chosen (why HFrEF, not HF)? | Yes | Addressed | Legend lines 578–580; Methods lines 248–254 |

His tracked edits are adopted:
- scale statements in the legends
- "not included in the primary dataset"
- "considered in NLRP3 trials".

### James Peters (18 comments)

| # | Concern | Point? | Now | Where / action |
|---|---|---|---|---|
| 5 | Neutral, genetics-focused title | Yes | Addressed | Lines 1–3 |
| 140 | Justify using European-ancestry data | Yes | Addressed | Line 93 |
| 159 | "Activity" needs validation against IL-18 in other datasets | Yes | Addressed | IL-1β/IL-18 validation in UKB-PPP (lines 284–286); "inflammasome activity" dropped |
| 175 | Approves a revision | — | — | — |
| 202 | "Shared inflammatory signal" sounds colloquial | Preference | Addressed | Lines 271–272 reworded |
| 223 | Scatter plot of variant effects (score vs CAD) | Partly | Open | Optional supplementary figure (7 of 38 EHJ MR papers show one) |
| 235 | Would a "purer" score give the same results? | Yes | Open | Answerable from existing data (see above) |
| 244 | pLOF confirms the gene, not the score | Yes | Partly | Results fine (line 332); Discussion lines 455–457 over-reach |
| 252 | Too few GOF carriers; CAD risk in CAPS? | Partly | Partly | Small numbers acknowledged (line 336). No action |
| 259 | IL1RN positive control is a leap | Partly | Open | One limitation sentence (see above) |
| 264 | Caution on complement measurement | No | — | Handling artefacts don't differ by genotype, so genetic associations aren't biased |
| 271 | Functional validation in a subset | Partly | Partly | Beyond scope; lines 469–471 already point to pharmacodynamic measurements |
| 290 | "At scale" is redundant | Yes | Addressed | Line 381 |
| 308 | Variance in IL-1β explained by the score | Partly | Partly | R² given for construction traits (lines 278–279). The small-lifelong-effect argument (lines 457–459) covers the CANTOS contrast |
| 311 | Other routes to IL-1β | Yes | Open | See above |
| 349 | Word order ("at the NLRP3 locus") | Yes | Superseded | Sentence rewritten |
| 361 | Combine NLRP3 inhibition with lipid, BP and glycaemic therapy | Partly | Partly | "Monitor" message at lines 415, 478–479. A combination claim would be speculative |
| 404 | Put IL-18 in the score and keep IL-1β for validation | Partly | Partly | The hold-out design is defensible; state the rationale (see above) |

### Paul Carter (22 comments)

| # | Concern | Point? | Now | Where / action |
|---|---|---|---|---|
| 0 | Title: stress the novel instrument, non-declarative | Yes | Addressed | Lines 1–3 |
| 31 | Abstract: add the other inflammatory conditions | Yes | Addressed | Lines 35–36 |
| 49 | Tone down the conclusion (lifelong vs short-term) | Yes | Addressed | Over-corrected: the Abstract now ends on the caveat (see Abstract item) |
| 70 | Introduction wording; say hsCRP | Yes | Addressed | Lines 45–48 (define hsCRP, see ZEUS item) |
| 103 | Other inflammasomes and caspase-8 also release IL-1β | Yes | Open | See above |
| 107 | Distinguish NLRP3 from the NLRP3 inflammasome | Yes | Addressed | Lines 57–59 |
| 118 | Inhibitors target the NLRP3 sensor | Yes | Addressed | Line 67 |
| 122 | MR precedent in inflammation (IL-6R) | Preference | Partly | Lines 72–77 give PCSK9 and Lp-PLA₂. No action |
| 128 | Imaging outcomes (CAC) | Yes | Addressed | Lines 120–124, Fig 3B |
| 129 | MI as an outcome | Yes | Partly | In Fig 5 but not the text (MI item) |
| 132 | "Activity" is fine, "inflammasome activity" too strong | Yes | Addressed | "NLRP3 activity" throughout |
| 144 | Why not instrument through IL-1β/IL-18? | Yes | Partly | State the rationale (see above) |
| 241 | Polygenic MR of CRP/GlycA/neutrophils on CAD | Partly | Open | Cite the existing EHJ neutrophil MR (see above) |
| 245 | Do pLOF/GOF carriers have more CAD or MI? | Partly | Open | Underpowered. Optional supportive analysis only |
| 277 | Figure 5 direction flipped | Yes | Addressed | Legend lines 579–581 (per unit lower) |
| 279 | Lung cancer (CANTOS) | Preference | Open | Outside the trial-based indication set. Not needed |
| 282 | "Inflammasome activity" wording | Yes | Addressed | — |
| 313 | IL-6R/TNF examples are protective overall | Yes | Open | See above |
| 314 | Prior IL-1 genetics and null or female-only experimental studies | Yes | Partly | Ref 48 added (lines 407–409). Experimental studies not cited (see above) |
| 318 | Trials enrol treated, established CAD | Yes | Addressed | Lines 461–464 |
| 329 | Offer to run CHIP GWAS | — | — | Collaboration offer, your call |
| 362 | PYCARD/CASP1 are integral, not "less specific" | Yes | Superseded | Sentence removed |

### Murray Clarke (13 comments and tracked edits)

| # | Concern | Point? | Now | Where / action |
|---|---|---|---|---|
| 7 | Titles should state the conclusion | Preference | Not adopted | The neutral title followed Dirk, James and Paul. EHJ MR titles use both styles |
| 11 | "NLRP3 doesn't signal; it's a protease activator" | Yes | Addressed | "NLRP3 signalling" no longer appears; line 419 is about IL-1β signalling |
| 37 | Lower IL-1 → higher CAD, and the T2D/BP direction, run against CANTOS: is the score wrong? | Yes | Partly | Validity now supported (lines 284–286, colocalization, rare variants, IL1RN). The biology is still one-sided (T2D item; preclinical and IR items above) |
| 97 | Cite CLEAR (no benefit) | Yes | Addressed | Lines 51–53, but COLCOT was lost (see colchicine item) |
| 117 | Sex-stratified results? | Yes | Open | See above |
| 123 | Why only NLRP3, not ASC/CASP1? | Partly | Partly | Line 67 implies the drug-target reason. Optional half-sentence: "ASC and caspase-1 are shared by other inflammasomes, so their variants would not proxy selective NLRP3 inhibition" |
| 158 | "Activity" is fine | — | — | — |
| 196 | How much NLRP3 activity do the variants explain? | Partly | Addressed | R² in lines 278–279. Low R² affects power, not validity |
| 255 | Do IL1RN variants shift the readouts like NLRP3? | Yes | Addressed | Fig 4C |
| 267 | Is IL-6 driven by IL-1 or by TNF? | Yes | Open | Answerable from ST12 (see above) |
| 273 | "Association with CAD is robust" is confusing | Yes | Addressed | Lines 365–366 |
| 276 | RA association? | Yes | Addressed | Reported. Delete "suggestive" (Results item) |
| 340 | Wording of "which would reduce power" | Yes | Superseded | Sentence removed |

His tracked insertions:
- "IL-1 may have protective effects via VSMC fibrous cap formation (PMIDs 22201681, 30038218)": valid, open (preclinical item above).
- The CANTOS "half of residual risk is not IL-1β-mediated" point: partly covered by lines 396–397.
- Administrative text for the declarations: not assessed.

### Ziad Mallat (10 comments)

| # | Concern | Point? | Now | Where / action |
|---|---|---|---|---|
| 99 | Cite the recent colchicine meta-analysis | Yes | Open | Samuel et al., *Eur Heart J* 2025 (see above) |
| 116 | Not only pharmacology: genetic deletion, and males vs females | Yes | Open | Menu 2011; Chen 2020 (see above) |
| 141 | South Asian analyses | Partly | Partly | Needs ancestry-specific instruments and CAD GWAS. Limitation at lines 472–473. Future work |
| 163 | Markers chosen because they are widely measured? | Yes | Partly | State the rationale (see above) |
| 232 | IL-18 → insulin resistance; test HOMA-IR, ISI, fasting insulin, TG/HDL | Yes | Partly | Hypothesis in line 409, untested (see above) |
| 240 | Repeat for other inflammasomes (AIM2, NLRP1) | Preference | Open | Out of scope: the drug target is NLRP3 |
| 304 | IL-18/insulin resistance explains the CANTOS discrepancy | Partly | Addressed | Lines 409–410, 457–461 |
| 312 | "Probably IL-18" | Partly | Addressed | Same |
| 319 | Insulin resistance takes time, so long-term inhibition is worse | Yes | Addressed | Lines 459–461 |
| 358 | Fits Schunk's age strata | Yes | Addressed | Lines 438–439 |

### Liam (9 comments)

| # | Concern | Point? | Now | Where / action |
|---|---|---|---|---|
| 220 | Name the exposure so the direction is clear to clinicians | Partly | Addressed | "Lower genetically proxied NLRP3 activity" throughout; lines 169–170 |
| 254 | Are pLOF carriers at higher CAD risk? | Partly | Open | Underpowered. Optional |
| 256 | Compare with a score based on IL1Ra protein levels | Partly | Partly | Validated against plasma IL1Ra (lines 347–349). No action |
| 261 | Colocalization for the proteome hits | Partly | Open | None of the 34 proteins is encoded near NLRP3, so LD with their own gene regions can't explain the hits. Locus-level colocalization is a nice-to-have |
| 266 | Do the proteins explain the ApoB/SBP/T2D effects? | Preference | Open | Not needed |
| 305 | Does it really "contrast" with CANTOS? | Yes | Open | See above |
| 346 | Schunk et al. were underpowered | Partly | Addressed | Lines 429–440 explain the difference without speculating about Schunk's motives, which is right |
| 433 | Add per-variant IL1Ra effects to Fig 4C | Preference | Open | Fig 4D already shows score → IL1Ra. Not needed |
| 482 | Include ruvonoflast in the drug search | Yes | Addressed | Line 701 |
