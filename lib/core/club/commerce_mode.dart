/// Se um fluxo transacional (Loja/Ingressos/Sócio) processa dinheiro/vínculo
/// de verdade ou é só uma demonstração de produto. Por clube e por área —
/// nada impede a Loja virar `real` antes de Ingressos, por exemplo. Nunca
/// muda em runtime (é parte de [ClubCapabilities], resolvida uma vez no
/// bootstrap como o resto de [ClubConfig]).
enum CommerceMode { demo, real }
