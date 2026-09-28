import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/player.dart';

class PlayerTokenComponent extends PositionComponent {
  Player player;
  final int playerIndex;
  final double boardWidth;
  final double boardHeight;

  // Hop stepping animation
  double _currentTile = 0.0;
  double _targetTile = 0.0;
  bool _isMoving = false;
  double _hopAltitude = 0.0;

  PlayerTokenComponent({
    required this.player,
    required this.playerIndex,
    required this.boardWidth,
    required this.boardHeight,
  }) {
    _currentTile = player.position.toDouble();
    _targetTile = player.position.toDouble();
  }

  void updatePlayer(Player updated) {
    if (player.position != updated.position) {
      int oldPos = player.position;
      int newPos = updated.position;

      // Calculate clockwise forward steps
      int forwardSteps = (newPos - oldPos) % 40;
      if (forwardSteps < 0) forwardSteps += 40;

      _targetTile = _currentTile + forwardSteps;
      _isMoving = true;
    }
    player = updated;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isMoving) {
      double speed = 2.8; // Reduced steps per second for clear, smooth jumping animation
      double step = speed * dt;
      if (_currentTile < _targetTile) {
        _currentTile += step;
        if (_currentTile >= _targetTile) {
          _currentTile = _targetTile;
          _isMoving = false;
          _hopAltitude = 0.0;
        } else {
          // Compute hop arc for each tile step
          double subProgress = _currentTile % 1.0;
          _hopAltitude = sin(subProgress * pi) * 16.0;
        }
      } else {
        _isMoving = false;
        _hopAltitude = 0.0;
      }
    } else {
      _hopAltitude = 0.0;
    }

    _updatePositionOnBoard();
  }

  void _updatePositionOnBoard() {
    double cornerW = boardWidth * 0.13;
    double cornerH = boardHeight * 0.13;
    double spaceW = (boardWidth - (2 * cornerW)) / 9;
    double spaceH = (boardHeight - (2 * cornerH)) / 9;

    int posIndex = (_currentTile % 40).floor();
    double subProgress = _currentTile % 1.0;

    Vector2 currentPos = _calculateTileWalkway(posIndex, cornerW, cornerH, spaceW, spaceH);
    Vector2 nextPos = _calculateTileWalkway((posIndex + 1) % 40, cornerW, cornerH, spaceW, spaceH);

    // Interpolate path
    double curX = currentPos.x + (nextPos.x - currentPos.x) * subProgress;
    double curY = currentPos.y + (nextPos.y - currentPos.y) * subProgress;

    // Dedicated offset for up to 4 pawns so they never overlap or cover tile text
    final offsets = [
      Vector2(-spaceW * 0.16, -spaceH * 0.12),
      Vector2(spaceW * 0.16, -spaceH * 0.12),
      Vector2(-spaceW * 0.16, spaceH * 0.12),
      Vector2(spaceW * 0.16, spaceH * 0.12),
    ];
    final offset = offsets[playerIndex % offsets.length];

    double pawnWidth = spaceW * 0.52;
    double pawnHeight = spaceW * 0.72;
    size = Vector2(pawnWidth, pawnHeight + 24);

    // Apply hop altitude vertically
    position = Vector2(curX + offset.x - pawnWidth / 2, curY + offset.y - pawnHeight - _hopAltitude);
  }

  Vector2 _calculateTileWalkway(int index, double cornerW, double cornerH, double spaceW, double spaceH) {
    // Positions pawns on the inner half of each space so text & price remain 100% visible
    if (index == 0) {
      return Vector2(boardWidth - cornerW * 0.5, boardHeight - cornerH * 0.5);
    } else if (index > 0 && index < 10) {
      // Bottom edge: pawns walk along the upper/inner half of the tile
      double rightOffset = cornerW + (index - 0.5) * spaceW;
      return Vector2(boardWidth - rightOffset, boardHeight - cornerH * 0.75);
    } else if (index == 10) {
      return Vector2(cornerW * 0.5, boardHeight - cornerH * 0.5);
    } else if (index > 10 && index < 20) {
      // Left edge: pawns walk along the right/inner half of the tile
      double bottomOffset = cornerH + (index - 10 - 0.5) * spaceH;
      return Vector2(cornerW * 0.75, boardHeight - bottomOffset);
    } else if (index == 20) {
      return Vector2(cornerW * 0.5, cornerH * 0.5);
    } else if (index > 20 && index < 30) {
      // Top edge: pawns walk along the lower/inner half of the tile
      double leftOffset = cornerW + (index - 20 - 0.5) * spaceW;
      return Vector2(leftOffset, cornerH * 0.75);
    } else if (index == 30) {
      return Vector2(boardWidth - cornerW * 0.5, cornerH * 0.5);
    } else {
      // Right edge: pawns walk along the left/inner half of the tile
      double topOffset = cornerH + (index - 30 - 0.5) * spaceH;
      return Vector2(boardWidth - cornerW * 0.75, topOffset);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final pW = width;
    final pH = height - 24;
    final centerX = pW / 2;
    final groundY = pH + _hopAltitude; // Ground level for shadow

    // ==================== 1. DYNAMIC GROUND SHADOW ====================
    // Shadow stays on the board surface and scales based on hop altitude
    double shadowScale = max(0.5, 1.0 - (_hopAltitude / 30.0));
    double shadowAlpha = max(0.15, 0.45 - (_hopAltitude / 50.0));

    final shadowRect = Rect.fromCenter(
      center: Offset(centerX, groundY),
      width: pW * 0.9 * shadowScale,
      height: pW * 0.35 * shadowScale,
    );
    canvas.drawOval(
      shadowRect,
      Paint()
        ..color = Colors.black.withValues(alpha: shadowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ==================== 2. 3D SCULPTED PAWN FIGURINE ====================
    final pawnColor = player.color;
    final darkShade = Color.lerp(pawnColor, Colors.black, 0.45)!;
    final lightShade = Color.lerp(pawnColor, Colors.white, 0.45)!;

    // --- A. Weighted Pedestal Base ---
    final baseRect = Rect.fromCenter(
      center: Offset(centerX, pH - 4),
      width: pW * 0.85,
      height: pW * 0.38,
    );

    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [lightShade, pawnColor, darkShade],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(baseRect);
    canvas.drawOval(baseRect, basePaint);

    // Gold rim around base
    final rimPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(baseRect, rimPaint);

    // --- B. Tapered Torso / Body ---
    final bodyPath = Path();
    bodyPath.moveTo(centerX - pW * 0.36, pH - 6);
    bodyPath.cubicTo(
      centerX - pW * 0.28, pH - 16,
      centerX - pW * 0.16, pH - 24,
      centerX - pW * 0.14, pH - 28,
    );
    bodyPath.lineTo(centerX + pW * 0.14, pH - 28);
    bodyPath.cubicTo(
      centerX + pW * 0.16, pH - 24,
      centerX + pW * 0.28, pH - 16,
      centerX + pW * 0.36, pH - 6,
    );
    bodyPath.close();

    final bodyRect = Rect.fromLTWH(centerX - pW * 0.36, pH - 28, pW * 0.72, 22);
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [lightShade, pawnColor, darkShade],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bodyRect);
    canvas.drawPath(bodyPath, bodyPaint);

    // --- C. Metallic Collar Ring ---
    final collarRect = Rect.fromCenter(
      center: Offset(centerX, pH - 28),
      width: pW * 0.36,
      height: 4.5,
    );
    final collarPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF176), Color(0xFFD4AF37), Color(0xFFB8860B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(collarRect);
    canvas.drawRRect(RRect.fromRectAndRadius(collarRect, const Radius.circular(2)), collarPaint);

    // --- D. Spherical Polished Head ---
    final headRadius = pW * 0.26;
    final headCenter = Offset(centerX, pH - 28 - headRadius + 1);
    final headRect = Rect.fromCircle(center: headCenter, radius: headRadius);

    final headPaint = Paint()
      ..shader = RadialGradient(
        colors: [lightShade, pawnColor, darkShade],
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
      ).createShader(headRect);
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // Specular Shine Glint on Head
    final shineCenter = headCenter + Offset(-headRadius * 0.35, -headRadius * 0.35);
    canvas.drawCircle(
      shineCenter,
      headRadius * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );

    // --- E. Engraved Identity Icon on Torso ---
    _drawEngravedPawnIcon(canvas, Offset(centerX, pH - 16));
  }

  void _drawEngravedPawnIcon(Canvas canvas, Offset center) {
    final iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    switch (player.token) {
      case PlayerToken.houseboat:
        // Mini Ship Helm
        canvas.drawCircle(center, 3.5, iconPaint);
        canvas.drawLine(center + const Offset(-4.5, 0), center + const Offset(4.5, 0), iconPaint);
        canvas.drawLine(center + const Offset(0, -4.5), center + const Offset(0, 4.5), iconPaint);
        break;
      case PlayerToken.elephant:
        // Mini Crown
        final path = Path();
        path.moveTo(center.dx - 4, center.dy + 3);
        path.lineTo(center.dx - 4, center.dy - 3);
        path.lineTo(center.dx - 1.5, center.dy);
        path.lineTo(center.dx, center.dy - 3);
        path.lineTo(center.dx + 1.5, center.dy);
        path.lineTo(center.dx + 4, center.dy - 3);
        path.lineTo(center.dx + 4, center.dy + 3);
        path.close();
        canvas.drawPath(path, iconPaint);
        break;
      case PlayerToken.chayaGlass:
        // Mini Cup
        canvas.drawRect(Rect.fromCenter(center: center, width: 6, height: 6), iconPaint);
        break;
      case PlayerToken.ksrtcBus:
        // Mini Bus
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: 7, height: 5), const Radius.circular(1)), iconPaint);
        break;
      default:
        // Star Gem
        canvas.drawCircle(center, 2.5, Paint()..color = Colors.white.withValues(alpha: 0.9));
        break;
    }
  }
}
