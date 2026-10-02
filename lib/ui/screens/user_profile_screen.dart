import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player.dart';
import '../../services/user_profile_service.dart';
import '../../ui/theme/app_theme.dart';

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

  late FocusNode _nameFocusNode;
  bool _isCustomMode = false;
  String _selectedPreset = '';

  static const List<String> _quickCustomTags = [
    '👑 Boss',
    '⚡ Champion',
    '💰 Tycoon',
    '🌟 Star',
    '🔥 Striker',
    '🎩 Master',
  ];

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
    _nameFocusNode = FocusNode();
    _selectedToken = profile.token;
    _selectedColor = profile.color;
    _isCustomMode = profile.isCustom || !UserProfileNotifier.keralaNames.contains(profile.name);
    _selectedPreset = _isCustomMode ? '' : profile.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _switchToCustomMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isCustomMode = true;
    });
    _nameFocusNode.requestFocus();
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
      _selectedPreset = nextName;
      _isCustomMode = false;
      _nameController.text = nextName;
    });
  }

  void _applyQuickCustomTag(String tag) {
    HapticFeedback.selectionClick();
    final cleanTag = tag.replaceAll(RegExp(r'^[^\w]+'), '').trim();
    setState(() {
      _isCustomMode = true;
      final current = _nameController.text.trim();
      if (current.isEmpty || UserProfileNotifier.keralaNames.contains(current)) {
        _nameController.text = cleanTag;
      } else if (!current.contains(cleanTag)) {
        _nameController.text = '$current $cleanTag';
      }
    });
    _nameFocusNode.requestFocus();
  }

  Future<void> _saveAndContinue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a custom name or choose a preset character'),
          backgroundColor: KuthakaColors.crimson,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final isCustom = _isCustomMode || !UserProfileNotifier.keralaNames.contains(name);
    await ref.read(userProfileProvider.notifier).saveProfile(
      name: name,
      token: _selectedToken,
      color: _selectedColor,
      isCustom: isCustom,
    );

    if (mounted) {
      final isDark = context.isDark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCustom ? 'Custom profile name "$name" saved!' : 'Playing as "$name"',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final cleanName = _nameController.text.trim();
    final isCurrentCustom = _isCustomMode || !UserProfileNotifier.keralaNames.contains(cleanName);
    final tempPlayer = Player(
      id: '',
      name: cleanName.isEmpty ? 'Player' : cleanName,
      type: PlayerType.human,
      token: _selectedToken,
      color: _selectedColor,
    );

    final accentColor = isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        centerTitle: true,
        title: Text(
          widget.isInitialSetup ? 'WELCOME TO KUTHAKA' : 'PLAYER PROFILE SETUP',
          style: GoogleFonts.outfit(
            color: context.textPrimary,
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
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.borderColor),
                      boxShadow: context.cardShadow,
                    ),
                    child: Column(
                      children: [
                        // Live Avatar Icon with Glow
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedColor,
                            boxShadow: [
                              BoxShadow(
                                color: _selectedColor.withValues(alpha: isDark ? 0.5 : 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(color: context.cardColor, width: 3.5),
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
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: context.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),

                        // Custom Name vs Preset Badge
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCurrentCustom ? context.emeraldBg : context.goldBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrentCustom
                                  ? KuthakaColors.emerald.withValues(alpha: isDark ? 0.6 : 1.0)
                                  : KuthakaColors.gold.withValues(alpha: isDark ? 0.6 : 1.0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCurrentCustom ? Icons.stars_rounded : Icons.theater_comedy_rounded,
                                size: 13,
                                color: isCurrentCustom ? accentColor : KuthakaColors.goldDark,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isCurrentCustom ? 'CUSTOM PLAYER NAME' : 'KERALA CHARACTER PRESET',
                                style: GoogleFonts.outfit(
                                  color: isCurrentCustom ? accentColor : KuthakaColors.goldDark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Token Lore Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.cardAltColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.workspace_premium_rounded,
                                size: 14,
                                color: context.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _tokenLore[_selectedToken] ?? tempPlayer.tokenName,
                                  style: GoogleFonts.outfit(
                                    color: context.textSecondary,
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

                  // ==================== NAME SELECTION CARD ====================
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.borderColor),
                      boxShadow: context.subtleShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'NAME OPTIONS',
                              style: GoogleFonts.outfit(
                                color: context.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Segmented Mode Selector
                        Container(
                          decoration: BoxDecoration(
                            color: context.cardAltColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.borderColor),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              // Custom Name Segment
                              Expanded(
                                child: InkWell(
                                  onTap: () => _switchToCustomMode(),
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _isCustomMode ? context.cardColor : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _isCustomMode ? context.subtleShadow : null,
                                      border: _isCustomMode
                                          ? Border.all(color: accentColor, width: 1.5)
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.edit_rounded,
                                          size: 15,
                                          color: _isCustomMode ? accentColor : context.textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Custom Name',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: _isCustomMode ? accentColor : context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Kerala Random Shuffle Segment
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _isCustomMode = false;
                                      if (_selectedPreset.isEmpty || !UserProfileNotifier.keralaNames.contains(_nameController.text.trim())) {
                                        _selectedPreset = UserProfileNotifier.keralaNames[Random().nextInt(UserProfileNotifier.keralaNames.length)];
                                        _nameController.text = _selectedPreset;
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: !_isCustomMode ? context.cardColor : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: !_isCustomMode ? context.subtleShadow : null,
                                      border: !_isCustomMode
                                          ? Border.all(color: accentColor, width: 1.5)
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.casino_rounded,
                                          size: 15,
                                          color: !_isCustomMode ? accentColor : context.textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Kerala Shuffle 🎲',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: !_isCustomMode ? accentColor : context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Content according to selected mode
                        if (_isCustomMode) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TYPE YOUR CUSTOM NAME',
                                style: GoogleFonts.outfit(
                                  color: context.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (_nameController.text.isNotEmpty)
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _nameController.clear();
                                    setState(() {});
                                    _nameFocusNode.requestFocus();
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.close_rounded, size: 14, color: context.textMuted),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Clear',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: context.textMuted,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Custom Name Text Field
                          TextField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            maxLength: 18,
                            textCapitalization: TextCapitalization.words,
                            style: GoogleFonts.outfit(
                              color: context.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'e.g. Arun, Priya, Dulquer, The Boss',
                              hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
                              prefixIcon: Icon(Icons.person_outline_rounded, color: accentColor, size: 20),
                              suffixIcon: _nameController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.cancel_rounded, color: context.textMuted, size: 18),
                                      onPressed: () {
                                        _nameController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: context.cardAltColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: context.borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: context.borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: accentColor, width: 2),
                              ),
                            ),
                            onChanged: (_) {
                              setState(() {
                                _isCustomMode = true;
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          // Quick Custom Name Ideas
                          Text(
                            'QUICK TITLE IDEAS',
                            style: GoogleFonts.outfit(
                              color: context.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _quickCustomTags.map((tag) {
                              return ActionChip(
                                label: Text(
                                  tag,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: context.textPrimary,
                                  ),
                                ),
                                backgroundColor: context.cardAltColor,
                                side: BorderSide(color: context.borderColor),
                                onPressed: () => _applyQuickCustomTag(tag),
                              );
                            }).toList(),
                          ),
                        ] else ...[
                          // Kerala Name Presets
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SELECTED AVATAR',
                                style: GoogleFonts.outfit(
                                  color: context.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              InkWell(
                                onTap: _randomizeName,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: context.emeraldBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.casino_rounded, size: 13, color: accentColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'SHUFFLE',
                                        style: GoogleFonts.outfit(
                                          color: accentColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Current Preset Name Display
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: context.cardAltColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: accentColor, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.theater_comedy_rounded, size: 20, color: accentColor),
                                const SizedBox(width: 12),
                                Text(
                                  _nameController.text,
                                  style: GoogleFonts.outfit(
                                    color: context.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================== TOKEN SELECTION CARD ====================
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.borderColor),
                      boxShadow: context.subtleShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'GAME TOKEN',
                              style: GoogleFonts.outfit(
                                color: context.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: context.emeraldBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _tokenShortNames[_selectedToken] ?? 'Token',
                                style: GoogleFonts.outfit(
                                  color: accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
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
                            childAspectRatio: 1.0,
                          ),
                          itemCount: PlayerToken.values.length,
                          itemBuilder: (context, i) {
                            final token = PlayerToken.values[i];
                            final isSelected = _selectedToken == token;
                            final dummy = Player(id: '', name: '', type: PlayerType.human, token: token, color: Colors.white);
                            final shortName = _tokenShortNames[token] ?? 'Token';

                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedToken = token);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _selectedColor.withValues(alpha: isDark ? 0.2 : 0.1)
                                      : context.cardAltColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? _selectedColor : context.borderColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: _selectedColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      dummy.tokenIcon,
                                      size: 26,
                                      color: isSelected ? _selectedColor : context.textSecondary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      shortName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? _selectedColor : context.textSecondary,
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

                  // ==================== COLOR SELECTION CARD ====================
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.borderColor),
                      boxShadow: context.subtleShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOKEN COLOR',
                          style: GoogleFonts.outfit(
                            color: context.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: UserProfileNotifier.palette.map((c) {
                            final isSelected = _selectedColor == c;
                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedColor = c);
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 42 : 34,
                                height: isSelected ? 42 : 34,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? context.textPrimary : context.borderColor,
                                    width: isSelected ? 2.5 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: c.withValues(alpha: isDark ? 0.5 : 0.3),
                                      blurRadius: isSelected ? 10 : 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
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
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
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
