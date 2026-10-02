import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/leaderboard_service.dart';
import '../../services/user_profile_service.dart';
import '../../ui/theme/app_theme.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardFutureProvider);
    final myProfile = ref.watch(userProfileProvider);
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'KERALA TYCOONS',
          style: GoogleFonts.outfit(
            color: context.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.textPrimary),
            tooltip: 'Refresh Rankings',
            onPressed: () => ref.invalidate(leaderboardFutureProvider),
          ),
        ],
      ),
      body: leaderboardAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark),
              const SizedBox(height: 16),
              Text(
                'Connecting to Live Leaderboard...',
                style: GoogleFonts.outfit(color: context.textSecondary, fontWeight: FontWeight.bold),
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
                Icon(Icons.cloud_off_rounded, size: 48, color: context.textMuted),
                const SizedBox(height: 12),
                Text(
                  'Failed to fetch live standings',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: context.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark,
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
                color: context.emeraldBg,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: KuthakaColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Official Kerala Championship • Live',
                      style: GoogleFonts.outfit(
                        color: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldMuted,
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
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.borderColor),
                  boxShadow: context.subtleShadow,
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
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.cardAltColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'YOU',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Active Challenger',
                            style: GoogleFonts.outfit(color: context.textSecondary, fontSize: 12),
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
                            color: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Starting Balance',
                          style: GoogleFonts.outfit(color: context.textMuted, fontSize: 10),
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
                        color: context.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'TOTAL XP',
                      style: GoogleFonts.outfit(
                        color: context.textSecondary,
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
                                  color: context.goldBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: KuthakaColors.gold.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 40,
                                  color: KuthakaColors.gold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Season 1 Leaderboard Open!',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No champions ranked yet. Play matches, acquire properties, and win games to claim #1 in Kerala!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: context.textSecondary,
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
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tycoon = tycoons[index];
                          return _buildTycoonTile(context, tycoon, index + 1);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTycoonTile(BuildContext context, KeralaTycoon tycoon, int rank) {
    final isDark = context.isDark;
    Widget rankBadge;
    Color tileBorderColor = context.borderColor;
    Color tileBg = context.cardColor;

    if (rank == 1) {
      rankBadge = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: context.goldBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.workspace_premium_rounded, color: KuthakaColors.gold, size: 20),
      );
      tileBorderColor = KuthakaColors.gold.withValues(alpha: 0.5);
      tileBg = isDark ? const Color(0xFF252010) : const Color(0xFFFFFDF5);
    } else if (rank == 2) {
      rankBadge = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: context.cardAltColor,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.military_tech_rounded, color: context.textSecondary, size: 20),
      );
      tileBorderColor = isDark ? const Color(0xFF3A3A4A) : const Color(0xFFCBD5E1);
    } else if (rank == 3) {
      rankBadge = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3D2A0A) : const Color(0xFFFFF7ED),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.shield_rounded, color: KuthakaColors.goldMuted, size: 18),
      );
      tileBorderColor = KuthakaColors.goldDark.withValues(alpha: 0.4);
    } else {
      rankBadge = Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.cardAltColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$rank',
          style: GoogleFonts.outfit(
            color: context.textSecondary,
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
        boxShadow: context.subtleShadow,
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
                          color: context.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: context.azureBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Lvl ${tycoon.level}',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isDark ? KuthakaColors.azure : const Color(0xFF3730A3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 12, color: context.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      tycoon.state,
                      style: GoogleFonts.outfit(color: context.textSecondary, fontSize: 11),
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
                  color: context.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              Text(
                '₹${tycoon.netWorth}',
                style: GoogleFonts.outfit(
                  color: isDark ? KuthakaColors.emerald : KuthakaColors.emeraldDark,
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
