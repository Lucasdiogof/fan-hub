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

  @override
  String get commonSave => 'GUARDAR';

  @override
  String get commonSaving => 'Guardando...';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonContinue => 'CONTINUAR';

  @override
  String get profileTitle => 'PERFIL';

  @override
  String get profileMyAccount => 'MI CUENTA';

  @override
  String get profilePersonalData => 'Datos personales';

  @override
  String get profileMyAddress => 'Mi dirección';

  @override
  String get profileSecurity => 'Seguridad';

  @override
  String get profileTheme => 'Tema';

  @override
  String get profileLegal => 'LEGAL';

  @override
  String get profileAccount => 'CUENTA';

  @override
  String get profileDeleteAccount => 'Eliminar cuenta';

  @override
  String get profileDeleteConfirmTitle => '¿Eliminar cuenta?';

  @override
  String get profileDeleteConfirmMessage =>
      'Al eliminar tu cuenta, tus datos y tu progreso se eliminarán de forma permanente. Esta acción no se puede deshacer.';

  @override
  String get profileSignOutTitle => '¿Cerrar sesión?';

  @override
  String get profileSignOutMessage =>
      'Tendrás que iniciar sesión de nuevo para acceder a tu cuenta.';

  @override
  String get profileSignOutConfirm => 'CERRAR SESIÓN';

  @override
  String get profileSignOut => 'Cerrar sesión';

  @override
  String get personalDataTitle => 'DATOS PERSONALES';

  @override
  String get personalDataLoadError => 'No se pudieron cargar tus datos.';

  @override
  String get personalFieldCpf => 'CPF (opcional)';

  @override
  String get personalFieldBirthDate => 'Fecha de nacimiento';

  @override
  String get personalSelectDate => 'Seleccionar fecha';

  @override
  String get personalFieldPhone => 'Celular';

  @override
  String get personalEmailLocked => 'El correo está vinculado a tu cuenta.';

  @override
  String get personalNameRequired => 'Ingresa tu nombre completo.';

  @override
  String get personalCpfInvalid => 'CPF inválido.';

  @override
  String get personalUpdateSuccess => 'Datos actualizados con éxito.';

  @override
  String get securityTitle => 'SEGURIDAD';

  @override
  String get securitySubtitle => 'Cambia la contraseña de tu cuenta Goiás EC.';

  @override
  String get securityCurrentPassword => 'Contraseña actual';

  @override
  String get securityCurrentPasswordHint => 'Confirma tu contraseña actual';

  @override
  String get securityNewPassword => 'Nueva contraseña';

  @override
  String get securityConfirmNewPassword => 'Confirmar nueva contraseña';

  @override
  String get securityConfirmNewPasswordHint => 'Repite la nueva contraseña';

  @override
  String get securitySaveButton => 'GUARDAR NUEVA CONTRASEÑA';

  @override
  String get securityChangeSuccess => 'Contraseña cambiada con éxito.';

  @override
  String get addressTitle => 'MI DIRECCIÓN';

  @override
  String get addressLoadError => 'No se pudo cargar tu dirección.';

  @override
  String get addressCepNotFound => 'Código postal no encontrado.';

  @override
  String get addressSaveSuccess => 'Dirección guardada con éxito.';

  @override
  String get addressFieldCep => 'Código postal';

  @override
  String get addressFieldStreet => 'Calle';

  @override
  String get addressFieldNumber => 'Número';

  @override
  String get addressFieldComplement => 'Complemento (opcional)';

  @override
  String get addressFieldNeighborhood => 'Barrio';

  @override
  String get addressFieldState => 'Estado';

  @override
  String get addressSelectState => 'Seleccionar estado';

  @override
  String get addressFieldCity => 'Ciudad';

  @override
  String get addressSaveButton => 'GUARDAR DIRECCIÓN';

  @override
  String get deleteAccountTitle => 'ELIMINAR CUENTA';

  @override
  String get deleteAccountConfirmWord => 'ELIMINAR';

  @override
  String deleteAccountInstruction(String word) {
    return 'Esta acción es permanente. Confirma tu contraseña y escribe $word para eliminar tu cuenta y todo tu progreso.';
  }

  @override
  String get deleteAccountPasswordHint => 'Confirma tu contraseña';

  @override
  String deleteAccountTypeWordLabel(String word) {
    return 'Escribe $word para confirmar';
  }

  @override
  String get deleteAccountConfirmButton => 'ELIMINAR MI CUENTA';

  @override
  String get deleteAccountDeleting => 'ELIMINANDO CUENTA...';

  @override
  String get settingsThemeTitle => 'TEMA';

  @override
  String get themeModeAuto => 'Automático';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get themeModeAutoDesc => 'Sigue el tema de tu teléfono';

  @override
  String get themeModeLightDesc => 'Siempre con fondo claro';

  @override
  String get themeModeDarkDesc => 'Siempre con fondo oscuro';

  @override
  String get avatarTakePhoto => 'Tomar foto';

  @override
  String get avatarChooseFromGallery => 'Elegir de la galería';

  @override
  String get socialFollowTitle => 'SIGUE AL GOIÁS';

  @override
  String get socialFollowSubtitle =>
      'Sigue al Goiás también en las redes sociales.';

  @override
  String socialOpenLink(String name) {
    return 'Abrir $name';
  }

  @override
  String get arenaSubtitle => 'Minijuegos rápidos para la afición.';

  @override
  String get arenaSectionPlayNow => 'JUEGA AHORA';

  @override
  String get arenaSectionMoreChallenges => 'MÁS DESAFÍOS';

  @override
  String get arenaPlay => 'JUGAR';

  @override
  String get arenaRankingTitle => 'Ranking de la Afición';

  @override
  String get arenaRankingBannerSubtitle =>
      'Mira a los mejores de la afición en los minijuegos.';

  @override
  String get arenaRankingEmpty => 'El ranking aún está vacío';

  @override
  String get arenaRankingEmptyMessage =>
      'Juega y sé el primero en aparecer en el ranking de la afición.';

  @override
  String get arenaAchievementTitle => 'LEYENDA ESMERALDINA';

  @override
  String get arenaAchievementMessage =>
      'Completaste el 100% de la Arena Esmeraldina — Quiz del Goiás, Adivina la Alineación y Adivina el Jugador. Este logro es permanente.';

  @override
  String get arenaAchievementConfirm => '¡GENIAL!';

  @override
  String get arenaPlayFirstTime => 'Juega por primera vez';

  @override
  String arenaStatMatchesCorrect(int played, int correct) {
    return '$played partidas · $correct aciertos';
  }

  @override
  String get arenaGameQuizTitle => 'Quiz del Goiás';

  @override
  String get arenaGameQuizTagline => 'Pon a prueba cuánto conoces al Goiás.';

  @override
  String get arenaGameLineupTitle => 'Adivina la Alineación';

  @override
  String get arenaGameLineupTagline =>
      'Descubre los 11 titulares de un partido histórico del Goiás.';

  @override
  String get arenaGameCareerTitle => 'Adivina el Jugador';

  @override
  String get arenaGameCareerTagline =>
      'Descubre al jugador por su trayectoria.';

  @override
  String get arenaGuessPlayerTitle => '¿Quién Vistió la Camiseta?';

  @override
  String get arenaGuessPlayerTagline =>
      'Descubre al jugador secreto por la foto borrosa y las pistas.';

  @override
  String get arenaSubtitleQuiz => '60 preguntas';

  @override
  String get arenaSubtitleLineup => '31 alineaciones';

  @override
  String get arenaSubtitleCareer => '23 jugadores';

  @override
  String get arenaSubtitleGuessPlayer => 'Descubre al jugador por las pistas';

  @override
  String get commonClose => 'CERRAR';

  @override
  String get quizChooseLevel => 'Elige el nivel';

  @override
  String get quizChooseLevelHint =>
      'Cada nivel tiene su propio banco de preguntas — cuanto más alto, más difícil.';

  @override
  String get quizDone => 'Completado';

  @override
  String get quizSeeResult => 'VER RESULTADO';

  @override
  String get quizNext => 'SIGUIENTE';

  @override
  String get quizHits => 'ACIERTOS';

  @override
  String get quizPerfect => '¡Perfecto!';

  @override
  String get quizScore => 'PUNTUACIÓN';

  @override
  String get quizNewRecord => 'Nuevo récord';

  @override
  String get quizReviewErrors => 'REVISAR ERRORES';

  @override
  String get quizPlayAgain => 'JUGAR DE NUEVO';

  @override
  String get quizReviewMore => 'REVISAR MÁS';

  @override
  String get quizBackToLevels => 'VOLVER A LOS NIVELES';

  @override
  String get quizMoreQuestions => 'MÁS PREGUNTAS';

  @override
  String get quizBackToArena => 'VOLVER A LA ARENA';

  @override
  String get quizLevelDescTorcedor =>
      'Datos básicos, títulos y campañas que todo hincha conoce.';

  @override
  String get quizLevelDescEsmeraldino =>
      'Historia, ídolos y partidos memorables para quien conoce el club.';

  @override
  String get quizLevelDescFanatico =>
      'Récords y números para quien no falla ninguna.';

  @override
  String quizLevelName(String level) {
    return 'Nivel $level';
  }

  @override
  String quizQuestionProgress(int current, int total) {
    return 'Pregunta $current de $total';
  }

  @override
  String quizAnsweredCount(int answered, int total) {
    return '$answered/$total preguntas';
  }

  @override
  String quizPendingReview(int count) {
    return '$count por revisar';
  }

  @override
  String quizLevelCompleted(String level) {
    return 'NIVEL $level COMPLETADO';
  }

  @override
  String quizAllAnswered(int total) {
    return 'Respondiste todas las $total preguntas de este nivel.';
  }

  @override
  String quizCorrectCount(int count) {
    return '$count acertadas';
  }

  @override
  String quizReviewLevel(String level) {
    return 'Revisión · Nivel $level';
  }

  @override
  String quizFinalResultLevel(String level) {
    return 'Resultado final · Nivel $level';
  }

  @override
  String quizScoreLine(int correct, int total) {
    return 'Acertaste $correct de $total preguntas';
  }

  @override
  String quizLevelQuestions(int answered, int total) {
    return '$answered/$total preguntas del nivel';
  }

  @override
  String quizBestRecord(int best) {
    return 'Récord: $best pts';
  }
}
