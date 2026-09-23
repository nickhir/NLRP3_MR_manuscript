## Sup Fig 2 - regional association plots for the three inflammatory biomarkers
## across NLRP3 +/- 1 Mb, with the eight instruments ringed in gold.
##
## Reads the readout GWAS named in config.R, writes
## figures_out/SupFig2_regional_plots.pdf.

suppressPackageStartupMessages({
    library(data.table)
    library(AnnotationHub)
    library(ensembldb)
    library(patchwork)
    library(here)
    library(locuszoomr)
    library(tidyverse)
})

source(here::here("config.R"))
source(here::here("helpers.R"))

FONT_BODY <- "Open Sans Semibold"
cairo_pdf_font <- function(filename, ...) cairo_pdf(filename, ..., family = FONT_BODY)

analysis_dir <- here::here()
out_dir <- file.path(analysis_dir, "figures_out")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

FLANK <- 1e6
index_snp <- "1_247438293_C_T"   # rs12239046, the variant the instruments tag
PANELS <- c(CRP = "CRP concentration",
            GlycA = "GlycA concentration",
            Neutrophil_count = "Neutrophil count")

# Same seven-level scheme gg_scatter bins into, as Figure 2A uses.
LD_SCHEME <- c(
    "grey62",    # NA - not in the LD panel
    "#1B36C4",   # 0.0 - 0.2
    "#00BEEF",   # 0.2 - 0.4
    "#00B81F",   # 0.4 - 0.6
    "#FF8A00",   # 0.6 - 0.8
    "#EB0000",   # 0.8 - 1.0
    "#9A00C8"    # index SNP
)

ah <- AnnotationHub()
ensDb_v111 <- ah[["AH116291"]]

# Approximately independent genome-wide significant variants across the whole
# plotted window. analysis/00 only clumps within 150 kb of the gene, so the
# distant neutrophil signals this figure is about need their own clump.
clump_leads <- function(d) {
    cl <- ld_clump_local(data.frame(SNP = d$panel_id, p = d$p),
                         bfile = ld_panel, r2 = 0.1, kb = 250)
    from_panel_id(cl$ID)
}

panels <- lapply(names(PANELS), function(k) {
    cfg <- READOUTS[[k]]
    d <- read_region(cfg, CHR, GENE_START - FLANK, GENE_END + FLANK) %>%
        harmonise_region(cfg, CHR) %>%
        mutate(chrom = as.integer(chrom), pos = as.integer(pos),
               panel_id = to_panel_id(SNPid)) %>%
        # locus() indexes with data[, p]; on a tibble that returns a one-column
        # tibble and -log10() of it makes logP a list column, which no scale can
        # render. A plain data.frame drops to a vector.
        as.data.frame()
    message(sprintf("%-18s %6d variants, min p = %.2e",
                    k, nrow(d), min(d$p, na.rm = TRUE)))
    d
})
names(panels) <- names(PANELS)

## ---- one panel ---------------------------------------------------------------
build_locus <- function(data) {
    ld <- locus(
        data      = data,
        xrange    = c(GENE_START - FLANK, GENE_END + FLANK),
        p         = "p",
        pos       = "pos",
        chrom     = "chrom",
        labs      = "SNPid",
        index_snp = index_snp,
        seqname   = 1,
        flank     = 0,
        ens_db    = ensDb_v111
    )
    # gg_scatter takes each point's outline from this column; a transparent
    # value leaves only the LD fill.
    ld$data$col <- factor(alpha("black", 0))
    ld <- add_LD(ld, reference = ld_panel, SNPid_col = "panel_id",
                 index_snp = to_panel_id(index_snp))
    ld$index_snp <- index_snp
    link_recomb(ld)
}

# Most neutrophil variants are missing from the LD panel and draw grey, which
# swamps the colour. Thin those to a quarter, keeping significant and ringed ones.
thin_grey <- function(ld, ring) {
    d <- ld$data
    set.seed(1)
    keep <- !is.na(d$ld) | d$p < 5e-8 | d$SNPid %in% ring | runif(nrow(d)) < 0.25
    ld$data <- d[keep, ]
    ld
}

scatter_panel <- function(ld, title, show_legend, trait) {
    base_size <- 6
    ring <- clump_leads(ld$data)
    if (trait == "Neutrophil_count") ld <- thin_grey(ld, ring)
    hl <- ld$data %>%
        filter(SNPid %in% ring) %>%
        mutate(.x = .data[[ld$pos]] / 1e6, .y = .data[[ld$yvar]])

    p <- gg_scatter(ld, index_snp = index_snp, size = 0.5,
                    LD_scheme = LD_SCHEME,
                    ylab = expression(-log[10](P - value))) +
        geom_hline(yintercept = -log10(5e-8), linetype = "dashed",
                   colour = "grey60", linewidth = 0.25) +
        # This readout's clumped signal leads, ringed in gold. gg_scatter plots
        # position in Mb, so the layer has to be on the same scale.
        geom_point(data = hl, aes(x = .x, y = .y), inherit.aes = FALSE,
                   shape = 21, size = 0.75, colour = "#DAA520",
                   fill = NA, stroke = 0.4) +
        ggtitle(title) +
        theme(
            plot.title = element_text(hjust = 0.5, size = base_size * 1.3,
                                      margin = margin(0, 0, 4, 0)),
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
            legend.text = element_text(size = base_size * 0.78,
                                       margin = margin(l = 1, unit = "pt")),
            legend.title = element_text(size = base_size * 0.88,
                                        margin = margin(b = 0.5, unit = "pt")),
            legend.background = element_rect(colour = "#FFFFFFAA", fill = "#FFFFFFAA"),
            plot.margin = margin(t = 7, r = 3.5, b = 0, l = 3.5, unit = "pt")
        )

    # Points sit on the axis, with headroom above the top hit. gg_scatter adds a
    # secondary recombination axis, so more than one scale carries "y" and only
    # the first is the one to widen.
    y_scale <- which(vapply(p$scales$scales,
                            function(s) "y" %in% s$aesthetics, logical(1)))[1]
    p$scales$scales[[y_scale]]$expand <- expansion(mult = c(0, 0.18))

    if (show_legend) {
        p + guides(fill = guide_legend(override.aes = list(size = 0.85, stroke = 0),
                                       reverse = TRUE))
    } else {
        p + theme(legend.position = "none")
    }
}

loci <- lapply(panels, build_locus)
scatters <- Map(scatter_panel, loci, PANELS[names(loci)],
                c(TRUE, rep(FALSE, length(loci) - 1)), names(loci))

genetracks <- gg_genetracks(loci[[1]],
    filter_gene_biotype = "protein_coding",
    highlight = "NLRP3",
    cex.text = 0.42,
    cex.axis = 0.60,
    cex.lab = 0.70
) +
    theme(
        axis.line = element_line(linewidth = 0.25),
        axis.ticks = element_line(linewidth = 0.25),
        axis.ticks.length = unit(1, "pt"),
        plot.margin = margin(t = 0, r = 3.5, b = 0, l = 3.5, unit = "pt")
    )

combined <- wrap_plots(c(scatters, list(genetracks)), ncol = 1,
                       heights = c(1, 1, 1, 1.3))

ggsave(file.path(out_dir, "SupFig2_regional_plots.pdf"), combined,
       width = 174, height = 215, units = "mm", device = cairo_pdf_font)

message("Done -> ", file.path(out_dir, "SupFig2_regional_plots.pdf"))
