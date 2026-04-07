import { Body, Controller, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RequestUser } from '../auth/auth.types';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CnIntakeDto } from './dto/cn-intake.dto';
import { CnStatusDto } from './dto/cn-status.dto';
import { CnWeightDto } from './dto/cn-weight.dto';
import { WarehouseCnService } from './warehouse-cn.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('warehouse-cn')
export class WarehouseCnController {
  constructor(private readonly warehouseCn: WarehouseCnService) {}

  /** Приёмка товара на складе КНР: трек + код клиента, опционально вес. */
  @Roles('worker_cn', 'admin')
  @Post('intake')
  intake(@Req() req: Request, @Body() dto: CnIntakeDto) {
    const actor = req.user as RequestUser;
    return this.warehouseCn.intake(actor.id, dto);
  }

  @Roles('worker_cn', 'admin')
  @Patch('orders/:id/weight')
  setWeight(
    @Req() req: Request,
    @Param('id') id: string,
    @Body() dto: CnWeightDto,
  ) {
    const actor = req.user as RequestUser;
    return this.warehouseCn.setWeight(actor.id, id, dto.weightGrams);
  }

  @Roles('worker_cn', 'admin')
  @Patch('orders/:id/status')
  setStatus(
    @Req() req: Request,
    @Param('id') id: string,
    @Body() dto: CnStatusDto,
  ) {
    const actor = req.user as RequestUser;
    return this.warehouseCn.setStatus(actor.id, id, dto.status);
  }
}
