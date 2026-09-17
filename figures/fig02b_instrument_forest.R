## Fig 2B - Instrument forest
##
## Per-instrument effects on the four readouts and on the activity score.
## Reads results/02_instrument_table/.

suppressPackageStartupMessages({
    library(data.table)
    library(patchwork)
    library(tidyverse)
    library(grid)
    library(here)
})

# FONT. One typeface across every panel of Figure 2, R and Python alike.
FONT      <- "Open Sans"           # bold elements only -> OpenSans-Bold
FONT_BODY <- "Open Sans Semibold"  # body text, and the device default

# Anything that falls through to the DEVICE default rather than a theme or geom
# setting - plotmath being the one that matters here, since the y axis label
# and the italic gene title are expressions -.
cairo_pdf_font <- function(filename, ...) cairo_pdf(filename, ..., family = FONT_BODY)


analysis_dir <- here::here()
instr_dir    <- file.path(analysis_dir, "results", "02_instrument_table")
readouts_in  <- file.path(instr_dir, "instrument_readouts_long.tsv")
aligned_in   <- file.path(instr_dir, "instrument_table_aligned.tsv")
figures_dir  <- file.path(analysis_dir, "figures_out")
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

for (f in c(readouts_in, aligned_in)) {
    if (!file.exists(f)) {
        stop("missing input: ", f, "\nRun analysis/02_instrument_table.R first.")
    }
}

# The eight instruments' rsIDs, hardcoded so this figure depends on nothing but
# step 02.
RSIDS <- tibble::tribble(
    ~SNP,              ~rsid,
    "1_247406019_C_T", "rs61838754",
    "1_247432548_C_T", "rs10925019",
    "1_247433558_A_C", "rs74154640",
    "1_247438293_C_T", "rs12239046",
    "1_247442302_A_G", "rs74815978",
    "1_247452478_A_G", "rs10802505",
    "1_247459572_C_T", "rs4925671",
    "1_247460342_C_G", "rs188628429"
)

## ---- assemble the five columns ---------------------------------------------
readouts <- fread(readouts_in, data.table = FALSE)
aligned  <- fread(aligned_in,  data.table = FALSE)

SCORE <- "NLRP3 activity score"

# The activity score as a fifth "readout", on the variant's own allele - step 02
# writes it un-negated, and the flip below is what turns it round.
score <- aligned |>
    transmute(SNP, trait = SCORE, beta = beta_exposure, se = se_exposure)

effects <- readouts |>
    select(SNP, trait, beta, se) |>
    bind_rows(score) |>
    left_join(aligned |> select(SNP, A1, A2), by = "SNP")

effects <- left_join(effects, RSIDS, by = "SNP")

## ---- orient to the NLRP3-activity-LOWERING allele ---------------------------
orientation <- effects |>
    filter(trait == SCORE) |>
    transmute(SNP, flip = beta > 0,
              effect_allele = if_else(beta > 0, A2, A1))

plot_data <- effects |>
    left_join(orientation, by = "SNP") |>
    mutate(beta     = if_else(flip, -beta, beta),
           ci_lower = beta - 1.96 * se,
           ci_upper = beta + 1.96 * se)

# Deciding the flip on expression instead of the score must pick the same eight
# alleles, or the two disagree in sign somewhere and the panel would be reading
# a different exposure than its title claims.
expr <- plot_data |> filter(trait == "NLRP3_expression")
if (any(expr$beta > 0)) {
    stop("orienting on the activity score leaves NLRP3 expression positive at: ",
         paste(expr$rsid[expr$beta > 0], collapse = ", "),
         " - score and expression disagree in sign there")
}

# And the same for the readouts, which is what makes all five columns run one way.
if (any(plot_data$beta > 0)) {
    stop("after orienting to lower NLRP3 activity, these are still positive: ",
         paste(unique(plot_data$rsid[plot_data$beta > 0]), collapse = ", "))
}

# Rows ordered by the activity score, strongest effect at the top.
row_order <- plot_data |>
    filter(trait == SCORE) |>
    arrange(beta) |>
    mutate(snp_label = paste0(rsid, "-", effect_allele))

plot_data <- plot_data |>
    left_join(row_order |> select(SNP, snp_label), by = "SNP") |>
    mutate(snp_label = factor(snp_label, levels = rev(row_order$snp_label)))

## ---- subplot builder --------------------------------------------------------
trait_colors <- c("NLRP3_expression" = "#1B9E77",
                  "CRP"              = "#4C72B0",
                  "GlycA"            = "#E76F51",
                  "Neutrophil_count" = "#7CAE00",
                  "NLRP3 activity score" = "black")

create_forest_subplot <- function(data, trait_name, trait_label,
                                  show_yaxis = FALSE, italic_first = FALSE) {
    trait_data  <- data |> filter(trait == trait_name)
    trait_color <- trait_colors[[trait_name]]

    # Every effect is negative once oriented, so the axis runs from the most
    # extreme confidence limit up to zero.
    min_val   <- min(trait_data$ci_lower, na.rm = TRUE)
    limit_min <- min(min_val, 0)
    if (trait_name == "NLRP3_expression") {
        limit_min <- limit_min - abs(limit_min) * 0.03
    }
    tick_vals <- sort(unique(c(min_val * 0.85, 0)))

    p <- ggplot(trait_data, aes(x = beta, y = snp_label)) +
        geom_segment(aes(x = ci_lower, xend = ci_upper,
                         y = snp_label, yend = snp_label),
                     linewidth = 0.4, color = trait_color) +
        geom_point(size = 1.8, shape = 21, fill = trait_color,
                   color = trait_color, stroke = 0.4) +
        geom_vline(xintercept = 0, linetype = "dashed",
                   color = "darkgrey", linewidth = 0.3) +
        scale_x_continuous(
            limits = c(limit_min, 0),
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
            axis.text.x         = element_text(size = 8.8, color = "black", family = FONT_BODY),
            axis.text.y         = if (show_yaxis) element_text(size = 8.8, color = "black", family = FONT_BODY) else element_blank(),
            axis.line.x         = element_line(color = "black", linewidth = 0.4),
            axis.line.y         = if (show_yaxis) element_line(color = "black", linewidth = 0.4) else element_blank(),
            axis.ticks.x        = element_line(color = "black", linewidth = 0.4),
            axis.ticks.y        = element_blank(),
            plot.title          = element_text(size = 9, face = "bold",
                                               hjust = 0.5, vjust = 0.5),
            plot.title.position = "plot",
            plot.margin         = margin(5, 2, 5, 2, "mm")
        )

    p_grob <- ggplotGrob(p)
    ti <- which(p_grob$layout$name == "title")
    pi <- which(p_grob$layout$name == "panel")

    if (length(ti) > 0 && length(pi) > 0) {
        strip_mm <- 10
        p_grob$heights[p_grob$layout$t[ti]] <- unit(strip_mm, "mm")
        p_grob$layout$l[ti] <- p_grob$layout$l[pi]
        p_grob$layout$r[ti] <- p_grob$layout$r[pi]

        # 9 pt at 0.95 lineheight inside the strip - see deviation 3
        dy <- (9 * 0.95) / (strip_mm / 25.4 * 72) / 2
        p_grob$grobs[[ti]] <- grid::grobTree(
            grid::rectGrob(gp = grid::gpar(fill = "#cdcdcd", col = "#cdcdcd")),
            grid::textGrob(
                trait_label[[1]], x = 0.5, y = 0.5 + dy, hjust = 0.5, vjust = 0.5,
                gp = grid::gpar(fontsize = 9, fontfamily = FONT,
                                fontface = if (italic_first) "bold.italic" else "bold")),
            grid::textGrob(
                trait_label[[2]], x = 0.5, y = 0.5 - dy, hjust = 0.5, vjust = 0.5,
                gp = grid::gpar(fontsize = 9, fontfamily = FONT, fontface = "bold"))
        )
    }
    p_grob
}

## ---- build and combine ------------------------------------------------------
trait_info <- list(
    list(name = "NLRP3_expression", label = c("NLRP3", "expression"),     italic = TRUE),
    list(name = "CRP",              label = c("CRP", "concentration"),    italic = FALSE),
    list(name = "GlycA",            label = c("GlycA", "concentration"),  italic = FALSE),
    list(name = "Neutrophil_count", label = c("Neutrophil", "count"),     italic = FALSE),
    list(name = SCORE,              label = c("NLRP3", "activity score"), italic = FALSE)
)

plots <- lapply(seq_along(trait_info), function(i) {
    create_forest_subplot(plot_data, trait_info[[i]]$name, trait_info[[i]]$label,
                          show_yaxis = (i == 1),
                          italic_first = trait_info[[i]]$italic)
})

combined_plot <- wrap_plots(plots[[1]], plots[[2]], plots[[3]],
                            plots[[4]], plots[[5]],
                            ncol = 5, widths = c(1.55, 0.85, 0.85, 0.85, 1)) +
    plot_annotation(
        caption = "Effect size",
        theme = theme(plot.caption = element_text(
            size = 9, hjust = 0.5, family = FONT_BODY,
            margin = margin(t = -3, unit = "mm")))
    )

pdf_out <- file.path(figures_dir, "Fig2B_NLRP3_instrument_forest.pdf")
ggsave(pdf_out, combined_plot, width = 200, height = 76.5, units = "mm",
       device = cairo_pdf_font)

message("flipped to the activity-lowering allele: ",
        paste(orientation$SNP[orientation$flip], collapse = ", "))
message("rows, top to bottom: ", paste(row_order$snp_label, collapse = ", "))
message("wrote ", pdf_out)
