enum PropertyGroup {
  malabar, // Brown
  thrissur, // Light Blue
  kochi, // Pink
  backwaters, // Orange
  highlands, // Red
  southKerala, // Yellow
  premium, // Green
  luxury, // Dark Blue
  transport, // e.g. KSRTC, Kochi Metro, Ferry, Airport
  utility // e.g. KSEB, Water Authority
}

class Property {
  final String id;
  final String name;
  final PropertyGroup group;
  final int price;
  final List<int> rent; // index 0 = base, 1 = 1 house, 2 = 2 houses, 3 = 3 houses, 4 = 4 houses, 5 = resort
  final int upgradeCost;
  final int mortgageValue;
  
  final String? ownerId;
  final int currentLevel; // 0 = empty, 1-4 = houses, 5 = resort
  final bool isMortgaged;

  const Property({
    required this.id,
    required this.name,
    required this.group,
    required this.price,
    required this.rent,
    required this.upgradeCost,
    required this.mortgageValue,
    this.ownerId,
    this.currentLevel = 0,
    this.isMortgaged = false,
  });

  bool get isTransport => group == PropertyGroup.transport;
  bool get isUtility => group == PropertyGroup.utility;
  bool get isBuildable => !isTransport && !isUtility;

  // Check if owner owns all properties in this group
  bool isMonopoly(Map<String, Property> allProperties) {
    if (ownerId == null) return false;
    final groupProps = allProperties.values.where((p) => p.group == group);
    return groupProps.every((p) => p.ownerId == ownerId);
  }

  int getRent(Map<String, Property> allProperties, int diceTotal) {
    if (isMortgaged) return 0;
    
    if (isUtility) {
      final ownedCount = allProperties.values
          .where((p) => p.group == PropertyGroup.utility && p.ownerId == ownerId && !p.isMortgaged)
          .length;
      return ownedCount >= 2 ? diceTotal * 10 : diceTotal * 4;
    }

    if (isTransport) {
      final ownedCount = allProperties.values
          .where((p) => p.group == PropertyGroup.transport && p.ownerId == ownerId && !p.isMortgaged)
          .length;
      if (ownedCount >= 1 && ownedCount <= rent.length) {
        return rent[ownedCount - 1];
      }
      return rent.isNotEmpty ? rent[0] : 15;
    }

    // Street property
    if (currentLevel > 0 && currentLevel < rent.length) {
      return rent[currentLevel];
    }

    // Base rent doubled if full group owned and unimproved
    if (isMonopoly(allProperties)) {
      return rent[0] * 2;
    }

    return rent[0];
  }

  bool canUpgrade(Map<String, Property> allProperties, int ownerCash) {
    if (!isBuildable || isMortgaged || ownerId == null) return false;
    if (currentLevel >= 5) return false;
    if (ownerCash < upgradeCost) return false;
    if (!isMonopoly(allProperties)) return false;
    
    // Check building evenly: this property cannot be upgraded if any group property has fewer buildings
    final groupProps = allProperties.values.where((p) => p.group == group);
    for (final p in groupProps) {
      if (p.isMortgaged) return false;
      if (p.currentLevel < currentLevel) return false;
    }
    return true;
  }

  bool canMortgage() => !isMortgaged && currentLevel == 0;
  bool canUnmortgage(int ownerCash) => isMortgaged && ownerCash >= unmortgageCost;
  int get unmortgageCost => (mortgageValue * 1.1).round();

  /// Official Monopoly Rule: A property cannot be traded while there are buildings
  /// on ANY property in its color group.
  bool hasBuildingsInGroup(Map<String, Property> allProperties) {
    if (!isBuildable) return false;
    final groupProps = allProperties.values.where((p) => p.group == group);
    return groupProps.any((p) => p.currentLevel > 0);
  }

  /// Mortgaged properties CAN be traded. Only properties whose color group
  /// contains houses/hotels cannot be traded.
  bool isTradeable(Map<String, Property> allProperties) {
    return !hasBuildingsInGroup(allProperties);
  }

  String getTradeBlockReason(Map<String, Property> allProperties) {
    if (hasBuildingsInGroup(allProperties)) {
      return 'Buildings exist in this color group';
    }
    return '';
  }

  Property copyWith({
    String? id,
    String? name,
    PropertyGroup? group,
    int? price,
    List<int>? rent,
    int? upgradeCost,
    int? mortgageValue,
    String? ownerId,
    bool clearOwner = false,
    int? currentLevel,
    bool? isMortgaged,
  }) {
    return Property(
      id: id ?? this.id,
      name: name ?? this.name,
      group: group ?? this.group,
      price: price ?? this.price,
      rent: rent ?? this.rent,
      upgradeCost: upgradeCost ?? this.upgradeCost,
      mortgageValue: mortgageValue ?? this.mortgageValue,
      ownerId: clearOwner ? null : (ownerId ?? this.ownerId),
      currentLevel: currentLevel ?? this.currentLevel,
      isMortgaged: isMortgaged ?? this.isMortgaged,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'group': group.name,
      'price': price,
      'rent': rent,
      'upgradeCost': upgradeCost,
      'mortgageValue': mortgageValue,
      'ownerId': ownerId,
      'currentLevel': currentLevel,
      'isMortgaged': isMortgaged,
    };
  }

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'],
      name: map['name'],
      group: PropertyGroup.values.firstWhere((e) => e.name == map['group']),
      price: map['price'],
      rent: List<int>.from(map['rent']),
      upgradeCost: map['upgradeCost'],
      mortgageValue: map['mortgageValue'],
      ownerId: map['ownerId'],
      currentLevel: map['currentLevel'] ?? 0,
      isMortgaged: map['isMortgaged'] ?? false,
    );
  }
}
