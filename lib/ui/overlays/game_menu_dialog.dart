import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../../services/audio_service.dart';
import '../../services/voice_stream_service.dart';
import '../../services/multiplayer_service.dart';
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.music_note_rounded, color: Color(0xFF0F172A), size: 20),
                            SizedBox(width: 8),
                            Text('Lo-Fi Ambient Music', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.volume_up_rounded, color: Color(0xFF0F172A), size: 20),
                            SizedBox(width: 8),
                            Text('Sound Effects (SFX)', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
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

              // ==================== LIVE VOICE STREAM ====================
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.mic_rounded, color: Color(0xFF0F172A), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Live Voice Chat Room',
                              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: voiceService.isVoiceStreaming ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            voiceService.isVoiceStreaming ? 'ONLINE' : 'OFFLINE',
                            style: TextStyle(
                              color: voiceService.isVoiceStreaming ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: voiceService.isMicMuted ? const Color(0xFFEF4444) : const Color(0xFF047857),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => ref.read(voiceStreamServiceProvider.notifier).toggleMic(),
                            icon: Icon(voiceService.isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded, size: 16),
                            label: Text(voiceService.isMicMuted ? 'Muted' : 'Mic On', style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => ref.read(voiceStreamServiceProvider.notifier).toggleSpeaker(),
                            icon: Icon(voiceService.isSpeakerMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 16),
                            label: Text(voiceService.isSpeakerMuted ? 'Deafened' : 'Listening', style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
                  if (mp.activeRoomId != null) {
                    mp.broadcastHostLeft(mp.activeRoomId!);
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
            Text(
              title,
              style: GoogleFonts.outfit(
                color: isDestructive ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.bold,
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
