import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ChannelsService {
  constructor(private readonly prisma: PrismaService) {}

  async listPostsForUser(userId: string, takeRaw?: number) {
    const take = Math.min(100, Math.max(1, Number(takeRaw ?? 40) || 40));
    const posts = await this.prisma.channelPost.findMany({
      orderBy: { createdAt: 'desc' },
      take,
      include: {
        author: { select: { id: true, name: true, role: true } },
      },
    });

    const postIds = posts.map((p) => p.id);
    if (postIds.length === 0) {
      return { items: [] };
    }

    await Promise.all(
      postIds.map((postId) =>
        this.prisma.channelPostView.upsert({
          where: { postId_userId: { postId, userId } },
          update: {},
          create: { postId, userId },
        }),
      ),
    );

    const [allReactions, myReactions, views] = await Promise.all([
      this.prisma.channelPostReaction.findMany({
        where: { postId: { in: postIds } },
        select: { postId: true, emoji: true },
      }),
      this.prisma.channelPostReaction.findMany({
        where: { postId: { in: postIds }, userId },
        select: { postId: true, emoji: true },
      }),
      this.prisma.channelPostView.groupBy({
        by: ['postId'],
        where: { postId: { in: postIds } },
        _count: { _all: true },
      }),
    ]);

    const reactionMap = new Map<string, Map<string, number>>();
    for (const r of allReactions) {
      const byEmoji = reactionMap.get(r.postId) ?? new Map<string, number>();
      byEmoji.set(r.emoji, (byEmoji.get(r.emoji) ?? 0) + 1);
      reactionMap.set(r.postId, byEmoji);
    }
    const myReactionMap = new Map<string, string>();
    for (const r of myReactions) {
      myReactionMap.set(r.postId, r.emoji);
    }
    const viewCountMap = new Map<string, number>();
    for (const row of views) {
      viewCountMap.set(row.postId, row._count._all);
    }

    return {
      items: posts.map((p) => {
        const buckets = reactionMap.get(p.id) ?? new Map<string, number>();
        const myReaction = myReactionMap.get(p.id) ?? null;
        return {
          id: p.id,
          body: p.body,
          createdAt: p.createdAt,
          updatedAt: p.updatedAt,
          author: p.author,
          views: viewCountMap.get(p.id) ?? 0,
          myReaction,
          reactions: Array.from(buckets.entries()).map(([emoji, count]) => ({
            emoji,
            count,
            reacted: myReaction === emoji,
          })),
        };
      }),
    };
  }

  async reactToPost(postId: string, userId: string, emoji: string) {
    const post = await this.prisma.channelPost.findUnique({
      where: { id: postId },
      select: { id: true },
    });
    if (!post) throw new NotFoundException('Пост канала не найден');

    const existing = await this.prisma.channelPostReaction.findUnique({
      where: { postId_userId: { postId, userId } },
      select: { id: true, emoji: true },
    });

    if (existing && existing.emoji === emoji) {
      await this.prisma.channelPostReaction.delete({
        where: { id: existing.id },
      });
      return { ok: true as const, myReaction: null };
    }

    if (existing) {
      await this.prisma.channelPostReaction.update({
        where: { id: existing.id },
        data: { emoji },
      });
      return { ok: true as const, myReaction: emoji };
    }

    await this.prisma.channelPostReaction.create({
      data: { postId, userId, emoji },
    });
    return { ok: true as const, myReaction: emoji };
  }
}
