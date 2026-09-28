import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../services/user_profile_service.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;

  const UserProfileScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  late TextEditingController _nameController;
  late PlayerToken _selectedToken;
  late Color _selectedColor;

  final Map<PlayerToken, String> _tokenLore = const {
    PlayerToken.houseboat: 'Kettuvallam • Sovereign of Alleppey Backwaters',
    PlayerToken.coconut: 'Thenga • The foundational fruit of God\'s Own Land',
    PlayerToken.elephant: 'Kerala Aana • Royal majesty of Thrissur Pooram',
    PlayerToken.chayaGlass: 'Meter Chaya • Steaming frothy Malabar tea',
    PlayerToken.ksrtcBus: 'KSRTC Minnal • Unstoppable king of the ghat roads',
    PlayerToken.fishingBoat: 'Chundan Vallam • Swift champion of the Nehru Trophy',
    PlayerToken.coconutTree: 'Thengu Palm • Symbol of endless bounty & abundance',
    PlayerToken.nilavilakku: 'Nilavilakku • Sacred brass flame of wealth & blessings',
  };

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

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _selectedToken = profile.token;
    _selectedColor = profile.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _randomizeName() {
    HapticFeedback.lightImpact();
    final names = UserProfileNotifier.keralaNames;
    final current = _nameController.text.trim();
    String nextName;
    do {
      nextName = (names.toList()..shuffle()).first;
    } while (nextName == current && names.length > 1);

    setState(() {
      _nameController.text = nextName;
    });
  }

  Future<void> _saveAndContinue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your player name'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    await ref.read(userProfileProvider.notifier).saveProfile(
      name: name,
      token: _selectedToken,
      color: _selectedColor,
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tempPlayer = Player(
      id: '',
      name: _nameController.text.trim().isEmpty ? 'Player' : _nameController.text.trim(),
      type: PlayerType.human,
      token: _selectedToken,
      color: _selectedColor,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        centerTitle: true,
        title: Text(
          widget.isInitialSetup ? 'WELCOME TO KUTHAKA' : 'PLAYER PROFILE SETUP',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ==================== AVATAR SHOWCASE CARD ====================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Live Avatar Icon
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedColor,
                            boxShadow: [
                              BoxShadow(
                                color: _selectedColor.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 3.5),
                          ),
                          child: Center(
                            child: Icon(
                              tempPlayer.tokenIcon,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Live Name
                        Text(
                          tempPlayer.name,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Token Lore Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.workspace_premium_rounded,
                                size: 14,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _tokenLore[_selectedToken] ?? tempPlayer.tokenName,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF92400E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================== DISPLAY NAME CARD ====================
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PLAYER DISPLAY NAME',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            InkWell(
                              onTap: _randomizeName,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.shuffle_rounded,
                                      size: 15,
                                      color: Color(0xFF047857),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Randomize',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF047857),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          maxLength: 16,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'e.g. Arun, Priya, Dulquer',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            prefixIcon: const Icon(
                              Icons.badge_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF047857), width: 2),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================== TOKEN PICKER CARD ====================
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'CHOOSE KERALA GAME PIECE',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '8 Unique Tokens',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: PlayerToken.values.length,
                          itemBuilder: (context, index) {
                            final token = PlayerToken.values[index];
                            final isSelected = _selectedToken == token;
                            final dummy = Player(
                              id: '',
                              name: '',
                              type: PlayerType.human,
                              token: token,
                              color: Colors.white,
                            );
                            final shortName = _tokenShortNames[token] ?? 'Token';

                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedToken = token);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _selectedColor.withValues(alpha: 0.12)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? _selectedColor : const Color(0xFFE2E8F0),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: _selectedColor.withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      dummy.tokenIcon,
                                      size: 26,
                                      color: isSelected ? _selectedColor : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      shortName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? _selectedColor : const Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================== COLOR PICKER CARD ====================
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECT SIGNATURE COLOR',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: UserProfileNotifier.palette.map((color) {
                            final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedColor = color);
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 44 : 38,
                                height: isSelected ? 44 : 38,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                                    width: isSelected ? 3 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: isSelected ? 0.45 : 0.2),
                                      blurRadius: isSelected ? 10 : 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================== SAVE BUTTON ====================
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _saveAndContinue,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: Text(
                        'SAVE & PROCEED',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

