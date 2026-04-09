import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    }),
  );

  const origins = process.env.CORS_ORIGINS?.trim();
  const parsedOrigins = origins
    ? origins
        .split(',')
        .map((o) => o.trim())
        .filter((o) => o.length > 0)
    : [];
  // До статики: чтобы GET /uploads/... получали CORS (иначе Image.network / web ломаются).
  app.enableCors({
    origin:
      parsedOrigins.length > 0
        ? parsedOrigins
        : process.env.NODE_ENV === 'production'
          ? false
          : true,
    credentials: true,
  });

  app.useStaticAssets(join(process.cwd(), 'uploads'), { prefix: '/uploads/' });

  const port = Number(process.env.PORT) || 3000;
  await app.listen(port);
}

bootstrap();
