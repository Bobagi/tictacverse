import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
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
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

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
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
