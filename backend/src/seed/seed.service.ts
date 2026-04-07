import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import { generateUniqueClientCode } from '../common/client-code';
import { parseTajikPhone } from '../auth/phone-tj';
import { PrismaService } from '../prisma/prisma.service';

const BCRYPT_ROUNDS = 10;

@Injectable()
export class SeedService implements OnModuleInit {
  private readonly log = new Logger(SeedService.name);

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit() {
    await this.seedAdminUser();
    await this.seedStaffWorkers();
    await this.backfillMissingClientCodes();
  }

  private async seedAdminUser() {
    const raw =
      process.env.ADMIN_PHONE?.trim() || process.env.STAFF_ADMIN_PHONE?.trim();
    if (!raw) {
      this.log.warn('ADMIN_PHONE not set — skip first admin seed');
      return;
    }
    try {
      const phone = parseTajikPhone(raw);
      const existing = await this.prisma.user.findUnique({ where: { phone } });
      const adminPassword = process.env.STAFF_ADMIN_PASSWORD?.trim() || randomUUID();
      const passwordHash = await bcrypt.hash(adminPassword, BCRYPT_ROUNDS);
      const adminName = process.env.STAFF_ADMIN_NAME?.trim() || 'Admin';

      if (!existing) {
        const clientCode = await generateUniqueClientCode(this.prisma);
        await this.prisma.user.create({
          data: {
            phone,
            name: adminName,
            passwordHash,
            role: UserRole.admin,
            clientCode,
          },
        });
        this.log.log(`Seeded admin user for ${phone}`);
        return;
      }

      const updates: {
        role?: UserRole;
        clientCode?: string;
        name?: string;
        passwordHash?: string;
      } = {};
      if (existing.role !== UserRole.admin) {
        updates.role = UserRole.admin;
      }
      if (!existing.clientCode) {
        updates.clientCode = await generateUniqueClientCode(this.prisma);
      }
      if (existing.name !== adminName) {
        updates.name = adminName;
      }
      updates.passwordHash = passwordHash;
      if (Object.keys(updates).length > 0) {
        await this.prisma.user.update({
          where: { id: existing.id },
          data: updates,
        });
        this.log.log(`Updated admin user ${phone}: ${JSON.stringify(updates)}`);
      }
    } catch (e) {
      this.log.warn(`Admin seed failed: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  private async seedStaffWorkers() {
    await this.ensureStaffUser({
      phoneRaw:
        process.env.STAFF_WAREHOUSE_CN_PHONE?.trim() ||
        process.env.STAFF_WAREHOUSE_PHONE?.trim(),
      defaultName: 'Worker CN',
      role: UserRole.worker_cn,
      passwordRaw: process.env.STAFF_WAREHOUSE_CN_PASSWORD?.trim(),
      nameRaw: process.env.STAFF_WAREHOUSE_CN_NAME?.trim(),
    });

    await this.ensureStaffUser({
      phoneRaw: process.env.STAFF_WAREHOUSE_TJ_PHONE?.trim(),
      defaultName: 'Worker TJ',
      role: UserRole.worker_tj,
      passwordRaw: process.env.STAFF_WAREHOUSE_TJ_PASSWORD?.trim(),
      nameRaw: process.env.STAFF_WAREHOUSE_TJ_NAME?.trim(),
    });
  }

  private async ensureStaffUser(params: {
    phoneRaw?: string;
    defaultName: string;
    role: UserRole;
    passwordRaw?: string;
    nameRaw?: string;
  }) {
    if (!params.phoneRaw) return;
    try {
      const phone = parseTajikPhone(params.phoneRaw);
      const existing = await this.prisma.user.findUnique({ where: { phone } });
      const password = params.passwordRaw || randomUUID();
      const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);
      const name = params.nameRaw || params.defaultName;

      if (!existing) {
        const clientCode = await generateUniqueClientCode(this.prisma);
        await this.prisma.user.create({
          data: {
            phone,
            name,
            passwordHash,
            role: params.role,
            clientCode,
          },
        });
        this.log.log(`Seeded ${params.role} user for ${phone}`);
        return;
      }

      const updates: {
        role?: UserRole;
        clientCode?: string;
        name?: string;
        passwordHash?: string;
      } = {
        role: params.role,
        passwordHash,
      };
      if (!existing.clientCode) {
        updates.clientCode = await generateUniqueClientCode(this.prisma);
      }
      if (existing.name !== name) {
        updates.name = name;
      }
      await this.prisma.user.update({
        where: { id: existing.id },
        data: updates,
      });
    } catch (e) {
      this.log.warn(
        `Staff seed failed (${params.role}): ${e instanceof Error ? e.message : String(e)}`,
      );
    }
  }

  private async backfillMissingClientCodes() {
    const missing = await this.prisma.user.findMany({
      where: { clientCode: null },
      select: { id: true },
    });
    for (const row of missing) {
      const clientCode = await generateUniqueClientCode(this.prisma);
      await this.prisma.user.update({
        where: { id: row.id },
        data: { clientCode },
      });
    }
    if (missing.length > 0) {
      this.log.log(`Backfilled clientCode for ${missing.length} user(s)`);
    }
  }
}
