#!/usr/bin/env python3
# Fig 5 - indications forest.
#
# Forest panel of the activity score against every candidate indication.
# Reads results/12_mr_indications/, writes figures_out/Fig5_indications_forest.pdf.

from pathlib import Path

from style import apply_style
apply_style()
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from forest_ticks import minor_ticks

SCRIPT_DIR = Path(__file__).resolve().parent
ANALYSIS_DIR = SCRIPT_DIR.parent
IN_FILE = (ANALYSIS_DIR / "results" / "12_mr_indications" /
           "additional_indications_mr_results.tsv")
# Case and control counts ride along in step 12's harmonised export, where they
# came from config.R. Reading them here rather than retyping them means the
# figure cannot print one study's sample size beside another study's estimate.
N_FILE = (ANALYSIS_DIR / "results" / "12_mr_indications" /
          "additional_indications_harmonised.tsv")
OUT_DIR = ANALYSIS_DIR / "figures_out"
OUT_DIR.mkdir(parents=True, exist_ok=True)

FS_BODY, FS_HEADER, FS_GROUP, FS_TICK, FS_XLAB, FS_SMALL = 8.0, 8.0, 8.0, 8.0, 7.8, 7.6
# House colours, shared with Figures 3A, 3C, 4D and 4F.
IVW_C, WM_C = "#C0392B", "#2C6FB5"

METHODS = (("IVW (LD-corrected)", "IVW", IVW_C),
           ("Weighted median", "Weighted Median", WM_C))

GROUPS = [
    ("Cardiovascular", ["Pericarditis", "Heart failure (reduced EF)",
                        "Myocardial infarction"]),
    ("Metabolic", ["Obesity", "Type 2 diabetes"]),
    ("Inflammatory / autoimmune",
     ["Rheumatoid arthritis", "Gout", "Ulcerative colitis"]),
    ("Respiratory", ["Chronic airway obstruction", "Allergic rhinitis", "Asthma"]),
    ("Neurological", ["Parkinson's disease",
                      "Amyotrophic lateral sclerosis"]),
    ("Other", ["Knee osteoarthritis", "Hospitalized COVID-19"]),
]

# Ends of the axis. Intervals reaching past either get an arrowhead there.
X_LO, X_HI = 0.10, 1.50
MINOR_STEP = 0.1     # minor ticks, see the header


def fmt_p(p):
    if pd.isna(p):
        return ""
    # 6.3e-4 rather than 6.3e-04, as in Figures 3 and 4
    return f"{p:.1e}".replace("e-0", "e-") if p < 0.001 else f"{p:.3f}"


def fmt_est(e, lo, hi):
    return f"{e:.2f} ({lo:.2f}, {hi:.2f})"


# ---- data -------------------------------------------------------------------
res = pd.read_csv(IN_FILE, sep="\t")
COUNTS = (pd.read_csv(N_FILE, sep="\t")
            .drop_duplicates("outcome")
            .set_index("outcome")[["n_cases", "n_controls"]])

ROWS = {}
for key in [k for _group, members in GROUPS for k in members]:
    d = {}
    for col, _label, _c in METHODS:
        r = res[(res["outcome"] == key) & (res["method"] == col)]
        r = r.iloc[0]
        d[col] = (np.exp(r["estimate"]), np.exp(r["ci_lower"]),
                  np.exp(r["ci_upper"]), r["p"])
    ROWS[key] = d

for _group, members in GROUPS:
    members.sort(key=lambda k: ROWS[k][METHODS[0][0]][0])

# ---- vertical layout, in millimetres from the top edge ----------------------
# Written in mm, not figure fractions, for the reason given in
# figures/fig04d_il1rn_mr_forest.py: text is sized in points, so a
# fraction-based grid silently changes every gap when the panel is resized.
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
    """mm from the top edge -> figure fraction."""
    return 1.0 - mm_from_top / FIG_H_MM


def fh(mm_val):
    return mm_val / FIG_H_MM


# Column x positions, in figure fractions. The label column has to hold
# "Amyotrophic lateral sclerosis" - 29 characters, about 41 mm at 8 pt, which
# is what sets X_N - and the count column "242,283 / 1,569,734".
X_LABEL, X_N = 0.012, 0.295
FOREST_L, FOREST_W = 0.465, 0.195
X_OR, X_P = 0.690, 0.885

DY = fh(DY_MM)

# ---- column headers ---------------------------------------------------------
for x, text in ((X_LABEL, "Indication"), (X_N, "Cases / Controls"),
                (X_OR, "OR (95% CI)"), (X_P, "P")):
    fig.text(x, fy(Y_HEADER), text, fontsize=FS_HEADER, fontweight="bold",
             va="center")
fig.add_artist(plt.Line2D([X_LABEL, 0.985], [fy(Y_RULE)] * 2, color="black",
                          linewidth=0.7, transform=fig.transFigure))

# ---- text columns -----------------------------------------------------------
for kind, key, y_mm in layout:
    if kind == "head":
        fig.text(X_LABEL, fy(y_mm), key, fontsize=FS_GROUP, fontweight="bold",
                 va="center")
        continue
    cases, controls = COUNTS.loc[key]
    # Label and counts sit on the midline between the two method rows.
    fig.text(X_LABEL + 0.014, fy(y_mm), key, fontsize=FS_BODY, va="center")
    fig.text(X_N, fy(y_mm), f"{cases:,.0f} / {controls:,.0f}", fontsize=FS_BODY,
             va="center")
    for (col, _l, _c), off in zip(METHODS, (DY, -DY)):
        e, lo, hi, p = ROWS[key][col]
        fig.text(X_OR, fy(y_mm) + off, fmt_est(e, lo, hi), fontsize=FS_BODY, va="center")
        fig.text(X_P, fy(y_mm) + off, fmt_p(p), fontsize=FS_BODY, va="center")

# ---- the forest -------------------------------------------------------------
Y_TOP, Y_BOT = fy(Y_TOP_MM), fy(Y_BOT_MM)
ax = fig.add_axes([FOREST_L, Y_BOT, FOREST_W, Y_TOP - Y_BOT])
ax.set_xscale("log")
# The view runs a little past each clip so an arrowhead, centred on it, is not
# cut in half; the spine is bounded back to the clips so the axis still ends
# where the arrows point.
ax.set_xlim(X_LO / 1.06, X_HI * 1.06)
ax.set_ylim(Y_BOT, Y_TOP)       # data y == figure y, so rows align by construction
ax.axvline(1.0, color="black", linestyle="--", linewidth=0.6, dashes=(3, 2),
           zorder=1)

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
minor_ticks(ax, MINOR_STEP, length=2.0, width=0.6)
ax.set_yticks([])
for s in ("top", "left", "right"):
    ax.spines[s].set_visible(False)
ax.spines["bottom"].set_linewidth(0.7)
ax.spines["bottom"].set_bounds(X_LO, X_HI)
ax.tick_params(axis="x", length=3.5, width=0.8, pad=1.5)
ax.set_xlabel("Odds ratio per one unit lower NLRP3 activity score",
              fontsize=FS_XLAB, fontweight="bold", labelpad=2.5)

# ---- legend, below the forest -----------------------------------------------
# Centred under the forest axis rather than on the page: the page is dominated
# by the text columns, and a legend centred on it would sit under the OR column.
# Label widths are measured, so renaming a method keeps it centred.
LY, HALF, GAP, PAD = fy(FIG_H_MM - LEGEND_MM), 0.016, 0.030, 0.008

fig.canvas.draw()
renderer = fig.canvas.get_renderer()
label_w = [fig.text(0, 0, lab, fontsize=FS_SMALL).get_window_extent(renderer=renderer).width
           / fig.bbox.width for _c, lab, _col in METHODS]
for t in list(fig.texts[-len(METHODS):]):
    t.remove()

item_w = [2 * HALF + PAD + w for w in label_w]
x = (FOREST_L + FOREST_W / 2) - (sum(item_w) + GAP * (len(METHODS) - 1)) / 2
for (_col, label, colour), w in zip(METHODS, item_w):
    cx = x + HALF
    fig.add_artist(plt.Line2D([cx - HALF, cx + HALF], [LY, LY], color=colour,
                              linewidth=1.0, transform=fig.transFigure))
    fig.add_artist(plt.Line2D([cx], [LY], marker="D", markersize=3.4, color=colour,
                              markerfacecolor="white", markeredgewidth=0.9,
                              linestyle="none", transform=fig.transFigure))
    fig.text(cx + HALF + PAD, LY, label, fontsize=FS_SMALL, va="center")
    x += w + GAP

fig.savefig(OUT_DIR / "Fig5_indications_forest.pdf", dpi=600, facecolor="white")
print(f"wrote {OUT_DIR / 'Fig5_indications_forest.pdf'}  "
      f"({FIG_W_MM:.0f} x {FIG_H_MM:.0f} mm)")
