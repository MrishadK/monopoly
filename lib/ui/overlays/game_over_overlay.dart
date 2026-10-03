import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../../models/player.dart';
import '../../ui/theme/app_theme.dart';
import '../screens/home_screen.dart';

class _PodiumData {
  final Player player;
  final int rank;
  const _PodiumData({required this.player, required this.rank});
}

class GameOverOverlay extends ConsumerWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGameOver = ref.watch(gameProvider.select((s) => s.phase == GamePhase.gameOver));
    if (!isGameOver) return const SizedBox.shrink();

    return const RepaintBoundary(
      child: _GameOverOverlayContent(),
    );
  }
}

class _GameOverOverlayContent extends ConsumerWidget {
  const _GameOverOverlayContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    if (gameState.phase != GamePhase.gameOver) return const SizedBox.shrink();

    final isDark = context.isDark;

    // Determine rankings by net worth
    final sortedPlayers = List<Player>.from(gameState.players)
      ..sort((a, b) => b.calculateNetWorth(gameState.properties).compareTo(a.calculateNetWorth(gameState.properties)));

    if (sortedPlayers.isEmpty) return const SizedBox.shrink();

    final winner = sortedPlayers.first;
    final top3 = sortedPlayers.take(3).toList();
    final rest = sortedPlayers.skip(3).toList();

    // Podium item arrangement:
    // 2 players: [Rank 1, Rank 2] side-by-side (natural 1st vs 2nd reading order)
    // 3+ players: [Rank 2, Rank 1, Rank 3] (Olympic center-elevated)
    final List<_PodiumData> podiumEntries;
    if (top3.length == 1) {
      podiumEntries = [_PodiumData(player: top3[0], rank: 1)];
    } else if (top3.length == 2) {
      podiumEntries = [
        _PodiumData(player: top3[0], rank: 1),
        _PodiumData(player: top3[1], rank: 2),
      ];
    } else {
      podiumEntries = [
        _PodiumData(player: top3[1], rank: 2),
        _PodiumData(player: top3[0], rank: 1),
        _PodiumData(player: top3[2], rank: 3),
      ];
    }

    final double basePlateWidth = podiumEntries.length == 1
        ? 130
        : (podiumEntries.length == 2 ? 230 : 310);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 660),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: KuthakaColors.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: KuthakaColors.gold.withValues(alpha: isDark ? 0.35 : 0.2),
              blurRadius: 36,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
            ...context.cardShadow,
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Celebratory Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 20, color: KuthakaColors.gold),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFEF3C7), Color(0xFFF59E0B)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: KuthakaColors.gold.withValues(alpha: 0.5),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 26,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.auto_awesome_rounded, size: 20, color: KuthakaColors.gold),
                  ],
                ),
                const SizedBox(height: 10),

                // Title (Single bold color, no gradient)
                Text(
                  'VICTORY!',
                  style: GoogleFonts.outfit(
                    color: isDark ? const Color(0xFFFFC107) : const Color(0xFFD97706),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'REAL ESTATE TYCOON OF KERALA',
                  style: GoogleFonts.outfit(
                    color: context.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),

                // Winner Spotlight Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? KuthakaColors.emerald.withValues(alpha: 0.18)
                        : KuthakaColors.emeraldSurfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👑 ', style: TextStyle(fontSize: 14)),
                      Flexible(
                        child: Text(
                          '${winner.name} is the Supreme Tycoon!',
                          style: GoogleFonts.outfit(
                            color: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── 3D Gamified Podium Row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < podiumEntries.length; i++) ...[
                      if (i > 0) SizedBox(width: podiumEntries.length == 2 ? 18 : 10),
                      _buildPodiumStep(
                        context: context,
                        player: podiumEntries[i].player,
                        rank: podiumEntries[i].rank,
                        isDark: isDark,
                        state: gameState,
                      ),
                    ],
                  ],
                ),

                // ── Shared Baseline Ground Stage Platform ──
                Container(
                  height: 10,
                  width: basePlateWidth,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF78350F),
                        Color(0xFFD97706),
                        Color(0xFFFDE68A),
                        Color(0xFFF59E0B),
                        Color(0xFF78350F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),

                // ── Runners Up (4, 5, 6) ──
                if (rest.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'RUNNERS UP',
                    style: GoogleFonts.outfit(
                      color: context.textSecondary,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (int r = 0; r < rest.length; r++) ...[
                    _buildRunnerUpTile(context, rest[r], r + 4, gameState, isDark),
                  ],
                ],

                const SizedBox(height: 22),

                // ── Action Buttons ──
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.replay_rounded, size: 18),
                        label: Text(
                          'PLAY AGAIN',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 3,
                        ),
                        onPressed: () {
                          ref.read(gameProvider.notifier).restartGame();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.home_rounded, size: 18, color: context.textPrimary),
                        label: Text(
                          'MAIN MENU',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            fontSize: 13,
                            color: context.textPrimary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.borderColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single podium step column (Avatar + Name + NetWorth + Pedestal Block)
  Widget _buildPodiumStep({
    required BuildContext context,
    required Player player,
    required int rank,
    required bool isDark,
    required GameState state,
  }) {
    final netWorth = player.calculateNetWorth(state.properties);

    // Dimensions calibrated by rank
    final double pedestalHeight = rank == 1 ? 96 : (rank == 2 ? 68 : 48);
    final double columnWidth = rank == 1 ? 96 : (rank == 2 ? 86 : 78);

    return SizedBox(
      width: columnWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Crown or Laurel Medal Slot
          SizedBox(
            height: 24,
            child: Center(
              child: _buildCrownOrMedal(rank),
            ),
          ),

          // Avatar with 3D glowing ring
          _buildPodiumAvatar(player: player, rank: rank, isDark: isDark),

          const SizedBox(height: 6),

          // Player Name + BOT badge if AI
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  player.name.split(' ').first,
                  style: GoogleFonts.outfit(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: rank == 1 ? 13 : 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (player.type == PlayerType.ai) ...[
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BOT',
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 4),

          // Net Worth Chip
          _buildNetWorthBadge(netWorth: netWorth, rank: rank, isDark: isDark),

          const SizedBox(height: 8),

          // 3D Pedestal Block resting on the baseline
          _buildPedestalBlock(
            rank: rank,
            width: columnWidth,
            height: pedestalHeight,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// Crown or Medal icon above the avatar
  Widget _buildCrownOrMedal(int rank) {
    if (rank == 1) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFFFFD700)),
          SizedBox(width: 2),
          Icon(Icons.workspace_premium_rounded, size: 22, color: Color(0xFFF59E0B)),
          SizedBox(width: 2),
          Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFFFFD700)),
        ],
      );
    } else if (rank == 2) {
      return const Icon(Icons.military_tech_rounded, size: 20, color: Color(0xFF94A3B8));
    } else {
      return const Icon(Icons.military_tech_outlined, size: 18, color: Color(0xFFB45309));
    }
  }

  /// Avatar with metallic border and glow
  Widget _buildPodiumAvatar({
    required Player player,
    required int rank,
    required bool isDark,
  }) {
    Color ringColor;
    Color glowColor;
    double radius;

    if (rank == 1) {
      ringColor = const Color(0xFFF59E0B);
      glowColor = const Color(0xFFFFD54F);
      radius = 26;
    } else if (rank == 2) {
      ringColor = const Color(0xFF94A3B8);
      glowColor = const Color(0xFFE2E8F0);
      radius = 22;
    } else {
      ringColor = const Color(0xFFEA580C);
      glowColor = const Color(0xFFFDBA74);
      radius = 20;
    }

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: rank == 1 ? 2.5 : 2.0),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: isDark ? 0.45 : 0.3),
            blurRadius: rank == 1 ? 12 : 6,
            spreadRadius: rank == 1 ? 1.5 : 0.5,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundImage: _getAvatarImage(player),
      ),
    );
  }

  /// Net worth chip styled per rank
  Widget _buildNetWorthBadge({
    required int netWorth,
    required int rank,
    required bool isDark,
  }) {
    Color bg;
    Color border;
    Color text;

    if (rank == 1) {
      bg = isDark ? const Color(0xFF3D2E0A) : const Color(0xFFFEF3C7);
      border = const Color(0xFFF59E0B);
      text = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
    } else if (rank == 2) {
      bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
      border = const Color(0xFF94A3B8);
      text = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    } else {
      bg = isDark ? const Color(0xFF3B1010) : const Color(0xFFFFEDD5);
      border = const Color(0xFFEA580C);
      text = isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border.withValues(alpha: 0.8), width: 1),
      ),
      child: Text(
        '₹$netWorth',
        style: GoogleFonts.outfit(
          color: text,
          fontSize: rank == 1 ? 12 : 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  /// 3D metallic pedestal block with embossed badge and stars
  Widget _buildPedestalBlock({
    required int rank,
    required double width,
    required double height,
    required bool isDark,
  }) {
    Color primaryHighlight;
    List<Color> gradientColors;
    Color borderColor;
    Color rankBadgeColor;

    if (rank == 1) {
      primaryHighlight = const Color(0xFFFFF9C4);
      gradientColors = isDark
          ? const [
              Color(0xFFF59E0B),
              Color(0xFFD97706),
              Color(0xFFB45309),
              Color(0xFF78350F),
            ]
          : const [
              Color(0xFFFFE082),
              Color(0xFFF59E0B),
              Color(0xFFD97706),
              Color(0xFFB45309),
            ];
      borderColor = const Color(0xFFFBBF24);
      rankBadgeColor = const Color(0xFFFEF3C7);
    } else if (rank == 2) {
      primaryHighlight = const Color(0xFFFFFFFF);
      gradientColors = isDark
          ? const [
              Color(0xFF94A3B8),
              Color(0xFF64748B),
              Color(0xFF475569),
              Color(0xFF1E293B),
            ]
          : const [
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
              Color(0xFFCBD5E1),
              Color(0xFF94A3B8),
            ];
      borderColor = const Color(0xFFCBD5E1);
      rankBadgeColor = const Color(0xFFF8FAFC);
    } else {
      primaryHighlight = const Color(0xFFFFEDD5);
      gradientColors = isDark
          ? const [
              Color(0xFFFB923C),
              Color(0xFFEA580C),
              Color(0xFF9A3412),
              Color(0xFF431407),
            ]
          : const [
              Color(0xFFFFEDD5),
              Color(0xFFFB923C),
              Color(0xFFEA580C),
              Color(0xFF9A3412),
            ];
      borderColor = const Color(0xFFFDBA74);
      rankBadgeColor = const Color(0xFFFFF7ED);
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        border: Border(
          top: BorderSide(color: primaryHighlight, width: 3.5),
          left: BorderSide(color: borderColor.withValues(alpha: 0.8), width: 1.5),
          right: BorderSide(color: borderColor.withValues(alpha: 0.8), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: (rank == 1
                    ? const Color(0xFFF59E0B)
                    : (rank == 2 ? const Color(0xFF94A3B8) : const Color(0xFFEA580C)))
                .withValues(alpha: isDark ? 0.35 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Embossed 3D Circular Rank Badge
          Container(
            width: rank == 1 ? 36 : 28,
            height: rank == 1 ? 36 : 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.22),
              border: Border.all(
                color: primaryHighlight.withValues(alpha: 0.9),
                width: 1.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: GoogleFonts.outfit(
                color: rankBadgeColor,
                fontSize: rank == 1 ? 20 : 16,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          // Mini star tier
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int s = 0; s < (4 - rank); s++)
                Icon(
                  Icons.star_rounded,
                  size: rank == 1 ? 11 : 9,
                  color: rank == 1 ? const Color(0xFFFFF59D) : Colors.white70,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Standings list tile for 4th, 5th, 6th place
  Widget _buildRunnerUpTile(BuildContext context, Player player, int rank, GameState state, bool isDark) {
    final netWorth = player.calculateNetWorth(state.properties);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardAltColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: context.borderColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: GoogleFonts.outfit(
                color: context.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 12,
            backgroundImage: _getAvatarImage(player),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.name,
              style: GoogleFonts.outfit(
                color: player.isBankrupt ? context.textMuted : context.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            player.isBankrupt ? 'BANKRUPT' : '₹$netWorth',
            style: GoogleFonts.outfit(
              color: player.isBankrupt
                  ? KuthakaColors.crimson
                  : (isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getAvatarImage(Player player) {
    final lower = player.name.toLowerCase();
    if (lower.contains('george') || player.token == PlayerToken.houseboat) {
      return const AssetImage('assets/images/avatar_houseboat.jpg');
    } else if (lower.contains('aadu') || lower.contains('thoma') || player.token == PlayerToken.coconut) {
      return const AssetImage('assets/images/avatar_kathakali.jpg');
    } else if (player.token == PlayerToken.elephant) {
      return const AssetImage('assets/images/app_logo.jpg');
    }
    return const AssetImage('assets/images/kuthaka_medallion.jpg');
  }
}
