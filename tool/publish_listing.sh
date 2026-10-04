#!/usr/bin/env bash
# Publica a ficha da loja (descrição curta e longa) e os prints de celular de uma
# versão, nos 7 idiomas. Rodar NO MESMO PASSO da promoção para produção: ficha
# mostrando o que a versão em produção ainda não tem engana o jogador.
#
# Uso: bash tool/publish_listing.sh shots-v28
set -euo pipefail
cd "$(dirname "$0")/.."
SHOTS=${1:?pasta de prints dentro de docs/store-listing, ex.: shots-v28}
G=~/.claude/skills/google-play/scripts/gplay.py
DIR=docs/store-listing

for lang in pt-BR en-US es-419 es-ES hi-IN bn-BD ne-NP; do
  short=$(python3 -c "import json,sys;print(json.load(open('$DIR/short.json'))['$lang'])")
  python3 "$G" listing-set --lang "$lang" --short "$short" --full "$DIR/$lang.txt"
  # es-419 usa os prints de es-ES.
  src=$lang; [[ $lang == es-419 ]] && src=es-ES
  files=$(ls "$DIR/$SHOTS/$src"/0*.png | paste -sd, -)
  python3 "$G" images-upload --lang "$lang" --files "$files"
done
echo "OK: ficha e prints publicados"
