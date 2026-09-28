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
    final human = profile.toPlayer(cash: 1000);
    const bot = Player(
      id: 'p2',
      name: 'Aadu Thoma',
      type: PlayerType.ai,
      token: PlayerToken.coconut,
      color: Color(0xFF0284C7),
      aiPersonality: AiPersonality.conservative,
      cash: 1000,
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
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.edit_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: profile.isCustom ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            profile.isCustom ? 'CUSTOM' : 'PROFILE',
                            style: GoogleFonts.outfit(
                              color: profile.isCustom ? const Color(0xFF047857) : const Color(0xFF92400E),
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

                // Logo Title - Responsive & guaranteed single line
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Builder(
                      builder: (context) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final double titleSize = (screenWidth * 0.12).clamp(32.0, 52.0);
                        final double spacing = (screenWidth * 0.016).clamp(3.0, 8.0);
                        return Text(
                          'KUTHAKA',
                          maxLines: 1,
                          softWrap: false,
                          style: GoogleFonts.outfit(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            letterSpacing: spacing,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'കുത്തക  •  A KERALA REAL ESTATE SAGA',
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                        letterSpacing: 2,
                      ),
                    ),
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
                  subtitle: 'Play as ${profile.name} vs Aadu Thoma',
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
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: Color(0xFF047857), size: 24),
            const SizedBox(width: 10),
            Text(
              'HOW TO PLAY KUTHAKA',
              style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _guideSection(Icons.flag_rounded, 'Objective of the Game', 'Become the wealthiest player across God\'s Own Country through buying, renting, and trading properties until opponents go bankrupt.'),
                _guideSection(Icons.account_balance_wallet_rounded, 'Starting Balance & GO (₹200)', 'All players begin with a ₹1,000 balance. Each time you land on or pass "Naattile Thudakkam" (GO), the Bank pays you a ₹200 salary.'),
                _guideSection(Icons.casino_rounded, 'Dice & Rolling Doubles', 'Roll two dice to move clockwise. Rolling matching numbers (Doubles) gives you an immediate extra turn! Roll doubles 3 times in a row and you go straight to Police Lockup.'),
                _guideSection(Icons.gavel_rounded, 'Buying Property & Auctions', 'Land on an unowned property to buy it from the Bank at printed price, or put it up for Auction. In auctions, the landing player bids first, and the highest bidder wins the Title Deed.'),
                _guideSection(Icons.payments_rounded, 'Paying Rent & Monopolies', 'Opponents pay rent when landing on your lands. Owning all properties in a complete color group (Monopoly) doubles the rent on unimproved properties.'),
                _guideSection(Icons.cottage_rounded, 'Cottages & Luxury Resorts', 'Once you hold a complete color group, build up to 4 traditional Cottages evenly across the properties, then upgrade to a luxury Resort for massive rent collection.'),
                _guideSection(Icons.directions_bus_rounded, 'Transports & Utilities', 'Own KSRTC Stand, Kochi Metro, Ferry, and Airport to scale travel fares (₹15 to ₹135). Utilities (KSEB, Water) collect rent based on dice rolls.'),
                _guideSection(Icons.local_police_rounded, 'Police Lockup (Jail)', 'Sent to Jail by landing on Police Station, drawing a card, or rolling 3 doubles. Get out by rolling doubles, using a "Get Out of Jail Free" card, or paying a ₹100 fine before rolling on either of your next two turns (mandatory after turn 3).'),
                _guideSection(Icons.account_balance_rounded, 'Mortgages (10% Interest)', 'Unimproved properties can be mortgaged to the Bank for cash (50% face value). Lift mortgages by repaying the mortgage value plus 10% interest. Mortgaged properties collect no rent.'),
                _guideSection(Icons.dangerous_rounded, 'Bankruptcy', 'You are declared bankrupt if you owe more debt than your cash and assets can cover. All assets are surrendered, and you retire from the match.'),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
