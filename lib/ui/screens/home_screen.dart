import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../controllers/banner_ad_controller.dart';
import '../../controllers/rewarded_ad_controller.dart';
import '../../models/store_product.dart';
import '../../services/progression_engine.dart';
import '../../services/purchase_service.dart';
import '../../services/starter_offer.dart';
import '../../services/ads_configuration.dart';
import '../../services/audio_service.dart';
import '../../services/daily_challenge.dart';
import '../../services/economy_service.dart';
import '../../services/haptics_service.dart';
import '../../services/language_suggestion.dart';
import '../../services/metrics_service.dart';
import '../../services/online/online_service.dart';
import '../../services/progression_service.dart';
import '../../services/storage_service.dart';
import '../../services/update_prompt.dart';
import '../../services/update_service.dart';
import '../widgets/achievements_sheet.dart';
import '../widgets/coin_badge.dart';
import '../widgets/daily_bonus_sheet.dart';
import '../widgets/juice/motion.dart';
import '../widgets/juice/press_scale.dart';
import '../widgets/juice/pulse.dart';
import '../widgets/language_selector_sheet.dart';
import '../widgets/modern_background.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/shop_sheet.dart';
import '../widgets/starter_offer_dialog.dart';
import '../widgets/stats_sheet.dart';
import '../widgets/update_available_dialog.dart';
import 'mode_select_screen.dart';
import 'online_lobby_screen.dart';
import 'ultimate2_screen.dart';

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

  /// Premiado opt-in da loja e do bônus diário. Nulo em build sem anúncios.
  final RewardedAdController? _rewarded =
      AdsConfiguration.adsEnabled ? RewardedAdController() : null;

  @override
  void initState() {
    super.initState();
    OnlineService.instance.pendingCode.addListener(_onPendingCode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Convite que abriu o app (link no WhatsApp): vai direto para a partida.
      _onPendingCode();
      OnlineService.instance.refreshBadge();
      if (AdsConfiguration.passiveAdsEnabled) {
        bannerAdController.loadBannerAd(
          context: context,
          onAdLoaded: _refreshBannerArea,
          onAdFailed: _refreshBannerArea,
        );
      }
      audioService.ensureBackgroundMusic();
      _maybeSuggestLanguage();
      _maybePromptUpdate();
      _maybeOfferStarter();
    });
  }

  /// Se o aparelho é de um país/idioma coberto por uma língua nova (hi/bn/ne)
  /// e o usuário nunca escolheu idioma manualmente, oferece a troca UMA vez.
  void _maybeSuggestLanguage() {
    final String? suggested = LanguageSuggestion.suggest(
      deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
      currentLanguage: widget.activeLocale.languageCode,
      hasManualChoice: StorageService.instance.localeCode != null,
      alreadySuggested: StorageService.instance.languageSuggestionShown,
    );
    if (suggested == null || !mounted) {
      return;
    }
    StorageService.instance.markLanguageSuggestionShown();
    final AppLocalizations target = lookupAppLocalizations(Locale(suggested));
    final AppLocalizations current = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF241048),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(target.langSuggestTitle),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                AudioService.instance.playUiClick();
                Navigator.of(dialogContext).pop();
              },
              child: Text(current.langSuggestKeep),
            ),
            FilledButton(
              onPressed: () {
                AudioService.instance.playUiClick();
                Navigator.of(dialogContext).pop();
                widget.onLocaleSelected(Locale(suggested));
              },
              child: Text(target.langSuggestAccept),
            ),
          ],
        );
      },
    );
  }

  /// Ao abrir o jogo, avisa (uma vez por sessão) se há versão nova.
  Future<void> _maybePromptUpdate() {
    return UpdatePromptCoordinator(
      isMounted: () => mounted,
      isTopRoute: () => ModalRoute.of(context)?.isCurrent ?? true,
      show: () =>
          showUpdateAvailableDialog(context, AppLocalizations.of(context)!),
    ).run();
  }

  /// Convite do pacote de boas-vindas (regras em [StarterOffer]). Espera a
  /// loja carregar os preços e nunca abre por cima de outro diálogo (idioma,
  /// versão nova): se a home não estiver no topo, fica para a próxima.
  Future<void> _maybeOfferStarter() async {
    final StorageService storage = StorageService.instance;
    final PurchaseService store = PurchaseService.instance;
    await Future<void>.delayed(const Duration(seconds: 3));
    for (int i = 0;
        i < 10 && store.availability.value == StoreAvailability.loading;
        i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    final DateTime now = DateTime.now();
    if (!mounted ||
        !(ModalRoute.of(context)?.isCurrent ?? false) ||
        !StarterOffer.shouldShow(
          sessions: storage.sessions,
          shows: storage.starterOfferShows,
          lastShownDay: storage.starterOfferLastDay,
          now: now,
          adsRemoved: EconomyService.instance.adsRemoved,
          productAvailable: store.productFor(starterPackProductId) != null,
        )) {
      return;
    }
    await storage.markStarterOfferShown(ProgressionEngine.dayKey(now));
    if (!mounted) {
      return;
    }
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool? open = await showStarterOfferDialog(
      context,
      localization: l,
      price: store.productFor(starterPackProductId)?.price,
    );
    if (open == true && mounted) {
      _openShop(l, initialTab: ShopTab.premium);
    }
  }

  void _onPendingCode() {
    final String? code = OnlineService.instance.pendingCode.value;
    if (code == null || !mounted) {
      return;
    }
    OnlineService.instance.pendingCode.value = null;
    _openOnline(joinCode: code);
  }

  void _openOnline({String? joinCode}) {
    audioService.playUiClick();
    HapticsService.instance.play(HapticCue.tap);
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (BuildContext context) => OnlineLobbyScreen(
            metricsService: widget.metricsService,
            joinCode: joinCode,
          ),
        ))
        .then((_) => OnlineService.instance.refreshBadge());
  }

  @override
  void dispose() {
    OnlineService.instance.pendingCode.removeListener(_onPendingCode);
    bannerAdController.dispose();
    _rewarded?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    return ModernGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          titleSpacing: 12,
          // O nome do jogo já está no logo; o topo mostra o saldo, que é o
          // atalho para a loja de visuais.
          title: ValueListenableBuilder<int>(
            valueListenable: ProgressionService.instance.revision,
            builder: (BuildContext context, int _, Widget? __) => Align(
              alignment: Alignment.centerLeft,
              child: CoinBadge(
                coins: EconomyService.instance.coins,
                semanticLabel:
                    '${EconomyService.instance.coins} ${localization.coinsLabel}. ${localization.shopTitle}',
                // Moedas se gastam nos visuais: o saldo abre direto lá.
                onTap: () => _openShop(localization),
              ),
            ),
          ),
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
                  // Rola quando falta altura (tela 360x640 com a fonte grande):
                  // nenhum botão pode ficar escondido atrás do banner.
                  child: LayoutBuilder(builder:
                      (BuildContext context, BoxConstraints constraints) {
                    return SingleChildScrollView(
                      // Sem recorte: a sombra neon dos botões vazava cortada
                      // nas bordas da área rolável (retângulo claro visível).
                      clipBehavior: Clip.none,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            // Logo ao lado do nome: o banner médio (300x250)
                            // ocupa a base da tela, e o espaço que sobra é dos
                            // botões de jogar e dos atalhos.
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                // O ícone "respira" devagar: a home nunca fica parada.
                                Pulse(
                                  maxScale: 1.05,
                                  period: const Duration(milliseconds: 2400),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      'assets/icon/app_icon.png',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Flexible(
                                  child: Text(
                                    localization.appTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
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
                              breathPhase: 0.33,
                              onTap: () => _openModes(playAgainstCpu: false),
                            ),
                            const SizedBox(height: 14),
                            // Online contra um amigo, cada um no seu celular.
                            // O selo conta as partidas esperando a jogada dele.
                            ValueListenableBuilder<int>(
                              valueListenable:
                                  OnlineService.instance.myTurnCount,
                              builder: (BuildContext context, int turns,
                                      Widget? _) =>
                                  _OpponentButton(
                                key: const ValueKey<String>('home-online'),
                                icon: Icons.public_rounded,
                                label: localization.onlineButton,
                                accent: VerseColors.coin,
                                breathPhase: 0.66,
                                badge: turns,
                                onTap: _openOnline,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ValueListenableBuilder<int>(
                              valueListenable:
                                  ProgressionService.instance.revision,
                              builder:
                                  (BuildContext context, int _, Widget? __) {
                                final EconomyService economy =
                                    EconomyService.instance;
                                return Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _HomeTile(
                                        key: const ValueKey<String>(
                                            'home-daily'),
                                        icon: Icons.card_giftcard_rounded,
                                        title: localization.dailyTitle,
                                        subtitle: economy.canClaimDaily
                                            ? localization.dailyReady
                                            : localization.dailyComeBack,
                                        highlight: economy.canClaimDaily,
                                        breathPhase: 0.15,
                                        onTap: () => _openDaily(localization),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _HomeTile(
                                        key:
                                            const ValueKey<String>('home-shop'),
                                        icon: Icons.palette_rounded,
                                        title: localization.shopTitle,
                                        subtitle: skinName(
                                            localization, economy.equippedSkin),
                                        highlight: false,
                                        breathPhase: 0.45,
                                        onTap: () => _openShop(localization),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            ValueListenableBuilder<int>(
                              valueListenable:
                                  ProgressionService.instance.revision,
                              builder:
                                  (BuildContext context, int _, Widget? __) =>
                                      _buildChallengeTile(localization),
                            ),
                            const SizedBox(height: 14),
                            // O nível é a porta de entrada das conquistas: fica no
                            // corpo da home, e não num ícone da AppBar, para o
                            // jogador ver o progresso sem procurar.
                            ValueListenableBuilder<int>(
                              valueListenable:
                                  ProgressionService.instance.revision,
                              builder:
                                  (BuildContext context, int _, Widget? __) {
                                return Semantics(
                                  button: true,
                                  label: localization.achievementsTitle,
                                  child: PressScale(
                                    pressedScale: 0.97,
                                    child: GestureDetector(
                                      onTap: () {
                                        audioService.playUiClick();
                                        HapticsService.instance
                                            .play(HapticCue.tap);
                                        _openAchievements(localization);
                                      },
                                      child: LevelPanel(
                                          localization: localization),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                if (AdsConfiguration.passiveAdsEnabled) ...<Widget>[
                  const SizedBox(height: 16),
                  GlassPanel(
                    padding: EdgeInsets.zero,
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: bannerAdController
                            .expectedAdHeightFor(MediaQuery.of(context).size),
                        child: bannerAdController.buildBannerAdWidget(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openModes({required bool playAgainstCpu}) {
    audioService.playUiClick();
    HapticsService.instance.play(HapticCue.tap);
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

  void _openAchievements(AppLocalizations localization) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      // Sem isto o sheet fica preso em 9/16 da tela e a lista de 16 conquistas
      // é cortada no meio de um card mesmo sobrando espaço.
      isScrollControlled: true,
      builder: (BuildContext context) =>
          AchievementsSheet(localization: localization),
    );
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

  /// Desafio do dia: um card largo, abaixo dos atalhos, porque é o motivo de
  /// voltar amanhã. Concluído, mostra a sequência e "volte amanhã".
  Widget _buildChallengeTile(AppLocalizations localization) {
    const DailyChallengeEngine rules = DailyChallengeEngine();
    final DateTime now = DateTime.now();
    final DailyChallenge challenge = rules.forDay(now);
    final bool open = rules.canComplete(StorageService.instance.progress, now);
    final int streak =
        rules.currentStreak(StorageService.instance.progress, now);
    final int reward = DailyChallengeEngine.rewardForStreak(
        rules.nextStreak(StorageService.instance.progress, now));
    return _HomeTile(
      key: const ValueKey<String>('home-challenge'),
      icon: Icons.emoji_events_rounded,
      title: localization.challengeTitle,
      subtitleLines: 2,
      subtitle: open
          ? '${localization.challengeGoalShort(challenge.moveLimit)} · +$reward'
          : streak >= 2
              ? '${localization.challengeDoneHome} · '
                  '${localization.dailyStreakChip(streak)}'
              : localization.challengeDoneHome,
      highlight: open,
      breathPhase: 0.75,
      onTap: () {
        audioService.playUiClick();
        HapticsService.instance.play(HapticCue.tap);
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => Ultimate2Screen(
            playAgainstCpu: true,
            cpuDifficulty: challenge.difficulty,
            metricsService: widget.metricsService,
            challenge: challenge,
          ),
        ));
      },
    );
  }

  void _openShop(AppLocalizations localization,
      {ShopTab initialTab = ShopTab.skins}) {
    audioService.playUiClick();
    HapticsService.instance.play(HapticCue.tap);
    showShopSheet(context, localization,
            rewarded: _rewarded, initialTab: initialTab)
        // Quem comprou "sem anúncios" volta para a home já sem o banner.
        .then((_) => _refreshBannerArea());
  }

  void _openDaily(AppLocalizations localization) {
    audioService.playUiClick();
    HapticsService.instance.play(HapticCue.tap);
    showDailyBonusSheet(context, localization, rewarded: _rewarded);
  }

  void _openSettings(AppLocalizations localization) {
    showSettingsSheet(context, localization);
  }
}

class _OpponentButton extends StatelessWidget {
  const _OpponentButton({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.breathPhase = 0,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  /// Desencontra a respiração dos ícones vizinhos.
  final double breathPhase;

  /// Partidas esperando o jogador (só o botão do online usa).
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PressScale(
        pressedScale: 0.96,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            // Três botões grandes desde o online: 12 em vez de 16 de respiro
            // segura o desafio do dia acima da dobra em 320x568.
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                Badge(
                  isLabelVisible: badge > 0,
                  backgroundColor: Colors.redAccent,
                  label: Text('$badge'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withOpacity(0.5)),
                    ),
                    child: Breathe(
                      phase: breathPhase,
                      child: Icon(icon, color: accent, size: 30),
                    ),
                  ),
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
      ),
    );
  }
}

/// Atalho secundário da home (bônus diário, visuais). Menor que os botões de
/// oponente de propósito: jogar continua sendo a ação principal.
class _HomeTile extends StatelessWidget {
  const _HomeTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleLines = 1,
    required this.highlight,
    required this.onTap,
    this.breathPhase = 0,
  });

  final double breathPhase;
  final IconData icon;
  final String title;
  final String subtitle;
  final int subtitleLines;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = highlight ? VerseColors.coin : VerseColors.mutedText;
    final Widget tile = Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(highlight ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withOpacity(highlight ? 0.8 : 0.35),
          width: highlight ? 1.6 : 1.2,
        ),
      ),
      child: Row(
        children: <Widget>[
          Badge(
            isLabelVisible: highlight,
            smallSize: 9,
            backgroundColor: Colors.redAccent,
            // Card "pronto para resgatar" balança o ícone: o olho vai nele.
            child: Breathe(
              phase: breathPhase,
              child: Wobble(
                active: highlight,
                angle: 0.16,
                child: Icon(icon,
                    color: highlight ? VerseColors.coin : Colors.white,
                    size: 26),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: subtitleLines,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: PressScale(
        pressedScale: 0.96,
        child: GestureDetector(
          onTap: onTap,
          // Mesma árvore com e sem destaque: só o `active` muda.
          child: Pulse(
            active: highlight,
            maxScale: 1.03,
            period: const Duration(milliseconds: 1400),
            child: tile,
          ),
        ),
      ),
    );
  }
}
