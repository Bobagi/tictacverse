import 'dart:math';

/// Trilhas de fundo. Caminhos relativos a `assets/` (formato do `AssetSource`).
/// Origem de cada uma em `assets/audio/CREDITS.md`. **Só entra faixa CC0 ou
/// própria**: licença que exige crédito (CC BY) obrigaria texto na tela.
const List<String> backgroundTracks = <String>[
  'audio/music/background_loop.mp3',
  'audio/music/junkala_level1.ogg',
  'audio/music/junkala_level2.ogg',
  'audio/music/junkala_level3.ogg',
  'audio/music/sketchy_mercury.ogg',
  'audio/music/sketchy_mars.ogg',
  'audio/music/congus_lasso_lady.ogg',
  'audio/music/chasers_chipscape.ogg',
];

/// Ordem de reprodução embaralhada: toca todas as faixas antes de repetir
/// qualquer uma, e nunca emenda a mesma faixa duas vezes seguidas (o loop
/// único de antes era a reclamação do dono). Lógica pura, com `Random`
/// injetável, para o teste não depender de sorte.
class MusicPlaylist {
  MusicPlaylist({List<String>? tracks, Random? random})
      : _tracks = List<String>.unmodifiable(tracks ?? backgroundTracks),
        _random = random ?? Random();

  final List<String> _tracks;
  final Random _random;
  final List<String> _queue = <String>[];
  String? _current;

  String? get current => _current;
  List<String> get tracks => _tracks;

  /// Próxima faixa. Reembaralha quando a rodada acaba, garantindo que a
  /// primeira da rodada nova não seja a última da anterior.
  String next() {
    if (_tracks.isEmpty) {
      throw StateError('playlist vazia');
    }
    if (_queue.isEmpty) {
      _queue.addAll(_tracks);
      _queue.shuffle(_random);
      if (_tracks.length > 1 && _queue.first == _current) {
        _queue.add(_queue.removeAt(0));
      }
    }
    _current = _queue.removeAt(0);
    return _current!;
  }
}
