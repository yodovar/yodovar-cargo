import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { PushService } from '../notifications/push.service';
import { PrismaService } from '../prisma/prisma.service';
import { WAREHOUSE_CN_STATUSES } from './warehouse.constants';
import { CnIntakeDto } from './dto/cn-intake.dto';

const CN_SET = new Set<string>(WAREHOUSE_CN_STATUSES);

@Injectable()
export class WarehouseCnService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly push: PushService,
  ) {}

  async intake(actorId: string, dto: CnIntakeDto) {
    const trackingCode = dto.trackingCode.trim().toUpperCase();
    const clientCode = dto.clientCode?.trim().toUpperCase() ?? '';
    const guestName = dto.guestName?.trim() ?? '';
    const guestPhone = dto.guestPhone?.trim() ?? '';

    if (!clientCode && !guestName && !guestPhone) {
      throw new BadRequestException(
        'Укажите clientCode, либо вручную введите данные клиента',
      );
    }

    let client:
      | { id: string; clientCode: string | null; name: string; role: UserRole }
      | null = null;

    if (clientCode) {
      client = await this.prisma.user.findUnique({
        where: { clientCode },
        select: { id: true, clientCode: true, name: true, role: true },
      });
      if (!client?.clientCode) {
        throw new BadRequestException('Клиент с таким clientCode не найден');
      }
      if (client.role !== UserRole.client) {
        throw new BadRequestException('clientCode должен принадлежать клиенту');
      }
    }

    const existing = await this.prisma.order.findUnique({
      where: { trackingCode },
    });

    if (existing) {
      if (client && existing.clientId && existing.clientId !== client.id) {
        throw new BadRequestException(
          'Этот трек уже привязан к другому клиенту',
        );
      }
      const updated = await this.prisma.order.update({
        where: { id: existing.id },
        data: {
          clientId: client?.id ?? null,
          guestName: client ? null : guestName,
          guestPhone: client ? null : guestPhone,
          status: 'received_china',
          ...(dto.weightGrams != null ? { weightGrams: dto.weightGrams } : {}),
        },
      });
      await this.audit.log({
        actorId,
        action: 'warehouse_cn.intake.updated',
        entityType: 'order',
        entityId: updated.id,
        before: existing,
        after: updated,
      });
      if (updated.clientId) {
        await this.push.sendOrderStatusChanged(
          updated.clientId,
          updated.id,
          updated.trackingCode,
          updated.status,
        );
      }
      return this.selectOrderPublic(updated.id);
    }

    const created = await this.prisma.order.create({
      data: {
        trackingCode,
        status: 'received_china',
        clientId: client?.id ?? null,
        guestName: client ? null : guestName,
        guestPhone: client ? null : guestPhone,
        weightGrams: dto.weightGrams ?? null,
        isPaid: false,
      },
    });
    await this.audit.log({
      actorId,
      action: 'warehouse_cn.intake.created',
      entityType: 'order',
      entityId: created.id,
      before: null,
      after: created,
    });
    if (client?.id) {
      await this.push.sendOrderStatusChanged(
        client.id,
        created.id,
        created.trackingCode,
        created.status,
      );
    }
    return this.selectOrderPublic(created.id);
  }

  async setWeight(actorId: string, orderId: string, weightGrams: number) {
    const existing = await this.requireOrder(orderId);
    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: { weightGrams },
    });
    await this.audit.log({
      actorId,
      action: 'warehouse_cn.weight.updated',
      entityType: 'order',
      entityId: orderId,
      before: { weightGrams: existing.weightGrams },
      after: { weightGrams: updated.weightGrams },
    });
    return this.selectOrderPublic(updated.id);
  }

  async setStatus(actorId: string, orderId: string, status: string) {
    if (!CN_SET.has(status)) {
      throw new BadRequestException(
        `Статус недоступен для склада КНР. Допустимо: ${[...CN_SET].join(', ')}`,
      );
    }
    const existing = await this.requireOrder(orderId);
    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: { status },
    });
    await this.audit.log({
      actorId,
      action: 'warehouse_cn.status.updated',
      entityType: 'order',
      entityId: orderId,
      before: { status: existing.status },
      after: { status: updated.status },
    });
    if (updated.clientId && existing.status !== updated.status) {
      await this.push.sendOrderStatusChanged(
        updated.clientId,
        updated.id,
        updated.trackingCode,
        updated.status,
      );
    }
    return this.selectOrderPublic(updated.id);
  }

  private async requireOrder(id: string) {
    const o = await this.prisma.order.findUnique({ where: { id } });
    if (!o) throw new NotFoundException('Заказ не найден');
    return o;
  }

  private async selectOrderPublic(id: string) {
    return this.prisma.order.findUniqueOrThrow({
      where: { id },
      select: {
        id: true,
        trackingCode: true,
        status: true,
        isPaid: true,
        clientId: true,
        weightGrams: true,
        guestName: true,
        guestPhone: true,
        handedOverAt: true,
        createdAt: true,
        updatedAt: true,
        client: {
          select: { id: true, name: true, clientCode: true, phone: true },
        },
      },
    });
  }
}
