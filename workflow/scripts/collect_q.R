# Gather the CLUMPAK major-mode Q matrices of every K into tidy tables that
# keep the real sample names and strata, plus a summary of the modes.

source(file.path(snakemake@scriptdir, "lib", "common.R"))
log_to_snakemake(snakemake)
source_lib(snakemake, "qmatrix.R")

samples <- read_samples(snakemake@input[["samples"]])
clumpak_dir <- snakemake@input[["clumpak"]]
ks <- as.integer(unlist(snakemake@params[["ks"]]))
wide_files <- unlist(snakemake@output[["wide"]])

wide <- list()
for (i in seq_along(ks)) {
  K <- ks[i]
  q <- read_clumpp_indfile(clumpp_major_file(clumpak_dir, K), K)
  if (nrow(q) != nrow(samples)) {
    stop("K=", K, ": CLUMPAK returned ", nrow(q), " individuals, expected ", nrow(samples))
  }
  q <- merge(samples, q, by = "index", sort = FALSE)
  q <- q[order(q$index), , drop = FALSE]
  q$pop_id <- NULL
  utils::write.csv(q, wide_files[i], row.names = FALSE)
  wide[[paste0("K", K)]] <- q
}

long <- do.call(rbind, lapply(names(wide), function(nm) {
  q <- wide[[nm]]
  cl <- cluster_cols(q)
  meta <- q[setdiff(names(q), cl)]
  data.frame(
    K = length(cl),
    meta[rep(seq_len(nrow(q)), times = length(cl)), , drop = FALSE],
    cluster = rep(cl, each = nrow(q)),
    q = unlist(q[cl], use.names = FALSE),
    check.names = FALSE, row.names = NULL
  )
}))
utils::write.table(long, snakemake@output[["long"]], sep = "\t", quote = FALSE, row.names = FALSE)

modes <- read_clumpak_modes(clumpak_dir)
utils::write.table(modes, snakemake@output[["modes"]], sep = "\t", quote = FALSE, row.names = FALSE)
print(modes)

writexl::write_xlsx(c(wide, list(modes = modes)), snakemake@output[["xlsx"]])
