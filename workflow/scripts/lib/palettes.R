# Named colour palettes for cluster colours. Add new ones here and refer to
# them by name in the config (plots.palette), or give a list of hex colours.

PALETTES <- list(
  # Wong (2011) colour-blind safe + grey, as used for FRUITDIV
  wong = c(
    "#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442",
    "#006699", "#D55E00", "#CC79A7", "grey50"
  ),
  cb_paired = c(
    "#A6CEE3", "#1F78B4", "#B2DF8A", "#33A02C", "#FB9A99", "#E31A1C",
    "#FDBF6F", "#FF7F00", "#CAB2D6", "#6A3D9A", "#FFFF99", "#B15928"
  ),
  cb_set3 = c(
    "#8DD3C7", "#FFFFB3", "#BEBADA", "#FB8072", "#80B1D3", "#FDB462",
    "#B3DE69", "#FCCDE5", "#D9D9D9", "#BC80BD", "#CCEBC5", "#FFED6F"
  ),
  krzywinski = c(
    "#006E82", "#8214A0", "#005AC8", "#00A0FA", "#FA78FA", "#14D2DC",
    "#AA0A3C", "#FA7850", "#0AB45A", "#F0F032", "#A0FA82", "#FAE6BE"
  ),
  kr12 = c(
    "#9F0162", "#009F81", "#FF5AAF", "#00FCCF", "#8400CD", "#008DF9",
    "#00C2F9", "#FFB2FD", "#A40122", "#E20134", "#FF6E3A", "#FFC33B"
  ),
  # from the FRUITDIV WGRS ADMIXTURE notebooks
  xlstat = c(
    "#7a81ff", "#00fe0a", "#7030a0", "#0070c0", "#00b050", "#03f2fc", "#f905ab",
    "#92d050", "#945200", "#ff0000", "#262626", "#c00000", "#ffc000"
  ),
  cb_paired_wgrs = c(
    "#B1DF8A", "#33A02C", "#A6CEE3", "#1F78B4", "#FB9A99", "#E31A1C",
    "#CAB2D6", "#6A3D9A", "#FDBF6F", "#FF7F00", "grey50", "#B15928", "black"
  ),
  shiny = c(
    "#1D72F5", "#DF0101", "#77CE61", "#FF9326", "#A945FF", "#0089B2",
    "#FDF060", "#FFA6B2", "#BFF217", "#60D5FD", "#CC1577", "#F2B950",
    "#7FB21D", "#EC496F", "#326397", "#B26314", "#027368", "#A4A4A4", "#610B5E"
  )
)

# Return k colours. Unknown names fail with the list of known palettes; short
# palettes are extended with extra colours (with a warning) so large K works.
get_palette <- function(spec, k) {
  if (is.character(spec) && length(spec) == 1 && !grepl("^#", spec)) {
    cols <- PALETTES[[spec]]
    if (is.null(cols)) {
      stop(
        "Unknown palette '", spec, "'. Choose one of: ",
        paste(names(PALETTES), collapse = ", "), " or give a list of colours."
      )
    }
  } else {
    cols <- unlist(spec)
  }
  if (length(cols) < k) {
    warning(
      "Palette has ", length(cols), " colours but K = ", k,
      "; adding ", k - length(cols), " extra colours."
    )
    cols <- c(cols, grDevices::hcl.colors(k - length(cols), "Dark 3"))
  }
  cols[seq_len(k)]
}
