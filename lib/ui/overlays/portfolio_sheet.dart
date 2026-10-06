import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/property.dart';
import '../../providers/game_provider.dart';
import '../../services/user_profile_service.dart';
import '../../services/multiplayer_service.dart';

class PortfolioSheet extends ConsumerWidget {
  const PortfolioSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final current = gameState.currentPlayer;
    final myProfile = ref.watch(userProfileProvider);
    final multiplayer = ref.watch(multiplayerServiceProvider);
    final isOnline = multiplayer.isConnected;
    final myLocalId = ref.watch(gameProvider.notifier).localPlayerId ?? myProfile.id;
    final isMyTurn = !isOnline || current.id == myLocalId;

    // Group properties by PropertyGroup
    final Map<PropertyGroup, List<Property>> grouped = {};
    for (final prop in gameState.properties.values) {
      grouped.putIfAbsent(prop.group, () => []).add(prop);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REAL ESTATE PORTFOLIO',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Cash: ${current.cash < 0 ? "-₹${-current.cash}" : "₹${current.cash}"}  •  Net Worth: ₹${current.calculateNetWorth(gameState.properties)}',
                      style: GoogleFonts.outfit(
                        color: current.cash < 0 ? const Color(0xFFEF4444) : const Color(0xFF475569),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (!isMyTurn)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'SPECTATOR VIEW • WAITING FOR ${current.name.toUpperCase()}\'S MOVE (45S)',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(color: Color(0xFFE2E8F0), height: 1),

          // Property Groups List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: grouped.entries.map((entry) {
                final group = entry.key;
                final props = entry.value;
                final isMyMonopoly = props.every((p) => p.ownerId == current.id);
                final groupColor = _getGroupColor(group);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMyMonopoly ? const Color(0xFFD97706) : const Color(0xFFE2E8F0),
                      width: isMyMonopoly ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Title Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: groupColor.withValues(alpha: 0.15),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          border: Border(bottom: BorderSide(color: groupColor, width: 2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getGroupName(group).toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1,
                              ),
                            ),
                            if (isMyMonopoly)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'MONOPOLY 2X',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Properties in Group
                      ...props.map((prop) {
                        final isOwnedByMe = prop.ownerId == current.id;
                        final owner = prop.ownerId != null
                            ? gameState.players.firstWhere((p) => p.id == prop.ownerId, orElse: () => current)
                            : null;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              // Building Badge
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isOwnedByMe
                                      ? current.color.withValues(alpha: 0.15)
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isOwnedByMe ? current.color : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Icon(
                                  prop.currentLevel == 5
                                      ? Icons.hotel_rounded
                                      : (prop.currentLevel > 0 ? Icons.home_rounded : Icons.location_on_rounded),
                                  color: isOwnedByMe ? current.color : const Color(0xFF64748B),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prop.name,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF0F172A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      owner != null
                                          ? (isOwnedByMe
                                              ? 'Rent: ₹${prop.getRent(gameState.properties, 7)}'
                                              : 'Owned by ${owner.name}')
                                          : 'Unowned • Cost: ₹${prop.price}',
                                      style: GoogleFonts.outfit(
                                        color: isOwnedByMe
                                            ? const Color(0xFF047857)
                                            : (owner != null ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (prop.isMortgaged)
                                      Text(
                                        'MORTGAGED',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFD97706),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Upgrade / Mortgage Controls - only allowed during active player's turn!
                              if (isOwnedByMe && isMyTurn) ...[
                                if (prop.canUpgrade(gameState.properties, current.cash))
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF047857),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                    onPressed: () => ref.read(gameProvider.notifier).upgradeProperty(prop.id),
                                    child: Text(
                                      prop.currentLevel == 4 ? '+RESORT (₹${prop.upgradeCost})' : '+HOUSE (₹${prop.upgradeCost})',
                                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: prop.isMortgaged ? const Color(0xFF047857) : const Color(0xFFD97706),
                                    side: BorderSide(
                                      color: prop.isMortgaged ? const Color(0xFF047857) : const Color(0xFFD97706),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () => ref.read(gameProvider.notifier).toggleMortgage(prop.id),
                                  child: Text(
                                    prop.isMortgaged ? 'UNMORTGAGE' : 'MORTGAGE',
                                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ] else if (isOwnedByMe && !isMyTurn) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    'LOCKED',
                                    style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getGroupName(PropertyGroup group) {
    switch (group) {
      case PropertyGroup.malabar: return 'Malabar Heritage (Brown)';
      case PropertyGroup.thrissur: return 'Thrissur Cultural (Sky Blue)';
      case PropertyGroup.kochi: return 'Kochi Urban (Coral Pink)';
      case PropertyGroup.backwaters: return 'Backwaters (Sunset Orange)';
      case PropertyGroup.highlands: return 'Highlands & Tea (Highlands Red)';
      case PropertyGroup.southKerala: return 'South Kerala Coast (Golden Yellow)';
      case PropertyGroup.premium: return 'Premium Eco Resorts (Emerald Green)';
      case PropertyGroup.luxury: return 'Kovalam Luxury (Royal Sapphire)';
      case PropertyGroup.transport: return 'Kerala Transports (Bus/Metro/Ferry/Air)';
      case PropertyGroup.utility: return 'State Utilities (KSEB / Water)';
    }
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
