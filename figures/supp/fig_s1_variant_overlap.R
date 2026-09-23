## Sup Fig 1 - overlap of the NLRP3-locus signals across the four readouts.
##
## Reads results/00_instrument_selection/nlrp3_signal_components.tsv, writes
## figures_out/SupFig1_variant_overlap.pdf.

suppressPackageStartupMessages({
    library(tidyverse)
    library(patchwork)
    library(here)
})

FONT_BODY <- "Open Sans Semibold"
cairo_pdf_font <- function(filename, ...) cairo_pdf(filename, ..., family = FONT_BODY)

analysis_dir <- here::here()
in_file <- file.path(analysis_dir, "results", "00_instrument_selection",
                     "nlrp3_signal_components.tsv")
out_dir <- file.path(analysis_dir, "figures_out")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Same four colours Figure 2B gives these readouts.
COLOURS <- c(eQTLs = "#1B9E77", CRP = "#4C72B0",
             neutro = "#7CAE00", GlycA = "#E76F51")
# Row labels, as plotmath so the gene name comes out italic.
LABELS <- c(eQTLs  = "italic('NLRP3')~'expression'",
            CRP    = "'CRP'",
            neutro = "'Neutrophil Count'",
            GlycA  = "'GlycA'")

comp <- read_tsv(in_file, show_col_types = FALSE) %>%
    select(all_of(names(COLOURS))) %>%
    mutate(across(everything(), as.integer))

# Readouts run largest set first, top to bottom.
sizes <- comp %>%
    summarise(across(everything(), sum)) %>%
    pivot_longer(everything(), names_to = "trait", values_to = "n") %>%
    arrange(desc(n))

ORDER <- sizes$trait
sizes$trait <- factor(sizes$trait, levels = rev(ORDER))

# One row per distinct membership pattern. count() returns the patterns sorted
# by their id string and arrange() is stable, so equal-sized intersections keep
# that order rather than an arbitrary one.
inter <- comp %>%
    select(all_of(ORDER)) %>%
    unite("id", everything(), sep = "-") %>%
    count(id, name = "n") %>%
    arrange(desc(n)) %>%
    mutate(idx = row_number()) %>%
    separate(id, into = ORDER, sep = "-", convert = TRUE)

# y = 1 at the bottom, so the largest set ends up on top.
dots <- inter %>%
    select(idx, all_of(ORDER)) %>%
    pivot_longer(-idx, names_to = "trait", values_to = "present") %>%
    mutate(y = match(trait, rev(ORDER)))

links <- dots %>%
    filter(present == 1) %>%
    group_by(idx) %>%
    summarise(lo = min(y), hi = max(y), .groups = "drop")

stripes <- tibble(y = seq_along(ORDER)) %>%
    mutate(fill = if_else(y %% 2 == 1, "#F7F7F7", "white"))

XLIM <- c(0.5, nrow(inter) + 0.5)

p_top <- ggplot(inter, aes(idx, n)) +
    geom_col(width = 0.6, fill = "gray30") +
    geom_text(aes(label = n), vjust = -0.3, size = 3) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15)),
                       breaks = seq(0, max(inter$n) + 1, by = 2)) +
    scale_x_continuous(limits = XLIM, expand = expansion(mult = 0.02)) +
    labs(x = NULL, y = "Intersection\nsize") +
    theme_classic(base_size = 9) +
    theme(
        axis.line.x = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.text.y = element_text(size = 10),
        axis.title.y = element_text(size = 11),
        panel.grid = element_blank(),
        plot.margin = margin(t = 5, r = 5, b = 2, l = -30, unit = "pt")
    )

p_dots <- ggplot() +
    geom_rect(data = stripes,
              aes(ymin = y - 0.5, ymax = y + 0.5, fill = fill),
              xmin = -Inf, xmax = Inf, show.legend = FALSE) +
    scale_fill_identity() +
    geom_point(data = dots, aes(idx, y, colour = factor(present)),
               size = 2.2, show.legend = FALSE) +
    scale_colour_manual(values = c("0" = "gray85", "1" = "black")) +
    geom_segment(data = links, aes(x = idx, xend = idx, y = lo, yend = hi),
                 linewidth = 0.7) +
    scale_y_continuous(expand = expansion(mult = 0)) +
    scale_x_continuous(limits = XLIM, expand = expansion(mult = 0.02)) +
    labs(x = NULL, y = NULL) +
    theme_classic(base_size = 9) +
    theme(
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        panel.grid = element_blank(),
        plot.margin = margin(t = 0, r = 5, b = 5, l = -30, unit = "pt")
    )

# Bars run right to left off a shared zero, with the count set just inside the
# far end.
p_sets <- ggplot(sizes, aes(n, trait)) +
    geom_col(aes(fill = as.character(trait)), width = 0.5, show.legend = FALSE) +
    scale_fill_manual(values = COLOURS) +
    geom_text(aes(label = n), hjust = -0.2, size = 2.5,
              colour = "white", fontface = "bold") +
    scale_x_reverse(expand = expansion(mult = c(0.02, 0.02)),
                    limits = c(max(sizes$n) * 1.05, 0)) +
    scale_y_discrete(labels = function(x) parse(text = LABELS[x])) +
    labs(x = "Set size", y = NULL) +
    theme_classic(base_size = 9) +
    theme(
        axis.line.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.text.y = element_text(hjust = 1, size = 8.5),
        axis.title.x = element_text(size = 9),
        panel.grid = element_blank(),
        plot.margin = margin(t = 5, r = -15, b = 5, l = 5, unit = "pt")
    )

combined <- (plot_spacer() / p_sets + plot_layout(heights = c(0.42, 0.58))) |
    (p_top / p_dots + plot_layout(heights = c(0.42, 0.58)))
combined <- combined + plot_layout(widths = c(0.48, 0.52))

ggsave(file.path(out_dir, "SupFig1_variant_overlap.pdf"), combined,
       width = 132, height = 109, units = "mm", device = cairo_pdf_font)

message("components: ", nrow(comp), " | set sizes: ",
        paste(sizes$trait, sizes$n, sep = "=", collapse = ", "))
message("intersections: ", paste(inter$n, collapse = ", "))
message("Done -> ", file.path(out_dir, "SupFig1_variant_overlap.pdf"))
