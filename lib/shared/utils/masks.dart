import 'package:flutter/services.dart';

class _PatternInputFormatter extends TextInputFormatter {
  _PatternInputFormatter(this.mask);

  final String mask;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    var digitIndex = 0;
    for (var i = 0; i < mask.length && digitIndex < digits.length; i++) {
      if (mask[i] == '#') {
        buffer.write(digits[digitIndex]);
        digitIndex++;
      } else {
        buffer.write(mask[i]);
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

TextInputFormatter cpfInputFormatter() => _PatternInputFormatter('###.###.###-##');

TextInputFormatter cepInputFormatter() => _PatternInputFormatter('#####-###');

TextInputFormatter phoneInputFormatter() => _PatternInputFormatter('(##) #####-####');

TextInputFormatter landlineInputFormatter() => _PatternInputFormatter('(##) ####-####');

String onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

String maskCpf(String cpf) {
  final digits = onlyDigits(cpf);
  if (digits.length != 11) return cpf;
  return '•••.•••.•••-${digits.substring(9)}';
}

String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  final name = email.substring(0, at);
  final domain = email.substring(at);
  final visible = name.length <= 2 ? name : name.substring(0, 2);
  return '$visible••••$domain';
}

String maskPhone(String phone) {
  final digits = onlyDigits(phone);
  if (digits.length < 10) return phone;
  final ddd = digits.substring(0, 2);
  final firstDigit = digits.length == 11 ? digits.substring(2, 3) : '';
  return '($ddd) $firstDigit••••-••••';
}
