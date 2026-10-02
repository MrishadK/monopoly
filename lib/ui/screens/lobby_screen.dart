import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/public_room.dart';
import '../../services/multiplayer_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/voice_stream_service.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/theme_provider.dart';
import 'user_profile_screen.dart';
import 'waiting_room_screen.dart';
import 'leaderboard_screen.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final TextEditingController _roomController = TextEditingController();
  int _startingCash = 1000;
  bool _isLoadingHost = false;
  bool _isLoadingJoin = false;
  String _error = '';
  List<PublicRoom> _publicRooms = [];

  @override
  void initState() {
    super.initState();
    // Start Supabase live public room discovery
    final multiplayer = ref.read(multiplayerServiceProvider);
    multiplayer.startRoomDiscovery((rooms) {
      if (mounted) {
        setState(() {
          _publicRooms = rooms;
        });
      }
    });
  }

  @override
  void dispose() {
    ref.read(multiplayerServiceProvider).stopRoomDiscovery();
    _roomController.dispose();
    super.dispose();
  }

  void _openProfileSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserProfileScreen()),
    );
  }

  void _openLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
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

      final multiplayer = ref.read(multiplayerServiceProvider);
      await multiplayer.hostRoom(roomId);

      // Connect to Live Voice Room
      await ref.read(voiceStreamServiceProvider.notifier).connectToVoiceRoom(
        roomId,
        myPlayer.id,
        myPlayer.name,
        isHost: true,
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

  Future<void> _joinSpecificRoom(String roomId) async {
    setState(() {
      _isLoadingJoin = true;
      _error = '';
    });

    try {
      final profile = ref.read(userProfileProvider);
      final myPlayer = profile.toPlayer(cash: _startingCash);
      
      final mpService = ref.read(multiplayerServiceProvider);
      
      // Check if room exists and is waiting for players
      final exists = await mpService.checkRoomExists(roomId);
      if (!exists) {
        throw Exception("Room does not exist, or the match has already started.");
      }

      await mpService.joinRoom(roomId);

      // Connect to Live Voice Room
      await ref.read(voiceStreamServiceProvider.notifier).connectToVoiceRoom(
        roomId,
        myPlayer.id,
        myPlayer.name,
        isHost: false,
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
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        setState(() => _error = errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingJoin = false);
      }
    }
  }

  Future<void> _joinFromInput() async {
    final roomId = _roomController.text.trim();
    if (roomId.isEmpty || roomId.length < 6) {
      setState(() => _error = 'Please enter a valid 6-digit room code');
      return;
    }
    await _joinSpecificRoom(roomId);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final myPlayer = profile.toPlayer(cash: _startingCash);
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        elevation: 0.5,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'MULTIPLAYER LOUNGE',
          style: GoogleFonts.outfit(
            color: context.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        actions: [
          // Theme Toggle Pill
          InkWell(
            onTap: () => ref.read(themeModeProvider.notifier).toggle(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242C3D) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFF59E0B),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    size: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDark ? 'Dark' : 'Light',
                    style: GoogleFonts.outfit(
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFFB45309),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.leaderboard_rounded,
              color: isDark ? KuthakaColors.emerald : const Color(0xFF047857),
            ),
            tooltip: 'Kerala Tycoons Leaderboard',
            onPressed: _openLeaderboard,
          ),
          IconButton(
            icon: Icon(Icons.manage_accounts_rounded, color: context.textPrimary),
            tooltip: 'Edit Player Profile',
            onPressed: _openProfileSetup,
          ),
        ],
      ),
      body: Column(
        children: [
          // Supabase Realtime Status Pill Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D3B2E) : const Color(0xFFECFDF5),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF134E3A) : const Color(0xFFA7F3D0),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Game Network: Online',
                  style: GoogleFonts.outfit(
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ==================== 1. PLAYER PROFILE SUMMARY ====================
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.borderColor),
                          boxShadow: context.subtleShadow,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: profile.color,
                              child: Icon(myPlayer.tokenIcon, size: 26, color: Colors.white),
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
                                            color: context.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 17,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF3D2E0A) : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.5) : const Color(0xFFFDE68A),
                                          ),
                                        ),
                                        child: Text(
                                          'READY',
                                          style: GoogleFonts.outfit(
                                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Token: ${myPlayer.tokenName}',
                                    style: GoogleFonts.outfit(
                                      color: context.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.textPrimary,
                                side: BorderSide(color: context.borderColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF3B1010) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
                            ),
                          ),
                          child: Text(
                            _error,
                            style: GoogleFonts.outfit(
                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ==================== 2. LIVE PUBLIC ROOMS DISCOVERY ====================
                      Row(
                        children: [
                          Icon(
                            Icons.radar_rounded,
                            size: 18,
                            color: isDark ? KuthakaColors.emerald : const Color(0xFF047857),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LIVE PUBLIC ROOMS',
                            style: GoogleFonts.outfit(
                              color: context.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_publicRooms.length} available',
                            style: GoogleFonts.outfit(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_publicRooms.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.borderColor),
                            boxShadow: context.subtleShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: context.cardAltColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: context.textMuted,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'No open public games right now',
                                      style: GoogleFonts.outfit(
                                        color: context.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'Host a room below to be seen by other players!',
                                      style: GoogleFonts.outfit(
                                        color: context.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _publicRooms.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final room = _publicRooms[idx];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.borderColor),
                                boxShadow: context.subtleShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0D3B2E) : const Color(0xFFECFDF5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.meeting_room_rounded,
                                      color: isDark ? KuthakaColors.emerald : const Color(0xFF047857),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${room.hostName}\'s Room',
                                          style: GoogleFonts.outfit(
                                            color: context.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              'PIN: ${room.roomId}',
                                              style: GoogleFonts.outfit(
                                                color: context.textSecondary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.people_alt_rounded,
                                              size: 12,
                                              color: context.textMuted,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${room.playerCount}/${room.maxPlayers}',
                                              style: TextStyle(
                                                color: context.textSecondary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? KuthakaColors.emerald : const Color(0xFF047857),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    onPressed: _isLoadingJoin ? null : () => _joinSpecificRoom(room.roomId),
                                    child: Text(
                                      'JOIN',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 24),

                      // ==================== 3. HOST NEW GAME CARD ====================
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: context.borderColor),
                          boxShadow: context.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF3D2E0A) : const Color(0xFFFEF3C7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_home_work_rounded,
                                    color: isDark ? KuthakaColors.gold : const Color(0xFFB45309),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CREATE NEW ROOM',
                                        style: GoogleFonts.outfit(
                                          color: context.textPrimary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Host a match & gather friends in waiting lobby',
                                        style: GoogleFonts.outfit(
                                          color: context.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'STARTING CASH PER PLAYER',
                              style: GoogleFonts.outfit(
                                color: context.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _cashOptionChip(context, 1000, '₹1,000', isDark),
                                const SizedBox(width: 8),
                                _cashOptionChip(context, 1500, '₹1,500', isDark),
                                const SizedBox(width: 8),
                                _cashOptionChip(context, 2500, '₹2,500', isDark),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? KuthakaColors.emerald : const Color(0xFF047857),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: _isLoadingHost ? null : _hostRoom,
                                icon: _isLoadingHost
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.rocket_launch_rounded, size: 20),
                                label: Text(
                                  _isLoadingHost ? 'CREATING LOBBY...' : 'HOST ROOM LOBBY',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================== 4. JOIN PRIVATE PIN CARD ====================
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: context.borderColor),
                          boxShadow: context.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFE0E7FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.vpn_key_rounded,
                                    color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'JOIN WITH PRIVATE PIN',
                                        style: GoogleFonts.outfit(
                                          color: context.textPrimary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Enter 6-digit code shared by host',
                                        style: GoogleFonts.outfit(
                                          color: context.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _roomController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: context.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '000000',
                                hintStyle: GoogleFonts.outfit(
                                  color: context.textMuted,
                                  letterSpacing: 8,
                                ),
                                filled: true,
                                fillColor: context.cardAltColor,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: context.borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: context.borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? KuthakaColors.emerald : const Color(0xFF047857),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF252538) : const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isDark ? context.borderColor : Colors.transparent,
                                    ),
                                  ),
                                ),
                                onPressed: _isLoadingJoin ? null : _joinFromInput,
                                icon: _isLoadingJoin
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.login_rounded, size: 20),
                                label: Text(
                                  _isLoadingJoin ? 'CONNECTING...' : 'JOIN ROOM',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================== 5. LEADERBOARD PROMO CARD ====================
                      InkWell(
                        onTap: _openLeaderboard,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.borderColor),
                            boxShadow: context.subtleShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF3D2E0A) : const Color(0xFFFFFBEB),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.workspace_premium_rounded,
                                  color: isDark ? KuthakaColors.gold : const Color(0xFFD97706),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kerala Tycoons Hall of Fame',
                                      style: GoogleFonts.outfit(
                                        color: context.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'See live top rankings from Kerala League',
                                      style: GoogleFonts.outfit(
                                        color: context.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: context.textMuted),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cashOptionChip(BuildContext context, int amount, String label, bool isDark) {
    final isSelected = _startingCash == amount;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _startingCash = amount),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0D3B2E) : const Color(0xFFECFDF5))
                : context.cardAltColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isDark ? KuthakaColors.emerald : const Color(0xFF047857))
                  : context.borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected
                  ? (isDark ? KuthakaColors.emerald : const Color(0xFF047857))
                  : context.textSecondary,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
