import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
class AudioState {
  final bool isMusicEnabled;
  final bool isSfxEnabled;
  final double musicVolume;
  final double sfxVolume;
  final bool isLoFiAmbientPlaying;

  const AudioState({
    this.isMusicEnabled = true,
    this.isSfxEnabled = true,
    this.musicVolume = 0.6,
    this.sfxVolume = 0.8,
    this.isLoFiAmbientPlaying = true,
  });

  AudioState copyWith({
    bool? isMusicEnabled,
    bool? isSfxEnabled,
    double? musicVolume,
    double? sfxVolume,
    bool? isLoFiAmbientPlaying,
  }) {
    return AudioState(
      isMusicEnabled: isMusicEnabled ?? this.isMusicEnabled,
      isSfxEnabled: isSfxEnabled ?? this.isSfxEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      isLoFiAmbientPlaying: isLoFiAmbientPlaying ?? this.isLoFiAmbientPlaying,
    );
  }
}

class AudioNotifier extends Notifier<AudioState> {
  @override
  AudioState build() {
    Future.microtask(() {
      startLoFiAmbient();
    });
    return const AudioState();
  }

  void setMusicEnabled(bool enabled) {
    state = state.copyWith(isMusicEnabled: enabled);
    if (enabled) {
      startLoFiAmbient();
    } else {
      stopLoFiAmbient();
    }
  }

  void setSfxEnabled(bool enabled) {
    state = state.copyWith(isSfxEnabled: enabled);
  }

  void setMusicVolume(double volume) {
    state = state.copyWith(musicVolume: volume.clamp(0.0, 1.0));
    _bgmPlayer?.setVolume(state.musicVolume);
  }

  void setSfxVolume(double volume) {
    state = state.copyWith(sfxVolume: volume.clamp(0.0, 1.0));
  }

  AudioPlayer? _bgmPlayer;

  static bool get _isTesting {
    if (!kIsWeb) {
      try {
        if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
      } catch (_) {}
    }
    return false;
  }

  void startLoFiAmbient() async {
    state = state.copyWith(isLoFiAmbientPlaying: true);
    if (!state.isMusicEnabled || _isTesting) return;

    _bgmPlayer ??= AudioPlayer();
    _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
    _bgmPlayer!.setVolume(state.musicVolume);
    try {
      await _bgmPlayer!.play(AssetSource('audio/bgm.mp3'));
    } catch (_) {}
  }

  void stopLoFiAmbient() async {
    state = state.copyWith(isLoFiAmbientPlaying: false);
    await _bgmPlayer?.stop();
  }

  // ==================== SOUND EFFECTS (SFX) ====================

  void _playSound(String fileName) async {
    if (!state.isSfxEnabled || _isTesting) return;
    try {
      final player = AudioPlayer();
      await player.setVolume(state.sfxVolume);
      await player.play(AssetSource('audio/$fileName'));
    } catch (e) {
      // Ignore audio errors in production
    }
  }

  void playDiceRoll() {
    if (!state.isSfxEnabled) return;
    HapticFeedback.lightImpact();
    _playSound('dice.wav');
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.mediumImpact();
    });
  }

  void playCoins() {
    if (!state.isSfxEnabled) return;
    HapticFeedback.lightImpact();
    _playSound('coins.wav');
  }

  void playBuy() {
    if (!state.isSfxEnabled) return;
    HapticFeedback.mediumImpact();
    _playSound('buy.wav');
  }

  void playUpgrade() {
    if (!state.isSfxEnabled) return;
    HapticFeedback.heavyImpact();
    _playSound('upgrade.wav');
  }

  void playJail() {
    if (!state.isSfxEnabled) return;
    HapticFeedback.heavyImpact();
    _playSound('jail.wav');
  }

  void playPoliceSiren() {
    if (!state.isSfxEnabled) return;
    HapticFeedback.heavyImpact();
    _playSound('police_siren.wav');
  }

  void playCardDraw() {
    if (!state.isSfxEnabled) return;
    HapticFeedback.lightImpact();
    _playSound('click.wav');
  }

  void playClick() {
    if (!state.isSfxEnabled) return;
    HapticFeedback.lightImpact();
    _playSound('click.wav');
  }

  void playPawnMove() {
    if (!state.isSfxEnabled) return;
    HapticFeedback.selectionClick();
    _playSound('pawn_move.mp3');
  }

  void playVictory() {
    if (!state.isSfxEnabled) return;
    HapticFeedback.vibrate();
    _playSound('victory.wav');
  }

  void playBankruptcy() {
    if (!state.isSfxEnabled) return;
    HapticFeedback.heavyImpact();
    _playSound('bankrupt.wav');
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.heavyImpact();
    });
  }
}

final audioServiceProvider = NotifierProvider<AudioNotifier, AudioState>(() {
  return AudioNotifier();
});
