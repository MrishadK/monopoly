import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import '../../game/kuthaka_game.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/property_card_overlay.dart';
import '../overlays/event_card_overlay.dart';
import '../overlays/bankruptcy_overlay.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/dice_roll_overlay.dart';

class GameScreen extends ConsumerWidget {
  final String? roomId;
  final bool isHost;

  const GameScreen({super.key, this.roomId, this.isHost = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4EE),
      body: SafeArea(
        child: GameWidget(
          game: KuthakaGame(ref),
          overlayBuilderMap: {
            'hud': (context, KuthakaGame game) => HudOverlay(game: game, ref: ref),
            'dice_roll': (context, KuthakaGame game) => const DiceRollOverlay(),
            'property_card': (context, KuthakaGame game) => const PropertyCardOverlay(),
            'event_card': (context, KuthakaGame game) => const EventCardOverlay(),
            'bankruptcy': (context, KuthakaGame game) => const BankruptcyOverlay(),
            'game_over': (context, KuthakaGame game) => const GameOverOverlay(),
          },
          initialActiveOverlays: const ['hud', 'dice_roll', 'property_card', 'event_card', 'bankruptcy', 'game_over'],
        ),
      ),
    );
  }
}
