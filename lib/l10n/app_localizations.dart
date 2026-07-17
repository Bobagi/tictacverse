import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
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
    Locale('en'),
    Locale('es'),
    Locale('hi'),
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
  /// **'Line up three to win the neon run.'**
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

  /// No description provided for @ultimate2FreeMove.
  ///
  /// In en, this message translates to:
  /// **'Free move: play in any board'**
  String get ultimate2FreeMove;

  /// No description provided for @ultimate2PlayIn.
  ///
  /// In en, this message translates to:
  /// **'Play in the highlighted board'**
  String get ultimate2PlayIn;

  /// No description provided for @ultimate2Help.
  ///
  /// In en, this message translates to:
  /// **'Each cell of the big board holds a small tic tac toe. The cell you pick inside a small board sends your opponent to the matching board. Win a small board to claim its cell on the big board — line up three claimed cells to win the match. If your destination board is closed, you play anywhere.'**
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
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'hi', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
