import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Supabase Realtime bidirectional broadcast test', () async {
    const url = 'https://nudbsagwyhaslaajwvoh.supabase.co';
    const key = 'sb_publishable_DRoKSQBEUW4c4DiTiVAeYw_kw09KLl0';

    final hostClient = SupabaseClient(url, key);
    final guestClient = SupabaseClient(url, key);

    final testRoomId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    print('Testing Room: $testRoomId');

    final guestReceivedCompleter = Completer<Map<String, dynamic>>();
    final hostReceivedCompleter = Completer<Map<String, dynamic>>();

    // Host setup
    final hostChannel = hostClient.channel('kuthaka_room_$testRoomId');
    hostChannel.onBroadcast(event: 'player_action', callback: (payload) {
      print('[HOST] Received player_action: $payload');
      if (!hostReceivedCompleter.isCompleted) hostReceivedCompleter.complete(payload);
    });

    // Guest setup
    final guestChannel = guestClient.channel('kuthaka_room_$testRoomId');
    guestChannel.onBroadcast(event: 'state_sync', callback: (payload) {
      print('[GUEST] Received state_sync: $payload');
      if (!guestReceivedCompleter.isCompleted) guestReceivedCompleter.complete(payload);
    });

    final hostSubCompleter = Completer<void>();
    final guestSubCompleter = Completer<void>();

    hostChannel.subscribe((status, [error]) {
      print('[HOST] Channel status: $status (error: $error)');
      if (status == RealtimeSubscribeStatus.subscribed) {
        if (!hostSubCompleter.isCompleted) hostSubCompleter.complete();
      }
    });

    guestChannel.subscribe((status, [error]) {
      print('[GUEST] Channel status: $status (error: $error)');
      if (status == RealtimeSubscribeStatus.subscribed) {
        if (!guestSubCompleter.isCompleted) guestSubCompleter.complete();
      }
    });

    print('Waiting for channels to subscribe...');
    await Future.wait([hostSubCompleter.future, guestSubCompleter.future]).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        print('TIMEOUT subscribing!');
        return [];
      },
    );

    print('Channels subscribed! Sending test messages...');

    // 1. Host sends state_sync
    print('[HOST] Sending state_sync...');
    final res1 = await hostChannel.sendBroadcastMessage(
      event: 'state_sync',
      payload: {'turn': 1, 'phase': 'roll'},
    );
    print('[HOST] send state_sync response: $res1');

    // 2. Guest sends player_action using our new payload schema
    print('[GUEST] Sending player_action...');
    final res2 = await guestChannel.sendBroadcastMessage(
      event: 'player_action',
      payload: {
        'action': 'roll_dice',
        'actionType': 'roll_dice',
        'data': {'playerId': 'p2'},
      },
    );
    print('[GUEST] send player_action response: $res2');

    final receivedState = await guestReceivedCompleter.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => {},
    );
    final receivedAction = await hostReceivedCompleter.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => {},
    );

    print('Guest received state_sync: $receivedState');
    print('Host received player_action: $receivedAction');

    expect(receivedState.isNotEmpty, isTrue, reason: 'Guest should receive state_sync');
    expect(receivedAction.isNotEmpty, isTrue, reason: 'Host should receive player_action');

    final extractedAction = (receivedAction['action'] ?? receivedAction['actionType'] ?? receivedAction['type']) as String?;
    print('Extracted Action: $extractedAction');
    expect(extractedAction, equals('roll_dice'), reason: 'Action must be properly extracted as roll_dice');

    await hostChannel.unsubscribe();
    await guestChannel.unsubscribe();
  }, timeout: const Timeout(Duration(seconds: 35)));
}
