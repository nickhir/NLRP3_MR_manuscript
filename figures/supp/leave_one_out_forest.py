#!/usr/bin/env python3
# Sup Fig - leave-one-out forest.
#
# The NLRP3 -> CAD estimate with each instrument dropped in turn.
# Reads results/11_mr_sensitivity/, writes figures_out/SupFig_leave_one_out.pdf.

import csv
import os
import sys
from math import exp
from pathlib import Path

os.environ.setdefault("MPLCONFIGDIR", "/tmp/mplconfig")
os.makedirs(os.environ["MPLCONFIGDIR"], exist_ok=True)

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import rcParams, font_manager

# figures/ is this script's parent, and it is not on sys.path when the
# script is run from supp/.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from forest_ticks import minor_ticks

# figures/supp/ is one level deeper than the main panels
SCRIPT_DIR = Path(__file__).resolve().parent
ANALYSIS_DIR = SCRIPT_DIR.parent.parent
IN_DIR = ANALYSIS_DIR / "results" / "11_mr_sensitivity"
OUT_DIR = ANALYSIS_DIR / "figures_out"
OUT_DIR.mkdir(parents=True, exist_ok=True)

for f in ("leave_one_out.tsv", "instrument_rsids.tsv", "single_variant.tsv"):
    if not (IN_DIR / f).exists():
        raise SystemExit(f"missing input: {IN_DIR / f}\n"
                         f"Run analysis/11_mr_sensitivity.R first.")

# Same typeface and PDF settings as every other panel - Open Sans semibold,
# fonttype 42. Helvetica is not installed here; asking for it silently fell
# back to DejaVu Sans.
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

FS_BODY, FS_SMALL, FS_TICK, FS_XLAB, FS_GROUP = 8.0, 7.6, 8.0, 7.8, 8.0
GREY = "#8A8A8A"          # house grey, shared with Figure 4F
IVW_C, WM_C = "#C0392B", "#2C6FB5"
SINGLE_C = GREY          # the single-variant Wald ratio


def load(p):
    with open(p) as fh:
        return list(csv.DictReader(fh, delimiter="\t"))


loo = load(IN_DIR / "leave_one_out.tsv")
rsid = {r["SNP"]: r["rsid"] for r in load(IN_DIR / "instrument_rsids.tsv")}

rows = {}
for r in loo:
    d = rows.setdefault(r["dropped"], {})
    d["ivw" if r["method"] == "IVW" else "wm"] = (
        exp(float(r["estimate"])), exp(float(r["ci_lower"])),
        exp(float(r["ci_upper"])), float(r["p"]))
    d["n"] = int(r["n_snps"])

dropped = sorted((k for k in rows if k != "none"),
                 key=lambda s: int(s.split("_")[1]))

# The single-variant analysis, kept apart from the leave-one-out block.
sv = load(IN_DIR / "single_variant.tsv")[0]
rows["single"] = {
    "wald": (exp(float(sv["estimate"])), exp(float(sv["ci_lower"])),
             exp(float(sv["ci_upper"])), float(sv["p"])),
    "label": rsid.get(sv.get("SNP", ""), sv.get("rsid", "rs12239046")),
}

# ("data", key) draws a result row; ("head", text) draws a group header and
# consumes a slot in the forest axis, so text and markers stay aligned.
layout = ([("data", "none"),
           ("head", "Leave-one-out")]
          + [("data", k) for k in dropped]
          + [("head", "Shared colocalising variant only"), ("data", "single")])
DATA_SLOTS = [i for i, (kind, _) in enumerate(layout) if kind == "data"]
KEYS = [k for kind, k in layout if kind == "data"]


def fmt_p(p):
    return f"{p:.2g}" if p >= 1e-3 else f"{p:.0e}".replace("e-0", "e-")


# VERTICAL LAYOUT IS IN MILLIMETRES, measured down from the top edge, as in
# figures/fig04d_il1rn_mr_forest.py.
N = len(layout)
ROW_MM = 7.70            # slot to slot
Y_HEADER = 3.85          # column headers
Y_RULE = 6.03            # rule under them
Y_FIRST_MM = 9.88        # first slot
DY_MM = 1.77             # half-separation of the two method lines
BELOW_MM = 21.0          # axis bottom -> figure bottom (ticks, title, legend)
LEGEND_MM = 4.16         # legend centre, up from the bottom edge

FIG_W_MM = 148.0
FIG_H_MM = Y_FIRST_MM + (N - 1) * ROW_MM + ROW_MM / 2 + BELOW_MM
fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))


def fy(mm_from_top):
    return 1.0 - mm_from_top / FIG_H_MM


def fh(mm_val):
    return mm_val / FIG_H_MM


X_LABEL, X_INDENT, X_EST, X_P = 0.015, 0.030, 0.560, 0.820
FOREST_L, FOREST_W = 0.200, 0.330

ROW_SPACING = fh(ROW_MM)
Y_FIRST = fy(Y_FIRST_MM)
DY_FIG = fh(DY_MM)
DY_DATA = DY_MM / ROW_MM

fig.text(X_LABEL, fy(Y_HEADER), "Instrument set", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_EST, fy(Y_HEADER), "Odds ratio (95% CI)", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_P, fy(Y_HEADER), "P", fontsize=FS_BODY, fontweight="bold", va="center")
fig.add_artist(plt.Line2D([X_LABEL, 0.985], [fy(Y_RULE)] * 2, color="black",
                          linewidth=0.6, transform=fig.transFigure))

for i, (kind, key) in enumerate(layout):
    yc = Y_FIRST - i * ROW_SPACING
    if kind == "head":
        fig.text(X_LABEL, yc, key, fontsize=FS_GROUP, fontweight="bold",
                 va="center", color=GREY)
        continue
    r = rows[key]
    is_full = key == "none"
    if "wald" in r:
        # one estimate, so it sits on the row centre rather than split in two
        fig.text(X_INDENT, yc, "only " + r["label"], fontsize=FS_BODY, va="center")
        e, lo, hi, pv = r["wald"]
        fig.text(X_EST, yc, f"{e:.2f} ({lo:.2f}, {hi:.2f})", fontsize=FS_BODY, va="center")
        fig.text(X_P, yc, fmt_p(pv), fontsize=FS_BODY, va="center")
        continue
    fig.text(X_LABEL if is_full else X_INDENT, yc,
             "All 8 instruments" if is_full else "w/o " + rsid.get(key, key),
             fontsize=FS_BODY, va="center",
             # "normal" would resolve to OpenSans-Regular; body weight is semibold
             fontweight="bold" if is_full else "semibold")
    for k, off in (("ivw", DY_FIG), ("wm", -DY_FIG)):
        e, lo, hi, p = r[k]
        fig.text(X_EST, yc + off, f"{e:.2f} ({lo:.2f}, {hi:.2f})",
                 fontsize=FS_BODY, va="center")
        fig.text(X_P, yc + off, fmt_p(p), fontsize=FS_BODY, va="center")

# A light rule above each group heading.
for _i, (_kind, _key) in enumerate(layout):
    if _kind != "head":
        continue
    fig.add_artist(plt.Line2D([X_LABEL, 0.985], [Y_FIRST - (_i - 0.5) * ROW_SPACING] * 2,
                              color="#CCCCCC", linewidth=0.5, transform=fig.transFigure))

# --- forest ----------------------------------------------------------------
rect = [FOREST_L, (Y_FIRST - (N - 1) * ROW_SPACING) - ROW_SPACING / 2,
        FOREST_W, N * ROW_SPACING]
ax = fig.add_axes(rect)
ax.set_xscale("log")
# Lower limit set to keep the Wald ratio's confidence interval on the axis.
ax.set_xlim(0.87, 1.70)
ax.set_ylim(-0.5, N - 0.5)
ax.invert_yaxis()
ax.axvline(1.0, color="black", linestyle="--", linewidth=0.5, dashes=(3, 2), zorder=1)

# Break the null line across the gap that holds the second heading.
_sv_head = [i for i, (kind, _) in enumerate(layout) if kind == "head"][-1]
ax.axhspan(_sv_head - 1 + DY_DATA + 0.22, _sv_head + 1 - 0.20,
           facecolor="white", edgecolor="none", zorder=1.5)

for slot, key in zip(DATA_SLOTS, KEYS):
    if "wald" in rows[key]:
        e, lo, hi, _ = rows[key]["wald"]
        ax.plot([lo, hi], [slot] * 2, color=SINGLE_C, linewidth=0.8,
                solid_capstyle="butt", zorder=2)
        ax.plot([e], [slot], marker="D", markersize=2.6, markerfacecolor="white",
                markeredgecolor=SINGLE_C, markeredgewidth=0.7, zorder=3)
        continue
    for k, off, col in (("ivw", -DY_DATA, IVW_C), ("wm", DY_DATA, WM_C)):
        e, lo, hi, _ = rows[key][k]
        ax.plot([lo, hi], [slot + off] * 2, color=col, linewidth=0.8,
                solid_capstyle="butt", zorder=2)
        ax.plot([e], [slot + off], marker="D", markersize=2.6, markerfacecolor="white",
                markeredgecolor=col, markeredgewidth=0.7, zorder=3)

ticks = [0.9, 1.0, 1.2, 1.4, 1.6]
ax.set_xticks(ticks)
ax.set_xticklabels(["%g" % t for t in ticks], fontsize=FS_TICK)
ax.tick_params(axis="x", length=2.8, width=0.6, pad=0.8)
ax.set_yticks([])
# Minor ticks come from figures/forest_ticks.py - one implementation for
# every forest axis in this directory; see that module for why
# matplotlib's own log minors are not usable here.
minor_ticks(ax, 0.05, length=1.7, width=0.55)
for s in ("top", "left", "right"):
    ax.spines[s].set_visible(False)
ax.spines["bottom"].set_linewidth(0.5)
ax.set_xlabel("Odds ratio for coronary artery disease\nper one unit lower NLRP3 activity score",
              fontsize=FS_XLAB, fontweight="bold", labelpad=1.8, linespacing=1.2)

# --- legend, centred on the figure ------------------------------------------
# Label widths are measured rather than guessed, so the group stays centred if a
# label is ever renamed.
LY, HALF, GAP, PAD = fy(FIG_H_MM - LEGEND_MM), 0.020, 0.045, 0.010
ITEMS = [(IVW_C, "D", "IVW"), (WM_C, "D", "Weighted Median"),
         (SINGLE_C, "D", "Wald ratio")]

fig.canvas.draw()
renderer = fig.canvas.get_renderer()
label_w = []
for _, _m, text in ITEMS:
    probe = fig.text(0, 0, text, fontsize=FS_SMALL)
    label_w.append(probe.get_window_extent(renderer=renderer).width / fig.bbox.width)
    probe.remove()

item_w = [2 * HALF + PAD + w for w in label_w]
x = 0.5 - (sum(item_w) + GAP * (len(ITEMS) - 1)) / 2
for (colour, marker, text), w in zip(ITEMS, item_w):
    cx = x + HALF
    fig.add_artist(plt.Line2D([cx - HALF, cx + HALF], [LY, LY], color=colour,
                              linewidth=0.8, transform=fig.transFigure))
    fig.add_artist(plt.Line2D([cx], [LY], marker=marker, markersize=2.6, color=colour,
                              markerfacecolor="white", markeredgewidth=0.7,
                              linestyle="none", transform=fig.transFigure))
    fig.text(cx + HALF + PAD, LY, text, fontsize=FS_SMALL, va="center")
    x += w + GAP

fig.savefig(OUT_DIR / "SupFig_leave_one_out.pdf", dpi=600, facecolor="white")
print(f"wrote {OUT_DIR / 'SupFig_leave_one_out.pdf'}  ({FIG_W_MM:.0f} x {FIG_H_MM:.0f} mm)")
