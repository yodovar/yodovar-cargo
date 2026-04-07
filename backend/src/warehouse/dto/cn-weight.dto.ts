import { IsInt, Min } from 'class-validator';

export class CnWeightDto {
  @IsInt()
  @Min(1)
  weightGrams!: number;
}
