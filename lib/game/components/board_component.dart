import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/board_space.dart';
import '../../models/property.dart';
import '../../models/player.dart';
import '../../data/game_data.dart';
import '../kuthaka_game.dart';

/// Fully vectorized, hardware-cached authentic Kerala Monopoly (Kuthaka) game board.
///
/// Uses [ui.PictureRecorder] and display-list caching to render at 60+ FPS with virtually zero GPU/CPU cost.
/// Displays clear Kerala property grouping, crisp dynamic typography, landmark watermarks,
/// multi-tier visual ownership indicators (outer stripe, background tint, inward luxury flag, header medallion),
/// and authentic corner tiles (Start, Lockup, Chaya Kada, Police Station).
class BoardComponent extends PositionComponent with TapCallbacks, HasGameReference<KuthakaGame> {
  static const double cornerRatio = 0.135;

  Map<String, Property> properties;
  List<Player> players;
  List<int> lastDiceRoll;
  bool isDoubles;
  bool isDark;
  final void Function(Property property)? onPropertyTapped;

  ui.Image? dayCenterImage;
  ui.Image? nightCenterImage;

  Set<String> _highlightedPropertyIds = {};
  Set<String> get highlightedPropertyIds => _highlightedPropertyIds;
  set highlightedPropertyIds(Set<String> value) {
    _highlightedPropertyIds = value;
    try {
      game.wakeEngine(frames: 6);
    } catch (_) {}
  }

  Color? _highlightColor;
  Color? get highlightColor => _highlightColor;
  set highlightColor(Color? value) {
    _highlightColor = value;
    try {
      game.wakeEngine(frames: 6);
    } catch (_) {}
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

    final cornerW = size.x * cornerRatio;
    final cornerH = size.y * cornerRatio;
    final spaceW = (size.x - (2 * cornerW)) / 9;
    final spaceH = (size.y - (2 * cornerH)) / 9;

    for (int i = 0; i < 40; i++) {
      final r = _getSpaceRect(i, cornerW, cornerH, spaceW, spaceH);
      _cachedSpaceRects[i] = r;
      if (i == 10) {
        // Tile 10: Jail cell inside bars vs Just Visiting walkway outside bars
        _cachedJailCellCenter = Offset(r.left + r.width * 0.50, r.top + r.height * 0.35);
        _cachedVisitingCenter = Offset(r.left + r.width * 0.50, r.top + r.height * 0.78);
      }
      _cachedTileCenters[i] = r.center;
    }
  }

  Rect getSpaceRect(int index) {
    if (index >= 0 && index < 40 && _lastGeomWidth == size.x && _lastGeomHeight == size.y) {
      return _cachedSpaceRects[index];
    }
    final cornerW = size.x * cornerRatio;
    final cornerH = size.y * cornerRatio;
    final spaceW = (size.x - (2 * cornerW)) / 9;
    final spaceH = (size.y - (2 * cornerH)) / 9;
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
          ? Offset(r.left + r.width * 0.50, r.top + r.height * 0.35)
          : Offset(r.left + r.width * 0.50, r.top + r.height * 0.78);
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
  void onMount() {
    super.onMount();
    try {
      game.wakeEngine(frames: 12);
    } catch (_) {}
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

    // Center artwork loader (with Flame cache + rootBundle fallback)
    try {
      dayCenterImage = await Flame.images.load('board_center_day.jpg');
    } catch (e) {
      try {
        final byteData = await rootBundle.load('assets/images/board_center_day.jpg');
        final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        dayCenterImage = frame.image;
      } catch (_) {}
    }

    try {
      nightCenterImage = await Flame.images.load('board_center_night.jpg');
    } catch (e) {
      try {
        final byteData = await rootBundle.load('assets/images/board_center_night.jpg');
        final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        nightCenterImage = frame.image;
      } catch (_) {}
    }

    _boardNeedsRepaint = true;
    try {
      game.wakeEngine(frames: 6);
    } catch (_) {}
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
      if (customHighlightColor != null) {
        _highlightColor = customHighlightColor;
      }
      try {
        game.wakeEngine(frames: 6);
      } catch (_) {}
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
      try {
        game.wakeEngine(frames: 6);
      } catch (_) {}
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

      // 1. Board background & frame
      _drawFrame(recordingCanvas, rect);

      // 2. Center Kerala lake / logo artwork
      _drawBoardCenter(recordingCanvas, rect);

      // 3. All 40 spaces (corners, properties, utilities, railroads, taxes)
      _drawAllSpaces(recordingCanvas);

      // 4. Inward luxury owner seal extensions
      _drawOwnershipInwardExtensions(recordingCanvas);

      _cachedBoardPicture = recorder.endRecording();
      _boardNeedsRepaint = false;
    }

    // Blit hardware-cached board display list at 60+ FPS
    canvas.drawPicture(_cachedBoardPicture!);

    // 5. Dynamic interactive highlight layer (Build, Mortgage, Redeem, Sell modes)
    if (highlightedPropertyIds.isNotEmpty) {
      _drawHighlightsLayer(canvas);
    }
  }

  // ==================== FRAME ====================

  void _drawFrame(Canvas canvas, Rect rect) {
    // Soft ambient drop shadow
    final shadowPaint = Paint()
      ..color = isDark ? Colors.black.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.16);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(0, 4)), const Radius.circular(16)), shadowPaint);

    // Board table surface
    final surfacePaint = Paint()..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), surfacePaint);

    // Board outer border
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), borderPaint);
  }

  // ==================== CENTER ARTWORK ====================

  void _drawBoardCenter(Canvas canvas, Rect rect) {
    final inner = rect.deflate(rect.width * cornerRatio);
    final innerRRect = RRect.fromRectAndRadius(inner, const Radius.circular(14));

    final currentImg = isDark ? nightCenterImage : dayCenterImage;

    if (currentImg != null) {
      canvas.save();
      canvas.clipRRect(innerRRect);
      final src = Rect.fromLTWH(0, 0, currentImg.width.toDouble(), currentImg.height.toDouble());
      canvas.drawImageRect(currentImg, src, inner, Paint()..filterQuality = FilterQuality.medium);
      canvas.restore();
    } else {
      // Elegant Kerala backwater landscape gradient if image is still loading
      final fallbackPaint = Paint()
        ..shader = LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF022C22), const Color(0xFF064E3B)]
              : [const Color(0xFFE0F2FE), const Color(0xFFD1FAE5), const Color(0xFFFEF3C7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(inner);
      canvas.drawRRect(innerRRect, fallbackPaint);

      final titleSpan = TextSpan(
        text: 'KUTHAKA\n',
        style: TextStyle(
          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 4.5,
        ),
        children: [
          TextSpan(
            text: 'KERALA REAL ESTATE',
            style: TextStyle(
              color: isDark ? const Color(0xFFD4AF37) : const Color(0xFFB45309),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ],
      );
      final titlePainter = TextPainter(text: titleSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      titlePainter.layout(maxWidth: inner.width);
      titlePainter.paint(canvas, Offset(inner.center.dx - titlePainter.width / 2, inner.top + inner.height * 0.14));
    }

    // Luxury center rim border
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..color = isDark ? const Color(0xFFD4AF37).withValues(alpha: 0.6) : const Color(0xFFB45309).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ==================== ALL SPACES ====================

  void _drawAllSpaces(Canvas canvas) {
    for (int i = 0; i < 40; i++) {
      final rect = getSpaceRect(i);
      _drawSingleSpace(canvas, i, rect);
    }
  }

  void _drawSingleSpace(Canvas canvas, int index, Rect rect) {
    final space = GameData.spaces[index];

    Property? prop;
    Player? owner;
    if (space.propertyId != null) {
      prop = properties[space.propertyId];
      final ownerId = prop?.ownerId;
      if (ownerId != null) {
        owner = players.where((p) => p.id == ownerId).firstOrNull;
      }
    }

    // 1. Tile background with clear owner tint
    Color bgColor = isDark ? const Color(0xFF131B2A) : Colors.white;
    if (owner != null) {
      bgColor = prop!.isMortgaged
          ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
          : Color.alphaBlend(owner.color.withValues(alpha: isDark ? 0.35 : 0.22), bgColor);
    }
    canvas.drawRect(rect, Paint()..color = bgColor);

    // 2. Grid dividing borders
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    canvas.drawRect(rect, Paint()..color = borderCol..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // 3. Bold Owner Stripe on outer board rim
    if (owner != null) {
      _drawOwnerOuterStripe(canvas, index, rect, prop!.isMortgaged ? const Color(0xFF64748B) : owner.color);
    }

    // 4. Space contents
    if (index == 0) {
      _drawStartCorner(canvas, rect);
    } else if (index == 10) {
      _drawJailCorner(canvas, rect);
    } else if (index == 20) {
      _drawFreeParkingCorner(canvas, rect);
    } else if (index == 30) {
      _drawGoToJailCorner(canvas, rect);
    } else if (space.type == SpaceType.property) {
      _drawPropertySpace(canvas, index, rect, space, owner);
    } else {
      _drawSpecialSpace(canvas, index, rect, space, owner);
    }

    // 5. Mortgaged Hatch Pattern Overlay
    if (prop != null && prop.isMortgaged) {
      _drawMortgagedOverlay(canvas, rect);
    }
  }

  void _drawOwnerOuterStripe(Canvas canvas, int index, Rect rect, Color color) {
    const double stripeThick = 4.5;
    Rect stripeRect;
    if (index > 0 && index < 10) {
      stripeRect = Rect.fromLTWH(rect.left, rect.bottom - stripeThick, rect.width, stripeThick);
    } else if (index > 10 && index < 20) {
      stripeRect = Rect.fromLTWH(rect.left, rect.top, stripeThick, rect.height);
    } else if (index > 20 && index < 30) {
      stripeRect = Rect.fromLTWH(rect.left, rect.top, rect.width, stripeThick);
    } else if (index > 30) {
      stripeRect = Rect.fromLTWH(rect.right - stripeThick, rect.top, stripeThick, rect.height);
    } else {
      return;
    }
    canvas.drawRect(stripeRect, Paint()..color = color);
  }

  // ==================== INWARD LUXURY OWNER SEALS ====================

  void _drawOwnershipInwardExtensions(Canvas canvas) {
    for (int i = 0; i < 40; i++) {
      final space = GameData.spaces[i];
      if (space.propertyId != null) {
        final prop = properties[space.propertyId];
        if (prop != null && prop.ownerId != null) {
          final rect = getSpaceRect(i);
          _drawOwnershipInwardExtension(canvas, i, rect, prop);
        }
      }
    }
  }

  void _drawOwnershipInwardExtension(Canvas canvas, int index, Rect spaceRect, Property prop) {
    if (prop.ownerId == null) return;
    final owner = players.where((p) => p.id == prop.ownerId).firstOrNull ?? players.first;

    const double extDepth = 13.0;
    Rect extRect;
    RRect rrect;

    if (index > 0 && index < 10) {
      extRect = Rect.fromLTWH(spaceRect.left + 2, spaceRect.top - extDepth, spaceRect.width - 4, extDepth);
      rrect = RRect.fromRectAndCorners(extRect, topLeft: const Radius.circular(5), topRight: const Radius.circular(5));
    } else if (index > 10 && index < 20) {
      extRect = Rect.fromLTWH(spaceRect.right, spaceRect.top + 2, extDepth, spaceRect.height - 4);
      rrect = RRect.fromRectAndCorners(extRect, topRight: const Radius.circular(5), bottomRight: const Radius.circular(5));
    } else if (index > 20 && index < 30) {
      extRect = Rect.fromLTWH(spaceRect.left + 2, spaceRect.bottom, spaceRect.width - 4, extDepth);
      rrect = RRect.fromRectAndCorners(extRect, bottomLeft: const Radius.circular(5), bottomRight: const Radius.circular(5));
    } else if (index > 30) {
      extRect = Rect.fromLTWH(spaceRect.left - extDepth, spaceRect.top + 2, extDepth, spaceRect.height - 4);
      rrect = RRect.fromRectAndCorners(extRect, topLeft: const Radius.circular(5), bottomLeft: const Radius.circular(5));
    } else {
      return;
    }

    // Subtle drop shadow
    canvas.drawRRect(rrect.shift(const Offset(0, 1)), Paint()..color = const Color(0x40000000));

    // Owner color body
    final fillPaint = Paint()..color = prop.isMortgaged ? const Color(0xFF64748B) : owner.color;
    canvas.drawRRect(rrect, fillPaint);

    // Luxury gold accent rim
    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // Circular white medal with owner initial
    final badgeRadius = min(extRect.width, extRect.height) * 0.38;
    canvas.drawCircle(extRect.center, badgeRadius, Paint()..color = Colors.white);

    final initial = owner.name.trim().isNotEmpty ? owner.name.trim()[0].toUpperCase() : 'P';
    final textSpan = TextSpan(
      text: prop.isMortgaged ? 'M' : initial,
      style: TextStyle(
        color: prop.isMortgaged ? const Color(0xFF64748B) : owner.color,
        fontSize: badgeRadius * 1.3,
        fontWeight: FontWeight.w900,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(extRect.center.dx - tp.width / 2, extRect.center.dy - tp.height / 2));
  }

  // ==================== PROPERTY SPACE ====================

  void _drawPropertySpace(Canvas canvas, int index, Rect rect, BoardSpace space, [Player? owner]) {
    final prop = properties[space.propertyId];
    if (prop == null) return;

    final groupColor = _getGroupColor(prop.group);

    // Authentic Monopoly color band facing inward
    Rect headerRect;
    if (index > 0 && index < 10) {
      headerRect = Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.28);
    } else if (index > 10 && index < 20) {
      headerRect = Rect.fromLTWH(rect.right - rect.width * 0.28, rect.top, rect.width * 0.28, rect.height);
    } else if (index > 20 && index < 30) {
      headerRect = Rect.fromLTWH(rect.left, rect.bottom - rect.height * 0.28, rect.width, rect.height * 0.28);
    } else {
      headerRect = Rect.fromLTWH(rect.left, rect.top, rect.width * 0.28, rect.height);
    }

    canvas.drawRect(headerRect, Paint()..color = groupColor);
    canvas.drawRect(headerRect, Paint()..color = const Color(0x33000000)..style = PaintingStyle.stroke..strokeWidth = 0.6);

    // Buildings or Owner Medallion in color band
    if (owner != null) {
      if (prop.currentLevel > 0) {
        _drawBuildings(canvas, headerRect, prop.currentLevel, index);
        // Compact owner dot in header band corner
        final badgeCenter = (index > 0 && index < 10) || (index > 20 && index < 30)
            ? Offset(headerRect.left + 5.5, headerRect.center.dy)
            : Offset(headerRect.center.dx, headerRect.top + 5.5);
        canvas.drawCircle(badgeCenter, 3.8, Paint()..color = Colors.white);
        canvas.drawCircle(badgeCenter, 2.8, Paint()..color = owner.color);
      } else {
        // Centered owner medallion
        canvas.drawCircle(headerRect.center, 6.5, Paint()..color = Colors.white);
        canvas.drawCircle(headerRect.center, 5.2, Paint()..color = owner.color);
        final initial = owner.name.trim().isNotEmpty ? owner.name.trim()[0].toUpperCase() : 'P';
        final tp = TextPainter(
          text: TextSpan(
            text: initial,
            style: const TextStyle(color: Colors.white, fontSize: 6.8, fontWeight: FontWeight.w900),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(headerRect.center.dx - tp.width / 2, headerRect.center.dy - tp.height / 2));
      }
    }

    // Subtle Kerala landmark watermark motif
    _drawPropertyLandmarkIcon(canvas, rect, index, prop.name);

    // Dynamic scale-to-fit property name + price text
    _drawTileText(
      canvas: canvas,
      rect: rect,
      index: index,
      title: prop.name,
      priceText: '₹${prop.price}',
    );
  }

  void _drawPropertyLandmarkIcon(Canvas canvas, Rect rect, int index, String name) {
    if (min(rect.width, rect.height) < 28) return;

    Offset iconCenter;
    if (index > 0 && index < 10) {
      iconCenter = Offset(rect.center.dx, rect.top + rect.height * 0.44);
    } else if (index > 10 && index < 20) {
      iconCenter = Offset(rect.right - rect.width * 0.44, rect.center.dy);
    } else if (index > 20 && index < 30) {
      iconCenter = Offset(rect.center.dx, rect.bottom - rect.height * 0.44);
    } else {
      iconCenter = Offset(rect.left + rect.width * 0.44, rect.center.dy);
    }

    if (name.contains('Athirappilly')) {
      _drawWaterfallIcon(canvas, iconCenter);
    } else if (name.contains('Vadakkunnathan') || name.contains('Guruvayur')) {
      _drawTempleIcon(canvas, iconCenter);
    } else if (name.contains('Alappuzha') || name.contains('Kumarakom')) {
      _drawHouseboatIcon(canvas, iconCenter);
    } else if (name.contains('Munnar') || name.contains('Wayanad') || name.contains('Vagamon')) {
      _drawHillsIcon(canvas, iconCenter);
    } else if (name.contains('Thekkady')) {
      _drawElephantIcon(canvas, iconCenter);
    } else if (name.contains('Bekal Fort')) {
      _drawFortIcon(canvas, iconCenter);
    } else if (name.contains('Kovalam')) {
      _drawLighthouseIcon(canvas, iconCenter);
    }
  }

  void _drawBuildings(Canvas canvas, Rect headerRect, int level, int index) {
    if (level == 5) {
      // Hotel (Resort)
      _drawResort(canvas, headerRect.center, 12, const Color(0xFFDC2626));
    } else {
      // 1..4 Cottages (Houses)
      final bool isHorizontal = (index > 0 && index < 10) || (index > 20 && index < 30);
      const double sz = 4.8;
      const double spacing = 2.0;
      final double totalSpan = level * sz + (level - 1) * spacing;

      if (isHorizontal) {
        final double startX = headerRect.center.dx - totalSpan / 2;
        for (int i = 0; i < level; i++) {
          final c = Offset(startX + i * (sz + spacing) + sz / 2, headerRect.center.dy);
          _drawCottage(canvas, c, sz, const Color(0xFF16A34A));
        }
      } else {
        final double startY = headerRect.center.dy - totalSpan / 2;
        for (int i = 0; i < level; i++) {
          final c = Offset(headerRect.center.dx, startY + i * (sz + spacing) + sz / 2);
          _drawCottage(canvas, c, sz, const Color(0xFF16A34A));
        }
      }
    }
  }

  void _drawCottage(Canvas canvas, Offset center, double sz, Color color) {
    final path = Path();
    path.moveTo(center.dx, center.dy - sz / 2);
    path.lineTo(center.dx + sz / 2, center.dy);
    path.lineTo(center.dx + sz / 2, center.dy + sz / 2);
    path.lineTo(center.dx - sz / 2, center.dy + sz / 2);
    path.lineTo(center.dx - sz / 2, center.dy);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 0.6);
  }

  void _drawResort(Canvas canvas, Offset center, double sz, Color color) {
    final r = Rect.fromCenter(center: center, width: sz, height: sz * 0.8);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(2)),
      Paint()..color = Colors.white.withValues(alpha: 0.9)..style = PaintingStyle.stroke..strokeWidth = 0.8,
    );
  }

  // ==================== SPECIAL SPACES ====================

  void _drawSpecialSpace(Canvas canvas, int index, Rect rect, BoardSpace space, [Player? owner]) {
    String sub = '';
    VoidCallback drawIcon;

    Offset iconCenter;
    if (index > 0 && index < 10) {
      iconCenter = Offset(rect.center.dx, rect.top + rect.height * 0.40);
    } else if (index > 10 && index < 20) {
      iconCenter = Offset(rect.right - rect.width * 0.28, rect.center.dy);
    } else if (index > 20 && index < 30) {
      iconCenter = Offset(rect.center.dx, rect.bottom - rect.height * 0.40);
    } else {
      iconCenter = Offset(rect.left + rect.width * 0.28, rect.center.dy);
    }

    switch (space.type) {
      case SpaceType.railroad:
        final prop = properties[space.propertyId];
        sub = '₹${prop?.price ?? 135}';
        if (space.name.contains('Metro')) {
          drawIcon = () => _drawMetroIcon(canvas, iconCenter);
        } else if (space.name.contains('Airport')) {
          drawIcon = () => _drawPlaneIcon(canvas, iconCenter);
        } else if (space.name.contains('Ferry')) {
          drawIcon = () => _drawFerryIcon(canvas, iconCenter);
        } else {
          drawIcon = () => _drawBusIcon(canvas, iconCenter);
        }
        break;
      case SpaceType.utility:
        final prop = properties[space.propertyId];
        sub = '₹${prop?.price ?? 100}';
        if (space.name.contains('KSEB')) {
          drawIcon = () => _drawLightningIcon(canvas, iconCenter);
        } else {
          drawIcon = () => _drawWaterDropIcon(canvas, iconCenter);
        }
        break;
      case SpaceType.chance:
        sub = 'MONSOON';
        drawIcon = () => _drawRainCloudIcon(canvas, iconCenter);
        break;
      case SpaceType.communityChest:
        sub = 'FESTIVAL';
        drawIcon = () => _drawLampIcon(canvas, iconCenter);
        break;
      case SpaceType.tax:
        sub = '₹${space.feeAmount ?? 50}';
        drawIcon = () => _drawTaxIcon(canvas, iconCenter);
        break;
      default:
        drawIcon = () {};
        break;
    }

    // Owner badge for transport/utility
    if (owner != null && (space.type == SpaceType.railroad || space.type == SpaceType.utility)) {
      Offset badgeOffset;
      if (index > 0 && index < 10) {
        badgeOffset = Offset(rect.center.dx, rect.top + 7);
      } else if (index > 10 && index < 20) {
        badgeOffset = Offset(rect.right - 7, rect.center.dy);
      } else if (index > 20 && index < 30) {
        badgeOffset = Offset(rect.center.dx, rect.bottom - 7);
      } else {
        badgeOffset = Offset(rect.left + 7, rect.center.dy);
      }
      canvas.drawCircle(badgeOffset, 4.8, Paint()..color = Colors.white);
      canvas.drawCircle(badgeOffset, 3.6, Paint()..color = owner.color);
      final initial = owner.name.trim().isNotEmpty ? owner.name.trim()[0].toUpperCase() : 'P';
      final tp = TextPainter(
        text: TextSpan(text: initial, style: const TextStyle(color: Colors.white, fontSize: 4.8, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(badgeOffset.dx - tp.width / 2, badgeOffset.dy - tp.height / 2));
    }

    _drawSpecialTileText(
      canvas: canvas,
      rect: rect,
      index: index,
      title: space.name,
      subText: sub,
      drawIcon: drawIcon,
    );
  }

  // ==================== READABLE TEXT RENDERING ====================

  List<String> _getTitleLines(String name) {
    switch (name) {
      case 'Athirappilly':
        return ['ATHIRA', 'PPILLY'];
      case 'Vadakkunnathan':
        return ['VADAKKU', 'NNATHAN'];
      case 'Mattancherry':
        return ['MATTAN', 'CHERRY'];
      case 'Guruvayur':
        return ['GURU', 'VAYUR'];
      case 'Alappuzha':
        return ['ALAPP', 'UZHA'];
      case 'Kumarakom':
        return ['KUMARA', 'KOM'];
      case 'Ashtamudi':
        return ['ASHTA', 'MUDI'];
      case 'Kuttanad':
        return ['KUTTA', 'NAD'];
      case 'Panchayath Tax':
        return ['PANCHAYATH', 'TAX'];
      case 'Water Authority':
        return ['WATER', 'AUTHORITY'];
      case 'Property Tax':
        return ['PROPERTY', 'TAX'];
      case 'KSRTC Stand':
        return ['KSRTC', 'STAND'];
      case 'Fort Kochi':
        return ['FORT', 'KOCHI'];
      case 'Marine Drive':
        return ['MARINE', 'DRIVE'];
      case 'Kochi Metro':
        return ['KOCHI', 'METRO'];
      case 'Swaraj Round':
        return ['SWARAJ', 'ROUND'];
      case 'Chaya Kada':
        return ['CHAYA', 'KADA'];
      case 'Police Station':
        return ['POLICE', 'STATION'];
      case 'Bekal Fort':
        return ['BEKAL', 'FORT'];
      default:
        final words = name.split(' ');
        if (words.length >= 2) {
          return [words[0].toUpperCase(), words.sublist(1).join(' ').toUpperCase()];
        }
        return [name.toUpperCase()];
    }
  }

  void _drawTileText({
    required Canvas canvas,
    required Rect rect,
    required int index,
    required String title,
    required String priceText,
  }) {
    double boxLeft;
    double boxTop;
    double boxW;
    double boxH;

    if (index > 0 && index < 10) {
      boxLeft = rect.left + 1.0;
      boxTop = rect.top + rect.height * 0.28 + 1.0;
      boxW = max(10.0, rect.width - 2.0);
      boxH = max(10.0, rect.height * 0.72 - 2.0);
    } else if (index > 10 && index < 20) {
      boxLeft = rect.left + 1.0;
      boxTop = rect.top + 1.0;
      boxW = max(10.0, rect.width * 0.72 - 2.0);
      boxH = max(10.0, rect.height - 2.0);
    } else if (index > 20 && index < 30) {
      boxLeft = rect.left + 1.0;
      boxTop = rect.top + 1.0;
      boxW = max(10.0, rect.width - 2.0);
      boxH = max(10.0, rect.height * 0.72 - 2.0);
    } else {
      boxLeft = rect.left + rect.width * 0.28 + 1.0;
      boxTop = rect.top + 1.0;
      boxW = max(10.0, rect.width * 0.72 - 2.0);
      boxH = max(10.0, rect.height - 2.0);
    }

    final titleLines = _getTitleLines(title);
    final titleCol = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final priceCol = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    double baseSize = (min(rect.width, rect.height) * 0.28).clamp(4.8, 8.5);
    double fontSize = baseSize;
    TextPainter? bestPainter;

    while (fontSize >= 3.6) {
      final children = <TextSpan>[];
      for (int i = 0; i < titleLines.length; i++) {
        children.add(TextSpan(
          text: '${titleLines[i]}\n',
          style: TextStyle(
            color: titleCol,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: -0.2,
          ),
        ));
      }
      if (priceText.isNotEmpty) {
        children.add(TextSpan(
          text: priceText,
          style: TextStyle(
            color: priceCol,
            fontSize: fontSize * 1.05,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: -0.1,
          ),
        ));
      }

      final testPainter = TextPainter(
        text: TextSpan(children: children),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      testPainter.layout();

      if (testPainter.width <= boxW && testPainter.height <= boxH) {
        bestPainter = testPainter;
        break;
      }
      fontSize -= 0.2;
    }

    bestPainter ??= TextPainter(
      text: TextSpan(
        children: [
          for (final line in titleLines)
            TextSpan(
              text: '$line\n',
              style: TextStyle(color: titleCol, fontSize: 3.6, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.2),
            ),
          if (priceText.isNotEmpty)
            TextSpan(
              text: priceText,
              style: TextStyle(color: priceCol, fontSize: 3.8, fontWeight: FontWeight.w900, height: 1.05),
            ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: boxW);

    final paintX = boxLeft + (boxW - bestPainter.width) / 2;
    final paintY = boxTop + (boxH - bestPainter.height) / 2;
    bestPainter.paint(canvas, Offset(paintX, paintY));
  }

  void _drawSpecialTileText({
    required Canvas canvas,
    required Rect rect,
    required int index,
    required String title,
    required String subText,
    required VoidCallback drawIcon,
  }) {
    canvas.save();
    drawIcon();

    final titleCol = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final subCol = isDark ? const Color(0xFF38BDF8) : const Color(0xFF00695C);

    double boxLeft;
    double boxTop;
    double boxW;
    double boxH;

    if (index > 0 && index < 10) {
      boxLeft = rect.left + 1.0;
      boxTop = rect.top + rect.height * 0.48;
      boxW = max(10.0, rect.width - 2.0);
      boxH = max(10.0, rect.height * 0.52 - 2.0);
    } else if (index > 10 && index < 20) {
      boxLeft = rect.left + rect.width * 0.38;
      boxTop = rect.top + 1.0;
      boxW = max(10.0, rect.width * 0.62 - 2.0);
      boxH = max(10.0, rect.height - 2.0);
    } else if (index > 20 && index < 30) {
      boxLeft = rect.left + 1.0;
      boxTop = rect.top + 1.0;
      boxW = max(10.0, rect.width - 2.0);
      boxH = max(10.0, rect.height * 0.52 - 2.0);
    } else {
      boxLeft = rect.left + 1.0;
      boxTop = rect.top + 1.0;
      boxW = max(10.0, rect.width * 0.62 - 2.0);
      boxH = max(10.0, rect.height - 2.0);
    }

    final titleLines = _getTitleLines(title);
    double baseSize = (min(rect.width, rect.height) * 0.26).clamp(4.6, 8.2);
    double fontSize = baseSize;
    TextPainter? bestPainter;

    while (fontSize >= 3.6) {
      final children = <TextSpan>[];
      for (int i = 0; i < titleLines.length; i++) {
        children.add(TextSpan(
          text: '${titleLines[i]}\n',
          style: TextStyle(
            color: titleCol,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: -0.2,
          ),
        ));
      }
      if (subText.isNotEmpty) {
        children.add(TextSpan(
          text: subText,
          style: TextStyle(
            color: subCol,
            fontSize: fontSize * 1.05,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: -0.1,
          ),
        ));
      }

      final testPainter = TextPainter(
        text: TextSpan(children: children),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      testPainter.layout();

      if (testPainter.width <= boxW && testPainter.height <= boxH) {
        bestPainter = testPainter;
        break;
      }
      fontSize -= 0.2;
    }

    bestPainter ??= TextPainter(
      text: TextSpan(
        children: [
          for (final line in titleLines)
            TextSpan(
              text: '$line\n',
              style: TextStyle(color: titleCol, fontSize: 3.6, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.2),
            ),
          if (subText.isNotEmpty)
            TextSpan(
              text: subText,
              style: TextStyle(color: subCol, fontSize: 3.8, fontWeight: FontWeight.w900, height: 1.05),
            ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: boxW);

    final paintX = boxLeft + (boxW - bestPainter.width) / 2;
    final paintY = boxTop + (boxH - bestPainter.height) / 2;
    bestPainter.paint(canvas, Offset(paintX, paintY));

    canvas.restore();
  }

  // ==================== KERALA LANDMARK & VECTOR ICONS ====================

  void _drawWaterfallIcon(Canvas canvas, Offset center) {
    final c = center - const Offset(0, 8);
    final p = Paint()..color = const Color(0xFF38BDF8)..strokeWidth = 1.0;
    canvas.drawLine(c + const Offset(-3, -4), c + const Offset(-3, 3), p);
    canvas.drawLine(c + const Offset(0, -4), c + const Offset(0, 4), p);
    canvas.drawLine(c + const Offset(3, -4), c + const Offset(3, 3), p);
    canvas.drawOval(Rect.fromCenter(center: c + const Offset(0, 4), width: 10, height: 3), Paint()..color = const Color(0xFF0284C7));
  }

  void _drawTempleIcon(Canvas canvas, Offset center) {
    final c = center - const Offset(0, 8);
    final p = Paint()..color = const Color(0xFFD97706);
    final path = Path();
    path.moveTo(c.dx, c.dy - 5);
    path.lineTo(c.dx + 5, c.dy);
    path.lineTo(c.dx - 5, c.dy);
    path.close();
    canvas.drawPath(path, p);
    canvas.drawRect(Rect.fromCenter(center: c + const Offset(0, 3), width: 8, height: 6), Paint()..color = const Color(0xFFB45309));
  }

  void _drawHouseboatIcon(Canvas canvas, Offset center) {
    final c = center - const Offset(0, 8);
    final p = Paint()..color = const Color(0xFF854D0E);
    final path = Path();
    path.moveTo(c.dx - 6, c.dy + 1);
    path.lineTo(c.dx + 6, c.dy + 1);
    path.lineTo(c.dx + 4, c.dy + 4);
    path.lineTo(c.dx - 4, c.dy + 4);
    path.close();
    canvas.drawPath(path, p);
    canvas.drawArc(Rect.fromCenter(center: c, width: 8, height: 6), pi, pi, true, Paint()..color = const Color(0xFFCA8A04));
  }

  void _drawHillsIcon(Canvas canvas, Offset center) {
    final c = center - const Offset(0, 8);
    final p = Paint()..color = const Color(0xFF059669);
    final path = Path();
    path.moveTo(c.dx - 6, c.dy + 4);
    path.lineTo(c.dx - 1, c.dy - 3);
    path.lineTo(c.dx + 3, c.dy + 4);
    path.close();
    canvas.drawPath(path, p);
    final path2 = Path();
    path2.moveTo(c.dx, c.dy + 4);
    path2.lineTo(c.dx + 4, c.dy - 1);
    path2.lineTo(c.dx + 7, c.dy + 4);
    path2.close();
    canvas.drawPath(path2, Paint()..color = const Color(0xFF047857));
  }

  void _drawElephantIcon(Canvas canvas, Offset center) {
    final c = center - const Offset(0, 8);
    final p = Paint()..color = const Color(0xFF475569);
    canvas.drawCircle(c, 4, p);
    canvas.drawOval(Rect.fromCenter(center: c + const Offset(-3, 1), width: 6, height: 5), p);
    canvas.drawLine(c + const Offset(3, 2), c + const Offset(5, 5), p..strokeWidth = 1.5);
  }

  void _drawFortIcon(Canvas canvas, Offset center) {
    final c = center - const Offset(0, 8);
    final p = Paint()..color = const Color(0xFF78716C);
    canvas.drawRect(Rect.fromCenter(center: c + const Offset(0, 2), width: 10, height: 6), p);
    canvas.drawRect(Rect.fromLTWH(c.dx - 5, c.dy - 3, 2.5, 3), p);
    canvas.drawRect(Rect.fromLTWH(c.dx - 1.25, c.dy - 3, 2.5, 3), p);
    canvas.drawRect(Rect.fromLTWH(c.dx + 2.5, c.dy - 3, 2.5, 3), p);
  }

  void _drawLighthouseIcon(Canvas canvas, Offset center) {
    final c = center - const Offset(0, 8);
    final p = Paint()..color = const Color(0xFFDC2626);
    final path = Path();
    path.moveTo(c.dx - 2, c.dy - 4);
    path.lineTo(c.dx + 2, c.dy - 4);
    path.lineTo(c.dx + 3.5, c.dy + 4);
    path.lineTo(c.dx - 3.5, c.dy + 4);
    path.close();
    canvas.drawPath(path, p);
    canvas.drawCircle(c - const Offset(0, 4.5), 1.8, Paint()..color = const Color(0xFFFDE047));
  }

  void _drawBusIcon(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFFE65100);
    final rect = Rect.fromCenter(center: center - const Offset(0, 8), width: 13, height: 9);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), p);
    canvas.drawCircle(rect.bottomLeft + const Offset(2.5, 1), 1.6, Paint()..color = Colors.black);
    canvas.drawCircle(rect.bottomRight + const Offset(-2.5, 1), 1.6, Paint()..color = Colors.black);
  }

  void _drawMetroIcon(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFF00838F);
    final rect = Rect.fromCenter(center: center - const Offset(0, 8), width: 12, height: 11);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), p);
    canvas.drawRect(Rect.fromLTWH(rect.left + 2, rect.top + 2, 8, 3.5), Paint()..color = Colors.white);
  }

  void _drawFerryIcon(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFF0277BD);
    final path = Path();
    final c = center - const Offset(0, 8);
    path.moveTo(c.dx - 7, c.dy);
    path.lineTo(c.dx + 7, c.dy);
    path.lineTo(c.dx + 4.5, c.dy + 5);
    path.lineTo(c.dx - 4.5, c.dy + 5);
    path.close();
    canvas.drawPath(path, p);
  }

  void _drawPlaneIcon(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFF1565C0);
    final c = center - const Offset(0, 8);
    final path = Path();
    path.moveTo(c.dx, c.dy - 5);
    path.lineTo(c.dx + 2, c.dy);
    path.lineTo(c.dx + 7, c.dy + 1.5);
    path.lineTo(c.dx + 2, c.dy + 2.5);
    path.lineTo(c.dx + 2, c.dy + 5);
    path.lineTo(c.dx, c.dy + 4);
    path.lineTo(c.dx - 2, c.dy + 5);
    path.lineTo(c.dx - 2, c.dy + 2.5);
    path.lineTo(c.dx - 7, c.dy + 1.5);
    path.lineTo(c.dx - 2, c.dy);
    path.close();
    canvas.drawPath(path, p);
  }

  void _drawLightningIcon(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFFFBC02D);
    final c = center - const Offset(0, 8);
    final path = Path();
    path.moveTo(c.dx + 1, c.dy - 6);
    path.lineTo(c.dx - 3.5, c.dy);
    path.lineTo(c.dx, c.dy);
    path.lineTo(c.dx - 1.5, c.dy + 6);
    path.lineTo(c.dx + 3.5, c.dy - 1);
    path.lineTo(c.dx, c.dy - 1);
    path.close();
    canvas.drawPath(path, p);
  }

  void _drawWaterDropIcon(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFF0288D1);
    final c = center - const Offset(0, 8);
    final path = Path();
    path.moveTo(c.dx, c.dy - 5);
    path.quadraticBezierTo(c.dx + 5, c.dy + 1.5, c.dx, c.dy + 5);
    path.quadraticBezierTo(c.dx - 5, c.dy + 1.5, c.dx, c.dy - 5);
    canvas.drawPath(path, p);
  }

  void _drawRainCloudIcon(Canvas canvas, Offset center) {
    final c = center - const Offset(0, 8);
    final cloudPaint = Paint()..color = const Color(0xFF546E7A);
    canvas.drawCircle(c, 3.5, cloudPaint);
    canvas.drawCircle(c + const Offset(-3.5, 1.5), 2.8, cloudPaint);
    canvas.drawCircle(c + const Offset(3.5, 1.5), 2.8, cloudPaint);
    final rainPaint = Paint()..color = const Color(0xFF29B6F6)..strokeWidth = 1.0;
    canvas.drawLine(c + const Offset(-2.5, 5), c + const Offset(-3.5, 8), rainPaint);
    canvas.drawLine(c + const Offset(0, 5), c + const Offset(-1, 8), rainPaint);
    canvas.drawLine(c + const Offset(2.5, 5), c + const Offset(1.5, 8), rainPaint);
  }

  void _drawLampIcon(Canvas canvas, Offset center) {
    final c = center - const Offset(0, 8);
    final brassPaint = Paint()..color = const Color(0xFFD4AF37);
    canvas.drawOval(Rect.fromCenter(center: c + const Offset(0, 4), width: 9, height: 2.5), brassPaint);
    canvas.drawRect(Rect.fromLTWH(c.dx - 1.2, c.dy - 2, 2.4, 6), brassPaint);
    canvas.drawOval(Rect.fromCenter(center: c - const Offset(0, 2), width: 7, height: 2.5), brassPaint);
    final flamePaint = Paint()..color = const Color(0xFFFF5722);
    final path = Path();
    path.moveTo(c.dx, c.dy - 6);
    path.quadraticBezierTo(c.dx + 2.5, c.dy - 2.5, c.dx, c.dy - 1.5);
    path.quadraticBezierTo(c.dx - 2.5, c.dy - 2.5, c.dx, c.dy - 6);
    canvas.drawPath(path, flamePaint);
  }

  void _drawTaxIcon(Canvas canvas, Offset center) {
    final c = center - const Offset(0, 8);
    final p = Paint()..color = const Color(0xFF5D4037);
    final rect = Rect.fromCenter(center: c, width: 9, height: 11);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), p);
    canvas.drawLine(c + const Offset(-2.5, -2), c + const Offset(2.5, -2), Paint()..color = Colors.white..strokeWidth = 0.8);
    canvas.drawLine(c + const Offset(-2.5, 1), c + const Offset(2.5, 1), Paint()..color = Colors.white..strokeWidth = 0.8);
  }

  // ==================== 4 CORNERS ====================

  void _drawStartCorner(Canvas canvas, Rect r) {
    canvas.drawRect(r, Paint()..color = isDark ? const Color(0xFF0C2417) : const Color(0xFFF0FDF4));
    canvas.drawRect(r, Paint()..color = isDark ? const Color(0xFF10B981) : const Color(0xFF16A34A)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    final double fs = (r.width * 0.14).clamp(4.8, 7.8);
    final span = TextSpan(
      text: 'START ➔\n',
      style: TextStyle(color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D), fontSize: fs * 1.15, fontWeight: FontWeight.w900, height: 1.08),
      children: [
        TextSpan(
          text: 'NAATTILE\nTHUDAKKAM\n',
          style: TextStyle(color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534), fontSize: fs * 0.88, fontWeight: FontWeight.bold, height: 1.08),
        ),
        TextSpan(
          text: 'COLLECT ₹200',
          style: TextStyle(color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFEA580C), fontSize: fs * 0.92, fontWeight: FontWeight.w900, height: 1.08),
        ),
      ],
    );
    final painter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    painter.layout(maxWidth: r.width);
    painter.paint(canvas, Offset(r.center.dx - painter.width / 2, r.top + 8));
  }

  void _drawJailCorner(Canvas canvas, Rect r) {
    canvas.drawRect(r, Paint()..color = isDark ? const Color(0xFF161F2E) : const Color(0xFFECEFF1));

    final innerCell = Rect.fromLTWH(r.left + r.width * 0.20, r.top + 2, r.width * 0.60, r.height * 0.52);
    canvas.drawRect(innerCell, Paint()..color = isDark ? const Color(0xFF261D15) : const Color(0xFFFFE0B2));

    final barPaint = Paint()..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF37474F)..strokeWidth = 1.2;
    canvas.drawLine(Offset(innerCell.left + 5, innerCell.top), Offset(innerCell.left + 5, innerCell.bottom), barPaint);
    canvas.drawLine(Offset(innerCell.left + 11, innerCell.top), Offset(innerCell.left + 11, innerCell.bottom), barPaint);
    canvas.drawLine(Offset(innerCell.left + 17, innerCell.top), Offset(innerCell.left + 17, innerCell.bottom), barPaint);

    final double fs = (r.width * 0.14).clamp(4.8, 7.5);
    final span = TextSpan(
      text: 'LOCKUP\n',
      style: TextStyle(color: isDark ? const Color(0xFFF87171) : const Color(0xFFBF360C), fontSize: fs * 1.05, fontWeight: FontWeight.w900, height: 1.08),
      children: [
        TextSpan(
          text: 'JUST VISITING',
          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF455A64), fontSize: fs * 0.88, fontWeight: FontWeight.bold, height: 1.08),
        ),
      ],
    );
    final painter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    painter.layout(maxWidth: r.width);
    painter.paint(canvas, Offset(r.center.dx - painter.width / 2, r.bottom - painter.height - 3));
  }

  void _drawFreeParkingCorner(Canvas canvas, Rect r) {
    canvas.drawRect(r, Paint()..color = isDark ? const Color(0xFF211D12) : const Color(0xFFFFFBEB));
    canvas.drawRect(r, Paint()..color = isDark ? const Color(0xFFD97706) : const Color(0xFFF59E0B)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    final c = r.center - const Offset(0, 10);
    final teaGlassPath = Path();
    teaGlassPath.moveTo(c.dx - 4, c.dy - 5);
    teaGlassPath.lineTo(c.dx + 4, c.dy - 5);
    teaGlassPath.lineTo(c.dx + 3, c.dy + 5);
    teaGlassPath.lineTo(c.dx - 3, c.dy + 5);
    teaGlassPath.close();
    canvas.drawPath(teaGlassPath, Paint()..color = const Color(0xFFB45309));
    canvas.drawRect(Rect.fromLTWH(c.dx - 3.8, c.dy - 5, 7.6, 2), Paint()..color = Colors.white.withValues(alpha: 0.8));

    final double fs = (r.width * 0.14).clamp(4.8, 7.5);
    final span = TextSpan(
      text: 'CHAYA KADA\n',
      style: TextStyle(color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F), fontSize: fs * 1.05, fontWeight: FontWeight.w900, height: 1.08),
      children: [
        TextSpan(
          text: 'FREE REST',
          style: TextStyle(color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E), fontSize: fs * 0.88, fontWeight: FontWeight.bold, height: 1.08),
        ),
      ],
    );
    final painter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    painter.layout(maxWidth: r.width);
    painter.paint(canvas, Offset(r.center.dx - painter.width / 2, r.bottom - painter.height - 3));
  }

  void _drawGoToJailCorner(Canvas canvas, Rect r) {
    canvas.drawRect(r, Paint()..color = isDark ? const Color(0xFF261217) : const Color(0xFFFEF2F2));
    canvas.drawRect(r, Paint()..color = isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    final c = r.center - const Offset(0, 10);
    canvas.drawCircle(c, 6, Paint()..color = const Color(0xFFDC2626));
    canvas.drawCircle(c, 2.5, Paint()..color = Colors.white);

    final double fs = (r.width * 0.14).clamp(4.8, 7.5);
    final span = TextSpan(
      text: 'POLICE\nSTATION\n',
      style: TextStyle(color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B), fontSize: fs, fontWeight: FontWeight.w900, height: 1.08),
      children: [
        TextSpan(
          text: 'GO TO LOCKUP',
          style: TextStyle(color: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626), fontSize: fs * 0.9, fontWeight: FontWeight.w900, height: 1.08),
        ),
      ],
    );
    final painter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    painter.layout(maxWidth: r.width);
    painter.paint(canvas, Offset(r.center.dx - painter.width / 2, r.bottom - painter.height - 3));
  }

  // ==================== MORTGAGED OVERLAY ====================

  void _drawMortgagedOverlay(Canvas canvas, Rect rect) {
    canvas.save();
    canvas.clipRect(rect);
    final hatchPaint = Paint()..color = const Color(0x3564748B)..strokeWidth = 1.2;
    for (double i = -rect.height; i < rect.width + rect.height; i += 7) {
      canvas.drawLine(
        Offset(rect.left + i, rect.top),
        Offset(rect.left + i + rect.height, rect.bottom),
        hatchPaint,
      );
    }
    final badgeW = min(rect.width * 0.9, 44.0);
    final badgeRect = Rect.fromCenter(center: rect.center, width: badgeW, height: 12);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(3)), Paint()..color = const Color(0xEE475569));
    final tp = TextPainter(
      text: const TextSpan(
        text: 'MORTGAGED',
        style: TextStyle(color: Colors.white, fontSize: 5.5, fontWeight: FontWeight.w900, letterSpacing: 0.3),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
    canvas.restore();
  }

  // ==================== DYNAMIC HIGHLIGHTS ====================

  void _drawHighlightsLayer(Canvas canvas) {
    for (int i = 0; i < 40; i++) {
      final space = GameData.spaces[i];
      if (space.propertyId != null && highlightedPropertyIds.contains(space.propertyId)) {
        final rect = getSpaceRect(i);
        _drawHighlight(canvas, rect);
      }
    }
  }

  void _drawHighlight(Canvas canvas, Rect rect) {
    final hCol = highlightColor ?? const Color(0xFFD4AF37);
    canvas.drawRect(rect, Paint()..color = hCol.withValues(alpha: isDark ? 0.35 : 0.25));
    canvas.drawRect(
      rect.deflate(1.5),
      Paint()
        ..color = hCol
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  // ==================== COLOR CATEGORIES ====================

  Color _getGroupColor(PropertyGroup group) {
    switch (group) {
      case PropertyGroup.malabar: return const Color(0xFF8B4513);
      case PropertyGroup.kochi: return const Color(0xFFEC4899);
      case PropertyGroup.thrissur: return const Color(0xFF0284C7);
      case PropertyGroup.backwaters: return const Color(0xFFEA580C);
      case PropertyGroup.highlands: return const Color(0xFFDC2626);
      case PropertyGroup.southKerala: return const Color(0xFFEAB308);
      case PropertyGroup.premium: return const Color(0xFF16A34A);
      case PropertyGroup.luxury: return const Color(0xFF1D4ED8);
      default: return Colors.blueGrey;
    }
  }

  // ==================== TAP HANDLING ====================

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
