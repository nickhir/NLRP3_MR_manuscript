# Pre-submission checklist

Supporting evidence: [working review log](/rds/user/nh608/hpc-work/NLRP3_MR_manuscript/manuscript_review_working_codex_v2.md).

## Title page

- [ ] **MUST FIX — Complete the author list.**  
  **Problem:** A dotted placeholder remains between Hirschmüller and Burgess.  
  **Why it matters:** The submitted authorship would be visibly unfinished.  
  **Action:** Insert the final authors and check their affiliations.

## Methods

- [ ] **MAJOR — Add the UK Biobank data-use declarations.**  
  **Problem:** No ethics/consent statement or approved application number is provided for the individual-level analyses.  
  **Why it matters:** The basis for using participant data is undocumented, and the required resource acknowledgement is missing.  
  **Action:** Add the applicable ethics approval, consent statement and application acknowledgement. [UK Biobank guidance](https://community.ukbiobank.ac.uk/hc/en-gb/articles/16594178325277-Submitting-publications-and-use-of-UK-Biobank-images).

## Results

### Section 4.1, first paragraph

- [ ] **MAJOR — Narrow the colocalisation claim.**  
  **Problem:** The text claims a single shared signal across ±1 Mb. HyPrColoc was run over ±200 kb; the wider region was only plotted.  
  **Why it matters:** Finding one shared signal does not establish that no others exist.  
  **Action:** Remove the unsupported uniqueness claim and describe the wider check as inspection of regional association plots, unless additional conditional analyses support it.

### Section 4.2, second paragraph

- [ ] **MUST FIX — Correct the IL-6 sign in the DOCX.**  
  **Problem:** Word reports β = **+0.72**; the output, Supplementary Table 6 and PDF correctly give **−0.72**.  
  **Why it matters:** The sign reverses the reported direction, and the submission formats disagree.  
  **Action:** Correct the DOCX and regenerate the final PDF from that source.

## Figures and supplementary tables

### Figure 3C and Supplementary Table 4

- [ ] **MUST FIX — Correct the smoking and alcohol sample sizes.**  
  **Problem:** Reported totals are 1,232,091 and 941,280. The files actually analysed give **632,802** and **535,425**, respectively, at every instrument.  
  **Why it matters:** The manuscript substantially overstates the analysed samples.  
  **Action:** Use the sample sizes of the analysed releases; verify the smoking case/control split before reporting it.

### Figure 3E

- [ ] **MAJOR — Stop clipping the error bars at OR 1.**  
  **Problem:** The axis and plotting code truncate lower bounds of approximately **0.94, 0.88 and 0.85**.  
  **Why it matters:** The plot hides the portions of the intervals crossing the null.  
  **Action:** Extend the axis below the smallest lower bound and draw each complete interval.

### Figure 5 and Supplementary Table 3

- [ ] **MAJOR — Distinguish Parkinson’s cases from proxy cases.**  
  **Problem:** The reported 33,674 cases comprise **15,056 cases plus 18,618 proxy cases**, according to the [analysed GWAS record](https://www.ebi.ac.uk/gwas/rest/api/studies/GCST009325).  
  **Why it matters:** More than half are relatives used as proxies, rather than diagnosed cases; the current description misstates the outcome population.  
  **Action:** Separate these counts in the table and figure/caption, and explain the proxy-case definition in the Methods.

## Funding

- [ ] **MUST FIX — Replace the funding placeholder.**  
  **Problem:** The statement still reads “[will be added]”.  
  **Why it matters:** The funding disclosure is incomplete.  
  **Action:** Add the actual funders and relevant grant details.

### Highest-priority pre-submission fixes

- [ ] Correct the colocalisation claim.
- [ ] Correct the analysed sample sizes and Parkinson’s case definitions.
- [ ] Restore the complete intervals in Figure 3E.

### Could not be fully verified

- [ ] Verify **1,821 effective protein tests** against the original eigenvalues or correlation calculation. The repository records this value but does not supply the calculation inputs or saved eigenvalue output; it determines the proteome-wide significance threshold.
