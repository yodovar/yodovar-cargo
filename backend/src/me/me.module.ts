import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ClientCodesController } from './client-codes.controller';
import { MeController } from './me.controller';
import { MeService } from './me.service';

@Module({
  imports: [AuthModule],
  controllers: [MeController, ClientCodesController],
  providers: [MeService],
  exports: [MeService],
})
export class MeModule {}
