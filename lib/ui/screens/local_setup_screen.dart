import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';
import '../../services/user_profile_service.dart';
import 'game_screen.dart';

class LocalSetupScreen extends ConsumerStatefulWidget {
  const LocalSetupScreen({super.key});

  @override
  ConsumerState<LocalSetupScreen> createState() => _LocalSetupScreenState();
}

class _LocalSetupScreenState extends ConsumerState<LocalSetupScreen> {
  int _startingCash = 1000;
  late List<Player> _players;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _players = [
      profile.toPlayer(cash: 1000),
      const Player(
        id: 'p2',
        name: 'Aadu Thoma',
        type: PlayerType.ai,
        token: PlayerToken.coconut,
        color: Color(0xFF0284C7),
        aiPersonality: AiPersonality.conservative,
      ),
    ];
  }

  final List<Color> _palette = const [
    Color(0xFF047857), // Kerala Emerald
    Color(0xFFD97706), // Kasavu Gold
    Color(0xFF0284C7), // Backwater Azure
    Color(0xFFE11D48), // Crimson Red
    Color(0xFF7C3AED), // Royal Violet
    Color(0xFFEA580C), // Terracotta Orange
  ];

  final Map<PlayerToken, String> _tokenShortNames = const {
    PlayerToken.houseboat: 'Houseboat',
    PlayerToken.coconut: 'Thenga',
    PlayerToken.elephant: 'Aana',
    PlayerToken.chayaGlass: 'Chaya',
    PlayerToken.ksrtcBus: 'Minnal',
    PlayerToken.fishingBoat: 'Chundan',
    PlayerToken.coconutTree: 'Palm',
    PlayerToken.nilavilakku: 'Vilakku',
  };

  void _addPlayer() {
    if (_players.length >= 6) return;
    HapticFeedback.lightImpact();
    int idx = _players.length + 1;
    const botAliases = ['Aadu Thoma', 'Ranga Annan', 'Dasamoolam Damu', 'Shaji Pappan', 'Manavalan'];
    final botName = botAliases.firstWhere(
      (name) => !_players.any((p) => p.name == name),
      orElse: () => 'Character $idx',
    );
    setState(() {
      _players.add(Player(
        id: 'p$idx',
        name: botName,
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
    HapticFeedback.lightImpact();
    setState(() {
      _players.removeAt(index);
    });
  }

  void _editPlayer(int index) {
    HapticFeedback.selectionClick();
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
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF047857),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'EDIT PLAYER',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    Text(
                      'PLAYER NAME',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF047857), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Player Type Segmented Control
                    Text(
                      'PLAYER TYPE',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => selectedType = PlayerType.human),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedType == PlayerType.human
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedType == PlayerType.human
                                      ? const Color(0xFF047857)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Human Player',
                                style: GoogleFonts.outfit(
                                  color: selectedType == PlayerType.human ? Colors.white : const Color(0xFF475569),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => selectedType = PlayerType.ai),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedType == PlayerType.ai
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedType == PlayerType.ai
                                      ? const Color(0xFF047857)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'AI Bot',
                                style: GoogleFonts.outfit(
                                  color: selectedType == PlayerType.ai ? Colors.white : const Color(0xFF475569),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // AI Personality (if AI)
                    if (selectedType == PlayerType.ai) ...[
                      Text(
                        'AI STRATEGY',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButton<AiPersonality>(
                          value: selectedPersonality,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF0F172A)),
                          items: AiPersonality.values.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(
                                '${p.name.toUpperCase()} • ${_getPersonalityDesc(p)}',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF0F172A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedPersonality = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Token Picker
                    Text(
                      'KERALA GAME TOKEN',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: PlayerToken.values.length,
                      itemBuilder: (context, i) {
                        final t = PlayerToken.values[i];
                        final isSelected = selectedToken == t;
                        final dummy = Player(
                          id: '',
                          name: '',
                          type: PlayerType.human,
                          token: t,
                          color: Colors.white,
                        );
                        final label = _tokenShortNames[t] ?? 'Token';

                        return InkWell(
                          onTap: () => setModalState(() => selectedToken = t),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor.withValues(alpha: 0.15)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? selectedColor : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  dummy.tokenIcon,
                                  size: 20,
                                  color: isSelected ? selectedColor : const Color(0xFF64748B),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  label,
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? selectedColor : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Color Picker
                    Text(
                      'TOKEN COLOR',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _palette.map((c) {
                        final isSelected = selectedColor == c;
                        return InkWell(
                          onTap: () => setModalState(() => selectedColor = c),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: isSelected ? 36 : 30,
                            height: isSelected ? 36 : 30,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() {
                    _players[index] = player.copyWith(
                      name: nameController.text.trim().isNotEmpty
                          ? nameController.text.trim()
                          : player.name,
                      type: selectedType,
                      token: selectedToken,
                      color: selectedColor,
                      aiPersonality: selectedType == PlayerType.ai ? selectedPersonality : null,
                    );
                  });
                  Navigator.pop(ctx);
                },
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getPersonalityDesc(AiPersonality p) {
    switch (p) {
      case AiPersonality.conservative:
        return 'Cautious, keeps reserves';
      case AiPersonality.aggressive:
        return 'Buys fast, builds resorts';
      case AiPersonality.investor:
        return 'Focuses on prime transport';
      case AiPersonality.trader:
        return 'Active negotiator';
      case AiPersonality.riskTaker:
        return 'High roller';
    }
  }

  void _startGame() {
    HapticFeedback.mediumImpact();
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        centerTitle: true,
        title: Text(
          'MATCH SETUP',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: const Color(0xFF0F172A),
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================== STARTING CASH CARD ====================
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF047857),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STARTING CAPITAL',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          DropdownButton<int>(
                            value: _startingCash,
                            isDense: true,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF047857),
                            ),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF047857),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 1000,
                                child: Text('₹1,000 (Standard Match)'),
                              ),
                              DropdownMenuItem(
                                value: 1500,
                                child: Text('₹1,500 (Classic Kerala)'),
                              ),
                              DropdownMenuItem(
                                value: 2500,
                                child: Text('₹2,500 (Tycoon Mode)'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _startingCash = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================== SECTION TITLE ====================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PLAYERS (${_players.length}/4)',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Min 2 • Max 4 Players',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ==================== PLAYERS LIST ====================
              Expanded(
                child: ListView.separated(
                  itemCount: _players.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    final isHuman = player.type == PlayerType.human;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Pawn Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: player.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: player.color.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Icon(
                                player.tokenIcon,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Name and Badges
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        player.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isHuman
                                            ? const Color(0xFFE0F2FE)
                                            : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isHuman
                                            ? 'HUMAN'
                                            : 'BOT (${player.aiPersonality?.name.toUpperCase() ?? "CAUTIOUS"})',
                                        style: GoogleFonts.outfit(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: isHuman
                                              ? const Color(0xFF0369A1)
                                              : const Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.token_rounded,
                                      size: 13,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      player.tokenName,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Action Buttons
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF475569),
                              size: 20,
                            ),
                            tooltip: 'Edit Player',
                            onPressed: () => _editPlayer(index),
                          ),
                          if (_players.length > 2)
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 20,
                              ),
                              tooltip: 'Remove Player',
                              onPressed: () => _removePlayer(index),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ==================== ADD PLAYER BUTTON ====================
              if (_players.length < 4)
                OutlinedButton.icon(
                  onPressed: _addPlayer,
                  icon: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 18,
                    color: Color(0xFF047857),
                  ),
                  label: Text(
                    'ADD PLAYER (${_players.length}/4)',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF047857),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF047857), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),

              const SizedBox(height: 14),

              // ==================== START GAME BUTTON ====================
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: Text(
                    'START GAME',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

