import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/property.dart';
import '../../providers/game_provider.dart';
import '../../services/user_profile_service.dart';
import '../../services/multiplayer_service.dart';

class TradeProposalOverlay extends ConsumerWidget {
  const TradeProposalOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTradeOffer = ref.watch(gameProvider.select((s) => s.activeTradeOffer != null));
    if (!hasTradeOffer) return const SizedBox.shrink();

    return const RepaintBoundary(
      child: _TradeProposalOverlayContent(),
    );
  }
}

class _TradeProposalOverlayContent extends ConsumerWidget {
  const _TradeProposalOverlayContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final offer = gameState.activeTradeOffer;

    if (offer == null) return const SizedBox.shrink();

    final sender = gameState.players.firstWhere(
      (p) => p.id == offer.senderId,
      orElse: () => gameState.currentPlayer,
    );
    final receiver = gameState.players.firstWhere(
      (p) => p.id == offer.receiverId,
      orElse: () => gameState.currentPlayer,
    );

    final myProfile = ref.watch(userProfileProvider);
    final multiplayer = ref.watch(multiplayerServiceProvider);
    final isOnline = multiplayer.isConnected;
    final myLocalId = ref.watch(gameProvider.notifier).localPlayerId ?? myProfile.id;

    final isReceiver = myLocalId == offer.receiverId;
    final isSender = myLocalId == offer.senderId;

    // For other players in an online match who are neither sender nor receiver, don't block their view
    if (isOnline && !isReceiver && !isSender) {
      return const SizedBox.shrink();
    }

    // Sender's view in an online match: Waiting status card with cancel button
    if (isOnline && isSender) {
      return Center(
        child: Container(
          width: 330,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x25000000), blurRadius: 25, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'TRADE OFFER PENDING',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Waiting for ${receiver.name} to accept or decline your trade offer...',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ref.read(gameProvider.notifier).cancelTradeOffer();
                  },
                  child: Text(
                    'CANCEL OFFER',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Receiver's view (or local pass-and-play): Full interactive Accept / Decline card
    final offeredProps = offer.offeredPropertyIds.map((id) => gameState.properties[id]).whereType<Property>().toList();
    final requestedProps = offer.requestedPropertyIds.map((id) => gameState.properties[id]).whereType<Property>().toList();

    return Center(
      child: Container(
        width: 360,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x30000000), blurRadius: 30, offset: Offset(0, 10)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INCOMING TRADE OFFER',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'From: ',
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                              ),
                              Icon(sender.tokenIcon, size: 14, color: sender.color),
                              const SizedBox(width: 4),
                              Text(
                                sender.name,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Section 1: You Receive
                    _buildTradeSection(
                      title: 'YOU WILL RECEIVE',
                      color: const Color(0xFF047857),
                      cash: offer.offeredCash,
                      properties: offeredProps,
                    ),

                    const SizedBox(height: 12),

                    // Section 2: You Give
                    _buildTradeSection(
                      title: 'YOU WILL GIVE',
                      color: const Color(0xFFD97706),
                      cash: offer.requestedCash,
                      properties: requestedProps,
                    ),

                    const SizedBox(height: 20),

                    // Decision Buttons: DECLINE vs ACCEPT TRADE
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              ref.read(gameProvider.notifier).respondToTrade(offer.id, false);
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: Text(
                              'REJECT',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF047857),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            onPressed: () {
                              ref.read(gameProvider.notifier).respondToTrade(offer.id, true);
                            },
                            icon: const Icon(Icons.handshake_rounded, size: 18),
                            label: Text(
                              'ACCEPT',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTradeSection({
    required String title,
    required Color color,
    required int cash,
    required List<Property> properties,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Cash
          if (cash > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, size: 16, color: Color(0xFF047857)),
                  const SizedBox(width: 6),
                  Text(
                    'Cash: ₹$cash',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Properties
          if (properties.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: properties.map((p) {
                final groupColor = _getGroupColor(p.group);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: groupColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.name,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0F172A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (p.isMortgaged) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '⚠️ Mortgaged',
                            style: TextStyle(color: Color(0xFFDC2626), fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),

          if (cash == 0 && properties.isEmpty)
            Text(
              'No cash or properties',
              style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

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
      case PropertyGroup.transport: return const Color(0xFF546E7A);
      case PropertyGroup.utility: return const Color(0xFF00897B);
    }
  }
}
