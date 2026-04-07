import { BadRequestException, Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { RegisterDto } from './dto/register.dto';
import { RequestOtpDto } from './dto/request-otp.dto';
import { ResendRegisterOtpDto } from './dto/resend-register-otp.dto';
import { VerifyRegisterDto } from './dto/verify-register.dto';
import { SetProfileNameDto } from './dto/set-profile-name.dto';
import { ChangePhoneDto } from './dto/change-phone.dto';
import { StaffLoginDto } from './dto/staff-login.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('request-otp')
  requestOtp(@Body() dto: RequestOtpDto) {
    return this.auth.requestOtp(dto.phone);
  }

  @Post('verify-otp')
  verifyOtp(@Body() dto: VerifyRegisterDto) {
    return this.auth.verifyOtp(dto.phone, dto.code);
  }

  @Post('resend-otp')
  resendOtp(@Body() dto: ResendRegisterOtpDto) {
    return this.auth.resendOtp(dto.phone);
  }

  // Backward compatibility for old mobile builds.
  @Post('register/send-otp')
  sendRegistrationOtp(@Body() dto: RegisterDto) {
    return this.auth.requestOtp(dto.phone);
  }

  @Post('register/verify')
  verifyRegistration(@Body() dto: VerifyRegisterDto) {
    return this.auth.verifyOtp(dto.phone, dto.code);
  }

  @Post('register/resend-otp')
  resendRegistrationOtp(@Body() dto: ResendRegisterOtpDto) {
    return this.auth.resendOtp(dto.phone);
  }

  @Post('register')
  registerLegacy() {
    throw new BadRequestException(
      'Используйте flow по OTP: /auth/request-otp -> /auth/verify-otp',
    );
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.auth.requestOtp(dto.phone);
  }

  @Post('staff-login')
  staffLogin(@Body() dto: StaffLoginDto) {
    return this.auth.staffLogin(dto.name, dto.password);
  }

  @Post('set-profile-name')
  setProfileName(@Body() dto: SetProfileNameDto) {
    return this.auth.setProfileName(dto.phone, dto.name);
  }

  @Post('change-phone')
  changePhone(@Body() dto: ChangePhoneDto) {
    return this.auth.changePhone(dto.currentPhone, dto.newPhone);
  }

  @Post('refresh')
  refresh(@Body() dto: RefreshDto) {
    return this.auth.refresh(dto.refreshToken);
  }
}
