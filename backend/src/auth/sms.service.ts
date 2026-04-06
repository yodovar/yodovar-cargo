import { Injectable, Logger } from '@nestjs/common';

/**
 * Заглушка SMS. В продакшене подключите Twilio / местного провайдера.
 * В development код дублируется в лог; при OTP_DEV_CODE в .env можно
 * использовать фиксированный код для тестов (см. AuthService).
 */
@Injectable()
export class SmsService {
  private readonly log = new Logger(SmsService.name);

  async sendOtp(phone: string, code: string): Promise<void> {
    this.log.warn(`[SMS stub] OTP для ${phone}: ${code}`);
  }
}
