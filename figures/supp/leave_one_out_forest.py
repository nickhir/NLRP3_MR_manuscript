#!/usr/bin/env python3
# Sup Fig - leave-one-out forest.
#
# The NLRP3 -> CAD estimate with each instrument dropped in turn, and on the
# single colocalising variant. Reads results/11_mr_sensitivity/, writes
# figures_out/SupFig_leave_one_out.pdf.

import csv
import sys
from math import exp
from pathlib import Path

# style.py is in figures/, one level up
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from style import apply_style, minor_ticks, centred_legend, RESULTS, OUT_DIR, IVW_C, WM_C, GREY
apply_style()
import matplotlib.pyplot as plt

FS_BODY, FS_SMALL, FS_TICK, FS_XLAB, FS_GROUP = 8.0, 7.6, 8.0, 7.8, 8.0
IN_DIR = RESULTS / "11_mr_sensitivity"


def load(p):
    with open(p) as fh:
        return list(csv.DictReader(fh, delimiter="\t"))


rsid = {r["SNP"]: r["rsid"] for r in load(IN_DIR / "instrument_rsids.tsv")}

rows = {}
for r in load(IN_DIR / "leave_one_out.tsv"):
    rows.setdefault(r["dropped"], {})["ivw" if r["method"] == "IVW" else "wm"] = (
        exp(float(r["estimate"])), exp(float(r["ci_lower"])),
        exp(float(r["ci_upper"])), float(r["p"]))
dropped = sorted((k for k in rows if k != "none"), key=lambda s: int(s.split("_")[1]))

sv = load(IN_DIR / "single_variant.tsv")[0]
rows["single"] = {"wald": (exp(float(sv["estimate"])), exp(float(sv["ci_lower"])),
                           exp(float(sv["ci_upper"])), float(sv["p"]))}

# ("data", key) draws a result row; ("head", text) a group header that takes a
# slot of the forest axis, so text and markers stay aligned.
layout = ([("data", "none"), ("head", "Leave-one-out")]
          + [("data", k) for k in dropped]
          + [("head", "Shared colocalising variant only"), ("data", "single")])


def fmt_p(p):
    return f"{p:.2g}" if p >= 1e-3 else f"{p:.0e}".replace("e-0", "e-")


# The vertical layout is in millimetres down from the top edge.
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


X_LABEL, X_INDENT, X_EST, X_P = 0.015, 0.030, 0.560, 0.820
FOREST_L, FOREST_W = 0.200, 0.330

ROW_SPACING = ROW_MM / FIG_H_MM
Y_FIRST = fy(Y_FIRST_MM)
DY_FIG = DY_MM / FIG_H_MM
DY_DATA = DY_MM / ROW_MM

fig.text(X_LABEL, fy(Y_HEADER), "Instrument set", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_EST, fy(Y_HEADER), "Odds ratio (95% CI)", fontsize=FS_BODY, fontweight="bold", va="center")
fig.text(X_P, fy(Y_HEADER), "P", fontsize=FS_BODY, fontweight="bold", va="center")
fig.add_artist(plt.Line2D([X_LABEL, 0.985], [fy(Y_RULE)] * 2, color="black",
                          linewidth=0.6, transform=fig.transFigure))

for i, (kind, key) in enumerate(layout):
    yc = Y_FIRST - i * ROW_SPACING
    if kind == "head":
        fig.text(X_LABEL, yc, key, fontsize=FS_GROUP, fontweight="bold", va="center", color=GREY)
        continue
    r = rows[key]
    if key == "single":
        # one estimate, so it sits on the row centre
        fig.text(X_INDENT, yc, "only rs12239046", fontsize=FS_BODY, va="center")
        e, lo, hi, pv = r["wald"]
        fig.text(X_EST, yc, f"{e:.2f} ({lo:.2f}, {hi:.2f})", fontsize=FS_BODY, va="center")
        fig.text(X_P, yc, fmt_p(pv), fontsize=FS_BODY, va="center")
        continue
    is_full = key == "none"
    # "normal" would resolve to OpenSans-Regular; the body weight is semibold
    fig.text(X_LABEL if is_full else X_INDENT, yc,
             "All 8 instruments" if is_full else "w/o " + rsid[key],
             fontsize=FS_BODY, va="center", fontweight="bold" if is_full else "semibold")
    for k, off in (("ivw", DY_FIG), ("wm", -DY_FIG)):
        e, lo, hi, p = r[k]
        fig.text(X_EST, yc + off, f"{e:.2f} ({lo:.2f}, {hi:.2f})", fontsize=FS_BODY, va="center")
        fig.text(X_P, yc + off, fmt_p(p), fontsize=FS_BODY, va="center")

# a light rule above each group heading
for i, (kind, _key) in enumerate(layout):
    if kind == "head":
        fig.add_artist(plt.Line2D([X_LABEL, 0.985], [Y_FIRST - (i - 0.5) * ROW_SPACING] * 2,
                                  color="#CCCCCC", linewidth=0.5, transform=fig.transFigure))

# --- forest ------------------------------------------------------------------
ax = fig.add_axes([FOREST_L, (Y_FIRST - (N - 1) * ROW_SPACING) - ROW_SPACING / 2,
                   FOREST_W, N * ROW_SPACING])
ax.set_xscale("log")
ax.set_xlim(0.87, 1.70)            # keeps the Wald ratio's interval on the axis
ax.set_ylim(-0.5, N - 0.5)
ax.invert_yaxis()
ax.axvline(1.0, color="black", linestyle="--", linewidth=0.5, dashes=(3, 2), zorder=1)

# break the null line across the gap that holds the second heading
sv_head = [i for i, (kind, _) in enumerate(layout) if kind == "head"][-1]
ax.axhspan(sv_head - 1 + DY_DATA + 0.22, sv_head + 1 - 0.20,
           facecolor="white", edgecolor="none", zorder=1.5)

for slot, (kind, key) in enumerate(layout):
    if kind != "data":
        continue
    if key == "single":
        e, lo, hi, _ = rows[key]["wald"]
        ax.plot([lo, hi], [slot] * 2, color=GREY, linewidth=0.8, solid_capstyle="butt", zorder=2)
        ax.plot([e], [slot], marker="D", markersize=2.6, markerfacecolor="white",
                markeredgecolor=GREY, markeredgewidth=0.7, zorder=3)
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
minor_ticks(ax, 0.05, length=1.7, width=0.55)
for s in ("top", "left", "right"):
    ax.spines[s].set_visible(False)
ax.spines["bottom"].set_linewidth(0.5)
ax.set_xlabel("Odds ratio for coronary artery disease\nper one unit lower NLRP3 activity score",
              fontsize=FS_XLAB, fontweight="bold", labelpad=1.8, linespacing=1.2)

centred_legend(fig, [(IVW_C, "IVW"), (WM_C, "Weighted Median"), (GREY, "Wald ratio")],
               fy(FIG_H_MM - LEGEND_MM), 0.5, gap=0.045,
               half=0.020, pad=0.010, lw=0.8, ms=2.6, mew=0.7, fontsize=FS_SMALL)

fig.savefig(OUT_DIR / "SupFig_leave_one_out.pdf", dpi=600, facecolor="white")
