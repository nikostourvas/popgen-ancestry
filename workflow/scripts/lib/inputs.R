# Input readers.
#
# Every reader takes (path, cfg) and returns a genind object whose population
# (pop) holds the full population label of the input file, e.g.
# "Wild_arm_ARM". prepare_genind() then splits it into strata and filters.
#
# To support a new format (e.g. VCF): write read_<format>(path, cfg), add it to
# INPUT_READERS, add the format name to the schema enum, and (optionally) map a
# file extension to it in detect_format().

read_genalex_csv <- function(path, cfg) {
  sep <- cfg$sep %||% "auto"
  if (identical(sep, "auto")) sep <- detect_sep(path)
  message("Reading GenAlEx CSV '", path, "' (separator '", sep, "')")
  poppr::read.genalex(path, genclone = FALSE, sep = sep)
}

# GenAlEx sheets saved as .xlsx: read the sheet as text and hand it to the CSV
# reader, so both formats follow exactly the same rules.
read_genalex_xlsx <- function(path, cfg) {
  sheet <- cfg$sheet %||% 1
  message("Reading GenAlEx Excel file '", path, "' (sheet ", sheet, ")")
  raw <- readxl::read_excel(path,
    sheet = sheet, col_names = FALSE,
    col_types = "text", .name_repair = "minimal"
  )
  raw <- as.data.frame(raw)
  raw[is.na(raw)] <- ""
  header <- suppressWarnings(as.integer(unlist(raw[1, 1:3])))
  if (anyNA(header)) {
    stop(
      "Sheet '", sheet, "' of ", path, " does not look like a GenAlEx sheet ",
      "(the first row must hold the number of loci, samples and populations). ",
      "Set input.sheet to the right sheet. Sheets in this file: ",
      paste(readxl::excel_sheets(path), collapse = ", ")
    )
  }
  if (any(grepl(",", as.matrix(raw), fixed = TRUE))) {
    stop("Cells of ", path, " contain commas; remove them (e.g. from sample or population names).")
  }
  # poppr::read.genalex() does not accept quoted cells in the header rows
  tmp <- tempfile(fileext = ".csv")
  utils::write.table(raw, tmp,
    sep = ",", row.names = FALSE, col.names = FALSE,
    quote = FALSE, na = ""
  )
  read_genalex_csv(tmp, utils::modifyList(cfg, list(sep = ",")))
}

INPUT_READERS <- list(
  genalex_csv = read_genalex_csv,
  genalex_xlsx = read_genalex_xlsx
)

detect_format <- function(path) {
  ext <- tolower(sub(".*\\.", "", basename(path)))
  switch(ext,
    csv = ,
    txt = "genalex_csv",
    xlsx = ,
    xls = "genalex_xlsx",
    stop(
      "Cannot guess the input format from the extension '.", ext,
      "'. Set input.format in the config (one of: ",
      paste(names(INPUT_READERS), collapse = ", "), ")."
    )
  )
}

# Excel in many European locales saves "CSV" with ';' as the separator.
detect_sep <- function(path) {
  first <- readLines(path, n = 3, warn = FALSE)
  n_comma <- sum(lengths(regmatches(first, gregexpr(",", first))))
  n_semi <- sum(lengths(regmatches(first, gregexpr(";", first))))
  if (n_semi > n_comma) ";" else ","
}

read_input <- function(cfg) {
  format <- cfg$format %||% "auto"
  if (identical(format, "auto")) format <- detect_format(cfg$file)
  reader <- INPUT_READERS[[format]]
  if (is.null(reader)) {
    stop(
      "Input format '", format, "' is not supported yet. Supported: ",
      paste(names(INPUT_READERS), collapse = ", ")
    )
  }
  obj <- reader(cfg$file, cfg)
  attr(obj, "input_format") <- format
  obj
}

# Split the population label into strata, choose the population level used by
# STRUCTURE (POPDATA column) and apply the keep/exclude filters.
prepare_genind <- function(obj, cfg) {
  if (!all(adegenet::ploidy(obj) == 2)) {
    stop("Only diploid data are supported at the moment.")
  }

  if (!is.null(cfg$strata) && nzchar(cfg$strata)) {
    adegenet::strata(obj) <- data.frame(.label = as.character(adegenet::pop(obj)))
    adegenet::splitStrata(obj, sep = cfg$strata_sep %||% "_") <-
      stats::as.formula(paste0("~", cfg$strata))
  } else {
    adegenet::strata(obj) <- data.frame(Pop = as.character(adegenet::pop(obj)))
  }
  strata_df <- adegenet::strata(obj)
  pop_level <- cfg$pop_level %||% names(strata_df)[1]
  if (!pop_level %in% names(strata_df)) {
    stop(
      "input.pop_level '", pop_level, "' is not one of the strata: ",
      paste(names(strata_df), collapse = ", ")
    )
  }
  adegenet::setPop(obj) <- stats::as.formula(paste0("~", pop_level))

  n_start <- adegenet::nInd(obj)
  pops <- as.character(adegenet::pop(obj))
  keep <- rep(TRUE, length(pops))
  if (length(cfg$keep_pops) > 0) {
    missing <- setdiff(cfg$keep_pops, pops)
    if (length(missing) > 0) warning("keep_pops not found in data: ", paste(missing, collapse = ", "))
    keep <- keep & pops %in% cfg$keep_pops
  }
  if (length(cfg$exclude_pops) > 0) {
    missing <- setdiff(cfg$exclude_pops, pops)
    if (length(missing) > 0) warning("exclude_pops not found in data: ", paste(missing, collapse = ", "))
    keep <- keep & !pops %in% cfg$exclude_pops
  }
  if (length(cfg$exclude_samples) > 0) {
    missing <- setdiff(cfg$exclude_samples, adegenet::indNames(obj))
    if (length(missing) > 0) warning("exclude_samples not found in data: ", paste(missing, collapse = ", "))
    keep <- keep & !adegenet::indNames(obj) %in% cfg$exclude_samples
  }
  obj <- obj[keep, , drop = TRUE]
  adegenet::pop(obj) <- droplevels(adegenet::pop(obj))
  message(
    "Kept ", adegenet::nInd(obj), " of ", n_start, " individuals in ",
    nlevels(adegenet::pop(obj)), " populations (", pop_level, "), ",
    adegenet::nLoc(obj), " loci."
  )
  attr(obj, "pop_level") <- pop_level
  obj
}
