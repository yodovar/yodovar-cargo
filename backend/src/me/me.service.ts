import { Injectable, NotFoundException } from '@nestjs/common';
import type { Express } from 'express';
import { existsSync } from 'fs';
import { unlink } from 'fs/promises';
import { join } from 'path';
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
      ...this.avatarPayload(user.avatarKey, user.avatarUpdatedAt),
    };
  }

  private avatarPayload(avatarKey: string | null, avatarUpdatedAt: Date | null) {
    if (!avatarKey || !avatarUpdatedAt) {
      return { avatarUrl: null as string | null, avatarVersion: null as number | null };
    }
    return {
      avatarUrl: `/uploads/${avatarKey}`,
      avatarVersion: avatarUpdatedAt.getTime(),
    };
  }

  async commitAvatar(userId: string, file: Express.Multer.File) {
    const key = `avatars/${file.filename}`;
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (user.avatarKey && user.avatarKey !== key) {
      const oldPath = join(process.cwd(), 'uploads', user.avatarKey);
      if (existsSync(oldPath)) {
        try {
          await unlink(oldPath);
        } catch {
          /* ignore */
        }
      }
    }
    const now = new Date();
    await this.prisma.user.update({
      where: { id: userId },
      data: { avatarKey: key, avatarUpdatedAt: now },
    });
    return {
      ok: true as const,
      ...this.avatarPayload(key, now),
    };
  }

  async removeAvatar(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    if (user.avatarKey) {
      const p = join(process.cwd(), 'uploads', user.avatarKey);
      if (existsSync(p)) {
        try {
          await unlink(p);
        } catch {
          /* ignore */
        }
      }
    }
    await this.prisma.user.update({
      where: { id: userId },
      data: { avatarKey: null, avatarUpdatedAt: null },
    });
    return { ok: true as const, avatarUrl: null, avatarVersion: null };
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
