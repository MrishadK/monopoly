class TradeOffer {
  final String id;
  final String senderId;
  final String receiverId;
  final int offeredCash;
  final List<String> offeredPropertyIds;
  final int requestedCash;
  final List<String> requestedPropertyIds;

  const TradeOffer({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.offeredCash = 0,
    this.offeredPropertyIds = const [],
    this.requestedCash = 0,
    this.requestedPropertyIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'offeredCash': offeredCash,
      'offeredPropertyIds': offeredPropertyIds,
      'requestedCash': requestedCash,
      'requestedPropertyIds': requestedPropertyIds,
    };
  }

  factory TradeOffer.fromMap(Map<String, dynamic> map) {
    return TradeOffer(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      offeredCash: map['offeredCash'] ?? 0,
      offeredPropertyIds: List<String>.from(map['offeredPropertyIds'] ?? const []),
      requestedCash: map['requestedCash'] ?? 0,
      requestedPropertyIds: List<String>.from(map['requestedPropertyIds'] ?? const []),
    );
  }
}
