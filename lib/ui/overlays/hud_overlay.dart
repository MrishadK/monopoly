
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/kuthaka_game.dart';
import '../../providers/game_provider.dart';
import '../../models/player.dart';
import '../../models/property.dart';
import '../../models/transaction_notice.dart';
import '../../services/voice_stream_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/multiplayer_service.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/theme_provider.dart';
import 'portfolio_sheet.dart';
import 'trade_dialog.dart';
import 'game_menu_dialog.dart';
import 'emoji_chat_overlay.dart';
import '../widgets/dice_widget.dart';
import '../screens/home_screen.dart';
import '../../data/game_data.dart';

enum BoardInteractionMode { none, redeem, build, mortgage, sell }

class HudOverlay extends ConsumerStatefulWidget {
  final KuthakaGame game;
  final WidgetRef ref;

  const HudOverlay({super.key, required this.game, required this.ref});

  @override
  ConsumerState<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends ConsumerState<HudOverlay> {
  int _activeNavIndex = 0;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider);
      final mp = ref.read(multiplayerServiceProvider);
      if (mp.activeRoomId != null) {
        final isHost = ref.read(gameProvider.notifier).isHost;
        ref.read(voiceStreamServiceProvider.notifier).connectToVoiceRoom(
          mp.activeRoomId!,
          profile.id,
          profile.name,
          isHost: isHost,
          autoStartMic: true,
        );
      }

      ref.read(multiplayerServiceProvider).onHostLeftReceived = (payload) {
        if (!mounted) return;
        ref.read(multiplayerServiceProvider).leaveRoom();
        ref.read(voiceStreamServiceProvider.notifier).disconnectVoice();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: ctx.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: KuthakaColors.crimson),
                const SizedBox(width: 8),
                Text('Host Left', style: TextStyle(fontWeight: FontWeight.bold, color: ctx.textPrimary)),
              ],
            ),
            content: Text(
              'The host has left the match. The room has been deleted.',
              style: TextStyle(color: ctx.textSecondary),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KuthakaColors.emerald,
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

      ref.read(multiplayerServiceProvider).onPlayerLeftReceived = (playerId, playerName) {
        if (!mounted) return;
        final notifier = ref.read(gameProvider.notifier);
        if (notifier.isHost) {
          notifier.surrenderPlayer(playerId);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.person_remove_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('$playerName left the match.', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: KuthakaColors.goldDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final myProfile = ref.watch(userProfileProvider);
    final multiplayer = ref.watch(multiplayerServiceProvider);
    final isOnline = multiplayer.isConnected || multiplayer.activeRoomId != null;
    final myLocalId = ref.watch(gameProvider.notifier).localPlayerId ?? myProfile.id;
    final isHumanTurn = currentPlayer.type == PlayerType.human;
    final isMyTurn = isHumanTurn && (!isOnline || currentPlayer.id == myLocalId);

    // Calculate dynamic anchor coordinates from the Flame game board
    final board = widget.game.board;
    final double diceTop = board != null ? (board.position.y + board.size.y * 0.52) : 360.0;
    final double diceLeft = board != null ? (board.position.x + board.size.x * 0.14) : 24.0;
    final double diceWidth = board != null ? (board.size.x * 0.72) : 300.0;

    ref.listen(gameProvider, (prev, next) {
      // Empty block for now, or you can completely remove the listen if it's empty
    });

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
        return SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ==================== TOP BAR ====================
              Positioned(
                top: 8,
                left: 10,
                right: 10,
                child: _buildTopBar(context, gameState, isOnline, multiplayer.activeRoomId),
              ),

              // ==================== PLAYER CARDS ====================
              Positioned(
                top: 54,
                left: 10,
                right: constraints.maxWidth < 600 ? 10 : null,
                child: _buildPlayerCardsSection(
                  context,
                  gameState,
                  voiceService,
                  constraints.maxWidth,
                ),
              ),

              // ==================== FLOATING EMOJI ====================
              const Positioned(
                top: 200,
                left: 0,
                right: 0,
                child: Center(child: EmojiFloatingDisplay()),
              ),

              // ==================== BOTTOM ACTION DOCK ====================
              Positioned(
                bottom: 74,
                left: 10,
                right: 10,
                child: Center(child: _buildBottomActionDock(context, gameState, currentPlayer, isMyTurn)),
              ),

              // ==================== BOARD CENTER CONTROLS & DICE ====================
              Positioned(
                top: diceTop,
                left: diceLeft,
                width: diceWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDiceTray(context, gameState, currentPlayer, isMyTurn),
                    if (gameState.phase == GamePhase.turnEnd && isMyTurn) ...[
                      const SizedBox(height: 6),
                      _buildMainActionButton(context, gameState, currentPlayer),
                    ],
                  ],
                ),
              ),

              // ==================== BOTTOM NAVIGATION DOCK ====================
              Positioned(
                bottom: 2,
                left: 10,
                right: 10,
                child: SafeArea(
                  top: false,
                  bottom: true,
                  child: _buildBottomNavDock(context, gameState, currentPlayer, isMyTurn),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  }

  Widget _buildTopBar(BuildContext context, GameState gameState, bool isOnline, String? roomId) {
    final isDark = context.isDark;
    final displayCode = roomId ?? "867548";
    
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFCBD5E1)),
        boxShadow: context.subtleShadow,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 20,
          child: Row(
            children: [
              // Menu button
              IconButton(
                icon: Icon(Icons.menu_rounded, size: 20, color: context.textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  showDialog(context: context, builder: (_) => const GameMenuDialog());
                },
              ),
              
              // Room ID pill with copy icon
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: displayCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Room code $displayCode copied to clipboard!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.cardAltColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ROOM: $displayCode',
                        style: GoogleFonts.outfit(
                          color: context.textPrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.copy_rounded, size: 11, color: context.textSecondary),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Players indicator (e.g. 2/4)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: context.cardAltColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_rounded, size: 12, color: context.textPrimary),
                    const SizedBox(width: 3),
                    Text(
                      '${gameState.players.where((p) => !p.isBankrupt).length}/${gameState.players.length}',
                      style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              
              // Turn Timer (e.g. 🟢 39s)
              const _HudTurnTimerBadge(),
              
              const SizedBox(width: 4),
              
              // Connection status
              Container(
                padding: const EdgeInsets.all(4.5),
                decoration: BoxDecoration(color: context.cardAltColor, shape: BoxShape.circle),
                child: Icon(
                  Icons.wifi_rounded,
                  size: 12,
                  color: isOnline ? const Color(0xFF10B981) : context.textSecondary,
                ),
              ),
              
              const SizedBox(width: 4),
              
              // Theme Toggle (Icon button with zero overflow)
              InkWell(
                onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF242C3D) : const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFF59E0B),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    size: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCardsSection(
    BuildContext context,
    GameState gameState,
    VoiceStreamState voiceService,
    double screenWidth,
  ) {
    final players = gameState.players;
    final isPhone = screenWidth < 600;

    if (!isPhone) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: screenWidth - 80),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < players.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _buildPlayerCard(players[i], i, gameState, voiceService, width: 155),
              ],
            ],
          ),
        ),
      );
    }

    // Phone layout: 2-column grid utilizing the available vertical space above the board
    final double cardWidth = ((screenWidth - 20) - 8) / 2;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (int i = 0; i < players.length; i++)
          _buildPlayerCard(
            players[i],
            i,
            gameState,
            voiceService,
            width: cardWidth,
          ),
      ],
    );
  }

  Widget _buildPlayerCard(
    Player player,
    int index,
    GameState gameState,
    VoiceStreamState voiceService, {
    required double width,
  }) {
    final isTurn = index == gameState.currentPlayerIndex;
    final isDark = context.isDark;
    final activeBorderColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF0D9488);

    // Calculate houses and hotels
    int houses = 0;
    int hotels = 0;
    for (var propId in player.ownedPropertyIds) {
      final prop = gameState.properties[propId];
      if (prop != null) {
        if (prop.currentLevel == 5) {
          hotels++;
        } else {
          houses += prop.currentLevel;
        }
      }
    }

    // Avatar image: Houseboat for Player 1, Kathakali for Player 2
    ImageProvider avatarImage;
    Color ringColor;
    if (index == 0) {
      avatarImage = const AssetImage('assets/images/avatar_houseboat.jpg');
      ringColor = const Color(0xFFD4AF37); // Gold ring
    } else if (index == 1) {
      avatarImage = const AssetImage('assets/images/avatar_kathakali.jpg');
      ringColor = const Color(0xFFEF4444); // Red ring
    } else {
      avatarImage = const AssetImage('assets/images/kuthaka_banner.jpg');
      ringColor = player.color;
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTurn ? activeBorderColor : (isDark ? const Color(0xFF2A364F) : const Color(0xFFCBD5E1)),
          width: isTurn ? 1.8 : 1.0,
        ),
        boxShadow: isTurn
            ? [
                BoxShadow(
                  color: activeBorderColor.withValues(alpha: isDark ? 0.35 : 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : context.subtleShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with decorative ring
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.3),
                  blurRadius: 3,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 13,
              backgroundImage: avatarImage,
            ),
          ),
          const SizedBox(width: 6),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name & BOT badge
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        style: GoogleFonts.outfit(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (player.consecutiveSkippedTurns > 0) ...[
                      const SizedBox(width: 3),
                      Tooltip(
                        message: '${player.consecutiveSkippedTurns} consecutive turn${player.consecutiveSkippedTurns > 1 ? "s" : ""} skipped',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
                          ),
                          child: Text(
                            '[${player.consecutiveSkippedTurns}]',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFEF4444),
                              fontSize: 8.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (index == 0) ...[
                      const SizedBox(width: 2),
                      const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD4AF37), size: 11),
                    ],
                    if (player.type == PlayerType.ai) ...[
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: context.cardAltColor,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: context.borderColor, width: 0.6),
                        ),
                        child: Text(
                          'BOT',
                          style: GoogleFonts.outfit(
                            color: context.textSecondary,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Cash
                Text(
                  _formatCurrency(player.cash),
                  style: GoogleFonts.outfit(
                    color: context.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                // Property stats (houses, hotels)
                Row(
                  children: [
                    const Icon(Icons.home_rounded, size: 9, color: Color(0xFF10B981)),
                    const SizedBox(width: 1),
                    Text('$houses', style: GoogleFonts.outfit(color: context.textSecondary, fontSize: 8, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_city_rounded, size: 9, color: Color(0xFF0284C7)),
                    const SizedBox(width: 1),
                    Text('$hotels', style: GoogleFonts.outfit(color: context.textSecondary, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          // Mini turn dot / pill (single bold color, no gradient)
          if (isTurn)
            Container(
              margin: const EdgeInsets.only(left: 3),
              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0D9488)).withValues(alpha: 0.45),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                'TURN',
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.black : Colors.white,
                  fontSize: 6.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionDock(BuildContext context, GameState gameState, Player currentPlayer, bool isMyTurn) {
    final isDark = context.isDark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFCBD5E1)),
        boxShadow: context.cardShadow,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
          _buildBottomDockActionButton(context, Icons.swap_horiz_rounded, 'Trade', const Color(0xFF2563EB), () {
            if (isMyTurn) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const TradeDialog(),
              );
            }
          }),
          _buildBottomDockActionButton(context, Icons.home_work_rounded, 'Mortgage', const Color(0xFFEA580C), () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const PortfolioSheet(),
            );
          }),
          _buildBottomDockActionButton(context, Icons.apartment_rounded, 'Build', const Color(0xFF7C3AED), () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const PortfolioSheet(),
            );
          }),
          _buildBottomDockActionButton(context, Icons.sell_rounded, 'Sell', const Color(0xFFE11D48), () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const PortfolioSheet(),
            );
          }),
        ],
      ),
      ),
    );
  }

  Widget _buildBottomDockActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    bool highlight = false,
  }) {
    final isDark = context.isDark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: highlight
                ? color.withValues(alpha: isDark ? 0.35 : 0.20)
                : color.withValues(alpha: isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight ? color : color.withValues(alpha: 0.35),
              width: highlight ? 1.8 : 1.0,
            ),
            boxShadow: highlight
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: highlight ? color : color),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: isDark ? const Color(0xFFF1F5F9) : (highlight ? color : color),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavDock(BuildContext context, GameState gameState, Player currentPlayer, bool isMyTurn) {
    final isDark = context.isDark;
    
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? const Color(0xFF2A364F) : const Color(0xFFCBD5E1)),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomDockItem(
            context,
            index: 0,
            icon: Icons.holiday_village_rounded,
            label: 'Properties',
            onTap: () {
              setState(() => _activeNavIndex = 0);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const PortfolioSheet(),
              );
            },
          ),
          _buildBottomDockItem(
            context,
            index: 1,
            icon: Icons.emoji_emotions_rounded,
            label: 'Chat / Emoji',
            hasNotification: true,
            onTap: () {
              setState(() => _activeNavIndex = 1);
              showDialog(
                context: context,
                barrierColor: Colors.black26,
                builder: (_) => const Center(child: EmojiChatPanel()),
              );
            },
          ),
          _buildBottomDockItem(
            context,
            index: 2,
            icon: Icons.history_rounded,
            label: 'Logs',
            onTap: () {
              setState(() => _activeNavIndex = 2);
              _showLogsDialog(context, gameState);
            },
          ),
          _buildBottomDockItem(
            context,
            index: 3,
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () {
              setState(() => _activeNavIndex = 3);
              showDialog(context: context, builder: (_) => const GameMenuDialog());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDockItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool hasNotification = false,
  }) {
    final isDark = context.isDark;
    final isActive = _activeNavIndex == index;
    final activeColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF0D9488);
    final activeBg = isDark ? const Color(0xFF0D3B3E) : const Color(0xFFE0F2F1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isActive ? 12 : 7, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? activeColor : context.textSecondary,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: isActive ? activeColor : context.textSecondary,
                    fontSize: 9.5,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (hasNotification)
              Positioned(
                top: -2,
                right: -4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: KuthakaColors.crimson,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiceTray(BuildContext context, GameState gameState, Player current, bool isMyTurn) {
    final canRoll = gameState.phase == GamePhase.roll && isMyTurn && !gameState.isRollingDice && !widget.game.isAnyTokenMoving && current.type == PlayerType.human;
    final isDark = context.isDark;

    // Detect if current player landed on an unowned property during space action
    final space = current.position < GameData.spaces.length ? GameData.spaces[current.position] : null;
    final prop = (space != null && space.propertyId != null) ? gameState.properties[space.propertyId] : null;
    final isUnownedProperty = prop != null && prop.ownerId == null && gameState.phase == GamePhase.spaceAction;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TumblingDicePairWidget(
          dice: gameState.lastDiceRoll,
          isRolling: gameState.isRollingDice,
          isDoubles: gameState.isDoubles,
          diceSize: 42.0,
        ),
        const SizedBox(height: 8),

        // Case 1: Human turn to roll
        if (canRoll)
          if (current.isInJail)
            _buildJailActionTray(context, gameState, current, isDark, isMyTurn)
          else
            GestureDetector(
              onTap: () => ref.read(gameProvider.notifier).rollDice(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF00E5FF), const Color(0xFF009688)]
                        : [const Color(0xFF00B4D8), const Color(0xFF0D9488)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0D9488)).withValues(alpha: isDark ? 0.50 : 0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.casino_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ROLL DICE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            )

        // Case 2: Landed on unowned property -> show sleek in-board action panel!
        else if (isUnownedProperty)
          _buildSpaceActionTray(context, gameState, current, prop, isDark, isMyTurn)

        // Case 3: Other phases / waiting on AI or move
        else if (gameState.phase != GamePhase.turnEnd)
          if (current.isInJail)
            _buildJailActionTray(context, gameState, current, isDark, isMyTurn)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF101826) : Colors.white).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A364F) : const Color(0xFFCBD5E1),
                  width: 0.8,
                ),
              ),
              child: Text(
                gameState.isRollingDice
                    ? '${current.name} is rolling...'
                    : (isMyTurn ? 'Your turn to roll' : '${current.name}\'s turn'),
                style: GoogleFonts.outfit(
                  color: context.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

        // Token moving indicator
        if (widget.game.isAnyTokenMoving) ...[
          const SizedBox(height: 4),
          Text(
            '${current.name} is moving...',
            style: GoogleFonts.outfit(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        // In-tray Transaction Notice (subtle, non-intrusive notification badge)
        if (gameState.activeTransaction != null)
          _buildInlineTransactionBadge(context, gameState.activeTransaction!, isDark)
        else if (gameState.message != null && gameState.phase != GamePhase.spaceAction && !canRoll && !widget.game.isAnyTokenMoving)
          _buildInlineMessageBadge(context, gameState.message!, isDark),
      ],
    );
  }

  Widget _buildSpaceActionTray(
    BuildContext context,
    GameState gameState,
    Player current,
    Property prop,
    bool isDark,
    bool isMyTurn,
  ) {
    final groupColor = _getGroupColor(prop.group);
    final canAfford = current.cash >= prop.price;
    final isHuman = current.type == PlayerType.human;

    if (!isMyTurn || !isHuman) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF101826) : Colors.white).withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: groupColor.withValues(alpha: 0.5)),
        ),
        child: Text(
          '${current.name} is deciding on ${prop.name}...',
          style: GoogleFonts.outfit(
            color: context.textPrimary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 310),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF131B2A) : Colors.white).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: groupColor.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: groupColor.withValues(alpha: isDark ? 0.30 : 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          ...context.subtleShadow,
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Property header info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: groupColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  prop.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: context.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F291E) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '₹${prop.price}',
                  style: GoogleFonts.outfit(
                    color: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // Action Buttons: BUY, AUCTION, DEED
          Row(
            children: [
              // BUY button
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford
                        ? (isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark)
                        : Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: canAfford ? 4 : 0,
                  ),
                  onPressed: canAfford
                      ? () => ref.read(gameProvider.notifier).buyProperty(prop.id)
                      : null,
                  icon: const Icon(Icons.shopping_cart_rounded, size: 14),
                  label: Text(
                    'BUY ₹${prop.price}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              // AUCTION button
              Expanded(
                flex: 4,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KuthakaColors.goldDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  onPressed: () => ref.read(gameProvider.notifier).startAuction(prop.id),
                  icon: const Icon(Icons.gavel_rounded, size: 13),
                  label: Text(
                    'AUCTION',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              // DEED inspection button
              InkWell(
                onTap: () => ref.read(gameProvider.notifier).inspectProperty(prop),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: context.cardAltColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineTransactionBadge(BuildContext context, TransactionNotice notice, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF131B2A) : Colors.white).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: notice.color, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: notice.color.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(notice.icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              notice.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: context.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineMessageBadge(BuildContext context, String message, bool isDark) {
    final isWarning = message.contains('Jail') || message.contains('Tax') || message.contains('bankrupt');
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF101826) : Colors.white).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWarning
              ? KuthakaColors.crimson
              : (isDark ? const Color(0xFF2A364F) : const Color(0xFFCBD5E1)),
          width: 0.8,
        ),
      ),
      child: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          color: isWarning ? KuthakaColors.crimson : context.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }



  Widget _buildJailActionTray(
    BuildContext context,
    GameState gameState,
    Player current,
    bool isDark,
    bool isMyTurn,
  ) {
    if (!isMyTurn || current.type != PlayerType.human) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF101826) : Colors.white).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE11D48).withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_police_rounded, color: Color(0xFFE11D48), size: 18),
            const SizedBox(width: 8),
            Text(
              '${current.name} is in Lockup / Jail',
              style: GoogleFonts.outfit(
                color: context.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final turns = current.turnsInJail;
    final rollsRemaining = (3 - turns).clamp(0, 3);
    final canPayBail = current.cash >= 100 && !gameState.isRollingDice && gameState.phase == GamePhase.roll;
    final hasJailCard = current.getOutOfJailCards > 0 && !gameState.isRollingDice && gameState.phase == GamePhase.roll;
    final canRoll = !gameState.isRollingDice && gameState.phase == GamePhase.roll && !widget.game.isAnyTokenMoving;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_police_rounded, color: Color(0xFFE11D48), size: 20),
              const SizedBox(width: 6),
              Text(
                'IN JAIL / LOCKUP',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFE11D48),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Jail attempt: ${turns + 1} / 3  ($rollsRemaining ${rollsRemaining == 1 ? "roll" : "rolls"} remaining)',
              style: GoogleFonts.outfit(
                color: const Color(0xFFE11D48),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Option A: Roll for doubles
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              onPressed: canRoll ? () => ref.read(gameProvider.notifier).rollDice() : null,
              icon: const Icon(Icons.casino_rounded, size: 16),
              label: Text(
                'ROLL FOR DOUBLES',
                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Option B: Pay 100 & Get Out
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              onPressed: canPayBail ? () => ref.read(gameProvider.notifier).payJailBail() : null,
              icon: const Icon(Icons.payment_rounded, size: 16),
              label: Text(
                'PAY ₹100 & GET OUT',
                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            ),
          ),

          // Option C: Use Get Out of Jail Free Card (if owned)
          if (hasJailCard) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
                onPressed: () => ref.read(gameProvider.notifier).useJailCard(),
                icon: const Icon(Icons.confirmation_number_rounded, size: 16),
                label: Text(
                  'USE GET OUT OF JAIL FREE',
                  style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLogsDialog(BuildContext context, GameState gameState) {
    final isDark = context.isDark;
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: ctx.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: KuthakaColors.goldDark.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_rounded, color: KuthakaColors.goldDark, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Game Activity Log',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ctx.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: ctx.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Chronological record of match events, rolls, and transactions',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: ctx.textSecondary,
                  ),
                ),
                const Divider(height: 20),
                Expanded(
                  child: gameState.gameLogs.isEmpty
                      ? Center(
                          child: Text(
                            'No logs recorded yet.',
                            style: GoogleFonts.outfit(color: ctx.textSecondary, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: gameState.gameLogs.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (c, i) {
                            final log = gameState.gameLogs[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4, right: 8),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i == 0 ? KuthakaColors.goldDark : ctx.textSecondary.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      log,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        height: 1.35,
                                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                                        color: i == 0 ? ctx.textPrimary : ctx.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      foregroundColor: ctx.textPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildMainActionButton(BuildContext context, GameState gameState, Player current) {
    final myProfile = ref.watch(userProfileProvider);
    final multiplayer = ref.watch(multiplayerServiceProvider);
    final isOnline = multiplayer.isConnected;
    final myLocalId = ref.watch(gameProvider.notifier).localPlayerId ?? myProfile.id;
    final isMyTurn = !isOnline || current.id == myLocalId;

    if (!isMyTurn || current.type != PlayerType.human) {
      return const SizedBox.shrink();
    }

    if (gameState.phase == GamePhase.turnEnd) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: KuthakaColors.goldDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          elevation: 6,
        ),
        onPressed: () => ref.read(gameProvider.notifier).endTurn(),
        child: Text('END TURN', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
      );
    }
    
    return const SizedBox.shrink();
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
}

class _HudTurnTimerBadge extends ConsumerWidget {
  const _HudTurnTimerBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final isAuction = ref.watch(gameProvider.select((s) => s.activeAuction != null));
    final timeRemaining = ref.watch(turnTimerRemainingProvider);
    final isWarning = !isAuction && timeRemaining <= 10;
    final timerColor = isAuction
        ? KuthakaColors.gold
        : (isWarning ? KuthakaColors.crimson : (isDark ? const Color(0xFF10B981) : const Color(0xFF047857)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isAuction
            ? context.goldBg
            : (isWarning ? context.crimsonBg : context.emeraldBg),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: timerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: timerColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '${timeRemaining}s',
            style: GoogleFonts.outfit(
              color: timerColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
