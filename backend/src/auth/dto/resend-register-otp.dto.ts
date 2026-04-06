import { IsString, MinLength } from 'class-validator';

export class ResendRegisterOtpDto {
  @IsString()
  @MinLength(9, { message: 'Некорректный телефон' })
  phone!: string;
}
