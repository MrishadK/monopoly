class PublicRoom {
  final String roomId;
  final String hostName;
  final int playerCount;
  final int maxPlayers;
  final int startingCash;
  final DateTime lastSeen;

  const PublicRoom({
    required this.roomId,
    required this.hostName,
    required this.playerCount,
    this.maxPlayers = 4,
    this.startingCash = 1000,
    required this.lastSeen,
  });

  Map<String, dynamic> toMap() => {
    'roomId': roomId,
    'hostName': hostName,
    'playerCount': playerCount,
    'maxPlayers': maxPlayers,
    'startingCash': startingCash,
    'timestamp': lastSeen.millisecondsSinceEpoch,
  };

  factory PublicRoom.fromMap(Map<String, dynamic> map) => PublicRoom(
    roomId: map['roomId']?.toString() ?? '',
    hostName: map['hostName']?.toString() ?? 'Player',
    playerCount: map['playerCount'] is int ? map['playerCount'] as int : 1,
    maxPlayers: map['maxPlayers'] is int ? map['maxPlayers'] as int : 4,
    startingCash: map['startingCash'] is int ? map['startingCash'] as int : 1000,
    lastSeen: map['timestamp'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
        : DateTime.now(),
  );
}
