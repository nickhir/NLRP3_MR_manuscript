#!/usr/bin/env python3
# Fig 3E - mediation waterfall.
#
# Bars showing what is left of the NLRP3 -> CAD effect as each mediator enters.
# Reads results/07d_mediation_waterfall/, writes figures_out/Fig3E_mediation_waterfall.pdf.

import csv
import os
from pathlib import Path

os.environ.setdefault("MPLCONFIGDIR", "/tmp/mplconfig")
os.makedirs(os.environ["MPLCONFIGDIR"], exist_ok=True)

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import rcParams, font_manager
from matplotlib.patches import FancyArrowPatch

SCRIPT_DIR = Path(__file__).resolve().parent
ANALYSIS_DIR = SCRIPT_DIR.parent
IN_FILE = ANALYSIS_DIR / "results" / "07d_mediation_waterfall" / "waterfall.tsv"
OUT_DIR = ANALYSIS_DIR / "figures_out"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# FONT. The Figure 2 convention - see figures/fig02c_validation_forest.py.
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

FS_BODY, FS_SMALL, FS_TICK, FS_XLAB = 8.0, 7.2, 8.0, 7.8

# Darkest first, ending on the red used for IVW in Figures 3A-C. The ramp is the
# point: the bar loses weight as each mediator is taken out of it.
BAR_COLOURS = ["#000000", "#4A4A4A", "#BEBEBE", "#C0392B"]


def load():
    with open(IN_FILE) as fh:
        rows = list(csv.DictReader(fh, delimiter="\t"))
    for r in rows:
        for k in ("or", "or_lower", "or_upper"):
            r[k] = float(r[k])
        r["delta_or"] = float(r["delta_or"]) if r["delta_or"] not in ("", "NA") else None
        r["label"] = r["label"].replace("\\n", "\n")
    # The geometry below assumes every bar grows rightward from 1 and every step
    # shrinks it. Both hold today; neither is guaranteed by the statistics, and a
    # silently upside-down bar would misread as the opposite conclusion.
    drop = sum(r["delta_or"] for r in rows if r["delta_or"] is not None)
    return rows


ROWS = load()

# WIDTH IS THE FIGURE 3 COLUMN WIDTH, not this panel's own content. At 113.9 mm
# the text block sits 2.4 mm from each edge with nothing wasted, but E has to
# line up underneath C, and C is 134.8 mm.
FIG_W_MM, FIG_H_MM = 134.8, 72.0
fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))

# COLUMN GRID. The row labels are RIGHT-aligned so their ragged left edge
# points away from the bars and every label ends the same distance from the
# axis, which is how the published panel reads.
def fx(mm):
    """A horizontal position given in millimetres, as a figure fraction.

    THE GRID IS IN MILLIMETRES because the TEXT is: point sizes do not scale
    with the canvas, so trimming FIG_W_MM while holding fractions fixed would
    slide every column relative to the type it has to clear, and the gaps tuned
    above would silently change. In mm, FIG_W_MM is a single knob - change it
    and only the right margin moves.
    """
    return mm / FIG_W_MM


X_LABEL = fx(31.4)                  # right edge of the row labels
AX_L, AX_W = fx(35.5), fx(72.8)

# VERTICAL. Four evenly pitched rows; the axis spans exactly the row band, and
# data y is figure y so a bar sits on its own label by construction.
ROW_SPACING = 0.200
Y_TOP = 0.870
BAR_H = 0.105
Y_ROW = [Y_TOP - i * ROW_SPACING for i in range(len(ROWS))]

Y_HI = Y_ROW[0] + ROW_SPACING / 2
Y_LO = Y_ROW[-1] - ROW_SPACING / 2

# X range from the data: the widest upper bound plus a hair, so the longest
# whisker ends just inside the axis as it does in the published panel.
X_MIN = 1.0
X_MAX = max(r["or_upper"] for r in ROWS) + 0.02

def x_fig(or_value):
    """Where an odds ratio falls across the page, as a figure fraction."""
    return AX_L + AX_W * (or_value - X_MIN) / (X_MAX - X_MIN)


ax = fig.add_axes([AX_L, Y_LO, AX_W, Y_HI - Y_LO])
ax.set_xlim(X_MIN, X_MAX)
ax.set_ylim(Y_LO, Y_HI)

# The null, at the bar origin. Behind everything.
ax.axvline(1.0, color="#7F7F7F", linestyle="--", linewidth=0.7, dashes=(3, 2),
           zorder=0)

CAP = BAR_H * 0.15        # half-height of the whisker cap
WHISKER_LW = 1.35          # the interval reads heavier than the arrows

for r, y, col in zip(ROWS, Y_ROW, BAR_COLOURS):
    # Whisker first, so the bar covers everything left of its own right edge.
    lo = max(r["or_lower"], X_MIN)
    ax.plot([lo, r["or_upper"]], [y, y], color="black", linewidth=WHISKER_LW,
            solid_capstyle="butt", zorder=1)
    ax.plot([r["or_upper"]] * 2, [y - CAP, y + CAP], color="black",
            linewidth=WHISKER_LW, zorder=1)
    if r["or_lower"] > X_MIN:
        ax.plot([r["or_lower"]] * 2, [y - CAP, y + CAP], color="black",
                linewidth=WHISKER_LW, zorder=1)

    ax.barh(y, r["or"] - 1.0, left=1.0, height=BAR_H, color=col,
            edgecolor="none", zorder=2)

ax.set_yticks([])
ax.minorticks_off()
for s in ("top", "left", "right"):
    ax.spines[s].set_visible(False)
ax.spines["bottom"].set_linewidth(0.7)

ticks = [1.0 + 0.1 * i for i in range(int((X_MAX - 1.0) / 0.1) + 1)]
ax.set_xticks(ticks)
ax.set_xticklabels([("1" if abs(t - 1.0) < 1e-9 else f"{t:.1f}") for t in ticks],
                   fontsize=FS_TICK)
ax.xaxis.set_minor_locator(matplotlib.ticker.NullLocator())
ax.tick_params(axis="x", length=3.2, width=0.8, pad=1.0)
ax.set_xlabel("Odds ratio for CAD per one unit lower\nNLRP3 activity score",
              fontsize=FS_XLAB, fontweight="bold", labelpad=2.0, linespacing=1.25)

# --- row labels --------------------------------------------------------------
for r, y in zip(ROWS, Y_ROW):
    fig.text(X_LABEL, y, r["label"], fontsize=FS_BODY, fontweight="bold",
             ha="right", va="center", linespacing=1.3)

# --- the interval, spelled out, on the first and last rows only ---------------
# These two are the panel's claim: where the effect starts and what is left.
# The printed interval is also the only place the LOWER bound appears, since
# the bar covers it.
ANNO_DY = 0.023
ANNO_GAP = fx(2.4)
for i in (0, len(ROWS) - 1):
    r, y = ROWS[i], Y_ROW[i]
    x = x_fig(r["or_upper"]) + ANNO_GAP
    fig.text(x, y + ANNO_DY, f"OR {r['or']:.2f}",
             fontsize=FS_BODY, fontweight="bold", va="center")
    fig.text(x, y - ANNO_DY,
             f"(95% CI {r['or_lower']:.2f} to {r['or_upper']:.2f})",
             fontsize=FS_SMALL, va="center")

# --- what each mediator took away --------------------------------------------
# THE HEAD POINTS DOWN AND LEFT, back toward the bar it lands on.
ARR_STEP = fx(4.45)                 # leftward indent added per row
# 5.5 mm inside the axis, not 1.9: the first row's upper bound sits very near
# X_MAX, so its printed interval starts almost at the axis edge and the arrow
# below it has to keep out of the way.
ARR_TAIL = AX_L + AX_W - fx(5.5)    # tail of the topmost arrow
ARR_DX = fx(6.75)                   # horizontal reach, tail to head
# Rise and fall are NOT equal. The binding constraint is underneath: the last
# row's "OR" sits high on its row and the T2D arrow has to clear it, while
# nothing at all sits above the first arrow.
ARR_RISE, ARR_FALL = 0.050, 0.029
LABEL_GAP = fx(1.9)                 # arrow's right edge to its label
LABEL_DY = -0.012                   # label sits below the arrow's bbox centre

# rad is NEGATIVE.
ARR_RAD = -0.45

def arrow_bbox(p0, p1, rad):
    """True extent of an arc3 arrow, in figure fractions: (x0, x1, y0, y1).

    matplotlib 3.0's FancyArrowPatch.get_window_extent does NOT return the drawn
    path's bounds - measured against these arrows it was out by 4 mm vertically
    and 2 mm horizontally - so the quadratic Bezier that ConnectionStyle.Arc3
    actually lays down is reconstructed here.

    Arc3 places its control point in DISPLAY coordinates, so the arithmetic has
    to happen there and come back: the page is 135 x 72 mm, and doing it in
    figure fractions would skew the curve by the aspect ratio.
    """
    W, H = fig.bbox.width, fig.bbox.height
    x1, y1, x2, y2 = p0[0] * W, p0[1] * H, p1[0] * W, p1[1] * H
    cx = (x1 + x2) / 2 + rad * (y2 - y1)
    cy = (y1 + y2) / 2 - rad * (x2 - x1)

    def span(a, c, b):
        lo, hi = min(a, b), max(a, b)
        denom = a - 2 * c + b
        if abs(denom) > 1e-9:
            t = (a - c) / denom
            if 0 < t < 1:                       # the curve turns inside the span
                v = (1 - t) ** 2 * a + 2 * (1 - t) * t * c + t ** 2 * b
                lo, hi = min(lo, v), max(hi, v)
        return lo, hi

    xs = span(x1, cx, x2)
    ys = span(y1, cy, y2)
    return xs[0] / W, xs[1] / W, ys[0] / H, ys[1] / H


for i in range(1, len(ROWS)):
    y_mid = (Y_ROW[i - 1] + Y_ROW[i]) / 2
    indent = (i - 1) * ARR_STEP
    tail = (ARR_TAIL - indent, y_mid + ARR_RISE)
    head = (ARR_TAIL - indent - ARR_DX, y_mid - ARR_FALL)
    fig.add_artist(FancyArrowPatch(
        tail, head, transform=fig.transFigure,
        connectionstyle=f"arc3,rad={ARR_RAD}", arrowstyle="-|>",
        mutation_scale=6.6, linewidth=1.0, color="black",
        shrinkA=0, shrinkB=0))

    # The label hangs off the arrow's RIGHT-MOST point, which is out on the bulge
    # rather than at either endpoint, and centres on the arrow's own vertical
    # span. Both follow the arrow if any of the constants above change.
    bx0, bx1, by0, by1 = arrow_bbox(tail, head, ARR_RAD)
    # Dropped below the bbox centre on purpose: the hook's mass sits low - the
    # tail is a thin overhang at the top - so the geometric middle reads high.
    fig.text(bx1 + LABEL_GAP, (by0 + by1) / 2 + LABEL_DY,
             f"{ROWS[i]['added']}: ΔOR ≈ {ROWS[i]['delta_or']:.2f}",
             fontsize=FS_SMALL, va="center")
    print(f"    arrow {ROWS[i]['added']:<5} x {bx0:.3f}-{bx1:.3f}  "
          f"y {by0:.3f}-{by1:.3f}  label at {bx1 + LABEL_GAP:.3f}")

# --- the layout has to actually fit ------------------------------------------
# Right-aligned labels grow leftwards, so the longest one decides whether the
# panel runs off its own edge. Measuring beats eyeballing: at assembly time the
# panel letter sits above this corner and an overhanging label would collide.
fig.canvas.draw()
rend = fig.canvas.get_renderer()
left = min(t.get_window_extent(renderer=rend).x0 for t in fig.texts) / fig.bbox.width
print(f"    left margin {left * FIG_W_MM:.1f} mm")

fig.savefig(OUT_DIR / "Fig3E_mediation_waterfall.pdf", dpi=600,
            facecolor="white")
print(f"wrote {OUT_DIR / 'Fig3E_mediation_waterfall.pdf'}  "
      f"({FIG_W_MM:.0f} x {FIG_H_MM:.0f} mm)")
