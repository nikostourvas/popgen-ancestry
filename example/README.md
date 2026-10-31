# Example: simulated data

A small, ready-to-run dataset to see what the pipeline does before you use your own data. No editing needed.

## Run it

From the pipeline folder (see the main [README](../README.md) for installing Docker and the image):

```
.\run.bat --configfile example/config.yaml --cores 4      # Windows
./run.sh  --configfile example/config.yaml --cores 4      # Linux / macOS
```

It does 40 STRUCTURE runs (K = 1–8, 5 runs each), then CLUMPAK, the plots and the report. On 4 cores this takes about 3 minutes on a desktop, and a few minutes more on a laptop. When it finishes, open `results/example/report.html`.

## The data

| File | Content |
|---|---|
| `data/simulated.csv` | GenAlEx file: 108 diploid samples, 10 microsatellite loci, about 2% missing genotypes |
| `data/simulated.xlsx` | The same data as an Excel file |
| `data/coords.csv` | Fictional coordinates of the 6 populations, for the maps |
| `config.yaml` | The configuration used for this example, with comments |
| `config_xlsx.yaml` | Runs the same example from the Excel file: `--configfile example/config.yaml example/config_xlsx.yaml` |
| `make_example_data.R` | The script that simulated the data |

The genotypes were simulated with `hierfstat::sim.genot()`. There are 6 populations of 18 samples (Ala, Bor, Cer, Dio, Ela, Fyl) that exchange migrants at the same rate (island model), so **the true number of clusters is 6**.

Population labels have two levels, e.g. `North_Ala` = Region_Pop. The config names them with `strata: Region/Pop`. Region is only a label here: the simulation has no regional structure.

## What to look at in the report

- **Choosing K:** the mean ln P(D) rises up to K = 6 and drops after it. Evanno's ΔK, however, peaks at K = 3. ΔK is a rule of thumb that often misses the true K, so never choose K from ΔK alone (see Janes et al. 2017, *Mol Ecol* 26:3594). Compare it with ln P(D), the CLUMPAK modes and the barplots.
- **CLUMPAK modes:** at K = 6, all 5 runs fall in one mode with high similarity (0.97). At K = 4 the runs split into two modes, i.e. they found two different solutions.
- **Barplots:** at K = 6 each population gets its own colour. At K = 7 and 8 no population gets a new colour of its own; the extra clusters are only mixed into many samples, a typical sign that K is too high. Colours stay the same across K because CLUMPAK aligns all K together.
- **Maps:** mean ancestry per population at K = 6, for the whole area and zoomed in on the north.

The run seeds are fixed, so you should see the same numbers.

## Try a change

Open `example/config.yaml` and change `k: [2, 6]` under `single_k` to `k: [2, 3, 6]`. Run the same command again. Only the single-K barplots and the report are redrawn, in seconds; STRUCTURE and CLUMPAK are not run again.

These settings are for a quick demonstration only. For real data use much longer runs (`burnin` and `numreps` of 100000 or more) and usually 10–20 replicates.
