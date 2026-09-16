# Codebase simplification — design

Date: 2026-09-16

## Purpose

The repository reproduces the figures and analyses of one manuscript, from one
frozen set of inputs, run once. It currently carries defensive code, unused
flexibility and shell plumbing appropriate to a general-purpose library. Strip
all three. Readability is the objective; efficiency and edge cases are not.

## Success criteria

| | criterion |
|---|---|
| Figures | all 18 PDFs pixel-identical to the baseline at 150 dpi |
| Numeric table columns | `max abs diff < 1e-3` and Pearson `r > 0.9994` vs baseline |
| Text table columns | identical |
| Code | no `stopifnot`, no `tryCatch`, no `awk`, no `system2` for data reads |
| Size | ~10,350 lines -> ~7,800 (-25%) |

Excluded from comparison: the `generated` timestamp in
`results/09_proteome_mr/ukb_ppp_proteome_run_metadata.tsv`.

## Starting state

| | lines |
|---|---|
| `config.R` | 894 |
| `helpers.R` | 1,479 (36 functions) |
| `analysis/*.R` (16) | 4,475 |
| `figures/*` (15) | 3,504 (1,806 python code lines) |

Defensive constructs: 90 `stopifnot`, 6 `tryCatch`, 13 file-existence guards,
7 `match.arg`, 12 `suppressWarnings`, 43 python guards, 212 `message()`.
Shell/regex: 14 `awk`, 22 `system2`, 17 `shQuote`, 27 `sub()`, 19 `grepl`,
176 `sprintf`. Column indirection: 43 `df[[cfg$...]]`, 29 `.data[[...]]`,
72 `cfg$*_col`.

## Dependency map

Hubs, 8 callers each: `read_region`, `load_instruments`, `interval_ld_matrix`.
Mid, 3-5 callers: `harmonise_region`, `ld_clump_local`, `run_mr`,
`verify_build`, `get_high_ld_snps`, `to_common`, `lookup_at`.
Single caller, to be inlined: `se_from_ci`, `se_from_p` (-> 12), `effective_n`
(-> 03), `report_missing` (-> 12), `read_significant`, `clump_key` (-> 07a),
`thin_genome` (-> 07b), `check_panel_freq` (-> 00),
`get_gene_coordinates_hg38` (-> 08).
Helpers-internal only: `panel_allele_freq` (<- `check_panel_freq`),
`nlog10_from_p` (<- `to_common`), `local_ld_calculation` (<- `ld_clump_local`).
Frozen defaults, never overridden anywhere (12): `pattern`, `drop_indels`,
`check_freq`, `tol`, `action`, `min_snps`, `p_threshold` x2, `stop`,
`plink2_bin`, `id_col`, `ensDb`.

## Stages

Each stage ends with a full 31-script run and a comparison against the frozen
baseline. A stage that fails reverts as a unit (`git revert`).

### Stage 0 — baseline

`results/` is currently a mix of the prune run and a partial smoke test. Run the
full pipeline once and freeze `results/` + `figures_out/` as the reference.

### Stage 1 — delete defensive code

Delete all 90 `stopifnot`, 6 `tryCatch`, 13 `if (!file.exists) stop()`,
7 `match.arg` (with the argument each validated), 12 `suppressWarnings`, and the
43 python guards. Keep `dir.create(showWarnings = FALSE)` — those create output
directories. Cannot change a number.

### Stage 2 — helpers.R: 36 functions -> 22

Inline the 9 single-caller helpers into their caller; fold the 3
helpers-internal functions into the function that calls them. Delete the 12
frozen parameters. Cut signatures: `ld_clump_local` 9 args -> `(variants, r2, kb)`,
`get_high_ld_snps` 9 -> `(leads, r2, kb)`.

Removed, 14 in total: 7 single-caller helpers, the 3 helpers-internal helpers,
and — once stage 3 lands — `reader_cmd`, `header_of` and `col_index`, which
exist only to build awk commands. `se_from_ci` and `se_from_p` look
single-caller but are called by `harmonise_region`, so they stay.

Survivors, 22: `read_region`, `harmonise_region`, `load_instruments`,
`interval_ld_matrix`, `run_mr`, `ld_clump_local`, `get_high_ld_snps`,
`to_common`, `lookup_at`, `calculate_maf`, `verify_build`, `se_from_ci`,
`se_from_p`, `to_panel_id`, `from_panel_id`, `nlrp3_scratch`, `scratch_file`,
`scratch_path`.

Target: ~600 lines, counting the shrinkage stage 3 brings to `read_region`
(64 -> ~10), `harmonise_region` (74 -> ~30) and `to_common` (78 -> ~40).

### Stage 3 — awk -> fread, and rename-on-read

The only stage that can move a number.

`read_region` becomes 4 arguments, no shell, and returns standard column names
for every GWAS:

```r
read_region <- function(cfg, chr, start, end) {
    cols <- c(chrom = cfg$chr_col, pos = cfg$pos_col, ea = cfg$ea_col,
              oa = cfg$oa_col, beta = cfg$effect_col, se = cfg$se_col,
              eaf = cfg$eaf_col, p = cfg$p_col)
    fread(cfg$file, select = unname(cols), data.table = FALSE) |>
        select(all_of(cols)) |>
        filter(chrom %in% c(chr, paste0("chr", chr)),
               pos >= start, pos <= end)
}
```

`select = ` keeps the worst file (neutrophil, 46.4M rows x 24 cols, 7.1 GB
uncompressed) near 5 GB rather than 15-20 GB. Scripts hold one file at a time.

Consequences:
- `extra_filter` (an awk string in config) becomes `gene_col = "phenotype_id"`
  plus `gene = NLRP3_ENSG` / `IL1RN_ENSG`.
- `harmonise_region` keeps `cfg` — it still needs `effect_type`, `se_source`,
  `neglog10_p` and `build` — but loses all 14 of its `.data[[cfg$*_col]]` uses.
- ~144 column-indirection sites disappear across the tree.
- `read_significant` -> `fread` + `filter`; `lookup_at` -> `fread` +
  `inner_join`; `thin_genome` -> `fread` + `group_by(bin) |> slice(1)`.
  No `semi_join` or `anti_join` — only `inner_join` and `left_join`.
- Step 12's private `read_nlrp3_region` is deleted as a duplicate.

Pre-flight, before the stage-wide change, confirm `fread` reproduces the awk
result on the four awkward files:

| file | issue |
|---|---|
| `coronary_atherosclerosis_finngen_R12.gz` | header column is literally `#chrom` |
| `pericarditis_decode.txt.gz` | config says `sep = "whitespace"`, header is tab-delimited |
| `nlrp3_eqtl_interval_chr1.tsv` | unnamed trailing columns; `select =` avoids them |
| `neutrophil_count_GCST90002351.h.tsv.gz` | 46.4M rows, memory ceiling |

Set the chromosome column to character via `colClasses` so `chrom %in% c(chr,
paste0("chr", chr))` is an explicit comparison rather than relying on coercion.
`filter()` preserves row order, so clumping ties do not move.

### Stage 4 — analysis scripts

Remove the remaining duplication (step 05's ad-hoc column literals -> the
`CAD_STUDIES` registry), flatten nested `sprintf`, drop `is.null()` branches
whose alternative never fires.

Reduce `message()` from 212 to about 45. Keep one line per external input read
and one per result that reaches a table or a figure. Delete section banners,
progress counters, and any message restating what the next line prints.

### Stage 5 — figures

New `figures/style.py`: the matplotlib and Open Sans setup currently duplicated
in 10 of 12 python files (~180 lines -> ~25), plus the shared mm-to-fraction
helpers. An R equivalent for the repeated `cairo_pdf_font` block.

**No layout constant is touched.** Font-list construction is moved verbatim,
because `font_manager.fontManager.ttflist` is order-sensitive.

### Stage 6 — final verification

Full run, full comparison, and re-measure every step's runtime so the SLURM
walltimes can be set to the measured maximum.

## Verification

Per stage: syntax check (`parse` for R, `py_compile` for python) -> full
31-script run -> comparison -> commit on pass.

A numeric comparator is required and does not exist yet. For every TSV it
compares rows positionally in file order — a reordering is itself a change worth
surfacing — and per numeric column reports `max abs diff` and Pearson `r`, so a regression is reported as "column X of table Y moved by Z" rather
than "differs". Figures are rasterised at 150 dpi and compared pixel-wise.

Resources: 5 cores (~34 GB) per job, at most 6 concurrent, one file in memory at
a time. Walltime 20 minutes, except stage 3 where steps 09, 11 and 12 get 90
minutes because full-file reads are materially slower; walltimes drop back to
the measured maximum at stage 6.

## Rollback

`git` tracks 34 files and one commit (`d52ca65`) is pushed to
`github.com/nickhir/NLRP3_MR_manuscript`. Each stage is one commit; a failed
stage is a `git revert`.

`.gitignore` excludes two files this work edits — `figures/fig04a_plof_violins.py`
(stage 5) and `README.md` (stage 4). No special handling: `fig04a` produces
Fig 4A, one of the 18 figures the pixel comparison checks every stage, so a
regression there is caught regardless; `README.md` is prose.

## Out of scope

- Changing any analysis method, threshold or model.
- Touching any figure layout constant.
- Re-deriving frozen constants (`N_EFFECTIVE_TESTS <- 1821`).
- Reinstating the outcomes or datasets pruned on 2026-09-16.
