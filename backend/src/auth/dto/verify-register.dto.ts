import { IsString, Length, Matches, MaxLength, MinLength } from 'class-validator';

export class VerifyRegisterDto {
  @IsString()
  @MinLength(9)
  @MaxLength(24)
  phone!: string;

  @IsString()
  @Length(6, 6, { message: 'Код из 6 цифр' })
  @Matches(/^\d{6}$/, { message: 'Только цифры' })
  code!: string;
}
