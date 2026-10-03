import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/player.dart';
import 'board_component.dart';

class PlayerTokenComponent extends PositionComponent {
  Player player;
  final int playerIndex;
  double boardWidth;
  double boardHeight;

  // Cached 3D sculpted pawn figurine display list
  ui.Picture? _cachedPawnPicture;
  Color? _cachedColor;
  PlayerToken? _cachedToken;
  double _cachedPW = 0.0;
  double _cachedPH = 0.0;

  // Waypoint path animation
  int _currentPosIndex = 0;
  final List<int> _movementPath = [];
  double _stepProgress = 0.0;
  bool _isMoving = false;
  double _hopAltitude = 0.0;
  Completer<void>? _movementCompleter;

  bool get isMoving => _isMoving || _movementPath.isNotEmpty;

  Future<void> waitForMovement() {
    if (!isMoving) return Future.value();
    _movementCompleter ??= Completer<void>();
    return _movementCompleter!.future;
  }

  void resetToPosition(int pos, {bool inJail = false}) {
    _movementPath.clear();
    _isMoving = false;
    _stepProgress = 0.0;
    _hopAltitude = 0.0;
    _currentPosIndex = pos;
    player = player.copyWith(position: pos, isInJail: inJail);
    if (_movementCompleter != null && !_movementCompleter!.isCompleted) {
      _movementCompleter!.complete();
      _movementCompleter = null;
    }
    _updatePositionOnBoard();
  }

  PlayerTokenComponent({
    required this.player,
    required this.playerIndex,
    required this.boardWidth,
    required this.boardHeight,
  }) {
    _currentPosIndex = player.position;
    _updatePositionOnBoard();
  }

  @override
  void onRemove() {
    _cachedPawnPicture?.dispose();
    _cachedPawnPicture = null;
    super.onRemove();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _updatePositionOnBoard();
  }

  void updateBoardDimensions(double width, double height) {
    boardWidth = width;
    boardHeight = height;
    _updatePositionOnBoard();
  }

  void updatePlayer(Player updated) {
    if (player.position != updated.position || (updated.isInJail != player.isInJail)) {
      int oldPos = player.position;
      int newPos = updated.position;

      final bool isSentToJail = updated.isInJail && (!player.isInJail || (oldPos != 10 && newPos == 10));

      _movementPath.clear();
      if (_movementCompleter != null && !_movementCompleter!.isCompleted) {
        _movementCompleter!.complete();
      }
      _movementCompleter = Completer<void>();

      if (isSentToJail) {
        // MONOPOLY RULE: Sent to Jail moves directly to Jail WITHOUT passing GO and WITHOUT collecting ₹200!
        if (oldPos >= 10) {
          // Backward movement: oldPos - 1 down to 10 (never passes 0)
          for (int pos = oldPos - 1; pos >= 10; pos--) {
            _movementPath.add(pos);
          }
        } else {
          // Forward movement from <10 up to 10 (e.g. from 7 to 10, never passes 0)
          for (int pos = oldPos + 1; pos <= 10; pos++) {
            _movementPath.add(pos);
          }
        }
        if (_movementPath.isEmpty) {
          _movementPath.add(10);
        }
        _isMoving = true;
        _stepProgress = 0.0;
      } else if (oldPos != newPos) {
        // Clockwise forward steps
        int forwardSteps = (newPos - oldPos) % 40;
        if (forwardSteps <= 0) forwardSteps += 40;

        for (int step = 1; step <= forwardSteps; step++) {
          _movementPath.add((oldPos + step) % 40);
        }
        _isMoving = true;
        _stepProgress = 0.0;
      }
    }
    player = updated;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_movementPath.isNotEmpty) {
      _isMoving = true;
      // Hop speed: 3.5 spaces per second for smooth, responsive feel
      const double speed = 3.5;
      _stepProgress += speed * dt;

      if (_stepProgress >= 1.0) {
        _currentPosIndex = _movementPath.removeAt(0);
        _stepProgress = 0.0;
        if (_movementPath.isEmpty) {
          _isMoving = false;
          _hopAltitude = 0.0;
          _currentPosIndex = player.position;
          if (_movementCompleter != null && !_movementCompleter!.isCompleted) {
            _movementCompleter!.complete();
            _movementCompleter = null;
          }
        }
      } else {
        _hopAltitude = sin(_stepProgress * pi) * 16.0;
      }
      _updatePositionOnBoard();
    } else if (_isMoving) {
      _isMoving = false;
      _hopAltitude = 0.0;
      _currentPosIndex = player.position;
      if (_movementCompleter != null && !_movementCompleter!.isCompleted) {
        _movementCompleter!.complete();
        _movementCompleter = null;
      }
      _updatePositionOnBoard();
    }
  }

  Offset getTileCenter(int index, {bool isInJail = false}) {
    if (parent is BoardComponent) {
      return (parent as BoardComponent).getTileCenter(index, isInJail: isInJail);
    }

    // Mathematical coordinate geometry derived directly from board tile specifications
    double cornerW = boardWidth * 0.13;
    double cornerH = boardHeight * 0.13;
    double spaceW = (boardWidth - (2 * cornerW)) / 9;
    double spaceH = (boardHeight - (2 * cornerH)) / 9;

    Rect r;
    if (index == 0) {
      r = Rect.fromLTWH(boardWidth - cornerW, boardHeight - cornerH, cornerW, cornerH);
    } else if (index > 0 && index < 10) {
      r = Rect.fromLTWH(boardWidth - cornerW - index * spaceW, boardHeight - cornerH, spaceW, cornerH);
    } else if (index == 10) {
      r = Rect.fromLTWH(0, boardHeight - cornerH, cornerW, cornerH);
    } else if (index > 10 && index < 20) {
      r = Rect.fromLTWH(0, boardHeight - cornerH - (index - 10) * spaceH, cornerW, spaceH);
    } else if (index == 20) {
      r = Rect.fromLTWH(0, 0, cornerW, cornerH);
    } else if (index > 20 && index < 30) {
      r = Rect.fromLTWH(cornerW + (index - 20 - 1) * spaceW, 0, spaceW, cornerH);
    } else if (index == 30) {
      r = Rect.fromLTWH(boardWidth - cornerW, 0, cornerW, cornerH);
    } else {
      r = Rect.fromLTWH(boardWidth - cornerW, cornerH + (index - 30 - 1) * spaceH, cornerW, spaceH);
    }

    if (index == 10 && isInJail) {
      final innerCell = Rect.fromLTWH(r.left + r.width * 0.35, r.top, r.width * 0.65, r.height * 0.65);
      return innerCell.center;
    }
    return r.center;
  }

  void _updatePositionOnBoard() {
    double cornerW = boardWidth * 0.13;
    double cornerH = boardHeight * 0.13;
    double spaceW = (boardWidth - (2 * cornerW)) / 9;
    double spaceH = (boardHeight - (2 * cornerH)) / 9;

    Offset curPos = getTileCenter(
      _currentPosIndex,
      isInJail: (_currentPosIndex == 10 && player.isInJail && _movementPath.isEmpty),
    );

    double curX = curPos.dx;
    double curY = curPos.dy;

    if (_movementPath.isNotEmpty) {
      final nextTile = _movementPath.first;
      final nextPos = getTileCenter(
        nextTile,
        isInJail: (nextTile == 10 && player.isInJail && _movementPath.length == 1),
      );
      curX = curPos.dx + (nextPos.dx - curPos.dx) * _stepProgress;
      curY = curPos.dy + (nextPos.dy - curPos.dy) * _stepProgress;
    }

    // Direct mathematical offset for 4 players (avoids per-frame List allocation)
    final double signX = (playerIndex % 2 == 0) ? -1.0 : 1.0;
    final double signY = (playerIndex < 2) ? -1.0 : 1.0;
    final double offX = signX * (spaceW * 0.14);
    final double offY = signY * (spaceH * 0.12);

    double pawnWidth = (spaceW * 0.52).clamp(13.0, 32.0);
    double pawnHeight = pawnWidth * 1.38;
    size = Vector2(pawnWidth, pawnHeight + 20);

    // Position component so bottom-center is at (curX + offX, curY + offY - _hopAltitude)
    position = Vector2(
      curX + offX - pawnWidth / 2,
      curY + offY - pawnHeight - _hopAltitude,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final pW = width;
    final pH = height - 20;
    if (pW <= 0 || pH <= 0) return;
    final centerX = pW / 2;
    final groundY = pH + _hopAltitude; // Ground level for shadow

    // ==================== 1. DYNAMIC GROUND SHADOW ====================
    final double shadowScale = max(0.5, 1.0 - (_hopAltitude / 30.0));
    final double shadowAlpha = max(0.15, 0.45 - (_hopAltitude / 50.0));

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
    if (_cachedPawnPicture == null ||
        _cachedColor != player.color ||
        _cachedToken != player.token ||
        _cachedPW != pW ||
        _cachedPH != pH) {
      _recordPawnPicture(pW, pH);
    }
    canvas.drawPicture(_cachedPawnPicture!);
  }

  void _recordPawnPicture(double pW, double pH) {
    _cachedPawnPicture?.dispose();
    _cachedColor = player.color;
    _cachedToken = player.token;
    _cachedPW = pW;
    _cachedPH = pH;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final centerX = pW / 2;

    final pawnColor = player.color;
    final darkShade = Color.lerp(pawnColor, Colors.black, 0.45)!;
    final lightShade = Color.lerp(pawnColor, Colors.white, 0.45)!;

    // --- A. Weighted Pedestal Base ---
    final baseH = pW * 0.36;
    final baseRect = Rect.fromCenter(
      center: Offset(centerX, pH - baseH * 0.4),
      width: pW * 0.88,
      height: baseH,
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
      ..strokeWidth = 1.1;
    canvas.drawOval(baseRect, rimPaint);

    // --- B. Tapered Torso / Body ---
    final torsoTop = pH * 0.36;
    final torsoBottom = pH - baseH * 0.45;
    final bodyPath = Path();
    bodyPath.moveTo(centerX - pW * 0.34, torsoBottom);
    bodyPath.cubicTo(
      centerX - pW * 0.26, torsoBottom - (torsoBottom - torsoTop) * 0.5,
      centerX - pW * 0.16, torsoTop + (torsoBottom - torsoTop) * 0.2,
      centerX - pW * 0.13, torsoTop,
    );
    bodyPath.lineTo(centerX + pW * 0.13, torsoTop);
    bodyPath.cubicTo(
      centerX + pW * 0.16, torsoTop + (torsoBottom - torsoTop) * 0.2,
      centerX + pW * 0.26, torsoBottom - (torsoBottom - torsoTop) * 0.5,
      centerX + pW * 0.34, torsoBottom,
    );
    bodyPath.close();

    final bodyRect = Rect.fromLTRB(centerX - pW * 0.34, torsoTop, centerX + pW * 0.34, torsoBottom);
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [lightShade, pawnColor, darkShade],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bodyRect);
    canvas.drawPath(bodyPath, bodyPaint);

    // --- C. Metallic Collar Ring ---
    final collarRect = Rect.fromCenter(
      center: Offset(centerX, torsoTop),
      width: pW * 0.35,
      height: max(3.0, pW * 0.12),
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
    final headCenter = Offset(centerX, torsoTop - headRadius + 0.5);
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
    _drawEngravedPawnIcon(canvas, Offset(centerX, (torsoTop + torsoBottom) / 2));

    _cachedPawnPicture = recorder.endRecording();
  }

  void _drawEngravedPawnIcon(Canvas canvas, Offset center) {
    final iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    switch (player.token) {
      case PlayerToken.houseboat:
        canvas.drawCircle(center, 3.2, iconPaint);
        canvas.drawLine(center + const Offset(-4.0, 0), center + const Offset(4.0, 0), iconPaint);
        canvas.drawLine(center + const Offset(0, -4.0), center + const Offset(0, 4.0), iconPaint);
        break;
      case PlayerToken.elephant:
        final path = Path();
        path.moveTo(center.dx - 3.5, center.dy + 2.5);
        path.lineTo(center.dx - 3.5, center.dy - 2.5);
        path.lineTo(center.dx - 1.2, center.dy);
        path.lineTo(center.dx, center.dy - 2.5);
        path.lineTo(center.dx + 1.2, center.dy);
        path.lineTo(center.dx + 3.5, center.dy - 2.5);
        path.lineTo(center.dx + 3.5, center.dy + 2.5);
        path.close();
        canvas.drawPath(path, iconPaint);
        break;
      case PlayerToken.chayaGlass:
        canvas.drawRect(Rect.fromCenter(center: center, width: 5.5, height: 5.5), iconPaint);
        break;
      case PlayerToken.ksrtcBus:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: 6.5, height: 4.5), const Radius.circular(1)),
          iconPaint,
        );
        break;
      default:
        canvas.drawCircle(center, 2.2, Paint()..color = Colors.white.withValues(alpha: 0.9));
        break;
    }
  }
}

