# Barplots of the CLUMPAK-aligned major modes, plus optional pie-chart maps.
# Plot settings are rule params: editing the plots section of the config only
# re-runs these rules (and the report), never STRUCTURE or CLUMPAK.


def plot_common():
    return {
        k: P[k]
        for k in (
            "engine",
            "palette",
            "group_labels",
            "order_by",
            "group_order",
            "show_sample_names",
            "dpi",
        )
    }


rule plot_single_k:
    input:
        q=f"{OUT}/q/Q_K{{K}}.csv",
        samples=f"{OUT}/input/samples.tsv",
    output:
        expand(f"{OUT}/plots/single/K{{{{K}}}}.{{ext}}", ext=FORMATS),
    params:
        common=plot_common(),
        opts=P["single_k"],
    log:
        f"{OUT}/logs/plots/single_K{{K}}.log",
    script:
        "../scripts/plot_single_k.R"


rule plot_k_range:
    input:
        q=lambda w: expand(
            f"{OUT}/q/Q_K{{K}}.csv", K=range(int(w.k_from), int(w.k_to) + 1)
        ),
        samples=f"{OUT}/input/samples.tsv",
    output:
        expand(f"{OUT}/plots/range/K{{{{k_from}}}}-{{{{k_to}}}}.{{ext}}", ext=FORMATS),
    params:
        common=plot_common(),
        opts=P["k_range"],
    log:
        f"{OUT}/logs/plots/range_K{{k_from}}-{{k_to}}.log",
    script:
        "../scripts/plot_k_range.R"


def map_region(wildcards):
    for region in MAPS["regions"]:
        if region["name"] == wildcards.region:
            return region
    raise WorkflowError(f"Unknown map region {wildcards.region}")


rule plot_map:
    input:
        q=f"{OUT}/q/Q_K{{K}}.csv",
        coords=MAPS["coords"],
    output:
        expand(f"{OUT}/plots/maps/K{{{{K}}}}_{{{{region}}}}.{{ext}}", ext=FORMATS),
    params:
        palette=P["palette"],
        dpi=P["dpi"],
        maps={
            "pop_column": MAPS["pop_column"] or config["input"]["pop_level"],
            "coords_columns": MAPS["coords_columns"],
            "pie_radius": MAPS["pie_radius"],
        },
        region=map_region,
    log:
        f"{OUT}/logs/plots/map_K{{K}}_{{region}}.log",
    script:
        "../scripts/plot_map.R"


# Target to (re)draw only the plots: snakemake ... plots
rule plots:
    input:
        all_plots(),
