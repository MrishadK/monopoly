enum SpaceType {
  start,
  property,
  railroad, // transport
  utility,
  chance,   // event
  communityChest, // bonus event
  tax,
  jail, // or visiting
  goToJail,
  freeParking // bonus
}

class BoardSpace {
  final int index;
  final String name;
  final SpaceType type;

  // Only for property/railroad/utility
  final String? propertyId;

  // Only for taxes or fixed fees
  final int? feeAmount;

  const BoardSpace({
    required this.index,
    required this.name,
    required this.type,
    this.propertyId,
    this.feeAmount,
  });
}
