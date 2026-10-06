import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';
import '../../services/user_profile_service.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/theme_provider.dart';
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
        MaterialPageRoute(
          builder: (_) => const UserProfileScreen(isInitialSetup: true),
        ),
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
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Atmospheric Kerala background artwork
          Image.asset(
            isDark ? 'assets/images/bg_dark.jpg' : 'assets/images/bg_light.jpg',
            fit: BoxFit.cover,
          ),
          // Gradient scrim overlay for contrast and depth
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF0C0C12).withValues(alpha: 0.84),
                        const Color(0xFF0C0C12).withValues(alpha: 0.70),
                        const Color(0xFF0C0C12).withValues(alpha: 0.88),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.88),
                        Colors.white.withValues(alpha: 0.76),
                        Colors.white.withValues(alpha: 0.92),
                      ],
              ),
            ),
          ),
          // Foreground Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ─── TOP BAR: User Badge + Theme Toggle ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // User Identity Badge
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserProfileScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: context.borderColor,
                            width: 1.5,
                          ),
                          boxShadow: context.subtleShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: profile.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: profile.color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                profile.toPlayer().tokenIcon,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              profile.name,
                              style: GoogleFonts.outfit(
                                color: context.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_rounded,
                              size: 13,
                              color: context.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Theme Toggle
                    _ThemeToggleButton(),
                  ],
                ),
                const SizedBox(height: 20),

                // ─── SUBTITLE BADGE ───
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.emeraldBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: KuthakaColors.emerald.withValues(alpha: isDark ? 0.4 : 1.0),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'GOD\'S OWN BOARD GAME',
                    style: GoogleFonts.outfit(
                      color: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── HERO BANNER ───
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 350),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: context.borderColor,
                        width: 1.5,
                      ),
                      boxShadow: context.cardShadow,
                    ),
                    child: Image.asset(
                      'assets/images/kuthaka_banner.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── LOGO TITLE ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Builder(
                      builder: (context) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final double titleSize = (screenWidth * 0.12).clamp(
                          32.0,
                          52.0,
                        );
                        final double spacing = (screenWidth * 0.016).clamp(
                          3.0,
                          8.0,
                        );
                        return Text(
                          'KUTHAKA',
                          maxLines: 1,
                          softWrap: false,
                          style: GoogleFonts.outfit(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xFFFFC107) : const Color(0xFF0F172A),
                            letterSpacing: spacing,
                            shadows: isDark
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFFC107).withValues(alpha: 0.30),
                                      blurRadius: 18,
                                    ),
                                  ]
                                : null,
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
                        color: context.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _accentIcon(Icons.sailing_rounded, isDark),
                    const SizedBox(width: 16),
                    _accentIcon(Icons.pets_rounded, isDark),
                    const SizedBox(width: 16),
                    _accentIcon(Icons.forest_rounded, isDark),
                    const SizedBox(width: 16),
                    _accentIcon(Icons.local_fire_department_rounded, isDark),
                  ],
                ),
                const SizedBox(height: 28),

                // ─── MENU BUTTONS ───
                _KuthakaMenuBtn(
                  title: 'QUICK PLAY',
                  subtitle: 'Play as ${profile.name} vs Aadu Thoma',
                  icon: Icons.play_arrow_rounded,
                  isPrimary: true,
                  onTap: () => _startQuickPlay(context, ref),
                ),
                const SizedBox(height: 12),

                _KuthakaMenuBtn(
                  title: 'LOCAL GAME SETUP',
                  subtitle: '2-4 Players & Custom AI Personalities',
                  icon: Icons.groups_rounded,
                  isPrimary: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LocalSetupScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _KuthakaMenuBtn(
                  title: 'ONLINE MULTIPLAYER',
                  subtitle: 'Live Rooms & Voice Streaming',
                  icon: Icons.wifi_tethering_rounded,
                  isPrimary: false,
                  onTap: () => _openMultiplayer(context, ref),
                ),
                const SizedBox(height: 12),

                _KuthakaMenuBtn(
                  title: 'KERALA TYCOONS',
                  subtitle: 'Global Kerala Hall of Fame',
                  icon: Icons.leaderboard_rounded,
                  isPrimary: false,
                  onTap: () => _openLeaderboard(context),
                ),
                const SizedBox(height: 12),

                _KuthakaMenuBtn(
                  title: 'HOW TO PLAY',
                  subtitle: 'Kerala Properties & Rules Guide',
                  icon: Icons.menu_book_rounded,
                  isPrimary: false,
                  onTap: () => _showRulesGuide(context),
                ),
                const SizedBox(height: 20),

                Text(
                  'v1.0.7 • Made with Kerala Pride',
                  style: GoogleFonts.outfit(
                    color: context.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
);
  }

  Widget _accentIcon(IconData icon, bool isDark) {
    return Icon(
      icon,
      color: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark,
      size: 20,
    );
  }

  void _showRulesGuide(BuildContext context) {
    final isDark = context.isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: context.borderColor, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(
              Icons.menu_book_rounded,
              color: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'HOW TO PLAY KUTHAKA',
              style: GoogleFonts.outfit(
                color: context.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _guideSection(context, Icons.flag_rounded, 'Objective of the Game',
                  'Become the wealthiest player across God\'s Own Country through buying, renting, and trading properties until opponents go bankrupt.'),
                _guideSection(context, Icons.account_balance_wallet_rounded, 'Starting Balance & GO (₹200)',
                  'All players begin with a ₹1,000 balance. Each time you land on or pass "Naattile Thudakkam" (GO), the Bank pays you a ₹200 salary.'),
                _guideSection(context, Icons.casino_rounded, 'Dice & Rolling Doubles',
                  'Roll two dice to move clockwise. Rolling matching numbers (Doubles) gives you an immediate extra turn! Roll doubles 3 times in a row and you go straight to Police Lockup.'),
                _guideSection(context, Icons.gavel_rounded, 'Buying Property & Auctions',
                  'Land on an unowned property to buy it from the Bank at printed price, or put it up for Auction. In auctions, the landing player bids first, and the highest bidder wins the Title Deed.'),
                _guideSection(context, Icons.payments_rounded, 'Paying Rent & Monopolies',
                  'Opponents pay rent when landing on your lands. Owning all properties in a complete color group (Monopoly) doubles the rent on unimproved properties.'),
                _guideSection(context, Icons.cottage_rounded, 'Cottages & Luxury Resorts',
                  'Once you hold a complete color group, build up to 4 traditional Cottages evenly across the properties, then upgrade to a luxury Resort for massive rent collection.'),
                _guideSection(context, Icons.directions_bus_rounded, 'Transports & Utilities',
                  'Own KSRTC Stand, Kochi Metro, Ferry, and Airport to scale travel fares (₹15 to ₹135). Utilities (KSEB, Water) collect rent based on dice rolls.'),
                _guideSection(context, Icons.local_police_rounded, 'Police Lockup (Jail)',
                  'Sent to Jail by landing on Police Station, drawing a card, or rolling 3 doubles. Get out by rolling doubles, using a "Get Out of Jail Free" card, or paying a ₹100 fine before rolling on either of your next two turns (mandatory after turn 3).'),
                _guideSection(context, Icons.account_balance_rounded, 'Mortgages (10% Interest)',
                  'Unimproved properties can be mortgaged to the Bank for cash (50% face value). Lift mortgages by repaying the mortgage value plus 10% interest. Mortgaged properties collect no rent.'),
                _guideSection(context, Icons.dangerous_rounded, 'Bankruptcy',
                  'You are declared bankrupt if you owe more debt than your cash and assets can cover. All assets are surrendered, and you retire from the match.'),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Widget _guideSection(BuildContext context, IconData icon, String title, String desc) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.emeraldBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: context.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    color: context.textSecondary,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── THEME TOGGLE BUTTON ───
class _ThemeToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 56,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E1E2A), const Color(0xFF252533)]
                : [const Color(0xFFFEF3C7), const Color(0xFFFFE4A0)],
          ),
          border: Border.all(
            color: isDark ? KuthakaColors.emerald.withValues(alpha: 0.4) : KuthakaColors.goldDark.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? KuthakaColors.emerald.withValues(alpha: 0.15)
                  : KuthakaColors.gold.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? KuthakaColors.emerald : KuthakaColors.goldDark,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? KuthakaColors.emerald : KuthakaColors.goldDark).withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── MENU BUTTON ───
class _KuthakaMenuBtn extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _KuthakaMenuBtn({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

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
                  ? LinearGradient(
                      colors: isDark
                          ? [KuthakaColors.emerald, const Color(0xFF059669)]
                          : [const Color(0xFFFFD54F), const Color(0xFFFFB300)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isPrimary ? null : context.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPrimary
                    ? (isDark ? KuthakaColors.emerald : const Color(0xFFFFB300))
                    : context.borderColor,
                width: 1.5,
              ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: (isDark ? KuthakaColors.emerald : const Color(0xFFFFB300))
                            .withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : context.subtleShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: isDark ? 0.15 : 0.25)
                        : context.emeraldBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark),
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
                          color: isPrimary
                              ? (isDark ? Colors.white : Colors.black87)
                              : context.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: isPrimary
                              ? (isDark ? Colors.white70 : Colors.black54)
                              : context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isPrimary
                      ? (isDark ? Colors.white54 : Colors.black54)
                      : context.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
