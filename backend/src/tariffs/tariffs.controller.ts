import { Controller, Get } from '@nestjs/common';
import { TariffsService } from './tariffs.service';

@Controller('tariffs')
export class TariffsController {
  constructor(private readonly tariffs: TariffsService) {}

  @Get()
  list() {
    return this.tariffs.listPublicTariffs();
  }

  @Get('support-contacts')
  listSupportContacts() {
    return this.tariffs.listSupportContacts();
  }

  @Get('pickup-points')
  listPickupPoints() {
    return this.tariffs.listPickupPoints();
  }
}
