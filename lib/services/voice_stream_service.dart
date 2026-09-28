import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoiceParticipant {
  final String id;
  final String name;
  final bool isSpeaking;
  final double audioLevel; // 0.0 to 1.0
  final bool isMuted;

  const VoiceParticipant({
    required this.id,
    required this.name,
    this.isSpeaking = false,
    this.audioLevel = 0.0,
    this.isMuted = false,
  });

  VoiceParticipant copyWith({
    String? id,
    String? name,
    bool? isSpeaking,
    double? audioLevel,
    bool? isMuted,
  }) {
    return VoiceParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      audioLevel: audioLevel ?? this.audioLevel,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class VoiceStreamState {
  final String? currentRoomId;
  final bool isMicMuted;
  final bool isSpeakerMuted;
  final bool isVoiceStreaming;
  final bool isSpeaking;
  final double myAudioLevel;
  final Map<String, VoiceParticipant> participants;

  const VoiceStreamState({
    this.currentRoomId,
    this.isMicMuted = false,
    this.isSpeakerMuted = false,
    this.isVoiceStreaming = false,
    this.isSpeaking = false,
    this.myAudioLevel = 0.0,
    this.participants = const {},
  });

  VoiceStreamState copyWith({
    String? currentRoomId,
    bool? isMicMuted,
    bool? isSpeakerMuted,
    bool? isVoiceStreaming,
    bool? isSpeaking,
    double? myAudioLevel,
    Map<String, VoiceParticipant>? participants,
  }) {
    return VoiceStreamState(
      currentRoomId: currentRoomId ?? this.currentRoomId,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isSpeakerMuted: isSpeakerMuted ?? this.isSpeakerMuted,
      isVoiceStreaming: isVoiceStreaming ?? this.isVoiceStreaming,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      myAudioLevel: myAudioLevel ?? this.myAudioLevel,
      participants: participants ?? this.participants,
    );
  }
}

class VoiceStreamNotifier extends Notifier<VoiceStreamState> {
  RealtimeChannel? _voiceChannel;
  String? _myPlayerId;
  String? _myPlayerName;
  Timer? _audioSimulationTimer;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  VoiceStreamState build() {
    ref.onDispose(() {
      _audioSimulationTimer?.cancel();
      _voiceChannel?.unsubscribe();
    });
    return const VoiceStreamState();
  }

  Future<void> connectToVoiceRoom(String roomId, String playerId, String playerName) async {
    _myPlayerId = playerId;
    _myPlayerName = playerName;

    state = state.copyWith(currentRoomId: roomId, isVoiceStreaming: true);

    final client = _client;
    if (client == null) {
      _startVoiceSimulation();
      return;
    }

    try {
      _voiceChannel = client.channel('kuthaka_voice_$roomId');

      _voiceChannel!
        .onBroadcast(event: 'voice_status', callback: (payload) {
          final senderId = payload['sender_id'] as String?;
          final senderName = payload['sender_name'] as String? ?? 'Player';
          final speaking = payload['is_speaking'] as bool? ?? false;
          final level = (payload['audio_level'] as num?)?.toDouble() ?? 0.0;
          final muted = payload['is_muted'] as bool? ?? false;

          if (senderId != null && senderId != _myPlayerId && !state.isSpeakerMuted) {
            final newParticipants = Map<String, VoiceParticipant>.from(state.participants);
            newParticipants[senderId] = VoiceParticipant(
              id: senderId,
              name: senderName,
              isSpeaking: speaking,
              audioLevel: level,
              isMuted: muted,
            );
            state = state.copyWith(participants: newParticipants);
          }
        })
        .subscribe();

      _startVoiceSimulation();
    } catch (e) {
      debugPrint('Voice stream connection fallback: $e');
      _startVoiceSimulation();
    }
  }

  void toggleMic() {
    final nextMuted = !state.isMicMuted;
    state = state.copyWith(
      isMicMuted: nextMuted,
      isSpeaking: nextMuted ? false : state.isSpeaking,
      myAudioLevel: nextMuted ? 0.0 : state.myAudioLevel,
    );
    _broadcastVoiceStatus();
  }

  void toggleSpeaker() {
    state = state.copyWith(isSpeakerMuted: !state.isSpeakerMuted);
  }

  void _startVoiceSimulation() {
    _audioSimulationTimer?.cancel();
    final random = Random();

    _audioSimulationTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!state.isVoiceStreaming) return;

      bool newSpeaking = state.isSpeaking;
      double newLevel = state.myAudioLevel;

      if (!state.isMicMuted) {
        if (random.nextDouble() > 0.65) {
          newSpeaking = true;
          newLevel = 0.3 + random.nextDouble() * 0.7;
        } else {
          newSpeaking = false;
          newLevel = 0.0;
        }
        _broadcastVoiceStatus();
      }

      final newParticipants = Map<String, VoiceParticipant>.from(state.participants);
      for (final id in newParticipants.keys) {
        if (random.nextDouble() > 0.7) {
          final current = newParticipants[id]!;
          newParticipants[id] = current.copyWith(
            isSpeaking: random.nextBool(),
            audioLevel: random.nextDouble() * 0.8,
          );
        }
      }

      state = state.copyWith(
        isSpeaking: newSpeaking,
        myAudioLevel: newLevel,
        participants: newParticipants,
      );
    });
  }

  void _broadcastVoiceStatus() {
    if (_voiceChannel != null && _myPlayerId != null) {
      try {
        _voiceChannel!.sendBroadcastMessage(
          event: 'voice_status',
          payload: {
            'sender_id': _myPlayerId,
            'sender_name': _myPlayerName,
            'is_speaking': state.isSpeaking,
            'audio_level': state.myAudioLevel,
            'is_muted': state.isMicMuted,
          },
        );
      } catch (_) {}
    }
  }

  void disconnectVoice() {
    _audioSimulationTimer?.cancel();
    _audioSimulationTimer = null;
    _voiceChannel?.unsubscribe();
    _voiceChannel = null;
    state = state.copyWith(isVoiceStreaming: false, participants: const {});
  }
}

final voiceStreamServiceProvider = NotifierProvider<VoiceStreamNotifier, VoiceStreamState>(() {
  return VoiceStreamNotifier();
});
