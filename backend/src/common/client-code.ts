import { randomInt } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';

const LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

function randomLetters2(): string {
  const a = LETTERS[randomInt(0, LETTERS.length)];
  const b = LETTERS[randomInt(0, LETTERS.length)];
  return `${a}${b}`;
}

/**
 * Генерирует уникальный код вида AP789 (2 буквы + 3 цифры = 5 символов).
 * Проверяет уникальность в БД.
 */
export async function generateUniqueClientCode(prisma: PrismaService): Promise<string> {
  for (let attempt = 0; attempt < 120; attempt++) {
    const letters = randomLetters2();
    const num = randomInt(0, 1000);
    const code = `${letters}${String(num).padStart(3, '0')}`;
    const exists = await prisma.user.findUnique({
      where: { clientCode: code },
      select: { id: true },
    });
    if (!exists) return code;
  }
  throw new Error('Failed to allocate unique clientCode');
}

/** Строка для QR (клиентское приложение кодирует её в изображение). */
export function buildQrPayload(clientCode: string): string {
  const base = process.env.CLIENT_QR_SCHEME_BASE?.trim() || 'yodovar-cargo://client';
  return `${base}/${clientCode}`;
}
