import 'storage_service.dart';

/// Cadência dos anúncios no fim da partida.
///
/// É um singleton de propósito. Cada tela de jogo criava a própria instância,
/// então o contador de partidas voltava a zero toda vez que o jogador saía pro
/// menu e entrava de novo, e cada modo ainda contava separado do outro. O
/// intervalo quase nunca era alcançado: no AdMob isso aparece como 1.545
/// intersticiais carregados para 23% de exibição.
class AdService {
  AdService._({int Function()? loadCounter, void Function(int)? saveCounter})
      : _loadCounter = loadCounter,
        _saveCounter = saveCounter;

  /// A instância do app guarda a contagem do premiado no aparelho.
  static final AdService instance = AdService._(
    loadCounter: () => StorageService.instance.rewardedOfferCounter,
    saveCounter: (int v) => StorageService.instance.saveRewardedOfferCounter(v),
  );

  /// Instância isolada para teste - o singleton guarda estado entre casos.
  /// [loadCounter]/[saveCounter] simulam o que fica gravado no aparelho.
  static AdService forTest(
          {int Function()? loadCounter, void Function(int)? saveCounter}) =>
      AdService._(loadCounter: loadCounter, saveCounter: saveCounter);

  final int Function()? _loadCounter;
  final void Function(int)? _saveCounter;

  /// Partidas entre um intersticial e o próximo.
  static const int interstitialInterval = 3;

  /// Partidas entre um convite de anúncio premiado e o próximo.
  ///
  /// A oferta é opt-in e não custa nada a quem ignora, mas repetir o convite em
  /// todo fim de partida cansa e vira ruído. Espaçar é ordem do dono.
  static const int rewardedOfferInterval = 4;

  int _matchesSinceInterstitial = 0;
  int? _rewardedCounter;

  int get _matchesSinceRewardedOffer =>
      _rewardedCounter ??= _loadCounter?.call() ?? 0;
  set _matchesSinceRewardedOffer(int value) {
    _rewardedCounter = value;
    _saveCounter?.call(value);
  }

  bool shouldShowBannerOnGameScreen() => true;

  bool shouldShowInterstitialOnMatchEnd() {
    _matchesSinceInterstitial += 1;
    if (_matchesSinceInterstitial < interstitialInterval) {
      return false;
    }
    _matchesSinceInterstitial = 0;
    return true;
  }

  /// Conta a partida que acabou e diz se o convite de dobrar o XP pode aparecer
  /// neste fim.
  ///
  /// Só a cadência. As outras condições (anúncio carregado, XP ganho na
  /// partida, intersticial não exibido) continuam com quem monta o modal, e
  /// qualquer uma delas ainda pode derrubar a oferta depois deste `true`.
  /// Por isso a vez **não se gasta aqui**: só [markRewardedOffered], quando o
  /// convite vai mesmo para a tela. Antes a vez se perdia sempre que caía junto
  /// do intersticial ou com o anúncio ainda carregando, e o premiado ficou com
  /// 1.108 anúncios atendidos e zero exibidos na vida do app.
  ///
  /// Chame **uma vez por partida**, junto do intersticial: o `builder` do modal
  /// pode ser reconstruído, e contar lá dentro adiantaria o intervalo.
  bool shouldOfferRewardedOnMatchEnd() {
    final int next = _matchesSinceRewardedOffer + 1;
    // Teto: com a vez pendente, não precisa crescer sem limite no disco.
    _matchesSinceRewardedOffer =
        next > rewardedOfferInterval ? rewardedOfferInterval : next;
    return _matchesSinceRewardedOffer >= rewardedOfferInterval;
  }

  /// O convite apareceu: recomeça a contagem.
  void markRewardedOffered() {
    if (_matchesSinceRewardedOffer != 0) {
      _matchesSinceRewardedOffer = 0;
    }
  }

  void resetTracking() {
    _matchesSinceInterstitial = 0;
    _matchesSinceRewardedOffer = 0;
  }
}
