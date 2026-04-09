import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { PushService } from '../notifications/push.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreateSupportContactDto } from './dto/create-support-contact.dto';
import { CreateTariffDto } from './dto/create-tariff.dto';
import { UpdateSupportContactDto } from './dto/update-support-contact.dto';
import { UpdateTariffDto } from './dto/update-tariff.dto';
import { CreateChannelPostDto } from './dto/create-channel-post.dto';

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly push: PushService,
  ) {}

  async listUsers(params: {
    skip: number;
    take: number;
    role?: UserRole;
    q?: string;
  }) {
    const where: Prisma.UserWhereInput = {};
    if (params.role) where.role = params.role;
    const q = params.q?.trim();
    if (q) {
      const upper = q.toUpperCase();
      where.OR = [
        { phone: { contains: q } },
        { name: { contains: q } },
        { clientCode: { contains: upper } },
      ];
    }
    const [items, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip: params.skip,
        take: params.take,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          phone: true,
          name: true,
          role: true,
          clientCode: true,
          createdAt: true,
        },
      }),
      this.prisma.user.count({ where }),
    ]);
    return { items, total, skip: params.skip, take: params.take };
  }

  async listOrders(params: {
    skip: number;
    take: number;
    status?: string;
    trackingCode?: string;
    clientCode?: string;
  }) {
    const where: Prisma.OrderWhereInput = {};
    if (params.status?.trim()) where.status = params.status.trim();
    const tr = params.trackingCode?.trim().toUpperCase();
    if (tr) where.trackingCode = { contains: tr };
    const cc = params.clientCode?.trim().toUpperCase();
    if (cc) {
      where.client = { clientCode: cc };
    }
    const [items, total] = await Promise.all([
      this.prisma.order.findMany({
        where,
        skip: params.skip,
        take: params.take,
        orderBy: { updatedAt: 'desc' },
        include: {
          client: {
            select: {
              id: true,
              name: true,
              phone: true,
              clientCode: true,
            },
          },
        },
      }),
      this.prisma.order.count({ where }),
    ]);
    return { items, total, skip: params.skip, take: params.take };
  }

  async setUserRole(actorId: string, userId: string, role: UserRole) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { role },
      select: { id: true, phone: true, role: true, name: true },
    });
    await this.audit.log({
      actorId,
      action: 'user.role.updated',
      entityType: 'user',
      entityId: userId,
      before: { role: user.role },
      after: { role: updated.role },
    });
    return updated;
  }

  async updateTariff(actorId: string, key: string, dto: UpdateTariffDto) {
    const prev = await this.prisma.tariff.findUnique({ where: { key } });
    if (!prev) throw new NotFoundException('Tariff not found');
    const { details, ...scalar } = dto;
    const data: Prisma.TariffUpdateInput = { ...scalar };
    if (details !== undefined) {
      data.detailsJson = JSON.stringify(details);
    }
    const updated = await this.prisma.tariff.update({
      where: { key },
      data,
    });
    await this.audit.log({
      actorId,
      action: 'tariff.updated',
      entityType: 'tariff',
      entityId: updated.id,
      before: prev,
      after: updated,
    });
    return updated;
  }

  async createTariff(actorId: string, dto: CreateTariffDto) {
    const exists = await this.prisma.tariff.findUnique({
      where: { key: dto.key },
    });
    if (exists) {
      throw new BadRequestException('Тариф с таким key уже существует');
    }
    const created = await this.prisma.tariff.create({
      data: {
        key: dto.key,
        title: dto.title,
        pricePerKgUsd: dto.pricePerKgUsd,
        pricePerCubicUsd: dto.pricePerCubicUsd,
        minChargeWeightG: dto.minChargeWeightG,
        etaDaysMin: dto.etaDaysMin,
        etaDaysMax: dto.etaDaysMax,
        detailsJson: JSON.stringify(dto.details),
      },
    });
    await this.audit.log({
      actorId,
      action: 'tariff.created',
      entityType: 'tariff',
      entityId: created.id,
      before: null,
      after: created,
    });
    return created;
  }

  async deleteTariff(actorId: string, key: string) {
    const prev = await this.prisma.tariff.findUnique({ where: { key } });
    if (!prev) throw new NotFoundException('Tariff not found');
    await this.prisma.tariff.delete({ where: { key } });
    await this.audit.log({
      actorId,
      action: 'tariff.deleted',
      entityType: 'tariff',
      entityId: prev.id,
      before: prev,
      after: null,
    });
    return { ok: true as const };
  }

  async updateSupportContact(actorId: string, key: string, dto: UpdateSupportContactDto) {
    const prev = await this.prisma.supportContact.findUnique({ where: { key } });
    if (!prev) throw new NotFoundException('Support contact not found');
    const updated = await this.prisma.supportContact.update({
      where: { key },
      data: dto,
    });
    await this.audit.log({
      actorId,
      action: 'support_contact.updated',
      entityType: 'support_contact',
      entityId: updated.id,
      before: prev,
      after: updated,
    });
    return updated;
  }

  async createSupportContact(actorId: string, dto: CreateSupportContactDto) {
    const exists = await this.prisma.supportContact.findUnique({
      where: { key: dto.key },
    });
    if (exists) {
      throw new BadRequestException('Контакт с таким key уже существует');
    }
    const created = await this.prisma.supportContact.create({
      data: {
        key: dto.key,
        label: dto.label,
        usernameOrPhone: dto.usernameOrPhone,
        appUrl: dto.appUrl,
        webUrl: dto.webUrl,
      },
    });
    await this.audit.log({
      actorId,
      action: 'support_contact.created',
      entityType: 'support_contact',
      entityId: created.id,
      before: null,
      after: created,
    });
    return created;
  }

  async deleteSupportContact(actorId: string, key: string) {
    const prev = await this.prisma.supportContact.findUnique({ where: { key } });
    if (!prev) throw new NotFoundException('Support contact not found');
    await this.prisma.supportContact.delete({ where: { key } });
    await this.audit.log({
      actorId,
      action: 'support_contact.deleted',
      entityType: 'support_contact',
      entityId: prev.id,
      before: prev,
      after: null,
    });
    return { ok: true as const };
  }

  listAudit(limit = 100) {
    return this.prisma.auditLog.findMany({
      orderBy: { createdAt: 'desc' },
      take: Math.min(Math.max(limit, 1), 500),
    });
  }

  async listChannelPosts(takeRaw?: number) {
    const take = Math.min(200, Math.max(1, Number(takeRaw ?? 80) || 80));
    const posts = await this.prisma.channelPost.findMany({
      orderBy: { createdAt: 'desc' },
      take,
      include: {
        author: { select: { id: true, name: true, role: true } },
      },
    });
    const ids = posts.map((p) => p.id);
    if (ids.length === 0) return { items: [] };

    const [reactions, views] = await Promise.all([
      this.prisma.channelPostReaction.findMany({
        where: { postId: { in: ids } },
        select: { postId: true, emoji: true },
      }),
      this.prisma.channelPostView.groupBy({
        by: ['postId'],
        where: { postId: { in: ids } },
        _count: { _all: true },
      }),
    ]);

    const reactionMap = new Map<string, Map<string, number>>();
    for (const r of reactions) {
      const byEmoji = reactionMap.get(r.postId) ?? new Map<string, number>();
      byEmoji.set(r.emoji, (byEmoji.get(r.emoji) ?? 0) + 1);
      reactionMap.set(r.postId, byEmoji);
    }
    const viewMap = new Map<string, number>();
    for (const v of views) {
      viewMap.set(v.postId, v._count._all);
    }

    return {
      items: posts.map((p) => ({
        id: p.id,
        body: p.body,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        author: p.author,
        views: viewMap.get(p.id) ?? 0,
        reactions: Array.from((reactionMap.get(p.id) ?? new Map()).entries()).map(
          ([emoji, count]) => ({ emoji, count }),
        ),
      })),
    };
  }

  async createChannelPost(actorId: string, dto: CreateChannelPostDto) {
    const body = dto.body.trim();
    if (!body) {
      throw new BadRequestException('Текст сообщения обязателен');
    }
    const created = await this.prisma.channelPost.create({
      data: {
        body,
        authorId: actorId,
      },
    });
    await this.audit.log({
      actorId,
      action: 'channel.post.created',
      entityType: 'channel_post',
      entityId: created.id,
      before: null,
      after: created,
    });
    const clients = await this.prisma.user.findMany({
      where: { role: 'client' },
      select: { id: true },
    });
    const snippet = body.length > 120 ? `${body.slice(0, 117)}...` : body;
    await Promise.all(
      clients.map((u) =>
        this.push.sendToUser(u.id, {
          title: 'Новый пост в канале',
          body: snippet,
          data: {
            type: 'channel_post',
            postId: created.id,
          },
        }),
      ),
    );
    return { ...created, pushTargets: clients.length };
  }
}
