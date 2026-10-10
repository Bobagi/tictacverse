# Privacy Policy (texto publicado)

Este arquivo é a **fonte da verdade** da política de privacidade do Tic Tac
Verse. O texto abaixo (a partir de "Privacy Policy") é publicado em:

`https://gist.github.com/Bobagi/883ef342da9408ba82c933c3817af1d6#file-privacy-policy`

que é a URL declarada na ficha da Play Store. **Manter a URL**: trocá-la obriga
a mexer no campo de política de privacidade da Play Console.

Ele tem de bater linha a linha com `docs/data-safety.md`, porque o Google exige
que a política e a declaração de Segurança de dados digam a mesma coisa. Mexeu
em um, mexa no outro.

Atualizado em 10/10/2026 (v1.15.0): modo online (seção 2.5), servidor do
desenvolvedor só para quem abre o online, exclusão pelo próprio app (seções 4 e 6).
Antes: 05/10/2026 (v1.14.0), compras únicas e compartilhar vitória.

---

# Privacy Policy

**App:** Tic Tac Verse (`com.bobagi.tictacverse`)
**Developer:** Bobagi (Gustavo Perin)
**Contact:** bobagi.contact@gmail.com
**Effective date:** October 10, 2026
**Last updated:** October 10, 2026

## 1. Summary

Tic Tac Verse is a game intended for the general public. It does not require you
to create an account. The developer operates one server, used only by the
optional online mode (playing against a friend over the internet); if you never
open the online mode, nothing is sent to it. The app also shows advertising and
offers optional Google Play Games features and optional purchases through Google
Play, and those services transmit some data off your device. This policy explains exactly what
is transmitted, by whom, and for what.

## 2. Data collected and shared

The app collects no personal information such as your name, email or contacts.
The optional online mode sends the limited game data described in section 2.5 to
the developer's server. The rest of the data below is collected by Google
services embedded in the app, and it matches, category by category,
what is declared in the app's Data safety section on Google Play.

### 2.1 Advertising (Google Mobile Ads SDK / AdMob)

Collected and shared with Google and its advertising partners:

- **Device or other IDs:** Advertising ID (Android advertising identifier), app
  set ID, and identifiers of a signed-in account.
- **Approximate location:** your IP address, which is used to estimate the
  general location of the device. The app does **not** request GPS or any
  location permission, and it has no access to your precise location.
- **App interactions:** app launches, taps, and video views.
- **Crash logs and diagnostics:** performance information such as app launch
  time, hang rate, and energy usage.

Purposes: to display personalized or non-personalized advertisements, to measure
ad performance, analytics, and fraud prevention, security, and compliance.

### 2.2 Google Play Games Services (optional)

If Google Play Games is available on your device and you are signed in, the app
mirrors your progress there:

- **Other actions (gameplay data):** achievements you unlocked and your level,
  submitted to the game's achievements and leaderboard.
- **Device or other IDs:** your Play Games player ID, used to attach that
  progress to your Play Games profile.

Purposes: app functionality (achievements and leaderboard). This data stays in
your own Play Games account and is not shared with any third party by the
developer.

This is optional. Your progress is stored on your device first and the game
works identically if Play Games is unavailable or you decline to sign in.

### 2.3 In-app purchases (Google Play Billing)

The app offers optional one-time purchases (removal of ads, a welcome pack with
a piece style, and the full collection of styles and board themes). Payments are
handled entirely by Google Play under its own terms: the app never sees your
card number or any other payment details. To know what you own, the app asks
Google Play on your device, keeps that list only on your device, and never sends
it to the developer or anyone else. If a purchase is refunded, Google Play stops
listing it and the app removes what it unlocked. Your purchase history is
available in your Google Play account, and "Restore purchases" in the app asks
Google Play again, for example after reinstalling.

### 2.4 Sharing a victory

When you tap "Share" after a win, the app creates a picture of the board and
opens your phone's share menu. The picture goes directly from your device to the
app you choose; the developer does not receive it.

### 2.5 Online mode (optional, developer's server)

Only if you open "Challenge a friend online", the app talks to the developer's
server at `tictacverse.bobagi.space` over HTTPS. It sends and stores:

- **Device or other IDs:** a random anonymous identifier created by the server
  the first time you use the online mode (the server keeps only a one-way hash
  of it). It is not linked to your name, email, Google account or Advertising ID.
  Other players see you only as a randomly assigned animal emoji and number.
- **Other actions (gameplay):** the moves and results of your online matches,
  and your online win/loss/draw counts.

Your IP address reaches the server as part of any internet connection; it is
used only in memory to limit abusive request rates and is never stored or
logged. There is no chat and no free text. Purpose: app functionality (running
the match between you and your friend). This data is not shared with anyone
and is not used for advertising.

### 2.6 Data that never leaves your device

Your game progress, experience points, coins, purchased items, unlocked
achievements, chosen language, and sound settings are stored only on your
device, using the operating system's local storage. They are not transmitted
anywhere, the developer cannot see them, and they are removed when you uninstall
the app.

## 3. Who receives the data

Google LLC, through the Google Mobile Ads SDK (AdMob), the User Messaging
Platform, Google Play Games Services and Google Play Billing, and, for
advertising, Google's advertising partners. Their handling of data is governed
by their own policies:

- Google Privacy Policy: https://policies.google.com/privacy
- How Google uses information from sites or apps that use its services:
  https://policies.google.com/technologies/partner-sites

The developer receives only the online-mode data described in section 2.5, and
does not sell, share or transfer it.

## 4. Consent and your choices

- **European Economic Area, United Kingdom, and Switzerland:** the app shows a
  consent message from Google's User Messaging Platform before ads are
  personalized, and your choice is respected. If you decline personalization,
  the app still shows non-personalized ads, which still require a device
  identifier for frequency capping and fraud prevention.
- **Advertising ID:** you can reset it or delete it at any time in the Android
  settings, under Settings → Privacy → Ads (the exact path varies by
  manufacturer and Android version). Deleting it stops the app from receiving a
  personalized advertising identifier.
- **Play Games data:** you can review or delete the data associated with this
  game at https://play.google.com/games/profile, or delete your Play Games
  account at https://myaccount.google.com.
- **Online mode data:** open Settings in the app and tap "Delete my online
  data". This deletes your anonymous identifier, your statistics and your link
  to every match from the server immediately (open matches count as a loss).
  You can also request deletion by email at the address below.
- **Everything else:** uninstalling the app removes all locally stored data.

## 5. Security

All data collected by the services described above is encrypted in transit,
using TLS/HTTPS.

## 6. Data retention and deletion

Online-mode data (section 2.5) is kept only while useful: finished matches are
deleted from the server after 120 days, and an anonymous identifier that has
not been used for 400 days is deleted together with its statistics. You can
delete it at any time from the app (section 4). Retention of the advertising,
Play Games and purchase data described above is controlled by Google, and the
controls listed in section 4 and your Google Play account are the way to review
or delete it.

## 7. Children

This app is not directed to children under the age of 13, and the developer does
not knowingly collect personal information from children. If you believe a child
has provided information, contact the address below and it will be addressed.

## 8. Cookies

The app does not use cookies directly. Third-party services such as Google AdMob
may use cookies or similar technologies as described in their policies.

## 9. Changes to this policy

This policy may be updated when the app changes what it transmits. The effective
date above always reflects the current version, and the Data safety section on
Google Play is updated in the same change.

## 10. Contact

bobagi.contact@gmail.com
