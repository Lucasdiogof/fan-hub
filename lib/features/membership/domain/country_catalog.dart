class Country {
  const Country({required this.code, required this.name, required this.dialCode});

  final String code;
  final String name;
  final String dialCode;
}

/// Lista curada, não exaustiva — cobre o Brasil, os vizinhos sul-americanos
/// e os países de onde mais vem torcedor/imigrante no contexto do clube.
/// Fácil de estender: só adicionar uma entrada.
class CountryCatalog {
  const CountryCatalog._();

  static const countries = <Country>[
    Country(code: 'BR', name: 'Brasil', dialCode: '+55'),
    Country(code: 'AR', name: 'Argentina', dialCode: '+54'),
    Country(code: 'PY', name: 'Paraguai', dialCode: '+595'),
    Country(code: 'UY', name: 'Uruguai', dialCode: '+598'),
    Country(code: 'BO', name: 'Bolívia', dialCode: '+591'),
    Country(code: 'CL', name: 'Chile', dialCode: '+56'),
    Country(code: 'CO', name: 'Colômbia', dialCode: '+57'),
    Country(code: 'PE', name: 'Peru', dialCode: '+51'),
    Country(code: 'VE', name: 'Venezuela', dialCode: '+58'),
    Country(code: 'EC', name: 'Equador', dialCode: '+593'),
    Country(code: 'US', name: 'Estados Unidos', dialCode: '+1'),
    Country(code: 'CA', name: 'Canadá', dialCode: '+1'),
    Country(code: 'MX', name: 'México', dialCode: '+52'),
    Country(code: 'PT', name: 'Portugal', dialCode: '+351'),
    Country(code: 'ES', name: 'Espanha', dialCode: '+34'),
    Country(code: 'FR', name: 'França', dialCode: '+33'),
    Country(code: 'IT', name: 'Itália', dialCode: '+39'),
    Country(code: 'DE', name: 'Alemanha', dialCode: '+49'),
    Country(code: 'GB', name: 'Reino Unido', dialCode: '+44'),
    Country(code: 'JP', name: 'Japão', dialCode: '+81'),
    Country(code: 'CN', name: 'China', dialCode: '+86'),
    Country(code: 'AO', name: 'Angola', dialCode: '+244'),
    Country(code: 'CV', name: 'Cabo Verde', dialCode: '+238'),
    Country(code: 'MZ', name: 'Moçambique', dialCode: '+258'),
  ];

  static String nameFor(String code) {
    for (final country in countries) {
      if (country.code == code) return country.name;
    }
    return code;
  }

  static String dialCodeFor(String code) {
    for (final country in countries) {
      if (country.code == code) return country.dialCode;
    }
    return '';
  }

  /// Bandeira via Regional Indicator Symbols — não precisa manter um emoji
  /// por país na lista, só o código ISO já cadastrado.
  static String flagFor(String code) {
    if (code.length != 2) return '🏳';
    const base = 0x1F1E6;
    final first = base + (code.codeUnitAt(0) - 'A'.codeUnitAt(0));
    final second = base + (code.codeUnitAt(1) - 'A'.codeUnitAt(0));
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}
