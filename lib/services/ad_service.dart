/// Cadência dos anúncios no fim da partida.
///
/// É um singleton de propósito. Cada tela de jogo criava a própria instância,
/// então o contador de partidas voltava a zero toda vez que o jogador saía pro
/// menu e entrava de novo, e cada modo ainda contava separado do outro. O
/// intervalo quase nunca era alcançado: no AdMob isso aparece como 1.545
/// intersticiais carregados para 23% de exibição.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  /// Instância isolada para teste - o singleton guarda estado entre casos.
  static AdService forTest() => AdService._();

  /// Partidas entre um intersticial e o próximo.
  static const int interstitialInterval = 3;

  /// Partidas entre um convite de anúncio premiado e o próximo.
  ///
  /// A oferta é opt-in e não custa nada a quem ignora, mas repetir o convite em
  /// todo fim de partida cansa e vira ruído. Espaçar é ordem do dono.
  static const int rewardedOfferInterval = 4;

  int _matchesSinceInterstitial = 0;
  int _matchesSinceRewardedOffer = 0;

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
  ///
  /// Chame **uma vez por partida**, junto do intersticial: o `builder` do modal
  /// pode ser reconstruído, e contar lá dentro adiantaria o intervalo.
  bool shouldOfferRewardedOnMatchEnd() {
    _matchesSinceRewardedOffer += 1;
    if (_matchesSinceRewardedOffer < rewardedOfferInterval) {
      return false;
    }
    _matchesSinceRewardedOffer = 0;
    return true;
  }

  void resetTracking() {
    _matchesSinceInterstitial = 0;
    _matchesSinceRewardedOffer = 0;
  }
}
