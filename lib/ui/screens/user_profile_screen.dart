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
          backgroundColor: Colors.redAccent,
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
      name: _nameController.text,
      type: PlayerType.human,
      token: _selectedToken,
      color: _selectedColor,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF06150E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2419),
        elevation: 0,
        title: Text(
          widget.isInitialSetup ? 'WELCOME TO KUTHAKA' : 'PLAYER PROFILE SETUP',
          style: GoogleFonts.outfit(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ==================== LIVE AVATAR HERO ====================
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _selectedColor.withValues(alpha: 0.35),
                          _selectedColor.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(color: _selectedColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _selectedColor.withValues(alpha: 0.3),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: _selectedColor.withValues(alpha: 0.25),
                      child: Icon(
                        tempPlayer.tokenIcon,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Token Lore Subtitle
                  Text(
                    _tokenLore[_selectedToken] ?? tempPlayer.tokenName,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFFD54F),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ==================== NAME INPUT CARD ====================
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white12),
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
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFFFD54F),
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Icon(Icons.shuffle_rounded, size: 16),
                              label: const Text('RANDOMIZE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: _randomizeName,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          maxLength: 16,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'e.g. Arun, Priya, Dulquer',
                            hintStyle: const TextStyle(color: Colors.white30),
                            prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFFFFD54F)),
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: _selectedColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: _selectedColor, width: 2),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================== TOKEN PICKER ====================
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHOOSE KERALA GAME PIECE',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                          itemCount: PlayerToken.values.length,
                          itemBuilder: (context, index) {
                            final token = PlayerToken.values[index];
                            final isSelected = _selectedToken == token;
                            final dummy = Player(id: '', name: '', type: PlayerType.human, token: token, color: Colors.white);

                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedToken = token);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected ? _selectedColor.withValues(alpha: 0.25) : Colors.black26,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? _selectedColor : Colors.white12,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: _selectedColor.withValues(alpha: 0.3), blurRadius: 10)]
                                      : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    dummy.tokenIcon,
                                    size: isSelected ? 30 : 24,
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================== COLOR PICKER ====================
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECT AVATAR GLOW COLOR',
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
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
                                width: isSelected ? 44 : 36,
                                height: isSelected ? 44 : 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 14)]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded, color: Colors.black, size: 22)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ==================== SAVE BUTTON ====================
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 6,
                      ),
                      onPressed: _saveAndContinue,
                      child: Text(
                        'SAVE & PROCEED ➔',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
