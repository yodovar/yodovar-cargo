import { IsOptional, IsString } from 'class-validator';

export class UpdateSupportContactDto {
  @IsOptional()
  @IsString()
  label?: string;

  @IsOptional()
  @IsString()
  usernameOrPhone?: string;

  @IsOptional()
  @IsString()
  appUrl?: string;

  @IsOptional()
  @IsString()
  webUrl?: string;
}
