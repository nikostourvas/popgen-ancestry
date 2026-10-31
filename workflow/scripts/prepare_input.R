# Genotype file -> STRUCTURE input (data.str), sample table, CLUMPAK
# population labels and a small summary used to write mainparams.

source(file.path(snakemake@scriptdir, "lib", "common.R"))
log_to_snakemake(snakemake)
source_lib(snakemake, "inputs.R")

suppressPackageStartupMessages({
  library(adegenet)
  library(poppr)
  library(hierfstat)
})

cfg <- snakemake@params[["input_cfg"]]

obj <- read_input(cfg)
input_format <- attr(obj, "input_format")
obj <- prepare_genind(obj, cfg)
pop_level <- attr(obj, "pop_level")

n <- nInd(obj)
pop_id <- as.integer(pop(obj))

# STRUCTURE input: two rows per individual, column 1 = running index (the real
# names live in samples.tsv), column 2 = population number, missing = -9.
hierfstat::write.struct(genind2hierfstat(obj),
  ilab = seq_len(n),
  pop = pop_id,
  fname = snakemake@output[["str"]]
)

samples <- data.frame(
  index = seq_len(n),
  sample = indNames(obj),
  pop_id = pop_id,
  as.data.frame(lapply(strata(obj), as.character), check.names = FALSE),
  check.names = FALSE
)
utils::write.table(samples, snakemake@output[["samples"]],
  sep = "\t", quote = FALSE, row.names = FALSE
)

# CLUMPAK --labels: "<pop number> <pop name>", no spaces inside names.
labels <- gsub("\\s+", "_", levels(pop(obj)))
writeLines(paste(seq_along(labels), labels), snakemake@output[["popnames"]])

missing_pct <- round(100 * mean(is.na(tab(obj))), 2)
summary <- list(
  input_file = cfg$file,
  input_format = input_format,
  pop_level = pop_level,
  strata = names(strata(obj)),
  n_individuals = n,
  n_loci = nLoc(obj),
  n_populations = nlevels(pop(obj)),
  ploidy = 2L,
  missing_data_percent = missing_pct,
  loci = locNames(obj),
  individuals_per_population = as.list(table(pop(obj)))
)
yaml::write_yaml(summary, snakemake@output[["summary"]])
message("Wrote STRUCTURE input with ", n, " individuals and ", nLoc(obj), " loci.")
