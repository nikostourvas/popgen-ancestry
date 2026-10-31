# Render the HTML summary report (workflow/report/report.Rmd).

source(file.path(snakemake@scriptdir, "lib", "common.R"))
log_to_snakemake(snakemake)

out <- normalizePath(snakemake@output[[1]], mustWork = FALSE)
work <- tempfile("report_")
dir.create(work)

inputs <- snakemake@input
paths <- function(x) normalizePath(unlist(x), mustWork = TRUE)

# Resolve paths now: render() changes the working directory.
report_params <- list(
  config = snakemake@params[["config"]],
  summary = paths(inputs[["summary"]]),
  samples = paths(inputs[["samples"]]),
  mainparams = paths(inputs[["main"]]),
  extraparams = paths(inputs[["extra"]]),
  evanno = paths(inputs[["evanno"]]),
  lnprob = paths(inputs[["lnprob"]]),
  evanno_plots = paths(inputs[["evanno_plots"]]),
  modes = paths(inputs[["modes"]]),
  plots = if (length(inputs[["plots"]]) > 0) paths(inputs[["plots"]]) else character(0)
)

rmarkdown::render(
  input = paths(inputs[["rmd"]]),
  output_file = basename(out),
  output_dir = dirname(out),
  intermediates_dir = work,
  knit_root_dir = getwd(),
  envir = new.env(),
  quiet = TRUE,
  params = report_params
)
