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

  @override
  void initState() {
    super.initState();
    metricsService.recordSessionStart();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) => AppLocalizations.of(context).appTitle,
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
      home: HomeScreen(metricsService: metricsService),
    );
  }
}
