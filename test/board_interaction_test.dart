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

  testWidgets('Complete Pipeline: Build, Mortgage, Redeem, Sell, Mode-Switching, and Board Tile Taps', (WidgetTester tester) async {
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

    // Setup properties:
    // Malabar group: prop_01 (lvl 1), prop_02 (lvl 0), prop_03 (lvl 0) owned by p1
    // prop_04 (mortgaged) owned by p1
    // prop_05 (unmortgaged, no buildings) owned by p1
    final state = container.read(gameProvider);
    final newProps = Map<String, Property>.from(state.properties);
    newProps['prop_01'] = state.properties['prop_01']!.copyWith(ownerId: 'p1', currentLevel: 1);
    newProps['prop_02'] = state.properties['prop_02']!.copyWith(ownerId: 'p1', currentLevel: 0);
    newProps['prop_03'] = state.properties['prop_03']!.copyWith(ownerId: 'p1', currentLevel: 0);
    newProps['prop_04'] = state.properties['prop_04']!.copyWith(ownerId: 'p1', isMortgaged: true);
    newProps['prop_05'] = state.properties['prop_05']!.copyWith(ownerId: 'p1', isMortgaged: false);

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
    final board = game.board!;

    // ==========================================
    // 1. BUILD MODE
    // ==========================================
    await tester.tap(find.text('Build'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('BUILD MODE'), findsOneWidget);
    // prop_01 is level 1, so even-building requires prop_02 & prop_03 to be built first
    expect(game.highlightedPropertyIds.contains('prop_02'), isTrue);
    expect(game.highlightedPropertyIds.contains('prop_03'), isTrue);
    expect(game.highlightedPropertyIds.contains('prop_01'), isFalse);

    // Tap tile for prop_02 (index 3)
    final tile2Center = board.getTileCenter(3);
    final localCanvasPos2 = Offset(board.position.x + tile2Center.dx, board.position.y + tile2Center.dy);
    game.handleBoardTap(localCanvasPos2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify prop_02 upgraded to level 1
    expect(container.read(gameProvider).properties['prop_02']!.currentLevel, 1);

    // ==========================================
    // 2. MODE SWITCHING: Build -> Mortgage
    // ==========================================
    await tester.tap(find.text('Mortgage'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('BUILD MODE'), findsNothing);
    expect(find.text('MORTGAGE MODE'), findsOneWidget);
    // prop_05 is eligible to mortgage. prop_04 is already mortgaged.
    // prop_01/02/03 have buildings, so they cannot be mortgaged.
    expect(game.highlightedPropertyIds.contains('prop_05'), isTrue);
    expect(game.highlightedPropertyIds.contains('prop_04'), isFalse);
    expect(game.highlightedPropertyIds.contains('prop_01'), isFalse);

    // Tap tile for prop_05 (index 9)
    final tile5Center = board.getTileCenter(9);
    final localCanvasPos5 = Offset(board.position.x + tile5Center.dx, board.position.y + tile5Center.dy);
    game.handleBoardTap(localCanvasPos5);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify prop_05 mortgaged
    expect(container.read(gameProvider).properties['prop_05']!.isMortgaged, isTrue);

    // ==========================================
    // 3. MODE SWITCHING: Mortgage -> Redeem
    // ==========================================
    await tester.tap(find.text('Redeem'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MORTGAGE MODE'), findsNothing);
    expect(find.text('REDEEM MODE'), findsOneWidget);
    // prop_04 and prop_05 are both mortgaged now!
    expect(game.highlightedPropertyIds.contains('prop_04'), isTrue);
    expect(game.highlightedPropertyIds.contains('prop_05'), isTrue);

    // Tap tile for prop_04 (index 8)
    final tile4Center = board.getTileCenter(8);
    final localCanvasPos4 = Offset(board.position.x + tile4Center.dx, board.position.y + tile4Center.dy);
    game.handleBoardTap(localCanvasPos4);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify prop_04 unmortgaged
    expect(container.read(gameProvider).properties['prop_04']!.isMortgaged, isFalse);
    // Only prop_05 remains mortgaged
    expect(game.highlightedPropertyIds.contains('prop_05'), isTrue);
    expect(game.highlightedPropertyIds.contains('prop_04'), isFalse);

    // ==========================================
    // 4. MODE SWITCHING: Redeem -> Sell
    // ==========================================
    await tester.tap(find.text('Sell'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('REDEEM MODE'), findsNothing);
    expect(find.text('SELL BUILDINGS'), findsOneWidget);
    // prop_01 and prop_02 both have level 1 buildings
    expect(game.highlightedPropertyIds.contains('prop_01'), isTrue);
    expect(game.highlightedPropertyIds.contains('prop_02'), isTrue);

    // Tap tile for prop_01 (index 1) to sell building
    final tile1Center = board.getTileCenter(1);
    final localCanvasPos1 = Offset(board.position.x + tile1Center.dx, board.position.y + tile1Center.dy);
    game.handleBoardTap(localCanvasPos1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify prop_01 downgraded from 1 to 0
    expect(container.read(gameProvider).properties['prop_01']!.currentLevel, 0);

    // ==========================================
    // 5. CLOSE MODE
    // ==========================================
    await tester.tap(find.text('CLOSE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('SELL BUILDINGS'), findsNothing);
    expect(game.highlightedPropertyIds.isEmpty, isTrue);
    expect(board.highlightedPropertyIds.isEmpty, isTrue);
    expect(game.onPropertyTappedCustom, isNull);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}
