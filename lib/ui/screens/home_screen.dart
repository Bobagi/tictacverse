import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../controllers/banner_ad_controller.dart';
import '../../services/audio_service.dart';
import '../../services/metrics_service.dart';
import '../../services/storage_service.dart';
import '../../services/update_service.dart';
import '../widgets/language_selector_sheet.dart';
import '../widgets/modern_background.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/stats_sheet.dart';
import 'mode_select_screen.dart';

/// Tela inicial enxuta: escolha do oponente (máquina ou amigo). Os modos de
/// jogo moram na ModeSelectScreen, com espaço de sobra.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.metricsService,
    required this.onLocaleSelected,
    required this.activeLocale,
  });

  final MetricsService metricsService;
  final void Function(Locale locale) onLocaleSelected;
  final Locale activeLocale;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BannerAdController bannerAdController = BannerAdController();
  final AudioService audioService = AudioService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bannerAdController.loadBannerAd(
        context: context,
        onAdLoaded: _refreshBannerArea,
        onAdFailed: _refreshBannerArea,
      );
      audioService.ensureBackgroundMusic();
    });
  }

  @override
  void dispose() {
    bannerAdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    return ModernGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(localization.appTitle),
          actions: <Widget>[
            ValueListenableBuilder<bool>(
              valueListenable: audioService.isMutedListenable,
              builder: (BuildContext context, bool isMuted, Widget? _) {
                return IconButton(
                  icon: Icon(isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded),
                  tooltip: localization.muteLabel,
                  onPressed: () => audioService.setMuted(!isMuted),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              tooltip: localization.statsTitle,
              onPressed: () {
                audioService.playUiClick();
                _openStats(localization);
              },
            ),
            IconButton(
              icon: const Icon(Icons.translate_rounded),
              tooltip: localization.languageLabel,
              onPressed: () {
                audioService.playUiClick();
                _openLanguageSelector(localization);
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: UpdateService.instance.updateAvailable,
              builder: (BuildContext context, bool hasUpdate, Widget? _) {
                return IconButton(
                  icon: Badge(
                    isLabelVisible: hasUpdate,
                    smallSize: 9,
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.settings_rounded),
                  ),
                  tooltip: localization.settingsTitle,
                  onPressed: () {
                    audioService.playUiClick();
                    _openSettings(localization);
                  },
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        localization.appTitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 34),
                      _OpponentButton(
                        icon: Icons.smart_toy_rounded,
                        label: localization.playVsCpuBig,
                        accent: const Color(0xFF6BE0FF),
                        onTap: () => _openModes(playAgainstCpu: true),
                      ),
                      const SizedBox(height: 14),
                      _OpponentButton(
                        icon: Icons.group_rounded,
                        label: localization.playWithFriend,
                        accent: const Color(0xFFFF6BD9),
                        onTap: () => _openModes(playAgainstCpu: false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassPanel(
                  padding: EdgeInsets.zero,
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: bannerAdController.expectedAdHeight,
                      child: bannerAdController.buildBannerAdWidget(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openModes({required bool playAgainstCpu}) {
    audioService.playUiClick();
    StorageService.instance.savePlayAgainstCpu(playAgainstCpu);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ModeSelectScreen(
          playAgainstCpu: playAgainstCpu,
          metricsService: widget.metricsService,
        ),
      ),
    );
  }

  void _refreshBannerArea() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openStats(AppLocalizations localization) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => StatsSheet(localization: localization),
    );
  }

  void _openLanguageSelector(AppLocalizations localization) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => LanguageSelectorSheet(
        localization: localization,
        selectedLocale: widget.activeLocale,
        onLocaleSelected: (Locale locale) {
          widget.onLocaleSelected(locale);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openSettings(AppLocalizations localization) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) =>
          SettingsSheet(localization: localization),
    );
  }
}

class _OpponentButton extends StatelessWidget {
  const _OpponentButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: <Color>[
              accent.withOpacity(0.16),
              Colors.white.withOpacity(0.05),
            ]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.65), width: 1.6),
            boxShadow: <BoxShadow>[
              BoxShadow(color: accent.withOpacity(0.28), blurRadius: 18),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withOpacity(0.5)),
                ),
                child: Icon(icon, color: accent, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
