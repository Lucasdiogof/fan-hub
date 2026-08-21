import 'package:goias_app/shared/utils/masks.dart';

/// Validação matemática real dos dígitos verificadores — não só "tem 11
/// números". Também rejeita sequências repetidas (000.000.000-00 etc.),
/// que passariam na conta dos dígitos verificadores por coincidência.
bool isValidCpf(String rawCpf) {
  final digits = onlyDigits(rawCpf);
  if (digits.length != 11) return false;
  if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

  int checkDigit(String base) {
    var sum = 0;
    var weight = base.length + 1;
    for (var i = 0; i < base.length; i++) {
      sum += int.parse(base[i]) * weight;
      weight--;
    }
    final rest = sum % 11;
    return rest < 2 ? 0 : 11 - rest;
  }

  final base9 = digits.substring(0, 9);
  final d1 = checkDigit(base9);
  final d2 = checkDigit('$base9$d1');
  return digits == '$base9$d1$d2';
}

/// Verificação sintática simples (não a RFC inteira) — rejeita "lucas",
/// "lucas@", "@gmail.com", "lucas@gmail"; aceita "lucas@gmail.com".
bool isValidEmailShape(String email) {
  return RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email.trim());
}

/// Sem regex rígida demais: permite acentos, hífen e apóstrofo, só rejeita
/// nome vazio, curto demais ou composto só de números.
bool isValidFullName(String name) {
  final trimmed = name.trim();
  if (trimmed.length < 3) return false;
  if (RegExp(r'^[\d\s]+$').hasMatch(trimmed)) return false;
  return RegExp(r"^[\p{L}\p{M}\s'-]+$", unicode: true).hasMatch(trimmed);
}

/// Só interpreta como data quando os 8 dígitos já foram digitados — nem
/// toda entrada incompleta é "inválida", só ainda não é uma data.
DateTime? parseDdMmYyyy(String text) {
  final digits = onlyDigits(text);
  if (digits.length != 8) return null;
  final day = int.parse(digits.substring(0, 2));
  final month = int.parse(digits.substring(2, 4));
  final year = int.parse(digits.substring(4, 8));
  if (year < 1900 || year > 2100) return null;
  try {
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) return null;
    return date;
  } catch (_) {
    return null;
  }
}

bool isAtLeast18(DateTime birthDate) {
  final now = DateTime.now();
  var age = now.year - birthDate.year;
  if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age >= 18;
}

/// Celular brasileiro: DDD (2 dígitos) + 9 dígitos começando em 9. Rejeita
/// sequências óbvias tipo (00) 00000-0000.
bool isValidMobilePhone(String phone) {
  final digits = onlyDigits(phone);
  if (digits.length != 11) return false;
  if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;
  if (digits.substring(0, 2) == '00') return false;
  if (digits[2] != '9') return false;
  return true;
}

/// Sem regra de DDD/prefixo — números internacionais variam demais pra
/// validar do jeito estrito do celular brasileiro. Só um comprimento
/// plausível.
bool isValidInternationalPhone(String phone) {
  final digits = onlyDigits(phone);
  return digits.length >= 6 && digits.length <= 15;
}

/// Não existe validação universal de passaporte — só uma checagem de forma
/// razoável (tamanho, letras/números). Chamar só quando o campo não está
/// vazio; passaporte é opcional.
bool isValidPassportShape(String passport) {
  final trimmed = passport.trim();
  if (trimmed.length < 5 || trimmed.length > 15) return false;
  return RegExp(r'^[A-Za-z0-9]+$').hasMatch(trimmed);
}

bool isValidCep(String cep) => onlyDigits(cep).length == 8;
