## Fig 4C - IL1RN instrument forest
##
## Per-instrument effects for the IL1RN positive control, the IL1RN analogue of
## Figure 2B. Reads results/08_il1rn_positive_control/.

suppressPackageStartupMessages({
    library(data.table)
    library(patchwork)
    library(tidyverse)
    library(grid)
    library(here)
})

# FONT. One typeface across every panel, R and Python alike - see
# figures/fig02b_instrument_forest.R and fig02c_validation_forest.py.
FONT      <- "Open Sans"           # bold elements only -> OpenSans-Bold
FONT_BODY <- "Open Sans Semibold"  # body text, and the device default

# The family goes on the DEVICE. This script used plain ggsave(), i.e.
cairo_pdf_font <- function(filename, ...) cairo_pdf(filename, ..., family = FONT_BODY)
update_geom_defaults("text", list(family = FONT))   # geoms ignore theme(text = )

analysis_dir <- here::here()
in_file      <- file.path(analysis_dir, "results", "08_il1rn_positive_control",
                          "il1rn_instrument_effects.tsv")
figures_dir  <- file.path(analysis_dir, "figures_out")
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

effects <- fread(in_file, data.table = FALSE)

READOUTS <- c("IL1RN expression", "CRP concentration", "GlycA concentration",
              "Neutrophil count", "IL1Ra activity score")

## ---- orient to the IL1RN-expression-increasing allele ----------------------
orientation <- effects |>
    filter(readout == "IL1RN expression") |>
    transmute(SNP, rsid, flip = beta < 0,
              effect_allele = if_else(beta < 0, A2, A1))

plot_data <- effects |>
    left_join(orientation |> select(SNP, flip, effect_allele), by = "SNP") |>
    mutate(beta     = if_else(flip, -beta, beta),
           ci_lower = beta - 1.96 * se,
           ci_upper = beta + 1.96 * se)

# Rows ordered by the activity score, strongest at the top. Fig 2B orders by
# its latent factor the same way; its values are all negative and ours all
# positive, hence desc() here.
row_order <- plot_data |>
    filter(readout == "IL1Ra activity score") |>
    arrange(desc(beta)) |>
    mutate(snp_label = paste0(rsid, "-", effect_allele))

plot_data <- plot_data |>
    left_join(row_order |> select(SNP, snp_label), by = "SNP") |>
    mutate(snp_label = factor(snp_label, levels = rev(row_order$snp_label)),
           readout   = factor(readout, levels = READOUTS))

## ---- Fig 2B subplot builder ------------------------------------------------
trait_colors <- c("IL1RN expression"     = "#1B9E77",
                  "CRP concentration"    = "#4C72B0",
                  "GlycA concentration"  = "#E76F51",
                  "Neutrophil count"     = "#7CAE00",
                  "IL1Ra activity score" = "black")

POINT_FILL_FOLLOWS_COLOUR <- TRUE   # see deviation 3

create_forest_subplot <- function(data, trait_name, trait_label,
                                  show_yaxis = FALSE, italic_first = FALSE) {
    trait_data  <- data |> filter(readout == trait_name)
    trait_color <- trait_colors[[trait_name]]
    if (is.null(trait_color)) trait_color <- "black"
    point_fill  <- if (POINT_FILL_FOLLOWS_COLOUR) trait_color else "white"

    lo   <- min(c(trait_data$ci_lower, 0), na.rm = TRUE)
    hi   <- max(c(trait_data$ci_upper, 0), na.rm = TRUE)
    span <- hi - lo
    negative_side <- abs(lo) >= abs(hi)

    if (negative_side) {
        limit_min <- lo - span * 0.03
        limit_max <- hi + span * 0.02
    } else {
        limit_min <- lo - span * 0.07   # keeps the dashed zero line off the axis
        limit_max <- hi + span * 0.03
    }
    extreme   <- if (negative_side) lo else hi
    tick_vals <- sort(unique(c(0, extreme * 0.85)))

    p <- ggplot(trait_data, aes(x = beta, y = snp_label)) +
        geom_segment(aes(x = ci_lower, xend = ci_upper,
                         y = snp_label, yend = snp_label),
                     linewidth = 0.55, color = trait_color) +
        geom_point(size = 1.3, shape = 21, fill = point_fill,
                   color = trait_color, stroke = 0.4) +
        geom_vline(xintercept = 0, linetype = "dashed",
                   color = "darkgrey", linewidth = 0.3) +
        scale_x_continuous(
            limits = c(limit_min, limit_max),
            breaks = tick_vals,
            labels = function(x) {
                f <- formatC(x, format = "f", digits = 2)
                f <- gsub("^-0\\.00$", "0", f)
                gsub("^0\\.00$", "0", f)
            },
            expand = expansion(mult = 0)
        ) +
        labs(x = NULL, y = NULL, title = "placeholder") +
        theme(
            panel.background    = element_rect(fill = "white", colour = NA),
            plot.background     = element_rect(fill = "white", colour = NA),
            panel.grid.major.x  = element_blank(),
            panel.grid.minor    = element_blank(),
            panel.grid.major.y  = element_blank(),
            text                = element_text(family = FONT_BODY),
            axis.text.x         = element_text(size = 8, colour = "black", family = FONT_BODY),
            axis.text.y         = if (show_yaxis) element_text(size = 8, colour = "black", family = FONT_BODY) else element_blank(),
            axis.line.x         = element_line(color = "black", linewidth = 0.4),
            axis.line.y         = if (show_yaxis) element_line(color = "black", linewidth = 0.4) else element_blank(),
            axis.ticks.x        = element_line(color = "black", linewidth = 0.4),
            axis.ticks.y        = element_blank(),
            plot.title          = element_text(size = 8, family = FONT, face = "bold",
                                               hjust = 0.5, vjust = 0.5),
            plot.title.position = "plot",
            plot.margin         = margin(2.2, 1.6, 2.2, 1.6, "mm")
        )

    p_grob <- ggplotGrob(p)
    ti <- which(p_grob$layout$name == "title")
    pi <- which(p_grob$layout$name == "panel")

    if (length(ti) > 0 && length(pi) > 0) {
        p_grob$heights[p_grob$layout$t[ti]] <- unit(8.2, "mm")
        p_grob$layout$l[ti] <- p_grob$layout$l[pi]
        p_grob$layout$r[ti] <- p_grob$layout$r[pi]

        # 8 pt x 0.95 lineheight, inside the 8.2 mm strip set above - see
        # deviation 4. Both lines are separate textGrobs at an explicit baseline
        # offset because plotmath ignores lineheight.
        dy <- (8 * 0.95) / (8.2 / 25.4 * 72) / 2
        p_grob$grobs[[ti]] <- grid::grobTree(
            grid::rectGrob(gp = grid::gpar(fill = "#cdcdcd", col = "#cdcdcd")),
            grid::textGrob(
                trait_label[[1]], x = 0.5, y = 0.5 + dy, hjust = 0.5, vjust = 0.5,
                gp = grid::gpar(fontsize = 8, fontfamily = FONT,
                                fontface = if (italic_first) "bold.italic" else "bold")),
            grid::textGrob(
                trait_label[[2]], x = 0.5, y = 0.5 - dy, hjust = 0.5, vjust = 0.5,
                gp = grid::gpar(fontsize = 8, fontfamily = FONT, fontface = "bold"))
        )
    }
    p_grob
}

## ---- build and combine -----------------------------------------------------
# Second lines are abbreviated - expr. / conc.
trait_info <- list(
    list(name = "IL1RN expression",     label = c("IL1RN", "expr."),      italic = TRUE),
    list(name = "CRP concentration",    label = c("CRP", "conc."),        italic = FALSE),
    list(name = "GlycA concentration",  label = c("GlycA", "conc."),      italic = FALSE),
    list(name = "Neutrophil count",     label = c("Neutrophil", "count"), italic = FALSE),
    list(name = "IL1Ra activity score", label = c("IL1Ra", "score"),      italic = FALSE)
)

plots <- lapply(seq_along(trait_info), function(i) {
    create_forest_subplot(plot_data, trait_info[[i]]$name, trait_info[[i]]$label,
                          show_yaxis = (i == 1),
                          italic_first = trait_info[[i]]$italic)
})

combined_plot <- wrap_plots(plots[[1]], plots[[2]], plots[[3]],
                            plots[[4]], plots[[5]],
                            # Widths are per SUBPLOT, but each grey strip is
                            # clipped to its PANEL, so subplot 1 - which also
                            # carries the rsID axis labels - needs much the
                            # largest share before its box matches the others.
                            ncol = 5, widths = c(2.50, 1.00, 1.00, 1.28, 1.00)) +
    plot_annotation(
        caption = "Effect size",
        theme = theme(plot.caption = element_text(
            size = 7.8, family = FONT, face = "bold", hjust = 0.5,
            margin = margin(t = -2, unit = "mm")))
    )

pdf_out <- file.path(figures_dir, "Fig4C_il1rn_instrument_forest.pdf")
# Taller than the 60 mm this carried at 6 pt: the strip titles are 8 pt now and
# the strip itself grew from 6.4 to 8.2 mm to hold two lines of them.
ggsave(pdf_out, combined_plot, width = 112, height = 50, units = "mm",
       device = cairo_pdf_font)

message("flipped to the expression-increasing allele: ",
        if (any(orientation$flip))
            paste(orientation$rsid[orientation$flip], collapse = ", ") else "(none)")
message("rows, top to bottom: ", paste(row_order$snp_label, collapse = ", "))
message("wrote ", pdf_out)
