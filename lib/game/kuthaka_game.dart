import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../../ui/theme/theme_provider.dart';
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
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _layoutBoard();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0 && size.y > 0 && (size.x != _lastWidth || size.y != _lastHeight)) {
      _layoutBoard();
    }
  }

  void _layoutBoard() {
    if (size.x <= 0 || size.y <= 0) return;
    _lastWidth = size.x;
    _lastHeight = size.y;

    // Calculate optimal board size to preserve clearance for top header, bottom HUDs, and right dock
    final bool isPortrait = size.y > size.x;
    double topPadding = isPortrait ? 134.0 : 66.0;
    double bottomPadding = isPortrait ? 76.0 : 70.0;
    double rightMargin = isPortrait ? 58.0 : 68.0;
    double availableWidth = size.x - 12 - rightMargin;
    double availableHeight = size.y - (topPadding + bottomPadding);
    double boardSize = min(availableWidth, availableHeight);
    boardSize = max(boardSize, 260); // Minimum sensible size

    double posX = 8.0;
    if (size.x - rightMargin > boardSize + 16) {
      posX = (size.x - rightMargin - boardSize) / 2 + 4;
    }
    double verticalSlack = max(0.0, availableHeight - boardSize);
    double posY = topPadding + verticalSlack * 0.35;

    final gameState = ref.read(gameProvider);
    final isDark = ref.read(themeModeProvider.notifier).isDark;

    // If board already exists, update its dimensions and existing tokens in-place
    if (board != null) {
      board!.size = Vector2(boardSize, boardSize);
      board!.position = Vector2(posX, posY);
      for (final token in tokens) {
        token.updateBoardDimensions(boardSize, boardSize);
      }
      return;
    }

    board = BoardComponent(
      properties: gameState.properties,
      players: gameState.players,
      lastDiceRoll: gameState.lastDiceRoll,
      isDoubles: gameState.isDoubles,
      isDark: isDark,
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
    final isDark = ref.read(themeModeProvider.notifier).isDark;

    // Ensure all players have tokens if player list changed or loaded after initial layout
    if (board != null && tokens.length != gameState.players.length) {
      for (final t in tokens) {
        board!.remove(t);
      }
      tokens.clear();
      for (int i = 0; i < gameState.players.length; i++) {
        var player = gameState.players[i];
        var token = PlayerTokenComponent(
          player: player,
          playerIndex: i,
          boardWidth: board!.size.x,
          boardHeight: board!.size.y,
        );
        board!.add(token);
        tokens.add(token);
      }
    }

    // Sync board properties, players, and dice state
    board?.updateData(
      newProperties: gameState.properties,
      newPlayers: gameState.players,
      dice: gameState.lastDiceRoll,
      doubles: gameState.isDoubles,
      isDark: isDark,
    );

    // Sync tokens with state
    for (int i = 0; i < tokens.length && i < gameState.players.length; i++) {
      tokens[i].updatePlayer(gameState.players[i]);
    }
  }
}
