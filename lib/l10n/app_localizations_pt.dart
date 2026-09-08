// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get settingsLanguageTitle => 'IDIOMA';

  @override
  String get settingsLanguageMenu => 'Idioma';

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
  String get authForgotPassword => 'Esqueci a senha';

  @override
  String get authSignInButton => 'ENTRAR';

  @override
  String get authSignInErrorTitle => 'Não foi possível entrar';

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
  String get authRegisterButton => 'CRIAR MINHA CONTA';

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
  String get authStepPersonal => 'Seus dados';

  @override
  String get authStepContact => 'Contato';

  @override
  String get authStepSecurity => 'Segurança';

  @override
  String authMarketingOptIn(String clubShortName) {
    return 'Quero receber novidades, promoções e informações do $clubShortName';
  }

  @override
  String authPasswordRequirementLength(int count) {
    return 'Mínimo de $count caracteres';
  }

  @override
  String get authCpfLabel => 'CPF';

  @override
  String get authBirthDateHint => 'DD/MM/AAAA';

  @override
  String get navHome => 'Início';

  @override
  String get navMatches => 'Jogos';

  @override
  String get navMembership => 'Sócio';

  @override
  String get navMedia => 'Mídia';

  @override
  String get navStore => 'Loja';

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
  String get homeCompactMatchToday => 'HOJE';

  @override
  String get homeCompactMatchFinished => 'Fim de jogo';

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
  String get matchGamesTitle => 'JOGOS';

  @override
  String get matchTabMatches => 'PARTIDAS';

  @override
  String get matchTabCalendar => 'CALENDÁRIO';

  @override
  String get matchTabStandings => 'CLASSIFICAÇÃO';

  @override
  String get matchCalendarHome => 'CASA';

  @override
  String get matchCalendarAway => 'FORA';

  @override
  String get matchLoadError => 'Não foi possível carregar os jogos';

  @override
  String get matchNoMatches => 'Nenhuma partida encontrada.';

  @override
  String get matchDetailsLoadError => 'Não foi possível carregar a partida.';

  @override
  String get matchBuyTicket => 'COMPRAR INGRESSO';

  @override
  String get matchDetailsShort => 'DETALHES DO JOGO';

  @override
  String get matchFollowLive => 'ACOMPANHAR JOGO';

  @override
  String get matchViewDetails => 'VER DETALHES';

  @override
  String get matchFinishedLabel => 'Finalizado';

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
  String get matchStatsTitle => 'ESTATÍSTICAS';

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
  String get matchCurrentRound => 'Rodada atual';

  @override
  String get commonSave => 'SALVAR';

  @override
  String get commonSaving => 'Salvando...';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonContinue => 'CONTINUAR';

  @override
  String get commonDemoTag => 'Demonstração';

  @override
  String get commonDemoBannerTitle => 'Demonstração';

  @override
  String get profileTitle => 'PERFIL';

  @override
  String get profileMyAccount => 'MINHA CONTA';

  @override
  String get profilePersonalData => 'Dados pessoais';

  @override
  String get profileMyAddress => 'Endereço residencial';

  @override
  String get profileDeliveryAddresses => 'Endereços de entrega';

  @override
  String get profileSecurity => 'Segurança';

  @override
  String get profileAppearance => 'Aparência';

  @override
  String get profileNotifications => 'Notificações';

  @override
  String get profileMyJourney => 'MINHA JORNADA';

  @override
  String get profilePreferences => 'PREFERÊNCIAS';

  @override
  String get profilePurchasesAndServices => 'COMPRAS E SERVIÇOS';

  @override
  String get profileMyTickets => 'Meus ingressos';

  @override
  String profileVersion(Object version) {
    return 'Versão $version';
  }

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
  String get authSessionExpiredTitle => 'Sua sessão expirou';

  @override
  String get authSessionExpiredMessage =>
      'Por segurança, precisamos confirmar seu acesso novamente. Entre na sua conta para continuar usando todos os recursos do Goiás.';

  @override
  String get authSessionExpiredCta => 'Entrar novamente';

  @override
  String get authErrorInvalidCredentials => 'E-mail ou senha incorretos.';

  @override
  String get authErrorCurrentPasswordIncorrect => 'Senha atual incorreta.';

  @override
  String get authErrorPasswordIncorrect => 'Senha incorreta.';

  @override
  String get authErrorEmailAlreadyRegistered =>
      'Este e-mail já possui uma conta.';

  @override
  String get authErrorWeakPassword =>
      'A senha não atende aos requisitos mínimos.';

  @override
  String get authErrorInvalidEmail => 'Informe um e-mail válido.';

  @override
  String get authErrorRateLimited =>
      'Já enviamos um código recentemente. Aguarde um pouco antes de solicitar outro.';

  @override
  String get authErrorOtpInvalidOrExpired =>
      'Este código não é válido ou já expirou. Confira e tente novamente, ou solicite um novo código.';

  @override
  String get authErrorSessionExpired =>
      'Sua sessão expirou. Faça login novamente.';

  @override
  String get authErrorSignupDisabled =>
      'Novos cadastros estão temporariamente indisponíveis.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Confirme seu e-mail antes de entrar.';

  @override
  String get authErrorServiceUnavailable =>
      'O serviço está temporariamente indisponível. Tente novamente em instantes.';

  @override
  String get authErrorNewPasswordSameAsCurrent =>
      'A nova senha precisa ser diferente da atual.';

  @override
  String get authErrorCpfAlreadyTaken =>
      'Este CPF já está cadastrado em outra conta.';

  @override
  String get authErrorAccountDeletionFailed =>
      'Não foi possível excluir sua conta. Tente novamente em alguns instantes.';

  @override
  String get authErrorNetwork => 'Verifique sua conexão com a internet.';

  @override
  String get authErrorGeneric =>
      'Não foi possível concluir agora. Tente novamente.';

  @override
  String get personalDataTitle => 'DADOS PESSOAIS';

  @override
  String get personalDataLoadError => 'Não foi possível carregar seus dados.';

  @override
  String get personalFieldCpf => 'CPF (opcional)';

  @override
  String get personalFieldBirthDate => 'Data de nascimento';

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
  String get addressTitle => 'ENDEREÇO RESIDENCIAL';

  @override
  String get addressResidentialSubtitle =>
      'Seu endereço principal cadastrado na conta.';

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
  String get settingsNotificationsTitle => 'NOTIFICAÇÕES';

  @override
  String get notificationsMatchesTitle => 'Partidas do Goiás';

  @override
  String get notificationsMatchesDescription =>
      'Gols e resultado final em tempo real.';

  @override
  String get notificationsTicketsTitle => 'Ingressos e check-in';

  @override
  String get notificationsTicketsDescription =>
      'Avisos quando a venda ou o check-in abrirem.';

  @override
  String get notificationsOsBlockedMessage =>
      'As notificações estão desativadas nas configurações do sistema — você não vai receber nada até reativar.';

  @override
  String get notificationsOpenSettings => 'Abrir configurações';

  @override
  String get notificationsForegroundCta => 'Ver';

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
  String get arenaTitle => 'Arena Esmeraldina';

  @override
  String get arenaGamesSectionSubtitle =>
      'Teste seus conhecimentos sobre o Verdão.';

  @override
  String get arenaNextMatchBadge => 'PRÓXIMO JOGO';

  @override
  String get arenaHighlightViewLineup => 'Ver escalação';

  @override
  String get arenaPlay => 'JOGAR';

  @override
  String get arenaRankingTitle => 'Ranking da Torcida';

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
  String get arenaHeaderSubtitle => 'Jogue, participe e viva o Goiás.';

  @override
  String get arenaSpotlightEyebrow => 'Arena Esmeraldina';

  @override
  String get arenaSpotlightHeadline => 'A sua paixão entra em campo';

  @override
  String get arenaSpotlightSubtitle =>
      'Jogue, participe e dispute seu lugar entre os Esmeraldinos.';

  @override
  String get arenaSpotlightCta => 'Entrar na Arena';

  @override
  String get arenaLineupHeroEyebrow => 'ESCALAÇÃO DA TORCIDA';

  @override
  String get arenaLineupHeroCta => 'Montar minha escalação';

  @override
  String get arenaLineupHeroEmptyTitle => 'Sem jogo por enquanto';

  @override
  String get arenaLineupHeroEmptyMessage =>
      'Assim que a próxima partida for confirmada, você já pode montar sua escalação aqui.';

  @override
  String get arenaChallengesSectionTitle => 'Desafios';

  @override
  String get arenaChallengeCtaContinue => 'Continuar';

  @override
  String get arenaChallengeCtaStart => 'Começar';

  @override
  String get arenaChallengeCtaCompleted => 'Concluído';

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
  String get arenaRankingWeekly => 'Semanal';

  @override
  String get arenaRankingMonthly => 'Mensal';

  @override
  String get arenaRankingAllTime => 'Geral';

  @override
  String get arenaRankingPoints => 'pts';

  @override
  String get arenaRankingYourPosition => 'SUA POSIÇÃO';

  @override
  String get arenaRankingMemberBadge => 'Sócio';

  @override
  String get arenaRankingUnknownFan => 'Torcedor';

  @override
  String get passportCardCta => 'Abrir passaporte';

  @override
  String get passportRankingCta => 'Ranking do Passaporte';

  @override
  String get passportLoadErrorTitle => 'Não foi possível carregar o passaporte';

  @override
  String get passportEmptyCatalogTitle => 'Nenhuma temporada disponível ainda';

  @override
  String get passportNoMatchesForFilter =>
      'Nenhuma partida encontrada com esse filtro';

  @override
  String get passportSummaryTotalMatches => 'Partidas registradas';

  @override
  String get passportSummaryYearsCount => 'Anos com presença';

  @override
  String get passportSummaryFirstMatch => 'Primeira partida';

  @override
  String get passportSummaryLastMatch => 'Última partida';

  @override
  String get passportFilterAll => 'Todos';

  @override
  String get passportFilterAttended => 'Marcados';

  @override
  String get passportFilterNotAttended => 'Não marcados';

  @override
  String get passportFilterHome => 'Casa';

  @override
  String get passportFilterAway => 'Fora';

  @override
  String get passportFilterAllCompetitions => 'Todas as competições';

  @override
  String get passportStatusScheduled => 'Agendado';

  @override
  String get passportStatusPostponed => 'Adiado';

  @override
  String get passportStatusCancelled => 'Cancelado';

  @override
  String get passportOutcomeWin => 'Vitória';

  @override
  String get passportOutcomeDraw => 'Empate';

  @override
  String get passportOutcomeLoss => 'Derrota';

  @override
  String get passportSaveGenericLabel => 'Salvar alterações';

  @override
  String passportSaveCountLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Salvar $count partidas',
      one: 'Salvar 1 partida',
    );
    return '$_temp0';
  }

  @override
  String get passportSaveSuccess => 'Passaporte atualizado.';

  @override
  String get passportDiscardChangesTitle => 'Descartar alterações?';

  @override
  String get passportDiscardChangesMessage =>
      'Você marcou partidas que ainda não foram salvas. Se sair agora, essas marcações são perdidas.';

  @override
  String get passportDiscardChangesConfirm => 'Descartar';

  @override
  String get passportRankingTitle => 'Ranking do Passaporte';

  @override
  String get passportRankingPeriodOverall => 'Geral';

  @override
  String passportRankingMatchCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidas',
      one: '1 partida',
    );
    return '$_temp0';
  }

  @override
  String get passportRankingEmptyTitle => 'Ninguém no ranking ainda';

  @override
  String get passportRankingEmptyMessage =>
      'Marque suas partidas no Passaporte pra aparecer aqui.';

  @override
  String get passportStatsTitle => 'Minha trajetória';

  @override
  String get passportStatsWins => 'Vitórias';

  @override
  String get passportStatsDraws => 'Empates';

  @override
  String get passportStatsLosses => 'Derrotas';

  @override
  String get passportStatsHomeGames => 'Em casa';

  @override
  String get passportStatsAwayGames => 'Fora de casa';

  @override
  String get passportStatsGoalsFor => 'Gols marcados';

  @override
  String get passportStatsGoalsAgainst => 'Gols sofridos';

  @override
  String get passportStatsGoalDifference => 'Saldo';

  @override
  String get passportStatsEmptyTitle => 'Sua trajetória começa aqui';

  @override
  String get passportStatsEmptyMessage =>
      'Marque partidas como \"Eu fui\" pra ver suas estatísticas.';

  @override
  String get passportTrajectoryGames => 'Jogos';

  @override
  String get passportTrajectoryStadiums => 'Estádios';

  @override
  String get passportTrajectorySeasons => 'Temporadas';

  @override
  String get passportTrajectoryMemorableMatch => 'Jogo mais memorável';

  @override
  String get passportTrajectoryMemorableEmpty =>
      'Escolha seu jogo mais memorável';

  @override
  String get passportTrajectoryPickMatch => 'Escolha seu jogo mais memorável';

  @override
  String get passportTrajectoryMostVisitedStadium => 'Estádio mais visitado';

  @override
  String get passportTrajectoryStadiumUnavailable =>
      'Ainda não temos essa informação';

  @override
  String passportTrajectoryGamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogos',
      one: '1 jogo',
    );
    return '$_temp0';
  }

  @override
  String get passportTrajectoryListEmpty => 'Nenhum jogo por aqui ainda';

  @override
  String get passportTrajectoryShareAction => 'Compartilhar';

  @override
  String passportTrajectoryOfUser(String name) {
    return 'Trajetória de $name';
  }

  @override
  String get passportTrajectoryMemorableEmptyReadOnly =>
      'Ainda não escolheu um jogo memorável';

  @override
  String get passportCoverEyebrow => 'MEU PASSAPORTE';

  @override
  String get passportEmptyHeadline => 'Todo torcedor tem uma história.';

  @override
  String get passportChangeSeasonCta => 'Trocar temporada';

  @override
  String passportSeasonProgressLine(Object marked, Object total) {
    return '$marked de $total jogos registrados';
  }

  @override
  String passportSeasonTotalOnly(Object total) {
    return '$total jogos';
  }

  @override
  String get passportSealLabel => 'EU FUI';

  @override
  String get passportSealActionLabel => 'Eu fui';

  @override
  String get passportRoundSemifinal => 'Semifinal';

  @override
  String get passportRoundQuarterfinal => 'Quartas de final';

  @override
  String get passportRoundFinal => 'Final';

  @override
  String get passportRoundPlayoff => 'Repescagem';

  @override
  String get passportRoundOf16 => 'Oitavas de final';

  @override
  String passportRoundPhase(int n) {
    return '$nª fase';
  }

  @override
  String passportRoundMatchday(int n) {
    return 'Rodada $n';
  }

  @override
  String passportRoundGroup(String letter) {
    return 'Grupo $letter';
  }

  @override
  String get arenaRankingDetailFirstTry => 'Acertos de primeira';

  @override
  String get arenaRankingDetailReview => 'Acertos na revisão';

  @override
  String get arenaRankingDetailAbandoned => 'Revelados/desistências';

  @override
  String get arenaRankingYouTag => 'VOCÊ';

  @override
  String arenaRankingPlace(int rank) {
    return '$rankº lugar';
  }

  @override
  String get arenaRankingPointsFull => 'pontos';

  @override
  String get arenaRankingPeriodOverall => 'Ranking Geral';

  @override
  String get arenaRankingPeriodWeek => 'Esta semana';

  @override
  String get arenaRankingByGame => 'Pontuação por jogo';

  @override
  String get arenaRankingHowScoredSelf => 'Como você pontuou';

  @override
  String arenaRankingHowScoredOther(String name) {
    return 'Como $name pontuou';
  }

  @override
  String arenaRankingGamePointsShare(int score, int percent) {
    return '$score pts • $percent% do total';
  }

  @override
  String get arenaRankingNoPointsTitle => 'Nenhum ponto neste período';

  @override
  String get arenaRankingNoPointsOther =>
      'Este torcedor ainda não pontuou nos jogos durante o período selecionado.';

  @override
  String get arenaRankingNoPointsSelf =>
      'Você ainda não pontuou nos jogos durante o período selecionado.';

  @override
  String arenaRankingGapToNext(int points, int rank) {
    return '$points pts para alcançar o $rankº';
  }

  @override
  String get commonClose => 'FECHAR';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonComingSoon => 'Em breve';

  @override
  String get commonComingSoonMessage => 'Essa área ainda está sendo preparada.';

  @override
  String get featureUnavailableTitle => 'Indisponível';

  @override
  String get featureUnavailableMessage => 'Essa área não está disponível.';

  @override
  String get commonLinkOpenError => 'Não foi possível abrir este link.';

  @override
  String get commonLoadError => 'Não foi possível carregar os dados';

  @override
  String get commonSelectPlaceholder => 'Selecionar';

  @override
  String get commonNoDataFound => 'Nenhum dado encontrado.';

  @override
  String get membershipCheckInAction => 'FAZER CHECK-IN';

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
  String get tacticalIdentityGameTitle => 'Identidade Futebolística';

  @override
  String get tacticalIdentityCardSubtitleNew =>
      'Que tipo de futebol você acredita?';

  @override
  String get tacticalIdentityCardCtaStart => 'Descobrir meu perfil';

  @override
  String get tacticalIdentityCardCtaViewResult => 'Ver resultado';

  @override
  String get tacticalIdentityCardCtaRedo => 'Refazer';

  @override
  String tacticalIdentityYourProfile(String name) {
    return 'Seu perfil: $name';
  }

  @override
  String get tacticalIntroTitle => 'Qual é a sua identidade futebolística?';

  @override
  String get tacticalIntroDescription =>
      '10 decisões. Nenhuma resposta certa. Descubra como você enxerga o jogo e com quais técnicos que passaram pelo Goiás sua filosofia mais se aproxima.';

  @override
  String get tacticalIntroMeta => '10 perguntas • ~3 minutos';

  @override
  String get tacticalIntroNoRightWrong =>
      'Não existem respostas certas ou erradas.';

  @override
  String get tacticalIntroStart => 'Começar';

  @override
  String get tacticalQuestionContinue => 'Continuar';

  @override
  String get tacticalProcessingTitle => 'Analisando sua identidade...';

  @override
  String get tacticalResultYourProfile => 'SEU PERFIL';

  @override
  String get tacticalResultTacticalMap => 'MAPA TÁTICO';

  @override
  String get tacticalResultMainReference =>
      'SUA PRINCIPAL REFERÊNCIA ESMERALDINA';

  @override
  String get tacticalResultOtherReferences => 'OUTRAS REFERÊNCIAS';

  @override
  String tacticalIdentityAffinityLabel(String percent) {
    return '$percent% de afinidade tática';
  }

  @override
  String get tacticalResultShare => 'Compartilhar resultado';

  @override
  String get tacticalAxisPossession => 'POSSE';

  @override
  String get tacticalAxisVertical => 'VERTICAL';

  @override
  String get tacticalAxisDogmatic => 'DOGMÁTICO';

  @override
  String get tacticalAxisPragmatic => 'PRAGMÁTICO';

  @override
  String get playerIdentityGameTitle => 'Que craque esmeraldino é você?';

  @override
  String get playerIdentityCardSubtitleNew =>
      '10 situações de jogo. Descubra com qual ídolo do Verdão seu estilo mais combina.';

  @override
  String get playerIdentityCardCtaStart => 'Descobrir meu perfil';

  @override
  String get playerIdentityCardCtaViewResult => 'Ver resultado';

  @override
  String get playerIdentityCardCtaRedo => 'Refazer';

  @override
  String playerIdentityYourProfile(String name) {
    return 'Seu perfil: $name';
  }

  @override
  String get playerIntroTitle => 'Que craque esmeraldino é você?';

  @override
  String get playerIntroDescription =>
      'Cada jogador enxerga a partida de um jeito. Responda 10 situações de jogo e descubra qual nome que marcou a história do Goiás mais combina com suas escolhas.';

  @override
  String get playerIntroMeta => '10 perguntas • ~3 minutos';

  @override
  String get playerIntroNoRightWrong => 'Não existem respostas certas.';

  @override
  String get playerIntroStart => 'Começar teste';

  @override
  String get playerProcessingTitle => 'Calculando seu estilo...';

  @override
  String get playerResultYourProfile => 'SEU PERFIL';

  @override
  String get playerResultReferencesTitle => 'REFERÊNCIAS ESMERALDINAS';

  @override
  String get playerResultTraitsTitle => 'SUAS MARCAS';

  @override
  String playerIdentityAffinityLabel(String percent) {
    return '$percent% afinidade de estilo';
  }

  @override
  String get playerResultShare => 'Compartilhar resultado';

  @override
  String get playerReferenceDisclaimer =>
      'Os atributos são referências editoriais utilizadas nesta experiência e não avaliações oficiais do jogador.';

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
  String get careerAggregateTitle => 'Totais agregados';

  @override
  String careerAggregateLine(
    String club,
    String spells,
    String apps,
    String goals,
  ) {
    return '$club ($spells): $apps jogos · $goals gols';
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
  String get socialPlatformInstagram => 'INSTAGRAM';

  @override
  String get socialPlatformYoutube => 'YOUTUBE';

  @override
  String get socialPlatformX => 'X';

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
  String get newsPdfLoadErrorTitle => 'Não foi possível carregar o PDF';

  @override
  String get newsPdfShareButton => 'Compartilhar PDF';

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
  String partnersTitle(String clubName) {
    return 'Parceiros do $clubName';
  }

  @override
  String partnersSubtitle(String clubName) {
    return 'Marcas que caminham junto com o $clubName.';
  }

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
  String get squadClubHistory => 'Carreira';

  @override
  String get squadAboutSection => 'Sobre';

  @override
  String squadCareerStatsLine(String matches, String goals) {
    return '$matches jogos · $goals gols';
  }

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
  String get squadInstagramLabel => 'Instagram';

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
  String get validatorPhoneRequired => 'Informe seu telefone.';

  @override
  String get validatorZipRequired => 'Informe o CEP.';

  @override
  String get checkEmailResent =>
      'E-mail reenviado. Confira sua caixa de entrada.';

  @override
  String get checkEmailTitle => 'Confirme seu e-mail';

  @override
  String get checkEmailResending => 'Reenviando...';

  @override
  String checkEmailResendIn(int seconds) {
    return 'Reenviar em ${seconds}s';
  }

  @override
  String get checkEmailResend => 'Reenviar código';

  @override
  String get checkEmailOtpSentTo => 'Enviamos um código de 6 dígitos para';

  @override
  String get checkEmailConfirmButton => 'CONFIRMAR CÓDIGO';

  @override
  String get checkEmailDidNotReceive => 'Não recebeu o código?';

  @override
  String get checkEmailChangeEmail => 'E-mail incorreto? Alterar e-mail';

  @override
  String get checkEmailChangeTitle => 'Alterar e-mail?';

  @override
  String get checkEmailChangeMessage =>
      'Isso encerra este cadastro e abre um novo, pra você digitar o e-mail correto.';

  @override
  String get checkEmailChangeConfirm => 'Alterar e-mail';

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
  String get forgotVerifyEmailTitle => 'Confira seu e-mail';

  @override
  String get forgotSentDescription =>
      'Se este e-mail tiver uma conta no aplicativo do Goiás, você vai receber um link de redefinição em instantes:';

  @override
  String get forgotNotReceived => 'Não recebeu?';

  @override
  String get forgotResendSuccess => 'Se a conta existir, reenviamos o e-mail.';

  @override
  String get commonGotIt => 'Entendi';

  @override
  String get forgotTitle => 'Recuperar senha';

  @override
  String get forgotSubtitle =>
      'Digite seu e-mail para receber o link de redefinição.';

  @override
  String get forgotSendButton => 'Enviar link';

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
  String get ticketStatusExpired => 'Expirado';

  @override
  String get ticketStatusRefunded => 'Reembolsado';

  @override
  String get orderStatusConfirmed => 'Confirmado';

  @override
  String get orderStatusPending => 'Pendente';

  @override
  String get orderStatusCancelled => 'Cancelado';

  @override
  String get orderStatusRefunded => 'Reembolsado';

  @override
  String get ticketsCheckinUnavailableLabel => 'CHECK-IN AINDA NÃO DISPONÍVEL';

  @override
  String get ticketsCheckinUnavailableButton => 'Check-in em breve';

  @override
  String ticketsCheckinAvailableFrom(String date, String time) {
    return 'Disponível a partir de $date às $time';
  }

  @override
  String get ticketsCheckinAvailableLabel =>
      'SEU PLANO PERMITE ACESSO A ESTA PARTIDA';

  @override
  String get ticketsCheckInButton => 'Fazer check-in';

  @override
  String get ticketsDeclinedLabel => 'VOCÊ MARCOU QUE NÃO VAI DESTA VEZ';

  @override
  String get ticketsChangedMindButton => 'Mudei de ideia';

  @override
  String get ticketsCheckinClosedLabel =>
      'CHECK-IN ENCERRADO PARA ESTA PARTIDA';

  @override
  String get ticketsCheckinClosedButton => 'Check-in encerrado';

  @override
  String get ticketsViewTicketButton => 'Visualizar ingresso';

  @override
  String get ticketsSaleUpcomingLabel => 'VENDA AINDA NÃO ABERTA';

  @override
  String get ticketsSaleUpcomingButton => 'Venda em breve';

  @override
  String ticketsSaleStartsAt(String date, String time) {
    return 'Início da venda: $date às $time';
  }

  @override
  String get ticketsSaleOpenLabel => 'INGRESSOS DISPONÍVEIS';

  @override
  String get ticketsBuyTicketButton => 'Comprar ingresso';

  @override
  String get ticketsSoldOutLabel => 'INGRESSOS ESGOTADOS';

  @override
  String get ticketsSoldOutButton => 'Esgotado';

  @override
  String get ticketsSaleClosedLabel => 'VENDA ENCERRADA PARA ESTA PARTIDA';

  @override
  String get ticketsSaleClosedButton => 'Venda encerrada';

  @override
  String get ticketsCheckinConfirmedLabel => 'CHECK-IN CONFIRMADO';

  @override
  String get ticketsUndoCheckInButton => 'Desfazer check-in';

  @override
  String get ticketsConfirmPresenceTitle => 'CONFIRMAR PRESENÇA';

  @override
  String get ticketsGoToMatchButton => 'Vou ao jogo';

  @override
  String get ticketsNotThisTimeButton => 'Não dessa vez';

  @override
  String get ticketsDeclineConfirmTitle => 'Tem certeza que não vai?';

  @override
  String get ticketsDeclineConfirmMessage =>
      'A Serrinha fica diferente com você lá. O Goiás conta com o apoio da Nação Esmeraldina! 💚\n\nVocê ainda poderá mudar de ideia enquanto o check-in estiver aberto.';

  @override
  String get ticketsWantToGoButton => 'Quero ir ao jogo';

  @override
  String get ticketsConfirmDeclineButton => 'Confirmar que não vou';

  @override
  String get ticketsCheckinSuccessTitle => 'Check-in realizado!';

  @override
  String get ticketsCheckinSuccessMessage =>
      'O ingresso também está disponível no menu Meus Ingressos.';

  @override
  String get ticketsCloseButton => 'Fechar';

  @override
  String get ticketsSaveTicketButton => 'Salvar ingresso';

  @override
  String get ticketsSectorPickerTitle => 'Onde você quer apoiar o Verdão?';

  @override
  String get ticketsSectorPickerSubtitle =>
      'Escolha o setor para esta partida.';

  @override
  String get ticketsConfirmCheckInButton => 'Confirmar check-in';

  @override
  String get ticketsViewTicketTitle => 'MEU INGRESSO';

  @override
  String get ticketsMatchInfoTitle => 'INFORMAÇÕES DA PARTIDA';

  @override
  String get ticketsHomeCrowdLabel => 'TORCIDA DO GOIÁS';

  @override
  String get ticketsAwayCrowdLabel => 'TORCIDA VISITANTE';

  @override
  String get ticketsContinueButton => 'Continuar';

  @override
  String ticketsTicketCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingressos',
      one: '1 ingresso',
    );
    return '$_temp0';
  }

  @override
  String get ticketsSummaryTitle => 'RESUMO DA COMPRA';

  @override
  String get ticketsTotalLabel => 'Total';

  @override
  String ticketsHolderDataTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DADOS DOS TITULARES',
      one: 'DADOS DO TITULAR',
    );
    return '$_temp0';
  }

  @override
  String ticketsHolderSlotLabel(int index, String sector, String category) {
    return 'Ingresso $index · $sector · $category';
  }

  @override
  String get ticketsHolderIsSelfCheckbox => 'Este ingresso é para mim';

  @override
  String get ticketsDocumentLabel => 'CPF ou passaporte';

  @override
  String get ticketsNominalWarning =>
      'O ingresso é nominal e intransferível. Confira os dados antes de continuar.';

  @override
  String get ticketsFinalizePurchaseButton => 'Finalizar compra';

  @override
  String get ticketsPurchaseSuccessTitle => 'Ingresso comprado!';

  @override
  String get ticketsPurchaseSuccessMessage =>
      'O ingresso também está disponível no menu Meus Ingressos.';

  @override
  String get ticketsTabUpcoming => 'Próximos';

  @override
  String get ticketsTabHistory => 'Histórico';

  @override
  String get ticketsUndoCheckInConfirmTitle => 'Desfazer check-in?';

  @override
  String get ticketsUndoCheckInConfirmMessage =>
      'Seu acesso para esta partida será cancelado e sua vaga poderá ser disponibilizada novamente.\n\nVocê poderá realizar um novo check-in enquanto o período permanecer aberto.';

  @override
  String get ticketsKeepCheckInButton => 'Manter check-in';

  @override
  String get ticketsOriginCheckIn => 'Check-in Sócio';

  @override
  String get ticketsOriginPurchase => 'Compra';

  @override
  String get ticketsViewRelatedTicket => 'Ver ingresso';

  @override
  String get ticketsLoadUserDataError =>
      'Não foi possível carregar seus dados. Tente novamente.';

  @override
  String get ticketsRequestRefundButton => 'Solicitar reembolso';

  @override
  String get ticketsRefundConfirmTitle => 'Solicitar reembolso';

  @override
  String get ticketsRefundConfirmMessage =>
      'Tem certeza de que deseja solicitar o reembolso deste ingresso?\n\nApós a confirmação, este ingresso deixará de ser válido.';

  @override
  String get ticketsRefundConfirmButton => 'Confirmar reembolso';

  @override
  String get ticketsRefundCancelButton => 'Voltar';

  @override
  String get ticketsRefundErrorTitle => 'Não foi possível reembolsar';

  @override
  String get ticketsRefundErrorMessage =>
      'Não foi possível concluir o reembolso deste ingresso. Tente novamente.';

  @override
  String get ticketsViewDetailsButton => 'Ver detalhes';

  @override
  String get ticketsRefundDetailsTitle => 'Ingresso reembolsado';

  @override
  String get ticketsRefundDetailsStatusLabel => 'Status';

  @override
  String get ticketsRefundDetailsMatchLabel => 'Jogo';

  @override
  String get ticketsRefundDetailsTicketLabel => 'Ingresso';

  @override
  String get ticketsRefundDetailsRequestedAtLabel => 'Data da solicitação';

  @override
  String get ticketsDemoDisclaimerBody =>
      'Esta compra é simulada. Nenhuma cobrança será realizada e o ingresso gerado não é válido para entrada no estádio.';

  @override
  String get ticketsDemoTag => 'Ingresso demonstrativo';

  @override
  String get ticketsRefundDemoNotice =>
      'Esta simulação não envolve nenhum valor real — nada será estornado.';

  @override
  String get ticketsRefundDemoConcludedNote =>
      'Reembolso demonstrativo — nenhum valor foi movimentado.';

  @override
  String get ticketPdfDemoWatermark => 'DEMONSTRAÇÃO\nNÃO VÁLIDO PARA ENTRADA';

  @override
  String get ticketPdfDemoQrCaption => 'QR demonstrativo';

  @override
  String get ticketPdfFieldVenue => 'Local';

  @override
  String get ticketPdfFieldGate => 'Portão';

  @override
  String get ticketPdfFieldCategory => 'Categoria';

  @override
  String get ticketPdfFieldDocument => 'CPF/Passaporte';

  @override
  String get ticketPdfFieldOrigin => 'Origem';

  @override
  String get ticketPdfFieldAmount => 'Valor';

  @override
  String get ticketPdfFieldCode => 'Código';

  @override
  String get ticketPdfAntiScalpingTitle => 'NÃO COMPRE\nDE CAMBISTAS!';

  @override
  String get ticketPdfAntiScalpingSubtitle => 'O ingresso pode ser falso.';

  @override
  String get ticketPdfFooterNotice =>
      'Ingresso pessoal e intransferível. Obrigatória a apresentação de documento com foto na entrada. Permitida somente camisa do Goiás ou da Seleção Brasileira.';

  @override
  String get ticketPdfInvalidTicket => 'INGRESSO\nINVÁLIDO';

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
  String get playerPositionGolFull => 'Goleiro';

  @override
  String get playerPositionGolShort => 'GOL';

  @override
  String get playerPositionZagFull => 'Zagueiro';

  @override
  String get playerPositionZagShort => 'ZAG';

  @override
  String get playerPositionLdFull => 'Lateral-direito';

  @override
  String get playerPositionLdShort => 'LD';

  @override
  String get playerPositionLeFull => 'Lateral-esquerdo';

  @override
  String get playerPositionLeShort => 'LE';

  @override
  String get playerPositionAldFull => 'Ala-direito';

  @override
  String get playerPositionAldShort => 'ALD';

  @override
  String get playerPositionAleFull => 'Ala-esquerdo';

  @override
  String get playerPositionAleShort => 'ALE';

  @override
  String get playerPositionVolFull => 'Volante';

  @override
  String get playerPositionVolShort => 'VOL';

  @override
  String get playerPositionMcFull => 'Meio-campista';

  @override
  String get playerPositionMcShort => 'MC';

  @override
  String get playerPositionMeiFull => 'Meia';

  @override
  String get playerPositionMeiShort => 'MEI';

  @override
  String get playerPositionMdFull => 'Meia-direita';

  @override
  String get playerPositionMdShort => 'MD';

  @override
  String get playerPositionMeFull => 'Meia-esquerda';

  @override
  String get playerPositionMeShort => 'ME';

  @override
  String get playerPositionPdFull => 'Ponta-direita';

  @override
  String get playerPositionPdShort => 'PD';

  @override
  String get playerPositionPeFull => 'Ponta-esquerda';

  @override
  String get playerPositionPeShort => 'PE';

  @override
  String get playerPositionSaFull => 'Segundo atacante';

  @override
  String get playerPositionSaShort => 'SA';

  @override
  String get playerPositionAtaFull => 'Atacante';

  @override
  String get playerPositionAtaShort => 'ATA';

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
  String get crowdMostVotedFormation => 'formação escolhida';

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
  String get crowdAlsoCanPlaySection => 'TAMBÉM PODE ATUAR';

  @override
  String get crowdCanAlsoPlayBadge => 'Pode atuar';

  @override
  String get crowdCardDescVoted =>
      'Veja como a torcida está escalando o Goiás para o próximo jogo.';

  @override
  String get crowdCardDescNew =>
      'Escale o Goiás para o próximo jogo e veja o time mais escalado pela torcida.';

  @override
  String get clubSectionHistory => 'História';

  @override
  String get clubSectionSquad => 'Elenco';

  @override
  String get clubSectionTitles => 'Títulos';

  @override
  String get clubSectionPartners => 'Parceiros';

  @override
  String get clubSectionBoard => 'Diretoria';

  @override
  String get clubBoardSubtitle =>
      'Conselhos, presidência e diretoria do clube.';

  @override
  String get clubBoardLoadErrorTitle => 'Não foi possível carregar a diretoria';

  @override
  String get clubBoardEmptyTitle => 'Diretoria em atualização';

  @override
  String get clubBoardEmptyMessage =>
      'Volte em breve para conferir a diretoria do clube.';

  @override
  String get clubSectionTransparency => 'Transparência';

  @override
  String get clubTransparencySubtitle =>
      'Balanços, atas e demonstrativos contábeis.';

  @override
  String get clubTransparencyLoadErrorTitle =>
      'Não foi possível carregar a transparência';

  @override
  String get clubTransparencyEmptyTitle => 'Nenhum documento disponível';

  @override
  String get clubTransparencyEmptyMessage =>
      'Volte em breve para conferir os documentos.';

  @override
  String clubTransparencyDocumentCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos',
      one: '1 documento',
      zero: 'Nenhum documento',
    );
    return '$_temp0';
  }

  @override
  String get clubTransparencyShareButton => 'Compartilhar PDF';

  @override
  String get clubSectionTimeline => 'Linha do Tempo';

  @override
  String get clubSectionSongs => 'Hino & Músicas';

  @override
  String clubHistorySubtitle(String year) {
    return 'De $year até os dias de hoje.';
  }

  @override
  String get clubSquadSubtitle => 'Os jogadores que vestem a camisa.';

  @override
  String clubTitlesSubtitle(int count) {
    return '$count conquistas ao longo da história.';
  }

  @override
  String clubPartnersSubtitle(String clubName) {
    return 'Quem caminha junto com o $clubName.';
  }

  @override
  String get clubSongsSubtitle => 'Hino e músicas que embalam a torcida.';

  @override
  String get clubSectionIdols => 'Ídolos';

  @override
  String get clubIdolsSubtitle => 'Nomes que marcaram a história do clube.';

  @override
  String clubIdolsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ídolos',
      one: '1 ídolo',
    );
    return '$_temp0';
  }

  @override
  String get clubAnthemSection => 'HINO';

  @override
  String get clubSongsSection => 'MÚSICAS ESMERALDINAS';

  @override
  String get clubLyricsLabel => 'LETRA';

  @override
  String get clubLyricsUnavailable => 'Letra ainda não disponível.';

  @override
  String get clubAudioUnavailable => 'Áudio indisponível no momento.';

  @override
  String get clubPlaybackError => 'Não foi possível reproduzir esta música.';

  @override
  String get clubMuteSemantics => 'Silenciar';

  @override
  String get clubUnmuteSemantics => 'Ativar som';

  @override
  String get clubVolumeSemantics => 'Controle de volume';

  @override
  String clubPlaySongSemantics(String title) {
    return 'Reproduzir $title';
  }

  @override
  String clubPauseSongSemantics(String title) {
    return 'Pausar $title';
  }

  @override
  String get clubMainTitles => 'TÍTULOS PRINCIPAIS';

  @override
  String get clubHistoricCampaigns => 'CAMPANHAS HISTÓRICAS';

  @override
  String clubTimesChampion(int count) {
    return '$count× CAMPEÃO';
  }

  @override
  String get clubEntryTitle => 'O CLUBE';

  @override
  String clubEntrySubtitle(String clubName) {
    return 'História, títulos, elenco e identidade do $clubName.';
  }

  @override
  String clubEntryCta(String clubName) {
    return 'CONHECER O $clubName';
  }

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
  String get membershipNoStadiumAccess => 'Sem acesso ao estádio';

  @override
  String get membershipViewPlan => 'CONHECER PLANO';

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
  String membershipDemoDisclaimerBody(String programName) {
    return 'Esta adesão é simulada e não cria vínculo com o $programName. Nenhuma cobrança será realizada.';
  }

  @override
  String membershipRegulationDemoNote(String programName) {
    return 'A visualização/aceite nesta demonstração não constitui adesão oficial ao $programName.';
  }

  @override
  String get membershipStatusDemoBadge => 'Modo Sócio — Demonstração';

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
  String get membershipMatchAccessNotice =>
      'Seu plano permite acesso a esta partida.';

  @override
  String membershipCardNumber(String number) {
    return 'Nº $number';
  }

  @override
  String get membershipRegulationPageTitle => 'REGULAMENTO';

  @override
  String get membershipProgramName => 'Sócio Esmeralda';

  @override
  String membershipRegulationEffectiveSince(String date) {
    return 'Em vigor desde $date';
  }

  @override
  String get membershipRegulationTableOfContents => 'CONTEÚDO';

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
  String get membershipFaqChipGeneral => 'Gerais';

  @override
  String get membershipFaqChipPayment => 'Pagamento';

  @override
  String get membershipFaqChipSupport => 'Atendimento';

  @override
  String get membershipFaqChipActions => 'Ações';

  @override
  String get membershipFaqChipStadium => 'Estádio';

  @override
  String get membershipFaqChipBenefits => 'Benefícios';

  @override
  String get membershipFaqChipPlans => 'Planos';

  @override
  String get membershipFaqChipFacial => 'Facial';

  @override
  String get membershipFaqChipRating => 'Rating';

  @override
  String get membershipFaqChipNoShow => 'No-Show';

  @override
  String get membershipStepAccess => 'Acesso';

  @override
  String get membershipStepPersonal => 'Cadastro';

  @override
  String get membershipStepAddress => 'Endereço';

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
  String lineupShareStats(int solved, int total, int attempts, String time) {
    return '$solved/$total descobertos · $attempts tentativas · $time';
  }

  @override
  String get crowdShareCrowd => 'Confira a escalação da torcida pro Goiás! 💚';

  @override
  String get crowdShareMine => 'Essa é a minha escalação pro Goiás! 💚';

  @override
  String get crowdSubmitted => 'Escalação enviada!';

  @override
  String get storeHomeEntryBadge => 'GOIÁS STORE';

  @override
  String get storeHomeEntryTitle => 'O manto te espera';

  @override
  String get storeHomeEntryDescription =>
      'Leve o Verdão com você dentro e fora de campo.';

  @override
  String get storeHomeEntryCta => 'Conhecer a loja';

  @override
  String get storeProfileEntry => 'Goiás Store';

  @override
  String get storeProfileMyOrders => 'Meus pedidos';

  @override
  String get storeHomeTitle => 'Goiás Store';

  @override
  String get storeHomeLoadErrorTitle => 'Não foi possível carregar a loja';

  @override
  String get storeHomeEmptyTitle => 'Loja em preparação';

  @override
  String get storeHomeEmptyMessage =>
      'Volte em breve para conferir os produtos oficiais.';

  @override
  String get storeMyPurchasesTitle => 'Minhas Compras';

  @override
  String get storeSectionCategories => 'Categorias';

  @override
  String get storeSearchHint => 'Buscar na Goiás Store';

  @override
  String get storeListingDefaultTitle => 'Produtos';

  @override
  String get storeSearchEmptyTitle => 'Busque por produtos';

  @override
  String get storeSearchEmptyMessage =>
      'Nome, categoria, coleção ou tipo de peça.';

  @override
  String get storeListingNoResultsTitle => 'Nenhum produto encontrado';

  @override
  String get storeListingNoResultsMessage =>
      'Tente ajustar sua busca ou remover alguns filtros.';

  @override
  String storeListingProductCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produtos',
      one: '1 produto',
    );
    return '$_temp0';
  }

  @override
  String storeItemCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String storeOrdersMoreItems(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count itens',
      one: '+ 1 item',
    );
    return '$_temp0';
  }

  @override
  String get storeSortLabel => 'Ordenar';

  @override
  String get storeFiltersLabel => 'Filtros';

  @override
  String storeFiltersLabelCount(Object count) {
    return 'Filtros ($count)';
  }

  @override
  String get storeSortSheetTitle => 'Ordenar por';

  @override
  String get storeFiltersSheetTitle => 'Filtros';

  @override
  String get storeClearFilters => 'Limpar filtros';

  @override
  String get storeFilterAudienceLabel => 'Público';

  @override
  String get storeFilterTypeLabel => 'Tipo';

  @override
  String get storeFilterUniformLabel => 'Uniforme';

  @override
  String get storeUniform01 => 'Uniforme 01';

  @override
  String get storeUniform02 => 'Uniforme 02';

  @override
  String get storeUniform03 => 'Uniforme 03';

  @override
  String get storeFilterSizeLabel => 'Tamanho';

  @override
  String get storeFilterOnlyAvailable => 'Somente disponíveis';

  @override
  String get storeFilterOnlyOnSale => 'Somente promoções';

  @override
  String get storeApplyFilters => 'Aplicar filtros';

  @override
  String get storeSortRelevance => 'Relevância';

  @override
  String get storeSortNewest => 'Lançamentos';

  @override
  String get storeSortPriceLowToHigh => 'Menor preço';

  @override
  String get storeSortPriceHighToLow => 'Maior preço';

  @override
  String get storeSortBiggestDiscount => 'Maior desconto';

  @override
  String get storeAudienceMasculine => 'Masculino';

  @override
  String get storeAudienceFeminine => 'Feminino';

  @override
  String get storeAudienceKids => 'Infantil';

  @override
  String get storeAudienceUnisex => 'Unissex';

  @override
  String get storeTypeMatchJersey => 'Jogo';

  @override
  String get storeTypeGoalkeeper => 'Goleiro';

  @override
  String get storeTypeTraining => 'Treino';

  @override
  String get storeTypeCasual => 'Casual';

  @override
  String get storeTypeAccessory => 'Acessório';

  @override
  String get storeTypeSouvenir => 'Souvenir';

  @override
  String get storeCategoryLaunches => 'Lançamentos';

  @override
  String get storeCategoryUniforms => 'Uniformes';

  @override
  String get storeCategoryAccessories => 'Acessórios';

  @override
  String get storeCategorySouvenirs => 'Souvenires';

  @override
  String get storeCategoryPersonalizable => 'Personalizáveis';

  @override
  String get storeCollectionFan => 'Torcedor';

  @override
  String get storeCollectionPlayer => 'Jogador';

  @override
  String get storeCollectionTrainingTravel => 'Treino, viagem e concentração';

  @override
  String get storeCollectionSocksGloves => 'Meias e luvas';

  @override
  String get storeShippingEconomyLabel => 'Econômica';

  @override
  String get storeShippingStandardLabel => 'Padrão';

  @override
  String get storeShippingExpressLabel => 'Expressa';

  @override
  String get storeShippingEconomyEta => '7 a 10 dias úteis';

  @override
  String get storeShippingStandardEta => '4 a 7 dias úteis';

  @override
  String get storeShippingExpressEta => '2 a 3 dias úteis';

  @override
  String get storeBadgeSoldOut => 'Esgotado';

  @override
  String get storeBadgeOnSale => 'Promoção';

  @override
  String storeInstallmentsLabel(Object count, Object value) {
    return 'em até ${count}x de $value';
  }

  @override
  String get storeProductLoadErrorTitle =>
      'Não foi possível carregar este produto';

  @override
  String get storeProductLoadErrorMessage => 'Volte e tente novamente.';

  @override
  String get storeOrderCreateErrorTitle =>
      'Não foi possível confirmar seu pedido';

  @override
  String get storeOrderCreateErrorMessage =>
      'Verifique sua conexão e tente novamente. Sua sacola continua salva.';

  @override
  String get storeBackToStoreButton => 'Voltar para a loja';

  @override
  String get storeProductSoldOut => 'Este produto está esgotado no momento.';

  @override
  String storeProductPhotoLabel(String name, int index, int total) {
    return '$name, foto $index de $total';
  }

  @override
  String get storeZoomImageHint => 'Toque para ampliar';

  @override
  String get storeShareProduct => 'Compartilhar produto';

  @override
  String get storeReferenceLabel => 'Ref.';

  @override
  String get storeDeliveryOrPickupLabel => 'Entrega ou retirada';

  @override
  String get storePickupFreeNote => 'Retirada grátis';

  @override
  String get storeSizeLabel => 'Tamanho';

  @override
  String get storeQuantityLabel => 'Quantidade';

  @override
  String get storeDetailsLabel => 'Detalhes';

  @override
  String get storePersonalizationLabel => 'Personalização (opcional)';

  @override
  String storePersonalizationNameField(Object price) {
    return 'Nome na camisa (+ $price)';
  }

  @override
  String storePersonalizationNumberField(Object price) {
    return 'Número na camisa (+ $price)';
  }

  @override
  String storePersonalizationSurchargeNote(Object price) {
    return 'Acréscimo de personalização: $price';
  }

  @override
  String get storeAddedToCartSnackbar => 'Produto adicionado à sacola.';

  @override
  String get storeAddToCartButton => 'Adicionar na sacola';

  @override
  String get storeSeeCartAction => 'Ver sacola';

  @override
  String get storeChooseSizeMessage =>
      'Selecione um tamanho antes de adicionar à sacola.';

  @override
  String get storeBuyNowButton => 'Comprar agora';

  @override
  String get storeVariationSoldOut => 'Essa variação está esgotada.';

  @override
  String get storeCartTitle => 'SACOLA';

  @override
  String get storeCartEmptyTitle => 'Sua sacola está vazia';

  @override
  String get storeCartEmptyMessage =>
      'Escolha seus produtos oficiais e carregue o Verdão com você.';

  @override
  String get storeCartEmptyCta => 'Ir para a Goiás Store';

  @override
  String storeCartItemSize(Object size) {
    return 'Tamanho $size';
  }

  @override
  String storeCartItemNumber(Object number) {
    return 'nº $number';
  }

  @override
  String get storeRemoveItemTitle => 'Remover item';

  @override
  String storeRemoveItemMessage(Object productName) {
    return 'Remover \"$productName\" da sacola?';
  }

  @override
  String storeRemoveItemAction(Object productName) {
    return 'Remover $productName da sacola';
  }

  @override
  String get storeRemove => 'Remover';

  @override
  String get storeCouponHint => 'Cupom de desconto';

  @override
  String get storeCouponApply => 'Aplicar';

  @override
  String get storeCouponInvalid => 'Cupom inválido ou expirado.';

  @override
  String get storeCheckoutCta => 'Finalizar compra';

  @override
  String get storeSubtotal => 'Subtotal';

  @override
  String get storeDiscountGeneric => 'Desconto';

  @override
  String storeDiscountLabel(Object code) {
    return 'Desconto ($code)';
  }

  @override
  String get storeTotal => 'Total';

  @override
  String storeFreeShippingNote(Object amount) {
    return 'Frete grátis a partir de $amount.';
  }

  @override
  String get storeFree => 'Grátis';

  @override
  String get storeShippingLabel => 'Frete';

  @override
  String get storePickupWord => 'Retirada';

  @override
  String get storeStepIdentification => 'Identificação';

  @override
  String get storeStepDelivery => 'Entrega';

  @override
  String get storeStepPayment => 'Pagamento';

  @override
  String get storeStepReview => 'Revisão';

  @override
  String get storeContinueButton => 'Continuar';

  @override
  String get storeFullNameLabel => 'Nome completo';

  @override
  String get storeCpfLabel => 'CPF';

  @override
  String get storePhoneLabel => 'Telefone / WhatsApp';

  @override
  String get storeDeliveryToHome => 'Receber em casa';

  @override
  String get storePickupAtStore => 'Retirar na loja';

  @override
  String get storeDeliveryAddressLabel => 'Endereço de entrega';

  @override
  String get storeAddAddress => 'Adicionar endereço';

  @override
  String storeZipCodePrefix(Object zip) {
    return 'CEP $zip';
  }

  @override
  String get storePickupResponsibleLabel => 'Quem vai retirar';

  @override
  String get storePickupSelf => 'Eu mesmo';

  @override
  String get storePickupOther => 'Outra pessoa';

  @override
  String get storePickupResponsibleNameField => 'Nome de quem vai retirar';

  @override
  String get storePickupResponsibleCpfField => 'CPF de quem vai retirar';

  @override
  String get storePickupSectionTitle => 'Retirada na loja';

  @override
  String get storePickupBySelf => 'Retirada pelo próprio titular';

  @override
  String storePickupByOther(Object name) {
    return 'Retirada por $name';
  }

  @override
  String storePickupAddressPrefix(Object address) {
    return 'Retirar em: $address';
  }

  @override
  String get storePaymentPix => 'Pix';

  @override
  String get storeCreditCard => 'Cartão de crédito';

  @override
  String get storeDemoDisclaimer =>
      'Ambiente demonstrativo. Nenhuma cobrança será realizada.';

  @override
  String get storeQrCodeNote =>
      'QR Code simulado — escaneie no app do seu banco.';

  @override
  String get storeSimulatePixButton => 'Simular pagamento Pix';

  @override
  String get storePixApproved => 'Pix simulado com sucesso.';

  @override
  String get storeCardNumberLabel => 'Número do cartão';

  @override
  String get storeCardHolderLabel => 'Nome impresso no cartão';

  @override
  String get storeCardExpiryLabel => 'Validade (MM/AA)';

  @override
  String get storeCardCvvLabel => 'CVV';

  @override
  String get storeInstallmentsFieldLabel => 'Parcelas';

  @override
  String storeInstallmentsCash(Object price) {
    return 'À vista — $price';
  }

  @override
  String storeInstallmentsNoInterest(Object count, Object price) {
    return '${count}x de $price sem juros';
  }

  @override
  String get storeSimulatePaymentButton => 'Simular pagamento';

  @override
  String get storeCardApprovedGeneric => 'Cartão aprovado (simulado).';

  @override
  String storeCardApprovedWithDigits(Object digits) {
    return 'Cartão final $digits aprovado (simulado).';
  }

  @override
  String storeCardFinalDigits(Object digits) {
    return 'Cartão de crédito final $digits';
  }

  @override
  String storeCardSummaryLine(Object digits, Object installments) {
    return 'Cartão de crédito final $digits · ${installments}x';
  }

  @override
  String get storeConfirmOrderButton => 'Confirmar pedido';

  @override
  String get storeEdit => 'Editar';

  @override
  String get storeAcceptTerms =>
      'Li e aceito os termos de compra da Goiás Store.';

  @override
  String get storeOrderConfirmedTitle => 'Pedido confirmado!';

  @override
  String get storeItemsLabel => 'Itens';

  @override
  String storeItemsCountLabel(Object count) {
    return 'Itens ($count)';
  }

  @override
  String get storeTrackOrderButton => 'Acompanhar pedido';

  @override
  String get storeContinueShoppingButton => 'Continuar comprando';

  @override
  String get storeBackHomeButton => 'Voltar ao início';

  @override
  String get storeOrdersTitle => 'MEUS PEDIDOS';

  @override
  String get storeOrdersEmptyTitle => 'Você ainda não fez nenhum pedido';

  @override
  String get storeOrdersEmptyMessage =>
      'Seus pedidos na Goiás Store aparecerão aqui.';

  @override
  String get storeOrdersLoadError => 'Não foi possível carregar seus pedidos';

  @override
  String get storeOrderCancelled => 'Pedido cancelado';

  @override
  String get storeCustomerLabel => 'Cliente';

  @override
  String get storeStatusStepDone => 'concluído';

  @override
  String get storeStatusStepPending => 'pendente';

  @override
  String get storeStatusCreated => 'Pedido realizado';

  @override
  String get storeStatusPaymentPending => 'Aguardando pagamento';

  @override
  String get storeStatusPaid => 'Pagamento aprovado';

  @override
  String get storeStatusPreparing => 'Em preparação';

  @override
  String get storeStatusReadyForPickup => 'Pronto para retirada';

  @override
  String get storeStatusShipped => 'Enviado';

  @override
  String get storeStatusDeliveredPickup => 'Retirado';

  @override
  String get storeStatusDeliveredShipping => 'Entregue';

  @override
  String get storeStatusCancelled => 'Cancelado';

  @override
  String get storeAddressesTitle => 'ENDEREÇOS DE ENTREGA';

  @override
  String get storeAddressesSubtitle =>
      'Escolha onde deseja receber seus pedidos.';

  @override
  String get storeAddressesEmptyTitle => 'Nenhum endereço salvo';

  @override
  String get storeAddressesEmptyMessage =>
      'Adicione um endereço pra agilizar suas próximas compras.';

  @override
  String get storeRemoveAddressTitle => 'Remover endereço';

  @override
  String storeRemoveAddressMessage(Object address) {
    return 'Remover \"$address\"?';
  }

  @override
  String get storeDefaultBadge => 'PADRÃO';

  @override
  String get storeMakeDefault => 'Tornar padrão';

  @override
  String get storeNewAddressTitle => 'NOVO ENDEREÇO';

  @override
  String get storeEditAddressTitle => 'EDITAR ENDEREÇO';

  @override
  String get storeZipCodeLabel => 'CEP';

  @override
  String get storeStreetLabel => 'Rua / Avenida';

  @override
  String get storeNumberLabel => 'Número';

  @override
  String get storeComplementLabel => 'Complemento (opcional)';

  @override
  String get storeNeighborhoodLabel => 'Bairro';

  @override
  String get storeCityLabel => 'Cidade';

  @override
  String get storeStateLabel => 'Estado';

  @override
  String get storeSaveAddressButton => 'Salvar endereço';

  @override
  String get storeAddressLabelField => 'Apelido (opcional)';

  @override
  String get storeAddressLabelHint => 'Ex.: Casa, Trabalho';

  @override
  String get storeUseResidentialAddress => 'Usar meu endereço residencial';

  @override
  String get storeDeliveryAddressSummaryTitle => 'ENDEREÇO DE ENTREGA';

  @override
  String get storeChangeAddressButton => 'Alterar';

  @override
  String get storeChooseDeliveryAddressTitle => 'ESCOLHA ONDE RECEBER';

  @override
  String get storeNoDeliveryAddressTitle =>
      'Você ainda não possui endereço de entrega.';

  @override
  String get storeAddAnotherAddress => 'Adicionar outro endereço';

  @override
  String get storeValFullNameRequired => 'Informe o nome completo.';

  @override
  String get storeValFullNameIncomplete => 'Informe nome e sobrenome.';

  @override
  String get storeValPhoneInvalid => 'Telefone inválido.';

  @override
  String get storeValCpfRequired => 'Informe o CPF.';

  @override
  String get storeValCpfInvalid => 'CPF inválido.';

  @override
  String get storeValZipInvalid => 'CEP inválido.';

  @override
  String get releaseGateTitle => 'Atualização necessária';

  @override
  String get releaseGateMessage =>
      'Esta versão do app não é mais suportada. Atualize para continuar.';

  @override
  String get releaseGateUpdateButton => 'Atualizar agora';

  @override
  String tacticalQ01(String club) {
    return 'O adversário pressiona sua saída de bola e fecha os passes curtos. O que seu $club faz?';
  }

  @override
  String get tacticalQ01A =>
      'Continua saindo curto, atraindo a pressão até encontrar o homem livre.';

  @override
  String get tacticalQ01B =>
      'Tenta sair curto, mas se a pressão encaixar busca imediatamente o espaço nas costas.';

  @override
  String get tacticalQ01C =>
      'Aciona o atacante ou o corredor diretamente e prepara a equipe para ganhar a segunda bola.';

  @override
  String get tacticalQ01D =>
      'Identifica onde a pressão rival é mais vulnerável e escolhe a saída por ali, curta ou longa.';

  @override
  String get tacticalQ02 =>
      'Seu time recupera a bola no meio-campo com o adversário ainda desorganizado. Qual é a primeira ideia?';

  @override
  String get tacticalQ02A =>
      'Retém a bola, aproxima o time e organiza o ataque.';

  @override
  String get tacticalQ02B =>
      'Procura o passe para frente se houver vantagem; se não houver, mantém a posse.';

  @override
  String get tacticalQ02C =>
      'Acelera imediatamente e tenta chegar ao gol em poucos passes.';

  @override
  String get tacticalQ02D =>
      'Decide pela posição dos adversários e pela superioridade numérica daquele lance.';

  @override
  String tacticalQ03(String club) {
    return 'O $club vence por 1 a 0 fora de casa aos 75 minutos.';
  }

  @override
  String get tacticalQ03A =>
      'Não muda o comportamento. Se o plano trouxe a vantagem, continua igual.';

  @override
  String get tacticalQ03B =>
      'Passa a controlar o jogo com mais posse e faz o adversário correr atrás da bola.';

  @override
  String get tacticalQ03C =>
      'Fecha melhor os espaços e prepara transições para matar o jogo.';

  @override
  String get tacticalQ03D =>
      'Continua pressionando e buscando o segundo gol antes que o rival cresça.';

  @override
  String get tacticalQ04 =>
      'O rival estacionou duas linhas perto da própria área. Como furar o bloqueio?';

  @override
  String get tacticalQ04A => 'Circula pacientemente até surgir o espaço certo.';

  @override
  String get tacticalQ04B =>
      'Muda posicionamentos e cria superioridade entre linhas ou pelos lados.';

  @override
  String get tacticalQ04C =>
      'Aumenta velocidade, cruzamentos, profundidade e disputa de rebotes.';

  @override
  String get tacticalQ04D =>
      'Coloca mais presença na área e muda a rota do ataque conforme a defesa reage.';

  @override
  String get tacticalQ05 =>
      'Você vai enfrentar fora de casa um adversário claramente superior tecnicamente.';

  @override
  String get tacticalQ05A =>
      'Mantém sua proposta de controle e saída com bola; é assim que o time joga.';

  @override
  String get tacticalQ05B =>
      'Continua tentando ter a bola, mas ajusta pressão e posicionamento ao rival.';

  @override
  String get tacticalQ05C =>
      'Aceita ter menos posse, protege os espaços e prioriza a transição.';

  @override
  String get tacticalQ05D =>
      'Pressiona alto e procura atacar rapidamente, mesmo assumindo risco.';

  @override
  String get tacticalQ06 =>
      'Seu melhor jogador decide partidas, mas participa pouco da recomposição. O que fazer?';

  @override
  String get tacticalQ06A =>
      'O modelo vem primeiro; se não cumprir a função, pode perder a vaga.';

  @override
  String get tacticalQ06B =>
      'Muda a função dele para manter o talento sem desequilibrar o coletivo.';

  @override
  String get tacticalQ06C =>
      'Reorganiza os companheiros para compensar e preserva o craque em zonas ofensivas.';

  @override
  String get tacticalQ06D =>
      'Dá liberdade. Jogadores especiais precisam ser tratados de maneira especial.';

  @override
  String tacticalQ07(String club) {
    return 'Intervalo. O $club perde por 1 a 0, mas está jogando bem e criando chances.';
  }

  @override
  String get tacticalQ07A =>
      'Não mexe. O plano funciona e o gol será consequência.';

  @override
  String get tacticalQ07B =>
      'Faz pequenos ajustes de posicionamento sem abandonar a ideia inicial.';

  @override
  String get tacticalQ07C =>
      'Coloca mais profundidade ou outro atacante e passa a chegar mais rápido.';

  @override
  String get tacticalQ07D =>
      'Aumenta a velocidade da circulação e coloca mais jogadores entre as linhas.';

  @override
  String get tacticalQ08 =>
      'Seu time perde a bola perto da área adversária. Qual reação você espera?';

  @override
  String get tacticalQ08A =>
      'Pressão imediata para recuperar ali mesmo, independentemente do rival.';

  @override
  String get tacticalQ08B =>
      'Pressiona se houver jogadores suficientes perto; caso contrário, recompõe.';

  @override
  String get tacticalQ08C =>
      'Primeiro reorganiza o bloco e fecha o centro do campo.';

  @override
  String get tacticalQ08D =>
      'Interrompe a transição e impede que o adversário consiga acelerar.';

  @override
  String tacticalQ09(String club) {
    return 'Faltam dez minutos e o $club precisa de um gol.';
  }

  @override
  String get tacticalQ09A =>
      'Mantém a construção paciente. Desorganização não é solução.';

  @override
  String get tacticalQ09B =>
      'Coloca jogadores mais ofensivos, mas mantém a bola no chão e a estrutura.';

  @override
  String get tacticalQ09C =>
      'Ocupa o campo adversário, joga mais direto e ataca primeira e segunda bolas.';

  @override
  String get tacticalQ09D =>
      'Muda o desenho e alterna ataques curtos e diretos conforme a defesa oferecer espaço.';

  @override
  String get tacticalQ10 =>
      'Qual frase mais representa sua maneira de pensar futebol?';

  @override
  String get tacticalQ10A =>
      'Primeiro vem a nossa maneira de jogar; depois pensamos no adversário.';

  @override
  String get tacticalQ10B =>
      'Os princípios permanecem, mas esquema e estratégia podem mudar.';

  @override
  String get tacticalQ10C =>
      'Chegar ao gol rapidamente vale mais do que ter a bola por ter.';

  @override
  String get tacticalQ10D =>
      'O melhor futebol é o que potencializa nossas peças e ataca as fraquezas do rival.';
}
