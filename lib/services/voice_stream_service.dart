import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

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
  final String? myPlayerId;
  final String? myPlayerName;
  final bool isHost;
  final bool isMicMuted;
  final bool isSpeakerMuted;
  final bool isVoiceStreaming;
  final bool isSpeaking;
  final double myAudioLevel;
  final Map<String, VoiceParticipant> participants;
  final bool isPushToTalkActive;
  final String? hostPlayerName;
  final String statusMessage;

  const VoiceStreamState({
    this.currentRoomId,
    this.myPlayerId,
    this.myPlayerName,
    this.isHost = false,
    this.isMicMuted = true, // Default to muted for privacy and zero feedback
    this.isSpeakerMuted = false,
    this.isVoiceStreaming = false,
    this.isSpeaking = false,
    this.myAudioLevel = 0.0,
    this.participants = const {},
    this.isPushToTalkActive = false,
    this.hostPlayerName,
    this.statusMessage = 'Voice Disconnected',
  });

  VoiceStreamState copyWith({
    String? currentRoomId,
    String? myPlayerId,
    String? myPlayerName,
    bool? isHost,
    bool? isMicMuted,
    bool? isSpeakerMuted,
    bool? isVoiceStreaming,
    bool? isSpeaking,
    double? myAudioLevel,
    Map<String, VoiceParticipant>? participants,
    bool? isPushToTalkActive,
    String? hostPlayerName,
    String? statusMessage,
  }) {
    return VoiceStreamState(
      currentRoomId: currentRoomId ?? this.currentRoomId,
      myPlayerId: myPlayerId ?? this.myPlayerId,
      myPlayerName: myPlayerName ?? this.myPlayerName,
      isHost: isHost ?? this.isHost,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isSpeakerMuted: isSpeakerMuted ?? this.isSpeakerMuted,
      isVoiceStreaming: isVoiceStreaming ?? this.isVoiceStreaming,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      myAudioLevel: myAudioLevel ?? this.myAudioLevel,
      participants: participants ?? this.participants,
      isPushToTalkActive: isPushToTalkActive ?? this.isPushToTalkActive,
      hostPlayerName: hostPlayerName ?? this.hostPlayerName,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class _VoiceChunkItem {
  final String senderId;
  final String senderName;
  final Uint8List wavBytes;
  final double audioLevel;

  _VoiceChunkItem({
    required this.senderId,
    required this.senderName,
    required this.wavBytes,
    required this.audioLevel,
  });
}

class VoiceStreamNotifier extends Notifier<VoiceStreamState> {
  RealtimeChannel? _voiceChannel;
  String? _myPlayerId;
  String? _myPlayerName;

  // Recording hardware components
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordSubscription;
  final List<int> _pcmBuffer = [];
  double _maxRmsInCurrentBuffer = 0.0;
  int _consecutiveSilenceCount = 0;
  Timer? _flushTimer;
  bool _isHardwareRecording = false;

  // Playback queue components
  final List<_VoiceChunkItem> _playbackQueue = [];
  bool _isPlaying = false;
  AudioPlayer? _player;
  Timer? _speakingSafetyTimer;
  Timer? _hostHeartbeatTimer;

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
      _cleanupResources();
    });
    return const VoiceStreamState();
  }

  void _cleanupResources() {
    _hostHeartbeatTimer?.cancel();
    _hostHeartbeatTimer = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _speakingSafetyTimer?.cancel();
    _speakingSafetyTimer = null;
    _recordSubscription?.cancel();
    _recordSubscription = null;

    if (_isHardwareRecording) {
      try {
        _recorder.stop();
      } catch (_) {}
      _isHardwareRecording = false;
    }

    try {
      _recorder.dispose();
    } catch (_) {}

    try {
      _player?.stop();
      _player?.dispose();
      _player = null;
    } catch (_) {}

    _voiceChannel?.unsubscribe();
    _voiceChannel = null;
  }

  // ==================== CONNECTION & CHANNEL SETUP ====================

  Future<void> connectToVoiceRoom(
    String roomId,
    String playerId,
    String playerName, {
    bool isHost = false,
    bool autoStartMic = true,
  }) async {
    if (state.currentRoomId == roomId && state.isVoiceStreaming) {
      if (_myPlayerId != playerId) {
        _myPlayerId = playerId;
        _myPlayerName = playerName;
        state = state.copyWith(myPlayerId: playerId, myPlayerName: playerName);
      }
      return;
    }

    _myPlayerId = playerId;
    _myPlayerName = playerName;

    state = state.copyWith(
      currentRoomId: roomId,
      myPlayerId: playerId,
      myPlayerName: playerName,
      isHost: isHost,
      isVoiceStreaming: true,
      statusMessage: 'Room Voice Mesh Active',
    );

    final client = _client;
    if (client != null) {
      try {
        if (_voiceChannel != null) {
          try {
            await _voiceChannel!.unsubscribe();
          } catch (_) {}
        }

        _voiceChannel = client.channel('kuthaka_voice_$roomId');

        // 1. Listen for voice chunks from any player in this room
        _voiceChannel!.onBroadcast(event: 'voice_chunk', callback: (payload) {
          _handleIncomingVoiceChunk(payload);
        });

        // 2. Listen for voice status & peer presence
        _voiceChannel!.onBroadcast(event: 'voice_status', callback: (payload) {
          _handleIncomingVoiceStatus(payload);
        });

        _voiceChannel!.subscribe((status, [error]) {
          debugPrint('[VoiceStream] Channel status: $status (error: $error)');
          if (status == RealtimeSubscribeStatus.subscribed) {
            _broadcastVoiceStatus();
          }
        });

        // Broadcast initial presence
        _broadcastVoiceStatus();

        // Start periodic peer presence heartbeat
        _startPeerHeartbeat();
      } catch (e) {
        debugPrint('[VoiceStream] Channel init error: $e');
      }
    }

    _initAudioPlayer();

    // Each device automatically starts hosting its own voice stream upon room entry
    if (autoStartMic) {
      state = state.copyWith(isMicMuted: false);
      _startHardwareRecording();
    }
  }

  void _startPeerHeartbeat() {
    _hostHeartbeatTimer?.cancel();
    _hostHeartbeatTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!state.isVoiceStreaming) {
        timer.cancel();
        return;
      }
      _broadcastVoiceStatus();
    });
  }

  void _initAudioPlayer() {
    _player ??= AudioPlayer();
    _player!.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _playNextChunk();
    });
  }

  // ==================== RECORDING & AUDIO STREAMING ====================

  void toggleMic() {
    final nextMuted = !state.isMicMuted;
    state = state.copyWith(isMicMuted: nextMuted);

    if (nextMuted) {
      _stopHardwareRecording();
    } else {
      _startHardwareRecording();
    }

    _broadcastVoiceStatus();
  }

  void toggleSpeaker() {
    final nextSpeakerMuted = !state.isSpeakerMuted;
    state = state.copyWith(isSpeakerMuted: nextSpeakerMuted);

    if (nextSpeakerMuted) {
      _playbackQueue.clear();
      _player?.stop();
      _isPlaying = false;
    }
  }

  // Push-to-Talk (Hold-to-Talk) support
  void startPushToTalk() {
    if (!state.isVoiceStreaming) return;
    state = state.copyWith(isPushToTalkActive: true, isMicMuted: false);
    _startHardwareRecording();
    _broadcastVoiceStatus();
  }

  void stopPushToTalk() {
    if (!state.isVoiceStreaming) return;
    _flushBufferIfVoice(forceSend: true);
    state = state.copyWith(isPushToTalkActive: false, isMicMuted: true);
    _stopHardwareRecording();
    _broadcastVoiceStatus();
  }

  Future<void> _startHardwareRecording() async {
    if (_isHardwareRecording) return;

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('[VoiceStream] Microphone permission was denied by user/OS');
        state = state.copyWith(
          isMicMuted: true,
          statusMessage: 'Microphone permission denied',
        );
        return;
      }

      // Check if already running
      if (await _recorder.isRecording()) {
        try {
          await _recorder.stop();
        } catch (_) {}
      }

      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
        autoGain: true,
      );

      final stream = await _recorder.startStream(config);
      _isHardwareRecording = true;
      _pcmBuffer.clear();
      _maxRmsInCurrentBuffer = 0.0;

      _recordSubscription?.cancel();
      _recordSubscription = stream.listen(
        (chunk) => _handleIncomingPcmChunk(chunk),
        onError: (err) {
          debugPrint('[VoiceStream] Stream error: $err');
          _stopHardwareRecording();
        },
      );

      // Slicing timer: flush every 700ms so voice is low-latency
      _flushTimer?.cancel();
      _flushTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
        _flushBufferIfVoice();
      });

      state = state.copyWith(statusMessage: 'Live Mic Active');
    } catch (e) {
      debugPrint('[VoiceStream] Hardware recording error: $e');
      state = state.copyWith(isMicMuted: true, statusMessage: 'Mic error: $e');
    }
  }

  Future<void> _stopHardwareRecording() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    _recordSubscription?.cancel();
    _recordSubscription = null;

    if (_isHardwareRecording) {
      try {
        await _recorder.stop();
      } catch (_) {}
      _isHardwareRecording = false;
    }

    _pcmBuffer.clear();
    _maxRmsInCurrentBuffer = 0.0;

    state = state.copyWith(
      isSpeaking: false,
      myAudioLevel: 0.0,
      statusMessage: state.isHost ? 'Voice Master (Muted)' : 'Voice Connected (Muted)',
    );
  }

  void _handleIncomingPcmChunk(Uint8List chunk) {
    if (!state.isVoiceStreaming || state.isMicMuted) return;

    _pcmBuffer.addAll(chunk);

    final rms = _calculatePcmRms(chunk);
    if (rms > _maxRmsInCurrentBuffer) {
      _maxRmsInCurrentBuffer = rms;
    }

    final level = (rms * 4.0).clamp(0.0, 1.0);
    final isSpeakingNow = level > 0.07;

    if (isSpeakingNow) {
      _consecutiveSilenceCount = 0;
    } else {
      _consecutiveSilenceCount++;
    }

    if ((state.myAudioLevel - level).abs() > 0.04 || state.isSpeaking != isSpeakingNow) {
      state = state.copyWith(
        myAudioLevel: level,
        isSpeaking: isSpeakingNow,
      );
    }

    // 1. Natural phrase end: user spoke, but has paused for ~250-300ms
    if (_pcmBuffer.length >= 8000 && _maxRmsInCurrentBuffer > 0.028 && _consecutiveSilenceCount >= 3) {
      _flushBufferIfVoice();
      return;
    }

    // 2. Max chunk limit: buffer reached ~32KB (approx 1.0 second of audio)
    if (_pcmBuffer.length >= 32000) {
      _flushBufferIfVoice();
      return;
    }

    // 3. Drop persistent ambient silence (buffer reached 16KB without any speech)
    if (_pcmBuffer.length >= 16000 && _maxRmsInCurrentBuffer <= 0.02) {
      _pcmBuffer.clear();
      _maxRmsInCurrentBuffer = 0.0;
      _consecutiveSilenceCount = 0;
    }
  }

  void _flushBufferIfVoice({bool forceSend = false}) {
    if (_pcmBuffer.isEmpty) return;

    final pcmBytes = Uint8List.fromList(_pcmBuffer);
    final peakRms = _maxRmsInCurrentBuffer;
    _pcmBuffer.clear();
    _maxRmsInCurrentBuffer = 0.0;
    _consecutiveSilenceCount = 0;

    // Minimum 1600 bytes (50ms) to ensure valid audio container
    if (pcmBytes.length < 1600) return;

    // Voice Activity Detection (VAD): Only broadcast if voice is detected or forced
    if (forceSend || (peakRms > 0.025 && !state.isMicMuted && state.isVoiceStreaming)) {
      final wavData = _createWav(pcmBytes, sampleRate: 16000, channels: 1, bitsPerSample: 16);
      final base64Audio = base64Encode(wavData);

      _broadcastVoiceChunk(base64Audio, (peakRms * 4.0).clamp(0.15, 1.0));
    }
  }

  void _broadcastVoiceChunk(String base64Audio, double level) {
    if (_voiceChannel != null && _myPlayerId != null) {
      try {
        _voiceChannel!.sendBroadcastMessage(
          event: 'voice_chunk',
          payload: {
            'sender_id': _myPlayerId,
            'sender_name': _myPlayerName,
            'audio_data': base64Audio,
            'audio_level': level,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      } catch (e) {
        debugPrint('[VoiceStream] Broadcast voice chunk failed: $e');
      }
    }
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

  // ==================== RECEIVING & AUDIO PLAYBACK ====================

  void _handleIncomingVoiceChunk(Map<String, dynamic> payload) {
    final senderId = payload['sender_id'] as String?;
    final senderName = payload['sender_name'] as String? ?? 'Player';
    final audioData = payload['audio_data'] as String?;
    final audioLevel = (payload['audio_level'] as num?)?.toDouble() ?? 0.5;

    // Ignore own voice to prevent acoustic feedback loop
    if (senderId == null || senderId == _myPlayerId) return;

    // Ignore if speaker is turned off
    if (state.isSpeakerMuted) return;

    if (audioData == null || audioData.isEmpty) return;

    try {
      final wavBytes = base64Decode(audioData);
      _playbackQueue.add(_VoiceChunkItem(
        senderId: senderId,
        senderName: senderName,
        wavBytes: wavBytes,
        audioLevel: audioLevel,
      ));

      _playNextChunk();
    } catch (e) {
      debugPrint('[VoiceStream] Decode chunk failed: $e');
    }
  }

  void _handleIncomingVoiceStatus(Map<String, dynamic> payload) {
    final senderId = payload['sender_id'] as String?;
    final senderName = payload['sender_name'] as String? ?? 'Player';
    final isSpeaking = payload['is_speaking'] as bool? ?? false;
    final level = (payload['audio_level'] as num?)?.toDouble() ?? 0.0;
    final isMuted = payload['is_muted'] as bool? ?? false;

    if (senderId == null || senderId == _myPlayerId) return;

    final updated = Map<String, VoiceParticipant>.from(state.participants);
    updated[senderId] = VoiceParticipant(
      id: senderId,
      name: senderName,
      isSpeaking: isSpeaking,
      audioLevel: level,
      isMuted: isMuted,
    );

    state = state.copyWith(participants: updated);
  }

  Future<void> _playNextChunk() async {
    if (_isPlaying || _playbackQueue.isEmpty || state.isSpeakerMuted) return;

    // Cap queue to avoid backlog during high latency
    if (_playbackQueue.length > 4) {
      _playbackQueue.removeRange(0, _playbackQueue.length - 4);
    }

    final item = _playbackQueue.removeAt(0);
    _isPlaying = true;

    _updateParticipantSpeaking(item.senderId, item.senderName, true, item.audioLevel);

    try {
      _player ??= AudioPlayer();
      try {
        await _player!.setVolume(1.0);
        await _player!.setReleaseMode(ReleaseMode.stop);
      } catch (_) {}

      // On Web: UrlSource with data URI. On Android: BytesSource with data URI fallback.
      Source source;
      if (kIsWeb) {
        source = UrlSource(Uri.dataFromBytes(item.wavBytes, mimeType: 'audio/wav').toString());
      } else {
        source = BytesSource(item.wavBytes, mimeType: 'audio/wav');
      }

      try {
        await _player!.play(source);
      } catch (innerError) {
        // Fallback for Android if BytesSource driver encounters quirks
        if (!kIsWeb) {
          final fallbackSource = UrlSource(Uri.dataFromBytes(item.wavBytes, mimeType: 'audio/wav').toString());
          await _player!.play(fallbackSource);
        } else {
          rethrow;
        }
      }

      // Exact duration based on PCM payload (32 bytes = 1ms)
      final pcmLength = (item.wavBytes.length - 44).clamp(0, 160000);
      final estimatedDurationMs = (pcmLength / 32).round().clamp(250, 6000);

      _speakingSafetyTimer?.cancel();
      _speakingSafetyTimer = Timer(Duration(milliseconds: estimatedDurationMs + 200), () {
        if (_isPlaying) {
          _isPlaying = false;
          _updateParticipantSpeaking(item.senderId, item.senderName, false, 0.0);
          _playNextChunk();
        }
      });
    } catch (e) {
      debugPrint('[VoiceStream] Play chunk error: $e');
      _isPlaying = false;
      _updateParticipantSpeaking(item.senderId, item.senderName, false, 0.0);
      _playNextChunk();
    }
  }

  void _updateParticipantSpeaking(String id, String name, bool speaking, double level) {
    final updated = Map<String, VoiceParticipant>.from(state.participants);
    final existing = updated[id];
    updated[id] = VoiceParticipant(
      id: id,
      name: existing?.name ?? name,
      isSpeaking: speaking,
      audioLevel: level,
      isMuted: existing?.isMuted ?? false,
    );
    state = state.copyWith(participants: updated);
  }

  // ==================== DISCONNECT & CLEANUP ====================

  void disconnectVoice() {
    _hostHeartbeatTimer?.cancel();
    _hostHeartbeatTimer = null;
    _stopHardwareRecording();
    _playbackQueue.clear();
    _player?.stop();

    _voiceChannel?.unsubscribe();
    _voiceChannel = null;

    state = const VoiceStreamState();
  }

  // ==================== AUDIO DSP & WAV UTILITIES ====================

  double _calculatePcmRms(Uint8List pcmData) {
    if (pcmData.length < 2) return 0.0;
    final byteData = ByteData.sublistView(pcmData);
    final sampleCount = pcmData.length ~/ 2;
    double sumSquares = 0.0;

    for (int i = 0; i < sampleCount; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      final normalized = sample / 32768.0;
      sumSquares += normalized * normalized;
    }

    return sqrt(sumSquares / sampleCount);
  }

  Uint8List _createWav(
    Uint8List pcmData, {
    required int sampleRate,
    required int channels,
    required int bitsPerSample,
  }) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final totalDataLen = pcmData.length;
    final totalAudioLen = totalDataLen + 36;

    final header = Uint8List(44);
    final byteData = ByteData.sublistView(header);

    // RIFF chunk descriptor
    header[0] = 0x52; // 'R'
    header[1] = 0x49; // 'I'
    header[2] = 0x46; // 'F'
    header[3] = 0x46; // 'F'
    byteData.setUint32(4, totalAudioLen, Endian.little);
    header[8] = 0x57; // 'W'
    header[9] = 0x41; // 'A'
    header[10] = 0x56; // 'V'
    header[11] = 0x45; // 'E'

    // fmt subchunk
    header[12] = 0x66; // 'f'
    header[13] = 0x6D; // 'm'
    header[14] = 0x74; // 't'
    header[15] = 0x20; // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
    byteData.setUint16(22, channels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, byteRate, Endian.little);
    byteData.setUint16(32, blockAlign, Endian.little);
    byteData.setUint16(34, bitsPerSample, Endian.little);

    // data subchunk
    header[36] = 0x64; // 'd'
    header[37] = 0x61; // 'a'
    header[38] = 0x74; // 't'
    header[39] = 0x61; // 'a'
    byteData.setUint32(40, totalDataLen, Endian.little);

    final wavBytes = Uint8List(44 + totalDataLen);
    wavBytes.setRange(0, 44, header);
    wavBytes.setRange(44, 44 + totalDataLen, pcmData);
    return wavBytes;
  }
}

final voiceStreamServiceProvider = NotifierProvider<VoiceStreamNotifier, VoiceStreamState>(() {
  return VoiceStreamNotifier();
});
