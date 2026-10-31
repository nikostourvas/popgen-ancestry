# Shared helpers: output paths, K/replicate lists, config sanity checks and
# the list of final targets. Everything here is derived from the config.

OUT = f"results/{config['project']}"

S = config["structure"]
KS = list(range(S["k_min"], S["k_max"] + 1))
REPS = list(range(1, S["replicates"] + 1))

P = config["plots"]
SINGLE_KS = P["single_k"]["k"]
RANGES = [tuple(r) for r in P["k_range"]["ranges"]]
MAPS = config["maps"]
MAP_KS = MAPS["k"] if MAPS["enabled"] else []
FORMATS = P["formats"]


wildcard_constraints:
    K=r"\d+",
    rep=r"\d+",
    k_from=r"\d+",
    k_to=r"\d+",


# Plots, tables and the report are quick: on SLURM run them on the head node.
localrules:
    all,
    structure_runs,
    plots,
    prepare_input,
    write_params,
    evanno,
    collect_q,
    plot_single_k,
    plot_k_range,
    plot_map,
    report,


# ---------------------------------------------------------------------------
# Friendly config checks (the JSON schema catches types, these catch logic)
# ---------------------------------------------------------------------------
def _check_config():
    problems = []
    if not re.fullmatch(r"[A-Za-z0-9_.-]+", config["project"]):
        problems.append(
            f"project: '{config['project']}' may only contain letters, numbers, "
            "'_', '-' and '.' (it becomes a folder name)."
        )
    if S["k_min"] > S["k_max"]:
        problems.append("structure: k_min must be <= k_max.")
    if not os.path.exists(config["input"]["file"]):
        problems.append(
            f"input.file: '{config['input']['file']}' does not exist. Paths are "
            "relative to the pipeline folder (e.g. data/my_genotypes.csv)."
        )
    for k in SINGLE_KS:
        if k not in KS:
            problems.append(f"plots.single_k.k: K={k} is outside k_min..k_max.")
    for a, b in RANGES:
        if a > b or a not in KS or b not in KS:
            problems.append(
                f"plots.k_range.ranges: [{a}, {b}] must satisfy "
                f"k_min <= from <= to <= k_max."
            )
    for k in MAP_KS:
        if k not in KS:
            problems.append(f"maps.k: K={k} is outside k_min..k_max.")
    if MAPS["enabled"] and not os.path.exists(MAPS["coords"]):
        problems.append(f"maps.coords: '{MAPS['coords']}' does not exist.")
    if problems:
        raise WorkflowError(
            "Problems found in the config file:\n  - " + "\n  - ".join(problems)
        )


_check_config()


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
def run_file(K, rep):
    return f"{OUT}/structure/runs/str_K{K}_rep{rep}_f"


def all_run_files():
    return [run_file(K, rep) for K in KS for rep in REPS]


def seed_for(wildcards):
    # One reproducible seed per run, recorded in the run log and the report.
    return S["seed"] + 1000 * int(wildcards.K) + int(wildcards.rep)


def q_tables():
    return expand(f"{OUT}/q/Q_K{{K}}.csv", K=KS)


def single_k_plots():
    return expand(f"{OUT}/plots/single/K{{K}}.{{ext}}", K=SINGLE_KS, ext=FORMATS)


def k_range_plots():
    return [
        f"{OUT}/plots/range/K{a}-{b}.{ext}" for a, b in RANGES for ext in FORMATS
    ]


def map_plots():
    return [
        f"{OUT}/plots/maps/K{k}_{region['name']}.{ext}"
        for k in MAP_KS
        for region in MAPS["regions"]
        for ext in FORMATS
    ]


def all_plots():
    return single_k_plots() + k_range_plots() + map_plots()


def all_targets():
    targets = [
        f"{OUT}/evanno/evanno.tsv",
        f"{OUT}/q/qmatrix_long.tsv",
        f"{OUT}/q/modes_summary.tsv",
    ]
    targets += all_plots()
    if config["report"]:
        targets.append(f"{OUT}/report.html")
    return targets
