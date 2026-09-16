#!/usr/bin/env python3
# Shared tick helper for the forest panels, not a figure.
#
# minor_ticks() places unlabelled minor ticks on a log or linear axis so the
# spacing stays even after matplotlib's own locator has chosen the major ones.


import math

from matplotlib.ticker import FixedLocator, NullFormatter


def minor_ticks(ax, step, length, width, axis="x"):
    """Put minor ticks every `step` data units across the current view of `ax`.

    Call it AFTER set_xlim() and set_xticks(): the positions are read off the
    view, and any that coincide with a major are dropped, so a minor tick can
    never appear under a labelled one.

    Returns the tick positions, which is what the regeneration check reads.
    """
    if axis not in ("x", "y"):
        raise ValueError("axis must be 'x' or 'y'")
    if step <= 0:
        raise ValueError("step must be positive")

    lo, hi = sorted(ax.get_xlim() if axis == "x" else ax.get_ylim())
    majors = {round(float(t), 9) for t in
              (ax.get_xticks() if axis == "x" else ax.get_yticks())}

    first = math.ceil(lo / step - 1e-9)
    last = math.floor(hi / step + 1e-9)
    ticks = [round(n * step, 9) for n in range(first, last + 1)]
    ticks = [t for t in ticks if t not in majors]

    target = ax.xaxis if axis == "x" else ax.yaxis
    target.set_minor_locator(FixedLocator(ticks))
    # Without this, a log axis whose view spans less than a decade lets the log
    # formatter LABEL the minors.
    target.set_minor_formatter(NullFormatter())
    ax.tick_params(axis=axis, which="minor", length=length, width=width)
    return ticks
