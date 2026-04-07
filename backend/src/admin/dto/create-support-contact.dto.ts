import { IsString, MinLength } from 'class-validator';

export class CreateSupportContactDto {
  @IsString()
  @MinLength(2)
  key!: string;

  @IsString()
  @MinLength(1)
  label!: string;

  @IsString()
  @MinLength(1)
  usernameOrPhone!: string;

  @IsString()
  @MinLength(1)
  appUrl!: string;

  @IsString()
  @MinLength(1)
  webUrl!: string;
}
