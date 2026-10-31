@echo off
rem Run the pipeline inside the forest_popgen Docker image (Windows).
rem Open "Command Prompt" or "PowerShell" in this folder and type e.g.
rem   run.bat --configfile config/my_project.yaml --cores 4
rem   run.bat --configfile config/my_project.yaml -n        (dry run)
rem All arguments are passed to snakemake. Docker Desktop must be running.
cd /d "%~dp0"
if "%FOREST_POPGEN_IMAGE%"=="" set FOREST_POPGEN_IMAGE=nikostourvas/forest_popgen:0.4.15
docker run --rm --init -it -v "%cd%:/work" -w /work %FOREST_POPGEN_IMAGE% snakemake --profile profiles/local %*
