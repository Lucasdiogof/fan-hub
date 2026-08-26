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

  @override
  String get commonCloseLabel => 'Fechar';

  @override
  String get careerSubtitle => 'Descubra pela carreira';

  @override
  String get careerSelectFromList => 'Selecione um jogador da lista.';

  @override
  String get careerRevealTitle => 'Revelar jogador?';

  @override
  String get careerRevealMessage =>
      'Ao revelar a resposta, esta rodada será considerada encerrada.';

  @override
  String get careerReveal => 'REVELAR';

  @override
  String get careerRevealPlayer => 'Revelar jogador';

  @override
  String get careerGuess => 'CHUTAR';

  @override
  String get careerNextPlayer => 'PRÓXIMO JOGADOR';

  @override
  String careerAttemptsRemaining(int remaining) {
    return 'Tentativas · Restam $remaining';
  }

  @override
  String get careerCorrectTitle => 'Você acertou!';

  @override
  String get careerCorrectFirstTry => 'Acertou de primeira!';

  @override
  String careerCorrectInAttempts(int attempts) {
    return 'Você acertou em $attempts tentativas.';
  }

  @override
  String get careerWrongTitle => 'Não foi dessa vez';

  @override
  String careerUsedAllAttempts(int max) {
    return 'Você usou as $max tentativas.';
  }

  @override
  String get careerPlayerRevealed => 'Jogador revelado';

  @override
  String get careerRoundEnded => 'Rodada encerrada.';

  @override
  String get careerYouGotIt => 'Você acertou';

  @override
  String get careerWas => 'Era';

  @override
  String get careerAnswer => 'Resposta';

  @override
  String get careerNationalTeam => 'Seleção nacional';

  @override
  String get careerYears => 'Anos';

  @override
  String get careerClubs => 'Clubes';

  @override
  String get careerGames => 'Jogos';

  @override
  String get careerGoals => 'Gols';

  @override
  String careerOnLoan(String team) {
    return '$team (emp.)';
  }

  @override
  String get commonBack => 'VOLTAR';

  @override
  String get guessCorrectTitle => 'ACERTOU!';

  @override
  String get guessOutOfAttempts => 'Fim das tentativas';

  @override
  String guessCorrectDetail(int used, int max) {
    return 'Você acertou em $used de $max tentativas.';
  }

  @override
  String get guessNoPlayers =>
      'Nenhum jogador disponível pra essa arena ainda.';

  @override
  String get guessRoundEnded => 'Rodada encerrada';

  @override
  String guessAttemptsRemaining(int remaining) {
    return '$remaining tentativas restantes';
  }

  @override
  String get guessThePlayerWas => 'O jogador era: ';

  @override
  String get guessTypePlayer => 'Digite um jogador...';

  @override
  String get guessColPos => 'POS';

  @override
  String get guessColShirt => 'CAMISA';

  @override
  String get guessColBase => 'BASE';

  @override
  String get guessColDebut => 'ESTREIA';

  @override
  String dateMinutesAgo(int minutes) {
    return '${minutes}min atrás';
  }

  @override
  String dateHoursAgo(int hours) {
    return '${hours}h atrás';
  }

  @override
  String dateDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias atrás',
      one: '1 dia atrás',
    );
    return '$_temp0';
  }

  @override
  String datePrepositionFull(int day, String month) {
    return '$day de $month';
  }

  @override
  String get socialMediaTitle => 'MÍDIA';

  @override
  String get socialMediaSubtitle => 'Goiás na Rede';

  @override
  String get socialFeedLoadError => 'Não foi possível carregar o feed';

  @override
  String get socialEmptyState => 'Acompanhe o Goiás nas redes';

  @override
  String socialViewsM(String value) {
    return '${value}M visualizações';
  }

  @override
  String socialViewsK(String value) {
    return '${value}K visualizações';
  }

  @override
  String socialViewsCount(int count) {
    return '$count visualizações';
  }

  @override
  String get newsTitle => 'NOTÍCIAS';

  @override
  String get newsLoadError => 'Não foi possível carregar as notícias';

  @override
  String get newsEmptyTitle => 'Nenhuma notícia por aqui ainda';

  @override
  String get newsEmptyMessage =>
      'Volte mais tarde para conferir as novidades do Goiás.';

  @override
  String get newsSourceLabel => 'FONTE: GOIÁS ESPORTE CLUBE';

  @override
  String get newsOpenOriginal => 'Abrir matéria original';

  @override
  String get newsSeeMore => 'Ver mais';

  @override
  String get commonNoConnection => 'Sem conexão com a internet.';

  @override
  String get relTimeNow => 'agora';

  @override
  String relTimeMinutes(int n) {
    return '${n}min';
  }

  @override
  String relTimeHours(int n) {
    return '${n}h';
  }

  @override
  String relTimeDays(int n) {
    return '${n}d';
  }

  @override
  String relTimeWeeks(int n) {
    return '${n}sem';
  }

  @override
  String relTimeMonths(int n) {
    return '${n}m';
  }

  @override
  String get partnersTitle => 'Parceiros do Goiás';

  @override
  String get partnersSubtitle => 'Marcas que caminham junto com o Verdão.';

  @override
  String get partnersSectionTitle => 'PARCEIROS DO GOIÁS';

  @override
  String get partnersSeeAll => 'Ver todos';

  @override
  String partnersOpenInstagram(String name) {
    return 'Abrir Instagram de $name';
  }

  @override
  String partnersOpenWebsite(String name) {
    return 'Abrir site de $name';
  }

  @override
  String get squadTitle => 'ELENCO';

  @override
  String get squadLoadError => 'Não foi possível carregar o elenco';

  @override
  String get squadEmpty => 'Elenco indisponível no momento';

  @override
  String get squadClubHistory => 'HISTÓRICO DE CLUBES';

  @override
  String get squadNumber => 'Número';

  @override
  String get squadAge => 'Idade';

  @override
  String squadAgeValue(int age) {
    return '$age anos';
  }

  @override
  String get squadNationality => 'Nacionalidade';

  @override
  String get squadHeight => 'Altura';

  @override
  String get squadFoot => 'Pé';

  @override
  String get squadHistoryYears => 'Anos';

  @override
  String get squadHistoryClubs => 'Clubes';

  @override
  String get squadHistoryMatches => 'Jogos';

  @override
  String get squadHistoryGoals => 'Gols';

  @override
  String get squadLoanTag => '(emp.)';

  @override
  String get squadDataUnconfirmed => 'Dado não confirmado na fonte.';

  @override
  String get squadGroupGoalkeepers => 'Goleiros';

  @override
  String get squadGroupDefenders => 'Zagueiros';

  @override
  String get squadGroupRightBacks => 'Laterais-direitos';

  @override
  String get squadGroupLeftBacks => 'Laterais-esquerdos';

  @override
  String get squadGroupDefensiveMids => 'Volantes';

  @override
  String get squadGroupMidfielders => 'Meios-campistas';

  @override
  String get squadGroupForwards => 'Atacantes';

  @override
  String get validatorNameRequired => 'Informe seu nome completo.';

  @override
  String get validatorEmailRequired => 'Informe seu e-mail.';

  @override
  String get validatorEmailInvalid => 'Informe um e-mail válido.';

  @override
  String get validatorPasswordRequired => 'Informe sua senha.';

  @override
  String get validatorPasswordCreate => 'Crie uma senha.';

  @override
  String validatorPasswordMinLength(int min) {
    return 'A senha deve ter ao menos $min caracteres.';
  }

  @override
  String get validatorConfirmRequired => 'Confirme sua senha.';

  @override
  String get validatorPasswordsDoNotMatch => 'As senhas não coincidem.';

  @override
  String get checkEmailResent =>
      'E-mail reenviado. Confira sua caixa de entrada.';

  @override
  String get checkEmailTitle => 'Confirme seu e-mail';

  @override
  String get checkEmailSentTo => 'Enviamos um link de confirmação para:';

  @override
  String get checkEmailInstruction =>
      'Abra sua caixa de entrada e confirme seu e-mail para ativar a conta.';

  @override
  String get checkEmailBackToLogin => 'Voltar para o login';

  @override
  String get checkEmailResending => 'Reenviando...';

  @override
  String checkEmailResendIn(int seconds) {
    return 'Reenviar em ${seconds}s';
  }

  @override
  String get checkEmailResend => 'Reenviar e-mail';

  @override
  String get resetPasswordTitle => 'Criar nova senha';

  @override
  String get resetPasswordSubtitle =>
      'Escolha uma nova senha para acessar sua conta.';

  @override
  String get resetPasswordSuccessTitle => 'Senha alterada com sucesso';

  @override
  String get resetPasswordSuccessMessage =>
      'Sua senha foi atualizada. Entre novamente para continuar.';

  @override
  String get forgotVerifyEmailTitle => 'Verifique seu e-mail';

  @override
  String forgotSentInstructions(String email) {
    return 'Enviamos as instruções de redefinição para $email.';
  }

  @override
  String get forgotTitle => 'Recuperar senha';

  @override
  String get forgotSubtitle =>
      'Informe seu e-mail e enviaremos as instruções para redefinir sua senha.';

  @override
  String get forgotSendButton => 'ENVIAR INSTRUÇÕES';

  @override
  String get forgotSending => 'Enviando...';

  @override
  String get authShowPassword => 'Mostrar senha';

  @override
  String get authHidePassword => 'Ocultar senha';

  @override
  String get ticketsLoadError => 'Não foi possível carregar os ingressos.';

  @override
  String get ticketsNextEvent => 'PRÓXIMO EVENTO';

  @override
  String get ticketsQuickAccess => 'ACESSO RÁPIDO';

  @override
  String get ticketsMyTickets => 'Meus ingressos';

  @override
  String get ticketsMyTicketsSubtitle => 'Ingressos para partidas do Goiás';

  @override
  String get ticketsMyOrders => 'Meus pedidos';

  @override
  String get ticketsMyOrdersSubtitle => 'Histórico das suas compras';

  @override
  String get ticketsNoEvents => 'Nenhum evento disponível no momento';

  @override
  String get ticketsNoEventsMessage =>
      'Quando uma nova partida estiver disponível para venda ou check-in, ela aparecerá aqui.';

  @override
  String get ticketsMyTicketsTitle => 'MEUS INGRESSOS';

  @override
  String get ticketsMyTicketsLoadError =>
      'Não foi possível carregar seus ingressos';

  @override
  String get ticketsMyTicketsEmpty => 'Você ainda não possui ingressos';

  @override
  String get ticketsMyTicketsEmptyMessage =>
      'Seus ingressos para partidas do Goiás aparecerão aqui.';

  @override
  String get ticketsMyOrdersTitle => 'MEUS PEDIDOS';

  @override
  String get ticketsMyOrdersLoadError =>
      'Não foi possível carregar seus pedidos';

  @override
  String get ticketsMyOrdersEmpty => 'Nenhum pedido encontrado';

  @override
  String get ticketsMyOrdersEmptyMessage =>
      'Suas compras de ingressos aparecerão aqui.';

  @override
  String ticketsOrderNumber(String number) {
    return 'Pedido $number';
  }

  @override
  String get ticketStatusValid => 'Válido';

  @override
  String get ticketStatusUsed => 'Utilizado';

  @override
  String get ticketStatusCancelled => 'Cancelado';

  @override
  String get orderStatusConfirmed => 'Confirmado';

  @override
  String get orderStatusPending => 'Pendente';

  @override
  String get orderStatusCancelled => 'Cancelado';

  @override
  String get orderStatusRefunded => 'Reembolsado';

  @override
  String get penaltyFinalResult => 'RESULTADO FINAL';

  @override
  String penaltyConverted(int goals, int total) {
    return 'Você converteu $goals de $total cobranças';
  }

  @override
  String get penaltyScoreLabel => 'PÊNALTIS';

  @override
  String get penaltyDragToShoot => 'Arraste a bola para chutar';

  @override
  String penaltyGoalsCount(int goals) {
    String _temp0 = intl.Intl.pluralLogic(
      goals,
      locale: localeName,
      other: '$goals Gols',
      one: '1 Gol',
    );
    return '$_temp0';
  }

  @override
  String penaltyGoalsCountUpper(int goals) {
    String _temp0 = intl.Intl.pluralLogic(
      goals,
      locale: localeName,
      other: '$goals GOLS',
      one: '1 GOL',
    );
    return '$_temp0';
  }

  @override
  String get penaltyResultGoal => 'GOL!';

  @override
  String get penaltyResultSave => 'DEFESA!';

  @override
  String get penaltyResultOut => 'PRA FORA!';

  @override
  String get penaltyResultPost => 'NA TRAVE!';

  @override
  String get penaltyResultGoalShort => 'Gol';

  @override
  String get penaltyResultSaveShort => 'Defesa';

  @override
  String get penaltyResultOutShort => 'Fora';

  @override
  String get penaltyResultPostShort => 'Trave';

  @override
  String get crowdTitle => 'ESCALAÇÃO DA TORCIDA';

  @override
  String get crowdTabEscale => 'ESCALE';

  @override
  String crowdSubmissionsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'escalações enviadas',
      one: 'escalação enviada',
    );
    return '$_temp0';
  }

  @override
  String get crowdMostVotedFormation => 'formação mais votada';

  @override
  String get crowdNoVotes => 'Ainda não há votos';

  @override
  String get crowdNoVotesMessage =>
      'Seja o primeiro a escalar o Goiás e ajude a formar o time da torcida.';

  @override
  String get crowdVotingClosed =>
      'Votação encerrada — esta é a escalação que você enviou.';

  @override
  String get crowdUpdateLineup => 'ATUALIZAR ESCALAÇÃO';

  @override
  String get crowdConfirmLineup => 'CONFIRMAR ESCALAÇÃO';

  @override
  String get crowdPickPlayer => 'Escolha o jogador para esta posição';

  @override
  String get crowdSelectedPlayer => 'Escalado';

  @override
  String get crowdCardTitleVoted => 'Escalação da Torcida';

  @override
  String get crowdCardTitleNew => 'Monte a escalação da torcida';

  @override
  String get crowdCardDescVoted =>
      'Veja como a torcida está escalando o Goiás para o próximo jogo.';

  @override
  String get crowdCardDescNew =>
      'Escale o Goiás para o próximo jogo e veja o time mais escalado pela torcida.';

  @override
  String get crowdCardCtaView => 'VER ESCALAÇÃO DA TORCIDA';

  @override
  String get crowdCardCtaEscale => 'ESCALAR AGORA';

  @override
  String get clubSectionHistory => 'História';

  @override
  String get clubSectionSquad => 'Elenco';

  @override
  String get clubSectionTitles => 'Títulos';

  @override
  String get clubSectionPartners => 'Parceiros';

  @override
  String get clubSectionTimeline => 'Linha do Tempo';

  @override
  String get clubSectionSongs => 'Hino & Músicas';

  @override
  String get clubHistorySubtitle => 'De 1943 até os dias de hoje.';

  @override
  String get clubSquadSubtitle => 'Os jogadores que vestem o manto.';

  @override
  String clubTitlesSubtitle(int count) {
    return '$count conquistas ao longo da história.';
  }

  @override
  String get clubPartnersSubtitle => 'Quem caminha junto com o Verdão.';

  @override
  String get clubAnthemSection => 'HINO';

  @override
  String get clubSongsSection => 'MÚSICAS ESMERALDINAS';

  @override
  String get clubViewLyrics => 'VER LETRA';

  @override
  String get clubMainTitles => 'TÍTULOS PRINCIPAIS';

  @override
  String get clubHistoricCampaigns => 'CAMPANHAS HISTÓRICAS';

  @override
  String get clubCampaignsSubtitle =>
      'Grandes campanhas do Goiás que não resultaram em título.';

  @override
  String clubTimesChampion(int count) {
    return '$count× CAMPEÃO';
  }

  @override
  String get clubEntryTitle => 'O CLUBE';

  @override
  String get clubEntrySubtitle =>
      'História, títulos, elenco e identidade do Verdão.';

  @override
  String get clubEntryCta => 'CONHECER O GOIÁS';

  @override
  String get clubHeaderTagline => 'O MAIOR DO CENTRO-OESTE';

  @override
  String get membershipLoadError =>
      'Não foi possível carregar o Sócio Esmeralda.';

  @override
  String get membershipPlansTitle => 'PLANOS';

  @override
  String membershipSector(String sector) {
    return 'Setor $sector';
  }

  @override
  String get membershipMostChosen => 'MAIS ESCOLHIDO';

  @override
  String get membershipPerMonth => '/mês';

  @override
  String membershipOrAnnual(String price) {
    return 'ou $price no plano anual';
  }

  @override
  String get membershipBenefits => 'BENEFÍCIOS';

  @override
  String get membershipSeeFullRegulation => 'Consulte o regulamento completo →';

  @override
  String get membershipStillHaveDoubts => 'Ainda tem dúvidas sobre este plano?';

  @override
  String get membershipSeeFaq => 'VER DÚVIDAS FREQUENTES';

  @override
  String get membershipWantToJoin => 'QUERO SER SÓCIO';

  @override
  String get membershipStadiumAccess => 'Acesso ao estádio';

  @override
  String get membershipNoStadiumAccess => 'Sem acesso ao estádio';

  @override
  String get membershipViewPlan => 'CONHECER PLANO';

  @override
  String get membershipCheckinUnavailable =>
      'O check-in do Sócio Esmeralda ainda não está disponível no app.';

  @override
  String get membershipOtherOptions => 'OUTRAS OPÇÕES';

  @override
  String get membershipMyMembership => 'Minha associação';

  @override
  String get membershipDependents => 'Dependentes';

  @override
  String get membershipDependentsPrep =>
      'A gestão de dependentes ainda está sendo preparada.';

  @override
  String get membershipPayments => 'Pagamentos';

  @override
  String get membershipPaymentsPrep =>
      'O histórico de pagamentos ainda está sendo preparado.';

  @override
  String get membershipCheckinHistory => 'Histórico de check-ins';

  @override
  String get membershipAreaPrep => 'Essa área ainda está sendo preparada.';

  @override
  String get membershipSeeOtherPlans => 'Conhecer outros planos';

  @override
  String get membershipHeroTitle => 'Esteja ainda mais próximo\ndo Goiás.';

  @override
  String get membershipHeroSubtitle =>
      'Faça parte dessa história com prioridade de acesso ao estádio, economia em ingressos, descontos e experiências exclusivas.';

  @override
  String get membershipChoosePlan => 'ESCOLHA SEU PLANO';

  @override
  String get membershipChosenPlan => 'PLANO ESCOLHIDO';

  @override
  String get membershipChangePlan => 'ALTERAR PLANO';

  @override
  String get membershipStep1Access => '1 de 3 · Dados de acesso';

  @override
  String get membershipStep2Personal => '2 de 3 · Dados cadastrais';

  @override
  String get membershipStep3Address => '3 de 3 · Endereço';

  @override
  String get membershipCpf => 'CPF';

  @override
  String get membershipNationality => 'Nacionalidade';

  @override
  String get membershipPassport => 'Passaporte';

  @override
  String get membershipPassportOptional => 'Passaporte (opcional)';

  @override
  String get membershipContactEmail => 'E-mail de contato';

  @override
  String get membershipNickname => 'Apelido (opcional)';

  @override
  String get membershipBirthdateHint => 'DD/MM/AAAA';

  @override
  String get membershipGender => 'Sexo';

  @override
  String get membershipGenderMale => 'Masculino';

  @override
  String get membershipGenderFemale => 'Feminino';

  @override
  String get membershipHomePhone => 'Telefone residencial (opcional)';

  @override
  String get membershipNewsletter =>
      'Desejo receber notícias do clube e do Sócio Esmeralda por e-mail.';

  @override
  String get membershipCountry => 'País';

  @override
  String get membershipPostalCode => 'Código postal';

  @override
  String get membershipDontKnowCep => 'Não sei meu CEP';

  @override
  String get membershipLoadingCities => 'Carregando cidades...';

  @override
  String get membershipSelectStateFirst => 'Selecione o estado primeiro';

  @override
  String get membershipSelectCity => 'Selecionar cidade';

  @override
  String get membershipConfirmAssociation => 'CONFIRMAR ASSOCIAÇÃO';

  @override
  String get membershipReviewTitle => 'REVISE SUA ASSOCIAÇÃO';

  @override
  String get membershipPlanLabel => 'Plano';

  @override
  String get membershipSectorLabel => 'Setor';

  @override
  String get membershipOptionLabel => 'Opção';

  @override
  String get membershipHolderData => 'DADOS DO TITULAR';

  @override
  String get membershipName => 'Nome';

  @override
  String get membershipBirthLabel => 'Nascimento';

  @override
  String get membershipContact => 'CONTATO';

  @override
  String get membershipAddressLabel => 'Endereço';

  @override
  String get membershipCityUf => 'Cidade/UF';

  @override
  String get membershipValue => 'VALOR';

  @override
  String get membershipMonthly => 'Mensal';

  @override
  String get membershipAnnual => 'Anual';

  @override
  String get membershipTerms => 'TERMOS DA ASSOCIAÇÃO';

  @override
  String get membershipAcceptRegulation =>
      'Li e aceito o Regulamento do Sócio Esmeralda';

  @override
  String get membershipReadFullRegulation => 'Ler regulamento completo →';

  @override
  String get membershipYourMembership => 'SUA ASSOCIAÇÃO';

  @override
  String get membershipYourBenefits => 'SEUS BENEFÍCIOS';

  @override
  String get membershipGoToMemberArea => 'IR PARA MINHA ÁREA DE SÓCIO';

  @override
  String get membershipBackToHome => 'Voltar para o início';

  @override
  String get membershipWelcome => 'BEM-VINDO AO\nSÓCIO ESMERALDA';

  @override
  String get membershipSuccessMessage =>
      'Sua associação foi concluída com sucesso.\nAgora você está ainda mais perto do Verdão.';

  @override
  String membershipAnnualPlan(String price) {
    return 'Plano anual • $price';
  }

  @override
  String get membershipHolder => 'Titular';

  @override
  String membershipCpfMasked(String cpf) {
    return 'CPF $cpf';
  }

  @override
  String get membershipAssociatedSince => 'Associado desde';

  @override
  String get membershipStatusActive => 'Ativo';

  @override
  String get membershipSeeAllBenefits => 'Ver todos os benefícios →';

  @override
  String get membershipWhatNow => 'E AGORA?';

  @override
  String get membershipWhatNowMessage =>
      'Sua área de sócio já está disponível. Acompanhe seu plano e seus benefícios e, quando disponível, faça o check-in nos jogos.';

  @override
  String get membershipSituation => 'Situação';

  @override
  String get membershipMemberNumber => 'Número do sócio';

  @override
  String get membershipMonthlyFee => 'Mensalidade';

  @override
  String get membershipAnnualFee => 'Anuidade';

  @override
  String get membershipMemberSince => 'Sócio desde';

  @override
  String get membershipRegulationName => 'Regulamento do Sócio Esmeralda';

  @override
  String membershipCancelWhatsapp(String plan) {
    return 'Olá, gostaria de cancelar minha associação Sócio Esmeralda ($plan).';
  }

  @override
  String get membershipCancel => 'CANCELAR ASSOCIAÇÃO';

  @override
  String get membershipCancelInfo =>
      'O cancelamento é feito com o atendimento pelo WhatsApp, sem cobrança de multa fora dos prazos previstos no Regulamento.';

  @override
  String get membershipStatusPending => 'Pendente';

  @override
  String get membershipStatusSuspended => 'Suspenso';

  @override
  String get membershipStatusCancelled => 'Cancelado';

  @override
  String get membershipFaqTitle => 'DÚVIDAS FREQUENTES';

  @override
  String get membershipFaqSubtitle =>
      'Encontre respostas sobre planos, pagamentos, check-in e benefícios.';

  @override
  String get membershipFaqLoadError =>
      'Não foi possível carregar as dúvidas frequentes.';

  @override
  String get membershipFaqNoResults => 'Nenhuma dúvida encontrada';

  @override
  String get membershipFaqNoResultsMessage =>
      'Tente outro termo ou fale com o atendimento do Sócio Esmeralda.';

  @override
  String get membershipTalkToSupport => 'FALAR COM O ATENDIMENTO';

  @override
  String get membershipTalkToSupportMenu => 'Falar com o atendimento';

  @override
  String get membershipDontStayInDoubt => 'NÃO FIQUE NA DÚVIDA';

  @override
  String get membershipDidntFindAnswer =>
      'Não encontrou a resposta que procurava?';

  @override
  String get membershipFaqScopeNote =>
      'Dúvidas sobre o clube, categorias de base, elenco e outros assuntos fora do Sócio Esmeralda não são respondidas por este canal.';

  @override
  String get membershipFaqAll => 'Todas';

  @override
  String get membershipFaqSearchHint => 'Buscar uma dúvida...';

  @override
  String get membershipHelpTitle => 'AJUDA E INFORMAÇÕES';

  @override
  String get membershipFaqMenuItem => 'Dúvidas frequentes';

  @override
  String get membershipFindCepTitle => 'ENCONTRAR MEU CEP';

  @override
  String get membershipFindCepSubtitle =>
      'Informe seu endereço para encontrarmos o CEP correspondente.';

  @override
  String get membershipStreetLabel => 'Rua / Logradouro';

  @override
  String get membershipSearchCep => 'BUSCAR CEP';

  @override
  String get membershipFoundAddresses => 'ENCONTRAMOS ESTES ENDEREÇOS';

  @override
  String get membershipNoAddressFound => 'Nenhum endereço encontrado.';

  @override
  String get membershipNoAddressHint =>
      'Confira o estado, a cidade e o logradouro informados.';

  @override
  String get membershipAddressSearchError =>
      'Não foi possível buscar o endereço.';

  @override
  String get membershipValCpfRequired => 'Informe seu CPF.';

  @override
  String get membershipValNationality => 'Selecione sua nacionalidade.';

  @override
  String get membershipValPassport => 'Informe um passaporte válido.';

  @override
  String get membershipValContactEmail => 'Informe seu e-mail de contato.';

  @override
  String get membershipValNameInvalid => 'Informe um nome válido.';

  @override
  String get membershipValBirthRequired => 'Informe sua data de nascimento.';

  @override
  String get membershipValBirthInvalid => 'Informe uma data válida.';

  @override
  String get membershipValMinAge => 'O titular precisa ter 18 anos ou mais.';

  @override
  String get membershipValSelectOption => 'Selecione uma opção.';

  @override
  String get membershipValPhoneRequired => 'Informe seu celular.';

  @override
  String get membershipValPhoneInvalid => 'Informe um celular válido.';

  @override
  String get membershipValCountry => 'Selecione o país.';

  @override
  String get membershipValCep8 => 'Informe um CEP com 8 dígitos.';

  @override
  String get membershipCepLookupError => 'Não foi possível consultar o CEP.';

  @override
  String get membershipValStreet => 'Informe o logradouro.';

  @override
  String get membershipValNumber => 'Informe o número.';

  @override
  String get membershipValNeighborhood => 'Informe o bairro.';

  @override
  String get membershipValState => 'Informe o estado.';

  @override
  String get membershipValCity => 'Informe a cidade.';

  @override
  String arenaYouMarker(String name) {
    return '$name (você)';
  }

  @override
  String arenaYourPosition(int rank) {
    return '#$rank sua posição';
  }

  @override
  String lineupShareStats(int solved, int total, int attempts, String time) {
    return '$solved/$total descobertos · $attempts tentativas · $time';
  }

  @override
  String get crowdShareCrowd => 'Confira a escalação da torcida pro Goiás! 💚';

  @override
  String get crowdShareMine => 'Essa é a minha escalação pro Goiás! 💚';

  @override
  String get crowdSubmitted => 'Escalação enviada!';
}
