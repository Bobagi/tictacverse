# Screenshots e vídeo da Play (v28)

Gera as 6 screenshots por idioma (1080x1920, RGB sem alfa) e o vídeo promocional
9:16 (1080x1920, H.264, 30 fps) com **gameplay real** capturado da build web e o
**frame real do Pixel 5** (`assets/pixel5.png`, fastlane/frameit-frames, tela em
+58+58 1080x2340). Nada aqui sobe arquivo para a Play: só gera.

Saída: `docs/store-listing/shots-v28/<locale>/01..06.png` e
`docs/store-listing/video-v28/<locale>.mp4`. es-419 reaproveita o es-ES.

## Passo a passo

```bash
cd /opt/tictacverse
# 1. build web com loja de demonstração e sem anúncio
PATH=/opt/flutter/bin:$PATH flutter build web --release \
  --dart-define=FAKE_STORE=true --dart-define=ADS_MODE=off
# copie para fora do repo (outra build pode sobrescrever) e sirva
cp -r build/web /tmp/ttv-web && (cd /tmp/ttv-web && python3 -m http.server 8931 --bind 127.0.0.1 &)

# 2. captura (puppeteer-core da skill frontend-review + Chrome do cache)
W=/tmp/ttv-shots
PAR=2 SLOW=1.6 tool/store_shots/capture.sh $W stills      # 6 telas x 6 idiomas
PAR=1 SLOW=1.3 tool/store_shots/capture.sh $W video       # 4 clipes x pt/en/hi

# 3. montagem
cd tool/store_shots
python3 compose.py $W/cap ../../docs/store-listing/shots-v28
python3 make_video.py $W/cap ../../docs/store-listing/video-v28
# 4. pare o http.server pelo PID (nunca pkill -f)
```

## Arquivos

- `scenarios.py`: roteiros de toque por idioma (coordenadas CSS num viewport
  390x844 medidas de screenshots 2x). Partidas legais: Super entre amigos (X
  fecha o tabuleiro do meio), Cinco em linha, Clássico com vitória do X.
- `drive.mjs`: executa um roteiro com `page.touchscreen.tap` (Flutter web só
  responde a toque com `hasTouch/isMobile`), semeia o `localStorage`
  (idioma, progresso com 900 moedas e visual Neon, tutorial visto) e, com
  `record`, grava todos os quadros por CDP `Page.startScreencast`.
- `ult_pick.py`: no Desafio do dia (contra a CPU) lê a tela e escolhe uma
  célula livre do tabuleiro aceso.
- `captions.py`: textos por idioma (`*palavra*` sai em amarelo #FFD21A).
- `compose.py`: fundo roxo, título, frame real e brilhos. Hindi, nepali e
  bengali usam Noto Sans Devanagari/Bengali; letras e dígitos latinos ("4x4")
  caem para a Fredoka, porque as Noto indianas não têm o "x".
- `make_video.py`: 4 segmentos de gameplay (Super, Desafio, Cinco em linha,
  vitória com Compartilhar) + cartão final com o ícone. Pausas paradas acima de
  450 ms são encurtadas e o resto acelera pelo menos 1,6x.

## Armadilhas

- A VPS tem 2 núcleos: com muitas capturas em paralelo os toques chegam antes da
  tela estar pronta e caem no lugar errado. Use `PAR` baixo e `SLOW` alto e
  confira as capturas antes de montar.
- O cartão do Super na lista de modos muda de altura por idioma; o toque no
  Clássico tem coordenada própria para en e hi (`MODES_CLASSIC`).
- Se o layout do app mudar, remeça as coordenadas em `scenarios.py`.
