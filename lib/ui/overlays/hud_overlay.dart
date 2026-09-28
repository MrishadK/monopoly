import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/kuthaka_game.dart';
import '../../providers/game_provider.dart';
import '../../models/player.dart';
import '../../services/voice_stream_service.dart';
import 'portfolio_sheet.dart';
import 'trade_dialog.dart';
import 'game_menu_dialog.dart';

class HudOverlay extends ConsumerStatefulWidget {
  final KuthakaGame game;
  final WidgetRef ref;

  const HudOverlay({super.key, required this.game, required this.ref});

  @override
  ConsumerState<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends ConsumerState<HudOverlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final players = ref.read(gameProvider).players;
      final human = players.firstWhere((p) => p.type == PlayerType.human, orElse: () => players.first);
      ref.read(voiceStreamServiceProvider.notifier).connectToVoiceRoom('kuthaka_live', human.id, human.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final currentPlayer = gameState.currentPlayer;
    final voiceService = ref.watch(voiceStreamServiceProvider);

    return Stack(
      children: [
        // ==================== TOP PLAYER STATUS BAR ====================
        Positioned(
          top: 8,
          left: 10,
          right: 10,
          child: Column(
            children: [
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: gameState.players.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final player = gameState.players[index];
                    final isTurn = index == gameState.currentPlayerIndex;
                    final isSpeaking = player.type == PlayerType.human
                        ? voiceService.isSpeaking
                        : (voiceService.participants[player.id]?.isSpeaking ?? false);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTurn ? player.color.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSpeaking
                              ? const Color(0xFF10B981)
                              : (isTurn ? player.color : const Color(0xFFE2E8F0)),
                          width: (isSpeaking || isTurn) ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: player.color,
                                child: Icon(player.tokenIcon, color: Colors.white, size: 18),
                              ),
                              if (isSpeaking)
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.mic_rounded, size: 10, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    player.name,
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF0F172A),
                                      fontWeight: isTurn ? FontWeight.w900 : FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (player.type == PlayerType.ai)
                                    const Text(' (Bot)', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                                  if (player.isInJail)
                                    const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFDC2626)),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '₹${player.cash}',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF047857),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.home_work_rounded, size: 12, color: Color(0xFF64748B)),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${player.ownedPropertyIds.length}',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (isTurn) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD54F),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'TURN',
                                style: GoogleFonts.outfit(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Voice Stream & Turn Notification Bar
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Live Voice Stream Status Pill
                    InkWell(
                      onTap: () => ref.read(voiceStreamServiceProvider.notifier).toggleMic(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: voiceService.isMicMuted ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0C000000), blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              voiceService.isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                              size: 14,
                              color: voiceService.isMicMuted ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              voiceService.isMicMuted ? 'VOICE MUTED' : 'LIVE VOICE',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1E293B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!voiceService.isMicMuted) ...[
                              const SizedBox(width: 4),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Notification Banner
                    if (gameState.message != null)
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (gameState.isAiThinking) ...[
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  gameState.message!,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF92400E),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ==================== BOTTOM CONTROLS & ACTION BAR ====================
        Positioned(
          bottom: 8,
          left: 10,
          right: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Turn Button
              _buildMainActionButton(context, gameState, currentPlayer),

              const SizedBox(height: 8),

              // Bottom Navigation Dock
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _dockButton(
                      icon: Icons.holiday_village_rounded,
                      title: 'Properties',
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const PortfolioSheet(),
                        );
                      },
                    ),
                    _dockButton(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Trade',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const TradeDialog(),
                        );
                      },
                    ),
                    _dockButton(
                      icon: Icons.history_edu_rounded,
                      title: 'Logs',
                      onTap: () => _showLogsDialog(context, gameState),
                    ),
                    _dockButton(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const GameMenuDialog(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainActionButton(BuildContext context, GameState gameState, Player current) {
    if (current.type == PlayerType.ai) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 6)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)),
            ),
            const SizedBox(width: 10),
            Text(
              '${current.name} is thinking...',
              style: GoogleFonts.outfit(color: const Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // Human Player Turn
    if (gameState.phase == GamePhase.roll) {
      if (current.isInJail) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF59E0B)),
            boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 8)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
                onPressed: current.cash >= 2500 ? () => ref.read(gameProvider.notifier).payJailBail() : null,
                icon: const Icon(Icons.payment_rounded, size: 16),
                label: Text('PAY ₹2,500', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              if (current.getOutOfJailCards > 0) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                  onPressed: () => ref.read(gameProvider.notifier).useJailCard(),
                  icon: const Icon(Icons.card_membership_rounded, size: 16),
                  label: Text('USE CARD', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                onPressed: () => ref.read(gameProvider.notifier).rollDice(),
                icon: const Icon(Icons.casino_rounded, size: 16),
                label: Text('ROLL DOUBLES', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }

      // Normal Roll Button
      return InkWell(
        onTap: () => ref.read(gameProvider.notifier).rollDice(),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: Color(0x35FFB300), blurRadius: 14, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.casino_rounded, color: Colors.black87, size: 22),
              const SizedBox(width: 10),
              Text(
                'ROLL DICE',
                style: GoogleFonts.outfit(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (gameState.phase == GamePhase.turnEnd || gameState.phase == GamePhase.spaceAction) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00695C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 4,
        ),
        onPressed: () => ref.read(gameProvider.notifier).endTurn(),
        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: Text(
          'END TURN',
          style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _dockButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF0F172A), size: 20),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.outfit(color: const Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogsDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.history_edu_rounded, color: Color(0xFF0F172A)),
            const SizedBox(width: 8),
            Text(
              'GAME LOGS',
              style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 340,
          height: 380,
          child: ListView.separated(
            itemCount: gameState.gameLogs.length,
            separatorBuilder: (_, _) => const Divider(color: Color(0xFFE2E8F0), height: 1),
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  gameState.gameLogs[i],
                  style: GoogleFonts.outfit(color: const Color(0xFF334155), fontSize: 13, height: 1.3),
                ),
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}
