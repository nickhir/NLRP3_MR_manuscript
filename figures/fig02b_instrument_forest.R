## Fig 2B - Instrument forest
##
## Per-instrument effects on the four readouts and on the activity score, each
## oriented to the allele that lowers the score. Reads results/02_instrument_table/.

suppressPackageStartupMessages({
    library(data.table)
    library(patchwork)
    library(tidyverse)
})
source(here::here("figures", "style.R"))

in_dir <- here::here("results", "02_instrument_table")
readouts <- fread(file.path(in_dir, "instrument_readouts_long.tsv"), data.table = FALSE)
aligned <- fread(file.path(in_dir, "instrument_table_aligned.tsv"), data.table = FALSE)
rsids <- fread(file.path(in_dir, "instrument_rsids.tsv"), data.table = FALSE)

SCORE <- "NLRP3 activity score"

# The activity score as a fifth column, on the variant's own allele (step 02
# writes it un-negated), then everything flipped to the allele lowering it.
effects <- readouts %>%
    select(SNP, trait, beta, se) %>%
    bind_rows(transmute(aligned, SNP, trait = SCORE, beta = beta_exposure, se = se_exposure)) %>%
    left_join(select(aligned, SNP, A1, A2), by = "SNP") %>%
    left_join(rsids, by = "SNP")
orientation <- effects %>%
    filter(trait == SCORE) %>%
    transmute(SNP, flip = beta > 0, effect_allele = if_else(beta > 0, A2, A1))
plot_data <- effects %>%
    left_join(orientation, by = "SNP") %>%
    mutate(beta = if_else(flip, -beta, beta),
           ci_lower = beta - 1.96 * se,
           ci_upper = beta + 1.96 * se)

# Rows ordered by the activity score, strongest effect at the top.
row_order <- plot_data %>%
    filter(trait == SCORE) %>%
    arrange(beta) %>%
    mutate(snp_label = paste0(rsid, "-", effect_allele))
plot_data <- plot_data %>%
    left_join(select(row_order, SNP, snp_label), by = "SNP") %>%
    mutate(snp_label = factor(snp_label, levels = rev(row_order$snp_label)))

trait_colors <- c("NLRP3_expression" = "#1B9E77",
                  "CRP" = "#4C72B0",
                  "GlycA" = "#E76F51",
                  "Neutrophil_count" = "#7CAE00",
                  "NLRP3 activity score" = "black")

# One column: its forest, and a grey two-line strip in place of the title.
create_forest_subplot <- function(trait_name, trait_label, show_yaxis, italic_first) {
    trait_data <- filter(plot_data, trait == trait_name)
    trait_color <- trait_colors[[trait_name]]

    # every effect is negative once oriented, so the axis runs up to zero
    min_val <- min(trait_data$ci_lower)
    limit_min <- min(min_val, 0)
    if (trait_name == "NLRP3_expression") limit_min <- limit_min - abs(limit_min) * 0.03

    p <- ggplot(trait_data, aes(x = beta, y = snp_label)) +
        geom_segment(aes(x = ci_lower, xend = ci_upper, y = snp_label, yend = snp_label),
                     linewidth = 0.4, color = trait_color) +
        geom_point(size = 1.8, shape = 21, fill = trait_color, color = trait_color, stroke = 0.4) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "darkgrey", linewidth = 0.3) +
        scale_x_continuous(
            limits = c(limit_min, 0),
            breaks = sort(unique(c(min_val * 0.85, 0))),
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
            axis.text.x = element_text(size = 8.8, color = "black", family = FONT_BODY),
            axis.text.y = if (show_yaxis) element_text(size = 8.8, color = "black", family = FONT_BODY) else element_blank(),
            axis.line.x = element_line(color = "black", linewidth = 0.4),
            axis.line.y = if (show_yaxis) element_line(color = "black", linewidth = 0.4) else element_blank(),
            axis.ticks.x = element_line(color = "black", linewidth = 0.4),
            axis.ticks.y = element_blank(),
            plot.title = element_text(size = 9, face = "bold", hjust = 0.5, vjust = 0.5),
            plot.title.position = "plot",
            plot.margin = margin(5, 2, 5, 2, "mm")
        )

    # The title cell becomes a 10 mm grey strip spanning the panel, with the two
    # lines as separate text grobs (9 pt at 0.95 line height), since plotmath
    # ignores lineheight.
    g <- ggplotGrob(p)
    ti <- which(g$layout$name == "title")
    pi <- which(g$layout$name == "panel")
    strip_mm <- 10
    g$heights[g$layout$t[ti]] <- unit(strip_mm, "mm")
    g$layout$l[ti] <- g$layout$l[pi]
    g$layout$r[ti] <- g$layout$r[pi]
    dy <- (9 * 0.95) / (strip_mm / 25.4 * 72) / 2
    g$grobs[[ti]] <- grid::grobTree(
        grid::rectGrob(gp = grid::gpar(fill = "#cdcdcd", col = "#cdcdcd")),
        grid::textGrob(trait_label[[1]], x = 0.5, y = 0.5 + dy, hjust = 0.5, vjust = 0.5,
                       gp = grid::gpar(fontsize = 9, fontfamily = FONT,
                                       fontface = if (italic_first) "bold.italic" else "bold")),
        grid::textGrob(trait_label[[2]], x = 0.5, y = 0.5 - dy, hjust = 0.5, vjust = 0.5,
                       gp = grid::gpar(fontsize = 9, fontfamily = FONT, fontface = "bold"))
    )
    g
}

plots <- list(
    create_forest_subplot("NLRP3_expression", c("NLRP3", "expression"), TRUE, TRUE),
    create_forest_subplot("CRP", c("CRP", "concentration"), FALSE, FALSE),
    create_forest_subplot("GlycA", c("GlycA", "concentration"), FALSE, FALSE),
    create_forest_subplot("Neutrophil_count", c("Neutrophil", "count"), FALSE, FALSE),
    create_forest_subplot(SCORE, c("NLRP3", "activity score"), FALSE, FALSE)
)

combined_plot <- wrap_plots(plots, ncol = 5, widths = c(1.55, 0.85, 0.85, 0.85, 1)) +
    plot_annotation(
        caption = "Effect size",
        theme = theme(plot.caption = element_text(size = 9, hjust = 0.5, family = FONT_BODY,
                                                  margin = margin(t = -3, unit = "mm")))
    )

ggsave(file.path(figures_dir, "Fig2B_NLRP3_instrument_forest.pdf"), combined_plot,
       width = 200, height = 76.5, units = "mm", device = cairo_pdf_font)
