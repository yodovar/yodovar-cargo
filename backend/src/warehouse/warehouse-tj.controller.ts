import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RequestUser } from '../auth/auth.types';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { TjScanDto } from './dto/tj-scan.dto';
import { WarehouseTjService } from './warehouse-tj.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('warehouse-tj')
export class WarehouseTjController {
  constructor(private readonly warehouseTj: WarehouseTjService) {}

  /** Скан QR / ввод кода: клиент + заказы к выдаче. */
  @Roles('worker_tj', 'admin')
  @Post('scan')
  scan(@Body() dto: TjScanDto) {
    return this.warehouseTj.scan(dto.code);
  }

  /** Список заказов к выдаче по clientCode (без тела запроса). */
  @Roles('worker_tj', 'admin')
  @Get('ready-orders')
  readyOrders(@Query('clientCode') clientCode?: string) {
    if (!clientCode?.trim()) {
      return { found: false as const, orders: [] };
    }
    return this.warehouseTj.readyOrdersByClientCode(clientCode);
  }

  /** Подтверждение выдачи клиенту. */
  @Roles('worker_tj', 'admin')
  @Post('orders/:id/handover')
  handover(@Req() req: Request, @Param('id') id: string) {
    const actor = req.user as RequestUser;
    return this.warehouseTj.handover(actor.id, id);
  }
}
