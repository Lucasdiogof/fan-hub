/// Qual composição visual do Passaporte Esmeraldino está ativa — domínio,
/// dados, Cubits e regras de negócio são os mesmos pras duas; só a camada
/// visual (`presentation/v1` vs `presentation/v2`) muda.
enum PassportUiVariant { v1, v2 }

/// Ponto único de troca entre V1 e V2. Voltar pra V1 é mudar [current] pra
/// `PassportUiVariant.v1` — não mexe em banco, RPC, import histórico nem em
/// nenhuma presença já salva, porque nenhum desses dois dependem da UI.
class PassportUiConfig {
  const PassportUiConfig._();

  static const current = PassportUiVariant.v2;
}
