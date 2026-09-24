#!/usr/bin/env python3
# Fig 3A - cis-NLRP3 activity -> coronary artery disease.
#
# Forest panel of the four CAD cohorts and their fixed-effect meta-analysis.
# Reads results/05_mr_cad/, writes figures_out/Fig3A_cad_forest.pdf.

from style import apply_style, minor_ticks, RESULTS, OUT_DIR, IVW_C, WM_C
apply_style()
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
import numpy as np
import pandas as pd

FS_BODY, FS_HEADER, FS_TICK, FS_XLAB = 8.0, 8.0, 8.0, 7.8
COLOURS = {"IVW": IVW_C, "Weighted Median": WM_C}

# Study, cases and controls; the meta-analysis row sums the four.
STUDIES = [
    ("Aragam et al.", 181_522, 984_168),
    ("MVP", 124_302, 300_039),
    ("All of Us", 19_856, 150_307),
    ("FinnGen", 63_307, 416_171),
]
STUDIES.append(("Meta-analysis", sum(s[1] for s in STUDIES), sum(s[2] for s in STUDIES)))

# Column grid, measured at 8 pt from each column's widest string plus a 2.5 mm
# gutter, in axes fractions.
X_STUDY, X_N, X_OR, X_P = -1.0184, -0.5820, 1.0512, 1.5328
AX_W = 0.3620          # the forest axes' width as a figure fraction


def format_pval(p):
    return f"{p:.3f}" if p >= 0.001 else f"{p:.1e}".replace("e-0", "e-")


res = pd.read_csv(RESULTS / "05_mr_cad" / "cad_meta_studies.tsv", sep="\t")
res["or"] = np.exp(res["beta"])
res["lo"] = np.exp(res["ci_lower"])
res["hi"] = np.exp(res["ci_upper"])

# ---- lay out rows -----------------------------------------------------------
rows, labels = [], []
y = 0.0
for study, cases, controls in STUDIES:
    labels.append((study, f"{cases:,} / {controls:,}", y + 0.5))
    for method in ("IVW", "Weighted Median"):
        r = res[(res["study"] == study) & (res["method"] == method)].iloc[0]
        rows.append((y, method, r["or"], r["lo"], r["hi"], r["pval"], study == "Meta-analysis"))
        y += 1.0
    y += 0.55                      # gap between studies
total = y - 0.55

# ---- figure -------------------------------------------------------------------
fig = plt.figure(figsize=(134.8 / 25.4, 66 / 25.4))
ax = fig.add_axes([0.3798, 12.7 / 66, AX_W, 49.0 / 66])

lo_all = min(r[3] for r in rows)
hi_all = max(r[4] for r in rows)
ax.set_xscale("log")
ax.set_xlim(lo_all * 0.90, hi_all * 1.08)
ax.set_ylim(total - 0.35, -1.35)
ax.axvline(1.0, linestyle=(0, (3, 2)), color="black", lw=0.6, zorder=1)

for y_row, method, orr, lo, hi, _p, is_meta in rows:
    col = COLOURS[method]
    if is_meta:
        # the meta-analysis as a diamond spanning its interval
        half = 0.26
        ax.add_patch(Polygon([[lo, y_row], [orr, y_row - half], [hi, y_row], [orr, y_row + half]],
                             closed=True, facecolor=col, edgecolor="none", lw=0, zorder=4))
    else:
        ax.plot([lo, hi], [y_row, y_row], color=col, lw=1.0, solid_capstyle="butt", zorder=3)
        ax.plot([orr], [y_row], marker="D", markersize=3.4, markerfacecolor="white",
                markeredgecolor=col, markeredgewidth=0.9, linestyle="none", zorder=4)

ticks = [t for t in (1.0, 1.5, 2.0) if lo_all * 0.90 <= t <= hi_all * 1.08]
ax.set_xticks(ticks)
ax.set_xticklabels([f"{t:.1f}" for t in ticks], fontsize=FS_TICK)
minor_ticks(ax, 0.1, length=2.0, width=0.6)
ax.set_yticks([])
for side in ("left", "right", "top"):
    ax.spines[side].set_visible(False)
ax.spines["bottom"].set_linewidth(0.7)
ax.tick_params(axis="x", length=3.2, width=0.8, pad=1.0)
ax.set_xlabel("Odds ratio per one unit lower\nNLRP3 activity score",
              fontsize=FS_XLAB, fontweight="bold", labelpad=6, linespacing=1.35)


# Body weight is semibold, not "normal": matplotlib's fontweight argument
# overrides rcParams["font.weight"].
def cell(x, y_row, s, weight="semibold", size=FS_BODY, style="normal"):
    return ax.annotate(s, xy=(x, y_row), xycoords=("axes fraction", "data"), ha="left",
                       va="center", fontsize=size, fontweight=weight, style=style,
                       annotation_clip=False)


def cell_study(x, y_row, s):
    """Study name, with a trailing 'et al.' set in italic."""
    if not s.endswith("et al."):
        cell(x, y_row, s)
        return
    t = cell(x, y_row, s[:-len("et al.")])
    fig.canvas.draw()
    w = t.get_window_extent(renderer=fig.canvas.get_renderer()).width / fig.bbox.width
    cell(x + w / AX_W, y_row, "et al.", style="italic")


# headers and the rule beneath them
for x, text in ((X_STUDY, "Study"), (X_N, "Cases / Controls"), (X_OR, "OR (95% CI)"), (X_P, "P")):
    cell(x, -1.00, text, weight="bold", size=FS_HEADER)
ax.annotate("", xy=(X_STUDY - 0.02, -0.62), xytext=(1.672, -0.62),
            xycoords=("axes fraction", "data"), textcoords=("axes fraction", "data"),
            annotation_clip=False, arrowprops=dict(arrowstyle="-", linewidth=0.7, color="0.1"))

for label, n_label, y_centre in labels:
    cell_study(X_STUDY, y_centre, label)
    cell(X_N, y_centre, n_label)

for y_row, _m, orr, lo, hi, p, _is_meta in rows:
    cell(X_OR, y_row, f"{orr:.2f} ({lo:.2f}, {hi:.2f})")
    cell(X_P, y_row, format_pval(p))

fig.savefig(OUT_DIR / "Fig3A_cad_forest.pdf", facecolor="white")
