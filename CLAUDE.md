# CLAUDE.md - Tic Tac Verse

Jogo da velha multiverso em Flutter, publicado na Play Store como
`com.bobagi.tictacverse`. É o app do portfolio com expectativa real de receita,
então **anúncio e loja são caminho crítico, não detalhe**.

> **Onde ver os painéis (Google Ads, AdMob, Play): [`docs/paineis.md`](docs/paineis.md).**
> Tem link direto de cada console, o que a API já responde sem abrir navegador,
> e o que só o operador consegue fazer clicando.

## Comandos

```bash
flutter test                  # suíte inteira
flutter analyze               # tem que ficar em ZERO erro e ZERO warning
flutter gen-l10n              # regenera lib/l10n/app_localizations*.dart após mexer nos .arb
flutter build appbundle --release
```

Na VPS de build, o Gradle precisa de ajuda: o box tem 0 swap, então crie um
swapfile temporário antes e remova depois, e use
`ANDROID_HOME=/opt/android-sdk GRADLE_USER_HOME=/opt/.gradle` com JDK 21. O
`android/gradle.properties` costuma ter um teto de heap **editado localmente que
NÃO deve ser commitado**. O keystore de release fica fora do repo, na máquina de
build.

## Como o código está organizado

- `lib/models/` - dados puros (`GameState`, `ProgressState`, `AchievementDefinition`).
  Sem Flutter, sem plugin.
- `lib/services/` - regra e integração. `progression_engine.dart` é **função pura
  sobre `ProgressState` com relógio injetável**, o que permite testar XP, nível e
  conquistas sem widget e sem esperar a virada do dia. Mantenha assim.
- `lib/controllers/` - um controller por formato de anúncio, mais o `GameController`.
- `lib/ui/screens/` e `lib/ui/widgets/`.
- `lib/l10n/` - ARB por idioma. **`lib/localization/` é sistema morto e duplicado,
  não use** (está no backlog para deletar).

Modos: `classic`, `shift`, `chaos`, `ultimateMini`, `ultimate2`. O **`ultimate2`
(Super Jogo da Velha) é o carro-chefe** por diretriz do dono: campanha, criativo e
screenshot giram em torno dele, e ele rende 50% mais XP de propósito.

## Idiomas

Seis: `pt`, `en`, `es`, `hi`, `bn`, `ne`. Hindi, bengali e nepali não são enfeite,
são o público real do app (Índia, Bangladesh e Nepal lideram as instalações).

**Consequência prática que já pegou bug:** esses idiomas têm string mais longa que
o inglês em que a UI foi desenhada. Ao mexer em layout, teste a matriz **idioma x
tela**, não só tela. O jeito de travar isso sem emulador é renderizar o widget num
viewport fixo e afirmar que nenhuma exceção de layout foi lançada
(`expect(tester.takeException(), isNull)`), como em `test/game_over_modal_test.dart`.

## Anúncios: as regras que não se quebram

A conta do AdMob **já foi suspensa uma vez** (julho de 2026, "Invalid activity:
self-clicking"). Reincidência é **encerramento permanente**, com retenção de até
60 dias de ganhos.

- **NUNCA clique nos próprios anúncios.** Aparelho de teste se cadastra no AdMob
  **antes** de abrir o app.
- Anúncio premiado é **opt-in**: só abre por toque, o rótulo diz o que o jogador
  ganha, e a recompensa é por **assistir**, nunca por clicar. O crédito acontece
  só no callback de recompensa do SDK (`showForReward()` devolve `bool` justamente
  para não existir jeito de creditar no escuro).
- **Sem encadear anúncios:** a oferta de premiado é suprimida na partida em que o
  intersticial realmente apareceu. Por isso `showInterstitialAdIfAvailable()`
  devolve `bool`: "mandei exibir" não é "exibiu".
- O convite de anúncio **não pode imitar nem encostar** no botão primário. A folga
  mínima é asserção de teste, não avaliação visual.
- `AdsConfiguration` tem kill switch (`adsSuspended`) e `--dart-define=ADS_MODE=off|test|real`.
  Build de release serve anúncio **real**, todo o resto serve **teste**.
- Os ids reais ficam em `lib/services/ad_unit_id_provider.dart`. Conferi-los contra
  o painel é `admob.py adunits`.

## Segurança de dados (Data safety) e privacidade

O app **coleta e compartilha dados**, porque serve anúncios. Declarar "nenhum
dado" é exatamente o erro que gerou o aviso de política de **24/09/2026**
(*Invalid Data safety form*, tipo *Device or other IDs*, prazo 08/10/2026): o
Google detectou o `com.google.android.gms.permission.AD_ID` que o Mobile Ads SDK
**mescla sozinho** no manifest final e não achou a declaração correspondente.
O app estava certo; a declaração estava errada.

O que sai do aparelho, resumido: Advertising ID, app set ID e id de conta
logada, IP (vira localização aproximada), interações, diagnóstico e crash, tudo
pelo Google Mobile Ads SDK; mais player ID, conquistas e nível pelo Play Games.
Nada mais: o app **não tem cliente HTTP próprio, backend, Firebase, Crashlytics
nem analytics**, e `shared_preferences` e `MetricsService` não saem do aparelho.

Declaração completa, campo por campo, com o passo a passo da Play Console:
[`docs/data-safety.md`](docs/data-safety.md). Texto publicado da política:
[`docs/privacy-policy.md`](docs/privacy-policy.md) (publicado no gist cuja URL
está na ficha da Play; **não trocar a URL**).

**Regra que não se quebra:** Data safety, política de privacidade e código são
**um só pacote**. Mexeu em SDK, plugin, permissão do manifest ou em qualquer
coisa que passe a sair do aparelho? Na mesma tarefa: atualize
`docs/data-safety.md`, refaça o formulário na Play Console, atualize
`docs/privacy-policy.md` e republique a política. A Play Developer API **não
cobre Data safety**, então isso é sempre manual e é sempre o passo que alguém
esquece. Conferência rápida do que o SDK mescla de verdade:

```bash
grep -oE '<uses-permission[^>]*android:name="[^"]*"' \
  build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml
```

## Play Games Services

Ligado. As 16 conquistas e o placar foram criados por `tool/play_games_setup.py`,
e os ids gerados vivem em `lib/services/play_games_ids.dart`. **Não edite esse
arquivo à mão**: ele é o registro de verdade que a ferramenta usa para casar as
conquistas e evitar duplicá-las.

**O local é a fonte da verdade; o Play Games é espelho.** A sincronização é
sempre "fire and forget": o estado já foi gravado localmente antes, então falha lá
não segura nem desfaz nada aqui. Detalhes e pendências em
[`docs/play-games.md`](docs/play-games.md).

## Testes

Priorize o que quebra dinheiro ou progressão: crédito de recompensa, XP, nível,
desbloqueio de conquista, guardas de fim de partida. Um teste só vale se **pode
falhar**: ao escrever, quebre a regra que ele cobre no código e confirme que ele
fica vermelho. Se não ficar, é teatro.

## Loja

O título da ficha é **só "Tic Tac Verse"**, sem subtítulo, em todos os idiomas
(ordem do dono). Não enumere nomes de lojas ou marcas de terceiros na descrição:
é rejeição por keyword spam.

Notas de versão vão **por idioma**, não um texto só replicado. A skill
`google-play` aceita `--notes-file` com JSON `{"pt-BR": "...", "en-US": "..."}`.

## Decisões do dono que não se reabrem

- A CPU "Impossível" do Clássico é **imbatível de propósito**. É provocação
  intencional, não bug.
- A campanha do Google Ads roda **sem segmentação geográfica**. A recomendação de
  segmentar já foi dada com dado na mão; a escolha de manter é dele.
