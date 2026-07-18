// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'Tic Tac Verse';

  @override
  String get modeClassicTitle => 'ক্লাসিক টিক ট্যাক টো';

  @override
  String get modeClassicSubtitle => 'চটজলদি রাউন্ডের জন্য চিরচেনা নিয়ম।';

  @override
  String get modeShiftTitle => 'টিক ট্যাক শিফট';

  @override
  String get modeShiftSubtitle =>
      'প্রতি খেলোয়াড়ের মাত্র তিনটি গুটি সক্রিয় থাকে।';

  @override
  String get modeChaosTitle => 'টিক ট্যাক কেওস';

  @override
  String get modeChaosSubtitle => 'কয়েক চাল পরপর একটি কেওস নিয়ম আসে।';

  @override
  String get modeUltimateTitle => 'আলটিমেট মিনি টিক ট্যাক';

  @override
  String get modeUltimateSubtitle => 'বদলাতে থাকা চ্যালেঞ্জ শর্তে জিতুন।';

  @override
  String get startMatch => 'ম্যাচ শুরু করুন';

  @override
  String get twoPlayers => 'দুই খেলোয়াড়';

  @override
  String get cpuOpponent => 'CPU-র বিরুদ্ধে খেলুন';

  @override
  String get currentPlayer => 'বর্তমান খেলোয়াড়';

  @override
  String get drawResult => 'ম্যাচ ড্র হলো!';

  @override
  String get winnerResult => 'বিজয়ী';

  @override
  String get playAgain => 'আবার খেলুন';

  @override
  String get backToMenu => 'মেনুতে ফিরুন';

  @override
  String get chaosRemovePiece => 'কেওস: একটি গুটি হঠাৎ সরিয়ে দেওয়া হলো!';

  @override
  String get chaosBlockCell => 'কেওস: এই চালে একটি ঘর ব্লক!';

  @override
  String get chaosSwapSymbols => 'কেওস: এক চালের জন্য চিহ্ন অদলবদল!';

  @override
  String get ultimateNoCenter => 'মাঝের ঘর ব্যবহার না করে জিতুন।';

  @override
  String get ultimateLimitedMoves => 'সীমিত চালের মধ্যে জিতুন।';

  @override
  String get movesRemaining => 'বাকি চাল';

  @override
  String get adsBannerPlacement =>
      'ব্যানার বিজ্ঞাপন শুধু গেম স্ক্রিনে দেখা যায়।';

  @override
  String get adInterstitialHint =>
      'কিছু ম্যাচের পরে ইন্টারস্টিশিয়াল বিজ্ঞাপন দেখায়।';

  @override
  String get gameModeLabel => 'গেম মোড';

  @override
  String get helpTitle => 'সাহায্য';

  @override
  String get tapToClaim => 'যেকোনো ঘরে ট্যাপ করে দখল করুন';

  @override
  String get closeLabel => 'বন্ধ করুন';

  @override
  String get winInstruction => 'তিনটি এক লাইনে সাজিয়ে নিয়ন জয় ছিনিয়ে নিন।';

  @override
  String get takeTurnCta => 'আপনার চাল দিন, বোর্ড আলোকিত করুন';

  @override
  String get playLabel => 'খেলুন';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get languageLabel => 'ভাষা';

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
  String get langSuggestTitle => 'এখন বাংলায় উপলব্ধ!';

  @override
  String get langSuggestAccept => 'বাংলায় খেলুন';

  @override
  String get langSuggestKeep => 'বাংলায় চালিয়ে যান';

  @override
  String get audioLabel => 'অডিও';

  @override
  String get muteLabel => 'মিউট';

  @override
  String get volumeLabel => 'ভলিউম';

  @override
  String get difficultyLabel => 'কঠিনতা';

  @override
  String get difficultyEasy => 'সহজ';

  @override
  String get difficultyMedium => 'মাঝারি';

  @override
  String get difficultyHard => 'অসম্ভব';

  @override
  String get statsTitle => 'পরিসংখ্যান';

  @override
  String get statsTotalMatches => 'খেলা ম্যাচ';

  @override
  String get statsVsCpu => 'CPU-র বিরুদ্ধে';

  @override
  String get statsWins => 'জয়';

  @override
  String get statsLosses => 'হার';

  @override
  String get statsDraws => 'ড্র';

  @override
  String get statsStreak => 'টানা জয়';

  @override
  String get statsBestStreak => 'সেরা ধারাবাহিকতা';

  @override
  String get statsByMode => 'মোড অনুযায়ী';

  @override
  String get statsEmpty => 'পরিসংখ্যান গড়তে একটি ম্যাচ খেলুন!';

  @override
  String get updatesLabel => 'আপডেট';

  @override
  String get checkUpdatesLabel => 'আপডেট দেখুন';

  @override
  String get upToDateMessage => 'আপনি ইতিমধ্যে সর্বশেষ সংস্করণে আছেন!';

  @override
  String get updateFailedMessage =>
      'আপডেট যাচাই করা গেল না। পরে আবার চেষ্টা করুন।';

  @override
  String get modeUltimate2Title => 'আলটিমেট টিক ট্যাক টো';

  @override
  String get modeUltimate2Subtitle =>
      'একটিতে ৯টি বোর্ড। আপনার চালই ঠিক করে প্রতিপক্ষ কোথায় খেলবে।';

  @override
  String get ultimate2FreeMove => 'ফ্রি চাল: যেকোনো বোর্ডে খেলুন';

  @override
  String get ultimate2PlayIn => 'হাইলাইট করা বোর্ডে খেলুন';

  @override
  String get ultimate2Help =>
      'বড় বোর্ডের প্রতিটি ঘরে একটি ছোট টিক ট্যাক টো আছে। ছোট বোর্ডে আপনি যে ঘরটি বেছে নেন, প্রতিপক্ষকে সেই নম্বরের বোর্ডে পাঠানো হয়। ছোট বোর্ড জিতে বড় বোর্ডে তার ঘর দখল করুন — দখল করা তিনটি ঘর এক লাইনে সাজিয়ে ম্যাচ জিতুন। আপনার গন্তব্য বোর্ড বন্ধ থাকলে যেকোনো জায়গায় খেলতে পারবেন।';

  @override
  String get playVsCpuBig => 'মেশিনের বিরুদ্ধে খেলুন';

  @override
  String get playWithFriend => 'বন্ধুর সাথে খেলুন';

  @override
  String get chooseModeTitle => 'একটি মোড বেছে নিন';
}
