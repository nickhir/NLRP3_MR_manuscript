#!/usr/bin/env python3
# Fig 2C - validation forest.
#
# Forest panel of the inflammatory readouts and the effector cytokines.
# Reads results/04_mr_biomarkers/, writes figures_out/Fig2C_validation_forest.pdf.

import csv

from style import apply_style, minor_ticks, legend_entry, RESULTS, OUT_DIR, IVW_C, WM_C, GREY
apply_style()
import matplotlib.pyplot as plt

FS_BODY, FS_SMALL, FS_TICK, FS_GROUP, FS_XLAB = 8.0, 7.6, 8.0, 8.0, 7.8

# outcome in the results file -> how it appears; the interleukins take the
# manuscript's hyphenated forms
DISPLAY = {"CRP concentration": "CRP",
           "GlycA concentration": "GlycA",
           "Neutrophil count": "Neutrophil count",
           "IL1B": "IL-1β",
           "IL18": "IL-18",
           "IL6": "IL-6"}

# Group headings, one tuple of lines each, and their outcomes.
HEADINGS = [(("Systemic inflammation proxies",),
             ["CRP concentration", "GlycA concentration", "Neutrophil count"]),
            (("NLRP3 inflammasome-associated", "cytokines"), ["IL1B", "IL18", "IL6"])]

ROWS = {}
with open(RESULTS / "04_mr_biomarkers" / "mr_biomarkers.tsv") as fh:
    for r in csv.DictReader(fh, delimiter="\t"):
        d = ROWS.setdefault(r["outcome"], {})
        d["ivw" if r["method"] == "IVW" else "wm"] = (
            float(r["estimate"]), float(r["ci_lower"]), float(r["ci_upper"]), float(r["p"]))
        d["n"] = f"n = {int(float(r['n_total'])):,}"


def fmt_p(p):
    # two significant figures, as the manuscript prints them
    return f"{p:.2g}" if p >= 1e-3 else f"{p:.1e}".replace("e-0", "e-")


FIG_W_MM, FIG_H_MM = 88.0, 102.0
fig = plt.figure(figsize=(FIG_W_MM / 25.4, FIG_H_MM / 25.4))

X_LABEL, X_EST, X_P = 0.015, 0.523, 0.832
FOREST_L, FOREST_W = 0.303, 0.200
X_INDENT = 0.014        # outcome names sit inside their group heading

ROW_SPACING = 0.104     # figure fraction between outcome rows
LINE_H = 0.028          # one line of heading text
HEAD_TO_ROW = 0.066     # bottom of a heading block -> centre of its first row
BLOCK_GAP = 0.098       # last row of a block -> top of the next heading
DY = 0.0255             # half-separation of the two method lines

# --- lay the rows out on one grid -------------------------------------------
# Group headings take a slot of their own, so the single forest axis spans
# everything without the two blocks drifting apart.
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
        # a white box, since a heading longer than the outcome column runs on
        # over the forest's dashed null line
        fig.text(X_LABEL, ycentre, "\n".join(key), fontsize=FS_GROUP,
                 fontweight="bold", va="center", linespacing=1.15,
                 bbox=dict(facecolor="white", edgecolor="none", pad=0.8))
        continue
    r = ROWS[key]
    fig.text(X_LABEL + X_INDENT, ycentre + 0.018, DISPLAY[key], fontsize=FS_BODY, va="center")
    fig.text(X_LABEL + X_INDENT, ycentre - 0.020, r["n"], fontsize=FS_SMALL,
             va="center", color=GREY)
    for slot, off in (("ivw", DY), ("wm", -DY)):
        e, lo, hi, p = r[slot]
        fig.text(X_EST, ycentre + off, f"{e:.2f} ({lo:.2f}, {hi:.2f})", fontsize=FS_BODY, va="center")
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
minor_ticks(ax, 0.1, length=1.7, width=0.55)
for s in ("top", "left", "right"):
    ax.spines[s].set_visible(False)
ax.spines["bottom"].set_linewidth(0.5)
ax.set_xlabel("β per one unit lower\nNLRP3 activity score",
              fontsize=FS_XLAB, fontweight="bold", labelpad=1.6, linespacing=1.15)

# --- legend, below the plot --------------------------------------------------
LEGEND = dict(half=0.022, pad=0.012, lw=0.8, ms=2.5, mew=0.7, fontsize=FS_SMALL)
legend_entry(fig, 0.330, 0.020, IVW_C, "IVW", **LEGEND)
legend_entry(fig, 0.530, 0.020, WM_C, "Weighted Median", **LEGEND)

fig.savefig(OUT_DIR / "Fig2C_validation_forest.pdf", dpi=600, facecolor="white")
