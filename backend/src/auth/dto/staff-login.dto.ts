import { IsString, MinLength } from 'class-validator';

export class StaffLoginDto {
  @IsString()
  @MinLength(2)
  name!: string;

  @IsString()
  @MinLength(6)
  password!: string;
}
