# One figure with a barplot per K, stacked from k_from to k_to.

source(file.path(snakemake@scriptdir, "lib", "common.R"))
log_to_snakemake(snakemake)
source_lib(snakemake, "palettes.R", "plotting.R")

common <- snakemake@params[["common"]]
opts <- snakemake@params[["opts"]]
k_from <- as.integer(snakemake@wildcards[["k_from"]])
k_to <- as.integer(snakemake@wildcards[["k_to"]])

samples <- read_samples(snakemake@input[["samples"]])
qlist <- lapply(unlist(snakemake@input[["q"]]), read_q_table)
names(qlist) <- paste0("K=", vapply(qlist, function(q) length(cluster_cols(q)), 1L))
stopifnot(identical(names(qlist), paste0("K=", k_from:k_to)))

p <- plot_q(qlist, samples, common, opts, joined = TRUE)
n_k <- length(qlist)
save_plot(p, unlist(snakemake@output),
  width = opts$width %||% 10,
  height = opts$height %||% (3 + n_k), # 10 inches for K=2..8, as before
  dpi = common$dpi %||% 300
)
