import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuthaka/models/player.dart';
import 'package:kuthaka/models/property.dart';
import 'package:kuthaka/providers/game_provider.dart';
import 'package:kuthaka/ui/screens/game_screen.dart';
import 'package:kuthaka/ui/overlays/hud_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HudOverlay renders full screen and all controls are visible during Human turn', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();

    final human = const Player(
      id: 'p1',
      name: 'Player 1',
      token: PlayerToken.coconut,
      color: Colors.red,
      type: PlayerType.human,
      cash: 1000,
    );
    const bot = Player(
      id: 'p2',
      name: 'Aadu Thoma',
      type: PlayerType.ai,
      token: PlayerToken.elephant,
      color: Colors.blue,
      cash: 1000,
    );

    container.read(gameProvider.notifier).initializeGame([human, bot]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GameScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final hudFinder = find.byType(HudOverlay);
    expect(hudFinder, findsOneWidget);
    final size = tester.getSize(hudFinder);
    expect(size.width, greaterThan(500));
    expect(size.height, greaterThan(1000));

    // Verify navigation dock buttons and action buttons
    expect(find.text('Properties'), findsOneWidget);
    expect(find.text('Redeem'), findsOneWidget);
    expect(find.text('Trade'), findsOneWidget);
    expect(find.text('Build'), findsOneWidget);
    expect(find.text('Mortgage'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Detail'), findsNothing);
    expect(find.text('Buy'), findsNothing);
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Chat / Emoji'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify dice tray and roll button
    expect(find.byIcon(Icons.casino_rounded), findsWidgets);
    expect(find.text('ROLL DICE'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('HudOverlay renders full screen and shows AI thinking indicator during AI turn', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();

    final human = const Player(
      id: 'p1',
      name: 'Player 1',
      token: PlayerToken.coconut,
      color: Colors.red,
      type: PlayerType.human,
      cash: 1000,
    );
    const bot = Player(
      id: 'p2',
      name: 'Aadu Thoma',
      type: PlayerType.ai,
      token: PlayerToken.elephant,
      color: Colors.blue,
      cash: 1000,
    );

    // Bot starts first
    container.read(gameProvider.notifier).initializeGame([bot, human]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GameScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final hudFinder = find.byType(HudOverlay);
    expect(hudFinder, findsOneWidget);
    final size = tester.getSize(hudFinder);
    expect(size.width, greaterThan(500));
    expect(size.height, greaterThan(1000));

    // Verify AI turn indicator and dock options
    expect(find.text("Aadu Thoma's turn"), findsOneWidget);
    expect(find.text('Properties'), findsOneWidget);
    expect(find.text('Trade'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('HudOverlay action dock buttons activate Build, Mortgage, Sell, and Redeem action modes with instruction cards', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();

    final human = const Player(
      id: 'p1',
      name: 'Player 1',
      token: PlayerToken.coconut,
      color: Colors.red,
      type: PlayerType.human,
      cash: 2000,
    );
    const bot = Player(
      id: 'p2',
      name: 'Aadu Thoma',
      type: PlayerType.ai,
      token: PlayerToken.elephant,
      color: Colors.blue,
      cash: 1000,
    );

    container.read(gameProvider.notifier).initializeGame([human, bot]);

    // Give p1 a complete monopoly for Malabar (prop_01, prop_02, prop_03) and one mortgaged prop
    final state = container.read(gameProvider);
    final newProps = Map<String, Property>.from(state.properties);
    newProps['prop_01'] = state.properties['prop_01']!.copyWith(ownerId: 'p1', currentLevel: 1);
    newProps['prop_02'] = state.properties['prop_02']!.copyWith(ownerId: 'p1', currentLevel: 1);
    newProps['prop_03'] = state.properties['prop_03']!.copyWith(ownerId: 'p1', currentLevel: 1);
    newProps['prop_04'] = state.properties['prop_04']!.copyWith(ownerId: 'p1', isMortgaged: true);
    newProps['prop_05'] = state.properties['prop_05']!.copyWith(ownerId: 'p1', isMortgaged: false);

    // Apply properties to state
    container.read(gameProvider.notifier).state = state.copyWith(properties: newProps);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GameScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final hud = tester.widget<HudOverlay>(find.byType(HudOverlay));
    final game = hud.game;

    // 1. Test Build button
    await tester.tap(find.text('Build'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('BUILD MODE'), findsOneWidget);
    expect(find.text('CLOSE'), findsOneWidget);
    expect(game.highlightedPropertyIds.contains('prop_01'), isTrue);

    // Execute Build on prop_01
    game.onPropertyTappedCustom!(container.read(gameProvider).properties['prop_01']!);
    await tester.pump();
    expect(container.read(gameProvider).properties['prop_01']!.currentLevel, 2);

    // Close Build mode
    await tester.tap(find.text('CLOSE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('BUILD MODE'), findsNothing);
    expect(game.highlightedPropertyIds.isEmpty, isTrue);

    // 2. Test Mortgage button
    await tester.tap(find.text('Mortgage'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('MORTGAGE MODE'), findsOneWidget);
    expect(find.text('CLOSE'), findsOneWidget);
    expect(game.highlightedPropertyIds.contains('prop_05'), isTrue);

    // Execute Mortgage on prop_05
    game.onPropertyTappedCustom!(container.read(gameProvider).properties['prop_05']!);
    await tester.pump();
    expect(container.read(gameProvider).properties['prop_05']!.isMortgaged, isTrue);

    // 3. Test Mode Switching: Mortgage -> Redeem directly
    await tester.tap(find.text('Redeem'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('MORTGAGE MODE'), findsNothing);
    expect(find.text('REDEEM MODE'), findsOneWidget);
    expect(game.highlightedPropertyIds.contains('prop_04'), isTrue);

    // Execute Redeem on prop_04
    game.onPropertyTappedCustom!(container.read(gameProvider).properties['prop_04']!);
    await tester.pump();
    expect(container.read(gameProvider).properties['prop_04']!.isMortgaged, isFalse);

    // 4. Test Mode Switching: Redeem -> Sell directly
    await tester.tap(find.text('Sell'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('REDEEM MODE'), findsNothing);
    expect(find.text('SELL BUILDINGS'), findsOneWidget);
    expect(game.highlightedPropertyIds.contains('prop_01'), isTrue);

    // Execute Sell on prop_01 (had level 2, returns to level 1)
    game.onPropertyTappedCustom!(container.read(gameProvider).properties['prop_01']!);
    await tester.pump();
    expect(container.read(gameProvider).properties['prop_01']!.currentLevel, 1);

    // Close Sell mode
    await tester.tap(find.text('CLOSE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('SELL BUILDINGS'), findsNothing);
    expect(game.highlightedPropertyIds.isEmpty, isTrue);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}

