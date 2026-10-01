import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../../services/audio_service.dart';
import '../../services/voice_stream_service.dart';
import '../../services/multiplayer_service.dart';
import '../../services/user_profile_service.dart';
import '../screens/home_screen.dart';

class GameMenuDialog extends ConsumerWidget {
  const GameMenuDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioServiceProvider);
    final voiceService = ref.watch(voiceStreamServiceProvider);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GAME & AUDIO SETTINGS',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // ==================== AUDIO SETTINGS ====================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.music_note_rounded, color: Color(0xFF0F172A), size: 20),
                              SizedBox(width: 8),
                              Expanded(child: Text('Lo-Fi Ambient Music', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Switch(
                          value: audioService.isMusicEnabled,
                          activeThumbColor: const Color(0xFF047857),
                          activeTrackColor: const Color(0xFFA7F3D0),
                          onChanged: (val) => ref.read(audioServiceProvider.notifier).setMusicEnabled(val),
                        ),
                      ],
                    ),
                    Slider(
                      value: audioService.musicVolume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFF047857),
                      inactiveColor: const Color(0xFFE2E8F0),
                      onChanged: audioService.isMusicEnabled
                          ? (val) => ref.read(audioServiceProvider.notifier).setMusicVolume(val)
                          : null,
                    ),

                    const Divider(color: Color(0xFFE2E8F0)),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.volume_up_rounded, color: Color(0xFF0F172A), size: 20),
                              SizedBox(width: 8),
                              Expanded(child: Text('Sound Effects (SFX)', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Switch(
                          value: audioService.isSfxEnabled,
                          activeThumbColor: const Color(0xFF047857),
                          activeTrackColor: const Color(0xFFA7F3D0),
                          onChanged: (val) => ref.read(audioServiceProvider.notifier).setSfxEnabled(val),
                        ),
                      ],
                    ),
                    Slider(
                      value: audioService.sfxVolume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFF047857),
                      inactiveColor: const Color(0xFFE2E8F0),
                      onChanged: audioService.isSfxEnabled
                          ? (val) => ref.read(audioServiceProvider.notifier).setSfxVolume(val)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (voiceService.isVoiceStreaming) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LIVE VOICE CHAT',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF334155),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
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
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Microphone', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(
                          voiceService.isMicMuted ? 'Muted' : 'Live Streaming',
                          style: TextStyle(fontSize: 11, color: voiceService.isMicMuted ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                        ),
                        value: !voiceService.isMicMuted,
                        activeColor: const Color(0xFF047857),
                        onChanged: (_) => ref.read(voiceStreamServiceProvider.notifier).toggleMic(),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Voice Audio (Speaker)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(
                          voiceService.isSpeakerMuted ? 'Muted' : 'Hearing Players',
                          style: TextStyle(fontSize: 11, color: voiceService.isSpeakerMuted ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                        ),
                        value: !voiceService.isSpeakerMuted,
                        activeColor: const Color(0xFF047857),
                        onChanged: (_) => ref.read(voiceStreamServiceProvider.notifier).toggleSpeaker(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Game Menu Options
              _menuItem(
                context,
                icon: Icons.menu_book_rounded,
                title: 'Rules of Kuthaka',
                onTap: () {
                  Navigator.pop(context);
                  _showRulesDialog(context);
                },
              ),
              const SizedBox(height: 8),

              _menuItem(
                context,
                icon: Icons.refresh_rounded,
                title: 'Restart Match',
                onTap: () {
                  Navigator.pop(context);
                  final players = ref.read(gameProvider).players;
                  ref.read(gameProvider.notifier).initializeGame(players);
                },
              ),
              const SizedBox(height: 8),

              _menuItem(
                context,
                icon: Icons.gavel_rounded,
                title: 'Declare Bankruptcy / Surrender',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  final current = ref.read(gameProvider).currentPlayer;
                  ref.read(gameProvider.notifier).surrenderPlayer(current.id);
                },
              ),
              const SizedBox(height: 8),

              _menuItem(
                context,
                icon: Icons.exit_to_app_rounded,
                title: 'Exit to Main Menu',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  final mp = ref.read(multiplayerServiceProvider);
                  final isHost = ref.read(gameProvider.notifier).isHost;
                  final myLocalId = ref.read(gameProvider.notifier).localPlayerId ?? ref.read(userProfileProvider).id;
                  if (mp.activeRoomId != null) {
                    if (isHost) {
                      mp.broadcastHostLeft(mp.activeRoomId!);
                    } else {
                      // Guest leaving: find player name from game state
                      final gameState = ref.read(gameProvider);
                      final myPlayer = gameState.players.where((p) => p.id == myLocalId).firstOrNull;
                      mp.broadcastPlayerLeft(mp.activeRoomId!, myLocalId, myPlayer?.name ?? 'A player');
                    }
                    mp.leaveRoom();
                  }
                  ref.read(voiceStreamServiceProvider.notifier).disconnectVoice();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('RESUME GAME', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDestructive ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? const Color(0xFFDC2626) : const Color(0xFF0F172A), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  color: isDestructive ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('HOW TO PLAY KUTHAKA', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ruleRow(Icons.flag_rounded, 'Pass Naattile Thudakkam (GO) to collect ₹200 salary.'),
              _ruleRow(Icons.account_balance_wallet_rounded, 'Every player starts with ₹1,000 cash balance.'),
              _ruleRow(Icons.casino_rounded, 'Rolling doubles awards an immediate extra roll! 3 doubles sends you to jail.'),
              _ruleRow(Icons.gavel_rounded, 'Land on unowned tiles to buy or auction. Landing player bids first.'),
              _ruleRow(Icons.stars_rounded, 'Hold all lands in a color group (Monopoly) to double base rent!'),
              _ruleRow(Icons.holiday_village_rounded, 'Build Cottages (1-4) evenly, then upgrade to Luxury Resorts.'),
              _ruleRow(Icons.directions_bus_rounded, 'Own Transports & Utilities for scaling fares and dice-based rent.'),
              _ruleRow(Icons.local_police_rounded, 'In Police Lockup: roll doubles, use a card, or pay ₹100 fine to exit.'),
              _ruleRow(Icons.account_balance_rounded, 'Mortgage properties for 50% value (repay with 10% interest).'),
              _ruleRow(Icons.military_tech_rounded, 'Bankrupt all opponents to become the Tycoon of God\'s Own Country!'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Widget _ruleRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF047857)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: GoogleFonts.outfit(color: const Color(0xFF334155), fontSize: 13, height: 1.3))),
        ],
      ),
    );
  }
}
