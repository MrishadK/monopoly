import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/kuthaka_game.dart';
import '../../services/multiplayer_service.dart';
import '../../services/voice_stream_service.dart';
import '../../services/user_profile_service.dart';
import '../../providers/game_provider.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/theme_provider.dart';
import 'home_screen.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/property_card_overlay.dart';
import '../overlays/event_card_overlay.dart';
import '../overlays/bankruptcy_overlay.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/auction_overlay.dart';
import '../overlays/trade_proposal_overlay.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/webrtc_audio_renderer.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String? roomId;
  final bool isHost;

  const GameScreen({super.key, this.roomId, this.isHost = true});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final KuthakaGame _game;

  @override
  void initState() {
    super.initState();
    _game = KuthakaGame(ref);
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.borderColor),
        ),
        title: Text(
          'Exit Match?',
          style: GoogleFonts.outfit(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          (widget.roomId != null && widget.isHost)
              ? 'You are the host. Leaving will delete this room and end the match for everyone.'
              : 'Are you sure you want to quit the current match?',
          style: GoogleFonts.outfit(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: TextStyle(color: context.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KuthakaColors.crimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final mp = ref.read(multiplayerServiceProvider);
              if (widget.roomId != null) {
                if (widget.isHost) {
                  mp.broadcastHostLeft(widget.roomId!);
                } else {
                  final myLocalId = ref.read(gameProvider.notifier).localPlayerId ?? ref.read(userProfileProvider).id;
                  final gameState = ref.read(gameProvider);
                  final myPlayer = gameState.players.where((p) => p.id == myLocalId).firstOrNull;
                  mp.broadcastPlayerLeft(widget.roomId!, myLocalId, myPlayer?.name ?? 'A player');
                }
                mp.leaveRoom();
              }
              ref.read(voiceStreamServiceProvider.notifier).disconnectVoice();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('EXIT GAME'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameState>(gameProvider, (prev, next) {
      _game.onGameStateChanged(next);
    });
    ref.listen<ThemeMode>(themeModeProvider, (prev, next) {
      _game.onThemeChanged(next == ThemeMode.dark);
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: Scaffold(
        backgroundColor: context.isDark ? const Color(0xFF090E17) : const Color(0xFFF1F5F9),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(context.isDark ? 'assets/images/bg_dark.jpg' : 'assets/images/bg_light.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RepaintBoundary(
                    child: GameWidget(
                      game: _game,
                      overlayBuilderMap: {
                        'hud': (context, KuthakaGame game) => HudOverlay(game: game, ref: ref),
                        'property_card': (context, KuthakaGame game) => const PropertyCardOverlay(),
                        'event_card': (context, KuthakaGame game) => const EventCardOverlay(),
                        'bankruptcy': (context, KuthakaGame game) => const BankruptcyOverlay(),
                        'game_over': (context, KuthakaGame game) => const GameOverOverlay(),
                        'auction': (context, KuthakaGame game) => const AuctionOverlay(),
                        'trade_proposal': (context, KuthakaGame game) => const TradeProposalOverlay(),
                      },
                      initialActiveOverlays: const ['hud', 'property_card', 'event_card', 'bankruptcy', 'game_over', 'auction', 'trade_proposal'],
                    ),
                  ),
                ),
                const WebrtcAudioRenderer(),
                const BannerAdWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
