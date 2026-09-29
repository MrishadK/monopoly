import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../../models/property.dart';
import '../../models/player.dart';
import '../../data/game_data.dart';
import '../../services/user_profile_service.dart';
import '../../services/multiplayer_service.dart';

class PropertyCardOverlay extends ConsumerWidget {
  const PropertyCardOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final prop = gameState.inspectedProperty;

    if (prop == null) return const SizedBox.shrink();

    final current = gameState.currentPlayer;
    final myProfile = ref.watch(userProfileProvider);
    final multiplayer = ref.watch(multiplayerServiceProvider);
    final isOnline = multiplayer.isConnected;
    final isMyTurn = !isOnline || current.id == myProfile.id;

    final isLandedHere = current.position == _getPropertySpaceIndex(prop.id) &&
        gameState.phase == GamePhase.spaceAction &&
        current.type == PlayerType.human;

    final isOwnedByMe = prop.ownerId == current.id;
    final isUnowned = prop.ownerId == null;
    final owner = prop.ownerId != null
        ? gameState.players.firstWhere((p) => p.id == prop.ownerId, orElse: () => current)
        : null;

    final groupColor = _getGroupColor(prop.group);

    // Computed property states for action buttons - only allowed during active player's turn!
    final canBuild = isMyTurn && isOwnedByMe && prop.canUpgrade(gameState.properties, current.cash);
    final canSell = isMyTurn && isOwnedByMe && prop.currentLevel > 0;
    final canMortgage = isMyTurn && isOwnedByMe && !prop.isMortgaged && prop.currentLevel == 0;
    final canRedeem = isMyTurn && isOwnedByMe && prop.isMortgaged && current.cash >= prop.unmortgageCost;

    return Center(
      child: Container(
        width: 330,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x25000000), blurRadius: 25, offset: Offset(0, 8)),
          ],
        ),
        child: SingleChildScrollView(
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
                    // Current Level Badge
                    if (isOwnedByMe && prop.isBuildable && prop.currentLevel > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          prop.currentLevel == 5
                              ? '🏨 LUXURY RESORT'
                              : '🏠 ${prop.currentLevel} COTTAGE${prop.currentLevel > 1 ? "S" : ""}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    if (prop.isMortgaged) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⚠️ MORTGAGED',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
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
                              ? 'Transport Fare Scale:\n1 Transport: ₹15  •  2: ₹35\n3: ₹70  •  4: ₹135'
                              : 'Kerala Utility Tariff:\n1 Utility: 4× Dice Total (₹8 - ₹48)\n2 Utilities: 10× Dice Total (₹20 - ₹120)',
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

                    // ==================== ACTION BUTTONS ====================

                    // CASE 0: Spectator View (it is not this player's turn)
                    if (!isMyTurn) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.visibility_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'SPECTATOR VIEW • WAITING FOR ${current.name.toUpperCase()}\'S MOVE',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => ref.read(gameProvider.notifier).inspectProperty(null),
                          child: Text('CLOSE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ]

                    // CASE 1: Landed on UNOWNED property & my turn → Buy / Auction
                    else if (isLandedHere && isUnowned) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF047857),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: current.cash >= prop.price
                                  ? () => ref.read(gameProvider.notifier).buyProperty(prop.id)
                                  : null,
                              icon: const Icon(Icons.shopping_cart_rounded, size: 16),
                              label: Text(
                                'BUY ₹${prop.price}',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                ref.read(gameProvider.notifier).startAuction(prop.id);
                              },
                              icon: const Icon(Icons.gavel_rounded, size: 16),
                              label: Text(
                                'AUCTION',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                          // PASS Button removed as requested
                        ],
                      ),
                    ]

                    // CASE 2: Owned by current player → Build/Sell/Mortgage/Redeem actions
                    else if (isOwnedByMe) ...[
                      // Property Management Actions Grid
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'PROPERTY ACTIONS',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF64748B),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // BUILD (Upgrade)
                                Expanded(
                                  child: _actionButton(
                                    icon: Icons.add_home_rounded,
                                    label: prop.currentLevel == 4 ? 'RESORT' : 'BUILD',
                                    sublabel: '₹${prop.upgradeCost}',
                                    color: const Color(0xFF047857),
                                    enabled: canBuild,
                                    onTap: () => ref.read(gameProvider.notifier).upgradeProperty(prop.id),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // SELL (Downgrade)
                                Expanded(
                                  child: _actionButton(
                                    icon: Icons.sell_rounded,
                                    label: 'SELL',
                                    sublabel: canSell ? '+ ₹${prop.upgradeCost ~/ 2}' : '—',
                                    color: const Color(0xFFDC2626),
                                    enabled: canSell,
                                    onTap: () => ref.read(gameProvider.notifier).sellBuilding(prop.id),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // MORTGAGE
                                Expanded(
                                  child: _actionButton(
                                    icon: Icons.account_balance_rounded,
                                    label: 'MORTGAGE',
                                    sublabel: canMortgage ? '+ ₹${prop.mortgageValue}' : '—',
                                    color: const Color(0xFFD97706),
                                    enabled: canMortgage,
                                    onTap: () => ref.read(gameProvider.notifier).toggleMortgage(prop.id),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // REDEEM (Unmortgage)
                                Expanded(
                                  child: _actionButton(
                                    icon: Icons.replay_rounded,
                                    label: 'REDEEM',
                                    sublabel: prop.isMortgaged ? '₹${prop.unmortgageCost}' : '—',
                                    color: const Color(0xFF1565C0),
                                    enabled: canRedeem,
                                    onTap: () => ref.read(gameProvider.notifier).toggleMortgage(prop.id),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => ref.read(gameProvider.notifier).inspectProperty(null),
                          child: Text('CLOSE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ]

                    // CASE 3: Owned by someone else or browsing → Close only
                    else ...[
                      SizedBox(
                        width: double.infinity,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: enabled ? color : const Color(0xFFCBD5E1)),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: enabled ? color : const Color(0xFFCBD5E1),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              sublabel,
              style: GoogleFonts.outfit(
                color: enabled ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                fontSize: 9,
                fontWeight: FontWeight.w600,
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
    return GameData.spaces.indexWhere((s) => s.propertyId == propId);
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
