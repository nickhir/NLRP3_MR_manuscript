#!/usr/bin/env python3
# Fig 3A - cis-NLRP3 activity -> coronary artery disease.
#
# Forest panel of the four CAD cohorts and their fixed-effect meta-analysis.
# Reads results/05_mr_cad/, writes figures_out/Fig3A_cad_forest.pdf.

import os
from pathlib import Path

os.environ.setdefault("MPLCONFIGDIR", "/tmp/mplconfig")
os.makedirs(os.environ["MPLCONFIGDIR"], exist_ok=True)

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import rcParams, font_manager
from matplotlib.patches import Polygon

from forest_ticks import minor_ticks
import numpy as np
import pandas as pd

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]

# FONT. The Figure 2 convention - see figures/fig02c_validation_forest.py for
# the full reasoning.
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

# SIZE AND TYPE. 190 mm wide with 8 pt body text, matching Figure 3B directly
# beneath it; the sizes are Figure 2C's.
FS_BODY = 8.0
FS_HEADER = 8.0
FS_TICK = 8.0
FS_XLAB = 7.8
FS_PANEL = 12.0

# Same red/blue as Figure 2C, so IVW and weighted median read alike across the
# whole manuscript.
COLOURS = {"IVW": "#C0392B", "Weighted Median": "#2C6FB5"}
METHOD_ORDER = ["IVW", "Weighted Median"]

# Study order, display label, cases and controls.
STUDIES = [
    ("Aragam et al.", "Aragam et al.", 181_522, 984_168),
    ("MVP", "MVP", 124_302, 300_039),
    ("All of Us", "All of Us", 19_856, 150_307),
    ("FinnGen", "FinnGen", 63_307, 416_171),
    ("Meta-analysis", "Meta-analysis", None, None),
]

# COLUMN GRID, sized to THIS panel's own content. Measured at 8 pt: Study 18.8
# mm ("Meta-analysis"), Cases / Controls 25.9 ("388,987 / 1,850,685"), OR 21.0,
# P 7.3, with a 2.5 mm gutter.
X_STUDY = -1.0184
X_N = -0.5820
X_OR = 1.0512
X_P = 1.5328


def format_pval(p: float) -> str:
    if pd.isna(p):
        return ""
    if p >= 0.001:
        return f"{p:.3f}"
    return f"{p:.1e}".replace("e-0", "e-")


def main() -> None:
    analysis_dir = SCRIPT_DIR.parent
    res = pd.read_csv(analysis_dir / "results" / "05_mr_cad" / "cad_meta_studies.tsv", sep="\t")
    out_pdf = analysis_dir / "figures_out" / "Fig3A_cad_forest.pdf"

    res["or"] = np.exp(res["beta"])
    res["lo"] = np.exp(res["ci_lower"])
    res["hi"] = np.exp(res["ci_upper"])

    meta_cases = sum(s[2] for s in STUDIES if s[2] is not None)
    meta_controls = sum(s[3] for s in STUDIES if s[3] is not None)

    # ---- lay out rows -----------------------------------------------------
    rows, labels = [], []
    y = 0.0
    for key, label, cases, controls in STUDIES:
        if cases is None:
            cases, controls = meta_cases, meta_controls
        labels.append((label, f"{cases:,} / {controls:,}", y + 0.5))
        for method in METHOD_ORDER:
            r = res[(res["study"] == key) & (res["method"] == method)].iloc[0]
            rows.append((y, method, r["or"], r["lo"], r["hi"], r["pval"],
                         key == "Meta-analysis"))
            y += 1.0
        y += 0.55                      # gap between studies
    total = y - 0.55

    # ---- figure -----------------------------------------------------------
    # NO LEGEND, and 66 mm rather than 72.
    fig = plt.figure(figsize=(134.8 / 25.4, 66 / 25.4))
    ax = fig.add_axes([0.3798, 12.7 / 66, 0.3620, 49.0 / 66])

    lo_all = min(r[3] for r in rows)
    hi_all = max(r[4] for r in rows)
    ax.set_xscale("log")
    ax.set_xlim(lo_all * 0.90, hi_all * 1.08)
    ax.set_ylim(total - 0.35, -1.35)

    ax.axvline(1.0, linestyle=(0, (3, 2)), color="black", lw=0.6, zorder=1)

    for y_row, method, orr, lo, hi, _p, is_meta in rows:
        col = COLOURS[method]
        if is_meta:
            # conventional meta-analysis diamond, spanning the interval
            half = 0.26
            # edgecolor="none".
            ax.add_patch(Polygon(
                [[lo, y_row], [orr, y_row - half], [hi, y_row], [orr, y_row + half]],
                closed=True, facecolor=col, edgecolor="none", lw=0, zorder=4,
            ))
        else:
            # Marker and line weights match Figure 3B. The old 6.0 pt diamonds
            # were sized for the 267 mm drawing this replaced.
            ax.plot([lo, hi], [y_row, y_row], color=col, lw=1.0,
                    solid_capstyle="butt", zorder=3)
            ax.plot([orr], [y_row], marker="D", markersize=3.4,
                    markerfacecolor="white", markeredgecolor=col,
                    markeredgewidth=0.9, linestyle="none", zorder=4)

    ticks = [t for t in (1.0, 1.5, 2.0) if lo_all * 0.90 <= t <= hi_all * 1.08]
    ax.set_xticks(ticks)
    ax.set_xticklabels([f"{t:.1f}" for t in ticks], fontsize=FS_TICK)
    # Minor ticks come from figures/forest_ticks.py - one implementation for
    # every forest axis in this directory; see that module for why
    # matplotlib's own log minors are not usable here.
    minor_ticks(ax, 0.1, length=2.0, width=0.6)
    ax.set_yticks([])
    for side in ("left", "right", "top"):
        ax.spines[side].set_visible(False)
    ax.spines["bottom"].set_linewidth(0.7)
    ax.tick_params(axis="x", length=3.2, width=0.8, pad=1.0)
    ax.set_xlabel("Odds ratio per one unit lower\nNLRP3 activity score",
                  fontsize=FS_XLAB, fontweight="bold", labelpad=6, linespacing=1.35)

    txt = ("axes fraction", "data")

    # Body weight is SEMIBOLD, not "normal": matplotlib's fontweight argument
    # overrides rcParams["font.weight"], so a "normal" default here would quietly
    # set this panel in regular Open Sans while 3B and 3C stayed semibold.
    def cell(x, y_row, s, weight="semibold", size=FS_BODY, style="normal"):
        return ax.annotate(s, xy=(x, y_row), xycoords=txt, ha="left", va="center",
                           fontsize=size, fontweight=weight, style=style,
                           annotation_clip=False)

    AX_W = 0.3620          # the forest axes' width as a figure fraction

    def cell_study(x, y_row, s):
        """Study name, with a trailing 'et al.' set in italic."""
        tail = "et al."
        if not s.endswith(tail):
            cell(x, y_row, s)
            return
        stem = s[: -len(tail)]
        t = cell(x, y_row, stem)
        fig.canvas.draw()
        w = (t.get_window_extent(renderer=fig.canvas.get_renderer()).width
             / fig.bbox.width)          # figure fraction
        cell(x + w / AX_W, y_row, tail, style="italic")

    # headers and the rule beneath them
    y_head = -1.00
    cell(X_STUDY, y_head, "Study", weight="bold", size=FS_HEADER)
    cell(X_N, y_head, "Cases / Controls", weight="bold", size=FS_HEADER)
    cell(X_OR, y_head, "OR (95% CI)", weight="bold", size=FS_HEADER)
    cell(X_P, y_head, "P", weight="bold", size=FS_HEADER)
    for x0, x1 in ((X_STUDY - 0.02, 1.672),):
        ax.annotate("", xy=(x0, -0.62), xytext=(x1, -0.62),
                    xycoords=txt, textcoords=txt, annotation_clip=False,
                    arrowprops=dict(arrowstyle="-", linewidth=0.7, color="0.1"))

    for label, n_label, y_centre in labels:
        cell_study(X_STUDY, y_centre, label)
        cell(X_N, y_centre, n_label)

    for y_row, _m, orr, lo, hi, p, _is_meta in rows:
        cell(X_OR, y_row, f"{orr:.2f} ({lo:.2f}, {hi:.2f})")
        cell(X_P, y_row, format_pval(p))

    # No panel letter: Figure 2's letters are placed by the script that
    # assembles the figure, and Figure 3 should match.

    # No bbox_inches="tight": it crops to the drawn content, which made this
    # panel 152 mm wide instead of the 190 mm the figsize asks for, so it could
    # not be stacked with Figure 3B at a matching width.
    fig.savefig(out_pdf, facecolor="white")
    print(f"wrote {out_pdf}")


if __name__ == "__main__":
    main()
