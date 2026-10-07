# Ficha da Play: textos, ícone, prints e vídeo

Fonte da verdade de tudo que aparece na página do jogo na Play Store. Atualizado em 2026-10-07.

## Estado de cada peça

| Peça | Arquivo / origem | Estado |
|---|---|---|
| Título | só "Tic Tac Verse", 7 idiomas (ordem do dono) | no ar, não mexer |
| Descrição curta (80) | `short.json` | no ar desde 2026-10-07 |
| Descrição longa | `<idioma>.txt` (pt-BR, en-US, es-ES, es-419, hi-IN, bn-BD, ne-NP) | no ar desde 2026-10-07 |
| Ícone 512 da loja | `icon-512.png`, gerado de `tool/icon/icon.svg` (`tool/icon/render_icon.mjs`) | no ar desde 2026-10-07 |
| Prints de celular | `shots-v28/<idioma>/01..06.png` (fora do git, gerados por `tool/store_shots/`) | no ar desde 2026-10-07 |
| Feature graphic 1024x500 | ver memória `feature-graphic-play` | antigo (mostra peças Aurora); refazer junto com os vídeos |
| **Vídeo (YouTube)** | link por idioma na ficha | **DESATUALIZADO**, ver abaixo |
| Notas de versão | `release-notes-v<code>.json` (por idioma) | v31 pronta |

Publicar textos e prints (no MESMO passo da promoção para produção, senão a ficha promete o que a
versão no ar não tem): `bash tool/publish_listing.sh shots-v28`. O ícone 512 sobe com
`python3 ~/.claude/skills/google-play/scripts/gplay.py images-upload --lang <idioma> --image-type icon --files docs/store-listing/icon-512.png`.

## Vídeos: o que está no ar e por que precisa trocar

| Idioma da ficha | Vídeo no ar |
|---|---|
| pt-BR | https://www.youtube.com/watch?v=cD4jQGZH-Sw |
| en-US, hi-IN, bn-BD, ne-NP | https://www.youtube.com/watch?v=jwo-DRee-wE (inglês) |
| es-ES, es-419 | https://www.youtube.com/watch?v=tbIrJPfxSMA |

Foram gravados em julho/2026 (campanha do Google Ads, `docs/google-ads-campaign.md`): mostram as
peças Aurora como padrão, o visual antigo e nenhum dos modos novos. Hindi, bengali e nepali veem o
vídeo em inglês.

### O que os vídeos novos precisam mostrar (v1.14)
- **Super Jogo da Velha** com peças **Neon** (o padrão desde a v1.14) e a jogada mandando o rival
  para outro tabuleiro (é o carro-chefe; abre o vídeo).
- **Desafio do dia** (card na home e a barra "Desafio do dia x/N" na partida).
- **Modos novos**: 4x4 e Cinco em linha (10x10).
- **Visuais e temas de tabuleiro** na loja (aba Visuais/Tabuleiros), com o Aurora como o visual
  premium.
- **Vitória** com confete, XP subindo e o botão **Compartilhar**.
- Cartão final com o **ícone novo** (`assets/icon/app_icon.png`) e "Tic Tac Verse".
- Não mostrar compra de moedas (não existe mais) nem preço em reais (muda por país).

### Padrão de qualidade (o dono já rejeitou o contrário, não repetir)
- **Celular REAL**: moldura `pixel5.png` do fastlane/frameit-frames (em
  `tool/store_shots/assets/pixel5.png`). Moldura desenhada em CSS foi chamada de "terrível".
- **Gameplay REAL** gravado da build (CDP screencast); vídeo de slides parados com zoom foi
  "completamente inútil".
- 9:16, 1080x1920, H.264, 30 fps, 20 a 30 s, legendas curtas por idioma, ritmo rápido (pausas
  cortadas, 1,5x a 2x).
- Um vídeo por idioma que importa: **pt, en, es, hi** no mínimo (hi é o público principal); bn e ne
  podem ficar com o en se não houver tempo.

### Como gerar
Pipeline pronto em **`tool/store_shots/`** (ver `README.md` lá): build web com
`FAKE_STORE=true ADS_MODE=off`, `capture.sh ... video`, `make_video.py`. Saída em
`docs/store-listing/video-v28/<idioma>.mp4`. Em 2026-10-05 ele gerou pt, en e hi (32 s), mas a
build era anterior à loja Premium e ao juice da oferta: **regenerar a partir da build atual** e
acrescentar es (e bn/ne se quiser) em `captions.py`/`scenarios.py`. O app mudou de layout desde
então (aba "Premium" na loja, card do desafio na home): remeça as coordenadas de toque em
`scenarios.py` antes de gravar.

### Como publicar
1. O **dono** sobe os MP4 no YouTube (canal do jogo; "Não listado" serve, "Privado" não aparece na
   Play). O Claude não tem acesso ao YouTube.
2. Com os links, o Claude troca na ficha:
   `python3 ~/.claude/skills/google-play/scripts/gplay.py listing-set --lang pt-BR --video "https://www.youtube.com/watch?v=ID"`
   (repetir por idioma; es-419 = mesmo do es-ES; hi/bn/ne = o de hi se existir).
3. Trocar o vídeo não precisa de versão nova do app.
