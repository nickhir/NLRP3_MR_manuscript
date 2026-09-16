#!/usr/bin/env python3
# Fig 3C - cardiometabolic forest.
#
# Forest panel of the eleven cardiometabolic and lifestyle traits. Reads
# results/06_mr_cardiometabolic/, writes figures_out/Fig3C_cardiometabolic_forest.pdf.

import csv
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
IN_FILE = ANALYSIS_DIR / "results" / "06_mr_cardiometabolic" / "cardiometabolic_mr.tsv"
OUT_DIR = ANALYSIS_DIR / "figures_out"
OUT_DIR.mkdir(parents=True, exist_ok=True)

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

FS_BODY, FS_SMALL, FS_HEADER, FS_TICK, FS_GROUP, FS_XLAB = 8.0, 7.2, 8.0, 8.0, 8.0, 7.8
IVW_C, WM_C = "#C0392B", "#2C6FB5"
METHODS = [("IVW", "ivw", IVW_C), ("Weighted median", "wm", WM_C)]

# Group order and the traits within each, as the panel reads top to bottom.
GROUPS = [
    ("Lipids",         ["Triglycerides", "Lpa", "ApoB", "non_HDL_C", "LDL_C"]),
    ("Blood pressure", ["DBP", "SBP"]),
    ("Lifestyle",      ["Alcohol", "Smoking"]),
    ("Metabolic",      ["BMI", "T2D"]),
]


def load():
    rows = {}
    with open(IN_FILE) as fh:
        for r in csv.DictReader(fh, delimiter="\t"):
            slot = next((s for m, s, _ in METHODS if r["method"] == m), None)
            if slot is None:
                continue
            d = rows.setdefault(r["trait"], {})
            d[slot] = (float(r["estimate"]), float(r["ci_lower"]),
                       float(r["ci_upper"]), float(r["p"]))
            d["label"] = r["outcome"]
            d["n"] = r["n_label"]
    wanted = [t for _, ts in GROUPS for t in ts]
    missing = [t for t in wanted if t not in rows]
    incomplete = [t for t in wanted if not {"ivw", "wm"} <= set(rows[t])]
    return rows


ROWS = load()


def fmt_p(p):
    return f"{p:.3f}" if p >= 0.001 else f"{p:.1e}".replace("e-0", "e-")


# 138 mm, not the 124 the content needs: in Figure 3 this panel stands beside A
# stacked over B, and it is sized to reach the same depth so no white gap opens
# under it.
FIG_W_MM, FIG_H_MM = 134.8, 142.0
fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))

# COLUMN GRID, measured at 8 pt from the widest string in each column plus a
# 2.5 mm gutter, the same method as Figures 3A and 3B. "Blood pressure" is the
# widest thing in the outcome column, not a trait name.
X_OUT, X_N, X_EST, X_P = 0.0111, 0.1861, 0.7407, 0.9283
FOREST_L, FOREST_W = 0.3968, 0.3253

# Vertical budget at 124 mm. The rows are sized as a FRACTION deliberately: the
# stack runs Y_TOP - 4*GROUP_H - 10*ROW_H, so those two numbers alone decide
# how much of the figure is left under the axis.
ROW_H = 0.056         # figure fraction per trait (two method lines) = 6.9 mm
GROUP_H = 0.031       # a group heading = 3.8 mm
DY = 0.0148           # half-separation of the two method lines
Y_TOP = 0.900         # first group heading sits here

# --- column headers ----------------------------------------------------------
fig.text(X_OUT, 0.968, "Outcome", fontsize=FS_HEADER, fontweight="bold", va="center")
fig.text(X_N, 0.975, "Sample size or", fontsize=FS_HEADER, fontweight="bold", va="center")
fig.text(X_N, 0.955, "Cases / Controls", fontsize=FS_HEADER, fontweight="bold", va="center")
fig.text(X_EST, 0.968, "β (95% CI)", fontsize=FS_HEADER, fontweight="bold", va="center")
fig.text(X_P, 0.968, "P", fontsize=FS_HEADER, fontweight="bold", va="center")
fig.add_artist(plt.Line2D([X_OUT, 0.985], [0.937, 0.937], color="black",
                          linewidth=0.7, transform=fig.transFigure))

# --- lay the rows out --------------------------------------------------------
# Group headings take their own slot, so the single forest axis spans everything
# and the traits keep one pitch regardless of how the groups are sized.
layout = []           # (kind, key, y)
y = Y_TOP
for heading, traits in GROUPS:
    layout.append(("group", heading, y))
    y -= GROUP_H
    for t in traits:
        layout.append(("row", t, y))
        y -= ROW_H
DATA = [(k, yy) for kind, k, yy in layout if kind == "row"]
Y_HI = max(yy for _, yy in DATA) + ROW_H / 2
Y_LO = min(yy for _, yy in DATA) - ROW_H / 2

# --- text --------------------------------------------------------------------
for kind, key, yc in layout:
    if kind == "group":
        fig.text(X_OUT, yc, key, fontsize=FS_GROUP, fontweight="bold", va="center")
        continue
    r = ROWS[key]
    fig.text(X_OUT + 0.014, yc, r["label"], fontsize=FS_BODY, va="center")
    fig.text(X_N, yc, r["n"], fontsize=FS_BODY, va="center")
    for (_, slot, _), off in zip(METHODS, (DY, -DY)):
        e, lo, hi, p = r[slot]
        fig.text(X_EST, yc + off, f"{e:.2f} ({lo:.2f}, {hi:.2f})",
                 fontsize=FS_BODY, va="center")
        fig.text(X_P, yc + off, fmt_p(p), fontsize=FS_BODY, va="center")

# --- the single forest axis --------------------------------------------------
# Data y equals figure y, so every diamond sits on its own text baseline by
# construction.
X_CLIP = 0.30

lo_all = min(min(ROWS[k][s][1] for s in ("ivw", "wm")) for k, _ in DATA)
hi_all = max(max(ROWS[k][s][2] for s in ("ivw", "wm")) for k, _ in DATA)

# Left edge: the data plus a margin, but never so tight that the -0.2 tick falls
# outside the view and silently disappears.
pad = 0.06 * (X_CLIP - lo_all)
X_MIN = min(lo_all - pad, -0.205)

# The view runs a little past X_CLIP so the arrowhead, which is centred on it,
# is not cut in half; the spine is then bounded back to X_CLIP so the axis line
# still visibly ends where the arrows point.
ax = fig.add_axes([FOREST_L, Y_LO, FOREST_W, Y_HI - Y_LO])
ax.set_xlim(X_MIN, X_CLIP + 0.015)
ax.set_ylim(Y_LO, Y_HI)
ax.axvline(0.0, color="black", linestyle="--", linewidth=0.6, dashes=(3, 2))

for key, yc in DATA:
    for (_, slot, col), off in zip(METHODS, (DY, -DY)):
        e, lo, hi, _p = ROWS[key][slot]
        y = yc + off
        ax.plot([lo, min(hi, X_CLIP)], [y] * 2, color=col, linewidth=1.0,
                solid_capstyle="butt", zorder=2)
        if hi > X_CLIP:
            ax.plot([X_CLIP], [y], marker=">", markersize=3.4, color=col,
                    markeredgewidth=0, linestyle="none", zorder=3)
        ax.plot([e], [y], marker="D", markersize=3.4,
                markerfacecolor="white", markeredgecolor=col,
                markeredgewidth=0.9, zorder=3)

ax.set_xticks([-0.2, 0.0, 0.2])
ax.set_xticklabels(["-0.2", "0", "0.2"], fontsize=FS_TICK)
ax.set_yticks([])
for s in ("top", "left", "right"):
    ax.spines[s].set_visible(False)
ax.spines["bottom"].set_linewidth(0.7)
ax.spines["bottom"].set_bounds(X_MIN, X_CLIP)
ax.tick_params(axis="x", length=3.2, width=0.8, pad=1.0)
# Minor ticks come from figures/forest_ticks.py - one implementation for
# every forest axis in this directory; see that module for why
# matplotlib's own log minors are not usable here.
minor_ticks(ax, 0.05, length=2.0, width=0.6)
ax.set_xlabel("β per one unit lower\nNLRP3 activity score",
              fontsize=FS_XLAB, fontweight="bold", labelpad=2.0, linespacing=1.25)

# --- legend ------------------------------------------------------------------
LY, HALF, PAD = 0.057, 0.020, 0.010


def legend_entry(x, colour, text):
    fig.add_artist(plt.Line2D([x - HALF, x + HALF], [LY, LY], color=colour,
                              linewidth=1.0, transform=fig.transFigure))
    fig.add_artist(plt.Line2D([x], [LY], marker="D", markersize=3.4, color=colour,
                              markerfacecolor="white", markeredgewidth=0.9,
                              linestyle="none", transform=fig.transFigure))
    fig.text(x + HALF + PAD, LY, text, fontsize=FS_SMALL, va="center")


legend_entry(0.410, IVW_C, "IVW")
legend_entry(0.541, WM_C, "Weighted Median")

fig.savefig(OUT_DIR / "Fig3C_cardiometabolic_forest.pdf", dpi=600,
            facecolor="white")
print(f"wrote {OUT_DIR / 'Fig3C_cardiometabolic_forest.pdf'}  "
      f"({FIG_W_MM:.0f} x {FIG_H_MM:.0f} mm)")
