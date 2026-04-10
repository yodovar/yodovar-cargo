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
import { CreateChannelPostDto } from './dto/create-channel-post.dto';
import { CreatePickupPointDto } from './dto/create-pickup-point.dto';
import { UpdateSupportContactDto } from './dto/update-support-contact.dto';
import { UpdatePickupPointDto } from './dto/update-pickup-point.dto';
import { UpdateTariffDto } from './dto/update-tariff.dto';
import { UpdateUserRoleDto } from './dto/update-user-role.dto';
import { AdminService } from './admin.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
@Controller('admin')
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('users')
  @Roles('admin', 'worker_cn', 'worker_tj')
  listUsers(
    @Req() req: Request,
    @Query('skip') skipStr?: string,
    @Query('take') takeStr?: string,
    @Query('role') roleQuery?: UserRole,
    @Query('q') q?: string,
  ) {
    const user = req.user as RequestUser;
    const role = user.role === 'admin' ? roleQuery : ('client' as UserRole);
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
    @Query('withoutClient') withoutClient?: string,
  ) {
    const skip = Math.max(0, parseInt(skipStr ?? '0', 10) || 0);
    const take = Math.min(100, Math.max(1, parseInt(takeStr ?? '50', 10) || 50));
    return this.admin.listOrders({
      skip,
      take,
      status,
      trackingCode,
      clientCode,
      withoutClient:
        withoutClient === '1' ||
        withoutClient === 'true' ||
        withoutClient === 'yes',
    });
  }

  @Get('orders-summary')
  @Roles('admin', 'worker_cn', 'worker_tj')
  ordersSummary() {
    return this.admin.ordersSummary();
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

  @Get('pickup-points')
  listPickupPoints() {
    return this.admin.listPickupPoints();
  }

  @Post('pickup-points')
  createPickupPoint(@Req() req: Request, @Body() dto: CreatePickupPointDto) {
    const actor = req.user as RequestUser;
    return this.admin.createPickupPoint(actor.id, dto);
  }

  @Patch('pickup-points/:key')
  updatePickupPoint(
    @Req() req: Request,
    @Param('key') key: string,
    @Body() dto: UpdatePickupPointDto,
  ) {
    const actor = req.user as RequestUser;
    return this.admin.updatePickupPoint(actor.id, key, dto);
  }

  @Delete('pickup-points/:key')
  deletePickupPoint(@Req() req: Request, @Param('key') key: string) {
    const actor = req.user as RequestUser;
    return this.admin.deletePickupPoint(actor.id, key);
  }

  @Get('audit')
  audit(@Query('limit') limit?: string) {
    const parsed = Number(limit ?? '100');
    return this.admin.listAudit(Number.isFinite(parsed) ? parsed : 100);
  }

  @Get('channel-posts')
  listChannelPosts(@Query('take') takeRaw?: string) {
    const take = Number.parseInt(String(takeRaw ?? '80'), 10);
    return this.admin.listChannelPosts(Number.isFinite(take) ? take : 80);
  }

  @Post('channel-posts')
  createChannelPost(@Req() req: Request, @Body() dto: CreateChannelPostDto) {
    const actor = req.user as RequestUser;
    return this.admin.createChannelPost(actor.id, dto);
  }
}
