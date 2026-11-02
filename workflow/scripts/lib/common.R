# Helpers shared by all pipeline scripts.

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

# Plots are always written with save_plot(); stop R from creating a stray
# Rplots.pdf in the pipeline folder when a package opens a default device.
options(device = function(...) grDevices::pdf(file = NULL))

# Send output, messages and warnings of a Snakemake R script to its log file.
log_to_snakemake <- function(sm) {
  if (length(sm@log) == 0) {
    return(invisible(NULL))
  }
  con <- file(sm@log[[1]], open = "wt")
  sink(con, type = "output")
  sink(con, type = "message")
  options(warn = 1) # print warnings as they happen, so they end up in the log
  invisible(con)
}

# Source the other files of lib/ relative to the running script.
source_lib <- function(sm, ...) {
  for (f in c(...)) {
    source(file.path(sm@scriptdir, "lib", f))
  }
}

# Column names holding ancestry proportions in the Q tables.
cluster_cols <- function(df) {
  grep("^Cluster[0-9]+$", names(df), value = TRUE)
}

# na.strings = "" keeps a literal "NA" label (e.g. Country of cultivars) as text.
read_samples <- function(path) {
  utils::read.delim(path, colClasses = "character", check.names = FALSE, na.strings = "") |>
    transform(index = as.integer(index), pop_id = as.integer(pop_id))
}

# Everything is read as text first so sample names such as "007" keep their
# leading zeros; index and cluster columns are then converted to numbers.
read_q_table <- function(path) {
  q <- utils::read.csv(path, check.names = FALSE, colClasses = "character", na.strings = "")
  q$index <- as.integer(q$index)
  for (col in cluster_cols(q)) q[[col]] <- as.numeric(q[[col]])
  q[order(q$index), , drop = FALSE]
}
