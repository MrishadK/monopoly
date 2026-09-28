import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../screens/home_screen.dart';

class GameOverOverlay extends ConsumerWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    if (gameState.phase != GamePhase.gameOver) return const SizedBox.shrink();

    // Determine winner
    final sortedPlayers = List.from(gameState.players)
      ..sort((a, b) => b.calculateNetWorth(gameState.properties).compareTo(a.calculateNetWorth(gameState.properties)));
    final winner = sortedPlayers.first;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFD97706), width: 2.5),
          boxShadow: const [
            BoxShadow(color: Color(0x35000000), blurRadius: 35, offset: Offset(0, 15)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 48),
            const SizedBox(height: 8),
            Text(
              'VICTORY!',
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            Text(
              'REAL ESTATE TYCOON OF KERALA',
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 18),

            // Winner Avatar Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: winner.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: winner.color, width: 2),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: winner.color,
                    child: Icon(winner.tokenIcon, size: 34, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    winner.name,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Total Wealth: ₹${winner.calculateNetWorth(gameState.properties)}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF047857),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Leaderboard
            Text(
              'FINAL STANDINGS',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...sortedPlayers.asMap().entries.map((entry) {
              int rank = entry.key + 1;
              var p = entry.value;
              int netWorth = p.calculateNetWorth(gameState.properties);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('#$rank', style: GoogleFonts.outfit(color: const Color(0xFFD97706), fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Icon(p.tokenIcon, size: 16, color: p.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.name,
                        style: GoogleFonts.outfit(
                          color: p.isBankrupt ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      p.isBankrupt ? 'BANKRUPT' : '₹$netWorth',
                      style: GoogleFonts.outfit(
                        color: p.isBankrupt ? const Color(0xFFDC2626) : const Color(0xFF047857),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
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
}
