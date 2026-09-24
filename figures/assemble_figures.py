#!/usr/bin/env python3
# Assembly only - places finished panel PDFs on a page with xelatex and adds
# the panel letters. Reads figures_out/ and figures/assets/, writes
# figures_out/<Figure>_combined.pdf.

import re
import shutil
import subprocess
import tempfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
OUT_DIR = SCRIPT_DIR.parent / "figures_out"

# Hand-drawn panels live in figures/assets/: figures_out/ holds only what a
# script can rebuild.
ASSET_DIR = SCRIPT_DIR / "assets"
ASSETS = {"Fig3D_mediation_diagram"}

A4_W = 210.0  # mm

# Page geometry, in mm; STYLE overrides the defaults per figure.
STYLE_DEFAULT = dict(
    margin=4.0,        # page edge to content
    gap_x=2.0,         # between panels in a row
    gap_y=5.0,         # between rows
    gap_stack=None,    # between panels stacked in one cell (None = gap_y)
    columns=False,     # give every row the same column widths, so cells line up
    cell_halign="left",  # a panel narrower than its column sits at its left edge
    letter=6.0,        # band above each row holding the panel letter
    letter_drop=4.2,   # letter baseline below the top of its band
    letter_pt=12,
    halign="left",     # rows start at the margin
    valign="top",      # panels hang from the row's top line
    fit="scale",       # shrink everything uniformly to fit the page width
)

STYLE = {
    "Fig3": dict(gap_stack=2.0, columns=True, cell_halign="centre"),
    "Fig4": dict(margin=1.0, gap_x=4.0, gap_y=4.0, letter=3.2, letter_drop=2.9,
                 letter_pt=11, halign="centre", valign="middle", fit="crop"),
}

# Each figure is a list of rows; each row a list of cells side by side; a cell
# a panel or a list of panels stacked. A panel may carry a size multiplier.
FIGURES = {
    "Fig2": [
        [("A", "Fig2A_NLRP3_locuszoom"), ("C", "Fig2C_validation_forest")],
        [("B", "Fig2B_NLRP3_instrument_forest")],
    ],
    "Fig3": [
        [[("A", "Fig3A_cad_forest"), ("B", "Fig3B_imaging_forest")],
         ("C", "Fig3C_cardiometabolic_forest")],
        [("D", "Fig3D_mediation_diagram", 1.19),
         ("E", "Fig3E_mediation_waterfall")],
    ],
    "Fig4": [
        [("A", "Fig4A_plof_violins"), ("B", "Fig4B_gof_carriers")],
        [("C", "Fig4C_il1rn_instrument_forest"), ("D", "Fig4D_il1rn_mr_forest")],
        [("E", "Fig4E_ora_dotplot"), ("F", "Fig4F_sensitivity")],
    ],
}


def panel_pdf(stem):
    return (ASSET_DIR if stem in ASSETS else OUT_DIR) / f"{stem}.pdf"


def page_size_mm(stem):
    """A panel's page size, read from the PDF."""
    # stdout=PIPE, not capture_output=: /usr/bin/python3 is 3.6
    info = subprocess.run(["pdfinfo", str(panel_pdf(stem))], stdout=subprocess.PIPE,
                          check=True, universal_newlines=True).stdout
    w, h = re.search(r"Page size:\s+([\d.]+) x ([\d.]+) pts", info).groups()
    return float(w) / 72 * 25.4, float(h) / 72 * 25.4


def build(name, rows):
    st = dict(STYLE_DEFAULT, **STYLE.get(name, {}))
    margin, gap_x, gap_y, letter = st["margin"], st["gap_x"], st["gap_y"], st["letter"]
    gy = gap_y if st["gap_stack"] is None else st["gap_stack"]

    # every cell as a stack of (letter, stem, multiplier)
    rows = [[[(t + (1.0,))[:3] for t in (cell if isinstance(cell, list) else [cell])]
             for cell in row] for row in rows]
    size = {}
    for row in rows:
        for cell in row:
            for _, stem, mult in cell:
                w, h = page_size_mm(stem)
                size[stem] = (w * mult, h * mult)

    # a cell is as wide as its widest panel and as tall as its panels plus
    # the letter band each carries
    def cell_w(cell):
        return max(size[s][0] for _, s, _ in cell)

    def cell_h(cell):
        return sum(letter + size[s][1] for _, s, _ in cell) + gy * (len(cell) - 1)

    if st["columns"]:
        col = [max(cell_w(r[j]) for r in rows) for j in range(len(rows[0]))]
        widths = [list(col) for _ in rows]
    else:
        widths = [[cell_w(c) for c in row] for row in rows]
    row_w = [sum(w) + gap_x * (len(w) - 1) for w in widths]

    if st["fit"] == "scale":
        # one scale, shrink-only, set by the widest row
        widest = max(row_w)
        scale = min(1.0, (A4_W - 2 * margin) / widest)
        page_w = widest * scale + 2 * margin
    else:
        # "crop": panels at true size on an A4-wide page, any overflow split
        # between the two edges (it falls on whitespace)
        scale, page_w = 1.0, A4_W

    row_h = [max(cell_h(c) for c in row) * scale for row in rows]
    page_h = 2 * margin + sum(row_h) + gap_y * (len(rows) - 1)

    body, y_row = [], page_h - margin
    for row, rw, rh, cols in zip(rows, row_w, row_h, widths):
        x = margin if st["halign"] == "left" else (page_w - rw * scale) / 2
        for cell, cw in zip(row, cols):
            ch = cell_h(cell) * scale
            y = y_row if st["valign"] == "top" else y_row - (rh - ch) / 2
            for lt, stem, _m in cell:
                w, h = (v * scale for v in size[stem])
                indent = (cw * scale - w) / 2 if st["cell_halign"] == "centre" else 0.0
                # the letter follows its column's left edge but never leaves the page
                body.append(f"\\put({max(x, margin):.3f},{y - st['letter_drop']:.3f})"
                            f"{{\\fontsize{{{st['letter_pt']}}}{{{st['letter_pt']}}}"
                            f"\\selectfont\\bfseries {lt}}}")
                body.append(f"\\put({x + indent:.3f},{y - letter - h:.3f})"
                            f"{{\\includegraphics[width={w:.3f}mm]"
                            f"{{{panel_pdf(stem)}}}}}")
                y -= letter + h + gy
            x += cw * scale + gap_x
        y_row -= rh + gap_y

    tex = (f"\\documentclass{{article}}\n"
           f"\\usepackage[paperwidth={page_w:.3f}mm,"
           f"paperheight={page_h:.3f}mm,margin=0mm]{{geometry}}\n"
           f"\\usepackage{{graphicx}}\n\\usepackage{{fontspec}}\n"
           f"\\setmainfont{{Open Sans}}[BoldFont={{Open Sans Bold}}]\n"
           f"\\pagestyle{{empty}}\n\\setlength{{\\parindent}}{{0pt}}\n"
           f"\\begin{{document}}\n\\setlength{{\\unitlength}}{{1mm}}\n"
           f"\\begin{{picture}}({page_w:.3f},{page_h:.3f})\n"
           + "\n".join(body)
           + f"\n\\end{{picture}}\n\\end{{document}}\n")

    # compiled somewhere disposable, since xelatex scatters .aux and .log files
    with tempfile.TemporaryDirectory() as tmp:
        (Path(tmp) / f"{name}.tex").write_text(tex)
        subprocess.run(["xelatex", "-interaction=nonstopmode", f"{name}.tex"], cwd=tmp,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        shutil.copy(Path(tmp) / f"{name}.pdf", OUT_DIR / f"{name}_combined.pdf")


for name, rows in FIGURES.items():
    build(name, rows)
