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

  int get netWorth => 150000 + (totalXp * 1500);
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
        if (client.auth.currentUser == null) {
          try {
            await client.auth.signInAnonymously();
          } catch (authErr) {
            debugPrint('[LeaderboardService] Anonymous sign-in attempt: $authErr');
          }
        }

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
        debugPrint('[LeaderboardService] Supabase fetch fallback: $e');
      }
    }

    return _fallbackKeralaTycoons;
  }

  static const List<KeralaTycoon> _fallbackKeralaTycoons = [
    KeralaTycoon(
      id: 'k1',
      displayName: 'Yusuff Ali',
      totalXp: 1250,
      level: 14,
      state: 'Thrissur',
      country: 'India',
      rank: 1,
    ),
    KeralaTycoon(
      id: 'k2',
      displayName: 'Ravi Pillai',
      totalXp: 980,
      level: 11,
      state: 'Kollam',
      country: 'India',
      rank: 2,
    ),
    KeralaTycoon(
      id: 'k3',
      displayName: 'Syed',
      totalXp: 750,
      level: 9,
      state: 'Malappuram',
      country: 'India',
      rank: 3,
    ),
    KeralaTycoon(
      id: 'k4',
      displayName: 'Afi',
      totalXp: 620,
      level: 8,
      state: 'Kozhikode',
      country: 'India',
      rank: 4,
    ),
    KeralaTycoon(
      id: 'k5',
      displayName: 'Zeeshan',
      totalXp: 540,
      level: 7,
      state: 'Kannur',
      country: 'India',
      rank: 5,
    ),
    KeralaTycoon(
      id: 'k6',
      displayName: 'Dulquer',
      totalXp: 490,
      level: 6,
      state: 'Kochi',
      country: 'India',
      rank: 6,
    ),
    KeralaTycoon(
      id: 'k7',
      displayName: 'Abdul Khader',
      totalXp: 410,
      level: 5,
      state: 'Alappuzha',
      country: 'India',
      rank: 7,
    ),
    KeralaTycoon(
      id: 'k8',
      displayName: 'Rash Pk',
      totalXp: 350,
      level: 4,
      state: 'Wayanad',
      country: 'India',
      rank: 8,
    ),
  ];
}
