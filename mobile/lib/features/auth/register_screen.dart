import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_messenger.dart';
import '../../core/tj_phone.dart';
import 'auth_repository.dart';
import 'auth_shell.dart';
import 'login_screen.dart';
import 'register_otp_screen.dart';
import 'tj_phone_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    if ((v ?? '').trim().length < 2) return 'Как к вам обращаться?';
    return null;
  }

  String? _validatePassword(String? v) {
    if ((v ?? '').length < 6) return 'Минимум 6 символов';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _password.text) return 'Пароли не совпадают';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final phone = TjPhone.e164FromField(_phone.text);
    try {
      await ref.read(authRepositoryProvider).registerSendOtp(
            name: _name.text.trim(),
            phone: phone,
            password: _password.text,
          );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => RegisterOtpScreen(
                phone: phone,
                displayName: _name.text.trim(),
              ),
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

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Регистрация',
      subtitle:
          'Номер только Таджикистан (+992). Затем подтверждение по SMS-коду.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: authInputDecoration(
                  context: context,
                  label: 'Имя',
                  hint: 'Как к вам обращаться',
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              TjPhoneFormField(
                controller: _phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: TjPhone.validateNationalField,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: authInputDecoration(
                  context: context,
                  label: 'Пароль',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure2,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.newPassword],
                decoration: authInputDecoration(
                  context: context,
                  label: 'Повторите пароль',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                    icon: Icon(
                      _obscure2
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                validator: _validateConfirm,
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Получить код в SMS'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Уже есть аккаунт? ',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                    child: const Text('Войти'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
