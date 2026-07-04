import 'package:in_app_review/in_app_review.dart';

import 'storage_service.dart';

/// Pede a avaliação nativa da Play no momento certo: depois de uma vitória
/// contra a CPU, com pelo menos 5 partidas jogadas e a partir da 2ª sessão.
/// Pergunta uma única vez (flag persistida) — a Play ainda aplica cota própria.
class ReviewService {
  ReviewService._();

  static final ReviewService instance = ReviewService._();

  static const int _minMatches = 5;
  static const int _minSessions = 2;

  Future<void> maybeRequestReview() async {
    final StorageService storage = StorageService.instance;
    if (!storage.isLoaded ||
        storage.reviewAsked ||
        storage.totalMatches < _minMatches ||
        storage.sessions < _minSessions) {
      return;
    }
    try {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await storage.markReviewAsked();
        await inAppReview.requestReview();
      }
    } catch (_) {
      // Sem loja disponível (ex.: build de desenvolvimento) — ignora.
    }
  }
}
