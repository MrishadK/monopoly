import 'dart:math';
import 'package:flutter/material.dart';

/// High-fidelity 3D Ivory Die with authentic pips and realistic perspective shading.
class DiceFaceWidget extends StatelessWidget {
  final int value;
  final double size;
  final double rotation;
  final double elevation;

  const DiceFaceWidget({
    super.key,
    required this.value,
    this.size = 52.0,
    this.rotation = 0.0,
    this.elevation = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(1, 6);

    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFAF7F0),
              Color(0xFFECE6D8),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
          border: Border.all(
            color: const Color(0xFFC5A049), // Kasavu Gold edge trim
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x35000000),
              blurRadius: elevation * 2,
              offset: Offset(0, elevation),
            ),
            // Top-left specular highlight
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 2,
              offset: const Offset(-1, -1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.16),
          child: CustomPaint(
            painter: _DicePipPainter(value: clampedValue),
          ),
        ),
      ),
    );
  }
}

class _DicePipPainter extends CustomPainter {
  final int value;

  _DicePipPainter({required this.value});

  static final Paint _aceDotPaint = Paint()
    ..color = const Color(0xFFC62828)
    ..style = PaintingStyle.fill;

  static final Paint _aceBorderPaint = Paint()
    ..color = const Color(0xFF8E0000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  static final Paint _slateDotPaint = Paint()
    ..color = const Color(0xFF1E293B)
    ..style = PaintingStyle.fill;

  static final Paint _slateBorderPaint = Paint()
    ..color = const Color(0xFF0F172A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  @override
  void paint(Canvas canvas, Size size) {
    // Traditional Indian / Kasavu dice: "1" has a large crimson dot, others have deep slate pips
    final isAce = value == 1;
    final dotPaint = isAce ? _aceDotPaint : _slateDotPaint;
    final dotBorderPaint = isAce ? _aceBorderPaint : _slateBorderPaint;

    final dotRadius = isAce ? size.width * 0.22 : size.width * 0.13;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = size.width * 0.18;
    final right = size.width * 0.82;
    final top = size.height * 0.18;
    final bottom = size.height * 0.82;

    void drawPip(double x, double y) {
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      canvas.drawCircle(Offset(x, y), dotRadius, dotBorderPaint);
    }

    if (value % 2 == 1) {
      drawPip(cx, cy); // Center dot for 1, 3, 5
    }

    if (value > 1) {
      drawPip(left, top);
      drawPip(right, bottom);
    }

    if (value > 3) {
      drawPip(right, top);
      drawPip(left, bottom);
    }

    if (value == 6) {
      drawPip(left, cy);
      drawPip(right, cy);
    }
  }

  @override
  bool shouldRepaint(covariant _DicePipPainter oldDelegate) => oldDelegate.value != value;
}

/// Dynamic 3D Tumbling Pair of Dice with sound and physics tumble simulation
class TumblingDicePairWidget extends StatefulWidget {
  final List<int> dice;
  final bool isRolling;
  final bool isDoubles;
  final double diceSize;
  final VoidCallback? onTap;

  const TumblingDicePairWidget({
    super.key,
    required this.dice,
    this.isRolling = false,
    this.isDoubles = false,
    this.diceSize = 46.0,
    this.onTap,
  });

  @override
  State<TumblingDicePairWidget> createState() => _TumblingDicePairWidgetState();
}

class _TumblingDicePairWidgetState extends State<TumblingDicePairWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rnd = Random();
  int _displayD1 = 1;
  int _displayD2 = 1;
  int _lastFaceUpdateMs = 0;

  @override
  void initState() {
    super.initState();
    _displayD1 = widget.dice.isNotEmpty ? widget.dice[0] : 1;
    _displayD2 = widget.dice.length > 1 ? widget.dice[1] : 1;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        if (widget.isRolling) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - _lastFaceUpdateMs >= 80) {
            _lastFaceUpdateMs = now;
            setState(() {
              _displayD1 = _rnd.nextInt(6) + 1;
              _displayD2 = _rnd.nextInt(6) + 1;
            });
          }
        }
      });

    if (widget.isRolling) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant TumblingDicePairWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _lastFaceUpdateMs = 0;
      _controller.repeat();
    } else if (!widget.isRolling && oldWidget.isRolling) {
      _controller.stop();
      setState(() {
        _displayD1 = widget.dice.isNotEmpty ? widget.dice[0] : 1;
        _displayD2 = widget.dice.length > 1 ? widget.dice[1] : 1;
      });
    } else if (!widget.isRolling) {
      _displayD1 = widget.dice.isNotEmpty ? widget.dice[0] : 1;
      _displayD2 = widget.dice.length > 1 ? widget.dice[1] : 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value * 2 * pi;
            final rot1 = widget.isRolling ? sin(t * 3) * 0.4 : 0.0;
            final rot2 = widget.isRolling ? -cos(t * 3) * 0.4 : 0.0;
            final bounce1 = widget.isRolling ? -sin(t * 4).abs() * 8.0 : 0.0;
            final bounce2 = widget.isRolling ? -cos(t * 4).abs() * 8.0 : 0.0;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  child: Transform.translate(
                    offset: Offset(0, bounce1),
                    child: DiceFaceWidget(
                      value: _displayD1,
                      size: widget.diceSize,
                      rotation: rot1,
                      elevation: widget.isRolling ? 8.0 : 4.0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                RepaintBoundary(
                  child: Transform.translate(
                    offset: Offset(0, bounce2),
                    child: DiceFaceWidget(
                      value: _displayD2,
                      size: widget.diceSize,
                      rotation: rot2,
                      elevation: widget.isRolling ? 8.0 : 4.0,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
