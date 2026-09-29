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

    // 1. Draw Blonde Teak Frame with Inlay
    _drawFrame(canvas, rect);

    // 2. Draw Elegant Light Board Center Canvas
    _drawBoardCenter(canvas, rect);

    // 3. Draw All 40 Spaces with High-Contrast Typography & Vector Icons
    _drawAllSpaces(canvas);
  }

  void _drawFrame(Canvas canvas, Rect rect) {
    // Outer frame: Clean blonde wood / champagne teak
    final woodPaint = Paint()..color = const Color(0xFFD7CCC8);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), woodPaint);

    // Gold Kasavu inner trim line
    final brassPaint = Paint()
      ..color = const Color(0xFFC5A049)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(8)), brassPaint);

    // Porcelain play surface
    final boardInner = rect.deflate(6);
    final surfacePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(boardInner, surfacePaint);
  }

  void _drawBoardCenter(Canvas canvas, Rect rect) {
    final inner = rect.deflate(rect.width * 0.13);

    // Clean, light ivory/linen central mat
    final centerPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFCFBF7), Color(0xFFF3EEE3)],
        radius: 0.85,
      ).createShader(inner);
    canvas.drawRRect(RRect.fromRectAndRadius(inner, const Radius.circular(16)), centerPaint);

    // Fine Kasavu gold inner border
    final goldBorderPaint = Paint()
      ..color = const Color(0xFFC5A049)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(RRect.fromRectAndRadius(inner.deflate(5), const Radius.circular(12)), goldBorderPaint);

    // Delicate corner accents
    final cornerAccent = Paint()
      ..color = const Color(0x66C5A049)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(inner.topLeft + const Offset(14, 14), 6, cornerAccent);
    canvas.drawCircle(inner.topRight + const Offset(-14, 14), 6, cornerAccent);
    canvas.drawCircle(inner.bottomLeft + const Offset(14, -14), 6, cornerAccent);
    canvas.drawCircle(inner.bottomRight + const Offset(-14, -14), 6, cornerAccent);

    // Title: KUTHAKA in deep Kerala forest green
    final titleSpan = TextSpan(
      text: 'KUTHAKA\n',
      style: const TextStyle(
        color: Color(0xFF133E2B),
        fontSize: 30,
        fontWeight: FontWeight.w900,
        letterSpacing: 6,
      ),
      children: const [
        TextSpan(
          text: 'A KERALA REAL ESTATE GAME',
          style: TextStyle(
            color: Color(0xFF5A786B),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );

    final titlePainter = TextPainter(
      text: titleSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: inner.width);
    titlePainter.paint(
      canvas,
      Offset(inner.center.dx - titlePainter.width / 2, inner.top + inner.height * 0.16),
    );

    // Center Traditional Emblem: Clean Vector Medallion (NO EMOJIS)
    _drawCenterEmblem(canvas, Offset(inner.center.dx, inner.top + inner.height * 0.44));

  }

  void _drawCenterEmblem(Canvas canvas, Offset center) {
    final goldPaint = Paint()
      ..color = const Color(0xFFC5A049)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Concentric emblem rings
    canvas.drawCircle(center, 22, goldPaint);
    canvas.drawCircle(center, 18, Paint()..color = const Color(0x22C5A049));

    // Vector Traditional Boat / Sun rays inside emblem
    final path = Path();
    // Boat hull curve
    path.moveTo(center.dx - 12, center.dy + 3);
    path.quadraticBezierTo(center.dx, center.dy + 10, center.dx + 12, center.dy + 3);
    path.close();

    // Sail triangle
    path.moveTo(center.dx, center.dy - 10);
    path.lineTo(center.dx + 8, center.dy + 1);
    path.lineTo(center.dx, center.dy + 1);
    path.close();

    final emblemFill = Paint()..color = const Color(0xFF133E2B);
    canvas.drawPath(path, emblemFill);
  }


  void _drawAllSpaces(Canvas canvas) {
    double cornerW = size.x * 0.13;
    double cornerH = size.y * 0.13;
    double spaceW = (size.x - (2 * cornerW)) / 9;
    double spaceH = (size.y - (2 * cornerH)) / 9;

    for (int i = 0; i < 40; i++) {
      final rect = _getSpaceRect(i, cornerW, cornerH, spaceW, spaceH);
      _drawSingleSpace(canvas, i, rect);
    }

    // Draw prominent inward ownership extensions so owners are crystal-clear
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

    const double extDepth = 13.0; // Inward extension depth
    Rect extRect;
    RRect rrect;

    if (index > 0 && index < 10) {
      // Bottom edge: inward is UP
      extRect = Rect.fromLTWH(spaceRect.left + 1, spaceRect.top - extDepth, spaceRect.width - 2, extDepth);
      rrect = RRect.fromRectAndCorners(
        extRect,
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
      );
    } else if (index > 10 && index < 20) {
      // Left edge: inward is RIGHT
      extRect = Rect.fromLTWH(spaceRect.right, spaceRect.top + 1, extDepth, spaceRect.height - 2);
      rrect = RRect.fromRectAndCorners(
        extRect,
        topRight: const Radius.circular(5),
        bottomRight: const Radius.circular(5),
      );
    } else if (index > 20 && index < 30) {
      // Top edge: inward is DOWN
      extRect = Rect.fromLTWH(spaceRect.left + 1, spaceRect.bottom, spaceRect.width - 2, extDepth);
      rrect = RRect.fromRectAndCorners(
        extRect,
        bottomLeft: const Radius.circular(5),
        bottomRight: const Radius.circular(5),
      );
    } else if (index > 30) {
      // Right edge: inward is LEFT
      extRect = Rect.fromLTWH(spaceRect.left - extDepth, spaceRect.top + 1, extDepth, spaceRect.height - 2);
      rrect = RRect.fromRectAndCorners(
        extRect,
        topLeft: const Radius.circular(5),
        bottomLeft: const Radius.circular(5),
      );
    } else {
      return; // Corners don't have ownership
    }

    // Shadow
    canvas.drawRRect(
      rrect.shift(const Offset(0, 1)),
      Paint()..color = const Color(0x30000000),
    );

    // Extension fill with owner color
    final fillPaint = Paint()..color = prop.isMortgaged ? const Color(0xFF64748B) : owner.color;
    canvas.drawRRect(rrect, fillPaint);

    // Gold Kasavu border
    final borderPaint = Paint()
      ..color = const Color(0xFFC5A049)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // Centered owner initial badge
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

  void _drawSingleSpace(Canvas canvas, int index, Rect rect) {
    final space = GameData.spaces[index];

    Property? prop;
    Player? owner;
    if (space.propertyId != null) {
      prop = properties[space.propertyId];
      final ownerId = prop?.ownerId;
      if (ownerId != null) {
        final matches = players.where((p) => p.id == ownerId);
        if (matches.isNotEmpty) {
          owner = matches.first;
        }
      }
    }

    // 1. Space background: White by default, lightly tinted with owner's color when owned
    Color bgColor = Colors.white;
    if (owner != null) {
      bgColor = prop!.isMortgaged
          ? const Color(0xFFF1F5F9)
          : Color.alphaBlend(owner.color.withValues(alpha: 0.12), Colors.white);
    }
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(rect, bgPaint);

    // Subtle crisp border
    final borderPaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, borderPaint);

    // 2. Prominent Outer-Edge Owner Stripe (3.5px solid vibrant stripe)
    if (owner != null) {
      _drawOwnerOuterStripe(canvas, index, rect, prop!.isMortgaged ? const Color(0xFF64748B) : owner.color);
    }

    // Corners
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

    // 3. Mortgaged Overlay if mortgaged
    if (prop != null && prop.isMortgaged) {
      _drawMortgagedOverlay(canvas, index, rect);
    }
  }

  void _drawOwnerOuterStripe(Canvas canvas, int index, Rect rect, Color color) {
    const double stripeThick = 3.5;
    Rect stripeRect;
    if (index > 0 && index < 10) {
      // Bottom edge: outer edge is bottom
      stripeRect = Rect.fromLTWH(rect.left, rect.bottom - stripeThick, rect.width, stripeThick);
    } else if (index > 10 && index < 20) {
      // Left edge: outer edge is left
      stripeRect = Rect.fromLTWH(rect.left, rect.top, stripeThick, rect.height);
    } else if (index > 20 && index < 30) {
      // Top edge: outer edge is top
      stripeRect = Rect.fromLTWH(rect.left, rect.top, rect.width, stripeThick);
    } else if (index > 30) {
      // Right edge: outer edge is right
      stripeRect = Rect.fromLTWH(rect.right - stripeThick, rect.top, stripeThick, rect.height);
    } else {
      return;
    }
    canvas.drawRect(stripeRect, Paint()..color = color);
  }

  void _drawMortgagedOverlay(Canvas canvas, int index, Rect rect) {
    canvas.save();
    canvas.clipRect(rect);
    final hatchPaint = Paint()
      ..color = const Color(0x3564748B)
      ..strokeWidth = 1.2;
    for (double i = -rect.height; i < rect.width + rect.height; i += 7) {
      canvas.drawLine(
        Offset(rect.left + i, rect.top),
        Offset(rect.left + i + rect.height, rect.bottom),
        hatchPaint,
      );
    }
    // "MORTGAGED" badge in center
    final badgeW = min(rect.width * 0.9, 44.0);
    final badgeRect = Rect.fromCenter(center: rect.center, width: badgeW, height: 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(3)),
      Paint()..color = const Color(0xEE475569),
    );
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

  void _drawPropertySpace(Canvas canvas, int index, Rect rect, BoardSpace space, [Player? owner]) {
    final prop = properties[space.propertyId];
    if (prop == null) return;

    final groupColor = _getGroupColor(prop.group);

    // 1. Color Category Header Band (Always on the INNER side of the track)
    Rect headerRect;
    if (index > 0 && index < 10) {
      // Bottom edge: header is on top (inner edge)
      headerRect = Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.28);
    } else if (index > 10 && index < 20) {
      // Left edge: header is on right (inner edge)
      headerRect = Rect.fromLTWH(rect.right - rect.width * 0.28, rect.top, rect.width * 0.28, rect.height);
    } else if (index > 20 && index < 30) {
      // Top edge: header is on bottom (inner edge)
      headerRect = Rect.fromLTWH(rect.left, rect.bottom - rect.height * 0.28, rect.width, rect.height * 0.28);
    } else {
      // Right edge: header is on left (inner edge)
      headerRect = Rect.fromLTWH(rect.left, rect.top, rect.width * 0.28, rect.height);
    }

    canvas.drawRect(headerRect, Paint()..color = groupColor);
    canvas.drawRect(
      headerRect,
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // 2. Owner Marker & Houses/Resorts
    if (owner != null) {
      if (prop.currentLevel > 0) {
        // Houses / Resorts
        _drawBuildings(canvas, headerRect, prop.currentLevel);
        // Owner small badge on side of header
        final badgeCenter = Offset(headerRect.left + 5.0, headerRect.center.dy);
        canvas.drawCircle(badgeCenter, 3.8, Paint()..color = Colors.white);
        canvas.drawCircle(badgeCenter, 2.8, Paint()..color = owner.color);
      } else {
        // Owner initial badge centered on header
        canvas.drawCircle(headerRect.center, 5.5, Paint()..color = Colors.white);
        canvas.drawCircle(headerRect.center, 4.2, Paint()..color = owner.color);
        final initial = owner.name.trim().isNotEmpty ? owner.name.trim()[0].toUpperCase() : 'P';
        final tp = TextPainter(
          text: TextSpan(
            text: initial,
            style: const TextStyle(color: Colors.white, fontSize: 5.5, fontWeight: FontWeight.w900),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(headerRect.center.dx - tp.width / 2, headerRect.center.dy - tp.height / 2));
      }
    }

    // 3. Crisp, High-Contrast Space Name and Price Tag
    _drawReadableText(
      canvas: canvas,
      rect: rect,
      index: index,
      title: prop.name,
      priceText: '₹${prop.price}',
    );
  }

  void _drawBuildings(Canvas canvas, Rect headerRect, int level) {
    if (level == 5) {
      // Resort (Hotel Level): Gold Resort shape
      _drawResort(canvas, headerRect.center, 12, const Color(0xFFFFD54F));
    } else {
      // 1-4 Cottages: Crisp green house shapes
      double size = 5.0;
      double spacing = 2.5;
      double totalW = level * size + (level - 1) * spacing;
      double startX = headerRect.center.dx - totalW / 2;

      for (int i = 0; i < level; i++) {
        _drawCottage(
          canvas,
          Offset(startX + i * (size + spacing) + size / 2, headerRect.center.dy),
          size,
          const Color(0xFF1B5E20),
        );
      }
    }
  }

  void _drawCottage(Canvas canvas, Offset center, double size, Color color) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size / 2);
    path.lineTo(center.dx + size / 2, center.dy);
    path.lineTo(center.dx + size / 2, center.dy + size / 2);
    path.lineTo(center.dx - size / 2, center.dy + size / 2);
    path.lineTo(center.dx - size / 2, center.dy);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 0.5);
  }

  void _drawResort(Canvas canvas, Offset center, double size, Color color) {
    final r = Rect.fromCenter(center: center, width: size, height: size * 0.8);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(2)),
      Paint()..color = const Color(0xFF8D6E63)..style = PaintingStyle.stroke..strokeWidth = 1,
    );
  }

  void _drawSpecialSpace(Canvas canvas, int index, Rect rect, BoardSpace space, [Player? owner]) {
    String sub = '';
    VoidCallback drawIcon;

    switch (space.type) {
      case SpaceType.railroad:
        final prop = properties[space.propertyId];
        sub = '₹${prop?.price ?? 135}';
        if (space.name.contains('Metro')) {
          drawIcon = () => _drawMetroIcon(canvas, rect.center);
        } else if (space.name.contains('Airport')) {
          drawIcon = () => _drawPlaneIcon(canvas, rect.center);
        } else if (space.name.contains('Ferry')) {
          drawIcon = () => _drawFerryIcon(canvas, rect.center);
        } else {
          drawIcon = () => _drawBusIcon(canvas, rect.center);
        }
        break;
      case SpaceType.utility:
        final prop = properties[space.propertyId];
        sub = '₹${prop?.price ?? 100}';
        if (space.name.contains('KSEB')) {
          drawIcon = () => _drawLightningIcon(canvas, rect.center);
        } else {
          drawIcon = () => _drawWaterDropIcon(canvas, rect.center);
        }
        break;
      case SpaceType.chance:
        sub = 'MONSOON';
        drawIcon = () => _drawRainCloudIcon(canvas, rect.center);
        break;
      case SpaceType.communityChest:
        sub = 'FESTIVAL';
        drawIcon = () => _drawLampIcon(canvas, rect.center);
        break;
      case SpaceType.tax:
        sub = '₹${space.feeAmount ?? 50}';
        drawIcon = () => _drawTaxIcon(canvas, rect.center);
        break;
      default:
        drawIcon = () {};
        break;
    }

    // Owner badge on railroad or utility
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
        text: TextSpan(
          text: initial,
          style: const TextStyle(color: Colors.white, fontSize: 5.0, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(badgeOffset.dx - tp.width / 2, badgeOffset.dy - tp.height / 2));
    }

    _drawReadableSpecialText(
      canvas: canvas,
      rect: rect,
      index: index,
      title: space.name,
      subText: sub,
      drawIcon: drawIcon,
    );
  }

  // ==================== READABLE TEXT ENGINE ====================
  // Keeps text completely legible, properly sized, and never upside-down!

  void _drawReadableText({
    required Canvas canvas,
    required Rect rect,
    required int index,
    required String title,
    required String priceText,
  }) {
    canvas.save();

    // Bottom Row (1-9) & Top Row (21-29) are painted upright so player reads naturally!
    // Left (11-19) & Right (31-39) are turned inwards cleanly with generous margins
    if (index > 10 && index < 20) {
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(pi / 2);
      canvas.translate(-rect.center.dx, -rect.center.dy);
    } else if (index > 30) {
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(-pi / 2);
      canvas.translate(-rect.center.dx, -rect.center.dy);
    }

    // Format title cleanly (split if long)
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

    // Compute vertical positioning depending on edge
    double maxW = (index > 10 && index < 20) || index > 30 ? rect.height - 4 : rect.width - 2;
    painter.layout(maxWidth: maxW);

    double offsetY;
    if (index > 0 && index < 10) {
      // Header is top, text is lower
      offsetY = rect.bottom - painter.height - 4;
    } else if (index > 20 && index < 30) {
      // Header is bottom, text is upper
      offsetY = rect.top + 4;
    } else {
      offsetY = rect.center.dy - painter.height / 2;
    }

    painter.paint(canvas, Offset(rect.center.dx - painter.width / 2, offsetY));

    canvas.restore();
  }

  void _drawReadableSpecialText({
    required Canvas canvas,
    required Rect rect,
    required int index,
    required String title,
    required String subText,
    required VoidCallback drawIcon,
  }) {
    canvas.save();

    if (index > 10 && index < 20) {
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(pi / 2);
      canvas.translate(-rect.center.dx, -rect.center.dy);
    } else if (index > 30) {
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(-pi / 2);
      canvas.translate(-rect.center.dx, -rect.center.dy);
    }

    // Draw the Vector Icon in upper area
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

    double maxW = (index > 10 && index < 20) || index > 30 ? rect.height - 4 : rect.width - 2;
    painter.layout(maxWidth: maxW);

    double offsetY = (index > 20 && index < 30) ? rect.top + 3 : rect.bottom - painter.height - 3;
    painter.paint(canvas, Offset(rect.center.dx - painter.width / 2, offsetY));

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

  // ==================== VECTOR ICONS (NO EMOJIS) ====================

  void _drawBusIcon(Canvas canvas, Offset center) {
    final p = Paint()..color = const Color(0xFFE65100);
    final rect = Rect.fromCenter(center: center - const Offset(0, 10), width: 14, height: 10);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), p);
    // Wheels
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
    // Base & Stem
    canvas.drawOval(Rect.fromCenter(center: c + const Offset(0, 5), width: 10, height: 3), brassPaint);
    canvas.drawRect(Rect.fromLTWH(c.dx - 1.5, c.dy - 2, 3, 7), brassPaint);
    canvas.drawOval(Rect.fromCenter(center: c - const Offset(0, 2), width: 8, height: 3), brassPaint);
    // Flame
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

    // Checkered Banner Vector
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

    // Inner cell
    final innerCell = Rect.fromLTWH(r.left + r.width * 0.35, r.top, r.width * 0.65, r.height * 0.65);
    canvas.drawRect(innerCell, Paint()..color = const Color(0xFFFFE0B2));

    // Jail bars
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

    // Vector Cup
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

    // Vector Siren / Badge
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
      case PropertyGroup.malabar: return const Color(0xFF8D5524); // Warm Mahogany
      case PropertyGroup.thrissur: return const Color(0xFF0288D1); // Coastal Cerulean
      case PropertyGroup.kochi: return const Color(0xFFD81B60); // Vibrant Magenta
      case PropertyGroup.backwaters: return const Color(0xFFF57C00); // Heritage Amber
      case PropertyGroup.highlands: return const Color(0xFFD32F2F); // Royal Crimson
      case PropertyGroup.southKerala: return const Color(0xFFFBC02D); // Saffron Gold
      case PropertyGroup.premium: return const Color(0xFF2E7D32); // Tea Garden Emerald
      case PropertyGroup.luxury: return const Color(0xFF1565C0); // Arabian Sea Navy
      default: return Colors.blueGrey;
    }
  }

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
