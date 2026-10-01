import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../models/board_space.dart';
import '../../models/property.dart';
import '../../models/player.dart';
import '../../data/game_data.dart';

class BoardComponent extends PositionComponent with TapCallbacks {
  Map<String, Property> properties;
  List<Player> players;
  List<int> lastDiceRoll;
  bool isDoubles;
  final void Function(Property property)? onPropertyTapped;

  BoardComponent({
    required this.properties,
    required this.players,
    required this.lastDiceRoll,
    this.isDoubles = false,
    this.onPropertyTapped,
  });

  void updateDice(List<int> dice, bool doubles) {
    lastDiceRoll = dice;
    isDoubles = doubles;
  }

  void updateData({
    required Map<String, Property> newProperties,
    required List<Player> newPlayers,
    required List<int> dice,
    required bool doubles,
  }) {
    properties = newProperties;
    players = newPlayers;
    lastDiceRoll = dice;
    isDoubles = doubles;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = size.toRect();
    _drawFrame(canvas, rect);
    _drawBoardCenter(canvas, rect);
    _drawAllSpaces(canvas);
  }

  // ==================== FRAME ====================

  void _drawFrame(Canvas canvas, Rect rect) {
    // Clean white board surface
    final surfacePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), surfacePaint);

    // Thin elegant border
    final borderPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);
  }

  // ==================== CENTER ====================

  void _drawBoardCenter(Canvas canvas, Rect rect) {
    final inner = rect.deflate(rect.width * 0.13);

    // Soft cream fill
    final centerPaint = Paint()..color = const Color(0xFFFAF9F6);
    canvas.drawRRect(RRect.fromRectAndRadius(inner, const Radius.circular(10)), centerPaint);

    // Thin border
    final borderPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(RRect.fromRectAndRadius(inner, const Radius.circular(10)), borderPaint);

    // Compact title
    final titleSpan = TextSpan(
      text: 'KUTHAKA',
      style: const TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: 5,
      ),
    );
    final titlePainter = TextPainter(
      text: titleSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: inner.width);
    titlePainter.paint(
      canvas,
      Offset(inner.center.dx - titlePainter.width / 2, inner.top + inner.height * 0.12),
    );

    // Subtitle
    final subSpan = const TextSpan(
      text: 'KERALA REAL ESTATE',
      style: TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
      ),
    );
    final subPainter = TextPainter(
      text: subSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    subPainter.layout(maxWidth: inner.width);
    subPainter.paint(
      canvas,
      Offset(inner.center.dx - subPainter.width / 2, inner.top + inner.height * 0.12 + 26),
    );

    // Dice display in center
    if (lastDiceRoll.isNotEmpty && lastDiceRoll.length >= 2) {
      _drawDice(canvas, inner.center);
    }
  }

  void _drawDice(Canvas canvas, Offset center) {
    final d1 = lastDiceRoll[0];
    final d2 = lastDiceRoll[1];
    const sz = 28.0;
    const gap = 8.0;

    _drawOneDie(canvas, Offset(center.dx - sz / 2 - gap / 2, center.dy), sz, d1);
    _drawOneDie(canvas, Offset(center.dx + sz / 2 + gap / 2, center.dy), sz, d2);

    if (isDoubles) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'DOUBLES!',
          style: TextStyle(color: Color(0xFFEA580C), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy + sz / 2 + 8));
    }
  }

  void _drawOneDie(Canvas canvas, Offset center, double sz, int value) {
    final r = Rect.fromCenter(center: center, width: sz, height: sz);
    // White die with shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.shift(const Offset(1, 2)), const Radius.circular(5)),
      Paint()..color = const Color(0x22000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(5)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(5)),
      Paint()..color = const Color(0xFFD1D5DB)..style = PaintingStyle.stroke..strokeWidth = 1,
    );

    final dotPaint = Paint()..color = const Color(0xFF1E293B);
    final dotR = sz * 0.09;
    final cx = center.dx;
    final cy = center.dy;
    final off = sz * 0.25;

    if (value == 1 || value == 3 || value == 5) canvas.drawCircle(Offset(cx, cy), dotR, dotPaint);
    if (value >= 2) {
      canvas.drawCircle(Offset(cx - off, cy - off), dotR, dotPaint);
      canvas.drawCircle(Offset(cx + off, cy + off), dotR, dotPaint);
    }
    if (value >= 4) {
      canvas.drawCircle(Offset(cx + off, cy - off), dotR, dotPaint);
      canvas.drawCircle(Offset(cx - off, cy + off), dotR, dotPaint);
    }
    if (value == 6) {
      canvas.drawCircle(Offset(cx - off, cy), dotR, dotPaint);
      canvas.drawCircle(Offset(cx + off, cy), dotR, dotPaint);
    }
  }

  // ==================== ALL SPACES ====================

  void _drawAllSpaces(Canvas canvas) {
    double cornerW = size.x * 0.13;
    double cornerH = size.y * 0.13;
    double spaceW = (size.x - (2 * cornerW)) / 9;
    double spaceH = (size.y - (2 * cornerH)) / 9;

    for (int i = 0; i < 40; i++) {
      final rect = _getSpaceRect(i, cornerW, cornerH, spaceW, spaceH);
      _drawSingleSpace(canvas, i, rect);
    }

    // Ownership extensions
    for (int i = 0; i < 40; i++) {
      final space = GameData.spaces[i];
      if (space.propertyId != null) {
        final prop = properties[space.propertyId];
        if (prop != null && prop.ownerId != null) {
          final rect = _getSpaceRect(i, cornerW, cornerH, spaceW, spaceH);
          _drawOwnershipInwardExtension(canvas, i, rect, prop);
        }
      }
    }
  }

  void _drawOwnershipInwardExtension(Canvas canvas, int index, Rect spaceRect, Property prop) {
    if (prop.ownerId == null) return;
    final owner = players.firstWhere((p) => p.id == prop.ownerId, orElse: () => players.first);

    const double extDepth = 13.0;
    Rect extRect;
    RRect rrect;

    if (index > 0 && index < 10) {
      extRect = Rect.fromLTWH(spaceRect.left + 1, spaceRect.top - extDepth, spaceRect.width - 2, extDepth);
      rrect = RRect.fromRectAndCorners(extRect, topLeft: const Radius.circular(5), topRight: const Radius.circular(5));
    } else if (index > 10 && index < 20) {
      extRect = Rect.fromLTWH(spaceRect.right, spaceRect.top + 1, extDepth, spaceRect.height - 2);
      rrect = RRect.fromRectAndCorners(extRect, topRight: const Radius.circular(5), bottomRight: const Radius.circular(5));
    } else if (index > 20 && index < 30) {
      extRect = Rect.fromLTWH(spaceRect.left + 1, spaceRect.bottom, spaceRect.width - 2, extDepth);
      rrect = RRect.fromRectAndCorners(extRect, bottomLeft: const Radius.circular(5), bottomRight: const Radius.circular(5));
    } else if (index > 30) {
      extRect = Rect.fromLTWH(spaceRect.left - extDepth, spaceRect.top + 1, extDepth, spaceRect.height - 2);
      rrect = RRect.fromRectAndCorners(extRect, topLeft: const Radius.circular(5), bottomLeft: const Radius.circular(5));
    } else {
      return;
    }

    canvas.drawRRect(rrect.shift(const Offset(0, 1)), Paint()..color = const Color(0x30000000));
    final fillColor = prop.isMortgaged ? const Color(0xFF64748B) : owner.color;
    canvas.drawRRect(rrect, Paint()..color = fillColor);
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFC5A049)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    final badgeRadius = min(extRect.width, extRect.height) * 0.32;
    canvas.drawCircle(extRect.center, badgeRadius, Paint()..color = Colors.white);

    final initial = owner.name.trim().isNotEmpty ? owner.name.trim()[0].toUpperCase() : 'P';
    final textSpan = TextSpan(
      text: prop.isMortgaged ? 'M' : initial,
      style: TextStyle(
        color: prop.isMortgaged ? const Color(0xFF64748B) : owner.color,
        fontSize: badgeRadius * 1.35,
        fontWeight: FontWeight.w900,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(extRect.center.dx - tp.width / 2, extRect.center.dy - tp.height / 2));
  }

  Rect _getSpaceRect(int index, double cornerW, double cornerH, double spaceW, double spaceH) {
    if (index == 0) {
      return Rect.fromLTWH(size.x - cornerW, size.y - cornerH, cornerW, cornerH);
    } else if (index > 0 && index < 10) {
      return Rect.fromLTWH(size.x - cornerW - index * spaceW, size.y - cornerH, spaceW, cornerH);
    } else if (index == 10) {
      return Rect.fromLTWH(0, size.y - cornerH, cornerW, cornerH);
    } else if (index > 10 && index < 20) {
      return Rect.fromLTWH(0, size.y - cornerH - (index - 10) * spaceH, cornerW, spaceH);
    } else if (index == 20) {
      return Rect.fromLTWH(0, 0, cornerW, cornerH);
    } else if (index > 20 && index < 30) {
      return Rect.fromLTWH(cornerW + (index - 20 - 1) * spaceW, 0, spaceW, cornerH);
    } else if (index == 30) {
      return Rect.fromLTWH(size.x - cornerW, 0, cornerW, cornerH);
    } else {
      return Rect.fromLTWH(size.x - cornerW, cornerH + (index - 30 - 1) * spaceH, cornerW, spaceH);
    }
  }

  // ==================== SINGLE SPACE ====================

  void _drawSingleSpace(Canvas canvas, int index, Rect rect) {
    final space = GameData.spaces[index];

    Property? prop;
    Player? owner;
    if (space.propertyId != null) {
      prop = properties[space.propertyId];
      final ownerId = prop?.ownerId;
      if (ownerId != null) {
        final matches = players.where((p) => p.id == ownerId);
        if (matches.isNotEmpty) owner = matches.first;
      }
    }

    // White background, tinted if owned
    Color bgColor = Colors.white;
    if (owner != null) {
      bgColor = prop!.isMortgaged
          ? const Color(0xFFF1F5F9)
          : Color.alphaBlend(owner.color.withValues(alpha: 0.12), Colors.white);
    }
    canvas.drawRect(rect, Paint()..color = bgColor);

    // Grid border
    canvas.drawRect(rect, Paint()..color = const Color(0xFFCFD8DC)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Owner stripe on outer edge
    if (owner != null) {
      _drawOwnerOuterStripe(canvas, index, rect, prop!.isMortgaged ? const Color(0xFF64748B) : owner.color);
    }

    // Draw content
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

    if (prop != null && prop.isMortgaged) {
      _drawMortgagedOverlay(canvas, index, rect);
    }
  }

  void _drawOwnerOuterStripe(Canvas canvas, int index, Rect rect, Color color) {
    const double stripeThick = 3.5;
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

  void _drawMortgagedOverlay(Canvas canvas, int index, Rect rect) {
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

  // ==================== PROPERTY SPACE ====================

  void _drawPropertySpace(Canvas canvas, int index, Rect rect, BoardSpace space, [Player? owner]) {
    final prop = properties[space.propertyId];
    if (prop == null) return;

    final groupColor = _getGroupColor(prop.group);

    // Thick color band on inner edge (takes ~30% of the tile)
    Rect headerRect;
    if (index > 0 && index < 10) {
      headerRect = Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.30);
    } else if (index > 10 && index < 20) {
      headerRect = Rect.fromLTWH(rect.right - rect.width * 0.30, rect.top, rect.width * 0.30, rect.height);
    } else if (index > 20 && index < 30) {
      headerRect = Rect.fromLTWH(rect.left, rect.bottom - rect.height * 0.30, rect.width, rect.height * 0.30);
    } else {
      headerRect = Rect.fromLTWH(rect.left, rect.top, rect.width * 0.30, rect.height);
    }

    canvas.drawRect(headerRect, Paint()..color = groupColor);
    canvas.drawRect(headerRect, Paint()..color = const Color(0x33000000)..style = PaintingStyle.stroke..strokeWidth = 0.5);

    // Buildings or owner badge on the color band
    if (owner != null) {
      if (prop.currentLevel > 0) {
        _drawBuildings(canvas, headerRect, prop.currentLevel);
        final badgeCenter = Offset(headerRect.left + 5.0, headerRect.center.dy);
        canvas.drawCircle(badgeCenter, 3.8, Paint()..color = Colors.white);
        canvas.drawCircle(badgeCenter, 2.8, Paint()..color = owner.color);
      } else {
        canvas.drawCircle(headerRect.center, 5.5, Paint()..color = Colors.white);
        canvas.drawCircle(headerRect.center, 4.2, Paint()..color = owner.color);
        final initial = owner.name.trim().isNotEmpty ? owner.name.trim()[0].toUpperCase() : 'P';
        final tp = TextPainter(
          text: TextSpan(text: initial, style: const TextStyle(color: Colors.white, fontSize: 5.5, fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(headerRect.center.dx - tp.width / 2, headerRect.center.dy - tp.height / 2));
      }
    }

    // Name + Price text — LARGE and readable
    _drawTileText(
      canvas: canvas, rect: rect, index: index,
      title: prop.name, priceText: '₹${prop.price}',
    );
  }

  void _drawBuildings(Canvas canvas, Rect headerRect, int level) {
    if (level == 5) {
      _drawResort(canvas, headerRect.center, 12, const Color(0xFFFFD54F));
    } else {
      double sz = 5.0;
      double spacing = 2.5;
      double totalW = level * sz + (level - 1) * spacing;
      double startX = headerRect.center.dx - totalW / 2;
      for (int i = 0; i < level; i++) {
        _drawCottage(canvas, Offset(startX + i * (sz + spacing) + sz / 2, headerRect.center.dy), sz, const Color(0xFF1B5E20));
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
    canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 0.5);
  }

  void _drawResort(Canvas canvas, Offset center, double sz, Color color) {
    final r = Rect.fromCenter(center: center, width: sz, height: sz * 0.8);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = color);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = const Color(0xFF8D6E63)..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  // ==================== SPECIAL SPACES ====================

  void _drawSpecialSpace(Canvas canvas, int index, Rect rect, BoardSpace space, [Player? owner]) {
    String sub = '';
    VoidCallback drawIcon;

    Offset iconCenter;
    if (index > 0 && index < 10) {
      iconCenter = Offset(rect.center.dx, rect.top + rect.height * 0.45);
    } else if (index > 10 && index < 20) {
      iconCenter = Offset(rect.right - rect.width * 0.25, rect.center.dy);
    } else if (index > 20 && index < 30) {
      iconCenter = Offset(rect.center.dx, rect.bottom - rect.height * 0.45);
    } else {
      iconCenter = Offset(rect.left + rect.width * 0.25, rect.center.dy);
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
      canvas.drawCircle(badgeOffset, 5.0, Paint()..color = Colors.white);
      canvas.drawCircle(badgeOffset, 3.8, Paint()..color = owner.color);
      final initial = owner.name.trim().isNotEmpty ? owner.name.trim()[0].toUpperCase() : 'P';
      final tp = TextPainter(
        text: TextSpan(text: initial, style: const TextStyle(color: Colors.white, fontSize: 5.0, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(badgeOffset.dx - tp.width / 2, badgeOffset.dy - tp.height / 2));
    }

    _drawSpecialTileText(
      canvas: canvas, rect: rect, index: index,
      title: space.name, subText: sub, drawIcon: drawIcon,
    );
  }

  // ==================== TEXT RENDERING (READABLE) ====================

  void _drawTileText({
    required Canvas canvas,
    required Rect rect,
    required int index,
    required String title,
    required String priceText,
  }) {
    final formattedTitle = _formatTileName(title);

    final textSpan = TextSpan(
      text: '$formattedTitle\n',
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 7.2,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
      children: [
        TextSpan(
          text: priceText,
          style: const TextStyle(
            color: Color(0xFF047857),
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );

    final painter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    double maxW;
    double offsetX;
    double offsetY;

    if (index > 10 && index < 20) {
      // Left side: Text on the left, color band on the right (width * 0.3)
      maxW = rect.width * 0.65;
      painter.layout(maxWidth: maxW);
      offsetX = rect.left + (rect.width * 0.7 - painter.width) / 2;
      offsetY = rect.center.dy - painter.height / 2;
    } else if (index > 30) {
      // Right side: Text on the right, color band on the left (width * 0.3)
      maxW = rect.width * 0.65;
      painter.layout(maxWidth: maxW);
      offsetX = rect.left + rect.width * 0.3 + (rect.width * 0.7 - painter.width) / 2;
      offsetY = rect.center.dy - painter.height / 2;
    } else {
      // Top/Bottom
      maxW = rect.width - 2;
      painter.layout(maxWidth: maxW);
      offsetX = rect.center.dx - painter.width / 2;
      offsetY = (index > 0 && index < 10) ? (rect.bottom - painter.height - 4) : (rect.top + 4);
    }

    painter.paint(canvas, Offset(offsetX, offsetY));
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

    final textSpan = TextSpan(
      text: '${_formatTileName(title)}\n',
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 6.8,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
      children: [
        if (subText.isNotEmpty)
          TextSpan(
            text: subText,
            style: const TextStyle(
              color: Color(0xFF00695C),
              fontSize: 7.0,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );

    final painter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    double maxW;
    double offsetX;
    double offsetY;

    if (index > 10 && index < 20) {
      // Left side: Text on the left, icon on the right
      maxW = rect.width * 0.65;
      painter.layout(maxWidth: maxW);
      offsetX = rect.left + (rect.width * 0.7 - painter.width) / 2;
      offsetY = rect.center.dy - painter.height / 2;
    } else if (index > 30) {
      // Right side: Text on the right, icon on the left
      maxW = rect.width * 0.65;
      painter.layout(maxWidth: maxW);
      offsetX = rect.left + rect.width * 0.3 + (rect.width * 0.7 - painter.width) / 2;
      offsetY = rect.center.dy - painter.height / 2;
    } else {
      // Top/Bottom
      maxW = rect.width - 2;
      painter.layout(maxWidth: maxW);
      offsetX = rect.center.dx - painter.width / 2;
      offsetY = (index > 20 && index < 30) ? rect.top + 3 : rect.bottom - painter.height - 3;
    }

    painter.paint(canvas, Offset(offsetX, offsetY));
    canvas.restore();
  }

  String _formatTileName(String name) {
    if (name.length <= 10) return name.toUpperCase();
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0].toUpperCase()}\n${words.sublist(1).join(' ').toUpperCase()}';
    }
    return name.toUpperCase();
  }

  // ==================== VECTOR ICONS ====================

  void _drawBusIcon(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFFE65100);
    final rect = Rect.fromCenter(center: center - const Offset(0, 10), width: 14, height: 10);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), p);
    canvas.drawCircle(rect.bottomLeft + const Offset(3, 1), 1.8, Paint()..color = Colors.black);
    canvas.drawCircle(rect.bottomRight + const Offset(-3, 1), 1.8, Paint()..color = Colors.black);
  }

  void _drawMetroIcon(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFF00838F);
    final rect = Rect.fromCenter(center: center - const Offset(0, 10), width: 12, height: 12);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), p);
    canvas.drawRect(Rect.fromLTWH(rect.left + 2, rect.top + 2, 8, 4), Paint()..color = Colors.white);
  }

  void _drawFerryIcon(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFF0277BD);
    final path = Path();
    final c = center - const Offset(0, 10);
    path.moveTo(c.dx - 8, c.dy);
    path.lineTo(c.dx + 8, c.dy);
    path.lineTo(c.dx + 5, c.dy + 6);
    path.lineTo(c.dx - 5, c.dy + 6);
    path.close();
    canvas.drawPath(path, p);
  }

  void _drawPlaneIcon(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFF1565C0);
    final c = center - const Offset(0, 10);
    final path = Path();
    path.moveTo(c.dx, c.dy - 6);
    path.lineTo(c.dx + 2, c.dy);
    path.lineTo(c.dx + 8, c.dy + 2);
    path.lineTo(c.dx + 2, c.dy + 3);
    path.lineTo(c.dx + 2, c.dy + 6);
    path.lineTo(c.dx, c.dy + 5);
    path.lineTo(c.dx - 2, c.dy + 6);
    path.lineTo(c.dx - 2, c.dy + 3);
    path.lineTo(c.dx - 8, c.dy + 2);
    path.lineTo(c.dx - 2, c.dy);
    path.close();
    canvas.drawPath(path, p);
  }

  void _drawLightningIcon(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFFFBC02D);
    final c = center - const Offset(0, 10);
    final path = Path();
    path.moveTo(c.dx + 1, c.dy - 7);
    path.lineTo(c.dx - 4, c.dy);
    path.lineTo(c.dx, c.dy);
    path.lineTo(c.dx - 2, c.dy + 7);
    path.lineTo(c.dx + 4, c.dy - 1);
    path.lineTo(c.dx, c.dy - 1);
    path.close();
    canvas.drawPath(path, p);
  }

  void _drawWaterDropIcon(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFF0288D1);
    final c = center - const Offset(0, 10);
    final path = Path();
    path.moveTo(c.dx, c.dy - 6);
    path.quadraticBezierTo(c.dx + 6, c.dy + 2, c.dx, c.dy + 6);
    path.quadraticBezierTo(c.dx - 6, c.dy + 2, c.dx, c.dy - 6);
    canvas.drawPath(path, p);
  }

  void _drawRainCloudIcon(Canvas canvas, Offset center) {
    final c = center - const Offset(0, 10);
    final cloudPaint = Paint()..color = const Color(0xFF546E7A);
    canvas.drawCircle(c, 4, cloudPaint);
    canvas.drawCircle(c + const Offset(-4, 2), 3, cloudPaint);
    canvas.drawCircle(c + const Offset(4, 2), 3, cloudPaint);
    final rainPaint = Paint()..color = const Color(0xFF29B6F6)..strokeWidth = 1.2;
    canvas.drawLine(c + const Offset(-3, 6), c + const Offset(-4, 9), rainPaint);
    canvas.drawLine(c + const Offset(0, 6), c + const Offset(-1, 9), rainPaint);
    canvas.drawLine(c + const Offset(3, 6), c + const Offset(2, 9), rainPaint);
  }

  void _drawLampIcon(Canvas canvas, Offset center) {
    final c = center - const Offset(0, 10);
    final brassPaint = Paint()..color = const Color(0xFFD4AF37);
    canvas.drawOval(Rect.fromCenter(center: c + const Offset(0, 5), width: 10, height: 3), brassPaint);
    canvas.drawRect(Rect.fromLTWH(c.dx - 1.5, c.dy - 2, 3, 7), brassPaint);
    canvas.drawOval(Rect.fromCenter(center: c - const Offset(0, 2), width: 8, height: 3), brassPaint);
    final flamePaint = Paint()..color = const Color(0xFFFF5722);
    final path = Path();
    path.moveTo(c.dx, c.dy - 7);
    path.quadraticBezierTo(c.dx + 3, c.dy - 3, c.dx, c.dy - 2);
    path.quadraticBezierTo(c.dx - 3, c.dy - 3, c.dx, c.dy - 7);
    canvas.drawPath(path, flamePaint);
  }

  void _drawTaxIcon(Canvas canvas, Offset center) {
    final c = center - const Offset(0, 10);
    final p = Paint()..color = const Color(0xFF5D4037);
    final rect = Rect.fromCenter(center: c, width: 10, height: 12);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), p);
    canvas.drawLine(c + const Offset(-3, -2), c + const Offset(3, -2), Paint()..color = Colors.white..strokeWidth = 1);
    canvas.drawLine(c + const Offset(-3, 1), c + const Offset(3, 1), Paint()..color = Colors.white..strokeWidth = 1);
  }

  // ==================== 4 CORNERS ====================

  void _drawStartCorner(Canvas canvas, Rect r) {
    canvas.drawRect(r, Paint()..color = const Color(0xFFF1F8E9));
    canvas.drawRect(r, Paint()..color = const Color(0xFF2E7D32)..style = PaintingStyle.stroke..strokeWidth = 2);

    final flagPaint = Paint()..color = const Color(0xFF1B5E20);
    canvas.drawRect(Rect.fromLTWH(r.center.dx - 10, r.top + 8, 20, 5), flagPaint);

    final span = const TextSpan(
      text: 'START ➔\n',
      style: TextStyle(color: Color(0xFF1B5E20), fontSize: 8.5, fontWeight: FontWeight.w900),
      children: [
        TextSpan(
          text: 'NAATTILE\nTHUDAKKAM\n',
          style: TextStyle(color: Color(0xFF2E7D32), fontSize: 7, fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: 'COLLECT ₹200',
          style: TextStyle(color: Color(0xFFE65100), fontSize: 6.8, fontWeight: FontWeight.w900),
        ),
      ],
    );
    final painter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    painter.layout(maxWidth: r.width);
    painter.paint(canvas, Offset(r.center.dx - painter.width / 2, r.top + 18));
  }

  void _drawJailCorner(Canvas canvas, Rect r) {
    canvas.drawRect(r, Paint()..color = const Color(0xFFECEFF1));

    final innerCell = Rect.fromLTWH(r.left + r.width * 0.35, r.top, r.width * 0.65, r.height * 0.65);
    canvas.drawRect(innerCell, Paint()..color = const Color(0xFFFFE0B2));

    final barPaint = Paint()..color = const Color(0xFF37474F)..strokeWidth = 1.2;
    canvas.drawLine(Offset(innerCell.left + 5, innerCell.top), Offset(innerCell.left + 5, innerCell.bottom), barPaint);
    canvas.drawLine(Offset(innerCell.left + 11, innerCell.top), Offset(innerCell.left + 11, innerCell.bottom), barPaint);
    canvas.drawLine(Offset(innerCell.left + 17, innerCell.top), Offset(innerCell.left + 17, innerCell.bottom), barPaint);

    final span = const TextSpan(
      text: 'LOCKUP\n',
      style: TextStyle(color: Color(0xFFBF360C), fontSize: 7.5, fontWeight: FontWeight.w900),
      children: [
        TextSpan(
          text: 'JUST VISITING',
          style: TextStyle(color: Color(0xFF455A64), fontSize: 6.5, fontWeight: FontWeight.bold),
        ),
      ],
    );
    final painter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    painter.layout(maxWidth: r.width);
    painter.paint(canvas, Offset(r.center.dx - painter.width / 2, r.bottom - painter.height - 4));
  }

  void _drawFreeParkingCorner(Canvas canvas, Rect r) {
    canvas.drawRect(r, Paint()..color = const Color(0xFFFFFDE7));
    canvas.drawRect(r, Paint()..color = const Color(0xFFFBC02D)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    final c = r.center - const Offset(0, 10);
    canvas.drawRect(Rect.fromLTWH(c.dx - 6, c.dy - 3, 12, 10), Paint()..color = const Color(0xFF795548));

    final span = const TextSpan(
      text: 'CHAYA KADA\n',
      style: TextStyle(color: Color(0xFF4E342E), fontSize: 7.5, fontWeight: FontWeight.w900),
      children: [
        TextSpan(
          text: 'FREE REST',
          style: TextStyle(color: Color(0xFF8D6E63), fontSize: 6.8, fontWeight: FontWeight.bold),
        ),
      ],
    );
    final painter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    painter.layout(maxWidth: r.width);
    painter.paint(canvas, Offset(r.center.dx - painter.width / 2, r.bottom - painter.height - 4));
  }

  void _drawGoToJailCorner(Canvas canvas, Rect r) {
    canvas.drawRect(r, Paint()..color = const Color(0xFFFFEBEE));
    canvas.drawRect(r, Paint()..color = const Color(0xFFD32F2F)..style = PaintingStyle.stroke..strokeWidth = 2);

    final c = r.center - const Offset(0, 10);
    canvas.drawCircle(c, 7, Paint()..color = const Color(0xFFC62828));

    final span = const TextSpan(
      text: 'POLICE\nSTATION\n',
      style: TextStyle(color: Color(0xFFB71C1C), fontSize: 7.5, fontWeight: FontWeight.w900),
      children: [
        TextSpan(
          text: 'GO TO LOCKUP',
          style: TextStyle(color: Color(0xFFC62828), fontSize: 6.5, fontWeight: FontWeight.w900),
        ),
      ],
    );
    final painter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    painter.layout(maxWidth: r.width);
    painter.paint(canvas, Offset(r.center.dx - painter.width / 2, r.bottom - painter.height - 4));
  }

  // ==================== COLOR CATEGORIES ====================

  Color _getGroupColor(PropertyGroup group) {
    switch (group) {
      case PropertyGroup.malabar: return const Color(0xFF8D5524);
      case PropertyGroup.thrissur: return const Color(0xFF0288D1);
      case PropertyGroup.kochi: return const Color(0xFFD81B60);
      case PropertyGroup.backwaters: return const Color(0xFFF57C00);
      case PropertyGroup.highlands: return const Color(0xFFD32F2F);
      case PropertyGroup.southKerala: return const Color(0xFFFBC02D);
      case PropertyGroup.premium: return const Color(0xFF2E7D32);
      case PropertyGroup.luxury: return const Color(0xFF1565C0);
      default: return Colors.blueGrey;
    }
  }

  // ==================== TAP HANDLING ====================

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final localPos = event.localPosition;

    double cornerW = size.x * 0.13;
    double cornerH = size.y * 0.13;
    double spaceW = (size.x - (2 * cornerW)) / 9;
    double spaceH = (size.y - (2 * cornerH)) / 9;

    for (int i = 0; i < 40; i++) {
      final r = _getSpaceRect(i, cornerW, cornerH, spaceW, spaceH);
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
