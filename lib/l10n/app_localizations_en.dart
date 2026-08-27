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
      'Each cell of the big board holds a small tic tac toe. The cell you pick inside a small board sends your opponent to the matching board. Win a small board to claim its cell on the big board - line up three claimed cells to win the match. If your destination board is closed, you play anywhere.';

  @override
  String get playVsCpuBig => 'Play vs the machine';

  @override
  String get playWithFriend => 'Play with a friend';

  @override
  String get chooseModeTitle => 'Choose a mode';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String achievementsProgress(int unlocked, int total) {
    return '$unlocked of $total unlocked';
  }

  @override
  String get achievementsEmpty =>
      'Play a match to start unlocking achievements.';

  @override
  String levelLabel(int level) {
    return 'Level $level';
  }

  @override
  String xpProgress(int into, int span) {
    return '$into / $span XP';
  }

  @override
  String xpGained(int amount) {
    return '+$amount XP';
  }

  @override
  String get achUnlockedToast => 'Achievement unlocked!';

  @override
  String get doubleXpCta => 'Watch an ad, double your XP';

  @override
  String get doubleXpDone => 'XP doubled!';

  @override
  String get doubleXpUnavailable =>
      'The ad didn\'t load. Try again next match.';

  @override
  String levelUpToast(int level) {
    return 'Level $level reached!';
  }

  @override
  String get achFirstWinTitle => 'First Victory';

  @override
  String get achFirstWinDesc => 'Beat the CPU for the first time';

  @override
  String get achWins10Title => 'Winner';

  @override
  String get achWins50Title => 'Dominant';

  @override
  String get achWins200Title => 'Legend';

  @override
  String achDescWins(int count) {
    return 'Win $count matches against the CPU';
  }

  @override
  String get achStreak3Title => 'Warming Up';

  @override
  String get achStreak7Title => 'On Fire';

  @override
  String get achStreak15Title => 'Unstoppable';

  @override
  String achDescStreak(int count) {
    return 'Win $count matches in a row';
  }

  @override
  String get achHardWinTitle => 'Not So Impossible';

  @override
  String get achHardWinDesc => 'Beat the CPU on Impossible';

  @override
  String get achAllModesTitle => 'Explorer';

  @override
  String get achAllModesDesc => 'Play all 5 game modes';

  @override
  String get achUltimateWinsTitle => 'Grid Master';

  @override
  String achDescUltimateWins(int count) {
    return 'Win $count matches in Ultimate Tic Tac Toe';
  }

  @override
  String get achDaily3Title => 'Routine';

  @override
  String get achDaily7Title => 'Full Week';

  @override
  String get achDaily30Title => 'Devoted';

  @override
  String achDescDaily(int count) {
    return 'Play $count days in a row';
  }

  @override
  String get achFastWinTitle => 'Lightning';

  @override
  String get achFastWinDesc => 'Win Classic in only 3 moves';

  @override
  String get achMatches50Title => 'Veteran';

  @override
  String get achMatches250Title => 'Marathoner';

  @override
  String achDescMatches(int count) {
    return 'Play $count matches';
  }

  @override
  String get playGamesOpen => 'View on Play Games';
}
