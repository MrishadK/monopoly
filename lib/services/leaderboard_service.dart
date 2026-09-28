import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KeralaTycoon {
  final String id;
  final String displayName;
  final int totalXp;
  final int level;
  final String state;
  final String country;
  final int rank;

  const KeralaTycoon({
    required this.id,
    required this.displayName,
    required this.totalXp,
    required this.level,
    required this.state,
    required this.country,
    required this.rank,
  });

  int get netWorth => 1000 + (totalXp * 15);
}

final leaderboardServiceProvider = Provider((ref) => LeaderboardService());

final leaderboardFutureProvider = FutureProvider.autoDispose<List<KeralaTycoon>>((ref) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.fetchLeaderboard();
});

class LeaderboardService {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<List<KeralaTycoon>> fetchLeaderboard() async {
    final client = _client;
    if (client != null) {
      try {


        final data = await client
            .from('user_xp')
            .select('id, display_name, total_xp, level, state, country')
            .order('total_xp', ascending: false)
            .limit(25);

        final list = data as List<dynamic>;
        if (list.isNotEmpty) {
          return list.asMap().entries.map((entry) {
            final idx = entry.key;
            final map = Map<String, dynamic>.from(entry.value as Map);
            final rawName = map['display_name']?.toString().trim();
            final name = (rawName != null && rawName.isNotEmpty && rawName != '__')
                ? rawName
                : 'Kuthaka Tycoon';

            return KeralaTycoon(
              id: map['id']?.toString() ?? '$idx',
              displayName: name,
              totalXp: (map['total_xp'] is int) ? map['total_xp'] as int : 0,
              level: (map['level'] is int) ? map['level'] as int : 1,
              state: map['state']?.toString() ?? 'Kerala',
              country: map['country']?.toString() ?? 'India',
              rank: idx + 1,
            );
          }).toList();
        }
      } catch (e) {
        debugPrint('[LeaderboardService] Leaderboard fetch: $e');
      }
    }

    return const <KeralaTycoon>[];
  }

  Future<void> awardXp({
    required String playerName,
    required int xpToAdd,
    bool isWinner = false,
  }) async {
    final client = _client;
    if (client == null) return;
    try {
      final res = await client
          .from('user_xp')
          .select('id, total_xp, level, games_played, games_won')
          .eq('display_name', playerName)
          .maybeSingle();

      if (res != null) {
        final currentXp = (res['total_xp'] is int) ? res['total_xp'] as int : 0;
        final newXp = currentXp + xpToAdd;
        final newLevel = (newXp / 100).floor() + 1;
        final gamesPlayed = (res['games_played'] is int) ? (res['games_played'] as int) + 1 : 1;
        final gamesWon = (res['games_won'] is int)
            ? (res['games_won'] as int) + (isWinner ? 1 : 0)
            : (isWinner ? 1 : 0);

        await client.from('user_xp').update({
          'total_xp': newXp,
          'level': newLevel,
          'games_played': gamesPlayed,
          'games_won': gamesWon,
          'last_updated': DateTime.now().toIso8601String(),
        }).eq('id', res['id']);
      } else {
        await client.from('user_xp').insert({
          'display_name': playerName,
          'total_xp': xpToAdd,
          'level': (xpToAdd / 100).floor() + 1,
          'games_played': 1,
          'games_won': isWinner ? 1 : 0,
          'state': 'Kerala',
          'country': 'India',
        });
      }
    } catch (e) {
      debugPrint('[LeaderboardService] awardXp error: $e');
    }
  }
}
