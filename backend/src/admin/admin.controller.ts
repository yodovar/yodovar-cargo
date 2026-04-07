import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RequestUser } from '../auth/auth.types';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CreateSupportContactDto } from './dto/create-support-contact.dto';
import { CreateTariffDto } from './dto/create-tariff.dto';
import { UpdateSupportContactDto } from './dto/update-support-contact.dto';
import { UpdateTariffDto } from './dto/update-tariff.dto';
import { UpdateUserRoleDto } from './dto/update-user-role.dto';
import { AdminService } from './admin.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
@Controller('admin')
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('users')
  listUsers(
    @Query('skip') skipStr?: string,
    @Query('take') takeStr?: string,
    @Query('role') role?: UserRole,
    @Query('q') q?: string,
  ) {
    const skip = Math.max(0, parseInt(skipStr ?? '0', 10) || 0);
    const take = Math.min(100, Math.max(1, parseInt(takeStr ?? '50', 10) || 50));
    return this.admin.listUsers({ skip, take, role, q });
  }

  @Get('orders')
  listOrders(
    @Query('skip') skipStr?: string,
    @Query('take') takeStr?: string,
    @Query('status') status?: string,
    @Query('trackingCode') trackingCode?: string,
    @Query('clientCode') clientCode?: string,
  ) {
    const skip = Math.max(0, parseInt(skipStr ?? '0', 10) || 0);
    const take = Math.min(100, Math.max(1, parseInt(takeStr ?? '50', 10) || 50));
    return this.admin.listOrders({
      skip,
      take,
      status,
      trackingCode,
      clientCode,
    });
  }

  @Patch('users/:id/role')
  setUserRole(
    @Req() req: Request,
    @Param('id') userId: string,
    @Body() dto: UpdateUserRoleDto,
  ) {
    const actor = req.user as RequestUser;
    return this.admin.setUserRole(actor.id, userId, dto.role);
  }

  @Post('tariffs')
  createTariff(@Req() req: Request, @Body() dto: CreateTariffDto) {
    const actor = req.user as RequestUser;
    return this.admin.createTariff(actor.id, dto);
  }

  @Patch('tariffs/:key')
  updateTariff(@Req() req: Request, @Param('key') key: string, @Body() dto: UpdateTariffDto) {
    const actor = req.user as RequestUser;
    return this.admin.updateTariff(actor.id, key, dto);
  }

  @Delete('tariffs/:key')
  deleteTariff(@Req() req: Request, @Param('key') key: string) {
    const actor = req.user as RequestUser;
    return this.admin.deleteTariff(actor.id, key);
  }

  @Post('support-contacts')
  createSupportContact(@Req() req: Request, @Body() dto: CreateSupportContactDto) {
    const actor = req.user as RequestUser;
    return this.admin.createSupportContact(actor.id, dto);
  }

  @Patch('support-contacts/:key')
  updateSupportContact(
    @Req() req: Request,
    @Param('key') key: string,
    @Body() dto: UpdateSupportContactDto,
  ) {
    const actor = req.user as RequestUser;
    return this.admin.updateSupportContact(actor.id, key, dto);
  }

  @Delete('support-contacts/:key')
  deleteSupportContact(@Req() req: Request, @Param('key') key: string) {
    const actor = req.user as RequestUser;
    return this.admin.deleteSupportContact(actor.id, key);
  }

  @Get('audit')
  audit(@Query('limit') limit?: string) {
    const parsed = Number(limit ?? '100');
    return this.admin.listAudit(Number.isFinite(parsed) ? parsed : 100);
  }
}
