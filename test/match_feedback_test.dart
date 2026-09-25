import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/l10n/app_localizations.dart';
import 'package:tictacverse/models/game_result.dart';
import 'package:tictacverse/models/player_marker.dart';
import 'package:tictacverse/services/match_feedback.dart';

void main() {
  GameResult win(PlayerMarker who) => GameResult(
      resolution: GameResolution.victory, winner: who, winningLine: <int>[0, 1, 2]);
  GameResult draw() => GameResult(resolution: GameResolution.draw);

  group('classifyMatchEnd', () {
    test('contra a máquina o X é o humano', () {
      expect(classifyMatchEnd(win(PlayerMarker.cross), vsCpu: true),
          MatchEndKind.humanWin);
      expect(classifyMatchEnd(win(PlayerMarker.nought), vsCpu: true),
          MatchEndKind.cpuWin);
    });

    test('entre amigos qualquer vitória é festa', () {
      expect(classifyMatchEnd(win(PlayerMarker.nought), vsCpu: false),
          MatchEndKind.twoPlayerWin);
    });

    test('empate é empate nos dois modos', () {
      expect(classifyMatchEnd(draw(), vsCpu: true), MatchEndKind.draw);
      expect(classifyMatchEnd(draw(), vsCpu: false), MatchEndKind.draw);
    });
  });

  group('matchEndTitle fala com o jogador', () {
    final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
    final AppLocalizations pt = lookupAppLocalizations(const Locale('pt'));

    test('vitória e derrota contra a máquina', () {
      expect(matchEndTitle(en, win(PlayerMarker.cross), vsCpu: true), 'You win!');
      expect(matchEndTitle(pt, win(PlayerMarker.nought), vsCpu: true),
          'A máquina venceu');
    });

    test('entre amigos nomeia o símbolo', () {
      expect(matchEndTitle(en, win(PlayerMarker.nought), vsCpu: false), 'O wins!');
    });

    test('todas as línguas têm os títulos novos preenchidos', () {
      for (final Locale locale in AppLocalizations.supportedLocales) {
        final AppLocalizations l = lookupAppLocalizations(locale);
        expect(l.youWinTitle, isNotEmpty, reason: '$locale');
        expect(l.cpuWinsTitle, isNotEmpty, reason: '$locale');
        expect(l.playerWinsTitle('X'), contains('X'), reason: '$locale');
        expect(l.winStreakChip(3), contains('3'), reason: '$locale');
        expect(l.dailyStreakChip(5), contains('5'), reason: '$locale');
        expect(l.hapticsLabel, isNotEmpty, reason: '$locale');
      }
    });
  });
}
