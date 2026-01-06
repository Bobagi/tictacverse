import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import 'services/metrics_service.dart';
import 'services/mobile_ads_initialization_service.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAdsInitializationService().initialize();
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      MobileAds.instance.setAppMuted(false);
      MobileAds.instance.setAppVolume(1.0);
      return;
    }

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      MobileAds.instance.setAppMuted(true);
      MobileAds.instance.setAppVolume(0.0);
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyanAccent, brightness: Brightness.dark),
        scaffoldBackgroundColor: Colors.transparent,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white.withOpacity(0.08),
          elevation: 0,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
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
  }
}
