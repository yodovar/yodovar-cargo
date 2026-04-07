import { Type } from 'class-transformer';
import {
  IsArray,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';
import { TariffDetailItemDto } from './create-tariff.dto';

export class UpdateTariffDto {
  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  pricePerKgUsd?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  pricePerCubicUsd?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  minChargeWeightG?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  etaDaysMin?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  etaDaysMax?: number;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => TariffDetailItemDto)
  details?: TariffDetailItemDto[];
}
