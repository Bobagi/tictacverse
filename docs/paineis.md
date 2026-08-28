# Painéis do Tic Tac Verse (onde ver cada coisa)

Mapa dos consoles do app, com link direto. Serve para abrir do navegador do
operador, onde ele já está logado.

> **Por que este arquivo existe:** o Claude que roda na VPS **não abre navegador
> logado no Google**, de propósito (anti-bot e 2FA podem travar a conta dona do
> Play e do AdMob, e é a conta que paga). Da VPS ele lê tudo por **API oficial**.
> Quando alguma coisa só existe na UI, quem clica é o operador. Este documento é
> a ponte: na máquina pessoal, o Claude pode abrir estes links no Chrome do
> próprio operador, com ele presente.

## Google Ads

| O quê | Link |
|---|---|
| Seletor de contas | https://ads.google.com/aw/accounts |
| Campanhas | https://ads.google.com/aw/campaigns |
| Visão geral | https://ads.google.com/aw/overview |
| Faturamento | https://ads.google.com/aw/billing/summary |

**Armadilha que já custou uma confusão:** existem DUAS contas visíveis, e só uma
tem campanha.

- A **conta do app** é onde `tictacverse-campanha1` está.
- A outra é a **MCC "Bobagi"**, criada só para obter o developer token da API.
  **Ela não tem campanha nenhuma.** Se o painel abrir nela, a tela fica vazia e
  parece que a campanha acabou. Sempre confira qual conta está selecionada antes
  de concluir qualquer coisa.

Os números das contas e o id da campanha **não ficam neste repositório, que é
público**. Eles estão em `~/.config/bobagi-google/gads-config.json` na VPS (chmod
600), aparecem no seletor de contas do painel, e saem de
`gads.py accounts` / `gads.py campaigns`. Para abrir direto numa conta, o painel
aceita `?__c=<customer_id sem hífens>` na URL.

Se o navegador tiver mais de uma conta Google logada, acrescente
`&authuser=<seu e-mail>` na URL, ou use janela anônima.

## AdMob e Play

| O quê | Link |
|---|---|
| AdMob | https://apps.admob.com |
| Play Console | https://play.google.com/console |
| Ficha pública na Play | https://play.google.com/store/apps/details?id=com.bobagi.tictacverse |

No AdMob, o que costuma interessar é **Apps → Tic Tac Verse → Unidades de
anúncio**. No Play Console, o estado da versão fica em **Versão → Produção**.

## O que a API já responde (não precisa abrir painel)

Da VPS, sem navegador, as skills leem direto:

```bash
# Google Ads: status, gasto por dia, CPI, desempenho por grupo
python3 ~/.claude/skills/google-ads/scripts/gads.py campaigns
python3 ~/.claude/skills/google-ads/scripts/gads.py daily --days 30
python3 ~/.claude/skills/google-ads/scripts/gads.py groups --days 30
python3 ~/.claude/skills/google-ads/scripts/gads.py search --gaql "<GAQL>"

# AdMob: receita, eCPM, impressões por dia / unidade / país
python3 ~/.claude/skills/admob/scripts/admob.py report --days 30
python3 ~/.claude/skills/admob/scripts/admob.py report --days 30 --by AD_UNIT
python3 ~/.claude/skills/admob/scripts/admob.py report --days 30 --by COUNTRY

# Play: tracks, releases, rollout, avaliações, ficha
python3 ~/.claude/skills/google-play/scripts/gplay.py tracks
python3 ~/.claude/skills/google-play/scripts/gplay.py reviews
```

Regra prática: **para LER, use a API** (é mais rápido, dá para cruzar dados e não
arrisca a conta). O painel é para o que a API não faz.

## O que só existe na UI (o operador clica)

A API oficial não cobre, e não adianta insistir:

- **Google Ads:** criar, pausar ou editar campanha, orçamento, segmentação por
  local ou idioma, criativos. A skill `google-ads` é **somente leitura** por
  decisão de projeto.
- **AdMob:** criar ou editar unidade de anúncio e grupos de mediação (a API
  devolve 403 para conta sem gerente), pagamentos, dados fiscais, central de
  políticas, status do app-ads.txt, dispositivos de teste.
- **Play Console:** Data safety, responder a certos avisos de política,
  Serviços de jogos (publicar, subir ícone de conquista).

## Renovar o acesso da API quando um token morrer

Acontece: o `gads-token.json` morreu com `invalid_grant` em 2026-08-25. A VPS não
pode fazer login no Google, então o fluxo que funciona é:

1. O Claude gera a URL de consentimento a partir do OAuth client local.
2. O operador abre no navegador dele e aceita.
3. O navegador redireciona para `http://localhost:8765/?code=...` e **dá erro de
   página**, que é o esperado (não há servidor nesse endereço).
4. O operador cola a **URL inteira** de volta, e o Claude troca o `code` pelo
   refresh token.

Isso evita o `input()` interativo do `gads.py auth`, que trava se for executado
de dentro da sessão. O `code` expira em poucos minutos, então faça de uma vez.
Se a resposta vier sem `refresh_token`, revogue o acesso antigo em
https://myaccount.google.com/permissions e repita.
