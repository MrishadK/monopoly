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
    this.startingCash = 150000,
  });

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  late List<Player> _roomPlayers;
  bool _copied = false;
  Timer? _heartbeatTimer;

  static const List<String> _botNames = [
    'Nihal (Bot)',
    'Appu (Bot)',
    'Sasi (Bot)',
    'Jayan (Bot)',
    'Balan (Bot)',
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

      // Periodic broadcast so any late-arriving guests catch up
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _broadcastCurrentLobby();
      });
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

          ref.read(gameProvider.notifier).initializeOnlineClient(parsedPlayers ?? _roomPlayers);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GameScreen(roomId: widget.roomId, isHost: false),
            ),
          );
        }
      };
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  void _broadcastCurrentLobby() {
    if (!widget.isHost) return;
    ref.read(multiplayerServiceProvider).broadcastLobbySync({
      'players': _roomPlayers.map((p) => p.toMap()).toList(),
      'startingCash': widget.startingCash,
    });
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
      backgroundColor: const Color(0xFF0F241A),
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
                        color: const Color(0xFFFFD54F),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Icon(Icons.smart_toy_rounded, color: Color(0xFFFFD54F)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Select Bot Personality Strategy:', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButton<AiPersonality>(
                  value: personality,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF143023),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
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
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
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
                    child: const Text('ADD BOT TO ROOM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    setState(() {
      _roomPlayers.removeAt(index);
    });
    _broadcastCurrentLobby();
  }

  void _leaveRoomConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14281E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Leave Waiting Room?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          widget.isHost
              ? 'You are the host. Leaving will close this room for all connected friends.'
              : 'You will disconnect from this room lobby.',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
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
    if (!widget.isHost) {
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
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();

    // Apply starting cash to all players
    final configured = _roomPlayers.map((p) => p.copyWith(cash: widget.startingCash)).toList();

    // Broadcast game start to all joined friends with player list
    ref.read(multiplayerServiceProvider).broadcastGameStart({
      'players': configured.map((p) => p.toMap()).toList(),
      'startingCash': widget.startingCash,
    });

    // Initialize game locally for host
    ref.read(gameProvider.notifier).initializeGame(configured, isHost: true);

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
        backgroundColor: const Color(0xFF071810),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D251A),
          title: Text(
            widget.isHost ? 'WAITING ROOM (HOST)' : 'WAITING ROOM (GUEST)',
            style: GoogleFonts.outfit(
              color: const Color(0xFFFFD54F),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF143526), Color(0xFF0A1F16)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.vpn_key_rounded, color: Color(0xFFFFD54F), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'ROOM CODE FOR FRIENDS',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.roomId,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFFD54F),
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
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
                                  backgroundColor: const Color(0xFF00695C),
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
                                color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFD54F)),
                              ),
                              child: Icon(
                                _copied ? Icons.check_rounded : Icons.copy_rounded,
                                color: const Color(0xFFFFD54F),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Share this 6-digit code with friends so they can join from their phone',
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),

                      // Live Voice Chat Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              voiceService.isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                              size: 16,
                              color: voiceService.isMicMuted ? Colors.redAccent : const Color(0xFF00E676),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              voiceService.isMicMuted ? 'Voice Muted' : 'Live Voice Streaming Active',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 14),
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref.read(voiceStreamServiceProvider.notifier).toggleMic();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: voiceService.isMicMuted ? const Color(0xFF00E676).withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  voiceService.isMicMuted ? 'UNMUTE' : 'MUTE',
                                  style: TextStyle(
                                    color: voiceService.isMicMuted ? const Color(0xFF00E676) : Colors.orangeAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==================== PLAYER SLOTS HEADER ====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PLAYERS (${_roomPlayers.length}/4)',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFFD54F),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (widget.isHost && _roomPlayers.length < 4)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                          foregroundColor: const Color(0xFFFFD54F),
                          side: const BorderSide(color: Color(0xFFFFD54F)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        final isHostSlot = index == 0;
                        final isMe = p.id == widget.myPlayer.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: p.color, width: 2),
                            boxShadow: [
                              BoxShadow(color: p.color.withValues(alpha: 0.15), blurRadius: 10),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: p.color.withValues(alpha: 0.25),
                                child: Icon(p.tokenIcon, size: 24, color: Colors.white),
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
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.white24,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('YOU', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isHostSlot
                                                ? const Color(0xFFFFD54F)
                                                : (p.type == PlayerType.human ? Colors.blueAccent : Colors.orangeAccent),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            isHostSlot ? 'HOST 👑' : (p.type == PlayerType.human ? 'GUEST' : 'BOT 🤖'),
                                            style: GoogleFonts.outfit(
                                              color: isHostSlot ? Colors.black : Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      p.type == PlayerType.ai
                                          ? 'Personality: ${p.aiPersonality?.name.toUpperCase()} • ₹${widget.startingCash}'
                                          : 'Piece: ${p.tokenName} • ₹${widget.startingCash}',
                                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.isHost && !isHostSlot)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                                  tooltip: 'Kick Player',
                                  onPressed: () => _removePlayer(index),
                                ),
                            ],
                          ),
                        );
                      }

                      // Empty Slot Card
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white30, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Slot ${index + 1}: Open for Player',
                                    style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  Text(
                                    'Waiting for friend or add an AI Bot...',
                                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.isHost)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFFD54F),
                                  side: const BorderSide(color: Color(0xFFFFD54F)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

                const SizedBox(height: 16),

                // ==================== BOTTOM ACTION CONTROLS ====================
                if (widget.isHost) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _roomPlayers.length >= 2 ? const Color(0xFFFFD54F) : Colors.white12,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: _roomPlayers.length >= 2 ? 6 : 0,
                      ),
                      onPressed: _roomPlayers.length >= 2 ? _startGame : null,
                      child: Text(
                        _roomPlayers.length >= 2
                            ? 'START MATCH (${_roomPlayers.length}/4) ➔'
                            : 'WAITING FOR PLAYERS (MIN 2)...',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: _roomPlayers.length >= 2 ? Colors.black : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                  if (_roomPlayers.length < 2) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tip: Tap "+ ADD BOT" above if playing solo or waiting for friends',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFFD54F)),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'WAITING FOR HOST TO START MATCH...',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFFD54F),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 13,
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
