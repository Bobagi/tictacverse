import '../controllers/modes/ultimate2_engine.dart';
import 'game_result.dart';
import 'player_marker.dart';

/// Estado de uma partida online do Super Jogo da Velha, como o servidor
/// (tictacverse-api) devolve. O servidor é o juiz; o app só refaz as jogadas
/// no mesmo motor para desenhar o tabuleiro.
enum OnlineStatus { waiting, active, finished, expired }

/// Como a partida acabou, do ponto de vista de quem está com o aparelho.
enum OnlineOutcome { win, loss, draw }

/// Adversário sem nome: um bicho (índice num emoji) e um número. Nada digitado
/// por gente, então não há o que moderar.
class OnlineOpponent {
  const OnlineOpponent({required this.avatar, required this.tag});

  final int avatar;
  final int tag;
}

class OnlineMatch {
  OnlineMatch({
    required this.id,
    required this.code,
    required this.status,
    required this.you,
    required this.opponent,
    required this.moves,
    required this.version,
    required this.result,
    required this.endReason,
    required this.deadline,
    required this.rematchId,
    required this.rematchOf,
    required this.updatedAt,
  });

  /// Lê o JSON do servidor. Qualquer coisa fora do formato vira
  /// [FormatException]: melhor recusar que desenhar uma partida torta.
  factory OnlineMatch.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('partida');
    }
    T field<T>(String key) {
      final Object? v = json[key];
      if (v is! T) {
        throw FormatException('partida.$key');
      }
      return v;
    }

    final List<(int, int)> moves = <(int, int)>[];
    for (final Object? m in field<List<dynamic>>('moves')) {
      if (m is! List || m.length != 2 || m[0] is! int || m[1] is! int) {
        throw const FormatException('partida.moves');
      }
      moves.add((m[0] as int, m[1] as int));
    }
    final Object? opp = json['opponent'];
    final String status = field<String>('status');
    return OnlineMatch(
      id: field<String>('id'),
      code: field<String>('code'),
      status: OnlineStatus.values.firstWhere(
          (OnlineStatus s) => s.name == status,
          orElse: () => throw const FormatException('partida.status')),
      you: field<String>('you') == 'x'
          ? PlayerMarker.cross
          : PlayerMarker.nought,
      opponent: opp is Map<String, dynamic> &&
              opp['avatar'] is int &&
              opp['tag'] is int
          ? OnlineOpponent(avatar: opp['avatar'] as int, tag: opp['tag'] as int)
          : null,
      moves: moves,
      version: field<int>('version'),
      result: json['result'] as String?,
      endReason: json['endReason'] as String?,
      deadline: DateTime.fromMillisecondsSinceEpoch(field<int>('deadline')),
      rematchId: json['rematchId'] as String?,
      rematchOf: json['rematchOf'] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(field<int>('updatedAt')),
    );
  }

  final String id;
  final String code;
  final OnlineStatus status;

  /// Peça de quem está com o aparelho. X sempre começa.
  final PlayerMarker you;
  final OnlineOpponent? opponent;
  final List<(int, int)> moves;
  final int version;

  /// 'x', 'o' ou 'draw' quando acabou.
  final String? result;

  /// line, draw, resign, timeout, abandon, expired, cancelled.
  final String? endReason;
  final DateTime deadline;
  final String? rematchId;
  final String? rematchOf;
  final DateTime updatedAt;

  /// Refaz as jogadas no motor do app (o mesmo que o servidor copia).
  Ultimate2State toState() {
    final Ultimate2Engine engine = Ultimate2Engine();
    Ultimate2State state = engine.start();
    for (final (int, int) move in moves) {
      state = engine.handleMove(state, move.$1, move.$2);
    }
    return state;
  }

  PlayerMarker get turn =>
      moves.length.isEven ? PlayerMarker.cross : PlayerMarker.nought;

  bool get isMyTurn => status == OnlineStatus.active && turn == you;

  bool get isOpen =>
      status == OnlineStatus.waiting || status == OnlineStatus.active;

  OnlineOutcome? get outcome {
    if (status != OnlineStatus.finished || result == null) {
      return null;
    }
    if (result == 'draw') {
      return OnlineOutcome.draw;
    }
    final PlayerMarker winner =
        result == 'x' ? PlayerMarker.cross : PlayerMarker.nought;
    return winner == you ? OnlineOutcome.win : OnlineOutcome.loss;
  }

  /// O resultado no formato do resto do jogo (modal de fim, linha neon).
  GameResult get gameResult {
    final Ultimate2State state = toState();
    if (state.result.isFinal) {
      return state.result;
    }
    // Acabou fora do tabuleiro (desistência, prazo): sem linha para riscar.
    if (result == 'draw') {
      return GameResult(resolution: GameResolution.draw);
    }
    if (result == 'x' || result == 'o') {
      return GameResult(
        resolution: GameResolution.victory,
        winner: result == 'x' ? PlayerMarker.cross : PlayerMarker.nought,
      );
    }
    return state.result;
  }
}

/// Estatísticas do jogador no online, guardadas no servidor.
class OnlineProfile {
  const OnlineProfile({
    required this.avatar,
    required this.tag,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  factory OnlineProfile.fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['avatar'] is! int ||
        json['tag'] is! int) {
      throw const FormatException('jogador');
    }
    int n(String k) => json[k] is int ? json[k] as int : 0;
    return OnlineProfile(
      avatar: json['avatar'] as int,
      tag: json['tag'] as int,
      wins: n('wins'),
      losses: n('losses'),
      draws: n('draws'),
    );
  }

  final int avatar;
  final int tag;
  final int wins;
  final int losses;
  final int draws;

  int get played => wins + losses + draws;
}
