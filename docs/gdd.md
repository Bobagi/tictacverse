# GDD · Tic Tac Verse

Documento de design do jogo. É a fonte de verdade do **que** o jogo é e **por que** cada
decisão existe; o `CLAUDE.md` da raiz cobre o **como** (código, comandos, armadilhas).
Mudou regra, número, economia, monetização ou política de loja? Atualize este arquivo na
mesma tarefa.

Última revisão: 2026-10-04 (v1.12.0+26, em produção a 100%).

---

## 1. Visão

Jogo da velha "multiverso": o jogo que todo mundo conhece, em cinco variações, com visual
neon, partidas rápidas e uma camada de progressão (XP, nível, conquistas, moedas, visuais)
que nenhum concorrente direto tem.

- **Carro-chefe:** o **Super Jogo da Velha** (Ultimate Tic Tac Toe). Diretriz do dono:
  campanha, criativo, screenshot e ficha giram em torno dele, e ele rende 50% a mais de XP
  (e, por consequência, de moedas).
- **Promessa ao jogador:** fácil de aprender, difícil de dominar; offline, leve, grátis, sem
  cadastro.
- **Pacote:** `com.bobagi.tictacverse` na Google Play. Único app do portfolio com
  expectativa real de receita.

## 2. Público

Medido, não suposto (AdMob e Google Ads, jul a out/2026): **Índia, Bangladesh, Nepal,
Venezuela, Paquistão, Quênia** lideram instalações e impressões. Brasil e países de tier 1
quase não aparecem.

Consequências de design:
- **Seis idiomas** completos: `pt`, `en`, `es`, `hi`, `bn`, `ne`. Hindi, bengali e nepali
  são o público real, não enfeite. Toda tela é testada na matriz idioma x tamanho de tela
  (strings de hi/bn/ne são mais longas que o inglês).
- **Celular modesto e tela baixa** (360x640 é alvo): nada importante pode depender de
  rolagem, e o anúncio grande só entra em tela >= 380x760.
- **eCPM baixo** (média medida de US$0,33 a 0,45): a receita depende de volume de jogadores
  ativos e do anúncio premiado, que paga várias vezes o banner.

## 3. Modos de jogo

| Modo | Regra | Papel |
|---|---|---|
| **Super Jogo da Velha** (`ultimate2`) | 9 tabuleiros dentro de um tabuleiro grande. A casa que você marca define em qual tabuleiro o rival joga em seguida. Ganhar um tabuleiro pequeno conquista a casa correspondente no grande; três em linha no grande vence. Destino fechado libera jogada livre. | Carro-chefe; +50% de XP |
| **Clássico** (`classic`) | 3x3 tradicional. | Porta de entrada |
| **Shift** (`shift`) | Cada jogador tem no máximo 3 peças; ao colocar a 4ª, a mais antiga some. | Acaba com o empate chato |
| **Caos** (`chaos`) | Eventos aleatórios no meio da partida: remover uma peça, bloquear uma casa, trocar os símbolos. | Imprevisibilidade |
| **Ultimate Mini** (`ultimateMini`) | 3x3 com condição especial sorteada por rodada: proibido usar o centro, ou número limitado de jogadas. | Variedade rápida |
| **4x4** (`fourByFour`) | Tabuleiro 4x4; quatro em linha (linha, coluna ou diagonal) vence; cheio sem linha empata. | Passo seguinte ao Clássico |
| **Cinco em linha** (`gomoku`) | Gomoku 10x10, regra livre: cinco ou mais em linha vencem (seis também); cheio sem linha empata. | Partida longa e estratégica; +25% de XP |

Os dois últimos rodam no mesmo fluxo do Clássico (`GameController` + `GameScreen`), com
`LineRulesEngine` e o formato do tabuleiro em `GameModeType.boardSize`/`winLength`; o
`GameBoard` desenha NxN a partir do número de casas.

**Oponentes:** contra a CPU ou 2 jogadores no mesmo aparelho. No modo contra a CPU o humano é
sempre o X.

**CPU, três níveis:**
- **Fácil:** casa aleatória.
- **Médio:** vence se puder, bloqueia se precisar, senão aleatório.
- **Impossível:** minimax perfeito no Clássico (imbatível **de propósito**: é provocação
  intencional do dono, não bug, não se reabre). Nos outros modos usa vitória/bloqueio ciente
  da regra do modo, filtro de jogadas seguras e preferência posicional.
- **4x4 e Cinco em linha** usam a `LineCpu` (`lib/controllers/line_cpu.dart`). Fácil: casa
  aleatória colada em alguma peça. Médio: vence, bloqueia, senão sorteia entre as 3 melhores
  da pontuação. Impossível: vence, bloqueia, arma ameaça dupla (quatro aberto), desmonta a
  ameaça dupla do rival (fecha o três aberto) e, sem nada disso, pontua janelas de N casas;
  responde em poucos milissegundos no 10x10.

## 4. Progressão

Tudo é regra pura com relógio injetável (`lib/services/progression_engine.dart`), testável
sem widget.

**XP por partida:** base 10; vitória +25; empate +5; contra a CPU no Médio +5, no Impossível
+12; Super Jogo da Velha x1,5; Cinco em linha x1,25 (abaixo do carro-chefe de propósito);
4x4 paga como o Clássico. Vitória local entre amigos não conta como vitória.

**Nível:** custo do nível N para N+1 = 80 + 40 x (N - 1), ou seja 80, 120, 160, 200... Os
primeiros níveis caem na primeira sessão; os altos viram meta longa.

**Conquistas (16, espelhadas no Google Play Games):** bronze rende 50 XP, prata 120, ouro 300.

| Grupo | Conquistas |
|---|---|
| Vitórias contra a CPU | 1 (bronze), 10 (bronze), 50 (prata), 200 (ouro) |
| Vitórias seguidas | 3 (bronze), 7 (prata), 15 (ouro) |
| Feitos | vencer no Impossível (ouro), vencer o Clássico em 3 jogadas (prata), jogar 5 modos diferentes (prata; meta fixa em 5 mesmo com 7 modos, quem já tinha segue com ela), 10 vitórias no Super Jogo da Velha (prata) |
| Dias seguidos jogando | 3 (bronze), 7 (prata), 30 (ouro) |
| Partidas | 50 (bronze), 250 (ouro) |

**Regra de verdade:** o estado local é a fonte; o Play Games é espelho "fire and forget".
Falha lá nunca desfaz nada aqui.

**Sequências:** vitórias seguidas contra a CPU e dias seguidos jogando aparecem no fim da
partida (com fogo e pulso). A sequência diária só é mostrada se ainda vale hoje.

## 5. Economia: moedas, visuais e bônus diário (desde v1.12.0)

**Por que existe:** a pesquisa de mercado de 2026-10-03 mostrou que os concorrentes diretos
(Tic Tac Toe Glow, XOXO e afins, de 10M a 100M downloads) vendem **visual de peça**, e que os
jogos casuais que faturam com anúncio (Block Blast, Ludo King) amarram o premiado a algo que
o jogador quer. Antes disso o XP não tinha onde ser gasto e o premiado "dobrar XP" teve 0
impressões em 30 dias.

**Moedas** (`lib/services/economy_engine.dart`):
- Toda partida paga moedas = teto(XP ganho / 3). Atrelado ao XP de propósito: o
  carro-chefe e o Impossível já rendem mais, sem uma segunda tabela para manter.
- O saldo nunca fica negativo e só é gasto na loja.
- Também se compram moedas com dinheiro (seção 6).

**Loja de visuais das peças** (`lib/models/piece_skin.dart`). Visual só muda aparência,
nunca dá vantagem.

| Visual | Preço | Estilo |
|---|---|---|
| Neon | grátis (inicial desde a v1.13.0) | traço fino com miolo branco, ciano e rosa |
| Fogo e gelo | 250 | degradê laranja/amarelo e azul/branco |
| Bala | 350 | traço grosso arredondado com reflexo, menta e morango |
| Ouro e prata | 500 | degradê metálico |
| Galáxia | 800 | degradê violeta/ciano com anel interno e brilhos |
| Aurora | 1000 | as artes PNG originais, o visual mais trabalhado (fecha o catálogo) |

**Troca do visual inicial (v1.13.0/v1.14.0, ordem do dono):** o Neon combina com o ícone novo e
virou o padrão; o Aurora, por ser o mais trabalhado, é o último e mais caro. Migração única
(`catalogVersion` 3 no save): **todo mundo** que estava com o Aurora em uso passa para o Neon; quem já
jogava continua dono do Aurora (a um toque de voltar); quem tinha comprado o Neon recebe as 120 moedas
de volta. O cartão do visual mostra sempre o preço (com cadeado sem saldo); tocar sem saldo leva aos
pacotes de moedas.

**Temas de tabuleiro (v1.14.0, aba "Tabuleiros"):** mudam as cores da grade neon e da moldura em
todos os modos. Neon (grátis), Pôr do sol 200, Oceano 300, Esmeralda 400, Realeza 600
(`lib/models/board_theme.dart`). Mais baratos que os visuais de peça: são o segundo desejo.

**Desafio do dia (v1.14.0):** card na home. Vencer a máquina no Super Jogo da Velha em até N
jogadas (22 a 28 em dia útil no médio; 28 a 33 no fim de semana no impossível), sorteado pela data
(igual para todo mundo). Paga 60 moedas + 10 por dia seguido (teto +60), uma vez por dia; voltar a
data do aparelho não libera de novo. `lib/services/daily_challenge.dart`.

Comprar debita o preço exato e já equipa. Visual comprado vale em todas as telas de jogo
(tabuleiro, Super Jogo da Velha, avatar, modal de fim).

**Bônus diário:** ciclo de 7 dias pagando 20, 25, 30, 40, 50, 60 e 100 moedas. Resgatar em
dias seguidos avança; pular um dia volta ao dia 1; depois do 7º o valor recomeça, mas a
contagem continua. Um resgate por dia. Voltar a data do aparelho não libera outro.

**Ritmo pretendido:** uma vitória rende ~12 moedas e o bônus 20 a 100, então o primeiro
visual sai na primeira ou segunda sessão e o mais caro vira meta de algumas semanas.

## 6. Monetização

Anúncio (Google AdMob) e, desde a v1.13.0, compras pelo Google Play Billing, validadas desde a
v1.14.0 no servidor do jogo (`tictacverse-api`, seção 6.1).

**Compras dentro do app** (aba "Moedas" da loja; o saldo no topo da home abre direto nela):

| Produto (id na Play) | Tipo | Entrega | Preço base |
|---|---|---|---|
| `starter_pack` | compra única, só para quem ainda vê anúncio | "sem anúncios" + 1000 moedas (moedas só no 1º resgate) | US$ 1,99 |
| `remove_ads` | compra única, volta ao reinstalar | some banner, retângulo médio e intersticial; o premiado continua opt-in | US$ 0,99 |
| `coins_300` | consumível | 300 moedas | US$ 0,99 |
| `coins_1000` | consumível | 1000 moedas | US$ 2,49 |
| `coins_3000` | consumível ("Melhor oferta") | 3000 moedas | US$ 4,99 |

Preço por país = conversão da própria Play a partir do preço base, com preço regional para o público
real: Índia ₹89/49/39/99/199, Bangladesh ৳110/60/50/120/240, Nepal US$ 0,99/0,49/0,49/0,99/1,99
(na ordem da tabela; `tool/play_products_setup.py`). O app mostra o preço formatado que a Play devolve
e calcula o "Economize X%" do pacote de boas-vindas com os preços reais. Regras que não se quebram:
- Servidor confirma na Play, app credita e grava, e SÓ ENTÃO consome/confirma na Play. Idempotente
  pelo token dos dois lados.
- Pagamento pendente (comum na Índia) não credita; credita quando a Play confirmar, mesmo com a loja
  fechada (a escuta começa no `main`).
- Os botões de preço só valem 600 ms depois de a aba aparecer (ela surge sob o dedo ao tocar num visual
  trancado). Toque duplo abre uma compra só.
- Servidor fora do ar: a compra fica paga e pendente (não credita, não finaliza) e é tentada de novo
  em 20 s, 2 min, 10 min e a cada abertura. A Play devolve o dinheiro se não for confirmada em 3 dias.
- **Reembolso/estorno desfaz a entrega** (seção 6.1).
- Convite do pacote de boas-vindas na home: a partir da 2ª sessão, no máximo 3 vezes, 2 dias de
  intervalo, nunca para quem já tirou os anúncios.
- `--dart-define=FAKE_STORE=true` liga uma loja de mentira para QA na web; release nativo ignora.

| Formato | Onde | Regra |
|---|---|---|
| Banner / retângulo médio | Base da home e das telas de jogo | 300x250 só com tela >= 380x760; abaixo, banner 320x50. Some com "sem anúncios" |
| Intersticial | Fim de partida | A cada 3 partidas (contador global, sobrevive à troca de tela). Some com "sem anúncios" |
| Premiado "dobrar XP e moedas" | Modal de fim de partida | A cada 4 partidas, só se houver XP ganho, só com anúncio carregado, nunca na partida em que o intersticial apareceu |
| Premiado "dobrar o bônus" | Bônus diário, depois do resgate | Uma vez por resgate |
| Premiado "+25 moedas" | Loja | Teto de 5 por dia |

**Regras que não se quebram** (a conta AdMob já foi suspensa uma vez por "self-clicking";
reincidência é encerramento permanente):
- Nunca clicar nos próprios anúncios; aparelho de teste se cadastra no AdMob antes de abrir o
  app.
- Premiado é sempre **opt-in** (só abre por toque), o rótulo diz o que o jogador ganha, e o
  crédito só acontece quando o SDK confirma que o anúncio foi assistido até o fim.
- O convite de anúncio só aparece com anúncio **já carregado**, é estilo contorno e fica
  longe do botão primário (folga é asserção de teste).
- Sem encadear anúncios.
- Toque duplo nunca abre dois anúncios nem paga duas vezes.

### 6.1 Servidor do jogo (`tictacverse-api`, desde a v1.14.0)

Repo privado `Bobagi/tictacverse-api`, `/opt/tictacverse-api` no VPS, container na porta 3066,
`https://tictacverse-api.bobagi.space`. Três funções:
1. **Validar compra:** consulta o token na Play Developer API; só entrega com `purchaseState = 0`.
   Pacote de moedas amarrado à instalação que comprou (`obfuscatedAccountId`); compra única
   restaurada em outra instalação devolve só o direito, nunca as moedas de novo.
2. **Desfazer reembolso:** a cada 30 min lê a lista de compras anuladas da Play. O app consulta os
   estornos da sua instalação ao abrir: tira as moedas e, se já gastou, devolve à loja visuais e
   temas do mais caro para o mais barato até cobrir; se não cobrir, o saldo fica negativo e as
   próximas moedas pagam. "Sem anúncios" estornado volta a mostrar anúncios.
3. **Medir retenção:** ping diário (id aleatório da instalação, versão, idioma; sem IP).
   `docker exec tictacverse-api npm run stats` dá DAU e D1/D7 por coorte.

**Expectativa realista:** casual só com anúncio fica em US$0,03 a 0,10 por usuário ativo
por dia; em tier 3, perto do piso. O gargalo é volume e retenção, não formato.

## 7. Interface e identidade

- **Paleta:** fundo roxo profundo (`#1A0B2E` a `#3A0F55`), X ciano (`#35D6FF`/`#6BE0FF`),
  O rosa (`#FF4FD8`/`#FF6BD9`), energia âmbar (`#FFB938`), moeda amarela (`#FFD21A`).
  Tokens em `VerseColors` (`lib/ui/widgets/modern_background.dart`).
- **Fonte:** Fredoka nos títulos.
- **Home:** saldo de moedas no topo (atalho para a loja), logo ao lado do nome, dois botões
  grandes de oponente (máquina, amigo), atalhos de Bônus diário (pulsa com ponto vermelho
  quando disponível) e Visual das peças, painel de nível (abre as conquistas), banner na
  base.
- **Ícone (desde v1.12.0):** X ciano e O rosa em neon sobre grade 3x3, fundo roxo, sem
  moldura nem texto, legível em 48px. É o sinal que quem busca "tic tac toe" reconhece.
  Desde a v1.14.0: peças com volume (degradê, brilho especular, sombra) sobre grade de vidro e faíscas, em `tool/icon/icon.svg`, renderizado em camadas (fundo e peças a 72%) por `tool/icon/render_icon.mjs`.
- **Configurações:** abrem sempre por `showSettingsSheet()`; "Buscar atualizações" é o
  primeiro item e tem de estar visível sem rolar em toda tela e idioma.

## 8. Game feel

Detalhes técnicos no `CLAUDE.md`, seção "Game feel".
- Sons Kenney (CC0) em toda ação; 8 músicas CC0 em playlist embaralhada, tocadas a 0,3 do volume
  dos efeitos (`AudioService.musicGain`, desde a v1.13.0: antes cobriam as jogadas). Só entra faixa CC0
  ou própria (o dono não quer texto de crédito na tela).
- Vibração por evento (ligável nas configurações).
- Partículas na peça e na captura, confete na vitória e no bônus, brilho na subida de nível.
- Fim de partida: risco neon da linha, depois som, vibração e confete; título que fala com o
  jogador; XP e moedas contando; barra de nível animando.
- Tudo respeita "reduzir animações" do sistema.

## 9. Loja (Play Store) e ASO

- **Título:** só "Tic Tac Verse", sem subtítulo, em todos os idiomas (ordem do dono).
- **Descrição curta (80):** carrega as palavras que o público busca: Super Jogo da Velha /
  Ultimate, "XO", "2 jogadores", "contra a CPU", "grátis e offline".
- **Descrição longa:** abre com o Super Jogo da Velha; seções de modos, oponentes, economia
  (moedas, visuais, bônus) e idiomas. Sem nomes de marcas ou lojas de terceiros (rejeição por
  keyword spam). Sem travessão.
- **Fonte dos textos:** `docs/store-listing/` (um `.txt` por idioma + `short.json` +
  `icon-512.png`). Publicados em 2026-10-04.
- **Notas de versão por idioma**, nunca um texto só replicado.
- **Data safety e política de privacidade** andam junto com o código (ver
  `docs/data-safety.md`): mexeu em SDK, permissão ou algo que sai do aparelho, refaz os dois
  na mesma tarefa. Moedas, visuais e bônus ficam só no aparelho e não mudam a declaração. As
  compras (v1.13.0) também não mudam o formulário: pagamento é do Google Play e o token fica no
  aparelho; a política ganhou a seção 2.3.

## 10. Política de lançamento

**Regra do dono (2026-10-04): toda versão vai para produção a 100%. Todos os jogadores
sempre atualizados.** Nada de lançamento gradual (20%, 50%): ele deixou 80% da base presa na
v20 por um mês enquanto a v22 ficava em 20%.

Fluxo: build assinado (`2A:B5:8C:02…`) → track interno → produção a 100% com a ficha e o
ícone atualizados no mesmo passo quando a versão muda o que a ficha descreve. O app também
avisa o jogador ao abrir quando há versão nova.

## 11. Métricas e estado atual (2026-10-03)

- ~1.850 instalações na vida, quase todas compradas pela campanha do Google Ads (pausada pelo
  dono em 27/08/2026, ~R$300 gastos).
- AdMob, últimos 30 dias: US$0,08, 198 impressões (~10 por dia), eCPM US$0,41. Premiado com
  0 impressões até a v1.12.0.
- Ficha sem nota visível (avaliações insuficientes); pedido de avaliação nativo depois de
  vitória contra a CPU, a partir de 5 partidas e da 2ª sessão, uma vez só.
- O app não tem analytics próprio: retenção D1/D7 é desconhecida.

O que medir depois da v1.12.0: impressões de premiado por unidade (`admob.py report --by
AD_UNIT`), receita diária, crashes na Play Console.

## 12. Roadmap

Em ordem de impacto, da pesquisa de 2026-10-03:
1. ~~Compra "remover anúncios"~~ feita na v1.13.0, junto com os pacotes de moedas.
2. **Teste A/B do ícone** novo contra o antigo pelo Store Listing Experiments.
3. ~~Desafio diário do Super Jogo da Velha~~ feito na v1.14.0 ("vença em N jogadas") usando a sequência de
   dias que já existe.
4. ~~Compartilhar vitória~~ feito na v1.14.0 (imagem do tabuleiro + link com `utm_source=share`).
5. ~~Tutorial do Super Jogo da Velha~~ feito na v1.14.0 (jogável, na 1ª abertura e no "?").
6. Também na v1.14.0: modos 4x4 e Cinco em linha, temas de tabuleiro, pacote de boas-vindas, pedido de
   avaliação também após conquista.
7. **Próximo:** medir D1/D7 pelo servidor por 2 semanas antes de decidir campanha paga.
8. **App open ad** só a partir da 2ª sessão, com limite de frequência, medindo D1 antes e
   depois.
9. **Multiplayer online** (Fase 3, servidor próprio no VPS) quando houver base ativa que o
   justifique.

## 13. Histórico de versões relevantes

| Versão | Data | O que trouxe |
|---|---|---|
| 1.6.0+15 | 2026-07-17 | Hindi; correção de estatística inflada |
| 1.9.1+20 | ago/2026 | AdMob reativado |
| 1.10.0+21 / 1.10.1+22 | 2026-08-27 | Premiado "dobrar XP"; contador de intersticial global |
| 1.11.0+23 a 1.11.2+25 | 2026-09-25/26 | Passe de game feel (sons, música, vibração, partículas, confete, sequências); botão de atualizar sempre visível; aviso de versão nova |
| **1.12.0+26** | **2026-10-03/04** | **Moedas, loja de 5 visuais, bônus diário de 7 dias, premiado dobra XP e moedas, home compacta, ícone novo, ficha nova. Produção a 100%.** |
| **1.13.0+27** | **2026-10-04** | **Compras na Play (sem anúncios + 3 pacotes de moedas), Neon vira o visual inicial e Aurora custa 50, música 10 dB abaixo dos efeitos** |
| **1.14.0+28** | **2026-10-04** | **Servidor de compras (valida na Play, desfaz reembolso, mede retenção), pacote de boas-vindas, desafio do dia, tutorial jogável do Super, compartilhar vitória, modos 4x4 e Cinco em linha, temas de tabuleiro, Aurora vira o visual mais caro (1000) e sai de uso de todos** |
