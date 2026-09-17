"""Shared matplotlib setup. One typeface across every panel, R and Python alike."""
import os

os.environ.setdefault("MPLCONFIGDIR", "/tmp/mplconfig")
os.makedirs(os.environ["MPLCONFIGDIR"], exist_ok=True)

import matplotlib
matplotlib.use("Agg")
from matplotlib import rcParams, font_manager


def apply_style():
    rcParams["pdf.fonttype"] = 42
    rcParams["ps.fonttype"] = 42
    rcParams["font.family"] = "Open Sans"
    rcParams["font.weight"] = "semibold"
    # matplotlib registers OpenSans-Bold.ttf AND OpenSans-ExtraBold.ttf under the
    # same family at the same weight, so which one fontweight="bold" gets is
    # decided by the order of fontManager.ttflist.
    font_manager.fontManager.ttflist = [
        f for f in font_manager.fontManager.ttflist
        if "OpenSans-ExtraBold" not in f.fname
    ]
