import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';

const _c = PlayerIdentityDimension.creativity;
const _d = PlayerIdentityDimension.definition;
const _l = PlayerIdentityDimension.leadership;
const _i = PlayerIdentityDimension.intensity;
const _t = PlayerIdentityDimension.technique;
const _x = PlayerIdentityDimension.tactics;

/// As 10 perguntas do jogo "Que craque esmeraldino é você?" — conteúdo
/// editorial fixo, nunca traduzido (mesma convenção de
/// `tactical_identity_questions.dart`: conteúdo fica em português puro, só a
/// UI ao redor passa por l10n). Cada alternativa contribui +3 pra uma
/// dimensão primária e +1 pra uma secundária — EXCETO a pergunta 7 opção D,
/// que divide +2/+2 (fiel ao pedido original). Nunca reordenar nem alterar
/// pontos sem decisão explícita.
const playerIdentityQuestions = <PlayerIdentityQuestion>[
  PlayerIdentityQuestion(
    id: 'p01',
    text: 'Você recebe a bola perto da área. O que enxerga primeiro?',
    options: [
      PlayerIdentityOption(
        id: 'p01_a',
        text: 'O passe inesperado que pode quebrar a defesa.',
        primary: _c,
        secondary: _t,
      ),
      PlayerIdentityOption(
        id: 'p01_b',
        text: 'O espaço para finalizar.',
        primary: _d,
        secondary: _i,
      ),
      PlayerIdentityOption(
        id: 'p01_c',
        text: 'A posição dos companheiros e o desenho da jogada.',
        primary: _x,
        secondary: _l,
      ),
      PlayerIdentityOption(
        id: 'p01_d',
        text: 'O defensor à sua frente. Se der, vou para o um contra um.',
        primary: _t,
        secondary: _c,
      ),
    ],
  ),
  PlayerIdentityQuestion(
    id: 'p02',
    text:
        'Seu time está sendo pressionado e começa a perder o controle do '
        'jogo. O que mais combina com você?',
    options: [
      PlayerIdentityOption(
        id: 'p02_a',
        text: 'Peço a bola e tento organizar o time.',
        primary: _l,
        secondary: _x,
      ),
      PlayerIdentityOption(
        id: 'p02_b',
        text: 'Aumento a pressão e tento recuperar a bola na marra.',
        primary: _i,
        secondary: _l,
      ),
      PlayerIdentityOption(
        id: 'p02_c',
        text: 'Seguro a bola e tento tirar o time da pressão com qualidade.',
        primary: _t,
        secondary: _x,
      ),
      PlayerIdentityOption(
        id: 'p02_d',
        text: 'Procuro uma jogada diferente que faça o adversário recuar.',
        primary: _c,
        secondary: _t,
      ),
    ],
  ),
  PlayerIdentityQuestion(
    id: 'p03',
    text:
        'Você participa de um contra-ataque com três jogadores contra três '
        'defensores.',
    options: [
      PlayerIdentityOption(
        id: 'p03_a',
        text: 'Procuro o passe que deixe um companheiro na melhor situação.',
        primary: _c,
        secondary: _x,
      ),
      PlayerIdentityOption(
        id: 'p03_b',
        text: 'Ataco a área. Quero terminar a jogada.',
        primary: _d,
        secondary: _i,
      ),
      PlayerIdentityOption(
        id: 'p03_c',
        text:
            'Carrego a bola em velocidade para obrigar alguém a sair da '
            'marcação.',
        primary: _i,
        secondary: _t,
      ),
      PlayerIdentityOption(
        id: 'p03_d',
        text: 'Leio como a defesa reage antes de escolher quando acelerar.',
        primary: _x,
        secondary: _t,
      ),
    ],
  ),
  PlayerIdentityQuestion(
    id: 'p04',
    text: 'Jogo grande, 1 a 1 e faltam poucos minutos.',
    options: [
      PlayerIdentityOption(
        id: 'p04_a',
        text: 'Quero a bola. Se surgir meio espaço, vou tentar decidir.',
        primary: _d,
        secondary: _l,
      ),
      PlayerIdentityOption(
        id: 'p04_b',
        text: 'Tento o passe, drible ou movimento que ninguém está esperando.',
        primary: _c,
        secondary: _t,
      ),
      PlayerIdentityOption(
        id: 'p04_c',
        text: 'Não abandono a organização só porque o relógio está acabando.',
        primary: _x,
        secondary: _l,
      ),
      PlayerIdentityOption(
        id: 'p04_d',
        text:
            'Aumento ainda mais o ritmo e disputo cada bola como se fosse a '
            'última.',
        primary: _i,
        secondary: _l,
      ),
    ],
  ),
  PlayerIdentityQuestion(
    id: 'p05',
    text: 'Um companheiro comete um erro importante e sente o golpe.',
    options: [
      PlayerIdentityOption(
        id: 'p05_a',
        text: 'Vou até ele, incentivo e tento reorganizar o time.',
        primary: _l,
        secondary: _x,
      ),
      PlayerIdentityOption(
        id: 'p05_b',
        text: 'Minha reação é correr para recuperar a bola imediatamente.',
        primary: _i,
        secondary: _x,
      ),
      PlayerIdentityOption(
        id: 'p05_c',
        text: 'Peço a bola na próxima jogada e assumo a responsabilidade.',
        primary: _l,
        secondary: _t,
      ),
      PlayerIdentityOption(
        id: 'p05_d',
        text:
            'Tento criar algo diferente rapidamente para mudar o clima da '
            'partida.',
        primary: _c,
        secondary: _d,
      ),
    ],
  ),
  PlayerIdentityQuestion(
    id: 'p06',
    text:
        'Você recebe a bola dentro ou muito perto da área, cercado por '
        'adversários.',
    options: [
      PlayerIdentityOption(
        id: 'p06_a',
        text: 'Se houver janela, finalizo de primeira.',
        primary: _d,
        secondary: _t,
      ),
      PlayerIdentityOption(
        id: 'p06_b',
        text: 'Procuro uma tabela curta para atravessar a marcação.',
        primary: _t,
        secondary: _c,
      ),
      PlayerIdentityOption(
        id: 'p06_c',
        text: 'Me movimento para tirar um marcador do lugar e abrir espaço.',
        primary: _x,
        secondary: _i,
      ),
      PlayerIdentityOption(
        id: 'p06_d',
        text: 'Confio no drible para criar meu próprio espaço.',
        primary: _c,
        secondary: _t,
      ),
    ],
  ),
  PlayerIdentityQuestion(
    id: 'p07',
    text: 'O adversário começa uma transição perigosa.',
    options: [
      PlayerIdentityOption(
        id: 'p07_a',
        text: 'Minha prioridade é fechar a linha de passe mais perigosa.',
        primary: _x,
        secondary: _l,
      ),
      PlayerIdentityOption(
        id: 'p07_b',
        text: 'Vou pressionar imediatamente quem está com a bola.',
        primary: _i,
        secondary: _x,
      ),
      PlayerIdentityOption(
        id: 'p07_c',
        text: 'Organizo quem está perto e aviso onde precisamos fechar.',
        primary: _l,
        secondary: _x,
      ),
      PlayerIdentityOption(
        id: 'p07_d',
        text:
            'Tento roubar e já transformar a recuperação numa jogada '
            'ofensiva.',
        primary: _i,
        secondary: _c,
        primaryPoints: 2,
        secondaryPoints: 2,
      ),
    ],
  ),
  PlayerIdentityQuestion(
    id: 'p08',
    text: 'Últimos minutos. Surge uma bola parada decisiva.',
    options: [
      PlayerIdentityOption(
        id: 'p08_a',
        text: 'Se puder bater, quero assumir a cobrança.',
        primary: _d,
        secondary: _l,
      ),
      PlayerIdentityOption(
        id: 'p08_b',
        text: 'Ajudo a organizar posicionamento, rebote e movimentações.',
        primary: _l,
        secondary: _x,
      ),
      PlayerIdentityOption(
        id: 'p08_c',
        text: 'Procuro uma cobrança ou movimentação ensaiada diferente.',
        primary: _c,
        secondary: _x,
      ),
      PlayerIdentityOption(
        id: 'p08_d',
        text: 'Meu foco é atacar aquela bola com tudo.',
        primary: _i,
        secondary: _d,
      ),
    ],
  ),
  PlayerIdentityQuestion(
    id: 'p09',
    text: 'Qual qualidade você mais gostaria que definisse seu jogo?',
    options: [
      PlayerIdentityOption(
        id: 'p09_a',
        text: 'Qualidade com a bola.',
        primary: _t,
        secondary: _c,
      ),
      PlayerIdentityOption(
        id: 'p09_b',
        text: 'Aparecer e decidir quando a partida precisa.',
        primary: _d,
        secondary: _l,
      ),
      PlayerIdentityOption(
        id: 'p09_c',
        text: 'Competir em todas as jogadas.',
        primary: _i,
        secondary: _l,
      ),
      PlayerIdentityOption(
        id: 'p09_d',
        text: 'Entender o jogo antes dos outros.',
        primary: _x,
        secondary: _l,
      ),
    ],
  ),
  PlayerIdentityQuestion(
    id: 'p10',
    text: 'Qual dessas frases mais representa você dentro de campo?',
    options: [
      PlayerIdentityOption(
        id: 'p10_a',
        text: 'Se todo mundo está vendo a mesma jogada, quero encontrar outra.',
        primary: _c,
        secondary: _t,
      ),
      PlayerIdentityOption(
        id: 'p10_b',
        text: 'Quando o jogo pede alguém para decidir, quero estar lá.',
        primary: _d,
        secondary: _l,
      ),
      PlayerIdentityOption(
        id: 'p10_c',
        text: 'Um time melhora quando alguém assume responsabilidade.',
        primary: _l,
        secondary: _x,
      ),
      PlayerIdentityOption(
        id: 'p10_d',
        text:
            'Posso não participar de toda jogada bonita, mas não abandono '
            'nenhuma disputa.',
        primary: _i,
        secondary: _x,
      ),
    ],
  ),
];
