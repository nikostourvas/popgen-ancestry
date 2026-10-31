# Mean ln P(D) per K and the Evanno et al. (2005) delta K, using pophelper
# (same as the original FRUITDIV notebook).

source(file.path(snakemake@scriptdir, "lib", "common.R"))
log_to_snakemake(snakemake)
source_lib(snakemake, "plotting.R")

suppressPackageStartupMessages(library(pophelper))

files <- unlist(snakemake@input)
slist <- readQ(files = files)
tab <- tabulateQ(slist)
sr <- summariseQ(tab)
utils::write.table(sr, snakemake@output[["lnprob"]], sep = "\t", quote = FALSE, row.names = FALSE)

res <- tryCatch(
  evannoMethodStructure(
    data = sr, exportplot = FALSE, returnplot = TRUE, returndata = TRUE,
    basesize = 12, linesize = 0.7
  ),
  error = function(e) e
)

out_plots <- unlist(snakemake@output[["plot"]])
if (inherits(res, "error")) {
  msg <- paste(
    "Evanno method not possible with these runs:", conditionMessage(res),
    "(it needs at least 3 consecutive K values, K starting at 1 is",
    "recommended, and more than one replicate per K)."
  )
  warning(msg)
  utils::write.table(data.frame(note = msg), snakemake@output[["table"]],
    sep = "\t", quote = FALSE, row.names = FALSE
  )
  grob <- grid::textGrob(paste(strwrap(msg, 70), collapse = "\n"))
} else {
  utils::write.table(res$data, snakemake@output[["table"]],
    sep = "\t", quote = FALSE, row.names = FALSE
  )
  grob <- res$plot
  best <- res$data$k[which.max(res$data$deltaK)]
  message("Highest delta K at K = ", best)
}
save_plot(grob, out_plots, width = 10, height = 7, dpi = 300)
