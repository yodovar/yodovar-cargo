import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async log(params: {
    actorId: string | null;
    action: string;
    entityType: string;
    entityId: string;
    before: unknown;
    after: unknown;
  }) {
    await this.prisma.auditLog.create({
      data: {
        actorId: params.actorId,
        action: params.action,
        entityType: params.entityType,
        entityId: params.entityId,
        beforeJson: JSON.stringify(params.before),
        afterJson: JSON.stringify(params.after),
      },
    });
  }
}
