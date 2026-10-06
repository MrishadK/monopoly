import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../../models/property.dart';
import '../../models/player.dart';
import '../../services/user_profile_service.dart';
import '../../services/multiplayer_service.dart';

class AuctionOverlay extends ConsumerWidget {
  const AuctionOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAuction = ref.watch(
      gameProvider.select((s) => s.activeAuction != null),
    );
    if (!hasAuction) return const SizedBox.shrink();

    return const RepaintBoundary(child: _AuctionOverlayModal());
  }
}

class _AuctionOverlayModal extends ConsumerStatefulWidget {
  const _AuctionOverlayModal();

  @override
  ConsumerState<_AuctionOverlayModal> createState() =>
      _AuctionOverlayModalState();
}

class _AuctionOverlayModalState extends ConsumerState<_AuctionOverlayModal> {
  final TextEditingController _customBidController = TextEditingController();

  @override
  void dispose() {
    _customBidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final auction = gameState.activeAuction;

    if (auction == null) return const SizedBox.shrink();

    ref.listen(gameProvider.select((s) => s.activeAuction?.isCompleted), (
      prev,
      isCompleted,
    ) {
      if (isCompleted == true) {
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) {
            ref.read(gameProvider.notifier).closeAuction();
          }
        });
      }
    });

    final prop = gameState.properties[auction.propertyId];
    if (prop == null) return const SizedBox.shrink();

    final myProfile = ref.watch(userProfileProvider);
    final multiplayer = ref.watch(multiplayerServiceProvider);
    final isOnline = multiplayer.isConnected;
    final myLocalId =
        ref.watch(gameProvider.notifier).localPlayerId ?? myProfile.id;

    final currentBidderId = auction.currentBidderId;
    final currentBidder = gameState.players.firstWhere(
      (p) => p.id == currentBidderId,
      orElse: () => gameState.currentPlayer,
    );

    final highestBidder = auction.highestBidderId != null
        ? gameState.players.firstWhere(
            (p) => p.id == auction.highestBidderId,
            orElse: () => currentBidder,
          )
        : null;

    final isMyTurnToBid =
        (!isOnline || currentBidder.id == myLocalId) &&
        currentBidder.type == PlayerType.human &&
        !auction.isCompleted;

    final groupColor = _getGroupColor(prop.group);
    final minNextBid = auction.minimumNextBid;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 30,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: groupColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.gavel_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PROPERTY AUCTION',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prop.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Market Value: ₹${prop.price}',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: [
                    // High Bid Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            auction.highestBid > 0
                                ? 'CURRENT HIGHEST BID'
                                : 'STARTING BID',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF92400E),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auction.highestBid > 0
                                ? '₹${auction.highestBid}'
                                : '₹0',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFB45309),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (highestBidder != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 9,
                                  backgroundColor: highestBidder.color,
                                  child: Icon(
                                    highestBidder.tokenIcon,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Held by ${highestBidder.name}',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF78350F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'No bids placed yet (Min: ₹$minNextBid)',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF92400E),
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Active Turn or Completed Status
                    if (auction.isCompleted) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: Color(0xFF047857),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              auction.winnerId != null
                                  ? '${gameState.players.firstWhere((p) => p.id == auction.winnerId).name} Wins for ₹${auction.winningBid}!'
                                  : 'Auction ended with no bids.',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF047857),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isMyTurnToBid) ...[
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: currentBidder.color,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                isMyTurnToBid
                                    ? 'YOUR TURN TO BID (${currentBidder.name}, Cash: ₹${currentBidder.cash}) - ${auction.timeRemaining}s'
                                    : 'Waiting for ${currentBidder.name} to bid... (${auction.timeRemaining}s)',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: isMyTurnToBid
                                      ? const Color(0xFF047857)
                                      : const Color(0xFF475569),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Bid History Log (last 3 entries)
                    if (auction.bidHistory.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AUCTION LOG',
                              style: GoogleFonts.outfit(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            ...auction.bidHistory.reversed
                                .take(2)
                                .map(
                                  (log) => Text(
                                    '• $log',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.5,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Interactive Action Controls for human bidder
                    if (isMyTurnToBid) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF047857),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: currentBidder.cash >= minNextBid
                                  ? () => ref
                                        .read(gameProvider.notifier)
                                        .placeBid(currentBidder.id, minNextBid)
                                  : null,
                              child: Text(
                                'BID ₹$minNextBid',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: currentBidder.cash >= minNextBid + 20
                                  ? () => ref
                                        .read(gameProvider.notifier)
                                        .placeBid(
                                          currentBidder.id,
                                          minNextBid + 20,
                                        )
                                  : null,
                              child: Text(
                                '+ ₹20',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(
                                  color: Color(0xFFFCA5A5),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => ref
                                  .read(gameProvider.notifier)
                                  .passBid(currentBidder.id),
                              child: Text(
                                'FOLD',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Custom Bid Trigger
                      InkWell(
                        onTap: () => _showCustomBidDialog(
                          context,
                          currentBidder,
                          minNextBid,
                        ),
                        child: Text(
                          'Enter Custom Bid Amount',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF0284C7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ] else if (auction.isCompleted) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                          ),
                          label: Text(
                            'BID FINALIZED • CLOSING...',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () =>
                              ref.read(gameProvider.notifier).closeAuction(),
                        ),
                      ),
                    ] else ...[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // Allow passive viewing
                        },
                        child: const Text('Bidding in progress...'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomBidDialog(BuildContext context, Player player, int minBid) {
    _customBidController.text = minBid.toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Place Custom Bid',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Cash: ₹${player.cash}\nMinimum Bid: ₹$minBid',
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customBidController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                labelText: 'Bid Amount',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final amount = int.tryParse(_customBidController.text);
              if (amount != null && amount >= minBid && amount <= player.cash) {
                Navigator.pop(ctx);
                ref.read(gameProvider.notifier).placeBid(player.id, amount);
              }
            },
            child: const Text('SUBMIT BID'),
          ),
        ],
      ),
    );
  }

  Color _getGroupColor(PropertyGroup group) {
    switch (group) {
      case PropertyGroup.malabar:
        return const Color(0xFF8D5524);
      case PropertyGroup.thrissur:
        return const Color(0xFF0288D1);
      case PropertyGroup.kochi:
        return const Color(0xFFD81B60);
      case PropertyGroup.backwaters:
        return const Color(0xFFF57C00);
      case PropertyGroup.highlands:
        return const Color(0xFFD32F2F);
      case PropertyGroup.southKerala:
        return const Color(0xFFFBC02D);
      case PropertyGroup.premium:
        return const Color(0xFF2E7D32);
      case PropertyGroup.luxury:
        return const Color(0xFF1565C0);
      case PropertyGroup.transport:
        return const Color(0xFF546E7A);
      case PropertyGroup.utility:
        return const Color(0xFF78909C);
      case PropertyGroup.brown:
        // TODO: Handle this case.
        throw UnimplementedError();
      case PropertyGroup.lightBlue:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}
