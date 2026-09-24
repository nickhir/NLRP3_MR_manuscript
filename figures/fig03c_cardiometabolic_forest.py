#!/usr/bin/env python3
# Fig 3C - cardiometabolic forest.
#
# Forest panel of the eleven cardiometabolic and lifestyle traits. Reads
# results/06_mr_cardiometabolic/, writes figures_out/Fig3C_cardiometabolic_forest.pdf.

import csv

from style import apply_style, minor_ticks, legend_entry, RESULTS, OUT_DIR, IVW_C, WM_C
apply_style()
import matplotlib.pyplot as plt

FS_BODY, FS_SMALL, FS_HEADER, FS_TICK, FS_GROUP, FS_XLAB = 8.0, 7.2, 8.0, 8.0, 8.0, 7.8
METHODS = [("ivw", IVW_C), ("wm", WM_C)]

# Group order and the traits within each, as the panel reads top to bottom.
GROUPS = [
    ("Lipids",         ["Triglycerides", "Lpa", "ApoB", "non_HDL_C", "LDL_C"]),
    ("Blood pressure", ["DBP", "SBP"]),
    ("Lifestyle",      ["Alcohol", "Smoking"]),
    ("Metabolic",      ["BMI", "T2D"]),
]

ROWS = {}
with open(RESULTS / "06_mr_cardiometabolic" / "cardiometabolic_mr.tsv") as fh:
    for r in csv.DictReader(fh, delimiter="\t"):
        d = ROWS.setdefault(r["trait"], {"label": r["outcome"], "n": r["n_label"]})
        d["ivw" if r["method"] == "IVW" else "wm"] = (
            float(r["estimate"]), float(r["ci_lower"]), float(r["ci_upper"]), float(r["p"]))


def fmt_p(p):
    return f"{p:.3f}" if p >= 0.001 else f"{p:.1e}".replace("e-0", "e-")


# 142 mm, not the 124 the content needs: in Figure 3 this panel stands beside A
# stacked over B and reaches the same depth.
FIG_W_MM, FIG_H_MM = 134.8, 142.0
fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))

# Column grid, measured at 8 pt from each column's widest string plus a 2.5 mm
# gutter; "Blood pressure" is the widest thing in the outcome column.
X_OUT, X_N, X_EST, X_P = 0.0111, 0.1861, 0.7407, 0.9283
FOREST_L, FOREST_W = 0.3968, 0.3253

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
# and the traits keep one pitch.
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
    for (slot, _), off in zip(METHODS, (DY, -DY)):
        e, lo, hi, p = r[slot]
        fig.text(X_EST, yc + off, f"{e:.2f} ({lo:.2f}, {hi:.2f})", fontsize=FS_BODY, va="center")
        fig.text(X_P, yc + off, fmt_p(p), fontsize=FS_BODY, va="center")

# --- the single forest axis --------------------------------------------------
# Data y equals figure y, so every diamond sits on its own text baseline.
# Intervals past X_CLIP end in an arrowhead there.
X_CLIP = 0.30
lo_all = min(min(ROWS[k][s][1] for s in ("ivw", "wm")) for k, _ in DATA)
# the data plus a margin, but never so tight that the -0.2 tick falls outside
X_MIN = min(lo_all - 0.06 * (X_CLIP - lo_all), -0.205)

# The view runs a little past X_CLIP so the arrowheads centred on it are not
# cut in half; the spine is bounded back to X_CLIP.
ax = fig.add_axes([FOREST_L, Y_LO, FOREST_W, Y_HI - Y_LO])
ax.set_xlim(X_MIN, X_CLIP + 0.015)
ax.set_ylim(Y_LO, Y_HI)
ax.axvline(0.0, color="black", linestyle="--", linewidth=0.6, dashes=(3, 2))

for key, yc in DATA:
    for (slot, col), off in zip(METHODS, (DY, -DY)):
        e, lo, hi, _p = ROWS[key][slot]
        y = yc + off
        ax.plot([lo, min(hi, X_CLIP)], [y] * 2, color=col, linewidth=1.0,
                solid_capstyle="butt", zorder=2)
        if hi > X_CLIP:
            ax.plot([X_CLIP], [y], marker=">", markersize=3.4, color=col,
                    markeredgewidth=0, linestyle="none", zorder=3)
        ax.plot([e], [y], marker="D", markersize=3.4, markerfacecolor="white",
                markeredgecolor=col, markeredgewidth=0.9, zorder=3)

ax.set_xticks([-0.2, 0.0, 0.2])
ax.set_xticklabels(["-0.2", "0", "0.2"], fontsize=FS_TICK)
ax.set_yticks([])
for s in ("top", "left", "right"):
    ax.spines[s].set_visible(False)
ax.spines["bottom"].set_linewidth(0.7)
ax.spines["bottom"].set_bounds(X_MIN, X_CLIP)
ax.tick_params(axis="x", length=3.2, width=0.8, pad=1.0)
minor_ticks(ax, 0.05, length=2.0, width=0.6)
ax.set_xlabel("β per one unit lower\nNLRP3 activity score",
              fontsize=FS_XLAB, fontweight="bold", labelpad=2.0, linespacing=1.25)

# --- legend ------------------------------------------------------------------
LEGEND = dict(half=0.020, pad=0.010, lw=1.0, ms=3.4, mew=0.9, fontsize=FS_SMALL)
legend_entry(fig, 0.410, 0.057, IVW_C, "IVW", **LEGEND)
legend_entry(fig, 0.541, 0.057, WM_C, "Weighted Median", **LEGEND)

fig.savefig(OUT_DIR / "Fig3C_cardiometabolic_forest.pdf", dpi=600, facecolor="white")
