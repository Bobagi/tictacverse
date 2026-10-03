import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../controllers/rewarded_ad_controller.dart';
import '../../models/piece_skin.dart';
import '../../models/player_marker.dart';
import '../../services/audio_service.dart';
import '../../services/economy_engine.dart';
import '../../services/economy_service.dart';
import '../../services/haptics_service.dart';
import '../../services/progression_service.dart';
import 'coin_badge.dart';
import 'juice/press_scale.dart';
import 'modern_background.dart';
import 'piece_glyph.dart';

/// Abre a loja de visuais. [rewarded] nulo = sem anúncios (build sem ads):
/// a loja funciona igual, só sem o atalho de moedas por anúncio.
Future<void> showShopSheet(
  BuildContext context,
  AppLocalizations localization, {
  RewardedAdGateway? rewarded,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) =>
        ShopSheet(localization: localization, rewarded: rewarded),
  );
}

String skinName(AppLocalizations l, PieceSkin skin) => switch (skin.id) {
      'neon' => l.skinNeon,
      'fireIce' => l.skinFireIce,
      'candy' => l.skinCandy,
      'gold' => l.skinGold,
      'galaxy' => l.skinGalaxy,
      _ => l.skinAurora,
    };

class ShopSheet extends StatefulWidget {
  const ShopSheet({super.key, required this.localization, this.rewarded});

  final AppLocalizations localization;
  final RewardedAdGateway? rewarded;

  @override
  State<ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<ShopSheet> {
  final EconomyService _economy = EconomyService.instance;
  bool _watching = false;
  String? _message;

  /// O convite de anúncio só aparece com anúncio JÁ carregado (prometer e não
  /// ter o que mostrar é pior do que não oferecer). O gateway não avisa quando
  /// carrega, então a sheet confere enquanto está aberta.
  Timer? _readyPoll;
  bool _adReady = false;

  @override
  void initState() {
    super.initState();
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
    _readyPoll?.cancel();
    super.dispose();
  }

  void _onSkinTap(PieceSkin skin) {
    final AppLocalizations l = widget.localization;
    if (_economy.owns(skin)) {
      if (_economy.equip(skin)) {
        AudioService.instance.playUiClick();
        HapticsService.instance.play(HapticCue.tap);
      }
      setState(() => _message = null);
      return;
    }
    final SkinPurchaseResult result = _economy.buy(skin);
    setState(() {
      if (result == SkinPurchaseResult.purchased) {
        AudioService.instance.play(Sfx.achievement);
        HapticsService.instance.play(HapticCue.capture);
        _message = l.shopPurchased;
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
    return Padding(
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
                      const Icon(Icons.palette_rounded,
                          color: VerseColors.coin),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l.shopTitle,
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
                  Text(
                    l.shopSubtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: VerseColors.mutedText),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          LayoutBuilder(builder:
                              (BuildContext context, BoxConstraints c) {
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
                                      skin: skin,
                                      name: skinName(l, skin),
                                      owned: _economy.owns(skin),
                                      equipped:
                                          _economy.equippedSkin.id == skin.id,
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
                              child: Text(
                                _message!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: VerseColors.coin,
                                        fontWeight: FontWeight.w700),
                              ),
                            ),
                          if (widget.rewarded != null &&
                              (_adReady || _watching)) ...<Widget>[
                            // Respiro grande: o convite de anúncio não encosta
                            // em nenhum botão de compra.
                            const SizedBox(height: 22),
                            _buildAdCoins(context, l),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
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

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.name,
    required this.owned,
    required this.equipped,
    required this.coins,
    required this.localization,
    required this.onTap,
  });

  final PieceSkin skin;
  final String name;
  final bool owned;
  final bool equipped;
  final int coins;
  final AppLocalizations localization;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool affordable = coins >= skin.price;
    final Color border = equipped
        ? VerseColors.coin
        : Colors.white.withOpacity(owned ? 0.35 : 0.15);
    final Widget action;
    if (equipped) {
      action = _pill(context, localization.shopEquipped, VerseColors.coin,
          icon: Icons.check_rounded, filled: true);
    } else if (owned) {
      action = _pill(context, localization.shopEquip, Colors.white);
    } else if (affordable) {
      action = _pill(context, '${skin.price}', VerseColors.coin,
          icon: Icons.monetization_on_rounded);
    } else {
      action = _pill(
          context, localization.shopMissing(skin.price - coins), Colors.white54,
          icon: Icons.lock_rounded);
    }
    return Semantics(
      button: true,
      label:
          '$name. ${owned ? '' : '${skin.price} ${localization.coinsLabel}'}',
      child: PressScale(
        pressedScale: 0.96,
        enabled: owned || affordable,
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
                Opacity(
                  opacity: owned || affordable ? 1 : 0.8,
                  // Encolhe a prévia em vez de estourar o cartão em 320px.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        PieceGlyph(
                            marker: PlayerMarker.cross, skin: skin, size: 48),
                        const SizedBox(width: 6),
                        PieceGlyph(
                            marker: PlayerMarker.nought, skin: skin, size: 48),
                      ],
                    ),
                  ),
                ),
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
