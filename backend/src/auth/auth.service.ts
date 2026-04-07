import {
  BadRequestException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { randomInt, randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { parseTajikPhone } from './phone-tj';
import { SmsService } from './sms.service';

const BCRYPT_ROUNDS = 10;
const OTP_TTL_MS = 10 * 60 * 1000;

function generateSixDigitCode(): string {
  const fixed = process.env.OTP_DEV_CODE?.trim();
  if (process.env.NODE_ENV !== 'production' && fixed && /^\d{6}$/.test(fixed)) {
    return fixed;
  }
  return String(randomInt(0, 1_000_000)).padStart(6, '0');
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly sms: SmsService,
  ) {}

  async requestOtp(phoneInput: string) {
    const phone = parseTajikPhone(phoneInput);
    const code = generateSixDigitCode();
    const otpHash = await bcrypt.hash(code, BCRYPT_ROUNDS);
    const expiresAt = new Date(Date.now() + OTP_TTL_MS);

    await this.prisma.pendingOtp.upsert({
      where: { phone },
      create: { phone, otpHash, expiresAt },
      update: { otpHash, expiresAt },
    });

    await this.sms.sendOtp(phone, code);
    return { ok: true as const };
  }

  async resendOtp(phoneInput: string) {
    const phone = parseTajikPhone(phoneInput);
    const pending = await this.prisma.pendingOtp.findUnique({ where: { phone } });
    if (!pending) {
      throw new NotFoundException('Сначала запросите код');
    }
    return this.requestOtp(phone);
  }

  async verifyOtp(phoneInput: string, code: string) {
    const phone = parseTajikPhone(phoneInput);
    const pending = await this.prisma.pendingOtp.findUnique({ where: { phone } });
    if (!pending) {
      throw new NotFoundException('Код не запрошен. Получите SMS-код снова.');
    }
    if (pending.expiresAt < new Date()) {
      await this.prisma.pendingOtp.delete({ where: { phone } });
      throw new BadRequestException('Код устарел. Запросите новый.');
    }
    const ok = await bcrypt.compare(code, pending.otpHash);
    if (!ok) {
      throw new BadRequestException('Неверный код');
    }

    let user = await this.prisma.user.findUnique({ where: { phone } });
    let isNewUser = false;
    if (!user) {
      isNewUser = true;
      const passwordHash = await bcrypt.hash(randomUUID(), BCRYPT_ROUNDS);
      user = await this.prisma.user.create({
        data: {
          phone,
          name: '',
          passwordHash,
        },
      });
    }

    await this.prisma.pendingOtp.delete({ where: { phone } });
    const tokens = this.signPair(user.id);
    const profileName = user.name.trim();
    return {
      ...tokens,
      needsProfileName: isNewUser || profileName.length === 0,
      profileName: profileName,
    };
  }

  async setProfileName(phoneInput: string, nameInput: string) {
    const phone = parseTajikPhone(phoneInput);
    const name = nameInput.trim();
    if (name.length < 2) {
      throw new BadRequestException('Имя слишком короткое');
    }

    const user = await this.prisma.user.findUnique({ where: { phone } });
    if (!user) {
      throw new NotFoundException('Пользователь не найден');
    }

    await this.prisma.user.update({
      where: { phone },
      data: { name },
    });

    return { ok: true as const };
  }

  async changePhone(currentPhoneInput: string, newPhoneInput: string) {
    const currentPhone = parseTajikPhone(currentPhoneInput);
    const newPhone = parseTajikPhone(newPhoneInput);
    if (currentPhone === newPhone) {
      throw new BadRequestException('Новый номер совпадает с текущим');
    }

    const user = await this.prisma.user.findUnique({ where: { phone: currentPhone } });
    if (!user) {
      throw new NotFoundException('Пользователь не найден');
    }

    const exists = await this.prisma.user.findUnique({ where: { phone: newPhone } });
    if (exists) {
      throw new BadRequestException('Этот номер уже используется');
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { phone: newPhone },
    });

    return { ok: true as const, phone: newPhone };
  }

  async refresh(refreshToken: string) {
    const refreshSecret = process.env.JWT_REFRESH_SECRET;
    if (!refreshSecret) {
      throw new UnauthorizedException('Сервер не настроен');
    }
    try {
      const payload = this.jwt.verify<{ sub: string; typ?: string }>(
        refreshToken,
        { secret: refreshSecret },
      );
      if (payload.typ !== 'refresh') throw new UnauthorizedException();

      const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
      if (!user) throw new UnauthorizedException();

      return this.signPair(user.id);
    } catch {
      throw new UnauthorizedException('Сессия устарела, войдите снова');
    }
  }

  private signPair(userId: string) {
    const accessSecret = process.env.JWT_SECRET;
    const refreshSecret = process.env.JWT_REFRESH_SECRET;
    if (!accessSecret || !refreshSecret) {
      throw new Error('JWT_SECRET и JWT_REFRESH_SECRET обязательны в .env');
    }
    const accessExpires = process.env.JWT_ACCESS_EXPIRES ?? '15m';
    const refreshExpires = process.env.JWT_REFRESH_EXPIRES ?? '30d';

    const accessToken = this.jwt.sign(
      { sub: userId },
      { secret: accessSecret, expiresIn: accessExpires },
    );
    const refreshToken = this.jwt.sign(
      { sub: userId, typ: 'refresh' },
      { secret: refreshSecret, expiresIn: refreshExpires },
    );

    return { accessToken, refreshToken };
  }
}
