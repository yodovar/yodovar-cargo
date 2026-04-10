import { IsString, MinLength } from 'class-validator';

export class CreatePickupPointDto {
  @IsString()
  @MinLength(2)
  key!: string;

  @IsString()
  @MinLength(1)
  city!: string;

  @IsString()
  @MinLength(4)
  addressTemplate!: string;
}
