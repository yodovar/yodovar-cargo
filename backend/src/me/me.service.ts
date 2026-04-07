import { Injectable, NotFoundException } from '@nestjs/common';
import { buildQrPayload, generateUniqueClientCode } from '../common/client-code';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MeService {
  constructor(private readonly prisma: PrismaService) {}

  async getIdentity(userId: string) {
    let user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    if (!user.clientCode) {
      const clientCode = await generateUniqueClientCode(this.prisma);
      user = await this.prisma.user.update({
        where: { id: userId },
        data: { clientCode },
      });
    }

    return {
      id: user.id,
      phone: user.phone,
      name: user.name,
      role: user.role,
      clientCode: user.clientCode,
      qrPayload: buildQrPayload(user.clientCode!),
    };
  }

  async lookupByClientCode(raw: string) {
    let code = raw.trim();
    if (code.includes('://') || code.includes('/')) {
      const parts = code.split('/').filter((p) => p.length > 0);
      code = parts[parts.length - 1] ?? code;
    }
    code = code.toUpperCase();
    if (code.length < 4) {
      return { found: false as const };
    }
    const user = await this.prisma.user.findUnique({
      where: { clientCode: code },
      select: {
        id: true,
        clientCode: true,
        name: true,
        phone: true,
        role: true,
      },
    });
    if (!user || !user.clientCode) {
      return { found: false as const };
    }
    return {
      found: true as const,
      userId: user.id,
      clientCode: user.clientCode,
      name: user.name,
      phone: user.phone,
      role: user.role,
    };
  }
}
