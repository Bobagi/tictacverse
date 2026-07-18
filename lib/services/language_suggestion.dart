import 'dart:ui';

/// Sugere um dos idiomas recém-adicionados a partir dos idiomas/país do
/// aparelho. Só SUGERE (diálogo único, uma vez) — nunca troca sozinho: na
/// Índia, por exemplo, boa parte dos usuários não fala hindi.
class LanguageSuggestion {
  static const Map<String, String> countryToLanguage = <String, String>{
    'IN': 'hi', // Índia — hindi
    'BD': 'bn', // Bangladesh — bengali
    'NP': 'ne', // Nepal — nepali
  };

  static const Set<String> suggestableLanguages = <String>{'hi', 'bn', 'ne'};

  /// Código do idioma a sugerir, ou null se não há o que sugerir.
  ///
  /// [deviceLocales] = lista de idiomas preferidos do aparelho;
  /// [currentLanguage] = idioma já resolvido do app;
  /// [hasManualChoice] = usuário já escolheu idioma manualmente;
  /// [alreadySuggested] = o diálogo já foi mostrado uma vez.
  static String? suggest({
    required List<Locale> deviceLocales,
    required String currentLanguage,
    required bool hasManualChoice,
    required bool alreadySuggested,
  }) {
    if (hasManualChoice || alreadySuggested) {
      return null;
    }
    // 1) Um dos idiomas preferidos do aparelho (mesmo secundário) é suportado?
    for (final Locale locale in deviceLocales) {
      final String language = locale.languageCode;
      if (suggestableLanguages.contains(language) &&
          language != currentLanguage) {
        return language;
      }
    }
    // 2) O país do aparelho mapeia para um idioma novo?
    for (final Locale locale in deviceLocales) {
      final String? language =
          countryToLanguage[locale.countryCode?.toUpperCase()];
      if (language != null && language != currentLanguage) {
        return language;
      }
    }
    return null;
  }
}
