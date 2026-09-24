## Fig 4E - ORA dot plot
##
## GO biological-process terms enriched among the proteins lowered by NLRP3
## inhibition, at adjusted P < 0.05. Reads results/10_proteome_ora/.

suppressPackageStartupMessages({
    library(data.table)
    library(tidyverse)
    library(scales)
})
source(here::here("figures", "style.R"))

WRAP <- 24 # GO term label wrap, in characters

terms <- fread(here::here("results", "10_proteome_ora", "ukb_ppp_proteome_ora.tsv"),
               data.table = FALSE) %>%
    filter(direction == "lowered_by_inhibition", collection == "GO:BP", p.adjust < 0.05) %>%
    mutate(
        term = Description %>%
            str_remove("^GOBP_") %>%
            str_replace_all("_", " ") %>%
            str_to_title() %>%
            str_wrap(width = WRAP),
        gene_ratio = as.numeric(str_split(GeneRatio, "/", simplify = TRUE)[, 1]) /
            as.numeric(str_split(GeneRatio, "/", simplify = TRUE)[, 2]),
        p_adjust_plot = pmax(as.numeric(p.adjust), .Machine$double.xmin)
    ) %>%
    # ties on adjusted P are broken on the raw p-value
    arrange(p_adjust_plot, pvalue) %>%
    mutate(term_reordered = reorder(term, -p_adjust_plot))

p_min <- min(terms$p_adjust_plot)
p_max <- max(terms$p_adjust_plot)
legend_breaks <- signif(p_min + (p_max - p_min) * c(0.05, 0.95))

ora_plot <- ggplot(terms, aes(x = gene_ratio, y = term_reordered, color = p_adjust_plot)) +
    geom_segment(aes(x = 0, xend = gene_ratio, y = term_reordered, yend = term_reordered),
                 linewidth = 0.45, alpha = 0.8) +
    geom_point(alpha = 0.95, size = 2.6, stroke = 0.35) +
    scale_y_discrete(labels = function(x) str_wrap(x, width = WRAP)) +
    scale_x_continuous(name = "Gene ratio", breaks = c(0.1, 0.3, 0.5),
                       labels = percent_format(accuracy = 1),
                       expand = expansion(mult = c(0, 0.08))) +
    scale_color_gradientn(
        colors = rev(viridisLite::viridis(256, option = "mako", begin = 0.2, end = 0.8)),
        limits = c(p_min, p_max),
        oob = squish,
        breaks = legend_breaks,
        labels = scientific(legend_breaks, digits = 1),
        name = "Adj. P-value",
        # raster = FALSE draws the bar as rectangles rather than an image
        guide = guide_colorbar(raster = FALSE, direction = "horizontal",
                               title.position = "top", title.hjust = 0.5,
                               barwidth = unit(15, "mm"), barheight = unit(2.5, "mm"),
                               ticks = FALSE, label.position = "bottom",
                               draw.ulim = FALSE, draw.llim = FALSE)
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

# The height is Figure 4F's, so the bottom row of Figure 4 sits level.
ggsave(file.path(figures_dir, "Fig4E_ora_dotplot.pdf"), ora_plot,
       width = 104, height = 80, units = "mm", device = cairo_pdf_font)
