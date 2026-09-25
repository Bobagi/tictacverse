import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'music_playlist.dart';
import 'storage_service.dart';

/// Efeitos sonoros do jogo. Os arquivos vivem em `assets/audio/sfx/` (origem e
/// licença em `assets/audio/CREDITS.md`).
enum Sfx {
  moveX('move_x.ogg'),
  moveO('move_o.ogg'),
  uiClick('ui_click.ogg'),
  capture('capture.ogg'),
  win('win.ogg'),
  lose('lose.ogg'),
  draw('draw.ogg'),
  levelUp('level_up.ogg'),
  achievement('achievement.ogg'),
  xpTick('xp_tick.ogg'),
  chaos('chaos.ogg'),
  streak('streak.ogg'),
  winLine('win_line.ogg');

  const Sfx(this.fileName);

  final String fileName;

  String get assetPath => 'audio/sfx/$fileName';
}

class AudioService {
  AudioService._() {
    _configurePlayers();
  }

  static final AudioService instance = AudioService._();

  /// Tocadores reutilizados em rodízio: criar um `AudioPlayer` por efeito
  /// vazava instâncias e atrasava o som na primeira jogada.
  static const int _sfxPoolSize = 4;

  /// Intervalo mínimo entre dois ticks do contador de XP, para o rajado do
  /// contador não virar ruído nem esgotar o pool.
  static const Duration _tickThrottle = Duration(milliseconds: 45);

  final AudioPlayer _musicPlayer = AudioPlayer();
  final MusicPlaylist _playlist = MusicPlaylist();
  final List<AudioPlayer> _sfxPool = <AudioPlayer>[];
  int _nextSfxSlot = 0;
  final ValueNotifier<bool> _isMuted = ValueNotifier<bool>(false);
  final ValueNotifier<double> _volume = ValueNotifier<double>(1.0);
  bool _hasStartedMusic = false;
  StreamSubscription<void>? _musicLoopSubscription;

  DateTime? _lastTickAt;

  ValueListenable<bool> get isMutedListenable => _isMuted;
  ValueListenable<double> get volumeListenable => _volume;
  bool get isMuted => _isMuted.value;
  double get volume => _volume.value;

  void _configurePlayers() {
    final AudioContext sharedContext = AudioContext(
      android: AudioContextAndroid(
        audioFocus: AndroidAudioFocus.none,
        usageType: AndroidUsageType.game,
        contentType: AndroidContentType.music,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: <AVAudioSessionOptions>{AVAudioSessionOptions.mixWithOthers},
      ),
    );

    _musicPlayer.setAudioContext(sharedContext);
    // `stop`, não `loop`: ao terminar uma faixa a próxima da playlist entra.
    _musicPlayer.setReleaseMode(ReleaseMode.stop);
    _musicPlayer.setVolume(_volume.value);
    for (int i = 0; i < _sfxPoolSize; i++) {
      final AudioPlayer player = AudioPlayer();
      player.setAudioContext(sharedContext);
      player.setReleaseMode(ReleaseMode.stop);
      player.setPlayerMode(PlayerMode.lowLatency);
      player.setVolume(_volume.value);
      _sfxPool.add(player);
    }
    _musicLoopSubscription?.cancel();
    _musicLoopSubscription = _musicPlayer.onPlayerComplete.listen((_) {
      if (!_isMuted.value) {
        _playNextTrack();
      }
    });
  }

  Future<void> _playNextTrack() async {
    try {
      await _musicPlayer.play(
        AssetSource(_playlist.next()),
        volume: _volume.value,
      );
    } catch (_) {
      // Sem música não se derruba o jogo.
    }
  }

  /// Aplica preferências persistidas sem tocar música (chamado no startup).
  void applyStoredSettings({required bool muted, required double volume}) {
    _isMuted.value = muted;
    _volume.value = volume.clamp(0.0, 1.0);
    _applyVolume(muted ? 0 : _volume.value);
  }

  void _applyVolume(double value) {
    _musicPlayer.setVolume(value);
    for (final AudioPlayer player in _sfxPool) {
      player.setVolume(value);
    }
  }

  void _persistSettings() {
    StorageService.instance
        .saveAudioSettings(muted: _isMuted.value, volume: _volume.value);
  }

  Future<void> setMuted(bool value) async {
    _isMuted.value = value;
    _persistSettings();
    if (value) {
      await _musicPlayer.pause();
      _applyVolume(0);
    } else {
      _applyVolume(_volume.value);
      await ensureBackgroundMusic();
    }
  }

  Future<void> setVolume(double value) async {
    final double clamped = value.clamp(0.0, 1.0);
    _volume.value = clamped;
    _persistSettings();
    if (!_isMuted.value) {
      _applyVolume(clamped);
    }
  }

  Future<void> ensureBackgroundMusic() async {
    if (_isMuted.value) {
      return;
    }
    try {
      if (!_hasStartedMusic) {
        _hasStartedMusic = true;
        await _playNextTrack();
      } else if (_musicPlayer.state == PlayerState.paused ||
          _musicPlayer.state == PlayerState.stopped) {
        await _musicPlayer.resume();
      }
    } catch (_) {
      // Sem música não se derruba o jogo.
    }
  }

  /// Toca um efeito. Efeitos são curtos e se sobrepõem (pool em rodízio), então
  /// uma rajada de eventos não corta o anterior no meio.
  Future<void> play(Sfx sfx) async {
    if (_isMuted.value || _sfxPool.isEmpty) {
      return;
    }
    if (sfx == Sfx.xpTick) {
      final DateTime now = DateTime.now();
      final DateTime? last = _lastTickAt;
      if (last != null && now.difference(last) < _tickThrottle) {
        return;
      }
      _lastTickAt = now;
    }
    final AudioPlayer player = _sfxPool[_nextSfxSlot];
    _nextSfxSlot = (_nextSfxSlot + 1) % _sfxPool.length;
    try {
      await player.stop();
      await player.play(
        AssetSource(sfx.assetPath),
        volume: _volume.value,
      );
    } catch (_) {
      // Asset ausente ou tocador ocupado: silêncio, nunca exceção.
    }
  }

  /// Som da peça sendo colocada. O O tem um timbre um pouco mais grave que o
  /// X, então dá para "ouvir" de quem foi a jogada sem olhar.
  Future<void> playMoveSfx({bool isNought = false}) =>
      play(isNought ? Sfx.moveO : Sfx.moveX);

  Future<void> playUiClick() => play(Sfx.uiClick);

  Future<void> pauseAll() async {
    await _musicPlayer.pause();
    for (final AudioPlayer player in _sfxPool) {
      await player.stop();
    }
  }

  Future<void> resumeBackgroundMusic() async {
    await ensureBackgroundMusic();
  }
}
