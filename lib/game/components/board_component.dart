import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../models/property.dart';
import '../../models/player.dart';
import '../../data/game_data.dart';
import '../kuthaka_game.dart';

class BoardComponent extends PositionComponent with TapCallbacks, HasGameReference<KuthakaGame> {
  Map<String, Property> properties;
  List<Player> players;
  List<int> lastDiceRoll;
  bool isDoubles;
  bool isDark;
  final void Function(Property property)? onPropertyTapped;

  ui.Image? boardImage;

  Set<String> _highlightedPropertyIds = {};
  Set<String> get highlightedPropertyIds => _highlightedPropertyIds;
  set highlightedPropertyIds(Set<String> value) {
    _highlightedPropertyIds = value;
    _boardNeedsRepaint = true;
  }

  Color? _highlightColor;
  Color? get highlightColor => _highlightColor;
  set highlightColor(Color? value) {
    _highlightColor = value;
    _boardNeedsRepaint = true;
  }

  // Display-List Caching for 60+ FPS zero-overhead board rendering
  ui.Picture? _cachedBoardPicture;
  bool _boardNeedsRepaint = true;

  // Precomputed geometry lookups
  final List<Rect> _cachedSpaceRects = List.filled(40, Rect.zero);
  final List<Offset> _cachedTileCenters = List.filled(40, Offset.zero);
  Offset _cachedJailCellCenter = Offset.zero;
  Offset _cachedVisitingCenter = Offset.zero;
  double _lastGeomWidth = -1;
  double _lastGeomHeight = -1;

  BoardComponent({
    required this.properties,
    required this.players,
    required this.lastDiceRoll,
    this.isDoubles = false,
    this.isDark = false,
    this.onPropertyTapped,
    Set<String> highlightedPropertyIds = const {},
    Color? highlightColor,
  }) {
    _highlightedPropertyIds = highlightedPropertyIds;
    _highlightColor = highlightColor;
  }

  void _recomputeCachedGeometry() {
    if (size.x <= 0 || size.y <= 0) return;
    _lastGeomWidth = size.x;
    _lastGeomHeight = size.y;

    // Mathematical coordinate geometry matching assets/images/board.png (1254 x 1254)
    final cornerW = size.x * 0.1555;
    final cornerH = size.y * 0.1555;
    final spaceW = (size.x - (2 * cornerW)) / 9;
    final spaceH = (size.y - (2 * cornerH)) / 9;

    for (int i = 0; i < 40; i++) {
      final r = _getSpaceRect(i, cornerW, cornerH, spaceW, spaceH);
      _cachedSpaceRects[i] = r;
      if (i == 10) {
        // Locked up inside jail cell (behind bars)
        _cachedJailCellCenter = Offset(r.left + r.width * 0.50, r.top + r.height * 0.44);
        // Just Visiting walkway (below cell bars, safely inside corner tile)
        _cachedVisitingCenter = Offset(r.left + r.width * 0.50, r.top + r.height * 0.72);
      }
      _cachedTileCenters[i] = r.center;
    }
  }

  Rect getSpaceRect(int index) {
    if (index >= 0 && index < 40 && _lastGeomWidth == size.x && _lastGeomHeight == size.y) {
      return _cachedSpaceRects[index];
    }
    double cornerW = size.x * 0.1555;
    double cornerH = size.y * 0.1555;
    double spaceW = (size.x - (2 * cornerW)) / 9;
    double spaceH = (size.y - (2 * cornerH)) / 9;
    return _getSpaceRect(index, cornerW, cornerH, spaceW, spaceH);
  }

  Offset getTileCenter(int index, {bool isInJail = false}) {
    if (index >= 0 && index < 40 && _lastGeomWidth == size.x && _lastGeomHeight == size.y) {
      if (index == 10) {
        return isInJail ? _cachedJailCellCenter : _cachedVisitingCenter;
      }
      return _cachedTileCenters[index];
    }
    final r = getSpaceRect(index);
    if (index == 10) {
      return isInJail
          ? Offset(r.left + r.width * 0.50, r.top + r.height * 0.44)
          : Offset(r.left + r.width * 0.50, r.top + r.height * 0.72);
    }
    return r.center;
  }

  Rect _getSpaceRect(int index, double cornerW, double cornerH, double spaceW, double spaceH) {
    if (index == 0) {
      // Bottom-right corner (Start)
      return Rect.fromLTWH(size.x - cornerW, size.y - cornerH, cornerW, cornerH);
    } else if (index > 0 && index < 10) {
      // Bottom row (from right to left: 1=Vengeri ... 9=Fort Kochi)
      return Rect.fromLTWH(size.x - cornerW - index * spaceW, size.y - cornerH, spaceW, cornerH);
    } else if (index == 10) {
      // Bottom-left corner (Central Lockup / Just Visiting)
      return Rect.fromLTWH(0, size.y - cornerH, cornerW, cornerH);
    } else if (index > 10 && index < 20) {
      // Left column (from bottom to top: 11=Marine Drive ... 19=Athirappilly)
      return Rect.fromLTWH(0, size.y - cornerH - (index - 10) * spaceH, cornerW, spaceH);
    } else if (index == 20) {
      // Top-left corner (Chaya Kada / Free Rest)
      return Rect.fromLTWH(0, 0, cornerW, cornerH);
    } else if (index > 20 && index < 30) {
      // Top row (from left to right: 21=Guruvayur ... 29=Munnar)
      return Rect.fromLTWH(cornerW + (index - 21) * spaceW, 0, spaceW, cornerH);
    } else if (index == 30) {
      // Top-right corner (Police Station / Go to Lockup)
      return Rect.fromLTWH(size.x - cornerW, 0, cornerW, cornerH);
    } else {
      // Right column (from top to bottom: 31=Wayanad ... 39=Kovalam)
      return Rect.fromLTWH(size.x - cornerW, cornerH + (index - 31) * spaceH, cornerW, spaceH);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _recomputeCachedGeometry();
    _boardNeedsRepaint = true;
  }

  @override
  void onRemove() {
    _cachedBoardPicture?.dispose();
    _cachedBoardPicture = null;
    super.onRemove();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _recomputeCachedGeometry();
    try {
      boardImage = await Flame.images.load('board.png');
      _boardNeedsRepaint = true;
      try {
        game.wakeEngine(frames: 6);
      } catch (_) {}
    } catch (e) {
      debugPrint('Could not load board.png via Flame.images: $e');
      try {
        final byteData = await rootBundle.load('assets/images/board.png');
        final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        boardImage = frame.image;
        _boardNeedsRepaint = true;
        try {
          game.wakeEngine(frames: 6);
        } catch (_) {}
      } catch (e2) {
        debugPrint('Fallback board image loading failed: $e2');
      }
    }
  }

  bool _havePropertiesChanged(Map<String, Property> newProps) {
    if (identical(properties, newProps)) return false;
    if (properties.length != newProps.length) return true;
    for (final entry in newProps.entries) {
      final old = properties[entry.key];
      if (old == null) return true;
      if (old.ownerId != entry.value.ownerId ||
          old.currentLevel != entry.value.currentLevel ||
          old.isMortgaged != entry.value.isMortgaged) {
        return true;
      }
    }
    return false;
  }

  bool _havePlayersChanged(List<Player> newPlayers) {
    if (identical(players, newPlayers)) return false;
    if (players.length != newPlayers.length) return true;
    for (int i = 0; i < players.length; i++) {
      if (players[i].id != newPlayers[i].id ||
          players[i].color != newPlayers[i].color ||
          players[i].name != newPlayers[i].name) {
        return true;
      }
    }
    return false;
  }

  bool _haveHighlightsChanged(Set<String>? newHighlights, Color? newColor) {
    if (newColor != _highlightColor) return true;
    if (newHighlights == null) return false;
    if (_highlightedPropertyIds.length != newHighlights.length) return true;
    for (final id in newHighlights) {
      if (!_highlightedPropertyIds.contains(id)) return true;
    }
    return false;
  }

  void updateData({
    required Map<String, Property> newProperties,
    required List<Player> newPlayers,
    required List<int> dice,
    required bool doubles,
    bool isDark = false,
    Set<String>? highlightedProperties,
    Color? customHighlightColor,
  }) {
    bool needsRepaint = false;
    if (this.isDark != isDark) {
      this.isDark = isDark;
      needsRepaint = true;
    }
    if (_haveHighlightsChanged(highlightedProperties, customHighlightColor)) {
      if (highlightedProperties != null) {
        _highlightedPropertyIds = highlightedProperties;
      }
      _highlightColor = customHighlightColor;
      needsRepaint = true;
    }
    if (_havePropertiesChanged(newProperties)) {
      properties = newProperties;
      needsRepaint = true;
    }
    if (_havePlayersChanged(newPlayers)) {
      players = newPlayers;
      needsRepaint = true;
    }

    lastDiceRoll = dice;
    isDoubles = doubles;

    if (needsRepaint) {
      _boardNeedsRepaint = true;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;
    if (_lastGeomWidth != size.x || _lastGeomHeight != size.y) {
      _recomputeCachedGeometry();
      _boardNeedsRepaint = true;
    }
    if (_boardNeedsRepaint || _cachedBoardPicture == null) {
      _cachedBoardPicture?.dispose();
      final recorder = ui.PictureRecorder();
      final recordingCanvas = Canvas(recorder);
      final rect = size.toRect();

      // 1. Draw pre-rendered high-definition board artwork
      if (boardImage != null) {
        final src = Rect.fromLTWH(0, 0, boardImage!.width.toDouble(), boardImage!.height.toDouble());
        recordingCanvas.drawImageRect(boardImage!, src, rect, Paint()..filterQuality = FilterQuality.medium);
      } else {
        // Fallback surface base if loading
        recordingCanvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(16)),
          Paint()..color = isDark ? const Color(0xFF0D1424) : Colors.white,
        );
      }

      // 2. Dynamic ownership banners, houses/hotels, mortgaged states, and highlights
      _drawDynamicOverlays(recordingCanvas);

      _cachedBoardPicture = recorder.endRecording();
      _boardNeedsRepaint = false;
    }
    canvas.drawPicture(_cachedBoardPicture!);
  }

  void _drawDynamicOverlays(Canvas canvas) {
    for (int i = 0; i < 40; i++) {
      final space = GameData.spaces[i];
      final rect = getSpaceRect(i);

      if (space.propertyId != null) {
        final prop = properties[space.propertyId];
        if (prop != null) {
          // Check ownership
          if (prop.ownerId != null) {
            final owner = players.where((p) => p.id == prop.ownerId).firstOrNull;
            if (owner != null) {
              _drawOwnerIndicator(canvas, i, rect, owner, prop);
              if (prop.currentLevel > 0) {
                _drawBuildings(canvas, i, rect, prop.currentLevel);
              }
            }
          }

          // Mortgaged overlay
          if (prop.isMortgaged) {
            _drawMortgagedOverlay(canvas, rect);
          }

          // Highlight overlay
          final isHighlighted = highlightedPropertyIds.contains(prop.id);
          if (isHighlighted) {
            _drawHighlight(canvas, rect);
          }
        }
      }
    }
  }

  void _drawOwnerIndicator(Canvas canvas, int index, Rect rect, Player owner, Property prop) {
    Rect cardRect;
    final double bezelX = size.x * 0.024;
    final double bezelY = size.y * 0.024;

    if (index > 0 && index < 10) {
      // Bottom row (Fort Kochi ... Vengeri)
      cardRect = Rect.fromLTWH(rect.left + 1.2, rect.top + 1.2, rect.width - 2.4, rect.height - bezelY - 2.4);
    } else if (index > 10 && index < 20) {
      // Left column (Marine Drive ... Athirappilly)
      cardRect = Rect.fromLTWH(rect.left + bezelX + 1.2, rect.top + 1.2, rect.width - bezelX - 2.4, rect.height - 2.4);
    } else if (index > 20 && index < 30) {
      // Top row (Guruvayur ... Munnar)
      cardRect = Rect.fromLTWH(rect.left + 1.2, rect.top + bezelY + 1.2, rect.width - 2.4, rect.height - bezelY - 2.4);
    } else if (index > 30) {
      // Right column (Wayanad ... Kovalam)
      cardRect = Rect.fromLTWH(rect.left + 1.2, rect.top + 1.2, rect.width - bezelX - 2.4, rect.height - 2.4);
    } else {
      return;
    }

    final color = prop.isMortgaged ? const Color(0xFF64748B) : owner.color;
    final rrect = RRect.fromRectAndRadius(cardRect, const Radius.circular(5.0));

    // Crisp owner outline framing the property card
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // Subtle inner gold luxury accent
    canvas.drawRRect(
      rrect.deflate(1.2),
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _drawBuildings(Canvas canvas, int index, Rect rect, int level) {
    // Locate the property color band facing inward
    Rect bandRect;
    final double bandDepth = min(rect.width, rect.height) * 0.28;

    if (index > 0 && index < 10) {
      // Bottom row: band is at top of tile
      bandRect = Rect.fromLTWH(rect.left + 2, rect.top + 1, rect.width - 4, bandDepth);
    } else if (index > 10 && index < 20) {
      // Left column: band is at right of tile
      bandRect = Rect.fromLTWH(rect.right - bandDepth - 1, rect.top + 2, bandDepth, rect.height - 4);
    } else if (index > 20 && index < 30) {
      // Top row: band is at bottom of tile
      bandRect = Rect.fromLTWH(rect.left + 2, rect.bottom - bandDepth - 1, rect.width - 4, bandDepth);
    } else {
      // Right column: band is at left of tile
      bandRect = Rect.fromLTWH(rect.left + 1, rect.top + 2, bandDepth, rect.height - 4);
    }

    final isHotel = level >= 5;
    final count = isHotel ? 1 : level;
    final houseColor = isHotel ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final isHorizontalBand = (index > 0 && index < 10) || (index > 20 && index < 30);

    final double bSize = isHotel ? min(bandRect.width, bandRect.height) * 0.65 : min(bandRect.width, bandRect.height) * 0.48;

    for (int k = 0; k < count; k++) {
      Offset bCenter;
      if (isHorizontalBand) {
        final step = bandRect.width / (count + 1);
        bCenter = Offset(bandRect.left + step * (k + 1), bandRect.center.dy);
      } else {
        final step = bandRect.height / (count + 1);
        bCenter = Offset(bandRect.center.dx, bandRect.top + step * (k + 1));
      }

      final bRect = Rect.fromCenter(center: bCenter, width: bSize, height: bSize);
      // Drop shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(bRect.shift(const Offset(0.5, 0.8)), const Radius.circular(1.5)),
        Paint()..color = const Color(0x60000000),
      );
      // Block body
      canvas.drawRRect(
        RRect.fromRectAndRadius(bRect, const Radius.circular(1.5)),
        Paint()..color = houseColor,
      );
      // Crisp white bevel rim
      canvas.drawRRect(
        RRect.fromRectAndRadius(bRect, const Radius.circular(1.5)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
    }
  }

  void _drawMortgagedOverlay(Canvas canvas, Rect rect) {
    canvas.save();
    canvas.clipRect(rect);
    final hatchPaint = Paint()
      ..color = const Color(0x550F172A)
      ..strokeWidth = 1.2;
    for (double i = -rect.height; i < rect.width + rect.height; i += 8) {
      canvas.drawLine(
        Offset(rect.left + i, rect.top),
        Offset(rect.left + i + rect.height, rect.bottom),
        hatchPaint,
      );
    }
    final badgeW = min(rect.width * 0.9, 42.0);
    final badgeRect = Rect.fromCenter(center: rect.center, width: badgeW, height: 11);
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(2.5)),
      Paint()..color = const Color(0xEE334155),
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: 'MORTGAGED',
        style: TextStyle(color: Colors.white, fontSize: 5.2, fontWeight: FontWeight.w900, letterSpacing: 0.3),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
    canvas.restore();
  }

  void _drawHighlight(Canvas canvas, Rect rect) {
    final hCol = highlightColor ?? const Color(0xFFD4AF37);
    // Translucent wash
    canvas.drawRect(rect, Paint()..color = hCol.withValues(alpha: 0.30));
    // Glowing border
    canvas.drawRect(
      rect.deflate(1.5),
      Paint()
        ..color = hCol
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    try {
      game.wakeEngine(frames: 4);
    } catch (_) {}
    final localPos = event.localPosition;

    for (int i = 0; i < 40; i++) {
      final r = getSpaceRect(i);
      if (r.contains(Offset(localPos.x, localPos.y))) {
        final space = GameData.spaces[i];
        if (space.propertyId != null) {
          final prop = properties[space.propertyId];
          if (prop != null && onPropertyTapped != null) {
            onPropertyTapped!(prop);
          }
        }
        break;
      }
    }
  }
}
