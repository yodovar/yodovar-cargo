import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/app_messenger.dart';
import '../../core/tj_phone.dart';
import 'auth_repository.dart';
import 'auth_session.dart';
import 'auth_shell.dart';
import 'tj_phone_field.dart';
import 'username_setup_screen.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final phone = TjPhone.e164FromField(_phone.text);
    try {
      await ref.read(authRepositoryProvider).requestOtp(phone: phone);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _OtpBottomSheet(phone: phone),
      );
    } catch (e) {
      appMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(messageFromDio(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Регистрация / Вход',
      subtitle:
          'Введите номер (+992). Мы отправим SMS-код. Без пароля и без лишних шагов.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TjPhoneFormField(
                controller: _phone,
                textInputAction: TextInputAction.done,
                validator: TjPhone.validateNationalField,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Получить код'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBottomSheet extends ConsumerStatefulWidget {
  const _OtpBottomSheet({required this.phone});

  final String phone;

  @override
  ConsumerState<_OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends ConsumerState<_OtpBottomSheet> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _cooldown = 60;
  bool _loading = false;
  bool _resendLoading = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_cooldown <= 0) {
        t.cancel();
      } else {
        setState(() => _cooldown--);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
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
        const SnackBar(content: Text('Введите 6 цифр кода')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ref.read(authRepositoryProvider).verifyOtp(
            phone: widget.phone,
            code: digits,
          );

      final prefs = ref.read(userPrefsProvider);
      await prefs.setPhone(widget.phone);
      if (result.profileName.isNotEmpty) {
        await prefs.setDisplayName(result.profileName);
      }

      if (result.needsProfileName) {
        if (!mounted) return;
        Navigator.of(context).pop();
        await Navigator.of(context, rootNavigator: true).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => UsernameSetupScreen(phone: widget.phone),
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      await ref.read(authSessionProvider.notifier).markSignedIn();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
      appMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Успешный вход')),
      );
    } catch (e) {
      appMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(messageFromDio(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resendLoading) return;
    setState(() => _resendLoading = true);
    try {
      await ref.read(authRepositoryProvider).resendOtp(phone: widget.phone);
      _timer?.cancel();
      setState(() => _cooldown = 60);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_cooldown <= 0) {
          t.cancel();
        } else {
          setState(() => _cooldown--);
        }
      });
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final btm = MediaQuery.viewInsetsOf(context).bottom;
    final digits = _code.text.replaceAll(RegExp(r'\D'), '');

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: btm),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Подтверждение номера',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(widget.phone, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => _focus.requestFocus(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  final ch = i < digits.length ? digits[i] : '';
                  return Container(
                    width: 46,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: i == digits.length
                            ? AppTheme.brandRed
                            : Colors.grey.shade300,
                        width: i == digits.length ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      ch,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }),
              ),
            ),
            Opacity(
              opacity: 0,
              child: TextField(
                controller: _code,
                focusNode: _focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _verify(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Подтвердить'),
            ),
            TextButton(
              onPressed: (_cooldown > 0 || _resendLoading) ? null : _resend,
              child: Text(
                _cooldown > 0
                    ? 'Отправить снова через $_cooldown с'
                    : 'Отправить код снова',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
