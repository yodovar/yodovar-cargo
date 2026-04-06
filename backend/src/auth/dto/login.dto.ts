import { IsString, MinLength } from 'class-validator';

export class LoginDto {
  @IsString()
  @MinLength(9, { message: 'Некорректный телефон' })
  phone!: string;

  @IsString()
  @MinLength(1, { message: 'Введите пароль' })
  password!: string;
}
