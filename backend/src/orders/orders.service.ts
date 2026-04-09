import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuthRole } from '../auth/auth.types';
import { buildQrPayload } from '../common/client-code';
import { PushService } from '../notifications/push.service';

type SeedOrder = {
  trackingCode: string;
  status: string;
  isPaid: boolean;
};

const DEFAULT_ORDERS: SeedOrder[] = [
  { trackingCode: 'SF4745', status: 'received_china', isPaid: true },
  { trackingCode: 'YD1001', status: 'received_china', isPaid: false },
  { trackingCode: 'YD1002', status: 'received_china', isPaid: true },
  { trackingCode: 'YD1003', status: 'received_china', isPaid: false },
  { trackingCode: 'YD1004', status: 'in_transit', isPaid: false },
  { trackingCode: 'YD1005', status: 'completed', isPaid: true },
  { trackingCode: 'YD1006', status: 'completed', isPaid: true },
];

const ALLOWED_STATUSES = new Set([
  'received_china',
  'in_transit',
  'sorting',
  'ready_pickup',
  'with_courier',
  'completed',
]);

@Injectable()
export class OrdersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly push: PushService,
  ) {}

  async summary(userId: string, role: AuthRole) {
    await this.ensureDefaults();
    const where = await this.buildScopeWhere(userId, role);
    const allOrders = await this.prisma.order.findMany({ where });
    const statusCount = (status: string) =>
      allOrders.filter((o) => o.status === status).length;

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { clientCode: true },
    });

    return {
      qrCode: user?.clientCode ?? '-----',
      qrPayload: user?.clientCode ? buildQrPayload(user.clientCode) : '',
      stats: {
        all: allOrders.length,
        receivedChina: statusCount('received_china'),
        inTransit: statusCount('in_transit'),
        sorting: statusCount('sorting'),
        readyPickup: statusCount('ready_pickup'),
        withCourier: statusCount('with_courier'),
        unpaid: allOrders.filter((o) => !o.isPaid).length,
        completed: statusCount('completed'),
      },
    };
  }

  async list(
    userId: string,
    role: AuthRole,
    params: { status?: string; take: number },
  ) {
    await this.ensureDefaults();
    const where: Prisma.OrderWhereInput = await this.buildScopeWhere(userId, role);
    if (params.status) where.status = params.status;
    const take = Math.min(Math.max(params.take, 1), 300);
    const items = await this.prisma.order.findMany({
      where,
      take,
      orderBy: { updatedAt: 'desc' },
      select: {
        id: true,
        trackingCode: true,
        status: true,
        isPaid: true,
        weightGrams: true,
        createdAt: true,
        updatedAt: true,
        handedOverAt: true,
      },
    });
    return { items };
  }

  async findByTrackingCode(userId: string, role: AuthRole, input: string) {
    await this.ensureDefaults();
    const trackingCode = input.trim().toUpperCase();
    if (trackingCode.length < 2) return { found: false as const };
    const scoped = await this.buildScopeWhere(userId, role);
    const order = await this.prisma.order.findFirst({ where: { ...scoped, trackingCode } });
    if (!order) return { found: false as const };
    return {
      found: true as const,
      trackingCode: order.trackingCode,
      status: order.status,
      isPaid: order.isPaid,
    };
  }

  async updateStatus(id: string, statusInput: string, actorId: string) {
    await this.ensureDefaults();
    const status = statusInput.trim();
    if (!ALLOWED_STATUSES.has(status)) {
      throw new BadRequestException('Unsupported status');
    }
    const existing = await this.prisma.order.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundException('Order not found');
    }
    const updated = await this.prisma.order.update({
      where: { id },
      data: { status },
      select: {
        id: true,
        trackingCode: true,
        status: true,
        isPaid: true,
      },
    });
    await this.audit.log({
      actorId,
      action: 'order.status.updated',
      entityType: 'order',
      entityId: id,
      before: { status: existing.status },
      after: { status: updated.status },
    });
    if (existing.clientId && existing.status !== updated.status) {
      await this.push.sendOrderStatusChanged(
        existing.clientId,
        existing.id,
        updated.trackingCode,
        updated.status,
      );
    }
    return updated;
  }

  private async ensureDefaults() {
    const count = await this.prisma.order.count();
    if (count > 0) return;
    await this.prisma.order.createMany({
      data: DEFAULT_ORDERS,
    });
  }

  private async buildScopeWhere(userId: string, role: AuthRole) {
    if (role !== 'client') return {};
    return { clientId: userId };
  }
}
