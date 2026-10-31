# Readers for CLUMPAK output.

clumpp_major_file <- function(dir, K) {
  file.path(dir, paste0("K=", K), "MajorCluster", "CLUMPP.files", "ClumppIndFile.output")
}

# ClumppIndFile.output lines look like
#   "  1    1  (11)    1  : 0.0135 0.0074 ..."
# (index, label, % missing, population, ':', Q values). Splitting on ':'
# keeps K=1 (a single Q column) as a proper table.
read_clumpp_indfile <- function(path, K) {
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(trimws(lines))]
  parts <- strsplit(lines, ":", fixed = TRUE)
  left <- trimws(vapply(parts, `[`, "", 1))
  right <- trimws(vapply(parts, `[`, "", 2))
  index <- as.integer(sub("^([0-9]+).*", "\\1", left))
  q <- do.call(rbind, lapply(strsplit(right, "\\s+"), as.numeric))
  if (ncol(q) != K) stop(path, ": expected ", K, " Q columns, found ", ncol(q))
  colnames(q) <- paste0("Cluster", seq_len(K))
  data.frame(index = index, q, check.names = FALSE)
}

# detectedModesSummery.log (sic) has a "K=<k>" line followed by one line per
# mode, e.g. "12/20    LnProb mean: -21207.092    Mean similarity score: 0.997".
# The first mode of each K is the major mode.
read_clumpak_modes <- function(dir) {
  lines <- trimws(readLines(file.path(dir, "detectedModesSummery.log"), warn = FALSE))
  lines <- lines[nzchar(lines)]
  k_line <- grepl("^K=[0-9]+", lines)
  K <- as.integer(sub("^K=([0-9]+).*", "\\1", lines[k_line]))[cumsum(k_line)]
  keep <- grepl("^[0-9]+/[0-9]+", lines)
  lines <- lines[keep]
  K <- K[keep]
  runs <- regmatches(lines, regexpr("^[0-9]+/[0-9]+", lines))
  mode_no <- stats::ave(seq_along(K), K, FUN = seq_along)
  data.frame(
    K = K,
    mode = ifelse(mode_no == 1, "Major", paste0("Minor", mode_no - 1)),
    n_runs = as.integer(sub("/.*", "", runs)),
    total_runs = as.integer(sub(".*/", "", runs)),
    lnprob_mean = as.numeric(sub(".*LnProb mean:\\s*(-?[0-9.eE+-]+).*", "\\1", lines)),
    mean_similarity = as.numeric(sub(".*similarity score:\\s*([0-9.eE+-]+).*", "\\1", lines))
  )
}
