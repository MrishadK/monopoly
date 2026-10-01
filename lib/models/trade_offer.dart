enum TradeStatus {
  pending,
  accepted,
  rejected,
  cancelled,
  failed,
}

class TradeOffer {
  final String id;
  final String senderId;
  final String receiverId;
  final int offeredCash;
  final List<String> offeredPropertyIds;
  final int requestedCash;
  final List<String> requestedPropertyIds;
  final TradeStatus status;

  const TradeOffer({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.offeredCash = 0,
    this.offeredPropertyIds = const [],
    this.requestedCash = 0,
    this.requestedPropertyIds = const [],
    this.status = TradeStatus.pending,
  });

  bool get isPending => status == TradeStatus.pending;
  bool get isAccepted => status == TradeStatus.accepted;
  bool get isRejected => status == TradeStatus.rejected;
  bool get isCancelled => status == TradeStatus.cancelled;
  bool get isFailed => status == TradeStatus.failed;

  TradeOffer copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    int? offeredCash,
    List<String>? offeredPropertyIds,
    int? requestedCash,
    List<String>? requestedPropertyIds,
    TradeStatus? status,
  }) {
    return TradeOffer(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      offeredCash: offeredCash ?? this.offeredCash,
      offeredPropertyIds: offeredPropertyIds ?? this.offeredPropertyIds,
      requestedCash: requestedCash ?? this.requestedCash,
      requestedPropertyIds: requestedPropertyIds ?? this.requestedPropertyIds,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'offeredCash': offeredCash,
      'offeredPropertyIds': offeredPropertyIds,
      'requestedCash': requestedCash,
      'requestedPropertyIds': requestedPropertyIds,
      'status': status.name,
    };
  }

  factory TradeOffer.fromMap(Map<String, dynamic> map) {
    TradeStatus parsedStatus = TradeStatus.pending;
    if (map['status'] != null) {
      parsedStatus = TradeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TradeStatus.pending,
      );
    }
    return TradeOffer(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      offeredCash: (map['offeredCash'] as num?)?.toInt() ?? 0,
      offeredPropertyIds: List<String>.from(map['offeredPropertyIds'] ?? const []),
      requestedCash: (map['requestedCash'] as num?)?.toInt() ?? 0,
      requestedPropertyIds: List<String>.from(map['requestedPropertyIds'] ?? const []),
      status: parsedStatus,
    );
  }
}
