## Fig 2A - NLRP3 locus zoom
##
## Regional association panels for NLRP3 expression, CRP, GlycA and neutrophil
## count, with LD computed against the INTERVAL panel.
## Reads results/01_colocalisation/ and results/02_instrument_table/.

suppressPackageStartupMessages({
    library(data.table)
    library(AnnotationHub)
    library(ensembldb)
    library(patchwork)
    library(here)
    library(locuszoomr)
    library(tidyverse)
})

# FONT. One typeface across every panel of Figure 2, R and Python alike.
FONT      <- "Open Sans"           # bold elements only -> OpenSans-Bold
FONT_BODY <- "Open Sans Semibold"  # body text, and the device default

# Anything that falls through to the DEVICE default rather than a theme or geom
# setting - plotmath being the one that matters here, since the y axis label
# and the italic gene title are expressions -.
cairo_pdf_font <- function(filename, ...) cairo_pdf(filename, ..., family = FONT_BODY)


# geom_text()/geom_label() read their family from the GEOM default, not from
# theme(text=), so locuszoomr's gene-track labels (ZNF496, OR2B11, ...) would
# otherwise stay on the device default.
update_geom_defaults("text",  list(family = FONT))
update_geom_defaults("label", list(family = FONT))

analysis_dir <- here::here()
coloc_dir    <- file.path(analysis_dir, "results", "01_colocalisation")
instr_file   <- file.path(analysis_dir, "results", "02_instrument_table",
                          "instrument_table_aligned.tsv")
figures_dir  <- file.path(analysis_dir, "figures_out")
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

# add_LD() and to_panel_id() come from here. helpers.R is shared function
# definitions only - the Rmd sourced its equivalent the same way. config.R is
# the file a figure script may not reach for, and this does not.
source(here::here("helpers.R"))

# INTERVAL WGS, GRCh38, 11,863 European-ancestry genomes - the same panel
# config.R names, hardcoded here because a figure script may not source
# config.R. The Rmd hardcoded its LD reference the same way.
ld_panel <- paste0(
    "/rds/user/nh608/hpc-work/oxLDL/data/oxLDL_data/INTERVAL_reference/",
    "WGS_reference/ld_panels/INTERVAL_allchr.GRCh38.alpha_sorted_alleles"
)

# One file per panel, all written by analysis/01_colocalisation.R.
PANEL_FILES <- c(
    NLRP3_expression = "regional_NLRP3_expression_unconditioned.tsv",
    CRP              = "regional_CRP.tsv",
    GlycA            = "regional_GlycA.tsv",
    Neutrophil_count = "regional_Neutrophil_count.tsv"
)

for (f in c(file.path(coloc_dir, PANEL_FILES), paste0(ld_panel, ".bed"), instr_file)) {
    if (!file.exists(f)) {
        stop("missing input: ", f,
             "\nRun analysis/01_colocalisation.R and analysis/02_instrument_table.R first.")
    }
}

## ---- setup -------------------------------------------------------------------
ah <- AnnotationHub()
ensDb_v111 <- ah[["AH116291"]]

# NLRP3 gene coordinates (hg38), as config.R states them. Hardcoded rather than
# sourced: config.R belongs to analysis/, and a figure may not reach for it.
chr        <- 1
start_hg38 <- 247416156
stop_hg38  <- 247449108
index_snp  <- "1_247438293_C_T"          # rs12239046, the colocalising variant

# LD colours, in the seven-level order gg_scatter bins into: no r2, then the
# five r2 bands, then the index variant.
LD_SCHEME <- c(
    "grey62",    # NA - not in the LD panel
    "#1B36C4",   # 0.0 - 0.2   (was royalblue)
    "#00BEEF",   # 0.2 - 0.4   (was cyan2)
    "#00B81F",   # 0.4 - 0.6   (was green3)
    "#FF8A00",   # 0.6 - 0.8   (was orange)
    "#EB0000",   # 0.8 - 1.0   (was red)
    "#9A00C8"    # index SNP   (was purple)
)

## ---- data --------------------------------------------------------------------
# Variants the INTERVAL panel does not carry keep an NA LD and are drawn grey,
# rather than dropped - a variant with no LD estimate is still a real
# association, and hiding it would overstate how.
load_panel <- function(trait) {
    fread(file.path(coloc_dir, PANEL_FILES[[trait]]), data.table = FALSE) |>
        mutate(chrom = as.integer(chrom), pos = as.integer(pos),
               panel_id = to_panel_id(SNPid))
}

panels <- lapply(names(PANEL_FILES), load_panel)
names(panels) <- names(PANEL_FILES)

for (k in names(panels)) {
    d <- panels[[k]]
    message(sprintf("%-18s %5d variants, min p = %.2e",
                    k, nrow(d), min(d$p, na.rm = TRUE)))
    if (!index_snp %in% d$SNPid) stop("index SNP missing from panel: ", k)
}

mr_instrument_snps <- fread(instr_file, data.table = FALSE)$SNP
stopifnot(length(mr_instrument_snps) == 8)

## ---- locuszoom ---------------------------------------------------------------
locus_plot <- function(data, highlights = NULL, title = waiver(),
                       add_recomb = TRUE, just_genes = FALSE,
                       just_scatter = FALSE, pt_size = 0.85) {
    if (!(index_snp %in% data$SNPid)) {
        stop(paste0("Configured index_snp not present in panel data: ", index_snp))
    }

    locus_data <- locus(
        data      = data,
        xrange    = c(start_hg38 - 150e3, start_hg38 + 150e3),
        p         = "p",
        pos       = "pos",
        chrom     = "chrom",
        labs      = "SNPid",
        index_snp = index_snp,
        seqname   = 1,
        flank     = 0,
        ens_db    = ensDb_v111
    )

    # Point borders off. gg_scatter draws every variant as shape 21 and takes
    # the outline colour from the levels of this column, so a fully transparent
    # value removes the stroke and leaves the LD fill alone.
    locus_data$data$col <- factor(alpha("black", 0))

    genetracks <- gg_genetracks(locus_data,
        filter_gene_biotype = "protein_coding",
        highlight = "NLRP3",
        filter_gene_name = c("ZNF496", "NLRP3", "OR2B11", "OR2C3", "GCSAML"),
        cex.text = 0.52,
        cex.axis = 0.60,
        cex.lab = 0.70
    ) +
        theme(
            axis.line = element_line(linewidth = 0.25),
            axis.ticks = element_line(linewidth = 0.25),
            axis.ticks.length = unit(1, "pt")
        )

    if (just_genes) {
        return(genetracks)
    }

    # LD on the fly, as the Rmd did - only against the region fileset step 01
    # leaves in results/, not the 43 GB genome-wide panel.
    locus_data <- add_LD(locus_data,
        reference = ld_panel,
        SNPid_col = "panel_id",
        index_snp = to_panel_id(index_snp)
    )
    locus_data$index_snp <- index_snp

    if (add_recomb) {
        locus_data <- link_recomb(locus_data)
    }

    base_size <- 6

    # gg_scatter plots position in Mb, so any layer added on top has to match.
    index_row <- locus_data$data[locus_data$data$SNPid == index_snp, , drop = FALSE]
    index_row$.x <- index_row[[locus_data$pos]] / 1e6
    index_row$.y <- index_row[[locus_data$yvar]]
    stopifnot(nrow(index_row) == 1)

    # ylab goes through gg_scatter rather than a trailing ylab(): gg_scatter
    # sets the y scale's name itself (for the recombination sec.axis), and a
    # scale name beats ylab().
    locus_plot <- gg_scatter(locus_data,
        index_snp = index_snp,
        size = pt_size,
        LD_scheme = LD_SCHEME,
        ylab = expression(-log[10](P - value))
    ) +
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
            legend.text = element_text(size = base_size * 0.78,
                                       margin = margin(l = 1, unit = "pt")),
            legend.title = element_text(size = base_size * 0.88,
                                        margin = margin(b = 0.5, unit = "pt")),
            legend.background = element_rect(colour = "#FFFFFFAA", fill = "#FFFFFFAA"),
            axis.title.x = element_blank(),
            axis.text.x = element_blank(),
            axis.ticks.x = element_blank(),
            axis.line = element_line(linewidth = 0.25),
            axis.ticks.y = element_line(linewidth = 0.25),
            axis.ticks.length = unit(1, "pt"),
            plot.margin = margin(t = 0, r = 3.5, b = 0, l = 3.5, unit = "pt")
        ) +
        # The index variant, again, purely so the legend has a key for it.
        # gg_scatter draws it in a layer of its own that is kept out of the
        # guide, so the "Index SNP" row comes back with a label and no glyph.
        geom_point(data = index_row, aes(x = .x, y = .y,
                                         fill = factor(7, levels = 1:7)),
                   inherit.aes = FALSE, shape = 23, size = pt_size,
                   colour = alpha("black", 0), stroke = 0,
                   show.legend = TRUE) +
        guides(fill = guide_legend(override.aes = list(size = 0.85, stroke = 0),
                                   reverse = TRUE)) +
        ggtitle(title)

    # Points sit on the axis rather than floating above it, with headroom left
    # above the top hit so the legend and the tallest points are not crowded
    # against the panel border.
    y_scale <- which(vapply(locus_plot$scales$scales,
                            function(s) "y" %in% s$aesthetics, logical(1)))
    stopifnot(length(y_scale) == 1)
    locus_plot$scales$scales[[y_scale]]$expand <- expansion(mult = c(0, 0.18))

    # Deviation 2: the instruments, ringed in gold. gg_scatter plots position in
    # Mb, so the layer has to be on the same scale.
    if (!is.null(highlights)) {
        hl <- locus_data$data |>
            filter(SNPid %in% highlights) |>
            mutate(.x = .data[[locus_data$pos]] / 1e6,
                   .y = .data[[locus_data$yvar]])
        locus_plot <- locus_plot +
            geom_point(data = hl, aes(x = .x, y = .y),
                       inherit.aes = FALSE, shape = 21, size = pt_size + 0.15,
                       colour = "#DAA520", fill = NA, stroke = 0.4)
    }

    if (just_scatter) {
        return(locus_plot)
    }

    wrap_plots(locus_plot, genetracks, ncol = 1) +
        plot_layout(heights = c(1, 0.3))
}

## ---- panels ------------------------------------------------------------------
eQTL_locuszoom <- locus_plot(panels$NLRP3_expression,
    highlights = mr_instrument_snps,
    title = expression(italic("NLRP3") ~ "expression"),
    just_scatter = TRUE
)
crp_locuszoom <- locus_plot(panels$CRP,
    highlights = mr_instrument_snps,
    title = "CRP concentration",
    just_scatter = TRUE
)
glyca_locuszoom <- locus_plot(panels$GlycA,
    highlights = mr_instrument_snps,
    title = "GlycA concentration",
    just_scatter = TRUE
)
neutro_locuszoom <- locus_plot(panels$Neutrophil_count,
    highlights = mr_instrument_snps,
    title = "Neutrophil count",
    just_scatter = TRUE
)
gene_tracks <- locus_plot(panels$CRP, just_genes = TRUE)

# The legend stays where gg_scatter puts it - inside the top-left panel, as in
# print.
final_plot <- wrap_plots(
    eQTL_locuszoom + theme(
        axis.title.y.right = element_blank(),
        plot.margin = margin(t = 0, r = 3.5, b = 6.5, l = 0, unit = "pt")
    ),
    crp_locuszoom + theme(
        axis.title.y = element_blank(),
        legend.position = "none",
        plot.margin = margin(t = 0, r = 0, b = 6.5, l = 3.5, unit = "pt")
    ),
    glyca_locuszoom + theme(
        axis.title.y.right = element_blank(),
        legend.position = "none",
        plot.margin = margin(t = 1, r = 3.5, b = 4, l = 0, unit = "pt")
    ),
    neutro_locuszoom + theme(
        axis.title.y = element_blank(),
        legend.position = "none",
        plot.margin = margin(t = 0, r = 0, b = 4, l = 3.5, unit = "pt")
    ),
    gene_tracks + theme(
        plot.margin = margin(t = 1, r = 3.5, b = 0, l = 0, unit = "pt")
    ),
    gene_tracks + theme(
        plot.margin = margin(t = 1, r = 0, b = 0, l = 3.5, unit = "pt")
    ),
    ncol = 2
) +
    # The gene tracks get a bigger share than the Rmd's 0.3.
    plot_layout(heights = c(1, 1, 0.45)) +
    plot_layout(axes = "collect")

# locuszoomr's gg_scatter() and gg_genetracks() each apply a complete theme, so
# setting the family inside locus_plot() would be overwritten. patchwork's &
# reaches every subplot of the assembled figure instead.
final_plot <- final_plot & theme(text = element_text(family = FONT_BODY))

pdf_out <- file.path(figures_dir, "Fig2A_NLRP3_locuszoom.pdf")
ggsave(pdf_out, final_plot, width = 120, height = 102, units = "mm",
       device = cairo_pdf_font)

message("wrote ", pdf_out)
