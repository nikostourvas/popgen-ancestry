# Write STRUCTURE's mainparams and extraparams from the config and the data.
# K, the input/output files and the seed are given on the command line of each
# run, so one pair of files serves every (K, replicate).

source(file.path(snakemake@scriptdir, "lib", "common.R"))
log_to_snakemake(snakemake)

summary <- yaml::read_yaml(snakemake@input[["summary"]])
p <- snakemake@params
model <- p[["model"]]
b <- function(x) as.integer(isTRUE(x))

total_iter <- p[["burnin"]] + p[["numreps"]]

mainparams <- list(
  MAXPOPS = 2, # overridden by -K on the command line
  BURNIN = p[["burnin"]],
  NUMREPS = p[["numreps"]],
  INFILE = "data.str", # overridden by -i
  OUTFILE = "out", # overridden by -o
  NUMINDS = summary$n_individuals,
  NUMLOCI = summary$n_loci,
  PLOIDY = summary$ploidy,
  MISSING = -9,
  ONEROWPERIND = 0,
  LABEL = 1,
  POPDATA = 1,
  POPFLAG = 0,
  LOCDATA = 0,
  PHENOTYPE = 0,
  EXTRACOLS = 0,
  MARKERNAMES = 0,
  RECESSIVEALLELES = 0,
  MAPDISTANCES = 0,
  PHASED = 0,
  PHASEINFO = 0,
  MARKOVPHASE = 0,
  NOTAMBIGUOUS = -999
)

extraparams <- list(
  NOADMIX = 1L - b(model$admixture),
  LINKAGE = 0,
  USEPOPINFO = 0,
  LOCPRIOR = b(model$locprior),
  FREQSCORR = b(model$freqscorr),
  ONEFST = 0,
  INFERALPHA = b(model$inferalpha),
  POPALPHAS = 0,
  ALPHA = model$alpha,
  INFERLAMBDA = b(model$inferlambda),
  POPSPECIFICLAMBDA = 0,
  LAMBDA = model$lambda,
  FPRIORMEAN = 0.01,
  FPRIORSD = 0.05,
  UNIFPRIORALPHA = 1,
  ALPHAMAX = 10.0,
  ALPHAPRIORA = 1.0,
  ALPHAPRIORB = 2.0,
  LOG10RMIN = -4.0,
  LOG10RMAX = 1.0,
  LOG10RPROPSD = 0.1,
  LOG10RSTART = -2.0,
  GENSBACK = 2,
  MIGRPRIOR = 0.01,
  PFROMPOPFLAGONLY = 0,
  LOCISPOP = 1, # LOCPRIOR uses the population column
  LOCPRIORINIT = 1.0,
  MAXLOCPRIOR = 20.0,
  PRINTNET = 1,
  PRINTLAMBDA = 1,
  PRINTQSUM = 1,
  SITEBYSITE = 0,
  PRINTQHAT = 0,
  # about 100 progress lines per run keeps the logs small
  UPDATEFREQ = max(100, round(total_iter / 100)),
  PRINTLIKES = 0,
  INTERMEDSAVE = 0,
  ECHODATA = 0,
  ANCESTDIST = 0,
  NUMBOXES = 1000,
  ANCESTPINT = 0.90,
  COMPUTEPROB = 1,
  ADMBURNIN = 500,
  ALPHAPROPSD = 0.025,
  STARTATPOPINFO = 0,
  RANDOMIZE = 0, # seeds come from the pipeline (-D), see the run logs
  SEED = 0,
  METROFREQ = 10,
  REPORTHITRATE = 0
)

# Advanced: any STRUCTURE setting can be added or overridden from the config.
apply_extra <- function(params, extra, what) {
  if (length(extra) == 0) {
    return(params)
  }
  names(extra) <- toupper(names(extra))
  for (key in names(extra)) {
    message(what, ": ", key, " = ", extra[[key]], " (from config)")
    params[[key]] <- extra[[key]]
  }
  params
}
mainparams <- apply_extra(mainparams, p[["mainparams_extra"]], "mainparams")
extraparams <- apply_extra(extraparams, p[["extraparams_extra"]], "extraparams")

write_defines <- function(params, file, header) {
  lines <- c(
    paste("//", header),
    "// Written by popgen-ancestry from the config file. Do not edit:",
    "// change the config and re-run the pipeline instead.",
    "",
    sprintf("#define %-18s %s", names(params), vapply(params, format, "", scientific = FALSE))
  )
  writeLines(lines, file)
}
write_defines(mainparams, snakemake@output[["main"]], "STRUCTURE mainparams")
write_defines(extraparams, snakemake@output[["extra"]], "STRUCTURE extraparams")

message(
  "NUMINDS=", mainparams$NUMINDS, " NUMLOCI=", mainparams$NUMLOCI,
  " BURNIN=", mainparams$BURNIN, " NUMREPS=", mainparams$NUMREPS
)
