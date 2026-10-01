import 'dart:async';
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
  Timer? _loFiPulseTimer;

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
  }

  void setSfxVolume(double volume) {
    state = state.copyWith(sfxVolume: volume.clamp(0.0, 1.0));
  }

  void startLoFiAmbient() {
    _loFiPulseTimer?.cancel();
    state = state.copyWith(isLoFiAmbientPlaying: true);

    _loFiPulseTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!state.isMusicEnabled || !state.isLoFiAmbientPlaying) return;
    });
  }

  void stopLoFiAmbient() {
    _loFiPulseTimer?.cancel();
    _loFiPulseTimer = null;
    state = state.copyWith(isLoFiAmbientPlaying: false);
  }

  // ==================== SOUND EFFECTS (SFX) ====================

  void _playSound(String fileName) async {
    if (!state.isSfxEnabled) return;
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
