import { randomInt } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';

/** Префиксы в стиле SF, KH, YD (как в ТЗ). */
const PREFIXES = ['SF', 'KH', 'YD', 'TB', 'ZK', 'AB', 'NV', 'QR'] as const;

/**
 * Генерирует уникальный код вида SF3456 (2 буквы + 4 цифры).
 * Проверяет уникальность в БД.
 */
export async function generateUniqueClientCode(prisma: PrismaService): Promise<string> {
  for (let attempt = 0; attempt < 80; attempt++) {
    const prefix = PREFIXES[randomInt(0, PREFIXES.length)];
    const num = randomInt(0, 10_000);
    const code = `${prefix}${String(num).padStart(4, '0')}`;
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
