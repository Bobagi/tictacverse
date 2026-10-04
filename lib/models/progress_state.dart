import 'dart:math' as math;

import 'board_theme.dart';
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
    this.adsRemoved = false,
    this.lastChallengeDay,
    this.challengeStreak = 0,
    this.bestChallengeStreak = 0,
    this.equippedTheme = defaultBoardThemeId,
    Set<GameModeType>? modesPlayed,
    Set<String>? unlockedAchievements,
    Set<String>? ownedSkins,
    List<String>? processedPurchases,
    List<String>? appliedRevocations,
    Set<String>? ownedThemes,
    Map<String, int>? coinPurchases,
    Set<String>? permanentPurchases,
  })  : modesPlayed = modesPlayed ?? <GameModeType>{},
        unlockedAchievements = unlockedAchievements ?? <String>{},
        ownedSkins = ownedSkins ?? <String>{defaultSkinId},
        processedPurchases = processedPurchases ?? <String>[],
        appliedRevocations = appliedRevocations ?? <String>[],
        ownedThemes = ownedThemes ?? <String>{defaultBoardThemeId},
        coinPurchases = coinPurchases ?? <String, int>{},
        permanentPurchases = permanentPurchases ?? <String>{};

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

  /// Quantos tokens de compra lembrar para não creditar a mesma compra duas
  /// vezes. A Play reentrega só compras não consumidas, então os últimos
  /// bastam com folga.
  static const int processedPurchasesCap = 100;

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

  /// Moedas: ganhas jogando, no bônus diário, em anúncio premiado opt-in ou
  /// compradas na loja da Play; gastas só na loja. Só ficam negativas como
  /// dívida de uma compra estornada.
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

  /// Comprou "sem anúncios": some banner, retângulo e intersticial. O
  /// premiado continua, porque é opt-in e paga moedas.
  bool adsRemoved;

  /// Tokens das compras da Play já creditadas, do mais antigo ao mais novo.
  final List<String> processedPurchases;

  /// Temas de tabuleiro comprados (o inicial sempre incluso) e o em uso.
  final Set<String> ownedThemes;
  String equippedTheme;

  /// Desafio diário: último dia concluído e dias seguidos concluídos.
  String? lastChallengeDay;
  int challengeStreak;
  int bestChallengeStreak;

  /// O que foi comprado COM MOEDAS e quanto custou (`skin:<id>`, `theme:<id>`).
  /// Só isso volta para a loja num estorno: item ganho de graça (o Aurora de
  /// quem já jogava) não pode virar moeda.
  final Map<String, int> coinPurchases;

  /// Tokens de compra ÚNICA (pacote de boas-vindas, sem anúncios) já
  /// creditados. Sem teto: a Play devolve essas compras em toda abertura, e
  /// esquecer o token pagaria as moedas do pacote de novo.
  final Set<String> permanentPurchases;

  /// Estornos (ids de resgate do servidor) já descontados aqui.
  final List<String> appliedRevocations;

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
        'adsRemoved': adsRemoved,
        'processedPurchases': processedPurchases,
        'appliedRevocations': appliedRevocations,
        'lastChallengeDay': lastChallengeDay,
        'challengeStreak': challengeStreak,
        'bestChallengeStreak': bestChallengeStreak,
        'ownedThemes': ownedThemes.toList(),
        'equippedTheme': equippedTheme,
        'coinPurchases': coinPurchases,
        'permanentPurchases': permanentPurchases.toList(),
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
    // Saldo negativo só existe como dívida de estorno (ver
    // `EconomyEngine.applyRevocation`) e precisa sobreviver ao save; o teto
    // de baixo evita que lixo no campo vire uma dívida absurda.
    int coins = math.max(-1000000, _asInt(json['coins']));
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
      adsRemoved: json['adsRemoved'] == true,
      lastChallengeDay: _asString(json['lastChallengeDay']),
      challengeStreak: _asInt(json['challengeStreak']),
      bestChallengeStreak: _asInt(json['bestChallengeStreak']),
      ownedThemes: <String>{
        defaultBoardThemeId,
        for (final Object? raw in _asList(json['ownedThemes']))
          if (raw is String) raw,
      },
      equippedTheme: _asString(json['equippedTheme']) ?? defaultBoardThemeId,
      coinPurchases: <String, int>{
        if (json['coinPurchases'] is Map)
          for (final MapEntry<dynamic, dynamic> e
              in (json['coinPurchases'] as Map).entries)
            if (e.key is String && e.value is num && (e.value as num) > 0)
              e.key as String: (e.value as num).toInt(),
      },
      permanentPurchases: <String>{
        for (final Object? raw in _asList(json['permanentPurchases']))
          if (raw is String) raw,
      },
      processedPurchases: <String>[
        for (final Object? raw in _asList(json['processedPurchases']))
          if (raw is String) raw,
      ],
      appliedRevocations: <String>[
        for (final Object? raw in _asList(json['appliedRevocations']))
          if (raw is String) raw,
      ],
    );
  }

  static int _asInt(Object? value) => value is num ? value.toInt() : 0;

  static String? _asString(Object? value) => value is String ? value : null;

  static List<Object?> _asList(Object? value) =>
      value is List<Object?> ? value : const <Object?>[];
}
