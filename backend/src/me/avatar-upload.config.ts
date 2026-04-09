import { BadRequestException } from '@nestjs/common';
import { existsSync, mkdirSync } from 'fs';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import type { Request } from 'express';
import type { RequestUser } from '../auth/auth.types';

const ALLOWED_EXT = new Set(['.jpg', '.jpeg', '.png', '.webp', '.gif']);

const mimeToExt: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/gif': '.gif',
};

function ensureUploadsDir() {
  const dir = join(process.cwd(), 'uploads', 'avatars');
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
  return dir;
}

export function avatarMulterOptions() {
  return {
    storage: diskStorage({
      destination: (_req: Request, _file, cb) => {
        cb(null, ensureUploadsDir());
      },
      filename: (req: Request, file, cb) => {
        const user = (req as Request & { user?: RequestUser }).user;
        if (!user?.id) {
          cb(new BadRequestException('Пользователь не определён'), '');
          return;
        }
        const fromMime = mimeToExt[file.mimetype];
        let ext = fromMime ?? extname(file.originalname).toLowerCase();
        if (!ALLOWED_EXT.has(ext)) {
          ext = '.jpg';
        }
        cb(null, `${user.id}${ext}`);
      },
    }),
    limits: { fileSize: 4 * 1024 * 1024 },
    fileFilter: (
      _req: Request,
      file: Express.Multer.File,
      cb: (error: Error | null, acceptFile: boolean) => void,
    ) => {
      if (!file.mimetype.startsWith('image/')) {
        cb(new BadRequestException('Нужен файл изображения'), false);
        return;
      }
      cb(null, true);
    },
  };
}
