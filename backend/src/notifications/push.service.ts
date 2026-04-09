import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

type PushPayload = {
  title: string;
  body: string;
  data?: Record<string, string>;
};

@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);
  private app: admin.app.App | null = null;

  constructor(private readonly prisma: PrismaService) {
    this.app = this.tryInitFirebase();
  }

  async registerDeviceToken(userId: string, token: string, platform: string) {
    const cleanToken = token.trim();
    if (!cleanToken) return { ok: true as const };
    await this.prisma.devicePushToken.upsert({
      where: { token: cleanToken },
      create: {
        userId,
        token: cleanToken,
        platform: platform.trim() || 'unknown',
      },
      update: {
        userId,
        platform: platform.trim() || 'unknown',
      },
    });
    return { ok: true as const };
  }

  async sendOrderStatusChanged(
    userId: string,
    orderId: string,
    trackingCode: string,
    status: string,
  ) {
    const title = `Статус заказа ${trackingCode}`;
    const body = `Новый статус: ${statusLabel(status)}`;
    const created = await this.createNotificationIfNew(
      userId,
      orderId,
      trackingCode,
      status,
      title,
      body,
    );
    if (!created) {
      return { ok: true as const, sent: 0, deduped: true as const };
    }
    return this.sendToUser(userId, {
      title,
      body,
      data: {
        type: 'order_status',
        trackingCode,
        status,
      },
    });
  }

  private async createNotificationIfNew(
    userId: string,
    orderId: string,
    trackingCode: string,
    status: string,
    title: string,
    body: string,
  ) {
    try {
      await this.prisma.orderStatusNotification.create({
        data: {
          userId,
          orderId,
          trackingCode,
          status,
          title,
          body,
        },
      });
      return true;
    } catch (e) {
      if (
        e instanceof Prisma.PrismaClientKnownRequestError &&
        e.code === 'P2002'
      ) {
        // Такой статус для этого заказа и клиента уже отправлялся.
        return false;
      }
      throw e;
    }
  }

  async sendToUser(userId: string, payload: PushPayload) {
    if (!this.app) return { ok: false as const, sent: 0 };
    const rows = await this.prisma.devicePushToken.findMany({
      where: { userId },
      select: { token: true },
    });
    if (rows.length === 0) return { ok: true as const, sent: 0 };
    const tokens = rows.map((r) => r.token);
    const messaging = this.app.messaging();
    const res = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: payload.title, body: payload.body },
      data: payload.data,
      android: {
        priority: 'high',
        notification: {
          sound: 'insof_notification',
          channelId: 'order_status_channel',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'insof_notification.aiff',
            badge: 1,
          },
        },
      },
    });
    const badTokens: string[] = [];
    res.responses.forEach((r, i) => {
      if (!r.success) {
        const code = (r.error as { code?: string } | undefined)?.code ?? '';
        if (
          code.includes('registration-token-not-registered') ||
          code.includes('invalid-registration-token')
        ) {
          badTokens.push(tokens[i]);
        }
      }
    });
    if (badTokens.length > 0) {
      await this.prisma.devicePushToken.deleteMany({
        where: { token: { in: badTokens } },
      });
    }
    return { ok: true as const, sent: res.successCount };
  }

  private tryInitFirebase(): admin.app.App | null {
    try {
      if (admin.apps.length > 0) return admin.app();
      const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
      if (json) {
        const parsed = JSON.parse(json) as admin.ServiceAccount;
        return admin.initializeApp({
          credential: admin.credential.cert(parsed),
        });
      }
      try {
        return admin.initializeApp({
          credential: admin.credential.applicationDefault(),
        });
      } catch {
        this.logger.warn(
          'Firebase не настроен: push-уведомления отключены (FIREBASE_SERVICE_ACCOUNT_JSON).',
        );
        return null;
      }
    } catch (e) {
      this.logger.warn(`Firebase init error: ${(e as Error).message}`);
      return null;
    }
  }
}

function statusLabel(status: string): string {
  switch (status) {
    case 'received_china':
      return 'Получено в Китае';
    case 'in_transit':
      return 'В пути';
    case 'sorting':
      return 'Сортировка';
    case 'ready_pickup':
      return 'Готово к выдаче';
    case 'with_courier':
      return 'Передан курьеру';
    case 'completed':
      return 'Получен';
    default:
      return status;
  }
}
