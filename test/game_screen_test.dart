import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuthaka/models/player.dart';
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

    // Verify all 5 navigation dock buttons
    expect(find.text('Properties'), findsOneWidget);
    expect(find.text('Trade'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Emoji'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify dice tray and roll button
    expect(find.byIcon(Icons.casino_rounded), findsWidgets);
    expect(find.text('Player 1 • ROLL'), findsOneWidget);

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

    // Verify AI thinking indicator and dock options
    expect(find.text('Aadu Thoma (AI) is thinking...'), findsOneWidget);
    expect(find.text('Properties'), findsOneWidget);
    expect(find.text('Trade'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}

