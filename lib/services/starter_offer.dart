import 'progression_engine.dart';

/// Quando convidar para o pacote de boas-vindas (sem anúncios + moedas).
///
/// Oferta de primeira compra é o formato que mais converte em jogo casual,
/// mas insistir cansa: só a partir da 2ª sessão (a 1ª é para conhecer o
/// jogo), no máximo [maxShows] vezes na vida e com [minDaysBetween] dias
/// entre uma e outra. Quem já tirou os anúncios nunca vê.
class StarterOffer {
  const StarterOffer._();

  static const int minSession = 2;
  static const int maxShows = 3;
  static const int minDaysBetween = 2;

  static bool shouldShow({
    required int sessions,
    required int shows,
    required String? lastShownDay,
    required DateTime now,
    required bool adsRemoved,
    required bool productAvailable,
  }) {
    if (adsRemoved || !productAvailable) {
      return false;
    }
    if (sessions < minSession || shows >= maxShows) {
      return false;
    }
    if (lastShownDay == null) {
      return true;
    }
    final DateTime? last = DateTime.tryParse(lastShownDay);
    if (last == null) {
      return true;
    }
    final DateTime today = DateTime.parse(ProgressionEngine.dayKey(now));
    // Data no futuro = relógio voltado: não reabre a oferta por isso.
    return today.difference(last).inDays >= minDaysBetween;
  }
}
