import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bankruptcy_record.dart';
import '../../models/player.dart';
import '../../services/audio_service.dart';
import '../../providers/game_provider.dart';

class BankruptcyOverlay extends ConsumerWidget {
  const BankruptcyOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final record = gameState.activeBankruptcyRecord;
    if (record == null) return const SizedBox.shrink();

    return _BankruptcyModal(record: record);
  }
}

class _BankruptcyModal extends ConsumerStatefulWidget {
  final BankruptcyRecord record;

  const _BankruptcyModal({required this.record});

  @override
  ConsumerState<_BankruptcyModal> createState() => _BankruptcyModalState();
}

class _BankruptcyModalState extends ConsumerState<_BankruptcyModal> with TickerProviderStateMixin {
  late AnimationController _stampController;
  late Animation<double> _stampScale;
  late Animation<double> _stampOpacity;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  bool _hasTriggeredImpact = false;

  @override
  void initState() {
    super.initState();

    // 1. Stamp Drop & Slam Animation
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _stampScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 3.5, end: 0.95).chain(CurveTween(curve: Curves.easeInQuad)), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05).chain(CurveTween(curve: Curves.easeOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
    ]).animate(_stampController);

    _stampOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _stampController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    // 2. Impact Shake Animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_shakeController);

    _stampController.addListener(() {
      if (_stampController.value >= 0.70 && !_hasTriggeredImpact) {
        _hasTriggeredImpact = true;
        _shakeController.forward(from: 0.0);
        try {
          ref.read(audioServiceProvider.notifier).playBankruptcy();
        } catch (_) {}
      }
    });

    // Start stamping after document appears
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _stampController.forward();
      }
    });
  }

  @override
  void dispose() {
    _stampController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final token = (widget.record.playerTokenIndex >= 0 && widget.record.playerTokenIndex < PlayerToken.values.length)
        ? PlayerToken.values[widget.record.playerTokenIndex]
        : PlayerToken.houseboat;
    final playerColor = Color(widget.record.playerColorValue);

    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final shakeOffset = sin(_shakeAnimation.value * pi * 4) * 8 * (1 - _shakeAnimation.value);
              return Transform.translate(
                offset: Offset(shakeOffset, -shakeOffset * 0.5),
                child: child,
              );
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFBF7), // Warm Kerala Linen
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD7CCC8), width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0x60000000), blurRadius: 30, offset: Offset(0, 10)),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Gold Kasavu Decorative Border Trim
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5), width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  // Legal Decree Document Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Official Emblem Header
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF3C7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.gavel_rounded, color: Color(0xFFB45309), size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'KERALA LAND & REVENUE TRIBUNAL',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'DECREE OF INSOLVENCY',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'കോടതി ഉത്തരവ് • OFFICIAL LIQUIDATION',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),

                        const Divider(color: Color(0xFFE2E8F0), thickness: 1.2),
                        const SizedBox(height: 14),

                        // Bankrupt Player Name & Figurine Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: playerColor,
                              child: Icon(token.icon, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                widget.record.bankruptPlayerName,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF0F172A),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Having exhausted all liquid funds and unable to honor outstanding financial obligations, the aforesaid individual is hereby formally declared insolvent.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF334155),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Surrender Summary Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Titles Liquidated:',
                                    style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                                  ),
                                  Text(
                                    '${widget.record.propertiesForfeited} Properties',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Transferred To:',
                                    style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                                  ),
                                  Text(
                                    widget.record.creditorName ?? 'Kerala Public Bank',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF047857),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                            ),
                            onPressed: () {
                              ref.read(gameProvider.notifier).dismissBankruptcy();
                            },
                            child: Text(
                              'ACKNOWLEDGE & CONTINUE',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==================== 3D RED RUBBER WAX STAMP ====================
                  Positioned.fill(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _stampController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _stampOpacity.value,
                            child: Transform.scale(
                              scale: _stampScale.value,
                              child: Transform.rotate(
                                angle: -0.22, // Tilted authentic notary angle
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDC2626), width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'GOVT. OF KERALA • INSOLVENCY SEAL',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'BANKRUPT',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFDC2626),
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'ദിവാളി പ്രഖ്യാപിച്ചു',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFB91C1C),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                height: 2,
                                color: const Color(0xFFDC2626),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'DECREE: ${widget.record.bankruptPlayerName.toUpperCase()}',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFDC2626),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
