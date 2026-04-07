import { IsInt, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class CnIntakeDto {
  @IsString()
  @MinLength(3)
  trackingCode!: string;

  @IsString()
  @MinLength(4)
  clientCode!: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  weightGrams?: number;
}
