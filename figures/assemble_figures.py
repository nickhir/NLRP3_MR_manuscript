#!/usr/bin/env python3
# Assembly only - places finished panel PDFs on a page with xelatex and adds
# the panel letters. Reads figures_out/ and figures/assets/, writes
# figures_out/<Figure>_combined.pdf.

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
OUT_DIR = SCRIPT_DIR.parent / "figures_out"

# Hand-drawn panels live in figures/assets/, NOT in figures_out/. figures_out
# is generated output - anything there can be deleted and rebuilt from a
# script, and a drawn illustration cannot.
ASSET_DIR = SCRIPT_DIR / "assets"

# Page geometry, in mm. These are the defaults; STYLE overrides them per figure.
A4_W = 210.0
PT = 25.4 / 72

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

# Each figure is a list of ROWS; each row is a list of CELLS side by side.
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

# 4B (gain-of-function carriers) needs individual-level UK Biobank exome data,
# so no script here produces it. It is supplied as a finished PDF and must be
# placed in figures_out/ beside the generated panels.
SUPPLIED = {"Fig4B_gof_carriers"}

# Drawn illustrations, kept in figures/assets/. No script can make these.
ASSETS = {"Fig3D_mediation_diagram"}

# Which script writes which panel, so a missing file says what to run.
PRODUCED_BY = {
    "Fig2A_NLRP3_locuszoom": "figures/fig02a_locuszoom.R",
    "Fig2B_NLRP3_instrument_forest": "figures/fig02b_instrument_forest.R",
    "Fig2C_validation_forest": "figures/fig02c_validation_forest.py",
    "Fig3A_cad_forest": "figures/fig03a_cad_forest.py",
    "Fig3B_imaging_forest": "figures/fig03b_imaging_forest.py",
    "Fig3C_cardiometabolic_forest": "figures/fig03c_cardiometabolic_forest.py",
    "Fig3E_mediation_waterfall": "figures/fig03e_mediation_waterfall.py",
    "Fig4A_plof_violins": "figures/fig04a_plof_violins.py",
    "Fig4C_il1rn_instrument_forest": "figures/fig04c_il1rn_instrument_forest.R",
    "Fig4D_il1rn_mr_forest": "figures/fig04d_il1rn_mr_forest.py",
    "Fig4E_ora_dotplot": "figures/fig04e_ora_dotplot.R",
    "Fig4F_sensitivity": "figures/fig04f_sensitivity.py",
}


def panel_pdf(stem):
    """Where a panel's PDF lives: generated output, or a drawn asset."""
    pdf = ASSET_DIR / f"{stem}.pdf" if stem in ASSETS else OUT_DIR / f"{stem}.pdf"
    return pdf


def page_size_mm(stem):
    """A panel's true page size, read from the PDF rather than assumed."""
    pdf = panel_pdf(stem)
    # stdout=PIPE rather than capture_output=: the only python on this machine
    # carrying matplotlib is /usr/bin/python3 (3.6), and capture_output= is
    # 3.7+.
    info = subprocess.run(["pdfinfo", str(pdf)], stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, check=True,
                          universal_newlines=True).stdout
    m = re.search(r"Page size:\s+([\d.]+) x ([\d.]+) pts", info)
    w, h = m.groups()
    return float(w) / 72 * 25.4, float(h) / 72 * 25.4


def ink_box_mm(stem):
    """The panel's INK bounding box, in mm from its page's bottom-left."""
    out = subprocess.run(["gs", "-q", "-dNOPAUSE", "-dBATCH", "-sDEVICE=bbox",
                          str(panel_pdf(stem))], stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT,
                         universal_newlines=True).stdout
    m = re.search(r"%%HiResBoundingBox:\s+([\d.-]+) ([\d.-]+) ([\d.-]+) ([\d.-]+)", out)
    return [float(v) * PT for v in m.groups()]


def build(name, rows):
    st = dict(STYLE_DEFAULT, **STYLE.get(name, {}))
    margin, gap_x, gap_y = st["margin"], st["gap_x"], st["gap_y"]
    letter = st["letter"]
    gy = gap_y if st["gap_stack"] is None else st["gap_stack"]

    # A cell is a vertical stack; a bare (letter, stem) pair is a stack of one.
    # A panel may carry a third element, a SIZE MULTIPLIER.
    rows = [[[(t + (1.0,))[:3] for t in (cell if isinstance(cell, list) else [cell])]
             for cell in row] for row in rows]

    size = {stem: page_size_mm(stem)
            for row in rows for cell in row for _, stem, _ in cell}
    mult = {stem: m for row in rows for cell in row for _, stem, m in cell}
    print(f"{name}:")
    for stem, (w, h) in size.items():
        extra = f"  x{mult[stem]:.2f}" if mult[stem] != 1.0 else ""
        print(f"    {stem:34s} {w:6.1f} x {h:6.1f} mm{extra}")
    size = {k: (w * mult[k], h * mult[k]) for k, (w, h) in size.items()}

    # A cell is as wide as its widest panel and as tall as its panels plus the
    # letter band each one carries; a row is as wide as its cells plus the gaps.
    def cell_w(cell):
        return max(size[s][0] for _, s, _ in cell)

    def cell_h(cell):
        return sum(letter + size[s][1] for _, s, _ in cell) + gy * (len(cell) - 1)

    # COLUMNS. Without this each row is packed independently, so the second
    # row's cells start wherever the first one happens to end and nothing lines
    # up down the page.
    if st["columns"]:
        ncells = {len(r) for r in rows}
        col = [max(cell_w(r[j]) for r in rows) for j in range(len(rows[0]))]
        widths = [list(col) for _ in rows]
    else:
        widths = [[cell_w(c) for c in row] for row in rows]

    row_w = [sum(w) + gap_x * (len(w) - 1) for w in widths]
    widest = max(row_w)

    if st["fit"] == "scale":
        # Rule 2: one scale, shrink-only, set by the widest row.
        scale = min(1.0, (A4_W - 2 * margin) / widest)
        page_w = widest * scale + 2 * margin
    else:
        # fit="crop": panels at true size on an A4-wide page, with any overflow
        # split between the two edges - and it may only eat whitespace.
        scale, page_w = 1.0, A4_W
        for row, rw in zip(rows, row_w):
            over = (rw - page_w) / 2
            if over <= 0:
                continue
            left, right = row[0][0][1], row[-1][-1][1]
            for stem, free in ((left, ink_box_mm(left)[0]),
                               (right, size[right][0] - ink_box_mm(right)[2])):
                print(f"    {stem:34s} {free:5.2f} mm of whitespace at the "
                      f"cropped edge ({over:.2f} mm is cut)")

    row_h = [max(cell_h(c) for c in row) * scale for row in rows]
    page_h = 2 * margin + sum(row_h) + gap_y * (len(rows) - 1)

    print(f"    -> page {page_w:.1f} x {page_h:.1f} mm, scale {scale:.4f}")
    # THE READABILITY CHECK. Every panel is authored at the Figure 2C type scale
    # (8 pt body), so the scale factor IS the final point size: shrink to 0.74
    # and 8 pt prints at 5.9 pt. Report it rather than let it pass unnoticed.
    if scale < 0.995:
        print(f"    NOTE: 8.0 pt body text will print at {8.0 * scale:.1f} pt "
              f"({(1 - scale) * 100:.0f}% smaller than Figure 2C).")
    for row, rh in zip(rows, row_h):
        heights = [cell_h(c) * scale for c in row]
        if len(row) > 1 and max(heights) - min(heights) > 2:
            names = ", ".join(s for c in row for _, s, _ in c)
            print(f"    NOTE: cells differ in height by "
                  f"{max(heights) - min(heights):.1f} mm ({names}); the shorter "
                  f"one will sit above white space.")

    body, y_row = [], page_h - margin
    for row, rw, rh, cols in zip(rows, row_w, row_h, widths):
        x = margin if st["halign"] == "left" else (page_w - rw * scale) / 2
        for cell, cw in zip(row, cols):
            ch = cell_h(cell) * scale
            # A short cell beside a tall one is centred when the style asks for
            # it, so it does not sit on top of its own slack.
            y = y_row if st["valign"] == "top" else y_row - (rh - ch) / 2
            for lt, stem, _m in cell:
                w, h = (v * scale for v in size[stem])
                # A panel narrower than its column is centred in it when the
                # style asks - a drawn illustration stranded at the left edge
                # of a column sized by a wide forest reads as a mistake.
                indent = (cw * scale - w) / 2 if st["cell_halign"] == "centre" else 0.0
                # The letter follows its column's left edge but never leaves the
                # page: a cropped row starts left of the margin and would take
                # its letter with it, and a letter is ink where an edge is not.
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

    # Compile somewhere disposable; xelatex scatters .aux and .log beside the
    # source and figures_out/ is for figures.
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        (tmp / f"{name}.tex").write_text(tex)
        r = subprocess.run(["xelatex", "-interaction=nonstopmode", f"{name}.tex"],
                           cwd=str(tmp), stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, universal_newlines=True)
        built = tmp / f"{name}.pdf"
        out_pdf = OUT_DIR / f"{name}_combined.pdf"
        shutil.copy(built, out_pdf)

    print(f"    wrote {out_pdf}  ({out_pdf.stat().st_size / 1e3:.0f} KB)")


def main():
    wanted = sys.argv[1:] or list(FIGURES)
    unknown = [w for w in wanted if w not in FIGURES]
    for name in wanted:
        build(name, FIGURES[name])


if __name__ == "__main__":
    main()
