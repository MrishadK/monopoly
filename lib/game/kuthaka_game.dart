import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../../ui/theme/theme_provider.dart';
import '../../models/property.dart';
import '../../models/player.dart';
import 'components/board_component.dart';
import 'components/player_token_component.dart';

class KuthakaGame extends FlameGame {
  final WidgetRef ref;

  KuthakaGame(this.ref) {
    try {
      ref.read(gameProvider.notifier).attachGame(this);
    } catch (_) {}
  }

  @override
  void onRemove() {
    try {
      ref.read(gameProvider.notifier).detachGame(this);
    } catch (_) {}
    super.onRemove();
  }

  BoardComponent? board;
  List<PlayerTokenComponent> tokens = [];
  double _lastWidth = 0;
  double _lastHeight = 0;

  Set<String> highlightedPropertyIds = {};
  Color? highlightColor;
  void Function(Property prop)? onPropertyTappedCustom;

  // On-demand rendering management for 0% idle GPU usage
  int _idleFramesRemaining = 12;

  void wakeEngine({int frames = 6}) {
    _idleFramesRemaining = max(_idleFramesRemaining, frames);
    if (paused) {
      resumeEngine();
    }
  }

  void setHighlightedProperties(Set<String> ids, [Color? color]) {
    highlightedPropertyIds = ids;
    highlightColor = color;
    board?.highlightedPropertyIds = ids;
    board?.highlightColor = color;
    wakeEngine(frames: 6);
  }

  bool get isAnyTokenMoving => tokens.any((t) => t.isMoving);

  void syncPlayerToken(Player updated) {
    final token = tokens.where((t) => t.player.id == updated.id).firstOrNull;
    if (token != null) {
      token.updatePlayer(updated);
      wakeEngine(frames: 6);
    }
  }

  Future<void> waitForPlayerMovement(String playerId) async {
    final token = tokens.where((t) => t.player.id == playerId).firstOrNull;
    if (token != null) {
      wakeEngine(frames: 6);
      await token.waitForMovement();
    }
  }

  Future<void> waitForAllMovements() async {
    final movingTokens = tokens.where((t) => t.isMoving).toList();
    if (movingTokens.isNotEmpty) {
      wakeEngine(frames: 6);
      await Future.wait(movingTokens.map((t) => t.waitForMovement()));
    }
  }

  void resetTokens(List<Player> resetPlayers) {
    for (int i = 0; i < resetPlayers.length && i < tokens.length; i++) {
      tokens[i].resetToPosition(0);
      tokens[i].player = resetPlayers[i];
    }
    highlightedPropertyIds.clear();
    highlightColor = null;
    board?.highlightedPropertyIds.clear();
    board?.highlightColor = null;
    wakeEngine(frames: 8);
  }

  void onGameStateChanged(GameState gameState) {
    if (board == null) return;

    // 1. Ensure token count matches player count
    if (tokens.length != gameState.players.length) {
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

    // 2. Sync token data
    for (int i = 0; i < tokens.length && i < gameState.players.length; i++) {
      tokens[i].updatePlayer(gameState.players[i]);
    }

    // 3. Sync board properties
    final isDark = ref.read(themeModeProvider.notifier).isDark;
    board?.updateData(
      newProperties: gameState.properties,
      newPlayers: gameState.players,
      dice: gameState.lastDiceRoll,
      doubles: gameState.isDoubles,
      isDark: isDark,
      highlightedProperties: highlightedPropertyIds,
      customHighlightColor: highlightColor,
    );

    wakeEngine(frames: 6);
  }

  void onThemeChanged(bool isDark) {
    if (board == null) return;
    board?.updateData(
      newProperties: board!.properties,
      newPlayers: board!.players,
      dice: board!.lastDiceRoll,
      doubles: board!.isDoubles,
      isDark: isDark,
      highlightedProperties: highlightedPropertyIds,
      customHighlightColor: highlightColor,
    );
    wakeEngine(frames: 6);
  }

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _layoutBoard();
    wakeEngine(frames: 12);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0 && size.y > 0 && (size.x != _lastWidth || size.y != _lastHeight)) {
      _layoutBoard();
      wakeEngine(frames: 6);
    }
  }

  void _layoutBoard() {
    if (size.x <= 0 || size.y <= 0) return;
    _lastWidth = size.x;
    _lastHeight = size.y;

    // Calculate optimal board size to guarantee zero overlap with top header, player cards, and bottom docks
    final bool isPortrait = size.y > size.x;
    // Top bar is at y=8..50, player cards are at y=54..108 (or up to ~168 on portrait with 4 players).
    // Ensuring generous clearance so the Monopoly board NEVER overlaps player cards or headers under any aspect ratio.
    final double topPadding = isPortrait ? 180.0 : 125.0;
    final double bottomPadding = isPortrait ? 144.0 : 135.0; 

    // Board is horizontally centered with slight padding
    double availableWidth = size.x - 16.0; 
    double availableHeight = size.y - (topPadding + bottomPadding);
    double boardSize = min(availableWidth, availableHeight);
    boardSize = max(boardSize, 260); // Minimum sensible size

    // Perfectly center horizontally
    double posX = (size.x - boardSize) / 2;
    
    // Perfectly center vertically within the available space
    double verticalSlack = max(0.0, availableHeight - boardSize);
    double posY = topPadding + (verticalSlack / 2);

    final gameState = ref.read(gameProvider);
    final isDark = ref.read(themeModeProvider.notifier).isDark;

    // If board already exists, update its dimensions and existing tokens in-place
    if (board != null) {
      board!.size.setValues(boardSize, boardSize);
      board!.position.setValues(posX, posY);
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
      highlightedPropertyIds: highlightedPropertyIds,
      highlightColor: highlightColor,
      onPropertyTapped: (prop) {
        wakeEngine(frames: 4);
        if (onPropertyTappedCustom != null) {
          onPropertyTappedCustom!(prop);
        } else {
          ref.read(gameProvider.notifier).inspectProperty(prop);
        }
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

    if (isAnyTokenMoving) {
      _idleFramesRemaining = 6;
    } else if (_idleFramesRemaining > 0) {
      _idleFramesRemaining--;
    } else if (!paused) {
      pauseEngine();
    }
  }
}
