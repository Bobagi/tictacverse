// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Tic Tac Verse';

  @override
  String get modeClassicTitle => 'क्लासिक टिक टैक टो';

  @override
  String get modeClassicSubtitle => 'झटपट राउंड के लिए पारंपरिक नियम।';

  @override
  String get modeShiftTitle => 'टिक टैक शिफ्ट';

  @override
  String get modeShiftSubtitle =>
      'हर खिलाड़ी के सिर्फ़ तीन मोहरे सक्रिय रहते हैं।';

  @override
  String get modeChaosTitle => 'टिक टैक कैओस';

  @override
  String get modeChaosSubtitle => 'हर कुछ चालों पर एक कैओस नियम आ जाता है।';

  @override
  String get modeUltimateTitle => 'अल्टीमेट मिनी टिक टैक';

  @override
  String get modeUltimateSubtitle => 'बदलती चुनौती शर्तों के साथ जीतें।';

  @override
  String get startMatch => 'मैच शुरू करें';

  @override
  String get twoPlayers => 'दो खिलाड़ी';

  @override
  String get cpuOpponent => 'CPU के खिलाफ़ खेलें';

  @override
  String get currentPlayer => 'मौजूदा खिलाड़ी';

  @override
  String get drawResult => 'मैच बराबर रहा!';

  @override
  String get winnerResult => 'विजेता';

  @override
  String get playAgain => 'फिर से खेलें';

  @override
  String get backToMenu => 'मेनू पर वापस';

  @override
  String get chaosRemovePiece => 'कैओस: एक मोहरा अचानक हटा दिया गया!';

  @override
  String get chaosBlockCell => 'कैओस: इस चाल में एक खाना ब्लॉक है!';

  @override
  String get chaosSwapSymbols => 'कैओस: एक चाल के लिए निशान आपस में बदल गए!';

  @override
  String get ultimateNoCenter => 'बीच वाले खाने का इस्तेमाल किए बिना जीतें।';

  @override
  String get ultimateLimitedMoves => 'सीमित चालों के भीतर जीतें।';

  @override
  String get movesRemaining => 'बची हुई चालें';

  @override
  String get adsBannerPlacement =>
      'बैनर विज्ञापन सिर्फ़ गेम स्क्रीन पर दिखते हैं।';

  @override
  String get adInterstitialHint =>
      'कुछ मैचों के बाद इंटरस्टीशियल विज्ञापन दिखते हैं।';

  @override
  String get gameModeLabel => 'गेम मोड';

  @override
  String get helpTitle => 'मदद';

  @override
  String get tapToClaim => 'किसी भी खाने पर टैप करके उसे अपना बनाएँ';

  @override
  String get closeLabel => 'बंद करें';

  @override
  String get winInstruction => 'तीन को एक लाइन में लगाएँ और नीयॉन जीत पाएँ।';

  @override
  String get takeTurnCta => 'अपनी चाल चलें और बोर्ड को रोशन करें';

  @override
  String get playLabel => 'खेलें';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get audioLabel => 'ऑडियो';

  @override
  String get muteLabel => 'म्यूट';

  @override
  String get volumeLabel => 'वॉल्यूम';

  @override
  String get difficultyLabel => 'कठिनाई';

  @override
  String get difficultyEasy => 'आसान';

  @override
  String get difficultyMedium => 'मध्यम';

  @override
  String get difficultyHard => 'नामुमकिन';

  @override
  String get statsTitle => 'आँकड़े';

  @override
  String get statsTotalMatches => 'खेले गए मैच';

  @override
  String get statsVsCpu => 'CPU के खिलाफ़';

  @override
  String get statsWins => 'जीत';

  @override
  String get statsLosses => 'हार';

  @override
  String get statsDraws => 'बराबरी';

  @override
  String get statsStreak => 'जीत का सिलसिला';

  @override
  String get statsBestStreak => 'सबसे लंबा सिलसिला';

  @override
  String get statsByMode => 'मोड के अनुसार';

  @override
  String get statsEmpty => 'अपने आँकड़े बनाने के लिए एक मैच खेलें!';

  @override
  String get updatesLabel => 'अपडेट';

  @override
  String get checkUpdatesLabel => 'अपडेट जाँचें';

  @override
  String get upToDateMessage => 'आप पहले से ही नवीनतम संस्करण पर हैं!';

  @override
  String get updateFailedMessage =>
      'अपडेट जाँच नहीं हो सकी। बाद में फिर कोशिश करें।';

  @override
  String get modeUltimate2Title => 'अल्टीमेट टिक टैक टो';

  @override
  String get modeUltimate2Subtitle =>
      'एक में 9 बोर्ड। आपकी चाल तय करती है कि विरोधी कहाँ खेलेगा।';

  @override
  String get ultimate2FreeMove => 'फ़्री चाल: किसी भी बोर्ड में खेलें';

  @override
  String get ultimate2PlayIn => 'हाइलाइट किए गए बोर्ड में खेलें';

  @override
  String get ultimate2Help =>
      'बड़े बोर्ड के हर खाने में एक छोटा टिक टैक टो है। छोटे बोर्ड में आप जो खाना चुनते हैं, विरोधी को उसी नंबर वाले बोर्ड में भेजा जाता है। छोटा बोर्ड जीतकर बड़े बोर्ड पर उसका खाना अपना बनाएँ — अपने तीन खाने एक लाइन में लगाकर मैच जीतें। अगर आपका अगला बोर्ड बंद है, तो आप कहीं भी खेल सकते हैं।';

  @override
  String get playVsCpuBig => 'मशीन के खिलाफ़ खेलें';

  @override
  String get playWithFriend => 'दोस्त के साथ खेलें';

  @override
  String get chooseModeTitle => 'एक मोड चुनें';
}
