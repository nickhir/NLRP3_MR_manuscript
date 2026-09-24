#!/usr/bin/env python3
# Fig 3B - imaging forest.
#
# Forest panel of the imaging outcomes.
# Reads results/12_mr_indications/, writes figures_out/Fig3B_imaging_forest.pdf.

import csv
import math

from style import apply_style, minor_ticks, legend_entry, RESULTS, OUT_DIR, IVW_C, WM_C
apply_style()
import matplotlib.pyplot as plt

FS_BODY, FS_SMALL, FS_HEADER, FS_TICK, FS_XLAB = 8.0, 7.0, 8.0, 7.6, 7.6
METHODS = [("ivw", IVW_C), ("wm", WM_C)]

# outcome in the results file -> (display name, N)
SD_BLOCK = [("Coronary artery calcification (Agatston, CT)",
             "Coronary artery calcification", 26_000)]
OR_BLOCK = [("Coronary plaque burden (SIS, CTA)", "Coronary plaque burden", 24_811),
            ("Carotid plaque (ultrasound)", "Carotid plaque", 26_807)]

ROWS = {}
with open(RESULTS / "12_mr_indications" / "additional_indications_mr_results.tsv") as fh:
    for r in csv.DictReader(fh, delimiter="\t"):
        slot = "ivw" if r["method"] == "IVW (LD-corrected)" else "wm"
        ROWS.setdefault(r["outcome"], {})[slot] = (
            float(r["estimate"]), float(r["ci_lower"]), float(r["ci_upper"]), float(r["p"]))


def fmt_p(p):
    return f"{p:.3f}" if p >= 0.001 else f"{p:.1e}".replace("e-0", "e-")


FIG_W_MM, FIG_H_MM = 134.8, 64.0
fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))

# Column grid, measured at 8 pt from each column's widest string.
X_TRAIT, X_N, X_EST, X_P = 0.0111, 0.3159, 0.7540, 0.9430
FOREST_L, FOREST_W = 0.4004, 0.3413

# Vertical anchors: a row is 8 mm (two method lines).
ROW_SPACING = 0.125          # figure fraction between traits
DY = 0.026                   # half-separation of the two method lines
Y_CAC = 0.835                # the single calcification row
Y_SIS = 0.465                # first row of the plaque block

# --- column headers ----------------------------------------------------------
for x, text in ((X_TRAIT, "Trait"), (X_N, "Sample size"), (X_EST, "β or POR (95% CI)"), (X_P, "P")):
    fig.text(x, 0.955, text, fontsize=FS_HEADER, fontweight="bold", va="center")
fig.add_artist(plt.Line2D([X_TRAIT, 0.985], [0.925, 0.925], color="black",
                          linewidth=0.7, transform=fig.transFigure))


def text_block(key, label, n, ycentre, fmt):
    """Trait name, N, and one estimate + P per method."""
    fig.text(X_TRAIT, ycentre, label, fontsize=FS_BODY, va="center")
    fig.text(X_N, ycentre, f"{n:,}", fontsize=FS_BODY, va="center")
    for (slot, _), off in zip(METHODS, (DY, -DY)):
        e, lo, hi, p = ROWS[key][slot]
        fig.text(X_EST, ycentre + off, fmt(e, lo, hi), fontsize=FS_BODY, va="center")
        fig.text(X_P, ycentre + off, fmt_p(p), fontsize=FS_BODY, va="center")


def draw_axis(keys, y_first, logscale, null, xlim, ticks, minor_step, xlabel):
    """One forest axis, placed so its rows sit on their text."""
    n = len(keys)
    ax = fig.add_axes([FOREST_L, (y_first - (n - 1) * ROW_SPACING) - ROW_SPACING / 2,
                       FOREST_W, n * ROW_SPACING])
    ax.set_xlim(*xlim)
    if logscale:
        ax.set_xscale("log")
    ax.set_ylim(-0.5, n - 0.5)
    ax.invert_yaxis()
    ax.axvline(null, color="black", linestyle="--", linewidth=0.6, dashes=(3, 2))
    dy_data = DY / ROW_SPACING
    for i, key in enumerate(keys):
        for (slot, col), off in zip(METHODS, (-dy_data, dy_data)):
            e, lo, hi, _p = ROWS[key][slot]
            if logscale:
                e, lo, hi = map(math.exp, (e, lo, hi))
            ax.plot([lo, hi], [i + off] * 2, color=col, linewidth=1.0,
                    solid_capstyle="butt", zorder=2)
            ax.plot([e], [i + off], marker="D", markersize=3.4, markerfacecolor="white",
                    markeredgecolor=col, markeredgewidth=0.9, zorder=3)
    ax.set_xticks(ticks)
    ax.set_xticklabels([("%g" % t) for t in ticks], fontsize=FS_TICK)
    ax.set_yticks([])
    for s in ("top", "left", "right"):
        ax.spines[s].set_visible(False)
    ax.spines["bottom"].set_linewidth(0.7)
    ax.tick_params(axis="x", length=3.2, width=0.8, pad=1.0)
    minor_ticks(ax, minor_step, length=2.0, width=0.6)
    ax.set_xlabel(xlabel, fontsize=FS_XLAB, fontweight="bold", labelpad=2.0, linespacing=1.25)


# --- calcification: an SD change, linear axis ---------------------------------
for i, (key, label, n) in enumerate(SD_BLOCK):
    text_block(key, label, n, Y_CAC - i * ROW_SPACING,
               lambda e, lo, hi: f"{e:.2f} ({lo:.2f}, {hi:.2f})")
draw_axis([k for k, *_ in SD_BLOCK], Y_CAC, False, 0.0, (-0.22, 0.80), [0, 0.4, 0.8], 0.1,
          "SD change per one unit lower\nNLRP3 activity score")

# --- plaque burden: proportional odds ratios, log axis ------------------------
for i, (key, label, n) in enumerate(OR_BLOCK):
    text_block(key, label, n, Y_SIS - i * ROW_SPACING,
               lambda e, lo, hi: f"{math.exp(e):.2f} ({math.exp(lo):.2f}, {math.exp(hi):.2f})")
draw_axis([k for k, *_ in OR_BLOCK], Y_SIS, True, 1.0, (0.78, 7.0), [1, 2, 4, 6], 0.5,
          "Proportional odds ratio per one unit lower\nNLRP3 activity score")

# --- legend: the pair centred under the forest axes ---------------------------
LEGEND = dict(half=0.020, pad=0.010, lw=1.0, ms=3.4, mew=0.9, fontsize=FS_SMALL)
legend_entry(fig, 0.421, 0.050, IVW_C, "IVW", **LEGEND)
legend_entry(fig, 0.552, 0.050, WM_C, "Weighted Median", **LEGEND)

fig.savefig(OUT_DIR / "Fig3B_imaging_forest.pdf", dpi=600, facecolor="white")
