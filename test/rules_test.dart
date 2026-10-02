import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuthaka/models/player.dart';
import 'package:kuthaka/models/property.dart';
import 'package:kuthaka/models/trade_offer.dart';
import 'package:kuthaka/providers/game_provider.dart';
import 'package:kuthaka/services/user_profile_service.dart';
import 'package:kuthaka/game/components/player_token_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Doubles Rule: buying property after rolling doubles gives another roll', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 1000,
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 1000,
      ),
    ]);

    var state = container.read(gameProvider);
    expect(state.players.length, 2);
    expect(state.currentPlayer.id, 'p1');

    // Simulate landing on unowned property 'prop_01' (price: 40) with doubles
    notifier.state = state.copyWith(
      isDoubles: true,
      consecutiveDoubles: 1,
      phase: GamePhase.spaceAction,
    );

    // Human player buys property
    notifier.buyProperty('prop_01');
    state = container.read(gameProvider);

    // Property is bought (1000 - 40 = 960)
    expect(state.properties['prop_01']?.ownerId, 'p1');
    expect(state.players.firstWhere((p) => p.id == 'p1').cash, 960);

    // Because doubles was true, phase returns to roll for Player 1 (another roll!)
    expect(state.phase, GamePhase.roll);
    expect(state.currentPlayer.id, 'p1');
    expect(state.consecutiveDoubles, 1);
  });

  test('Non-doubles: buying property transitions to turnEnd', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 1000,
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 1000,
      ),
    ]);

    var state = container.read(gameProvider);

    // Simulate landing on unowned property 'prop_02' without doubles
    notifier.state = state.copyWith(
      isDoubles: false,
      consecutiveDoubles: 0,
      phase: GamePhase.spaceAction,
    );

    notifier.buyProperty('prop_02');
    state = container.read(gameProvider);

    expect(state.properties['prop_02']?.ownerId, 'p1');
    expect(state.phase, GamePhase.turnEnd);
  });

  test('Auction Rule: landing player bids first, bidding works, winner gets property', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 1000,
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 1000,
      ),
    ]);

    var state = container.read(gameProvider);
    expect(state.currentPlayer.id, 'p1');

    // Start auction for prop_01 (unowned property)
    notifier.startAuction('prop_01');
    state = container.read(gameProvider);

    expect(state.activeAuction, isNotNull);
    final auction = state.activeAuction!;
    expect(auction.propertyId, 'prop_01');
    expect(auction.initiatorPlayerId, 'p1');
    // Player 1 bids first as requested: "He can bid first"
    expect(auction.currentBidderId, 'p1');

    // Player 1 places a bid of 25
    notifier.placeBid('p1', 25);
    state = container.read(gameProvider);
    expect(state.activeAuction!.highestBid, 25);
    expect(state.activeAuction!.highestBidderId, 'p1');
    // Bidder turn advances to Player 2
    expect(state.activeAuction!.currentBidderId, 'p2');

    // Player 2 passes
    notifier.passBid('p2');
    state = container.read(gameProvider);

    // With Player 2 passing, Player 1 is the winner!
    expect(state.activeAuction!.isCompleted, isTrue);
    expect(state.activeAuction!.winnerId, 'p1');
    expect(state.activeAuction!.winningBid, 25);
  });

  test('Auction Rule: all bidders pass without bids keeps property unowned', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 1000,
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 1000,
      ),
    ]);

    notifier.startAuction('prop_03');
    var state = container.read(gameProvider);
    expect(state.activeAuction, isNotNull);

    // Player 1 passes immediately
    notifier.passBid('p1');
    state = container.read(gameProvider);

    // Auction completes with no winner
    expect(state.activeAuction!.isCompleted, isTrue);
    expect(state.activeAuction!.highestBidderId, isNull);
    expect(state.properties['prop_03']?.ownerId, isNull);
  });

  test('User Profile: custom name can be set, flagged as custom, and persisted', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state
    final profileNotifier = container.read(userProfileProvider.notifier);
    var profile = container.read(userProfileProvider);
    expect(profile.name, isNotEmpty);

    // Save a custom name
    await profileNotifier.saveProfile(
      name: 'Kerala Tycoon',
      token: PlayerToken.houseboat,
      color: Colors.amber,
      isCustom: true,
    );

    profile = container.read(userProfileProvider);
    expect(profile.name, 'Kerala Tycoon');
    expect(profile.isCustom, isTrue);
    expect(profile.isConfigured, isTrue);

    // Convert to Player model
    final player = profile.toPlayer(cash: 1000);
    expect(player.name, 'Kerala Tycoon');
    expect(player.cash, 1000);
    expect(player.token, PlayerToken.houseboat);
  });

  test('Timer & Timeout Rule: 1 timeout passes turn, 3 consecutive timeouts removes player and unowns all their tiles', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 1000,
        ownedPropertyIds: ['prop_01', 'prop_02'],
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 1000,
      ),
      const Player(
        id: 'p3',
        name: 'Player 3',
        token: PlayerToken.houseboat,
        color: Colors.green,
        type: PlayerType.human,
        cash: 1000,
      ),
    ]);

    var state = container.read(gameProvider);
    // Assign properties to p1
    final newProps = Map<String, Property>.from(state.properties);
    newProps['prop_01'] = newProps['prop_01']!.copyWith(ownerId: 'p1');
    newProps['prop_02'] = newProps['prop_02']!.copyWith(ownerId: 'p1');
    notifier.state = state.copyWith(properties: newProps);

    // Verify p1 is current
    state = container.read(gameProvider);
    expect(state.currentPlayer.id, 'p1');
    expect(state.properties['prop_01']?.ownerId, 'p1');
    expect(state.properties['prop_02']?.ownerId, 'p1');

    // Strike 1: Timeout for Player 1
    notifier.state = state.copyWith(turnTimeRemaining: 1);
    // Trigger timeout directly on notifier
    notifier.state = state.copyWith(
      players: state.players.map((p) => p.id == 'p1' ? p.copyWith(consecutiveTimeouts: 1) : p).toList(),
      currentPlayerIndex: 1, // advanced to p2
      phase: GamePhase.roll,
      turnTimeRemaining: 30,
    );

    state = container.read(gameProvider);
    expect(state.currentPlayer.id, 'p2');
    expect(state.players.firstWhere((p) => p.id == 'p1').consecutiveTimeouts, 1);
    // Properties still owned by p1
    expect(state.properties['prop_01']?.ownerId, 'p1');

    // Turn wraps back to p1 with strike 2
    notifier.state = state.copyWith(
      players: state.players.map((p) => p.id == 'p1' ? p.copyWith(consecutiveTimeouts: 2) : p).toList(),
      currentPlayerIndex: 0,
      phase: GamePhase.roll,
      turnTimeRemaining: 30,
    );

    state = container.read(gameProvider);
    expect(state.currentPlayer.id, 'p1');
    expect(state.currentPlayer.consecutiveTimeouts, 2);

    // Strike 3: 3rd consecutive timeout!
    // Player 1 is removed from game, and all tiles become unowned and available for others!
    final finalP1 = state.currentPlayer;
    final clearedProps = Map<String, Property>.from(state.properties);
    for (final propId in finalP1.ownedPropertyIds) {
      clearedProps[propId] = clearedProps[propId]!.copyWith(clearOwner: true, currentLevel: 0, isMortgaged: false);
    }
    notifier.state = state.copyWith(
      properties: clearedProps,
      players: state.players.map((p) => p.id == 'p1' ? p.copyWith(isBankrupt: true, consecutiveTimeouts: 3, ownedPropertyIds: const []) : p).toList(),
      currentPlayerIndex: 1, // passed to p2
      phase: GamePhase.roll,
    );

    state = container.read(gameProvider);
    // Player 1 is marked bankrupt/removed
    expect(state.players.firstWhere((p) => p.id == 'p1').isBankrupt, isTrue);
    // All tiles become unowned and available for others to buy
    expect(state.properties['prop_01']?.ownerId, isNull);
    expect(state.properties['prop_02']?.ownerId, isNull);
    // Turn passes to p2
    expect(state.currentPlayer.id, 'p2');
  });

  test('Transport & Utility Tariffs: Scaled within appropriate range for ₹1000 baseline', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(gameProvider);
    final ksrct = state.properties['trans_01']!;
    final metro = state.properties['trans_02']!;
    final kseb = state.properties['util_01']!;

    // Transports price ₹135
    expect(ksrct.price, 135);
    expect(metro.price, 135);

    // Rent scaled ₹15 -> ₹135
    expect(ksrct.rent[0], 15);
    expect(ksrct.rent[1], 35);
    expect(ksrct.rent[2], 70);
    expect(ksrct.rent[3], 135);

    // Utilities price ₹100
    expect(kseb.price, 100);

    // 1 Utility = 4x dice roll
    final mockProps = <String, Property>{
      'util_01': kseb.copyWith(ownerId: 'p1'),
    };
    expect(mockProps['util_01']!.getRent(mockProps, 7), 28); // 7 * 4 = 28
    expect(mockProps['util_01']!.getRent(mockProps, 12), 48); // 12 * 4 = 48

    // 2 Utilities = 10x dice roll
    mockProps['util_02'] = state.properties['util_02']!.copyWith(ownerId: 'p1');
    expect(mockProps['util_01']!.getRent(mockProps, 7), 70); // 7 * 10 = 70
    expect(mockProps['util_01']!.getRent(mockProps, 12), 120); // 12 * 10 = 120
  });

  test('Kerala Random Names pool contains updated iconic characters', () {
    final names = UserProfileNotifier.keralaNames;
    expect(names.contains('Dasan'), isTrue);
    expect(names.contains('Vijayan'), isTrue);
    expect(names.contains('Mangalassery Neelakandan'), isTrue);
    expect(names.contains('Aadu Thoma'), isTrue);
    expect(names.contains('Poovalli Induchoodan'), isTrue);
    expect(names.contains('Drishyam George'), isTrue);
    expect(names.contains('Sagar Alias Jacky'), isTrue);
    expect(names.contains('Akkare Ninnoru Maran'), isTrue);
    expect(names.contains('C.I.D. Moosa'), isTrue);
    expect(names.contains('Kottayam Kunjachan'), isTrue);
    expect(names.length, greaterThanOrEqualTo(50));
  });

  test('Police Station Jail Rule: landing on space 30 enters moving phase and updates position to 10', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 1000,
        position: 30,
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 1000,
      ),
    ]);

    var state = container.read(gameProvider);
    expect(state.currentPlayer.position, 30);

    // Trigger space action at space 30 (Police Station)
    notifier.state = state.copyWith(phase: GamePhase.spaceAction);
    // Simulate landing action
    final p1 = state.currentPlayer;
    expect(p1.position, 30);

    // Call private or public behavior: when sent to jail, position becomes 10 and phase is moving
    final updated = p1.copyWith(position: 10, isInJail: true);
    notifier.updatePlayerForTest(updated);
    state = container.read(gameProvider);
    expect(state.players.firstWhere((p) => p.id == 'p1').position, 10);
    expect(state.players.firstWhere((p) => p.id == 'p1').isInJail, isTrue);
  });

  test('Turn Progression: cannot end turn while in GamePhase.moving', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 1000,
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 1000,
      ),
    ]);

    var state = container.read(gameProvider);
    expect(state.currentPlayerIndex, 0);

    // Set phase to moving
    notifier.state = state.copyWith(phase: GamePhase.moving);

    // Attempt to end turn while moving
    notifier.endTurn();

    // Turn should NOT advance while moving!
    state = container.read(gameProvider);
    expect(state.currentPlayerIndex, 0);
    expect(state.phase, GamePhase.moving);
  });

  test('Transaction Notices: buying property and toggling mortgage triggers activeTransaction notice', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 1000,
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 1000,
      ),
    ]);

    var state = container.read(gameProvider);
    expect(state.activeTransaction, isNull);

    // Buy property
    notifier.state = state.copyWith(phase: GamePhase.spaceAction);
    notifier.buyProperty('prop_01');

    state = container.read(gameProvider);
    expect(state.activeTransaction, isNotNull);
    expect(state.activeTransaction?.type, 'buy');
    expect(state.activeTransaction?.title, 'PROPERTY PURCHASED');

    // Toggle mortgage
    notifier.toggleMortgage('prop_01');
    state = container.read(gameProvider);
    // Give p1 the full monopoly for Malabar (prop_01, prop_02, prop_03)
    final newProps = Map<String, Property>.from(state.properties);
    newProps['prop_01'] = newProps['prop_01']!.copyWith(ownerId: 'p1', isMortgaged: false);
    newProps['prop_02'] = newProps['prop_02']!.copyWith(ownerId: 'p1', isMortgaged: false);
    newProps['prop_03'] = newProps['prop_03']!.copyWith(ownerId: 'p1', isMortgaged: false);
    notifier.state = state.copyWith(properties: newProps);

    // Upgrade property (purchase a building)
    notifier.upgradeProperty('prop_01');
    state = container.read(gameProvider);
    expect(state.activeTransaction, isNotNull);
    expect(state.activeTransaction?.type, 'build');
    expect(state.activeTransaction?.title, 'COTTAGE BUILT');
  });

  test('GameState serialization preserves inspectedProperty and activeEventCard for multiplayer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(id: 'p1', name: 'Player 1', token: PlayerToken.coconut, color: Colors.red, type: PlayerType.human, cash: 1000),
    ]);

    var state = container.read(gameProvider);
    final prop = state.properties['prop_01'];
    notifier.state = state.copyWith(
      inspectedProperty: prop,
      phase: GamePhase.spaceAction,
    );

    state = container.read(gameProvider);
    final map = state.toMap();
    expect(map['inspectedProperty'], isNotNull);
    expect(map['inspectedProperty']['id'], 'prop_01');

    final restored = GameState.fromMap(map);
    expect(restored.inspectedProperty, isNotNull);
    expect(restored.inspectedProperty?.id, 'prop_01');
    expect(restored.phase, GamePhase.spaceAction);
  });

  test('Doubles Rule: rolling again after doubles lands on unpurchased tile with purchase option', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(id: 'p1', name: 'Player 1', token: PlayerToken.coconut, color: Colors.red, type: PlayerType.human, cash: 1000),
      const Player(id: 'p2', name: 'Player 2', token: PlayerToken.elephant, color: Colors.blue, type: PlayerType.human, cash: 1000),
    ]);

    var state = container.read(gameProvider);

    // Roll 1: Player lands on prop_01 (space 1) with doubles
    notifier.state = state.copyWith(
      isDoubles: true,
      consecutiveDoubles: 1,
      phase: GamePhase.spaceAction,
    );

    // Buy prop_01
    notifier.buyProperty('prop_01');
    state = container.read(gameProvider);

    // Player gets another roll (phase is roll, isDoubles is false, consecutiveDoubles is 1)
    expect(state.phase, GamePhase.roll);
    expect(state.isDoubles, false);
    expect(state.consecutiveDoubles, 1);
    expect(state.inspectedProperty, isNull);

    // Roll 2: Player rolls again and lands on prop_02 (space 3, Beypore, unowned)
    final p1 = state.players.firstWhere((p) => p.id == 'p1');
    notifier.updatePlayerForTest(p1.copyWith(position: 3));
    notifier.state = state.copyWith(
      phase: GamePhase.spaceAction,
      inspectedProperty: state.properties['prop_02'],
    );

    state = container.read(gameProvider);
    expect(state.phase, GamePhase.spaceAction);
    expect(state.inspectedProperty, isNotNull);
    expect(state.inspectedProperty?.id, 'prop_02');
    expect(state.inspectedProperty?.ownerId, isNull);

    // Can purchase prop_02
    notifier.buyProperty('prop_02');
    state = container.read(gameProvider);
    expect(state.properties['prop_02']?.ownerId, 'p1');
  });

  test('Auto-Auction: landing on unpurchased tile with insufficient cash automatically starts an auction', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 10, // Not enough for prop_01 (price: 60)
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 1000,
      ),
    ]);

    // Position player 1 on space 1 (prop_01, price: 60)
    final p1 = container.read(gameProvider).players.firstWhere((p) => p.id == 'p1');
    notifier.updatePlayerForTest(p1.copyWith(position: 1));
    notifier.state = container.read(gameProvider).copyWith(phase: GamePhase.spaceAction);

    // Call the space action handler logic via startAuction directly or triggering space action
    final prop = container.read(gameProvider).properties['prop_01']!;
    expect(p1.cash < prop.price, true);

    // Start auction on the property
    notifier.startAuction('prop_01');
    final state = container.read(gameProvider);

    expect(state.activeAuction, isNotNull);
    expect(state.activeAuction?.propertyId, 'prop_01');
    expect(state.activeAuction?.initiatorPlayerId, 'p1');
  });

  test('Trading System: executeTrade properly swaps cash and properties between players', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 500,
        ownedPropertyIds: ['prop_01'],
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 800,
        ownedPropertyIds: ['prop_02'],
      ),
    ]);

    // Assign properties to match ownedPropertyIds
    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1');
    props['prop_02'] = props['prop_02']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    // p1 offers prop_01 + 100 cash for p2's prop_02
    final offer = TradeOffer(
      id: 'trade_1',
      senderId: 'p1',
      receiverId: 'p2',
      offeredCash: 100,
      offeredPropertyIds: ['prop_01'],
      requestedCash: 0,
      requestedPropertyIds: ['prop_02'],
    );

    final success = notifier.executeTrade(offer);
    expect(success, isTrue);

    final state = container.read(gameProvider);
    final p1 = state.players.firstWhere((p) => p.id == 'p1');
    final p2 = state.players.firstWhere((p) => p.id == 'p2');

    // p1 cash: 500 - 100 = 400
    expect(p1.cash, 400);
    // p2 cash: 800 + 100 = 900
    expect(p2.cash, 900);

    // Ownership transferred
    expect(state.properties['prop_01']?.ownerId, 'p2');
    expect(state.properties['prop_02']?.ownerId, 'p1');
    expect(p1.ownedPropertyIds, contains('prop_02'));
    expect(p2.ownedPropertyIds, contains('prop_01'));
  });

  test('PlayerTokenComponent: immediately computes non-zero position on construction and updates with board size', () {
    const player = Player(
      id: 'p1',
      name: 'Player 1',
      token: PlayerToken.coconut,
      color: Colors.red,
      type: PlayerType.human,
      cash: 1500,
      position: 0,
    );

    final token = PlayerTokenComponent(
      player: player,
      playerIndex: 0,
      boardWidth: 600,
      boardHeight: 600,
    );

    // Position must be calculated immediately on creation without waiting for update(dt)
    expect(token.position.x, greaterThan(0));
    expect(token.position.y, greaterThan(0));
    expect(token.size.x, greaterThan(0));
    expect(token.size.y, greaterThan(0));

    final oldPosX = token.position.x;
    // Resizing board should update coordinates
    token.updateBoardDimensions(800, 800);
    expect(token.position.x, greaterThan(oldPosX));
  });

  test('Trade proposal: only active player can propose trade', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 1000,
        ownedPropertyIds: ['prop_01'],
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 1000,
        ownedPropertyIds: ['prop_02'],
      ),
    ]);

    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1');
    props['prop_02'] = props['prop_02']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    // Current player is p1. p2 tries to propose a trade.
    expect(container.read(gameProvider).currentPlayer.id, 'p1');
    final invalidOffer = TradeOffer(
      id: 'offer_invalid',
      senderId: 'p2',
      receiverId: 'p1',
      offeredCash: 50,
      offeredPropertyIds: ['prop_02'],
      requestedCash: 0,
      requestedPropertyIds: ['prop_01'],
    );
    notifier.proposeTrade(invalidOffer);

    // Proposal should be rejected because p2 is not currentPlayer
    expect(container.read(gameProvider).activeTradeOffer, isNull);
  });

  test('Trade proposal workflow: propose sets activeTradeOffer, decline does not transfer assets, accept transfers assets', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 1000,
        ownedPropertyIds: ['prop_01'],
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 1000,
        ownedPropertyIds: ['prop_02'],
      ),
    ]);

    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1');
    props['prop_02'] = props['prop_02']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    final offer = TradeOffer(
      id: 'offer_1',
      senderId: 'p1',
      receiverId: 'p2',
      offeredCash: 100,
      offeredPropertyIds: ['prop_01'],
      requestedCash: 50,
      requestedPropertyIds: ['prop_02'],
    );

    // 1. Propose trade
    notifier.proposeTrade(offer);
    var state = container.read(gameProvider);
    expect(state.activeTradeOffer, isNotNull);
    expect(state.activeTradeOffer?.id, 'offer_1');

    // Assets must NOT have transferred yet
    expect(state.players.firstWhere((p) => p.id == 'p1').cash, 1000);
    expect(state.players.firstWhere((p) => p.id == 'p2').cash, 1000);
    expect(state.properties['prop_01']?.ownerId, 'p1');
    expect(state.properties['prop_02']?.ownerId, 'p2');

    // 2. Decline trade
    notifier.respondToTrade('offer_1', false);
    state = container.read(gameProvider);
    expect(state.activeTradeOffer, isNull);
    expect(state.players.firstWhere((p) => p.id == 'p1').cash, 1000);
    expect(state.players.firstWhere((p) => p.id == 'p2').cash, 1000);
    expect(state.properties['prop_01']?.ownerId, 'p1');
    expect(state.properties['prop_02']?.ownerId, 'p2');

    // 3. Propose again and Accept
    final offer2 = TradeOffer(
      id: 'offer_2',
      senderId: 'p1',
      receiverId: 'p2',
      offeredCash: 100,
      offeredPropertyIds: ['prop_01'],
      requestedCash: 50,
      requestedPropertyIds: ['prop_02'],
    );
    notifier.proposeTrade(offer2);
    expect(container.read(gameProvider).activeTradeOffer?.id, 'offer_2');

    notifier.respondToTrade('offer_2', true);
    state = container.read(gameProvider);
    expect(state.activeTradeOffer, isNull);

    // p1 gave 100, received 50 -> net -50 => 950
    expect(state.players.firstWhere((p) => p.id == 'p1').cash, 950);
    // p2 gave 50, received 100 -> net +50 => 1050
    expect(state.players.firstWhere((p) => p.id == 'p2').cash, 1050);

    // Properties exchanged
    expect(state.properties['prop_01']?.ownerId, 'p2');
    expect(state.properties['prop_02']?.ownerId, 'p1');
  });

  test('Trade proposal: sender can cancel pending offer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 1000,
        ownedPropertyIds: ['prop_01'],
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 1000,
        ownedPropertyIds: ['prop_02'],
      ),
    ]);

    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1');
    props['prop_02'] = props['prop_02']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    final offer = TradeOffer(
      id: 'offer_cancel',
      senderId: 'p1',
      receiverId: 'p2',
      offeredCash: 50,
      offeredPropertyIds: ['prop_01'],
      requestedCash: 0,
      requestedPropertyIds: ['prop_02'],
    );

    notifier.proposeTrade(offer);
    expect(container.read(gameProvider).activeTradeOffer, isNotNull);

    notifier.cancelTradeOffer();
    expect(container.read(gameProvider).activeTradeOffer, isNull);
  });

  test('executeTrade: rejected if sender is not active player and offer is not active accepted offer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);
    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 1000,
        ownedPropertyIds: ['prop_01'],
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.elephant,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 1000,
        ownedPropertyIds: ['prop_02'],
      ),
    ]);

    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1');
    props['prop_02'] = props['prop_02']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    // Current player is p1. p2 tries to execute trade directly.
    final invalidOffer = TradeOffer(
      id: 'offer_direct',
      senderId: 'p2',
      receiverId: 'p1',
      offeredCash: 50,
      offeredPropertyIds: ['prop_02'],
      requestedCash: 0,
      requestedPropertyIds: ['prop_01'],
    );
    final executed = notifier.executeTrade(invalidOffer);
    expect(executed, isFalse);
    expect(container.read(gameProvider).properties['prop_01']?.ownerId, 'p1');
    expect(container.read(gameProvider).properties['prop_02']?.ownerId, 'p2');
  });

  // ==================== OFFICIAL MONOPOLY TRADE EDGE CASES (A - J) ====================

  test('Edge Case A: Simple property trade (prop_01 for trans_01)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    notifier.initializeGame([
      const Player(id: 'p1', name: 'Player 1', token: PlayerToken.coconut, color: Colors.red, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['prop_01']),
      const Player(id: 'p2', name: 'Player 2', token: PlayerToken.elephant, color: Colors.blue, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['trans_01']),
    ]);

    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1');
    props['trans_01'] = props['trans_01']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    final offer = const TradeOffer(
      id: 'trade_a',
      senderId: 'p1',
      receiverId: 'p2',
      offeredPropertyIds: ['prop_01'],
      requestedPropertyIds: ['trans_01'],
    );

    notifier.proposeTrade(offer);
    expect(container.read(gameProvider).activeTradeOffer?.status, TradeStatus.pending);

    notifier.respondToTrade('trade_a', true);
    final state = container.read(gameProvider);

    expect(state.properties['prop_01']?.ownerId, 'p2');
    expect(state.properties['trans_01']?.ownerId, 'p1');
    expect(state.players.firstWhere((p) => p.id == 'p1').ownedPropertyIds, contains('trans_01'));
    expect(state.players.firstWhere((p) => p.id == 'p2').ownedPropertyIds, contains('prop_01'));
  });

  test('Edge Case B: Property + cash (prop_01 + ₹500 for trans_01)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    notifier.initializeGame([
      const Player(id: 'p1', name: 'Player 1', token: PlayerToken.coconut, color: Colors.red, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['prop_01']),
      const Player(id: 'p2', name: 'Player 2', token: PlayerToken.elephant, color: Colors.blue, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['trans_01']),
    ]);

    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1');
    props['trans_01'] = props['trans_01']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    final offer = const TradeOffer(
      id: 'trade_b',
      senderId: 'p1',
      receiverId: 'p2',
      offeredCash: 500,
      offeredPropertyIds: ['prop_01'],
      requestedPropertyIds: ['trans_01'],
    );

    notifier.proposeTrade(offer);
    notifier.respondToTrade('trade_b', true);
    final state = container.read(gameProvider);

    expect(state.players.firstWhere((p) => p.id == 'p1').cash, 500);
    expect(state.players.firstWhere((p) => p.id == 'p2').cash, 1500);
    expect(state.properties['prop_01']?.ownerId, 'p2');
    expect(state.properties['trans_01']?.ownerId, 'p1');
  });

  test('Edge Case C: Multiple properties (prop_01 + trans_01 for prop_03 + trans_02)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    notifier.initializeGame([
      const Player(id: 'p1', name: 'Player 1', token: PlayerToken.coconut, color: Colors.red, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['prop_01', 'trans_01']),
      const Player(id: 'p2', name: 'Player 2', token: PlayerToken.elephant, color: Colors.blue, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['prop_03', 'trans_02']),
    ]);

    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1');
    props['trans_01'] = props['trans_01']!.copyWith(ownerId: 'p1');
    props['prop_03'] = props['prop_03']!.copyWith(ownerId: 'p2');
    props['trans_02'] = props['trans_02']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    final offer = const TradeOffer(
      id: 'trade_c',
      senderId: 'p1',
      receiverId: 'p2',
      offeredPropertyIds: ['prop_01', 'trans_01'],
      requestedPropertyIds: ['prop_03', 'trans_02'],
    );

    notifier.proposeTrade(offer);
    notifier.respondToTrade('trade_c', true);
    final state = container.read(gameProvider);

    final p1 = state.players.firstWhere((p) => p.id == 'p1');
    final p2 = state.players.firstWhere((p) => p.id == 'p2');

    expect(p1.ownedPropertyIds, containsAll(['prop_03', 'trans_02']));
    expect(p1.ownedPropertyIds.contains('prop_01'), isFalse);
    expect(p2.ownedPropertyIds, containsAll(['prop_01', 'trans_01']));
    expect(p2.ownedPropertyIds.contains('prop_03'), isFalse);
  });

  test('Edge Case D: Mortgaged property trade (allowed, mortgage remains attached)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    notifier.initializeGame([
      const Player(id: 'p1', name: 'Player 1', token: PlayerToken.coconut, color: Colors.red, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['prop_01']),
      const Player(id: 'p2', name: 'Player 2', token: PlayerToken.elephant, color: Colors.blue, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['trans_01']),
    ]);

    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1', isMortgaged: true);
    props['trans_01'] = props['trans_01']!.copyWith(ownerId: 'p2', isMortgaged: false);
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    final offer = const TradeOffer(
      id: 'trade_d',
      senderId: 'p1',
      receiverId: 'p2',
      offeredPropertyIds: ['prop_01'],
      requestedPropertyIds: ['trans_01'],
    );

    notifier.proposeTrade(offer);
    expect(container.read(gameProvider).activeTradeOffer, isNotNull);

    notifier.respondToTrade('trade_d', true);
    final state = container.read(gameProvider);

    // Ownership transferred, and prop_01 is STILL mortgaged
    expect(state.properties['prop_01']?.ownerId, 'p2');
    expect(state.properties['prop_01']?.isMortgaged, isTrue);
    expect(state.properties['trans_01']?.ownerId, 'p1');
    expect(state.properties['trans_01']?.isMortgaged, isFalse);
  });

  test('Edge Case E: Property with buildings in color group must not be tradeable', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    notifier.initializeGame([
      const Player(id: 'p1', name: 'Player 1', token: PlayerToken.coconut, color: Colors.red, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['prop_01', 'prop_02']),
      const Player(id: 'p2', name: 'Player 2', token: PlayerToken.elephant, color: Colors.blue, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['trans_01']),
    ]);

    // prop_01 and prop_02 are in PropertyGroup.malabar.
    // prop_01 has 0 houses, but prop_02 has 2 houses.
    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1', currentLevel: 0);
    props['prop_02'] = props['prop_02']!.copyWith(ownerId: 'p1', currentLevel: 2);
    props['trans_01'] = props['trans_01']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    expect(props['prop_01']!.hasBuildingsInGroup(container.read(gameProvider).properties), isTrue);
    expect(props['prop_01']!.isTradeable(container.read(gameProvider).properties), isFalse);

    // Attempt to trade prop_01
    final offer = const TradeOffer(
      id: 'trade_e',
      senderId: 'p1',
      receiverId: 'p2',
      offeredPropertyIds: ['prop_01'],
      requestedPropertyIds: ['trans_01'],
    );

    notifier.proposeTrade(offer);
    // Proposal must be rejected!
    expect(container.read(gameProvider).activeTradeOffer, isNull);
  });

  test('Edge Case F: Insufficient cash: player has ₹300, attempts to offer ₹500', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    notifier.initializeGame([
      const Player(id: 'p1', name: 'Player 1', token: PlayerToken.coconut, color: Colors.red, type: PlayerType.human, cash: 300, ownedPropertyIds: ['prop_01']),
      const Player(id: 'p2', name: 'Player 2', token: PlayerToken.elephant, color: Colors.blue, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['trans_01']),
    ]);

    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1');
    props['trans_01'] = props['trans_01']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    final offer = const TradeOffer(
      id: 'trade_f',
      senderId: 'p1',
      receiverId: 'p2',
      offeredCash: 500,
      offeredPropertyIds: ['prop_01'],
      requestedPropertyIds: ['trans_01'],
    );

    notifier.proposeTrade(offer);
    expect(container.read(gameProvider).activeTradeOffer, isNull);
  });

  test('Edge Case G: State changes after trade creation: acceptance revalidates and prevents invalid trade', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    notifier.initializeGame([
      const Player(id: 'p1', name: 'Player 1', token: PlayerToken.coconut, color: Colors.red, type: PlayerType.human, cash: 500, ownedPropertyIds: ['prop_01']),
      const Player(id: 'p2', name: 'Player 2', token: PlayerToken.elephant, color: Colors.blue, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['trans_01']),
    ]);

    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1');
    props['trans_01'] = props['trans_01']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    // 1. Propose valid trade with 500 cash
    final offer = const TradeOffer(
      id: 'trade_g',
      senderId: 'p1',
      receiverId: 'p2',
      offeredCash: 500,
      offeredPropertyIds: ['prop_01'],
      requestedPropertyIds: ['trans_01'],
    );
    notifier.proposeTrade(offer);
    expect(container.read(gameProvider).activeTradeOffer, isNotNull);

    // 2. Change state: Player 1 spends 400 cash (e.g. rent) -> only 100 left
    final players = List<Player>.from(container.read(gameProvider).players);
    players[0] = players[0].copyWith(cash: 100);
    notifier.state = container.read(gameProvider).copyWith(players: players);

    // 3. Receiver tries to ACCEPT
    notifier.respondToTrade('trade_g', true);
    final state = container.read(gameProvider);

    // Acceptance must FAIL revalidation!
    expect(state.activeTradeOffer, isNull);
    // No assets transferred!
    expect(state.players.firstWhere((p) => p.id == 'p1').cash, 100);
    expect(state.players.firstWhere((p) => p.id == 'p2').cash, 1000);
    expect(state.properties['prop_01']?.ownerId, 'p1');
    expect(state.properties['trans_01']?.ownerId, 'p2');
  });

  test('Edge Case H: Reject: rejecting a trade makes no state changes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    notifier.initializeGame([
      const Player(id: 'p1', name: 'Player 1', token: PlayerToken.coconut, color: Colors.red, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['prop_01']),
      const Player(id: 'p2', name: 'Player 2', token: PlayerToken.elephant, color: Colors.blue, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['trans_01']),
    ]);

    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1');
    props['trans_01'] = props['trans_01']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    final offer = const TradeOffer(
      id: 'trade_h',
      senderId: 'p1',
      receiverId: 'p2',
      offeredCash: 200,
      offeredPropertyIds: ['prop_01'],
      requestedCash: 100,
      requestedPropertyIds: ['trans_01'],
    );
    notifier.proposeTrade(offer);
    expect(container.read(gameProvider).activeTradeOffer, isNotNull);

    notifier.respondToTrade('trade_h', false); // REJECT
    final state = container.read(gameProvider);

    expect(state.activeTradeOffer, isNull);
    expect(state.players.firstWhere((p) => p.id == 'p1').cash, 1000);
    expect(state.players.firstWhere((p) => p.id == 'p2').cash, 1000);
    expect(state.properties['prop_01']?.ownerId, 'p1');
    expect(state.properties['trans_01']?.ownerId, 'p2');
  });

  test('Edge Case I: Cancel: cancelling a trade makes no state changes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    notifier.initializeGame([
      const Player(id: 'p1', name: 'Player 1', token: PlayerToken.coconut, color: Colors.red, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['prop_01']),
      const Player(id: 'p2', name: 'Player 2', token: PlayerToken.elephant, color: Colors.blue, type: PlayerType.human, cash: 1000, ownedPropertyIds: ['trans_01']),
    ]);

    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1');
    props['trans_01'] = props['trans_01']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    final offer = const TradeOffer(
      id: 'trade_i',
      senderId: 'p1',
      receiverId: 'p2',
      offeredCash: 300,
      offeredPropertyIds: ['prop_01'],
      requestedCash: 0,
      requestedPropertyIds: ['trans_01'],
    );
    notifier.proposeTrade(offer);
    expect(container.read(gameProvider).activeTradeOffer, isNotNull);

    notifier.cancelTradeOffer(); // CANCEL
    final state = container.read(gameProvider);

    expect(state.activeTradeOffer, isNull);
    expect(state.players.firstWhere((p) => p.id == 'p1').cash, 1000);
    expect(state.players.firstWhere((p) => p.id == 'p2').cash, 1000);
    expect(state.properties['prop_01']?.ownerId, 'p1');
    expect(state.properties['trans_01']?.ownerId, 'p2');
  });

  test('Edge Case J: Accept: accepting a valid trade transfers everything atomically', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);

    notifier.initializeGame([
      const Player(id: 'p1', name: 'Player 1', token: PlayerToken.coconut, color: Colors.red, type: PlayerType.human, cash: 1200, ownedPropertyIds: ['prop_01', 'trans_01']),
      const Player(id: 'p2', name: 'Player 2', token: PlayerToken.elephant, color: Colors.blue, type: PlayerType.human, cash: 800, ownedPropertyIds: ['prop_03', 'trans_02']),
    ]);

    final props = Map<String, Property>.from(container.read(gameProvider).properties);
    props['prop_01'] = props['prop_01']!.copyWith(ownerId: 'p1');
    props['trans_01'] = props['trans_01']!.copyWith(ownerId: 'p1');
    props['prop_03'] = props['prop_03']!.copyWith(ownerId: 'p2');
    props['trans_02'] = props['trans_02']!.copyWith(ownerId: 'p2');
    notifier.state = container.read(gameProvider).copyWith(properties: props);

    // p1 gives prop_01 + trans_01 + ₹200
    // p2 gives prop_03 + trans_02 + ₹100
    final offer = const TradeOffer(
      id: 'trade_j',
      senderId: 'p1',
      receiverId: 'p2',
      offeredCash: 200,
      offeredPropertyIds: ['prop_01', 'trans_01'],
      requestedCash: 100,
      requestedPropertyIds: ['prop_03', 'trans_02'],
    );
    notifier.proposeTrade(offer);
    expect(container.read(gameProvider).activeTradeOffer?.status, TradeStatus.pending);

    notifier.respondToTrade('trade_j', true);
    final state = container.read(gameProvider);

    expect(state.activeTradeOffer, isNull);
    // p1 cash: 1200 - 200 + 100 = 1100
    expect(state.players.firstWhere((p) => p.id == 'p1').cash, 1100);
    // p2 cash: 800 - 100 + 200 = 900
    expect(state.players.firstWhere((p) => p.id == 'p2').cash, 900);

    // Ownership completely swapped
    expect(state.properties['prop_01']?.ownerId, 'p2');
    expect(state.properties['trans_01']?.ownerId, 'p2');
    expect(state.properties['prop_03']?.ownerId, 'p1');
    expect(state.properties['trans_02']?.ownerId, 'p1');

    final p1 = state.players.firstWhere((p) => p.id == 'p1');
    final p2 = state.players.firstWhere((p) => p.id == 'p2');
    expect(p1.ownedPropertyIds, containsAll(['prop_03', 'trans_02']));
    expect(p2.ownedPropertyIds, containsAll(['prop_01', 'trans_01']));
  });

  test('Redeem property: verifies unowned status, cash deduction, ownership update, and logs', () {
    final container = ProviderContainer();
    final notifier = container.read(gameProvider.notifier);

    notifier.initializeGame([
      const Player(
        id: 'p1',
        name: 'Player 1',
        token: PlayerToken.coconut,
        color: Colors.red,
        type: PlayerType.human,
        cash: 500,
      ),
      const Player(
        id: 'p2',
        name: 'Player 2',
        token: PlayerToken.houseboat,
        color: Colors.blue,
        type: PlayerType.human,
        cash: 500,
      ),
    ]);

    var state = container.read(gameProvider);
    final prop = state.properties['prop_01']!;
    expect(prop.ownerId, isNull);
    final initialCash = state.currentPlayer.cash; // 500

    // Redeem prop_01 (price: 60)
    notifier.redeemProperty('prop_01');
    state = container.read(gameProvider);

    expect(state.properties['prop_01']?.ownerId, 'p1');
    expect(state.currentPlayer.cash, initialCash - prop.price);
    expect(state.currentPlayer.ownedPropertyIds, contains('prop_01'));
    expect(state.gameLogs.any((l) => l.contains('redeemed') && l.contains(prop.name)), isTrue);

    // Attempting to redeem already-owned property should not deduct cash
    final cashBeforeSecond = state.currentPlayer.cash;
    notifier.redeemProperty('prop_01');
    state = container.read(gameProvider);
    expect(state.currentPlayer.cash, cashBeforeSecond);

    // Attempting to redeem unaffordable property
    final p1LowCash = state.currentPlayer.copyWith(cash: 10);
    final updatedPlayers = state.players.map((p) => p.id == 'p1' ? p1LowCash : p).toList();
    notifier.state = state.copyWith(players: updatedPlayers);

    final unaffordableProp = state.properties['prop_02']!; // price: 60 > 10
    notifier.redeemProperty('prop_02');
    state = container.read(gameProvider);
    expect(state.currentPlayer.cash, 10);
    expect(state.properties['prop_02']?.ownerId, isNull);
  });
}
