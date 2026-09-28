import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

class UserProfile {
  final String id;
  final String name;
  final PlayerToken token;
  final Color color;
  final bool isConfigured;
  final bool isCustom;

  const UserProfile({
    required this.id,
    required this.name,
    required this.token,
    required this.color,
    this.isConfigured = false,
    this.isCustom = false,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    PlayerToken? token,
    Color? color,
    bool? isConfigured,
    bool? isCustom,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      token: token ?? this.token,
      color: color ?? this.color,
      isConfigured: isConfigured ?? this.isConfigured,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Player toPlayer({int cash = 1000}) {
    return Player(
      id: id,
      name: name,
      type: PlayerType.human,
      token: token,
      color: color,
      cash: cash,
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  static const String _keyName = 'kuthaka_user_name';
  static const String _keyToken = 'kuthaka_user_token';
  static const String _keyColor = 'kuthaka_user_color';
  static const String _keyId = 'kuthaka_user_id';
  static const String _keyConfigured = 'kuthaka_user_configured';
  static const String _keyIsCustom = 'kuthaka_user_is_custom';

  static const List<String> keralaNames = [
    'Dasan',
    'Vijayan',
    'Aadu Thoma',
    'Mangalassery Neelakandan',
    'Induchoodan',
    'Poovalli Induchoodan',
    'Narasimham',
    'Chacko',
    'Georgekutty',
    'Drishyam George',
    'Sagar Alias Jacky',
    'Devanarayanan',
    'Maanikyan',
    'Kunjumon',
    'Kuttan',
    'Unnikuttan',
    'Muthu',
    'Achuthan',
    'Kannan',
    'Balan',
    'Gopalakrishnan',
    'Ramji Rao',
    'Mannar Mathai',
    'Gopu',
    'Akkare Ninnoru Maran',
    'C.I. D. Unnikrishnan',
    'C.I.D. Moosa',
    'Meesha Madhavan',
    'Madhavan',
    'Ramanan',
    'Sethu',
    'Dasappan',
    'Pavanayi',
    'Vijayaraghavan',
    'Captain Raju',
    'Thomman',
    'Kunjikkoonan',
    'Chinthamani',
    'Arakkal Abu',
    'Peruchazhi',
    'Jagannathan',
    'Achu',
    'Appukuttan',
    'Ayyappan',
    'Kunjunni',
    'Kuttan Pillai',
    'Balachandran',
    'Pranchiyettan',
    'Kariyachan',
    'Pappu',
    'Kottayam Kunjachan',
    'Malabar Majeed',
    'Velayudhan',
    'Paleri Manikyam',
    'Murali',
    'Murugan',
    'Shaji',
    'Rasool',
    'Kareem',
    'Pottan',
    'Pachu',
    'Aadu',
    'Kattalan Jose',
    'Kunjikka',
    'Sudhi',
    'Shankaran',
    'Krishnan',
    'Soman',
    'Balakrishnan',
  ];

  static const List<Color> palette = [
    Color(0xFFFFD54F), // Kasavu Gold
    Color(0xFFE91E63), // Malabar Crimson
    Color(0xFF00E676), // Kerala Palm Green
    Color(0xFF29B6F6), // Backwater Sky Blue
    Color(0xFFFF7043), // Sunset Terracotta
    Color(0xFFAB47BC), // Royal Orchid
  ];

  @override
  UserProfile build() {
    // Generate initial default
    final initialId = 'usr_${Random().nextInt(900000) + 100000}';
    final initial = UserProfile(
      id: initialId,
      name: keralaNames[Random().nextInt(keralaNames.length)],
      token: PlayerToken.houseboat,
      color: palette[0],
      isConfigured: false,
    );

    // Asynchronously load stored preferences
    _loadFromPrefs();

    return initial;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasConfigured = prefs.getBool(_keyConfigured) ?? false;
      if (!hasConfigured) return;

      final savedId = prefs.getString(_keyId) ?? state.id;
      final savedName = prefs.getString(_keyName) ?? state.name;
      final tokenIndex = prefs.getInt(_keyToken) ?? PlayerToken.houseboat.index;
      final colorValue = prefs.getInt(_keyColor) ?? palette[0].toARGB32();

      final savedToken = (tokenIndex >= 0 && tokenIndex < PlayerToken.values.length)
          ? PlayerToken.values[tokenIndex]
          : PlayerToken.houseboat;
      final savedIsCustom = prefs.getBool(_keyIsCustom) ?? !keralaNames.contains(savedName);

      state = UserProfile(
        id: savedId,
        name: savedName,
        token: savedToken,
        color: Color(colorValue),
        isConfigured: true,
        isCustom: savedIsCustom,
      );
    } catch (_) {
      // Fallback to in-memory state
    }
  }

  Future<void> saveProfile({
    required String name,
    required PlayerToken token,
    required Color color,
    bool? isCustom,
  }) async {
    final cleanName = name.trim().isNotEmpty ? name.trim() : 'Player';
    final customFlag = isCustom ?? (!keralaNames.contains(cleanName));
    state = state.copyWith(
      name: cleanName,
      token: token,
      color: color,
      isConfigured: true,
      isCustom: customFlag,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyId, state.id);
      await prefs.setString(_keyName, cleanName);
      await prefs.setInt(_keyToken, token.index);
      await prefs.setInt(_keyColor, color.toARGB32());
      await prefs.setBool(_keyConfigured, true);
      await prefs.setBool(_keyIsCustom, customFlag);
    } catch (_) {
      // Ignore disk error, state is updated
    }
  }

  void randomize() {
    final randomName = keralaNames[Random().nextInt(keralaNames.length)];
    final randomToken = PlayerToken.values[Random().nextInt(PlayerToken.values.length)];
    final randomColor = palette[Random().nextInt(palette.length)];

    saveProfile(
      name: randomName,
      token: randomToken,
      color: randomColor,
      isCustom: false,
    );
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(
  () => UserProfileNotifier(),
);
