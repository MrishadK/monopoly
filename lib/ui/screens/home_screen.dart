import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';
import '../../services/user_profile_service.dart';
import 'game_screen.dart';
import 'lobby_screen.dart';
import 'local_setup_screen.dart';
import 'user_profile_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _startQuickPlay(BuildContext context, WidgetRef ref) {
    final profile = ref.read(userProfileProvider);
    final human = profile.toPlayer(cash: 150000);
    const bot = Player(
      id: 'p2',
      name: 'Nihal (Bot)',
      type: PlayerType.ai,
      token: PlayerToken.coconut,
      color: Color(0xFF2196F3),
      aiPersonality: AiPersonality.conservative,
      cash: 150000,
    );

    ref.read(gameProvider.notifier).initializeGame([human, bot]);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  void _openMultiplayer(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(userProfileProvider);
    if (!profile.isConfigured) {
      final done = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const UserProfileScreen(isInitialSetup: true)),
      );
      if (done != true && !context.mounted) return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LobbyScreen()),
      );
    }
  }

  void _openLeaderboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // User Identity Badge at Top
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: profile.color,
                          child: Icon(profile.toPlayer().tokenIcon, size: 14, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profile.name,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PROFILE',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF92400E),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Subtitle Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF047857), width: 1),
                  ),
                  child: Text(
                    'GOD\'S OWN BOARD GAME',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF065F46),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Generated Hero Banner Art
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 350),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x10000000), blurRadius: 15, offset: Offset(0, 6)),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/kuthaka_banner.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Logo Title
                Text(
                  'KUTHAKA',
                  style: GoogleFonts.outfit(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 8,
                  ),
                ),
                Text(
                  'കുത്തക  •  A KERALA REAL ESTATE SAGA',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.sailing_rounded, color: Color(0xFF047857), size: 20),
                    SizedBox(width: 16),
                    Icon(Icons.pets_rounded, color: Color(0xFF047857), size: 20),
                    SizedBox(width: 16),
                    Icon(Icons.forest_rounded, color: Color(0xFF047857), size: 20),
                    SizedBox(width: 16),
                    Icon(Icons.local_fire_department_rounded, color: Color(0xFF047857), size: 20),
                  ],
                ),
                const SizedBox(height: 28),

                // Menu Buttons
                _buildMenuBtn(
                  context,
                  title: 'QUICK PLAY',
                  subtitle: 'Play as ${profile.name} vs Nihal (Bot)',
                  icon: Icons.play_arrow_rounded,
                  isPrimary: true,
                  onTap: () => _startQuickPlay(context, ref),
                ),
                const SizedBox(height: 12),

                _buildMenuBtn(
                  context,
                  title: 'LOCAL GAME SETUP',
                  subtitle: '2-4 Players & Custom AI Personalities',
                  icon: Icons.groups_rounded,
                  isPrimary: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LocalSetupScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildMenuBtn(
                  context,
                  title: 'ONLINE MULTIPLAYER',
                  subtitle: 'Live Rooms & Voice Streaming',
                  icon: Icons.wifi_tethering_rounded,
                  isPrimary: false,
                  onTap: () => _openMultiplayer(context, ref),
                ),
                const SizedBox(height: 12),

                _buildMenuBtn(
                  context,
                  title: 'KERALA TYCOONS',
                  subtitle: 'Global Kerala Hall of Fame',
                  icon: Icons.leaderboard_rounded,
                  isPrimary: false,
                  onTap: () => _openLeaderboard(context),
                ),
                const SizedBox(height: 12),

                _buildMenuBtn(
                  context,
                  title: 'HOW TO PLAY',
                  subtitle: 'Kerala Properties & Rules Guide',
                  icon: Icons.menu_book_rounded,
                  isPrimary: false,
                  onTap: () => _showRulesGuide(context),
                ),
                const SizedBox(height: 20),

                Text(
                  'v1.0.0 • Made with Kerala Pride',
                  style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuBtn(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 350),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isPrimary ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPrimary ? const Color(0xFFFFB300) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: isPrimary
                  ? const [
                      BoxShadow(color: Color(0x30FFB300), blurRadius: 14, offset: Offset(0, 4)),
                    ]
                  : const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPrimary ? Colors.black12 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.black87 : const Color(0xFF047857),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isPrimary ? Colors.black87 : const Color(0xFF0F172A),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: isPrimary ? Colors.black54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isPrimary ? Colors.black54 : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRulesGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        title: Text(
          'KUTHAKA RULES GUIDE',
          style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w900),
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _guideSection(Icons.flag_rounded, 'The Objective', 'Bankrupt your fellow players and become the supreme real estate tycoon across God\'s Own Country.'),
                _guideSection(Icons.casino_rounded, 'Starting Out', 'All players begin at "Naattile Thudakkam" with ₹1,50,000 cash. Passing Start awards ₹20,000.'),
                _guideSection(Icons.star_rounded, 'Monopolies', 'Acquire all lands in a color group (e.g. Kozhikode, Kochi, Munnar) to DOUBLE the base rent!'),
                _guideSection(Icons.cottage_rounded, 'Cottages & Resorts', 'Once you hold a monopoly, build up to 4 traditional Cottages, then upgrade to a luxury Resort for massive rent payouts!'),
                _guideSection(Icons.directions_bus_rounded, 'Transports & Utilities', 'Own KSRTC Stand, Kochi Metro, Ferry, and Airport for scaling travel fares. Utilities (KSEB, Water) charge based on dice rolls.'),
                _guideSection(Icons.local_police_rounded, 'Police Lockup', 'Landing on the Police Station sends you to Lockup at the Hospital. Pay ₹2,500 fine, use a card, or roll doubles to get out!'),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Widget _guideSection(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF047857)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12.5, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
