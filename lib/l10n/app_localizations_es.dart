// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get languageName => 'Español';

  @override
  String get settingsLanguageTitle => 'IDIOMA';

  @override
  String get settingsLanguageMenu => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Elige el idioma de la aplicación';

  @override
  String get languageSystemLabel => 'Predeterminado del sistema';

  @override
  String get languageSystemDescription => 'Sigue el idioma de tu dispositivo';

  @override
  String get commonEmailLabel => 'Correo electrónico';

  @override
  String get commonEmailHint => 'tucorreo@email.com';

  @override
  String get commonPasswordLabel => 'Contraseña';

  @override
  String get authTagline => 'Sigue todo sobre el mayor del Centro-Oeste';

  @override
  String get authRegisterSubtitle =>
      'Sigue todo sobre el mayor del Centro-Oeste.';

  @override
  String get authForgotPassword => 'Olvidé mi contraseña';

  @override
  String get authSignInButton => 'ENTRAR';

  @override
  String get authSigningIn => 'Entrando...';

  @override
  String get authNoAccountQuestion => '¿Aún no tienes una cuenta? ';

  @override
  String get authCreateAccount => 'Crear cuenta';

  @override
  String get authRegisterTitle => 'Crear cuenta';

  @override
  String get authFullNameLabel => 'Nombre completo';

  @override
  String get authFullNameHint => 'Tu nombre';

  @override
  String authPasswordMinHint(int count) {
    return 'Mínimo $count caracteres';
  }

  @override
  String get authConfirmPasswordLabel => 'Confirmar contraseña';

  @override
  String get authConfirmPasswordHint => 'Repite la contraseña';

  @override
  String get authRegisterButton => 'CREAR CUENTA';

  @override
  String get authCreatingAccount => 'Creando...';

  @override
  String get authTermsPrefix => 'He leído y acepto los ';

  @override
  String get authTermsLink => 'Términos de Uso';

  @override
  String get authTermsConnector => ' y la ';

  @override
  String get authPrivacyLink => 'Política de Privacidad';

  @override
  String get authTermsSuffix => '.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navMatches => 'Partidos';

  @override
  String get navMembership => 'Socio';

  @override
  String get navMedia => 'Medios';

  @override
  String get navArena => 'Arena';

  @override
  String get homeGreetingMorning => 'Buenos días';

  @override
  String get homeGreetingAfternoon => 'Buenas tardes';

  @override
  String get homeGreetingEvening => 'Buenas noches';

  @override
  String get homeNextMatch => 'PRÓXIMO PARTIDO';

  @override
  String get homeDateToBeConfirmed => 'FECHA POR CONFIRMAR';

  @override
  String get homeMatchDetails => 'DETALLES DEL PARTIDO';

  @override
  String get homeTickets => 'ENTRADAS';

  @override
  String get homeCountdownTitle => 'EL PARTIDO COMIENZA EN';

  @override
  String get homeCountdownDays => 'DÍAS';

  @override
  String get homeCountdownHours => 'HORAS';

  @override
  String get homeCountdownMinutes => 'MIN';

  @override
  String get homeCountdownSeconds => 'SEG';

  @override
  String get homeMembershipPitch =>
      'Acércate aún más a Goiás\n¡y sé parte de esta historia!';

  @override
  String get homeMembershipBenefit1 => 'Acceso prioritario al estadio';

  @override
  String get homeMembershipBenefit2 => 'Ahorro en el precio de la entrada';

  @override
  String get homeMembershipBenefit3 => 'Descuentos exclusivos y mucho más';

  @override
  String get homeMembershipCta => 'HAZTE SOCIO';

  @override
  String get matchGamesTitle => 'PARTIDOS';

  @override
  String get matchTabMatches => 'PARTIDOS';

  @override
  String get matchTabStandings => 'CLASIFICACIÓN';

  @override
  String get matchLoadError => 'No se pudieron cargar los partidos';

  @override
  String get matchNoMatches => 'No se encontraron partidos.';

  @override
  String get matchDetailsLoadError => 'No se pudo cargar el partido.';

  @override
  String get matchBuyTicket => 'COMPRAR ENTRADA';

  @override
  String get matchDetailsShort => 'DETALLES';

  @override
  String get matchDateToBeConfirmed => 'Fecha por confirmar';

  @override
  String get matchToBeConfirmed => 'Por confirmar';

  @override
  String get matchInfoTitle => 'INFORMACIÓN';

  @override
  String get matchFieldDate => 'Fecha';

  @override
  String get matchFieldTime => 'Hora';

  @override
  String get matchFieldStadium => 'Estadio';

  @override
  String get matchFieldCity => 'Ciudad';

  @override
  String get matchFieldCompetition => 'Competición';

  @override
  String get matchFieldRound => 'Jornada';

  @override
  String get matchFieldStatus => 'Estado';

  @override
  String get matchEventsTitle => 'EVENTOS DEL PARTIDO';

  @override
  String get matchEventGoal => 'Gol';

  @override
  String get matchEventCard => 'Tarjeta';

  @override
  String matchEventSubstitution(String playerIn, String playerOut) {
    return '$playerIn entra por $playerOut';
  }

  @override
  String get matchLineupsTitle => 'ALINEACIONES';

  @override
  String get standingsClub => 'CLUB';

  @override
  String get standingsColPoints => 'Pts';

  @override
  String get standingsColPlayed => 'PJ';

  @override
  String get standingsColWins => 'G';

  @override
  String get standingsColGoalDiff => 'DG';

  @override
  String get standingsUnavailable =>
      'Clasificación no disponible en este momento.';

  @override
  String get matchStatusScheduled => 'Programado';

  @override
  String get matchStatusLive => 'En vivo';

  @override
  String get matchStatusHalfTime => 'Descanso';

  @override
  String get matchStatusFinished => 'Finalizado';

  @override
  String get matchStatusPostponed => 'Aplazado';

  @override
  String get matchStatusCancelled => 'Cancelado';

  @override
  String get matchStatusSuspended => 'Suspendido';

  @override
  String get matchStatusUnknown => 'Indefinido';
}
