import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';

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
  ) {}

  async summary() {
    await this.ensureDefaults();
    const allOrders = await this.prisma.order.findMany();
    const statusCount = (status: string) =>
      allOrders.filter((o) => o.status === status).length;

    return {
      qrCode: 'SF4745',
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

  async findByTrackingCode(input: string) {
    await this.ensureDefaults();
    const trackingCode = input.trim().toUpperCase();
    if (trackingCode.length < 2) return { found: false as const };
    const order = await this.prisma.order.findUnique({ where: { trackingCode } });
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
    return updated;
  }

  private async ensureDefaults() {
    const count = await this.prisma.order.count();
    if (count > 0) return;
    await this.prisma.order.createMany({
      data: DEFAULT_ORDERS,
    });
  }
}
