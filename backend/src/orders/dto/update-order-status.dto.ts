import { IsIn, IsString } from 'class-validator';

const ORDER_STATUSES = [
  'received_china',
  'in_transit',
  'sorting',
  'ready_pickup',
  'with_courier',
  'completed',
] as const;

export class UpdateOrderStatusDto {
  @IsString()
  @IsIn(ORDER_STATUSES as unknown as string[])
  status!: (typeof ORDER_STATUSES)[number];
}
