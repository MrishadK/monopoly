import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/multiplayer_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/voice_stream_service.dart';
import 'user_profile_screen.dart';
import 'waiting_room_screen.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final TextEditingController _roomController = TextEditingController();
  int _startingCash = 150000;
  bool _isLoadingHost = false;
  bool _isLoadingJoin = false;
  String _error = '';

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  void _openProfileSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserProfileScreen()),
    );
  }

  Future<void> _hostRoom() async {
    setState(() {
      _isLoadingHost = true;
      _error = '';
    });

    try {
      final profile = ref.read(userProfileProvider);
      final myPlayer = profile.toPlayer(cash: _startingCash);

      // 6-digit unique room PIN
      final roomId = (Random().nextInt(900000) + 100000).toString();

      await ref.read(multiplayerServiceProvider).hostRoom(roomId);

      // Connect to Live Voice Room
      await ref.read(voiceStreamServiceProvider.notifier).connectToVoiceRoom(
        roomId,
        myPlayer.id,
        myPlayer.name,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingRoomScreen(
              roomId: roomId,
              isHost: true,
              myPlayer: myPlayer,
              startingCash: _startingCash,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not create room lobby: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingHost = false);
      }
    }
  }

  Future<void> _joinRoom() async {
    final roomId = _roomController.text.trim();
    if (roomId.isEmpty || roomId.length < 6) {
      setState(() => _error = 'Please enter a valid 6-digit room code');
      return;
    }

    setState(() {
      _isLoadingJoin = true;
      _error = '';
    });

    try {
      final profile = ref.read(userProfileProvider);
      final myPlayer = profile.toPlayer(cash: _startingCash);

      await ref.read(multiplayerServiceProvider).joinRoom(roomId);

      // Connect to Live Voice Room
      await ref.read(voiceStreamServiceProvider.notifier).connectToVoiceRoom(
        roomId,
        myPlayer.id,
        myPlayer.name,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingRoomScreen(
              roomId: roomId,
              isHost: false,
              myPlayer: myPlayer,
              startingCash: _startingCash,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not connect to room: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingJoin = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final myPlayer = profile.toPlayer(cash: _startingCash);

    return Scaffold(
      backgroundColor: const Color(0xFF06150E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2419),
        title: Text(
          'MULTIPLAYER LOUNGE',
          style: GoogleFonts.outfit(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts_rounded, color: Color(0xFFFFD54F)),
            tooltip: 'Edit Player Profile',
            onPressed: _openProfileSetup,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                // ==================== 1. PLAYER PROFILE CARD ====================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: profile.color, width: 2),
                    boxShadow: [
                      BoxShadow(color: profile.color.withValues(alpha: 0.2), blurRadius: 16),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: profile.color.withValues(alpha: 0.25),
                        child: Text(myPlayer.tokenEmoji, style: const TextStyle(fontSize: 28)),
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
                                    profile.name,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'READY',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFFFD54F),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Token: ${myPlayer.tokenName}',
                              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFD54F),
                          side: const BorderSide(color: Color(0xFFFFD54F)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: const Text('EDIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: _openProfileSetup,
                      ),
                    ],
                  ),
                ),

                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Text(_error, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
                  ),
                ],

                const SizedBox(height: 24),

                // ==================== 2. HOST NEW GAME CARD ====================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF133224), Color(0xFF0B1E16)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFFD54F).withValues(alpha: 0.12), blurRadius: 20),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text('👑', style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HOST A PRIVATE ROOM',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Opens waiting room lobby before starting match',
                                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Starting Cash
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Starting Cash:', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                          DropdownButton<int>(
                            value: _startingCash,
                            dropdownColor: const Color(0xFF10261C),
                            style: GoogleFonts.outfit(color: const Color(0xFF69F0AE), fontWeight: FontWeight.bold, fontSize: 14),
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(value: 100000, child: Text('₹1,00,000 (Quick Match)')),
                              DropdownMenuItem(value: 150000, child: Text('₹1,50,000 (Standard Kerala)')),
                              DropdownMenuItem(value: 250000, child: Text('₹2,50,000 (Grand Tycoon)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _startingCash = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD54F),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            elevation: 4,
                          ),
                          onPressed: _isLoadingHost ? null : _hostRoom,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoadingHost)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              else ...[
                                Text(
                                  'CREATE WAITING LOBBY ➔',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '💡 Match will NOT start automatically. You can invite friends and add bots in the lobby.',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  '── OR JOIN AN EXISTING GAME ──',
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, letterSpacing: 2),
                ),

                const SizedBox(height: 24),

                // ==================== 3. JOIN WITH CODE CARD ====================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _roomController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFFD54F),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '• • • • • •',
                          hintStyle: const TextStyle(color: Colors.white30, letterSpacing: 8),
                          labelText: 'Enter 6-Digit Room Code',
                          labelStyle: const TextStyle(color: Colors.white70, letterSpacing: 1),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: Colors.black26,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.paste_rounded, color: Color(0xFFFFD54F)),
                            tooltip: 'Paste from Clipboard',
                            onPressed: () async {
                              final data = await Clipboard.getData('text/plain');
                              if (data?.text != null) {
                                final clean = data!.text!.replaceAll(RegExp(r'[^0-9]'), '');
                                if (clean.isNotEmpty) {
                                  _roomController.text = clean.length > 6 ? clean.substring(0, 6) : clean;
                                }
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00695C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            elevation: 4,
                          ),
                          onPressed: _isLoadingJoin ? null : _joinRoom,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoadingJoin)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              else ...[
                                Text(
                                  'JOIN WAITING LOBBY ➔',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
