#!/usr/bin/env python3
# Fig 5 - indications forest.
#
# Forest panel of the activity score against every candidate indication.
# Reads results/12_mr_indications/, writes figures_out/Fig5_indications_forest.pdf.

from style import apply_style, minor_ticks, centred_legend, RESULTS, OUT_DIR, IVW_C, WM_C
apply_style()
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

FS_BODY, FS_HEADER, FS_GROUP, FS_TICK, FS_XLAB, FS_SMALL = 8.0, 8.0, 8.0, 8.0, 7.8, 7.6
METHODS = (("IVW (LD-corrected)", "IVW", IVW_C),
           ("Weighted median", "Weighted Median", WM_C))

GROUPS = [
    ("Cardiovascular", ["Pericarditis", "Heart failure (reduced EF)", "Myocardial infarction"]),
    ("Metabolic", ["Obesity", "Type 2 diabetes"]),
    ("Inflammatory / autoimmune", ["Rheumatoid arthritis", "Gout", "Ulcerative colitis"]),
    ("Respiratory", ["Chronic airway obstruction", "Allergic rhinitis", "Asthma"]),
    ("Neurological", ["Parkinson's disease", "Amyotrophic lateral sclerosis"]),
    ("Other", ["Knee osteoarthritis", "Hospitalized COVID-19"]),
]

# Ends of the axis; intervals reaching past either get an arrowhead there.
X_LO, X_HI = 0.10, 1.50


def fmt_p(p):
    return f"{p:.1e}".replace("e-0", "e-") if p < 0.001 else f"{p:.3f}"


# ---- data -------------------------------------------------------------------
res = pd.read_csv(RESULTS / "12_mr_indications" / "additional_indications_mr_results.tsv", sep="\t")
# Case and control counts ride along in step 12's harmonised export.
COUNTS = (pd.read_csv(RESULTS / "12_mr_indications" / "additional_indications_harmonised.tsv", sep="\t")
            .drop_duplicates("outcome")
            .set_index("outcome")[["n_cases", "n_controls"]])

ROWS = {}
for key in [k for _group, members in GROUPS for k in members]:
    ROWS[key] = {}
    for col, _label, _c in METHODS:
        r = res[(res["outcome"] == key) & (res["method"] == col)].iloc[0]
        ROWS[key][col] = (np.exp(r["estimate"]), np.exp(r["ci_lower"]),
                          np.exp(r["ci_upper"]), r["p"])

# each group runs by its IVW odds ratio
for _group, members in GROUPS:
    members.sort(key=lambda k: ROWS[k][METHODS[0][0]][0])

# ---- vertical layout, in millimetres from the top edge ----------------------
FIG_W_MM = 180.0

Y_HEADER = 4.4       # column headers
Y_RULE = 7.0         # rule under them
FIRST_HEAD = 11.2    # first group heading
GROUP_GAP = 3.6      # extra space before each later group heading
HEAD_TO_ROW = 5.2    # group heading -> first indication of that group
ROW_MM = 7.6         # indication -> indication
DY_MM = 1.95         # half-separation of the two method lines
BOTTOM_MM = 20.0     # axis bottom -> figure bottom (ticks, title, legend)
LEGEND_MM = 5.5      # legend centre, up from the bottom edge

layout, last = [], None
y = FIRST_HEAD
for i, (group, members) in enumerate(GROUPS):
    if i:
        y = last + ROW_MM / 2 + GROUP_GAP
    layout.append(("head", group, y))
    y += HEAD_TO_ROW
    for key in members:
        layout.append(("row", key, y))
        last = y
        y += ROW_MM

ROW_Y = [(k, yy) for kind, k, yy in layout if kind == "row"]
Y_TOP_MM = ROW_Y[0][1] - ROW_MM / 2
Y_BOT_MM = ROW_Y[-1][1] + ROW_MM / 2
FIG_H_MM = Y_BOT_MM + BOTTOM_MM

fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))


def fy(mm_from_top):
    return 1.0 - mm_from_top / FIG_H_MM


# Column x positions, in figure fractions. The label column has to hold
# "Amyotrophic lateral sclerosis", the count column "242,283 / 1,569,734".
X_LABEL, X_N = 0.012, 0.295
FOREST_L, FOREST_W = 0.465, 0.195
X_OR, X_P = 0.690, 0.885
DY = DY_MM / FIG_H_MM

# ---- column headers ---------------------------------------------------------
for x, text in ((X_LABEL, "Indication"), (X_N, "Cases / Controls"),
                (X_OR, "OR (95% CI)"), (X_P, "P")):
    fig.text(x, fy(Y_HEADER), text, fontsize=FS_HEADER, fontweight="bold", va="center")
fig.add_artist(plt.Line2D([X_LABEL, 0.985], [fy(Y_RULE)] * 2, color="black",
                          linewidth=0.7, transform=fig.transFigure))

# ---- text columns -----------------------------------------------------------
for kind, key, y_mm in layout:
    if kind == "head":
        fig.text(X_LABEL, fy(y_mm), key, fontsize=FS_GROUP, fontweight="bold", va="center")
        continue
    cases, controls = COUNTS.loc[key]
    # label and counts on the midline between the two method rows
    fig.text(X_LABEL + 0.014, fy(y_mm), key, fontsize=FS_BODY, va="center")
    fig.text(X_N, fy(y_mm), f"{cases:,.0f} / {controls:,.0f}", fontsize=FS_BODY, va="center")
    for (col, _l, _c), off in zip(METHODS, (DY, -DY)):
        e, lo, hi, p = ROWS[key][col]
        fig.text(X_OR, fy(y_mm) + off, f"{e:.2f} ({lo:.2f}, {hi:.2f})", fontsize=FS_BODY,
                 va="center")
        fig.text(X_P, fy(y_mm) + off, fmt_p(p), fontsize=FS_BODY, va="center")

# ---- the forest -------------------------------------------------------------
Y_TOP, Y_BOT = fy(Y_TOP_MM), fy(Y_BOT_MM)
ax = fig.add_axes([FOREST_L, Y_BOT, FOREST_W, Y_TOP - Y_BOT])
ax.set_xscale("log")
# The view runs a little past each end so the arrowheads centred on them are
# not cut in half; the spine is bounded back to the ends.
ax.set_xlim(X_LO / 1.06, X_HI * 1.06)
ax.set_ylim(Y_BOT, Y_TOP)       # data y == figure y, so rows align by construction
ax.axvline(1.0, color="black", linestyle="--", linewidth=0.6, dashes=(3, 2), zorder=1)

for key, y_mm in ROW_Y:
    for (col, _l, colour), off in zip(METHODS, (DY, -DY)):
        e, lo, hi, _p = ROWS[key][col]
        y = fy(y_mm) + off
        ax.plot([max(lo, X_LO), min(hi, X_HI)], [y] * 2, color=colour,
                linewidth=1.0, solid_capstyle="butt", zorder=2)
        for bound, end, marker in ((lo, X_LO, "<"), (hi, X_HI, ">")):
            if (bound < end) == (marker == "<"):
                ax.plot([end], [y], marker=marker, markersize=3.4, color=colour,
                        markeredgewidth=0, linestyle="none", zorder=3)
        ax.plot([e], [y], marker="D", markersize=3.4, markerfacecolor="white",
                markeredgecolor=colour, markeredgewidth=0.9, zorder=4)

ticks = [t for t in (0.1, 0.25, 0.5, 1, 1.5, 2, 4) if X_LO <= t <= X_HI]
ax.set_xticks(ticks)
ax.set_xticklabels([f"{t:g}" for t in ticks], fontsize=FS_TICK)
minor_ticks(ax, 0.1, length=2.0, width=0.6)
ax.set_yticks([])
for s in ("top", "left", "right"):
    ax.spines[s].set_visible(False)
ax.spines["bottom"].set_linewidth(0.7)
ax.spines["bottom"].set_bounds(X_LO, X_HI)
ax.tick_params(axis="x", length=3.5, width=0.8, pad=1.5)
ax.set_xlabel("Odds ratio per one unit lower NLRP3 activity score",
              fontsize=FS_XLAB, fontweight="bold", labelpad=2.5)

# The legend is centred under the forest axis, not the page, which the text
# columns dominate.
centred_legend(fig, [(colour, label) for _col, label, colour in METHODS],
               fy(FIG_H_MM - LEGEND_MM), FOREST_L + FOREST_W / 2, gap=0.030,
               half=0.016, pad=0.008, lw=1.0, ms=3.4, mew=0.9, fontsize=FS_SMALL)

fig.savefig(OUT_DIR / "Fig5_indications_forest.pdf", dpi=600, facecolor="white")
