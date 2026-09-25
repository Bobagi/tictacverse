import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/services/music_playlist.dart';

void main() {
  const List<String> tracks = <String>['a', 'b', 'c', 'd'];

  test('toca todas as faixas antes de repetir qualquer uma', () {
    final MusicPlaylist playlist =
        MusicPlaylist(tracks: tracks, random: Random(1));
    final List<String> round = <String>[for (int i = 0; i < 4; i++) playlist.next()];
    expect(round.toSet(), tracks.toSet());
  });

  test('nunca emenda a mesma faixa duas vezes seguidas, em nenhuma semente', () {
    for (int seed = 0; seed < 200; seed++) {
      final MusicPlaylist playlist =
          MusicPlaylist(tracks: tracks, random: Random(seed));
      String previous = playlist.next();
      for (int i = 0; i < 40; i++) {
        final String track = playlist.next();
        expect(track, isNot(previous), reason: 'semente $seed, passo $i');
        previous = track;
      }
    }
  });

  test('a lista real tem mais de uma faixa e todas em audio/music', () {
    expect(backgroundTracks.length, greaterThan(1));
    for (final String track in backgroundTracks) {
      expect(track, startsWith('audio/music/'));
    }
  });
}
