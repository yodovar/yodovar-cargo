import {
  BadRequestException,
  Controller,
  Delete,
  Get,
  Post,
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
}
