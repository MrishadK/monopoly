import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../../models/event_card.dart';
import '../../ui/theme/app_theme.dart';

class EventCardOverlay extends ConsumerWidget {
  const EventCardOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCard = ref.watch(gameProvider.select((s) => s.activeEventCard != null));
    if (!hasCard) return const SizedBox.shrink();

    return const RepaintBoundary(
      child: _EventCardOverlayContent(),
    );
  }
}

class _EventCardOverlayContent extends ConsumerWidget {
  const _EventCardOverlayContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final card = gameState.activeEventCard;

    if (card == null) return const SizedBox.shrink();

    final isDark = context.isDark;
    final isPositive = card.type == EventCardType.moneyReward || card.type == EventCardType.getOutOfJail;

    final accentColor = isPositive
        ? (isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark)
        : KuthakaColors.crimson;
    final accentBg = isPositive ? context.emeraldBg : context.crimsonBg;

    return Center(
      child: Container(
        width: 320,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accentColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.3 : 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            ...context.cardShadow,
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.verified_rounded : Icons.warning_amber_rounded,
                    size: 14,
                    color: accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPositive ? 'KERALA FORTUNE' : 'KERALA ADVERSITY',
                    style: GoogleFonts.outfit(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Material Icon Motif
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCardIcon(card),
                size: 42,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 14),

            // Card Title
            Text(
              card.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: context.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),

            // Card Description
            Text(
              card.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: context.textSecondary,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                  elevation: 0,
                ),
                onPressed: () {
                  ref.read(gameProvider.notifier).dismissEventCard();
                },
                child: Text(
                  'CONTINUE',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCardIcon(EventCard card) {
    if (card.title.contains('Monsoon')) return Icons.thunderstorm_rounded;
    if (card.title.contains('Onam')) return Icons.celebration_rounded;
    if (card.title.contains('Vishu')) return Icons.local_fire_department_rounded;
    if (card.title.contains('Jail')) return Icons.local_police_rounded;
    if (card.title.contains('Metro') || card.title.contains('Advance')) return Icons.directions_subway_rounded;
    if (card.title.contains('Lottery')) return Icons.stars_rounded;
    if (card.title.contains('Chaya')) return Icons.local_cafe_rounded;
    return Icons.description_rounded;
  }
}
