import { IsString, MinLength } from 'class-validator';

export class SetProfileNameDto {
  @IsString()
  @MinLength(9, { message: 'Некорректный телефон' })
  phone!: string;

  @IsString()
  @MinLength(2, { message: 'Имя слишком короткое' })
  name!: string;
}
