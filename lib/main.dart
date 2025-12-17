import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'localization/app_localizations.dart';
import 'services/metrics_service.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(const TicTacVerseApp());
}

class TicTacVerseApp extends StatefulWidget {
  const TicTacVerseApp({super.key});

  @override
  State<TicTacVerseApp> createState() => _TicTacVerseAppState();
}

class _TicTacVerseAppState extends State<TicTacVerseApp> {
  final MetricsService metricsService = MetricsService();
  late Locale _resolvedStartupLocale;
  Locale? _userSelectedLocale;

  @override
  void initState() {
    super.initState();
    metricsService.recordSessionStart();
    _resolvedStartupLocale = _resolveInitialLocale();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) => AppLocalizations.of(context).appTitle,
      locale: _userSelectedLocale ?? _resolvedStartupLocale,
      localeListResolutionCallback: (List<Locale>? locales, Iterable<Locale> supported) {
        if (_userSelectedLocale != null) {
          return _userSelectedLocale;
        }
        final Locale? deviceLocale = locales != null && locales.isNotEmpty ? locales.first : null;
        return AppLocalizations.resolveSupportedLocale(deviceLocale ?? _resolvedStartupLocale);
      },
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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

  Locale _resolveInitialLocale() {
    final Locale platformLocale = WidgetsBinding.instance.platformDispatcher.locale;
    return AppLocalizations.resolveSupportedLocale(platformLocale);
  }

  void _handleLocaleChange(Locale locale) {
    setState(() {
      _userSelectedLocale = AppLocalizations.resolveSupportedLocale(locale);
    });
  }
}
