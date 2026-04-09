import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { RequestUser } from '../auth/auth.types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { ReactChannelPostDto } from './dto/react-channel-post.dto';
import { ChannelsService } from './channels.service';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('channels')
export class ChannelsController {
  constructor(private readonly channels: ChannelsService) {}

  @Roles('client', 'worker_cn', 'worker_tj', 'admin')
  @Get('posts')
  list(@Req() req: Request, @Query('take') takeRaw?: string) {
    const user = req.user as RequestUser;
    const take = Number.parseInt(String(takeRaw ?? '40'), 10);
    return this.channels.listPostsForUser(user.id, Number.isFinite(take) ? take : 40);
  }

  @Roles('client', 'worker_cn', 'worker_tj', 'admin')
  @Post('posts/:id/reactions')
  react(@Req() req: Request, @Param('id') id: string, @Body() dto: ReactChannelPostDto) {
    const user = req.user as RequestUser;
    return this.channels.reactToPost(id, user.id, dto.emoji);
  }
}
