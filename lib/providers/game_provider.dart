import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player.dart';
import '../models/property.dart';
import '../models/board_space.dart';
import '../models/event_card.dart';
import '../models/trade_offer.dart';
import '../models/bankruptcy_record.dart';
import '../models/auction_state.dart';
import '../models/transaction_notice.dart';
import '../data/game_data.dart';
import '../services/multiplayer_service.dart';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../services/user_profile_service.dart';
import '../ui/overlays/emoji_chat_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum GamePhase { roll, moving, spaceAction, turnEnd, gameOver }

const int kTurnDurationSeconds = 45;

class GameState {
  final List<Player> players;
  final int currentPlayerIndex;
  final GamePhase phase;
  final Map<String, Property> properties;
  final List<int> lastDiceRoll;
  final bool isDoubles;
  final int consecutiveDoubles;
  final String? message;
  final EventCard? activeEventCard;
  final Property? inspectedProperty;
  final BankruptcyRecord? activeBankruptcyRecord;
  final AuctionState? activeAuction;
  final TradeOffer? activeTradeOffer;
  final TransactionNotice? activeTransaction;
  final List<String> gameLogs;
  final bool isAiThinking;
  final bool isRollingDice;
  final int turnTimeRemaining;

  const GameState({
    required this.players,
    required this.currentPlayerIndex,
    required this.phase,
    required this.properties,
    this.lastDiceRoll = const [1, 1],
    this.isDoubles = false,
    this.consecutiveDoubles = 0,
    this.message,
    this.activeEventCard,
    this.inspectedProperty,
    this.activeBankruptcyRecord,
    this.activeAuction,
    this.activeTradeOffer,
    this.activeTransaction,
    this.gameLogs = const [],
    this.isAiThinking = false,
    this.isRollingDice = false,
    this.turnTimeRemaining = kTurnDurationSeconds,
  });

  Player get currentPlayer => players[currentPlayerIndex];
  int get diceTotal => lastDiceRoll[0] + lastDiceRoll[1];

  GameState copyWith({
    List<Player>? players,
    int? currentPlayerIndex,
    GamePhase? phase,
    Map<String, Property>? properties,
    List<int>? lastDiceRoll,
    bool? isDoubles,
    int? consecutiveDoubles,
    String? message,
    EventCard? activeEventCard,
    bool clearActiveEventCard = false,
    Property? inspectedProperty,
    bool clearInspectedProperty = false,
    BankruptcyRecord? activeBankruptcyRecord,
    bool clearBankruptcyRecord = false,
    AuctionState? activeAuction,
    bool clearActiveAuction = false,
    TradeOffer? activeTradeOffer,
    bool clearActiveTradeOffer = false,
    TransactionNotice? activeTransaction,
    bool clearActiveTransaction = false,
    List<String>? gameLogs,
    bool? isAiThinking,
    bool? isRollingDice,
    int? turnTimeRemaining,
  }) {
    return GameState(
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      phase: phase ?? this.phase,
      properties: properties ?? this.properties,
      lastDiceRoll: lastDiceRoll ?? this.lastDiceRoll,
      isDoubles: isDoubles ?? this.isDoubles,
      consecutiveDoubles: consecutiveDoubles ?? this.consecutiveDoubles,
      message: message,
      activeEventCard: clearActiveEventCard ? null : (activeEventCard ?? this.activeEventCard),
      inspectedProperty: clearInspectedProperty ? null : (inspectedProperty ?? this.inspectedProperty),
      activeBankruptcyRecord: clearBankruptcyRecord ? null : (activeBankruptcyRecord ?? this.activeBankruptcyRecord),
      activeAuction: clearActiveAuction ? null : (activeAuction ?? this.activeAuction),
      activeTradeOffer: clearActiveTradeOffer ? null : (activeTradeOffer ?? this.activeTradeOffer),
      activeTransaction: clearActiveTransaction ? null : (activeTransaction ?? this.activeTransaction),
      gameLogs: gameLogs ?? this.gameLogs,
      isAiThinking: isAiThinking ?? this.isAiThinking,
      isRollingDice: isRollingDice ?? this.isRollingDice,
      turnTimeRemaining: turnTimeRemaining ?? this.turnTimeRemaining,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'players': players.map((p) => p.toMap()).toList(),
      'currentPlayerIndex': currentPlayerIndex,
      'phase': phase.name,
      'properties': properties.map((k, v) => MapEntry(k, v.toMap())),
      'lastDiceRoll': lastDiceRoll,
      'isDoubles': isDoubles,
      'consecutiveDoubles': consecutiveDoubles,
      'message': message,
      'activeBankruptcyRecord': activeBankruptcyRecord?.toMap(),
      'activeAuction': activeAuction?.toMap(),
      'activeTradeOffer': activeTradeOffer?.toMap(),
      'activeTransaction': activeTransaction?.toMap(),
      'inspectedProperty': inspectedProperty?.toMap(),
      'activeEventCard': activeEventCard?.toMap(),
      'gameLogs': gameLogs,
      'isRollingDice': isRollingDice,
      'turnTimeRemaining': turnTimeRemaining,
    };
  }

  factory GameState.fromMap(Map<String, dynamic> map) {
    return GameState(
      players: List<Player>.from(map['players']?.map((x) => Player.fromMap(Map<String, dynamic>.from(x))) ?? []),
      currentPlayerIndex: map['currentPlayerIndex'] ?? 0,
      phase: GamePhase.values.firstWhere((e) => e.name == map['phase'], orElse: () => GamePhase.roll),
      properties: Map<String, Property>.from(map['properties']?.map((k, v) => MapEntry(k.toString(), Property.fromMap(Map<String, dynamic>.from(v)))) ?? {}),
      lastDiceRoll: List<int>.from(map['lastDiceRoll'] ?? [1, 1]),
      isDoubles: map['isDoubles'] ?? false,
      consecutiveDoubles: map['consecutiveDoubles'] ?? 0,
      message: map['message'],
      activeBankruptcyRecord: map['activeBankruptcyRecord'] != null
          ? BankruptcyRecord.fromMap(Map<String, dynamic>.from(map['activeBankruptcyRecord']))
          : null,
      activeAuction: map['activeAuction'] != null
          ? AuctionState.fromMap(Map<String, dynamic>.from(map['activeAuction']))
          : null,
      activeTradeOffer: map['activeTradeOffer'] != null
          ? TradeOffer.fromMap(Map<String, dynamic>.from(map['activeTradeOffer']))
          : null,
      activeTransaction: map['activeTransaction'] != null
          ? TransactionNotice.fromMap(Map<String, dynamic>.from(map['activeTransaction']))
          : null,
      inspectedProperty: map['inspectedProperty'] != null
          ? Property.fromMap(Map<String, dynamic>.from(map['inspectedProperty']))
          : null,
      activeEventCard: map['activeEventCard'] != null
          ? EventCard.fromMap(Map<String, dynamic>.from(map['activeEventCard']))
          : null,
      gameLogs: List<String>.from(map['gameLogs'] ?? []),
      isRollingDice: map['isRollingDice'] ?? false,
      turnTimeRemaining: (map['turnTimeRemaining'] as num?)?.toInt() ?? kTurnDurationSeconds,
    );
  }
}

class GameNotifier extends Notifier<GameState> {
  final Random _random = Random();
  bool _isHost = true;
  bool get isHost => _isHost;
  String? _localPlayerId;
  String? get localPlayerId => _localPlayerId;
  int _actionLockId = 0;
  Timer? _turnTimer;
  Timer? _transactionTimer;
  Timer? _aiTurnTimer;
  Timer? _aiTurnEndTimer;
  Timer? _diceRollTimer;
  Timer? _auctionTimer;

  void _showTransactionNotice({
    required String type,
    required String title,
    required String description,
    required String icon,
    Color? color,
  }) {
    _transactionTimer?.cancel();
    final notice = TransactionNotice(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}',
      type: type,
      title: title,
      description: description,
      icon: icon,
      colorValue: (color ?? const Color(0xFF0F172A)).toARGB32(),
    );
    state = state.copyWith(activeTransaction: notice);
    _broadcastState();

    _transactionTimer = Timer(const Duration(milliseconds: 3200), () {
      if (state.activeTransaction?.id == notice.id) {
        state = state.copyWith(clearActiveTransaction: true);
        _broadcastState();
      }
    });
  }

  @override
  GameState build() {
    ref.onDispose(() {
      _turnTimer?.cancel();
      _transactionTimer?.cancel();
      _aiTurnTimer?.cancel();
      _aiTurnEndTimer?.cancel();
      _diceRollTimer?.cancel();
      _auctionTimer?.cancel();
    });
    return GameState(
      players: [
        const Player(
          id: 'p1',
          name: 'Aadu Thoma',
          type: PlayerType.human,
          token: PlayerToken.houseboat,
          color: Color(0xFFE91E63),
          cash: 1000,
        ),
        const Player(
          id: 'p2',
          name: 'Ranga Annan (Bot)',
          type: PlayerType.ai,
          token: PlayerToken.coconut,
          color: Color(0xFF2196F3),
          aiPersonality: AiPersonality.conservative,
          cash: 1000,
        ),
      ],
      currentPlayerIndex: 0,
      phase: GamePhase.roll,
      properties: GameData.initialProperties,
      gameLogs: const ['Welcome to Kuthaka: Kerala Monopoly! 🌴'],
    );
  }

  @override
  set state(GameState value) {
    super.state = value;
    _broadcastState();
  }

  void _addLog(String log) {
    final newLogs = [log, ...state.gameLogs];
    if (newLogs.length > 50) newLogs.removeLast();
    state = state.copyWith(gameLogs: newLogs);
  }

  // Curated palette for auto-assigning unique colors per match
  static const List<Color> _matchColors = [
    Color(0xFFFFD54F), // Kasavu Gold
    Color(0xFFE91E63), // Malabar Crimson
    Color(0xFF00E676), // Kerala Palm Green
    Color(0xFF29B6F6), // Backwater Sky Blue
    Color(0xFFFF7043), // Sunset Terracotta
    Color(0xFFAB47BC), // Royal Orchid
  ];

  void initializeGame(List<Player> players, {bool isHost = true, String? localPlayerId}) {
    _actionLockId++;
    _turnTimer?.cancel();
    _transactionTimer?.cancel();
    _aiTurnTimer?.cancel();
    _aiTurnEndTimer?.cancel();
    _diceRollTimer?.cancel();
    _auctionTimer?.cancel();
    _isHost = isHost;
    _localPlayerId = localPlayerId ?? (isHost ? players.firstWhere((p) => p.type == PlayerType.human, orElse: () => players.first).id : null);

    // Auto-assign unique colors so no two players share a color
    final coloredPlayers = <Player>[];
    for (int i = 0; i < players.length; i++) {
      coloredPlayers.add(players[i].copyWith(color: _matchColors[i % _matchColors.length]));
    }

    state = GameState(
      players: coloredPlayers,
      currentPlayerIndex: 0,
      phase: GamePhase.roll,
      properties: GameData.initialProperties,
      gameLogs: ['Match started with ${coloredPlayers.length} players!'],
      message: '${coloredPlayers.first.name}\'s Turn to Roll!',
    );

    if (_isHost) {
      ref.read(multiplayerServiceProvider).onPlayerActionReceived = _handleRemotePlayerAction;
      ref.read(multiplayerServiceProvider).onEmojiReceived = (emoji, playerName) {
        // Broadcasts don't reach sender, but if they did we could deduplicate. 
        // We just invoke the provider.
        ref.read(emojiReactionProvider.notifier).receiveEmoji(emoji, playerName);
      };
      _broadcastState();
    }

    _startTurnTimer();

    if (players.first.type == PlayerType.ai) {
      _scheduleAiTurn();
    }
  }

  void initializeOnlineClient({List<Player>? initialPlayers, String? localPlayerId}) {
    _isHost = false;
    _localPlayerId = localPlayerId;
    if (initialPlayers != null && initialPlayers.isNotEmpty) {
      state = state.copyWith(
        players: initialPlayers,
        currentPlayerIndex: 0,
        phase: GamePhase.roll,
        properties: GameData.initialProperties,
        gameLogs: ['Connected to Host! Match started!'],
        message: '${initialPlayers.first.name}\'s Turn to Roll!',
      );
    }
    ref.read(multiplayerServiceProvider).onStateSyncReceived = (data) {
      state = GameState.fromMap(data);
    };
    ref.read(multiplayerServiceProvider).onEmojiReceived = (emoji, playerName) {
      ref.read(emojiReactionProvider.notifier).receiveEmoji(emoji, playerName);
    };
  }

  void _handleRemotePlayerAction(Map<String, dynamic> payload) {
    if (!_isHost) return;
    final actionType = (payload['action'] ?? payload['actionType'] ?? payload['type']) as String?;
    final data = payload['data'] is Map ? Map<String, dynamic>.from(payload['data'] as Map) : <String, dynamic>{};
    final senderPlayerId = data['playerId'] as String?;

    debugPrint('[GameNotifier] Host received remote action: $actionType from sender: $senderPlayerId (active player: ${state.currentPlayer.id})');

    if (actionType == null || actionType == 'broadcast') return;

    final turnBasedActions = {
      'roll_dice',
      'buy_property',
      'pass_property',
      'upgrade_property',
      'toggle_mortgage',
      'sell_building',
      'pay_jail_bail',
      'use_jail_card',
      'end_turn',
      'dismiss_event_card',
      'dismiss_bankruptcy',
      'propose_trade',
      'execute_trade',
    };

    if (turnBasedActions.contains(actionType) && senderPlayerId != null && senderPlayerId != state.currentPlayer.id) {
      debugPrint('[GameNotifier] Ignored $actionType from $senderPlayerId (active: ${state.currentPlayer.id})');
      return;
    }

    switch (actionType) {
      case 'roll_dice':
        _executeRollDice();
        break;
      case 'buy_property':
        final propId = data['propertyId'] as String?;
        if (propId != null) _executeBuyProperty(propId);
        break;
      case 'start_auction':
        final propId = data['propertyId'] as String?;
        if (propId != null) _executeStartAuction(propId);
        break;
      case 'place_bid':
        final pId = data['playerId'] as String?;
        final amount = (data['amount'] as num?)?.toInt();
        if (pId != null && amount != null) _executePlaceBid(pId, amount);
        break;
      case 'pass_bid':
        final pId = data['playerId'] as String?;
        if (pId != null) _executePassBid(pId);
        break;
      case 'pass_property':
        _executePassProperty();
        break;
      case 'upgrade_property':
        final propId = data['propertyId'] as String?;
        if (propId != null) _executeUpgradeProperty(propId);
        break;
      case 'toggle_mortgage':
        final propId = data['propertyId'] as String?;
        if (propId != null) _executeToggleMortgage(propId);
        break;
      case 'pay_jail_bail':
        _executePayJailBail();
        break;
      case 'use_jail_card':
        _executeUseJailCard();
        break;
      case 'end_turn':
        _endTurn();
        break;
      case 'dismiss_event_card':
        dismissEventCard();
        break;
      case 'dismiss_bankruptcy':
        dismissBankruptcy();
        break;
      case 'surrender_player':
        final pId = data['playerId'] as String?;
        if (pId != null) surrenderPlayer(pId);
        break;
      case 'sell_building':
        final propId = data['propertyId'] as String?;
        if (propId != null) _executeSellBuilding(propId);
        break;
      case 'execute_trade':
        final offerMap = data['offer'] as Map<String, dynamic>?;
        if (offerMap != null) {
          final offer = TradeOffer.fromMap(offerMap);
          executeTrade(offer);
        }
        break;
      case 'propose_trade':
        final offerMap = data['offer'] as Map<String, dynamic>?;
        if (offerMap != null) {
          final offer = TradeOffer.fromMap(offerMap);
          proposeTrade(offer);
        }
        break;
      case 'respond_trade':
        final offerId = data['offerId'] as String?;
        final accept = data['accept'] as bool? ?? false;
        if (offerId != null) {
          respondToTrade(offerId, accept);
        }
        break;
      case 'cancel_trade':
        cancelTradeOffer();
        break;
      case 'chat_message':
        final pId = data['playerId'] as String?;
        final msg = data['message'] as String?;
        if (pId != null && msg != null) {
          final p = state.players.firstWhere((p) => p.id == pId);
          _addLog('💬 ${p.name}: $msg');
          try { ref.read(audioServiceProvider.notifier).playClick(); } catch (_) {}
        }
        break;
      case 'emoji_reaction':
        final pId = data['playerId'] as String?;
        final emoji = data['emoji'] as String?;
        if (pId != null && emoji != null) {
          final p = state.players.firstWhere((p) => p.id == pId, orElse: () => state.players.first);
          debugPrint('[GameNotifier] Emoji reaction from ${p.name}: $emoji');
        }
        break;
    }
  }

  void _broadcastState() {
    if (_isHost) {
      try {
        ref.read(multiplayerServiceProvider).broadcastState(state.toMap());
      } catch (_) {}
    }
  }

  void inspectProperty(Property? prop) {
    state = state.copyWith(
      inspectedProperty: prop,
      clearInspectedProperty: prop == null,
      phase: (prop == null && state.phase == GamePhase.spaceAction) ? GamePhase.turnEnd : state.phase,
    );
  }

  void dismissEventCard() {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('dismiss_event_card', {
        'playerId': state.currentPlayer.id,
      });
      return;
    }
    state = state.copyWith(clearActiveEventCard: true);
    final current = state.currentPlayer;
    if (state.isDoubles && !current.isInJail) {
      _addLog('🎲 Doubles! ${current.name} gets another roll!');
      state = state.copyWith(
        phase: GamePhase.roll,
        isDoubles: false,
        turnTimeRemaining: kTurnDurationSeconds,
        message: 'DOUBLES! ${current.name} rolls again! 🎲',
      );
      _startTurnTimer();
      if (current.type == PlayerType.ai) {
        _scheduleAiTurn();
      }
    } else {
      state = state.copyWith(phase: GamePhase.turnEnd);
      if (current.type == PlayerType.ai) {
        _scheduleAiTurnEnd();
      }
    }
  }

  // ==================== DICE & MOVEMENT ====================

  void rollDice() {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('roll_dice', {
        'playerId': state.currentPlayer.id,
      });
      return;
    }
    _executeRollDice();
  }

  void _executeRollDice() {
    if (state.phase != GamePhase.roll || state.isRollingDice) return;
    try { ref.read(audioServiceProvider.notifier).playDiceRoll(); } catch (_) {}
    final current = state.currentPlayer;
    if (current.consecutiveTimeouts > 0) {
      _updatePlayer(current.copyWith(consecutiveTimeouts: 0));
    }

    // Check jail handling
    if (current.isInJail) {
      _handleJailRoll();
      return;
    }

    final d1 = _random.nextInt(6) + 1;
    final d2 = _random.nextInt(6) + 1;
    final isDouble = d1 == d2;
    final newConsecutive = isDouble ? state.consecutiveDoubles + 1 : 0;

    // Trigger dynamic rolling animation across all clients & overlays
    state = state.copyWith(
      isRollingDice: true,
      clearInspectedProperty: true,
      clearActiveEventCard: true,
      message: '${current.name} is rolling the dice...',
    );

    final lockId = _actionLockId;
    _diceRollTimer?.cancel();
    _diceRollTimer = Timer(const Duration(milliseconds: 900), () {
      if (lockId != _actionLockId) return;

      _addLog('${current.name} rolled $d1 & $d2 (${d1 + d2})${isDouble ? " - DOUBLES!" : ""}');

      if (newConsecutive >= 3) {
        _addLog('${current.name} rolled 3 doubles in a row! Sent to Police Station.');
        state = state.copyWith(
          isRollingDice: false,
          lastDiceRoll: [d1, d2],
          clearInspectedProperty: true,
          clearActiveEventCard: true,
        );
        _sendToJail(current);
        return;
      }

      state = state.copyWith(
        lastDiceRoll: [d1, d2],
        isDoubles: isDouble,
        consecutiveDoubles: newConsecutive,
        isRollingDice: false,
        clearInspectedProperty: true,
        clearActiveEventCard: true,
        phase: GamePhase.moving,
        message: '${current.name} rolled ${d1 + d2}! Moving spaces...',
      );

      _movePlayerStepwise(d1 + d2);
    });
  }

  void _handleJailRoll() {
    final current = state.currentPlayer;
    final d1 = _random.nextInt(6) + 1;
    final d2 = _random.nextInt(6) + 1;
    final isDouble = d1 == d2;

    state = state.copyWith(
      isRollingDice: true,
      message: '${current.name} in Hospital/Lockup rolling for doubles...',
    );

    final lockId = _actionLockId;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (lockId != _actionLockId) return;

      _addLog('${current.name} in Hospital/Jail rolled $d1 & $d2');

      if (isDouble) {
        _addLog('🎉 Doubles! ${current.name} escapes from Lockup free!');
        final updated = current.copyWith(isInJail: false, turnsInJail: 0);
        _updatePlayer(updated);
        state = state.copyWith(
          lastDiceRoll: [d1, d2],
          isDoubles: false,
          consecutiveDoubles: 0,
          isRollingDice: false,
          phase: GamePhase.moving,
          message: '${current.name} rolled doubles and got out of jail!',
        );
        _movePlayerStepwise(d1 + d2);
      } else {
        int turns = current.turnsInJail + 1;
        if (turns >= 3) {
          // Forced bail
          _addLog('${current.name} served 3 turns. Paid ₹100 fine and is freed.');
          final updated = current.copyWith(
            cash: max(0, current.cash - 100),
            isInJail: false,
            turnsInJail: 0,
          );
          _updatePlayer(updated);
          state = state.copyWith(
            lastDiceRoll: [d1, d2],
            isDoubles: false,
            isRollingDice: false,
            phase: GamePhase.moving,
            message: '${current.name} paid ₹100 fine and was released.',
          );
          _movePlayerStepwise(d1 + d2);
        } else {
          _addLog('${current.name} did not roll doubles ($turns/3 turns)');
          final updated = current.copyWith(turnsInJail: turns);
          _updatePlayer(updated);
          state = state.copyWith(
            lastDiceRoll: [d1, d2],
            isDoubles: false,
            isRollingDice: false,
            phase: GamePhase.turnEnd,
            message: 'Still in Lockup. Try again next turn.',
          );
          if (current.type == PlayerType.ai) {
            Future.delayed(const Duration(milliseconds: 1200), _endTurn);
          }
        }
      }
    });
  }

  void payJailBail() {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('pay_jail_bail', {
        'playerId': state.currentPlayer.id,
      });
      return;
    }
    _executePayJailBail();
  }

  void _executePayJailBail() {
    final current = state.currentPlayer;
    if (!current.isInJail) return;
    const bailCost = 100;
    if (current.cash >= bailCost) {
      _addLog('${current.name} paid ₹$bailCost fine to leave Lockup.');
      final updated = current.copyWith(
        cash: current.cash - bailCost,
        isInJail: false,
        turnsInJail: 0,
      );
      _updatePlayer(updated);
      state = state.copyWith(
        message: '${current.name} is now free to roll.',
        phase: GamePhase.roll,
      );
    }
  }

  void useJailCard() {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('use_jail_card', {
        'playerId': state.currentPlayer.id,
      });
      return;
    }
    _executeUseJailCard();
  }

  void _executeUseJailCard() {
    final current = state.currentPlayer;
    if (!current.isInJail || current.getOutOfJailCards <= 0) return;
    _addLog('${current.name} used a "Get Out of Jail Free" card!');
    final updated = current.copyWith(
      getOutOfJailCards: current.getOutOfJailCards - 1,
      isInJail: false,
      turnsInJail: 0,
    );
    _updatePlayer(updated);
    state = state.copyWith(
      message: '${current.name} is free to roll.',
      phase: GamePhase.roll,
    );
  }

  void _movePlayerStepwise(int totalSteps) {
    final lockId = _actionLockId;
    final current = state.currentPlayer;
    final targetPos = (current.position + totalSteps) % 40;
    final passedStart = targetPos < current.position;

    int newCash = current.cash;
    if (passedStart) {
      newCash += 200;
      _addLog('${current.name} passed Naattile Thudakkam! Collected ₹200. 💰');
    }

    _updatePlayer(current.copyWith(position: targetPos, cash: newCash));

    // Allow board token hop animation to finish at calibrated slower speed
    final delayMs = (totalSteps * 360) + 500;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (lockId != _actionLockId) return;
      state = state.copyWith(phase: GamePhase.spaceAction);
      _handleSpaceAction();
    });
  }

  // ==================== SPACE ACTIONS ====================

  void _handleSpaceAction() {
    final current = state.currentPlayer;
    final space = GameData.spaces[current.position];

    switch (space.type) {
      case SpaceType.property:
      case SpaceType.railroad:
      case SpaceType.utility:
        final prop = state.properties[space.propertyId]!;
        if (prop.ownerId == null) {
          // Unowned property
          if (current.type == PlayerType.ai) {
            _runAiBuyDecision(prop);
          } else {
            // Human player: If not enough money, automatically send to auction
            if (current.cash < prop.price) {
              _addLog('${current.name} lands on ${prop.name} but cannot afford ₹${prop.price} (has ₹${current.cash}). Sent automatically to Auction! 🔨');
              _executeStartAuction(prop.id);
            } else {
              // Has enough money: show property card with Buy / Auction choices
              state = state.copyWith(
                inspectedProperty: prop,
                message: 'Land on ${prop.name}! Buy for ₹${prop.price} or Auction?',
              );
            }
          }
        } else if (prop.ownerId == current.id) {
          _addLog('${current.name} visited their own property (${prop.name})');
          if (state.isDoubles && !current.isInJail) {
            _addLog('🎲 Doubles! ${current.name} gets another roll!');
            state = state.copyWith(
              phase: GamePhase.roll,
              isDoubles: false,
              turnTimeRemaining: kTurnDurationSeconds,
              message: 'You own ${prop.name}. Rolled DOUBLES! Roll again! 🎲',
            );
            _startTurnTimer();
            if (current.type == PlayerType.ai) {
              _scheduleAiTurn();
            }
          } else {
            state = state.copyWith(
              phase: GamePhase.turnEnd,
              message: 'You own ${prop.name}. Relax!',
            );
            if (current.type == PlayerType.ai) {
              _scheduleAiTurnEnd();
            }
          }
        } else {
          // Opponent property - pay rent!
          if (!prop.isMortgaged) {
            _payRent(prop);
          } else {
            _addLog('${prop.name} is mortgaged. No rent due!');
            if (state.isDoubles && !current.isInJail) {
              _addLog('🎲 Doubles! ${current.name} gets another roll!');
              state = state.copyWith(
                phase: GamePhase.roll,
                isDoubles: false,
                turnTimeRemaining: kTurnDurationSeconds,
                message: '${prop.name} is mortgaged. Rolled DOUBLES! Roll again! 🎲',
              );
              _startTurnTimer();
              if (current.type == PlayerType.ai) {
                _scheduleAiTurn();
              }
            } else {
              state = state.copyWith(
                phase: GamePhase.turnEnd,
                message: '${prop.name} is mortgaged. No rent owed!',
              );
              if (current.type == PlayerType.ai) {
                _scheduleAiTurnEnd();
              }
            }
          }
        }
        break;

      case SpaceType.tax:
        final tax = space.feeAmount ?? 100;
        _payTax(tax, space.name);
        break;

      case SpaceType.goToJail:
        _addLog('${current.name} landed on Police Station! Sent to Jail.');
        _sendToJail(current);
        break;

      case SpaceType.chance:
        _drawEventCard(GameData.chanceCards, 'Monsoon Alert');
        break;

      case SpaceType.communityChest:
        _drawEventCard(GameData.communityChestCards, 'Festival Bonus');
        break;

      case SpaceType.freeParking:
        _addLog('${current.name} took a tea break at Chaya Kada. ☕');
        if (state.isDoubles && !current.isInJail) {
          _addLog('🎲 Doubles! ${current.name} gets another roll!');
          state = state.copyWith(
            phase: GamePhase.roll,
            isDoubles: false,
            turnTimeRemaining: kTurnDurationSeconds,
            message: 'Enjoyed Meter Chaya! Rolled DOUBLES! Roll again! 🎲',
          );
          _startTurnTimer();
          if (current.type == PlayerType.ai) {
            _scheduleAiTurn();
          }
        } else {
          state = state.copyWith(
            phase: GamePhase.turnEnd,
            message: 'Enjoyed a Meter Chaya at Chaya Kada!',
          );
          if (current.type == PlayerType.ai) {
            _scheduleAiTurnEnd();
          }
        }
        break;

      case SpaceType.jail:
        _addLog('${current.name} is Just Visiting the Hospital/Jail.');
        if (state.isDoubles && !current.isInJail) {
          _addLog('🎲 Doubles! ${current.name} gets another roll!');
          state = state.copyWith(
            phase: GamePhase.roll,
            isDoubles: false,
            turnTimeRemaining: kTurnDurationSeconds,
            message: 'Just visiting. Rolled DOUBLES! Roll again! 🎲',
          );
          _startTurnTimer();
          if (current.type == PlayerType.ai) {
            _scheduleAiTurn();
          }
        } else {
          state = state.copyWith(
            phase: GamePhase.turnEnd,
            message: 'Just visiting the Hospital.',
          );
          if (current.type == PlayerType.ai) {
            _scheduleAiTurnEnd();
          }
        }
        break;

      case SpaceType.start:
        if (state.isDoubles && !current.isInJail) {
          _addLog('🎲 Doubles! ${current.name} gets another roll!');
          state = state.copyWith(
            phase: GamePhase.roll,
            isDoubles: false,
            turnTimeRemaining: kTurnDurationSeconds,
            message: 'At Naattile Thudakkam! Rolled DOUBLES! Roll again! 🎲',
          );
          _startTurnTimer();
          if (current.type == PlayerType.ai) {
            _scheduleAiTurn();
          }
        } else {
          state = state.copyWith(
            phase: GamePhase.turnEnd,
            message: 'At Naattile Thudakkam!',
          );
          if (current.type == PlayerType.ai) {
            _scheduleAiTurnEnd();
          }
        }
        break;
    }
  }

  void _sendToJail(Player player) {
    try { ref.read(audioServiceProvider.notifier).playJail(); } catch (_) {}
    final isPoliceStationJump = player.position == 30;
    final updated = player.copyWith(
      position: 10,
      isInJail: true,
      turnsInJail: 0,
    );
    _updatePlayer(updated);

    final lockId = _actionLockId;
    state = state.copyWith(
      phase: GamePhase.moving, // Keep in moving phase during the backward jump!
      consecutiveDoubles: 0,
      isDoubles: false,
      message: isPoliceStationJump
          ? '🚨 Police Station! ${player.name} jumping backwards to Central Jail...'
          : '${player.name} sent to Central Jail.',
    );

    final delayMs = isPoliceStationJump ? 4800 : 1500;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (lockId != _actionLockId) return;
      state = state.copyWith(
        phase: GamePhase.turnEnd,
        message: '${player.name} is now locked in Central Jail.',
      );
      if (player.type == PlayerType.ai) {
        _scheduleAiTurnEnd();
      }
    });
  }

  void _drawEventCard(List<EventCard> cardDeck, String category) {
    final card = cardDeck[_random.nextInt(cardDeck.length)];
    _addLog('${state.currentPlayer.name} drew $category: ${card.title}');
    try { ref.read(audioServiceProvider.notifier).playCardDraw(); } catch (_) {}

    state = state.copyWith(
      activeEventCard: card,
      message: '${card.title}: ${card.description}',
    );

    // Apply card effect
    _applyEventCard(card);
  }

  void _applyEventCard(EventCard card) {
    final current = state.currentPlayer;
    switch (card.type) {
      case EventCardType.moneyReward:
        final reward = card.amount ?? 20;
        _updatePlayer(current.copyWith(cash: current.cash + reward));
        _addLog('${current.name} gained ₹$reward');
        break;

      case EventCardType.moneyPenalty:
        final penalty = card.amount ?? 20;
        if (current.cash >= penalty) {
          _updatePlayer(current.copyWith(cash: current.cash - penalty));
          _addLog('${current.name} paid ₹$penalty');
        } else {
          _handleCashDeficit(current, penalty);
        }
        break;

      case EventCardType.moveToSpace:
        final dest = card.destinationIndex ?? 0;
        int cash = current.cash;
        if (dest < current.position && dest != 10) {
          cash += 200;
          _addLog('${current.name} passed Start! +₹200');
        }
        _updatePlayer(current.copyWith(position: dest, cash: cash));
        _addLog('${current.name} moved to ${GameData.spaces[dest].name}');
        break;

      case EventCardType.getOutOfJail:
        _updatePlayer(current.copyWith(getOutOfJailCards: current.getOutOfJailCards + 1));
        _addLog('${current.name} acquired a Get Out of Jail Free Card! 🎫');
        break;

      case EventCardType.goToJail:
        _sendToJail(current);
        return;

      case EventCardType.payPerHouse:
        int houses = 0;
        int resorts = 0;
        for (final pId in current.ownedPropertyIds) {
          final p = state.properties[pId];
          if (p != null) {
            if (p.currentLevel == 5) {
              resorts++;
            } else if (p.currentLevel > 0) {
              houses += p.currentLevel;
            }
          }
        }
        final totalFee = (houses * (card.houseFee ?? 25)) + (resorts * (card.resortFee ?? 100));
        _addLog('${current.name} owes ₹$totalFee for repairs ($houses houses, $resorts resorts)');
        if (current.cash >= totalFee) {
          _updatePlayer(current.copyWith(cash: current.cash - totalFee));
        } else {
          _handleCashDeficit(current, totalFee);
        }
        break;

      default:
        break;
    }

    if (current.type == PlayerType.ai) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        dismissEventCard();
      });
    }
  }

  void _payRent(Property prop) {
    final current = state.currentPlayer;
    final owner = state.players.firstWhere((p) => p.id == prop.ownerId);
    final rent = prop.getRent(state.properties, state.diceTotal);

    _addLog('${current.name} pays ₹$rent rent to ${owner.name} for ${prop.name}');

    if (current.cash >= rent) {
      _transferMoney(current.id, owner.id, rent);
      try { ref.read(audioServiceProvider.notifier).playCoins(); } catch (_) {}

      _showTransactionNotice(
        type: 'rent',
        title: 'RENT PAID',
        description: '${current.name} paid ₹$rent rent to ${owner.name} for ${prop.name}',
        icon: '💸',
        color: const Color(0xFFE11D48),
      );

      if (state.isDoubles && !current.isInJail) {
        _addLog('🎲 Doubles! ${current.name} gets another roll!');
        state = state.copyWith(
          phase: GamePhase.roll,
          isDoubles: false,
          turnTimeRemaining: kTurnDurationSeconds,
          message: 'Paid ₹$rent rent to ${owner.name}. Rolled DOUBLES! Roll again! 🎲',
        );
        _startTurnTimer();
        if (current.type == PlayerType.ai) {
          _scheduleAiTurn();
        }
      } else {
        state = state.copyWith(
          phase: GamePhase.turnEnd,
          message: 'Paid ₹$rent rent to ${owner.name}',
        );
        if (current.type == PlayerType.ai) {
          _scheduleAiTurnEnd();
        }
      }
    } else {
      _handleCashDeficit(current, rent, creditorId: owner.id);
    }
  }

  void _payTax(int amount, String taxName) {
    final current = state.currentPlayer;
    _addLog('${current.name} owes ₹$amount in $taxName');
    if (current.cash >= amount) {
      _updatePlayer(current.copyWith(cash: current.cash - amount));
      try { ref.read(audioServiceProvider.notifier).playCoins(); } catch (_) {}

      _showTransactionNotice(
        type: 'tax',
        title: 'TAX PAID',
        description: '${current.name} paid ₹$amount in $taxName',
        icon: '🏛️',
        color: const Color(0xFF64748B),
      );

      if (state.isDoubles && !current.isInJail) {
        _addLog('🎲 Doubles! ${current.name} gets another roll!');
        state = state.copyWith(
          phase: GamePhase.roll,
          isDoubles: false,
          turnTimeRemaining: kTurnDurationSeconds,
          message: 'Paid ₹$amount in $taxName. Rolled DOUBLES! Roll again! 🎲',
        );
        _startTurnTimer();
        if (current.type == PlayerType.ai) {
          _scheduleAiTurn();
        }
      } else {
        state = state.copyWith(
          phase: GamePhase.turnEnd,
          message: 'Paid ₹$amount in $taxName',
        );
        if (current.type == PlayerType.ai) {
          _scheduleAiTurnEnd();
        }
      }
    } else {
      _handleCashDeficit(current, amount);
    }
  }

  void _handleCashDeficit(Player player, int amountNeeded, {String? creditorId}) {
    // Attempt emergency mortgage of unmortgaged properties
    int deficit = amountNeeded - player.cash;
    final newProps = Map<String, Property>.from(state.properties);
    int raised = 0;

    for (final propId in player.ownedPropertyIds) {
      final prop = newProps[propId];
      if (prop != null && !prop.isMortgaged && prop.currentLevel == 0) {
        newProps[propId] = prop.copyWith(isMortgaged: true);
        raised += prop.mortgageValue;
        _addLog('${player.name} mortgaged ${prop.name} for ₹${prop.mortgageValue}');
        if (raised >= deficit) break;
      }
    }

    final newCash = player.cash + raised;
    if (newCash >= amountNeeded) {
      _updatePlayer(player.copyWith(cash: newCash - amountNeeded));
      state = state.copyWith(properties: newProps, phase: GamePhase.turnEnd);
      if (creditorId != null) {
        final creditor = state.players.firstWhere((p) => p.id == creditorId);
        _updatePlayer(creditor.copyWith(cash: creditor.cash + amountNeeded));
      }
      if (player.type == PlayerType.ai) {
        _scheduleAiTurnEnd();
      }
    } else {
      // Bankruptcy!
      _declareBankrupt(player, creditorId: creditorId);
    }
  }

  // ==================== PROPERTY ACTIONS ====================

  void buyProperty(String propertyId) {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('buy_property', {
        'playerId': state.currentPlayer.id,
        'propertyId': propertyId,
      });
      return;
    }
    _executeBuyProperty(propertyId);
  }

  void _executeBuyProperty(String propertyId) {
    try { ref.read(audioServiceProvider.notifier).playBuy(); } catch (_) {}
    final prop = state.properties[propertyId];
    final current = state.currentPlayer;
    if (prop == null || prop.ownerId != null) return;

    if (current.cash >= prop.price) {
      final newProps = Map<String, Property>.from(state.properties);
      newProps[propertyId] = prop.copyWith(ownerId: current.id);

      final updatedPlayer = current.copyWith(
        cash: current.cash - prop.price,
        ownedPropertyIds: [...current.ownedPropertyIds, propertyId],
      );

      _updatePlayer(updatedPlayer);
      try { ref.read(audioServiceProvider.notifier).playBuy(); } catch (_) {}

      _addLog('${current.name} bought ${prop.name} for ₹${prop.price}');

      _showTransactionNotice(
        type: 'buy',
        title: 'PROPERTY PURCHASED',
        description: '${current.name} bought ${prop.name} for ₹${prop.price}',
        icon: '🏷️',
        color: const Color(0xFF16A34A),
      );

      if (state.isDoubles && !updatedPlayer.isInJail) {
        _addLog('🎲 Doubles! ${current.name} gets another roll!');
        state = state.copyWith(
          properties: newProps,
          clearInspectedProperty: true,
          phase: GamePhase.roll,
          isDoubles: false,
          turnTimeRemaining: kTurnDurationSeconds,
          message: '${current.name} purchased ${prop.name}! Rolled DOUBLES! Roll again! 🎲',
        );
        _startTurnTimer();
        if (updatedPlayer.type == PlayerType.ai) {
          _scheduleAiTurn();
        }
      } else {
        state = state.copyWith(
          properties: newProps,
          clearInspectedProperty: true,
          phase: GamePhase.turnEnd,
          message: '${current.name} purchased ${prop.name} for ₹${prop.price}!',
        );
        if (updatedPlayer.type == PlayerType.ai) {
          _scheduleAiTurnEnd();
        }
      }
    }
  }

  void passProperty() {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('pass_property', {
        'playerId': state.currentPlayer.id,
      });
      return;
    }
    _executePassProperty();
  }

  void _executePassProperty() {
    final current = state.currentPlayer;
    final prop = state.inspectedProperty;
    if (prop != null && prop.ownerId == null && state.phase == GamePhase.spaceAction) {
      // Per Monopoly rules: passing on an unpurchased tile puts it up for auction
      _executeStartAuction(prop.id);
      return;
    }

    _addLog('${current.name} passed on buying ${state.inspectedProperty?.name ?? "property"}');
    state = state.copyWith(
      clearInspectedProperty: true,
      phase: GamePhase.turnEnd,
      message: '${current.name} passed.',
    );
    if (current.type == PlayerType.ai) {
      _scheduleAiTurnEnd();
    }
  }

  // ==================== AUCTION SYSTEM ====================

  void startAuction(String propertyId) {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('start_auction', {
        'playerId': state.currentPlayer.id,
        'propertyId': propertyId,
      });
      return;
    }
    _executeStartAuction(propertyId);
  }

  void _executeStartAuction(String propertyId) {
    final prop = state.properties[propertyId];
    if (prop == null || prop.ownerId != null) return;

    final current = state.currentPlayer;
    // Bidders list starting with current player (who landed on the tile and bids first)
    final nonBankrupt = state.players.where((p) => !p.isBankrupt).toList();
    final currentIdxInNonBankrupt = nonBankrupt.indexWhere((p) => p.id == current.id);
    final orderedBidders = <Player>[];
    for (int i = 0; i < nonBankrupt.length; i++) {
      final p = nonBankrupt[(currentIdxInNonBankrupt + i) % nonBankrupt.length];
      orderedBidders.add(p);
    }

    final auction = AuctionState(
      propertyId: propertyId,
      initiatorPlayerId: current.id,
      highestBid: 0,
      highestBidderId: null,
      currentBidderIndex: 0, // Current player bids first!
      activeBidderIds: orderedBidders.map((p) => p.id).toList(),
      bidHistory: ['${current.name} put ${prop.name} up for auction!'],
    );

    _addLog('🔨 AUCTION: ${current.name} put ${prop.name} up for auction! ${current.name} bids first.');
    try { ref.read(audioServiceProvider.notifier).playCardDraw(); } catch (_) {}

    state = state.copyWith(
      clearInspectedProperty: true,
      activeAuction: auction,
      message: 'Auction for ${prop.name}! ${current.name} bids first.',
    );

    if (current.type == PlayerType.ai) {
      _scheduleAiAuctionBid();
    }
    
    _startAuctionTimer();
  }

  void _startAuctionTimer() {
    _auctionTimer?.cancel();
    _auctionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final auction = state.activeAuction;
      if (auction == null || auction.isCompleted) {
        timer.cancel();
        return;
      }
      
      final remaining = auction.timeRemaining - 1;
      if (remaining <= 0) {
        timer.cancel();
        _executePassBid(auction.currentBidderId);
      } else {
        state = state.copyWith(
          activeAuction: auction.copyWith(timeRemaining: remaining),
        );
      }
    });
  }

  void placeBid(String playerId, int amount) {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('place_bid', {
        'playerId': playerId,
        'amount': amount,
      });
      return;
    }
    _executePlaceBid(playerId, amount);
  }

  void _executePlaceBid(String playerId, int amount) {
    final auction = state.activeAuction;
    if (auction == null || auction.isCompleted) return;

    final bidder = state.players.firstWhere((p) => p.id == playerId);
    if (amount <= auction.highestBid || bidder.cash < amount) return;

    _addLog('🔨 ${bidder.name} bid ₹$amount on ${state.properties[auction.propertyId]?.name ?? "property"}');
    try { ref.read(audioServiceProvider.notifier).playCoins(); } catch (_) {}

    // Advance to next active bidder
    final nextIdx = (auction.currentBidderIndex + 1) % auction.activeBidderIds.length;

    final updatedAuction = auction.copyWith(
      highestBid: amount,
      highestBidderId: playerId,
      currentBidderIndex: nextIdx,
      bidHistory: [...auction.bidHistory, '${bidder.name} bid ₹$amount'],
    );

    state = state.copyWith(
      activeAuction: updatedAuction,
      message: '${bidder.name} bid ₹$amount! Waiting for next bidder...',
    );

    final nextBidderId = updatedAuction.currentBidderId;
    final nextBidder = state.players.firstWhere((p) => p.id == nextBidderId);
    if (nextBidder.type == PlayerType.ai && !updatedAuction.isCompleted) {
      _scheduleAiAuctionBid();
    }
    
    _startAuctionTimer();
  }

  void passBid(String playerId) {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('pass_bid', {
        'playerId': playerId,
      });
      return;
    }
    _executePassBid(playerId);
  }

  void _executePassBid(String playerId) {
    final auction = state.activeAuction;
    if (auction == null || auction.isCompleted) return;

    final passer = state.players.firstWhere((p) => p.id == playerId);
    final remainingBidders = List<String>.from(auction.activeBidderIds)..remove(playerId);

    _addLog('${passer.name} folded in auction for ${state.properties[auction.propertyId]?.name ?? "property"}');

    // Case 1: Only 1 bidder left and there is a highest bidder -> Winner!
    if (remainingBidders.length == 1 && auction.highestBidderId != null) {
      final winnerId = auction.highestBidderId!;
      final winningBid = auction.highestBid;
      final completedAuction = auction.copyWith(
        activeBidderIds: remainingBidders,
        bidHistory: [...auction.bidHistory, '${passer.name} folded.'],
        isCompleted: true,
        winnerId: winnerId,
        winningBid: winningBid,
      );
      state = state.copyWith(activeAuction: completedAuction);
      _concludeAuction(winnerId, winningBid);
      return;
    }

    // Case 2: All bidders have folded (nobody placed a bid or all remaining folded)
    if (remainingBidders.isEmpty || (remainingBidders.length == 1 && auction.highestBidderId == null)) {
      final completedAuction = auction.copyWith(
        activeBidderIds: [],
        bidHistory: [...auction.bidHistory, '${passer.name} folded.'],
        isCompleted: true,
      );
      state = state.copyWith(activeAuction: completedAuction);
      _concludeAuctionNoBids();
      return;
    }

    // Case 3: Still multiple bidders left -> Advance turn
    final nextIdx = auction.currentBidderIndex % remainingBidders.length;
    final updatedAuction = auction.copyWith(
      activeBidderIds: remainingBidders,
      currentBidderIndex: nextIdx,
      bidHistory: [...auction.bidHistory, '${passer.name} folded.'],
    );

    state = state.copyWith(
      activeAuction: updatedAuction,
      message: '${passer.name} folded.',
    );

    final nextBidderId = updatedAuction.currentBidderId;
    final nextBidder = state.players.firstWhere((p) => p.id == nextBidderId);
    if (nextBidder.type == PlayerType.ai) {
      _scheduleAiAuctionBid();
    }
    
    _startAuctionTimer();
  }

  void _concludeAuction(String winnerId, int winningBid) {
    final auction = state.activeAuction;
    if (auction == null) return;
    final prop = state.properties[auction.propertyId];
    if (prop == null) return;
    final winner = state.players.firstWhere((p) => p.id == winnerId);

    _addLog('🏆 ${winner.name} won ${prop.name} for ₹$winningBid in auction!');
    try { ref.read(audioServiceProvider.notifier).playBuy(); } catch (_) {}

    _showTransactionNotice(
      type: 'auction',
      title: 'AUCTION WON',
      description: '${winner.name} won ${prop.name} for ₹$winningBid in auction!',
      icon: '🏆',
      color: const Color(0xFF7C3AED),
    );

    final newProps = Map<String, Property>.from(state.properties);
    newProps[prop.id] = prop.copyWith(ownerId: winner.id);

    final updatedWinner = winner.copyWith(
      cash: winner.cash - winningBid,
      ownedPropertyIds: [...winner.ownedPropertyIds, prop.id],
    );
    _updatePlayer(updatedWinner);

    state = state.copyWith(
      properties: newProps,
      message: '${winner.name} won ${prop.name} for ₹$winningBid!',
    );

    Future.delayed(const Duration(milliseconds: 1600), () {
      state = state.copyWith(clearActiveAuction: true);

      // Check doubles rule for current turn player!
      final current = state.currentPlayer;
      if (state.isDoubles && !current.isInJail) {
        _addLog('🎲 Doubles! ${current.name} gets another roll!');
        state = state.copyWith(
          phase: GamePhase.roll,
          isDoubles: false,
          turnTimeRemaining: kTurnDurationSeconds,
          message: 'DOUBLES! ${current.name} rolls again! 🎲',
        );
        _startTurnTimer();
        if (current.type == PlayerType.ai) {
          _scheduleAiTurn();
        }
      } else {
        state = state.copyWith(
          phase: GamePhase.turnEnd,
          message: 'Auction concluded. Turn finished.',
        );
        if (current.type == PlayerType.ai) {
          _scheduleAiTurnEnd();
        }
      }
    });
  }

  void _concludeAuctionNoBids() {
    final current = state.currentPlayer;
    _addLog('No bids received. Property remains unowned.');

    Future.delayed(const Duration(milliseconds: 1800), () {
      state = state.copyWith(clearActiveAuction: true);

      if (state.isDoubles && !current.isInJail) {
        _addLog('🎲 Doubles! ${current.name} gets another roll!');
        state = state.copyWith(
          phase: GamePhase.roll,
          isDoubles: false,
          turnTimeRemaining: kTurnDurationSeconds,
          message: 'DOUBLES! ${current.name} rolls again! 🎲',
        );
        _startTurnTimer();
        if (current.type == PlayerType.ai) {
          _scheduleAiTurn();
        }
      } else {
        state = state.copyWith(
          phase: GamePhase.turnEnd,
          message: 'Auction ended. No one purchased the property.',
        );
        if (current.type == PlayerType.ai) {
          _scheduleAiTurnEnd();
        }
      }
    });
  }

  void _scheduleAiAuctionBid() {
    final auction = state.activeAuction;
    if (auction == null || auction.isCompleted) return;

    final bidderId = auction.currentBidderId;
    final ai = state.players.firstWhere((p) => p.id == bidderId);
    if (ai.type != PlayerType.ai) return;

    Future.delayed(const Duration(milliseconds: 1100), () {
      final currentAuction = state.activeAuction;
      if (currentAuction == null || currentAuction.isCompleted) return;
      if (currentAuction.currentBidderId != ai.id) return;

      final prop = state.properties[currentAuction.propertyId];
      if (prop == null) {
        passBid(ai.id);
        return;
      }

      // AI Valuation:
      final personality = ai.aiPersonality ?? AiPersonality.conservative;
      double factor = 0.8;
      switch (personality) {
        case AiPersonality.aggressive:
        case AiPersonality.riskTaker:
          factor = 1.15;
          break;
        case AiPersonality.investor:
          factor = 1.0;
          break;
        case AiPersonality.trader:
          factor = 0.9;
          break;
        case AiPersonality.conservative:
          factor = 0.75;
          break;
      }

      // Check if completing monopoly:
      final groupProps = state.properties.values.where((p) => p.group == prop.group);
      final aiOwned = groupProps.where((p) => p.ownerId == ai.id).length;
      if (aiOwned == groupProps.length - 1) {
        factor = 1.6; // High willingness to bid for monopoly
      }

      final maxWillingness = (prop.price * factor).round();
      final minNextBid = currentAuction.minimumNextBid;

      if (minNextBid <= maxWillingness && ai.cash >= minNextBid + 15) {
        // AI places bid!
        placeBid(ai.id, minNextBid);
      } else {
        // AI passes
        passBid(ai.id);
      }
    });
  }

  void upgradeProperty(String propertyId) {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('upgrade_property', {
        'playerId': state.currentPlayer.id,
        'propertyId': propertyId,
      });
      return;
    }
    _executeUpgradeProperty(propertyId);
  }

  void _executeUpgradeProperty(String propertyId) {
    try { ref.read(audioServiceProvider.notifier).playUpgrade(); } catch (_) {}
    final prop = state.properties[propertyId];
    if (prop == null || prop.ownerId == null) return;
    final owner = state.players.firstWhere((p) => p.id == prop.ownerId);

    if (prop.canUpgrade(state.properties, owner.cash)) {
      final newLevel = prop.currentLevel + 1;
      final newProps = Map<String, Property>.from(state.properties);
      newProps[propertyId] = prop.copyWith(currentLevel: newLevel);

      final updatedOwner = owner.copyWith(cash: owner.cash - prop.upgradeCost);
      _updatePlayer(updatedOwner);
      try { ref.read(audioServiceProvider.notifier).playUpgrade(); } catch (_) {}

      final buildingType = newLevel == 5 ? 'Luxury Resort' : 'Cottage ($newLevel/4)';
      _addLog('${owner.name} upgraded ${prop.name} to $buildingType for ₹${prop.upgradeCost}');

      _showTransactionNotice(
        type: 'build',
        title: newLevel == 5 ? 'LUXURY RESORT BUILT' : 'COTTAGE BUILT',
        description: '${owner.name} built $buildingType on ${prop.name} for ₹${prop.upgradeCost}',
        icon: newLevel == 5 ? '🏨' : '🏡',
        color: const Color(0xFF0D9488),
      );

      state = state.copyWith(
        properties: newProps,
        message: 'Built $buildingType on ${prop.name}!',
      );
    }
  }

  void toggleMortgage(String propertyId) {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('toggle_mortgage', {
        'playerId': state.currentPlayer.id,
        'propertyId': propertyId,
      });
      return;
    }
    _executeToggleMortgage(propertyId);
  }

  void sendChatMessage(String message, String playerId) {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('chat_message', {
        'playerId': playerId,
        'message': message,
      });
    } else {
      final p = state.players.firstWhere((p) => p.id == playerId);
      _addLog('💬 ${p.name}: $message');
      try { ref.read(audioServiceProvider.notifier).playClick(); } catch (_) {}
    }
  }

  void _executeToggleMortgage(String propertyId) {
    final prop = state.properties[propertyId];
    if (prop == null || prop.ownerId == null) return;
    final owner = state.players.firstWhere((p) => p.id == prop.ownerId);

    final newProps = Map<String, Property>.from(state.properties);
    if (!prop.isMortgaged && prop.canMortgage()) {
      newProps[propertyId] = prop.copyWith(isMortgaged: true);
      _updatePlayer(owner.copyWith(cash: owner.cash + prop.mortgageValue));
      _addLog('${owner.name} mortgaged ${prop.name} (+₹${prop.mortgageValue})');
      _showTransactionNotice(
        type: 'mortgage',
        title: 'MORTGAGE COMPLETED',
        description: '${owner.name} mortgaged ${prop.name} for +₹${prop.mortgageValue}',
        icon: '🏦',
        color: const Color(0xFFD97706),
      );
      state = state.copyWith(properties: newProps);
    } else if (prop.isMortgaged && prop.canUnmortgage(owner.cash)) {
      newProps[propertyId] = prop.copyWith(isMortgaged: false);
      _updatePlayer(owner.copyWith(cash: owner.cash - prop.unmortgageCost));
      _addLog('${owner.name} unmortgaged ${prop.name} (-₹${prop.unmortgageCost})');
      _showTransactionNotice(
        type: 'redeem',
        title: 'MORTGAGE REDEEMED',
        description: '${owner.name} unmortgaged ${prop.name} for ₹${prop.unmortgageCost}',
        icon: '🔓',
        color: const Color(0xFF059669),
      );
      state = state.copyWith(properties: newProps);
    }
  }

  // ==================== SELL BUILDING (DOWNGRADE) ====================

  void sellBuilding(String propertyId) {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('sell_building', {
        'playerId': state.currentPlayer.id,
        'propertyId': propertyId,
      });
      return;
    }
    _executeSellBuilding(propertyId);
  }

  void _executeSellBuilding(String propertyId) {
    final prop = state.properties[propertyId];
    if (prop == null || prop.ownerId == null || prop.currentLevel <= 0) return;
    final owner = state.players.firstWhere((p) => p.id == prop.ownerId);

    // Check even building rule: can't sell if any group property has MORE buildings
    final groupProps = state.properties.values.where((p) => p.group == prop.group);
    for (final p in groupProps) {
      if (p.id != prop.id && p.currentLevel > prop.currentLevel) return;
    }

    final refund = prop.upgradeCost ~/ 2;
    final newLevel = prop.currentLevel - 1;
    final newProps = Map<String, Property>.from(state.properties);
    newProps[propertyId] = prop.copyWith(currentLevel: newLevel);

    _updatePlayer(owner.copyWith(cash: owner.cash + refund));

    final buildingType = prop.currentLevel == 5 ? 'Luxury Resort' : 'Cottage';
    _addLog('${owner.name} sold $buildingType on ${prop.name} (+₹$refund)');

    _showTransactionNotice(
      type: 'sell',
      title: 'SOLD BUILDING',
      description: '${owner.name} sold $buildingType on ${prop.name} for +₹$refund',
      icon: '🏠',
      color: const Color(0xFFEA580C),
    );

    state = state.copyWith(
      properties: newProps,
      message: 'Sold $buildingType on ${prop.name} for ₹$refund',
    );
  }


  // ==================== TRADING SYSTEM ====================

  bool executeTrade(TradeOffer offer) {
    // Only the currently active player can propose/execute trades, or offer must match accepted activeTradeOffer
    if (offer.senderId != state.currentPlayer.id && state.activeTradeOffer?.id != offer.id) {
      debugPrint('[GameNotifier] Trade execution rejected: sender ${offer.senderId} is not active player (${state.currentPlayer.id})');
      return false;
    }

    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('execute_trade', {
        'playerId': offer.senderId,
        'offer': offer.toMap(),
      });
      return true;
    }

    final sender = state.players.where((p) => p.id == offer.senderId).firstOrNull;
    final receiver = state.players.where((p) => p.id == offer.receiverId).firstOrNull;
    if (sender == null || receiver == null) return false;

    // Validate ownership and cash
    if (sender.cash < offer.offeredCash || receiver.cash < offer.requestedCash) return false;
    for (final pId in offer.offeredPropertyIds) {
      if (!sender.ownedPropertyIds.contains(pId)) return false;
    }
    for (final pId in offer.requestedPropertyIds) {
      if (!receiver.ownedPropertyIds.contains(pId)) return false;
    }

    // Transfer cash
    final updatedSenderCash = sender.cash - offer.offeredCash + offer.requestedCash;
    final updatedReceiverCash = receiver.cash - offer.requestedCash + offer.offeredCash;

    // Transfer properties
    final updatedSenderProps = List<String>.from(sender.ownedPropertyIds)
      ..removeWhere(offer.offeredPropertyIds.contains)
      ..addAll(offer.requestedPropertyIds);

    final updatedReceiverProps = List<String>.from(receiver.ownedPropertyIds)
      ..removeWhere(offer.requestedPropertyIds.contains)
      ..addAll(offer.offeredPropertyIds);

    final newProps = Map<String, Property>.from(state.properties);
    for (final pId in offer.offeredPropertyIds) {
      newProps[pId] = newProps[pId]!.copyWith(ownerId: receiver.id);
    }
    for (final pId in offer.requestedPropertyIds) {
      newProps[pId] = newProps[pId]!.copyWith(ownerId: sender.id);
    }

    _updatePlayer(sender.copyWith(cash: updatedSenderCash, ownedPropertyIds: updatedSenderProps));
    _updatePlayer(receiver.copyWith(cash: updatedReceiverCash, ownedPropertyIds: updatedReceiverProps));

    state = state.copyWith(properties: newProps);
    _addLog('🤝 Trade executed between ${sender.name} and ${receiver.name}!');

    _showTransactionNotice(
      type: 'trade',
      title: 'TRADE COMPLETED',
      description: 'Trade executed between ${sender.name} and ${receiver.name}!',
      icon: '🤝',
      color: const Color(0xFF2563EB),
    );

    _broadcastState();
    return true;
  }

  bool evaluateAiTrade(TradeOffer offer) {
    final receiver = state.players.firstWhere((p) => p.id == offer.receiverId);
    if (receiver.type != PlayerType.ai) return false;

    // AI value assessment:
    int giveValue = offer.requestedCash;
    for (final pId in offer.requestedPropertyIds) {
      final p = state.properties[pId]!;
      giveValue += p.price;
      // High penalty if giving away part of a monopoly
      if (p.isMonopoly(state.properties)) giveValue += p.price * 2;
    }

    int getValue = offer.offeredCash;
    for (final pId in offer.offeredPropertyIds) {
      final p = state.properties[pId]!;
      getValue += p.price;
      // High bonus if receiving property completes a monopoly
      final simulatedProps = Map<String, Property>.from(state.properties);
      simulatedProps[pId] = p.copyWith(ownerId: receiver.id);
      if (simulatedProps[pId]!.isMonopoly(simulatedProps)) {
        getValue += p.price * 2;
      }
    }

    return getValue >= giveValue * 0.95; // Reasonable fairness threshold
  }

  void proposeTrade(TradeOffer offer) {
    if (offer.senderId != state.currentPlayer.id) {
      debugPrint('[GameNotifier] Trade proposal rejected: sender ${offer.senderId} is not active player (${state.currentPlayer.id})');
      return;
    }

    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('propose_trade', {
        'playerId': offer.senderId,
        'offer': offer.toMap(),
      });
      return;
    }

    _executeProposeTrade(offer);
  }

  void _executeProposeTrade(TradeOffer offer) {
    final sender = state.players.where((p) => p.id == offer.senderId).firstOrNull;
    final receiver = state.players.where((p) => p.id == offer.receiverId).firstOrNull;
    if (sender == null || receiver == null) return;

    // Requirement: Only the player playing currently can implement/propose trade
    if (sender.id != state.currentPlayer.id) {
      debugPrint('[GameNotifier] Trade rejected: sender ${sender.name} is not the active turn player (${state.currentPlayer.name})');
      return;
    }

    // Validate ownership and cash
    if (sender.cash < offer.offeredCash || receiver.cash < offer.requestedCash) return;
    for (final pId in offer.offeredPropertyIds) {
      if (!sender.ownedPropertyIds.contains(pId)) return;
    }
    for (final pId in offer.requestedPropertyIds) {
      if (!receiver.ownedPropertyIds.contains(pId)) return;
    }

    if (receiver.type == PlayerType.ai) {
      final isFair = evaluateAiTrade(offer);
      if (isFair) {
        executeTrade(offer);
      } else {
        _addLog('❌ Deal Rejected! ${receiver.name} wants more value.');
        _showTransactionNotice(
          type: 'trade_declined',
          title: 'TRADE REJECTED',
          description: '${receiver.name} rejected the trade offer.',
          icon: '❌',
          color: const Color(0xFFEF4444),
        );
        _broadcastState();
      }
      return;
    }

    // Human receiver: set activeTradeOffer so receiver sees proposal overlay to accept or decline
    state = state.copyWith(activeTradeOffer: offer);
    _addLog('🤝 ${sender.name} proposed a trade to ${receiver.name}!');
    _showTransactionNotice(
      type: 'trade_proposed',
      title: 'TRADE PROPOSED',
      description: '${sender.name} sent a trade offer to ${receiver.name}.',
      icon: '🤝',
      color: const Color(0xFF2563EB),
    );
    _broadcastState();
  }

  void respondToTrade(String offerId, bool accept) {
    if (!_isHost) {
      final myProfile = ref.read(userProfileProvider);
      final myLocalId = localPlayerId ?? myProfile.id;
      ref.read(multiplayerServiceProvider).sendPlayerAction('respond_trade', {
        'playerId': myLocalId,
        'offerId': offerId,
        'accept': accept,
      });
      return;
    }

    final offer = state.activeTradeOffer;
    if (offer == null || offer.id != offerId) return;

    final sender = state.players.where((p) => p.id == offer.senderId).firstOrNull;
    final receiver = state.players.where((p) => p.id == offer.receiverId).firstOrNull;

    if (accept) {
      state = state.copyWith(clearActiveTradeOffer: true);
      final success = executeTrade(offer);
      if (success) {
        _addLog('🤝 Deal Accepted! ${receiver?.name ?? "Receiver"} accepted ${sender?.name ?? "Sender"}\'s trade offer.');
      } else {
        _addLog('❌ Trade failed: asset balances or ownership changed.');
        _broadcastState();
      }
    } else {
      state = state.copyWith(clearActiveTradeOffer: true);
      _addLog('❌ Trade Declined: ${receiver?.name ?? "Receiver"} declined ${sender?.name ?? "Sender"}\'s trade offer.');
      _showTransactionNotice(
        type: 'trade_declined',
        title: 'TRADE DECLINED',
        description: '${receiver?.name ?? "Receiver"} declined the trade offer.',
        icon: '❌',
        color: const Color(0xFFEF4444),
      );
      _broadcastState();
    }
  }

  void cancelTradeOffer() {
    if (!_isHost) {
      final myProfile = ref.read(userProfileProvider);
      final myLocalId = localPlayerId ?? myProfile.id;
      ref.read(multiplayerServiceProvider).sendPlayerAction('cancel_trade', {
        'playerId': myLocalId,
      });
      return;
    }

    if (state.activeTradeOffer != null) {
      state = state.copyWith(clearActiveTradeOffer: true);
      _addLog('Trade offer was cancelled.');
      _broadcastState();
    }
  }

  // ==================== INTELLIGENT AI ENGINE ====================

  void _scheduleAiTurn() {
    _aiTurnTimer?.cancel();
    final lockId = _actionLockId;
    state = state.copyWith(isAiThinking: true);

    _aiTurnTimer = Timer(const Duration(milliseconds: 1400), () {
      if (lockId != _actionLockId) return;
      state = state.copyWith(isAiThinking: false);

      final current = state.currentPlayer;
      if (current.type != PlayerType.ai) return;

      if (current.isInJail) {
        _handleAiJail(current);
      } else {
        rollDice();
      }
    });
  }

  void _handleAiJail(Player ai) {
    // If AI has card, use it
    if (ai.getOutOfJailCards > 0) {
      useJailCard();
      Future.delayed(const Duration(milliseconds: 800), rollDice);
      return;
    }

    // If early game or wealthy, pay bail
    final totalResorts = state.properties.values.where((p) => p.currentLevel >= 4).length;
    if (ai.cash > 200 && totalResorts == 0) {
      payJailBail();
      Future.delayed(const Duration(milliseconds: 800), rollDice);
    } else {
      // Roll for doubles
      rollDice();
    }
  }

  void _runAiBuyDecision(Property prop) {
    final ai = state.currentPlayer;
    final personality = ai.aiPersonality ?? AiPersonality.conservative;

    int reserveCash = 250;
    switch (personality) {
      case AiPersonality.aggressive:
      case AiPersonality.riskTaker:
        reserveCash = 80;
        break;
      case AiPersonality.investor:
        reserveCash = 180;
        break;
      case AiPersonality.trader:
        reserveCash = 150;
        break;
      case AiPersonality.conservative:
        reserveCash = 350;
        break;
    }

    // Check monopoly completion potential
    final groupProps = state.properties.values.where((p) => p.group == prop.group);
    final aiOwnedInGroup = groupProps.where((p) => p.ownerId == ai.id).length;
    final totalInGroup = groupProps.length;
    final isCompleting = aiOwnedInGroup == totalInGroup - 1;

    bool shouldBuy = false;
    if (isCompleting && ai.cash >= prop.price + 20) {
      // Completing monopoly is top priority!
      shouldBuy = true;
    } else if (prop.isTransport || prop.isUtility) {
      shouldBuy = ai.cash >= prop.price + (reserveCash * 0.7);
    } else {
      shouldBuy = ai.cash >= prop.price + reserveCash;
    }

    if (shouldBuy) {
      buyProperty(prop.id);
    } else {
      startAuction(prop.id);
    }
  }

  void _runAiPropertyManagement() {
    final ai = state.currentPlayer;
    if (ai.type != PlayerType.ai) return;

    // Scan for monopolies to upgrade
    for (final propId in ai.ownedPropertyIds) {
      for (int i = 0; i < 5; i++) { // Max 5 upgrades per property
        final currentAi = state.players.firstWhere((p) => p.id == ai.id);
        final currentProp = state.properties[propId];
        if (currentProp != null && currentProp.isBuildable && currentProp.isMonopoly(state.properties)) {
          if (currentProp.canUpgrade(state.properties, currentAi.cash) && currentAi.cash > currentProp.upgradeCost + 150) {
            upgradeProperty(currentProp.id);
          } else {
            break; // Cannot afford or max level reached
          }
        } else {
          break; // Not buildable or not monopoly
        }
      }
    }
  }

  void _scheduleAiTurnEnd() {
    _aiTurnEndTimer?.cancel();
    final lockId = _actionLockId;
    final delayMs = state.activeTransaction != null ? 3300 : 1400;
    _aiTurnEndTimer = Timer(Duration(milliseconds: delayMs), () {
      if (lockId != _actionLockId) return;
      _runAiPropertyManagement();
      _endTurn();
    });
  }

  // ==================== TURN PROGRESSION ====================

  void endTurn() {
    if (state.phase == GamePhase.moving) return;
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('end_turn', {
        'playerId': state.currentPlayer.id,
      });
      return;
    }
    _endTurn();
  }

  void closeAuction() {
    if (state.activeAuction != null) {
      state = state.copyWith(clearActiveAuction: true);
    }
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    if (state.phase == GamePhase.gameOver) return;

    state = state.copyWith(turnTimeRemaining: kTurnDurationSeconds);
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.phase == GamePhase.gameOver) {
        timer.cancel();
        return;
      }
      // If an auction is active, pause the turn timer so bidders aren't rushed
      if (state.activeAuction != null) {
        return;
      }
      final remaining = state.turnTimeRemaining - 1;
      if (remaining > 0) {
        state = state.copyWith(turnTimeRemaining: remaining);
      } else {
        timer.cancel();
        _handleTurnTimeout();
      }
    });
  }

  void _handleTurnTimeout() {
    if (state.phase == GamePhase.gameOver) return;

    final current = state.currentPlayer;
    final newTimeouts = current.consecutiveTimeouts + 1;
    _addLog('⏱️ ${current.name}\'s 45s turn timer expired! (Strike $newTimeouts/3)');

    if (newTimeouts >= 3) {
      _addLog('🚫 ${current.name} did not play for 3 consecutive turns! Removed from game. All tiles are now unowned.');
      _removePlayerForTimeouts(current);
    } else {
      _updatePlayer(current.copyWith(consecutiveTimeouts: newTimeouts));

      // If player timed out while on an unpurchased tile, send it to auction
      final currentSpace = current.position < GameData.spaces.length ? GameData.spaces[current.position] : null;
      final propId = currentSpace?.propertyId;
      final prop = propId != null ? state.properties[propId] : state.inspectedProperty;
      if (prop != null && prop.ownerId == null && state.phase == GamePhase.spaceAction) {
        _addLog('⏱️ ${current.name} timed out on ${prop.name}. Sent to Auction!');
        _executeStartAuction(prop.id);
        return;
      }
      state = state.copyWith(
        clearActiveAuction: true,
        clearActiveEventCard: true,
        clearInspectedProperty: true,
        clearActiveTradeOffer: true,
        message: '${current.name} timed out (Strike $newTimeouts/3). Passing turn.',
      );
      _forcePassTurn();
    }
  }

  void _removePlayerForTimeouts(Player player) {
    final newProps = Map<String, Property>.from(state.properties);
    final newPlayers = List<Player>.from(state.players);
    final playerIdx = newPlayers.indexWhere((p) => p.id == player.id);

    // All properties become unowned and available for others to buy
    for (final propId in player.ownedPropertyIds) {
      final prop = newProps[propId];
      if (prop != null) {
        newProps[propId] = prop.copyWith(
          clearOwner: true,
          currentLevel: 0,
          isMortgaged: false,
        );
      }
    }

    if (playerIdx != -1) {
      newPlayers[playerIdx] = player.copyWith(
        isBankrupt: true,
        cash: 0,
        ownedPropertyIds: const [],
        consecutiveTimeouts: 3,
      );
    }

    final active = newPlayers.where((p) => !p.isBankrupt).toList();
    if (active.length <= 1) {
      final winner = active.isNotEmpty ? active.first : player;
      _addLog('🏆 VICTORY! ${winner.name} won Kuthaka!');
      try { ref.read(audioServiceProvider.notifier).playVictory(); } catch (_) {}
      state = state.copyWith(
        players: newPlayers,
        properties: newProps,
        phase: GamePhase.gameOver,
        clearActiveAuction: true,
        clearActiveEventCard: true,
        clearInspectedProperty: true,
        message: '${winner.name} Wins Kuthaka!',
      );
      _turnTimer?.cancel();
    } else {
      state = state.copyWith(
        players: newPlayers,
        properties: newProps,
        clearActiveAuction: true,
        clearActiveEventCard: true,
        clearInspectedProperty: true,
        message: '${player.name} removed for inactivity.',
      );
      _forcePassTurn();
    }
  }

  void _forcePassTurn() {
    if (state.phase == GamePhase.gameOver) return;

    state = state.copyWith(isDoubles: false, consecutiveDoubles: 0);

    int nextIdx = (state.currentPlayerIndex + 1) % state.players.length;
    int searchCount = 0;
    while (state.players[nextIdx].isBankrupt && searchCount < state.players.length) {
      nextIdx = (nextIdx + 1) % state.players.length;
      searchCount++;
    }

    final nextPlayer = state.players[nextIdx];

    state = state.copyWith(
      currentPlayerIndex: nextIdx,
      phase: GamePhase.roll,
      consecutiveDoubles: 0,
      isDoubles: false,
      clearActiveEventCard: true,
      clearInspectedProperty: true,
      clearActiveAuction: true,
      turnTimeRemaining: kTurnDurationSeconds,
      message: '${nextPlayer.name}\'s Turn!',
    );

    _startTurnTimer();

    if (nextPlayer.type == PlayerType.ai) {
      _scheduleAiTurn();
    }
  }

  void _endTurn() {
    if (state.phase == GamePhase.gameOver || state.phase == GamePhase.moving) return;

    // Reset strike count if current player successfully took action
    final current = state.currentPlayer;
    if (current.consecutiveTimeouts > 0) {
      _updatePlayer(current.copyWith(consecutiveTimeouts: 0));
    }

    // If rolled doubles, get another roll (unless currently in jail)
    if (state.isDoubles && !state.currentPlayer.isInJail) {
      _addLog('${state.currentPlayer.name} rolled Doubles! Roll again! 🎲');
      state = state.copyWith(
        phase: GamePhase.roll,
        isDoubles: false,
        turnTimeRemaining: kTurnDurationSeconds,
        message: 'DOUBLES! Roll again.',
      );
      _startTurnTimer();
      if (state.currentPlayer.type == PlayerType.ai) {
        _scheduleAiTurn();
      }
      return;
    }

    // Advance to next active player
    int nextIdx = (state.currentPlayerIndex + 1) % state.players.length;
    int searchCount = 0;
    while (state.players[nextIdx].isBankrupt && searchCount < state.players.length) {
      nextIdx = (nextIdx + 1) % state.players.length;
      searchCount++;
    }

    final nextPlayer = state.players[nextIdx];

    state = state.copyWith(
      currentPlayerIndex: nextIdx,
      phase: GamePhase.roll,
      consecutiveDoubles: 0,
      isDoubles: false,
      clearActiveEventCard: true,
      clearInspectedProperty: true,
      clearActiveTradeOffer: true,
      turnTimeRemaining: kTurnDurationSeconds,
      message: '${nextPlayer.name}\'s Turn!',
    );

    _startTurnTimer();

    if (nextPlayer.type == PlayerType.ai) {
      _scheduleAiTurn();
    }
  }

  // ==================== BANKRUPTCY & TRANSFERS ====================

  void _transferMoney(String fromId, String toId, int amount) {
    final newPlayers = List<Player>.from(state.players);
    final fromIdx = newPlayers.indexWhere((p) => p.id == fromId);
    final toIdx = newPlayers.indexWhere((p) => p.id == toId);

    newPlayers[fromIdx] = newPlayers[fromIdx].copyWith(cash: newPlayers[fromIdx].cash - amount);
    newPlayers[toIdx] = newPlayers[toIdx].copyWith(cash: newPlayers[toIdx].cash + amount);

    try { ref.read(audioServiceProvider.notifier).playCoins(); } catch (_) {}
    state = state.copyWith(players: newPlayers);
  }

  void _updatePlayer(Player updated) {
    final newPlayers = List<Player>.from(state.players);
    final idx = newPlayers.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      newPlayers[idx] = updated;
      state = state.copyWith(players: newPlayers);
    }
  }

  @visibleForTesting
  void updatePlayerForTest(Player updated) => _updatePlayer(updated);

  void _declareBankrupt(Player player, {String? creditorId}) {
    try { ref.read(audioServiceProvider.notifier).playBankruptcy(); } catch (_) {}
    _addLog('${player.name} went bankrupt and surrendered all assets.');

    final newProps = Map<String, Property>.from(state.properties);
    final newPlayers = List<Player>.from(state.players);
    final playerIdx = newPlayers.indexWhere((p) => p.id == player.id);

    // Transfer properties to creditor or release to bank
    for (final propId in player.ownedPropertyIds) {
      if (creditorId != null) {
        newProps[propId] = newProps[propId]!.copyWith(ownerId: creditorId);
      } else {
        newProps[propId] = newProps[propId]!.copyWith(
          clearOwner: true,
          currentLevel: 0,
          isMortgaged: false,
        );
      }
    }

    if (creditorId != null) {
      final credIdx = newPlayers.indexWhere((p) => p.id == creditorId);
      if (credIdx != -1) {
        newPlayers[credIdx] = newPlayers[credIdx].copyWith(
          cash: newPlayers[credIdx].cash + player.cash,
          ownedPropertyIds: [...newPlayers[credIdx].ownedPropertyIds, ...player.ownedPropertyIds],
        );
      }
    }

    final creditor = creditorId != null
        ? newPlayers.cast<Player?>().firstWhere((p) => p?.id == creditorId, orElse: () => null)
        : null;

    final bankruptcyRecord = BankruptcyRecord(
      bankruptPlayerName: player.name,
      bankruptPlayerId: player.id,
      playerColorValue: player.color.toARGB32(),
      playerTokenIndex: player.token.index,
      creditorName: creditor?.name,
      propertiesForfeited: player.ownedPropertyIds.length,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    newPlayers[playerIdx] = player.copyWith(
      isBankrupt: true,
      cash: 0,
      ownedPropertyIds: const [],
    );

    // Persist real bankruptcy decree log in Supabase Postgres
    try {
      Supabase.instance.client.from('bankruptcy_logs').insert({
        'room_id': 'match',
        'bankrupt_player_name': player.name,
        'creditor_name': creditor?.name,
        'properties_forfeited': player.ownedPropertyIds.length,
        'sealed_at': DateTime.now().toIso8601String(),
      }).then((_) {}).catchError((_) {});
    } catch (_) {}

    // Check winner condition
    final active = newPlayers.where((p) => !p.isBankrupt).toList();
    if (active.length <= 1) {
      final winner = active.isNotEmpty ? active.first : player;
      _addLog('VICTORY! ${winner.name} won Kuthaka!');
      try { ref.read(audioServiceProvider.notifier).playVictory(); } catch (_) {}

      // Award real XP to winner in Supabase Postgres user_xp
      try {
        ref.read(leaderboardServiceProvider).awardXp(
          playerName: winner.name,
          xpToAdd: 50,
          isWinner: true,
        );
      } catch (_) {}

      state = state.copyWith(
        players: newPlayers,
        properties: newProps,
        phase: GamePhase.gameOver,
        activeBankruptcyRecord: bankruptcyRecord,
        message: '${winner.name} Wins Kuthaka!',
      );
    } else {
      state = state.copyWith(
        players: newPlayers,
        properties: newProps,
        activeBankruptcyRecord: bankruptcyRecord,
        message: '${player.name} is bankrupt!',
      );
    }
  }

  void surrenderPlayer(String playerId) {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('surrender_player', {
        'playerId': playerId,
      });
      return;
    }
    final player = state.players.cast<Player?>().firstWhere((p) => p?.id == playerId, orElse: () => null);
    if (player != null && !player.isBankrupt) {
      _declareBankrupt(player);
    }
  }


  void dismissBankruptcy() {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('dismiss_bankruptcy', {
        'playerId': state.currentPlayer.id,
      });
      return;
    }
    state = state.copyWith(clearBankruptcyRecord: true);
    if (state.phase != GamePhase.gameOver) {
      _endTurn();
    }
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(() {
  return GameNotifier();
});
