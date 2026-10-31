#!/usr/bin/env bash
# Run the pipeline inside the forest_popgen Docker image (Linux / macOS).
#   ./run.sh --configfile config/my_project.yaml --cores 4
#   ./run.sh --configfile config/my_project.yaml -n          # dry run
# All arguments are passed to snakemake.
set -euo pipefail
IMAGE="${FOREST_POPGEN_IMAGE:-nikostourvas/forest_popgen:0.4.15}"
ENGINE="${CONTAINER_ENGINE:-docker}"
cd "$(dirname "$0")"
# Interactive terminal: Ctrl+C then stops Snakemake inside the container cleanly
TTY=()
if [ -t 0 ] && [ -t 1 ]; then TTY=(-it); fi
exec "$ENGINE" run --rm --init ${TTY[@]+"${TTY[@]}"} \
  --user "$(id -u):$(id -g)" -e HOME=/tmp \
  -v "$PWD:/work" -w /work \
  "$IMAGE" snakemake --profile profiles/local "$@"
