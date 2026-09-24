## Shared by the R figure scripts. One typeface across every panel, R and
## Python alike (figures/style.py).

FONT <- "Open Sans" # bold elements only -> OpenSans-Bold
FONT_BODY <- "Open Sans Semibold" # body text, and the device default

# The family goes on the device too, for anything no theme or geom sets
# (plotmath titles and labels).
cairo_pdf_font <- function(filename, ...) cairo_pdf(filename, ..., family = FONT_BODY)

figures_dir <- here::here("figures_out")
dir.create(figures_dir, showWarnings = FALSE)

# LD colours of the locuszoom panels, in the order gg_scatter bins into: no r2,
# the five r2 bands, then the index variant.
LD_SCHEME <- c(
    "grey62", # NA - not in the LD panel
    "#1B36C4", # 0.0 - 0.2
    "#00BEEF", # 0.2 - 0.4
    "#00B81F", # 0.4 - 0.6
    "#FF8A00", # 0.6 - 0.8
    "#EB0000", # 0.8 - 1.0
    "#9A00C8" # index SNP
)
