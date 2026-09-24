#!/usr/bin/env python3
# Fig 4F - sensitivity panel.
#
# The NLRP3 -> CAD estimate with instruments re-selected at each LD clumping
# threshold. Reads results/11_mr_sensitivity/, writes figures_out/Fig4F_sensitivity.pdf.

import csv
from math import exp

from style import apply_style, minor_ticks, centred_legend, RESULTS, OUT_DIR, IVW_C, WM_C, GREY
apply_style()
import matplotlib.pyplot as plt

FS_BODY, FS_SMALL, FS_TICK, FS_GROUP, FS_XLAB = 8.0, 7.6, 8.0, 8.0, 7.8

with open(RESULTS / "11_mr_sensitivity" / "r2_sweep.tsv") as fh:
    sweep = list(csv.DictReader(fh, delimiter="\t"))
by = {(float(r["r2_threshold"]), r["method"]): r for r in sweep}
THRESHOLDS = sorted({float(r["r2_threshold"]) for r in sweep})

ROWS = []
for t in THRESHOLDS:
    # U+00B2, not mathtext: $...$ would embed DejaVuSans-Bold beside Open Sans
    d = {"label": "r² < %g" % t, "sub": "%s instruments" % by[(t, "IVW")]["n_snps"]}
    for method, slot in (("IVW", "ivw"), ("Weighted median", "wm")):
        r = by[(t, method)]
        d[slot] = (exp(float(r["estimate"])), exp(float(r["ci_lower"])),
                   exp(float(r["ci_upper"])), float(r["p"]))
    ROWS.append(d)

HEADING = ("Instruments re-selected at each", "LD clumping threshold")


def fmt_p(p):
    return f"{p:.2g}" if p >= 1e-3 else f"{p:.1e}".replace("e-0", "e-")


FIG_W_MM, FIG_H_MM = 104.0, 80.0
fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))

X_LABEL, X_EST, X_P = 0.015, 0.515, 0.810
FOREST_L, FOREST_W = 0.265, 0.225
X_INDENT = 0.014


# The vertical layout is in millimetres down from the top edge.
def fy(mm_from_top):
    return 1.0 - mm_from_top / FIG_H_MM


def fh(mm_val):
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
DATA_Y = [Y_FIRST - i * ROW_SPACING for i in range(len(ROWS))]
Y_TOP = Y_FIRST + ROW_SPACING / 2
Y_BOT = DATA_Y[-1] - ROW_SPACING / 2

# --- column headers ----------------------------------------------------------
fig.text(X_LABEL, fy(Y_HEADER), "Analysis", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_EST, fy(Y_HEADER), "OR (95% CI)", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_P, fy(Y_HEADER), "P", fontsize=FS_BODY, fontweight="bold", va="center")
fig.add_artist(plt.Line2D([X_LABEL, 0.985], [fy(Y_RULE)] * 2, color="black",
                          linewidth=0.6, transform=fig.transFigure))

# --- text column -------------------------------------------------------------
fig.text(X_LABEL, Y_HEAD_CENTRE, "\n".join(HEADING), fontsize=FS_GROUP,
         fontweight="bold", va="center", linespacing=1.15)

for r, ycentre in zip(ROWS, DATA_Y):
    fig.text(X_LABEL + X_INDENT, ycentre + fh(NAME_DY), r["label"], fontsize=FS_BODY, va="center")
    fig.text(X_LABEL + X_INDENT, ycentre - fh(SUB_DY), r["sub"], fontsize=FS_SMALL,
             va="center", color=GREY)
    for slot, off in (("ivw", DY), ("wm", -DY)):
        e, lo, hi, p = r[slot]
        fig.text(X_EST, ycentre + off, f"{e:.2f} ({lo:.2f}, {hi:.2f})", fontsize=FS_BODY, va="center")
        fig.text(X_P, ycentre + off, fmt_p(p), fontsize=FS_BODY, va="center")

# --- the single forest axis --------------------------------------------------
vals = [v for r in ROWS for slot in ("ivw", "wm") for v in r[slot][1:3]]
xlim = (min(min(vals) * 0.97, 0.98), max(vals) * 1.03)
ticks = [t for t in (0.9, 1.0, 1.2, 1.4, 1.6, 1.8) if xlim[0] <= t <= xlim[1]]

ax = fig.add_axes([FOREST_L, Y_BOT, FOREST_W, Y_TOP - Y_BOT])
ax.set_xscale("log")
ax.set_xlim(*xlim)
ax.set_ylim(Y_BOT, Y_TOP)          # data y == figure y, so rows align exactly

# the null line stops just above the first row
ax.plot([1.0, 1.0], [Y_BOT, Y_FIRST + fh(2.6)], color="black", linestyle="--",
        linewidth=0.5, dashes=(3, 2), zorder=1)

for r, ycentre in zip(ROWS, DATA_Y):
    for slot, off, col in (("ivw", DY, IVW_C), ("wm", -DY, WM_C)):
        e, lo, hi, _ = r[slot]
        ax.plot([lo, hi], [ycentre + off] * 2, color=col, linewidth=0.8,
                solid_capstyle="butt", zorder=2)
        ax.plot([e], [ycentre + off], marker="D", markersize=2.5, markerfacecolor="white",
                markeredgecolor=col, markeredgewidth=0.7, zorder=3)

ax.set_xticks(ticks)
ax.set_xticklabels(["%g" % t for t in ticks], fontsize=FS_TICK)
ax.tick_params(axis="x", length=2.8, width=0.6, pad=0.6)
ax.set_yticks([])
minor_ticks(ax, 0.05, length=1.7, width=0.55)
for s in ("top", "left", "right"):
    ax.spines[s].set_visible(False)
ax.spines["bottom"].set_linewidth(0.5)
ax.set_xlabel("Odds ratio for coronary artery disease\nper one unit lower NLRP3 activity score",
              fontsize=FS_XLAB, fontweight="bold", labelpad=1.6, linespacing=1.15)

centred_legend(fig, [(IVW_C, "IVW"), (WM_C, "Weighted Median")], fy(FIG_H_MM - LEGEND_MM), 0.5,
               gap=0.040, half=0.020, pad=0.010, lw=0.8, ms=2.6, mew=0.7, fontsize=FS_SMALL)

fig.savefig(OUT_DIR / "Fig4F_sensitivity.pdf", dpi=600, facecolor="white")
