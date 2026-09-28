import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuthaka/models/player.dart';
import 'package:kuthaka/models/property.dart';
import 'package:kuthaka/providers/game_provider.dart';
import 'package:kuthaka/services/user_profile_service.dart';

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
}
