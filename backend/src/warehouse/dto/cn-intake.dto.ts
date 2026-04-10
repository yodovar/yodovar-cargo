import { IsInt, IsOptional, IsString, Min, MinLength } from 'class-validator';
import { Transform } from 'class-transformer';

export class CnIntakeDto {
  @IsString()
  @MinLength(3)
  trackingCode!: string;

  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' && value.trim() === '' ? undefined : value))
  @IsString()
  @MinLength(4)
  clientCode?: string;

  @IsOptional()
  @IsString()
  @MinLength(2)
  guestName?: string;

  @IsOptional()
  @IsString()
  @MinLength(5)
  guestPhone?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  weightGrams?: number;
}
