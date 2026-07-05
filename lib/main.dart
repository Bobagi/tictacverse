import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import 'services/audio_service.dart';
import 'services/consent_service.dart';
import 'services/metrics_service.dart';
import 'services/mobile_ads_initialization_service.dart';
import 'services/storage_service.dart';
import 'services/update_service.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.load();
  AudioService.instance.applyStoredSettings(
    muted: StorageService.instance.audioMuted,
    volume: StorageService.instance.audioVolume,
  );
  // O plugin google_mobile_ads não existe na web — consent/ads só fora dela,
  // senão o main() trava no splash.
  if (!kIsWeb) {
    await ConsentService().gatherConsent();
    await MobileAdsInitializationService().initialize();
  }
  // Fire-and-forget: marca o badge de "nova versão" se a Play tiver update.
  UpdateService.instance.silentCheck();
  runApp(const TicTacVerseApp());
}

class TicTacVerseApp extends StatefulWidget {
  const TicTacVerseApp({super.key});

  @override
  State<TicTacVerseApp> createState() => _TicTacVerseAppState();
}

class _TicTacVerseAppState extends State<TicTacVerseApp> with WidgetsBindingObserver {
  final MetricsService metricsService = MetricsService();
  late Locale _resolvedStartupLocale;
  Locale? _userSelectedLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    metricsService.recordSessionStart();
    _resolvedStartupLocale = _resolveSupportedLocale(WidgetsBinding.instance.platformDispatcher.locale);
    final String? storedLocaleCode = StorageService.instance.localeCode;
    if (storedLocaleCode != null) {
      _userSelectedLocale = _resolveSupportedLocale(Locale(storedLocaleCode));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!kIsWeb) {
        MobileAds.instance.setAppMuted(false);
        MobileAds.instance.setAppVolume(1.0);
      }
      AudioService.instance.resumeBackgroundMusic();
      return;
    }

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!kIsWeb) {
        MobileAds.instance.setAppMuted(true);
        MobileAds.instance.setAppVolume(0.0);
      }
      AudioService.instance.pauseAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)?.appTitle ?? '',
      locale: _userSelectedLocale ?? _resolvedStartupLocale,
      localeListResolutionCallback: (List<Locale>? locales, Iterable<Locale> supported) {
        if (_userSelectedLocale != null) {
          return _userSelectedLocale;
        }
        final Locale? deviceLocale = locales != null && locales.isNotEmpty ? locales.first : null;
        return _resolveSupportedLocale(deviceLocale ?? _resolvedStartupLocale);
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB98BFF), brightness: Brightness.dark),
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white.withOpacity(0.06),
          elevation: 0,
          foregroundColor: Colors.white,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: 21,
            color: Colors.white,
          ),
        ),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto').copyWith(
              headlineMedium: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 30,
                  color: Colors.white),
              titleLarge: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: Colors.white),
              titleMedium: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  color: Colors.white),
            ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(
        metricsService: metricsService,
        onLocaleSelected: _handleLocaleChange,
        activeLocale: _userSelectedLocale ?? _resolvedStartupLocale,
      ),
    );
  }

  Locale _resolveSupportedLocale(Locale? requestedLocale) {
    final Locale fallbackLocale = AppLocalizations.supportedLocales.first;
    if (requestedLocale == null) {
      return fallbackLocale;
    }
    for (final Locale supportedLocale in AppLocalizations.supportedLocales) {
      if (supportedLocale.languageCode == requestedLocale.languageCode) {
        return supportedLocale;
      }
    }
    return fallbackLocale;
  }

  void _handleLocaleChange(Locale locale) {
    setState(() {
      _userSelectedLocale = _resolveSupportedLocale(locale);
    });
    StorageService.instance.saveLocale(locale.languageCode);
  }
}
