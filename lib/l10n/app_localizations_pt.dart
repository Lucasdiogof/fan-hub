// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get languageName => 'Português';

  @override
  String get settingsLanguageTitle => 'IDIOMA';

  @override
  String get settingsLanguageMenu => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Escolha o idioma do aplicativo';

  @override
  String get languageSystemLabel => 'Padrão do sistema';

  @override
  String get languageSystemDescription => 'Segue o idioma do seu aparelho';

  @override
  String get commonEmailLabel => 'E-mail';

  @override
  String get commonEmailHint => 'seuemail@email.com';

  @override
  String get commonPasswordLabel => 'Senha';

  @override
  String get authTagline => 'Acompanhe tudo sobre o maior do Centro-Oeste';

  @override
  String get authRegisterSubtitle =>
      'Acompanhe tudo sobre o maior do Centro-Oeste.';

  @override
  String get authForgotPassword => 'Esqueci a senha';

  @override
  String get authSignInButton => 'ENTRAR';

  @override
  String get authSigningIn => 'Entrando...';

  @override
  String get authNoAccountQuestion => 'Ainda não possui uma conta? ';

  @override
  String get authCreateAccount => 'Criar conta';

  @override
  String get authRegisterTitle => 'Criar conta';

  @override
  String get authFullNameLabel => 'Nome completo';

  @override
  String get authFullNameHint => 'Seu nome';

  @override
  String authPasswordMinHint(int count) {
    return 'Mínimo $count caracteres';
  }

  @override
  String get authConfirmPasswordLabel => 'Confirmar senha';

  @override
  String get authConfirmPasswordHint => 'Repita a senha';

  @override
  String get authRegisterButton => 'CRIAR CONTA';

  @override
  String get authCreatingAccount => 'Criando...';

  @override
  String get authTermsPrefix => 'Li e aceito os ';

  @override
  String get authTermsLink => 'Termos de Uso';

  @override
  String get authTermsConnector => ' e a ';

  @override
  String get authPrivacyLink => 'Política de Privacidade';

  @override
  String get authTermsSuffix => '.';

  @override
  String get navHome => 'Início';

  @override
  String get navMatches => 'Jogos';

  @override
  String get navMembership => 'Sócio';

  @override
  String get navMedia => 'Mídia';

  @override
  String get navArena => 'Arena';

  @override
  String get homeGreetingMorning => 'Bom dia';

  @override
  String get homeGreetingAfternoon => 'Boa tarde';

  @override
  String get homeGreetingEvening => 'Boa noite';

  @override
  String get homeNextMatch => 'PRÓXIMO JOGO';

  @override
  String get homeDateToBeConfirmed => 'DATA A CONFIRMAR';

  @override
  String get homeMatchDetails => 'DETALHES DO JOGO';

  @override
  String get homeTickets => 'INGRESSOS';

  @override
  String get homeCountdownTitle => 'O JOGO COMEÇA EM';

  @override
  String get homeCountdownDays => 'DIAS';

  @override
  String get homeCountdownHours => 'HORAS';

  @override
  String get homeCountdownMinutes => 'MIN';

  @override
  String get homeCountdownSeconds => 'SEG';

  @override
  String get homeMembershipPitch =>
      'Esteja ainda mais perto do Goiás\ne faça parte dessa história!';

  @override
  String get homeMembershipBenefit1 => 'Prioridade de acesso ao estádio';

  @override
  String get homeMembershipBenefit2 => 'Economia no valor do ingresso';

  @override
  String get homeMembershipBenefit3 => 'Descontos exclusivos e muito mais';

  @override
  String get homeMembershipCta => 'SEJA SÓCIO ESMERALDINO';

  @override
  String get matchGamesTitle => 'JOGOS';

  @override
  String get matchTabMatches => 'PARTIDAS';

  @override
  String get matchTabStandings => 'CLASSIFICAÇÃO';

  @override
  String get matchLoadError => 'Não foi possível carregar os jogos';

  @override
  String get matchNoMatches => 'Nenhuma partida encontrada.';

  @override
  String get matchDetailsLoadError => 'Não foi possível carregar a partida.';

  @override
  String get matchBuyTicket => 'COMPRAR INGRESSO';

  @override
  String get matchDetailsShort => 'DETALHES';

  @override
  String get matchDateToBeConfirmed => 'Data a confirmar';

  @override
  String get matchToBeConfirmed => 'A confirmar';

  @override
  String get matchInfoTitle => 'INFORMAÇÕES';

  @override
  String get matchFieldDate => 'Data';

  @override
  String get matchFieldTime => 'Horário';

  @override
  String get matchFieldStadium => 'Estádio';

  @override
  String get matchFieldCity => 'Cidade';

  @override
  String get matchFieldCompetition => 'Competição';

  @override
  String get matchFieldRound => 'Rodada';

  @override
  String get matchFieldStatus => 'Status';

  @override
  String get matchEventsTitle => 'EVENTOS DA PARTIDA';

  @override
  String get matchEventGoal => 'Gol';

  @override
  String get matchEventCard => 'Cartão';

  @override
  String matchEventSubstitution(String playerIn, String playerOut) {
    return '$playerIn entra no lugar de $playerOut';
  }

  @override
  String get matchLineupsTitle => 'ESCALAÇÕES';

  @override
  String get standingsClub => 'CLUBE';

  @override
  String get standingsColPoints => 'P';

  @override
  String get standingsColPlayed => 'J';

  @override
  String get standingsColWins => 'V';

  @override
  String get standingsColGoalDiff => 'SG';

  @override
  String get standingsUnavailable => 'Classificação indisponível no momento.';

  @override
  String get matchStatusScheduled => 'Agendada';

  @override
  String get matchStatusLive => 'Ao vivo';

  @override
  String get matchStatusHalfTime => 'Intervalo';

  @override
  String get matchStatusFinished => 'Encerrada';

  @override
  String get matchStatusPostponed => 'Adiada';

  @override
  String get matchStatusCancelled => 'Cancelada';

  @override
  String get matchStatusSuspended => 'Suspensa';

  @override
  String get matchStatusUnknown => 'Indefinido';

  @override
  String get commonSave => 'SALVAR';

  @override
  String get commonSaving => 'Salvando...';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonContinue => 'CONTINUAR';

  @override
  String get profileTitle => 'PERFIL';

  @override
  String get profileMyAccount => 'MINHA CONTA';

  @override
  String get profilePersonalData => 'Dados pessoais';

  @override
  String get profileMyAddress => 'Meu endereço';

  @override
  String get profileSecurity => 'Segurança';

  @override
  String get profileTheme => 'Tema';

  @override
  String get profileLegal => 'LEGAL';

  @override
  String get profileAccount => 'CONTA';

  @override
  String get profileDeleteAccount => 'Excluir conta';

  @override
  String get profileDeleteConfirmTitle => 'Excluir conta?';

  @override
  String get profileDeleteConfirmMessage =>
      'Ao excluir sua conta, seus dados e seu progresso serão removidos permanentemente. Essa ação não pode ser desfeita.';

  @override
  String get profileSignOutTitle => 'Sair da conta?';

  @override
  String get profileSignOutMessage =>
      'Você precisará entrar novamente para acessar sua conta.';

  @override
  String get profileSignOutConfirm => 'SAIR';

  @override
  String get profileSignOut => 'Sair';

  @override
  String get personalDataTitle => 'DADOS PESSOAIS';

  @override
  String get personalDataLoadError => 'Não foi possível carregar seus dados.';

  @override
  String get personalFieldCpf => 'CPF (opcional)';

  @override
  String get personalFieldBirthDate => 'Data de nascimento';

  @override
  String get personalSelectDate => 'Selecionar data';

  @override
  String get personalFieldPhone => 'Celular';

  @override
  String get personalEmailLocked => 'O e-mail é vinculado à sua conta.';

  @override
  String get personalNameRequired => 'Informe seu nome completo.';

  @override
  String get personalCpfInvalid => 'CPF inválido.';

  @override
  String get personalUpdateSuccess => 'Dados atualizados com sucesso.';

  @override
  String get securityTitle => 'SEGURANÇA';

  @override
  String get securitySubtitle => 'Altere a senha da sua conta Goiás EC.';

  @override
  String get securityCurrentPassword => 'Senha atual';

  @override
  String get securityCurrentPasswordHint => 'Confirme sua senha atual';

  @override
  String get securityNewPassword => 'Nova senha';

  @override
  String get securityConfirmNewPassword => 'Confirmar nova senha';

  @override
  String get securityConfirmNewPasswordHint => 'Repita a nova senha';

  @override
  String get securitySaveButton => 'SALVAR NOVA SENHA';

  @override
  String get securityChangeSuccess => 'Senha alterada com sucesso.';

  @override
  String get addressTitle => 'MEU ENDEREÇO';

  @override
  String get addressLoadError => 'Não foi possível carregar seu endereço.';

  @override
  String get addressCepNotFound => 'CEP não encontrado.';

  @override
  String get addressSaveSuccess => 'Endereço salvo com sucesso.';

  @override
  String get addressFieldCep => 'CEP';

  @override
  String get addressFieldStreet => 'Logradouro';

  @override
  String get addressFieldNumber => 'Número';

  @override
  String get addressFieldComplement => 'Complemento (opcional)';

  @override
  String get addressFieldNeighborhood => 'Bairro';

  @override
  String get addressFieldState => 'Estado';

  @override
  String get addressSelectState => 'Selecionar estado';

  @override
  String get addressFieldCity => 'Cidade';

  @override
  String get addressSaveButton => 'SALVAR ENDEREÇO';

  @override
  String get deleteAccountTitle => 'EXCLUIR CONTA';

  @override
  String get deleteAccountConfirmWord => 'EXCLUIR';

  @override
  String deleteAccountInstruction(String word) {
    return 'Essa ação é permanente. Confirme sua senha e digite $word para excluir sua conta e todo o seu progresso.';
  }

  @override
  String get deleteAccountPasswordHint => 'Confirme sua senha';

  @override
  String deleteAccountTypeWordLabel(String word) {
    return 'Digite $word para confirmar';
  }

  @override
  String get deleteAccountConfirmButton => 'EXCLUIR MINHA CONTA';

  @override
  String get deleteAccountDeleting => 'EXCLUINDO CONTA...';

  @override
  String get settingsThemeTitle => 'TEMA';

  @override
  String get themeModeAuto => 'Automático';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Escuro';

  @override
  String get themeModeAutoDesc => 'Segue o tema do seu celular';

  @override
  String get themeModeLightDesc => 'Sempre com fundo claro';

  @override
  String get themeModeDarkDesc => 'Sempre com fundo escuro';

  @override
  String get avatarTakePhoto => 'Tirar foto';

  @override
  String get avatarChooseFromGallery => 'Escolher da galeria';

  @override
  String get socialFollowTitle => 'SIGA O GOIÁS';

  @override
  String get socialFollowSubtitle =>
      'Acompanhe o Verdão também nas redes sociais.';

  @override
  String socialOpenLink(String name) {
    return 'Abrir $name';
  }

  @override
  String get arenaSubtitle => 'Minigames rápidos para o torcedor.';

  @override
  String get arenaSectionPlayNow => 'JOGUE AGORA';

  @override
  String get arenaSectionMoreChallenges => 'MAIS DESAFIOS';

  @override
  String get arenaPlay => 'JOGAR';

  @override
  String get arenaRankingTitle => 'Ranking da Torcida';

  @override
  String get arenaRankingBannerSubtitle =>
      'Veja os melhores da torcida nos minigames.';

  @override
  String get arenaRankingEmpty => 'Ranking ainda vazio';

  @override
  String get arenaRankingEmptyMessage =>
      'Jogue e seja o primeiro a aparecer no ranking da torcida.';

  @override
  String get arenaAchievementTitle => 'LENDA ESMERALDINA';

  @override
  String get arenaAchievementMessage =>
      'Você completou 100% da Arena Esmeraldina — Quiz do Verdão, Adivinhe a Escalação e Adivinhe o Jogador. Essa conquista é permanente.';

  @override
  String get arenaAchievementConfirm => 'SHOW DE BOLA!';

  @override
  String get arenaPlayFirstTime => 'Jogue pela primeira vez';

  @override
  String arenaStatMatchesCorrect(int played, int correct) {
    return '$played partidas · $correct acertos';
  }

  @override
  String get arenaGameQuizTitle => 'Quiz do Verdão';

  @override
  String get arenaGameQuizTagline => 'Teste o quanto você conhece o Goiás.';

  @override
  String get arenaGameLineupTitle => 'Adivinhe a Escalação';

  @override
  String get arenaGameLineupTagline =>
      'Descubra os 11 titulares de uma partida histórica do Goiás.';

  @override
  String get arenaGameCareerTitle => 'Adivinhe o Jogador';

  @override
  String get arenaGameCareerTagline =>
      'Descubra o jogador pela trajetória na carreira.';

  @override
  String get arenaGuessPlayerTitle => 'Quem Vestiu o Manto?';

  @override
  String get arenaGuessPlayerTagline =>
      'Descubra o jogador secreto pela foto embaçada e pelas pistas.';

  @override
  String get arenaSubtitleQuiz => '60 perguntas';

  @override
  String get arenaSubtitleLineup => '31 escalações';

  @override
  String get arenaSubtitleCareer => '23 jogadores';

  @override
  String get arenaSubtitleGuessPlayer => 'Descubra o jogador pelas pistas';

  @override
  String get commonClose => 'FECHAR';

  @override
  String get quizChooseLevel => 'Escolha o nível';

  @override
  String get quizChooseLevelHint =>
      'Cada nível tem seu próprio banco de perguntas — quanto mais alto, mais difícil.';

  @override
  String get quizDone => 'Concluído';

  @override
  String get quizSeeResult => 'VER RESULTADO';

  @override
  String get quizNext => 'PRÓXIMA';

  @override
  String get quizHits => 'ACERTOS';

  @override
  String get quizPerfect => 'Perfeito!';

  @override
  String get quizScore => 'PONTUAÇÃO';

  @override
  String get quizNewRecord => 'Novo recorde';

  @override
  String get quizReviewErrors => 'REVISAR ERROS';

  @override
  String get quizPlayAgain => 'JOGAR NOVAMENTE';

  @override
  String get quizReviewMore => 'REVISAR MAIS';

  @override
  String get quizBackToLevels => 'VOLTAR AOS NÍVEIS';

  @override
  String get quizMoreQuestions => 'MAIS PERGUNTAS';

  @override
  String get quizBackToArena => 'VOLTAR À ARENA';

  @override
  String get quizLevelDescTorcedor =>
      'Fatos básicos, títulos e campanhas que todo torcedor conhece.';

  @override
  String get quizLevelDescEsmeraldino =>
      'História, ídolos e jogos marcantes pra quem manja do clube.';

  @override
  String get quizLevelDescFanatico =>
      'Recordes e números pra quem não erra nenhuma.';

  @override
  String quizLevelName(String level) {
    return 'Nível $level';
  }

  @override
  String quizQuestionProgress(int current, int total) {
    return 'Pergunta $current de $total';
  }

  @override
  String quizAnsweredCount(int answered, int total) {
    return '$answered/$total perguntas';
  }

  @override
  String quizPendingReview(int count) {
    return '$count para revisar';
  }

  @override
  String quizLevelCompleted(String level) {
    return 'NÍVEL $level CONCLUÍDO';
  }

  @override
  String quizAllAnswered(int total) {
    return 'Você respondeu todas as $total perguntas deste nível.';
  }

  @override
  String quizCorrectCount(int count) {
    return '$count acertadas';
  }

  @override
  String quizReviewLevel(String level) {
    return 'Revisão · Nível $level';
  }

  @override
  String quizFinalResultLevel(String level) {
    return 'Resultado final · Nível $level';
  }

  @override
  String quizScoreLine(int correct, int total) {
    return 'Você acertou $correct de $total perguntas';
  }

  @override
  String quizLevelQuestions(int answered, int total) {
    return '$answered/$total perguntas do nível';
  }

  @override
  String quizBestRecord(int best) {
    return 'Recorde: $best pts';
  }

  @override
  String get lineupPlayerHeading => 'JOGADOR';

  @override
  String lineupShirt(int number) {
    return 'CAMISA $number';
  }

  @override
  String get lineupTypePlayerName => 'Digite o nome do jogador';

  @override
  String get lineupBackToField => 'VOLTAR AO CAMPO';

  @override
  String get lineupGiveUp => 'DESISTIR DA PARTIDA';

  @override
  String get lineupGiveUpTitle => 'Desistir da partida?';

  @override
  String get lineupGiveUpMessage =>
      'Os jogadores restantes serão revelados e a partida será encerrada.';

  @override
  String get lineupGiveUpConfirm => 'DESISTIR';

  @override
  String get lineupKeepPlaying => 'Continuar jogando';

  @override
  String lineupMatchProgress(int current, int total) {
    return 'PARTIDA $current DE $total';
  }

  @override
  String lineupWordCount(int words, int letters) {
    String _temp0 = intl.Intl.pluralLogic(
      words,
      locale: localeName,
      other: '$words palavras',
      one: '1 palavra',
    );
    String _temp1 = intl.Intl.pluralLogic(
      letters,
      locale: localeName,
      other: '$letters letras',
      one: '1 letra',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String get lineupComplete => 'ESCALAÇÃO COMPLETA';

  @override
  String get lineupDiscovered => 'DESCOBERTOS';

  @override
  String get lineupAttempts => 'TENTATIVAS';

  @override
  String get lineupTime => 'TEMPO';

  @override
  String get lineupResultCopied => 'Resultado copiado.';

  @override
  String get lineupCopyResult => 'Copiar resultado';

  @override
  String get lineupShareResult => 'Compartilhar resultado';

  @override
  String get lineupNextMatch => 'PRÓXIMO JOGO';

  @override
  String get lineupPreviousMatch => 'ANTERIOR';

  @override
  String get lineupNoNumber => 'Jogador sem número confirmado';

  @override
  String lineupNotDiscovered(String shirt) {
    return '$shirt, não descoberto';
  }

  @override
  String lineupShirtLabel(int number) {
    return 'Camisa $number';
  }

  @override
  String lineupA11yRevealed(String shirt, String name) {
    return '$shirt, $name, descoberto';
  }

  @override
  String lineupA11yPending(String shirt, String position) {
    return '$shirt, $position, ainda não descoberto';
  }

  @override
  String get lineupTileCorrect => 'posição correta';

  @override
  String get lineupTilePresent => 'letra existe, posição errada';

  @override
  String get lineupTileAbsent => 'letra não existe';

  @override
  String get lineupTileEmpty => 'vazio';

  @override
  String get keyboardDelete => 'Apagar';

  @override
  String get keyboardConfirm => 'Confirmar';
}
