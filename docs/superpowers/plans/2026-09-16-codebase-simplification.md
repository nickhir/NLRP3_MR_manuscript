# Codebase Simplification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Strip defensive code, unused flexibility and shell plumbing from a single-purpose manuscript-reproduction repository, without moving any published number.

**Architecture:** Six stages applied in order, each a single git commit. Every stage ends with a full 31-script SLURM run compared against a frozen baseline. Figures must stay pixel-identical; numeric table columns must stay within `max abs diff < 1e-3` and Pearson `r > 0.9994`. A stage that fails its comparison is reverted with `git revert` and redesigned.

**Tech Stack:** R 4.3.1 (`gcc/11 R/4.3.1-icelake`), `data.table`, `dplyr`; Python 3.6 (`/usr/bin/python3`, matplotlib 3.0.3) for figures; Python 3.10 (`/rds/user/nh608/hpc-work/software/micromamba/envs/limix_ieqtl/bin/python3`, numpy/pandas/Pillow) for the comparator; SLURM on CSD3 icelake-himem.

**Spec:** `docs/superpowers/specs/2026-09-16-codebase-simplification-design.md`

## Global Constraints

Every task's requirements implicitly include this section.

- **Repo root:** `/rds/user/nh608/hpc-work/NLRP3_MR_manuscript` (also reachable as `~/work_dir/NLRP3_MR_manuscript`).
- **Harness root:** `/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916`. Job scripts, logs and baselines live here, never in the repo — the repo's README states job scripts are scratch.
- **Figures pass criterion:** all 18 PDFs in `figures_out/`, rasterised at 150 dpi, must differ by **0 pixels**.
- **Tables pass criterion:** every numeric column `max abs diff < 1e-3` AND Pearson `r > 0.9994`; every text column identical.
- **Excluded from comparison:** the `generated` row of `results/09_proteome_mr/ukb_ppp_proteome_run_metadata.tsv`.
- **Forbidden in final code:** `stopifnot`, `tryCatch`, `try(`, `match.arg`, `suppressWarnings`, `awk`, `system2` for reading data (`system2` for plink2/gcta stays), `fread(cmd=)`, `semi_join`, `anti_join`.
- **Allowed join verbs:** `inner_join`, `left_join` only.
- **Memory:** one summary-statistics file in memory at a time. SLURM: `--cpus-per-task=5` (~34 GB) unless a task says otherwise.
- **Walltime:** `--time=00:20:00` unless a task says otherwise.
- **Concurrency:** at most 6 jobs at once.
- **Never change:** analysis methods, thresholds, models, figure layout constants, `N_EFFECTIVE_TESTS <- 1821`.
- **Do not run R or the pipeline on the login node.** Everything goes through `sbatch`.
- **Commit at the end of every task**, on the branch `simplify`.

---

## File Structure

**Created (harness, outside the repo):**
- `<harness>/compare_outputs.py` — the numeric + pixel comparator. One responsibility: given two output trees, report per-column deltas and per-figure pixel diffs, and exit non-zero on failure.
- `<harness>/test_compare_outputs.py` — unit tests for the comparator.
- `<harness>/run_step.sh` — SLURM wrapper running one script, writing a status file.
- `<harness>/submit_all.sh` — submits all 31 scripts as four dependency-chained waves.
- `<harness>/baseline/` — frozen `results/` and `figures_out/`.

**Created (repo):**
- `figures/style.py` — the matplotlib/Open Sans setup shared by 10 python figures (Task 9).

**Modified (repo):** `config.R`, `helpers.R`, all 16 `analysis/*.R`, all 11 `figures/*.py`, `figures/supp/leave_one_out_forest.py`, 4 `figures/*.R`.

---

## Task 1: The comparator

The only genuinely new code in this plan, and the only task with real unit tests. Everything after it depends on it being correct — a broken comparator silently passes a regression.

**Files:**
- Create: `/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916/compare_outputs.py`
- Test: `/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916/test_compare_outputs.py`

**Interfaces:**
- Consumes: nothing.
- Produces: `compare_outputs.py` run as `PY compare_outputs.py <baseline_dir> <repo_dir>`, exit 0 on pass and 1 on fail. `PY` is `/rds/user/nh608/hpc-work/software/micromamba/envs/limix_ieqtl/bin/python3`. Importable functions `compare_table(path_a, path_b) -> list[dict]` and `compare_figure(path_a, path_b) -> int` (pixels differing).

- [ ] **Step 1: Write the failing test**

Create `test_compare_outputs.py`:

```python
import os, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compare_outputs import compare_table

def write(path, text):
    with open(path, "w") as fh:
        fh.write(text)

def test_identical_tables_report_no_failures():
    d = tempfile.mkdtemp()
    a = os.path.join(d, "a.tsv"); b = os.path.join(d, "b.tsv")
    write(a, "key\tbeta\n1_1_A_C\t0.100000\n1_2_A_G\t-0.250000\n")
    write(b, "key\tbeta\n1_1_A_C\t0.100000\n1_2_A_G\t-0.250000\n")
    rows = compare_table(a, b)
    assert all(r["pass"] for r in rows), rows

def test_drift_within_tolerance_passes():
    d = tempfile.mkdtemp()
    a = os.path.join(d, "a.tsv"); b = os.path.join(d, "b.tsv")
    write(a, "key\tbeta\n1_1_A_C\t0.1000000\n1_2_A_G\t-0.2500000\n")
    write(b, "key\tbeta\n1_1_A_C\t0.1000004\n1_2_A_G\t-0.2500003\n")
    rows = compare_table(a, b)
    assert all(r["pass"] for r in rows), rows

def test_drift_beyond_tolerance_fails():
    d = tempfile.mkdtemp()
    a = os.path.join(d, "a.tsv"); b = os.path.join(d, "b.tsv")
    write(a, "key\tbeta\n1_1_A_C\t0.100\n1_2_A_G\t-0.250\n")
    write(b, "key\tbeta\n1_1_A_C\t0.250\n1_2_A_G\t-0.100\n")
    rows = compare_table(a, b)
    assert any(not r["pass"] for r in rows), rows

def test_changed_text_column_fails():
    d = tempfile.mkdtemp()
    a = os.path.join(d, "a.tsv"); b = os.path.join(d, "b.tsv")
    write(a, "key\tlabel\n1_1_A_C\tGout\n")
    write(b, "key\tlabel\n1_1_A_C\tAsthma\n")
    rows = compare_table(a, b)
    assert any(not r["pass"] for r in rows), rows

def test_row_count_change_fails():
    d = tempfile.mkdtemp()
    a = os.path.join(d, "a.tsv"); b = os.path.join(d, "b.tsv")
    write(a, "key\tbeta\n1_1_A_C\t0.1\n1_2_A_G\t0.2\n")
    write(b, "key\tbeta\n1_1_A_C\t0.1\n")
    rows = compare_table(a, b)
    assert any(not r["pass"] for r in rows), rows

def test_timestamp_row_is_ignored():
    d = tempfile.mkdtemp()
    a = os.path.join(d, "a.tsv"); b = os.path.join(d, "b.tsv")
    write(a, "field\tvalue\ngenerated\t2026-09-16 11:00:00\nassays\t2940\n")
    write(b, "field\tvalue\ngenerated\t2026-09-17 09:30:00\nassays\t2940\n")
    rows = compare_table(a, b)
    assert all(r["pass"] for r in rows), rows
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd /rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
/rds/user/nh608/hpc-work/software/micromamba/envs/limix_ieqtl/bin/python3 -m pytest test_compare_outputs.py -q
```

Expected: FAIL with `ModuleNotFoundError: No module named 'compare_outputs'`.

- [ ] **Step 3: Write the comparator**

Create `compare_outputs.py`:

```python
"""Compare a candidate output tree against a frozen baseline.

Tables: numeric columns within MAX_ABS_DIFF and above MIN_R; text columns exact.
Figures: PDFs rasterised at 150 dpi must be pixel-identical.
"""
import os
import subprocess
import sys
import tempfile

import numpy as np
import pandas as pd
from PIL import Image

MAX_ABS_DIFF = 1e-3
MIN_R = 0.9994
IGNORE_ROWS = {"generated"}


def compare_table(path_a, path_b):
    """Return one result dict per column: name, max_abs_diff, r, pass."""
    a = pd.read_csv(path_a, sep="\t", dtype=str, keep_default_na=False)
    b = pd.read_csv(path_b, sep="\t", dtype=str, keep_default_na=False)

    if not a.empty and a.columns[0] == "field":
        a = a[~a["field"].isin(IGNORE_ROWS)]
        b = b[~b["field"].isin(IGNORE_ROWS)]

    if list(a.columns) != list(b.columns):
        return [{"column": "<header>", "max_abs_diff": float("nan"),
                 "r": float("nan"), "pass": False,
                 "note": "column names differ"}]
    if len(a) != len(b):
        return [{"column": "<nrow>", "max_abs_diff": float("nan"),
                 "r": float("nan"), "pass": False,
                 "note": "%d rows vs %d" % (len(a), len(b))}]

    out = []
    for col in a.columns:
        va = pd.to_numeric(a[col], errors="coerce")
        vb = pd.to_numeric(b[col], errors="coerce")
        numeric = va.notna().any() and vb.notna().any()
        if not numeric:
            same = (a[col] == b[col]).all()
            out.append({"column": col, "max_abs_diff": 0.0 if same else float("nan"),
                        "r": float("nan"), "pass": bool(same),
                        "note": "" if same else "text differs"})
            continue
        both = va.notna() & vb.notna()
        if (va.notna() != vb.notna()).any():
            out.append({"column": col, "max_abs_diff": float("nan"),
                        "r": float("nan"), "pass": False,
                        "note": "NA pattern differs"})
            continue
        d = float(np.abs(va[both] - vb[both]).max()) if both.any() else 0.0
        if both.sum() > 1 and va[both].nunique() > 1 and vb[both].nunique() > 1:
            r = float(np.corrcoef(va[both], vb[both])[0, 1])
        else:
            r = 1.0
        ok = d < MAX_ABS_DIFF and r > MIN_R
        out.append({"column": col, "max_abs_diff": d, "r": r, "pass": bool(ok),
                    "note": ""})
    return out


def compare_figure(path_a, path_b, dpi=150):
    """Rasterise both PDFs and return the number of differing pixels."""
    def raster(path):
        tmp = tempfile.mkdtemp()
        stem = os.path.join(tmp, "page")
        subprocess.check_call(
            ["pdftoppm", "-png", "-r", str(dpi), "-singlefile", path, stem],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return np.asarray(Image.open(stem + ".png").convert("RGB")).astype(np.int16)

    a, b = raster(path_a), raster(path_b)
    if a.shape != b.shape:
        return -1
    return int((np.abs(a - b).max(axis=2) > 0).sum())


def main(baseline, candidate):
    failures = 0

    print("=" * 72)
    print("FIGURES")
    print("=" * 72)
    fig_base = os.path.join(baseline, "figures_out")
    for name in sorted(os.listdir(fig_base)):
        if not name.endswith(".pdf"):
            continue
        other = os.path.join(candidate, "figures_out", name)
        if not os.path.exists(other):
            print("  MISSING  %s" % name)
            failures += 1
            continue
        n = compare_figure(os.path.join(fig_base, name), other)
        if n == 0:
            continue
        print("  %-34s %s" % (name, "size mismatch" if n < 0 else "%d px differ" % n))
        failures += 1
    print("  %d figures compared, %d failing" %
          (len([f for f in os.listdir(fig_base) if f.endswith(".pdf")]), failures))

    print()
    print("=" * 72)
    print("TABLES")
    print("=" * 72)
    tab_base = os.path.join(baseline, "results")
    n_tables = 0
    for root, _, files in os.walk(tab_base):
        for name in sorted(files):
            if not name.endswith((".tsv", ".csv")):
                continue
            rel = os.path.relpath(os.path.join(root, name), tab_base)
            other = os.path.join(candidate, "results", rel)
            n_tables += 1
            if not os.path.exists(other):
                print("  MISSING  %s" % rel)
                failures += 1
                continue
            for r in compare_table(os.path.join(root, name), other):
                if r["pass"]:
                    continue
                print("  %-52s %-22s maxdiff=%s r=%s %s" %
                      (rel, r["column"], r["max_abs_diff"], r["r"], r.get("note", "")))
                failures += 1
    print("  %d tables compared, %d failing checks" % (n_tables, failures))

    print()
    print("VERDICT:", "PASS" if failures == 0 else "FAIL (%d)" % failures)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2]))
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
cd /rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
/rds/user/nh608/hpc-work/software/micromamba/envs/limix_ieqtl/bin/python3 -m pytest test_compare_outputs.py -q
```

Expected: `6 passed`.

- [ ] **Step 5: Verify the comparator detects a real regression**

Perturb one number in a real results file and confirm a FAIL, then restore:

```bash
cd /rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
REPO=/rds/user/nh608/hpc-work/NLRP3_MR_manuscript
mkdir -p /tmp/fake/results/06_mr_cardiometabolic
cp $REPO/results/06_mr_cardiometabolic/cardiometabolic_mr.tsv /tmp/fake/results/06_mr_cardiometabolic/
/rds/user/nh608/hpc-work/software/micromamba/envs/limix_ieqtl/bin/python3 - <<'EOF'
p = "/tmp/fake/results/06_mr_cardiometabolic/cardiometabolic_mr.tsv"
lines = open(p).read().split("\n")
parts = lines[1].split("\t"); parts[4] = str(float(parts[4]) + 0.05)  # col 4 = estimate
lines[1] = "\t".join(parts)
open(p, "w").write("\n".join(lines))
EOF
```

Then run `compare_table` on the two files and confirm at least one column reports `pass: False`.

- [ ] **Step 6: Commit**

```bash
cd /rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
# harness lives outside the repo and is not version controlled;
# record its existence in the repo instead
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
git checkout -b simplify
git commit --allow-empty -m "chore: start simplify branch; comparator built in trashtmp harness"
```

---

## Task 2: SLURM harness and frozen baseline

`results/` is currently a mix of the prune run and a partial smoke test that re-ran only 02/05/06/12. Nothing can be compared until one clean full run exists.

**Files:**
- Create: `<harness>/run_step.sh`, `<harness>/submit_all.sh`
- Create: `<harness>/baseline/results/`, `<harness>/baseline/figures_out/`

**Interfaces:**
- Consumes: `compare_outputs.py` from Task 1.
- Produces: `bash <harness>/submit_all.sh` submits 31 jobs in four waves and writes one status file per script to `<harness>/status/<tag>.status` whose first field is `OK` or `FAIL(rc=N)`. `<harness>/baseline/` is the reference every later task compares against.

- [ ] **Step 1: Copy the working harness from the previous refactor**

```bash
H=/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
mkdir -p $H/{jobs,logs,status,baseline}
for f in run_step.sh submit_all.sh; do
  sed 's|nlrp3_prune_20260916|nlrp3_simplify_20260916|g' \
    /rds/user/nh608/hpc-work/trashtmp/nlrp3_prune_20260916/jobs/$f > $H/$f
done
chmod +x $H/*.sh
grep -n "time=\|cpus-per-task" $H/run_step.sh
```

Expected: `--time=00:20:00`. Set `--cpus-per-task=5` in `run_step.sh` (the previous harness used per-step values).

- [ ] **Step 2: Clear the outputs and run the full pipeline**

```bash
H=/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
REPO=/rds/user/nh608/hpc-work/NLRP3_MR_manuscript
rm -rf $REPO/results $REPO/figures_out
mkdir -p $REPO/results $REPO/figures_out
cp -p $REPO/figures/assets/Fig4B_gof_carriers.pdf $REPO/figures_out/
rm -f $H/status/*.status
bash $H/submit_all.sh
```

`Fig4B_gof_carriers.pdf` is a supplied panel no script produces; `assemble_figures.py` fails without it.

- [ ] **Step 3: Wait for all 31 and confirm none failed**

```bash
H=/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
until [ "$(ls $H/status/*.status 2>/dev/null | wc -l)" -ge 31 ] \
   || [ "$(squeue -u $USER -h -o '%j' | grep -c '^s_')" -eq 0 ]; do sleep 30; done
ls $H/status/*.status | wc -l
grep -h '^FAIL' $H/status/*.status || echo "no failures"
ls $REPO/figures_out/*.pdf | wc -l
```

Expected: `31`, `no failures`, `18`.

- [ ] **Step 4: Freeze the baseline**

```bash
H=/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
REPO=/rds/user/nh608/hpc-work/NLRP3_MR_manuscript
rm -rf $H/baseline/results $H/baseline/figures_out
cp -a $REPO/results $H/baseline/results
cp -a $REPO/figures_out $H/baseline/figures_out
find $H/baseline -type f | wc -l
```

- [ ] **Step 5: Verify the comparator passes the baseline against itself**

```bash
/rds/user/nh608/hpc-work/software/micromamba/envs/limix_ieqtl/bin/python3 \
  $H/compare_outputs.py $H/baseline $REPO
```

Expected: `VERDICT: PASS`. If this fails, the comparator is wrong — fix it before going further.

- [ ] **Step 6: Commit**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
git commit --allow-empty -m "chore: freeze pipeline baseline for the simplification"
```

---

## Task 3: Stage 1 — delete defensive code

Mechanical and incapable of changing a number: every construct removed either aborts the run or suppresses a warning.

**Files:**
- Modify: `helpers.R` (8 `stopifnot`, 3 `match.arg`, 2 `suppressWarnings`, 3 file-existence guards)
- Modify: all 16 `analysis/*.R` (74 `stopifnot`, 6 `tryCatch`, 4 `match.arg`, 10 `suppressWarnings`, 7 file-existence guards)
- Modify: 10 `figures/*.py` and `figures/supp/leave_one_out_forest.py` (40 guards)

**Interfaces:**
- Consumes: the frozen baseline from Task 2.
- Produces: no interface change. Function signatures lose only the parameters that existed to be validated by `match.arg`.

- [ ] **Step 1: List every site so nothing is missed**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
grep -rn "stopifnot\|tryCatch\|match.arg\|suppressWarnings" config.R helpers.R analysis/*.R > /tmp/stage1_r.txt
grep -rn "raise SystemExit" figures/*.py figures/supp/*.py > /tmp/stage1_py.txt
wc -l /tmp/stage1_r.txt /tmp/stage1_py.txt
```

Expected: 116 R sites, ~20 python sites.

- [ ] **Step 2: Delete the R constructs**

Rules, applied by hand file by file:

- `stopifnot(...)` — delete the whole call, including multi-line ones.
- `tryCatch(expr, error = function(e) NULL)` — replace with `expr`.
- `match.arg(x)` — delete the line; change the parameter default from `c("tab", "whitespace")` to the value actually used, e.g. `sep = "tab"`.
- `suppressWarnings(expr)` — replace with `expr`.
- `if (!file.exists(f)) stop(...)` — delete the whole `if` block.
- **Keep** `dir.create(..., showWarnings = FALSE)`.

`analysis/07c_mediation.R` and `analysis/07d_mediation_waterfall.R` each contain one `tryCatch` guarding an MVMR fit; both become the bare call.

- [ ] **Step 3: Delete the python guards**

In each of the 10 python figures, delete blocks of this shape:

```python
if not IN_FILE.exists():
    raise SystemExit(f"missing input: {IN_FILE}\n"
                     f"Run analysis/04_mr_biomarkers.R first.")
```

`figures/assemble_figures.py` has 7, including `panel_pdf()`'s `raise SystemExit` for a missing panel — delete the `if not pdf.exists()` block and return `pdf` unconditionally.

- [ ] **Step 4: Syntax check**

```bash
H=/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
cat > $H/jobs/syntax.sh <<'EOS'
#!/bin/bash
#SBATCH -J x_syn -A BUTTERWORTH-SL3-CPU -p icelake-himem
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=2 --time=00:10:00
#SBATCH -o /rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916/logs/syntax.out
#SBATCH -e /rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916/logs/syntax.err
. /etc/profile.d/modules.sh
module purge >/dev/null 2>&1; module load rhel8/default-icl >/dev/null 2>&1
module load gcc/11 R/4.3.1-icelake >/dev/null 2>&1
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
for f in config.R helpers.R analysis/*.R figures/*.R; do
  Rscript -e "invisible(parse('$f'))" >/dev/null 2>&1 && echo "OK $f" || echo "PARSE-ERROR $f"
done
/usr/bin/python3 -m py_compile figures/*.py figures/supp/*.py && echo "OK python"
rm -rf figures/__pycache__ figures/supp/__pycache__
EOS
sbatch $H/jobs/syntax.sh
```

Expected: no `PARSE-ERROR`, `OK python`.

- [ ] **Step 5: Confirm the constructs are gone**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
grep -rc "stopifnot\|tryCatch\|match.arg\|suppressWarnings" config.R helpers.R analysis/*.R | grep -v ":0" || echo "clean"
grep -rc "raise SystemExit" figures/*.py figures/supp/*.py | grep -v ":0" || echo "clean"
```

Expected: `clean` twice.

- [ ] **Step 6: Full run and compare**

```bash
H=/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
REPO=/rds/user/nh608/hpc-work/NLRP3_MR_manuscript
rm -rf $REPO/results $REPO/figures_out; mkdir -p $REPO/results $REPO/figures_out
cp -p $REPO/figures/assets/Fig4B_gof_carriers.pdf $REPO/figures_out/
rm -f $H/status/*.status
bash $H/submit_all.sh
until [ "$(ls $H/status/*.status 2>/dev/null | wc -l)" -ge 31 ] \
   || [ "$(squeue -u $USER -h -o '%j' | grep -c '^s_')" -eq 0 ]; do sleep 30; done
grep -h '^FAIL' $H/status/*.status || echo "no failures"
/rds/user/nh608/hpc-work/software/micromamba/envs/limix_ieqtl/bin/python3 \
  $H/compare_outputs.py $H/baseline $REPO
```

Expected: `no failures` and `VERDICT: PASS`.

- [ ] **Step 7: Commit**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
git add -A
git commit -m "refactor: delete defensive code

Remove 90 stopifnot, 6 tryCatch, 13 file-existence guards, 7 match.arg,
12 suppressWarnings and 40 python input guards. The pipeline runs once on
frozen inputs; it either works or it does not.

Verified: 31/31 scripts OK, figures pixel-identical, tables within tolerance."
```

---

## Task 4: Stage 2 — helpers.R, 31 functions to 18

**Files:**
- Modify: `helpers.R` (1,479 lines -> ~600)
- Modify: `analysis/00_instrument_selection.R` (receives `check_panel_freq`)
- Modify: `analysis/03_instrument_strength.R` (receives `effective_n`)
- Modify: `analysis/07a_mediator_instruments.R` (receives `read_significant`, `clump_key`)
- Modify: `analysis/07b_sample_overlap.R` (receives `thin_genome`)
- Modify: `analysis/08_il1rn_positive_control.R` (receives `get_gene_coordinates_hg38`)
- Modify: `analysis/12_mr_indications.R` (receives `se_from_ci`, `se_from_p`, `report_missing`)

**Interfaces:**
- Consumes: the Stage 1 tree.
- Produces: `helpers.R` exporting exactly these 18 — `read_region`, `harmonise_region`, `load_instruments`, `interval_ld_matrix`, `run_mr`, `ld_clump_local`, `get_high_ld_snps`, `to_common`, `lookup_at`, `calculate_maf`, `verify_build`, `se_from_ci`, `se_from_p`, `to_panel_id`, `from_panel_id`, `nlrp3_scratch`, `scratch_file`, `scratch_path`. New signatures: `ld_clump_local(variants, r2, kb)`, `get_high_ld_snps(leads, r2, kb)`.

- [ ] **Step 1: Move the 7 single-caller helpers into their callers**

Cut each function body from `helpers.R` and paste it into the one script that calls it, directly above first use. The mapping is exact:

| function | lines in helpers.R | destination |
|---|---|---|
| `effective_n` | 5 | `analysis/03_instrument_strength.R` |
| `report_missing` | 34 | `analysis/12_mr_indications.R` |
| `read_significant` | 42 | `analysis/07a_mediator_instruments.R` |
| `clump_key` | 11 | `analysis/07a_mediator_instruments.R` |
| `thin_genome` | 21 | `analysis/07b_sample_overlap.R` |
| `check_panel_freq` | 58 | `analysis/00_instrument_selection.R` |
| `get_gene_coordinates_hg38` | 52 | `analysis/08_il1rn_positive_control.R` |

`se_from_ci` and `se_from_p` look like single-caller helpers but are not: `harmonise_region` calls both (`helpers.R` lines 17 and 21 of its body), and `harmonise_region` stays. Leave them in `helpers.R`; `analysis/12_mr_indications.R` uses them from there.

Removals total 13 — these 7, the 3 helpers-internal functions in Step 2, and `reader_cmd` / `header_of` / `col_index` in Task 6 Step 5. 31 - 13 = 18.

- [ ] **Step 2: Fold the 3 helpers-internal functions into their caller**

- `panel_allele_freq` (46 lines) has one caller, `check_panel_freq`, which Step 1 just moved into `analysis/00_instrument_selection.R`. Move `panel_allele_freq` there too and inline it into `check_panel_freq`.
- `nlog10_from_p` (11 lines) has one caller, `to_common`. Inline its body at `helpers.R` line ~827.
- `local_ld_calculation` (80 lines) has one caller, `ld_clump_local`. Inline its body.

- [ ] **Step 3: Delete the 12 frozen parameters**

Each of these is never passed a non-default value anywhere. Delete the parameter and substitute its default into the body:

| function | parameter | frozen value |
|---|---|---|
| `scratch_file` | `pattern` | `"file"` |
| `harmonise_region` | `drop_indels` | `TRUE` |
| `load_instruments` | `check_freq` | its default |
| `check_panel_freq` | `tol`, `action` | their defaults |
| `run_mr` | `min_snps` | `3L` |
| `read_significant` | `p_threshold` | its default |
| `clump_key` | `p_threshold` | its default |
| `get_high_ld_snps` | `stop` | its default |
| `calculate_maf` | `plink2_bin` | `plink2_bin` from `config.R` |
| `ld_clump_local` | `id_col` | its default |
| `get_gene_coordinates_hg38` | `ensDb` | its default |

- [ ] **Step 4: Cut the two 9-argument signatures**

`ld_clump_local` becomes `ld_clump_local(variants, r2, kb)` and `get_high_ld_snps` becomes `get_high_ld_snps(leads, r2, kb)`. The remaining arguments — `panel`, `plink2`, `threads`, `p_col`, `chr`, `start`, `stop` — all take their values from `config.R` constants (`ld_panel`, `plink2_bin`) or are frozen. Update the 4 and 3 call sites respectively:

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
grep -rn "ld_clump_local(\|get_high_ld_snps(" analysis/*.R
```

- [ ] **Step 5: Confirm the function inventory**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
grep -cE "^[a-z_0-9.]+ <- function" helpers.R
wc -l helpers.R
```

Expected: `18` after Task 6 deletes the three awk builders, `21` at the end of this task, and roughly 600 lines.

- [ ] **Step 6: Syntax check, full run, compare**

Run Step 4 of Task 3 (syntax), then Step 6 of Task 3 (full run + compare).

Expected: `no failures`, `VERDICT: PASS`.

- [ ] **Step 7: Commit**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
git add -A
git commit -m "refactor: slim helpers.R from 31 functions to 16

Inline the single-caller helpers into their one caller, fold the three
helpers-internal functions into the function that calls them, delete 12
parameters that were never given a non-default value, and cut
ld_clump_local and get_high_ld_snps from nine arguments to three.

Verified: 31/31 scripts OK, figures pixel-identical, tables within tolerance."
```

---

## Task 5: Stage 3a — fread pre-flight on the four awkward files

The riskiest stage, de-risked before it is applied anywhere. Each of these four files has a property the awk path handles by hand.

**Files:**
- Create: `<harness>/jobs/preflight.R`, `<harness>/jobs/preflight.sh`

**Interfaces:**
- Consumes: the Stage 2 tree.
- Produces: a printed confirmation, per file, that `fread` + `filter` returns the same rows and values as the current `read_region`. No repo change.

- [ ] **Step 1: Write the pre-flight script**

Create `<harness>/jobs/preflight.R`:

```r
suppressPackageStartupMessages({library(tidyverse); library(data.table); library(here)})
setwd("/rds/user/nh608/hpc-work/NLRP3_MR_manuscript")
source(here::here("config.R"))
source(here::here("helpers.R"))

check <- function(label, file, chr_col, pos_col, chr, start, end, sep = "tab") {
    old <- read_region(file, chr_col, pos_col, chr, start, end, sep = sep)
    new <- fread(file, data.table = FALSE) |>
        filter(.data[[chr_col]] %in% c(chr, paste0("chr", chr)),
               .data[[pos_col]] >= start, .data[[pos_col]] <= end)
    cat(sprintf("%-28s awk rows=%d  fread rows=%d  header match=%s\n",
                label, nrow(old), nrow(new),
                identical(sort(names(old)), sort(names(new)))))
    shared <- intersect(names(old), names(new))
    for (cl in shared) {
        a <- old[[cl]]; b <- new[[cl]]
        if (is.numeric(a) && is.numeric(b) && length(a) == length(b)) {
            d <- max(abs(a - b), na.rm = TRUE)
            if (!is.finite(d) || d > 1e-9) cat(sprintf("    column %s max diff %g\n", cl, d))
        }
    }
}

check("finngen (#chrom)", file.path(dataset_dir, "coronary_atherosclerosis_finngen_R12.gz"),
      "#chrom", "pos", 1L, 247390000L, 247650000L)
check("pericarditis (whitespace)", OUTCOMES$pericarditis$file,
      OUTCOMES$pericarditis$chr_col, OUTCOMES$pericarditis$pos_col,
      1L, 247390000L, 247650000L, sep = "whitespace")
check("interval eqtl (unnamed cols)", READOUTS$NLRP3_expression$file,
      READOUTS$NLRP3_expression$chr_col, READOUTS$NLRP3_expression$pos_col,
      1L, 247390000L, 247650000L)
cat("\nneutrophil memory probe\n")
t0 <- Sys.time()
n <- fread(READOUTS$Neutrophil_count$file,
           select = c("hm_chrom", "hm_pos", "hm_effect_allele", "hm_other_allele",
                      "hm_beta", "standard_error", "p_value",
                      "hm_effect_allele_frequency", "hm_rsid"),
           data.table = FALSE)
cat(sprintf("  rows=%d  elapsed=%.0fs  size=%.1f GB\n",
            nrow(n), as.numeric(difftime(Sys.time(), t0, units = "secs")),
            as.numeric(object.size(n)) / 1e9))
```

- [ ] **Step 2: Submit it with generous resources**

```bash
H=/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
cat > $H/jobs/preflight.sh <<'EOS'
#!/bin/bash
#SBATCH -J x_pre -A BUTTERWORTH-SL3-CPU -p icelake-himem
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --time=00:45:00
#SBATCH -o /rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916/logs/preflight.out
#SBATCH -e /rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916/logs/preflight.err
. /etc/profile.d/modules.sh
module purge >/dev/null 2>&1; module load rhel8/default-icl >/dev/null 2>&1
module load gcc/11 R/4.3.1-icelake >/dev/null 2>&1
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
Rscript /rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916/jobs/preflight.R
EOS
sbatch $H/jobs/preflight.sh
```

`--cpus-per-task=8` (~54 GB) only here, to measure the true ceiling before committing to 5.

- [ ] **Step 3: Read the result and decide**

```bash
cat /rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916/logs/preflight.out
```

Expected: identical row counts for all three files, no column diff lines, and a neutrophil size under 6 GB. Act on what it says:

- If FinnGen's header comes back as anything other than `#chrom`, add `check.names = FALSE` to the `fread` call in the Task 6 `read_region`.
- If pericarditis row counts differ, keep `sep` handling: pass `sep = " "` to `fread` for that file via a `cfg$sep` entry.
- If the neutrophil object exceeds ~10 GB, keep `--cpus-per-task=8` for steps 09, 11 and 12 instead of 5.

- [ ] **Step 4: Record the findings in the plan**

Append the measured numbers to this task as a comment so Task 6 can be written against facts rather than assumptions. No commit — nothing in the repo changed.

---

## Task 6: Stage 3b — read_region and rename-on-read

**Files:**
- Modify: `helpers.R` — `read_region`, `harmonise_region`, delete `reader_cmd`, `header_of`, `col_index`
- Modify: `config.R` — replace `extra_filter` with `gene_col` + `gene`
- Modify: `analysis/00,01,02,04,05,06,08,11` — the 8 `read_region` call sites

**Interfaces:**
- Consumes: the Task 5 findings.
- Produces: `read_region(cfg, chr, start, end)` returning a data frame whose columns are always named `chrom, pos, ea, oa, beta, se, eaf, p` (plus `rsid` and `gene` where the config names them). `harmonise_region(df, chr)` — no `cfg` argument.

- [ ] **Step 1: Rewrite read_region**

Replace the whole function in `helpers.R`:

```r
# Read one chromosome window out of a summary-statistics file. Column names are
# standardised on the way in, so every caller downstream sees the same eight.
read_region <- function(cfg, chr, start, end) {
    cols <- c(chrom = cfg$chr_col, pos = cfg$pos_col, ea = cfg$ea_col,
              oa = cfg$oa_col, beta = cfg$effect_col, se = cfg$se_col,
              eaf = cfg$eaf_col, p = cfg$p_col, rsid = cfg$rsid_col,
              gene = cfg$gene_col, ci_lower = cfg$ci_lower_col,
              ci_upper = cfg$ci_upper_col)
    df <- fread(cfg$file, select = unname(cols), colClasses = list(character = cfg$chr_col),
                data.table = FALSE) |>
        select(all_of(cols)) |>
        filter(chrom %in% c(as.character(chr), paste0("chr", chr)),
               pos >= start, pos <= end)
    if (!is.null(cfg$gene)) df <- filter(df, gene == cfg$gene)
    df
}
```

`cols` drops `NULL` entries automatically because `c()` on a list with `NULL` omits them, so a config without `eaf_col` simply yields no `eaf` column.

- [ ] **Step 2: Replace extra_filter in config.R**

```r
# before
extra_filter = sprintf("$1==\"%s\"", NLRP3_ENSG)

# after
gene_col = "phenotype_id",
gene = NLRP3_ENSG
```

Do the same for `IL1RN_ENSG` in `analysis/08_il1rn_positive_control.R` line ~208.

- [ ] **Step 3: Simplify harmonise_region**

It no longer needs `cfg` for column names, only for `effect_type`, `se_source`, `neglog10_p` and `build`. Change the signature to `harmonise_region(df, cfg, chr)` — keep `cfg` for those four — and replace every `std[[cfg$*_col]]` with the standard name:

```r
harmonise_region <- function(df, cfg, chr) {
    std <- df |>
        mutate(pos = as.integer(pos), ea = toupper(ea), oa = toupper(oa),
               beta = as.numeric(beta))
    if (identical(cfg$effect_type, "OR")) std$beta <- log(std$beta)
    std$se <- switch(
        if (is.null(cfg$se_source)) "column" else cfg$se_source,
        column = as.numeric(std$se),
        ci = se_from_ci(as.numeric(std$ci_lower), as.numeric(std$ci_upper)),
        p = se_from_p(std$beta, as.numeric(std$p)))
    std$p <- if (isTRUE(cfg$neglog10_p)) 10^(-as.numeric(std$p)) else as.numeric(std$p)
    std <- filter(std, !is.na(beta), !is.na(se), se > 0,
                  ea %in% c("A","C","G","T"), oa %in% c("A","C","G","T"))
    ...
}
```

Keep the GRCh37 build-mapping block that follows unchanged apart from column names.

- [ ] **Step 4: Update the 8 call sites**

Seven already pass a registry `cfg` and collapse from six arguments to four:

```r
# before
read_region(cfg$file, cfg$chr_col, cfg$pos_col, CHR, LOCUS_START, LOCUS_END,
            extra_filter = cfg$extra_filter)
# after
read_region(cfg, CHR, LOCUS_START, LOCUS_END)
```

`analysis/05_mr_cad.R` passes literal column names for Aragam, MVP and FinnGen. Replace those three calls with the `CAD_STUDIES` entries already in `config.R`:

```r
aragam  <- read_region(CAD_STUDIES$aragam,  CHR, REGION_START, REGION_END)
mvp     <- read_region(CAD_STUDIES$mvp,     CHR, REGION_START, REGION_END)
finngen <- read_region(CAD_STUDIES$finngen, CHR, REGION_START, REGION_END)
```

Then drop the `transmute(join_pos = ..., ea = ..., ...)` that followed each, because the columns already carry those names — keep only `join_pos = pos`.

- [ ] **Step 5: Delete the awk builders**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
# reader_cmd, header_of and col_index exist only to build awk commands
grep -rn "reader_cmd\|header_of\|col_index" helpers.R analysis/*.R
```

Delete all three from `helpers.R` and every remaining reference.

- [ ] **Step 6: Syntax check, full run, compare**

Run Step 4 of Task 3 (syntax). Then the full run, but with raised limits for this stage only:

```bash
H=/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
sed -i 's|--time=00:20:00|--time=01:30:00|' $H/run_step.sh
# then the standard clear / submit / wait / compare from Task 3 Step 6
```

Expected: `no failures`, `VERDICT: PASS`. This is the stage most likely to report a column delta — if one appears, the comparator names the file and column; diagnose that one file rather than reverting the whole stage.

- [ ] **Step 7: Commit**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
git add -A
git commit -m "refactor: replace awk region filtering with fread and dplyr

read_region takes a config entry and standardises column names on read, so
downstream code uses plain dplyr instead of df[[cfg\$chr_col]]. Removes the
awk command builders and ~144 column-indirection sites.

Verified: 31/31 scripts OK, figures pixel-identical, tables within tolerance."
```

---

## Task 7: Stage 3c — the three remaining awk sites

**Files:**
- Modify: `helpers.R` — `lookup_at`
- Modify: `analysis/07a_mediator_instruments.R` (`read_significant`, `clump_key`, 2 `lookup_at` call sites)
- Modify: `analysis/07b_sample_overlap.R` (`thin_genome`, 1 `lookup_at` call site)
- Modify: `analysis/07c_mediation.R` (2 `lookup_at` call sites)
- Modify: `analysis/08_il1rn_positive_control.R` line ~435, `analysis/12_mr_indications.R`

**Interfaces:**
- Consumes: the Task 6 tree.
- Produces: zero `awk` and zero `fread(cmd=)` anywhere in the repo.

- [ ] **Step 1: Rewrite read_significant**

Genome-wide p-value filter, currently `helpers.R:771`. In `analysis/07a_mediator_instruments.R`:

```r
read_significant <- function(cfg) {
    fread(cfg$file, select = unname(c(chrom = cfg$chr_col, pos = cfg$pos_col,
                                      ea = cfg$ea_col, oa = cfg$oa_col,
                                      beta = cfg$effect_col, se = cfg$se_col,
                                      p = cfg$p_col)),
          data.table = FALSE) |>
        filter(p < MED_CLUMP_P)
}
```

- [ ] **Step 2: Rewrite lookup_at**

Currently an awk join against a keep-list, `helpers.R:881`. Use `inner_join`:

```r
lookup_at <- function(cfg, want) {
    fread(cfg$file, data.table = FALSE) |>
        rename(chrom = all_of(cfg$chr_col), pos = all_of(cfg$pos_col)) |>
        mutate(chrom = sub("^chr", "", chrom)) |>
        inner_join(want, by = c("chrom", "pos"))
}
```

`want` is a data frame with `chrom` and `pos`. `inner_join` keeps only matching rows, which is what the awk did.

There are **5 call sites**, not 3 — `07a` lines 64 and 107, `07b` line 38, `07c` lines 109 and 296 — all currently `lookup_at(cfg, ids, chr, pos, label)`. Each becomes `lookup_at(cfg, want)` where `want <- tibble(chrom = ..., pos = ...)`.

- [ ] **Step 3: Rewrite thin_genome**

One variant per 100 kb bin, currently `helpers.R:922`. In `analysis/07b_sample_overlap.R`:

```r
thin_genome <- function(cfg, bin_bp) {
    fread(cfg$file, select = unname(c(chrom = cfg$chr_col, pos = cfg$pos_col)),
          data.table = FALSE) |>
        mutate(chrom = sub("^chr", "", chrom), bin = floor(pos / bin_bp)) |>
        group_by(chrom, bin) |>
        slice(1) |>
        ungroup()
}
```

`slice(1)` takes the first row per bin, matching awk's `if (!(k in seen))`.

- [ ] **Step 4: Rewrite the two script-local awk calls**

`analysis/08_il1rn_positive_control.R` line ~435 filters the rsID map to one chromosome:

```r
rsid_map <- fread(rsid_map_file, data.table = FALSE) |>
    filter(chr == paste0("chr", CHR), pos %in% variants$position_hg38) |>
    transmute(position_hg38 = as.integer(pos), rsid_map = rsid)
```

`analysis/12_mr_indications.R` still holds `read_nlrp3_region`, a duplicate of `read_region`. Delete it and call `read_region(cfg, CHR, INDICATION_REGION_START, INDICATION_REGION_END)`.

- [ ] **Step 5: Confirm the shell is gone**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
grep -rn "awk\|fread(cmd\|shQuote" helpers.R analysis/*.R | grep -v "plink2\|gcta" || echo "clean"
```

Expected: `clean`. `system2` calls to plink2 and GCTA remain and are allowed.

- [ ] **Step 6: Syntax check, full run, compare**

As Task 6 Step 6, keeping the raised walltime.

Expected: `no failures`, `VERDICT: PASS`.

- [ ] **Step 7: Commit**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
git add -A
git commit -m "refactor: remove the last awk sites

read_significant, lookup_at and thin_genome become fread plus filter,
inner_join and group_by/slice. Step 12's duplicate region reader is deleted.
No awk, no fread(cmd=) and no shQuote for data reads remain.

Verified: 31/31 scripts OK, figures pixel-identical, tables within tolerance."
```

---

## Task 8: Stage 4 — analysis scripts and messages

**Files:**
- Modify: all 16 `analysis/*.R`
- Modify: `README.md`

**Interfaces:**
- Consumes: the Task 7 tree.
- Produces: no interface change. `message()` count drops from 212 to about 45.

- [ ] **Step 1: Count the starting point**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
grep -c "message(" analysis/*.R helpers.R | sort -t: -k2 -rn
```

- [ ] **Step 2: Apply the message rule**

Keep exactly two kinds of line, delete everything else:

1. One line per **external input read** — e.g. `"  Alcohol (GCST007461, GRCh37) ..."`, `"build check: 8/8 at GRCh38"`.
2. One line per **result that reaches a table or a figure** — e.g. the `IVW:` blocks in step 06, `"8/8 instruments"`, `"PC1 explains 96.8% of variance"`.

Delete: section banners (`"## ---- step 3 ----"`), progress counters (`"  processing 1200 of 2940"`), and any message whose content the next `print()` already shows.

Target roughly: 00→6, 01→4, 04→3, 06→4, 07a→4, 07b→3, 07c→5, 07d→3, 08→6, 09→3, 10→2, 11→4, 12→3, helpers→0.

- [ ] **Step 3: Remove the remaining duplication**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
grep -rn "is.null(" analysis/*.R | wc -l
```

For each `is.null()` branch, check whether the alternative ever fires given the frozen config; if not, keep only the branch that runs. Flatten nested `sprintf(sprintf(...))` into single calls.

- [ ] **Step 4: Update README.md**

The `datasets/` entry count and the "Running" section still describe the pre-simplification tree. Update the line counts and drop any mention of `awk`, `stopifnot` or the removed helpers.

- [ ] **Step 5: Syntax check, full run, compare**

As Task 3 Steps 4 and 6. Restore the standard walltime first if Task 6 raised it and the measured runtimes allow:

```bash
H=/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
grep -n "time=" $H/run_step.sh
```

Expected: `no failures`, `VERDICT: PASS`.

- [ ] **Step 6: Commit**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
git add -A
git commit -m "refactor: simplify the analysis scripts

Cut message() from 212 to ~45 - one line per input read and one per result
that reaches a table or figure. Remove is.null branches that never fire and
flatten nested sprintf. README updated.

Verified: 31/31 scripts OK, figures pixel-identical, tables within tolerance."
```

---

## Task 9: Stage 5 — figures

The font block is byte-identical across all 10 python figures (md5 `302d1e2ab1af`), so this is a literal move. **No layout constant changes.**

**Files:**
- Create: `figures/style.py`
- Modify: 10 `figures/*.py`, `figures/supp/leave_one_out_forest.py`
- Modify: 4 `figures/*.R`

**Interfaces:**
- Consumes: the Task 8 tree.
- Produces: `figures/style.py` exporting `apply_style()`, which sets the rcParams and prunes `fontManager.ttflist`. Every python figure calls it once after importing matplotlib.

- [ ] **Step 1: Create figures/style.py**

```python
"""Shared matplotlib setup. One typeface across every panel, R and Python alike."""
import os

os.environ.setdefault("MPLCONFIGDIR", "/tmp/mplconfig")
os.makedirs(os.environ["MPLCONFIGDIR"], exist_ok=True)

import matplotlib
matplotlib.use("Agg")
from matplotlib import rcParams, font_manager


def apply_style():
    rcParams["pdf.fonttype"] = 42
    rcParams["ps.fonttype"] = 42
    rcParams["font.family"] = "Open Sans"
    rcParams["font.weight"] = "semibold"
    # matplotlib registers OpenSans-Bold.ttf AND OpenSans-ExtraBold.ttf under the
    # same family at the same weight, so which one fontweight="bold" gets is
    # decided by the order of fontManager.ttflist.
    font_manager.fontManager.ttflist = [
        f for f in font_manager.fontManager.ttflist
        if "OpenSans-ExtraBold" not in f.fname
    ]
```

- [ ] **Step 2: Replace the block in each python figure**

In each of the 10 files plus `supp/leave_one_out_forest.py`, delete the `os.environ.setdefault(...)` through the `font_manager.fontManager.ttflist = [...]` block and replace with:

```python
from style import apply_style
apply_style()
import matplotlib.pyplot as plt
```

`figures/supp/leave_one_out_forest.py` already inserts `figures/` on `sys.path` for `forest_ticks`, so `from style import apply_style` resolves there too.

- [ ] **Step 3: Remove the forbidden constructs the R figures still carry**

Task 3's file list did not cover `figures/*.R`, so 8 constructs survive there and the Global
Constraints forbid them repo-wide. Delete them:

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
grep -nE "stopifnot|tryCatch|match\.arg|suppressWarnings" figures/*.R
```

Expected: 3 in `fig02b_instrument_forest.R`, 3 in `fig02a_locuszoom.R`, 2 in
`fig04c_il1rn_instrument_forest.R`. Same rules as Task 3: delete the whole call, keep
`dir.create(showWarnings = FALSE)`.

Also clear the dead residue Task 3's review noted, now that its guards are gone:
`drop` in `figures/fig03e_mediation_waterfall.py`, and `missing` / `off_scale` in
`figures/fig05_indications_forest.py` — variables computed only to feed a deleted guard.

- [ ] **Step 4: Do the same for the R figures**

`fig02a_locuszoom.R`, `fig02b_instrument_forest.R`, `fig04c_il1rn_instrument_forest.R` and `fig04e_ora_dotplot.R` each define an identical `cairo_pdf_font`. Move it to `helpers.R` (which they already source) and delete the four copies.

- [ ] **Step 5: Confirm no layout constant moved**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
git diff --stat
git diff | grep -E "^[+-]" | grep -E "FIG_W_MM|FIG_H_MM|X_LO|X_HI|ROW_SPACING|Y_|FS_|_C =|0\.[0-9]{3}" || echo "no layout constants touched"
```

Expected: `no layout constants touched`.

- [ ] **Step 6: Syntax check, full run, compare**

As Task 3 Steps 4 and 6. The figure comparison is the real test here — a font-ordering mistake shows as thousands of differing pixels.

Expected: `no failures`, `VERDICT: PASS`.

- [ ] **Step 7: Commit**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
git add -A
git commit -m "refactor: share the figure style setup

figures/style.py holds the matplotlib and Open Sans setup that was
byte-identical in 10 of 12 python figures; cairo_pdf_font moves to helpers.R
for the four R figures. No layout constant changed.

Verified: 31/31 scripts OK, figures pixel-identical, tables within tolerance."
```

---

## Task 10: Stage 6 — final verification and walltime calibration

**Files:**
- Modify: `<harness>/run_step.sh`

**Interfaces:**
- Consumes: the Task 9 tree.
- Produces: a final comparison report and measured walltimes.

- [ ] **Step 1: Clean full run from scratch**

```bash
H=/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
REPO=/rds/user/nh608/hpc-work/NLRP3_MR_manuscript
rm -rf $REPO/results $REPO/figures_out; mkdir -p $REPO/results $REPO/figures_out
cp -p $REPO/figures/assets/Fig4B_gof_carriers.pdf $REPO/figures_out/
rm -f $H/status/*.status
bash $H/submit_all.sh
```

- [ ] **Step 2: Compare**

```bash
/rds/user/nh608/hpc-work/software/micromamba/envs/limix_ieqtl/bin/python3 \
  $H/compare_outputs.py $H/baseline $REPO
```

Expected: `VERDICT: PASS`.

- [ ] **Step 3: Measure runtimes and set walltimes**

```bash
H=/rds/user/nh608/hpc-work/trashtmp/nlrp3_simplify_20260916
cat $H/status/*.status | awk -F'\t' '{print $3, $2}' | sort -r
```

Set `--time` in `run_step.sh` to twice the longest measured step, rounded up to the next five minutes. Record the number here.

- [ ] **Step 4: Confirm the end state against the spec's success criteria**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
echo "lines: $(cat config.R helpers.R analysis/*.R figures/*.R figures/*.py figures/supp/*.py | wc -l)"
echo "helpers functions: $(grep -cE '^[a-z_0-9.]+ <- function' helpers.R)"
for p in stopifnot tryCatch match.arg suppressWarnings awk 'fread(cmd' semi_join anti_join; do
  printf "  %-18s %s\n" "$p" "$(grep -rF "$p" config.R helpers.R analysis figures 2>/dev/null | grep -v Binary | wc -l)"
done
```

Expected: ~7,800 lines, 16 helper functions, and 0 for every forbidden construct.

- [ ] **Step 5: Merge and push**

```bash
cd /rds/user/nh608/hpc-work/NLRP3_MR_manuscript
git checkout main 2>/dev/null || git checkout master
git merge --no-ff simplify -m "Simplify the codebase

Six staged refactors, each verified by a full pipeline re-run against a
frozen baseline. Figures pixel-identical throughout; table columns within
1e-3 and r > 0.9994."
git push origin HEAD
```

- [ ] **Step 6: Report**

Produce a short summary: lines before and after per file, the forbidden-construct counts, the final comparison verdict, and the measured runtimes.
