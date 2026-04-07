import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { MeService } from '../me/me.service';
import { PrismaService } from '../prisma/prisma.service';
import { WAREHOUSE_TJ_READY_STATUSES } from './warehouse.constants';

const READY_SET = new Set<string>(WAREHOUSE_TJ_READY_STATUSES);

@Injectable()
export class WarehouseTjService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly meService: MeService,
  ) {}

  async scan(code: string) {
    const lookup = await this.meService.lookupByClientCode(code);
    if (!lookup.found) {
      return { found: false as const };
    }
    const orders = await this.listReadyOrdersInternal(lookup.userId);
    return {
      found: true as const,
      client: {
        userId: lookup.userId,
        clientCode: lookup.clientCode,
        name: lookup.name,
        phone: lookup.phone,
      },
      orders,
    };
  }

  async readyOrdersByClientCode(code: string) {
    const lookup = await this.meService.lookupByClientCode(code);
    if (!lookup.found) {
      return { found: false as const, orders: [] };
    }
    const orders = await this.listReadyOrdersInternal(lookup.userId);
    return {
      found: true as const,
      clientCode: lookup.clientCode,
      orders,
    };
  }

  async handover(actorId: string, orderId: string) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException('Заказ не найден');
    if (!order.clientId) {
      throw new BadRequestException('У заказа не указан клиент');
    }
    if (!READY_SET.has(order.status)) {
      throw new BadRequestException(
        `Выдача возможна только в статусах: ${[...READY_SET].join(', ')}`,
      );
    }
    const handedOverAt = new Date();
    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: {
        status: 'completed',
        handedOverAt,
      },
    });
    await this.audit.log({
      actorId,
      action: 'warehouse_tj.handover',
      entityType: 'order',
      entityId: orderId,
      before: { status: order.status, handedOverAt: order.handedOverAt },
      after: { status: updated.status, handedOverAt: updated.handedOverAt },
    });
    return this.prisma.order.findUniqueOrThrow({
      where: { id: orderId },
      select: {
        id: true,
        trackingCode: true,
        status: true,
        isPaid: true,
        clientId: true,
        weightGrams: true,
        handedOverAt: true,
        createdAt: true,
        updatedAt: true,
        client: {
          select: { id: true, name: true, clientCode: true, phone: true },
        },
      },
    });
  }

  private async listReadyOrdersInternal(clientUserId: string) {
    return this.prisma.order.findMany({
      where: {
        clientId: clientUserId,
        status: { in: [...WAREHOUSE_TJ_READY_STATUSES] },
      },
      orderBy: { updatedAt: 'desc' },
      select: {
        id: true,
        trackingCode: true,
        status: true,
        isPaid: true,
        weightGrams: true,
        handedOverAt: true,
        updatedAt: true,
      },
    });
  }
}
