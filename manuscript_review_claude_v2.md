# Pre-submission audit: NLRP3 cis-MR manuscript, *European Heart Journal* (Clinical Research)

> Superseded by the combined Claude + codex report: `manuscript_review_final_combined_v2.md`.

**Reviewer and date:** Claude (v2), 24 September 2026.

**What was reviewed:**
- `NLRP3_manuscript_WIP.docx` / `.pdf` and `SuppTables_completed_DRAFT.xlsx`, byte-identical to the current files.
- Code and outputs, via a snapshot taken on 23 Sep at 18:40. It is identical to the current `results/`.

**Supporting files:**
- Working log: `manuscript_review_working_claude_v2.md`.
- EHJ rules: `trashtmp/ehj_author_guidelines_checklist_claude.md`.
- Benchmark: `trashtmp/ehj_mr_benchmark_claude.md`.
- The two trashtmp files carry a `_claude` suffix so they don't collide with files of the same name written by another review.

**How to read the items:**
- P-numbers are Word paragraphs.
- Each item gives **P** (problem), **W** (why it matters), **N** (EHJ norm) and **A** (action).
- Quoted text is the proposed manuscript wording. "[ref]" marks a new or renumbered citation.
- No item is **CRITICAL**: nothing overturns the CAD or mediation conclusions.
- EHJ format rules, typos and consistency points are collected in their own sections. The rule-based P97 disclosure item also appears under Declarations.

---

## Highest-priority pre-submission fixes

- [ ] **MAJOR:**
  - P72 RA estimate.
  - Fig 3E vs the joint model.
  - P74 rs12239046 Wald ratio and label.
  - P90 pleiotropy rebuttal.
  - Cochran's Q (P41).
  - Short additions: the MI null (P77), UK Biobank overlap (P90), COLCOT/colchicine (P19, P80), T2D (P81, P89).
  - Clinical take-home (P16, P79).
  - Disclosure of interest (P97).
  - SI P144 RA rationale.
- [ ] **MUST FIX:**
  - EHJ package: SGA, keywords, corresponding author, AI disclosure, alt text, legend order, separate supplement, page numbers.
  - pLOF window ±110 kb.
  - Pericarditis variants and proxy.
  - P37 selection rule.
  - Oxford (-ize) spelling throughout.

---

## Title page and Abstract

- [ ] **MAJOR — P16, the Conclusions undersell the paper.**
  - **P:** They end on a caveat. The take-home appears only in P81 and P91.
  - **W:** Editors read this first.
  - **N:** Not a reporting-norm issue. The SGA Take-home Message (R4.2) needs this point anyway.
  - **A:** Replace P16 with:
    > "Lifelong lower genetically proxied NLRP3 activity was associated with higher CAD risk, largely through adverse cardiometabolic effects. These findings provide no genetic support for cardioprotection from lower NLRP3 activity; NLRP3-inhibitor trials should monitor blood pressure, lipids, and glycaemia."

    The lifelong-vs-drug caveat stays in P90–P91.

## Introduction

- [ ] **MAJOR — P23 states neither novelty nor prior genetic evidence.**
  - **P:** Schunk et al. (EHJ 2021, ref 53) appears only in P88. The reason for a composite score appears only in P62 and P79.
  - **W:** Novelty drives editorial triage. **N:** Not a reporting-norm issue.
  - **A:** Replace P23 and offset it by deleting P89 sentences 1–2, which repeat P77 and P79:
    > "Human genetic evidence on NLRP3 is limited: a study based on a single *NLRP3* expression variant linked higher NLRP3 activity to higher cardiovascular mortality [ref: Schunk]. Because no single biomarker captures NLRP3 activity, we combined variant effects on *NLRP3* expression and downstream inflammatory biomarkers into an NLRP3 activity score, validated it against IL-1β and IL-18, and used drug-target MR to test its association with CAD, the pathways involved, and diseases for which NLRP3 inhibitors have been or are being evaluated."
- [ ] **MAJOR — P19/P80, colchicine is framed selectively.**
  - **P:**
    - P19 contrasts LoDoCo2 with CLEAR-SYNERGY to argue that benefit depends on clinical context. It omits COLCOT (benefit after MI), which ref 4 calls the most comparable trial.
    - The paper never says that colchicine acts partly through NLRP3 (ref 53).
  - **W:** This is a cardiologist reviewer's first question. **N:** Not a reporting-norm issue.
  - **A:**
    - P19: "…with benefit in COLCOT [ref: Tardif, *N Engl J Med* 2019;381:2497–505] (recent myocardial infarction) and LoDoCo2³ (chronic coronary disease) but not in CLEAR-SYNERGY⁴ (acute myocardial infarction)". Then soften "and the clinical context" in P19's last sentence, since COLCOT and CLEAR-SYNERGY enrolled similar patients.
    - P80, add: "Colchicine, which inhibits NLRP3 inflammasome activation among broader anti-inflammatory effects⁵³, reduced cardiovascular events in COLCOT [ref] and LoDoCo2³; this may reflect actions beyond NLRP3 or short-term effects not captured by lifelong genetic variation."
- [ ] **MUST FIX — P19/P80, ZEUS is overstated.**
  - **P:** The claim rests on top-line results (ref 5 is a commentary), from a population with ASCVD, CKD and high hsCRP.
  - **W:** It reads as a general IL-6 null. **N:** Not a reporting-norm issue.
  - **A:**
    - P19: define "high-sensitivity C-reactive protein (hsCRP)" at first use, then write "Recently, in top-line results, the phase 3 ZEUS trial of interleukin-6 (IL-6) inhibition in patients with atherosclerotic disease, chronic kidney disease, and elevated hsCRP found no reduction in cardiovascular events⁵."
    - P80: add the same population and "top-line".

## Methods

- [ ] **MUST FIX — P31, data sources.**
  - **P:**
    - The immunoturbidimetry clause applies only to the UK Biobank part.
    - "meta-analysis including 519,288 individuals": the meta-analysis had 746,667 participants; 519,288 is the European subset.
  - **W:** Both are factual errors. **N:** Not a reporting-norm issue.
  - **A:** Delete the assay clause. Write "Neutrophil count summary statistics were obtained from 519,288 European-ancestry participants of a multi-ancestry blood-cell trait meta-analysis, in which counts were measured by automated haematology analysers in contributing cohorts¹⁶."
- [ ] **MUST FIX — P33, FinnGen release.**
  - **P:** The counts are from release 12 (I9_CORATHER); ref 22 describes release 5.
  - **W:** The source is untraceable. **N:** Not a reporting-norm issue.
  - **A:** "…FinnGen (release 12)…".
- [ ] **MUST FIX — P35, mediator selection.**
  - **P:** "Those showing evidence of association were carried forward", but only 3 of 7 were. DBP's exclusion is unexplained.
  - **W:** The text doesn't match the analysis. **N:** Not a reporting-norm issue.
  - **A:** "…and a subset was carried forward to mediation analysis (Section 3.7)". Add "SBP represented blood pressure" to P45.
- [ ] **MUST FIX — P37, selection rule.**
  - **P:** The code applies the "≥2 traits" rule to merged signal blocks. rs74154640 is genome-wide significant for CRP only (ST05). Ten signals became 8 because 2 were missing from some datasets. The Supp Fig 1 caption says "variants" where it counts signals.
  - **W:** A reader can't reconcile the 10 signals with the 8 instruments. **N:** Not a reporting-norm issue.
  - **A:** "…retained independent signals associated at genome-wide significance with at least two traits and available in all datasets, yielding eight variants". Caption: "signals".
- [ ] **MUST FIX — P37/P62/SI P128, PCA depends on allele coding.**
  - **P:** Centred PCA of signed effects gives PC1 86.8–98.5% depending on the arbitrary effect-allele coding. Uncentred PCA gives 97.1% for any coding, and the per-variant score effects change by <0.1%.
  - **W:** A reviewer reproducing the score gets a different number. **N:** Not a reporting-norm issue.
  - **A:** Use `center = FALSE` and report 97.1% in P62. Change P37 "were centred and scaled" to "were scaled (not centred)", and SI P128 to "scaled to unit root mean square, without centring". Otherwise, keep centring and state the allele coding in the SI.
- [ ] **MAJOR — P41, Cochran's Q claimed but not reported.**
  - **P:** The values exist but are not shown:
    - CAD: Q 13.9 on 7 df, *P* = 0.053
    - CRP: *P* = 0.004
    - neutrophil count: *P* = 2×10⁻⁵
    - SBP / ApoB / T2D: *P* 0.93 / 0.94 / 0.68
    - MVMR: Q/df ≈ 16
    - IL1Ra protein: Q 54.5 on 2 df.
  - **W:** A stated method with no result, and the P90 fix depends on it.
  - **N:** Reported in 8 of 31 applicable EHJ MR papers (a minority). The reason to act is the Methods claim.
  - **A:**
    - Add Cochran's Q columns to ST06–ST09, ST11 and ST14.
    - Add MR-Egger intercept columns to ST08.
    - Footnote ST11: the IL1Ra Q is high, but random-effects IVW gives *P* = 1×10⁻¹⁰.
- [ ] **MUST FIX — "shared colocalising variant (rs12239046)" (P41, P74, Supp Fig 4, ST14 R32).**
  - **P:** The HyPrColoc candidate is rs58546652; rs12239046 is its proxy (r² 0.98).
  - **W:** It mislabels the result. **N:** Not a reporting-norm issue.
  - **A:** P41: "…estimated a Wald ratio using only rs12239046, which tags the colocalizing signal (*r*² = 0.98 with the HyPrColoc candidate rs58546652)". Relabel the others to match.
- [ ] **MUST FIX — P41, reporting scales.**
  - **P:** Proportional odds ratios for the ordinal imaging outcomes (P66, Fig 3 legend) are not in the Methods.
  - **W:** The Methods are incomplete. **N:** Not a reporting-norm issue.
  - **A:** "Estimates are reported as betas (continuous outcomes), odds ratios (ORs; binary outcomes), or proportional odds ratios (ordinal outcomes) with 95% confidence intervals (CIs)." This also defines OR and CI.
- [ ] **MAJOR — P41/P55, ST15, Fig 5: missing and proxied outcome variants unexplained.**
  - **P:** ST15 shows 5 instruments for pericarditis (an Abstract result) and 6 for knee OA, with no explanation. One pericarditis variant is an LD proxy (r² 0.98), and the pericarditis SEs were derived from ORs and *P* values because the deCODE file has no SE. The only proxy rule in the paper (P127) covers instrument construction.
  - **W:** Transparency about a headline result. **N:** Not a reporting-norm issue.
  - **A:** Add to P41: "Missing outcome variants were omitted, except one pericarditis variant, which was replaced by an LD proxy (*r*² = 0.98; Supplementary Table 15)." Add an ST15 footnote naming the missing and proxied variants and the SE derivation. Add the counts to the Fig 5 legend.
- [ ] **MUST FIX — P43/P53, ST06, ST12: assays chosen by smallest *P*.**
  - **P:** IL-6 has four Olink assays and the most significant is reported; the others give β −0.58 to −0.70, *P* ≤ 1.6×10⁻⁵. Six ST12 proteins are affected.
  - **W:** Undisclosed selection. **N:** Not a reporting-norm issue.
  - **A:** Add an ST06/ST12 footnote giving the rule and the IL-6 range.
- [ ] **MUST FIX — P45, MVMR details.**
  - **P:** The instrument count (1,265) is missing. The MVMR package and conditional F need Sanderson, Spiller & Bowden, *Stat Med* 2021;40:5434–52.
  - **W:** A basic reporting item, and the wrong source is cited. **N:** Not a reporting-norm issue.
  - **A:** Add both.
- [ ] **MUST FIX — P48, P71, Supp Fig 3 caption: pLOF window.**
  - **P:** The text says "within ±150 kb", but the pipeline uses ±110 kb (`01_identify_LOF_mutations.Rmd` l.95–101), so OR2G2 was not tested.
  - **W:** The Methods are wrong. **N:** Not a reporting-norm issue.
  - **A:** Change to "±110 kb" in all three places.
- [ ] **MUST FIX — P53/SI P138, test-count rule.**
  - **P:** The 95%-variance rule is Gao's simpleM at a non-default cut-off (the standard is 99.5%), but it is credited to ref 40.
  - **W:** A wrong citation. Plain Bonferroni over 2,922 tests still keeps 30 of 34 proteins, which pre-empts the question.
  - **N:** Not a reporting-norm issue (wrong citation). Multiple-testing correction is reported in 14 of 33 applicable EHJ MR papers.
  - **A:** In P138, cite Gao 2008 and write "95% (rather than the default 99.5%)". Add to the SI: "Bonferroni correction for 2,922 tests retained 30 of the 34 proteins."

## Results

- [ ] **MUST FIX — P59/Fig 2A, tallest expression peak unexplained.**
  - **P:** Fig 2A shows unconditioned expression. Its tallest peak (rs6689545, *P* = 3.4×10⁻⁶⁹; CRP *P* = 0.04) is explained only in Methods P39 (conditioned out). P59 names rs58546652 as the expression lead without mentioning it, and the caption does not mention it either.
  - **W:** It is the first thing a reader of Fig 2A will ask about. **N:** Not a reporting-norm issue.
  - **A:** Caption: "*NLRP3* expression is shown unconditioned; the upstream signal (rs6689545) was conditioned out before colocalization."
- [ ] **MUST FIX — P59 (method in P39), flank colocalization.**
  - **P:** P59 cites Supp Fig 2 for "no additional colocalising signals" between 200 kb and 1 Mb. The figure doesn't show this, and the result (regional probability ≤0.13) is reported nowhere.
  - **W:** An unsupported statement. **N:** Not a reporting-norm issue.
  - **A:** P59: "(HyPrColoc regional probability ≤0.13; Supplementary Figure 2)", or add the result to the Supp Fig 2 caption.
- [ ] **MAJOR — P68/Fig 3E, the figure shows different models from the text.**
  - **P:** Fig 3E comes from three nested, separately refitted MVMR models (833 / 876 / 1,265 variants), giving ΔOR 0.09 / 0.06 / 0.03. The text cites it for the joint-model indirect ORs 1.080 / 1.047 / 1.045, where ApoB ≈ T2D. The nested models are not in the Methods.
  - **W:** The key mechanism figure contradicts the text. **N:** Not a reporting-norm issue.
  - **A:** Redraw from the joint model: 1.21 → 1.12 → 1.07 → 1.03 (ΔOR 0.09 / 0.05 / 0.05, from unrounded ORs, so printed steps may differ by 0.01). Otherwise, label it "sequential, order-dependent", cite ST09 for the ORs, and add one Methods sentence.
- [ ] **MAJOR — P72, RA estimate out of date.**
  - **P:** The text says 0.26 (0.07 to 0.94), *P* = 0.04. The output, ST11 and Fig 4D say 0.22 (0.11 to 0.41), *P* = 3.3×10⁻⁶.
  - **W:** The text contradicts the figure it cites. **N:** Not a reporting-norm issue.
  - **A:** "(OR = 0.22, 95% CI 0.11 to 0.41, *P* = 3.3×10⁻⁶)".
- [ ] **MUST FIX — P73, drug-effect wording.**
  - **P:** "The downregulated proteins" and "the seven proteins raised by inhibition" describe genetic associations as drug effects.
  - **W:** It contradicts the paper's own caveat. **N:** Not a reporting-norm issue.
  - **A:** "the 27 proteins with lower levels" and "the seven proteins with higher levels".
- [ ] **MAJOR — P74/P75, colocalising-variant result not given.**
  - **P:**
    - The rs12239046 Wald ratio, OR 1.05 (0.89 to 1.23), *P* = 0.58, is given without its numbers.
    - Leave-one-out: all ORs > 1, but 4 of 8 have *P* 0.053–0.063.
    - The r² sweep is consistently significant (ORs 1.16–1.22, *P* ≤ 0.032).
  - **W:** Better disclosed than found by a reviewer, and the r² sweep helps the paper.
  - **N:** Leave-one-out is reported in 7 of 30 applicable EHJ MR papers; the issue here is accuracy.
  - **A:** P74: "…consistent across LD clumping thresholds (ORs 1.16–1.22), directionally consistent in leave-one-out analyses, and attenuated when restricted to rs12239046, which tags the colocalizing signal (OR = 1.05, 95% CI 0.89 to 1.23)".
- [ ] **MUST FIX — P77, RA called "suggestive" at *P* = 0.14.**
  - **P:** Other borderline results (knee OA weighted median *P* 0.027) are not singled out.
  - **W:** It reads as selective emphasis. **N:** Not a reporting-norm issue.
  - **A:** Delete the sentence.
- [ ] **MAJOR — P77/Fig 5, null MI estimate not mentioned.**
  - **P:** MI in MVP gives OR 1.01 (0.70 to 1.45), shown under "Cardiovascular". It is compatible with the CAD estimate (difference *P* = 0.36).
  - **W:** An unexplained null next to the headline invites doubt. **N:** Not a reporting-norm issue.
  - **A:** P77: "No clear associations were observed for the other indications examined, including myocardial infarction (OR = 1.01, 95% CI 0.70 to 1.45), whose wide interval is compatible with the CAD estimate (Supplementary Tables 15 and 16)." This also cites ST16 (EHJ compliance).

## Discussion

- [ ] **MUST FIX — P79/P81, mediation overstated.**
  - **P:** "Almost all" (P81) and "no evidence of a residual direct association" (P79), against 87% and "little evidence" in the Results.
  - **W:** Overclaim. **N:** Not a reporting-norm issue.
  - **A:**
    - Change to "most (an estimated 87%)" and "little evidence".
    - Replace P79's last sentence with "Overall, our data provide no genetic support for cardioprotection from lower NLRP3 activity; NLRP3-inhibitor trials should monitor blood pressure, lipids, and glycaemia."
    - Delete P81's last sentence, which then duplicates it.
- [ ] **MAJOR — P81/P89, the T2D finding gets one-sided support.**
  - **P:**
    - T2D (OR 1.26, *P* = 0.002) accounts for 22.7% of the total CAD association (ST09). It is the only trial indication where the genetics points against benefit, yet dapansutrile is in a phase 2 T2D trial (NCT06047262, ST16).
    - P81's only support is IL-18-knockout mice (ref 49), whose insulin resistance was mainly secondary to hyperphagic obesity. The score shows no BMI association (β −0.03, *P* = 0.41).
    - Not mentioned: NLRP3-deficient mice are protected from diet-induced insulin resistance, and canakinumab did not reduce incident diabetes in CANTOS.
  - **W:** A metabolic reviewer will see selective support for a key mediator, and trialists need the implication. **N:** Not a reporting-norm issue.
  - **A:**
    - P81: replace the IL-18 sentence with "The T2D association was less expected: NLRP3 deficiency protects mice against diet-induced insulin resistance [ref: Vandanmagsar, *Nat Med* 2011], canakinumab did not reduce incident diabetes [ref: Everett, *J Am Coll Cardiol* 2018], and we found no association with BMI."
    - P89: add "The higher T2D risk with lower genetically proxied NLRP3 activity is relevant to a phase 2 trial of dapansutrile in T2D (NCT06047262), in which glycaemic effects need close attention."
    - Shorten P89's last sentence to "These exploratory associations require replication."
- [ ] **MUST FIX — P82, TET2 subgroup.**
  - **P:** "A greater reduction", but the interaction *P* was 0.14 (ref 52: "equivocal").
  - **W:** Overclaim. **N:** Not a reporting-norm issue.
  - **A:** "a numerically greater reduction".
- [ ] **MAJOR — P90, the pleiotropy rebuttal is a non sequitur.**
  - **P:** Rare variants were tested only for CRP, GlycA and neutrophils, so they say nothing about pleiotropy for SBP, ApoB or T2D. The data that do are unreported and supportive:
    - Q *P* 0.93 / 0.94 / 0.68
    - MR-Egger intercept *P* 0.22 / 0.81 / 0.13
    - CAD intercept null at r² 0.2–0.6 (*P* 0.20–0.86).
  - **W:** A statistical reviewer will notice, and the real evidence helps the paper.
  - **N:** Not a reporting-norm issue (the argument does not follow). Pleiotropy is acknowledged as a limitation in 28 of 33 EHJ MR papers.
  - **A:** Replace the "However, rare…" sentence with the text below, and add the columns named in the P41 item:
    > "However, variant effects on SBP, ApoB, and T2D were homogeneous (Cochran's Q *P* ≥ 0.68) with null MR-Egger intercepts, and the CAD intercept was null at relaxed clumping thresholds (Supplementary Tables 8 and 14), consistent with a shared pathway."
- [ ] **MAJOR — P90, exposure–outcome sample overlap not discussed.**
  - **P:** UK Biobank is in the biomarker GWAS and in the Aragam CAD GWAS. "No sample overlap" is stated only for SCAPIS (P33).
  - **W:** A standard reviewer question, and the answer favours the paper.
  - **N:** Discussed in 17 of 29 applicable EHJ MR papers (the majority).
  - **A:** Add: "UK Biobank contributed to both exposure and CAD GWAS; with strong instruments (F = 92), any resulting bias is small and would act against our finding."

## Declarations and end matter

- [ ] **MAJOR — P97, disclosure of interest incomplete.**
  - **P:** It covers only N.H., S.B. and D.S.P.: nothing for A.S.B., and no "none declared".
  - **W:** AstraZeneca relationships matter for an NLRP3 paper.
  - **N:** EHJ rule R14.5–R14.7.
  - **A:** Add A.S.B.'s statement and "All other authors: none declared."
- [ ] **MUST FIX — P100, the code claim isn't true yet.**
  - **P:** The public repository lacks 09b, the table builder, some figure scripts, and all rare-variant and trial-search code. The local unpushed commit also contains the manuscript and review files; don't push it as is.
  - **W:** The availability claim is false. **N:** Not a reporting-norm issue.
  - **A:** Push the final code with a README and a Zenodo DOI. Either add the RAP scripts or write "Code for the summary-statistic analyses and figures…".

## References

- [ ] **MUST FIX — ref 24 misattributed.**
  - **P:** Rietveld 2023 is cited for the delta method (P37, P45, P133) but doesn't describe it.
  - **W:** Wrong source. **N:** Not a reporting-norm issue.
  - **A:** Replace ref 24 (cited only in P37, P45 and P133) with Carter AR et al., *Eur J Epidemiol* 2021;36:465–78.
- [ ] **MUST FIX — incomplete entries.**
  - **P:**
    - Ref 52 lacks its subtitle ("…: An Exploratory Analysis of the CANTOS Randomized Clinical Trial").
    - Ref 56 omits the group author GP2.
    - Ref 5 (pre-proof) has no volume or DOI.
    - ST01 "Sun B" and "Chen MH" vs refs "Sun BB" and "Chen M-H".
    - The ST02 All of Us PMID/DOI cell reads "NA", although ref 21 has a DOI.
  - **W:** Citation accuracy. **N:** Not a reporting-norm issue.
  - **A:** Correct each.

## Figures

- [ ] **MUST FIX — Fig 1.**
  - **P:** The title "Causal Effects on CAD" contradicts the paper's association wording. Pericarditis is in the caption but not in the graphic.
  - **W:** Overclaim, and the caption doesn't match the figure. **N:** Not a reporting-norm issue.
  - **A:** "Associations with CAD"; add the icon or remove the word.
- [ ] **MUST FIX — Fig 2.**
  - **P:**
    - 2A: the index marker, dashed line, grey NA and recombination line are unexplained.
    - 2B: ticks sit at unrounded positions (up to 9% off); units and error bars are undefined.
    - 2C: the IL-1β upper CI prints "−0.00".
  - **W:** Misleading or unreadable in places. **N:** Not a reporting-norm issue.
  - **A:**
    - 2A: define the elements in the legend.
    - 2B: use round ticks; add "bars are 95% CIs" and each panel's unit (or add a Units column to ST05 and cite it).
    - 2C: print 3 decimals.
- [ ] **MUST FIX — Fig 3.**
  - **P:**
    - The legend doesn't say that red = IVW, blue = weighted median, and bars are 95% CIs.
    - The 3C "β" header covers log-OR rows (T2D shows 0.23 against OR 1.26 in the text).
    - The Lp(a) upper CI prints "−0.00".
  - **W:** Values are misread. **N:** Not a reporting-norm issue.
  - **A:** Add the key; mark the log-OR rows or plot them as ORs; print more decimals.
- [ ] **MUST FIX — Fig 4.**
  - **P:**
    - 4C: the allele shown, the error bars and the units are undefined.
    - 4E: the key reads "Adj. P-value", while the legend says "adjusted P value".
  - **W:** Readers can't interpret 4C. **N:** Not a reporting-norm issue.
  - **A:** Define the 4C elements; use "Adjusted *P*" in 4E.
- [ ] **MUST FIX — Fig 5.**
  - **P:** The arrowheads are unexplained.
  - **W:** Incomplete legend. **N:** Not a reporting-norm issue.
  - **A:** Explain them in the legend.
- [ ] **MUST FIX — Supp Fig 1, stale render.**
  - **P:** The embedded image is older than `figures_out`.
  - **W:** It is not the current figure. **N:** Not a reporting-norm issue.
  - **A:** Re-embed.
- [ ] **MUST FIX — Supp Fig 2, undisclosed point thinning.**
  - **P:** A random ~75% of the non-significant neutrophil variants that lack LD data (grey points) are not plotted. The "Index SNP" key has no symbol.
  - **W:** Figure integrity. **N:** Not a reporting-norm issue.
  - **A:** Plot all points or state the thinning; fix the key.

## Supplementary Information and Tables

- [ ] **MUST FIX — SI P127, procedure misdescribed.**
  - **P:**
    - Proxies within 0.05 r² of the best are tied and chosen by lowest CRP *P*, not "highest LD" (chosen proxy r² 0.911 vs best 0.920).
    - The frequency filter used only the neutrophil GWAS and dropped all indels, including 16 genome-wide significant CRP indels.
  - **W:** Not reproducible as written. **N:** Not a reporting-norm issue.
  - **A:** Describe both as coded.
- [ ] **MUST FIX — SI P132, orientation.**
  - **P:** Scores are oriented to target-gene expression, not CRP; the two are opposite for IL1Ra.
  - **W:** Wrong for the positive control. **N:** Not a reporting-norm issue.
  - **A:** "oriented to lower target-gene expression".
- [ ] **MUST FIX — SI P138, covariates.**
  - **P:** Age² and age²×sex are missing (P136 lists them), and the European-only restriction is unstated.
  - **W:** Incomplete Methods. **N:** Not a reporting-norm issue.
  - **A:** Add both.
- [ ] **MUST FIX — SI P139 and ST13.**
  - **P:**
    - 10 MSigDB Hallmark rows are undescribed.
    - The GO:BP background is effectively 2,745.
    - The adjusted-*P* < 0.5 display filter is unstated.
    - The Description column repeats Term ID.
  - **W:** The table doesn't match the Methods. **N:** Not a reporting-norm issue.
  - **A:** Describe or delete the Hallmark rows; add "(2,745 with a GO:BP annotation)"; state the filter; add the term names.
- [ ] **MUST FIX — SI P141–P144 styled Heading 2.**
  - **P:** Body text is formatted as a heading, so citation 65 prints bold.
  - **W:** Visible formatting error. **N:** Not a reporting-norm issue.
  - **A:** Apply the Normal style.
- [ ] **MAJOR — SI P144, RA rationale.**
  - **P:** "A Phase II trial that was terminated due to off-target hepatotoxicity rather than lack of efficacy" goes beyond ref 65, which reports only raised liver enzymes of unclear cause.
  - **W:** It is the only stated reason for including RA, and the citation does not support it. **N:** Not a reporting-norm issue.
  - **A:** "…a selective NLRP3 inhibitor (MCC950/CP-456773) was evaluated in a phase 2 trial but was not developed further after it raised serum liver enzyme levels⁶⁵".
- [ ] **MUST FIX — ST01, positive-control sources.**
  - **P:** There is no row for the IL1Ra protein GWAS (UKB-PPP, n = 50,898). The eQTL row reads "NLRP3 eQTLs" but also supplied the IL1RN eQTLs. The main text never points to either source.
  - **W:** Data source undocumented. **N:** Not a reporting-norm issue.
  - **A:** Add the row. Relabel as "Whole-blood *cis*-eQTLs (*NLRP3*, *IL1RN*)". In P37, add "(Supplementary Tables 1 and 3)" after "gout and rheumatoid arthritis".
- [ ] **MUST FIX — ST07.**
  - **P:** R12–R13 "excl. 1_247460342_C_G" duplicate the rs188628429 leave-one-out estimate (ST14 R30–R31). R14 shows an MR-Egger slope, which P41 says is not used.
  - **W:** Redundant and contradictory rows. **N:** Not a reporting-norm issue.
  - **A:** Delete R12–R13. R14 is the only row with the CAD MR-Egger intercept (0.0089, *P* = 0.018) that P65 cites. Either move the intercept into the IVW meta-analysis row R10 (columns J–K) and then delete R14, or keep R14 with a footnote that the slope is not used as an estimator.
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
  - **A:** Format PMIDs as text; keep trailing zeros; show decimal *P* ≥ 0.001; add a notes block to Contents.

---

## Typos (all MUST FIX)

**Main text and SI**
- [ ] P39: "blood neutrophil count , using" → "blood neutrophil count, using"
- [ ] P39: "prior.c = 0.02. Evidence" → "prior.c = 0.02). Evidence"
- [ ] P41: "MendelianRandomization²⁸  (version" → single space
- [ ] P50: "*NLRP3* Predicted Gain-of-Function Analysis" → "*NLRP3* gain-of-function analysis" (P51: these are known pathogenic variants)
- [ ] P51: "Cosson et al. ³⁹" → "Cosson et al.³⁹"
- [ ] P51: "Supplementary Information″." → "Supplementary Information."
- [ ] P55: "on the 28 of April 2026" → "on 28 April 2026"
- [ ] P59: "support coherent NLRP3-linked inflammatory signal" → "support a coherent NLRP3-linked inflammatory signal"
- [ ] P71: "pLOF variants in NLRP3 were associated with significantly lower CRP … than non-carriers" → "Carriers of pLOF variants in NLRP3 had significantly lower CRP … than non-carriers"
- [ ] P71: "higher GlycA and neutrophil levels" → "higher GlycA concentrations and neutrophil counts"
- [ ] P73: "after multiple-testing" → "after multiple-testing correction"
- [ ] P88: "…reference panel and was additionally associated" → "…reference panel, and was additionally associated"
- [ ] P97: "during the duration of this work" → "during this work"
- [ ] P109: "PC1, principal component" → "PC1, first principal component"
- [ ] P127: "Components represented in…" / "For each retained component" → "Merged blocks represented in…" / "For each retained block"
- [ ] P136: "recruitment centre" → "assessment centre" (the same covariate is named both ways)
- [ ] P141: "on the 28th of April 2026" → "on 28 April 2026"

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

- [ ] **MUST FIX — Structured Graphical Abstract missing.**
  - **EHJ rule:** R4.1–R4.9 (present in 22 of 24 EHJ papers from 2024–26).
  - **Location:** Absent.
  - **Action:** Add an 11 × 18 cm graphic and three text fields of ≤40 words. Draft:
    - *Key Question:* "Does lower genetically proxied NLRP3 activity, mimicking NLRP3 inhibition, reduce coronary artery disease (CAD) risk?"
    - *Key Finding:* "A genetic score for lower NLRP3 activity was associated with lower IL-1β and IL-18 but higher CAD risk (OR 1.21), an estimated 87% mediated by higher blood pressure, apolipoprotein B, and type 2 diabetes risk."
    - *Take-home Message:* "Human genetics does not support cardioprotection from lower NLRP3 activity; trials of NLRP3 inhibitors should monitor blood pressure, lipids, and glycaemia."
- [ ] **MUST FIX — keywords missing.**
  - **EHJ rule:** R2.6.
  - **Location:** After the Abstract.
  - **Action:** Add up to 6, e.g. NLRP3 inflammasome; Mendelian randomization; Drug target; Coronary artery disease; Inflammation; Cardiometabolic risk.
- [ ] **MUST FIX — corresponding author missing.**
  - **EHJ rule:** R2.1.
  - **Location:** Title page.
  - **Action:** Add postal address and email.
- [ ] **MUST FIX — AI-use disclosure missing.**
  - **EHJ rule:** R14.45 (cover letter AND Methods/Acknowledgements).
  - **Location:** Absent. The repository linked in P100 shows 16 of 23 commits co-authored by Claude Opus 5 or Claude Sonnet 5.
  - **Action:** Template for the authors to complete: "Claude Opus 5 and Claude Sonnet 5 (Anthropic) were used to write and check analysis and figure code [authors: add any other use]; the authors checked all outputs and take full responsibility for the content." Repeat in the cover letter.
- [ ] **MUST FIX — disclosure of interest incomplete.**
  - **EHJ rule:** R14.5–R14.7.
  - **Location:** P97.
  - **Action:** See Declarations.
- [ ] **MUST FIX — sex/gender reporting missing.**
  - **EHJ rule:** R2.5 (abstract); R15.6–R15.8 (Methods, with rationale).
  - **Location:** Abstract Methods (P10) and Methods.
  - **Action:** Abstract: say the data are sex-combined. Methods: "All summary statistics were from sex-combined analyses of men and women; sex-stratified analyses were not performed because sex-specific data were not available for most sources [authors: confirm]."
- [ ] **MUST FIX — document order and packaging.**
  - **EHJ rule:** R5.1, R5.4, R8.1.
  - **Location:**
    - Legends sit under "12. Figures", interleaved with the images, before the References (P105–P116).
    - The supplementary figures and SI are inside the main file (P117–P144).
    - SI-only refs 59–65 are in the main list.
  - **Action:** Put the legends after the References under "Figure Legends". Move P117–P144 to a separate file with its own references.
- [ ] **MUST FIX — alt text missing.**
  - **EHJ rule:** R8.5.
  - **Location:** Fig 1–5 legends (P107, P109, P111, P113, P116).
  - **Action:** Add "Alt text: …" under each.
- [ ] **MUST FIX — page numbering.**
  - **EHJ rule:** R16.2.
  - **Location:** A section break restarts page numbering, so PDF pp. 28–32 read 1–5.
  - **Action:** Use a page break instead.
- [ ] **MUST FIX — legends missing n and definitions.**
  - **EHJ rule:** R8.2, R8.3.
  - **Location:**
    - Fig 2A/2B give no n.
    - Defined nowhere: SD (Figs 2–4), OR (Figs 3–5), CI (Figs 2–5), ΔOR (Fig 3E), SNP and cM/Mb (Fig 2A, Supp Fig 2).
  - **Action:** Add n to Fig 2A/2B, and define these terms in the legends that use them.
- [ ] **MUST FIX — figure format.**
  - **EHJ rule:** R7.14, R7.17, R7.22.
  - **Location:**
    - Fig 3 panels are shrunk to 74%, giving text of about 5 pt.
    - The Fig 2A and Supp Fig 2 LD keys are about 4.7 pt.
    - Supp Fig 3 is a 187-ppi raster; EHJ asks for graphs as vector files.
  - **Action:** Rebuild Fig 3 near 1:1 or split out D–E. Enlarge both LD keys. Export Supp Fig 3, and Fig 1 (now a 300-dpi embed), as vector PDFs at upload.
- [ ] **MUST FIX — ST16 not cited in the main text.**
  - **EHJ rule:** R13.4.
  - **Location:** P144 only.
  - **Action:** Cite it in P77 (text in the MI item).
- [ ] **MUST FIX (at revision at the latest) — datasets not cited.**
  - **EHJ rule:** R10.13–R10.14.
  - **Location:**
    - 11 source GWAS are missing from the reference list: RA (Ishigaki), PD (Nalls), pericarditis (deCODE, whose readme asks to be cited), GLGC lipids, BMI, GSCAN smoking, ALS, GBMI asthma, HGI COVID-19, UC, UK Biobank WGS.
    - Datasets cited through their papers have no "[dataset]" entry. Accessions appear only in ST01–ST04.
  - **Action:** Cite the 11 papers. Add "[dataset]" entries with accessions for the main-analysis datasets (about 15; about 80 references in total, within the 100 limit).
- [ ] **MUST FIX (at revision) — reference style.**
  - **EHJ rule:** R10.6, R10.10, R10.11 (style binds at revision, R10.15).
  - **Location:**
    - Ref 21 lacks "[Preprint]".
    - Software refs 28 and 63 lack version and URL.
    - Journal abbreviations: ref 56 "NPJ Park Dis" → NPJ Parkinsons Dis; ref 62 → Innovation (Camb); ref 43 → Rheumatology (Oxford).
  - **Action:** Correct each.
- [ ] **MUST FIX — statistics statement.**
  - **EHJ rule:** R11.32, R11.25.
  - **Location:**
    - P41 gives no significance level, sidedness or R version.
    - Versions are missing for HyPrColoc (0.0.2), GCTA (1.94.1) and PLINK 2 (v2.00a6).
  - **Action:** "Two-sided *P* < 0.05 was considered significant unless stated otherwise; analyses used R [version]", plus the three versions.
- [ ] **MUST FIX — abbreviations.**
  - **EHJ rule:** R6.1.
  - **Location:**
    - Used before definition: GWAS (P29; defined in P45); LD (P37).
    - Never defined: OR and CI (P41 spells them out without the abbreviations → "odds ratios (ORs) … 95% confidence intervals (CIs)"); SNP (P33; use "variant"); ASC (P20); CHARGE (P31); InSIDE (P41); IL-1 and IL-1α (P81, P89); eQTL (SI P127).
    - Trial acronyms: CANTOS (4 uses from P19) → "Canakinumab Anti-inflammatory Thrombosis Outcome Study (CANTOS)"; ZEUS, LoDoCo2 and CLEAR-SYNERGY (and COLCOT, if added) are also unexpanded.
    - IL1Ra is defined twice (P37, P72).
    - PD is defined in P77, spelled out in P79, then used in P89.
    - GlycA is expanded only in the Abstract. P20 introduces it without its full name, although the main text redefines CAD (P19).
  - **Action:** Define each once at first use, or spell out single uses.
- [ ] **MUST FIX — Word formatting.**
  - **EHJ rule:** R12.4.
  - **Location:**
    - Equation objects: P77 "P=0.0052" (Cambria Math), P113, P121, P127.
    - Unicode superscripts: P37, P41, P45, P88, P119, P127.
  - **Action:** Retype as text with Word superscripts.
- [ ] **MUST FIX — Oxford spelling.**
  - **EHJ rule:** R12.1.
  - **Location:**
    - -ise forms: colocalisation/colocalising ×11, recognised (P19), summarised, characterise (×3), prioritised, prioritising (P127), visualisation, normalisation, maximise, generalisability, P22 "randomised".
    - -ize forms alongside them: "randomization" ×6 in the text, "authorized" (P100), "Hospitalized" (Fig 5, ST03, ST15).
  - **Action:** Change every -ise to -ize in the text, figures and tables; keep analyse, haematopoiesis, centre and colour.
- [ ] **MUST FIX — numbers one to ten.**
  - **EHJ rule:** R11.26.
  - **Location:** P73 "higher levels of 7".
  - **Action:** "seven".
- [ ] **MUST FIX at revision — layout.**
  - **EHJ rule:** R16.5, R16.7, R16.9, R16.11.
  - **Location:**
    - Single-spaced and justified.
    - Line numbers don't restart each page and are missing from the References.
    - Indents are set by style instead of one TAB, and P81–P82 add a typed tab on top of the style indent.
  - **Action:** Double spacing, unjustified text, line numbers on every page restarting each page, one-TAB indents.

---

## Consistency (all MUST FIX; dominant form → deviations)

- [ ] **P notation.** Dominant: italic *P*, spaced operators, Word-superscript exponent. Deviations: roman in P45, P123, P127 ×2; unspaced in P37 "(*P*<5×10⁻⁸)", P77 "P=0.0052"; "P-value" in P127.
- [ ] **P precision.** Dominant: 2 significant figures. Deviations: 3 significant figures in P59 "1.04×10⁻⁵⁸, 1.34×10⁻⁸⁷, 1.93×10⁻⁴³"; 1 significant figure in P68 "0.002"; P72 "1×10⁻¹⁰", "3×10⁻¹⁰"; CAD weighted median: 0.005 (P65, Fig 3A) vs 0.0047 (Fig 4F, Supp Fig 4); gout: 0.0052 (P77) vs 0.005 (Fig 5).
- [ ] **P in figures.** Dominant: ×10⁻ⁿ (text). Deviations: e-notation ("1e-10") in Figs 2C, 3C, 4D–F and Supp Fig 4.
- [ ] **r².** Target: italic *r* with Word superscript (P62, P74); Unicode ² in P37, P41, P45, P88, P119, P127; roman r in P119, P127, Fig 4F; unspaced P119; "r2" in ST14.
- [ ] **n.** Dominant: "*n* = 4,732" (P59). Deviations: P33 "(n=26,000)" ×3.
- [ ] **β.** Dominant: italic. Deviations: roman in P68 "(β = 0.14".
- [ ] **CI.** Dominant: "1.02 to 1.45" (text). Deviations: "1.02–1.45" in the Abstract (P13 ×2).
- [ ] **Direct OR.** Dominant: 1.03 (Abstract, Fig 3E). Deviations: P68 "1.026".
- [ ] **Gene italics.** Dominant: italic. Deviations: roman in P45, P71 "driven by NLRP3 itself", P89 "at the NLRP3 locus", P119 ×2, the Fig 2A and Supp Fig 2 gene tracks, Fig 4A "NLRP3 pLOF status", Fig 4B "NLRP3 GOF carrier" and the Supp Fig 3 titles.
- [ ] **cis.** Dominant: italic (P27, P72, Fig 1). Deviations: roman in P45 and P90.
- [ ] **Cytokines.** Dominant: IL-1β / IL-18 / IL-6. Deviations: ST06 "IL1B / IL18 / IL6"; "interleukin-1" (P43, P72) vs "IL-1" (P81, P89).
- [ ] **Exposure name.** Dominant: "NLRP3 activity score" (about 70 uses); "lower genetically proxied NLRP3 activity". Deviations: Fig 1 legend has two names in one sentence; Fig 2 title "genetic score for NLRP3 activity"; ST06 "cis-NLRP3 activity score (lower)"; ST11 "cis-IL1RN / IL1Ra activity score"; Fig 4C "IL1Ra score"; "genetically proxied lower" (P16, P79); "reduced" (P79); heading 4.6: "inhibitors" vs "inhibition" (heading 3.11, Fig 5 title).
- [ ] **Biomarkers** (pick one form per trait). "CRP levels" (P31 ×2, P39, P43, P48, P51, P59, P136) vs "CRP concentration" (P109, P121, Fig 2A/2B, Supp Fig 2, ST06); "GlycA concentrations" (P31, P39, P43, P48, P51, P59, P136) vs "GlycA levels" (P37, P113 ×2, P119, P123, P127, Fig 1); "neutrophil count" vs "neutrophil counts" (P51, P71); "IL1RN expr.", "CRP conc." (Fig 4C); "Neutrophil Count" (Supp Fig 1).
- [ ] **Outcome names.** Dominant: "coronary atherosclerosis" for MVP, All of Us and FinnGen (P33, ST02); "coronary plaque burden", "carotid plaque". Deviations: ST07 R4–R9 "Coronary artery disease"; ST02 "Coronary/Carotid artery plaque burden"; ST07 "Coronary plaque burden (SIS, CTA)", "Carotid plaque (ultrasound)"; axis titles: Fig 3E "…CAD…" vs Fig 4F and Supp Fig 4 "…coronary artery disease…".
- [ ] **Apostrophes.** Dominant: curly. Deviations: straight in P41, P93, P102, P116 and Fig 5 "Parkinson's", and P127; straight double quotes in P142.
- [ ] **Serial comma.** Dominant: used (P13, P43, P89, P107). Deviations: missing in P63, P79 "gout, pericarditis and Parkinson's disease", P80 "IL-1β, IL-18 and IL-6", P93, P141 "(CTIS) and ISRCTN".
- [ ] **Trial phase.** Dominant: "phase 3" / "phase 2a". Deviations: P144 "Phase II".
- [ ] **Hyphenation.** Dominant: hyphenated modifiers. Deviations: P48 "whole exome sequencing"; "European ancestry individuals" (35 cells in ST01–ST04); axes "per one unit" (captions "one-unit"); Fig 4 legend "weighted-median".
- [ ] **Capitalisation.** Dominant: sentence case. Deviations: "Weighted Median" in Figs 2C, 3A–C, 4F, 5 and Supp Fig 4; ST12 headers ("Gene Name", "IVW Beta"); reference titles: 18 in Title Case, the rest in sentence case.
- [ ] **Headings.** Dominant: numbered, sentence case. Deviations: Title Case in 3.8 "Predicted Loss-of-Function Analysis", 10, 11 and 13; "Supplementary Information" and "References" are unnumbered, while the SI subsections are 14.1–14.4.
- [ ] **Supplementary table labels.** Dominant: "Supplementary Table 1" (text). Deviations: workbook tabs and Contents use "ST01"–"ST16".
- [ ] **Variant IDs.** Dominant: rsIDs. Deviations: chr_pos in ST07 R12–R13, ST14 A16–A31 and the ST05 "SNP" column.
- [ ] **"Excluding".** Dominant: "excluding" (ST14). Deviations: "w/o" (Supp Fig 4).
- [ ] **Genome build.** Dominant: "GRCh38" (P51). Deviations: "hg38" (ST05).
- [ ] **Missing values.** Dominant: "NA". Deviations: "N/A" (ST01, ST03, ST04); "-" (ST02).
- [ ] **"et al."** Dominant: "*et al.*" (P88 second use, P111, P136). Deviations: "*et al*." with roman full stop: P51, P88 first use.
- [ ] **Paragraph layout.** Dominant: 0.25-inch first-line indent (Normal style). Deviations: 0.5 inch in P20–P23, P80, P128, P142–P144; 0.21 inch in P63, P71–P75, P88–P91, P133, P134, P139; no indent in P141; typed tabs in P81–P82; empty paragraphs P83–P87 (five blank numbered lines in the Discussion), plus P18, P46, P49, P60, P98 and P114.

---

## EHJ benchmark summary

Full table: [`trashtmp/ehj_mr_benchmark_claude.md`](/rds/user/nh608/hpc-work/trashtmp/ehj_mr_benchmark_claude.md).
- **Screened:** 52 main-journal EHJ papers, 2019–2026.
- **Read in full:** 51 (33 core, 7 with MR as a minor component, 11 without MR on reading).
- **Read in part:** 1, not counted.
- **Core set:** 33 papers in which MR is the primary analysis or a major component; 11 of them cis/drug-target.

| Item | Applicable EHJ MR papers reporting it | This manuscript |
|---|---|---|
| Heterogeneity (Q / I²) | 8 / 31 (cis 2 / 9) | Claimed, not reported |
| MR-Egger intercept · weighted median | 19 / 30 · 19 / 30 | Yes · Yes |
| F-statistic | 15 / 33 (cis 6 / 11) | Yes |
| Colocalisation | 6 / 33 (cis 4 / 11) | Yes |
| Positive control · leave-one-out | 5 / 33 · 7 / 30 | Yes · Yes |
| Formal mediation · multiple testing | 6 / 33 · 14 / 33 | Yes · Yes |
| LD-matrix handling of correlated cis variants | 9 / 16 (drug-target 5 / 7) | Yes |
| Sample overlap discussed | 17 / 29 | Partly (SCAPIS, mediators); not exposure–CAD |
| STROBE-MR cited | 3 / 33 | No |
| SGA (2024–26 papers) | 22 / 24 | No |
| Causal language | strong 15, moderate 16, cautious 2 | Moderate |

---

## Could not be fully verified

- [ ] **INTERVAL acknowledgement:** P93 thanks INTERVAL only generically. I couldn't confirm whether its standard acknowledgement is a data-use condition; check the data access agreement.
- [ ] **ZEUS:** if full results are published by submission, cite the primary report instead of the ref 5 commentary.
- [ ] **Public code repository:** its final state at submission is unknown (see Declarations).
