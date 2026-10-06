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

class _TradeDialogState extends ConsumerState<TradeDialog>
    with TickerProviderStateMixin {
  Player? _selectedTarget;
  final Set<String> _offeredProps = {};
  final Set<String> _requestedProps = {};
  int _offeredCash = 0;
  int _requestedCash = 0;
  late AnimationController _shimmerController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ─── Color palette ─────────────────────────────────────────────
  static const _bgDark = Color(0xFF0B0F1A);
  static const _cardDark = Color(0xFF131926);
  static const _surfaceDark = Color(0xFF1A2036);
  static const _borderSubtle = Color(0xFF252D44);
  static const _textPrimary = Color(0xFFF0F2F8);
  static const _textSecondary = Color(0xFF7C8DB5);
  static const _accentGive = Color(0xFFFF8C42);
  static const _accentReceive = Color(0xFF34D399);
  static const _accentGiveGlow = Color(0x30FF8C42);
  static const _accentReceiveGlow = Color(0x3034D399);

  Color _getGroupColor(PropertyGroup group) {
    switch (group) {
      case PropertyGroup.malabar: return const Color(0xFFC97B4B);
      case PropertyGroup.thrissur: return const Color(0xFF3DAEF2);
      case PropertyGroup.kochi: return const Color(0xFFF06292);
      case PropertyGroup.backwaters: return const Color(0xFFFFB74D);
      case PropertyGroup.highlands: return const Color(0xFFEF5350);
      case PropertyGroup.southKerala: return const Color(0xFFFFEE58);
      case PropertyGroup.premium: return const Color(0xFF66BB6A);
      case PropertyGroup.luxury: return const Color(0xFF42A5F5);
      case PropertyGroup.transport: return const Color(0xFF90A4AE);
      case PropertyGroup.utility: return const Color(0xFF26A69A);
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
      return _buildRestrictedSheet(currentPlayer);
    }

    final myPlayer = currentPlayer;
    final otherPlayers = gameState.players.where((p) => p.id != myPlayer.id && !p.isBankrupt).toList();

    _selectedTarget ??= otherPlayers.isNotEmpty ? otherPlayers.first : null;

    if (_selectedTarget == null) {
      return _buildNoPlayersSheet();
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

    // Bottom sheet height: leave space for the bottom nav dock (~72px from bottom)
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetMaxHeight = screenHeight - 76;

    return Container(
      constraints: BoxConstraints(maxHeight: sheetMaxHeight),
      margin: const EdgeInsets.only(bottom: 68),
      decoration: const BoxDecoration(
        color: _bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x60000000),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Drag Handle ────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ─── Header Row ────────────────────────────
            _buildHeader(),

            // ─── Target Selector ────────────────────────
            _buildTargetSelector(otherPlayers, target),

            // ─── Tab Bar ────────────────────────────────
            _buildTabBar(myPlayer, target),

            // ─── Tab Content ────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: YOU GIVE
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                    child: _buildTradeColumn(
                      playerName: myPlayer.name,
                      label: 'YOU GIVE',
                      icon: Icons.arrow_upward_rounded,
                      accentColor: _accentGive,
                      glowColor: _accentGiveGlow,
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
                      playerToken: myPlayer.tokenIcon,
                      playerColor: myPlayer.color,
                    ),
                  ),
                  // Tab 2: THEY GIVE
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                    child: _buildTradeColumn(
                      playerName: target.name,
                      label: 'THEY GIVE',
                      icon: Icons.arrow_downward_rounded,
                      accentColor: _accentReceive,
                      glowColor: _accentReceiveGlow,
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
                      playerToken: target.tokenIcon,
                      playerColor: target.color,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Submit Button ────────────────────────
            _buildSubmitButton(hasTradeContent, myPlayer, target),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ─── Header ───────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 10, 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [_accentGive, _accentReceive],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROPOSE TRADE',
                  style: GoogleFonts.outfit(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Select cash & properties to exchange',
                  style: GoogleFonts.outfit(
                    color: _textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _surfaceDark,
                  border: Border.all(color: _borderSubtle),
                ),
                child: const Icon(Icons.close_rounded, color: _textSecondary, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ─── Target Selector ──────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTargetSelector(List<Player> otherPlayers, Player target) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: target.color.withValues(alpha: 0.15),
                border: Border.all(color: target.color.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Icon(target.tokenIcon, size: 11, color: target.color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: target.id,
                  dropdownColor: _cardDark,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary, size: 18),
                  style: GoogleFonts.outfit(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  items: otherPlayers.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Row(
                        children: [
                          Icon(p.tokenIcon, color: p.color, size: 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              p.name,
                              style: GoogleFonts.outfit(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: _surfaceDark,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p.type == PlayerType.ai ? 'BOT' : '👤',
                              style: GoogleFonts.outfit(
                                color: _textSecondary,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '₹${p.cash}',
                            style: GoogleFonts.outfit(color: _accentReceive, fontSize: 11, fontWeight: FontWeight.w700),
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
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ─── Tab Bar ──────────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabBar(Player myPlayer, Player target) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderSubtle),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          gradient: LinearGradient(
            colors: [
              _tabController.index == 0
                  ? _accentGive.withValues(alpha: 0.2)
                  : _accentReceive.withValues(alpha: 0.2),
              _tabController.index == 0
                  ? _accentGive.withValues(alpha: 0.1)
                  : _accentReceive.withValues(alpha: 0.1),
            ],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        onTap: (_) => setState(() {}),
        tabs: [
          Tab(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: myPlayer.color.withValues(alpha: 0.2),
                    border: Border.all(color: myPlayer.color.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Icon(myPlayer.tokenIcon, size: 9, color: myPlayer.color),
                ),
                const SizedBox(width: 6),
                Text(
                  'YOU GIVE',
                  style: GoogleFonts.outfit(
                    color: _tabController.index == 0 ? _accentGive : _textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_offeredProps.isNotEmpty || _offeredCash > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accentGive,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: target.color.withValues(alpha: 0.2),
                    border: Border.all(color: target.color.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Icon(target.tokenIcon, size: 9, color: target.color),
                ),
                const SizedBox(width: 6),
                Text(
                  'THEY GIVE',
                  style: GoogleFonts.outfit(
                    color: _tabController.index == 1 ? _accentReceive : _textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_requestedProps.isNotEmpty || _requestedCash > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accentReceive,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ─── Trade Column ─────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTradeColumn({
    required String playerName,
    required String label,
    required IconData icon,
    required Color accentColor,
    required Color glowColor,
    required int cashBalance,
    required int selectedCash,
    required ValueChanged<int> onCashChanged,
    required List<Property> properties,
    required Set<String> selectedPropertyIds,
    required void Function(String propertyId, bool isSelected) onPropertyToggled,
    required Map<String, Property> allProperties,
    required IconData playerToken,
    required Color playerColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Column Header ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: accentColor.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: playerColor.withValues(alpha: 0.15),
                    border: Border.all(color: playerColor.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Icon(playerToken, size: 10, color: playerColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${playerName.toUpperCase()} — $label',
                    style: GoogleFonts.outfit(
                      color: _textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: accentColor, size: 14),
              ],
            ),
          ),

          // ─── Cash Selector ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedCash > 0
                      ? accentColor.withValues(alpha: 0.4)
                      : _borderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded,
                              color: accentColor, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '₹$selectedCash',
                            style: GoogleFonts.outfit(
                              color: selectedCash > 0 ? accentColor : _textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _bgDark,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '/ ₹$cashBalance',
                          style: GoogleFonts.outfit(
                            color: _textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: accentColor,
                      thumbColor: accentColor,
                      inactiveTrackColor: accentColor.withValues(alpha: 0.12),
                      overlayColor: accentColor.withValues(alpha: 0.1),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
                  // Quick-pick cash buttons
                  if (cashBalance > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [0.0, 0.25, 0.5, 0.75, 1.0].map((fraction) {
                        final amount = (cashBalance * fraction).toInt();
                        final isActive = selectedCash == amount;
                        final labelText = fraction == 0
                            ? '₹0'
                            : fraction == 1
                                ? 'MAX'
                                : '${(fraction * 100).toInt()}%';
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1.5),
                            child: GestureDetector(
                              onTap: () => onCashChanged(amount),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? accentColor.withValues(alpha: 0.2)
                                      : _bgDark,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isActive
                                        ? accentColor.withValues(alpha: 0.5)
                                        : _borderSubtle,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  labelText,
                                  style: GoogleFonts.outfit(
                                    color: isActive ? accentColor : _textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          // ─── Properties Header ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_city_rounded, color: _textSecondary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'PROPERTIES',
                      style: GoogleFonts.outfit(
                        color: _textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _surfaceDark,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${properties.length}',
                        style: GoogleFonts.outfit(
                          color: _textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (selectedPropertyIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${selectedPropertyIds.length} selected',
                      style: GoogleFonts.outfit(
                        color: accentColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ─── Properties List ──────────────────────────────
          Expanded(
            child: properties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, color: _borderSubtle, size: 26),
                        const SizedBox(height: 6),
                        Text(
                          'No properties owned yet',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: _textSecondary.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    itemCount: properties.length,
                    itemBuilder: (context, idx) {
                      final p = properties[idx];
                      final isTradeable = p.isTradeable(allProperties);
                      final isSelected = selectedPropertyIds.contains(p.id);
                      final groupColor = _getGroupColor(p.group);

                      return _buildPropertyCard(
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

  // ═══════════════════════════════════════════════════════════════
  // ─── Property Card ────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPropertyCard({
    required Property property,
    required Color groupColor,
    required bool isTradeable,
    required bool isSelected,
    required Color accentColor,
    required ValueChanged<bool?>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isTradeable
              ? () => onChanged?.call(!isSelected)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.08)
                  : isTradeable
                      ? _surfaceDark
                      : _surfaceDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.5)
                    : _borderSubtle,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Color group indicator bar
                Container(
                  width: 5,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isTradeable ? groupColor : groupColor.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                property.name,
                                style: GoogleFonts.outfit(
                                  color: isTradeable ? _textPrimary : _textSecondary.withValues(alpha: 0.5),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₹${property.price}',
                              style: GoogleFonts.outfit(
                                color: _textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (property.isMortgaged)
                              _buildStatusChip('MORTGAGED', const Color(0xFFEF4444), Icons.warning_amber_rounded)
                            else if (!isTradeable)
                              _buildStatusChip('LOCKED', const Color(0xFFEF4444), Icons.lock_rounded)
                            else if (isSelected)
                              _buildStatusChip('SELECTED', accentColor, Icons.check_circle_rounded)
                            else
                              _buildStatusChip('AVAILABLE', const Color(0xFF6B7280), null),
                            if (property.currentLevel > 0) ...[
                              const SizedBox(width: 4),
                              _buildStatusChip(
                                property.currentLevel == 5 ? 'HOTEL' : 'LVL ${property.currentLevel}',
                                const Color(0xFF60A5FA),
                                property.currentLevel == 5 ? Icons.apartment_rounded : Icons.home_rounded,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Checkbox
                if (isTradeable)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: onChanged,
                        activeColor: accentColor,
                        checkColor: _bgDark,
                        side: const BorderSide(color: _borderSubtle, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            text,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ─── Submit Button ────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSubmitButton(bool hasTradeContent, Player myPlayer, Player target) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _borderSubtle, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: EdgeInsets.zero,
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
          child: Ink(
            decoration: BoxDecoration(
              gradient: hasTradeContent
                  ? const LinearGradient(
                      colors: [_accentGive, _accentReceive],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: hasTradeContent ? null : _surfaceDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasTradeContent ? Icons.handshake_rounded : Icons.touch_app_rounded,
                    size: 18,
                    color: hasTradeContent ? Colors.white : _textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasTradeContent ? 'PROPOSE TRADE' : 'SELECT CASH OR PROPERTIES',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: hasTradeContent ? Colors.white : _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ─── Restricted / No Players sheets ───────────────────────────
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRestrictedSheet(Player currentPlayer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 68),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: _bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            'TRADE RESTRICTED',
            style: GoogleFonts.outfit(
              color: _textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentPlayer.type == PlayerType.ai
                ? 'Trading is paused while ${currentPlayer.name} (AI) is playing.'
                : 'Only ${currentPlayer.name} can trade during their turn.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: _textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _surfaceDark,
                foregroundColor: _textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('CLOSE', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlayersSheet() {
    return Container(
      margin: const EdgeInsets.only(bottom: 68),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: _bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentGive.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.person_off_rounded, color: _accentGive, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            'NO TRADE PARTNERS',
            style: GoogleFonts.outfit(
              color: _textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No other active players to trade with.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: _textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _surfaceDark,
                foregroundColor: _textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
