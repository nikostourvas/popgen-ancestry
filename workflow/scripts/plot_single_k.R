# Barplot of one K (CLUMPAK major mode).

source(file.path(snakemake@scriptdir, "lib", "common.R"))
log_to_snakemake(snakemake)
source_lib(snakemake, "palettes.R", "plotting.R")

common <- snakemake@params[["common"]]
opts <- snakemake@params[["opts"]]
K <- as.integer(snakemake@wildcards[["K"]])

samples <- read_samples(snakemake@input[["samples"]])
q <- read_q_table(snakemake@input[["q"]])
qlist <- stats::setNames(list(q), paste0("K=", K))

p <- plot_q(qlist, samples, common, opts, joined = FALSE)
save_plot(p, unlist(snakemake@output),
  width = opts$width %||% 10, height = opts$height %||% 5,
  dpi = common$dpi %||% 300
)
