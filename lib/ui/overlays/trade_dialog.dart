import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../models/trade_offer.dart';
import '../../providers/game_provider.dart';
import '../../services/user_profile_service.dart';

class TradeDialog extends ConsumerStatefulWidget {
  const TradeDialog({super.key});

  @override
  ConsumerState<TradeDialog> createState() => _TradeDialogState();
}

class _TradeDialogState extends ConsumerState<TradeDialog> {
  Player? _selectedTarget;
  final Set<String> _offeredProps = {};
  final Set<String> _requestedProps = {};
  double _offeredCash = 0;
  double _requestedCash = 0;
  String? _resultMessage;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final myProfile = ref.watch(userProfileProvider);
    final myLocalId = ref.watch(gameProvider.notifier).localPlayerId ?? myProfile.id;
    final myPlayer = gameState.players.firstWhere(
      (p) => p.id == myLocalId,
      orElse: () => gameState.players.firstWhere(
        (p) => p.type == PlayerType.human,
        orElse: () => gameState.currentPlayer,
      ),
    );
    final otherPlayers = gameState.players.where((p) => p.id != myPlayer.id && !p.isBankrupt).toList();

    _selectedTarget ??= otherPlayers.isNotEmpty ? otherPlayers.first : null;

    if (_selectedTarget == null) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text('TRADE', style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        content: Text('No other active players to trade with.', style: GoogleFonts.outfit(color: const Color(0xFF475569))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      );
    }

    final target = _selectedTarget!;
    final myProps = myPlayer.ownedPropertyIds.map((id) => gameState.properties[id]!).toList();
    final targetProps = target.ownedPropertyIds.map((id) => gameState.properties[id]!).toList();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: Color(0xFF0F172A), size: 26),
                    const SizedBox(width: 8),
                    Text(
                      'PROPOSE TRADE',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE2E8F0)),

            // Select Target Partner
            DropdownButton<String>(
              value: target.id,
              dropdownColor: Colors.white,
              isExpanded: true,
              style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
              items: otherPlayers.map((p) {
                return DropdownMenuItem(
                  value: p.id,
                  child: Row(
                    children: [
                      Icon(p.tokenIcon, color: p.color, size: 20),
                      const SizedBox(width: 8),
                      Text(p.name, style: TextStyle(color: p.color, fontWeight: FontWeight.bold)),
                      Text(p.type == PlayerType.ai ? ' (Bot)' : ' (Human)', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newId) {
                if (newId != null) {
                  setState(() {
                    _selectedTarget = otherPlayers.firstWhere((p) => p.id == newId);
                    _requestedProps.clear();
                    _requestedCash = 0;
                    _resultMessage = null;
                  });
                }
              },
            ),

            if (_resultMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _resultMessage!.contains('Accepted') ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _resultMessage!,
                  style: GoogleFonts.outfit(
                    color: _resultMessage!.contains('Accepted') ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Two Columns: You Offer vs You Want
            Expanded(
              child: Row(
                children: [
                  // You Offer
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YOU GIVE:', style: GoogleFonts.outfit(color: const Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Cash: ₹${_offeredCash.toInt()}', style: GoogleFonts.outfit(color: const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600)),
                          Slider(
                            value: _offeredCash.clamp(0.0, myPlayer.cash.toDouble()),
                            min: 0,
                            max: myPlayer.cash.toDouble().clamp(1.0, double.infinity),
                            divisions: myPlayer.cash > 0 ? 20 : 1,
                            activeColor: const Color(0xFFD97706),
                            onChanged: (val) => setState(() => _offeredCash = val),
                          ),
                          Text('Properties (${myProps.length}):', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11)),
                          Expanded(
                            child: ListView(
                              children: myProps.map((p) {
                                return CheckboxListTile(
                                  dense: true,
                                  title: Text(p.name, style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600)),
                                  subtitle: Text('₹${p.price}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                                  value: _offeredProps.contains(p.id),
                                  activeColor: const Color(0xFF047857),
                                  onChanged: (checked) {
                                    setState(() {
                                      checked == true ? _offeredProps.add(p.id) : _offeredProps.remove(p.id);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // You Want
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('YOU GET:', style: GoogleFonts.outfit(color: const Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Cash: ₹${_requestedCash.toInt()}', style: GoogleFonts.outfit(color: const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600)),
                          Slider(
                            value: _requestedCash.clamp(0.0, target.cash.toDouble()),
                            min: 0,
                            max: target.cash.toDouble().clamp(1.0, double.infinity),
                            divisions: target.cash > 0 ? 20 : 1,
                            activeColor: const Color(0xFF059669),
                            onChanged: (val) => setState(() => _requestedCash = val),
                          ),
                          Text('Properties (${targetProps.length}):', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11)),
                          Expanded(
                            child: ListView(
                              children: targetProps.map((p) {
                                return CheckboxListTile(
                                  dense: true,
                                  title: Text(p.name, style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600)),
                                  subtitle: Text('₹${p.price}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                                  value: _requestedProps.contains(p.id),
                                  activeColor: const Color(0xFF047857),
                                  onChanged: (checked) {
                                    setState(() {
                                      checked == true ? _requestedProps.add(p.id) : _requestedProps.remove(p.id);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () {
                  final offer = TradeOffer(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    senderId: myPlayer.id,
                    receiverId: target.id,
                    offeredCash: _offeredCash.toInt(),
                    offeredPropertyIds: _offeredProps.toList(),
                    requestedCash: _requestedCash.toInt(),
                    requestedPropertyIds: _requestedProps.toList(),
                  );

                  if (target.type == PlayerType.ai) {
                    final isFair = ref.read(gameProvider.notifier).evaluateAiTrade(offer);
                    if (isFair) {
                      ref.read(gameProvider.notifier).executeTrade(offer);
                      setState(() {
                        _resultMessage = 'Deal Accepted! ${target.name} agreed to the trade.';
                      });
                      final nav = Navigator.of(context);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) nav.pop();
                      });
                    } else {
                      setState(() {
                        _resultMessage = 'Deal Rejected! ${target.name} wants more value.';
                      });
                    }
                  } else {
                    ref.read(gameProvider.notifier).proposeTrade(offer);
                    Navigator.pop(context);
                  }
                },
                child: Text('PROPOSE TRADE', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
