# One STRUCTURE job per (K, replicate). Snakemake runs them in parallel on a
# laptop (--cores) or as separate SLURM jobs on an HPC.


rule structure:
    input:
        data=f"{OUT}/input/data.str",
        main=f"{OUT}/structure/mainparams",
        extra=f"{OUT}/structure/extraparams",
    output:
        f"{OUT}/structure/runs/str_K{{K}}_rep{{rep}}_f",
    params:
        seed=seed_for,
    log:
        f"{OUT}/logs/structure/K{{K}}_rep{{rep}}.log",
    threads: 1
    shell:
        """
        # Work in a private scratch folder with short file names: STRUCTURE
        # writes seed.txt to the current folder and limits paths to 200 chars.
        log="$(pwd)/{log}"
        wd="$(mktemp -d "${{TMPDIR:-/tmp}}/structure_K{wildcards.K}_rep{wildcards.rep}.XXXXXX")"
        trap 'rm -rf "$wd"' EXIT
        cp {input.data} "$wd/data.str"
        cp {input.main} "$wd/mainparams"
        cp {input.extra} "$wd/extraparams"
        echo "K={wildcards.K} rep={wildcards.rep} seed={params.seed}" > "$log"
        (cd "$wd" && structure -K {wildcards.K} -m mainparams -e extraparams \
            -i data.str -o out -D {params.seed}) >> "$log" 2>&1
        test -s "$wd/out_f" || {{ echo "STRUCTURE did not write its output" >> "$log"; exit 1; }}
        cp "$wd/out_f" {output}
        """


# Target to run only STRUCTURE (e.g. on an HPC) and do CLUMPAK/plots later.
rule structure_runs:
    input:
        all_run_files(),


rule evanno:
    input:
        all_run_files(),
    output:
        table=f"{OUT}/evanno/evanno.tsv",
        lnprob=f"{OUT}/evanno/lnprob_by_k.tsv",
        plot=expand(f"{OUT}/evanno/evanno.{{ext}}", ext=FORMATS),
    log:
        f"{OUT}/logs/evanno.log",
    script:
        "../scripts/evanno.R"
