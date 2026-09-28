import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final multiplayerServiceProvider = Provider((ref) => MultiplayerService());

class MultiplayerService {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      return null;
    }
  }

  RealtimeChannel? _roomChannel;
  bool get isConnected => _roomChannel != null;

  void Function(Map<String, dynamic>)? onStateSyncReceived;
  void Function(Map<String, dynamic>)? onPlayerActionReceived;
  void Function(Map<String, dynamic>)? onLobbySyncReceived;
  void Function(Map<String, dynamic>)? onLobbyJoinReceived;
  void Function(Map<String, dynamic>)? onLobbyLeaveReceived;
  void Function(Map<String, dynamic>)? onGameStartReceived;

  Future<void> hostRoom(String roomId) async {
    final client = _client;
    if (client == null) throw Exception("Supabase not configured");

    // Clean up any existing channel
    await leaveRoom();

    _roomChannel = client.channel('kuthaka_room_$roomId');

    _roomChannel!
      .onBroadcast(event: 'lobby_join', callback: (payload) {
        if (onLobbyJoinReceived != null) {
          onLobbyJoinReceived!(payload);
        }
      })
      .onBroadcast(event: 'lobby_leave', callback: (payload) {
        if (onLobbyLeaveReceived != null) {
          onLobbyLeaveReceived!(payload);
        }
      })
      .onBroadcast(event: 'player_action', callback: (payload) {
        if (onPlayerActionReceived != null) {
          onPlayerActionReceived!(payload);
        }
      });

    _roomChannel!.subscribe((status, [error]) {
      debugPrint('[MultiplayerService] Host room status: $status');
    });
  }

  Future<void> joinRoom(String roomId) async {
    final client = _client;
    if (client == null) throw Exception("Supabase not configured");

    // Clean up any existing channel
    await leaveRoom();

    _roomChannel = client.channel('kuthaka_room_$roomId');

    _roomChannel!
      .onBroadcast(event: 'lobby_sync', callback: (payload) {
        if (onLobbySyncReceived != null) {
          onLobbySyncReceived!(payload);
        }
      })
      .onBroadcast(event: 'game_start', callback: (payload) {
        if (onGameStartReceived != null) {
          onGameStartReceived!(payload);
        }
      })
      .onBroadcast(event: 'state_sync', callback: (payload) {
        if (onStateSyncReceived != null) {
          onStateSyncReceived!(payload);
        }
      })
      .onBroadcast(event: 'player_action', callback: (payload) {
        if (onPlayerActionReceived != null) {
          onPlayerActionReceived!(payload);
        }
      });

    _roomChannel!.subscribe((status, [error]) {
      debugPrint('[MultiplayerService] Guest room status: $status');
    });
  }

  void broadcastLobbySync(Map<String, dynamic> lobbyData) {
    if (_roomChannel != null) {
      _roomChannel!.sendBroadcastMessage(
        event: 'lobby_sync',
        payload: lobbyData,
      );
    }
  }

  void sendLobbyJoin(Map<String, dynamic> playerData) {
    if (_roomChannel != null) {
      _roomChannel!.sendBroadcastMessage(
        event: 'lobby_join',
        payload: playerData,
      );
    }
  }

  void sendLobbyLeave(String playerId) {
    if (_roomChannel != null) {
      _roomChannel!.sendBroadcastMessage(
        event: 'lobby_leave',
        payload: {'playerId': playerId},
      );
    }
  }

  void broadcastGameStart(Map<String, dynamic> gameStartData) {
    if (_roomChannel != null) {
      _roomChannel!.sendBroadcastMessage(
        event: 'game_start',
        payload: gameStartData,
      );
    }
  }

  void broadcastState(Map<String, dynamic> stateMap) {
    if (_roomChannel != null) {
      _roomChannel!.sendBroadcastMessage(
        event: 'state_sync',
        payload: stateMap,
      );
    }
  }

  void sendPlayerAction(String actionType, Map<String, dynamic> data) {
    if (_roomChannel != null) {
      _roomChannel!.sendBroadcastMessage(
        event: 'player_action',
        payload: {
          'type': actionType,
          'data': data,
        },
      );
    }
  }

  Future<void> leaveRoom() async {
    if (_roomChannel != null) {
      try {
        await _roomChannel!.unsubscribe();
      } catch (_) {}
      _roomChannel = null;
    }
    onStateSyncReceived = null;
    onPlayerActionReceived = null;
    onLobbySyncReceived = null;
    onLobbyJoinReceived = null;
    onLobbyLeaveReceived = null;
    onGameStartReceived = null;
  }
}
