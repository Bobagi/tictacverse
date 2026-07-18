import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/services/language_suggestion.dart';

void main() {
  group('LanguageSuggestion.suggest', () {
    String? run(
      List<Locale> locales, {
      String current = 'en',
      bool manual = false,
      bool shown = false,
    }) {
      return LanguageSuggestion.suggest(
        deviceLocales: locales,
        currentLanguage: current,
        hasManualChoice: manual,
        alreadySuggested: shown,
      );
    }

    test('aparelho en-IN (Índia em inglês) sugere hindi', () {
      expect(run(<Locale>[const Locale('en', 'IN')]), 'hi');
    });

    test('hindi como idioma secundário do aparelho sugere hindi', () {
      expect(
        run(<Locale>[const Locale('en', 'US'), const Locale('hi', 'IN')]),
        'hi',
      );
    });

    test('Bangladesh sugere bengali e Nepal sugere nepali', () {
      expect(run(<Locale>[const Locale('en', 'BD')]), 'bn');
      expect(run(<Locale>[const Locale('en', 'NP')]), 'ne');
    });

    test('app já resolvido no idioma sugerido não sugere de novo', () {
      expect(run(<Locale>[const Locale('hi', 'IN')], current: 'hi'), isNull);
    });

    test('escolha manual de idioma veta a sugestão', () {
      expect(run(<Locale>[const Locale('en', 'IN')], manual: true), isNull);
    });

    test('diálogo já mostrado uma vez veta a sugestão', () {
      expect(run(<Locale>[const Locale('en', 'IN')], shown: true), isNull);
    });

    test('país sem idioma novo não sugere nada', () {
      expect(run(<Locale>[const Locale('pt', 'BR')]), isNull);
      expect(run(<Locale>[const Locale('en', 'US')]), isNull);
    });
  });
}
