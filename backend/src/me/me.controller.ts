import {
  Body,
  BadRequestException,
  Controller,
  Delete,
  Get,
  Post,
  Query,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Express } from 'express';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RequestUser } from '../auth/auth.types';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { avatarMulterOptions } from './avatar-upload.config';
import { MeService } from './me.service';
import { PushService } from '../notifications/push.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('me')
export class MeController {
  constructor(
    private readonly meService: MeService,
    private readonly push: PushService,
  ) {}

  /**
   * Уникальный код клиента и строка для QR (приложение рисует QR из qrPayload).
   */
  @Roles('client', 'worker_cn', 'worker_tj', 'admin')
  @Get()
  profile(@Req() req: Request) {
    const user = req.user as RequestUser;
    return this.meService.getIdentity(user.id);
  }

  @Roles('client', 'worker_cn', 'worker_tj', 'admin')
  @Get('notifications')
  notifications(@Req() req: Request, @Query('take') takeRaw?: string) {
    const user = req.user as RequestUser;
    const take = Number(takeRaw ?? 120);
    return this.meService.listNotifications(
      user.id,
      Number.isFinite(take) ? take : 120,
    );
  }

  /** Загрузка фото профиля (multipart field `file`). */
  @Roles('client', 'worker_cn', 'worker_tj', 'admin')
  @Post('avatar')
  @UseInterceptors(FileInterceptor('file', avatarMulterOptions()))
  uploadAvatar(@Req() req: Request, @UploadedFile() file: Express.Multer.File) {
    const user = req.user as RequestUser;
    if (!file) {
      throw new BadRequestException('Выберите изображение');
    }
    return this.meService.commitAvatar(user.id, file);
  }

  @Roles('client', 'worker_cn', 'worker_tj', 'admin')
  @Delete('avatar')
  removeAvatar(@Req() req: Request) {
    const user = req.user as RequestUser;
    return this.meService.removeAvatar(user.id);
  }

  @Roles('client', 'worker_cn', 'worker_tj', 'admin')
  @Post('device-token')
  registerDeviceToken(
    @Req() req: Request,
    @Body() body: { token?: string; platform?: string },
  ) {
    const user = req.user as RequestUser;
    const token = body?.token?.trim();
    if (!token) {
      throw new BadRequestException('token обязателен');
    }
    return this.push.registerDeviceToken(
      user.id,
      token,
      body?.platform ?? 'unknown',
    );
  }
}
