import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/leaderboard_service.dart';
import '../../services/user_profile_service.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardFutureProvider);
    final myProfile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          'KERALA TYCOONS',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A)),
            tooltip: 'Refresh Rankings',
            onPressed: () => ref.invalidate(leaderboardFutureProvider),
          ),
        ],
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF047857)),
              SizedBox(height: 16),
              Text(
                'Connecting to Live Leaderboard...',
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                Text(
                  'Failed to fetch live standings',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => ref.invalidate(leaderboardFutureProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (tycoons) {
          return Column(
            children: [
              // Realtime Backend Sync Status Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFECFDF5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Official Kerala Championship • Live',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF065F46),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Local User Rank Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: myProfile.color,
                      child: Icon(myProfile.toPlayer().tokenIcon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                myProfile.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'YOU',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Active Challenger',
                            style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹1,000',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF047857),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Starting Balance',
                          style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Standings Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'TOP PROPERTY MAGNATES',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'TOTAL XP',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Standings List
              Expanded(
                child: tycoons.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 40,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Season 1 Leaderboard Open!',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No champions ranked yet. Play matches, acquire properties, and win games to claim #1 in Kerala!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF64748B),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: tycoons.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tycoon = tycoons[index];
                          return _buildTycoonTile(tycoon, index + 1);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTycoonTile(KeralaTycoon tycoon, int rank) {
    Widget rankBadge;
    Color tileBorderColor = const Color(0xFFE2E8F0);
    Color tileBg = Colors.white;

    if (rank == 1) {
      rankBadge = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBEB),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 20),
      );
      tileBorderColor = const Color(0xFFFDE68A);
      tileBg = const Color(0xFFFFFDF5);
    } else if (rank == 2) {
      rankBadge = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.military_tech_rounded, color: Color(0xFF64748B), size: 20),
      );
      tileBorderColor = const Color(0xFFCBD5E1);
    } else if (rank == 3) {
      rankBadge = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF7ED),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.shield_rounded, color: Color(0xFFB45309), size: 18),
      );
      tileBorderColor = const Color(0xFFFED7AA);
    } else {
      rankBadge = Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$rank',
          style: GoogleFonts.outfit(
            color: const Color(0xFF475569),
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tileBorderColor),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          rankBadge,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tycoon.displayName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Lvl ${tycoon.level}',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3730A3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 2),
                    Text(
                      tycoon.state,
                      style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tycoon.totalXp} XP',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              Text(
                '₹${tycoon.netWorth}',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF047857),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
