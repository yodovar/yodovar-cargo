import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
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

  const origins = process.env.CORS_ORIGINS?.trim();
  app.enableCors({
    origin: origins ? origins.split(',').map((o) => o.trim()) : true,
    credentials: true,
  });

  const port = Number(process.env.PORT) || 3000;
  await app.listen(port);
}

bootstrap();
