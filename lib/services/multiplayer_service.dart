import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/public_room.dart';

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
  RealtimeChannel? _discoveryChannel;
  Timer? _pruneTimer;
  final Map<String, PublicRoom> _activeRooms = {};
  void Function(List<PublicRoom>)? _onRoomsUpdated;

  String? activeRoomId;
  bool get isConnected => _roomChannel != null;

  void Function(Map<String, dynamic>)? onStateSyncReceived;
  void Function(Map<String, dynamic>)? onPlayerActionReceived;
  void Function(Map<String, dynamic>)? onLobbySyncReceived;
  void Function(Map<String, dynamic>)? onLobbyJoinReceived;
  void Function(Map<String, dynamic>)? onLobbyLeaveReceived;
  void Function(Map<String, dynamic>)? onGameStartReceived;

  // ==================== PUBLIC ROOM DISCOVERY ====================

  Future<void> startRoomDiscovery(void Function(List<PublicRoom>) callback) async {
    _onRoomsUpdated = callback;
    final client = _client;
    if (client == null) return;

    if (_discoveryChannel != null) {
      try {
        await _discoveryChannel!.unsubscribe();
      } catch (_) {}
      _discoveryChannel = null;
    }

    _discoveryChannel = client.channel('kuthaka_discovery');

    _discoveryChannel!
      .onBroadcast(event: 'room_heartbeat', callback: (payload) {
        try {
          final room = PublicRoom.fromMap(Map<String, dynamic>.from(payload));
          if (room.roomId.isNotEmpty) {
            _activeRooms[room.roomId] = room;
            _notifyRooms();
          }
        } catch (e) {
          debugPrint('[MultiplayerService] Discovery parse error: $e');
        }
      })
      .onBroadcast(event: 'room_closed', callback: (payload) {
        final roomId = payload['roomId']?.toString();
        if (roomId != null) {
          _activeRooms.remove(roomId);
          _notifyRooms();
        }
      });

    _discoveryChannel!.subscribe((status, [error]) {
      debugPrint('[MultiplayerService] Discovery status: $status');
    });

    // Query persistent Postgres game_rooms table
    client.from('game_rooms')
      .select('room_id, host_name, player_count, max_players, starting_cash, updated_at')
      .eq('status', 'waiting')
      .then((rows) {
        for (final row in rows) {
          final rId = row['room_id']?.toString() ?? '';
          if (rId.isNotEmpty) {
            _activeRooms[rId] = PublicRoom(
              roomId: rId,
              hostName: row['host_name']?.toString() ?? 'Host',
              playerCount: row['player_count'] is int ? row['player_count'] as int : 1,
              maxPlayers: row['max_players'] is int ? row['max_players'] as int : 4,
              startingCash: row['starting_cash'] is int ? row['starting_cash'] as int : 150000,
              lastSeen: DateTime.now(),
            );
          }
        }
        _notifyRooms();
      }).catchError((err) {
        debugPrint('[MultiplayerService] game_rooms query: $err');
      });

    _pruneTimer?.cancel();
    _pruneTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final now = DateTime.now();
      final beforeCount = _activeRooms.length;
      _activeRooms.removeWhere((_, room) => now.difference(room.lastSeen).inSeconds > 10);
      if (_activeRooms.length != beforeCount) {
        _notifyRooms();
      }
    });
  }

  void _notifyRooms() {
    if (_onRoomsUpdated != null) {
      final sorted = _activeRooms.values.toList()
        ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
      _onRoomsUpdated!(sorted);
    }
  }

  Future<void> stopRoomDiscovery() async {
    _pruneTimer?.cancel();
    _pruneTimer = null;
    _onRoomsUpdated = null;
    if (_discoveryChannel != null) {
      try {
        await _discoveryChannel!.unsubscribe();
      } catch (_) {}
      _discoveryChannel = null;
    }
  }

  void broadcastRoomHeartbeat({
    required String roomId,
    required String hostName,
    required int playerCount,
    int startingCash = 150000,
  }) {
    if (_discoveryChannel != null) {
      _discoveryChannel!.sendBroadcastMessage(
        event: 'room_heartbeat',
        payload: {
          'roomId': roomId,
          'hostName': hostName,
          'playerCount': playerCount,
          'maxPlayers': 4,
          'startingCash': startingCash,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    }

    // Also persist in Supabase Postgres game_rooms table
    final client = _client;
    if (client != null) {
      client.from('game_rooms').upsert({
        'room_id': roomId,
        'host_id': client.auth.currentUser?.id ?? 'host_$roomId',
        'host_name': hostName,
        'player_count': playerCount,
        'max_players': 4,
        'starting_cash': startingCash,
        'status': 'waiting',
        'updated_at': DateTime.now().toIso8601String(),
      }).then((_) {}).catchError((err) {
        debugPrint('[MultiplayerService] game_rooms upsert: $err');
      });
    }
  }

  void broadcastRoomClosed(String roomId) {
    if (_discoveryChannel != null) {
      _discoveryChannel!.sendBroadcastMessage(
        event: 'room_closed',
        payload: {'roomId': roomId},
      );
    }

    final client = _client;
    if (client != null) {
      client.from('game_rooms').update({
        'status': 'closed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('room_id', roomId).then((_) {}).catchError((_) {});
    }
  }

  // ==================== ROOM HOSTING & JOINING ====================

  Future<void> hostRoom(String roomId) async {
    final client = _client;
    if (client == null) throw Exception("Network service unavailable");

    await leaveRoom();
    activeRoomId = roomId;

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
    if (client == null) throw Exception("Network service unavailable");

    await leaveRoom();
    activeRoomId = roomId;

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

  // ==================== MESSAGING ====================

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
    activeRoomId = null;
  }
}
