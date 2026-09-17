#!/usr/bin/env python3
# Fig 4F - sensitivity panel.
#
# The r2 clumping sweep and the single-variant Wald ratio for NLRP3 -> CAD.
# Reads results/11_mr_sensitivity/, writes figures_out/Fig4F_sensitivity.pdf.

import csv
from math import exp
from pathlib import Path

from style import apply_style
apply_style()
import matplotlib.pyplot as plt

from forest_ticks import minor_ticks

SCRIPT_DIR = Path(__file__).resolve().parent
ANALYSIS_DIR = SCRIPT_DIR.parent
IN_DIR = ANALYSIS_DIR / "results" / "11_mr_sensitivity"
OUT_DIR = ANALYSIS_DIR / "figures_out"
OUT_DIR.mkdir(parents=True, exist_ok=True)

FS_BODY, FS_SMALL, FS_TICK, FS_GROUP, FS_XLAB = 8.0, 7.6, 8.0, 8.0, 7.8
# #8A8A8A is the house grey - the instrument counts under each threshold use it,
# so nothing grey on the panel is a different grey.
GREY = "#8A8A8A"
IVW_C, WM_C = "#C0392B", "#2C6FB5"


def load(p):
    with open(p) as fh:
        return list(csv.DictReader(fh, delimiter="\t"))


sweep = load(IN_DIR / "r2_sweep.tsv")

THRESHOLDS = sorted({float(r["r2_threshold"]) for r in sweep})
by = {(float(r["r2_threshold"]), r["method"]): r for r in sweep}

ROWS = {}
for t in THRESHOLDS:
    key = "r2_%g" % t
    # U+00B2, not mathtext: matplotlib renders $...$ with its own font set and
    # would embed DejaVuSans-Bold alongside the Open Sans faces.
    d = ROWS.setdefault(key, {"label": "r² < %g" % t})
    for method, slot in (("IVW", "ivw"), ("Weighted median", "wm")):
        r = by[(t, method)]
        d[slot] = (exp(float(r["estimate"])), exp(float(r["ci_lower"])),
                   exp(float(r["ci_upper"])), float(r["p"]))
    d["sub"] = "%s instruments" % by[(t, "IVW")]["n_snps"]

HEADING = ("Instruments re-selected at each", "LD clumping threshold")
KEYS = ["r2_%g" % t for t in THRESHOLDS]


def fmt_p(p):
    return f"{p:.2g}" if p >= 1e-3 else f"{p:.1e}".replace("e-0", "e-")


def fmt_est(e, lo, hi):
    return f"{e:.2f} ({lo:.2f}, {hi:.2f})"


FIG_W_MM, FIG_H_MM = 104.0, 80.0
fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))

X_LABEL, X_EST, X_P = 0.015, 0.515, 0.810
FOREST_L, FOREST_W = 0.265, 0.225
X_INDENT = 0.014


# VERTICAL LAYOUT IS IN MILLIMETRES, measured down from the top edge, as in
# figures/fig04d_il1rn_mr_forest.py.
def fy(mm_from_top):
    """mm from the top edge -> figure fraction."""
    return 1.0 - mm_from_top / FIG_H_MM


def fh(mm_val):
    """a height in mm -> figure fraction."""
    return mm_val / FIG_H_MM


Y_HEADER = 2.6       # column headers
Y_RULE = 4.9         # rule under them
HEAD_TOP = 6.8       # top of the group heading
LINE_MM = 2.26       # per line of the group heading
HEAD_TO_ROW = 4.9    # heading block to the first row centre
ROW_MM = 7.5         # between rows
DY_MM = 1.85         # half-separation of the two method lines
NAME_DY = 1.3        # threshold label above the row centre
SUB_DY = 1.5         # instrument count below it
LEGEND_MM = 7.0      # legend centre, up from the bottom edge

ROW_SPACING = fh(ROW_MM)
DY = fh(DY_MM)

Y_HEAD_CENTRE = fy(HEAD_TOP + len(HEADING) * LINE_MM / 2)
Y_FIRST = fy(HEAD_TOP + len(HEADING) * LINE_MM + HEAD_TO_ROW)
DATA_Y = [(k, Y_FIRST - i * ROW_SPACING) for i, k in enumerate(KEYS)]
Y_TOP = Y_FIRST + ROW_SPACING / 2
Y_BOT = DATA_Y[-1][1] - ROW_SPACING / 2

# --- column headers ----------------------------------------------------------
fig.text(X_LABEL, fy(Y_HEADER), "Analysis", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_EST, fy(Y_HEADER), "OR (95% CI)", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_P, fy(Y_HEADER), "P", fontsize=FS_BODY, fontweight="bold", va="center")
fig.add_artist(plt.Line2D([X_LABEL, 0.985], [fy(Y_RULE)] * 2, color="black",
                          linewidth=0.6, transform=fig.transFigure))

# --- text column -------------------------------------------------------------
fig.text(X_LABEL, Y_HEAD_CENTRE, "\n".join(HEADING), fontsize=FS_GROUP,
         fontweight="bold", va="center", linespacing=1.15)

for key, ycentre in DATA_Y:
    r = ROWS[key]
    fig.text(X_LABEL + X_INDENT, ycentre + fh(NAME_DY), r["label"],
             fontsize=FS_BODY, va="center")
    fig.text(X_LABEL + X_INDENT, ycentre - fh(SUB_DY), r["sub"], fontsize=FS_SMALL,
             va="center", color=GREY)
    for slot, off in (("ivw", DY), ("wm", -DY)):
        e, lo, hi, p = r[slot]
        fig.text(X_EST, ycentre + off, fmt_est(e, lo, hi), fontsize=FS_BODY, va="center")
        fig.text(X_P, ycentre + off, fmt_p(p), fontsize=FS_BODY, va="center")

# --- the single forest axis --------------------------------------------------
vals = []
for key, _ in DATA_Y:
    for slot in ("ivw", "wm"):
        vals += [ROWS[key][slot][1], ROWS[key][slot][2]]
xlim = (min(min(vals) * 0.97, 0.98), max(vals) * 1.03)
ticks = [t for t in (0.9, 1.0, 1.2, 1.4, 1.6, 1.8) if xlim[0] <= t <= xlim[1]]

ax = fig.add_axes([FOREST_L, Y_BOT, FOREST_W, Y_TOP - Y_BOT])
ax.set_xscale("log")
ax.set_xlim(*xlim)
ax.set_ylim(Y_BOT, Y_TOP)          # data y == figure y, so rows align exactly

# The null line stops just above the FIRST row rather than spanning the rect.
ax.plot([1.0, 1.0], [Y_BOT, Y_FIRST + fh(2.6)], color="black", linestyle="--",
        linewidth=0.5, dashes=(3, 2), zorder=1)

for key, ycentre in DATA_Y:
    for slot, off, col in (("ivw", DY, IVW_C), ("wm", -DY, WM_C)):
        e, lo, hi, _ = ROWS[key][slot]
        ax.plot([lo, hi], [ycentre + off] * 2, color=col, linewidth=0.8,
                solid_capstyle="butt", zorder=2)
        ax.plot([e], [ycentre + off], marker="D", markersize=2.5,
                markerfacecolor="white", markeredgecolor=col,
                markeredgewidth=0.7, zorder=3)

ax.set_xticks(ticks)
ax.set_xticklabels(["%g" % t for t in ticks], fontsize=FS_TICK)
ax.tick_params(axis="x", length=2.8, width=0.6, pad=0.6)
ax.set_yticks([])
# Minor ticks come from figures/forest_ticks.py - one implementation for
# every forest axis in this directory; see that module for why
# matplotlib's own log minors are not usable here.
minor_ticks(ax, 0.05, length=1.7, width=0.55)
for s in ("top", "left", "right"):
    ax.spines[s].set_visible(False)
ax.spines["bottom"].set_linewidth(0.5)
ax.set_xlabel("Odds ratio for coronary artery disease\nper one unit lower NLRP3 activity score",
              fontsize=FS_XLAB, fontweight="bold", labelpad=1.6, linespacing=1.15)

# --- legend, below the plot --------------------------------------------------
LY, HALF, GAP, PAD = fy(FIG_H_MM - LEGEND_MM), 0.020, 0.040, 0.010
ITEMS = [(IVW_C, "IVW"), (WM_C, "Weighted Median")]

fig.canvas.draw()
renderer = fig.canvas.get_renderer()
label_w = []
for _, text in ITEMS:
    probe = fig.text(0, 0, text, fontsize=FS_SMALL)
    label_w.append(probe.get_window_extent(renderer=renderer).width / fig.bbox.width)
    probe.remove()

item_w = [2 * HALF + PAD + w for w in label_w]
x = 0.5 - (sum(item_w) + GAP * (len(ITEMS) - 1)) / 2
for (colour, text), w in zip(ITEMS, item_w):
    cx = x + HALF
    fig.add_artist(plt.Line2D([cx - HALF, cx + HALF], [LY, LY], color=colour,
                              linewidth=0.8, transform=fig.transFigure))
    fig.add_artist(plt.Line2D([cx], [LY], marker="D", markersize=2.6, color=colour,
                              markerfacecolor="white", markeredgewidth=0.7,
                              linestyle="none", transform=fig.transFigure))
    fig.text(cx + HALF + PAD, LY, text, fontsize=FS_SMALL, va="center")
    x += w + GAP


fig.savefig(OUT_DIR / "Fig4F_sensitivity.pdf", dpi=600, facecolor="white")
print(f"wrote {OUT_DIR / 'Fig4F_sensitivity.pdf'}  ({FIG_W_MM:.0f} x {FIG_H_MM:.0f} mm)")
