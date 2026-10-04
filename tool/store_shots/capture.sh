#!/usr/bin/env bash
# Roda todos os roteiros de captura (stills e clipes de video) em paralelo.
# Uso: capture.sh <workDir> [stills|video|all] [locale ...]
# Pre-requisito: build web servida em $BASE (padrao http://127.0.0.1:8931/).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$1"; WHAT="${2:-all}"; shift 2 || true
LOCS=("$@"); [ ${#LOCS[@]} -eq 0 ] && LOCS=(pt-BR en-US es-ES hi-IN bn-BD ne-NP)
export PATH=/opt/node-v22/bin:$PATH
python3 "$HERE/scenarios.py" "$WORK/scen" >/dev/null
jobs_list=()
for loc in "${LOCS[@]}"; do
  for f in "$WORK/scen/$loc"/*.json; do
    n=$(basename "$f" .json)
    case "$WHAT" in stills) [[ $n == s* ]] || continue;; video) [[ $n == v* ]] || continue;; esac
    jobs_list+=("$f|$WORK/cap/$loc/$n")
  done
done
printf '%s\n' "${jobs_list[@]}" | xargs -P "${PAR:-5}" -I{} bash -c 'IFS="|" read -r f o <<< "{}"; rm -rf "$o"; node "'"$HERE"'/drive.mjs" "$f" "$o"'
