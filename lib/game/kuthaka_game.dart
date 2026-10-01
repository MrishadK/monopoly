import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import 'components/board_component.dart';
import 'components/player_token_component.dart';

class KuthakaGame extends FlameGame {
  final WidgetRef ref;

  KuthakaGame(this.ref);

  BoardComponent? board;
  List<PlayerTokenComponent> tokens = [];
  double _lastWidth = 0;
  double _lastHeight = 0;

  bool get isAnyTokenMoving => tokens.any((t) => t.isMoving);

  @override
  Color backgroundColor() => const Color(0xFFF6F4EE);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _layoutBoard();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if ((size.x != _lastWidth || size.y != _lastHeight) && isLoaded) {
      _layoutBoard();
    }
  }

  void _layoutBoard() {
    _lastWidth = size.x;
    _lastHeight = size.y;

    // Clear previous components if re-laying out
    if (board != null) {
      remove(board!);
      tokens.clear();
    }

    // Calculate optimal board size to preserve clearance for top header & bottom HUDs
    final playerCount = ref.read(gameProvider).players.length;
    final bool isPortrait = size.y > size.x;
    double topPadding = isPortrait ? (playerCount > 2 ? 172.0 : 120.0) : 66.0;
    double bottomPadding = isPortrait ? 165.0 : 160.0;
    double availableWidth = isPortrait ? (size.x - 16) : (size.x - 40);
    double availableHeight = size.y - (topPadding + bottomPadding);
    double boardSize = min(availableWidth, availableHeight);
    boardSize = max(boardSize, 260); // Minimum sensible size

    double posX = (size.x - boardSize) / 2;
    double verticalSlack = max(0.0, availableHeight - boardSize);
    double posY = topPadding + verticalSlack * 0.45;

    final gameState = ref.read(gameProvider);

    board = BoardComponent(
      properties: gameState.properties,
      players: gameState.players,
      lastDiceRoll: gameState.lastDiceRoll,
      isDoubles: gameState.isDoubles,
      onPropertyTapped: (prop) {
        ref.read(gameProvider.notifier).inspectProperty(prop);
      },
    )
      ..size = Vector2(boardSize, boardSize)
      ..position = Vector2(posX, posY);

    add(board!);

    for (int i = 0; i < gameState.players.length; i++) {
      var player = gameState.players[i];
      var token = PlayerTokenComponent(
        player: player,
        playerIndex: i,
        boardWidth: boardSize,
        boardHeight: boardSize,
      );
      board!.add(token);
      tokens.add(token);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final gameState = ref.read(gameProvider);

    // Sync board properties, players, and dice state
    board?.updateData(
      newProperties: gameState.properties,
      newPlayers: gameState.players,
      dice: gameState.lastDiceRoll,
      doubles: gameState.isDoubles,
    );

    // Sync tokens with state
    for (int i = 0; i < tokens.length && i < gameState.players.length; i++) {
      tokens[i].updatePlayer(gameState.players[i]);
    }
  }
}
