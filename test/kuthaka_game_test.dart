import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuthaka/game/kuthaka_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('KuthakaGame lifecycle: pauses engine when idle to eliminate 3D GPU usage', (tester) async {
    late KuthakaGame game;

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, child) {
            game = KuthakaGame(ref);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(game.paused, isFalse);

    // Run update steps until idle frames elapse
    for (int i = 0; i < 20; i++) {
      game.update(1 / 60);
    }

    // Engine should now be paused (0% idle GPU usage)
    expect(game.paused, isTrue);

    // Waking the engine resumes execution
    game.wakeEngine(frames: 5);
    expect(game.paused, isFalse);

    // Running frames until settling should pause again
    for (int i = 0; i < 10; i++) {
      game.update(1 / 60);
    }
    expect(game.paused, isTrue);
  });
}
