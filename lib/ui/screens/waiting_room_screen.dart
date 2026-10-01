import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../services/multiplayer_service.dart';
import '../../services/voice_stream_service.dart';
import '../../providers/game_provider.dart';
import 'game_screen.dart';

class WaitingRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  final bool isHost;
  final Player myPlayer;
  final int startingCash;

  const WaitingRoomScreen({
    super.key,
    required this.roomId,
    required this.isHost,
    required this.myPlayer,
    this.startingCash = 1000,
  });

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  late List<Player> _roomPlayers;
  bool _copied = false;
  Timer? _heartbeatTimer;

  static const List<String> _botNames = [
    'Aadu Thoma',
    'Ranga Annan',
    'Dasamoolam Damu',
    'Shaji Pappan',
    'Manavalan',
    'Bilal John',
    'Neelakandan',
    'CID Moosa',
  ];

  static const List<Color> _botPalette = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
  ];

  @override
  void initState() {
    super.initState();
    _roomPlayers = [widget.myPlayer];

    final multiplayer = ref.read(multiplayerServiceProvider);

    if (widget.isHost) {
      // Host listens for guest joins
      multiplayer.onLobbyJoinReceived = (payload) {
        final guestData = payload['player'];
        if (guestData != null) {
          final guest = Player.fromMap(Map<String, dynamic>.from(guestData));
          if (!_roomPlayers.any((p) => p.id == guest.id) && _roomPlayers.length < 4) {
            setState(() {
              _roomPlayers.add(guest);
            });
            HapticFeedback.mediumImpact();
            _broadcastCurrentLobby();
          }
        }
      };

      // Host listens for guest leaves
      multiplayer.onLobbyLeaveReceived = (payload) {
        final leavingId = payload['playerId'];
        if (leavingId != null) {
          setState(() {
            _roomPlayers.removeWhere((p) => p.id == leavingId);
          });
          _broadcastCurrentLobby();
        }
      };

      // Periodic broadcast for guests and lobby discovery
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _broadcastCurrentLobby();
      });
      _broadcastCurrentLobby();
    } else {
      // Guest sends join info to host repeatedly until acknowledged
      int joinAttempts = 0;
      _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        joinAttempts++;
        if (_roomPlayers.length > 1 || joinAttempts > 10) {
          timer.cancel();
        } else {
          multiplayer.sendLobbyJoin({'player': widget.myPlayer.toMap()});
        }
      });

      // Initial send
      multiplayer.sendLobbyJoin({'player': widget.myPlayer.toMap()});

      // Guest listens for host leaving -> auto kick with message
      multiplayer.onHostLeftReceived = (payload) {
        if (!mounted) return;
        _heartbeatTimer?.cancel();
        ref.read(multiplayerServiceProvider).leaveRoom();
        ref.read(voiceStreamServiceProvider.notifier).disconnectVoice();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.door_back_door_outlined, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Host left the room. The match lobby has been closed.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      };

      // Guest listens for being kicked individually
      multiplayer.onPlayerKickedReceived = (payload) {
        final kickedId = payload['playerId']?.toString();
        if (kickedId == widget.myPlayer.id && mounted) {
          _heartbeatTimer?.cancel();
          ref.read(multiplayerServiceProvider).leaveRoom();
          ref.read(voiceStreamServiceProvider.notifier).disconnectVoice();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.person_remove_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You were removed from the room by the host.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      };

      // Guest listens for lobby state sync from host
      multiplayer.onLobbySyncReceived = (payload) {
        final rawList = payload['players'] as List?;
        if (rawList != null && mounted) {
          final playersList = List<Player>.from(
            rawList.map((p) => Player.fromMap(Map<String, dynamic>.from(p))),
          );
          setState(() {
            _roomPlayers = playersList;
          });
        }
      };

      // Guest listens for match launch from host
      multiplayer.onGameStartReceived = (payload) {
        if (mounted) {
          List<Player>? parsedPlayers;
          final rawList = payload['players'] as List?;
          if (rawList != null) {
            parsedPlayers = List<Player>.from(
              rawList.map((p) => Player.fromMap(Map<String, dynamic>.from(p))),
            );
          }

          ref.read(gameProvider.notifier).initializeOnlineClient(
            initialPlayers: parsedPlayers ?? _roomPlayers,
            localPlayerId: widget.myPlayer.id,
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GameScreen(roomId: widget.roomId, isHost: false),
            ),
          );
        }
      };
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceStreamServiceProvider.notifier).connectToVoiceRoom(
        widget.roomId, 
        widget.myPlayer.id, 
        widget.myPlayer.name,
        isHost: widget.isHost,
        autoStartMic: true,
      );
    });
  }

  bool _isStartingGame = false;

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    if (widget.isHost && !_isStartingGame) {
      try {
        ref.read(multiplayerServiceProvider).broadcastHostLeft(widget.roomId);
      } catch (_) {}
    }
    super.dispose();
  }

  void _broadcastCurrentLobby() {
    if (!widget.isHost) return;
    final multiplayer = ref.read(multiplayerServiceProvider);
    multiplayer.broadcastLobbySync({
      'players': _roomPlayers.map((p) => p.toMap()).toList(),
      'startingCash': widget.startingCash,
    });

    // Also broadcast room discovery heartbeat
    multiplayer.broadcastRoomHeartbeat(
      roomId: widget.roomId,
      hostName: widget.myPlayer.name,
      playerCount: _roomPlayers.length,
      startingCash: widget.startingCash,
    );
  }

  void _addBot() {
    if (_roomPlayers.length >= 4) return;
    int botIndex = _roomPlayers.length;
    final botName = _botNames[(botIndex - 1) % _botNames.length];
    final personality = AiPersonality.values[(botIndex - 1) % AiPersonality.values.length];

    final bot = Player(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      name: botName,
      type: PlayerType.ai,
      token: PlayerToken.values[botIndex % PlayerToken.values.length],
      color: _botPalette[(botIndex - 1) % _botPalette.length],
      aiPersonality: personality,
      cash: widget.startingCash,
    );

    HapticFeedback.lightImpact();
    setState(() {
      _roomPlayers.add(bot);
    });
    _broadcastCurrentLobby();
  }

  void _showAddBotSheet() {
    if (_roomPlayers.length >= 4) return;
    String botName = _botNames[(_roomPlayers.length - 1) % _botNames.length];
    AiPersonality personality = AiPersonality.conservative;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ADD AI OPPONENT',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Icon(Icons.smart_toy_rounded, color: Color(0xFF047857)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Select AI Strategy:', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButton<AiPersonality>(
                  value: personality,
                  isExpanded: true,
                  style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 15),
                  items: AiPersonality.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text('${p.name.toUpperCase()} - ${_getPersonalityDesc(p)}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => personality = val);
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      int botIndex = _roomPlayers.length;
                      final bot = Player(
                        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
                        name: botName,
                        type: PlayerType.ai,
                        token: PlayerToken.values[botIndex % PlayerToken.values.length],
                        color: _botPalette[(botIndex - 1) % _botPalette.length],
                        aiPersonality: personality,
                        cash: widget.startingCash,
                      );
                      setState(() => _roomPlayers.add(bot));
                      _broadcastCurrentLobby();
                    },
                    child: const Text('ADD BOT TO ROOM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getPersonalityDesc(AiPersonality p) {
    switch (p) {
      case AiPersonality.conservative: return 'Cautious, maintains safety cash';
      case AiPersonality.aggressive: return 'Buys all lands & builds fast';
      case AiPersonality.investor: return 'Prioritizes Transports & high-yield cities';
      case AiPersonality.trader: return 'Balances negotiations & trades';
      case AiPersonality.riskTaker: return 'High stakes spender';
    }
  }

  void _removePlayer(int index) {
    if (index == 0) return; // Cannot kick host
    HapticFeedback.mediumImpact();
    final removed = _roomPlayers[index];
    setState(() {
      _roomPlayers.removeAt(index);
    });
    ref.read(multiplayerServiceProvider).sendPlayerKicked(removed.id);
    _broadcastCurrentLobby();
  }

  void _leaveRoomConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Leave Waiting Room?',
          style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        content: Text(
          widget.isHost
              ? 'You are the host. Leaving will close this room for all connected friends.'
              : 'You will disconnect from this room lobby.',
          style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _handleExit();
            },
            child: const Text('LEAVE ROOM'),
          ),
        ],
      ),
    );
  }

  void _handleExit() {
    if (widget.isHost) {
      ref.read(multiplayerServiceProvider).broadcastHostLeft(widget.roomId);
    } else {
      ref.read(multiplayerServiceProvider).sendLobbyLeave(widget.myPlayer.id);
    }
    ref.read(multiplayerServiceProvider).leaveRoom();
    ref.read(voiceStreamServiceProvider.notifier).disconnectVoice();
    Navigator.pop(context);
  }

  void _startGame() {
    if (!widget.isHost) return;
    if (_roomPlayers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 players are required to start the match! Tap "+ ADD BOT" or invite a friend.'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _isStartingGame = true;
    });

    // Close room on discovery channel so it disappears from lobby browser
    ref.read(multiplayerServiceProvider).broadcastRoomClosed(widget.roomId);

    // Apply starting cash to all players
    final configured = _roomPlayers.map((p) => p.copyWith(cash: widget.startingCash)).toList();

    // Broadcast game start to all joined friends with player list
    ref.read(multiplayerServiceProvider).broadcastGameStart({
      'players': configured.map((p) => p.toMap()).toList(),
      'startingCash': widget.startingCash,
    });

    // Initialize game locally for host
    ref.read(gameProvider.notifier).initializeGame(configured, isHost: true, localPlayerId: widget.myPlayer.id);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(roomId: widget.roomId, isHost: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = ref.watch(voiceStreamServiceProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveRoomConfirm();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          title: Text(
            widget.isHost ? 'WAITING ROOM (HOST)' : 'WAITING ROOM (GUEST)',
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 17,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFDC2626)),
              tooltip: 'Leave Room',
              onPressed: _leaveRoomConfirm,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // ==================== ROOM PIN CARD ====================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.vpn_key_rounded, color: Color(0xFFB45309), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'ROOM PIN CODE',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF64748B),
                              fontSize: 12,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.roomId,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF0F172A),
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(width: 14),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: widget.roomId));
                              HapticFeedback.lightImpact();
                              setState(() => _copied = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Room Code ${widget.roomId} copied to clipboard!'),
                                  backgroundColor: const Color(0xFF047857),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) setState(() => _copied = false);
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Icon(
                                _copied ? Icons.check_rounded : Icons.copy_rounded,
                                color: const Color(0xFF0F172A),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Share this PIN with friends so they can join from their phone',
                        style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      
                      // Voice Chat Pill
                      if (voiceService.isVoiceStreaming)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: voiceService.isSpeaking
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFE2E8F0),
                              width: voiceService.isSpeaking ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Mic Toggle / Push-to-Talk
                              GestureDetector(
                                onTap: () {
                                  ref.read(voiceStreamServiceProvider.notifier).toggleMic();
                                  HapticFeedback.lightImpact();
                                },
                                onLongPressStart: (_) {
                                  ref.read(voiceStreamServiceProvider.notifier).startPushToTalk();
                                  HapticFeedback.mediumImpact();
                                },
                                onLongPressEnd: (_) {
                                  ref.read(voiceStreamServiceProvider.notifier).stopPushToTalk();
                                  HapticFeedback.lightImpact();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: voiceService.isPushToTalkActive
                                        ? const Color(0xFFDCFCE7)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    voiceService.isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                                    color: voiceService.isMicMuted ? const Color(0xFFEF4444) : const Color(0xFF047857),
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Live Voice Animation or State
                              if (!voiceService.isMicMuted && voiceService.isSpeaking)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(4, (index) {
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 120),
                                      width: 4,
                                      height: 8 + (voiceService.myAudioLevel * 18 * (index % 2 == 0 ? 1 : 0.6)),
                                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF047857),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  }),
                                )
                              else
                                Text(
                                  voiceService.isPushToTalkActive
                                      ? 'TALKING...'
                                      : (voiceService.isMicMuted ? 'Mic Off' : 'Mic Live'),
                                  style: GoogleFonts.outfit(
                                    color: voiceService.isMicMuted ? const Color(0xFF64748B) : const Color(0xFF047857),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              const SizedBox(width: 10),
                              // Speaker Toggle
                              GestureDetector(
                                onTap: () {
                                  ref.read(voiceStreamServiceProvider.notifier).toggleSpeaker();
                                  HapticFeedback.lightImpact();
                                },
                                child: Icon(
                                  voiceService.isSpeakerMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                  color: voiceService.isSpeakerMuted ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Serverless / Host Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'PEER VOICE MESH',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF0369A1),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ==================== PLAYER SLOTS HEADER ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PLAYERS (${_roomPlayers.length}/4)',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF334155),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (widget.isHost && _roomPlayers.length < 4)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFECFDF5),
                          foregroundColor: const Color(0xFF047857),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFF047857)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        icon: const Icon(Icons.smart_toy_rounded, size: 16),
                        label: const Text('+ ADD BOT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: _showAddBotSheet,
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // ==================== 4 PLAYER SLOTS ====================
                Expanded(
                  child: ListView.builder(
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      if (index < _roomPlayers.length) {
                        final p = _roomPlayers[index];
                        // The host is always at index 0, EXCEPT if we are a guest who hasn't received sync yet
                        final isHostSlot = index == 0 && (widget.isHost || _roomPlayers.length > 1);
                        final isMe = p.id == widget.myPlayer.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: p.color,
                                child: Icon(p.tokenIcon, size: 20, color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            p.name,
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF0F172A),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('YOU', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isHostSlot
                                                ? const Color(0xFFFEF3C7)
                                                : (p.type == PlayerType.human ? const Color(0xFFE0E7FF) : const Color(0xFFF3E8FF)),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isHostSlot ? 'HOST' : (p.type == PlayerType.human ? 'GUEST' : 'BOT'),
                                            style: GoogleFonts.outfit(
                                              color: isHostSlot
                                                  ? const Color(0xFF92400E)
                                                  : (p.type == PlayerType.human ? const Color(0xFF3730A3) : const Color(0xFF6B21A8)),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.type == PlayerType.ai
                                          ? 'Personality: ${p.aiPersonality?.name.toUpperCase()} • ₹${widget.startingCash}'
                                          : 'Piece: ${p.tokenName} • ₹${widget.startingCash}',
                                      style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.isHost && !isHostSlot)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Color(0xFFDC2626), size: 20),
                                  tooltip: 'Kick Player',
                                  onPressed: () => _removePlayer(index),
                                ),
                            ],
                          ),
                        );
                      }

                      // Empty Slot Card
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFE2E8F0),
                              child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF94A3B8), size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Slot ${index + 1}: Open for Player',
                                    style: GoogleFonts.outfit(color: const Color(0xFF334155), fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  Text(
                                    'Waiting for friend or add an AI Bot...',
                                    style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.isHost)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF047857),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('BOT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: _addBot,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // ==================== BOTTOM ACTION CONTROLS ====================
                if (widget.isHost) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _roomPlayers.length >= 2 ? const Color(0xFF047857) : const Color(0xFFCBD5E1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: _roomPlayers.length >= 2 ? 4 : 0,
                      ),
                      onPressed: _roomPlayers.length >= 2 ? _startGame : null,
                      child: Text(
                        _roomPlayers.length >= 2
                            ? 'START MATCH (${_roomPlayers.length}/4)'
                            : 'WAITING FOR PLAYERS (MIN 2)...',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (_roomPlayers.length < 2) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Tip: Tap "+ ADD BOT" above if playing solo or waiting for friends',
                      style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF047857)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'WAITING FOR HOST TO START MATCH...',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF047857),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
