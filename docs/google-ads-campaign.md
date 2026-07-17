# Campanha Google Ads — Tic Tac Verse (estado atual: 2026-07-06)

> **DIRETRIZ DO OPERADOR (2026-07-05): o Ultimate Tic Tac Toe / Super Jogo da Velha é o
> CARRO-CHEFE do app.** Toda campanha, criativo, screenshot de ficha e esforço de divulgação
> gira em torno dele ("9 tabuleiros em um / sua jogada decide onde o rival joga").

## STATUS (2026-07-06)

- **Campanha criada pelo operador:** `tictacverse-campanha1` (Promoção de app, Android).
- **Estrutura escolhida pelo operador: 1 campanha, 3 grupos de anúncios por idioma (PT/EN/ES).**
  (Recusou 3 campanhas separadas; ciente de que idioma trava só no nível campanha — a IA do
  Google casa criativo↔público, texto acerta quase sempre, imagem/vídeo pode ocasionalmente
  cruzar.) Em Configurações → **Idiomas = PT+EN+ES** e **Locais** = países dos 3 mercados.
  O campo Idiomas NÃO traduz — só filtra público; por isso 1 grupo com criativos por língua.
- **Play ↔ Google Ads VINCULADO (2026-07-06)** → conversão "Instalações (Google Play)" é
  automática. Conferir em Ferramentas → Conversões.
- **PENDENTE (operador):** confirmar cartão/faturamento (bloqueio nº1 — sem isso nada roda);
  subir os 3 vídeos no YouTube (canal separado, **"Não listado"** — "Privado" NÃO veicula; não
  apagar depois) e colar as URLs nos grupos; ativar; **7 dias sem mexer** (aprendizado);
  checar cupom em Faturamento → Promoções.
- ⚠️ **NUNCA clicar nos próprios anúncios** (tráfego inválido = ban AdMob/Ads).
- Após ~7 dias: ler CPI por grupo/idioma, cruzar com AdMob (receita/eCPM) e Play via skills
  `admob`/`google-play`, e decidir escalar/realocar/pausar.

## Criativos (v3 — FINAIS, aprovados após 2 rejeições)

**Local:** `/root/prints/tictacverse-ads/{pt,en,es}/` — por idioma:
- `banner-1200x628.png` (1.91:1) · `banner-1200x1200.png` (1:1) · `banner-1200x1500.png` (4:5)
- `video-gameplay-9x16.mp4` (1080×1920, ~16-18s, sem áudio) — **gameplay REAL do Ultimate**
- `textos.txt` — 10 títulos (≤30 chars) + 5 descrições (≤90), validados por script

Cada idioma usa screenshots do app naquela língua (pt=Super Jogo da Velha, en=Ultimate Tic Tac
Toe, es=Súper Tres en Raya). Metadados de YouTube (título/descrição/tags dos 3 vídeos)
entregues no chat de 2026-07-06.

**Histórico de rejeições (não repetir):** v1 = celulares pequenos com vazio no meio; v2 =
moldura CSS "imitando celular" (operador: terrível) + vídeo de slides estáticos (operador:
inútil, não mostrava nada). v3 = frame de celular REAL + partida real gravada.

## Toolchain (como regenerar — ex.: após nova repaginação visual)

Scripts no scratchpad da sessão de 2026-07-06 (recriáveis; lógica documentada aqui):
1. **Screenshots do app:** skill `frontend-review` na build web (`flutter build web`), 390×844@2x,
   por locale (`pt-st-*`/`st-*`/`es-st-*` no store-shots).
2. **Frame real:** `pixel5.png` do repo **fastlane/frameit-frames** (gh-pages, "Google Pixel 5
   Just Black", 1204×2456, tela em +58+58 1080×2340 — encaixe exato com 390×844@2x).
   `compose_frame.py` (PIL): redimensiona shot p/ 1080×2340, cantos arredondados r=60,
   alpha_composite sob o frame.
3. **Banners:** HTML+CSS (`ad-sq/ad-land/ad-port.html` + `i18n.js` com dicionário PT/EN/ES,
   `?lang=`) usando `<img>` dos phones framed → PNG via Chrome headless
   (`--screenshot --window-size=WxH --allow-file-access-from-files`).
4. **Vídeo de gameplay:** servir `build/web` (`python3 -m http.server 8899`); `record.mjs`
   (puppeteer-core) dirige uma partida real — **GOTCHAS:** Flutter web só responde a
   `page.touchscreen.tap` com viewport `hasTouch:true,isMobile:true` (mouse.click NÃO navega);
   locale forçado com `evaluateOnNewDocument` sobrescrevendo `navigator.language(s)`.
   Captura via **CDP `Page.startScreencast`** (PNG + timestamps). Partida roteirizada LEGAL:
   X vence o board 4 pela fileira do topo (O rebate pelas células centrais dos boards 0/1 →
   devolve X sempre pro board 4); payoff = X neon gigante c/ partículas; segue "jogada livre".
   Mapa de células em `record.mjs` (colX/rowY medidos de screenshot 2x).
5. **Montagem:** `make_gameplay.py` (concat demuxer com durações reais ÷1.9 speedup, fps=30,
   escala 1080×2340) → `compose_video.sh` (ffmpeg): fundo+legendas trocando em 3 segmentos
   (30%/62% da duração) + gameplay dentro do frame real (alphamerge `screenmask.png` p/ cantos)
   + end card com xfade. Fundos/end card: `vidbg.html?lang=&seg=1|2|3|end`.
6. **ffmpeg**: instalado na VPS via apt (2026-07-06).

## Textos por idioma (fonte da verdade: `textos.txt` em cada pasta)

Títulos priorizados PT: "Tic Tac Toe 2: 9 em 1" · "O jogo da velha evoluiu" · "Jogo da velha
estratégico" · "Sua jogada manda no rival" · +6. EN: "Ultimate Tic Tac Toe" · "Tic Tac Toe,
evolved" · +8. ES: "Súper Tres en Raya" · "El tres en raya evolucionó" · +8.

## Configuração da campanha

- Tipo: Instalações do app · Orçamento: R$ 10–20/dia, teto total ~R$ 300 (kickstart de
  instalações/avaliações — CPI ~R$ 0,50–2,00 vs ARPDAU de centavos NÃO fecha conta em escala;
  crescimento sustentável = orgânico: Shorts/Reels/TikTok com os próprios vídeos de gameplay).
- Lance: CPI alvo ~R$ 1,00; revisar após 1 semana.
