import { BadRequestException } from '@nestjs/common';

/**
 * Единый формат: +992 и ровно 9 цифр национального номера (Таджикистан).
 */
export function parseTajikPhone(input: string): string {
  const trimmed = input.trim().replace(/\s/g, '');
  let digits = trimmed.startsWith('+')
    ? trimmed.slice(1).replace(/\D/g, '')
    : trimmed.replace(/\D/g, '');
  if (digits.startsWith('992')) digits = digits.slice(3);
  if (digits.length === 10 && digits.startsWith('0')) digits = digits.slice(1);
  if (!/^\d{9}$/.test(digits)) {
    throw new BadRequestException(
      'Номер Таджикистана: после +992 должно быть 9 цифр',
    );
  }
  return `+992${digits}`;
}
