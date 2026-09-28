import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';
import 'game_screen.dart';

import '../../services/user_profile_service.dart';

class LocalSetupScreen extends ConsumerStatefulWidget {
  const LocalSetupScreen({super.key});

  @override
  ConsumerState<LocalSetupScreen> createState() => _LocalSetupScreenState();
}

class _LocalSetupScreenState extends ConsumerState<LocalSetupScreen> {
  int _startingCash = 150000;
  late List<Player> _players;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _players = [
      profile.toPlayer(cash: 150000),
      const Player(
        id: 'p2',
        name: 'Nihal (Bot)',
        type: PlayerType.ai,
        token: PlayerToken.coconut,
        color: Color(0xFF2196F3),
        aiPersonality: AiPersonality.conservative,
      ),
    ];
  }

  final List<Color> _palette = const [
    Color(0xFFE91E63),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
    Color(0xFF9C27B0),
    Color(0xFFFF5722),
  ];

  void _addPlayer() {
    if (_players.length >= 4) return;
    int idx = _players.length + 1;
    setState(() {
      _players.add(Player(
        id: 'p$idx',
        name: 'Bot $idx',
        type: PlayerType.ai,
        token: PlayerToken.values[idx % PlayerToken.values.length],
        color: _palette[idx % _palette.length],
        aiPersonality: AiPersonality.values[idx % AiPersonality.values.length],
        cash: _startingCash,
      ));
    });
  }

  void _removePlayer(int index) {
    if (_players.length <= 2) return;
    setState(() {
      _players.removeAt(index);
    });
  }

  void _editPlayer(int index) {
    final player = _players[index];
    final nameController = TextEditingController(text: player.name);
    PlayerToken selectedToken = player.token;
    Color selectedColor = player.color;
    PlayerType selectedType = player.type;
    AiPersonality selectedPersonality = player.aiPersonality ?? AiPersonality.conservative;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF102218),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFFFD54F), width: 1.5),
            ),
            title: Text('EDIT PLAYER', style: GoogleFonts.outfit(color: const Color(0xFFFFD54F), fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Player Name',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Player Type
                  Row(
                    children: [
                      const Text('Type: ', style: TextStyle(color: Colors.white70)),
                      ChoiceChip(
                        label: const Text('Human'),
                        selected: selectedType == PlayerType.human,
                        onSelected: (val) => setModalState(() => selectedType = PlayerType.human),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('AI Bot'),
                        selected: selectedType == PlayerType.ai,
                        onSelected: (val) => setModalState(() => selectedType = PlayerType.ai),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // AI Personality (if AI)
                  if (selectedType == PlayerType.ai) ...[
                    const Text('Bot Strategy:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    DropdownButton<AiPersonality>(
                      value: selectedPersonality,
                      dropdownColor: const Color(0xFF14241B),
                      isExpanded: true,
                      style: GoogleFonts.outfit(color: Colors.white),
                      items: AiPersonality.values.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text('${p.name.toUpperCase()} - ${_getPersonalityDesc(p)}', style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedPersonality = val);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Token Picker
                  const Text('Select Kerala Token:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PlayerToken.values.map((t) {
                      final isSelected = selectedToken == t;
                      return InkWell(
                        onTap: () => setModalState(() => selectedToken = t),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFD54F) : Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? Colors.white : Colors.transparent),
                          ),
                          child: Icon(
                            Player(id: '', name: '', type: PlayerType.human, token: t, color: Colors.white).tokenIcon,
                            size: 22,
                            color: isSelected ? Colors.black87 : Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Color Picker
                  const Text('Select Color:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _palette.map((c) {
                      final isSelected = selectedColor == c;
                      return InkWell(
                        onTap: () => setModalState(() => selectedColor = c),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: c,
                          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD54F), foregroundColor: Colors.black),
                onPressed: () {
                  setState(() {
                    _players[index] = player.copyWith(
                      name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : player.name,
                      type: selectedType,
                      token: selectedToken,
                      color: selectedColor,
                      aiPersonality: selectedType == PlayerType.ai ? selectedPersonality : null,
                    );
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('SAVE'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getPersonalityDesc(AiPersonality p) {
    switch (p) {
      case AiPersonality.conservative: return 'Cautious, keeps high reserves';
      case AiPersonality.aggressive: return 'Buys everything, builds resorts fast';
      case AiPersonality.investor: return 'Focuses on Transports & Kochi/Thrissur';
      case AiPersonality.trader: return 'Seeks fair trades & negotiations';
      case AiPersonality.riskTaker: return 'Spends down to last rupee';
    }
  }

  void _startGame() {
    final configuredPlayers = _players.map((p) => p.copyWith(cash: _startingCash)).toList();
    ref.read(gameProvider.notifier).initializeGame(configuredPlayers);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1811),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F241A),
        title: Text(
          'MATCH SETUP',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2, color: const Color(0xFFFFD54F)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Starting Cash Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Starting Cash:', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                  DropdownButton<int>(
                    value: _startingCash,
                    dropdownColor: const Color(0xFF102218),
                    style: GoogleFonts.outfit(color: const Color(0xFF69F0AE), fontWeight: FontWeight.bold, fontSize: 15),
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 100000, child: Text('₹1,00,000 (Quick Blitz)')),
                      DropdownMenuItem(value: 150000, child: Text('₹1,50,000 (Standard Kerala)')),
                      DropdownMenuItem(value: 250000, child: Text('₹2,50,000 (Tycoon Mode)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _startingCash = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Players List
            Expanded(
              child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (context, index) {
                  final player = _players[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: player.color.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: player.color,
                        child: Icon(player.tokenIcon, size: 22, color: Colors.white),
                      ),
                      title: Row(
                        children: [
                          Text(
                            player.name,
                            style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: player.type == PlayerType.human ? Colors.blue.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              player.type == PlayerType.human ? 'HUMAN' : 'BOT (${player.aiPersonality?.name.toUpperCase()})',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: player.type == PlayerType.human ? Colors.lightBlueAccent : Colors.amberAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Token: ${player.tokenName}',
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFFFFD54F)),
                            onPressed: () => _editPlayer(index),
                          ),
                          if (_players.length > 2)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _removePlayer(index),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_players.length < 4)
              OutlinedButton.icon(
                onPressed: _addPlayer,
                icon: const Icon(Icons.add, color: Color(0xFFFFD54F)),
                label: Text('ADD PLAYER (${_players.length}/4)', style: GoogleFonts.outfit(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFD54F)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 6,
                ),
                child: Text(
                  'START GAME ➔',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
