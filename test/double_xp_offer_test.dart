import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/controllers/rewarded_ad_controller.dart';
import 'package:tictacverse/models/achievement.dart';
import 'package:tictacverse/models/progress_state.dart';
import 'package:tictacverse/services/ad_service.dart';
import 'package:tictacverse/services/double_xp_offer.dart';
import 'package:tictacverse/services/progression_engine.dart';
import 'package:tictacverse/services/storage_service.dart';

/// Dublê do anúncio premiado: diz se está carregado e o que "assistir" devolve.
class FakeRewarded implements RewardedAdGateway {
  FakeRewarded({this.ready = true, this.earns = true});

  bool ready;
  bool earns;
  int loads = 0;
  int shows = 0;

  @override
  bool get isReady => ready;

  @override
  void loadRewardedAd() => loads++;

  @override
  Future<bool> showForReward() async {
    shows++;
    return earns;
  }
}

ProgressionResult earned(int xp) => ProgressionResult(
      xpGained: xp,
      levelBefore: 1,
      levelAfter: 1,
      newlyUnlocked: const <AchievementDefinition>[],
    );

/// Leva a cadência do AdService até a partida em que o convite cai (4ª).
void advanceToDue(AdService ads, {int matchesBefore = 3}) {
  for (int i = 0; i < matchesBefore; i++) {
    ads.shouldOfferRewardedOnMatchEnd();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdService ads;
  late FakeRewarded rewarded;

  DoubleXpOffer offer({bool adsEnabled = true}) => DoubleXpOffer(
        rewardedAdController: rewarded,
        adService: ads,
        adsEnabled: adsEnabled,
      );

  setUp(() {
    ads = AdService.forTest();
    rewarded = FakeRewarded();
    StorageService.instance.progress = ProgressState();
  });

  group('quando o convite aparece', () {
    test('partida na cadência, anúncio pronto e XP ganho: convida', () {
      final DoubleXpOffer o = offer();
      advanceToDue(ads);
      o.onMatchEnded(earned(35));
      o.onCelebrationDone(interstitialShown: false);
      expect(o.build(), isNotNull);
    });

    test('fora da cadência não convida', () {
      final DoubleXpOffer o = offer();
      o.onMatchEnded(earned(35));
      o.onCelebrationDone(interstitialShown: false); // 1ª partida
      expect(o.build(), isNull);
    });

    test('depois de um intersticial exibido NUNCA convida (sem encadear anúncio)', () {
      final DoubleXpOffer o = offer();
      advanceToDue(ads);
      o.onMatchEnded(earned(35));
      o.onCelebrationDone(interstitialShown: true);
      expect(o.build(), isNull);
    });

    test('sem anúncio carregado não promete o que não tem', () {
      rewarded.ready = false;
      final DoubleXpOffer o = offer();
      advanceToDue(ads);
      o.onMatchEnded(earned(35));
      o.onCelebrationDone(interstitialShown: false);
      expect(o.build(), isNull);
    });

    test('partida sem XP não recebe convite', () {
      final DoubleXpOffer o = offer();
      advanceToDue(ads);
      o.onMatchEnded(earned(0));
      o.onCelebrationDone(interstitialShown: false);
      expect(o.build(), isNull);
    });

    test('anúncios desligados: nunca', () {
      final DoubleXpOffer o = offer(adsEnabled: false);
      advanceToDue(ads);
      o.onMatchEnded(earned(35));
      o.onCelebrationDone(interstitialShown: false);
      expect(o.build(), isNull);
    });

    test('o fim de partida pré-carrega o próximo anúncio', () {
      final DoubleXpOffer o = offer();
      o.onMatchEnded(earned(35));
      expect(rewarded.loads, 1);
    });
  });

  group('crédito', () {
    test('assistiu até o fim: credita exatamente o XP da partida (dobra)', () async {
      final DoubleXpOffer o = offer();
      StorageService.instance.progress.xp = 100;
      advanceToDue(ads);
      o.onMatchEnded(earned(35));
      o.onCelebrationDone(interstitialShown: false);
      final ProgressionResult? bonus = await o.build()!();
      expect(bonus, isNotNull);
      expect(bonus!.xpGained, 35);
      expect(StorageService.instance.progress.xp, 135);
      expect(rewarded.shows, 1);
    });

    test('fechou antes do fim: NADA é creditado', () async {
      rewarded.earns = false;
      final DoubleXpOffer o = offer();
      StorageService.instance.progress.xp = 100;
      advanceToDue(ads);
      o.onMatchEnded(earned(35));
      o.onCelebrationDone(interstitialShown: false);
      final ProgressionResult? bonus = await o.build()!();
      expect(bonus, isNull);
      expect(StorageService.instance.progress.xp, 100,
          reason: 'crédito no escuro é exatamente o que a política proíbe');
    });
  });
}
