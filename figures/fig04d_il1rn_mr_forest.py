#!/usr/bin/env python3
# Fig 4D - IL1RN MR forest.
#
# Forest panel of the IL1Ra activity score against its outcomes. IVW only: with
# three instruments step 08 fits no weighted median or MR-Egger.
# Reads results/08_il1rn_positive_control/, writes figures_out/Fig4D_il1rn_mr_forest.pdf.

import csv

from style import apply_style, minor_ticks, centred_legend, RESULTS, OUT_DIR, IVW_C, GREY
apply_style()
import matplotlib.pyplot as plt

# FS_XLAB is 7.0, not 7.8: these two axis titles are the only two-line titles
# in Figure 4 and at 7.8 they dominated the panel.
FS_BODY, FS_SMALL, FS_TICK, FS_XLAB = 8.0, 7.6, 8.0, 7.0

ROWS = {}
with open(RESULTS / "08_il1rn_positive_control" / "il1rn_mr_results.tsv") as fh:
    for r in csv.DictReader(fh, delimiter="\t"):
        # Cases and controls spelled out, over two lines: in full they are
        # wider than the label column.
        if r["n_cases"] not in ("", "NA"):
            n = [f"{int(float(r['n_cases'])):,} cases /",
                 f"{int(float(r['n_controls'])):,} controls"]
        else:
            n = [f"n = {int(float(r['n_total'])):,}"]
        ROWS[r["outcome"]] = {"label": r["outcome"], "n": n,
                              "ivw": (float(r["estimate"]), float(r["ci_lower"]),
                                      float(r["ci_upper"]), float(r["p"]))}


def fmt_p(p):
    return f"{p:.2g}" if p >= 1e-3 else f"{p:.0e}".replace("e-0", "e-")


FIG_W_MM, FIG_H_MM = 96.0, 70.0
fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))

X_LABEL, X_EST, X_P = 0.012, 0.560, 0.855
FOREST_L, FOREST_W = 0.345, 0.190


# The vertical layout is in millimetres down from the top edge.
def fy(mm_from_top):
    return 1.0 - mm_from_top / FIG_H_MM


def fh(mm_val):
    return mm_val / FIG_H_MM


Y_HEADER = 3.6      # column headers
Y_RULE = 6.4        # rule under them
ROW_MM = 12.0       # between outcome rows within a block
NAME_DY = 2.1       # outcome name above the row centre
SUB_DY = 1.4        # first sample-size line below it
SUB_STEP = 2.9      # between sample-size lines
ROW_SPACING = fh(ROW_MM)

fig.text(X_LABEL, fy(Y_HEADER), "Outcome", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_EST, fy(Y_HEADER), "Effect (95% CI)", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_P, fy(Y_HEADER), "P", fontsize=FS_BODY, fontweight="bold", va="center")
fig.add_artist(plt.Line2D([X_LABEL, 0.985], [fy(Y_RULE), fy(Y_RULE)], color="black",
                          linewidth=0.6, transform=fig.transFigure))


def text_block(r, ycentre):
    # the name above the row centre and the count lines below it, so one- and
    # two-line rows centre on the same baseline
    fig.text(X_LABEL + 0.018, ycentre + fh(NAME_DY), r["label"], fontsize=FS_BODY, va="center")
    for i, line in enumerate(r["n"]):
        fig.text(X_LABEL + 0.018, ycentre - fh(SUB_DY + i * SUB_STEP), line,
                 fontsize=FS_SMALL, va="center", color=GREY)
    e, lo, hi, p = r["ivw"]
    fig.text(X_EST, ycentre, f"{e:.2f} ({lo:.2f}, {hi:.2f})", fontsize=FS_BODY, va="center")
    fig.text(X_P, ycentre, fmt_p(p), fontsize=FS_BODY, va="center")


def draw_axis(rows, y_first, logscale, null, xlim, ticks, minor_step, xlabel):
    n = len(rows)
    ax = fig.add_axes([FOREST_L, (y_first - (n - 1) * ROW_SPACING) - ROW_SPACING / 2,
                       FOREST_W, n * ROW_SPACING])
    ax.set_xlim(*xlim)
    if logscale:
        ax.set_xscale("log")
    ax.set_ylim(-0.5, n - 0.5)
    ax.invert_yaxis()
    # the null line stops just above the first row
    ax.plot([null, null], [-0.37, n - 0.5], color="black",
            linestyle="--", linewidth=0.5, dashes=(3, 2), zorder=1)
    for i, r in enumerate(rows):
        e, lo, hi, _ = r["ivw"]
        ax.plot([lo, hi], [i, i], color=IVW_C, linewidth=0.8, solid_capstyle="butt", zorder=2)
        ax.plot([e], [i], marker="D", markersize=2.5, markerfacecolor="white",
                markeredgecolor=IVW_C, markeredgewidth=0.7, zorder=3)
    ax.set_xticks(ticks)
    ax.set_xticklabels(["%g" % t for t in ticks], fontsize=FS_TICK)
    ax.tick_params(axis="x", length=2.8, width=0.6, pad=0.6)
    ax.set_yticks([])
    minor_ticks(ax, minor_step, length=1.7, width=0.55)
    for s in ("top", "left", "right"):
        ax.spines[s].set_visible(False)
    ax.spines["bottom"].set_linewidth(0.5)
    ax.set_xlabel(xlabel, fontsize=FS_XLAB, fontweight="bold", labelpad=1.6, linespacing=1.15)


# --- protein block -----------------------------------------------------------
protein = ROWS["IL1Ra concentration"]
text_block(protein, fy(12.8))
draw_axis([protein], fy(12.8), False, 0.0, (-1.4, 8.6), [0, 4, 8], 1,
          "SD change per one unit higher\nIL1Ra activity score")

# --- disease block -----------------------------------------------------------
diseases = [ROWS["Gout"], ROWS["Rheumatoid arthritis"]]
for i, r in enumerate(diseases):
    text_block(r, fy(34.6) - i * ROW_SPACING)
draw_axis(diseases, fy(34.6), True, 1.0, (0.05, 1.12), [0.1, 0.5, 1], 0.1,
          "Odds ratio per one unit higher\nIL1Ra activity score")

centred_legend(fig, [(IVW_C, "IVW")], fy(66.4), 0.5, gap=0.045,
               half=0.022, pad=0.012, lw=0.8, ms=2.6, mew=0.7, fontsize=FS_SMALL)

fig.savefig(OUT_DIR / "Fig4D_il1rn_mr_forest.pdf", dpi=600, facecolor="white")
