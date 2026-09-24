## Fig 2A - NLRP3 locus zoom
##
## Regional association panels for NLRP3 expression, CRP, GlycA and neutrophil
## count, with LD to the colocalising variant from the INTERVAL panel and the
## instruments ringed in gold. Reads results/01_colocalisation/ and
## results/02_instrument_table/.

suppressPackageStartupMessages({
    library(AnnotationHub)
    library(ensembldb)
    library(patchwork)
    library(locuszoomr)
})
source(here::here("config.R"))
source(here::here("helpers.R"))
source(here::here("figures", "style.R"))

# geoms take their family from the geom default, not the theme: this is what
# reaches locuszoomr's gene labels
update_geom_defaults("text", list(family = FONT))
update_geom_defaults("label", list(family = FONT))

ensDb_v111 <- AnnotationHub()[["AH116291"]]
index_snp <- "1_247438293_C_T" # rs12239046, the colocalising variant
instruments <- fread(file.path(results_dir, "02_instrument_table",
                               "instrument_table_aligned.tsv"))$SNP

# One of step 01's regional tables as a locuszoomr locus. A variant the LD
# panel lacks is drawn grey rather than dropped.
make_locus <- function(file) {
    data <- fread(file.path(results_dir, "01_colocalisation", file), data.table = FALSE) %>%
        mutate(chrom = as.integer(chrom), pos = as.integer(pos), panel_id = to_panel_id(SNPid))
    loc <- locus(data = data, xrange = c(GENE_START - 150e3, GENE_START + 150e3),
                 p = "p", pos = "pos", chrom = "chrom", labs = "SNPid",
                 index_snp = index_snp, seqname = 1, flank = 0, ens_db = ensDb_v111)
    # no point borders: gg_scatter takes the outline colour from this column
    loc$data$col <- factor(alpha("black", 0))
    loc
}

scatter_panel <- function(file, title) {
    loc <- make_locus(file) %>% add_LD(index_snp) %>% link_recomb()
    base_size <- 6
    pt_size <- 0.85
    at_mb <- function(d) mutate(d, .x = pos / 1e6, .y = .data[[loc$yvar]])
    p <- gg_scatter(loc, index_snp = index_snp, size = pt_size, LD_scheme = LD_SCHEME,
                    recomb_col = NA, border = TRUE, ylab = expression(-log[10](P - value))) +
        theme(
            plot.title = element_text(hjust = 0.5, size = base_size * 1.3, margin = margin(0, 0, 2, 0)),
            axis.title.y = element_text(size = base_size, angle = 90, vjust = 0.5),
            axis.title.y.right = element_text(size = base_size, angle = 270, vjust = 0.5),
            axis.text.y = element_text(size = base_size * 0.98),
            axis.text.y.right = element_text(size = base_size * 0.98),
            legend.key.height = unit(0.085, "cm"),
            legend.key.width = unit(0.16, "cm"),
            legend.key.spacing.y = unit(-1.6, "pt"),
            legend.spacing.x = unit(0.4, "mm"),
            legend.margin = margin(1, 1.5, 1, 1.5, "pt"),
            legend.text = element_text(size = base_size * 0.78, margin = margin(l = 1, unit = "pt")),
            legend.title = element_text(size = base_size * 0.88, margin = margin(b = 0.5, unit = "pt")),
            legend.background = element_rect(colour = "#FFFFFFAA", fill = "#FFFFFFAA"),
            axis.title.x = element_blank(),
            axis.text.x = element_blank(),
            axis.ticks.x = element_blank(),
            axis.line = element_line(linewidth = 0.25),
            axis.ticks.y = element_line(linewidth = 0.25),
            axis.ticks.length = unit(1, "pt"),
            plot.margin = margin(t = 0, r = 3.5, b = 0, l = 3.5, unit = "pt")
        ) +
        # the index variant again, so the legend's "Index SNP" row gets a glyph
        geom_point(data = at_mb(filter(loc$data, SNPid == index_snp)),
                   aes(x = .x, y = .y, fill = factor(7, levels = 1:7)),
                   inherit.aes = FALSE, shape = 23, size = pt_size,
                   colour = alpha("black", 0), stroke = 0, show.legend = TRUE) +
        guides(fill = guide_legend(override.aes = list(size = 0.85, stroke = 0), reverse = TRUE)) +
        ggtitle(title)
    add_recomb_line(p, loc) +
        geom_point(data = at_mb(filter(loc$data, SNPid %in% instruments)), aes(x = .x, y = .y),
                   inherit.aes = FALSE, shape = 21, size = pt_size + 0.75,
                   colour = "#DAA520", fill = NA, stroke = 0.5)
}

eqtl_panel <- scatter_panel("regional_NLRP3_expression_unconditioned.tsv",
                            expression(italic("NLRP3") ~ "expression"))
crp_panel <- scatter_panel("regional_CRP.tsv", "CRP concentration")
glyca_panel <- scatter_panel("regional_GlycA.tsv", "GlycA concentration")
neutro_panel <- scatter_panel("regional_Neutrophil_count.tsv", "Neutrophil count")
gene_tracks <- gg_genetracks(make_locus("regional_CRP.tsv"),
                             filter_gene_biotype = "protein_coding", highlight = "NLRP3",
                             filter_gene_name = c("ZNF496", "NLRP3", "OR2B11", "OR2C3", "GCSAML"),
                             cex.text = 0.52, cex.axis = 0.60, cex.lab = 0.70) +
    theme(axis.line = element_line(linewidth = 0.25),
          axis.ticks = element_line(linewidth = 0.25),
          axis.ticks.length = unit(1, "pt"))

# The legend stays where gg_scatter puts it, inside the top-left panel.
final_plot <- wrap_plots(
    eqtl_panel + theme(axis.title.y.right = element_blank(),
                       plot.margin = margin(t = 0, r = 3.5, b = 6.5, l = 0, unit = "pt")),
    crp_panel + theme(axis.title.y = element_blank(), legend.position = "none",
                      plot.margin = margin(t = 0, r = 0, b = 6.5, l = 3.5, unit = "pt")),
    glyca_panel + theme(axis.title.y.right = element_blank(), legend.position = "none",
                        plot.margin = margin(t = 1, r = 3.5, b = 4, l = 0, unit = "pt")),
    neutro_panel + theme(axis.title.y = element_blank(), legend.position = "none",
                         plot.margin = margin(t = 0, r = 0, b = 4, l = 3.5, unit = "pt")),
    gene_tracks + theme(plot.margin = margin(t = 1, r = 3.5, b = 0, l = 0, unit = "pt")),
    gene_tracks + theme(plot.margin = margin(t = 1, r = 0, b = 0, l = 3.5, unit = "pt")),
    ncol = 2
) +
    plot_layout(heights = c(1, 1, 0.45)) +
    plot_layout(axes = "collect")

# gg_scatter() and gg_genetracks() each apply a complete theme, so the family
# goes on the assembled figure.
final_plot <- final_plot & theme(text = element_text(family = FONT_BODY))

ggsave(file.path(figures_dir, "Fig2A_NLRP3_locuszoom.pdf"), final_plot,
       width = 120, height = 102, units = "mm", device = cairo_pdf_font)
