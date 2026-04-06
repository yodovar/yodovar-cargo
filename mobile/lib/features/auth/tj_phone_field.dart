import 'package:flutter/material.dart';

import '../../core/tj_phone.dart';
import 'auth_shell.dart';

/// Поле телефона: префикс **+992** не редактируется, ввод только 9 цифр.
class TjPhoneFormField extends StatelessWidget {
  const TjPhoneFormField({
    super.key,
    required this.controller,
    required this.validator,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      inputFormatters: TjPhone.nationalInputFormatters,
      onFieldSubmitted: onFieldSubmitted,
      decoration: authInputDecoration(
        context: context,
        label: 'Телефон',
        hint: '90 000 00 00',
      ).copyWith(
        prefixText: '${TjPhone.dialCode} ',
        prefixStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      validator: validator,
    );
  }
}
