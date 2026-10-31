# popgen-ancestry

A config-driven pipeline for population ancestry analyses. It currently runs [STRUCTURE](https://web.stanford.edu/group/pritchardlab/structure.html) for a range of K with replicate runs and summarises them with [CLUMPAK](https://clumpak.tau.ac.il/). It then draws barplots (single K and K ranges), the Evanno ΔK plot, optional pie-chart maps and an HTML report.

Support for ADMIXTURE is planned.

**You only edit a configuration file.** Everything runs inside the `forest_popgen` Docker image, so the same pipeline works on a Windows laptop, a Linux workstation and an HPC cluster.

The pipeline only *runs* STRUCTURE and CLUMPAK and reads their output. Evanno's ΔK and the barplots come from [pophelper](https://github.com/royfrancis/pophelper). The workflow is managed by [Snakemake](https://snakemake.readthedocs.io).

---

## Quick start (Windows laptop)

1. **Install Docker Desktop** (https://www.docker.com/products/docker-desktop/) with the WSL 2 backend and start it.
   - In *Settings → Resources*, give Docker most of your CPU cores and at least 4 GB RAM.
2. **Download the image** once. Open *PowerShell* and type:
   ```
   docker pull nikostourvas/forest_popgen:0.4.15
   ```
   Older images (0.4.13 and earlier) cannot run STRUCTURE.
3. **Get the pipeline:** `git clone https://github.com/nikostourvas/popgen-ancestry.git`, or on GitHub click *Code → Download ZIP* and extract it, e.g. to `C:\Users\<you>\popgen-ancestry`.
4. **Add your data:** copy your GenAlEx file (`.csv` or `.xlsx`) into the `data\` folder.
5. **Make your config:** copy `config\config.yaml` to e.g. `config\my_project.yaml` and edit the copy. Every option is explained in the file. Usually you change:
   - `project`: a short name; results go to `results\<project>\`
   - `input.file`, `input.strata`, `input.pop_level`
   - `structure.k_max`, `replicates`, `burnin`, `numreps`
   - `plots.single_k.k` and `plots.k_range.ranges`
6. **Open a terminal in the pipeline folder:** in Explorer, right-click the folder and choose *Open in Terminal*.
7. **Check the plan (dry run).** This lists every step without running anything:
   ```
   .\run.bat --configfile config/my_project.yaml -n
   ```
8. **Run:**
   ```
   .\run.bat --configfile config/my_project.yaml --cores 6
   ```
   Snakemake prints `x of y steps done`. When it finishes, open `results\<project>\report.html`.

**Tip:** do a quick test first, with `burnin: 10000` and `numreps: 10000` in your config and a different `project` name. Then switch to the real run lengths.

## Quick start (Linux / macOS)

Same steps, but use `./run.sh` instead of `.\run.bat`:
```
./run.sh --configfile config/my_project.yaml -n          # dry run
./run.sh --configfile config/my_project.yaml --cores 8
```
Set `CONTAINER_ENGINE=podman` to use podman instead of docker.

To try the pipeline on the small simulated test dataset (about 1 minute; see `.test/make_test_data.R`):
```
./run.sh --configfile .test/config/config.yaml --cores 4
```

## Good to know

- **Resuming:** if the laptop sleeps, Docker stops, or you press Ctrl+C, run the same command again. Finished STRUCTURE runs are kept and only missing ones are run.
- **"Directory cannot be locked":** first make sure no earlier run is still going. If you closed the terminal window during a run, it may continue inside Docker: look in Docker Desktop → *Containers* (or `docker ps`) and stop the `forest_popgen` container there. Then add `--unlock` once and run again.
- **Changing plots:** edit only the `plots:` (or `maps:`) section and run again. Only the plots and the report are redrawn; STRUCTURE and CLUMPAK are not re-run.
- **Adding K values:** raise `k_max` and run again. Only the new STRUCTURE runs are done; CLUMPAK and the plots are redone.
- **Changing data, filters or run settings:** everything downstream is re-run. Use a new `project` name to keep the old results.
- **Run only part of it:**
  - `... structure_runs` runs only STRUCTURE.
  - `... plots` redraws only the plots.
- **Laptop CPU:** each STRUCTURE run uses one core. `--cores N` runs N at a time. Keep the laptop plugged in and stop it from sleeping during long runs.

## Input format

- **GenAlEx** layout, diploid codominant markers (e.g. microsatellites), two columns per locus:
  - row 1: number of loci, samples, populations, then the sizes of each population
  - row 2: population names
  - row 3: `Ind`, `Pop`, then locus names
  - then one row per sample
- **Missing alleles** are coded `0`.
- **CSV** files with `,` or `;` separators both work. With **Excel** files, set `input.sheet` if the data are not on the first sheet.
- **Hierarchical labels:** population labels can hold several levels joined by `_`, e.g. `Wild_arm_ARM`. Name them with `input.strata: GenePool/Pop/Country`. Then choose the level STRUCTURE uses as its population (`pop_level`) and the levels shown under the plots (`plots.group_labels`).
- **Maps:** need a CSV with one row per population (`pop`, `Latitude`, `Longitude`; column names are configurable).

## Results (`results/<project>/`)

| Path | Content |
|---|---|
| `report.html` | Summary: data, settings, Evanno, CLUMPAK modes, all plots, versions, citations |
| `q/Q_K<k>.csv`, `q/Q_all_K.xlsx` | CLUMPAK major-mode Q matrix per K, with sample names and strata |
| `q/qmatrix_long.tsv` | All K in one long table (for your own plots) |
| `q/modes_summary.tsv` | CLUMPAK modes per K (runs in each mode, mean LnP, similarity) |
| `evanno/` | Mean ln P(D) per K and Evanno ΔK (table and plot) |
| `plots/single/`, `plots/range/`, `plots/maps/` | Figures (pdf/png/svg/tiff, as configured) |
| `clumpak/` | Full CLUMPAK output (all modes, CLUMPP files, CLUMPAK's own figures) |
| `structure/` | Generated `mainparams`/`extraparams` and the raw STRUCTURE output (`runs/str_K*_rep*_f`) |
| `input/` | STRUCTURE input file, sample table, population labels, data summary |
| `logs/` | One log per step; STRUCTURE logs record each run's seed |

## HPC (SLURM + Apptainer)

On the cluster you need Snakemake ≥ 8 with `snakemake-executor-plugin-slurm`, and Apptainer or Singularity. The pipeline pulls the container (`docker://nikostourvas/forest_popgen:0.4.15`) and runs every step inside it. Every STRUCTURE run is a separate SLURM job.

1. Edit `profiles/slurm/config.yaml`: set the partition (and account), and the per-run time for STRUCTURE (`set-resources: structure: runtime`).
2. From the pipeline folder, ideally inside `tmux` or `screen`:
   ```
   snakemake --profile profiles/slurm --configfile config/my_project.yaml
   ```

Notes:
- **One large node:** to use a single node without SLURM, run
  ```
  snakemake --profile profiles/local --sdm apptainer --cores 64 --configfile ...
  ```
  or `apptainer exec forest_popgen.sif snakemake --profile profiles/local --cores 64 --configfile ...`.
- **Local image:** to use a local `.sif` instead of pulling from Docker Hub, set `container: /path/to/forest_popgen_0.4.15.sif` in your config.
- **Plotting on a laptop:** you can run only STRUCTURE on the HPC (`... structure_runs`), copy `results/<project>/` to a laptop, and continue there.

## For maintainers

- **Layout:**
  - `workflow/Snakefile` and `workflow/rules/*.smk`: steps
  - `workflow/scripts/*.R`: one script per step
  - `workflow/scripts/lib/`: reusable R code
  - `workflow/schemas/config.schema.yaml`: config validation and defaults
- **New input format** (e.g. VCF): add a reader to `workflow/scripts/lib/inputs.R` (see the comment at its top) and its name to the `input.format` enum in the schema.
- **New plotting engine** (e.g. ggplot2 with facets): add `plot_q_<engine>()` to `workflow/scripts/lib/plotting.R`, register it in `PLOT_ENGINES` and add the name to the `plots.engine` enum in the schema. Settings specific to pophelper can already be passed through `extra_args`.
- **Re-runs:** the profiles set `rerun-triggers: [mtime, params, input]`, so changes to pipeline *code* do not trigger re-runs of finished steps. To redraw plots after changing plotting code, run with `--forcerun plot_single_k plot_k_range plot_map report`.
- **Image version:** the container is pinned in the config schema default (`container`) and in `run.bat` / `run.sh`.

## How to cite

Use **"Cite this repository"** on the GitHub page (from `CITATION.cff`). A Zenodo DOI will be added with the first release. Please also cite the programs the pipeline runs, listed below.

## Citations

- Pritchard, Stephens & Donnelly (2000) *Genetics* 155:945; Falush, Stephens & Pritchard (2003) *Genetics* 164:1567 (STRUCTURE)
- Kopelman et al. (2015) *Mol Ecol Resour* 15:1179 (CLUMPAK)
- Evanno, Regnaut & Goudet (2005) *Mol Ecol* 14:2611 (ΔK)
- Francis (2017) *Mol Ecol Resour* 17:27 (pophelper)
- Mölder et al. (2021) *F1000Research* 10:33 (Snakemake)

## License

MIT (see `LICENSE`). STRUCTURE, CLUMPAK and the R packages used are not part of this repository; they are installed in the `forest_popgen` image and keep their own licences. The test data in `.test/data/` are simulated (`.test/make_test_data.R`).
