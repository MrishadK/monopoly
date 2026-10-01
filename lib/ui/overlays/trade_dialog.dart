import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../models/property.dart';
import '../../models/trade_offer.dart';
import '../../providers/game_provider.dart';
import '../../services/user_profile_service.dart';
import '../../services/multiplayer_service.dart';

class TradeDialog extends ConsumerStatefulWidget {
  const TradeDialog({super.key});

  @override
  ConsumerState<TradeDialog> createState() => _TradeDialogState();
}

class _TradeDialogState extends ConsumerState<TradeDialog> {
  Player? _selectedTarget;
  final Set<String> _offeredProps = {};
  final Set<String> _requestedProps = {};
  int _offeredCash = 0;
  int _requestedCash = 0;

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
      case PropertyGroup.utility: return const Color(0xFF00897B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final currentPlayer = gameState.currentPlayer;
    final myProfile = ref.watch(userProfileProvider);
    final multiplayer = ref.watch(multiplayerServiceProvider);
    final isOnline = multiplayer.isConnected || multiplayer.activeRoomId != null;
    final myLocalId = ref.watch(gameProvider.notifier).localPlayerId ?? myProfile.id;

    // Strict validation: Only the currently active player can propose trades
    final isCurrentlyPlaying = currentPlayer.type == PlayerType.human &&
        (!isOnline || currentPlayer.id == myLocalId);

    if (!isCurrentlyPlaying) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'TRADE RESTRICTED',
          style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        content: Text(
          currentPlayer.type == PlayerType.ai
              ? 'Trading is paused while ${currentPlayer.name} (AI) is playing.'
              : 'Only the player currently playing (${currentPlayer.name}) can make trades during their turn.',
          style: GoogleFonts.outfit(color: const Color(0xFF475569)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      );
    }

    final myPlayer = currentPlayer;
    final otherPlayers = gameState.players.where((p) => p.id != myPlayer.id && !p.isBankrupt).toList();

    _selectedTarget ??= otherPlayers.isNotEmpty ? otherPlayers.first : null;

    if (_selectedTarget == null) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('TRADE', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        content: Text('No other active players to trade with.', style: GoogleFonts.outfit(color: const Color(0xFF475569))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      );
    }

    // Ensure selected target is still valid
    final target = otherPlayers.firstWhere((p) => p.id == _selectedTarget!.id, orElse: () => otherPlayers.first);
    if (_selectedTarget!.id != target.id) {
      _selectedTarget = target;
    }

    // Clamp cash values
    if (_offeredCash > myPlayer.cash) _offeredCash = myPlayer.cash;
    if (_requestedCash > target.cash) _requestedCash = target.cash;

    final myProps = myPlayer.ownedPropertyIds
        .map((id) => gameState.properties[id])
        .whereType<Property>()
        .toList();
    final targetProps = target.ownedPropertyIds
        .map((id) => gameState.properties[id])
        .whereType<Property>()
        .toList();

    // Clean up selections that are no longer owned or no longer tradeable
    _offeredProps.removeWhere((id) {
      final p = gameState.properties[id];
      return p == null || p.ownerId != myPlayer.id || !p.isTradeable(gameState.properties);
    });
    _requestedProps.removeWhere((id) {
      final p = gameState.properties[id];
      return p == null || p.ownerId != target.id || !p.isTradeable(gameState.properties);
    });

    final hasTradeContent = _offeredCash > 0 || _requestedCash > 0 ||
        _offeredProps.isNotEmpty || _requestedProps.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: Color(0xFF0F172A), size: 26),
                    const SizedBox(width: 8),
                    Text(
                      'PROPOSE TRADE',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE2E8F0)),

            // Target Player Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Text(
                    'Trade Partner: ',
                    style: GoogleFonts.outfit(color: const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: target.id,
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                        items: otherPlayers.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Row(
                              children: [
                                Icon(p.tokenIcon, color: p.color, size: 18),
                                const SizedBox(width: 6),
                                Text(p.name, style: TextStyle(color: p.color, fontWeight: FontWeight.bold)),
                                Text(
                                  p.type == PlayerType.ai ? ' (Bot - ₹${p.cash})' : ' (Human - ₹${p.cash})',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newId) {
                          if (newId != null) {
                            setState(() {
                              _selectedTarget = otherPlayers.firstWhere((p) => p.id == newId);
                              _requestedProps.clear();
                              _requestedCash = 0;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Two Columns: YOU (Give) vs OTHER PLAYER (Get)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column 1: YOU
                  Expanded(
                    child: _buildPlayerTradeColumn(
                      playerTitle: 'YOU (${myPlayer.name})',
                      sectionSubtitle: 'What you are giving',
                      accentColor: const Color(0xFFD97706),
                      cashBalance: myPlayer.cash,
                      selectedCash: _offeredCash,
                      onCashChanged: (val) => setState(() => _offeredCash = val),
                      properties: myProps,
                      selectedPropertyIds: _offeredProps,
                      onPropertyToggled: (pId, checked) {
                        setState(() {
                          checked ? _offeredProps.add(pId) : _offeredProps.remove(pId);
                        });
                      },
                      allProperties: gameState.properties,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Column 2: OTHER PLAYER
                  Expanded(
                    child: _buildPlayerTradeColumn(
                      playerTitle: target.name.toUpperCase(),
                      sectionSubtitle: 'What they are giving',
                      accentColor: const Color(0xFF059669),
                      cashBalance: target.cash,
                      selectedCash: _requestedCash,
                      onCashChanged: (val) => setState(() => _requestedCash = val),
                      properties: targetProps,
                      selectedPropertyIds: _requestedProps,
                      onPropertyToggled: (pId, checked) {
                        setState(() {
                          checked ? _requestedProps.add(pId) : _requestedProps.remove(pId);
                        });
                      },
                      allProperties: gameState.properties,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasTradeContent ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: hasTradeContent ? 2 : 0,
                ),
                onPressed: hasTradeContent
                    ? () {
                        final offer = TradeOffer(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          senderId: myPlayer.id,
                          receiverId: target.id,
                          offeredCash: _offeredCash,
                          offeredPropertyIds: _offeredProps.toList(),
                          requestedCash: _requestedCash,
                          requestedPropertyIds: _requestedProps.toList(),
                          status: TradeStatus.pending,
                        );

                        ref.read(gameProvider.notifier).proposeTrade(offer);
                        Navigator.pop(context);
                      }
                    : null,
                child: Text(
                  hasTradeContent ? 'PROPOSE TRADE' : 'SELECT CASH OR PROPERTIES',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTradeColumn({
    required String playerTitle,
    required String sectionSubtitle,
    required Color accentColor,
    required int cashBalance,
    required int selectedCash,
    required ValueChanged<int> onCashChanged,
    required List<Property> properties,
    required Set<String> selectedPropertyIds,
    required void Function(String propertyId, bool isSelected) onPropertyToggled,
    required Map<String, Property> allProperties,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Text(
            playerTitle,
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sectionSubtitle,
            style: GoogleFonts.outfit(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),

          // Cash Selector Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cash: ₹$selectedCash',
                      style: GoogleFonts.outfit(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Available: ₹$cashBalance',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: accentColor,
                    thumbColor: accentColor,
                    inactiveTrackColor: accentColor.withValues(alpha: 0.15),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: selectedCash.clamp(0, cashBalance).toDouble(),
                    min: 0,
                    max: cashBalance > 0 ? cashBalance.toDouble() : 1.0,
                    divisions: cashBalance > 0 ? (cashBalance >= 50 ? 50 : cashBalance) : 1,
                    onChanged: cashBalance > 0
                        ? (val) => onCashChanged(val.toInt())
                        : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Properties list header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Properties (${properties.length}):',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
              if (selectedPropertyIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${selectedPropertyIds.length} selected',
                    style: GoogleFonts.outfit(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Properties ListView
          Expanded(
            child: properties.isEmpty
                ? Center(
                    child: Text(
                      'No properties owned',
                      style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.separated(
                    itemCount: properties.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 4),
                    itemBuilder: (context, idx) {
                      final p = properties[idx];
                      final isTradeable = p.isTradeable(allProperties);
                      final isSelected = selectedPropertyIds.contains(p.id);
                      final groupColor = _getGroupColor(p.group);

                      return _buildPropertyItem(
                        property: p,
                        groupColor: groupColor,
                        isTradeable: isTradeable,
                        isSelected: isSelected,
                        accentColor: accentColor,
                        onChanged: isTradeable
                            ? (checked) => onPropertyToggled(p.id, checked ?? false)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyItem({
    required Property property,
    required Color groupColor,
    required bool isTradeable,
    required bool isSelected,
    required Color accentColor,
    required ValueChanged<bool?>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isTradeable ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? accentColor : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: CheckboxListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        value: isSelected,
        activeColor: accentColor,
        onChanged: onChanged,
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: groupColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                property.name,
                style: GoogleFonts.outfit(
                  color: isTradeable ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price + Mortgage Status + Buildings info
              Row(
                children: [
                  Text(
                    '₹${property.price}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  if (property.isMortgaged)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '⚠️ Mortgaged',
                        style: TextStyle(color: Color(0xFFDC2626), fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    const Text(
                      'Unmortgaged',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                    ),
                  if (property.currentLevel > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      property.currentLevel == 5 ? '🏨 Hotel' : '🏠 ${property.currentLevel}',
                      style: const TextStyle(color: Color(0xFF2563EB), fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              // Tradeable indicator
              if (isTradeable)
                const Text(
                  '✓ Tradeable',
                  style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold),
                )
              else
                const Text(
                  '🔒 Cannot trade: Buildings in color group',
                  style: TextStyle(color: Color(0xFFDC2626), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
