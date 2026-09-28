import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/kuthaka_game.dart';
import '../../providers/game_provider.dart';
import '../../models/player.dart';
import '../../services/voice_stream_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/multiplayer_service.dart';
import 'portfolio_sheet.dart';
import 'trade_dialog.dart';
import 'game_menu_dialog.dart';
import '../widgets/dice_widget.dart';
import '../screens/home_screen.dart';

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

      // Listen for host leaving during active online game
      ref.read(multiplayerServiceProvider).onHostLeftReceived = (payload) {
        if (!mounted) return;
        ref.read(multiplayerServiceProvider).leaveRoom();
        ref.read(voiceStreamServiceProvider.notifier).disconnectVoice();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                SizedBox(width: 8),
                Text('Host Left', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'The host has left the match. The room has been deleted.',
              style: TextStyle(color: Color(0xFF475569)),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Return to Home'),
              ),
            ],
          ),
        );
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final currentPlayer = gameState.currentPlayer;
    final voiceService = ref.watch(voiceStreamServiceProvider);

    return Stack(
      children: [
        // ==================== TOP PLAYER STATUS BAR (2:N FRIENDS GRID) ====================
        Positioned(
          top: 6,
          left: 10,
          right: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Match & Voice Stream Header
              _buildTopHeader(context, gameState, voiceService),
              const SizedBox(height: 6),
              // 2:N Friends Grid (2 columns wide, responsive N rows)
              _buildFriendsGrid2N(context, gameState, voiceService),
              // Notification Banner
              if (gameState.message != null) ...[
                const SizedBox(height: 4),
                _buildNotificationBanner(gameState),
              ],
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
              // Dedicated Prominent Dice Tray
              _buildDiceTray(context, gameState, currentPlayer),

              const SizedBox(height: 6),

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

  Widget _buildTopHeader(BuildContext context, GameState gameState, VoiceStreamState voiceService) {
    final multiplayer = ref.watch(multiplayerServiceProvider);
    final isOnline = multiplayer.isConnected;
    final roomId = multiplayer.activeRoomId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Live Voice Stream Status Pill
          InkWell(
            onTap: () => ref.read(voiceStreamServiceProvider.notifier).toggleMic(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: voiceService.isMicMuted ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: voiceService.isMicMuted ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    voiceService.isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    size: 13,
                    color: voiceService.isMicMuted ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    voiceService.isMicMuted ? 'VOICE MUTED' : 'LIVE VOICE',
                    style: GoogleFonts.outfit(
                      color: voiceService.isMicMuted ? const Color(0xFFDC2626) : const Color(0xFF047857),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (!voiceService.isMicMuted) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 5,
                      height: 5,
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

          // Match / Room Mode Badge & Quick Menu
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOnline ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnline ? Icons.wifi_rounded : Icons.offline_bolt_rounded,
                      size: 12,
                      color: isOnline ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'ROOM: ${roomId ?? "LIVE"}' : 'CLASSIC MATCH',
                      style: GoogleFonts.outfit(
                        color: isOnline ? const Color(0xFF1E40AF) : const Color(0xFF475569),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const GameMenuDialog(),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.pause_circle_outline_rounded, size: 20, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsGrid2N(BuildContext context, GameState gameState, VoiceStreamState voiceService) {
    final players = gameState.players;
    final rows = <Widget>[];

    for (int i = 0; i < players.length; i += 2) {
      final p1 = players[i];
      final p1Index = i;
      final hasP2 = (i + 1 < players.length);
      final p2 = hasP2 ? players[i + 1] : null;
      final p2Index = i + 1;

      rows.add(
        Row(
          children: [
            Expanded(child: _buildPlayerCard(p1, p1Index, gameState, voiceService)),
            const SizedBox(width: 8),
            if (p2 != null)
              Expanded(child: _buildPlayerCard(p2, p2Index, gameState, voiceService))
            else
              const Spacer(),
          ],
        ),
      );

      if (i + 2 < players.length) {
        rows.add(const SizedBox(height: 6));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _buildPlayerCard(Player player, int index, GameState gameState, VoiceStreamState voiceService) {
    final isTurn = index == gameState.currentPlayerIndex;
    final isSpeaking = player.type == PlayerType.human
        ? voiceService.isSpeaking
        : (voiceService.participants[player.id]?.isSpeaking ?? false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isTurn ? player.color.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSpeaking
              ? const Color(0xFF10B981)
              : (isTurn ? player.color : const Color(0xFFE2E8F0)),
          width: (isSpeaking || isTurn) ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isTurn ? player.color.withValues(alpha: 0.18) : const Color(0x0A000000),
            blurRadius: isTurn ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: player.color,
                child: Icon(player.tokenIcon, color: Colors.white, size: 17),
              ),
              if (isSpeaking)
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_rounded, size: 9, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0F172A),
                          fontWeight: isTurn ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    if (player.type == PlayerType.ai) ...[
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BOT',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF64748B),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    if (player.isInJail) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.lock_rounded, size: 11, color: Color(0xFFDC2626)),
                    ],
                    if (player.isBankrupt) ...[
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BANKRUPT',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFDC2626),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Text(
                      _formatCurrency(player.cash),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF047857),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.holiday_village_rounded, size: 11, color: Color(0xFF64748B)),
                    const SizedBox(width: 2),
                    Text(
                      '${player.ownedPropertyIds.length}',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isTurn) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Color(0x30FFD54F), blurRadius: 4),
                ],
              ),
              child: Text(
                'TURN',
                style: GoogleFonts.outfit(
                  color: Colors.black87,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationBanner(GameState gameState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (gameState.isAiThinking) ...[
            const SizedBox(
              width: 11,
              height: 11,
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    if (amount < 0) return '-${_formatCurrency(-amount)}';
    final str = amount.toString();
    if (str.length <= 3) return '₹$str';
    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);
    final formattedRemaining = remaining.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (match) => ',',
    );
    return '₹$formattedRemaining,$lastThree';
  }

  Widget _buildDiceTray(BuildContext context, GameState gameState, Player current) {
    final myProfile = ref.watch(userProfileProvider);
    final multiplayer = ref.watch(multiplayerServiceProvider);
    final isOnline = multiplayer.isConnected;
    final isMyTurn = !isOnline || current.id == myProfile.id;
    final canRoll = gameState.phase == GamePhase.roll && isMyTurn && !gameState.isRollingDice && current.type == PlayerType.human;

    return GestureDetector(
      onTap: canRoll ? () => ref.read(gameProvider.notifier).rollDice() : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: canRoll ? const Color(0xFFFFB300) : const Color(0xFFE2E8F0),
            width: canRoll ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: canRoll ? const Color(0x25FFB300) : const Color(0x10000000),
              blurRadius: canRoll ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TumblingDicePairWidget(
              dice: gameState.lastDiceRoll,
              isRolling: gameState.isRollingDice,
              isDoubles: gameState.isDoubles,
              diceSize: 34.0,
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'DICE ROLL',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (gameState.isDoubles) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DOUBLES!',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  gameState.isRollingDice
                      ? 'Rolling...'
                      : '${gameState.lastDiceRoll[0]} + ${gameState.lastDiceRoll[1]} = ${gameState.diceTotal}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (canRoll) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app_rounded, size: 12, color: Color(0xFFB45309)),
                    const SizedBox(width: 3),
                    Text(
                      'TAP',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFB45309),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionButton(BuildContext context, GameState gameState, Player current) {
    final myProfile = ref.watch(userProfileProvider);
    final multiplayer = ref.watch(multiplayerServiceProvider);
    final isOnline = multiplayer.isConnected;
    final isMyTurn = !isOnline || current.id == myProfile.id;

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
              '${current.name} (AI) is thinking...',
              style: GoogleFonts.outfit(color: const Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // In online game, if it is NOT the local player's turn:
    if (!isMyTurn) {
      return Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: current.color, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 8)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: current.color),
            ),
            const SizedBox(width: 10),
            Text(
              gameState.phase == GamePhase.roll
                  ? "Waiting for ${current.name} to roll..."
                  : "Waiting for ${current.name}'s move...",
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // Active Human Player Turn
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
                !isOnline ? '${current.name.toUpperCase()} - ROLL' : 'ROLL DICE',
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
