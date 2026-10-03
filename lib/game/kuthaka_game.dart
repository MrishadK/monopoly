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

  void setHighlightedProperties(Set<String> ids, [Color? color]) {
    highlightedPropertyIds = ids;
    highlightColor = color;
    board?.highlightedPropertyIds = ids;
    board?.highlightColor = color;
  }

  bool get isAnyTokenMoving => tokens.any((t) => t.isMoving);

  void syncPlayerToken(Player updated) {
    final token = tokens.where((t) => t.player.id == updated.id).firstOrNull;
    if (token != null) {
      token.updatePlayer(updated);
    }
  }

  Future<void> waitForPlayerMovement(String playerId) async {
    final token = tokens.where((t) => t.player.id == playerId).firstOrNull;
    if (token != null) {
      await token.waitForMovement();
    }
  }

  Future<void> waitForAllMovements() async {
    final movingTokens = tokens.where((t) => t.isMoving).toList();
    if (movingTokens.isNotEmpty) {
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
  }

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

    // Calculate optimal board size to preserve clearance for top header and bottom HUDs
    final bool isPortrait = size.y > size.x;
    double topPadding = isPortrait ? 134.0 : 66.0;
    // Increased bottom padding to accommodate both bottom docks
    double bottomPadding = isPortrait ? 144.0 : 130.0; 

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
      highlightedPropertyIds: highlightedPropertyIds,
      highlightColor: highlightColor,
      onPropertyTapped: (prop) {
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
      highlightedProperties: highlightedPropertyIds,
      customHighlightColor: highlightColor,
    );

    // Sync tokens with state
    for (int i = 0; i < tokens.length && i < gameState.players.length; i++) {
      tokens[i].updatePlayer(gameState.players[i]);
    }
  }
}
