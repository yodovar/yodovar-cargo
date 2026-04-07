import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RequestUser } from '../auth/auth.types';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { MeService } from './me.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('me')
export class MeController {
  constructor(private readonly meService: MeService) {}

  /**
   * Уникальный код клиента и строка для QR (приложение рисует QR из qrPayload).
   */
  @Roles('client', 'worker_cn', 'worker_tj', 'admin')
  @Get()
  profile(@Req() req: Request) {
    const user = req.user as RequestUser;
    return this.meService.getIdentity(user.id);
  }
}
