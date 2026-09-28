import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player.dart';
import '../models/property.dart';
import '../models/board_space.dart';
import '../models/event_card.dart';
import '../models/trade_offer.dart';
import '../models/bankruptcy_record.dart';
import '../data/game_data.dart';
import '../services/multiplayer_service.dart';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum GamePhase { roll, moving, spaceAction, turnEnd, gameOver }

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
  final List<String> gameLogs;
  final bool isAiThinking;
  final bool isRollingDice;

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
    this.gameLogs = const [],
    this.isAiThinking = false,
    this.isRollingDice = false,
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
    List<String>? gameLogs,
    bool? isAiThinking,
    bool? isRollingDice,
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
      gameLogs: gameLogs ?? this.gameLogs,
      isAiThinking: isAiThinking ?? this.isAiThinking,
      isRollingDice: isRollingDice ?? this.isRollingDice,
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
      'gameLogs': gameLogs,
      'isRollingDice': isRollingDice,
    };
  }

  factory GameState.fromMap(Map<String, dynamic> map) {
    return GameState(
      players: List<Player>.from(map['players']?.map((x) => Player.fromMap(x)) ?? []),
      currentPlayerIndex: map['currentPlayerIndex'] ?? 0,
      phase: GamePhase.values.firstWhere((e) => e.name == map['phase'], orElse: () => GamePhase.roll),
      properties: Map<String, Property>.from(map['properties']?.map((k, v) => MapEntry(k, Property.fromMap(v))) ?? {}),
      lastDiceRoll: List<int>.from(map['lastDiceRoll'] ?? [1, 1]),
      isDoubles: map['isDoubles'] ?? false,
      consecutiveDoubles: map['consecutiveDoubles'] ?? 0,
      message: map['message'],
      activeBankruptcyRecord: map['activeBankruptcyRecord'] != null
          ? BankruptcyRecord.fromMap(Map<String, dynamic>.from(map['activeBankruptcyRecord']))
          : null,
      gameLogs: List<String>.from(map['gameLogs'] ?? []),
      isRollingDice: map['isRollingDice'] ?? false,
    );
  }
}

class GameNotifier extends Notifier<GameState> {
  final Random _random = Random();
  bool _isHost = true;
  int _actionLockId = 0;

  @override
  GameState build() {
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

  void initializeGame(List<Player> players, {bool isHost = true}) {
    _actionLockId++;
    _isHost = isHost;
    state = GameState(
      players: players,
      currentPlayerIndex: 0,
      phase: GamePhase.roll,
      properties: GameData.initialProperties,
      gameLogs: ['Match started with ${players.length} players!'],
      message: '${players.first.name}\'s Turn to Roll!',
    );

    if (_isHost) {
      ref.read(multiplayerServiceProvider).onPlayerActionReceived = _handleRemotePlayerAction;
      _broadcastState();
    }

    if (players.first.type == PlayerType.ai) {
      _scheduleAiTurn();
    }
  }

  void initializeOnlineClient([List<Player>? initialPlayers]) {
    _isHost = false;
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
  }

  void _handleRemotePlayerAction(Map<String, dynamic> payload) {
    if (!_isHost) return;
    final actionType = payload['type'] as String?;
    final data = payload['data'] is Map ? Map<String, dynamic>.from(payload['data'] as Map) : <String, dynamic>{};
    final senderPlayerId = data['playerId'] as String?;

    if (senderPlayerId != null && senderPlayerId != state.currentPlayer.id) {
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
      case 'start_auction':
        final propId = data['propertyId'] as String?;
        if (propId != null) _executeStartAuction(propId);
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
    if (state.phase == GamePhase.spaceAction) {
      state = state.copyWith(phase: GamePhase.turnEnd);
      if (state.currentPlayer.type == PlayerType.ai) {
        _endTurn();
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
      message: '${current.name} is rolling the dice...',
    );

    final lockId = _actionLockId;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (lockId != _actionLockId) return;

      _addLog('${current.name} rolled $d1 & $d2 (${d1 + d2})${isDouble ? " - DOUBLES!" : ""}');

      if (newConsecutive >= 3) {
        _addLog('${current.name} rolled 3 doubles in a row! Sent to Police Station.');
        state = state.copyWith(
          isRollingDice: false,
          lastDiceRoll: [d1, d2],
        );
        _sendToJail(current);
        return;
      }

      state = state.copyWith(
        lastDiceRoll: [d1, d2],
        isDoubles: isDouble,
        consecutiveDoubles: newConsecutive,
        isRollingDice: false,
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
          _addLog('${current.name} served 3 turns. Paid ₹50 fine and is freed.');
          final updated = current.copyWith(
            cash: max(0, current.cash - 50),
            isInJail: false,
            turnsInJail: 0,
          );
          _updatePlayer(updated);
          state = state.copyWith(
            lastDiceRoll: [d1, d2],
            isDoubles: false,
            isRollingDice: false,
            phase: GamePhase.moving,
            message: '${current.name} paid ₹50 fine and was released.',
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
    const bailCost = 50;
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

    // Allow board token hop animation to finish
    Future.delayed(const Duration(milliseconds: 1200), () {
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
            // Human player: show property card or prompt
            state = state.copyWith(
              inspectedProperty: prop,
              message: 'Land on ${prop.name}! Buy for ₹${prop.price}?',
            );
          }
        } else if (prop.ownerId == current.id) {
          _addLog('${current.name} visited their own property (${prop.name})');
          state = state.copyWith(
            phase: GamePhase.turnEnd,
            message: 'You own ${prop.name}. Relax!',
          );
          if (current.type == PlayerType.ai) {
            _scheduleAiTurnEnd();
          }
        } else {
          // Opponent property - pay rent!
          if (!prop.isMortgaged) {
            _payRent(prop);
          } else {
            _addLog('${prop.name} is mortgaged. No rent due!');
            state = state.copyWith(
              phase: GamePhase.turnEnd,
              message: '${prop.name} is mortgaged. No rent owed!',
            );
            if (current.type == PlayerType.ai) {
              _scheduleAiTurnEnd();
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
        state = state.copyWith(
          phase: GamePhase.turnEnd,
          message: 'Enjoyed a Meter Chaya at Chaya Kada!',
        );
        if (current.type == PlayerType.ai) {
          _scheduleAiTurnEnd();
        }
        break;

      case SpaceType.jail:
        _addLog('${current.name} is Just Visiting the Hospital/Jail.');
        state = state.copyWith(
          phase: GamePhase.turnEnd,
          message: 'Just visiting the Hospital.',
        );
        if (current.type == PlayerType.ai) {
          _scheduleAiTurnEnd();
        }
        break;

      case SpaceType.start:
        state = state.copyWith(
          phase: GamePhase.turnEnd,
          message: 'At Naattile Thudakkam!',
        );
        if (current.type == PlayerType.ai) {
          _scheduleAiTurnEnd();
        }
        break;
    }
  }

  void _sendToJail(Player player) {
    try { ref.read(audioServiceProvider.notifier).playJail(); } catch (_) {}
    final updated = player.copyWith(
      position: 10,
      isInJail: true,
      turnsInJail: 0,
    );
    _updatePlayer(updated);
    state = state.copyWith(
      phase: GamePhase.turnEnd,
      consecutiveDoubles: 0,
      isDoubles: false,
      message: '${player.name} is in Police Lockup (Hospital).',
    );
    if (player.type == PlayerType.ai) {
      _scheduleAiTurnEnd();
    }
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
      state = state.copyWith(
        phase: GamePhase.turnEnd,
        message: 'Paid ₹$rent rent to ${owner.name}',
      );
      if (current.type == PlayerType.ai) {
        _scheduleAiTurnEnd();
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
      state = state.copyWith(
        phase: GamePhase.turnEnd,
        message: 'Paid ₹$amount in $taxName',
      );
      if (current.type == PlayerType.ai) {
        _scheduleAiTurnEnd();
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
      state = state.copyWith(
        properties: newProps,
        clearInspectedProperty: true,
        phase: GamePhase.turnEnd,
        message: '${current.name} purchased ${prop.name} for ₹${prop.price}!',
      );

      _addLog('${current.name} bought ${prop.name} for ₹${prop.price}');

      if (updatedPlayer.type == PlayerType.ai) {
        _scheduleAiTurnEnd();
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

  void _executeToggleMortgage(String propertyId) {
    final prop = state.properties[propertyId];
    if (prop == null || prop.ownerId == null) return;
    final owner = state.players.firstWhere((p) => p.id == prop.ownerId);

    final newProps = Map<String, Property>.from(state.properties);
    if (!prop.isMortgaged && prop.canMortgage()) {
      newProps[propertyId] = prop.copyWith(isMortgaged: true);
      _updatePlayer(owner.copyWith(cash: owner.cash + prop.mortgageValue));
      _addLog('${owner.name} mortgaged ${prop.name} (+₹${prop.mortgageValue})');
      state = state.copyWith(properties: newProps);
    } else if (prop.isMortgaged && prop.canUnmortgage(owner.cash)) {
      newProps[propertyId] = prop.copyWith(isMortgaged: false);
      _updatePlayer(owner.copyWith(cash: owner.cash - prop.unmortgageCost));
      _addLog('${owner.name} unmortgaged ${prop.name} (-₹${prop.unmortgageCost})');
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

    state = state.copyWith(
      properties: newProps,
      message: 'Sold $buildingType on ${prop.name} for ₹$refund',
    );
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

    _addLog('🔨 AUCTION STARTED for ${prop.name}! Starting at ₹1');

    // Collect bids from all active players
    final activePlayers = state.players.where((p) => !p.isBankrupt).toList();
    int highestBid = 0;
    Player? highestBidder;

    for (final player in activePlayers) {
      int bid = 0;

      if (player.type == PlayerType.ai) {
        // AI bidding logic based on personality
        final personality = player.aiPersonality ?? AiPersonality.conservative;
        double maxBidRatio;
        switch (personality) {
          case AiPersonality.aggressive:
          case AiPersonality.riskTaker:
            maxBidRatio = 1.2;
            break;
          case AiPersonality.investor:
            maxBidRatio = 1.0;
            break;
          case AiPersonality.trader:
            maxBidRatio = 0.9;
            break;
          case AiPersonality.conservative:
            maxBidRatio = 0.7;
            break;
        }

        // Check if completing monopoly makes it more valuable
        final groupProps = state.properties.values.where((p) => p.group == prop.group);
        final aiOwnsInGroup = groupProps.where((p) => p.ownerId == player.id).length;
        final isNearMonopoly = aiOwnsInGroup == groupProps.length - 1;
        if (isNearMonopoly) maxBidRatio += 0.5;

        final maxBid = (prop.price * maxBidRatio).round();
        // AI bids up to maxBid but at least 1 above current highest
        if (player.cash >= highestBid + 10 && maxBid > highestBid) {
          bid = min(maxBid, player.cash);
          bid = max(bid, highestBid + 10);
          bid = min(bid, player.cash); // Cap at cash
        }
      } else {
        // Human player: auto-bid at starting price (base value)
        // In a real-time game this would be interactive; for now, human gets a fair starting bid
        if (player.cash >= highestBid + 10) {
          bid = min(prop.price ~/ 2, player.cash);
          bid = max(bid, highestBid + 10);
          bid = min(bid, player.cash);
        }
      }

      if (bid > highestBid && bid > 0) {
        highestBid = bid;
        highestBidder = player;
      }
    }

    // Execute auction result
    if (highestBidder != null && highestBid > 0) {
      final newProps = Map<String, Property>.from(state.properties);
      newProps[propertyId] = prop.copyWith(ownerId: highestBidder.id);

      final updatedBidder = highestBidder.copyWith(
        cash: highestBidder.cash - highestBid,
        ownedPropertyIds: [...highestBidder.ownedPropertyIds, propertyId],
      );
      _updatePlayer(updatedBidder);
      try { ref.read(audioServiceProvider.notifier).playBuy(); } catch (_) {}

      _addLog('🔨 ${highestBidder.name} won auction for ${prop.name} at ₹$highestBid!');

      state = state.copyWith(
        properties: newProps,
        clearInspectedProperty: true,
        phase: GamePhase.turnEnd,
        message: '${highestBidder.name} won ${prop.name} at auction for ₹$highestBid!',
      );
    } else {
      _addLog('🔨 No bidders for ${prop.name}. Property remains unsold.');
      state = state.copyWith(
        clearInspectedProperty: true,
        phase: GamePhase.turnEnd,
        message: 'No one bid on ${prop.name}. Property stays with the bank.',
      );
    }

    if (state.currentPlayer.type == PlayerType.ai) {
      _scheduleAiTurnEnd();
    }
  }

  // ==================== TRADING SYSTEM ====================

  bool executeTrade(TradeOffer offer) {
    final sender = state.players.firstWhere((p) => p.id == offer.senderId);
    final receiver = state.players.firstWhere((p) => p.id == offer.receiverId);

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

  // ==================== INTELLIGENT AI ENGINE ====================

  void _scheduleAiTurn() {
    final lockId = _actionLockId;
    state = state.copyWith(isAiThinking: true);

    Future.delayed(const Duration(milliseconds: 1400), () {
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
      passProperty();
    }
  }

  void _runAiPropertyManagement() {
    final ai = state.currentPlayer;
    if (ai.type != PlayerType.ai) return;

    // Scan for monopolies to upgrade
    for (final propId in ai.ownedPropertyIds) {
      final prop = state.properties[propId];
      if (prop != null && prop.isBuildable && prop.isMonopoly(state.properties)) {
        while (prop.canUpgrade(state.properties, ai.cash) && ai.cash > prop.upgradeCost + 150) {
          upgradeProperty(prop.id);
        }
      }
    }
  }

  void _scheduleAiTurnEnd() {
    final lockId = _actionLockId;
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (lockId != _actionLockId) return;
      _runAiPropertyManagement();
      _endTurn();
    });
  }

  // ==================== TURN PROGRESSION ====================

  void endTurn() {
    if (!_isHost) {
      ref.read(multiplayerServiceProvider).sendPlayerAction('end_turn', {
        'playerId': state.currentPlayer.id,
      });
      return;
    }
    _endTurn();
  }

  void _endTurn() {
    if (state.phase == GamePhase.gameOver) return;

    // If rolled doubles, get another roll (unless currently in jail)
    if (state.isDoubles && !state.currentPlayer.isInJail) {
      _addLog('${state.currentPlayer.name} rolled Doubles! Roll again! 🎲');
      state = state.copyWith(
        phase: GamePhase.roll,
        isDoubles: false,
        message: 'DOUBLES! Roll again.',
      );
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
      message: '${nextPlayer.name}\'s Turn!',
    );

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

  void _declareBankrupt(Player player, {String? creditorId}) {
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
          ownerId: null,
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
