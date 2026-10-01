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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'amount': amount,
      'destinationIndex': destinationIndex,
      'houseFee': houseFee,
      'resortFee': resortFee,
    };
  }

  factory EventCard.fromMap(Map<String, dynamic> map) {
    return EventCard(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: EventCardType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EventCardType.moneyReward,
      ),
      amount: (map['amount'] as num?)?.toInt(),
      destinationIndex: (map['destinationIndex'] as num?)?.toInt(),
      houseFee: (map['houseFee'] as num?)?.toInt(),
      resortFee: (map['resortFee'] as num?)?.toInt(),
    );
  }
}
