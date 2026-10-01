import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VoiceParticipant {
  final String id;
  final String name;
  final bool isSpeaking;
  final double audioLevel;
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
    this.isMicMuted = true,
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

class VoiceStreamNotifier extends Notifier<VoiceStreamState> {
  RealtimeChannel? _signalingChannel;
  String? _myPlayerId;
  String? _myPlayerName;

  MediaStream? _localStream;
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final Map<String, List<RTCIceCandidate>> _earlyIceCandidates = {};
  
  Timer? _statusBroadcastTimer;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Ice servers configuration
  final Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
          'stun:stun4.l.google.com:19302',
          'stun:stun.cloudflare.com:3478',
        ],
      },
      {
        'urls': [
          'turn:openrelay.metered.ca:80',
          'turn:openrelay.metered.ca:443',
          'turn:openrelay.metered.ca:443?transport=tcp',
          'turn:relay.metered.ca:80',
          'turn:relay.metered.ca:443',
          'turn:relay.metered.ca:443?transport=tcp',
        ],
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      }
    ],
    'sdpSemantics': 'unified-plan',
  };

  @override
  VoiceStreamState build() {
    ref.onDispose(() {
      disconnectVoice(isDisposing: true);
    });
    return const VoiceStreamState();
  }

  // ==================== CONNECTION SETUP ====================

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
      statusMessage: 'Connecting WebRTC...',
    );

    await _initLocalStream();

    final client = _client;
    if (client != null) {
      try {
        if (_signalingChannel != null) {
          try {
            await _signalingChannel!.unsubscribe();
          } catch (_) {}
        }

        _signalingChannel = client.channel('kuthaka_webrtc_$roomId');

        _signalingChannel!.onBroadcast(event: 'webrtc_signaling', callback: (payload) {
          _handleSignalingMessage(payload);
        });
        
        _signalingChannel!.onBroadcast(event: 'voice_status', callback: (payload) {
          _handleIncomingVoiceStatus(payload);
        });

        _signalingChannel!.subscribe((status, [error]) {
          debugPrint('[WebRTC] Channel status: $status (error: $error)');
          if (status == RealtimeSubscribeStatus.subscribed) {
            _broadcastSignaling({'type': 'peer-join'});
            _startStatusBroadcast();
            state = state.copyWith(statusMessage: 'Voice Mesh Connected');
          }
        });
      } catch (e) {
        debugPrint('[WebRTC] Channel init error: $e');
        state = state.copyWith(statusMessage: 'Connection Error');
      }
    }

    if (autoStartMic) {
      _setMicMuted(false);
    } else {
      _setMicMuted(true);
    }
  }

  Future<void> _initLocalStream() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
    } catch (e) {
      debugPrint('[WebRTC] Failed to get local stream: $e');
      state = state.copyWith(statusMessage: 'Mic Access Denied');
    }
  }

  // ==================== SIGNALING & WEBRTC CORE ====================

  void _broadcastSignaling(Map<String, dynamic> data) {
    if (_signalingChannel == null || _myPlayerId == null) return;
    try {
      _signalingChannel!.sendBroadcastMessage(
        event: 'webrtc_signaling',
        payload: {
          'sender_id': _myPlayerId,
          'sender_name': _myPlayerName,
          'data': data,
        },
      );
    } catch (e) {
      debugPrint('[WebRTC] Signaling broadcast failed: $e');
    }
  }

  Future<void> _handleSignalingMessage(Map<String, dynamic> payload) async {
    final senderId = payload['sender_id'] as String?;
    final senderName = payload['sender_name'] as String? ?? 'Player';
    final data = payload['data'] as Map<String, dynamic>?;

    if (senderId == null || senderId == _myPlayerId || data == null) return;

    final targetId = data['target_id'] as String?;
    if (targetId != null && targetId != _myPlayerId) {
      // This message is for someone else
      return;
    }

    final type = data['type'] as String?;
    
    switch (type) {
      case 'peer-join':
        debugPrint('[WebRTC] New peer joined: $senderId, initiating offer...');
        await _createPeerConnection(senderId, senderName);
        await _makeOffer(senderId);
        break;
        
      case 'offer':
        debugPrint('[WebRTC] Received offer from: $senderId');
        await _createPeerConnection(senderId, senderName);
        final offerMap = data['sdp'] as Map<String, dynamic>;
        await _peerConnections[senderId]!.setRemoteDescription(
          RTCSessionDescription(offerMap['sdp'], offerMap['type'])
        );
        _flushEarlyCandidates(senderId);
        await _makeAnswer(senderId);
        break;
        
      case 'answer':
        debugPrint('[WebRTC] Received answer from: $senderId');
        final answerMap = data['sdp'] as Map<String, dynamic>;
        final pc = _peerConnections[senderId];
        if (pc != null) {
          await pc.setRemoteDescription(
            RTCSessionDescription(answerMap['sdp'], answerMap['type'])
          );
          _flushEarlyCandidates(senderId);
        }
        break;
        
      case 'ice-candidate':
        final candidateMap = data['candidate'] as Map<String, dynamic>?;
        if (candidateMap == null) break;
        final cStr = candidateMap['candidate'] as String?;
        if (cStr == null || cStr.trim().isEmpty) break;
        
        final candidate = RTCIceCandidate(
          cStr,
          candidateMap['sdpMid'] as String?,
          candidateMap['sdpMLineIndex'] as int?,
        );
        
        final pc = _peerConnections[senderId];
        // If peer connection doesn't exist yet OR remote description is not set, we queue it
        if (pc == null || await pc.getRemoteDescription() == null) {
          debugPrint('[WebRTC] Queueing early ICE candidate from $senderId: $cStr');
          _earlyIceCandidates.putIfAbsent(senderId, () => []).add(candidate);
        } else {
          debugPrint('[WebRTC] Adding ICE candidate from $senderId: $cStr');
          await pc.addCandidate(candidate);
        }
        break;
    }
  }
  
  Future<void> _flushEarlyCandidates(String peerId) async {
    final pc = _peerConnections[peerId];
    if (pc == null) return;
    
    final candidates = _earlyIceCandidates[peerId] ?? [];
    if (candidates.isNotEmpty) {
      debugPrint('[WebRTC] Flushing ${candidates.length} queued ICE candidates for $peerId');
      for (final candidate in candidates) {
        await pc.addCandidate(candidate);
      }
      _earlyIceCandidates.remove(peerId);
    }
  }

  Future<void> _createPeerConnection(String peerId, String peerName) async {
    if (_peerConnections.containsKey(peerId)) return;

    final pc = await createPeerConnection(_rtcConfig);
    _peerConnections[peerId] = pc;

    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.trim().isEmpty) {
        debugPrint('[WebRTC] ICE candidate gathering finished for $peerId');
        return;
      }
      debugPrint('[WebRTC] Gathered candidate for $peerId: ${candidate.candidate}');
      _broadcastSignaling({
        'type': 'ice-candidate',
        'target_id': peerId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    pc.onIceConnectionState = (iceState) {
      debugPrint('[WebRTC] ICE connection state with $peerId: $iceState');
    };

    pc.onTrack = (event) async {
      debugPrint('[WebRTC] Received remote track from $peerId');
      if (event.streams.isNotEmpty) {
        final stream = event.streams.first;
        
        // Add renderer for web/desktop playback support
        if (!_remoteRenderers.containsKey(peerId)) {
          final renderer = RTCVideoRenderer();
          await renderer.initialize();
          renderer.srcObject = stream;
          _remoteRenderers[peerId] = renderer;
          
          // Rebuild state so UI can mount the renderer
          state = state.copyWith();
        } else {
          _remoteRenderers[peerId]!.srcObject = stream;
        }

        // Add to participants list
        _updateParticipantStatus(
          peerId, 
          peerName, 
          false, 
          0.0, 
          false
        );
      }
    };
    
    pc.onConnectionState = (rtcState) {
      debugPrint('[WebRTC] Connection state with $peerId: $rtcState');
      if (rtcState == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          rtcState == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _removePeer(peerId);
      }
    };
  }

  Future<void> _makeOffer(String targetId) async {
    final pc = _peerConnections[targetId];
    if (pc == null) return;
    
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    
    _broadcastSignaling({
      'type': 'offer',
      'target_id': targetId,
      'sdp': {'sdp': offer.sdp, 'type': offer.type},
    });
  }

  Future<void> _makeAnswer(String targetId) async {
    final pc = _peerConnections[targetId];
    if (pc == null) return;
    
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    
    _broadcastSignaling({
      'type': 'answer',
      'target_id': targetId,
      'sdp': {'sdp': answer.sdp, 'type': answer.type},
    });
  }

  void _removePeer(String peerId) {
    _peerConnections[peerId]?.close();
    _peerConnections.remove(peerId);
    
    _remoteRenderers[peerId]?.dispose();
    _remoteRenderers.remove(peerId);
    
    final updated = Map<String, VoiceParticipant>.from(state.participants);
    updated.remove(peerId);
    state = state.copyWith(participants: updated);
  }

  // ==================== AUDIO CONTROLS ====================

  void toggleMic() {
    _setMicMuted(!state.isMicMuted);
  }

  void _setMicMuted(bool muted) {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !muted;
      }
    }
    state = state.copyWith(isMicMuted: muted, isSpeaking: !muted);
    _broadcastCurrentStatus();
  }

  void toggleSpeaker() {
    final nextSpeakerMuted = !state.isSpeakerMuted;
    state = state.copyWith(isSpeakerMuted: nextSpeakerMuted);
    
    for (final renderer in _remoteRenderers.values) {
      renderer.muted = nextSpeakerMuted;
    }
  }

  void startPushToTalk() {
    if (!state.isVoiceStreaming) return;
    state = state.copyWith(isPushToTalkActive: true);
    _setMicMuted(false);
  }

  void stopPushToTalk() {
    if (!state.isVoiceStreaming) return;
    state = state.copyWith(isPushToTalkActive: false);
    _setMicMuted(true);
  }

  // ==================== STATUS BROADCASTING ====================

  void _startStatusBroadcast() {
    _statusBroadcastTimer?.cancel();
    _statusBroadcastTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _broadcastCurrentStatus();
    });
  }

  void _broadcastCurrentStatus() {
    if (_signalingChannel == null || _myPlayerId == null) return;
    try {
      _signalingChannel!.sendBroadcastMessage(
        event: 'voice_status',
        payload: {
          'sender_id': _myPlayerId,
          'sender_name': _myPlayerName,
          'is_speaking': !state.isMicMuted,
          'is_muted': state.isMicMuted,
        },
      );
    } catch (_) {}
  }

  void _handleIncomingVoiceStatus(Map<String, dynamic> payload) {
    final senderId = payload['sender_id'] as String?;
    final senderName = payload['sender_name'] as String? ?? 'Player';
    final isSpeaking = payload['is_speaking'] as bool? ?? false;
    final isMuted = payload['is_muted'] as bool? ?? false;

    if (senderId == null || senderId == _myPlayerId) return;

    _updateParticipantStatus(senderId, senderName, isSpeaking, isSpeaking ? 0.8 : 0.0, isMuted);
  }

  void _updateParticipantStatus(String id, String name, bool speaking, double level, bool isMuted) {
    final updated = Map<String, VoiceParticipant>.from(state.participants);
    updated[id] = VoiceParticipant(
      id: id,
      name: name,
      isSpeaking: speaking,
      audioLevel: level,
      isMuted: isMuted,
    );
    state = state.copyWith(participants: updated);
  }

  // ==================== CLEANUP ====================

  void disconnectVoice({bool isDisposing = false}) {
    _statusBroadcastTimer?.cancel();
    _statusBroadcastTimer = null;
    
    for (final peerId in _peerConnections.keys.toList()) {
      _removePeer(peerId);
    }
    
    _localStream?.dispose();
    _localStream = null;

    _signalingChannel?.unsubscribe();
    _signalingChannel = null;

    if (!isDisposing) {
      state = const VoiceStreamState();
    }
  }

  // Expose renderers for the UI to attach to the widget tree
  Map<String, RTCVideoRenderer> get remoteRenderers => _remoteRenderers;
}

final voiceStreamServiceProvider = NotifierProvider<VoiceStreamNotifier, VoiceStreamState>(() {
  return VoiceStreamNotifier();
});
