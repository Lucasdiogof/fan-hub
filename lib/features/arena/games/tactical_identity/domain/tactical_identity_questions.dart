import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// As 10 perguntas do jogo "Identidade Futebolística" — conteúdo editorial
/// fixo, nunca traduzido (mesma convenção de `quiz_questions.dart`: conteúdo
/// fica em português puro, só a UI ao redor passa por l10n). Nunca reordenar
/// nem alterar `deltaX`/`deltaY` sem decisão explícita — ver
/// `tactical_coach_references.dart` sobre a mesma regra pro dataset de
/// técnicos.
const tacticalIdentityQuestions = <TacticalQuestion>[
  TacticalQuestion(
    id: 'q01',
    text:
        'O adversário pressiona sua saída de bola e fecha os passes curtos. '
        'O que seu Goiás faz?',
    options: [
      TacticalOption(
        id: 'q01_a',
        text:
            'Continua saindo curto, atraindo a pressão até encontrar o '
            'homem livre.',
        deltaX: -2,
        deltaY: -2,
      ),
      TacticalOption(
        id: 'q01_b',
        text:
            'Tenta sair curto, mas se a pressão encaixar busca imediatamente '
            'o espaço nas costas.',
        deltaX: -1,
        deltaY: 2,
      ),
      TacticalOption(
        id: 'q01_c',
        text:
            'Aciona o atacante ou o corredor diretamente e prepara a equipe '
            'para ganhar a segunda bola.',
        deltaX: 2,
        deltaY: -1,
      ),
      TacticalOption(
        id: 'q01_d',
        text:
            'Identifica onde a pressão rival é mais vulnerável e escolhe a '
            'saída por ali, curta ou longa.',
        deltaX: 1,
        deltaY: 2,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q02',
    text:
        'Seu time recupera a bola no meio-campo com o adversário ainda '
        'desorganizado. Qual é a primeira ideia?',
    options: [
      TacticalOption(
        id: 'q02_a',
        text: 'Retém a bola, aproxima o time e organiza o ataque.',
        deltaX: -2,
        deltaY: -1,
      ),
      TacticalOption(
        id: 'q02_b',
        text:
            'Procura o passe para frente se houver vantagem; se não houver, '
            'mantém a posse.',
        deltaX: -1,
        deltaY: 2,
      ),
      TacticalOption(
        id: 'q02_c',
        text: 'Acelera imediatamente e tenta chegar ao gol em poucos passes.',
        deltaX: 2,
        deltaY: -1,
      ),
      TacticalOption(
        id: 'q02_d',
        text:
            'Decide pela posição dos adversários e pela superioridade '
            'numérica daquele lance.',
        deltaX: 1,
        deltaY: 2,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q03',
    text: 'Goiás vence por 1 a 0 fora de casa aos 75 minutos.',
    options: [
      TacticalOption(
        id: 'q03_a',
        text: 'Não muda o comportamento. Se o plano trouxe a vantagem, '
            'continua igual.',
        deltaX: 0,
        deltaY: -2,
      ),
      TacticalOption(
        id: 'q03_b',
        text:
            'Passa a controlar o jogo com mais posse e faz o adversário '
            'correr atrás da bola.',
        deltaX: -2,
        deltaY: 1,
      ),
      TacticalOption(
        id: 'q03_c',
        text: 'Fecha melhor os espaços e prepara transições para matar o '
            'jogo.',
        deltaX: 2,
        deltaY: 2,
      ),
      TacticalOption(
        id: 'q03_d',
        text:
            'Continua pressionando e buscando o segundo gol antes que o '
            'rival cresça.',
        deltaX: 1,
        deltaY: -1,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q04',
    text:
        'O rival estacionou duas linhas perto da própria área. Como furar o '
        'bloqueio?',
    options: [
      TacticalOption(
        id: 'q04_a',
        text: 'Circula pacientemente até surgir o espaço certo.',
        deltaX: -2,
        deltaY: -2,
      ),
      TacticalOption(
        id: 'q04_b',
        text:
            'Muda posicionamentos e cria superioridade entre linhas ou '
            'pelos lados.',
        deltaX: -1,
        deltaY: 2,
      ),
      TacticalOption(
        id: 'q04_c',
        text:
            'Aumenta velocidade, cruzamentos, profundidade e disputa de '
            'rebotes.',
        deltaX: 2,
        deltaY: -1,
      ),
      TacticalOption(
        id: 'q04_d',
        text:
            'Coloca mais presença na área e muda a rota do ataque conforme '
            'a defesa reage.',
        deltaX: 1,
        deltaY: 2,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q05',
    text:
        'Você vai enfrentar fora de casa um adversário claramente superior '
        'tecnicamente.',
    options: [
      TacticalOption(
        id: 'q05_a',
        text:
            'Mantém sua proposta de controle e saída com bola; é assim que '
            'o time joga.',
        deltaX: -2,
        deltaY: -2,
      ),
      TacticalOption(
        id: 'q05_b',
        text:
            'Continua tentando ter a bola, mas ajusta pressão e '
            'posicionamento ao rival.',
        deltaX: -1,
        deltaY: 2,
      ),
      TacticalOption(
        id: 'q05_c',
        text:
            'Aceita ter menos posse, protege os espaços e prioriza a '
            'transição.',
        deltaX: 2,
        deltaY: 2,
      ),
      TacticalOption(
        id: 'q05_d',
        text:
            'Pressiona alto e procura atacar rapidamente, mesmo assumindo '
            'risco.',
        deltaX: 2,
        deltaY: -1,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q06',
    text:
        'Seu melhor jogador decide partidas, mas participa pouco da '
        'recomposição. O que fazer?',
    options: [
      TacticalOption(
        id: 'q06_a',
        text:
            'O modelo vem primeiro; se não cumprir a função, pode perder a '
            'vaga.',
        deltaX: 0,
        deltaY: -2,
      ),
      TacticalOption(
        id: 'q06_b',
        text:
            'Muda a função dele para manter o talento sem desequilibrar o '
            'coletivo.',
        deltaX: -1,
        deltaY: 2,
      ),
      TacticalOption(
        id: 'q06_c',
        text:
            'Reorganiza os companheiros para compensar e preserva o craque '
            'em zonas ofensivas.',
        deltaX: 1,
        deltaY: 1,
      ),
      TacticalOption(
        id: 'q06_d',
        text:
            'Dá liberdade. Jogadores especiais precisam ser tratados de '
            'maneira especial.',
        deltaX: 1,
        deltaY: -1,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q07',
    text: 'Intervalo. Goiás perde por 1 a 0, mas está jogando bem e criando '
        'chances.',
    options: [
      TacticalOption(
        id: 'q07_a',
        text: 'Não mexe. O plano funciona e o gol será consequência.',
        deltaX: -1,
        deltaY: -2,
      ),
      TacticalOption(
        id: 'q07_b',
        text:
            'Faz pequenos ajustes de posicionamento sem abandonar a ideia '
            'inicial.',
        deltaX: -1,
        deltaY: 1,
      ),
      TacticalOption(
        id: 'q07_c',
        text:
            'Coloca mais profundidade ou outro atacante e passa a chegar '
            'mais rápido.',
        deltaX: 2,
        deltaY: 1,
      ),
      TacticalOption(
        id: 'q07_d',
        text:
            'Aumenta a velocidade da circulação e coloca mais jogadores '
            'entre as linhas.',
        deltaX: -2,
        deltaY: 1,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q08',
    text: 'Seu time perde a bola perto da área adversária. Qual reação você '
        'espera?',
    options: [
      TacticalOption(
        id: 'q08_a',
        text:
            'Pressão imediata para recuperar ali mesmo, independentemente '
            'do rival.',
        deltaX: -1,
        deltaY: -2,
      ),
      TacticalOption(
        id: 'q08_b',
        text:
            'Pressiona se houver jogadores suficientes perto; caso '
            'contrário, recompõe.',
        deltaX: 0,
        deltaY: 2,
      ),
      TacticalOption(
        id: 'q08_c',
        text: 'Primeiro reorganiza o bloco e fecha o centro do campo.',
        deltaX: 1,
        deltaY: 1,
      ),
      TacticalOption(
        id: 'q08_d',
        text:
            'Interrompe a transição e impede que o adversário consiga '
            'acelerar.',
        deltaX: 2,
        deltaY: -1,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q09',
    text: 'Faltam dez minutos e o Goiás precisa de um gol.',
    options: [
      TacticalOption(
        id: 'q09_a',
        text:
            'Mantém a construção paciente. Desorganização não é solução.',
        deltaX: -2,
        deltaY: -2,
      ),
      TacticalOption(
        id: 'q09_b',
        text:
            'Coloca jogadores mais ofensivos, mas mantém a bola no chão e a '
            'estrutura.',
        deltaX: -1,
        deltaY: 2,
      ),
      TacticalOption(
        id: 'q09_c',
        text:
            'Ocupa o campo adversário, joga mais direto e ataca primeira e '
            'segunda bolas.',
        deltaX: 2,
        deltaY: -1,
      ),
      TacticalOption(
        id: 'q09_d',
        text:
            'Muda o desenho e alterna ataques curtos e diretos conforme a '
            'defesa oferecer espaço.',
        deltaX: 1,
        deltaY: 2,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q10',
    text: 'Qual frase mais representa sua maneira de pensar futebol?',
    options: [
      TacticalOption(
        id: 'q10_a',
        text:
            'Primeiro vem a nossa maneira de jogar; depois pensamos no '
            'adversário.',
        deltaX: -1,
        deltaY: -2,
      ),
      TacticalOption(
        id: 'q10_b',
        text: 'Os princípios permanecem, mas esquema e estratégia podem '
            'mudar.',
        deltaX: -1,
        deltaY: 2,
      ),
      TacticalOption(
        id: 'q10_c',
        text: 'Chegar ao gol rapidamente vale mais do que ter a bola por '
            'ter.',
        deltaX: 2,
        deltaY: -1,
      ),
      TacticalOption(
        id: 'q10_d',
        text:
            'O melhor futebol é o que potencializa nossas peças e ataca as '
            'fraquezas do rival.',
        deltaX: 1,
        deltaY: 2,
      ),
    ],
  ),
];
