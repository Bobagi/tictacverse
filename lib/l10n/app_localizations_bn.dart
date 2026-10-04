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
  String get winInstruction => 'তিনটি সারিতে সাজিয়ে জিতুন';

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
  String get modeFourByFourTitle => '4x4';

  @override
  String get modeFourByFourSubtitle => 'বড় বোর্ডে টানা চারটি মেলান।';

  @override
  String get modeGomokuTitle => 'টানা পাঁচ';

  @override
  String get modeGomokuSubtitle => 'গোমোকু: ১০x১০ বোর্ডে টানা পাঁচটি মেলান।';

  @override
  String get winInstructionFour => 'চারটি সারিতে সাজিয়ে জিতুন';

  @override
  String get winInstructionFive => 'পাঁচটি সারিতে সাজিয়ে জিতুন';

  @override
  String get ultimate2FreeMove => 'মুক্ত চাল: যেকোনো বোর্ড';

  @override
  String get ultimate2PlayIn => 'আলোকিত বোর্ডে খেলুন';

  @override
  String get ultimate2Help =>
      'বড় বোর্ডের প্রতিটি ঘরে একটি ছোট টিক ট্যাক টো আছে। ছোট বোর্ডে আপনি যে ঘরটি বেছে নেন, প্রতিপক্ষকে সেই নম্বরের বোর্ডে পাঠানো হয়। ছোট বোর্ড জিতে বড় বোর্ডে তার ঘর দখল করুন - দখল করা তিনটি ঘর এক লাইনে সাজিয়ে ম্যাচ জিতুন। আপনার গন্তব্য বোর্ড বন্ধ থাকলে যেকোনো জায়গায় খেলতে পারবেন।';

  @override
  String get playVsCpuBig => 'মেশিনের বিরুদ্ধে খেলুন';

  @override
  String get playWithFriend => 'বন্ধুর সাথে খেলুন';

  @override
  String get chooseModeTitle => 'একটি মোড বেছে নিন';

  @override
  String get achievementsTitle => 'অর্জন';

  @override
  String achievementsProgress(int unlocked, int total) {
    return '$total-এর মধ্যে $unlockedটি আনলক';
  }

  @override
  String get achievementsEmpty => 'অর্জন আনলক করতে একটি ম্যাচ খেলুন।';

  @override
  String levelLabel(int level) {
    return 'লেভেল $level';
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
  String get achUnlockedToast => 'অর্জন আনলক হয়েছে!';

  @override
  String get doubleXpCta => 'বিজ্ঞাপন দেখুন, XP ও কয়েন দ্বিগুণ করুন';

  @override
  String get doubleXpDone => 'XP ও কয়েন দ্বিগুণ!';

  @override
  String get doubleXpUnavailable =>
      'বিজ্ঞাপন লোড হয়নি। পরের ম্যাচে চেষ্টা করুন।';

  @override
  String levelUpToast(int level) {
    return 'লেভেল $level অর্জন হয়েছে!';
  }

  @override
  String get achFirstWinTitle => 'প্রথম জয়';

  @override
  String get achFirstWinDesc => 'প্রথমবার CPU-কে হারান';

  @override
  String get achWins10Title => 'বিজয়ী';

  @override
  String get achWins50Title => 'আধিপত্য';

  @override
  String get achWins200Title => 'কিংবদন্তি';

  @override
  String achDescWins(int count) {
    return 'CPU-এর বিরুদ্ধে $countটি ম্যাচ জিতুন';
  }

  @override
  String get achStreak3Title => 'শুরু হলো';

  @override
  String get achStreak7Title => 'আগুন ঝরছে';

  @override
  String get achStreak15Title => 'অপ্রতিরোধ্য';

  @override
  String achDescStreak(int count) {
    return 'টানা $countটি ম্যাচ জিতুন';
  }

  @override
  String get achHardWinTitle => 'এত অসম্ভব নয়';

  @override
  String get achHardWinDesc => 'অসম্ভব লেভেলে CPU-কে হারান';

  @override
  String get achAllModesTitle => 'অভিযাত্রী';

  @override
  String get achAllModesDesc => '৫টি আলাদা মোডে খেলুন';

  @override
  String get achUltimateWinsTitle => 'বোর্ডের ওস্তাদ';

  @override
  String achDescUltimateWins(int count) {
    return 'আলটিমেট টিক ট্যাক টো-তে $countটি ম্যাচ জিতুন';
  }

  @override
  String get achDaily3Title => 'অভ্যাস';

  @override
  String get achDaily7Title => 'পুরো সপ্তাহ';

  @override
  String get achDaily30Title => 'নিবেদিত';

  @override
  String achDescDaily(int count) {
    return 'টানা $count দিন খেলুন';
  }

  @override
  String get achFastWinTitle => 'বিদ্যুৎ';

  @override
  String get achFastWinDesc => 'ক্লাসিক মাত্র ৩ চালে জিতুন';

  @override
  String get achMatches50Title => 'পোড়খাওয়া';

  @override
  String get achMatches250Title => 'ম্যারাথনার';

  @override
  String achDescMatches(int count) {
    return '$countটি ম্যাচ খেলুন';
  }

  @override
  String get playGamesOpen => 'Play Games-এ দেখুন';

  @override
  String get hapticsLabel => 'কম্পন';

  @override
  String get youWinTitle => 'আপনি জিতেছেন!';

  @override
  String get cpuWinsTitle => 'মেশিন জিতেছে';

  @override
  String playerWinsTitle(String symbol) {
    return '$symbol জিতেছে!';
  }

  @override
  String winStreakChip(int count) {
    return 'টানা $count জয়!';
  }

  @override
  String dailyStreakChip(int count) {
    return 'টানা $count দিন';
  }

  @override
  String get newRecordChip => 'নতুন রেকর্ড!';

  @override
  String get cpuThinking => 'ভাবছে...';

  @override
  String get yourTurn => 'আপনার পালা';

  @override
  String get updateAvailableTitle => 'নতুন সংস্করণ উপলব্ধ';

  @override
  String get updateAvailableBody =>
      'সর্বশেষ উন্নতি ও সমাধান পেতে এখনই আপডেট করুন।';

  @override
  String get updateNowLabel => 'আপডেট করুন';

  @override
  String get updateLaterLabel => 'পরে';

  @override
  String get coinsLabel => 'কয়েন';

  @override
  String coinsGained(int amount) {
    return '+$amount কয়েন';
  }

  @override
  String get shopTitle => 'ঘুঁটির স্টাইল';

  @override
  String get shopSubtitle => 'খেলে কয়েন জিতুন আর X ও O-এর চেহারা বদলান।';

  @override
  String get shopEquip => 'ব্যবহার করুন';

  @override
  String get shopEquipped => 'চালু আছে';

  @override
  String get shopPurchased => 'নতুন স্টাইল আনলক হয়েছে!';

  @override
  String get skinAurora => 'অরোরা';

  @override
  String get skinNeon => 'নিয়ন';

  @override
  String get skinFireIce => 'আগুন ও বরফ';

  @override
  String get skinCandy => 'ক্যান্ডি';

  @override
  String get skinGold => 'সোনা ও রুপা';

  @override
  String get skinGalaxy => 'গ্যালাক্সি';

  @override
  String adCoinsCta(int amount) {
    return 'বিজ্ঞাপন দেখুন: +$amount কয়েন';
  }

  @override
  String adCoinsLeft(int count) {
    return 'আজ $countটি বাকি';
  }

  @override
  String get adCoinsSoldOut => 'বিজ্ঞাপনে আরও কয়েনের জন্য কাল আসুন।';

  @override
  String get adUnavailable =>
      'এখন কোনো বিজ্ঞাপন নেই। একটু পরে আবার চেষ্টা করুন।';

  @override
  String get dailyTitle => 'দৈনিক বোনাস';

  @override
  String get dailyReady => 'তৈরি!';

  @override
  String get dailyComeBack => 'কাল আবার আসুন';

  @override
  String dailyDay(int day) {
    return 'দিন $day';
  }

  @override
  String get dailyClaim => 'নিন';

  @override
  String get dailyHint => 'প্রতিদিন আসুন: বোনাস ৭ম দিন পর্যন্ত বাড়ে।';

  @override
  String get dailyDoubleCta => 'বিজ্ঞাপন দেখে দ্বিগুণ করুন';

  @override
  String get shopTabSkins => 'স্টাইল';

  @override
  String get shopTabCoins => 'কয়েন';

  @override
  String coinPackTitle(int amount) {
    return '$amount কয়েন';
  }

  @override
  String get coinPackBestValue => 'সেরা অফার';

  @override
  String get removeAdsTitle => 'বিজ্ঞাপন ছাড়া';

  @override
  String get removeAdsBody =>
      'ব্যানার আর ম্যাচের মাঝের বিজ্ঞাপন চিরতরে সরে যায়। পুরস্কারের বিজ্ঞাপন আপনার ইচ্ছায় থাকে।';

  @override
  String get removeAdsOwned => 'বিজ্ঞাপন সরানো হয়েছে। ধন্যবাদ!';

  @override
  String get storeLoading => 'স্টোর লোড হচ্ছে...';

  @override
  String get storeUnavailable =>
      'এখন কেনাকাটা করা যাচ্ছে না। সংযোগ দেখে পরে আবার চেষ্টা করুন।';

  @override
  String get restorePurchases => 'কেনাকাটা ফিরিয়ে আনুন';

  @override
  String get purchasePending =>
      'পেমেন্ট বাকি আছে। Google Play নিশ্চিত করলেই কেনাকাটা পৌঁছে যাবে।';

  @override
  String get purchaseFailed => 'কেনাকাটা সম্পূর্ণ হয়নি।';

  @override
  String needMoreCoins(int amount) {
    return 'এই স্টাইলের জন্য আরও $amount কয়েন লাগবে।';
  }

  @override
  String get starterTitle => 'ওয়েলকাম প্যাক';

  @override
  String starterBody(int amount) {
    return 'চিরতরে বিজ্ঞাপন ছাড়া + $amount কয়েন, এক কেনাতেই।';
  }

  @override
  String starterSave(int percent) {
    return '$percent% সাশ্রয়';
  }

  @override
  String get starterSee => 'অফার দেখুন';

  @override
  String get notNow => 'এখন না';

  @override
  String get purchaseVerifying =>
      'পেমেন্ট পাওয়া গেছে। কেনাকাটা নিশ্চিত করা হচ্ছে, একটু পরেই পৌঁছাবে।';

  @override
  String get challengeTitle => 'আজকের চ্যালেঞ্জ';

  @override
  String challengeGoal(int limit) {
    return 'সুপার টিক ট্যাক টো-তে $limit চালের মধ্যে কম্পিউটারকে হারান';
  }

  @override
  String challengeMoves(int used, int limit) {
    return '$used/$limit';
  }

  @override
  String challengeOverLimit(int limit) {
    return '$limit চাল পার: এবার পুরস্কার নেই';
  }

  @override
  String challengeWon(int coins) {
    return 'আজকের চ্যালেঞ্জ শেষ! +$coins কয়েন';
  }

  @override
  String challengeLate(int limit) {
    return 'জিতেছেন, কিন্তু $limit-এর বেশি চাল লেগেছে। আবার চেষ্টা করুন!';
  }

  @override
  String get challengeAlreadyDone => 'আজকের চ্যালেঞ্জ আগেই শেষ। কাল আবার আসুন!';

  @override
  String get challengeDoneHome => 'শেষ! কাল আবার আসুন';

  @override
  String get shareVictory => 'শেয়ার করুন';

  @override
  String get shareMessage =>
      'আমি এইমাত্র Tic Tac Verse-এ জিতলাম! আমাকে হারাতে পারবেন?';

  @override
  String get tutorialTitle => 'সুপার টিক ট্যাক টো কীভাবে খেলবেন';

  @override
  String get tutorialIntro =>
      'একটা বড় বোর্ডের ভেতরে ৯টা ছোট বোর্ড। ছোট বোর্ড জিতলে সেটা আপনার, আর এক লাইনে ৩টা জিতলে খেলা আপনার।';

  @override
  String get tutorialTapFirst =>
      'আপনার পালা। জ্বলজ্বলে ঘরে ট্যাপ করুন: মাঝের বোর্ডের উপর-ডান কোণ।';

  @override
  String get tutorialSent =>
      'আপনি উপর-ডান কোণে খেলেছেন, তাই প্রতিপক্ষকে এখন উপর-ডান বোর্ডে খেলতে হবে। আপনি যে ঘর বাছেন, সেটাই ঠিক করে অন্যজন কোথায় খেলবে।';

  @override
  String get tutorialTapSecond =>
      'প্রতিপক্ষ মাঝের ঘরে খেলেছে, তাই এখন আপনি মাঝের বোর্ডে যাবেন। জ্বলজ্বলে ঘরে ট্যাপ করুন।';

  @override
  String get tutorialFinal =>
      'এটুকুই! যদি এমন বোর্ডে পাঠানো হয় যা আগেই জেতা বা ভরা, তাহলে যেকোনো বোর্ডে খেলতে পারেন। আগে থেকে ভাবুন: প্রতিটি চাল প্রতিপক্ষকে কোথাও পাঠায়।';

  @override
  String get tutorialSkip => 'বাদ দিন';

  @override
  String get tutorialNext => 'পরের';

  @override
  String get tutorialPlay => 'চলুন খেলি!';

  @override
  String get tutorialReplay => 'টিউটোরিয়াল দেখুন';
}
