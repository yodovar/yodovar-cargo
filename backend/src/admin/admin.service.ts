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
import { CreatePickupPointDto } from './dto/create-pickup-point.dto';
import { UpdatePickupPointDto } from './dto/update-pickup-point.dto';
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
      const upper = q.toUpperCase().replace(/\s+/g, '');
      const digits = q.replace(/\D/g, '');
      const or: Prisma.UserWhereInput[] = [
        { phone: { contains: q } },
        { name: { contains: q } },
        { clientCode: { contains: upper } },
      ];
      // Match phones saved as +992… when staff types local digits only.
      if (digits.length >= 4 && digits !== q) {
        or.push({ phone: { contains: digits } });
      }
      where.OR = or;
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
    withoutClient?: boolean;
  }) {
    const where: Prisma.OrderWhereInput = {};
    if (params.status?.trim()) where.status = params.status.trim();
    const tr = params.trackingCode?.trim().toUpperCase();
    if (tr) where.trackingCode = { contains: tr };
    const cc = params.clientCode?.trim().toUpperCase();
    if (cc) {
      where.client = { clientCode: cc };
    }
    if (params.withoutClient) {
      where.clientId = null;
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

  async ordersSummary() {
    const [all, unpaid, byStatus] = await Promise.all([
      this.prisma.order.count(),
      this.prisma.order.count({ where: { isPaid: false } }),
      this.prisma.order.groupBy({
        by: ['status'],
        _count: { _all: true },
      }),
    ]);
    const statusMap = new Map(byStatus.map((r) => [r.status, r._count._all]));
    return {
      stats: {
        all,
        receivedChina: statusMap.get('received_china') ?? 0,
        inTransit: statusMap.get('in_transit') ?? 0,
        sorting: statusMap.get('sorting') ?? 0,
        readyPickup: statusMap.get('ready_pickup') ?? 0,
        withCourier: statusMap.get('with_courier') ?? 0,
        unpaid,
        completed: statusMap.get('completed') ?? 0,
      },
    };
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

  listPickupPoints() {
    return this.prisma.pickupPoint.findMany({ orderBy: { createdAt: 'asc' } });
  }

  async createPickupPoint(actorId: string, dto: CreatePickupPointDto) {
    const exists = await this.prisma.pickupPoint.findUnique({
      where: { key: dto.key },
    });
    if (exists) {
      throw new BadRequestException('Пункт выдачи с таким key уже существует');
    }
    const created = await this.prisma.pickupPoint.create({
      data: {
        key: dto.key,
        city: dto.city,
        addressTemplate: dto.addressTemplate,
      },
    });
    await this.audit.log({
      actorId,
      action: 'pickup_point.created',
      entityType: 'pickup_point',
      entityId: created.id,
      before: null,
      after: created,
    });
    return created;
  }

  async updatePickupPoint(actorId: string, key: string, dto: UpdatePickupPointDto) {
    const prev = await this.prisma.pickupPoint.findUnique({ where: { key } });
    if (!prev) throw new NotFoundException('Pickup point not found');
    const updated = await this.prisma.pickupPoint.update({
      where: { key },
      data: dto,
    });
    await this.audit.log({
      actorId,
      action: 'pickup_point.updated',
      entityType: 'pickup_point',
      entityId: updated.id,
      before: prev,
      after: updated,
    });
    return updated;
  }

  async deletePickupPoint(actorId: string, key: string) {
    const prev = await this.prisma.pickupPoint.findUnique({ where: { key } });
    if (!prev) throw new NotFoundException('Pickup point not found');
    await this.prisma.pickupPoint.delete({ where: { key } });
    await this.audit.log({
      actorId,
      action: 'pickup_point.deleted',
      entityType: 'pickup_point',
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
