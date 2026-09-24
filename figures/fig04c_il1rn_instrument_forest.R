## Fig 4C - IL1RN instrument forest
##
## Per-instrument effects for the IL1RN positive control, the IL1RN analogue of
## Figure 2B, oriented to the allele raising IL1RN expression. Reads
## results/08_il1rn_positive_control/.

suppressPackageStartupMessages({
    library(data.table)
    library(patchwork)
    library(tidyverse)
})
source(here::here("figures", "style.R"))

effects <- fread(here::here("results", "08_il1rn_positive_control", "il1rn_instrument_effects.tsv"),
                 data.table = FALSE)

orientation <- effects %>%
    filter(readout == "IL1RN expression") %>%
    transmute(SNP, flip = beta < 0, effect_allele = if_else(beta < 0, A2, A1))
plot_data <- effects %>%
    left_join(orientation, by = "SNP") %>%
    mutate(beta = if_else(flip, -beta, beta),
           ci_lower = beta - 1.96 * se,
           ci_upper = beta + 1.96 * se)

# Rows ordered by the activity score, strongest at the top.
row_order <- plot_data %>%
    filter(readout == "IL1Ra activity score") %>%
    arrange(desc(beta)) %>%
    mutate(snp_label = paste0(rsid, "-", effect_allele))
plot_data <- plot_data %>%
    left_join(select(row_order, SNP, snp_label), by = "SNP") %>%
    mutate(snp_label = factor(snp_label, levels = rev(row_order$snp_label)))

trait_colors <- c("IL1RN expression" = "#1B9E77",
                  "CRP concentration" = "#4C72B0",
                  "GlycA concentration" = "#E76F51",
                  "Neutrophil count" = "#7CAE00",
                  "IL1Ra activity score" = "black")

# One column: its forest, and a grey two-line strip in place of the title.
create_forest_subplot <- function(trait_name, trait_label, show_yaxis, italic_first) {
    trait_data <- filter(plot_data, readout == trait_name)
    trait_color <- trait_colors[[trait_name]]

    lo <- min(c(trait_data$ci_lower, 0))
    hi <- max(c(trait_data$ci_upper, 0))
    span <- hi - lo
    negative_side <- abs(lo) >= abs(hi)
    if (negative_side) {
        limits <- c(lo - span * 0.03, hi + span * 0.02)
    } else {
        limits <- c(lo - span * 0.07, hi + span * 0.03) # keeps the zero line off the axis
    }

    p <- ggplot(trait_data, aes(x = beta, y = snp_label)) +
        geom_segment(aes(x = ci_lower, xend = ci_upper, y = snp_label, yend = snp_label),
                     linewidth = 0.55, color = trait_color) +
        geom_point(size = 1.3, shape = 21, fill = trait_color, color = trait_color, stroke = 0.4) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "darkgrey", linewidth = 0.3) +
        scale_x_continuous(
            limits = limits,
            breaks = sort(unique(c(0, (if (negative_side) lo else hi) * 0.85))),
            labels = function(x) sub("^-?0\\.00$", "0", formatC(x, format = "f", digits = 2)),
            expand = expansion(mult = 0)
        ) +
        labs(x = NULL, y = NULL, title = "placeholder") +
        theme(
            panel.background = element_rect(fill = "white", colour = NA),
            plot.background = element_rect(fill = "white", colour = NA),
            panel.grid.major.x = element_blank(),
            panel.grid.minor = element_blank(),
            panel.grid.major.y = element_blank(),
            text = element_text(family = FONT_BODY),
            axis.text.x = element_text(size = 8, colour = "black", family = FONT_BODY),
            axis.text.y = if (show_yaxis) element_text(size = 8, colour = "black", family = FONT_BODY) else element_blank(),
            axis.line.x = element_line(color = "black", linewidth = 0.4),
            axis.line.y = if (show_yaxis) element_line(color = "black", linewidth = 0.4) else element_blank(),
            axis.ticks.x = element_line(color = "black", linewidth = 0.4),
            axis.ticks.y = element_blank(),
            plot.title = element_text(size = 8, family = FONT, face = "bold", hjust = 0.5, vjust = 0.5),
            plot.title.position = "plot",
            plot.margin = margin(2.2, 1.6, 2.2, 1.6, "mm")
        )

    # The title cell becomes an 8.2 mm grey strip spanning the panel, with the
    # two lines as separate text grobs (8 pt at 0.95 line height).
    g <- ggplotGrob(p)
    ti <- which(g$layout$name == "title")
    pi <- which(g$layout$name == "panel")
    g$heights[g$layout$t[ti]] <- unit(8.2, "mm")
    g$layout$l[ti] <- g$layout$l[pi]
    g$layout$r[ti] <- g$layout$r[pi]
    dy <- (8 * 0.95) / (8.2 / 25.4 * 72) / 2
    g$grobs[[ti]] <- grid::grobTree(
        grid::rectGrob(gp = grid::gpar(fill = "#cdcdcd", col = "#cdcdcd")),
        grid::textGrob(trait_label[[1]], x = 0.5, y = 0.5 + dy, hjust = 0.5, vjust = 0.5,
                       gp = grid::gpar(fontsize = 8, fontfamily = FONT,
                                       fontface = if (italic_first) "bold.italic" else "bold")),
        grid::textGrob(trait_label[[2]], x = 0.5, y = 0.5 - dy, hjust = 0.5, vjust = 0.5,
                       gp = grid::gpar(fontsize = 8, fontfamily = FONT, fontface = "bold"))
    )
    g
}

plots <- list(
    create_forest_subplot("IL1RN expression", c("IL1RN", "expr."), TRUE, TRUE),
    create_forest_subplot("CRP concentration", c("CRP", "conc."), FALSE, FALSE),
    create_forest_subplot("GlycA concentration", c("GlycA", "conc."), FALSE, FALSE),
    create_forest_subplot("Neutrophil count", c("Neutrophil", "count"), FALSE, FALSE),
    create_forest_subplot("IL1Ra activity score", c("IL1Ra", "score"), FALSE, FALSE)
)

# Widths are per subplot but each strip is clipped to its panel, so the first,
# which also carries the rsID labels, needs much the largest share.
combined_plot <- wrap_plots(plots, ncol = 5, widths = c(2.50, 1.00, 1.00, 1.28, 1.00)) +
    plot_annotation(
        caption = "Effect size",
        theme = theme(plot.caption = element_text(size = 7.8, family = FONT, face = "bold",
                                                  hjust = 0.5, margin = margin(t = -2, unit = "mm")))
    )

ggsave(file.path(figures_dir, "Fig4C_il1rn_instrument_forest.pdf"), combined_plot,
       width = 112, height = 50, units = "mm", device = cairo_pdf_font)
