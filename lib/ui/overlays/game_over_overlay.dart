import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../../models/player.dart';
import '../../ui/theme/app_theme.dart';
import '../screens/home_screen.dart';

class GameOverOverlay extends ConsumerWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    if (gameState.phase != GamePhase.gameOver) return const SizedBox.shrink();

    final isDark = context.isDark;

    // Determine winner
    final sortedPlayers = List.from(gameState.players)
      ..sort((a, b) => b.calculateNetWorth(gameState.properties).compareTo(a.calculateNetWorth(gameState.properties)));
    
    final top3 = sortedPlayers.take(3).toList();
    final rest = sortedPlayers.skip(3).toList();

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: KuthakaColors.gold, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: KuthakaColors.gold.withValues(alpha: isDark ? 0.3 : 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            ...context.cardShadow,
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: isDark
                    ? [KuthakaColors.gold, KuthakaColors.emerald]
                    : [context.textPrimary, context.textPrimary],
              ).createShader(bounds),
              child: Text(
                'VICTORY!',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
            Text(
              'REAL ESTATE TYCOON OF KERALA',
              style: GoogleFonts.outfit(
                color: context.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),

            // Podium for Top 3
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rank 2 (Silver)
                  if (top3.length > 1) _buildPodiumStep(context, top3[1], 2, 100, const Color(0xFF94A3B8), gameState),
                  // Rank 1 (Gold)
                  if (top3.isNotEmpty) Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _buildPodiumStep(context, top3[0], 1, 140, KuthakaColors.gold, gameState),
                  ),
                  // Rank 3 (Bronze)
                  if (top3.length > 2) _buildPodiumStep(context, top3[2], 3, 70, const Color(0xFFB45309), gameState),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // List for 4,5,6
            if (rest.isNotEmpty) ...[
              Text(
                'OTHER STANDINGS',
                style: GoogleFonts.outfit(
                  color: context.textSecondary,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: rest.asMap().entries.map((entry) {
                      int rank = entry.key + 4;
                      var p = entry.value;
                      int netWorth = p.calculateNetWorth(gameState.properties);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text('#$rank', style: GoogleFonts.outfit(color: context.textSecondary, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Icon(p.tokenIcon, size: 16, color: p.color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.name,
                                style: GoogleFonts.outfit(
                                  color: p.isBankrupt ? context.textMuted : context.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              p.isBankrupt ? 'BANKRUPT' : '₹$netWorth',
                              style: GoogleFonts.outfit(
                                color: p.isBankrupt ? KuthakaColors.crimson : (isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 22),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ref.read(gameProvider.notifier).initializeGame(gameState.players);
                    },
                    child: Text('PLAY AGAIN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textPrimary,
                      side: BorderSide(color: context.borderColor),
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
                    child: Text('MAIN MENU', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumStep(BuildContext context, Player player, int rank, double height, Color color, GameState state) {
    final netWorth = player.calculateNetWorth(state.properties);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 26 : 20,
              backgroundColor: player.color,
              child: Icon(player.tokenIcon, size: rank == 1 ? 26 : 20, color: Colors.white),
            ),
            if (rank == 1)
              Positioned(
                top: -10,
                child: Icon(Icons.star_rounded, color: KuthakaColors.gold, size: 24),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          player.name.split(' ').first,
          style: GoogleFonts.outfit(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: rank == 1 ? 16 : 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '₹$netWorth',
          style: GoogleFonts.outfit(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: rank == 1 ? 14 : 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$rank',
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ),
      ],
    );
  }
}
