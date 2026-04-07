import { IsString, MinLength } from 'class-validator';

export class RequestOtpDto {
  @IsString()
  @MinLength(9, { message: 'Некорректный телефон' })
  phone!: string;
}
