import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import 'juice/motion.dart';
import 'juice/particles.dart';
import 'juice/press_scale.dart';
import 'juice/pulse.dart';
import 'modern_background.dart';
import 'pop_in.dart';

/// Abre o convite do pacote de boas-vindas. Devolve `true` se o jogador quis
/// ver a oferta (a home leva para a aba Moedas; a compra continua lá, com
/// toque de confirmação da Play, nunca direto daqui).
Future<bool?> showStarterOfferDialog(
  BuildContext context, {
  required AppLocalizations localization,
  required int coins,
  String? price,
  int? savingPercent,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: localization.notNow,
    barrierColor: Colors.black.withOpacity(0.72),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (BuildContext context, _, __) => StarterOfferDialog(
      localization: localization,
      coins: coins,
      price: price,
      savingPercent: savingPercent,
    ),
  );
}

/// A oferta é o momento de maior valor percebido do jogo, então ela entra
/// como "baú aberto": raios girando, presente balançando, moedas flutuando,
/// faíscas e o selo de desconto pulsando. Tudo some com "reduzir animações".
class StarterOfferDialog extends StatefulWidget {
  const StarterOfferDialog({
    super.key,
    required this.localization,
    required this.coins,
    this.price,
    this.savingPercent,
  });

  final AppLocalizations localization;
  final int coins;
  final String? price;
  final int? savingPercent;

  @override
  State<StarterOfferDialog> createState() => _StarterOfferDialogState();
}

class _StarterOfferDialogState extends State<StarterOfferDialog> {
  final ParticleController _particles = ParticleController();
  final GlobalKey _giftKey = GlobalKey();
  Timer? _sparkles;

  @override
  void initState() {
    super.initState();
    AudioService.instance.play(Sfx.levelUp);
    HapticsService.instance.play(HapticCue.capture);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || MediaQuery.of(context).disableAnimations) {
        return;
      }
      _burstAtGift(count: 34);
      // Faíscas de tempos em tempos enquanto a oferta está aberta.
      _sparkles = Timer.periodic(const Duration(milliseconds: 900), (_) {
        if (mounted) {
          _sparkleAtGift();
        }
      });
    });
  }

  Rect? _giftRect() {
    final RenderObject? box = _giftKey.currentContext?.findRenderObject();
    final RenderObject? field = context.findRenderObject();
    if (box is! RenderBox || field is! RenderBox || !box.hasSize) {
      return null;
    }
    final Offset topLeft = box.localToGlobal(Offset.zero, ancestor: field);
    return topLeft & box.size;
  }

  void _burstAtGift({int count = 20}) {
    final Rect? r = _giftRect();
    if (r != null) {
      _particles.burst(
        center: r.center,
        color: VerseColors.coin,
        accent: const Color(0xFFFF6BD9),
        count: count,
        speed: 1.4,
        size: 5,
      );
    }
  }

  void _sparkleAtGift() {
    final Rect? r = _giftRect();
    if (r != null) {
      _particles.sparkle(area: r.inflate(30), color: VerseColors.coin);
    }
  }

  @override
  void dispose() {
    _sparkles?.cancel();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = widget.localization;
    final TextTheme text = Theme.of(context).textTheme;
    return Stack(
      children: <Widget>[
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: PopIn(
              beginScale: 0.55,
              duration: const Duration(milliseconds: 520),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    key: const ValueKey<String>('starter-offer-dialog'),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFF3B1475), Color(0xFF1D0E3A)],
                      ),
                      border: Border.all(color: VerseColors.coin, width: 2),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: VerseColors.coin.withOpacity(0.35),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _buildHero(),
                          const SizedBox(height: 6),
                          Shine(
                            borderRadius: BorderRadius.circular(8),
                            child: Text(
                              l.starterTitle,
                              textAlign: TextAlign.center,
                              style: text.headlineSmall?.copyWith(
                                fontFamily: 'Fredoka',
                                fontWeight: FontWeight.w700,
                                color: VerseColors.coin,
                                shadows: <Shadow>[
                                  Shadow(
                                      color: VerseColors.coin.withOpacity(0.6),
                                      blurRadius: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.starterBody(widget.coins),
                            textAlign: TextAlign.center,
                            style: text.bodyLarge?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          _buildCta(l, text),
                          const SizedBox(height: 4),
                          TextButton(
                            key: const ValueKey<String>('starter-offer-later'),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(l.notNow,
                                style: const TextStyle(
                                    color: VerseColors.mutedText)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(child: ParticleField(controller: _particles)),
        ),
      ],
    );
  }

  /// Presente balançando no meio de raios girando, com moedas flutuando em
  /// volta e o selo de desconto pulsando no canto.
  Widget _buildHero() {
    const double size = 170;
    return SizedBox(
      height: size,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          const Sunburst(size: size),
          Wobble(
            key: _giftKey,
            child: const Icon(Icons.card_giftcard_rounded,
                size: 84, color: VerseColors.coin),
          ),
          for (final (Alignment a, double phase) in <(Alignment, double)>[
            (const Alignment(-0.62, -0.55), 0.0),
            (const Alignment(0.66, -0.35), 0.33),
            (const Alignment(-0.5, 0.62), 0.66),
          ])
            Align(
              alignment: a,
              child: Bob(
                phase: phase,
                child: const Icon(Icons.monetization_on_rounded,
                    size: 26, color: VerseColors.coin),
              ),
            ),
          if (widget.savingPercent != null)
            Align(
              alignment: const Alignment(0.95, 0.8),
              child: Transform.rotate(
                angle: -0.2,
                child: Pulse(
                  maxScale: 1.12,
                  child: Container(
                    key: const ValueKey<String>('starter-offer-save'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: VerseColors.danger,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                            color: VerseColors.danger.withOpacity(0.6),
                            blurRadius: 12),
                      ],
                    ),
                    child: Text(
                      '-${widget.savingPercent}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCta(AppLocalizations l, TextTheme text) {
    final String label =
        widget.price == null ? l.starterSee : '${l.starterSee} · ${widget.price}';
    return Pulse(
      maxScale: 1.04,
      period: const Duration(milliseconds: 1100),
      child: PressScale(
        child: Shine(
          borderRadius: BorderRadius.circular(16),
          period: const Duration(milliseconds: 2200),
          opacity: 0.55,
          child: SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: <Color>[
                  Color(0xFFFFE27A),
                  Color(0xFFFFB938),
                ]),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                      color: VerseColors.energy.withOpacity(0.55),
                      blurRadius: 18,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: TextButton(
                key: const ValueKey<String>('starter-offer-see'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2A1250),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  _burstAtGift(count: 24);
                  Navigator.of(context).pop(true);
                },
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2A1250))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
