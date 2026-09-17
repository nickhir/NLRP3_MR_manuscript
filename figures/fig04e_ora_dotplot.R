## Fig 4E - ORA dot plot
##
## GO biological-process terms enriched among the proteins lowered by NLRP3
## inhibition. Reads results/10_proteome_ora/.

suppressPackageStartupMessages({
    library(data.table)
    library(tidyverse)
    library(scales)
    library(here)
})

# FONT. One typeface across every panel, R and Python alike - see
# figures/fig02b_instrument_forest.R and fig02c_validation_forest.py.
FONT      <- "Open Sans"           # bold elements only -> OpenSans-Bold
FONT_BODY <- "Open Sans Semibold"  # body text, and the device default

# The family goes on the DEVICE, not just the theme: anything that falls
# through a theme or geom setting - the superscript in the legend labels, for
# one - otherwise comes out in the device's own.
cairo_pdf_font <- function(filename, ...) cairo_pdf(filename, ..., family = FONT_BODY)
update_geom_defaults("text", list(family = FONT))   # geoms ignore theme(text = )

analysis_dir <- here::here()
ora_file <- file.path(analysis_dir, "results", "10_proteome_ora",
                      "ukb_ppp_proteome_ora.tsv")
figures_dir <- file.path(analysis_dir, "figures_out")
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

ora_results <- fread(ora_file, data.table = FALSE) %>%
    filter(direction == "lowered_by_inhibition", collection == "GO:BP")

## ---- prepare ---------------------------------------------------------------
# GO term label wrap, in characters.
WRAP <- 24

clean_term <- function(term) {
    term %>%
        str_remove("^GOBP_") %>%
        str_replace_all("_", " ") %>%
        str_to_title() %>%
        str_wrap(width = WRAP)
}

ora_plot_data <- ora_results %>%
    mutate(
        term = clean_term(Description),
        gene_ratio = as.numeric(str_split(GeneRatio, "/", simplify = TRUE)[, 1]) /
            as.numeric(str_split(GeneRatio, "/", simplify = TRUE)[, 2]),
        p_adjust_plot = pmax(as.numeric(p.adjust), .Machine$double.xmin)
    ) %>%
    filter(!is.na(p_adjust_plot))

# Terms can tie on adjusted P, so the raw p-value breaks the tie
# deterministically rather than leaving it to row order.
ora_top_terms <- ora_plot_data %>%
    filter(p.adjust < 0.05) %>%
    arrange(p_adjust_plot, pvalue) %>%
    mutate(term_reordered = reorder(term, -p_adjust_plot))

if (nrow(ora_top_terms) == 0) {
    stop("no GO BP terms with adj. p < 0.05 in ", ora_file)
}
message(nrow(ora_top_terms), " terms at adj. P < 0.05")

## ---- plot ------------------------------------------------------------------
p_min <- min(ora_top_terms$p_adjust_plot, na.rm = TRUE)
p_max <- max(ora_top_terms$p_adjust_plot, na.rm = TRUE)
cols <- rev(viridisLite::viridis(256, option = "mako", begin = 0.2, end = 0.8))
legend_breaks <- signif(p_min + (p_max - p_min) * c(0.05, 0.95))

ora_plot <- ggplot(
    ora_top_terms,
    aes(x = gene_ratio, y = term_reordered, color = p_adjust_plot)
) +
    geom_segment(
        aes(x = 0, xend = gene_ratio, y = term_reordered, yend = term_reordered),
        linewidth = 0.45, alpha = 0.8
    ) +
    geom_point(alpha = 0.95, size = 2.6, stroke = 0.35) +
    scale_y_discrete(labels = function(x) stringr::str_wrap(x, width = WRAP)) +
    scale_x_continuous(
        name = "Gene ratio",
        breaks = c(0.1, 0.3, 0.5),
        labels = percent_format(accuracy = 1),
        expand = expansion(mult = c(0, 0.08))
    ) +
    scale_color_gradientn(
        colors = cols,
        limits = c(p_min, p_max),
        oob = squish,
        breaks = legend_breaks,
        labels = scales::scientific(legend_breaks, digits = 1),
        name = "Adj. P-value",
        guide = guide_colorbar(
            # raster = FALSE draws the bar as filled rectangles instead of an
            # image.
            raster = FALSE,
            direction = "horizontal",
            title.position = "top",
            title.hjust = 0.5,
            barwidth = unit(15, "mm"),
            barheight = unit(2.5, "mm"),
            ticks = FALSE,
            label.position = "bottom",
            draw.ulim = FALSE,
            draw.llim = FALSE
        )
    ) +
    theme_classic(base_size = 8, base_family = FONT_BODY) +
    theme(
        panel.background = element_rect(fill = "white", colour = NA),
        plot.background = element_rect(fill = "white", colour = NA),
        axis.title.x = element_text(size = 7.8, family = FONT, face = "bold",
                                    margin = margin(t = 1, b = -1, unit = "mm")),
        axis.text.x = element_text(size = 8, colour = "black", family = FONT_BODY),
        axis.text.y = element_text(size = 8, colour = "black", family = FONT_BODY),
        axis.ticks.y = element_blank(),
        axis.title.y = element_blank(),
        legend.position = c(1.0, -0.01),
        legend.justification = c(1, 0),
        legend.background = element_rect(fill = NA, colour = NA),
        legend.title = element_text(size = 7.6, family = FONT, face = "bold"),
        legend.text = element_text(size = 7.6, family = FONT_BODY),
        legend.key.width = unit(2.5, "mm"),
        legend.key.height = unit(2.5, "mm"),
        plot.margin = margin(3, 7, 3, 3, "mm")
    )

pdf_out <- file.path(figures_dir, "Fig4E_ora_dotplot.pdf")
# Wider than the 80 mm this carried at 7.5 pt: the wrapped GO term labels grow
# with the body size, and the panel has to grow with them. The height is 4F's,
# so the two panels in the bottom row of Figure 4 sit level.
ggsave(pdf_out, ora_plot, width = 104, height = 80, units = "mm",
       device = cairo_pdf_font)

print(as.data.frame(ora_top_terms %>%
    transmute(term = gsub("\n", " ", term), GeneRatio,
              gene_ratio = round(gene_ratio, 3),
              p.adjust = signif(p.adjust, 3))), row.names = FALSE)
message("wrote ", pdf_out)
