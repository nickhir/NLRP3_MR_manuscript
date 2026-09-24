#!/usr/bin/env python3
# Fig 3E - mediation waterfall.
#
# Bars showing what is left of the NLRP3 -> CAD effect as each mediator enters.
# Reads results/07d_mediation_waterfall/, writes figures_out/Fig3E_mediation_waterfall.pdf.

import csv

from style import apply_style, RESULTS, OUT_DIR, IVW_C
apply_style()
import matplotlib
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch

FS_BODY, FS_SMALL, FS_TICK, FS_XLAB = 8.0, 7.2, 8.0, 7.8

# Darkest first, ending on the IVW red of Figures 3A-C: the bar loses weight as
# each mediator is taken out of it.
BAR_COLOURS = ["#000000", "#4A4A4A", "#BEBEBE", IVW_C]

with open(RESULTS / "07d_mediation_waterfall" / "waterfall.tsv") as fh:
    ROWS = list(csv.DictReader(fh, delimiter="\t"))
for r in ROWS:
    for k in ("or", "or_lower", "or_upper"):
        r[k] = float(r[k])
    r["label"] = r["label"].replace("\\n", "\n")

# The Figure 3 column width, so that E lines up under C.
FIG_W_MM, FIG_H_MM = 134.8, 72.0
fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))


def fx(mm):
    """A horizontal position in millimetres, as a figure fraction. The grid is
    in mm because the text is: point sizes do not scale with the canvas."""
    return mm / FIG_W_MM


# Row labels are right-aligned, so each ends the same distance from the axis.
X_LABEL = fx(31.4)                  # right edge of the row labels
AX_L, AX_W = fx(35.5), fx(72.8)

# Four evenly pitched rows; the axis spans exactly the row band and data y is
# figure y, so a bar sits on its own label.
ROW_SPACING = 0.200
Y_TOP = 0.870
BAR_H = 0.105
Y_ROW = [Y_TOP - i * ROW_SPACING for i in range(len(ROWS))]
Y_HI = Y_ROW[0] + ROW_SPACING / 2
Y_LO = Y_ROW[-1] - ROW_SPACING / 2

# the widest upper bound plus a hair, so the longest whisker ends inside the axis
X_MIN = 1.0
X_MAX = max(r["or_upper"] for r in ROWS) + 0.02


def x_fig(or_value):
    """Where an odds ratio falls across the page, as a figure fraction."""
    return AX_L + AX_W * (or_value - X_MIN) / (X_MAX - X_MIN)


ax = fig.add_axes([AX_L, Y_LO, AX_W, Y_HI - Y_LO])
ax.set_xlim(X_MIN, X_MAX)
ax.set_ylim(Y_LO, Y_HI)
ax.axvline(1.0, color="#7F7F7F", linestyle="--", linewidth=0.7, dashes=(3, 2), zorder=0)

CAP = BAR_H * 0.15        # half-height of the whisker cap
WHISKER_LW = 1.35          # the interval reads heavier than the arrows

for r, y, col in zip(ROWS, Y_ROW, BAR_COLOURS):
    # whisker first, so the bar covers everything left of its own right edge
    ax.plot([max(r["or_lower"], X_MIN), r["or_upper"]], [y, y], color="black",
            linewidth=WHISKER_LW, solid_capstyle="butt", zorder=1)
    ax.plot([r["or_upper"]] * 2, [y - CAP, y + CAP], color="black",
            linewidth=WHISKER_LW, zorder=1)
    if r["or_lower"] > X_MIN:
        ax.plot([r["or_lower"]] * 2, [y - CAP, y + CAP], color="black",
                linewidth=WHISKER_LW, zorder=1)
    ax.barh(y, r["or"] - 1.0, left=1.0, height=BAR_H, color=col, edgecolor="none", zorder=2)

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

# --- the interval spelled out, on the first and last rows ----------------------
# where the effect starts and what is left; the bar hides the lower bound
ANNO_DY = 0.023
ANNO_GAP = fx(2.4)
for i in (0, len(ROWS) - 1):
    r, y = ROWS[i], Y_ROW[i]
    x = x_fig(r["or_upper"]) + ANNO_GAP
    fig.text(x, y + ANNO_DY, f"OR {r['or']:.2f}", fontsize=FS_BODY, fontweight="bold",
             va="center")
    fig.text(x, y - ANNO_DY, f"(95% CI {r['or_lower']:.2f} to {r['or_upper']:.2f})",
             fontsize=FS_SMALL, va="center")

# --- what each mediator took away --------------------------------------------
# Each arrow's head points down and left, back toward the bar it lands on.
ARR_STEP = fx(4.45)                 # leftward indent added per row
# 5.5 mm inside the axis: the first row's printed interval starts almost at
# the axis edge and the arrow below it has to keep clear
ARR_TAIL = AX_L + AX_W - fx(5.5)    # tail of the topmost arrow
ARR_DX = fx(6.75)                   # horizontal reach, tail to head
# rise and fall differ: the last row's "OR" sits high and the T2D arrow must clear it
ARR_RISE, ARR_FALL = 0.050, 0.029
LABEL_GAP = fx(1.9)                 # arrow's right edge to its label
LABEL_DY = -0.012                   # the hook's mass sits low, so its middle reads high
ARR_RAD = -0.45


def arrow_bbox(p0, p1, rad):
    """True extent of an arc3 arrow, in figure fractions: (x0, x1, y0, y1).

    matplotlib 3.0's FancyArrowPatch.get_window_extent is not the drawn path's
    bounds, so the quadratic Bezier that ConnectionStyle.Arc3 lays down is
    rebuilt here, in display coordinates, where Arc3 places its control point.
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
    # the label hangs off the arrow's right-most point, out on the bulge
    bx0, bx1, by0, by1 = arrow_bbox(tail, head, ARR_RAD)
    fig.text(bx1 + LABEL_GAP, (by0 + by1) / 2 + LABEL_DY,
             f"{ROWS[i]['added']}: ΔOR ≈ {float(ROWS[i]['delta_or']):.2f}",
             fontsize=FS_SMALL, va="center")

fig.savefig(OUT_DIR / "Fig3E_mediation_waterfall.pdf", dpi=600, facecolor="white")
