import { IsOptional, IsString } from 'class-validator';

export class UpdatePickupPointDto {
  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  addressTemplate?: string;
}
