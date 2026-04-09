import { Module } from '@nestjs/common';
import { AuditModule } from '../audit/audit.module';
import { AuthModule } from '../auth/auth.module';
import { MeModule } from '../me/me.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { WarehouseCnController } from './warehouse-cn.controller';
import { WarehouseCnService } from './warehouse-cn.service';
import { WarehouseTjController } from './warehouse-tj.controller';
import { WarehouseTjService } from './warehouse-tj.service';

@Module({
  imports: [AuthModule, AuditModule, MeModule, NotificationsModule],
  controllers: [WarehouseCnController, WarehouseTjController],
  providers: [WarehouseCnService, WarehouseTjService],
})
export class WarehouseModule {}
