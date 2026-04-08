import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.use(helmet());

  const origins = process.env.CORS_ORIGINS?.trim();
  const parsedOrigins = origins
    ? origins
        .split(',')
        .map((o) => o.trim())
        .filter((o) => o.length > 0)
    : [];
  app.enableCors({
    origin:
      parsedOrigins.length > 0
        ? parsedOrigins
        : process.env.NODE_ENV === 'production'
          ? false
          : true,
    credentials: true,
  });

  const port = Number(process.env.PORT) || 3000;
  await app.listen(port);
}

bootstrap();
