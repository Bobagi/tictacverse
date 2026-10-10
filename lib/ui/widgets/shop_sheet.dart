import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../controllers/rewarded_ad_controller.dart';
import '../../models/board_theme.dart';
import '../../models/piece_skin.dart';
import '../../models/player_marker.dart';
import '../../models/store_product.dart';
import '../../services/audio_service.dart';
import '../../services/economy_engine.dart';
import '../../services/economy_service.dart';
import '../../services/haptics_service.dart';
import '../../services/progression_service.dart';
import '../../services/purchase_service.dart';
import 'coin_badge.dart';
import 'game_board.dart' show NeonGridPainter;
import 'juice/motion.dart';
import 'juice/particles.dart';
import 'juice/press_scale.dart';
import 'modern_background.dart';
import 'piece_glyph.dart';

/// Abas da loja: visuais (gastar moedas) e moedas (compras na Play).
enum ShopTab { skins, boards, premium }

/// Abre a loja. [rewarded] nulo = sem anúncios (build sem ads): a loja
/// funciona igual, só sem o atalho de moedas por anúncio. [purchases] nulo =
/// o serviço do app (o teste injeta um com backend falso).
Future<void> showShopSheet(
  BuildContext context,
  AppLocalizations localization, {
  RewardedAdGateway? rewarded,
  ShopTab initialTab = ShopTab.skins,
  PurchaseService? purchases,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) => ShopSheet(
      localization: localization,
      rewarded: rewarded,
      initialTab: initialTab,
      purchases: purchases,
    ),
  );
}

String themeName(AppLocalizations l, BoardTheme theme) => switch (theme.id) {
      'sunset' => l.themeSunset,
      'ocean' => l.themeOcean,
      'emerald' => l.themeEmerald,
      'royal' => l.themeRoyal,
      _ => l.themeNeonGrid,
    };

String skinName(AppLocalizations l, PieceSkin skin) => switch (skin.id) {
      'aurora' => l.skinAurora,
      'fireIce' => l.skinFireIce,
      'candy' => l.skinCandy,
      'gold' => l.skinGold,
      'galaxy' => l.skinGalaxy,
      _ => l.skinNeon,
    };

class ShopSheet extends StatefulWidget {
  const ShopSheet({
    super.key,
    required this.localization,
    this.rewarded,
    this.initialTab = ShopTab.skins,
    this.purchases,
  });

  final AppLocalizations localization;
  final RewardedAdGateway? rewarded;
  final ShopTab initialTab;
  final PurchaseService? purchases;

  @override
  State<ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<ShopSheet> {
  final EconomyService _economy = EconomyService.instance;
  late final PurchaseService _purchases =
      widget.purchases ?? PurchaseService.instance;
  late ShopTab _tab = widget.initialTab;
  bool _watching = false;
  String? _message;

  /// Confete e moedas por cima da loja (compra concluída, visual novo).
  final ParticleController _fx = ParticleController();

  /// O convite de anúncio só aparece com anúncio JÁ carregado (prometer e não
  /// ter o que mostrar é pior do que não oferecer). O gateway não avisa quando
  /// carrega, então a sheet confere enquanto está aberta.
  Timer? _readyPoll;
  bool _adReady = false;

  @override
  void initState() {
    super.initState();
    _purchases.lastOutcome.addListener(_onPurchaseOutcome);
    _armPrices();
    final RewardedAdGateway? rewarded = widget.rewarded;
    if (rewarded != null) {
      rewarded.loadRewardedAd();
      _adReady = rewarded.isReady;
      _readyPoll = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted && rewarded.isReady != _adReady) {
          setState(() => _adReady = rewarded.isReady);
        }
      });
    }
  }

  @override
  void dispose() {
    _purchases.lastOutcome.removeListener(_onPurchaseOutcome);
    _readyPoll?.cancel();
    _armTimer?.cancel();
    _fx.dispose();
    super.dispose();
  }

  void _onPurchaseOutcome() {
    final PurchaseOutcome? outcome = _purchases.lastOutcome.value;
    if (outcome == null || !mounted) {
      return;
    }
    final AppLocalizations l = widget.localization;
    setState(() {
      _message = switch (outcome.kind) {
        PurchaseOutcomeKind.unlocked => l.purchaseUnlocked,
        PurchaseOutcomeKind.pending => l.purchasePending,
        PurchaseOutcomeKind.failed => l.purchaseFailed,
        PurchaseOutcomeKind.canceled => null,
      };
    });
    if (outcome.kind == PurchaseOutcomeKind.unlocked) {
      AudioService.instance.play(Sfx.levelUp);
      HapticsService.instance.play(HapticCue.capture);
      _celebrate(big: true);
    }
  }

  /// Compra com dinheiro: chuva de confete dourado. Visual comprado com
  /// moedas: explosão de moedas no meio da loja.
  void _celebrate({required bool big}) {
    if (big) {
      _fx.confetti(colors: const <Color>[
        VerseColors.coin,
        Color(0xFFFF6BD9),
        Color(0xFF6BE0FF),
        Colors.white,
      ], count: 70);
    } else {
      _fx.burst(
        center: _fx.viewport.center(Offset.zero),
        color: VerseColors.coin,
        accent: Colors.white,
        count: 30,
        speed: 1.6,
        size: 6,
      );
    }
  }

  void _selectTab(ShopTab tab) {
    if (tab == _tab) {
      return;
    }
    AudioService.instance.playUiClick();
    setState(() {
      _tab = tab;
      _armPrices();
      _message = null;
    });
  }

  /// A aba Moedas pode surgir sob o dedo (tocar num visual trancado troca de
  /// aba), então os botões de preço só valem [_armDelay] depois de ela
  /// aparecer: um toque duplo não pode abrir uma compra.
  static const Duration _armDelay = Duration(milliseconds: 600);
  Timer? _armTimer;
  bool _pricesArmed = false;

  void _armPrices() {
    _pricesArmed = false;
    _armTimer?.cancel();
    _armTimer = Timer(_armDelay, () => _pricesArmed = true);
  }

  Future<void> _buyProduct(StoreProduct product) async {
    if (!_pricesArmed) {
      return;
    }
    AudioService.instance.playUiClick();
    HapticsService.instance.play(HapticCue.tap);
    setState(() => _message = null);
    await _purchases.buy(product.id);
  }

  void _onSkinTap(PieceSkin skin) => _onItemTap(
        owned: _economy.owns(skin),
        equip: () => _economy.equip(skin),
        buy: () => _economy.buy(skin),
        price: skin.price,
      );

  void _onThemeTap(BoardTheme theme) => _onItemTap(
        owned: _economy.ownsTheme(theme),
        equip: () => _economy.equipTheme(theme),
        buy: () => _economy.buyTheme(theme),
        price: theme.price,
      );

  void _onItemTap({
    required bool owned,
    required bool Function() equip,
    required SkinPurchaseResult Function() buy,
    required int price,
  }) {
    final AppLocalizations l = widget.localization;
    if (owned) {
      if (equip()) {
        AudioService.instance.playUiClick();
        HapticsService.instance.play(HapticCue.tap);
      }
      setState(() => _message = null);
      return;
    }
    final SkinPurchaseResult result = buy();
    setState(() {
      if (result == SkinPurchaseResult.purchased) {
        AudioService.instance.play(Sfx.achievement);
        HapticsService.instance.play(HapticCue.capture);
        _celebrate(big: false);
        _message = l.shopPurchased;
      } else if (result == SkinPurchaseResult.notEnoughCoins &&
          _purchases.availability.value == StoreAvailability.ready) {
        // Visual trancado leva ao Premium, dizendo quanto falta em moedas e
        // que a Coleção completa libera tudo de uma vez.
        AudioService.instance.playUiClick();
        _tab = ShopTab.premium;
        _armPrices();
        _message = l.needMoreCoinsPremium(price - _economy.coins);
      } else {
        _message = null;
      }
    });
  }

  /// Moedas por anúncio: opt-in, rótulo diz o valor, crédito só com a
  /// confirmação do SDK. `_watching` trava o toque duplo antes do `await`.
  Future<void> _watchAdForCoins() async {
    final RewardedAdGateway? rewarded = widget.rewarded;
    if (rewarded == null || _watching || _economy.adCoinsRemaining <= 0) {
      return;
    }
    AudioService.instance.playUiClick();
    setState(() {
      _watching = true;
      _message = null;
    });
    final bool earned = await rewarded.showForReward();
    if (!mounted) {
      if (earned) {
        _economy.grantAdCoins();
      }
      return;
    }
    setState(() {
      _watching = false;
      if (earned) {
        final int got = _economy.grantAdCoins();
        _message = widget.localization.coinsGained(got);
        AudioService.instance.play(Sfx.levelUp);
        HapticsService.instance.play(HapticCue.capture);
      } else {
        _message = widget.localization.adUnavailable;
        rewarded.loadRewardedAd();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = widget.localization;
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Stack(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: GlassPanel(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.86,
              ),
              child: ValueListenableBuilder<int>(
                valueListenable: ProgressionService.instance.revision,
                builder: (BuildContext context, int _, Widget? __) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Breathe(
                            child: Icon(
                                switch (_tab) {
                                  ShopTab.skins => Icons.palette_rounded,
                                  ShopTab.boards => Icons.grid_on_rounded,
                                  ShopTab.premium =>
                                    Icons.workspace_premium_rounded,
                                },
                                color: VerseColors.coin),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                switch (_tab) {
                                  ShopTab.skins => l.shopTitle,
                                  ShopTab.boards => l.shopTabBoards,
                                  ShopTab.premium => l.shopTabPremium,
                                },
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge),
                          ),
                          CoinBadge(coins: _economy.coins),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: l.closeLabel,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _ShopTabs(
                        selected: _tab,
                        skinsLabel: l.shopTabSkins,
                        boardsLabel: l.shopTabBoards,
                        coinsLabel: l.shopTabPremium,
                        onSelect: _selectTab,
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: SingleChildScrollView(
                          child: switch (_tab) {
                            ShopTab.skins => _buildSkinsTab(context, l),
                            ShopTab.boards => _buildBoardsTab(context, l),
                            ShopTab.premium => _buildPremiumTab(context, l),
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(child: ParticleField(controller: _fx)),
        ),
      ],
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Text(
      _message!,
      key: const ValueKey<String>('shop-message'),
      textAlign: TextAlign.center,
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: VerseColors.coin, fontWeight: FontWeight.w700),
    );
  }

  Widget _skinPreview(PieceSkin skin) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PieceGlyph(marker: PlayerMarker.cross, skin: skin, size: 48),
            const SizedBox(width: 6),
            PieceGlyph(marker: PlayerMarker.nought, skin: skin, size: 48),
          ],
        ),
      );

  Widget _buildBoardsTab(BuildContext context, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l.boardsSubtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: VerseColors.mutedText),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (BuildContext context, BoxConstraints c) {
          const double gap = 10;
          final double w = (c.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: <Widget>[
              for (final BoardTheme theme in boardThemeCatalog)
                SizedBox(
                  width: w,
                  child: _SkinCard(
                    key: ValueKey<String>('theme-${theme.id}'),
                    price: theme.price,
                    preview: SizedBox(
                      width: 56,
                      height: 56,
                      child: CustomPaint(
                        painter: NeonGridPainter(
                          progress: 0.25,
                          colorA: theme.gridA,
                          colorB: theme.gridB,
                        ),
                      ),
                    ),
                    name: themeName(l, theme),
                    owned: _economy.ownsTheme(theme),
                    equipped: _economy.equippedTheme.id == theme.id,
                    coins: _economy.coins,
                    localization: l,
                    onTap: () => _onThemeTap(theme),
                  ),
                ),
            ],
          );
        }),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildMessage(context),
          ),
      ],
    );
  }

  Widget _buildSkinsTab(BuildContext context, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l.shopSubtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: VerseColors.mutedText),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (BuildContext context, BoxConstraints c) {
          const double gap = 10;
          final double w = (c.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: <Widget>[
              for (final PieceSkin skin in pieceSkinCatalog)
                SizedBox(
                  width: w,
                  child: _SkinCard(
                    price: skin.price,
                    preview: _skinPreview(skin),
                    name: skinName(l, skin),
                    owned: _economy.owns(skin),
                    equipped: _economy.equippedSkin.id == skin.id,
                    coins: _economy.coins,
                    localization: l,
                    onTap: () => _onSkinTap(skin),
                  ),
                ),
            ],
          );
        }),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildMessage(context),
          ),
        if (widget.rewarded != null && (_adReady || _watching)) ...<Widget>[
          // Respiro grande: o convite de anúncio não encosta em nenhum botão
          // de compra.
          const SizedBox(height: 22),
          _buildAdCoins(context, l),
        ],
      ],
    );
  }

  /// Compras com dinheiro de verdade. Sem convite de anúncio nesta aba: o
  /// premiado mora na aba de visuais, longe dos botões de preço.
  /// Compras com dinheiro (tudo compra única, ver StoreProduct). Sem convite
  /// de anúncio aqui: o premiado mora na aba de visuais, longe dos preços.
  Widget _buildPremiumTab(BuildContext context, AppLocalizations l) {
    return ValueListenableBuilder<StoreAvailability>(
      valueListenable: _purchases.availability,
      builder: (BuildContext context, StoreAvailability availability, _) {
        if (availability != StoreAvailability.ready) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: <Widget>[
                if (availability == StoreAvailability.loading) ...<Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                ],
                Text(
                  availability == StoreAvailability.loading
                      ? l.storeLoading
                      : l.storeUnavailable,
                  key: const ValueKey<String>('store-unavailable'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: VerseColors.mutedText),
                ),
                if (_message != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _buildMessage(context),
                ],
              ],
            ),
          );
        }
        return ValueListenableBuilder<String?>(
          valueListenable: _purchases.buying,
          builder: (BuildContext context, String? buying, _) {
            String? priceOf(String id) => _purchases.productFor(id)?.price;
            final bool ownsCollection = _purchases.isOwned(collectionProductId);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (_message != null) ...<Widget>[
                  _buildMessage(context),
                  const SizedBox(height: 12),
                ],
                // Boas-vindas só para quem ainda vê anúncio: para quem já
                // tirou, seria pagar de novo pelo mesmo direito.
                if (!_economy.adsRemoved &&
                    priceOf(starterPackProductId) != null) ...<Widget>[
                  _StarterPackCard(
                    price: priceOf(starterPackProductId)!,
                    busy: buying == starterPackProductId,
                    enabled: buying == null,
                    localization: l,
                    onBuy: () =>
                        _buyProduct(storeProductById(starterPackProductId)!),
                  ),
                  const SizedBox(height: 10),
                ],
                if (ownsCollection ||
                    priceOf(collectionProductId) != null) ...<Widget>[
                  _CollectionCard(
                    owned: ownsCollection,
                    price: priceOf(collectionProductId),
                    busy: buying == collectionProductId,
                    enabled: buying == null,
                    localization: l,
                    onBuy: () =>
                        _buyProduct(storeProductById(collectionProductId)!),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_economy.adsRemoved || priceOf(removeAdsProductId) != null)
                  _RemoveAdsCard(
                    owned: _economy.adsRemoved,
                    price: priceOf(removeAdsProductId),
                    busy: buying == removeAdsProductId,
                    enabled: buying == null,
                    localization: l,
                    onBuy: () =>
                        _buyProduct(storeProductById(removeAdsProductId)!),
                  ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton.icon(
                    key: const ValueKey<String>('store-restore'),
                    onPressed: buying == null
                        ? () {
                            AudioService.instance.playUiClick();
                            _purchases.restore();
                          }
                        : null,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: Text(l.restorePurchases),
                    style: TextButton.styleFrom(
                        foregroundColor: VerseColors.mutedText),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAdCoins(BuildContext context, AppLocalizations l) {
    final int left = _economy.adCoinsRemaining;
    if (left <= 0) {
      return Text(
        l.adCoinsSoldOut,
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: VerseColors.mutedText),
      );
    }
    return Column(
      children: <Widget>[
        OutlinedButton.icon(
          key: const ValueKey<String>('shop-ad-coins'),
          onPressed: _watching ? null : _watchAdForCoins,
          icon: _watching
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.ondemand_video_rounded),
          label: Text(l.adCoinsCta(EconomyEngine.adCoinsReward)),
          style: OutlinedButton.styleFrom(
            foregroundColor: VerseColors.coin,
            side: BorderSide(color: VerseColors.coin.withOpacity(0.6)),
            minimumSize: const Size.fromHeight(46),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.adCoinsLeft(left),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: VerseColors.mutedText),
        ),
      ],
    );
  }
}

/// Cartão de item da loja paga em moedas (visual de peça ou tema de
/// tabuleiro): prévia, nome e preço/estado.
class _SkinCard extends StatelessWidget {
  const _SkinCard({
    super.key,
    required this.price,
    required this.preview,
    required this.name,
    required this.owned,
    required this.equipped,
    required this.coins,
    required this.localization,
    required this.onTap,
  });

  final int price;
  final Widget preview;
  final String name;
  final bool owned;
  final bool equipped;
  final int coins;
  final AppLocalizations localization;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool affordable = coins >= price;
    final Color border = equipped
        ? VerseColors.coin
        : Colors.white.withOpacity(owned ? 0.35 : 0.15);
    final Widget action;
    if (equipped) {
      action = _pill(context, localization.shopEquipped, VerseColors.coin,
          icon: Icons.check_rounded, filled: true);
    } else if (owned) {
      action = _pill(context, localization.shopEquip, Colors.white);
    } else {
      // Sempre o preço, com ou sem saldo: o jogador escolhe pelo que quer,
      // não por uma contagem do que falta (o "Faltam 210" da v1.12 parecia
      // barra de progressão). Sem saldo, o toque leva aos pacotes de moedas.
      action = _pill(
          context, '$price', affordable ? VerseColors.coin : Colors.white70,
          icon:
              affordable ? Icons.monetization_on_rounded : Icons.lock_rounded);
    }
    return Semantics(
      button: true,
      label: '$name. ${owned ? '' : '$price ${localization.coinsLabel}'}',
      child: PressScale(
        pressedScale: 0.96,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(equipped ? 0.08 : 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: equipped ? 2 : 1.2),
            ),
            child: Column(
              children: <Widget>[
                // A prévia encolhe em vez de estourar o cartão em 320px.
                SizedBox(height: 56, child: Center(child: preview)),
                const SizedBox(height: 8),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                action,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String text, Color color,
      {IconData? icon, bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopTabs extends StatelessWidget {
  const _ShopTabs({
    required this.selected,
    required this.skinsLabel,
    required this.boardsLabel,
    required this.coinsLabel,
    required this.onSelect,
  });

  final ShopTab selected;
  final String skinsLabel;
  final String boardsLabel;
  final String coinsLabel;
  final ValueChanged<ShopTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: <Widget>[
          _tab(context, ShopTab.skins, skinsLabel, Icons.palette_rounded),
          _tab(context, ShopTab.boards, boardsLabel, Icons.grid_on_rounded),
          _tab(context, ShopTab.premium, coinsLabel,
              Icons.workspace_premium_rounded),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, ShopTab tab, String label, IconData icon) {
    final bool active = tab == selected;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          key: ValueKey<String>('shop-tab-${tab.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(tab),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? VerseColors.coin.withOpacity(0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: active
                      ? VerseColors.coin.withOpacity(0.7)
                      : Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon,
                    size: 18,
                    color: active ? VerseColors.coin : Colors.white70),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: active ? VerseColors.coin : Colors.white70,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão de preço. O preço vem da Play já na moeda do jogador.
class _PriceButton extends StatelessWidget {
  const _PriceButton({
    required this.price,
    required this.busy,
    required this.enabled,
    required this.onPressed,
    this.buttonKey,
  });

  final String price;
  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: buttonKey,
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: VerseColors.coin,
        foregroundColor: const Color(0xFF1A0B2E),
        minimumSize: const Size(88, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF1A0B2E)))
          : Text(price,
              maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _RemoveAdsCard extends StatelessWidget {
  const _RemoveAdsCard({
    required this.owned,
    required this.price,
    required this.busy,
    required this.enabled,
    required this.localization,
    required this.onBuy,
  });

  final bool owned;
  final String? price;
  final bool busy;
  final bool enabled;
  final AppLocalizations localization;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = localization;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: <Color>[
          const Color(0xFF6BE0FF).withOpacity(0.14),
          const Color(0xFFFF6BD9).withOpacity(0.14),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: owned ? VerseColors.coin : Colors.white.withOpacity(0.25),
            width: owned ? 2 : 1.2),
      ),
      child: Row(
        children: <Widget>[
          Icon(owned ? Icons.verified_rounded : Icons.block_rounded,
              color: owned ? VerseColors.coin : Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l.removeAdsTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(owned ? l.removeAdsOwned : l.removeAdsBody,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: VerseColors.mutedText)),
              ],
            ),
          ),
          if (!owned && price != null) ...<Widget>[
            const SizedBox(width: 10),
            _PriceButton(
              buttonKey: const ValueKey<String>('store-buy-remove_ads'),
              price: price!,
              busy: busy,
              enabled: enabled,
              onPressed: onBuy,
            ),
          ],
        ],
      ),
    );
  }
}

class _StarterPackCard extends StatelessWidget {
  const _StarterPackCard({
    required this.price,
    required this.busy,
    required this.enabled,
    required this.localization,
    required this.onBuy,
  });

  final String price;
  final bool busy;
  final bool enabled;
  final AppLocalizations localization;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = localization;
    final PieceSkin aurora = pieceSkinById('aurora');
    return Shine(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        key: const ValueKey<String>('store-starter-card'),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: <Color>[
            VerseColors.coin.withOpacity(0.22),
            const Color(0xFFFF6BD9).withOpacity(0.18),
          ]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VerseColors.coin, width: 1.6),
        ),
        child: Row(
          children: <Widget>[
            // O Aurora balançando: é o que a pessoa leva junto.
            // Espaço fixo que encolhe a prévia: em 320px com fonte grande o
            // preço precisa caber (teste da matriz de idiomas).
            SizedBox(
              width: 44,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Wobble(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PieceGlyph(
                          marker: PlayerMarker.cross, skin: aurora, size: 28),
                      PieceGlyph(
                          marker: PlayerMarker.nought, skin: aurora, size: 28),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l.starterTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(l.starterBody,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _PriceButton(
              buttonKey: const ValueKey<String>('store-buy-starter_pack'),
              price: price,
              busy: busy,
              enabled: enabled,
              onPressed: onBuy,
            ),
          ],
        ),
      ),
    );
  }
}

/// Coleção completa: todos os visuais e temas (de hoje e os próximos) + sem
/// anúncios. A prévia mostra os visuais em fila, cada um balançando.
class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.owned,
    required this.price,
    required this.busy,
    required this.enabled,
    required this.localization,
    required this.onBuy,
  });

  final bool owned;
  final String? price;
  final bool busy;
  final bool enabled;
  final AppLocalizations localization;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = localization;
    final Widget card = Container(
      key: const ValueKey<String>('store-collection-card'),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: <Color>[
          const Color(0xFFB36BFF).withOpacity(0.28),
          const Color(0xFF6BE0FF).withOpacity(0.16),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: owned ? VerseColors.coin : const Color(0xFFB36BFF),
            width: owned ? 2 : 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < pieceSkinCatalog.length; i++)
                  Bob(
                    phase: i / pieceSkinCatalog.length,
                    distance: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: PieceGlyph(
                          marker: i.isEven
                              ? PlayerMarker.cross
                              : PlayerMarker.nought,
                          skin: pieceSkinCatalog[i],
                          size: 30),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l.collectionTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(owned ? l.collectionOwned : l.collectionBody,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: VerseColors.mutedText)),
                  ],
                ),
              ),
              if (!owned && price != null) ...<Widget>[
                const SizedBox(width: 10),
                _PriceButton(
                  buttonKey: const ValueKey<String>('store-buy-collection'),
                  price: price!,
                  busy: busy,
                  enabled: enabled,
                  onPressed: onBuy,
                ),
              ],
            ],
          ),
        ],
      ),
    );
    return owned
        ? card
        : Shine(borderRadius: BorderRadius.circular(16), child: card);
  }
}
