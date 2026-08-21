class BrazilianState {
  const BrazilianState({required this.code, required this.name});

  final String code;
  final String name;
}

class BrazilianStates {
  const BrazilianStates._();

  static const states = <BrazilianState>[
    BrazilianState(code: 'AC', name: 'Acre'),
    BrazilianState(code: 'AL', name: 'Alagoas'),
    BrazilianState(code: 'AP', name: 'Amapá'),
    BrazilianState(code: 'AM', name: 'Amazonas'),
    BrazilianState(code: 'BA', name: 'Bahia'),
    BrazilianState(code: 'CE', name: 'Ceará'),
    BrazilianState(code: 'DF', name: 'Distrito Federal'),
    BrazilianState(code: 'ES', name: 'Espírito Santo'),
    BrazilianState(code: 'GO', name: 'Goiás'),
    BrazilianState(code: 'MA', name: 'Maranhão'),
    BrazilianState(code: 'MT', name: 'Mato Grosso'),
    BrazilianState(code: 'MS', name: 'Mato Grosso do Sul'),
    BrazilianState(code: 'MG', name: 'Minas Gerais'),
    BrazilianState(code: 'PA', name: 'Pará'),
    BrazilianState(code: 'PB', name: 'Paraíba'),
    BrazilianState(code: 'PR', name: 'Paraná'),
    BrazilianState(code: 'PE', name: 'Pernambuco'),
    BrazilianState(code: 'PI', name: 'Piauí'),
    BrazilianState(code: 'RJ', name: 'Rio de Janeiro'),
    BrazilianState(code: 'RN', name: 'Rio Grande do Norte'),
    BrazilianState(code: 'RS', name: 'Rio Grande do Sul'),
    BrazilianState(code: 'RO', name: 'Rondônia'),
    BrazilianState(code: 'RR', name: 'Roraima'),
    BrazilianState(code: 'SC', name: 'Santa Catarina'),
    BrazilianState(code: 'SP', name: 'São Paulo'),
    BrazilianState(code: 'SE', name: 'Sergipe'),
    BrazilianState(code: 'TO', name: 'Tocantins'),
  ];

  static String nameForCode(String code) {
    for (final state in states) {
      if (state.code.toUpperCase() == code.toUpperCase()) return state.name;
    }
    return code;
  }

  static String? codeForName(String name) {
    for (final state in states) {
      if (state.name == name) return state.code;
    }
    return null;
  }
}
