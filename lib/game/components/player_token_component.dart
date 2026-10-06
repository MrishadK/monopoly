import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../kuthaka_game.dart';
import '../../services/audio_service.dart';
import 'board_component.dart';

class PlayerTokenComponent extends PositionComponent with HasGameReference<KuthakaGame> {
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

  // Cached resting shadow to eliminate GPU shader recreation on every frame
  Paint? _cachedRestingShadowPaint;
  Rect? _cachedRestingShadowRect;
  double _cachedShadowPW = 0.0;
  double _cachedShadowPH = 0.0;

  // Direct flight to jail animation
  bool _isDirectFlightToJail = false;
  int _flightStartPos = 0;

  // Waypoint path animation
  int _currentPosIndex = 0;
  final List<int> _movementPath = [];
  double _stepProgress = 0.0;
  bool _isMoving = false;
  double _hopAltitude = 0.0;
  Completer<void>? _movementCompleter;

  bool get isMoving => _isMoving || _isDirectFlightToJail || _movementPath.isNotEmpty;

  Future<void> waitForMovement() {
    if (!isMoving) return Future.value();
    _movementCompleter ??= Completer<void>();
    return _movementCompleter!.future;
  }

  void resetToPosition(int pos, {bool inJail = false}) {
    _isDirectFlightToJail = false;
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
    try {
      game.wakeEngine(frames: 6);
    } catch (_) {}
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
    _cachedRestingShadowPaint = null;
    _cachedRestingShadowRect = null;
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
        // Direct flight to Central Lockup across the board (no circling around the table!)
        _flightStartPos = oldPos;
        _currentPosIndex = 10;
        _isDirectFlightToJail = true;
        _isMoving = true;
        _stepProgress = 0.0;
        _hopAltitude = 0.0;
        try {
          game.wakeEngine();
        } catch (_) {}
      } else if (oldPos != newPos) {
        _isDirectFlightToJail = false;
        // Clockwise forward steps
        int forwardSteps = (newPos - oldPos) % 40;
        if (forwardSteps <= 0) forwardSteps += 40;

        for (int step = 1; step <= forwardSteps; step++) {
          _movementPath.add((oldPos + step) % 40);
        }
        _isMoving = true;
        _stepProgress = 0.0;
        try {
          game.wakeEngine();
        } catch (_) {}
      }
    }
    player = updated;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDirectFlightToJail) {
      _isMoving = true;
      // Fly across the board in ~0.8 seconds (speed = 1.25)
      const double speed = 1.25;
      _stepProgress += speed * dt;

      if (_stepProgress >= 1.0) {
        _stepProgress = 1.0;
        _isDirectFlightToJail = false;
        _isMoving = false;
        _hopAltitude = 0.0;
        _currentPosIndex = 10;
        if (_movementCompleter != null && !_movementCompleter!.isCompleted) {
          _movementCompleter!.complete();
          _movementCompleter = null;
        }
      } else {
        // Parabolic arc while flying directly across the board
        _hopAltitude = sin(_stepProgress * pi) * 52.0;
      }
      _updatePositionOnBoard();
      return;
    }

    if (_movementPath.isNotEmpty) {
      if (!_isMoving || _stepProgress == 0.0) {
        try {
          game.ref.read(audioServiceProvider.notifier).playPawnMove();
        } catch (_) {}
      }
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
    double cornerW = boardWidth * BoardComponent.cornerRatio;
    double cornerH = boardHeight * BoardComponent.cornerRatio;
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
      r = Rect.fromLTWH(cornerW + (index - 21) * spaceW, 0, spaceW, cornerH);
    } else if (index == 30) {
      r = Rect.fromLTWH(boardWidth - cornerW, 0, cornerW, cornerH);
    } else {
      r = Rect.fromLTWH(boardWidth - cornerW, cornerH + (index - 31) * spaceH, cornerW, spaceH);
    }

    if (index == 10) {
      return isInJail
          ? Offset(r.left + r.width * 0.50, r.top + r.height * 0.35)
          : Offset(r.left + r.width * 0.50, r.top + r.height * 0.78);
    }
    
    // Shift pawn base downwards on vertical edges so it doesn't spill over into the tile above
    if ((index > 10 && index < 20) || (index > 30 && index < 40)) {
      return Offset(r.center.dx, r.center.dy + spaceH * 0.35);
    }
    return r.center;
  }

  void _updatePositionOnBoard() {
    double cornerW = boardWidth * BoardComponent.cornerRatio;
    double cornerH = boardHeight * BoardComponent.cornerRatio;
    double spaceW = (boardWidth - (2 * cornerW)) / 9;
    double spaceH = (boardHeight - (2 * cornerH)) / 9;

    Offset curPos;
    if (_isDirectFlightToJail) {
      final startPos = getTileCenter(_flightStartPos, isInJail: false);
      final destPos = getTileCenter(10, isInJail: true);
      curPos = Offset(
        startPos.dx + (destPos.dx - startPos.dx) * _stepProgress,
        startPos.dy + (destPos.dy - startPos.dy) * _stepProgress,
      );
    } else {
      curPos = getTileCenter(
        _currentPosIndex,
        isInJail: (_currentPosIndex == 10 && player.isInJail && _movementPath.isEmpty),
      );

      if (_movementPath.isNotEmpty) {
        final nextTile = _movementPath.first;
        final nextPos = getTileCenter(
          nextTile,
          isInJail: (nextTile == 10 && player.isInJail && _movementPath.length == 1),
        );
        curPos = Offset(
          curPos.dx + (nextPos.dx - curPos.dx) * _stepProgress,
          curPos.dy + (nextPos.dy - curPos.dy) * _stepProgress,
        );
      }
    }

    // Direct mathematical offset for 4 players (avoids per-frame List allocation)
    final double signX = (playerIndex % 2 == 0) ? -1.0 : 1.0;
    final double signY = (playerIndex < 2) ? -1.0 : 1.0;
    final double offX = signX * (spaceW * 0.12);
    final double offY = signY * (spaceH * 0.10);

    double pawnWidth = (spaceW * 0.52).clamp(13.0, 32.0);
    double pawnHeight = pawnWidth * 1.38;
    size.setValues(pawnWidth, pawnHeight + 20);

    // Position component so bottom-center is at (curX + offX, curY + offY - _hopAltitude)
    position.setValues(
      curPos.dx + offX - pawnWidth / 2,
      curPos.dy + offY - pawnHeight - _hopAltitude,
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
    if (_hopAltitude == 0.0) {
      // Zero-allocation pre-cached resting shadow
      if (_cachedRestingShadowPaint == null || _cachedShadowPW != pW || _cachedShadowPH != pH) {
        _cachedShadowPW = pW;
        _cachedShadowPH = pH;
        _cachedRestingShadowRect = Rect.fromCenter(
          center: Offset(centerX, groundY),
          width: pW * 0.9,
          height: pW * 0.35,
        );
        _cachedRestingShadowPaint = Paint()
          ..shader = ui.Gradient.radial(
            Offset(centerX, groundY),
            pW * 0.45,
            const [
              Color(0x73000000), // alpha 0.45
              Color(0x00000000),
            ],
          );
      }
      canvas.drawOval(_cachedRestingShadowRect!, _cachedRestingShadowPaint!);
    } else {
      // Dynamic scaling shadow while airborne hopping
      final double shadowScale = max(0.5, 1.0 - (_hopAltitude / 30.0));
      final double shadowAlpha = max(0.15, 0.45 - (_hopAltitude / 50.0));

      final shadowRect = Rect.fromCenter(
        center: Offset(centerX, groundY),
        width: pW * 0.9 * shadowScale,
        height: pW * 0.35 * shadowScale,
      );
      final shadowPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(centerX, groundY),
          pW * 0.45 * shadowScale,
          [
            Colors.black.withValues(alpha: shadowAlpha),
            Colors.black.withValues(alpha: 0.0),
          ],
        );

      canvas.drawOval(shadowRect, shadowPaint);
    }

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

