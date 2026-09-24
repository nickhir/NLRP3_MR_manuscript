## Sup Fig 2 - regional association plots for the three inflammatory biomarkers
## across NLRP3 +/- 1 Mb, with each readout's clumped leads ringed in gold.
##
## Reads the readout GWAS named in config.R, writes
## figures_out/SupFig2_regional_plots.pdf.

suppressPackageStartupMessages({
    library(AnnotationHub)
    library(ensembldb)
    library(patchwork)
    library(locuszoomr)
})
source(here::here("config.R"))
source(here::here("helpers.R"))
source(here::here("figures", "style.R"))

FLANK <- 1e6
index_snp <- "1_247438293_C_T" # rs12239046, the variant the instruments tag
PANELS <- c(CRP = "CRP concentration",
            GlycA = "GlycA concentration",
            Neutrophil_count = "Neutrophil count")

ensDb_v111 <- AnnotationHub()[["AH116291"]]

build_locus <- function(cfg) {
    # locus() indexes with data[, p], which needs a plain data.frame
    data <- read_region(cfg, CHR, GENE_START - FLANK, GENE_END + FLANK) %>%
        harmonise(cfg) %>%
        transmute(SNPid, chrom = chr, pos, A1, A2, beta, se, p, panel_id = to_panel_id(SNPid)) %>%
        as.data.frame()
    loc <- locus(data = data, xrange = c(GENE_START - FLANK, GENE_END + FLANK),
                 p = "p", pos = "pos", chrom = "chrom", labs = "SNPid",
                 index_snp = index_snp, seqname = 1, flank = 0, ens_db = ensDb_v111)
    # no point borders: gg_scatter takes the outline colour from this column
    loc$data$col <- factor(alpha("black", 0))
    link_recomb(add_LD(loc, index_snp))
}

scatter_panel <- function(loc, title, show_legend, trait) {
    base_size <- 6
    # The readout's own approximately independent genome-wide significant
    # variants over the whole window (step 00 clumps only near the gene).
    ring <- from_panel_id(ld_clump_local(data.frame(SNP = loc$data$panel_id, p = loc$data$p),
                                         ld_panel, 0.1, 250)$ID)
    # Most neutrophil variants are missing from the LD panel and draw grey,
    # which swamps the colour: those are thinned to a quarter, keeping the
    # significant and the ringed ones.
    if (trait == "Neutrophil_count") {
        set.seed(1)
        d <- loc$data
        loc$data <- d[!is.na(d$ld) | d$p < 5e-8 | d$SNPid %in% ring | runif(nrow(d)) < 0.25, ]
    }
    hl <- loc$data %>%
        filter(SNPid %in% ring) %>%
        mutate(.x = pos / 1e6, .y = .data[[loc$yvar]])

    # recombination comes from add_recomb_line(), thin and grey
    p <- gg_scatter(loc, index_snp = index_snp, size = 0.5, LD_scheme = LD_SCHEME,
                    recomb_col = NA, border = TRUE, ylab = expression(-log[10](P - value))) +
        geom_hline(yintercept = -log10(5e-8), linetype = "dashed", colour = "grey60",
                   linewidth = 0.25) +
        geom_point(data = hl, aes(x = .x, y = .y), inherit.aes = FALSE,
                   shape = 21, size = 1.25, colour = "#DAA520", fill = NA, stroke = 0.5) +
        ggtitle(title) +
        theme(
            plot.title = element_text(hjust = 0.5, size = base_size * 1.3, margin = margin(0, 0, 4, 0)),
            axis.title.y = element_text(size = base_size, angle = 90, vjust = 0.5),
            axis.title.y.right = element_text(size = base_size, angle = 270, vjust = 0.5),
            axis.text.y = element_text(size = base_size * 0.98),
            axis.text.y.right = element_text(size = base_size * 0.98),
            axis.title.x = element_blank(),
            axis.text.x = element_blank(),
            axis.ticks.x = element_blank(),
            axis.line = element_line(linewidth = 0.25),
            axis.ticks.y = element_line(linewidth = 0.25),
            axis.ticks.length = unit(1, "pt"),
            legend.key.height = unit(0.085, "cm"),
            legend.key.width = unit(0.16, "cm"),
            legend.key.spacing.y = unit(-1.6, "pt"),
            legend.margin = margin(1, 1.5, 1, 1.5, "pt"),
            legend.text = element_text(size = base_size * 0.78, margin = margin(l = 1, unit = "pt")),
            legend.title = element_text(size = base_size * 0.88, margin = margin(b = 0.5, unit = "pt")),
            legend.background = element_rect(colour = "#FFFFFFAA", fill = "#FFFFFFAA"),
            plot.margin = margin(t = 7, r = 3.5, b = 0, l = 3.5, unit = "pt")
        )
    p <- add_recomb_line(p, loc)

    if (show_legend) {
        p + guides(fill = guide_legend(override.aes = list(size = 0.85, stroke = 0), reverse = TRUE))
    } else {
        p + theme(legend.position = "none")
    }
}

loci <- lapply(READOUTS[names(PANELS)], build_locus)
scatters <- Map(scatter_panel, loci, PANELS, c(TRUE, FALSE, FALSE), names(PANELS))

genetracks <- gg_genetracks(loci[[1]], filter_gene_biotype = "protein_coding",
                            highlight = "NLRP3", cex.text = 0.42, cex.axis = 0.60,
                            cex.lab = 0.70) +
    theme(axis.line = element_line(linewidth = 0.25),
          axis.ticks = element_line(linewidth = 0.25),
          axis.ticks.length = unit(1, "pt"),
          plot.margin = margin(t = 0, r = 3.5, b = 0, l = 3.5, unit = "pt"))

combined <- wrap_plots(c(scatters, list(genetracks)), ncol = 1, heights = c(1, 1, 1, 1.3))

ggsave(file.path(figures_dir, "SupFig2_regional_plots.pdf"), combined,
       width = 174, height = 215, units = "mm", device = cairo_pdf_font)
