import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../widgets/dice_widget.dart';

class DiceRollOverlay extends ConsumerWidget {
  const DiceRollOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final isRolling = gameState.isRollingDice;
    final isMoving = gameState.phase == GamePhase.moving;
    final lastDice = gameState.lastDiceRoll;

    // Show center hero animation when rolling or right as pawn begins moving
    final shouldShow = isRolling || isMoving;

    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: shouldShow ? 1.0 : 0.0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFC5A049), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TumblingDicePairWidget(
                  dice: lastDice,
                  isRolling: isRolling,
                  isDoubles: gameState.isDoubles,
                  diceSize: 58.0,
                ),
                const SizedBox(height: 10),
                if (isRolling) ...[
                  Text(
                    'ROLLING...',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF92400E),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF133E2B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${lastDice[0]} + ${lastDice[1]} = ${lastDice[0] + lastDice[1]}',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFFD54F),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      if (gameState.isDoubles) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC62828),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'DOUBLES!',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
