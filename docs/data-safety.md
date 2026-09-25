# Segurança de dados (Data safety) - Tic Tac Verse

Este arquivo é a **fonte da verdade da declaração** enviada na Play Console em
`App content → Data safety`. A Play Developer API **não cobre** Data safety, então
a declaração é feita à mão. Se este arquivo e o formulário divergirem, o
formulário está errado.

> **Regra de manutenção:** mexeu em SDK, plugin, permissão do manifest ou
> passou a mandar qualquer coisa para fora do aparelho? Atualize **este
> arquivo**, o formulário na Play Console e a política de privacidade
> (`docs/privacy-policy.md`) na mesma tarefa. Foi a dessincronização disso que
> gerou o aviso de política de 24/09/2026.

## Por que esta declaração existe

Aviso do Google Play em **24/09/2026**, prazo **08/10/2026**:

- Issue: *Invalid Data safety form*.
- Área: *Version code 22: Policy Declaration - Data Safety Section: Device Or
  Other IDs Data Type*.
- Causa real: o app serve anúncios pelo Google Mobile Ads SDK desde a v1.0.4 e
  o formulário continuava declarando **"Nenhum dado coletado"**. O app está
  correto; a **declaração** estava errada.
- Consequência de não corrigir: updates passam a ser rejeitados.
- Não é caso de appeal. O caminho é corrigir a declaração. **Não precisa de
  build nova**: Data safety é declaração do app, não da versão.

## O que realmente sai do aparelho (auditado na v1.10.1+22)

Levantado no código e no manifest **mesclado** de release
(`build/app/intermediates/merged_manifests/release/...`), que é o que de fato
foi para o AAB.

| Componente | Versão | Sai do aparelho? | O que sai |
| --- | --- | --- | --- |
| `google_mobile_ads` (Google Mobile Ads SDK) | plugin 7.0.0, nativo `play-services-ads:24.9.0` | **Sim** | Advertising ID (GAID), app set ID, identificadores de conta logada, endereço IP, interações (abertura do app, toques, vídeo assistido), diagnóstico/desempenho |
| UMP (User Messaging Platform), via `ConsentService` | `user-messaging-platform:3.1.0` | **Sim** | Estado de consentimento, IP e dados de dispositivo para decidir região e formulário |
| `games_services` (Play Games Services v2) | plugin 5.1.0 | **Sim** | Player ID; conquistas desbloqueadas e nível enviados ao placar; analytics/diagnóstico do próprio SDK |
| `in_app_update` (Play Core) | 4.2.5 | Fluxo da própria Play Store | Checagem de update. Dado da Play Store, não dado do app |
| `in_app_review` (Play In-App Review) | 2.0.12 | Fluxo da própria Play Store | Avaliação, **iniciada pelo usuário** |
| `url_launcher` | 6.3.2 | Abre a ficha da Play no navegador | Nada do app |
| `shared_preferences` / `StorageService` | 2.5.5 | **Não** | Progressão, XP, conquistas, idioma, áudio: só no aparelho |
| `MetricsService` | interno | **Não** | Contadores em memória, zerados ao fechar |
| `audioplayers` | 6.8.1 | **Não** | Assets locais |

Confirmações que sustentam a declaração:

- O app **não tem nenhum cliente HTTP próprio**: zero `package:http`,
  `HttpClient`, `dio` ou socket em `lib/`. Não existe backend nosso.
- **Sem Firebase, Crashlytics ou Sentry.** Nenhum analytics próprio.
- **Sem permissão de localização** no manifest mesclado (zero `*_LOCATION`). A
  localização aproximada declarada é a **derivada do IP** pelo SDK de anúncios,
  não GPS.
- Permissões que o SDK de anúncios **mescla sozinho** no manifest final (não
  estão no nosso `AndroidManifest.xml`, por isso é fácil esquecer que existem):
  `com.google.android.gms.permission.AD_ID`,
  `android.permission.ACCESS_ADSERVICES_AD_ID`,
  `ACCESS_ADSERVICES_ATTRIBUTION`, `ACCESS_ADSERVICES_TOPICS`.
  **É o `AD_ID` que o scanner do Google viu e que motivou o aviso.**
- Em release, `ConsentService().gatherConsent()` e a init do SDK rodam no
  `main()` **antes** do `runApp`, sem toggle no app. Logo a coleta é
  **obrigatória (required)**, não opcional.

Fontes oficiais do que cada SDK coleta:
[Google Mobile Ads](https://developers.google.com/admob/android/privacy/play-data-disclosure),
[Play Games Services](https://developer.android.com/games/pgs/data-collection),
[definições do formulário](https://support.google.com/googleplay/android-developer/answer/10787469).

## A declaração exata

### Perguntas gerais

| Pergunta (rótulo em inglês) | Resposta |
| --- | --- |
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (os dois SDKs usam TLS/HTTPS, está escrito na doc do Google) |
| Do you provide a way for users to request that their data be deleted? | **No** |

Sobre o "No" da exclusão: o app não cria conta nem guarda dado nosso em
servidor algum, então não há o que pedir para excluir. Os caminhos que existem
são do próprio Google e estão escritos na política de privacidade (resetar ou
apagar o Advertising ID nas configurações do Android, apagar os dados do Play
Games no perfil do Play Games). A exigência de URL de exclusão de conta só vale
para app que permite criar conta, o que não é o caso.

### Tipos de dados a marcar

Marcar exatamente estes seis tipos, em quatro categorias:

#### 1. Location → Approximate location

| Campo | Resposta |
| --- | --- |
| Collected | **Yes** |
| Shared | **Yes** |
| Processed ephemerally | **No** |
| Required or optional | **Data collection is required** |
| Purposes | **Advertising or marketing**, **Analytics**, **Fraud prevention, security, and compliance** |

Por quê: o SDK de anúncios coleta o IP e o usa para estimar a localização geral.
**Não marcar `Precise location`** (não há permissão de localização no app).

#### 2. App activity → App interactions

| Campo | Resposta |
| --- | --- |
| Collected | **Yes** |
| Shared | **Yes** |
| Processed ephemerally | **No** |
| Required or optional | **Data collection is required** |
| Purposes | **Advertising or marketing**, **Analytics** |

Por quê: o SDK de anúncios coleta abertura do app, toques e vídeo assistido.

#### 3. App activity → Other actions

| Campo | Resposta |
| --- | --- |
| Collected | **Yes** |
| Shared | **No** |
| Processed ephemerally | **No** |
| Required or optional | **Data collection is optional** |
| Purposes | **App functionality** |

Por quê: conquista desbloqueada, nível e placar sobem para o Play Games
(`GameServicesBridge.mirrorUnlocked` e `submitLevel`). É **opcional** porque o
jogo funciona igual sem Play Games: o estado local é a fonte da verdade e todo
o espelho é fire-and-forget, então quem recusa o login joga normalmente.
`Shared` é **No** porque isso fica no Play Games do próprio jogador, não vai
para terceiro.

Não marcar os outros tipos de App activity: `In-app search history`,
`Installed apps` (não há `QUERY_ALL_PACKAGES`; o `<queries>` de `PROCESS_TEXT`
não é coleta) e `Other user-generated content`.

#### 4. App info and performance → Crash logs

| Campo | Resposta |
| --- | --- |
| Collected | **Yes** |
| Shared | **Yes** |
| Processed ephemerally | **No** |
| Required or optional | **Data collection is required** |
| Purposes | **Analytics**, **Fraud prevention, security, and compliance** |

Por quê: o app **não tem** SDK de crash próprio, mas os SDKs do Google reportam
os próprios erros. Declarar aqui é seguro e barato; o que gera aviso é declarar
de menos, nunca de mais.

#### 5. App info and performance → Diagnostics

| Campo | Resposta |
| --- | --- |
| Collected | **Yes** |
| Shared | **Yes** |
| Processed ephemerally | **No** |
| Required or optional | **Data collection is required** |
| Purposes | **Advertising or marketing**, **Analytics**, **Fraud prevention, security, and compliance** |

Por quê: a doc do Mobile Ads cita explicitamente tempo de inicialização, taxa
de travamento e consumo de energia. Não marcar `Other app performance data`.

#### 6. Device or other IDs → Device or other IDs

| Campo | Resposta |
| --- | --- |
| Collected | **Yes** |
| Shared | **Yes** |
| Processed ephemerally | **No** |
| Required or optional | **Data collection is required** |
| Purposes | **Advertising or marketing**, **Analytics**, **Fraud prevention, security, and compliance**, **App functionality** |

**É esta a linha que o aviso citou.** Cobre o Advertising ID (GAID), o app set
ID e os identificadores de conta logada do SDK de anúncios, mais o player ID do
Play Games (esse é o `App functionality`).

### O que NÃO declarar, e por quê

| Não marcar | Motivo |
| --- | --- |
| Personal info → Name, Email address | O apelido do Play Games **entra** no app vindo do Google; o app nunca o manda para fora (não há backend nem cliente HTTP). Receber não é coletar |
| Photos and videos | A foto do perfil do Play Games também só entra |
| Financial info | Não há compra no app |
| Messages, Contacts, Calendar, Health, Files, Audio, Web browsing | Nada disso é tocado |
| Qualquer coisa do `shared_preferences` (progressão, XP, idioma, áudio) e do `MetricsService` | Exceção de **on-device access/processing**: não sai do aparelho |
| `in_app_update`, `in_app_review`, `url_launcher` | Fluxos da própria Play Store, e a avaliação é iniciada pelo usuário |

### Armadilha a lembrar

Se o app algum dia entrar no programa **Designed for Families / Teacher
Approved**, o `AD_ID` passa a ser **proibido** e o manifest precisa removê-lo
explicitamente. Hoje ele é necessário para anúncio personalizado, que é a
receita do app, então fica.

## Passo a passo na Play Console

1. Abrir a **Play Console** e selecionar **Tic Tac Verse**.
2. Menu da esquerda: **Policy** (Política) → **App content** (Conteúdo do app).
3. Na linha **Data safety** (Segurança dos dados), clicar em **Manage**
   (Gerenciar) ou **Start**.
4. Tela **Overview**: ler e clicar em **Next**.
5. Tela **Data collection and security**:
   - *Does your app collect or share any of the required user data types?* →
     **Yes**
   - *Is all of the user data collected by your app encrypted in transit?* →
     **Yes**
   - *Do you provide a way for users to request that their data be deleted?* →
     **No**
   - **Next**.
6. Tela **Data types**: marcar somente estes seis e clicar em **Next**:
   - Location → **Approximate location**
   - App activity → **App interactions**
   - App activity → **Other actions**
   - App info and performance → **Crash logs**
   - App info and performance → **Diagnostics**
   - Device or other IDs → **Device or other IDs**
7. A Console abre uma tela **Data usage and handling** por tipo marcado.
   Preencher cada uma **exatamente** como nas tabelas acima (Collected, Shared,
   Processed ephemerally, Required/Optional, Purposes) e salvar.
8. Tela final de revisão: conferir o resumo contra este arquivo e clicar em
   **Save**.
9. Voltar em **App content** e confirmar que **Data safety** aparece como
   completo/atualizado.
10. Ir em **Publishing overview** (Visão geral da publicação) e clicar em
    **Send for review** (Enviar para revisão). Sem esse clique a alteração fica
    parada como mudança pendente.
11. Em **Policy status** (Status da política), acompanhar o aviso de
    *Invalid Data safety form* até ele sair. **Não abrir appeal**: o caminho é a
    correção. Prazo: **08/10/2026**.
12. Depois que a revisão passar, conferir a ficha pública: a seção
    *Segurança dos dados* deve deixar de dizer "Nenhum dado foi coletado" e
    passar a listar as categorias acima. Isso é o resultado esperado, não um
    problema.
