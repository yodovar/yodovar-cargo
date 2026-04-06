import 'package:flutter/services.dart';

/// Номера только Таджикистан: код страны **+992** фиксирован, ввод — национальная часть (9 цифр).
abstract final class TjPhone {
  TjPhone._();

  static const String dialCode = '+992';

  /// Из ввода пользователя (в т.ч. вставка с +992) — только 9 цифр абонента.
  static String nationalDigits(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('992')) d = d.substring(3);
    if (d.startsWith('0')) d = d.substring(1);
    return d;
  }

  static String? validateNationalField(String? v) {
    final d = nationalDigits(v ?? '');
    if (d.length != 9) {
      return 'Введите 9 цифр номера (Таджикистан, код +992)';
    }
    return null;
  }

  /// Полный номер для API: `+992` + 9 цифр.
  static String e164FromField(String fieldText) => '$dialCode${nationalDigits(fieldText)}';

  static List<TextInputFormatter> get nationalInputFormatters => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ];
}
