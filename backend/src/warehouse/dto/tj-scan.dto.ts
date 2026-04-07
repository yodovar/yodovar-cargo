import { IsString, MinLength } from 'class-validator';

export class TjScanDto {
  @IsString()
  @MinLength(4)
  code!: string;
}
