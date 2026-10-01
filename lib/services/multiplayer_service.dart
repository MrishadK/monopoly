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
  void Function(Map<String, dynamic>)? onHostLeftReceived;
  void Function(Map<String, dynamic>)? onPlayerKickedReceived;
  void Function(String playerId, String playerName)? onPlayerLeftReceived;
  void Function(String emoji, String playerName)? onEmojiReceived;

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
              maxPlayers: row['max_players'] is int ? row['max_players'] as int : 6,
              startingCash: row['starting_cash'] is int ? row['starting_cash'] as int : 1000,
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
    int startingCash = 1000,
  }) {
    if (_discoveryChannel != null) {
      _discoveryChannel!.sendBroadcastMessage(
        event: 'room_heartbeat',
        payload: {
          'roomId': roomId,
          'hostName': hostName,
          'playerCount': playerCount,
          'maxPlayers': 6,
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
        'max_players': 6,
        'starting_cash': startingCash,
        'status': 'waiting',
        'updated_at': DateTime.now().toIso8601String(),
      }).then((_) {}).catchError((err) {
        debugPrint('[MultiplayerService] game_rooms upsert: $err');
      });
    }
  }

  Future<void> broadcastHostLeft(String roomId) async {
    // 1. Immediately broadcast host_left to the room channel so all connected players are kicked
    if (_roomChannel != null) {
      try {
        await _roomChannel!.sendBroadcastMessage(
          event: 'host_left',
          payload: {
            'roomId': roomId,
            'message': 'Host left the room',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      } catch (e) {
        debugPrint('[MultiplayerService] broadcast host_left error: $e');
      }
    }

    // 2. Alert discovery channel to remove room from browser
    if (_discoveryChannel != null) {
      try {
        await _discoveryChannel!.sendBroadcastMessage(
          event: 'room_closed',
          payload: {'roomId': roomId},
        );
      } catch (_) {}
    }

    _activeRooms.remove(roomId);
    _notifyRooms();

    // 3. Automatically and permanently DELETE room from Supabase database
    final client = _client;
    if (client != null) {
      try {
        await client.from('game_rooms').delete().eq('room_id', roomId);
      } catch (err) {
        debugPrint('[MultiplayerService] game_rooms delete error: $err');
      }
    }
  }

  Future<void> broadcastRoomClosed(String roomId) async {
    // 1. Alert discovery channel to remove room from browser
    if (_discoveryChannel != null) {
      try {
        await _discoveryChannel!.sendBroadcastMessage(
          event: 'room_closed',
          payload: {'roomId': roomId},
        );
      } catch (_) {}
    }

    _activeRooms.remove(roomId);
    _notifyRooms();

    // 2. Automatically and permanently DELETE room from Supabase database
    final client = _client;
    if (client != null) {
      try {
        await client.from('game_rooms').delete().eq('room_id', roomId);
      } catch (err) {
        debugPrint('[MultiplayerService] game_rooms delete error: $err');
      }
    }
  }

  void sendPlayerKicked(String playerId) {
    if (_roomChannel != null) {
      _roomChannel!.sendBroadcastMessage(
        event: 'player_kicked',
        payload: {'playerId': playerId},
      );
    }
  }

  Future<void> broadcastPlayerLeft(String roomId, String playerId, String playerName) async {
    if (_roomChannel != null) {
      try {
        await _roomChannel!.sendBroadcastMessage(
          event: 'player_left',
          payload: {
            'roomId': roomId,
            'playerId': playerId,
            'playerName': playerName,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      } catch (e) {
        debugPrint('[MultiplayerService] broadcast player_left error: $e');
      }
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
      .onBroadcast(event: 'host_left', callback: (payload) {
        if (onHostLeftReceived != null) {
          onHostLeftReceived!(payload);
        }
      })
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
      })
      .onBroadcast(event: 'player_left', callback: (payload) {
        final pId = payload['playerId'] as String?;
        final pName = payload['playerName'] as String?;
        if (pId != null && pName != null && onPlayerLeftReceived != null) {
          onPlayerLeftReceived!(pId, pName);
        }
      })
      .onBroadcast(event: 'emoji_reaction', callback: (payload) {
        if (onEmojiReceived != null) {
          final emoji = payload['emoji'] as String?;
          final playerName = payload['playerName'] as String?;
          if (emoji != null && playerName != null) {
            onEmojiReceived!(emoji, playerName);
          }
        }
      });

    _roomChannel!.subscribe((status, [error]) {
      debugPrint('[MultiplayerService] Host room status: $status');
    });
  }

  Future<bool> checkRoomExists(String roomId) async {
    final client = _client;
    if (client == null) return false;
    try {
      final response = await client
          .from('game_rooms')
          .select('status')
          .eq('room_id', roomId)
          .maybeSingle();
      
      if (response == null) return false;
      // You can only join if it's waiting for players
      return response['status'] == 'waiting';
    } catch (e) {
      debugPrint('[MultiplayerService] checkRoomExists error: $e');
      // If network fails, default to allowing the attempt (Realtime might still connect)
      return true; 
    }
  }

  Future<void> joinRoom(String roomId) async {
    final client = _client;
    if (client == null) throw Exception("Network service unavailable");

    await leaveRoom();
    activeRoomId = roomId;

    _roomChannel = client.channel('kuthaka_room_$roomId');

    _roomChannel!
      .onBroadcast(event: 'host_left', callback: (payload) {
        if (onHostLeftReceived != null) {
          onHostLeftReceived!(payload);
        }
      })
      .onBroadcast(event: 'player_kicked', callback: (payload) {
        if (onPlayerKickedReceived != null) {
          onPlayerKickedReceived!(payload);
        }
      })
      .onBroadcast(event: 'player_left', callback: (payload) {
        final pId = payload['playerId'] as String?;
        final pName = payload['playerName'] as String?;
        if (pId != null && pName != null && onPlayerLeftReceived != null) {
          onPlayerLeftReceived!(pId, pName);
        }
      })
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
      })
      .onBroadcast(event: 'emoji_reaction', callback: (payload) {
        if (onEmojiReceived != null) {
          final emoji = payload['emoji'] as String?;
          final playerName = payload['playerName'] as String?;
          if (emoji != null && playerName != null) {
            onEmojiReceived!(emoji, playerName);
          }
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
      debugPrint('[MultiplayerService] Sending player_action: action=$actionType, data=$data');
      _roomChannel!.sendBroadcastMessage(
        event: 'player_action',
        payload: {
          'action': actionType,
          'actionType': actionType,
          'data': data,
        },
      );
    }
  }

  void broadcastEmoji(String emoji, String playerName) {
    if (_roomChannel != null) {
      _roomChannel!.sendBroadcastMessage(
        event: 'emoji_reaction',
        payload: {
          'emoji': emoji,
          'playerName': playerName,
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
    onHostLeftReceived = null;
    onPlayerKickedReceived = null;
    onPlayerLeftReceived = null;
    activeRoomId = null;
  }
}
