import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../controllers/rewarded_ad_controller.dart';
import '../../services/audio_service.dart';
import '../../services/economy_engine.dart';
import '../../services/economy_service.dart';
import '../../services/haptics_service.dart';
import 'juice/particles.dart';
import 'modern_background.dart';
import 'juice/motion.dart';

Future<void> showDailyBonusSheet(
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
        DailyBonusSheet(localization: localization, rewarded: rewarded),
  );
}

/// Bônus diário: 7 dias em sequência com valor crescente. Depois de resgatar,
/// convite opt-in para dobrar com anúncio premiado (uma vez por resgate).
class DailyBonusSheet extends StatefulWidget {
  const DailyBonusSheet({super.key, required this.localization, this.rewarded});

  final AppLocalizations localization;
  final RewardedAdGateway? rewarded;

  @override
  State<DailyBonusSheet> createState() => _DailyBonusSheetState();
}

class _DailyBonusSheetState extends State<DailyBonusSheet> {
  final EconomyService _economy = EconomyService.instance;
  final ParticleController _particles = ParticleController();

  /// O valor resgatado agora (0 = ainda não resgatou nesta abertura).
  int _claimed = 0;
  bool _doubled = false;
  bool _watching = false;
  bool _adFailed = false;

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
    _particles.dispose();
    super.dispose();
  }

  void _claim() {
    if (_claimed > 0) {
      return;
    }
    final int got = _economy.claimDaily();
    if (got <= 0) {
      return;
    }
    AudioService.instance.play(Sfx.levelUp);
    HapticsService.instance.play(HapticCue.levelUp);
    final Size size = _particles.viewport;
    _particles.confetti(colors: const <Color>[
      VerseColors.coin,
      VerseColors.cross,
      VerseColors.nought,
      Color(0xFF3EF0C4),
    ]);
    _particles.sparkle(
      area: Rect.fromLTWH(size.width * 0.2, size.height * 0.3, size.width * 0.6,
          size.height * 0.3),
      color: VerseColors.coin,
      count: 30,
    );
    setState(() => _claimed = got);
  }

  Future<void> _double() async {
    final RewardedAdGateway? rewarded = widget.rewarded;
    if (rewarded == null || _claimed <= 0 || _doubled || _watching) {
      return;
    }
    AudioService.instance.playUiClick();
    // Trava ANTES do await: toque duplo não abre dois anúncios nem paga duas vezes.
    setState(() {
      _watching = true;
      _adFailed = false;
    });
    final bool earned = await rewarded.showForReward();
    if (earned) {
      _economy.grantDailyDouble(_claimed);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _watching = false;
      if (earned) {
        _doubled = true;
        AudioService.instance.play(Sfx.achievement);
      } else {
        _adFailed = true;
        rewarded.loadRewardedAd();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = widget.localization;
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final bool canClaim = _economy.canClaimDaily && _claimed == 0;
    // Dia destacado: o que vai ser resgatado, ou o que acabou de ser.
    final int today = _economy.nextDailyStreak;
    final int cycleDay = (today - 1) % EconomyEngine.dailyRewards.length + 1;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Stack(
        children: <Widget>[
          GlassPanel(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Breathe(
                        child: Icon(Icons.card_giftcard_rounded,
                            color: VerseColors.coin),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l.dailyTitle,
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: l.closeLabel,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Text(
                    l.dailyHint,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: VerseColors.mutedText),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (int d = 1;
                          d <= EconomyEngine.dailyRewards.length;
                          d++)
                        _DayTile(
                          label: l.dailyDay(d),
                          amount: EconomyEngine.rewardForStreak(d),
                          done: d < cycleDay || (d == cycleDay && !canClaim),
                          current: d == cycleDay,
                          jackpot: d == EconomyEngine.dailyRewards.length,
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (canClaim)
                    FilledButton.icon(
                      key: const ValueKey<String>('daily-claim'),
                      onPressed: _claim,
                      icon: const Icon(Icons.monetization_on_rounded),
                      label:
                          Text('${l.dailyClaim} +${_economy.nextDailyReward}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: VerseColors.coin,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(52),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                    )
                  else ...<Widget>[
                    Text(
                      _claimed > 0
                          ? l.coinsGained(_doubled ? _claimed * 2 : _claimed)
                          : l.dailyComeBack,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: VerseColors.coin, fontWeight: FontWeight.w800),
                    ),
                    if (_claimed > 0 &&
                        !_doubled &&
                        widget.rewarded != null &&
                        (_adReady || _watching || _adFailed)) ...<Widget>[
                      // Respiro: o convite de anúncio fica longe do resgate.
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        key: const ValueKey<String>('daily-double'),
                        onPressed: _watching ? null : _double,
                        icon: _watching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.ondemand_video_rounded),
                        label: Text(l.dailyDoubleCta),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VerseColors.coin,
                          side: BorderSide(
                              color: VerseColors.coin.withOpacity(0.6)),
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                      if (_adFailed)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            l.adUnavailable,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: VerseColors.mutedText),
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(child: ParticleField(controller: _particles)),
          ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.label,
    required this.amount,
    required this.done,
    required this.current,
    this.jackpot = false,
  });

  /// O último dia do ciclo, o que paga mais: ganha o presente no lugar da moeda.
  final bool jackpot;
  final String label;
  final int amount;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final Color tint = current ? VerseColors.coin : Colors.white;
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: current
            ? VerseColors.coin.withOpacity(0.14)
            : Colors.white.withOpacity(done ? 0.08 : 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: tint.withOpacity(current ? 0.9 : 0.2),
            width: current ? 2 : 1),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Icon(
            done
                ? Icons.check_circle_rounded
                : (jackpot
                    ? Icons.card_giftcard_rounded
                    : Icons.monetization_on_rounded),
            color: done ? const Color(0xFF3EF0C4) : VerseColors.coin,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            '$amount',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
