# Play Games Services (conquistas, placar e identidade)

Estado: **ligado e funcionando**. Faltam dois passos manuais no Console
(ícones e publicar), listados no fim.

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
ninguém.

## Configuração desta instalação

| Item | Valor |
|---|---|
| ID do aplicativo (PGS) | `1050584273275` |
| Projeto GCP | `1050584273275` (mesmo número) |
| Conquistas | 16, criadas via API |
| Placar de nível | `CgkI-6LP3ckeEAIQEQ` |
| SHA-1 da chave de assinatura | `36:F0:B9:9D:D0:D0:28:83:4D:CF:27:A0:38:4E:B9:26:AF:03:94:FB` |
| SHA-1 da chave de upload | `F4:28:B1:17:A1:37:D2:9D:F8:A0:F7:4E:D7:49:D9:11:1D:94:F9:73` |

O `APP_ID` está no `AndroidManifest.xml` como referência ao recurso
`@string/game_services_app_id` (em `android/app/src/main/res/values/strings.xml`),
que é o formato que o SDK exige.

> **Cadastre os DOIS SHA-1 como credenciais Android no projeto do PGS.** O da
> chave de assinatura faz funcionar para quem instala pela Play; o da chave de
> upload faz funcionar nos APKs que buildamos aqui para teste. Com só um deles,
> o login silencioso falha justamente no cenário que você não cadastrou, e a
> falha é silenciosa (o app funciona, só não sincroniza).

## Como o código está organizado

- `lib/services/play_games_ids.dart` é **gerado** pela ferramenta. Não editar à
  mão: rode `tool/play_games_setup.py` de novo depois de mexer no catálogo.
- `lib/services/game_services_bridge.dart` é a ponte (login silencioso, espelho
  de conquistas, placar, UI nativa).
- **O estado local é a fonte da verdade; o Play Games é só espelho.** Falha de
  rede, login recusado ou serviço ausente nunca alteram nem seguram a
  progressão. Todos os guards estão travados por teste com mutation check.
- `ProgressionService` espelha os desbloqueios novos a cada partida e o conjunto
  **inteiro** a cada boot, porque desbloquear no PGS o que já está desbloqueado
  é no-op. Assim quem jogou offline sincroniza no primeiro boot com login.

## A ferramenta

```bash
cd /opt/tictacverse
python3 tool/play_games_setup.py --app-id 1050584273275 --dry-run             # confere
python3 tool/play_games_setup.py --app-id 1050584273275 --write-dart          # cria o que falta
python3 tool/play_games_setup.py --app-id 1050584273275 --create-leaderboard --write-dart
python3 tool/play_games_setup.py --app-id 1050584273275 --sync-translations   # reenvia textos
```

Lê o catálogo de `lib/models/achievement.dart` e os textos já traduzidos das
ARB, então cria tudo de uma fonte só. Recusa rodar se a tabela dela divergir do
catálogo Dart, apontando qual id saiu de sincronia.

### Duas armadilhas descobertas na prática

**1. O `token` que você manda no insert não volta na listagem.** O Google o
substitui por um opaco próprio. Se a idempotência depender dele, rodar a
ferramenta duas vezes **duplica todas as conquistas**. Por isso o casamento é
feito, nesta ordem: pelo mapa em `play_games_ids.dart` (que é o registro de
verdade) e, como reserva, pelo nome em en-US.

**2. O projeto do PGS nasce só com `en-US` habilitado.** Mandar outro idioma
devolve `400 UnsupportedLocale`. A ferramenta trata isso derrubando o idioma
recusado e seguindo, e **avisa em voz alta** quais ficaram de fora, em vez de
falhar tudo ou fingir sucesso.

## Pendências no Console

### 1. Habilitar os outros 5 idiomas (opcional, mas recomendado)

Hoje as 16 conquistas e o placar existem **só em inglês**, porque o projeto do
PGS só aceita `en-US`. Para ter pt-BR, es-ES, hi-IN, bn-BD e ne-NP:

Play Console → Serviços de jogos do Play → Configuração → seção de **idiomas /
traduções** → adicionar os 5. Depois, aqui:

```bash
python3 tool/play_games_setup.py --app-id 1050584273275 --sync-translations
```

Os textos já estão traduzidos nas ARB, então é só rodar.

### 2. Ícone de cada conquista (obrigatório para publicar)

512x512 por conquista. O Console exige, e não há API para subir isso em lote.

### 3. Publicar os Serviços de jogos (obrigatório)

Até publicar, as conquistas **só valem para contas de teste**. Adicione seu
próprio e-mail como testador em Serviços de jogos → Testadores, senão nem você
vê acontecer no seu aparelho.

### 4. Segurança de dados

O formulário da Play precisa refletir que o app passou a usar identificadores do
Play Games. Isso é no Console e não tem API.

## Orçamento de pontos

O Play Games limita a soma de pontos de **todas** as conquistas a 1000. A divisão
atual (bronze 25, prata 50, ouro 100) soma **925**, deixando folga para uma ou
duas novas. A ferramenta recusa rodar se a soma passar de 1000.
