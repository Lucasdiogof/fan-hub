// Termos PRÓPRIOS do app pra experiência de associação Massa Bruta dentro
// do Fan Hub — nunca uma cópia do Regulamento oficial do Massa Bruta (que
// o clube publica em massabruta.com.br e que rege a associação real, fora
// deste app). Ver `MembershipProgramConfig.externalUrl`/`consentUrl` pro
// link oficial. Escrito à mão (não gerado de asset), porque não existe
// hoje um Regulamento oficial público cobrindo os 4 planos vendáveis
// (Asas Bronze/Prata/Ouro/Platina) pra reproduzir com fidelidade — só um
// Regulamento do plano "Asas Diamante" (não vendável hoje), achado em
// auditoria — reproduzir esse texto como se valesse pros outros planos
// seria inventar regra, o que o pedido explicitamente proíbe.

import 'package:goias_app/features/membership/domain/entities/regulation_section.dart';

const bragantinoMembershipRegulationIntro =
    'Este é o Termo de Adesão do Massa Bruta dentro do Fan Hub — a '
    'experiência de sócio-torcedor deste aplicativo, inspirada no '
    'programa oficial Massa Bruta do Red Bull Bragantino. Antes de '
    'continuar, é importante entender exatamente o que esta adesão '
    'significa aqui dentro, e o que ela NÃO é.';

const bragantinoMembershipRegulationSections = <RegulationSection>[
  RegulationSection(
    index: 1,
    title: 'O que esta adesão é',
    body:
        'Ao se associar por aqui, você contrata uma versão de demonstração '
        'do programa Massa Bruta dentro do Fan Hub: os planos exibidos '
        '(Asas Bronze, Prata, Ouro e Platina), seus preços e benefícios são '
        'os mesmos publicados no site oficial do Massa Bruta na data '
        'informada nesta tela, mas a contratação em si acontece só dentro '
        'deste app — sem cobrança real, sem parcelamento e sem vínculo com '
        'nenhum sistema de pagamento.',
  ),
  RegulationSection(
    index: 2,
    title: 'O que esta adesão NÃO é',
    body:
        'Esta adesão não cria nem altera nenhuma conta sua no site oficial '
        'massabruta.com.br, não é processada pelo Red Bull Bragantino nem '
        'pela administração real do programa Massa Bruta, e não garante '
        'nenhum direito fora deste app (compra de ingresso real com '
        'desconto, acesso físico ao estádio, cadastro biométrico, etc.). '
        'Para a associação oficial, com cobrança e benefícios de verdade, '
        'use o site oficial do Massa Bruta.',
  ),
  RegulationSection(
    index: 3,
    title: 'Seus dados',
    body:
        'Os dados preenchidos no cadastro (nome, CPF, contato, data de '
        'nascimento, endereço) ficam guardados só na nossa própria base de '
        'dados (Supabase), vinculados à sua conta neste app — nunca são '
        'enviados ao site oficial do Massa Bruta ou a qualquer sistema do '
        'Red Bull Bragantino. Campos já preenchidos automaticamente a '
        'partir do seu perfil no app podem ser conferidos e alterados '
        'livremente antes de confirmar.',
  ),
  RegulationSection(
    index: 4,
    title: 'Planos, preços e check-in',
    body:
        'Os benefícios de cada plano — incluindo quais setores liberam '
        'check-in livre (Bronze: nenhum; Prata: Leste e Oeste; Ouro: Sul, '
        'Leste e Oeste; Platina: Norte, Sul, Leste e Oeste) — seguem a '
        'mesma estrutura publicada oficialmente. O app pode atualizar esses '
        'valores sempre que o programa oficial mudar; a data da última '
        'atualização usada por este app fica sempre visível na tela de '
        'planos.',
  ),
  RegulationSection(
    index: 5,
    title: 'Cancelamento',
    body:
        'A qualquer momento, é possível encerrar esta associação de '
        'demonstração pelo canal de contato disponível em "Minha '
        'Associação" — sem nenhuma cobrança ou multa, já que nenhuma '
        'cobrança real chegou a existir.',
  ),
];
