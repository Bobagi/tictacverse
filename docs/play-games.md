# Play Games Services (conquistas, placar e identidade)

O que está pronto no código e o que falta fazer no Console para ligar.

## O que o Play Games resolve, e o que ele não resolve

| Precisa de | Play Games entrega? |
|---|---|
| Conquistas sincronizadas entre aparelhos | sim |
| Placar (leaderboard) | sim |
| Save na nuvem | sim (não usamos ainda) |
| **Identidade do jogador** (apelido e foto, sem tela de login) | **sim, e é o ponto principal** |
| Multiplayer em tempo real ou por turnos | **não.** Desligado pelo Google em 31/03/2020 |

A identidade é o que interessa para o multiplayer: o Play Games v2 autentica em
silêncio quando o jogo abre, sem botão e sem pop-up, e devolve um id de jogador
que **só vale dentro deste jogo**, mais o apelido público e a foto. Não vem
e-mail nem conta Google, então o app nunca passa a guardar credencial de
ninguém. Quem não tiver Play Games cai no caminho alternativo (apelido gerado e
editável), que ainda será construído junto do multiplayer.

## Estado atual do código

Tudo escrito e testado, **desligado por falta dos ids**:

- `lib/services/play_games_ids.dart` guarda o mapa `nosso id -> id do PGS`.
  **Nasce vazio**, e enquanto estiver vazio `playGamesConfigured` é falso.
- `lib/services/game_services_bridge.dart` é a ponte. Com a configuração
  ausente, todo método retorna cedo e **nada toca o canal nativo**, que é
  justamente onde moraria um crash em aparelho real. Isso está travado por
  teste (`test/game_services_bridge_test.dart`) com mutation check nos 4 guards.
- O estado local continua sendo a **fonte da verdade**; o Play Games é só um
  espelho. Se o login falhar, a rede cair ou o jogador recusar, a progressão
  funciona igual.
- `ProgressionService` espelha os desbloqueios novos a cada partida e o conjunto
  **inteiro** a cada boot, porque desbloquear no PGS o que já está desbloqueado
  não faz nada. Assim quem jogou offline sincroniza no primeiro boot com login.

## Passo a passo para ligar

### 1. Criar o jogo no Play Console (só você faz)

Play Console → o app → **Crescer → Serviços de jogos do Play → Configuração e
gerenciamento → Configuração**. Criar o jogo, vincular o app Android usando o
**SHA-1 da chave de assinatura do app** (a do Play App Signing, não a de upload),
e anotar o **ID do projeto**, um número longo.

### 2. Habilitar a API no projeto do Google Cloud (só você faz)

A ferramenta de automação usa a Publishing API do PGS, que vem desligada. Ela
mesma cospe o link exato quando tenta rodar sem isso:

```
https://console.developers.google.com/apis/api/gamesconfiguration.googleapis.com/overview?project=1050584273275
```

Esse `1050584273275` é o projeto onde vive a service account
`claude-play-publisher`, a mesma já usada para publicar na Play. Clicar em
**Ativar** e esperar alguns minutos.

### 3. Criar as 16 conquistas (automático)

```bash
cd /opt/tictacverse
python3 tool/play_games_setup.py --app-id <ID_DO_PROJETO> --dry-run   # confere
python3 tool/play_games_setup.py --app-id <ID_DO_PROJETO> --write-dart
```

A ferramenta lê o catálogo de `lib/models/achievement.dart` e os textos já
traduzidos das ARB, então cria as 16 conquistas **nos 6 idiomas de uma vez** (192
campos que ninguém precisa digitar). É idempotente: casa pelo `token`, que é o
nosso id estável, e só cria o que falta. No fim regrava
`lib/services/play_games_ids.dart`, e é esse arquivo que liga a integração.

Ela também recusa rodar se a tabela dela sair de sincronia com o catálogo Dart,
apontando exatamente qual id divergiu.

### 4. O que sobra de manual

- **Ícone de cada conquista** (512x512). O Console exige para publicar.
- **Publicar** as alterações dos Serviços de jogos. Antes disso as conquistas só
  valem para contas de teste.
- Criar o **placar de nível**, se quiser, e passar o id em `--leaderboard-id`.
- Adicionar o `APP_ID` no `AndroidManifest.xml`. **Ainda não está lá de
  propósito:** um APP_ID inválido pode derrubar o app no boot, e não há aparelho
  nem emulador nesta VPS para testar isso. Entra junto com o id real, num build
  que você valide no seu aparelho antes de subir para a Play.

```xml
<!-- dentro de <application>, com o valor vindo de um recurso de string -->
<meta-data android:name="com.google.android.gms.games.APP_ID"
           android:value="@string/play_games_app_id" />
```

### 5. Antes de publicar

O formulário de **Segurança de dados** da Play precisa refletir que o app passou
a usar identificadores do Play Games. Isso é no Console e não tem API.

## Orçamento de pontos

O Play Games limita a soma de pontos de **todas** as conquistas a 1000. A divisão
atual (bronze 25, prata 50, ouro 100) soma **925**, deixando folga para uma ou
duas conquistas novas antes de precisar rebalancear. A ferramenta recusa rodar se
a soma passar de 1000.
