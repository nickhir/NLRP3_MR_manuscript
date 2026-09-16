#!/usr/bin/env python3
# Fig 3B - imaging forest.
#
# Forest panel of the imaging outcomes.
# Reads results/12_mr_indications/, writes figures_out/Fig3B_imaging_forest.pdf.

import csv
import math
import os
from pathlib import Path

os.environ.setdefault("MPLCONFIGDIR", "/tmp/mplconfig")
os.makedirs(os.environ["MPLCONFIGDIR"], exist_ok=True)

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import rcParams, font_manager

from forest_ticks import minor_ticks

SCRIPT_DIR = Path(__file__).resolve().parent
ANALYSIS_DIR = SCRIPT_DIR.parent
IN_FILE = ANALYSIS_DIR / "results" / "12_mr_indications" / \
    "additional_indications_mr_results.tsv"
OUT_DIR = ANALYSIS_DIR / "figures_out"
OUT_DIR.mkdir(parents=True, exist_ok=True)

if not IN_FILE.exists():
    raise SystemExit(f"missing input: {IN_FILE}\n"
                     f"Run analysis/12_mr_indications.R first.")

# FONT. The Figure 2 convention - see figures/fig02c_validation_forest.py.
rcParams["pdf.fonttype"] = 42
rcParams["ps.fonttype"] = 42
rcParams["font.family"] = "Open Sans"
rcParams["font.weight"] = "semibold"

# matplotlib registers OpenSans-Bold.ttf AND OpenSans-ExtraBold.ttf under the
# same family at the same weight ("bold"), so which one fontweight="bold" gets
# is decided by the order of fontManager.ttflist.
font_manager.fontManager.ttflist = [
    f for f in font_manager.fontManager.ttflist
    if "OpenSans-ExtraBold" not in f.fname
]

FS_BODY, FS_SMALL, FS_HEADER, FS_TICK, FS_GROUP, FS_XLAB = 8.0, 7.0, 8.0, 7.6, 8.0, 7.6
IVW_C, WM_C = "#C0392B", "#2C6FB5"
METHODS = [("IVW (LD-corrected)", "ivw", IVW_C), ("Weighted median", "wm", WM_C)]

# key in the results file -> (display name, N)
SD_BLOCK = [("Coronary artery calcification (Agatston, CT)",
             "Coronary artery calcification", 26_000)]
OR_BLOCK = [("Coronary plaque burden (SIS, CTA)", "Coronary plaque burden", 24_811),
            ("Carotid plaque (ultrasound)", "Carotid plaque", 26_807)]


def load():
    rows = {}
    with open(IN_FILE) as fh:
        for r in csv.DictReader(fh, delimiter="\t"):
            slot = next((s for m, s, _ in METHODS if r["method"] == m), None)
            if slot is None:
                continue
            rows.setdefault(r["outcome"], {})[slot] = (
                float(r["estimate"]), float(r["ci_lower"]),
                float(r["ci_upper"]), float(r["p"]))
    wanted = [k for k, *_ in SD_BLOCK + OR_BLOCK]
    missing = [k for k in wanted if k not in rows]
    if missing:
        raise SystemExit(f"missing outcomes in {IN_FILE}: {missing}")
    incomplete = [k for k in wanted if len(rows[k]) != 2]
    if incomplete:
        raise SystemExit(f"outcomes lacking both methods: {incomplete}")
    return rows


ROWS = load()


def fmt_p(p):
    return f"{p:.3f}" if p >= 0.001 else f"{p:.1e}".replace("e-0", "e-")


FIG_W_MM, FIG_H_MM = 134.8, 64.0
fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))

# COLUMN GRID, sized to THIS panel's own content rather than shared with Figure
# 3A. Measured at 8 pt: Trait needs 38.6 mm ("Coronary artery calcification"),
# N only 8.9 ("24,811"), Effect 21.1, P 7.3.
X_TRAIT, X_N, X_EST, X_P = 0.0111, 0.3159, 0.7540, 0.9430
FOREST_L, FOREST_W = 0.4004, 0.3413

# Vertical anchors, set from what the content needs at 64 mm, working down from
# the header rule: a row is 8 mm (two method lines) and each axis adds about
# 3 mm of spine and ticks.
ROW_SPACING = 0.125          # figure fraction between traits = 8 mm
DY = 0.026                   # half-separation of the two method lines
Y_CAC = 0.835                # the single calcification row
Y_SIS = 0.465                # first row of the plaque block

# --- column headers ----------------------------------------------------------
fig.text(X_TRAIT, 0.955, "Trait", fontsize=FS_HEADER, fontweight="bold", va="center")
# "Sample size", not "N": every row here is a single cohort count, and the
# other panels spell the same column out ("Cases / Controls" in A, "Sample
# size or Cases / Controls" in C).
fig.text(X_N, 0.955, "Sample size", fontsize=FS_HEADER, fontweight="bold",
         va="center")
# "β or POR", not "Effect".
fig.text(X_EST, 0.955, "β or POR (95% CI)", fontsize=FS_HEADER,
         fontweight="bold", va="center")
fig.text(X_P, 0.955, "P", fontsize=FS_HEADER, fontweight="bold", va="center")
fig.add_artist(plt.Line2D([X_TRAIT, 0.985], [0.925, 0.925], color="black",
                          linewidth=0.7, transform=fig.transFigure))


def text_block(key, label, n, ycentre, transform):
    """Trait name, N, and one estimate + P per method."""
    fig.text(X_TRAIT, ycentre, label, fontsize=FS_BODY, va="center")
    fig.text(X_N, ycentre, f"{n:,}", fontsize=FS_BODY, va="center")
    for (_, slot, _), off in zip(METHODS, (DY, -DY)):
        e, lo, hi, p = ROWS[key][slot]
        fig.text(X_EST, ycentre + off, transform(e, lo, hi), fontsize=FS_BODY, va="center")
        fig.text(X_P, ycentre + off, fmt_p(p), fontsize=FS_BODY, va="center")


def draw_axis(keys, y_first, logscale, null, xlim, ticks, minor_step, xlabel):
    """One forest axis. Data y equals figure y, so rows align by construction."""
    n = len(keys)
    ax = fig.add_axes([FOREST_L,
                       (y_first - (n - 1) * ROW_SPACING) - ROW_SPACING / 2,
                       FOREST_W, n * ROW_SPACING])
    ax.set_xlim(*xlim)
    if logscale:
        ax.set_xscale("log")
    ax.set_ylim(-0.5, n - 0.5)
    ax.invert_yaxis()
    ax.axvline(null, color="black", linestyle="--", linewidth=0.6, dashes=(3, 2))
    dy_data = DY / ROW_SPACING
    for i, key in enumerate(keys):
        for (_, slot, col), off in zip(METHODS, (-dy_data, dy_data)):
            e, lo, hi, _p = ROWS[key][slot]
            if logscale:
                e, lo, hi = map(math.exp, (e, lo, hi))
            ax.plot([lo, hi], [i + off] * 2, color=col, linewidth=1.0,
                    solid_capstyle="butt", zorder=2)
            ax.plot([e], [i + off], marker="D", markersize=3.4,
                    markerfacecolor="white", markeredgecolor=col,
                    markeredgewidth=0.9, zorder=3)
    ax.set_xticks(ticks)
    ax.set_xticklabels([("%g" % t) for t in ticks], fontsize=FS_TICK)
    ax.set_yticks([])
    for s in ("top", "left", "right"):
        ax.spines[s].set_visible(False)
    ax.spines["bottom"].set_linewidth(0.7)
    ax.tick_params(axis="x", length=3.2, width=0.8, pad=1.0)
    # Minor ticks come from figures/forest_ticks.py - one implementation for
    # every forest axis in this directory; see that module for why
    # matplotlib's own log minors are not usable here.
    minor_ticks(ax, minor_step, length=2.0, width=0.6)
    ax.set_xlabel(xlabel, fontsize=FS_XLAB, fontweight="bold",
                  labelpad=2.0, linespacing=1.25)


def exp_ci(e, lo, hi):
    return f"{math.exp(e):.2f} ({math.exp(lo):.2f}, {math.exp(hi):.2f})"


def sd_ci(e, lo, hi):
    return f"{e:.2f} ({lo:.2f}, {hi:.2f})"


# --- calcification: an SD change, linear axis ---------------------------------
for i, (key, label, n) in enumerate(SD_BLOCK):
    text_block(key, label, n, Y_CAC - i * ROW_SPACING, sd_ci)
draw_axis([k for k, *_ in SD_BLOCK], Y_CAC, False, 0.0, (-0.22, 0.80), [0, 0.4, 0.8], 0.1,
          "SD change per one unit lower\nNLRP3 activity score")

# --- plaque burden: proportional odds ratios, log axis -------------------------------------
for i, (key, label, n) in enumerate(OR_BLOCK):
    text_block(key, label, n, Y_SIS - i * ROW_SPACING, exp_ci)
draw_axis([k for k, *_ in OR_BLOCK], Y_SIS, True, 1.0, (0.78, 7.0), [1, 2, 4, 6], 0.5,
          "Proportional odds ratio per one unit lower\nNLRP3 activity score")

# --- legend ------------------------------------------------------------------
LY, HALF = 0.050, 0.020


def legend_entry(x, colour, text):
    fig.add_artist(plt.Line2D([x - HALF, x + HALF], [LY, LY], color=colour,
                              linewidth=1.0, transform=fig.transFigure))
    fig.add_artist(plt.Line2D([x], [LY], marker="D", markersize=3.4, color=colour,
                              markerfacecolor="white", markeredgewidth=0.9,
                              linestyle="none", transform=fig.transFigure))
    fig.text(x + HALF + 0.010, LY, text, fontsize=FS_SMALL, va="center")


# Anchors chosen so the two entries sit as a pair, ~6 mm apart, centred
# under the forest axes.
legend_entry(0.421, IVW_C, "IVW")
legend_entry(0.552, WM_C, "Weighted Median")

fig.savefig(OUT_DIR / "Fig3B_imaging_forest.pdf", dpi=600, facecolor="white")
print(f"wrote {OUT_DIR / 'Fig3B_imaging_forest.pdf'}  ({FIG_W_MM:.0f} x {FIG_H_MM:.0f} mm)")
