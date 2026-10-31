# One self-contained HTML page summarising the run (settings, Evanno, CLUMPAK
# modes, plots, software versions).


rule report:
    input:
        summary=f"{OUT}/input/summary.yaml",
        samples=f"{OUT}/input/samples.tsv",
        main=f"{OUT}/structure/mainparams",
        extra=f"{OUT}/structure/extraparams",
        evanno=f"{OUT}/evanno/evanno.tsv",
        lnprob=f"{OUT}/evanno/lnprob_by_k.tsv",
        modes=f"{OUT}/q/modes_summary.tsv",
        plots=all_plots(),
        evanno_plots=expand(f"{OUT}/evanno/evanno.{{ext}}", ext=FORMATS),
        rmd=workflow.source_path("../report/report.Rmd"),
    output:
        f"{OUT}/report.html",
    params:
        config=config,
    log:
        f"{OUT}/logs/report.log",
    script:
        "../scripts/render_report.R"
