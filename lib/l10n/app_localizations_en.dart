// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tic Tac Verse';

  @override
  String get modeClassicTitle => 'Classic Tic Tac Toe';

  @override
  String get modeClassicSubtitle => 'Traditional rules for quick rounds.';

  @override
  String get modeShiftTitle => 'Tic Tac Shift';

  @override
  String get modeShiftSubtitle => 'Only three active pieces per player.';

  @override
  String get modeChaosTitle => 'Tic Tac Chaos';

  @override
  String get modeChaosSubtitle => 'Every few turns a chaos rule appears.';

  @override
  String get modeUltimateTitle => 'Ultimate Mini Tic Tac';

  @override
  String get modeUltimateSubtitle => 'Win with rotating challenge conditions.';

  @override
  String get startMatch => 'Start Match';

  @override
  String get twoPlayers => 'Two Players';

  @override
  String get cpuOpponent => 'Play vs CPU';

  @override
  String get currentPlayer => 'Current player';

  @override
  String get drawResult => 'It\'s a draw!';

  @override
  String get winnerResult => 'Winner';

  @override
  String get playAgain => 'Play Again';

  @override
  String get backToMenu => 'Back to Menu';

  @override
  String get chaosRemovePiece => 'Chaos: A random piece was removed!';

  @override
  String get chaosBlockCell => 'Chaos: One cell is blocked this turn!';

  @override
  String get chaosSwapSymbols => 'Chaos: Symbols swapped for one turn!';

  @override
  String get ultimateNoCenter => 'Win without using the center cell.';

  @override
  String get ultimateLimitedMoves => 'Win within a limited number of moves.';

  @override
  String get movesRemaining => 'Moves remaining';

  @override
  String get adsBannerPlacement => 'Banner ads appear on the game screen only.';

  @override
  String get adInterstitialHint => 'Interstitial ads show after some matches.';

  @override
  String get gameModeLabel => 'Game mode';

  @override
  String get helpTitle => 'Help';

  @override
  String get tapToClaim => 'Tap any cell to claim it';

  @override
  String get closeLabel => 'Close';

  @override
  String get winInstruction => 'Line up three to win the neon run.';

  @override
  String get takeTurnCta => 'Make your move and light the board';

  @override
  String get playLabel => 'Play';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageSpanish => 'Español';

  @override
  String get audioLabel => 'Audio';

  @override
  String get muteLabel => 'Mute';

  @override
  String get volumeLabel => 'Volume';
}
