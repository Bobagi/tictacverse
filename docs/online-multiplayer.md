# Jogo online contra pessoas reais: investigação (2026-10-04)

Pedido do dono: investigar o que seria necessário para jogar online contra pessoas reais, se faz
sentido, e o que entra junto (perfil, placar, etc.). **Nada foi implementado.**

## Resposta curta

Faz sentido, mas **não no formato "achar um adversário agora"** enquanto a base for pequena. Hoje o
jogo tem por volta de 6 impressões de anúncio por dia (AdMob, 30 dias até 04/10/2026), o que indica
poucas pessoas abrindo o app por dia. Partida ao vivo precisa de duas pessoas procurando partida no
MESMO minuto: com essa base, a fila ficaria vazia quase sempre e o jogador desistiria esperando.

O caminho que funciona com qualquer tamanho de base, na ordem:

1. **Desafie um amigo (por link, partida por turnos)**: o jogador manda um link no WhatsApp, o amigo
   instala/abre e joga; cada um faz a jogada quando puder. Não precisa de fila, e cada desafio é
   divulgação de graça (o canal que mais pesa na Índia e em Bangladesh).
2. **Partida por turnos contra desconhecidos + placar com ranking (Elo)**: o jogo junta pessoas que
   estão esperando adversário, sem precisar estarem online ao mesmo tempo.
3. **Partida ao vivo com fila (matchmaking)**: só quando houver base para isso. Regra prática:
   ~1.000 jogadores por dia já dão gente na fila em horário de pico; abaixo disso, ao vivo frustra.

## O que já existe e ajuda

| Peça | Situação |
|---|---|
| Identidade sem login | **Play Games v2 já está ligado**: entra em silêncio, dá id de jogador só deste jogo, apelido e foto. Nada de e-mail nem senha |
| Prova de identidade para o servidor | O plugin já tem `GameAuth.getAuthCode(clientId)`: o app pega um código, o servidor troca no Google e confirma o id do jogador. Falta criar um client OAuth "Web" no projeto GCP 1050584273275 |
| Servidor | `tictacverse-api` (Node 22 + Express + SQLite, Docker, :3066) já existe e já conversa com o Google. O online seria um módulo novo nele (ou um serviço irmão) |
| Regras do jogo | Motores puros em Dart (`lib/controllers/modes/*`, `ultimate2_engine.dart`, `line_rules_engine.dart`), com testes |
| Placar | 1 placar de nível no Play Games. Ranking de online precisaria de placar novo |
| Multiplayer do Play Games | **Não existe**: o Google desligou turnos e tempo real em 31/03/2020 |

## O que precisaria ser feito

### 1. Perfil
- Identidade = Play Games (id do jogador verificado no servidor pelo `getAuthCode`). Quem recusar o
  Play Games joga offline como hoje; o online exige estar conectado.
- Perfil mínimo: apelido e foto do Play Games, nível, visual de peça em uso (já existe), número de
  vitórias online e rating.
- **Sem apelido digitado e sem chat livre**: evita moderação de conteúdo e mudança de classificação
  etária. No lugar do chat, emojis prontos ("Boa!", "Ops", "GG").
- Exclusão de conta obrigatória pela política da Play (app com conta): botão no app + página web
  com o mesmo pedido.

### 2. Servidor de partidas
- **O servidor é o juiz**: valida toda jogada com as mesmas regras do app. Para não manter duas
  cópias divergentes, a opção mais segura é compilar o motor Dart para o servidor
  (`dart compile exe`, ou `dart compile js` rodando no Node) e usar os MESMOS testes; a alternativa é
  portar para TypeScript com uma bateria de partidas-gabarito rodando nos dois lados.
- Partida por turnos: REST (`criar desafio`, `jogar`, `estado`), relógio por jogada (ex.: 24 h no
  modo por turnos), desistência por tempo.
- Ao vivo (fase 3): WebSocket (o nginx e o Cloudflare já passam WebSocket), relógio de 30 s por
  jogada, reconexão, vitória por abandono após 60 s fora.
- Anti-trapaça: jogada só vale se o servidor aceitar; limite de requisições; partidas e resultados
  só gravados pelo servidor.

### 3. Fila e ranking
- Fila por modo (começar só com o carro-chefe, Super Jogo da Velha, e o Clássico) e por faixa de
  rating.
- Rating Elo (ou Glicko-2) calculado no servidor; o placar do Play Games fica como espelho (ele não
  pode ser a fonte, porque o próprio app envia a nota).
- Placares: semanal e geral, por país opcional.

### 4. Aviso de "sua vez" (para o modo por turnos)
- Sem push: o app confere ao abrir e a cada poucos segundos enquanto está aberto. Simples e sem
  novo SDK.
- Com push: Firebase Cloud Messaging. Traz o SDK do Firebase, muda o Data safety e a política, e
  aumenta muito o retorno ao jogo. Recomendo começar sem e decidir pelo número de partidas
  abandonadas.

### 5. Papelada que vem junto
- **Data safety**: passa a declarar id de jogador do Play Games enviado ao nosso servidor, partidas
  e resultados (App activity), apelido (Personal info → Name, se exibido a outros jogadores).
- **Política de privacidade**: seção do online (o que outros jogadores veem: apelido, foto, nível,
  rating).
- **Classificação etária (IARC)**: responder de novo o questionário marcando que usuários
  interagem; sem chat livre o impacto é pequeno.
- **Exclusão de conta**: página web + fluxo no app (exigência da Play para apps com conta).

### 6. Testes
- Motor do servidor = motor do app (mesmas partidas-gabarito).
- Corrida: duas jogadas simultâneas na mesma partida (só uma vale), jogada fora de vez, jogada em
  partida encerrada, replay de requisição.
- Dois aparelhos reais (ou dois clientes no navegador) jogando uma partida inteira.

## Esforço estimado (em sessões de trabalho como a de hoje)

| Fase | Inclui | Esforço |
|---|---|---|
| A. Desafie um amigo por link (turnos) | identidade verificada, partidas por turnos no servidor, link de convite, tela de partidas em andamento, Data safety/política | 2 a 3 |
| B. Turnos contra desconhecidos + ranking | fila assíncrona, Elo, placar semanal/geral, perfil, emojis | 2 a 3 |
| C. Ao vivo | WebSocket, relógio, reconexão, fila em tempo real | 2 a 4 |

Custo de infraestrutura: o VPS atual aguenta com folga milhares de partidas por turnos; ao vivo
também, na escala esperada.

## Recomendação

1. Colocar a v1.14 em produção e **medir 2 semanas de D1/D7** pelo servidor (`npm run stats`).
2. Se a retenção estiver razoável, fazer a **Fase A (desafie um amigo)**: é a que traz instalação
   nova de graça e funciona com a base atual.
3. Fase B quando houver algumas centenas de jogadores por dia; Fase C só perto de 1.000 por dia.

Pré-requisitos do dono antes da Fase A: domínio do servidor no ar (`deploy/setup-domain.sh`) e um
client OAuth "Web" no projeto GCP 1050584273275 (para o `getAuthCode`).
