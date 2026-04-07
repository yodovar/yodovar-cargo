import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { MeService } from './me.service';

/**
 * Проверка уникального кода клиента (скан QR на складе).
 */
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('client-codes')
export class ClientCodesController {
  constructor(private readonly meService: MeService) {}

  @Roles('worker_tj', 'worker_cn', 'admin')
  @Get(':code')
  lookup(@Param('code') code: string) {
    return this.meService.lookupByClientCode(code);
  }
}
