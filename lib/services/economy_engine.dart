import '../models/piece_skin.dart';
import '../models/progress_state.dart';
import 'progression_engine.dart';

/// Resultado de tentar comprar ou equipar um visual.
enum SkinPurchaseResult { purchased, alreadyOwned, notEnoughCoins, unknownSkin }

/// Regras das moedas, do bônus diário e da loja de visuais.
///
/// Mesma filosofia do [ProgressionEngine]: função pura sobre [ProgressState]
/// com relógio injetável, então tudo é testável sem plugin e sem esperar a
/// virada do dia. Quem persiste é o `EconomyService`.
class EconomyEngine {
  const EconomyEngine();

  /// Recompensa do bônus diário pelo dia da sequência (1 a 7). Depois do 7º
  /// o ciclo recomeça no 1, mas a sequência não zera.
  static const List<int> dailyRewards = <int>[20, 25, 30, 40, 50, 60, 100];

  /// Moedas por anúncio premiado assistido na loja, e quantas vezes por dia.
  static const int adCoinsReward = 25;
  static const int adCoinsDailyCap = 5;

  /// Moedas que acompanham um ganho de XP. Atreladas ao XP de propósito: o
  /// carro-chefe e a dificuldade alta já rendem mais XP, então rendem mais
  /// moeda sem uma segunda tabela para manter em sincronia, e o anúncio de
  /// "dobrar" dobra as duas coisas juntas.
  static int coinsForXp(int xp) => xp <= 0 ? 0 : (xp / 3).ceil();

  /// Credita [amount] moedas (ignora valores não positivos).
  void earn(ProgressState state, int amount) {
    if (amount > 0) {
      state.coins += amount;
    }
  }

  /// Dia da sequência que o PRÓXIMO resgate teria (1 = sequência nova).
  int nextDailyStreak(ProgressState state, DateTime now) {
    final String? last = state.lastDailyClaimDay;
    if (last != null && last == ProgressionEngine.yesterdayKey(now)) {
      return state.dailyClaimStreak + 1;
    }
    if (last == ProgressionEngine.dayKey(now)) {
      return state.dailyClaimStreak;
    }
    return 1;
  }

  /// Valor do bônus para um dia de sequência.
  static int rewardForStreak(int streak) {
    final int index = (streak - 1) % dailyRewards.length;
    return dailyRewards[index < 0 ? 0 : index];
  }

  /// Também recusa quando o último resgate está no FUTURO: voltar a data do
  /// aparelho não pode liberar o bônus de novo. `yyyy-mm-dd` compara certo
  /// como texto.
  bool canClaimDaily(ProgressState state, DateTime now) {
    final String? last = state.lastDailyClaimDay;
    return last == null || last.compareTo(ProgressionEngine.dayKey(now)) < 0;
  }

  /// Resgata o bônus do dia. Devolve as moedas creditadas, ou 0 se o bônus de
  /// hoje já foi resgatado (dois toques rápidos não pagam duas vezes).
  int claimDaily(ProgressState state, DateTime now) {
    if (!canClaimDaily(state, now)) {
      return 0;
    }
    final int streak = nextDailyStreak(state, now);
    final int reward = rewardForStreak(streak);
    state.dailyClaimStreak = streak;
    state.lastDailyClaimDay = ProgressionEngine.dayKey(now);
    state.coins += reward;
    return reward;
  }

  /// Quantos resgates de moedas por anúncio ainda restam hoje.
  int adCoinsRemaining(ProgressState state, DateTime now) {
    final String today = ProgressionEngine.dayKey(now);
    final String? counted = state.adCoinsDay;
    // Contagem de um dia "futuro" = relógio voltado: o teto segue valendo.
    if (counted != null && counted.compareTo(today) > 0) {
      return 0;
    }
    if (counted != today) {
      return adCoinsDailyCap;
    }
    final int left = adCoinsDailyCap - state.adCoinsClaimsToday;
    return left < 0 ? 0 : left;
  }

  /// Credita as moedas de um anúncio premiado da loja, respeitando o teto
  /// diário. Só deve ser chamado depois de o SDK confirmar a recompensa.
  int grantAdCoins(ProgressState state, DateTime now) {
    if (adCoinsRemaining(state, now) <= 0) {
      return 0;
    }
    final String today = ProgressionEngine.dayKey(now);
    if (state.adCoinsDay != today) {
      state.adCoinsDay = today;
      state.adCoinsClaimsToday = 0;
    }
    state.adCoinsClaimsToday += 1;
    state.coins += adCoinsReward;
    return adCoinsReward;
  }

  /// Compra um visual. Só debita se o jogador tiver o saldo inteiro, e
  /// equipa na hora (quem compra quer ver).
  SkinPurchaseResult buySkin(ProgressState state, String skinId) {
    final PieceSkin? skin = _find(skinId);
    if (skin == null) {
      return SkinPurchaseResult.unknownSkin;
    }
    if (state.ownedSkins.contains(skin.id)) {
      return SkinPurchaseResult.alreadyOwned;
    }
    if (state.coins < skin.price) {
      return SkinPurchaseResult.notEnoughCoins;
    }
    state.coins -= skin.price;
    state.ownedSkins.add(skin.id);
    state.equippedSkin = skin.id;
    return SkinPurchaseResult.purchased;
  }

  /// Equipa um visual que o jogador já tem. Devolve `false` se não tiver.
  bool equipSkin(ProgressState state, String skinId) {
    if (!state.ownedSkins.contains(skinId) || _find(skinId) == null) {
      return false;
    }
    state.equippedSkin = skinId;
    return true;
  }

  static PieceSkin? _find(String id) {
    for (final PieceSkin skin in pieceSkinCatalog) {
      if (skin.id == id) {
        return skin;
      }
    }
    return null;
  }
}
