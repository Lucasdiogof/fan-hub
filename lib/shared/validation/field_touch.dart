/// Controla quando o erro de UM campo deve aparecer, seguindo a mesma regra
/// em todo o app: campo vazio nunca mostra erro antes do submit (mesmo já
/// tendo sido editado e esvaziado de novo); valor não-vazio valida em tempo
/// real assim que o usuário mexe nele; valores pré-carregados (edição) só
/// passam a validar quando o próprio usuário os edita ou quando o formulário
/// é submetido. `touched` só deve virar `true` num `onChanged` de verdade —
/// nunca em atribuição programática de `controller.text` — por isso é a
/// própria tela quem seta, nunca este objeto sozinho.
class FieldTouch {
  bool touched = false;

  String? errorFor(
    String value, {
    required bool submitted,
    String? Function(String value)? format,
    String? requiredMessage,
  }) {
    if (value.trim().isEmpty) {
      return submitted ? requiredMessage : null;
    }
    if (!touched && !submitted) return null;
    return format?.call(value);
  }
}
