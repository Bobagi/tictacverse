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
  String get languageHindi => 'हिन्दी';

  @override
  String get languageBengali => 'বাংলা';

  @override
  String get languageNepali => 'नेपाली';

  @override
  String get langSuggestTitle => 'Now available in your language!';

  @override
  String get langSuggestAccept => 'Switch language';

  @override
  String get langSuggestKeep => 'Keep English';

  @override
  String get audioLabel => 'Audio';

  @override
  String get muteLabel => 'Mute';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get difficultyLabel => 'Difficulty';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Impossible';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsTotalMatches => 'Matches played';

  @override
  String get statsVsCpu => 'Versus CPU';

  @override
  String get statsWins => 'Wins';

  @override
  String get statsLosses => 'Losses';

  @override
  String get statsDraws => 'Draws';

  @override
  String get statsStreak => 'Win streak';

  @override
  String get statsBestStreak => 'Best streak';

  @override
  String get statsByMode => 'By mode';

  @override
  String get statsEmpty => 'Play a match to start building your stats!';

  @override
  String get updatesLabel => 'Updates';

  @override
  String get checkUpdatesLabel => 'Check for updates';

  @override
  String get upToDateMessage => 'You are already on the latest version!';

  @override
  String get updateFailedMessage =>
      'Could not check for updates. Try again later.';

  @override
  String get modeUltimate2Title => 'Ultimate Tic Tac Toe';

  @override
  String get modeUltimate2Subtitle =>
      '9 boards in one. Your move picks where your rival plays.';

  @override
  String get ultimate2FreeMove => 'Free move: play in any board';

  @override
  String get ultimate2PlayIn => 'Play in the highlighted board';

  @override
  String get ultimate2Help =>
      'Each cell of the big board holds a small tic tac toe. The cell you pick inside a small board sends your opponent to the matching board. Win a small board to claim its cell on the big board — line up three claimed cells to win the match. If your destination board is closed, you play anywhere.';

  @override
  String get playVsCpuBig => 'Play vs the machine';

  @override
  String get playWithFriend => 'Play with a friend';

  @override
  String get chooseModeTitle => 'Choose a mode';
}
