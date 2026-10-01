import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/kuthaka_game.dart';
import '../../services/multiplayer_service.dart';
import '../../services/voice_stream_service.dart';
import '../../services/user_profile_service.dart';
import '../../providers/game_provider.dart';
import 'home_screen.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/property_card_overlay.dart';
import '../overlays/event_card_overlay.dart';
import '../overlays/bankruptcy_overlay.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/auction_overlay.dart';
import '../widgets/banner_ad_widget.dart';

class GameScreen extends ConsumerWidget {
  final String? roomId;
  final bool isHost;

  const GameScreen({super.key, this.roomId, this.isHost = true});

  void _confirmExit(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Exit Match?',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          (roomId != null && isHost)
              ? 'You are the host. Leaving will delete this room and end the match for everyone.'
              : 'Are you sure you want to quit the current match?',
          style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final mp = ref.read(multiplayerServiceProvider);
              if (roomId != null) {
                if (isHost) {
                  mp.broadcastHostLeft(roomId!);
                } else {
                  final myLocalId = ref.read(gameProvider.notifier).localPlayerId ?? ref.read(userProfileProvider).id;
                  final gameState = ref.read(gameProvider);
                  final myPlayer = gameState.players.where((p) => p.id == myLocalId).firstOrNull;
                  mp.broadcastPlayerLeft(roomId!, myLocalId, myPlayer?.name ?? 'A player');
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
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context, ref);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F4EE),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: GameWidget(
                  game: KuthakaGame(ref),
                  overlayBuilderMap: {
                    'hud': (context, KuthakaGame game) => HudOverlay(game: game, ref: ref),
                    'property_card': (context, KuthakaGame game) => const PropertyCardOverlay(),
                    'event_card': (context, KuthakaGame game) => const EventCardOverlay(),
                    'bankruptcy': (context, KuthakaGame game) => const BankruptcyOverlay(),
                    'game_over': (context, KuthakaGame game) => const GameOverOverlay(),
                    'auction': (context, KuthakaGame game) => const AuctionOverlay(),
                  },
                  initialActiveOverlays: const ['hud', 'property_card', 'event_card', 'bankruptcy', 'game_over', 'auction'],
                ),
              ),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

