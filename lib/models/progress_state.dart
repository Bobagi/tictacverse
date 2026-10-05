import 'dart:math' as math;

import 'board_theme.dart';
import 'entitlements.dart';
import 'game_mode.dart';

/// Estado persistido da progressão (XP, contadores e conquistas desbloqueadas).
///
/// Fica separado do [StorageService] de propósito: o motor de progressão opera
/// sobre este objeto sem tocar em `shared_preferences`, então dá para testar a
/// regra inteira sem plugin nem widget.
class ProgressState {
  ProgressState({
    this.xp = 0,
    this.matches = 0,
    this.cpuWins = 0,
    this.ultimateWins = 0,
    this.hardWins = 0,
    this.currentWinStreak = 0,
    this.bestWinStreak = 0,
    this.dailyStreak = 0,
    this.bestDailyStreak = 0,
    this.hasFastWin = false,
    this.lastPlayedDay,
    this.coins = 0,
    this.equippedSkin = defaultSkinId,
    this.lastDailyClaimDay,
    this.dailyClaimStreak = 0,
    this.adCoinsDay,
    this.adCoinsClaimsToday = 0,
    this.lastChallengeDay,
    this.challengeStreak = 0,
    this.bestChallengeStreak = 0,
    this.equippedTheme = defaultBoardThemeId,
    Set<GameModeType>? modesPlayed,
    Set<String>? unlockedAchievements,
    Set<String>? ownedSkins,
    Set<String>? ownedThemes,
    Set<String>? playOwned,
  })  : modesPlayed = modesPlayed ?? <GameModeType>{},
        unlockedAchievements = unlockedAchievements ?? <String>{},
        ownedSkins = ownedSkins ?? <String>{defaultSkinId},
        ownedThemes = ownedThemes ?? <String>{defaultBoardThemeId},
        playOwned = playOwned ?? <String>{};

  /// Visual de peças que todo jogador tem desde o início (Neon desde a
  /// v1.13.0; até a v1.12.0 era o Aurora).
  static const String defaultSkinId = 'neon';

  /// Versão do catálogo de visuais gravada junto do estado. Abaixo dela, o
  /// [fromJson] aplica a migração da troca de visual inicial.
  ///
  /// 2 = Neon vira o inicial (v1.13.0, interno); 3 = Aurora vira o visual
  /// mais caro e sai de uso de todo mundo.
  static const int catalogVersion = 3;

  /// O que o Neon custava antes de virar o visual inicial. Quem comprou recebe
  /// de volta: pagar por algo que agora é grátis seria injusto.
  static const int legacyNeonPrice = 120;

  /// XP acumulado. Só cresce; o nível é derivado dele.
  int xp;

  /// Partidas concluídas em qualquer modo, contra a máquina ou contra amigo.
  int matches;

  /// Vitórias do humano **contra a máquina** (ver nota no catálogo).
  int cpuWins;

  /// Vitórias contra a máquina no Super Jogo da Velha.
  int ultimateWins;

  /// Vitórias contra a máquina com a dificuldade no Impossível.
  int hardWins;

  int currentWinStreak;
  int bestWinStreak;

  /// Dias consecutivos com pelo menos uma partida.
  int dailyStreak;
  int bestDailyStreak;

  /// Venceu o Clássico com o mínimo de jogadas possível (3).
  bool hasFastWin;

  /// Último dia jogado, no formato `yyyy-mm-dd` em horário local.
  String? lastPlayedDay;

  final Set<GameModeType> modesPlayed;
  final Set<String> unlockedAchievements;

  /// Moedas: ganhas jogando, no bônus diário, no desafio do dia e em anúncio
  /// premiado opt-in; gastas só na loja. Não se compram (ver StoreProduct).
  int coins;

  /// Visuais de peça comprados (o padrão sempre incluso) e o que está em uso.
  final Set<String> ownedSkins;
  String equippedSkin;

  /// Último dia (`yyyy-mm-dd`, local) em que o bônus diário foi resgatado e
  /// quantos dias seguidos o jogador resgatou até ele.
  String? lastDailyClaimDay;
  int dailyClaimStreak;

  /// Teto diário das moedas por anúncio premiado na loja: dia da contagem e
  /// quantos resgates já foram feitos nele.
  String? adCoinsDay;
  int adCoinsClaimsToday;

  /// Produtos que a Play confirmou, na última consulta, que o jogador
  /// POSSUI. Fonte da verdade do que foi pago: compra reembolsada some da
  /// lista da Play e daqui na consulta seguinte. Guardado só para o jogo
  /// funcionar offline com o último estado conhecido.
  final Set<String> playOwned;

  /// O que as compras liberam (calculado, nunca gravado).
  Entitlements get entitlements => Entitlements.fromOwned(playOwned);

  bool get adsRemoved => entitlements.adsRemoved;

  /// Visual/tema disponível: comprado com moedas OU liberado por compra.
  bool hasSkin(String id) =>
      ownedSkins.contains(id) || entitlements.skins.contains(id);
  bool hasTheme(String id) =>
      ownedThemes.contains(id) || entitlements.themes.contains(id);

  /// Temas de tabuleiro comprados (o inicial sempre incluso) e o em uso.
  final Set<String> ownedThemes;
  String equippedTheme;

  /// Desafio diário: último dia concluído e dias seguidos concluídos.
  String? lastChallengeDay;
  int challengeStreak;
  int bestChallengeStreak;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'xp': xp,
        'matches': matches,
        'cpuWins': cpuWins,
        'ultimateWins': ultimateWins,
        'hardWins': hardWins,
        'currentWinStreak': currentWinStreak,
        'bestWinStreak': bestWinStreak,
        'dailyStreak': dailyStreak,
        'bestDailyStreak': bestDailyStreak,
        'hasFastWin': hasFastWin,
        'lastPlayedDay': lastPlayedDay,
        'modesPlayed': modesPlayed.map((GameModeType m) => m.name).toList(),
        'unlocked': unlockedAchievements.toList(),
        'coins': coins,
        'ownedSkins': ownedSkins.toList(),
        'equippedSkin': equippedSkin,
        'lastDailyClaimDay': lastDailyClaimDay,
        'dailyClaimStreak': dailyClaimStreak,
        'adCoinsDay': adCoinsDay,
        'adCoinsClaimsToday': adCoinsClaimsToday,
        'playOwned': playOwned.toList(),
        'lastChallengeDay': lastChallengeDay,
        'challengeStreak': challengeStreak,
        'bestChallengeStreak': bestChallengeStreak,
        'ownedThemes': ownedThemes.toList(),
        'equippedTheme': equippedTheme,
        'catalogVersion': catalogVersion,
      };

  /// Leitura tolerante a campo com tipo errado.
  ///
  /// Cada campo cai no padrão por conta própria em vez de lançar: um `cast`
  /// estourando aqui seria engolido pelo `try` do [StorageService] e apagaria a
  /// progressão INTEIRA por causa de um único valor estranho.
  static ProgressState fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ProgressState();
    }
    final Set<GameModeType> modes = <GameModeType>{};
    for (final Object? raw in _asList(json['modesPlayed'])) {
      for (final GameModeType mode in GameModeType.values) {
        if (mode.name == raw) {
          modes.add(mode);
        }
      }
    }
    final Set<String> owned = <String>{
      for (final Object? raw in _asList(json['ownedSkins']))
        if (raw is String) raw,
    };
    int coins = math.max(0, _asInt(json['coins']));
    String equipped = json['equippedSkin'] is String
        ? json['equippedSkin'] as String
        : 'aurora';
    final int savedCatalog = _asInt(json['catalogVersion']);
    if (savedCatalog < 2) {
      // Estado gravado quando o Aurora era o visual inicial: quem já jogava
      // continua dono dele, e quem tinha comprado o Neon (agora grátis)
      // recebe as moedas de volta.
      if (owned.contains('neon')) {
        coins += legacyNeonPrice;
      }
      owned.add('aurora');
    }
    if (savedCatalog < catalogVersion && equipped == 'aurora') {
      // Ordem do dono (2026-10-04): o Neon é a cara do jogo, então todo
      // mundo que estava com o Aurora em uso passa para o Neon. O Aurora
      // segue na coleção de quem já tinha, a um toque de voltar.
      equipped = defaultSkinId;
    }
    if (json['equippedSkin'] is! String) {
      equipped = defaultSkinId;
    }
    owned.add(defaultSkinId);
    return ProgressState(
      xp: _asInt(json['xp']),
      matches: _asInt(json['matches']),
      cpuWins: _asInt(json['cpuWins']),
      ultimateWins: _asInt(json['ultimateWins']),
      hardWins: _asInt(json['hardWins']),
      currentWinStreak: _asInt(json['currentWinStreak']),
      bestWinStreak: _asInt(json['bestWinStreak']),
      dailyStreak: _asInt(json['dailyStreak']),
      bestDailyStreak: _asInt(json['bestDailyStreak']),
      hasFastWin: json['hasFastWin'] is bool && json['hasFastWin'] as bool,
      lastPlayedDay: json['lastPlayedDay'] is String
          ? json['lastPlayedDay'] as String
          : null,
      modesPlayed: modes,
      unlockedAchievements: <String>{
        for (final Object? raw in _asList(json['unlocked']))
          if (raw is String) raw,
      },
      coins: coins,
      ownedSkins: owned,
      equippedSkin: equipped,
      lastDailyClaimDay: _asString(json['lastDailyClaimDay']),
      dailyClaimStreak: _asInt(json['dailyClaimStreak']),
      adCoinsDay: _asString(json['adCoinsDay']),
      adCoinsClaimsToday: _asInt(json['adCoinsClaimsToday']),
      playOwned: <String>{
        for (final Object? raw in _asList(json['playOwned']))
          if (raw is String) raw,
      },
      lastChallengeDay: _asString(json['lastChallengeDay']),
      challengeStreak: _asInt(json['challengeStreak']),
      bestChallengeStreak: _asInt(json['bestChallengeStreak']),
      ownedThemes: <String>{
        defaultBoardThemeId,
        for (final Object? raw in _asList(json['ownedThemes']))
          if (raw is String) raw,
      },
      equippedTheme: _asString(json['equippedTheme']) ?? defaultBoardThemeId,
    );
  }

  static int _asInt(Object? value) => value is num ? value.toInt() : 0;

  static String? _asString(Object? value) => value is String ? value : null;

  static List<Object?> _asList(Object? value) =>
      value is List<Object?> ? value : const <Object?>[];
}
