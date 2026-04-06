import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { randomInt } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { ResendRegisterOtpDto } from './dto/resend-register-otp.dto';
import { VerifyRegisterDto } from './dto/verify-register.dto';
import { parseTajikPhone } from './phone-tj';
import { SmsService } from './sms.service';

const BCRYPT_ROUNDS = 10;
const OTP_TTL_MS = 10 * 60 * 1000;

function generateSixDigitCode(): string {
  const fixed = process.env.OTP_DEV_CODE?.trim();
  if (
    process.env.NODE_ENV !== 'production' &&
    fixed &&
    /^\d{6}$/.test(fixed)
  ) {
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

  /** Шаг 1: сохранить данные и отправить SMS с 6-значным кодом. */
  async sendRegistrationOtp(dto: RegisterDto) {
    const phone = parseTajikPhone(dto.phone);
    const existing = await this.prisma.user.findUnique({
      where: { phone },
    });
    if (existing) {
      throw new ConflictException('Этот номер уже зарегистрирован');
    }
    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);
    const code = generateSixDigitCode();
    const otpHash = await bcrypt.hash(code, BCRYPT_ROUNDS);
    const expiresAt = new Date(Date.now() + OTP_TTL_MS);

    await this.prisma.pendingRegistration.upsert({
      where: { phone },
      create: {
        phone,
        name: dto.name.trim(),
        passwordHash,
        otpHash,
        expiresAt,
      },
      update: {
        name: dto.name.trim(),
        passwordHash,
        otpHash,
        expiresAt,
      },
    });

    await this.sms.sendOtp(phone, code);
    return { ok: true as const };
  }

  /** Шаг 2: проверить код и создать пользователя. */
  async verifyRegistrationOtp(dto: VerifyRegisterDto) {
    const phone = parseTajikPhone(dto.phone);
    const pending = await this.prisma.pendingRegistration.findUnique({
      where: { phone },
    });
    if (!pending) {
      throw new NotFoundException(
        'Заявка не найдена. Начните регистрацию заново.',
      );
    }
    if (pending.expiresAt < new Date()) {
      await this.prisma.pendingRegistration.delete({ where: { phone } });
      throw new BadRequestException('Код устарел. Запросите новый.');
    }
    const codeOk = await bcrypt.compare(dto.code, pending.otpHash);
    if (!codeOk) {
      throw new BadRequestException('Неверный код');
    }

    const user = await this.prisma.user.create({
      data: {
        phone,
        name: pending.name,
        passwordHash: pending.passwordHash,
      },
    });
    await this.prisma.pendingRegistration.delete({ where: { phone } });
    return this.signPair(user.id);
  }

  /** Повторная отправка кода (тот же номер, данные уже в Pending). */
  async resendRegistrationOtp(dto: ResendRegisterOtpDto) {
    const phone = parseTajikPhone(dto.phone);
    const pending = await this.prisma.pendingRegistration.findUnique({
      where: { phone },
    });
    if (!pending) {
      throw new NotFoundException(
        'Нет активной регистрации на этот номер. Заполните форму снова.',
      );
    }
    const code = generateSixDigitCode();
    const otpHash = await bcrypt.hash(code, BCRYPT_ROUNDS);
    const expiresAt = new Date(Date.now() + OTP_TTL_MS);
    await this.prisma.pendingRegistration.update({
      where: { phone },
      data: { otpHash, expiresAt },
    });
    await this.sms.sendOtp(phone, code);
    return { ok: true as const };
  }

  async login(dto: LoginDto) {
    const phone = parseTajikPhone(dto.phone);
    const user = await this.prisma.user.findUnique({ where: { phone } });
    if (!user) {
      throw new UnauthorizedException('Неверный телефон или пароль');
    }
    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Неверный телефон или пароль');
    }
    return this.signPair(user.id);
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
      if (payload.typ !== 'refresh') {
        throw new UnauthorizedException();
      }
      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });
      if (!user) {
        throw new UnauthorizedException();
      }
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
    const accessExpires =
      process.env.JWT_ACCESS_EXPIRES ?? process.env.JWT_EXPIRES ?? '15m';
    const refreshExpires = process.env.JWT_REFRESH_EXPIRES ?? '30d';

    const accessToken = this.jwt.sign({ sub: userId }, {
      secret: accessSecret,
      expiresIn: accessExpires,
    });
    const refreshToken = this.jwt.sign(
      { sub: userId, typ: 'refresh' },
      { secret: refreshSecret, expiresIn: refreshExpires },
    );

    return { accessToken, refreshToken };
  }
}
