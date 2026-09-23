# Independent adversarial review of the supplementary-table builder

Reviewed after the first implementation, using a separate Python/OOXML verifier
rather than the exporter's R helpers. No subagents or other reviewers' reports
were used. The final script was executed successfully against the supplied
manual workbook and saved analysis outputs.

The review identified and corrected the following implementation issues:

- Full CAD Egger results are unavailable, but the intercept and its P value are
  saved in the sensitivity output. Those real diagnostics are exported separately
  from the explicitly synthetic full-export example.
- Optional files must fail on malformed values/schema, rather than fall back to
  fabricated data. A supplied Egger intercept/P must agree with the saved baseline.
- Long gene/pathway text needs variable row heights as well as column widths.
- The proteome's effective-test count must come from saved metadata. The saved
  adjusted P values are checked against that count.
- Small nonzero estimates must not display as zero, gene/variant identifiers and
  enrichment ratios must remain text, and uncertainty above 100% must be retained.

Independent checks passed for:

- All five original sheets' populated values, hyperlinks and cell-font semantics;
  the original workbook SHA256 is unchanged.
- All main MR rows in ST06/ST07/ST08/ST11/ST13/ST15, including correct handling of
  already-exponentiated IL1RN outcomes, continuous calcium, proportional-odds
  plaque outcomes, and the opposing NLRP3/IL1Ra score orientations.
- All 2,922 selected protein assays and their primary/sensitivity estimates;
  34 corrected-significant proteins; all 16 exported significant enrichment rows.
- Aligned instrument/readout tables, score metadata, signed LD matrix, proxy,
  mediator paths, sampling correlations and sequential residual results.
- The exact 1,265 variants used by the saved three-mediator MVMR, their order,
  and every exported association/SE. The larger pre-selection set is not substituted.
- Numeric/string read-back, explicit text storage for identifiers/ratios, and
  exactly 14 synthetic rows with every populated cell red and a textual warning.
- No generated formulas, filters, dropdowns or conditional formatting.
- Refusal to overwrite the manual input, to use an already-generated workbook as
  the template, or to accept missing required files, impossible P values or a
  malformed optional export. Failed builds preserve the previous output.
- Successful optional-export branches using clearly named artificial test fixtures
  confined to the temporary directory; those fixtures are not scientific results
  and were not used for the delivered workbook.

Representative sheets were exported through LibreOffice 6.4 and visually checked
for legibility and red placeholder display. Native Microsoft Excel was not
available; this is not a certification of a final journal PDF layout. The exporter
reformats existing results and does not resolve the methodological issues in the
manuscript audit or validate the unavailable rare-variant/Egger exports.

Evidence, independent checks, test fixtures and preview PDFs are in
`/rds/user/nh608/hpc-work/trashtmp/codex_supplement_builder/`.

Delivered workbook: `SuppTables_completed_DRAFT.xlsx`, SHA256
`6e17d02fbfd7e93646c694747b52869d3a9023ae1425b9a169910039635bbfa7`.
