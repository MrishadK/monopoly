import 'package:flutter/material.dart';
import 'property.dart';

enum PlayerType { human, ai }
enum AiPersonality { conservative, aggressive, trader, investor, riskTaker }
enum PlayerToken { coconut, houseboat, elephant, chayaGlass, ksrtcBus, fishingBoat, coconutTree, nilavilakku }

class Player {
  final String id;
  final String name;
  final PlayerType type;
  final PlayerToken token;
  final Color color;
  final AiPersonality? aiPersonality;
  
  final int cash;
  final int position;
  final bool isBankrupt;
  final bool isInJail;
  final int turnsInJail;
  final int getOutOfJailCards;
  final List<String> ownedPropertyIds;
  
  const Player({
    required this.id,
    required this.name,
    required this.type,
    required this.token,
    required this.color,
    this.aiPersonality,
    this.cash = 150000,
    this.position = 0,
    this.isBankrupt = false,
    this.isInJail = false,
    this.turnsInJail = 0,
    this.getOutOfJailCards = 0,
    this.ownedPropertyIds = const [],
  });

  IconData get tokenIcon {
    switch (token) {
      case PlayerToken.coconut: return Icons.spa_rounded;
      case PlayerToken.houseboat: return Icons.sailing_rounded;
      case PlayerToken.elephant: return Icons.pets_rounded;
      case PlayerToken.chayaGlass: return Icons.local_cafe_rounded;
      case PlayerToken.ksrtcBus: return Icons.directions_bus_rounded;
      case PlayerToken.fishingBoat: return Icons.kayaking_rounded;
      case PlayerToken.coconutTree: return Icons.forest_rounded;
      case PlayerToken.nilavilakku: return Icons.local_fire_department_rounded;
    }
  }

  String get tokenEmoji {
    switch (token) {
      case PlayerToken.coconut: return '🥥';
      case PlayerToken.houseboat: return '⛵';
      case PlayerToken.elephant: return '🐘';
      case PlayerToken.chayaGlass: return '☕';
      case PlayerToken.ksrtcBus: return '🚌';
      case PlayerToken.fishingBoat: return '🛶';
      case PlayerToken.coconutTree: return '🌴';
      case PlayerToken.nilavilakku: return '🪔';
    }
  }

  String get tokenName {
    switch (token) {
      case PlayerToken.coconut: return 'Coconut';
      case PlayerToken.houseboat: return 'Kettuvallam (Houseboat)';
      case PlayerToken.elephant: return 'Kerala Aana (Elephant)';
      case PlayerToken.chayaGlass: return 'Meter Chaya Glass';
      case PlayerToken.ksrtcBus: return 'KSRTC Minnal';
      case PlayerToken.fishingBoat: return 'Vallam (Canoe)';
      case PlayerToken.coconutTree: return 'Thengu (Palm)';
      case PlayerToken.nilavilakku: return 'Nilavilakku (Lamp)';
    }
  }

  int calculateNetWorth(Map<String, Property> properties) {
    int total = cash;
    for (final propId in ownedPropertyIds) {
      final prop = properties[propId];
      if (prop != null) {
        if (prop.isMortgaged) {
          total += prop.mortgageValue;
        } else {
          total += prop.price;
          total += prop.currentLevel * prop.upgradeCost;
        }
      }
    }
    return total;
  }

  Player copyWith({
    String? id,
    String? name,
    PlayerType? type,
    PlayerToken? token,
    Color? color,
    AiPersonality? aiPersonality,
    int? cash,
    int? position,
    bool? isBankrupt,
    bool? isInJail,
    int? turnsInJail,
    int? getOutOfJailCards,
    List<String>? ownedPropertyIds,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      token: token ?? this.token,
      color: color ?? this.color,
      aiPersonality: aiPersonality ?? this.aiPersonality,
      cash: cash ?? this.cash,
      position: position ?? this.position,
      isBankrupt: isBankrupt ?? this.isBankrupt,
      isInJail: isInJail ?? this.isInJail,
      turnsInJail: turnsInJail ?? this.turnsInJail,
      getOutOfJailCards: getOutOfJailCards ?? this.getOutOfJailCards,
      ownedPropertyIds: ownedPropertyIds ?? List.from(this.ownedPropertyIds),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'token': token.name,
      'color': color.toARGB32(),
      'aiPersonality': aiPersonality?.name,
      'cash': cash,
      'position': position,
      'isBankrupt': isBankrupt,
      'isInJail': isInJail,
      'turnsInJail': turnsInJail,
      'getOutOfJailCards': getOutOfJailCards,
      'ownedPropertyIds': ownedPropertyIds,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] ?? 'p1',
      name: map['name'] ?? 'Player',
      type: PlayerType.values.firstWhere((e) => e.name == map['type'], orElse: () => PlayerType.human),
      token: PlayerToken.values.firstWhere((e) => e.name == map['token'], orElse: () => PlayerToken.houseboat),
      color: Color(map['color'] ?? 0xFF00695C),
      aiPersonality: map['aiPersonality'] != null 
          ? AiPersonality.values.firstWhere((e) => e.name == map['aiPersonality'], orElse: () => AiPersonality.conservative)
          : null,
      cash: map['cash'] ?? 150000,
      position: map['position'] ?? 0,
      isBankrupt: map['isBankrupt'] ?? false,
      isInJail: map['isInJail'] ?? false,
      turnsInJail: map['turnsInJail'] ?? 0,
      getOutOfJailCards: map['getOutOfJailCards'] ?? 0,
      ownedPropertyIds: List<String>.from(map['ownedPropertyIds'] ?? const []),
    );
  }
}
