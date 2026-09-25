import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../models/game_result.dart';
import '../models/player_marker.dart';
import '../ui/widgets/juice/particles.dart';
import '../ui/widgets/modern_background.dart';
import 'audio_service.dart';
import 'haptics_service.dart';

/// Como a partida terminou, do ponto de vista de quem segura o aparelho.
enum MatchEndKind { humanWin, cpuWin, twoPlayerWin, draw }

/// Classifica o resultado. Contra a máquina o humano é sempre o X.
MatchEndKind classifyMatchEnd(GameResult result, {required bool vsCpu}) {
  if (result.resolution != GameResolution.victory || result.winner == null) {
    return MatchEndKind.draw;
  }
  if (!vsCpu) {
    return MatchEndKind.twoPlayerWin;
  }
  return result.winner == PlayerMarker.cross
      ? MatchEndKind.humanWin
      : MatchEndKind.cpuWin;
}

/// Título do modal de fim: fala com o jogador ("Você venceu!") em vez de
/// anunciar "Vencedor: X" como um placar frio.
String matchEndTitle(
  AppLocalizations localization,
  GameResult result, {
  required bool vsCpu,
}) {
  switch (classifyMatchEnd(result, vsCpu: vsCpu)) {
    case MatchEndKind.humanWin:
      return localization.youWinTitle;
    case MatchEndKind.cpuWin:
      return localization.cpuWinsTitle;
    case MatchEndKind.twoPlayerWin:
      return localization.playerWinsTitle(result.winner!.symbol);
    case MatchEndKind.draw:
      return localization.drawResult;
  }
}

/// Feedback sensorial do fim da partida: som, vibração e confete. O confete só
/// cai para quem venceu (no modo amigo, para a mesa inteira); a derrota para a
/// máquina tem som e pulso próprios, sem festa, para a vitória valer mais.
void playMatchEndFeedback(
  MatchEndKind kind, {
  required ParticleController screenParticles,
}) {
  final AudioService audio = AudioService.instance;
  final HapticsService haptics = HapticsService.instance;
  switch (kind) {
    case MatchEndKind.humanWin:
    case MatchEndKind.twoPlayerWin:
      audio.play(Sfx.win);
      haptics.play(HapticCue.win);
      screenParticles.confetti(colors: confettiColors);
    case MatchEndKind.cpuWin:
      audio.play(Sfx.lose);
      haptics.play(HapticCue.lose);
    case MatchEndKind.draw:
      audio.play(Sfx.draw);
      haptics.play(HapticCue.place);
  }
}

const List<Color> confettiColors = <Color>[
  VerseColors.cross,
  VerseColors.nought,
  VerseColors.energy,
  Color(0xFF3EF0C4),
  Color(0xFFB98BFF),
  Colors.white,
];
