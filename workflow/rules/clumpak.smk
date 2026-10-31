# CLUMPAK is run once on all STRUCTURE runs of all K, exactly as on the
# CLUMPAK website / the original notebook. CLUMPAK itself clusters the runs into
# modes, aligns them with CLUMPP and keeps cluster numbering consistent across K.
# It calls its helpers (CLUMPP, mcl, distruct) through relative paths, so the
# job works in a private scratch copy of the CLUMPAK folder.


def clumpak_args():
    c = config["clumpak"]
    args = [f"--clumppsearchmethod {c['clumpp_search_method']}"]
    if c["mcl_threshold"] is not None:
        args.append(f"--mclthreshold {c['mcl_threshold']}")
    if c["mcl_min_cluster_fraction"] is not None:
        args.append(f"--mclminclusterfraction {c['mcl_min_cluster_fraction']}")
    if c["clumpp_repeats"] is not None:
        args.append(f"--clumpprepeats {c['clumpp_repeats']}")
    if c["extra_args"]:
        args.append(c["extra_args"])
    return " ".join(args)


rule clumpak:
    input:
        runs=all_run_files(),
        labels=f"{OUT}/input/popnames.txt",
    output:
        directory(f"{OUT}/clumpak"),
    params:
        clumpak_dir=config["clumpak"]["path"],
        args=clumpak_args(),
    log:
        f"{OUT}/logs/clumpak.log",
    threads: 1
    shell:
        """
        set -euo pipefail
        out="$(pwd)/{output}"
        log="$(pwd)/{log}"
        labels="$(pwd)/{input.labels}"
        scratch="$(mktemp -d "${{TMPDIR:-/tmp}}/clumpak.XXXXXX")"
        trap 'rm -rf "$scratch"' EXIT

        cp -r "{params.clumpak_dir}" "$scratch/CLUMPAK"
        zip -j -q "$scratch/CLUMPAK/input.zip" {input.runs}

        cd "$scratch/CLUMPAK"
        perl -I. CLUMPAK.pl --id 1 --dir "$scratch/res" \
            --file input.zip --inputtype structure --labels "$labels" \
            {params.args} > "$log" 2>&1

        if [ ! -s "$scratch/res/detectedModesSummery.log" ]; then
            echo "CLUMPAK did not finish (no detectedModesSummery.log)" >> "$log"
            exit 1
        fi
        rm -rf "$out"
        cp -r "$scratch/res" "$out"
        """


rule collect_q:
    input:
        clumpak=f"{OUT}/clumpak",
        samples=f"{OUT}/input/samples.tsv",
    output:
        long=f"{OUT}/q/qmatrix_long.tsv",
        modes=f"{OUT}/q/modes_summary.tsv",
        wide=q_tables(),
        xlsx=f"{OUT}/q/Q_all_K.xlsx",
    params:
        ks=KS,
    log:
        f"{OUT}/logs/collect_q.log",
    script:
        "../scripts/collect_q.R"
