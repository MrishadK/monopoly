import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  print('Testing Supabase URL: $supabaseUrl');

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);
  
  final channel = client.channel('test_broadcast');
  
  channel.onBroadcast(event: 'ping', callback: (payload) {
    print('Received broadcast: $payload');
  });
  
  channel.subscribe((status, [error]) async {
    print('Channel status: $status');
    if (status == RealtimeSubscribeStatus.subscribed) {
      print('Sending broadcast message...');
      await channel.sendBroadcastMessage(event: 'ping', payload: {'hello': 'world'});
      await Future.delayed(Duration(seconds: 2));
      exit(0);
    }
  });
  
  await Future.delayed(Duration(seconds: 10));
  print('Timeout waiting for broadcast');
  exit(1);
}
