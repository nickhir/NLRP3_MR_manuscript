#!/usr/bin/env python3
# Fig 2C - validation forest.
#
# Forest panel of the inflammatory readouts and the effector cytokines.
# Reads results/04_mr_biomarkers/, writes figures_out/Fig2C_validation_forest.pdf.

import csv
from pathlib import Path

from style import apply_style
apply_style()
import matplotlib.pyplot as plt

from forest_ticks import minor_ticks

SCRIPT_DIR = Path(__file__).resolve().parent
ANALYSIS_DIR = SCRIPT_DIR.parent

IN_FILE = ANALYSIS_DIR / "results" / "04_mr_biomarkers" / "mr_biomarkers.tsv"
OUT_DIR = ANALYSIS_DIR / "figures_out"
OUT_DIR.mkdir(parents=True, exist_ok=True)

FS_BODY, FS_SMALL, FS_TICK, FS_GROUP, FS_XLAB = 8.0, 7.6, 8.0, 8.0, 7.8
IVW_C, WM_C = "#C0392B", "#2C6FB5"

PROXIES = ["CRP concentration", "GlycA concentration", "Neutrophil count"]
CYTOKINES = ["IL1B", "IL18", "IL6"]

# outcome label in the results file -> how it appears in the panel.
# The interleukins take the manuscript's hyphenated forms (see its abbreviation
# list), not the UKB-PPP gene symbols the results file is keyed on.
DISPLAY = {"CRP concentration": "CRP",
           "GlycA concentration": "GlycA",
           "Neutrophil count": "Neutrophil count",
           "IL1B": "IL-1β",
           "IL18": "IL-18",
           "IL6": "IL-6"}

# Group headings, one tuple of lines each. Splitting a heading over two lines is
# a display choice only - the results file keeps each block name as one string.
HEADINGS = [(("Systemic inflammation proxies",), PROXIES),
            (("NLRP3 inflammasome-associated", "cytokines"), CYTOKINES)]


def load():
    rows = {}
    with open(IN_FILE) as fh:
        for r in csv.DictReader(fh, delimiter="\t"):
            if r["method"] not in ("IVW", "Weighted median"):
                continue
            d = rows.setdefault(r["outcome"], {})
            slot = "ivw" if r["method"] == "IVW" else "wm"
            d[slot] = (float(r["estimate"]), float(r["ci_lower"]),
                       float(r["ci_upper"]), float(r["p"]))
            if r["n_total"] not in ("", "NA"):
                d["n"] = f"n = {int(float(r['n_total'])):,}"
            else:
                d["n"] = ""
            d["label"] = DISPLAY.get(r["outcome"], r["outcome"])
    return rows


ROWS = load()


def fmt_p(p):
    # Two significant figures throughout, as the manuscript prints them. Figure
    # 4D drops to one because its P column is narrower; here there is room.
    return f"{p:.2g}" if p >= 1e-3 else f"{p:.1e}".replace("e-0", "e-")


def fmt_est(e, lo, hi):
    return f"{e:.2f} ({lo:.2f}, {hi:.2f})"


FIG_W_MM, FIG_H_MM = 88.0, 102.0
fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))

# Column positions are hand-laid, so they have to be checked against the font
# size rather than left alone.
X_LABEL, X_EST, X_P = 0.015, 0.523, 0.832
FOREST_L, FOREST_W = 0.303, 0.200
X_INDENT = 0.014        # outcome names sit inside their group heading

ROW_SPACING = 0.104     # figure fraction between outcome rows
LINE_H = 0.028          # one line of heading text
HEAD_TO_ROW = 0.066     # bottom of a heading block -> centre of its first row
BLOCK_GAP = 0.098       # last row of a block -> top of the next heading
DY = 0.0255             # half-separation of the two method lines

# --- lay the rows out on one grid -------------------------------------------
# Each entry is (kind, key, y). Group headings take a slot of their own so the
# single forest axis can span everything without the two blocks drifting apart.
LAYOUT = []
y = 0.918
for lines, keys in HEADINGS:
    height = len(lines) * LINE_H
    LAYOUT.append(("group", lines, y - height / 2))
    y -= height + HEAD_TO_ROW
    for k in keys:
        LAYOUT.append(("row", k, y))
        y -= ROW_SPACING
    y += ROW_SPACING - BLOCK_GAP

DATA_Y = [(k, yy) for kind, k, yy in LAYOUT if kind == "row"]
Y_TOP = max(yy for _, yy in DATA_Y) + ROW_SPACING / 2
Y_BOT = min(yy for _, yy in DATA_Y) - ROW_SPACING / 2

# --- column headers ----------------------------------------------------------
fig.text(X_LABEL, 0.968, "Outcome", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_EST, 0.968, "β (95% CI)", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_P, 0.968, "P", fontsize=FS_BODY, fontweight="bold", va="center")
fig.add_artist(plt.Line2D([X_LABEL, 0.985], [0.940, 0.940], color="black",
                          linewidth=0.6, transform=fig.transFigure))

# --- text column -------------------------------------------------------------
for kind, key, ycentre in LAYOUT:
    if kind == "group":
        # A heading longer than the outcome column runs on over the forest, and
        # the dashed null line would strike through it.
        fig.text(X_LABEL, ycentre, "\n".join(key), fontsize=FS_GROUP,
                 fontweight="bold", va="center", linespacing=1.15,
                 bbox=dict(facecolor="white", edgecolor="none", pad=0.8))
        continue
    r = ROWS[key]
    fig.text(X_LABEL + X_INDENT, ycentre + 0.018, r["label"], fontsize=FS_BODY, va="center")
    fig.text(X_LABEL + X_INDENT, ycentre - 0.020, r["n"], fontsize=FS_SMALL,
             va="center", color="#8A8A8A")
    for slot, off in (("ivw", DY), ("wm", -DY)):
        e, lo, hi, p = r[slot]
        fig.text(X_EST, ycentre + off, fmt_est(e, lo, hi), fontsize=FS_BODY, va="center")
        fig.text(X_P, ycentre + off, fmt_p(p), fontsize=FS_BODY, va="center")

# --- the single forest axis --------------------------------------------------
lo_all = min(min(ROWS[k][s][1] for s in ("ivw", "wm")) for k, _ in DATA_Y)
hi_all = max(max(ROWS[k][s][2] for s in ("ivw", "wm")) for k, _ in DATA_Y)
span = hi_all - lo_all
xlim = (min(lo_all - 0.06 * span, -0.02), max(hi_all + 0.06 * span, 0.02))
ticks = [t for t in (-1.5, -1.0, -0.5, 0.0, 0.5) if xlim[0] <= t <= xlim[1]]

ax = fig.add_axes([FOREST_L, Y_BOT, FOREST_W, Y_TOP - Y_BOT])
ax.set_xlim(*xlim)
ax.set_ylim(Y_BOT, Y_TOP)          # data y == figure y, so rows align exactly
ax.axvline(0.0, color="black", linestyle="--", linewidth=0.5, dashes=(3, 2))

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
minor_ticks(ax, 0.1, length=1.7, width=0.55)
for s in ("top", "left", "right"):
    ax.spines[s].set_visible(False)
ax.spines["bottom"].set_linewidth(0.5)
ax.set_xlabel("β per one unit lower\nNLRP3 activity score",
              fontsize=FS_XLAB, fontweight="bold", labelpad=1.6, linespacing=1.15)

# --- legend, below the plot --------------------------------------------------
LY, HALF = 0.020, 0.022


def legend_entry(x, colour, text):
    fig.add_artist(plt.Line2D([x - HALF, x + HALF], [LY, LY], color=colour,
                              linewidth=0.8, transform=fig.transFigure))
    fig.add_artist(plt.Line2D([x], [LY], marker="D", markersize=2.5, color=colour,
                              markerfacecolor="white", markeredgewidth=0.7,
                              linestyle="none", transform=fig.transFigure))
    fig.text(x + HALF + 0.012, LY, text, fontsize=FS_SMALL, va="center")


legend_entry(0.330, IVW_C, "IVW")
legend_entry(0.530, WM_C, "Weighted Median")

fig.savefig(OUT_DIR / "Fig2C_validation_forest.pdf", dpi=600, facecolor="white")
print(f"wrote {OUT_DIR / 'Fig2C_validation_forest.pdf'}  ({FIG_W_MM:.0f} x {FIG_H_MM:.0f} mm)")
