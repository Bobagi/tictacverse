import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('ne'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Tic Tac Verse'**
  String get appTitle;

  /// No description provided for @modeClassicTitle.
  ///
  /// In en, this message translates to:
  /// **'Classic Tic Tac Toe'**
  String get modeClassicTitle;

  /// No description provided for @modeClassicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Traditional rules for quick rounds.'**
  String get modeClassicSubtitle;

  /// No description provided for @modeShiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Tic Tac Shift'**
  String get modeShiftTitle;

  /// No description provided for @modeShiftSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only three active pieces per player.'**
  String get modeShiftSubtitle;

  /// No description provided for @modeChaosTitle.
  ///
  /// In en, this message translates to:
  /// **'Tic Tac Chaos'**
  String get modeChaosTitle;

  /// No description provided for @modeChaosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every few turns a chaos rule appears.'**
  String get modeChaosSubtitle;

  /// No description provided for @modeUltimateTitle.
  ///
  /// In en, this message translates to:
  /// **'Ultimate Mini Tic Tac'**
  String get modeUltimateTitle;

  /// No description provided for @modeUltimateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Win with rotating challenge conditions.'**
  String get modeUltimateSubtitle;

  /// No description provided for @startMatch.
  ///
  /// In en, this message translates to:
  /// **'Start Match'**
  String get startMatch;

  /// No description provided for @twoPlayers.
  ///
  /// In en, this message translates to:
  /// **'Two Players'**
  String get twoPlayers;

  /// No description provided for @cpuOpponent.
  ///
  /// In en, this message translates to:
  /// **'Play vs CPU'**
  String get cpuOpponent;

  /// No description provided for @currentPlayer.
  ///
  /// In en, this message translates to:
  /// **'Current player'**
  String get currentPlayer;

  /// No description provided for @drawResult.
  ///
  /// In en, this message translates to:
  /// **'It\'s a draw!'**
  String get drawResult;

  /// No description provided for @winnerResult.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winnerResult;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @backToMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to Menu'**
  String get backToMenu;

  /// No description provided for @chaosRemovePiece.
  ///
  /// In en, this message translates to:
  /// **'Chaos: A random piece was removed!'**
  String get chaosRemovePiece;

  /// No description provided for @chaosBlockCell.
  ///
  /// In en, this message translates to:
  /// **'Chaos: One cell is blocked this turn!'**
  String get chaosBlockCell;

  /// No description provided for @chaosSwapSymbols.
  ///
  /// In en, this message translates to:
  /// **'Chaos: Symbols swapped for one turn!'**
  String get chaosSwapSymbols;

  /// No description provided for @ultimateNoCenter.
  ///
  /// In en, this message translates to:
  /// **'Win without using the center cell.'**
  String get ultimateNoCenter;

  /// No description provided for @ultimateLimitedMoves.
  ///
  /// In en, this message translates to:
  /// **'Win within a limited number of moves.'**
  String get ultimateLimitedMoves;

  /// No description provided for @movesRemaining.
  ///
  /// In en, this message translates to:
  /// **'Moves remaining'**
  String get movesRemaining;

  /// No description provided for @adsBannerPlacement.
  ///
  /// In en, this message translates to:
  /// **'Banner ads appear on the game screen only.'**
  String get adsBannerPlacement;

  /// No description provided for @adInterstitialHint.
  ///
  /// In en, this message translates to:
  /// **'Interstitial ads show after some matches.'**
  String get adInterstitialHint;

  /// No description provided for @gameModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Game mode'**
  String get gameModeLabel;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @tapToClaim.
  ///
  /// In en, this message translates to:
  /// **'Tap any cell to claim it'**
  String get tapToClaim;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @winInstruction.
  ///
  /// In en, this message translates to:
  /// **'Line up three to win.'**
  String get winInstruction;

  /// No description provided for @takeTurnCta.
  ///
  /// In en, this message translates to:
  /// **'Make your move and light the board'**
  String get takeTurnCta;

  /// No description provided for @playLabel.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @languageBengali.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageBengali;

  /// No description provided for @languageNepali.
  ///
  /// In en, this message translates to:
  /// **'नेपाली'**
  String get languageNepali;

  /// No description provided for @langSuggestTitle.
  ///
  /// In en, this message translates to:
  /// **'Now available in your language!'**
  String get langSuggestTitle;

  /// No description provided for @langSuggestAccept.
  ///
  /// In en, this message translates to:
  /// **'Switch language'**
  String get langSuggestAccept;

  /// No description provided for @langSuggestKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep English'**
  String get langSuggestKeep;

  /// No description provided for @audioLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioLabel;

  /// No description provided for @muteLabel.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get muteLabel;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumeLabel;

  /// No description provided for @difficultyLabel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficultyLabel;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Impossible'**
  String get difficultyHard;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @statsTotalMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches played'**
  String get statsTotalMatches;

  /// No description provided for @statsVsCpu.
  ///
  /// In en, this message translates to:
  /// **'Versus CPU'**
  String get statsVsCpu;

  /// No description provided for @statsWins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get statsWins;

  /// No description provided for @statsLosses.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get statsLosses;

  /// No description provided for @statsDraws.
  ///
  /// In en, this message translates to:
  /// **'Draws'**
  String get statsDraws;

  /// No description provided for @statsStreak.
  ///
  /// In en, this message translates to:
  /// **'Win streak'**
  String get statsStreak;

  /// No description provided for @statsBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get statsBestStreak;

  /// No description provided for @statsByMode.
  ///
  /// In en, this message translates to:
  /// **'By mode'**
  String get statsByMode;

  /// No description provided for @statsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Play a match to start building your stats!'**
  String get statsEmpty;

  /// No description provided for @updatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesLabel;

  /// No description provided for @checkUpdatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkUpdatesLabel;

  /// No description provided for @upToDateMessage.
  ///
  /// In en, this message translates to:
  /// **'You are already on the latest version!'**
  String get upToDateMessage;

  /// No description provided for @updateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates. Try again later.'**
  String get updateFailedMessage;

  /// No description provided for @modeUltimate2Title.
  ///
  /// In en, this message translates to:
  /// **'Ultimate Tic Tac Toe'**
  String get modeUltimate2Title;

  /// No description provided for @modeUltimate2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'9 boards in one. Your move picks where your rival plays.'**
  String get modeUltimate2Subtitle;

  /// No description provided for @modeFourByFourTitle.
  ///
  /// In en, this message translates to:
  /// **'4x4'**
  String get modeFourByFourTitle;

  /// No description provided for @modeFourByFourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Four in a row on a bigger board.'**
  String get modeFourByFourSubtitle;

  /// No description provided for @modeGomokuTitle.
  ///
  /// In en, this message translates to:
  /// **'Five in a Row'**
  String get modeGomokuTitle;

  /// No description provided for @modeGomokuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gomoku: line up five on a 10x10 board.'**
  String get modeGomokuSubtitle;

  /// No description provided for @winInstructionFour.
  ///
  /// In en, this message translates to:
  /// **'Line up four to win.'**
  String get winInstructionFour;

  /// No description provided for @winInstructionFive.
  ///
  /// In en, this message translates to:
  /// **'Line up five to win.'**
  String get winInstructionFive;

  /// No description provided for @ultimate2FreeMove.
  ///
  /// In en, this message translates to:
  /// **'Free move: any board'**
  String get ultimate2FreeMove;

  /// No description provided for @ultimate2PlayIn.
  ///
  /// In en, this message translates to:
  /// **'Play in the lit board'**
  String get ultimate2PlayIn;

  /// No description provided for @ultimate2Help.
  ///
  /// In en, this message translates to:
  /// **'Each cell of the big board holds a small tic tac toe. The cell you pick inside a small board sends your opponent to the matching board. Win a small board to claim its cell on the big board - line up three claimed cells to win the match. If your destination board is closed, you play anywhere.'**
  String get ultimate2Help;

  /// No description provided for @playVsCpuBig.
  ///
  /// In en, this message translates to:
  /// **'Play vs the machine'**
  String get playVsCpuBig;

  /// No description provided for @playWithFriend.
  ///
  /// In en, this message translates to:
  /// **'Play with a friend'**
  String get playWithFriend;

  /// No description provided for @chooseModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a mode'**
  String get chooseModeTitle;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// No description provided for @achievementsProgress.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} of {total} unlocked'**
  String achievementsProgress(int unlocked, int total);

  /// No description provided for @achievementsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Play a match to start unlocking achievements.'**
  String get achievementsEmpty;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelLabel(int level);

  /// No description provided for @xpProgress.
  ///
  /// In en, this message translates to:
  /// **'{into} / {span} XP'**
  String xpProgress(int into, int span);

  /// No description provided for @xpGained.
  ///
  /// In en, this message translates to:
  /// **'+{amount} XP'**
  String xpGained(int amount);

  /// No description provided for @achUnlockedToast.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked!'**
  String get achUnlockedToast;

  /// No description provided for @doubleXpCta.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad, double XP and coins'**
  String get doubleXpCta;

  /// No description provided for @doubleXpDone.
  ///
  /// In en, this message translates to:
  /// **'XP and coins doubled!'**
  String get doubleXpDone;

  /// No description provided for @doubleXpUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The ad didn\'t load. Try again next match.'**
  String get doubleXpUnavailable;

  /// No description provided for @levelUpToast.
  ///
  /// In en, this message translates to:
  /// **'Level {level} reached!'**
  String levelUpToast(int level);

  /// No description provided for @achFirstWinTitle.
  ///
  /// In en, this message translates to:
  /// **'First Victory'**
  String get achFirstWinTitle;

  /// No description provided for @achFirstWinDesc.
  ///
  /// In en, this message translates to:
  /// **'Beat the CPU for the first time'**
  String get achFirstWinDesc;

  /// No description provided for @achWins10Title.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get achWins10Title;

  /// No description provided for @achWins50Title.
  ///
  /// In en, this message translates to:
  /// **'Dominant'**
  String get achWins50Title;

  /// No description provided for @achWins200Title.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get achWins200Title;

  /// No description provided for @achDescWins.
  ///
  /// In en, this message translates to:
  /// **'Win {count} matches against the CPU'**
  String achDescWins(int count);

  /// No description provided for @achStreak3Title.
  ///
  /// In en, this message translates to:
  /// **'Warming Up'**
  String get achStreak3Title;

  /// No description provided for @achStreak7Title.
  ///
  /// In en, this message translates to:
  /// **'On Fire'**
  String get achStreak7Title;

  /// No description provided for @achStreak15Title.
  ///
  /// In en, this message translates to:
  /// **'Unstoppable'**
  String get achStreak15Title;

  /// No description provided for @achDescStreak.
  ///
  /// In en, this message translates to:
  /// **'Win {count} matches in a row'**
  String achDescStreak(int count);

  /// No description provided for @achHardWinTitle.
  ///
  /// In en, this message translates to:
  /// **'Not So Impossible'**
  String get achHardWinTitle;

  /// No description provided for @achHardWinDesc.
  ///
  /// In en, this message translates to:
  /// **'Beat the CPU on Impossible'**
  String get achHardWinDesc;

  /// No description provided for @achAllModesTitle.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get achAllModesTitle;

  /// No description provided for @achAllModesDesc.
  ///
  /// In en, this message translates to:
  /// **'Play 5 different game modes'**
  String get achAllModesDesc;

  /// No description provided for @achUltimateWinsTitle.
  ///
  /// In en, this message translates to:
  /// **'Grid Master'**
  String get achUltimateWinsTitle;

  /// No description provided for @achDescUltimateWins.
  ///
  /// In en, this message translates to:
  /// **'Win {count} matches in Ultimate Tic Tac Toe'**
  String achDescUltimateWins(int count);

  /// No description provided for @achDaily3Title.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get achDaily3Title;

  /// No description provided for @achDaily7Title.
  ///
  /// In en, this message translates to:
  /// **'Full Week'**
  String get achDaily7Title;

  /// No description provided for @achDaily30Title.
  ///
  /// In en, this message translates to:
  /// **'Devoted'**
  String get achDaily30Title;

  /// No description provided for @achDescDaily.
  ///
  /// In en, this message translates to:
  /// **'Play {count} days in a row'**
  String achDescDaily(int count);

  /// No description provided for @achFastWinTitle.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get achFastWinTitle;

  /// No description provided for @achFastWinDesc.
  ///
  /// In en, this message translates to:
  /// **'Win Classic in only 3 moves'**
  String get achFastWinDesc;

  /// No description provided for @achMatches50Title.
  ///
  /// In en, this message translates to:
  /// **'Veteran'**
  String get achMatches50Title;

  /// No description provided for @achMatches250Title.
  ///
  /// In en, this message translates to:
  /// **'Marathoner'**
  String get achMatches250Title;

  /// No description provided for @achDescMatches.
  ///
  /// In en, this message translates to:
  /// **'Play {count} matches'**
  String achDescMatches(int count);

  /// No description provided for @playGamesOpen.
  ///
  /// In en, this message translates to:
  /// **'View on Play Games'**
  String get playGamesOpen;

  /// No description provided for @hapticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get hapticsLabel;

  /// No description provided for @youWinTitle.
  ///
  /// In en, this message translates to:
  /// **'You win!'**
  String get youWinTitle;

  /// No description provided for @cpuWinsTitle.
  ///
  /// In en, this message translates to:
  /// **'The machine wins'**
  String get cpuWinsTitle;

  /// No description provided for @playerWinsTitle.
  ///
  /// In en, this message translates to:
  /// **'{symbol} wins!'**
  String playerWinsTitle(String symbol);

  /// No description provided for @winStreakChip.
  ///
  /// In en, this message translates to:
  /// **'{count} wins in a row!'**
  String winStreakChip(int count);

  /// No description provided for @dailyStreakChip.
  ///
  /// In en, this message translates to:
  /// **'Day {count} streak'**
  String dailyStreakChip(int count);

  /// No description provided for @newRecordChip.
  ///
  /// In en, this message translates to:
  /// **'New record!'**
  String get newRecordChip;

  /// No description provided for @cpuThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get cpuThinking;

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurn;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'Update now to get the latest improvements and fixes.'**
  String get updateAvailableBody;

  /// No description provided for @updateNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNowLabel;

  /// No description provided for @updateLaterLabel.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLaterLabel;

  /// No description provided for @coinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coinsLabel;

  /// No description provided for @coinsGained.
  ///
  /// In en, this message translates to:
  /// **'+{amount} coins'**
  String coinsGained(int amount);

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Piece styles'**
  String get shopTitle;

  /// No description provided for @shopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Earn coins by playing and change how X and O look.'**
  String get shopSubtitle;

  /// No description provided for @shopEquip.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get shopEquip;

  /// No description provided for @shopEquipped.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get shopEquipped;

  /// No description provided for @shopPurchased.
  ///
  /// In en, this message translates to:
  /// **'New style unlocked!'**
  String get shopPurchased;

  /// No description provided for @skinAurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get skinAurora;

  /// No description provided for @skinNeon.
  ///
  /// In en, this message translates to:
  /// **'Neon'**
  String get skinNeon;

  /// No description provided for @skinFireIce.
  ///
  /// In en, this message translates to:
  /// **'Fire and ice'**
  String get skinFireIce;

  /// No description provided for @skinCandy.
  ///
  /// In en, this message translates to:
  /// **'Candy'**
  String get skinCandy;

  /// No description provided for @skinGold.
  ///
  /// In en, this message translates to:
  /// **'Gold and silver'**
  String get skinGold;

  /// No description provided for @skinGalaxy.
  ///
  /// In en, this message translates to:
  /// **'Galaxy'**
  String get skinGalaxy;

  /// No description provided for @adCoinsCta.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad: +{amount} coins'**
  String adCoinsCta(int amount);

  /// No description provided for @adCoinsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left today'**
  String adCoinsLeft(int count);

  /// No description provided for @adCoinsSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow for more ad coins.'**
  String get adCoinsSoldOut;

  /// No description provided for @adUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No ad available right now. Try again in a moment.'**
  String get adUnavailable;

  /// No description provided for @dailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily bonus'**
  String get dailyTitle;

  /// No description provided for @dailyReady.
  ///
  /// In en, this message translates to:
  /// **'Ready!'**
  String get dailyReady;

  /// No description provided for @dailyComeBack.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow'**
  String get dailyComeBack;

  /// No description provided for @dailyDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String dailyDay(int day);

  /// No description provided for @dailyClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get dailyClaim;

  /// No description provided for @dailyHint.
  ///
  /// In en, this message translates to:
  /// **'Come back every day: the bonus grows until day 7.'**
  String get dailyHint;

  /// No description provided for @dailyDoubleCta.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad and double it'**
  String get dailyDoubleCta;

  /// No description provided for @shopTabSkins.
  ///
  /// In en, this message translates to:
  /// **'Styles'**
  String get shopTabSkins;

  /// No description provided for @shopTabCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get shopTabCoins;

  /// No description provided for @coinPackTitle.
  ///
  /// In en, this message translates to:
  /// **'{amount} coins'**
  String coinPackTitle(int amount);

  /// No description provided for @coinPackBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get coinPackBestValue;

  /// No description provided for @removeAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get removeAdsTitle;

  /// No description provided for @removeAdsBody.
  ///
  /// In en, this message translates to:
  /// **'Removes banners and ads between matches, forever. Reward ads stay optional.'**
  String get removeAdsBody;

  /// No description provided for @removeAdsOwned.
  ///
  /// In en, this message translates to:
  /// **'Ads removed. Thank you!'**
  String get removeAdsOwned;

  /// No description provided for @storeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the store...'**
  String get storeLoading;

  /// No description provided for @storeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases are not available right now. Check your connection and try again later.'**
  String get storeUnavailable;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @purchasePending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending. Your purchase arrives as soon as Google Play confirms it.'**
  String get purchasePending;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase was not completed.'**
  String get purchaseFailed;

  /// No description provided for @needMoreCoins.
  ///
  /// In en, this message translates to:
  /// **'You need {amount} more coins for this style.'**
  String needMoreCoins(int amount);

  /// No description provided for @starterTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome pack'**
  String get starterTitle;

  /// No description provided for @starterBody.
  ///
  /// In en, this message translates to:
  /// **'No ads forever + {amount} coins, in one purchase.'**
  String starterBody(int amount);

  /// No description provided for @starterSave.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String starterSave(int percent);

  /// No description provided for @starterSee.
  ///
  /// In en, this message translates to:
  /// **'See offer'**
  String get starterSee;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @purchaseVerifying.
  ///
  /// In en, this message translates to:
  /// **'Payment received. Confirming your purchase, it arrives in a moment.'**
  String get purchaseVerifying;

  /// No description provided for @challengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge'**
  String get challengeTitle;

  /// No description provided for @challengeGoal.
  ///
  /// In en, this message translates to:
  /// **'Beat the CPU in Super Tic Tac Toe in {limit} moves or fewer'**
  String challengeGoal(int limit);

  /// No description provided for @challengeMoves.
  ///
  /// In en, this message translates to:
  /// **'{used}/{limit}'**
  String challengeMoves(int used, int limit);

  /// No description provided for @challengeOverLimit.
  ///
  /// In en, this message translates to:
  /// **'Over {limit} moves: no prize this time'**
  String challengeOverLimit(int limit);

  /// No description provided for @challengeWon.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge done! +{coins} coins'**
  String challengeWon(int coins);

  /// No description provided for @challengeLate.
  ///
  /// In en, this message translates to:
  /// **'You won, but took more than {limit} moves. Try again!'**
  String challengeLate(int limit);

  /// No description provided for @challengeAlreadyDone.
  ///
  /// In en, this message translates to:
  /// **'Today\'s challenge is already done. Come back tomorrow!'**
  String get challengeAlreadyDone;

  /// No description provided for @challengeDoneHome.
  ///
  /// In en, this message translates to:
  /// **'Done! Come back tomorrow'**
  String get challengeDoneHome;

  /// No description provided for @shareVictory.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareVictory;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'I just won at Tic Tac Verse! Think you can beat me?'**
  String get shareMessage;

  /// No description provided for @tutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'How Super Tic Tac Toe works'**
  String get tutorialTitle;

  /// No description provided for @tutorialIntro.
  ///
  /// In en, this message translates to:
  /// **'There are 9 small boards inside a big one. Win a small board to claim it, and claim 3 in a row to win the game.'**
  String get tutorialIntro;

  /// No description provided for @tutorialTapFirst.
  ///
  /// In en, this message translates to:
  /// **'Your turn. Tap the glowing square: the top-right corner of the middle board.'**
  String get tutorialTapFirst;

  /// No description provided for @tutorialSent.
  ///
  /// In en, this message translates to:
  /// **'You played in the top-right corner, so your opponent must now play in the top-right BOARD. The square you pick decides where the other player goes.'**
  String get tutorialSent;

  /// No description provided for @tutorialTapSecond.
  ///
  /// In en, this message translates to:
  /// **'Your opponent played in the centre square, so now YOU go to the middle board. Tap the glowing square.'**
  String get tutorialTapSecond;

  /// No description provided for @tutorialFinal.
  ///
  /// In en, this message translates to:
  /// **'That\'s it! If you are sent to a board that is already won or full, you may play on any board. Think ahead: every move sends your opponent somewhere.'**
  String get tutorialFinal;

  /// No description provided for @tutorialSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkip;

  /// No description provided for @tutorialNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// No description provided for @tutorialPlay.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play!'**
  String get tutorialPlay;

  /// No description provided for @tutorialReplay.
  ///
  /// In en, this message translates to:
  /// **'See the tutorial'**
  String get tutorialReplay;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'bn',
        'en',
        'es',
        'hi',
        'ne',
        'pt'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
    case 'ne':
      return AppLocalizationsNe();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
