import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  AudioService._() {
    _configurePlayers();
  }

  static final AudioService instance = AudioService._();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final ValueNotifier<bool> _isMuted = ValueNotifier<bool>(false);
  final ValueNotifier<double> _volume = ValueNotifier<double>(0.85);
  bool _hasStartedMusic = false;
  StreamSubscription<void>? _musicLoopSubscription;
  AudioContext? _sharedContext;

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
    _sharedContext = sharedContext;
    _musicPlayer.setAudioContext(sharedContext);
    _sfxPlayer.setAudioContext(sharedContext);
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _musicPlayer.setVolume(_volume.value);
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    _sfxPlayer.setVolume(_volume.value);
    _musicLoopSubscription?.cancel();
    _musicLoopSubscription = _musicPlayer.onPlayerComplete.listen((_) {
      if (!_isMuted.value) {
        _musicPlayer.play(
          AssetSource('audio/music/background_loop.wav'),
          volume: _volume.value,
        );
      }
    });
  }

  Future<void> setMuted(bool value) async {
    _isMuted.value = value;
    if (value) {
      await _musicPlayer.pause();
      await _musicPlayer.setVolume(0);
      await _sfxPlayer.setVolume(0);
    } else {
      await _musicPlayer.setVolume(_volume.value);
      await _sfxPlayer.setVolume(_volume.value);
      await ensureBackgroundMusic();
    }
  }

  Future<void> setVolume(double value) async {
    final double clamped = value.clamp(0.0, 1.0);
    _volume.value = clamped;
    if (!_isMuted.value) {
      await _musicPlayer.setVolume(clamped);
      await _sfxPlayer.setVolume(clamped);
    }
  }

  Future<void> ensureBackgroundMusic() async {
    if (_isMuted.value) {
      return;
    }
    try {
      if (!_hasStartedMusic) {
        _hasStartedMusic = true;
        await _musicPlayer.play(
          AssetSource('audio/music/background_loop.wav'),
          volume: _volume.value,
        );
      } else if (_musicPlayer.state == PlayerState.paused ||
          _musicPlayer.state == PlayerState.stopped) {
        await _musicPlayer.resume();
      }
    } catch (_) {
      // Ignore missing asset errors until audio files are swapped.
    }
  }

  Future<void> playMoveSfx() async {
    if (_isMuted.value) {
      return;
    }
    try {
      final AudioPlayer player = AudioPlayer();
      final AudioContext? sharedContext = _sharedContext;
      if (sharedContext != null) {
        await player.setAudioContext(sharedContext);
      }
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(_volume.value);
      await player.play(
        AssetSource('audio/sfx/move_click.wav'),
        volume: _volume.value,
      );
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (_) {
      // Ignore missing asset errors until audio files are swapped.
    }
  }
}
