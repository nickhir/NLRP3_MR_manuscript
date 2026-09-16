#!/usr/bin/env python3
# Fig 4D - IL1RN MR forest.
#
# Forest panel of the IL1Ra activity score against its outcomes.
# Reads results/08_il1rn_positive_control/, writes figures_out/Fig4D_il1rn_mr_forest.pdf.

import csv
import os
from pathlib import Path

os.environ.setdefault("MPLCONFIGDIR", "/tmp/mplconfig")
os.makedirs(os.environ["MPLCONFIGDIR"], exist_ok=True)

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import rcParams, font_manager

from forest_ticks import minor_ticks

SCRIPT_DIR = Path(__file__).resolve().parent
ANALYSIS_DIR = SCRIPT_DIR.parent

IN_FILE = ANALYSIS_DIR / "results" / "08_il1rn_positive_control" / "il1rn_mr_results.tsv"
OUT_DIR = ANALYSIS_DIR / "figures_out"
OUT_DIR.mkdir(parents=True, exist_ok=True)

if not IN_FILE.exists():
    raise SystemExit(f"missing input: {IN_FILE}\n"
                     f"Run analysis/08_il1rn_positive_control.R first.")

# FONT. One typeface across every panel, R and Python alike - see
# figures/fig02c_validation_forest.py and fig02b_instrument_forest.R.
rcParams["pdf.fonttype"] = 42
rcParams["ps.fonttype"] = 42
rcParams["font.family"] = "Open Sans"
rcParams["font.weight"] = "semibold"

# matplotlib registers OpenSans-Bold.ttf AND OpenSans-ExtraBold.ttf under the
# same family at the same weight ("bold"), and ExtraBold wins the tie - so
# fontweight="bold" silently gives ExtraBold.
font_manager.fontManager.ttflist = [
    f for f in font_manager.fontManager.ttflist
    if "OpenSans-ExtraBold" not in f.fname
]

# FS_XLAB is 7.0 here, not the standard's 7.8: these two axis titles are the
# only two-line titles in Figure 4 and at 7.8 they dominated the panel.
FS_BODY, FS_SMALL, FS_TICK, FS_GROUP, FS_XLAB = 8.0, 7.6, 8.0, 8.0, 7.0
GREY = "#8A8A8A"          # house grey, shared across the Figure 4 panels
IVW_C, WM_C = "#C0392B", "#2C6FB5"

# outcome label in the results file -> how it appears in the panel
PROTEIN = "IL1Ra concentration"
DISEASES = ["Gout", "Rheumatoid arthritis (Ishigaki)"]
DISPLAY = {PROTEIN: "IL1Ra concentration",
           "Gout": "Gout",
           "Rheumatoid arthritis (Ishigaki)": "Rheumatoid arthritis"}


def load():
    rows = {}
    with open(IN_FILE) as fh:
        for r in csv.DictReader(fh, delimiter="\t"):
            if r["method"] not in ("IVW", "Weighted median"):
                continue
            key = r["outcome"]
            d = rows.setdefault(key, {})
            slot = "ivw" if r["method"] == "IVW" else "wm"
            d[slot] = (float(r["estimate"]), float(r["ci_lower"]),
                       float(r["ci_upper"]), float(r["p"]))
            # Two lines, not one: spelled out in full - the reader has to see
            # that the grey numbers are cases and controls - but "42,034 cases
            # / 397,989 controls" is 44 mm at 7.6 pt, wider than the entire
            # label.
            if r["n_cases"] not in ("", "NA"):
                d["n"] = [f"{int(float(r['n_cases'])):,} cases /",
                          f"{int(float(r['n_controls'])):,} controls"]
            elif r["n_total"] not in ("", "NA"):
                d["n"] = [f"n = {int(float(r['n_total'])):,}"]
            else:
                d["n"] = []
            d["label"] = DISPLAY.get(key, key)
    missing = [k for k in [PROTEIN] + DISEASES if k not in rows]
    if missing:
        raise SystemExit(f"missing outcomes in {IN_FILE}: {missing}")
    return rows


ROWS = load()


def fmt_p(p):
    return f"{p:.2g}" if p >= 1e-3 else f"{p:.0e}".replace("e-0", "e-")


def fmt_est(e, lo, hi):
    return f"{e:.2f} ({lo:.2f}, {hi:.2f})"


FIG_W_MM, FIG_H_MM = 96.0, 70.0
fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))

X_LABEL, X_EST, X_P = 0.012, 0.560, 0.855
FOREST_L, FOREST_W = 0.345, 0.190

# VERTICAL LAYOUT IS IN MILLIMETRES, measured down from the top edge, and
# converted at the end.
def fy(mm_from_top):
    """mm from the top edge -> figure fraction."""
    return 1.0 - mm_from_top / FIG_H_MM


def fh(mm_val):
    """a height in mm -> figure fraction."""
    return mm_val / FIG_H_MM


Y_HEADER = 3.6      # column headers
Y_RULE = 6.4        # rule under them
ROW_MM = 12.0       # between outcome rows within a block
DY_MM = 2.3         # half-separation of the two method lines
NAME_DY = 2.1       # outcome name above the row centre
SUB_DY = 1.4        # first sample-size line below it
SUB_STEP = 2.9      # between sample-size lines

ROW_SPACING = fh(ROW_MM)
DY_FIG = fh(DY_MM)
DY_DATA = DY_MM / ROW_MM        # the same offset, in axis data units

fig.text(X_LABEL, fy(Y_HEADER), "Outcome", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_EST, fy(Y_HEADER), "Effect (95% CI)", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_P, fy(Y_HEADER), "P", fontsize=FS_BODY, fontweight="bold", va="center")
fig.add_artist(plt.Line2D([X_LABEL, 0.985], [fy(Y_RULE), fy(Y_RULE)], color="black",
                          linewidth=0.6, transform=fig.transFigure))


def text_block(r, ycentre):
    # The name sits above the row centre and the count lines stack below it, so
    # a one-line and a two-line row still centre on the same baseline.
    fig.text(X_LABEL + 0.018, ycentre + fh(NAME_DY), r["label"],
             fontsize=FS_BODY, va="center")
    for i, line in enumerate(r["n"]):
        fig.text(X_LABEL + 0.018, ycentre - fh(SUB_DY + i * SUB_STEP), line,
                 fontsize=FS_SMALL, va="center", color=GREY)
    for k, off in (("ivw", DY_FIG), ("wm", -DY_FIG)):
        e, lo, hi, p = r[k]
        fig.text(X_EST, ycentre + off, fmt_est(e, lo, hi), fontsize=FS_BODY, va="center")
        fig.text(X_P, ycentre + off, fmt_p(p), fontsize=FS_BODY, va="center")


def draw_axis(rows, y_first, logscale, null, xlim, ticks, minor_step, xlabel):
    n = len(rows)
    rect = [FOREST_L,
            (y_first - (n - 1) * ROW_SPACING) - ROW_SPACING / 2,
            FOREST_W,
            n * ROW_SPACING]
    ax = fig.add_axes(rect)
    ax.set_xlim(*xlim)
    if logscale:
        ax.set_xscale("log")
    ax.set_ylim(-0.5, n - 0.5)
    ax.invert_yaxis()
    # The null line stops just above the FIRST row rather than running the
    # whole rect.
    ax.plot([null, null], [-DY_DATA - 0.18, n - 0.5], color="black",
            linestyle="--", linewidth=0.5, dashes=(3, 2), zorder=1)
    for i, r in enumerate(rows):
        for k, off, col in (("ivw", -DY_DATA, IVW_C), ("wm", DY_DATA, WM_C)):
            e, lo, hi, _ = r[k]
            ax.plot([lo, hi], [i + off] * 2, color=col, linewidth=0.8,
                    solid_capstyle="butt", zorder=2)
            ax.plot([e], [i + off], marker="D", markersize=2.5,
                    markerfacecolor="white", markeredgecolor=col,
                    markeredgewidth=0.7, zorder=3)
    ax.set_xticks(ticks)
    ax.set_xticklabels(["%g" % t for t in ticks], fontsize=FS_TICK)
    ax.tick_params(axis="x", length=2.8, width=0.6, pad=0.6)
    ax.set_yticks([])
    # Minor ticks come from figures/forest_ticks.py - one implementation for
    # every forest axis in this directory; see that module for why
    # matplotlib's own log minors are not usable here.
    minor_ticks(ax, minor_step, length=1.7, width=0.55)
    for s in ("top", "left", "right"):
        ax.spines[s].set_visible(False)
    ax.spines["bottom"].set_linewidth(0.5)
    ax.set_xlabel(xlabel, fontsize=FS_XLAB, fontweight="bold", labelpad=1.6,
                  linespacing=1.15)


# --- protein block ---------------------------------------------------------
Y_PROT = fy(12.8)
text_block(ROWS[PROTEIN], Y_PROT)
draw_axis([ROWS[PROTEIN]], Y_PROT, False, 0.0, (-1.4, 8.6), [0, 4, 8], 1,
          "SD change per one unit higher\nIL1Ra activity score")

# --- disease block ---------------------------------------------------------
Y_FIRST = fy(34.6)
for i, key in enumerate(DISEASES):
    text_block(ROWS[key], Y_FIRST - i * ROW_SPACING)
draw_axis([ROWS[k] for k in DISEASES], Y_FIRST, True, 1.0, (0.05, 1.12),
          [0.1, 0.5, 1], 0.1,
          "Odds ratio per one unit higher\nIL1Ra activity score")

# --- legend, below the plot ------------------------------------------------
LY, HALF = fy(66.4), 0.022


def legend_entry(x, colour, text):
    fig.add_artist(plt.Line2D([x - HALF, x + HALF], [LY, LY], color=colour,
                              linewidth=0.8, transform=fig.transFigure))
    fig.add_artist(plt.Line2D([x], [LY], marker="D", markersize=2.6, color=colour,
                              markerfacecolor="white", markeredgewidth=0.7,
                              linestyle="none", transform=fig.transFigure))
    fig.text(x + HALF + 0.012, LY, text, fontsize=FS_SMALL, va="center")


# Measured rather than hand-placed, so the group stays centred at any panel
# width or label wording.
fig.canvas.draw()
renderer = fig.canvas.get_renderer()
ITEMS = [(IVW_C, "IVW"), (WM_C, "Weighted Median")]
label_w = []
for _, text in ITEMS:
    probe = fig.text(0, 0, text, fontsize=FS_SMALL)
    label_w.append(probe.get_window_extent(renderer=renderer).width / fig.bbox.width)
    probe.remove()
GAP, PAD = 0.045, 0.012
item_w = [2 * HALF + PAD + w for w in label_w]
x = 0.5 - (sum(item_w) + GAP * (len(ITEMS) - 1)) / 2
for (colour, text), w in zip(ITEMS, item_w):
    legend_entry(x + HALF, colour, text)
    x += w + GAP

fig.savefig(OUT_DIR / "Fig4D_il1rn_mr_forest.pdf", dpi=600, facecolor="white")
print(f"wrote {OUT_DIR / 'Fig4D_il1rn_mr_forest.pdf'}  ({FIG_W_MM:.0f} x {FIG_H_MM:.0f} mm)")
