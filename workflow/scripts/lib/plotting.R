# Ancestry barplots.
#
# plot_q() is the single entry point used by the pipeline. It dispatches on
# plots.engine; only "pophelper" exists for now (the plots used for FRUITDIV).
# To add an engine (e.g. a ggplot2 facet plot): write plot_q_<engine>() with
# the same arguments, returning a grob or ggplot, and register it in
# PLOT_ENGINES.
#
# Arguments shared by all engines:
#   qlist   named list of Q tables (one per K, rows in sample order), each with
#           columns Cluster1..ClusterK
#   samples sample table (index, sample, pop_id, strata columns)
#   common  plots.* settings shared by all plots (palette, group_labels, ...)
#   opts    settings of this plot type (plots.single_k or plots.k_range)
#   joined  TRUE for the multi-K figure

plot_q <- function(qlist, samples, common, opts, joined) {
  engine <- common$engine %||% "pophelper"
  fun <- PLOT_ENGINES[[engine]]
  if (is.null(fun)) {
    stop(
      "Unknown plots.engine '", engine, "'. Available: ",
      paste(names(PLOT_ENGINES), collapse = ", ")
    )
  }
  fun(qlist, samples, common, opts, joined)
}

plot_q_pophelper <- function(qlist, samples, common, opts, joined) {
  max_k <- max(vapply(qlist, function(q) length(cluster_cols(q)), 1L))
  ql <- lapply(qlist, function(q) {
    df <- as.data.frame(q[, cluster_cols(q), drop = FALSE])
    rownames(df) <- q$sample
    df
  })
  ql <- pophelper::as.qlist(ql)

  # Defaults reproduce the plotQ() calls of the FRUITDIV STRUCTURE notebook.
  if (joined) {
    args <- list(
      imgoutput = "join", basesize = 20,
      splabsize = 11, splabangle = 90,
      showyaxis = FALSE, showticks = FALSE, ticksize = 0.3, ticklength = 0.2,
      grplabsize = 3.5, linesize = 0.8, pointsize = 4, grplabangle = 90,
      grplabjust = 0.3, grplabpos = 0.1, divsize = 0.5,
      panelratio = c(3, 2)
    )
  } else {
    args <- list(
      basesize = 11, splabsize = 11, splabangle = 90,
      divsize = 0.5, grplabsize = 3.5, linesize = 0.8, pointsize = 3,
      grplabangle = 90, grplabjust = 0.45,
      panelratio = c(5, 2.5)
    )
  }
  args$qlist <- ql
  args$returnplot <- TRUE
  args$exportplot <- FALSE
  args$splab <- names(qlist)
  args$clustercol <- get_palette(common$palette, max_k)

  show_names <- isTRUE(common$show_sample_names)
  args$showindlab <- show_names
  args$useindlab <- show_names
  if (show_names) args$indlabsize <- 2.5

  sortind <- opts$sort_individuals %||% "none"
  if (!identical(sortind, "none")) args$sortind <- sortind

  groups <- unlist(common$group_labels)
  if (length(groups) > 0) {
    missing <- setdiff(groups, names(samples))
    if (length(missing) > 0) {
      stop(
        "plots.group_labels: column(s) ", paste(missing, collapse = ", "),
        " not found. Available: ", paste(setdiff(names(samples), c("index", "pop_id")), collapse = ", ")
      )
    }
    args$grplab <- as.data.frame(lapply(samples[groups], as.character), check.names = FALSE)
    args$ordergrp <- TRUE
    args$selgrp <- common$order_by %||% groups[1]
    if (!is.null(opts$divide_by)) args$divgrp <- opts$divide_by
    if (length(common$group_order) > 0) args$subsetgrp <- unlist(common$group_order)
  }

  # Anything else pophelper::plotQ() accepts can be set in the config.
  if (length(opts$extra_args) > 0) args <- utils::modifyList(args, opts$extra_args)

  p <- do.call(pophelper::plotQ, args)
  p$plot[[1]]
}

PLOT_ENGINES <- list(
  pophelper = plot_q_pophelper
)

# Write one plot to every requested file; the format comes from the extension.
save_plot <- function(plot, files, width, height, dpi = 300) {
  for (f in files) {
    ext <- tolower(tools::file_ext(f))
    switch(ext,
      pdf = grDevices::pdf(f, width = width, height = height, useDingbats = FALSE),
      png = grDevices::png(f, width = width, height = height, units = "in", res = dpi, type = "cairo"),
      tiff = grDevices::tiff(f, width = width, height = height, units = "in", res = dpi, type = "cairo", compression = "lzw"),
      svg = grDevices::svg(f, width = width, height = height),
      stop("Unsupported plot format: ", ext)
    )
    if (inherits(plot, "ggplot")) {
      print(plot)
    } else {
      grid::grid.newpage()
      grid::grid.draw(plot)
    }
    grDevices::dev.off()
  }
  invisible(files)
}
