import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_messenger.dart';
import '../../core/lang.dart';
import '../../core/app_theme.dart';
import 'auth_repository.dart';
import 'auth_session.dart';
import 'auth_shell.dart';

/// Подтверждение номера 6-значным кодом из SMS.
class RegisterOtpScreen extends ConsumerStatefulWidget {
  const RegisterOtpScreen({
    super.key,
    required this.phone,
    this.displayName,
  });

  final String phone;
  final String? displayName;

  @override
  ConsumerState<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends ConsumerState<RegisterOtpScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false;
  bool _resendLoading = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown(60);
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _cooldown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final digits = _code.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) {
      appMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(tr(context, ru: 'Введите 6 цифр из SMS', tg: '6 рақамро аз SMS ворид кунед')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).registerVerify(
            phone: widget.phone,
            code: digits,
          );
      if (!mounted) return;
      final name = widget.displayName?.trim();
      if (name != null && name.isNotEmpty) {
        await ref.read(userPrefsProvider).setDisplayName(name);
      }
      await ref.read(authSessionProvider.notifier).markSignedIn();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (!mounted) return;
      appMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(tr(context, ru: 'Номер подтверждён, вы вошли', tg: 'Рақам тасдиқ шуд, шумо ворид шудед')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      appMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(messageFromDio(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resendLoading) return;
    setState(() => _resendLoading = true);
    try {
      await ref.read(authRepositoryProvider).registerResendOtp(
            phone: widget.phone,
          );
      if (!mounted) return;
      _startCooldown(60);
      appMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(tr(context, ru: 'Код отправлен повторно', tg: 'Код дубора фиристода шуд')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      appMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(messageFromDio(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: tr(context, ru: 'Подтверждение номера', tg: 'Тасдиқи рақам'),
      subtitle:
          tr(context, ru: 'Введите 6 цифр из SMS, отправленного на\n${widget.phone}', tg: '6 рақамро аз SMS-и фиристодашуда ба\n${widget.phone} ворид кунед'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: _code,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofocus: true,
              maxLength: 6,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: authInputDecoration(
                context: context,
                label: tr(context, ru: 'Код из SMS', tg: 'Код аз SMS'),
                hint: '• • • • • •',
              ).copyWith(
                counterText: '',
                hintStyle: TextStyle(
                  letterSpacing: 4,
                  color: Colors.grey.shade400,
                ),
              ),
              onFieldSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(tr(context, ru: 'Подтвердить', tg: 'Тасдиқ кардан')),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: (_cooldown > 0 || _resendLoading) ? null : _resend,
              child: _resendLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _cooldown > 0
                          ? tr(context, ru: 'Отправить снова через $_cooldown с', tg: 'Боз фиристодан баъди $_cooldown с')
                          : tr(context, ru: 'Отправить код снова', tg: 'Кодро боз фиристодан'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandRed,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
