class AuctionState {
  final String propertyId;
  final String initiatorPlayerId;
  final int highestBid;
  final String? highestBidderId;
  final int currentBidderIndex;
  final List<String> activeBidderIds;
  final List<String> bidHistory;
  final bool isCompleted;
  final String? winnerId;
  final int winningBid;

  const AuctionState({
    required this.propertyId,
    required this.initiatorPlayerId,
    this.highestBid = 0,
    this.highestBidderId,
    this.currentBidderIndex = 0,
    required this.activeBidderIds,
    this.bidHistory = const [],
    this.isCompleted = false,
    this.winnerId,
    this.winningBid = 0,
  });

  String get currentBidderId {
    if (activeBidderIds.isEmpty) return '';
    return activeBidderIds[currentBidderIndex % activeBidderIds.length];
  }

  int get minimumNextBid => highestBid == 0 ? 10 : highestBid + 10;

  AuctionState copyWith({
    String? propertyId,
    String? initiatorPlayerId,
    int? highestBid,
    String? highestBidderId,
    bool clearHighestBidder = false,
    int? currentBidderIndex,
    List<String>? activeBidderIds,
    List<String>? bidHistory,
    bool? isCompleted,
    String? winnerId,
    int? winningBid,
  }) {
    return AuctionState(
      propertyId: propertyId ?? this.propertyId,
      initiatorPlayerId: initiatorPlayerId ?? this.initiatorPlayerId,
      highestBid: highestBid ?? this.highestBid,
      highestBidderId: clearHighestBidder ? null : (highestBidderId ?? this.highestBidderId),
      currentBidderIndex: currentBidderIndex ?? this.currentBidderIndex,
      activeBidderIds: activeBidderIds ?? this.activeBidderIds,
      bidHistory: bidHistory ?? this.bidHistory,
      isCompleted: isCompleted ?? this.isCompleted,
      winnerId: winnerId ?? this.winnerId,
      winningBid: winningBid ?? this.winningBid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'initiatorPlayerId': initiatorPlayerId,
      'highestBid': highestBid,
      'highestBidderId': highestBidderId,
      'currentBidderIndex': currentBidderIndex,
      'activeBidderIds': activeBidderIds,
      'bidHistory': bidHistory,
      'isCompleted': isCompleted,
      'winnerId': winnerId,
      'winningBid': winningBid,
    };
  }

  factory AuctionState.fromMap(Map<String, dynamic> map) {
    return AuctionState(
      propertyId: map['propertyId'] as String,
      initiatorPlayerId: map['initiatorPlayerId'] as String,
      highestBid: (map['highestBid'] as num?)?.toInt() ?? 0,
      highestBidderId: map['highestBidderId'] as String?,
      currentBidderIndex: (map['currentBidderIndex'] as num?)?.toInt() ?? 0,
      activeBidderIds: List<String>.from(map['activeBidderIds'] ?? []),
      bidHistory: List<String>.from(map['bidHistory'] ?? []),
      isCompleted: map['isCompleted'] as bool? ?? false,
      winnerId: map['winnerId'] as String?,
      winningBid: (map['winningBid'] as num?)?.toInt() ?? 0,
    );
  }
}
