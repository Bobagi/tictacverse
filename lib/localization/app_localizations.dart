import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale, this._messages);

  final Locale locale;
  final Map<String, String> _messages;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'), <String, String>{});
  }

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  static Future<AppLocalizations> load(Locale locale) async {
    final Locale chosenLocale = resolveSupportedLocale(locale);
    Intl.defaultLocale = chosenLocale.toLanguageTag();
    final Map<String, String> messages = await _loadMessagesForLocale(chosenLocale);
    return AppLocalizations(chosenLocale, messages);
  }

  static Locale resolveSupportedLocale(Locale? requestedLocale) {
    if (requestedLocale == null) {
      return supportedLocales.first;
    }

    for (final Locale supported in supportedLocales) {
      if (supported.languageCode == requestedLocale.languageCode) {
        return supported;
      }
    }
    return supportedLocales.first;
  }

  static Future<Map<String, String>> _loadMessagesForLocale(Locale locale) async {
    final String localeCode = locale.languageCode;
    const String fallbackPath = 'l10n/app_en.arb';
    final String localePath = 'l10n/app_$localeCode.arb';

    final String rawJson = await _safeLoadString(localePath) ?? await _safeLoadString(fallbackPath) ?? '{}';
    final Map<String, dynamic> decoded = json.decode(rawJson) as Map<String, dynamic>;
    return decoded.map((String key, dynamic value) => MapEntry<String, String>(key, value as String));
  }

  static Future<String?> _safeLoadString(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      return null;
    }
  }

  String get appTitle => _messages['appTitle'] ?? '';
  String get modeClassicTitle => _messages['modeClassicTitle'] ?? '';
  String get modeClassicSubtitle => _messages['modeClassicSubtitle'] ?? '';
  String get modeShiftTitle => _messages['modeShiftTitle'] ?? '';
  String get modeShiftSubtitle => _messages['modeShiftSubtitle'] ?? '';
  String get modeChaosTitle => _messages['modeChaosTitle'] ?? '';
  String get modeChaosSubtitle => _messages['modeChaosSubtitle'] ?? '';
  String get modeUltimateTitle => _messages['modeUltimateTitle'] ?? '';
  String get modeUltimateSubtitle => _messages['modeUltimateSubtitle'] ?? '';
  String get startMatch => _messages['startMatch'] ?? '';
  String get twoPlayers => _messages['twoPlayers'] ?? '';
  String get cpuOpponent => _messages['cpuOpponent'] ?? '';
  String get currentPlayer => _messages['currentPlayer'] ?? '';
  String get drawResult => _messages['drawResult'] ?? '';
  String get winnerResult => _messages['winnerResult'] ?? '';
  String get playAgain => _messages['playAgain'] ?? '';
  String get backToMenu => _messages['backToMenu'] ?? '';
  String get chaosRemovePiece => _messages['chaosRemovePiece'] ?? '';
  String get chaosBlockCell => _messages['chaosBlockCell'] ?? '';
  String get chaosSwapSymbols => _messages['chaosSwapSymbols'] ?? '';
  String get ultimateNoCenter => _messages['ultimateNoCenter'] ?? '';
  String get ultimateLimitedMoves => _messages['ultimateLimitedMoves'] ?? '';
  String get movesRemaining => _messages['movesRemaining'] ?? '';
  String get adsBannerPlacement => _messages['adsBannerPlacement'] ?? '';
  String get adInterstitialHint => _messages['adInterstitialHint'] ?? '';
  String get gameModeLabel => _messages['gameModeLabel'] ?? '';
  String get helpTitle => _messages['helpTitle'] ?? '';
  String get tapToClaim => _messages['tapToClaim'] ?? '';
  String get closeLabel => _messages['closeLabel'] ?? '';
  String get winInstruction => _messages['winInstruction'] ?? '';
  String get takeTurnCta => _messages['takeTurnCta'] ?? '';
  String get playLabel => _messages['playLabel'] ?? '';
  String get settingsTitle => _messages['settingsTitle'] ?? '';
  String get languageLabel => _messages['languageLabel'] ?? '';
  String get languageEnglish => _messages['languageEnglish'] ?? '';
  String get languagePortuguese => _messages['languagePortuguese'] ?? '';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((Locale supportedLocale) => supportedLocale.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(covariant AppLocalizationsDelegate old) => false;
}
