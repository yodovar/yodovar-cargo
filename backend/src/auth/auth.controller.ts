import {
  BadRequestException,
  Body,
  Controller,
  Post,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { RegisterDto } from './dto/register.dto';
import { ResendRegisterOtpDto } from './dto/resend-register-otp.dto';
import { VerifyRegisterDto } from './dto/verify-register.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register/send-otp')
  sendRegistrationOtp(@Body() dto: RegisterDto) {
    return this.auth.sendRegistrationOtp(dto);
  }

  @Post('register/verify')
  verifyRegistration(@Body() dto: VerifyRegisterDto) {
    return this.auth.verifyRegistrationOtp(dto);
  }

  @Post('register/resend-otp')
  resendRegistrationOtp(@Body() dto: ResendRegisterOtpDto) {
    return this.auth.resendRegistrationOtp(dto);
  }

  /** Подсказка для старых клиентов / Postman (раньше был один POST /auth/register). */
  @Post('register')
  registerLegacy() {
    throw new BadRequestException(
      'Этот URL больше не используется. Сначала POST /auth/register/send-otp с полями name, phone, password, затем POST /auth/register/verify с phone и code (6 цифр). См. backend/README.md',
    );
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Post('refresh')
  refresh(@Body() dto: RefreshDto) {
    return this.auth.refresh(dto.refreshToken);
  }
}
