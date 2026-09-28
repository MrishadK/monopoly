class BankruptcyRecord {
  final String bankruptPlayerName;
  final String bankruptPlayerId;
  final int playerColorValue;
  final int playerTokenIndex;
  final String? creditorName;
  final int propertiesForfeited;
  final int timestamp;

  const BankruptcyRecord({
    required this.bankruptPlayerName,
    required this.bankruptPlayerId,
    required this.playerColorValue,
    required this.playerTokenIndex,
    this.creditorName,
    required this.propertiesForfeited,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'bankruptPlayerName': bankruptPlayerName,
    'bankruptPlayerId': bankruptPlayerId,
    'playerColorValue': playerColorValue,
    'playerTokenIndex': playerTokenIndex,
    'creditorName': creditorName,
    'propertiesForfeited': propertiesForfeited,
    'timestamp': timestamp,
  };

  factory BankruptcyRecord.fromMap(Map<String, dynamic> map) => BankruptcyRecord(
    bankruptPlayerName: map['bankruptPlayerName']?.toString() ?? 'Player',
    bankruptPlayerId: map['bankruptPlayerId']?.toString() ?? '',
    playerColorValue: map['playerColorValue'] is int ? map['playerColorValue'] as int : 0xFFE91E63,
    playerTokenIndex: map['playerTokenIndex'] is int ? map['playerTokenIndex'] as int : 0,
    creditorName: map['creditorName']?.toString(),
    propertiesForfeited: map['propertiesForfeited'] is int ? map['propertiesForfeited'] as int : 0,
    timestamp: map['timestamp'] is int ? map['timestamp'] as int : DateTime.now().millisecondsSinceEpoch,
  );
}
