import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../../services/user_profile_service.dart';
import '../../services/multiplayer_service.dart';
import '../../models/player.dart';

// ==================== EMOJI REACTION STATE ====================

class EmojiReaction {
  final String emoji;
  final String playerName;

  const EmojiReaction({required this.emoji, required this.playerName});
}

class EmojiReactionNotifier extends Notifier<EmojiReaction?> {
  @override
  EmojiReaction? build() => null;

  void sendEmoji(String emoji, String playerName, dynamic multiplayerService) {
    state = EmojiReaction(emoji: emoji, playerName: playerName);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (state?.emoji == emoji) state = null;
    });
    multiplayerService.broadcastEmoji(emoji, playerName);
  }

  void receiveEmoji(String emoji, String playerName) {
    state = EmojiReaction(emoji: emoji, playerName: playerName);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (state?.emoji == emoji) state = null;
    });
  }
}

final emojiReactionProvider =
    NotifierProvider<EmojiReactionNotifier, EmojiReaction?>(() {
      return EmojiReactionNotifier();
    });

// ==================== FLOATING EMOJI DISPLAY (shown on board) ====================

class EmojiFloatingDisplay extends ConsumerWidget {
  const EmojiFloatingDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reaction = ref.watch(emojiReactionProvider);
    if (reaction == null) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 15,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reaction.emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 4),
            Text(
              reaction.playerName,
              style: GoogleFonts.outfit(
                color: const Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== EMOJI CHAT PANEL (shown via showDialog) ====================

class EmojiChatPanel extends ConsumerWidget {
  const EmojiChatPanel({super.key});

  static const List<String> _gameEmojis = [
    '😂',
    '😭',
    '🔥',
    '💀',
    '🎉',
    '😤',
    '🤑',
    '😱',
    '🤡',
    '💰',
    '🏠',
    '🎲',
    '👑',
    '🙏',
    '😈',
    '🤝',
    '💸',
    '🧠',
    '⚡',
    '🫡',
    '😎',
    '🥲',
    '💪',
    '🫣',
    '🎯',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final myProfile = ref.watch(userProfileProvider);
    final myLocalId = ref.watch(gameProvider.notifier).localPlayerId ?? myProfile.id;
    final myPlayer = gameState.players.firstWhere(
      (p) => p.id == myLocalId,
      orElse: () => gameState.players.firstWhere(
        (p) => p.type == PlayerType.human,
        orElse: () => gameState.currentPlayer,
      ),
    );
    final myName = myPlayer.name.trim().isNotEmpty ? myPlayer.name : myProfile.name;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.emoji_emotions_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EMOJI REACTION',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 10),

              // Emoji Grid — fixed 5 columns, no scrolling needed
              Flexible(
                child: GridView.count(
                  crossAxisCount: 5,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: _gameEmojis.map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        final mp = ref.read(multiplayerServiceProvider);
                        ref
                            .read(emojiReactionProvider.notifier)
                            .sendEmoji(emoji, myName, mp);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        alignment: Alignment.center,
                        child: Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== QUICK CHAT PANEL ====================

class QuickChatPanel extends ConsumerWidget {
  const QuickChatPanel({super.key});

  static const List<String> _quickMessages = [
    "Hello everyone! 👋",
    "Hurry up! ⏳",
    "Good roll! 🎲",
    "Let's trade! 🤝",
    "I'm broke! 😭",
    "Thanks! 🙏",
    "Oops! 😬",
    "Well played! 👏",
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.chat_bubble_rounded, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'QUICK CHAT',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 10),

              // Messages List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _quickMessages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final msg = _quickMessages[index];
                  return InkWell(
                    onTap: () {
                      final myId = ref.read(gameProvider.notifier).localPlayerId ?? ref.read(userProfileProvider).id;
                      ref.read(gameProvider.notifier).sendChatMessage(msg, myId);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        msg,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
