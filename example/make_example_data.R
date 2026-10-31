# Regenerates the simulated example data in example/data/ (run from the repo root):
#   docker run --rm -v "$PWD:/work" -w /work nikostourvas/forest_popgen:0.4.15 \
#     Rscript example/make_example_data.R
#
# Genotypes are simulated with hierfstat::sim.genot() (island model), so the
# example data are synthetic and carry no third-party licence.
# The six populations exchange migrants equally (no regional hierarchy); the
# North/South regions are labels only, to show strata and group labels.

suppressPackageStartupMessages({
  library(hierfstat)
  library(adegenet)
  library(poppr)
})

set.seed(20261031)
n_per_pop <- 18
n_loci <- 10
pops <- data.frame(
  Region = rep(c("North", "South"), each = 3),
  Pop = c("Ala", "Bor", "Cer", "Dio", "Ela", "Fyl"),
  Latitude = c(41.10, 40.85, 41.35, 38.20, 37.90, 38.55),
  Longitude = c(22.40, 23.30, 24.10, 21.70, 22.60, 23.40)
)

# sim.genot codes a diploid genotype as two digits, one per allele (1-9)
sim <- sim.genot(
  size = n_per_pop, nbal = 9, nbloc = n_loci, nbpop = nrow(pops),
  N = 1000, mig = 0.002, mut = 1e-4
)

# Turn allele indices into microsatellite-like allele sizes (2 bp steps)
to_sizes <- function(g) {
  a1 <- 100 + 2 * (g %/% 10)
  a2 <- 100 + 2 * (g %% 10)
  paste(pmin(a1, a2), pmax(a1, a2), sep = "/")
}
geno <- as.data.frame(lapply(sim[-1], to_sizes))
names(geno) <- sprintf("SSR%02d", seq_len(n_loci))

# About 2% missing genotypes, as in real data
miss <- matrix(runif(nrow(geno) * n_loci) < 0.02, nrow(geno))
geno[miss] <- NA

p <- pops[sim$Pop, ]
obj <- df2genind(geno,
  sep = "/", ploidy = 2,
  ind.names = sprintf("%s_%02d", p$Pop, ave(sim$Pop, sim$Pop, FUN = seq_along)),
  pop = paste(p$Region, p$Pop, sep = "_")
)

dir.create("example/data", showWarnings = FALSE)
genind2genalex(obj, "example/data/simulated.csv", overwrite = TRUE, sep = ",")

# Same data as an Excel GenAlEx sheet, to show Excel input
raw <- utils::read.csv("example/data/simulated.csv", header = FALSE, colClasses = "character")
writexl::write_xlsx(raw, "example/data/simulated.xlsx", col_names = FALSE)

# Fictional sampling coordinates, for the pie-chart maps
utils::write.csv(pops[c("Pop", "Latitude", "Longitude")], "example/data/coords.csv", row.names = FALSE)

print(table(pop(obj)))
cat(nInd(obj), "individuals,", nLoc(obj), "loci,", sum(miss), "missing genotypes\n")
