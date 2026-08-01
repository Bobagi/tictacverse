import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

import 'play_games_ids.dart';

/// Identidade do jogador vinda do Play Games.
///
/// É de propósito o mínimo: um id que só vale dentro deste jogo, o apelido
/// público e a foto. **Não** traz e-mail nem conta Google, então o app nunca
/// passa a guardar credencial de ninguém. É esta mesma identidade que o
/// multiplayer vai exibir, em vez de pedir um apelido digitado.
class PlayerIdentity {
  const PlayerIdentity({
    required this.id,
    required this.displayName,
    this.iconImageBase64,
  });

  final String id;
  final String displayName;
  final String? iconImageBase64;
}

/// Ponte com o Play Games Services (conquistas e placar).
///
/// Regra de ouro: **o estado local é a fonte da verdade e o Play Games é só um
/// espelho.** Nada aqui pode alterar a progressão nem lançar exceção para cima;
/// se o serviço não existir, o jogador recusar o login ou a rede cair, o jogo
/// segue idêntico. Por isso toda chamada está dentro de try/catch e o
/// [playGamesConfigured] desliga tudo enquanto os ids não forem preenchidos.
class GameServicesBridge {
  GameServicesBridge._();

  static final GameServicesBridge instance = GameServicesBridge._();

  /// Jogador autenticado, ou nulo. A UI escuta para mostrar o apelido/foto.
  final ValueNotifier<PlayerIdentity?> player =
      ValueNotifier<PlayerIdentity?>(null);

  StreamSubscription<PlayerData?>? _playerSubscription;
  bool _initialized = false;

  /// Mapa em uso. Fica como campo, e não lendo a constante direto, para o teste
  /// poder injetar ids falsos: com a constante vazia o `continue` do laço
  /// esconderia o guard de disponibilidade, e um teste que não consegue
  /// distinguir os dois não prova nada.
  @visibleForTesting
  Map<String, String> achievementIds = playGamesAchievementIds;

  @visibleForTesting
  String leaderboardId = playGamesLevelLeaderboardId;

  /// A plataforma tem Play Games ou Game Center. A web não tem nenhum dos dois,
  /// e o plugin nem carrega lá.
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  bool get isAvailable => isSupported && achievementIds.isNotEmpty;

  bool get isSignedIn => player.value != null;

  /// Login silencioso. No Play Games v2 não existe botão de login: o SDK
  /// autentica sozinho quando o jogo abre. Chamar isto é "fire and forget".
  Future<void> initialize() async {
    if (_initialized || !isAvailable) {
      return;
    }
    _initialized = true;
    try {
      _playerSubscription = GameAuth.player.listen(
        _handlePlayer,
        onError: (Object _) => player.value = null,
      );
      await GameAuth.signIn();
    } catch (_) {
      // Sem Play Games instalado, login recusado ou app ainda não configurado
      // no Console: o jogo continua igual, só sem espelho.
      player.value = null;
    }
  }

  void _handlePlayer(PlayerData? data) {
    final String? id = data?.playerID;
    if (data == null || id == null) {
      player.value = null;
      return;
    }
    player.value = PlayerIdentity(
      id: id,
      displayName: data.displayName,
      iconImageBase64: data.iconImage,
    );
  }

  /// Espelha as conquistas já desbloqueadas localmente.
  ///
  /// É idempotente do lado do Play Games (desbloquear o que já está
  /// desbloqueado não faz nada), então pode ser chamado no boot com a lista
  /// inteira: quem jogou offline sincroniza tudo assim que o login acontece.
  Future<void> mirrorUnlocked(Iterable<String> localIds) async {
    if (!isAvailable || !isSignedIn) {
      return;
    }
    for (final String localId in localIds) {
      final String? remoteId = achievementIds[localId];
      if (remoteId == null) {
        continue;
      }
      try {
        await Achievements.unlock(
          achievement: Achievement(androidID: remoteId, iOSID: remoteId),
        );
      } catch (_) {
        // Uma conquista que falha não pode impedir as outras de subirem.
      }
    }
  }

  /// Envia o nível atual para o placar.
  Future<void> submitLevel(int level) async {
    if (!isAvailable || !isSignedIn || leaderboardId.isEmpty) {
      return;
    }
    try {
      await Leaderboards.submitScore(
        score: Score(
          androidLeaderboardID: leaderboardId,
          iOSLeaderboardID: leaderboardId,
          value: level,
        ),
      );
    } catch (_) {
      // Placar é enfeite: falhar aqui não pode aparecer para o jogador.
    }
  }

  /// Abre a tela nativa de conquistas do Play Games.
  ///
  /// Devolve `false` quando não deu para abrir, para a UI decidir se mostra
  /// alguma mensagem em vez de simplesmente não reagir ao toque.
  Future<bool> showAchievementsUi() async {
    if (!isAvailable || !isSignedIn) {
      return false;
    }
    try {
      await Achievements.showAchievements();
      return true;
    } catch (_) {
      return false;
    }
  }

  @visibleForTesting
  void disposeForTest() {
    _playerSubscription?.cancel();
    _playerSubscription = null;
    _initialized = false;
    player.value = null;
    achievementIds = playGamesAchievementIds;
    leaderboardId = playGamesLevelLeaderboardId;
  }
}
