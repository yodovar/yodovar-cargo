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
  summary() {
    return this.orders.summary();
  }

  @Roles('client', 'worker_cn', 'worker_tj', 'admin')
  @Get('search')
  search(@Query('trackingCode') trackingCode?: string) {
    return this.orders.findByTrackingCode(trackingCode ?? '');
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
