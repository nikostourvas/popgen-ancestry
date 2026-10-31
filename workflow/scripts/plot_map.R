# Pie-chart map: mean ancestry per population at its coordinates.

source(file.path(snakemake@scriptdir, "lib", "common.R"))
log_to_snakemake(snakemake)
source_lib(snakemake, "palettes.R", "plotting.R")

suppressPackageStartupMessages({
  library(ggplot2)
  library(scatterpie)
})

m <- snakemake@params[["maps"]]
region <- snakemake@params[["region"]]
K <- as.integer(snakemake@wildcards[["K"]])

q <- read_q_table(snakemake@input[["q"]])
cl <- cluster_cols(q)
pop_col <- m$pop_column
if (!pop_col %in% names(q)) stop("maps.pop_column '", pop_col, "' is not a column of the Q table")

avg <- stats::aggregate(q[cl], by = list(.pop = q[[pop_col]]), FUN = mean)

coords <- utils::read.csv(snakemake@input[["coords"]], check.names = FALSE, colClasses = "character")
cc <- m$coords_columns
for (col in unlist(cc)) {
  if (!col %in% names(coords)) stop("maps.coords: column '", col, "' not found in ", snakemake@input[["coords"]])
}
coords <- data.frame(
  .pop = coords[[cc$pop]],
  .lon = as.numeric(coords[[cc$longitude]]),
  .lat = as.numeric(coords[[cc$latitude]])
)
df <- merge(avg, coords, by = ".pop", all.x = TRUE)
no_coords <- df$.pop[is.na(df$.lon) | is.na(df$.lat)]
if (length(no_coords) > 0) {
  warning("No coordinates for: ", paste(no_coords, collapse = ", "), " (not drawn)")
}
df <- df[!(df$.pop %in% no_coords), , drop = FALSE]
df$.r <- m$pie_radius

xlim <- unlist(region$xlim) %||% (range(df$.lon) + c(-2, 2))
ylim <- unlist(region$ylim) %||% (range(df$.lat) + c(-2, 2))

p <- ggplot() +
  borders("world", fill = "grey90", colour = "grey") +
  coord_fixed(xlim = xlim, ylim = ylim) + # 1:1 keeps the pies round
  geom_scatterpie(data = df, aes(x = .lon, y = .lat, r = .r), cols = cl) +
  scale_fill_manual(values = get_palette(snakemake@params[["palette"]], K)) +
  theme_bw() +
  theme(legend.position = "none") +
  labs(x = "Longitude", y = "Latitude", title = if (isTRUE(region$title)) paste0("K=", K))
if (isTRUE(region$labels %||% TRUE)) {
  p <- p + geom_text(data = df, aes(x = .lon, y = .lat, label = .pop), vjust = -2.1)
}

save_plot(p, unlist(snakemake@output),
  width = region$width %||% 7, height = region$height %||% 4,
  dpi = snakemake@params[["dpi"]] %||% 300
)
