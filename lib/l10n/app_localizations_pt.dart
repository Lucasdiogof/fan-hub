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
}
