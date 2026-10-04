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

**Loja de visuais das peças** (`lib/models/piece_skin.dart`). Visual só muda aparência,
nunca dá vantagem.

| Visual | Preço | Estilo |
|---|---|---|
| Aurora | grátis | as artes PNG originais |
| Neon | 120 | traço fino com miolo branco, ciano e rosa |
| Fogo e gelo | 250 | degradê laranja/amarelo e azul/branco |
| Bala | 350 | traço grosso arredondado com reflexo, menta e morango |
| Ouro e prata | 500 | degradê metálico |
| Galáxia | 800 | degradê violeta/ciano com anel interno e brilhos |

Comprar debita o preço exato e já equipa. Visual comprado vale em todas as telas de jogo
(tabuleiro, Super Jogo da Velha, avatar, modal de fim).

**Bônus diário:** ciclo de 7 dias pagando 20, 25, 30, 40, 50, 60 e 100 moedas. Resgatar em
dias seguidos avança; pular um dia volta ao dia 1; depois do 7º o valor recomeça, mas a
contagem continua. Um resgate por dia. Voltar a data do aparelho não libera outro.

**Ritmo pretendido:** uma vitória rende ~12 moedas e o bônus 20 a 100, então o primeiro
visual sai na primeira ou segunda sessão e o mais caro vira meta de algumas semanas.

## 6. Monetização

Só anúncio (Google AdMob). Compras dentro do app: ainda não (ver Roadmap).

| Formato | Onde | Regra |
|---|---|---|
| Banner / retângulo médio | Base da home, da seleção de modo e das telas de jogo | 300x250 só com tela >= 380x760; abaixo, banner 320x50 |
| Intersticial | Fim de partida | A cada 3 partidas (contador global, sobrevive à troca de tela) |
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
  Gerado por `tool/icon/make_app_icon.py` em camadas (fundo e peças) para o ícone adaptativo.
- **Configurações:** abrem sempre por `showSettingsSheet()`; "Buscar atualizações" é o
  primeiro item e tem de estar visível sem rolar em toda tela e idioma.

## 8. Game feel

Detalhes técnicos no `CLAUDE.md`, seção "Game feel".
- Sons Kenney (CC0) em toda ação; 8 músicas CC0 em playlist embaralhada. Só entra faixa CC0
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
  na mesma tarefa. Moedas, visuais e bônus ficam só no aparelho e não mudam a declaração.

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
1. **Compra "remover anúncios"** com preço regional (~US$0,99; ~INR 49 a 99). Exige refazer
   Data safety e política de privacidade na mesma tarefa.
2. **Teste A/B do ícone** novo contra o antigo pelo Store Listing Experiments.
3. **Desafio diário do Super Jogo da Velha** ("vença em N jogadas") usando a sequência de
   dias que já existe.
4. **Compartilhar vitória / convidar amigo** (sem servidor).
5. **Tutorial do Super Jogo da Velha** no primeiro uso (regra menos óbvia do carro-chefe).
6. **App open ad** só a partir da 2ª sessão, com limite de frequência, medindo D1 antes e
   depois.
7. **Multiplayer online** (Fase 3, servidor próprio no VPS) quando houver base ativa que o
   justifique.

## 13. Histórico de versões relevantes

| Versão | Data | O que trouxe |
|---|---|---|
| 1.6.0+15 | 2026-07-17 | Hindi; correção de estatística inflada |
| 1.9.1+20 | ago/2026 | AdMob reativado |
| 1.10.0+21 / 1.10.1+22 | 2026-08-27 | Premiado "dobrar XP"; contador de intersticial global |
| 1.11.0+23 a 1.11.2+25 | 2026-09-25/26 | Passe de game feel (sons, música, vibração, partículas, confete, sequências); botão de atualizar sempre visível; aviso de versão nova |
| **1.12.0+26** | **2026-10-03/04** | **Moedas, loja de 5 visuais, bônus diário de 7 dias, premiado dobra XP e moedas, home compacta, ícone novo, ficha nova. Produção a 100%.** |
