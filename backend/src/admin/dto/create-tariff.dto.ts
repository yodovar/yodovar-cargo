import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsInt,
  IsNumber,
  IsString,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class TariffDetailItemDto {
  @IsString()
  icon!: string;

  @IsString()
  @MinLength(1)
  text!: string;
}

export class CreateTariffDto {
  @IsString()
  @MinLength(2)
  key!: string;

  @IsString()
  @MinLength(2)
  title!: string;

  @IsNumber()
  @Min(0)
  pricePerKgUsd!: number;

  @IsNumber()
  @Min(0)
  pricePerCubicUsd!: number;

  @IsInt()
  @Min(0)
  minChargeWeightG!: number;

  @IsInt()
  @Min(1)
  etaDaysMin!: number;

  @IsInt()
  @Min(1)
  etaDaysMax!: number;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => TariffDetailItemDto)
  details!: TariffDetailItemDto[];
}
