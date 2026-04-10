import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/lang.dart';
import '../auth/auth_session.dart';

const _channelEmojis = ['👍', '❤️', '🔥', '👏', '😮'];

final channelFeedProvider = FutureProvider<List<ChannelPostItem>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(
    '/channels/posts',
    queryParameters: {'take': 80},
  );
  final raw = res.data?['items'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => ChannelPostItem.fromJson(e.cast<String, dynamic>()))
      .toList();
});

final unreadChannelPostsCountProvider = FutureProvider<int>((ref) async {
  final prefs = ref.read(userPrefsProvider);
  final seenAtMs = await prefs.readChannelSeenAtMs() ?? 0;
  final items = await ref.watch(channelFeedProvider.future);
  return items
      .where((e) => e.createdAt.millisecondsSinceEpoch > seenAtMs)
      .length;
});

class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(channelFeedProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(channelFeedProvider),
          child: feed.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 80),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(channelFeedProvider),
                  child: Text(
                    tr(context, ru: 'Ошибка загрузки канала. Повторить', tg: 'Хатои боркунии канал. Такрор'),
                  ),
                ),
              ],
            ),
            data: (items) => ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
              children: [
                Text(
                  tr(context, ru: 'Канал', tg: 'Канал'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(context, ru: 'Новости и сообщения от администрации.', tg: 'Хабарҳо ва паёмҳо аз маъмурият.'),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      tr(context, ru: 'Пока нет сообщений в канале.', tg: 'Ҳоло дар канал паём нест.'),
                    ),
                  ),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ChannelPostCard(item: item),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChannelPostCard extends ConsumerWidget {
  const _ChannelPostCard({required this.item});

  final ChannelPostItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: Color(0xFFF57C00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: item.authorRole == 'admin'
                    ? RichText(
                        text: TextSpan(
                          text: item.authorName,
                          style: const TextStyle(
                            color: Color(0xFF202227),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          children: const [
                            TextSpan(
                              text: '  Admin',
                              style: TextStyle(
                                color: Color(0xFF7E8794),
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        item.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF202227),
                        ),
                      ),
              ),
              Text(
                _formatDate(item.createdAt),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202227),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _channelEmojis.map((emoji) {
              final row = item.reactionsByEmoji[emoji];
              final count = row?.count ?? 0;
              final active = row?.reacted ?? false;
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () async {
                  await _toggleReaction(ref, item.id, emoji, context);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFFFE0B2)
                        : const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? const Color(0xFFF57C00)
                          : const Color(0xFFE3E7ED),
                    ),
                  ),
                  child: Text(
                    '$emoji ${count > 0 ? count : ''}'.trim(),
                    style: TextStyle(
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined,
                  size: 17, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${item.views}',
                style: TextStyle(
                    color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleReaction(
    WidgetRef ref,
    String postId,
    String emoji,
    BuildContext context,
  ) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.post<void>(
        '/channels/posts/$postId/reactions',
        data: {'emoji': emoji},
      );
      ref.invalidate(channelFeedProvider);
    } on DioException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(context, ru: 'Не удалось поставить реакцию', tg: 'Реаксия гузошта нашуд'),
            ),
          ),
        );
      }
    }
  }
}

class ChannelPostItem {
  const ChannelPostItem({
    required this.id,
    required this.body,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
    required this.views,
    required this.reactionsByEmoji,
  });

  final String id;
  final String body;
  final String authorName;
  final String authorRole;
  final DateTime createdAt;
  final int views;
  final Map<String, ChannelReactionItem> reactionsByEmoji;

  factory ChannelPostItem.fromJson(Map<String, dynamic> json) {
    final reactionsRaw = json['reactions'];
    final reactionMap = <String, ChannelReactionItem>{};
    if (reactionsRaw is List) {
      for (final item in reactionsRaw.whereType<Map>()) {
        final row = ChannelReactionItem.fromJson(item.cast<String, dynamic>());
        reactionMap[row.emoji] = row;
      }
    }
    final author = json['author'];
    String name = 'Администрация';
    String role = 'admin';
    if (author is Map &&
        author['name'] is String &&
        (author['name'] as String).trim().isNotEmpty) {
      name = (author['name'] as String).trim();
    }
    if (author is Map && author['role'] is String) {
      role = (author['role'] as String).trim();
    }
    return ChannelPostItem(
      id: (json['id'] as String? ?? '').trim(),
      body: (json['body'] as String? ?? '').trim(),
      authorName: name,
      authorRole: role,
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '')?.toLocal() ??
              DateTime.now(),
      views: (json['views'] as num?)?.toInt() ?? 0,
      reactionsByEmoji: reactionMap,
    );
  }
}

class ChannelReactionItem {
  const ChannelReactionItem({
    required this.emoji,
    required this.count,
    required this.reacted,
  });

  final String emoji;
  final int count;
  final bool reacted;

  factory ChannelReactionItem.fromJson(Map<String, dynamic> json) {
    return ChannelReactionItem(
      emoji: (json['emoji'] as String? ?? '').trim(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      reacted: json['reacted'] == true,
    );
  }
}

String _formatDate(DateTime dt) {
  final d = dt.toLocal();
  String two(int n) => n < 10 ? '0$n' : '$n';
  return '${two(d.day)}.${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
}
