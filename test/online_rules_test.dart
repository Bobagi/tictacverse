import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/models/online_match.dart';
import 'package:tictacverse/models/player_marker.dart';
import 'package:tictacverse/services/online/online_service.dart';

OnlineMatch finished({
  String id = 'a',
  String result = 'x',
  PlayerMarker you = PlayerMarker.cross,
  int moves = 12,
  OnlineStatus status = OnlineStatus.finished,
}) =>
    OnlineMatch(
      id: id,
      code: 'ABC234',
      status: status,
      you: you,
      opponent: const OnlineOpponent(avatar: 1, tag: 10),
      moves: List<(int, int)>.generate(moves, (int i) => (i % 9, i ~/ 9)),
      version: 9,
      result: status == OnlineStatus.finished ? result : null,
      endReason: 'line',
      deadline: DateTime(2026, 10, 12),
      rematchId: null,
      rematchOf: null,
      updatedAt: DateTime(2026, 10, 9),
    );

void main() {
  const OnlineRewardRules rules = OnlineRewardRules();
  final DateTime day1 = DateTime(2026, 10, 9, 10);

  group('recompensa do online', () {
    test('vitória, derrota e empate do ponto de vista de quem joga', () {
      final OnlineRewardLedger ledger = OnlineRewardLedger();
      expect(rules.claim(finished(id: '1', result: 'x'), ledger, day1),
          OnlineOutcome.win);
      expect(
          rules.claim(finished(id: '2', result: 'x', you: PlayerMarker.nought),
              ledger, day1),
          OnlineOutcome.loss);
      expect(rules.claim(finished(id: '3', result: 'draw'), ledger, day1),
          OnlineOutcome.draw);
    });

    test('cada partida paga uma vez só', () {
      final OnlineRewardLedger ledger = OnlineRewardLedger();
      expect(rules.claim(finished(), ledger, day1), isNotNull);
      expect(rules.claim(finished(), ledger, day1), isNull);
      expect(rules.claim(finished(), ledger, day1.add(const Duration(days: 2))),
          isNull);
    });

    test('partida em andamento ou curta demais não paga', () {
      final OnlineRewardLedger ledger = OnlineRewardLedger();
      expect(
          rules.claim(finished(id: 'open', status: OnlineStatus.active), ledger,
              day1),
          isNull);
      expect(
          rules.claim(
              finished(id: 'short', moves: OnlineRewardRules.minMoves - 1),
              ledger,
              day1),
          isNull);
      expect(
          rules.claim(finished(id: 'ok', moves: OnlineRewardRules.minMoves),
              ledger, day1),
          isNotNull);
    });

    test('teto diário, e o dia seguinte volta a pagar', () {
      final OnlineRewardLedger ledger = OnlineRewardLedger();
      for (int i = 0; i < OnlineRewardRules.dailyCap; i++) {
        expect(rules.claim(finished(id: 'd$i'), ledger, day1), isNotNull);
      }
      expect(rules.claim(finished(id: 'over'), ledger, day1), isNull);
      // A que passou do teto não paga depois, na virada do dia.
      final DateTime day2 = day1.add(const Duration(days: 1));
      expect(rules.claim(finished(id: 'over'), ledger, day2), isNull);
      expect(rules.claim(finished(id: 'new'), ledger, day2), isNotNull);
    });

    test('a lista de pagas não cresce sem limite', () {
      final OnlineRewardLedger ledger = OnlineRewardLedger();
      for (int i = 0; i < 400; i++) {
        rules.claim(finished(id: 'm$i'), ledger,
            day1.add(Duration(days: i ~/ OnlineRewardRules.dailyCap)));
      }
      expect(ledger.paid.length, lessThanOrEqualTo(200));
      expect(ledger.paid.last, 'm399');
    });
  });

  group('link e código do convite', () {
    test('aceita só o nosso domínio e o esquema do app', () {
      expect(OnlineService.codeFromLink('https://tictacverse.bobagi.space/m/K7P2QX'),
          'K7P2QX');
      expect(OnlineService.codeFromLink('https://tictacverse.bobagi.space/m/k7p2qx'),
          'K7P2QX');
      expect(OnlineService.codeFromLink('tictacverse://m/K7P2QX'), 'K7P2QX');
      for (final String bad in <String>[
        'https://evil.example/m/K7P2QX',
        'https://tictacverse.bobagi.space.evil.example/m/K7P2QX',
        'https://tictacverse.bobagi.space/x/K7P2QX',
        'https://tictacverse.bobagi.space/m/K7P2QX/extra',
        'https://tictacverse.bobagi.space/m/K7P2Q',
        'tictacverse://other/K7P2QX',
        'javascript:alert(1)',
        '',
      ]) {
        expect(OnlineService.codeFromLink(bad), isNull, reason: bad);
      }
      expect(OnlineService.codeFromLink(null), isNull);
    });

    test('código digitado: maiúsculas, sem espaço; letras ambíguas recusadas', () {
      expect(OnlineService.normalizeCode(' k7p 2qx '), 'K7P2QX');
      expect(OnlineService.normalizeCode('K7P-2QX'), 'K7P2QX');
      expect(OnlineService.normalizeCode('K0P2QX'), isNull);
      expect(OnlineService.normalizeCode('KIP2QX'), isNull);
      expect(OnlineService.normalizeCode('K7P2QXZ'), isNull);
    });

    test('link montado volta para o mesmo código', () {
      expect(OnlineService.codeFromLink(OnlineService.linkFor('ABC234')),
          'ABC234');
    });
  });

  group('partida vinda do servidor', () {
    Map<String, dynamic> json() => <String, dynamic>{
          'id': 'a' * 20,
          'code': 'ABC234',
          'status': 'active',
          'you': 'o',
          'opponent': <String, dynamic>{'avatar': 3, 'tag': 42},
          'moves': <List<int>>[
            <int>[4, 4],
          ],
          'version': 3,
          'result': null,
          'endReason': null,
          'deadline': 1760000000000,
          'rematchId': null,
          'rematchOf': null,
          'updatedAt': 1760000000000,
        };

    test('lê e sabe de quem é a vez', () {
      final OnlineMatch m = OnlineMatch.fromJson(json());
      expect(m.you, PlayerMarker.nought);
      expect(m.isMyTurn, isTrue, reason: 'X jogou uma vez, vez do O');
      expect(m.toState().boards[4][4], PlayerMarker.cross);
      expect(m.toState().activeBoard, 4);
    });

    test('formato torto vira FormatException', () {
      for (final void Function(Map<String, dynamic>) breakIt
          in <void Function(Map<String, dynamic>)>[
        (Map<String, dynamic> j) => j['status'] = 'weird',
        (Map<String, dynamic> j) => j['moves'] = <Object>[
              <Object>['4', 4]
            ],
        (Map<String, dynamic> j) => j['moves'] = <Object>[
              <int>[4]
            ],
        (Map<String, dynamic> j) => j.remove('version'),
        (Map<String, dynamic> j) => j['id'] = 5,
      ]) {
        final Map<String, dynamic> j = json();
        breakIt(j);
        expect(() => OnlineMatch.fromJson(j), throwsFormatException);
      }
      expect(() => OnlineMatch.fromJson('x'), throwsFormatException);
    });

    test('desistência sem linha vira vitória sem risco', () {
      final Map<String, dynamic> j = json()
        ..['status'] = 'finished'
        ..['result'] = 'o'
        ..['endReason'] = 'resign';
      final OnlineMatch m = OnlineMatch.fromJson(j);
      expect(m.outcome, OnlineOutcome.win);
      expect(m.gameResult.winner, PlayerMarker.nought);
      expect(m.gameResult.winningLine, isNull);
    });
  });
}
