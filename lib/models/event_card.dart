enum EventCardType {
  moneyReward,
  moneyPenalty,
  moveToSpace,
  moveBackwards,
  payPerHouse,
  getOutOfJail,
  goToJail
}

class EventCard {
  final String id;
  final String title;
  final String description;
  final EventCardType type;
  
  final int? amount;
  final int? destinationIndex;
  final int? houseFee;
  final int? resortFee;

  const EventCard({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.amount,
    this.destinationIndex,
    this.houseFee,
    this.resortFee,
  });
}
