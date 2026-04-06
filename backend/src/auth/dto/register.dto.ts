import { IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @IsString()
  @MinLength(2, { message: 'Имя слишком короткое' })
  name!: string;

  @IsString()
  @MinLength(9, { message: 'Некорректный телефон' })
  phone!: string;

  @IsString()
  @MinLength(6, { message: 'Пароль минимум 6 символов' })
  password!: string;
}
