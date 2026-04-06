import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_messenger.dart';
import '../../core/tj_phone.dart';
import 'auth_repository.dart';
import 'auth_session.dart';
import 'auth_shell.dart';
import 'register_screen.dart';
import 'tj_phone_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validatePassword(String? v) {
    if ((v ?? '').length < 6) return 'Минимум 6 символов';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final phone = TjPhone.e164FromField(_phone.text);
    final password = _password.text;
    try {
      await ref.read(authRepositoryProvider).login(
            phone: phone,
            password: password,
          );
      if (!mounted) return;
      await ref.read(authSessionProvider.notifier).markSignedIn();
      if (!mounted) return;
      // Снять экран входа с стека — иначе он остаётся поверх обновлённого корня.
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (!mounted) return;
      appMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Вы вошли в аккаунт'),
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

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Вход',
      subtitle:
          'Номер Таджикистана (+992): 9 цифр без кода страны, затем пароль.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                autofillHints: const [AutofillHints.password],
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
                    : const Text('Войти'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Нет аккаунта? ',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                    child: const Text('Регистрация'),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  appMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text('Восстановление пароля появится позже'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  'Забыли пароль?',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
