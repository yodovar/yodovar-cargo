import { IsIn, IsString } from 'class-validator';
import { WAREHOUSE_CN_STATUSES } from '../warehouse.constants';

export class CnStatusDto {
  @IsString()
  @IsIn([...WAREHOUSE_CN_STATUSES])
  status!: (typeof WAREHOUSE_CN_STATUSES)[number];
}
