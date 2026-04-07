import { IsString, MinLength } from 'class-validator';

export class ChangePhoneDto {
  @IsString()
  @MinLength(9, { message: 'Некорректный текущий номер' })
  currentPhone!: string;

  @IsString()
  @MinLength(9, { message: 'Некорректный новый номер' })
  newPhone!: string;
}
