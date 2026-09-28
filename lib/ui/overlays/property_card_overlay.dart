import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../../models/property.dart';
import '../../models/player.dart';

class PropertyCardOverlay extends ConsumerWidget {
  const PropertyCardOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final prop = gameState.inspectedProperty;

    if (prop == null) return const SizedBox.shrink();

    final current = gameState.currentPlayer;
    final isLandedHere = current.position == _getPropertySpaceIndex(prop.id) &&
        gameState.phase == GamePhase.spaceAction &&
        current.type == PlayerType.human;

    final isOwnedByMe = prop.ownerId == current.id;
    final isUnowned = prop.ownerId == null;
    final owner = prop.ownerId != null
        ? gameState.players.firstWhere((p) => p.id == prop.ownerId, orElse: () => current)
        : null;

    final groupColor = _getGroupColor(prop.group);

    return Center(
      child: Container(
        width: 320,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x25000000), blurRadius: 25, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Color Strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: groupColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                children: [
                  Text(
                    'KUTHAKA TITLE DEED',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prop.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Price Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PURCHASE PRICE',
                        style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${prop.price}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF047857),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE2E8F0)),

                  // Rent Table
                  if (prop.isBuildable) ...[
                    _rentRow('Base Rent', prop.rent[0], isBold: prop.currentLevel == 0 && !prop.isMonopoly(gameState.properties)),
                    _rentRow('Monopoly (Color Group)', prop.rent[0] * 2, isBold: prop.currentLevel == 0 && prop.isMonopoly(gameState.properties)),
                    _rentRow('With 1 Cottage', prop.rent[1], isBold: prop.currentLevel == 1),
                    _rentRow('With 2 Cottages', prop.rent[2], isBold: prop.currentLevel == 2),
                    _rentRow('With 3 Cottages', prop.rent[3], isBold: prop.currentLevel == 3),
                    _rentRow('With 4 Cottages', prop.rent[4], isBold: prop.currentLevel == 4),
                    _rentRow('With Luxury Resort', prop.rent[5], isBold: prop.currentLevel == 5, highlight: true),
                    const Divider(color: Color(0xFFE2E8F0)),
                    _rentRow('Cottage / Resort Upgrade', prop.upgradeCost),
                    _rentRow('Mortgage Value', prop.mortgageValue),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        prop.isTransport
                            ? 'Transport Scale:\n1 Station: ₹2,500  •  2: ₹5,000\n3: ₹10,000  •  4: ₹20,000'
                            : 'Utility Scale:\n1 Utility: 400x Dice Roll\n2 Utilities: 1000x Dice Roll',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: const Color(0xFF334155), fontSize: 13, height: 1.4),
                      ),
                    ),
                    const Divider(color: Color(0xFFE2E8F0)),
                    _rentRow('Mortgage Value', prop.mortgageValue),
                  ],

                  const SizedBox(height: 12),

                  // Ownership Tag
                  if (owner != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: owner.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: owner.color),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(owner.tokenIcon, size: 16, color: owner.color),
                          const SizedBox(width: 8),
                          Text(
                            isOwnedByMe ? 'YOU OWN THIS PROPERTY' : 'OWNED BY ${owner.name.toUpperCase()}',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Actions
                  if (isLandedHere && isUnowned) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF047857),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: current.cash >= prop.price
                                ? () => ref.read(gameProvider.notifier).buyProperty(prop.id)
                                : null,
                            child: Text(
                              'BUY ₹${prop.price}',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => ref.read(gameProvider.notifier).passProperty(),
                            child: Text('PASS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        if (isOwnedByMe && prop.canUpgrade(gameState.properties, current.cash)) ...[
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF047857),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => ref.read(gameProvider.notifier).upgradeProperty(prop.id),
                              child: Text(
                                prop.currentLevel == 4 ? '+ RESORT' : '+ COTTAGE',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => ref.read(gameProvider.notifier).inspectProperty(null),
                            child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rentRow(String title, int amount, {bool isBold = false, bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFFEF3C7)
            : (isBold ? const Color(0xFFF1F5F9) : Colors.transparent),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: highlight ? const Color(0xFF92400E) : const Color(0xFF334155),
              fontSize: 12.5,
              fontWeight: (isBold || highlight) ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹$amount',
            style: GoogleFonts.outfit(
              color: highlight ? const Color(0xFF92400E) : const Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: (isBold || highlight) ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  int _getPropertySpaceIndex(String propId) {
    return 0;
  }

  Color _getGroupColor(PropertyGroup group) {
    switch (group) {
      case PropertyGroup.malabar: return const Color(0xFF8D5524);
      case PropertyGroup.thrissur: return const Color(0xFF0288D1);
      case PropertyGroup.kochi: return const Color(0xFFD81B60);
      case PropertyGroup.backwaters: return const Color(0xFFF57C00);
      case PropertyGroup.highlands: return const Color(0xFFD32F2F);
      case PropertyGroup.southKerala: return const Color(0xFFFBC02D);
      case PropertyGroup.premium: return const Color(0xFF2E7D32);
      case PropertyGroup.luxury: return const Color(0xFF1565C0);
      case PropertyGroup.transport: return const Color(0xFF546E7A);
      case PropertyGroup.utility: return const Color(0xFF78909C);
    }
  }
}
