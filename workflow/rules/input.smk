# Read the genotype file, apply filters and write the STRUCTURE input plus a
# sample table that keeps the real sample names and all strata.


rule prepare_input:
    input:
        config["input"]["file"],
    output:
        str=f"{OUT}/input/data.str",
        samples=f"{OUT}/input/samples.tsv",
        popnames=f"{OUT}/input/popnames.txt",
        summary=f"{OUT}/input/summary.yaml",
    params:
        input_cfg=config["input"],
    log:
        f"{OUT}/logs/prepare_input.log",
    script:
        "../scripts/prepare_input.R"


# mainparams/extraparams are generated from the config and the data, so nobody
# edits NUMINDS/NUMLOCI by hand. Only MCMC/model settings are params here, so
# changing k_max or replicates does not re-run existing STRUCTURE runs.
rule write_params:
    input:
        summary=f"{OUT}/input/summary.yaml",
    output:
        main=f"{OUT}/structure/mainparams",
        extra=f"{OUT}/structure/extraparams",
    params:
        burnin=S["burnin"],
        numreps=S["numreps"],
        model=S["model"],
        mainparams_extra=S["mainparams_extra"],
        extraparams_extra=S["extraparams_extra"],
    log:
        f"{OUT}/logs/write_params.log",
    script:
        "../scripts/write_params.R"
