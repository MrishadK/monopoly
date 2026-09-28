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
      // If user hasn't set up their profile yet, show setup page first
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF04140D), Color(0xFF09291B), Color(0xFF020C08)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Ambient Decorative Watermark
              Positioned(
                bottom: -50,
                right: -50,
                child: Opacity(
                  opacity: 0.05,
                  child: Text(
                    '🌴',
                    style: const TextStyle(fontSize: 320),
                  ),
                ),
              ),

              Center(
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
                            color: profile.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: profile.color, width: 1.5),
                            boxShadow: [
                              BoxShadow(color: profile.color.withValues(alpha: 0.2), blurRadius: 10),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: profile.color,
                                child: Text(profile.toPlayer().tokenEmoji, style: const TextStyle(fontSize: 14)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                profile.name,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD54F),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'SETUP',
                                  style: TextStyle(
                                    color: Colors.black,
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

                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                        ),
                        child: Text(
                          '👑 GOD\'S OWN BOARD GAME',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFFD54F),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Generated Hero Banner Art
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 350),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 6)),
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
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFFD54F),
                          letterSpacing: 10,
                          shadows: [
                            const Shadow(color: Colors.black87, offset: Offset(4, 4), blurRadius: 15),
                            Shadow(color: const Color(0xFFFFD54F).withValues(alpha: 0.5), blurRadius: 25),
                          ],
                        ),
                      ),
                      Text(
                        'കുത്തക  •  A KERALA REAL ESTATE SAGA',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('⛵', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 14),
                          Text('🐘', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 14),
                          Text('🌴', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 14),
                          Text('🪔', style: TextStyle(fontSize: 22)),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // Menu Buttons
                      _buildMenuBtn(
                        context,
                        title: 'QUICK PLAY',
                        subtitle: 'Play as ${profile.name} vs Nihal (Bot)',
                        icon: Icons.play_arrow_rounded,
                        isPrimary: true,
                        onTap: () => _startQuickPlay(context, ref),
                      ),
                      const SizedBox(height: 14),

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
                      const SizedBox(height: 14),

                      _buildMenuBtn(
                        context,
                        title: 'ONLINE MULTIPLAYER',
                        subtitle: 'Host / Join 6-Digit Lobby (Voice Chat)',
                        icon: Icons.wifi_tethering_rounded,
                        isPrimary: false,
                        onTap: () => _openMultiplayer(context, ref),
                      ),
                      const SizedBox(height: 14),

                      _buildMenuBtn(
                        context,
                        title: 'HOW TO PLAY',
                        subtitle: 'Kerala Properties & Rules Guide',
                        icon: Icons.menu_book_rounded,
                        isPrimary: false,
                        onTap: () => _showRulesGuide(context),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'v1.0.0 • Made with Kerala Pride',
                        style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
      constraints: const BoxConstraints(maxWidth: 340),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.03)],
                    ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isPrimary ? const Color(0xFFFFD54F) : Colors.white24,
                width: 1.5,
              ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPrimary ? Colors.black12 : Colors.white10,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.black87 : const Color(0xFFFFD54F),
                    size: 26,
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
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: isPrimary ? Colors.black87 : Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: isPrimary ? Colors.black54 : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isPrimary ? Colors.black54 : Colors.white30,
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
        backgroundColor: const Color(0xFF0F241A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFFD54F), width: 2),
        ),
        title: Text(
          '🌴 KUTHAKA RULES GUIDE',
          style: GoogleFonts.outfit(color: const Color(0xFFFFD54F), fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _guideSection('🎲 The Objective', 'Bankrupt your fellow players and become the supreme real estate tycoon across God\'s Own Country.'),
                _guideSection('🚩 Starting Out', 'All players begin at "Naattile Thudakkam" with ₹1,50,000 cash. Passing Start awards ₹20,000.'),
                _guideSection('⭐ Monopolies', 'Acquire all lands in a color group (e.g. Kozhikode, Kochi, Munnar) to DOUBLE the base rent!'),
                _guideSection('🏠 Cottages & Resorts', 'Once you hold a monopoly, build up to 4 traditional Cottages, then upgrade to a luxury Resort for massive rent payouts!'),
                _guideSection('🚌 Transports & Utilities', 'Own KSRTC Stand, Kochi Metro, Ferry, and Airport for scaling travel fares. Utilities (KSEB, Water) charge based on dice rolls.'),
                _guideSection('👮 Police Lockup', 'Landing on the Police Station sends you to Lockup at the Hospital. Pay ₹2,500 fine, use a card, or roll doubles to get out!'),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('READY TO PLAY'),
          ),
        ],
      ),
    );
  }

  Widget _guideSection(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(desc, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12.5, height: 1.3)),
        ],
      ),
    );
  }
}
