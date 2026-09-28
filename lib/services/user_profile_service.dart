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

  const UserProfile({
    required this.id,
    required this.name,
    required this.token,
    required this.color,
    this.isConfigured = false,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    PlayerToken? token,
    Color? color,
    bool? isConfigured,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      token: token ?? this.token,
      color: color ?? this.color,
      isConfigured: isConfigured ?? this.isConfigured,
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

  static const List<String> keralaNames = [
    'Aadu Thoma',
    'Ranga Annan',
    'Dasamoolam Damu',
    'Manavalan',
    'Shaji Pappan',
    'Bilal John',
    'Neelakandan',
    'Ambaan',
    'John Honai',
    'Ramanan',
    'CID Moosa',
    'Sethurama Iyer',
    'Minnal Murali',
    'Georgekutty',
    'Gafoorkka',
    'Arakkal Abu',
    'Dude',
    'Dasan',
    'Vijayan',
    'Appukuttan',
    'Thomaskutty',
    'Gangadharan',
    'Peethambaran',
    'Jagannathan',
    'Induchoodan',
    'Puli Murugan',
    'Michael Anjootti',
    'Dr Sunny',
    'Faizi',
    'Vincent Gomez',
    'Keerikkadan Jose',
    'Kadavul Antony',
    'Ananthan Nambiar',
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

      state = UserProfile(
        id: savedId,
        name: savedName,
        token: savedToken,
        color: Color(colorValue),
        isConfigured: true,
      );
    } catch (_) {
      // Fallback to in-memory state
    }
  }

  Future<void> saveProfile({
    required String name,
    required PlayerToken token,
    required Color color,
  }) async {
    final cleanName = name.trim().isNotEmpty ? name.trim() : 'Player';
    state = state.copyWith(
      name: cleanName,
      token: token,
      color: color,
      isConfigured: true,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyId, state.id);
      await prefs.setString(_keyName, cleanName);
      await prefs.setInt(_keyToken, token.index);
      await prefs.setInt(_keyColor, color.toARGB32());
      await prefs.setBool(_keyConfigured, true);
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
    );
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(
  () => UserProfileNotifier(),
);
