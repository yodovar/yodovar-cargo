import { Body, Controller, Get, Param, Patch, Query, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RequestUser } from '../auth/auth.types';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { OrdersService } from './orders.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('orders')
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Roles('client', 'worker_cn', 'worker_tj', 'admin')
  @Get('summary')
  summary(@Req() req: Request) {
    const actor = req.user as RequestUser;
    return this.orders.summary(actor.id, actor.role);
  }

  @Roles('client', 'worker_cn', 'worker_tj', 'admin')
  @Get()
  list(
    @Req() req: Request,
    @Query('status') status?: string,
    @Query('take') take?: string,
  ) {
    const actor = req.user as RequestUser;
    const parsedTake = Number.parseInt(String(take ?? '100'), 10);
    return this.orders.list(actor.id, actor.role, {
      status: status?.trim() || undefined,
      take: Number.isFinite(parsedTake) ? parsedTake : 100,
    });
  }

  @Roles('client', 'worker_cn', 'worker_tj', 'admin')
  @Get('search')
  search(@Req() req: Request, @Query('trackingCode') trackingCode?: string) {
    const actor = req.user as RequestUser;
    return this.orders.findByTrackingCode(actor.id, actor.role, trackingCode ?? '');
  }

  @Roles('worker_cn', 'worker_tj', 'admin')
  @Patch(':id/status')
  updateStatus(
    @Req() req: Request,
    @Param('id') id: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    const actor = req.user as RequestUser;
    return this.orders.updateStatus(id, dto.status, actor.id);
  }
}
