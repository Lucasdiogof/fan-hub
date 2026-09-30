// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settingsLanguageTitle => 'IDIOMA';

  @override
  String get settingsLanguageMenu => 'Idioma';

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
  String get authForgotPassword => 'Olvidé mi contraseña';

  @override
  String get authSignInButton => 'ENTRAR';

  @override
  String get authSignInErrorTitle => 'No fue posible iniciar sesión';

  @override
  String get authSigningIn => 'Iniciando sesión...';

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
  String get authRegisterButton => 'CREAR MI CUENTA';

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
  String get authStepPersonal => 'Tus datos';

  @override
  String get authStepContact => 'Contacto';

  @override
  String get authStepSecurity => 'Seguridad';

  @override
  String authMarketingOptIn(String clubShortName) {
    return 'Quiero recibir novedades, promociones e información de $clubShortName';
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
  String get navHome => 'Inicio';

  @override
  String get navMatches => 'Partidos';

  @override
  String get navMembership => 'Socio';

  @override
  String get navMedia => 'Medios';

  @override
  String get navStore => 'Tienda';

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
  String get homeCompactMatchToday => 'HOY';

  @override
  String get homeCompactMatchFinished => 'Fin del partido';

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
  String get matchGamesTitle => 'PARTIDOS';

  @override
  String get matchTabMatches => 'PARTIDOS';

  @override
  String get matchTabCalendar => 'CALENDARIO';

  @override
  String get matchTabStandings => 'CLASIFICACIÓN';

  @override
  String get matchCalendarHome => 'LOCAL';

  @override
  String get matchCalendarAway => 'FUERA';

  @override
  String get matchLoadError => 'No se pudieron cargar los partidos';

  @override
  String get matchNoMatches => 'No se encontraron partidos.';

  @override
  String get matchDetailsLoadError => 'No se pudo cargar el partido.';

  @override
  String get matchBuyTicket => 'COMPRAR ENTRADA';

  @override
  String get matchDetailsShort => 'DETALLES DEL PARTIDO';

  @override
  String get matchFollowLive => 'SEGUIR PARTIDO';

  @override
  String get matchViewDetails => 'VER DETALLES';

  @override
  String get matchFinishedLabel => 'Finalizado';

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
  String get matchStatsTitle => 'ESTADÍSTICAS';

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
  String get otherCompetitionsCta => 'Ver otros campeonatos';

  @override
  String get otherCompetitionsTitle => 'Campeonatos';

  @override
  String get otherCompetitionsSearchHint => 'Buscar campeonato';

  @override
  String get otherCompetitionsYourCompetitions => 'TUS COMPETICIONES';

  @override
  String get otherCompetitionsSearchEmpty => 'No se encontraron campeonatos.';

  @override
  String get knockoutFirstLeg => 'Ida';

  @override
  String get knockoutSecondLeg => 'Vuelta';

  @override
  String get knockoutAggregateShort => 'Marcador';

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
  String get matchCurrentRound => 'Jornada actual';

  @override
  String get commonSave => 'GUARDAR';

  @override
  String get commonSaving => 'Guardando...';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonContinue => 'CONTINUAR';

  @override
  String get commonDemoTag => 'Demostración';

  @override
  String get commonDemoBannerTitle => 'Demostración';

  @override
  String get profileTitle => 'PERFIL';

  @override
  String get profileMyAccount => 'MI CUENTA';

  @override
  String get profilePersonalData => 'Datos personales';

  @override
  String get profileMyAddress => 'Dirección residencial';

  @override
  String get profileDeliveryAddresses => 'Direcciones de entrega';

  @override
  String get profileSecurity => 'Seguridad';

  @override
  String get profileAppearance => 'Apariencia';

  @override
  String get profileNotifications => 'Notificaciones';

  @override
  String get profileMyJourney => 'MI TRAYECTORIA';

  @override
  String get profilePreferences => 'PREFERENCIAS';

  @override
  String get profilePurchasesAndServices => 'COMPRAS Y SERVICIOS';

  @override
  String get profileMyTickets => 'Mis entradas';

  @override
  String profileVersion(Object version) {
    return 'Versión $version';
  }

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
  String get authSessionExpiredTitle => 'Tu sesión expiró';

  @override
  String authSessionExpiredMessage(String club) {
    return 'Por seguridad, necesitamos confirmar tu acceso de nuevo. Inicia sesión para seguir usando todos los recursos del $club.';
  }

  @override
  String get authSessionExpiredCta => 'Iniciar sesión de nuevo';

  @override
  String get authErrorInvalidCredentials => 'Correo o contraseña incorrectos.';

  @override
  String get authErrorCurrentPasswordIncorrect =>
      'La contraseña actual es incorrecta.';

  @override
  String get authErrorPasswordIncorrect => 'Contraseña incorrecta.';

  @override
  String get authErrorEmailAlreadyRegistered =>
      'Este correo ya tiene una cuenta.';

  @override
  String get authErrorWeakPassword =>
      'La contraseña no cumple los requisitos mínimos.';

  @override
  String get authErrorInvalidEmail => 'Ingresa un correo electrónico válido.';

  @override
  String get authErrorRateLimited =>
      'Ya enviamos un código recientemente. Espera un poco antes de solicitar otro.';

  @override
  String get authErrorOtpInvalidOrExpired =>
      'Este código no es válido o ya expiró. Revísalo e intenta de nuevo, o solicita uno nuevo.';

  @override
  String get authErrorSessionExpired =>
      'Tu sesión ha expirado. Inicia sesión de nuevo.';

  @override
  String get authErrorSignupDisabled =>
      'Los nuevos registros no están disponibles por el momento.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Confirma tu correo antes de iniciar sesión.';

  @override
  String get authErrorServiceUnavailable =>
      'El servicio no está disponible en este momento. Intenta de nuevo en unos instantes.';

  @override
  String get authErrorNewPasswordSameAsCurrent =>
      'La nueva contraseña debe ser diferente de la actual.';

  @override
  String get authErrorCpfAlreadyTaken =>
      'Este CPF ya está registrado en otra cuenta.';

  @override
  String get authErrorAccountDeletionFailed =>
      'No fue posible eliminar tu cuenta. Intenta de nuevo en unos instantes.';

  @override
  String get authErrorNetwork => 'Verifica tu conexión a internet.';

  @override
  String get authErrorGeneric =>
      'No fue posible completar esto ahora. Intenta de nuevo.';

  @override
  String get personalDataTitle => 'DATOS PERSONALES';

  @override
  String get personalDataLoadError => 'No se pudieron cargar tus datos.';

  @override
  String get personalFieldCpf => 'CPF (opcional)';

  @override
  String get personalFieldBirthDate => 'Fecha de nacimiento';

  @override
  String get personalFieldPhone => 'Celular';

  @override
  String get personalEmailLocked => 'El correo está vinculado a tu cuenta.';

  @override
  String get personalNameRequired => 'Ingresa tu nombre completo.';

  @override
  String get personalCpfRequired => 'Ingresa tu CPF.';

  @override
  String get personalCpfInvalid => 'CPF inválido.';

  @override
  String get personalUpdateSuccess => 'Datos actualizados con éxito.';

  @override
  String get securityTitle => 'SEGURIDAD';

  @override
  String securitySubtitle(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'Cambia la contraseña de tu cuenta Goiás EC.',
      'other': 'Cambia la contraseña de tu cuenta $club.',
    });
    return '$_temp0';
  }

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
  String get addressTitle => 'DIRECCIÓN RESIDENCIAL';

  @override
  String get addressResidentialSubtitle =>
      'Tu dirección principal registrada en la cuenta.';

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
  String get settingsNotificationsTitle => 'NOTIFICACIONES';

  @override
  String get notificationsLiveMatchesTitle => 'Partidos en vivo';

  @override
  String notificationsLiveMatchesDescription(String club) {
    return 'Activa para recibir los avisos de abajo en tiempo real, con el marcador del $club.';
  }

  @override
  String get notificationsKickoffTitle => 'Inicio del partido';

  @override
  String get notificationsKickoffDescription =>
      'Aviso apenas comience el partido.';

  @override
  String notificationsGoalForTitle(String club) {
    return 'Goles del $club';
  }

  @override
  String notificationsGoalForDescription(String club) {
    return 'Aviso por cada gol marcado por el $club.';
  }

  @override
  String get notificationsGoalAgainstTitle => 'Goles del rival';

  @override
  String get notificationsGoalAgainstDescription =>
      'Aviso por cada gol recibido.';

  @override
  String get notificationsHalfTimeTitle => 'Entretiempo';

  @override
  String get notificationsHalfTimeDescription =>
      'Aviso en el entretiempo, con el marcador parcial.';

  @override
  String get notificationsSecondHalfTitle => 'Inicio del segundo tiempo';

  @override
  String get notificationsSecondHalfDescription =>
      'Aviso cuando comience el segundo tiempo.';

  @override
  String get notificationsFullTimeTitle => 'Fin del partido';

  @override
  String get notificationsFullTimeDescription => 'Aviso con el marcador final.';

  @override
  String get notificationsTicketsTitle => 'Entradas y check-in';

  @override
  String get notificationsTicketsDescription =>
      'Avisos cuando la venta o el check-in se habiliten.';

  @override
  String get notificationsOsBlockedMessage =>
      'Las notificaciones están desactivadas en la configuración del sistema — no recibirás nada hasta reactivarlas.';

  @override
  String get notificationsOpenSettings => 'Abrir configuración';

  @override
  String get notificationsForegroundCta => 'Ver';

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
  String socialFollowTitle(String clubCode, String club) {
    return 'SIGUE AL $club';
  }

  @override
  String socialFollowSubtitle(String clubCode, String club) {
    return 'Sigue al $club también en las redes sociales.';
  }

  @override
  String socialOpenLink(String name) {
    return 'Abrir $name';
  }

  @override
  String arenaTitle(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'Arena Esmeraldina',
      'other': 'Arena $club',
    });
    return '$_temp0';
  }

  @override
  String arenaGamesSectionSubtitle(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'Pon a prueba tu conocimiento sobre el Goiás.',
      'other': 'Pon a prueba tu conocimiento sobre el $club.',
    });
    return '$_temp0';
  }

  @override
  String get arenaNextMatchBadge => 'PRÓXIMO PARTIDO';

  @override
  String get arenaHighlightViewLineup => 'Ver alineación';

  @override
  String get arenaPlay => 'JUGAR';

  @override
  String get arenaRankingTitle => 'Ranking de la Afición';

  @override
  String get arenaRankingEmpty => 'El ranking aún está vacío';

  @override
  String get arenaRankingEmptyMessage =>
      'Juega y sé el primero en aparecer en el ranking de la afición.';

  @override
  String arenaAchievementTitle(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'LEYENDA ESMERALDINA',
      'other': 'LEYENDA DEL $club',
    });
    return '$_temp0';
  }

  @override
  String arenaAchievementMessage(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias':
          'Completaste el 100% de la Arena Esmeraldina — Quiz del Goiás, Adivina la Alineación y Adivina el Jugador. Este logro es permanente.',
      'other':
          'Completaste el 100% de la Arena $club — Quiz, Adivina la Alineación y Adivina el Jugador. Este logro es permanente.',
    });
    return '$_temp0';
  }

  @override
  String get arenaAchievementConfirm => '¡GENIAL!';

  @override
  String get arenaPlayFirstTime => 'Juega por primera vez';

  @override
  String arenaStatMatchesCorrect(int played, int correct) {
    return '$played partidas · $correct aciertos';
  }

  @override
  String arenaHeaderSubtitle(String club) {
    return 'Juega, participa y vive el $club.';
  }

  @override
  String arenaSpotlightEyebrow(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'Arena Esmeraldina',
      'other': 'Arena $club',
    });
    return '$_temp0';
  }

  @override
  String get arenaSpotlightHeadline => 'Tu pasión entra en el campo';

  @override
  String arenaSpotlightSubtitle(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'Juega, participa y gana tu lugar entre los Esmeraldinos.',
      'bragantino': 'Juega, participa y gana tu lugar entre la Massa Bruta.',
      'other': 'Juega, participa y gana tu lugar entre los hinchas del $club.',
    });
    return '$_temp0';
  }

  @override
  String get arenaSpotlightCta => 'Entrar a la Arena';

  @override
  String get arenaLineupHeroEyebrow => 'ALINEACIÓN DE LA HINCHADA';

  @override
  String get arenaLineupHeroCta => 'Armar mi alineación';

  @override
  String get arenaLineupHeroEmptyTitle => 'Sin partido por ahora';

  @override
  String get arenaLineupHeroEmptyMessage =>
      'En cuanto se confirme el próximo partido, podrás armar tu alineación aquí.';

  @override
  String get arenaChallengesSectionTitle => 'Desafíos';

  @override
  String get arenaChallengeCtaContinue => 'Continuar';

  @override
  String get arenaChallengeCtaStart => 'Empezar';

  @override
  String get arenaChallengeCtaCompleted => 'Completado';

  @override
  String arenaGameQuizTitle(String clubCode, String club) {
    return 'Quiz del $club';
  }

  @override
  String arenaGameQuizTagline(String club) {
    return 'Pon a prueba cuánto conoces al $club.';
  }

  @override
  String get arenaGameLineupTitle => 'Adivina la Alineación';

  @override
  String arenaGameLineupTagline(String club) {
    return 'Descubre los 11 titulares de un partido histórico del $club.';
  }

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
  String get arenaRankingWeekly => 'Semanal';

  @override
  String get arenaRankingMonthly => 'Mensual';

  @override
  String get arenaRankingAllTime => 'General';

  @override
  String get arenaRankingPoints => 'pts';

  @override
  String get arenaRankingYourPosition => 'TU POSICIÓN';

  @override
  String get arenaRankingMemberBadge => 'Socio';

  @override
  String get arenaRankingUnknownFan => 'Hincha';

  @override
  String get passportCardCta => 'Abrir pasaporte';

  @override
  String get passportRankingCta => 'Ranking del Pasaporte';

  @override
  String get passportLoadErrorTitle => 'No se pudo cargar el pasaporte';

  @override
  String get passportEmptyCatalogTitle =>
      'Ninguna temporada disponible todavía';

  @override
  String get passportNoMatchesForFilter =>
      'Ningún partido encontrado con ese filtro';

  @override
  String get passportSummaryTotalMatches => 'Partidos registrados';

  @override
  String get passportSummaryYearsCount => 'Años con presencia';

  @override
  String get passportSummaryFirstMatch => 'Primer partido';

  @override
  String get passportSummaryLastMatch => 'Último partido';

  @override
  String get passportFilterAll => 'Todos';

  @override
  String get passportFilterAttended => 'Marcados';

  @override
  String get passportFilterNotAttended => 'No marcados';

  @override
  String get passportFilterHome => 'Local';

  @override
  String get passportFilterAway => 'Visitante';

  @override
  String get passportFilterAllCompetitions => 'Todas las competiciones';

  @override
  String get passportStatusScheduled => 'Programado';

  @override
  String get passportStatusPostponed => 'Aplazado';

  @override
  String get passportStatusCancelled => 'Cancelado';

  @override
  String get passportOutcomeWin => 'Victoria';

  @override
  String get passportOutcomeDraw => 'Empate';

  @override
  String get passportOutcomeLoss => 'Derrota';

  @override
  String get passportSaveGenericLabel => 'Guardar cambios';

  @override
  String passportSaveCountLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Guardar $count partidos',
      one: 'Guardar 1 partido',
    );
    return '$_temp0';
  }

  @override
  String get passportSaveSuccess => 'Pasaporte actualizado.';

  @override
  String get passportDiscardChangesTitle => '¿Descartar cambios?';

  @override
  String get passportDiscardChangesMessage =>
      'Marcaste partidos que aún no se guardaron. Si sales ahora, esas marcas se pierden.';

  @override
  String get passportDiscardChangesConfirm => 'Descartar';

  @override
  String get passportRankingTitle => 'Ranking del Pasaporte';

  @override
  String get passportRankingPeriodOverall => 'General';

  @override
  String passportRankingMatchCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidos',
      one: '1 partido',
    );
    return '$_temp0';
  }

  @override
  String get passportRankingEmptyTitle => 'Todavía nadie en el ranking';

  @override
  String get passportRankingEmptyMessage =>
      'Marca tus partidos en el Pasaporte para aparecer aquí.';

  @override
  String get passportStatsTitle => 'Mi trayectoria';

  @override
  String get passportStatsWins => 'Victorias';

  @override
  String get passportStatsDraws => 'Empates';

  @override
  String get passportStatsLosses => 'Derrotas';

  @override
  String get passportStatsHomeGames => 'En casa';

  @override
  String get passportStatsAwayGames => 'Fuera de casa';

  @override
  String get passportStatsGoalsFor => 'Goles marcados';

  @override
  String get passportStatsGoalsAgainst => 'Goles recibidos';

  @override
  String get passportStatsGoalDifference => 'Diferencia de goles';

  @override
  String get passportStatsEmptyTitle => 'Tu trayectoria empieza aquí';

  @override
  String get passportStatsEmptyMessage =>
      'Marca partidos como \"Yo estuve\" para ver tus estadísticas.';

  @override
  String get passportTrajectoryGames => 'Partidos';

  @override
  String get passportTrajectoryStadiums => 'Estadios';

  @override
  String get passportTrajectorySeasons => 'Temporadas';

  @override
  String get passportTrajectoryMemorableMatch => 'Partido más memorable';

  @override
  String get passportTrajectoryMemorableEmpty =>
      'Elige tu partido más memorable';

  @override
  String get passportTrajectoryPickMatch => 'Elige tu partido más memorable';

  @override
  String get passportTrajectoryMostVisitedStadium => 'Estadio más visitado';

  @override
  String get passportTrajectoryStadiumUnavailable =>
      'Todavía no tenemos esta información';

  @override
  String passportTrajectoryGamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidos',
      one: '1 partido',
    );
    return '$_temp0';
  }

  @override
  String get passportTrajectoryListEmpty => 'Todavía no hay partidos aquí';

  @override
  String get passportTrajectoryShareAction => 'Compartir';

  @override
  String passportTrajectoryOfUser(String name) {
    return 'Trayectoria de $name';
  }

  @override
  String get passportTrajectoryMemorableEmptyReadOnly =>
      'Todavía no eligió un partido memorable';

  @override
  String get passportCoverEyebrow => 'MI PASAPORTE';

  @override
  String get passportEmptyHeadline => 'Todo hincha tiene una historia.';

  @override
  String get passportChangeSeasonCta => 'Cambiar temporada';

  @override
  String passportSeasonProgressLine(Object marked, Object total) {
    return '$marked de $total partidos registrados';
  }

  @override
  String passportSeasonTotalOnly(Object total) {
    return '$total partidos';
  }

  @override
  String get passportSealLabel => 'YO FUI';

  @override
  String get passportSealActionLabel => 'Yo fui';

  @override
  String get passportRoundSemifinal => 'Semifinal';

  @override
  String get passportRoundQuarterfinal => 'Cuartos de final';

  @override
  String get passportRoundFinal => 'Final';

  @override
  String get passportRoundPlayoff => 'Repesca';

  @override
  String get passportRoundOf16 => 'Octavos de final';

  @override
  String passportRoundPhase(int n) {
    return 'Fase $n';
  }

  @override
  String passportRoundMatchday(int n) {
    return 'Jornada $n';
  }

  @override
  String passportRoundGroup(String letter) {
    return 'Grupo $letter';
  }

  @override
  String get arenaRankingDetailFirstTry => 'Aciertos a la primera';

  @override
  String get arenaRankingDetailReview => 'Aciertos en la revisión';

  @override
  String get arenaRankingDetailAbandoned => 'Revelados/abandonos';

  @override
  String get arenaRankingYouTag => 'TÚ';

  @override
  String arenaRankingPlace(int rank) {
    return '$rank.º lugar';
  }

  @override
  String get arenaRankingPointsFull => 'puntos';

  @override
  String get arenaRankingPeriodOverall => 'Ranking general';

  @override
  String get arenaRankingPeriodWeek => 'Esta semana';

  @override
  String get arenaRankingByGame => 'Puntos por juego';

  @override
  String get arenaRankingHowScoredSelf => 'Cómo puntuaste';

  @override
  String arenaRankingHowScoredOther(String name) {
    return 'Cómo puntuó $name';
  }

  @override
  String arenaRankingGamePointsShare(int score, int percent) {
    return '$score pts • $percent% del total';
  }

  @override
  String get arenaRankingNoPointsTitle => 'Sin puntos en este período';

  @override
  String get arenaRankingNoPointsOther =>
      'Este hincha aún no ha puntuado en los juegos durante el período seleccionado.';

  @override
  String get arenaRankingNoPointsSelf =>
      'Aún no has puntuado en los juegos durante el período seleccionado.';

  @override
  String arenaRankingGapToNext(int points, int rank) {
    return '$points pts para alcanzar el $rank.º';
  }

  @override
  String get commonClose => 'CERRAR';

  @override
  String get commonRetry => 'Intentar de nuevo';

  @override
  String get commonComingSoon => 'Próximamente';

  @override
  String get commonComingSoonMessage => 'Esta sección aún se está preparando.';

  @override
  String get featureUnavailableTitle => 'No disponible';

  @override
  String get featureUnavailableMessage => 'Esta sección no está disponible.';

  @override
  String get commonLinkOpenError => 'No se pudo abrir este enlace.';

  @override
  String get commonLoadError => 'No se pudieron cargar los datos';

  @override
  String get commonSelectPlaceholder => 'Seleccionar';

  @override
  String get commonNoDataFound => 'No se encontraron datos.';

  @override
  String get membershipCheckInAction => 'HACER CHECK-IN';

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

  @override
  String get tacticalIdentityGameTitle => 'Identidad Futbolística';

  @override
  String get tacticalIdentityCardSubtitleNew => '¿En qué tipo de fútbol crees?';

  @override
  String get tacticalIdentityCardCtaStart => 'Descubrir mi perfil';

  @override
  String get tacticalIdentityCardCtaViewResult => 'Ver resultado';

  @override
  String get tacticalIdentityCardCtaRedo => 'Rehacer';

  @override
  String tacticalIdentityYourProfile(String name) {
    return 'Tu perfil: $name';
  }

  @override
  String get tacticalIntroTitle => '¿Cuál es tu identidad futbolística?';

  @override
  String tacticalIntroDescription(String club) {
    return '10 decisiones. Ninguna respuesta correcta. Descubre cómo ves el juego y con qué técnicos que pasaron por el $club tu filosofía más se acerca.';
  }

  @override
  String get tacticalIntroMeta => '10 preguntas • ~3 minutos';

  @override
  String get tacticalIntroNoRightWrong =>
      'No existen respuestas correctas o incorrectas.';

  @override
  String get tacticalIntroStart => 'Empezar';

  @override
  String get tacticalQuestionContinue => 'Continuar';

  @override
  String get tacticalProcessingTitle => 'Analizando tu identidad...';

  @override
  String get tacticalResultYourProfile => 'TU PERFIL';

  @override
  String get tacticalResultTacticalMap => 'MAPA TÁCTICO';

  @override
  String tacticalResultMainReference(String club) {
    return 'Tu principal referencia del $club';
  }

  @override
  String get tacticalResultOtherReferences => 'OTRAS REFERENCIAS';

  @override
  String tacticalIdentityAffinityLabel(String percent) {
    return '$percent% de afinidad táctica';
  }

  @override
  String get tacticalResultShare => 'Compartir resultado';

  @override
  String get tacticalAxisPossession => 'POSESIÓN';

  @override
  String get tacticalAxisVertical => 'VERTICAL';

  @override
  String get tacticalAxisDogmatic => 'DOGMÁTICO';

  @override
  String get tacticalAxisPragmatic => 'PRAGMÁTICO';

  @override
  String playerIdentityGameTitle(String club) {
    return '¿Qué crack del $club eres?';
  }

  @override
  String playerIdentityCardSubtitleNew(String club) {
    return '10 situaciones de juego. Descubre con qué ídolo del $club tu estilo combina más.';
  }

  @override
  String get playerIdentityCardCtaStart => 'Descubrir mi perfil';

  @override
  String get playerIdentityCardCtaViewResult => 'Ver resultado';

  @override
  String get playerIdentityCardCtaRedo => 'Rehacer';

  @override
  String playerIdentityYourProfile(String name) {
    return 'Tu perfil: $name';
  }

  @override
  String playerIntroTitle(String club) {
    return '¿Qué crack del $club eres?';
  }

  @override
  String playerIntroDescription(String club) {
    return 'Cada jugador ve el partido de una manera. Responde 10 situaciones de juego y descubre qué nombre que marcó la historia del $club combina más con tus elecciones.';
  }

  @override
  String get playerIntroMeta => '10 preguntas • ~3 minutos';

  @override
  String get playerIntroNoRightWrong => 'No existen respuestas correctas.';

  @override
  String get playerIntroStart => 'Empezar prueba';

  @override
  String get playerProcessingTitle => 'Calculando tu estilo...';

  @override
  String get playerResultYourProfile => 'TU PERFIL';

  @override
  String playerResultReferencesTitle(String club) {
    return 'Referencias del $club';
  }

  @override
  String get playerResultTraitsTitle => 'TUS RASGOS';

  @override
  String playerIdentityAffinityLabel(String percent) {
    return '$percent% afinidad de estilo';
  }

  @override
  String get playerResultShare => 'Compartir resultado';

  @override
  String get playerReferenceDisclaimer =>
      'Estos atributos son referencias editoriales usadas en esta experiencia y no evaluaciones oficiales del jugador.';

  @override
  String get lineupPlayerHeading => 'JUGADOR';

  @override
  String lineupShirt(int number) {
    return 'CAMISETA $number';
  }

  @override
  String get lineupTypePlayerName => 'Escribe el nombre del jugador';

  @override
  String get lineupBackToField => 'VOLVER AL CAMPO';

  @override
  String get lineupGiveUp => 'ABANDONAR EL PARTIDO';

  @override
  String get lineupGiveUpTitle => '¿Abandonar el partido?';

  @override
  String get lineupGiveUpMessage =>
      'Los jugadores restantes se revelarán y el partido terminará.';

  @override
  String get lineupGiveUpConfirm => 'ABANDONAR';

  @override
  String get lineupKeepPlaying => 'Seguir jugando';

  @override
  String lineupMatchProgress(int current, int total) {
    return 'PARTIDO $current DE $total';
  }

  @override
  String lineupWordCount(int words, int letters) {
    String _temp0 = intl.Intl.pluralLogic(
      words,
      locale: localeName,
      other: '$words palabras',
      one: '1 palabra',
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
  String get lineupComplete => 'ALINEACIÓN COMPLETA';

  @override
  String get lineupDiscovered => 'DESCUBIERTOS';

  @override
  String get lineupAttempts => 'INTENTOS';

  @override
  String get lineupTime => 'TIEMPO';

  @override
  String get lineupResultCopied => 'Resultado copiado.';

  @override
  String get lineupCopyResult => 'Copiar resultado';

  @override
  String get lineupShareResult => 'Compartir resultado';

  @override
  String get lineupNextMatch => 'PRÓXIMO PARTIDO';

  @override
  String get lineupPreviousMatch => 'ANTERIOR';

  @override
  String get lineupNoNumber => 'Jugador sin número confirmado';

  @override
  String lineupNotDiscovered(String shirt) {
    return '$shirt, no descubierto';
  }

  @override
  String lineupShirtLabel(int number) {
    return 'Camiseta $number';
  }

  @override
  String lineupA11yRevealed(String shirt, String name) {
    return '$shirt, $name, descubierto';
  }

  @override
  String lineupA11yPending(String shirt, String position) {
    return '$shirt, $position, aún no descubierto';
  }

  @override
  String get lineupTileCorrect => 'posición correcta';

  @override
  String get lineupTilePresent => 'la letra existe, posición incorrecta';

  @override
  String get lineupTileAbsent => 'la letra no existe';

  @override
  String get lineupTileEmpty => 'vacío';

  @override
  String get keyboardDelete => 'Borrar';

  @override
  String get keyboardConfirm => 'Confirmar';

  @override
  String get commonCloseLabel => 'Cerrar';

  @override
  String get careerSubtitle => 'Descubre por la carrera';

  @override
  String get careerSelectFromList => 'Selecciona un jugador de la lista.';

  @override
  String get careerRevealTitle => '¿Revelar jugador?';

  @override
  String get careerRevealMessage =>
      'Al revelar la respuesta, esta ronda se dará por terminada.';

  @override
  String get careerReveal => 'REVELAR';

  @override
  String get careerRevealPlayer => 'Revelar jugador';

  @override
  String get careerGuess => 'ADIVINAR';

  @override
  String get careerNextPlayer => 'PRÓXIMO JUGADOR';

  @override
  String careerWrongGuessFeedback(String name, int remaining) {
    return 'No es $name · Quedan $remaining';
  }

  @override
  String get careerTriedLabel => 'Ya intentaste';

  @override
  String careerAttemptsRemaining(int remaining) {
    return 'Intentos · Quedan $remaining';
  }

  @override
  String get careerCorrectTitle => '¡Acertaste!';

  @override
  String get careerCorrectFirstTry => '¡Acertaste a la primera!';

  @override
  String careerCorrectInAttempts(int attempts) {
    return 'Acertaste en $attempts intentos.';
  }

  @override
  String get careerWrongTitle => 'Esta vez no';

  @override
  String careerUsedAllAttempts(int max) {
    return 'Usaste los $max intentos.';
  }

  @override
  String get careerPlayerRevealed => 'Jugador revelado';

  @override
  String get careerRoundEnded => 'Ronda terminada.';

  @override
  String get careerYouGotIt => 'Acertaste';

  @override
  String get careerWas => 'Era';

  @override
  String get careerAnswer => 'Respuesta';

  @override
  String get careerNationalTeam => 'Selección nacional';

  @override
  String get careerYears => 'Años';

  @override
  String get careerClubs => 'Clubes';

  @override
  String get careerGames => 'Partidos';

  @override
  String get careerGoals => 'Goles';

  @override
  String careerOnLoan(String team) {
    return '$team (cedido)';
  }

  @override
  String get careerAggregateTitle => 'Totales combinados';

  @override
  String careerAggregateLine(
    String club,
    String spells,
    String apps,
    String goals,
  ) {
    return '$club ($spells): $apps partidos · $goals goles';
  }

  @override
  String get commonBack => 'VOLVER';

  @override
  String get guessCorrectTitle => '¡ACERTASTE!';

  @override
  String get guessOutOfAttempts => 'Se acabaron los intentos';

  @override
  String guessCorrectDetail(int used, int max) {
    return 'Acertaste en $used de $max intentos.';
  }

  @override
  String get guessNoPlayers =>
      'Aún no hay jugadores disponibles para esta arena.';

  @override
  String get guessRoundEnded => 'Ronda terminada';

  @override
  String guessAttemptsRemaining(int remaining) {
    return '$remaining intentos restantes';
  }

  @override
  String get guessThePlayerWas => 'El jugador era: ';

  @override
  String get guessTypePlayer => 'Escribe un jugador...';

  @override
  String get guessColPos => 'POS';

  @override
  String get guessColShirt => 'CAMISETA';

  @override
  String get guessColBase => 'CANTERA';

  @override
  String get guessColDebut => 'DEBUT';

  @override
  String dateMinutesAgo(int minutes) {
    return 'hace ${minutes}min';
  }

  @override
  String dateHoursAgo(int hours) {
    return 'hace ${hours}h';
  }

  @override
  String dateDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'hace $days días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String datePrepositionFull(int day, String month) {
    return '$day de $month';
  }

  @override
  String get socialMediaTitle => 'MEDIOS';

  @override
  String get socialFeedLoadError => 'No se pudo cargar el feed';

  @override
  String socialEmptyState(String club) {
    return 'Sigue al $club en las redes';
  }

  @override
  String socialViewsM(String value) {
    return '${value}M visualizaciones';
  }

  @override
  String socialViewsK(String value) {
    return '${value}K visualizaciones';
  }

  @override
  String socialViewsCount(int count) {
    return '$count visualizaciones';
  }

  @override
  String get socialPlatformInstagram => 'INSTAGRAM';

  @override
  String get socialPlatformYoutube => 'YOUTUBE';

  @override
  String get socialPlatformX => 'X';

  @override
  String get newsTitle => 'NOTICIAS';

  @override
  String get newsLoadError => 'No se pudieron cargar las noticias';

  @override
  String get newsEmptyTitle => 'Aún no hay noticias';

  @override
  String newsEmptyMessage(String club) {
    return 'Vuelve más tarde para las novedades del $club.';
  }

  @override
  String newsSourceLabel(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'FUENTE: GOIÁS ESPORTE CLUBE',
      'other': 'FUENTE: $club',
    });
    return '$_temp0';
  }

  @override
  String get newsOpenOriginal => 'Abrir artículo original';

  @override
  String get newsPdfLoadErrorTitle => 'No se pudo cargar el PDF';

  @override
  String get newsPdfShareButton => 'Compartir PDF';

  @override
  String get relTimeNow => 'ahora';

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
    return 'Socios del $clubName';
  }

  @override
  String partnersSubtitle(String clubName) {
    return 'Marcas que caminan junto al $clubName.';
  }

  @override
  String partnersOpenInstagram(String name) {
    return 'Abrir Instagram de $name';
  }

  @override
  String partnersOpenWebsite(String name) {
    return 'Abrir sitio de $name';
  }

  @override
  String get partnersTierInstitutional => 'Institucional';

  @override
  String get partnersTierPremium => 'Patrocinadores Premium';

  @override
  String get partnersTierRegional => 'Patrocinadores Regionales';

  @override
  String get partnersTierOfficialSupplier => 'Proveedores Oficiales';

  @override
  String get squadTitle => 'PLANTILLA';

  @override
  String get squadLoadError => 'No se pudo cargar la plantilla';

  @override
  String get squadEmpty => 'Plantilla no disponible en este momento';

  @override
  String get squadClubHistory => 'Carrera';

  @override
  String get squadAboutSection => 'Acerca de';

  @override
  String squadCareerStatsLine(String matches, String goals) {
    return '$matches partidos · $goals goles';
  }

  @override
  String get squadNumber => 'Número';

  @override
  String get squadAge => 'Edad';

  @override
  String squadAgeValue(int age) {
    return '$age años';
  }

  @override
  String get squadNationality => 'Nacionalidad';

  @override
  String get squadHeight => 'Altura';

  @override
  String get squadFoot => 'Pie';

  @override
  String get squadLoanTag => '(prest.)';

  @override
  String get squadDataUnconfirmed => 'Dato no confirmado en la fuente.';

  @override
  String get squadGroupGoalkeepers => 'Porteros';

  @override
  String get squadGroupDefenders => 'Centrales';

  @override
  String get squadGroupRightBacks => 'Laterales derechos';

  @override
  String get squadGroupLeftBacks => 'Laterales izquierdos';

  @override
  String get squadGroupDefensiveMids => 'Volantes';

  @override
  String get squadGroupMidfielders => 'Mediocampistas';

  @override
  String get squadGroupForwards => 'Delanteros';

  @override
  String get squadInstagramLabel => 'Instagram';

  @override
  String get validatorNameRequired => 'Ingresa tu nombre completo.';

  @override
  String get validatorEmailRequired => 'Ingresa tu correo.';

  @override
  String get validatorEmailInvalid => 'Ingresa un correo válido.';

  @override
  String get validatorPasswordRequired => 'Ingresa tu contraseña.';

  @override
  String get validatorPasswordCreate => 'Crea una contraseña.';

  @override
  String validatorPasswordMinLength(int min) {
    return 'La contraseña debe tener al menos $min caracteres.';
  }

  @override
  String get validatorConfirmRequired => 'Confirma tu contraseña.';

  @override
  String get validatorPasswordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get validatorPhoneRequired => 'Ingresa tu teléfono.';

  @override
  String get validatorZipRequired => 'Ingresa el código postal.';

  @override
  String get checkEmailResent =>
      'Correo reenviado. Revisa tu bandeja de entrada.';

  @override
  String get checkEmailTitle => 'Confirma tu correo';

  @override
  String get checkEmailResending => 'Reenviando...';

  @override
  String checkEmailResendIn(int seconds) {
    return 'Reenviar en ${seconds}s';
  }

  @override
  String get checkEmailResend => 'Reenviar código';

  @override
  String get checkEmailOtpSentTo => 'Enviamos un código de 6 dígitos a';

  @override
  String get checkEmailConfirmButton => 'CONFIRMAR CÓDIGO';

  @override
  String get checkEmailDidNotReceive => '¿No recibiste el código?';

  @override
  String get checkEmailChangeEmail => '¿Correo incorrecto? Cambiar correo';

  @override
  String get checkEmailChangeTitle => '¿Cambiar correo?';

  @override
  String get checkEmailChangeMessage =>
      'Esto termina este registro y comienza uno nuevo, para que ingreses el correo correcto.';

  @override
  String get checkEmailChangeConfirm => 'Cambiar correo';

  @override
  String get resetPasswordTitle => 'Crear nueva contraseña';

  @override
  String get resetPasswordSubtitle =>
      'Elige una nueva contraseña para acceder a tu cuenta.';

  @override
  String get resetPasswordSuccessTitle => 'Contraseña cambiada con éxito';

  @override
  String get resetPasswordSuccessMessage =>
      'Tu contraseña se ha actualizado. Inicia sesión de nuevo para continuar.';

  @override
  String get forgotVerifyEmailTitle => 'Revisa tu correo';

  @override
  String forgotSentDescription(String club) {
    return 'Si este correo tiene una cuenta en la app de $club, recibirás un enlace de restablecimiento en breve:';
  }

  @override
  String get forgotNotReceived => '¿No lo recibiste?';

  @override
  String get forgotResendSuccess =>
      'Si la cuenta existe, reenviamos el correo.';

  @override
  String get commonGotIt => 'Entendido';

  @override
  String get forgotTitle => 'Recuperar contraseña';

  @override
  String get forgotSubtitle =>
      'Escribe tu correo para recibir el enlace de restablecimiento.';

  @override
  String get forgotSendButton => 'Enviar enlace';

  @override
  String get forgotSending => 'Enviando...';

  @override
  String get authShowPassword => 'Mostrar contraseña';

  @override
  String get authHidePassword => 'Ocultar contraseña';

  @override
  String get ticketsLoadError => 'No se pudieron cargar las entradas.';

  @override
  String get ticketsNextEvent => 'PRÓXIMO EVENTO';

  @override
  String get ticketsQuickAccess => 'ACCESO RÁPIDO';

  @override
  String get ticketsMyTickets => 'Mis entradas';

  @override
  String ticketsMyTicketsSubtitle(String club) {
    return 'Entradas para partidos del $club';
  }

  @override
  String get ticketsMyOrders => 'Mis pedidos';

  @override
  String get ticketsMyOrdersSubtitle => 'Historial de tus compras';

  @override
  String get ticketsNoEvents => 'No hay eventos disponibles en este momento';

  @override
  String get ticketsNoEventsMessage =>
      'Cuando un nuevo partido esté disponible para venta o check-in, aparecerá aquí.';

  @override
  String get ticketsMyTicketsTitle => 'MIS ENTRADAS';

  @override
  String get ticketsMyTicketsLoadError => 'No se pudieron cargar tus entradas';

  @override
  String get ticketsMyTicketsEmpty => 'Aún no tienes entradas';

  @override
  String ticketsMyTicketsEmptyMessage(String club) {
    return 'Tus entradas para partidos del $club aparecerán aquí.';
  }

  @override
  String get ticketsMyOrdersTitle => 'MIS PEDIDOS';

  @override
  String get ticketsMyOrdersLoadError => 'No se pudieron cargar tus pedidos';

  @override
  String get ticketsMyOrdersEmpty => 'No se encontraron pedidos';

  @override
  String get ticketsMyOrdersEmptyMessage =>
      'Tus compras de entradas aparecerán aquí.';

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
  String get orderStatusPending => 'Pendiente';

  @override
  String get orderStatusCancelled => 'Cancelado';

  @override
  String get orderStatusRefunded => 'Reembolsado';

  @override
  String get ticketsCheckinUnavailableLabel => 'CHECK-IN AÚN NO DISPONIBLE';

  @override
  String get ticketsCheckinUnavailableButton => 'Check-in próximamente';

  @override
  String ticketsCheckinAvailableFrom(String date, String time) {
    return 'Disponible a partir del $date a las $time';
  }

  @override
  String get ticketsCheckinAvailableLabel =>
      'TU PLAN TE DA ACCESO A ESTE PARTIDO';

  @override
  String get ticketsCheckInButton => 'Hacer check-in';

  @override
  String get ticketsDeclinedLabel => 'MARCASTE QUE NO IRÁS ESTA VEZ';

  @override
  String get ticketsChangedMindButton => 'Cambié de opinión';

  @override
  String get ticketsCheckinClosedLabel => 'CHECK-IN CERRADO PARA ESTE PARTIDO';

  @override
  String get ticketsCheckinClosedButton => 'Check-in cerrado';

  @override
  String get ticketsCheckinAwayGameLabel => 'CHECK-IN SOLO DISPONIBLE DE LOCAL';

  @override
  String get ticketsViewTicketButton => 'Ver entrada';

  @override
  String get ticketsSaleUpcomingLabel => 'VENTA AÚN NO ABIERTA';

  @override
  String get ticketsSaleUpcomingButton => 'Venta próximamente';

  @override
  String ticketsSaleStartsAt(String date, String time) {
    return 'Inicio de venta: $date a las $time';
  }

  @override
  String get ticketsSaleOpenLabel => 'ENTRADAS DISPONIBLES';

  @override
  String get ticketsBuyTicketButton => 'Comprar entrada';

  @override
  String get ticketsSoldOutLabel => 'ENTRADAS AGOTADAS';

  @override
  String get ticketsSoldOutButton => 'Agotado';

  @override
  String get ticketsSaleClosedLabel => 'VENTA CERRADA PARA ESTE PARTIDO';

  @override
  String get ticketsSaleClosedButton => 'Venta cerrada';

  @override
  String get ticketsSaleAwayGameLabel => 'ENTRADAS SOLO CON EL CLUB LOCAL';

  @override
  String get ticketsCheckinConfirmedLabel => 'CHECK-IN CONFIRMADO';

  @override
  String get ticketsUndoCheckInButton => 'Deshacer check-in';

  @override
  String get ticketsChangeCheckInButton => 'Cambiar check-in';

  @override
  String get ticketsConfirmPresenceTitle => 'CONFIRMAR PRESENCIA';

  @override
  String get ticketsGoToMatchButton => 'Voy al partido';

  @override
  String get ticketsNotThisTimeButton => 'Esta vez no';

  @override
  String get ticketsDeclineConfirmTitle => '¿Seguro que no vas?';

  @override
  String ticketsDeclineConfirmMessage(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias':
          'La Serrinha no es lo mismo sin vos. ¡El Goiás cuenta con el apoyo de la Nación Esmeraldina! 💚\n\nTodavía podrás cambiar de opinión mientras el check-in siga abierto.',
      'other':
          'El estadio no es lo mismo sin vos. ¡El $club cuenta con el apoyo de la afición! 💚\n\nTodavía podrás cambiar de opinión mientras el check-in siga abierto.',
    });
    return '$_temp0';
  }

  @override
  String get ticketsWantToGoButton => 'Quiero ir al partido';

  @override
  String get ticketsConfirmDeclineButton => 'Confirmar que no voy';

  @override
  String get ticketsCheckinSuccessTitle => '¡Check-in realizado!';

  @override
  String get ticketsCheckinSuccessMessage =>
      'La entrada también está disponible en el menú Mis Entradas.';

  @override
  String get ticketsCloseButton => 'Cerrar';

  @override
  String get ticketsSaveTicketButton => 'Guardar entrada';

  @override
  String ticketsSectorPickerTitle(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': '¿Dónde quieres apoyar al Verdão?',
      'other': '¿Dónde quieres apoyar al $club?',
    });
    return '$_temp0';
  }

  @override
  String get ticketsSectorPickerSubtitle =>
      'Elige el sector para este partido.';

  @override
  String get ticketsConfirmCheckInButton => 'Confirmar check-in';

  @override
  String get ticketsViewTicketTitle => 'MI ENTRADA';

  @override
  String get ticketsMatchInfoTitle => 'INFORMACIÓN DEL PARTIDO';

  @override
  String ticketsHomeCrowdLabel(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'HINCHADA DEL GOIÁS',
      'other': 'HINCHADA DEL $club',
    });
    return '$_temp0';
  }

  @override
  String get ticketsAwayCrowdLabel => 'HINCHADA VISITANTE';

  @override
  String get ticketsContinueButton => 'Continuar';

  @override
  String ticketsTicketCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas',
      one: '1 entrada',
    );
    return '$_temp0';
  }

  @override
  String get ticketsSummaryTitle => 'RESUMEN DE LA COMPRA';

  @override
  String get ticketsTotalLabel => 'Total';

  @override
  String ticketsHolderDataTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DATOS DE LOS TITULARES',
      one: 'DATOS DEL TITULAR',
    );
    return '$_temp0';
  }

  @override
  String ticketsHolderSlotLabel(int index, String sector, String category) {
    return 'Entrada $index · $sector · $category';
  }

  @override
  String get ticketsHolderIsSelfCheckbox => 'Esta entrada es para mí';

  @override
  String get ticketsDocumentLabel => 'DNI o pasaporte';

  @override
  String get ticketsNominalWarning =>
      'La entrada es nominal e intransferible. Revisa los datos antes de continuar.';

  @override
  String get ticketsFinalizePurchaseButton => 'Finalizar compra';

  @override
  String get ticketsPurchaseSuccessTitle => '¡Entrada comprada!';

  @override
  String get ticketsPurchaseSuccessMessage =>
      'La entrada también está disponible en el menú Mis Entradas.';

  @override
  String get ticketsTabUpcoming => 'Próximos';

  @override
  String get ticketsTabHistory => 'Historial';

  @override
  String get ticketsUndoCheckInConfirmTitle => '¿Deshacer check-in?';

  @override
  String get ticketsUndoCheckInConfirmMessage =>
      'Tu acceso a este partido será cancelado y tu lugar podrá quedar disponible nuevamente.\n\nPodrás hacer un nuevo check-in mientras el período siga abierto.';

  @override
  String get ticketsKeepCheckInButton => 'Mantener check-in';

  @override
  String get ticketsOriginCheckIn => 'Check-in de socio';

  @override
  String get ticketsOriginPurchase => 'Compra';

  @override
  String get ticketsViewRelatedTicket => 'Ver entrada';

  @override
  String get ticketsLoadUserDataError =>
      'No fue posible cargar tus datos. Inténtalo de nuevo.';

  @override
  String get ticketsNotMemberTitle => 'Todavía no eres socio';

  @override
  String ticketsNotMemberMessage(String programName) {
    return 'El check-in es exclusivo para quien ya tiene el $programName activo.';
  }

  @override
  String get ticketsNotMemberGoToMembershipButton => 'Ver los planes';

  @override
  String get ticketsRequestRefundButton => 'Solicitar reembolso';

  @override
  String get ticketsRefundConfirmTitle => 'Solicitar reembolso';

  @override
  String get ticketsRefundConfirmMessage =>
      '¿Seguro que deseas solicitar el reembolso de esta entrada?\n\nDespués de confirmar, esta entrada dejará de ser válida.';

  @override
  String get ticketsRefundConfirmButton => 'Confirmar reembolso';

  @override
  String get ticketsRefundCancelButton => 'Volver';

  @override
  String get ticketsRefundErrorTitle => 'No fue posible reembolsar';

  @override
  String get ticketsRefundErrorMessage =>
      'No fue posible completar el reembolso de esta entrada. Inténtalo de nuevo.';

  @override
  String get ticketsViewDetailsButton => 'Ver detalles';

  @override
  String get ticketsRefundDetailsTitle => 'Entrada reembolsada';

  @override
  String get ticketsRefundDetailsStatusLabel => 'Estado';

  @override
  String get ticketsRefundDetailsMatchLabel => 'Partido';

  @override
  String get ticketsRefundDetailsTicketLabel => 'Entrada';

  @override
  String get ticketsRefundDetailsRequestedAtLabel => 'Fecha de la solicitud';

  @override
  String get ticketsDemoDisclaimerBody =>
      'Esta compra es simulada. No se realizará ningún cobro y la entrada generada no es válida para el ingreso al estadio.';

  @override
  String get ticketsDemoTag => 'Entrada de demostración';

  @override
  String get ticketsRefundDemoNotice =>
      'Esta simulación no involucra dinero real — no se reembolsará nada.';

  @override
  String get ticketsRefundDemoConcludedNote =>
      'Reembolso de demostración — ningún valor fue movido.';

  @override
  String get ticketsHalfPriceTypeLabel => 'Tipo de entrada con descuento';

  @override
  String get ticketsHalfPriceLawOption => 'Por ley';

  @override
  String get ticketsHalfPricePromotionalOption => 'Promocional';

  @override
  String get ticketsHalfPriceProofLabel =>
      'Comprobante de descuento (obligatorio)';

  @override
  String get ticketsHalfPriceProofUploadButton => 'Adjuntar comprobante';

  @override
  String get ticketsHalfPriceProofUploaded => 'Comprobante enviado';

  @override
  String get ticketPdfDemoWatermark =>
      'DEMOSTRACIÓN\nNO VÁLIDO PARA EL INGRESO';

  @override
  String get ticketPdfDemoQrCaption => 'QR de demostración';

  @override
  String get ticketPdfFieldVenue => 'Lugar';

  @override
  String get ticketPdfFieldGate => 'Puerta';

  @override
  String get ticketPdfFieldCategory => 'Categoría';

  @override
  String get ticketPdfFieldDocument => 'DNI/Pasaporte';

  @override
  String get ticketPdfFieldOrigin => 'Origen';

  @override
  String get ticketPdfFieldAmount => 'Importe';

  @override
  String get ticketPdfFieldCode => 'Código';

  @override
  String get ticketPdfAntiScalpingTitle => 'NO COMPRES\nA REVENDEDORES!';

  @override
  String get ticketPdfAntiScalpingSubtitle => 'La entrada puede ser falsa.';

  @override
  String ticketPdfFooterNotice(String club) {
    return 'Esta entrada es personal e intransferible. Es obligatoria la presentación de un documento con foto en el ingreso. Solo se permite camiseta del $club o de la Selección Brasileña.';
  }

  @override
  String get ticketPdfInvalidTicket => 'ENTRADA\nINVÁLIDA';

  @override
  String get penaltyFinalResult => 'RESULTADO FINAL';

  @override
  String penaltyConverted(int goals, int total) {
    return 'Convertiste $goals de $total tiros';
  }

  @override
  String get penaltyScoreLabel => 'PENALES';

  @override
  String get penaltyDragToShoot => 'Arrastra el balón para disparar';

  @override
  String penaltyGoalsCount(int goals) {
    String _temp0 = intl.Intl.pluralLogic(
      goals,
      locale: localeName,
      other: '$goals Goles',
      one: '1 Gol',
    );
    return '$_temp0';
  }

  @override
  String penaltyGoalsCountUpper(int goals) {
    String _temp0 = intl.Intl.pluralLogic(
      goals,
      locale: localeName,
      other: '$goals GOLES',
      one: '1 GOL',
    );
    return '$_temp0';
  }

  @override
  String get penaltyResultGoal => '¡GOL!';

  @override
  String get penaltyResultSave => '¡ATAJADA!';

  @override
  String get penaltyResultOut => '¡FUERA!';

  @override
  String get penaltyResultPost => '¡AL PALO!';

  @override
  String get penaltyResultGoalShort => 'Gol';

  @override
  String get penaltyResultSaveShort => 'Atajada';

  @override
  String get penaltyResultOutShort => 'Fuera';

  @override
  String get penaltyResultPostShort => 'Palo';

  @override
  String get playerPositionGolFull => 'Portero';

  @override
  String get playerPositionGolShort => 'POR';

  @override
  String get playerPositionZagFull => 'Defensa central';

  @override
  String get playerPositionZagShort => 'DFC';

  @override
  String get playerPositionLdFull => 'Lateral derecho';

  @override
  String get playerPositionLdShort => 'LD';

  @override
  String get playerPositionLeFull => 'Lateral izquierdo';

  @override
  String get playerPositionLeShort => 'LI';

  @override
  String get playerPositionAldFull => 'Carrilero derecho';

  @override
  String get playerPositionAldShort => 'CAD';

  @override
  String get playerPositionAleFull => 'Carrilero izquierdo';

  @override
  String get playerPositionAleShort => 'CAI';

  @override
  String get playerPositionVolFull => 'Volante';

  @override
  String get playerPositionVolShort => 'VOL';

  @override
  String get playerPositionMcFull => 'Centrocampista';

  @override
  String get playerPositionMcShort => 'MC';

  @override
  String get playerPositionMeiFull => 'Mediapunta';

  @override
  String get playerPositionMeiShort => 'MP';

  @override
  String get playerPositionMdFull => 'Volante por derecha';

  @override
  String get playerPositionMdShort => 'MD';

  @override
  String get playerPositionMeFull => 'Volante por izquierda';

  @override
  String get playerPositionMeShort => 'MI';

  @override
  String get playerPositionPdFull => 'Extremo derecho';

  @override
  String get playerPositionPdShort => 'ED';

  @override
  String get playerPositionPeFull => 'Extremo izquierdo';

  @override
  String get playerPositionPeShort => 'EI';

  @override
  String get playerPositionSaFull => 'Segundo delantero';

  @override
  String get playerPositionSaShort => 'SD';

  @override
  String get playerPositionAtaFull => 'Delantero';

  @override
  String get playerPositionAtaShort => 'DEL';

  @override
  String get crowdTitle => 'ALINEACIÓN DE LA AFICIÓN';

  @override
  String get crowdTabEscale => 'ALINEAR';

  @override
  String crowdSubmissionsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'alineaciones enviadas',
      one: 'alineación enviada',
    );
    return '$_temp0';
  }

  @override
  String get crowdMostVotedFormation => 'formación elegida';

  @override
  String get crowdNoVotes => 'Aún no hay votos';

  @override
  String crowdNoVotesMessage(String club) {
    return 'Sé el primero en alinear al $club y ayuda a formar el equipo de la afición.';
  }

  @override
  String get crowdVotingClosed =>
      'Votación cerrada — esta es la alineación que enviaste.';

  @override
  String get crowdUpdateLineup => 'ACTUALIZAR ALINEACIÓN';

  @override
  String get crowdConfirmLineup => 'CONFIRMAR ALINEACIÓN';

  @override
  String get crowdPickPlayer => 'Elige el jugador para esta posición';

  @override
  String get crowdSelectedPlayer => 'Seleccionado';

  @override
  String get crowdAlsoCanPlaySection => 'TAMBIÉN PUEDE JUGAR AQUÍ';

  @override
  String get crowdCanAlsoPlayBadge => 'Puede jugar';

  @override
  String crowdCardDescVoted(String club) {
    return 'Mira cómo la afición está alineando al $club para el próximo partido.';
  }

  @override
  String crowdCardDescNew(String club) {
    return 'Alinea al $club para el próximo partido y mira el equipo más elegido por la afición.';
  }

  @override
  String get clubSectionHistory => 'Historia';

  @override
  String get clubSectionSquad => 'Plantel';

  @override
  String get clubSectionTitles => 'Títulos';

  @override
  String get clubSectionPartners => 'Aliados';

  @override
  String get clubSectionBoard => 'Directiva';

  @override
  String get clubBoardSubtitle => 'Consejos, presidencia y directiva del club.';

  @override
  String get clubBoardLoadErrorTitle => 'No se pudo cargar la directiva';

  @override
  String get clubBoardEmptyTitle => 'Directiva en actualización';

  @override
  String get clubBoardEmptyMessage =>
      'Vuelve pronto para ver la directiva del club.';

  @override
  String get clubSectionTransparency => 'Transparencia';

  @override
  String get clubTransparencySubtitle => 'Balances, actas y estados contables.';

  @override
  String get clubTransparencyLoadErrorTitle =>
      'No se pudo cargar la transparencia';

  @override
  String get clubTransparencyEmptyTitle => 'Ningún documento disponible';

  @override
  String get clubTransparencyEmptyMessage =>
      'Vuelve pronto para ver los documentos.';

  @override
  String clubTransparencyDocumentCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos',
      one: '1 documento',
    );
    return '$_temp0';
  }

  @override
  String get clubTransparencyShareButton => 'Compartir PDF';

  @override
  String get clubSectionTimeline => 'Cronología';

  @override
  String get clubSectionSongs => 'Himno y Canciones';

  @override
  String clubHistorySubtitle(String year) {
    return 'Desde $year hasta hoy.';
  }

  @override
  String get clubSquadSubtitle => 'Los jugadores que visten la camiseta.';

  @override
  String clubTitlesSubtitle(int count) {
    return '$count conquistas a lo largo de la historia.';
  }

  @override
  String clubPartnersSubtitle(String clubName) {
    return 'Quienes caminan junto al $clubName.';
  }

  @override
  String get clubSongsSubtitle =>
      'El himno y las canciones que animan a la afición.';

  @override
  String get clubSectionIdols => 'Ídolos';

  @override
  String get clubIdolsSubtitle => 'Nombres que marcaron la historia del club.';

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
  String get clubAnthemSection => 'HIMNO';

  @override
  String clubSongsSection(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'CANCIONES ESMERALDINAS',
      'other': 'CANCIONES DEL $club',
    });
    return '$_temp0';
  }

  @override
  String get clubLyricsLabel => 'LETRA';

  @override
  String get clubLyricsUnavailable => 'Letra aún no disponible.';

  @override
  String get clubAudioUnavailable => 'Audio no disponible por ahora.';

  @override
  String get clubPlaybackError => 'No fue posible reproducir esta canción.';

  @override
  String get clubMuteSemantics => 'Silenciar';

  @override
  String get clubUnmuteSemantics => 'Activar sonido';

  @override
  String get clubVolumeSemantics => 'Control de volumen';

  @override
  String clubPlaySongSemantics(String title) {
    return 'Reproducir $title';
  }

  @override
  String clubPauseSongSemantics(String title) {
    return 'Pausar $title';
  }

  @override
  String get clubMainTitles => 'TÍTULOS PRINCIPALES';

  @override
  String get clubHistoricCampaigns => 'CAMPAÑAS HISTÓRICAS';

  @override
  String clubTimesChampion(int count) {
    return '$count× CAMPEÓN';
  }

  @override
  String get clubEntryTitle => 'EL CLUB';

  @override
  String clubEntrySubtitle(String clubName) {
    return 'Historia, títulos, plantel e identidad del $clubName.';
  }

  @override
  String clubEntryCta(String clubName) {
    return 'CONOCER AL $clubName';
  }

  @override
  String membershipLoadError(String programName) {
    return 'No se pudo cargar $programName.';
  }

  @override
  String get membershipPlansTitle => 'PLANES';

  @override
  String membershipSector(String sector) {
    return 'Sector $sector';
  }

  @override
  String get membershipMostChosen => 'MÁS ELEGIDO';

  @override
  String get membershipPerMonth => '/mes';

  @override
  String membershipOrAnnual(String price) {
    return 'o $price en el plan anual';
  }

  @override
  String membershipAnnualContractInfo(String total) {
    return 'Adhesión anual de $total — cuotas equivalentes a este valor por mes';
  }

  @override
  String get membershipBenefits => 'BENEFICIOS';

  @override
  String get membershipSeeFullRegulation => 'Consulta el reglamento completo →';

  @override
  String get membershipStillHaveDoubts => '¿Aún tienes dudas sobre este plan?';

  @override
  String get membershipSeeFaq => 'VER PREGUNTAS FRECUENTES';

  @override
  String get membershipWantToJoin => 'QUIERO SER SOCIO';

  @override
  String get membershipNoStadiumAccess => 'Sin acceso al estadio';

  @override
  String get membershipViewPlan => 'VER PLAN';

  @override
  String get membershipOtherOptions => 'OTRAS OPCIONES';

  @override
  String get membershipMyMembership => 'Mi afiliación';

  @override
  String get membershipDependents => 'Dependientes';

  @override
  String get membershipDependentsPrep =>
      'La gestión de dependientes aún se está preparando.';

  @override
  String get membershipPayments => 'Pagos';

  @override
  String get membershipPaymentsPrep =>
      'El historial de pagos aún se está preparando.';

  @override
  String get membershipCheckinHistory => 'Historial de check-ins';

  @override
  String get membershipAreaPrep => 'Esta área aún se está preparando.';

  @override
  String get membershipSeeOtherPlans => 'Ver otros planes';

  @override
  String membershipHeroTitle(String club) {
    return 'Acércate aún más\nal $club.';
  }

  @override
  String get membershipHeroSubtitle =>
      'Sé parte de esta historia con acceso prioritario al estadio, ahorro en entradas, descuentos y experiencias exclusivas.';

  @override
  String get membershipChoosePlan => 'ELIGE TU PLAN';

  @override
  String get membershipChosenPlan => 'PLAN ELEGIDO';

  @override
  String get membershipChangePlan => 'CAMBIAR PLAN';

  @override
  String get membershipStep1Access => '1 de 3 · Datos de acceso';

  @override
  String get membershipStep2Personal => '2 de 3 · Datos de registro';

  @override
  String get membershipStep3Address => '3 de 3 · Dirección';

  @override
  String get membershipCpf => 'CPF';

  @override
  String get membershipNationality => 'Nacionalidad';

  @override
  String get membershipPassport => 'Pasaporte';

  @override
  String get membershipPassportOptional => 'Pasaporte (opcional)';

  @override
  String get membershipContactEmail => 'Correo de contacto';

  @override
  String get membershipNickname => 'Apodo (opcional)';

  @override
  String get membershipBirthdateHint => 'DD/MM/AAAA';

  @override
  String get membershipGender => 'Sexo';

  @override
  String get membershipGenderMale => 'Masculino';

  @override
  String get membershipGenderFemale => 'Femenino';

  @override
  String get membershipHomePhone => 'Teléfono fijo (opcional)';

  @override
  String membershipNewsletter(String programName) {
    return 'Deseo recibir noticias del club y de $programName por correo.';
  }

  @override
  String get membershipCountry => 'País';

  @override
  String get membershipPostalCode => 'Código postal';

  @override
  String get membershipDontKnowCep => 'No sé mi código postal';

  @override
  String get membershipLoadingCities => 'Cargando ciudades...';

  @override
  String get membershipSelectStateFirst => 'Selecciona primero el estado';

  @override
  String get membershipSelectCity => 'Seleccionar ciudad';

  @override
  String get membershipConfirmAssociation => 'CONFIRMAR AFILIACIÓN';

  @override
  String get membershipReviewTitle => 'REVISA TU AFILIACIÓN';

  @override
  String get membershipPlanLabel => 'Plan';

  @override
  String get membershipSectorLabel => 'Sector';

  @override
  String get membershipOptionLabel => 'Opción';

  @override
  String get membershipHolderData => 'DATOS DEL TITULAR';

  @override
  String get membershipName => 'Nombre';

  @override
  String get membershipBirthLabel => 'Nacimiento';

  @override
  String get membershipContact => 'CONTACTO';

  @override
  String get membershipAddressLabel => 'Dirección';

  @override
  String get membershipCityUf => 'Ciudad/Estado';

  @override
  String get membershipValue => 'IMPORTE';

  @override
  String get membershipMonthly => 'Mensual';

  @override
  String get membershipAnnual => 'Anual';

  @override
  String get membershipTerms => 'TÉRMINOS DE LA AFILIACIÓN';

  @override
  String membershipAcceptRegulation(String programName) {
    return 'He leído y acepto el Reglamento de $programName';
  }

  @override
  String get membershipReadFullRegulation => 'Leer el reglamento completo →';

  @override
  String membershipDemoDisclaimerBody(String programName) {
    return 'Esta adhesión es simulada y no crea ningún vínculo con el $programName. No se realizará ningún cobro.';
  }

  @override
  String membershipRegulationDemoNote(String programName) {
    return 'Ver/aceptar esto en la demostración no constituye una adhesión oficial al $programName.';
  }

  @override
  String get membershipStatusDemoBadge => 'Modo Socio — Demostración';

  @override
  String get membershipYourMembership => 'TU AFILIACIÓN';

  @override
  String get membershipYourBenefits => 'TUS BENEFICIOS';

  @override
  String get membershipGoToMemberArea => 'IR A MI ÁREA DE SOCIO';

  @override
  String get membershipBackToHome => 'Volver al inicio';

  @override
  String membershipWelcome(String programName) {
    return 'BIENVENIDO A\n$programName';
  }

  @override
  String membershipSuccessMessage(String club) {
    return 'Tu afiliación se completó con éxito.\nAhora estás aún más cerca del $club.';
  }

  @override
  String membershipAnnualPlan(String price) {
    return 'Plan anual • $price';
  }

  @override
  String get membershipHolder => 'Titular';

  @override
  String get membershipAssociatedSince => 'Socio desde';

  @override
  String get membershipStatusActive => 'Activo';

  @override
  String get membershipSeeAllBenefits => 'Ver todos los beneficios →';

  @override
  String get membershipWhatNow => '¿Y AHORA?';

  @override
  String get membershipWhatNowMessage =>
      'Tu área de socio ya está disponible. Sigue tu plan y tus beneficios y, cuando esté disponible, haz el check-in en los partidos.';

  @override
  String get membershipSituation => 'Situación';

  @override
  String get membershipMemberNumber => 'Número de socio';

  @override
  String get membershipMonthlyFee => 'Cuota mensual';

  @override
  String get membershipAnnualFee => 'Cuota anual';

  @override
  String get membershipMemberSince => 'Socio desde';

  @override
  String membershipRegulationName(String programName) {
    return 'Reglamento de $programName';
  }

  @override
  String get membershipMatchAccessNotice =>
      'Tu plan te da acceso a este partido.';

  @override
  String membershipCardNumber(String number) {
    return 'N.º $number';
  }

  @override
  String get membershipRegulationPageTitle => 'REGLAMENTO';

  @override
  String membershipRegulationEffectiveSince(String date) {
    return 'Vigente desde $date';
  }

  @override
  String get membershipRegulationTableOfContents => 'CONTENIDO';

  @override
  String membershipCancelWhatsapp(String plan, String programName) {
    return 'Hola, me gustaría cancelar mi afiliación $programName ($plan).';
  }

  @override
  String get membershipCancel => 'CANCELAR AFILIACIÓN';

  @override
  String get membershipCancelInfo =>
      'La cancelación se hace con atención por WhatsApp, sin multa fuera de los plazos previstos en el Reglamento.';

  @override
  String get membershipStatusPending => 'Pendiente';

  @override
  String get membershipStatusSuspended => 'Suspendido';

  @override
  String get membershipStatusCancelled => 'Cancelado';

  @override
  String get membershipFaqTitle => 'PREGUNTAS FRECUENTES';

  @override
  String get membershipFaqSubtitle =>
      'Encuentra respuestas sobre planes, pagos, check-in y beneficios.';

  @override
  String get membershipFaqLoadError =>
      'No se pudieron cargar las preguntas frecuentes.';

  @override
  String get membershipFaqNoResults => 'No se encontraron preguntas';

  @override
  String membershipFaqNoResultsMessage(String programName) {
    return 'Prueba otro término o contacta con la atención de $programName.';
  }

  @override
  String get membershipTalkToSupport => 'HABLAR CON ATENCIÓN';

  @override
  String get membershipTalkToSupportMenu => 'Hablar con atención';

  @override
  String get membershipDontStayInDoubt => 'NO TE QUEDES CON LA DUDA';

  @override
  String get membershipDidntFindAnswer =>
      '¿No encontraste la respuesta que buscabas?';

  @override
  String membershipFaqScopeNote(String programName) {
    return 'Las dudas sobre el club, las categorías inferiores, el plantel y otros temas fuera de $programName no se responden por este canal.';
  }

  @override
  String get membershipFaqAll => 'Todas';

  @override
  String get membershipFaqChipGeneral => 'General';

  @override
  String get membershipFaqChipPayment => 'Pago';

  @override
  String get membershipFaqChipSupport => 'Atención';

  @override
  String get membershipFaqChipActions => 'Acciones';

  @override
  String get membershipFaqChipStadium => 'Estadio';

  @override
  String get membershipFaqChipBenefits => 'Beneficios';

  @override
  String get membershipFaqChipPlans => 'Planes';

  @override
  String get membershipFaqChipFacial => 'Facial';

  @override
  String get membershipFaqChipRating => 'Rating';

  @override
  String get membershipFaqChipNoShow => 'No-Show';

  @override
  String get membershipStepAccess => 'Acceso';

  @override
  String get membershipStepPersonal => 'Registro';

  @override
  String get membershipStepAddress => 'Dirección';

  @override
  String get membershipFaqSearchHint => 'Buscar una pregunta...';

  @override
  String get membershipHelpTitle => 'AYUDA E INFORMACIÓN';

  @override
  String get membershipFaqMenuItem => 'Preguntas frecuentes';

  @override
  String get membershipFindCepTitle => 'ENCONTRAR MI CÓDIGO POSTAL';

  @override
  String get membershipFindCepSubtitle =>
      'Ingresa tu dirección y encontraremos el código postal correspondiente.';

  @override
  String get membershipStreetLabel => 'Calle / Dirección';

  @override
  String get membershipSearchCep => 'BUSCAR CÓDIGO POSTAL';

  @override
  String get membershipFoundAddresses => 'ENCONTRAMOS ESTAS DIRECCIONES';

  @override
  String get membershipNoAddressFound => 'No se encontró ninguna dirección.';

  @override
  String get membershipNoAddressHint =>
      'Revisa el estado, la ciudad y la calle que ingresaste.';

  @override
  String get membershipAddressSearchError => 'No se pudo buscar la dirección.';

  @override
  String get membershipValCpfRequired => 'Ingresa tu CPF.';

  @override
  String get membershipValNationality => 'Selecciona tu nacionalidad.';

  @override
  String get membershipValPassport => 'Ingresa un pasaporte válido.';

  @override
  String get membershipValContactEmail => 'Ingresa tu correo de contacto.';

  @override
  String get membershipValNameInvalid => 'Ingresa un nombre válido.';

  @override
  String get membershipValBirthRequired => 'Ingresa tu fecha de nacimiento.';

  @override
  String get membershipValBirthInvalid => 'Ingresa una fecha válida.';

  @override
  String get membershipValMinAge => 'El titular debe tener 18 años o más.';

  @override
  String get membershipValSelectOption => 'Selecciona una opción.';

  @override
  String get membershipValPhoneRequired => 'Ingresa tu celular.';

  @override
  String get membershipValPhoneInvalid => 'Ingresa un celular válido.';

  @override
  String get membershipValCountry => 'Selecciona el país.';

  @override
  String get membershipValCep8 => 'Ingresa un código postal de 8 dígitos.';

  @override
  String get membershipCepLookupError =>
      'No se pudo consultar el código postal.';

  @override
  String get membershipValStreet => 'Ingresa la calle.';

  @override
  String get membershipValNumber => 'Ingresa el número.';

  @override
  String get membershipValNeighborhood => 'Ingresa el barrio.';

  @override
  String get membershipValState => 'Ingresa el estado.';

  @override
  String get membershipValCity => 'Ingresa la ciudad.';

  @override
  String lineupShareStats(int solved, int total, int attempts, String time) {
    return '$solved/$total descubiertos · $attempts intentos · $time';
  }

  @override
  String crowdShareCrowd(String club) {
    return '¡Mira la alineación de la afición para el $club! 💚';
  }

  @override
  String crowdShareMine(String club) {
    return '¡Esta es mi alineación para el $club! 💚';
  }

  @override
  String get crowdSubmitted => '¡Alineación enviada!';

  @override
  String storeHomeEntryBadge(String storeName) {
    return '$storeName';
  }

  @override
  String get storeHomeEntryTitle => 'El manto te espera';

  @override
  String storeHomeEntryDescription(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'Lleva al Verdão contigo dentro y fuera de la cancha.',
      'other': 'Lleva al $club contigo dentro y fuera de la cancha.',
    });
    return '$_temp0';
  }

  @override
  String get storeHomeEntryCta => 'Conocer la tienda';

  @override
  String get storeProfileMyOrders => 'Mis pedidos';

  @override
  String get storeHomeLoadErrorTitle => 'No se pudo cargar la tienda';

  @override
  String get storeHomeEmptyTitle => 'Tienda en preparación';

  @override
  String get storeHomeEmptyMessage =>
      'Vuelve pronto para ver los productos oficiales.';

  @override
  String get storeMyPurchasesTitle => 'Mis Compras';

  @override
  String get storeSectionCategories => 'Categorías';

  @override
  String storeSearchHint(String storeName) {
    return 'Buscar en la $storeName';
  }

  @override
  String get storeListingDefaultTitle => 'Productos';

  @override
  String get storeSearchEmptyTitle => 'Busca productos';

  @override
  String get storeSearchEmptyMessage =>
      'Nombre, categoría, colección o tipo de prenda.';

  @override
  String get storeListingNoResultsTitle => 'Ningún producto encontrado';

  @override
  String get storeListingNoResultsMessage =>
      'Intenta ajustar tu búsqueda o quitar algunos filtros.';

  @override
  String storeListingProductCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count productos',
      one: '1 producto',
    );
    return '$_temp0';
  }

  @override
  String storeItemCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos',
      one: '1 artículo',
    );
    return '$_temp0';
  }

  @override
  String storeOrdersMoreItems(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count artículos',
      one: '+ 1 artículo',
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
  String get storeClearFilters => 'Borrar filtros';

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
  String get storeFilterSizeLabel => 'Talla';

  @override
  String get storeFilterOnlyAvailable => 'Solo disponibles';

  @override
  String get storeFilterOnlyOnSale => 'Solo en oferta';

  @override
  String get storeApplyFilters => 'Aplicar filtros';

  @override
  String get storeSortRelevance => 'Relevancia';

  @override
  String get storeSortNewest => 'Novedades';

  @override
  String get storeSortPriceLowToHigh => 'Menor precio';

  @override
  String get storeSortPriceHighToLow => 'Mayor precio';

  @override
  String get storeSortBiggestDiscount => 'Mayor descuento';

  @override
  String get storeAudienceMasculine => 'Hombre';

  @override
  String get storeAudienceFeminine => 'Mujer';

  @override
  String get storeAudienceKids => 'Niños';

  @override
  String get storeAudienceUnisex => 'Unisex';

  @override
  String get storeTypeMatchJersey => 'Partido';

  @override
  String get storeTypeGoalkeeper => 'Portero';

  @override
  String get storeTypeTraining => 'Entrenamiento';

  @override
  String get storeTypeCasual => 'Casual';

  @override
  String get storeTypeAccessory => 'Accesorio';

  @override
  String get storeTypeSouvenir => 'Recuerdo';

  @override
  String get storeCategoryLaunches => 'Novedades';

  @override
  String get storeCategoryUniforms => 'Camisetas';

  @override
  String get storeCategoryAccessories => 'Accesorios';

  @override
  String get storeCategorySouvenirs => 'Recuerdos';

  @override
  String get storeCategoryPersonalizable => 'Personalizables';

  @override
  String get storeCollectionFan => 'Aficionado';

  @override
  String get storeCollectionPlayer => 'Jugador';

  @override
  String get storeCollectionTrainingTravel =>
      'Entrenamiento, viaje y concentración';

  @override
  String get storeCollectionSocksGloves => 'Medias y guantes';

  @override
  String get storeShippingEconomyLabel => 'Económico';

  @override
  String get storeShippingStandardLabel => 'Estándar';

  @override
  String get storeShippingExpressLabel => 'Exprés';

  @override
  String get storeShippingEconomyEta => '7 a 10 días hábiles';

  @override
  String get storeShippingStandardEta => '4 a 7 días hábiles';

  @override
  String get storeShippingExpressEta => '2 a 3 días hábiles';

  @override
  String get storeBadgeSoldOut => 'Agotado';

  @override
  String get storeBadgeOnSale => 'Oferta';

  @override
  String storeInstallmentsLabel(Object count, Object value) {
    return 'hasta ${count}x de $value';
  }

  @override
  String get storeProductLoadErrorTitle => 'No se pudo cargar este producto';

  @override
  String get storeProductLoadErrorMessage => 'Vuelve e inténtalo de nuevo.';

  @override
  String get storeOrderCreateErrorTitle => 'No se pudo confirmar tu pedido';

  @override
  String get storeOrderCreateErrorMessage =>
      'Verifica tu conexión e inténtalo de nuevo. Tu bolsa sigue guardada.';

  @override
  String get storeBackToStoreButton => 'Volver a la tienda';

  @override
  String get storeProductSoldOut =>
      'Este producto está agotado por el momento.';

  @override
  String storeProductPhotoLabel(String name, int index, int total) {
    return '$name, foto $index de $total';
  }

  @override
  String get storeZoomImageHint => 'Toca para ampliar';

  @override
  String get storeShareProduct => 'Compartir producto';

  @override
  String get storeReferenceLabel => 'Ref.';

  @override
  String get storeDeliveryOrPickupLabel => 'Entrega o retiro';

  @override
  String get storePickupFreeNote => 'Retiro gratis';

  @override
  String get storeSizeLabel => 'Talla';

  @override
  String get storeQuantityLabel => 'Cantidad';

  @override
  String get storeDetailsLabel => 'Detalles';

  @override
  String get storePersonalizationLabel => 'Personalización (opcional)';

  @override
  String storePersonalizationNameField(Object price) {
    return 'Nombre en la camiseta (+ $price)';
  }

  @override
  String storePersonalizationNumberField(Object price) {
    return 'Número en la camiseta (+ $price)';
  }

  @override
  String storePersonalizationSurchargeNote(Object price) {
    return 'Recargo de personalización: $price';
  }

  @override
  String get storeAddedToCartSnackbar => 'Producto agregado a tu bolsa.';

  @override
  String get storeAddToCartButton => 'Agregar a la bolsa';

  @override
  String get storeSeeCartAction => 'Ver bolsa';

  @override
  String get storeChooseSizeMessage =>
      'Selecciona una talla antes de agregar a la bolsa.';

  @override
  String get storeBuyNowButton => 'Comprar ahora';

  @override
  String get storeVariationSoldOut => 'Esta variación está agotada.';

  @override
  String get storeCartTitle => 'BOLSA';

  @override
  String get storeCartEmptyTitle => 'Tu bolsa está vacía';

  @override
  String storeCartEmptyMessage(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'Elige tus productos oficiales y lleva al Verdão contigo.',
      'other': 'Elige tus productos oficiales y lleva al $club contigo.',
    });
    return '$_temp0';
  }

  @override
  String storeCartEmptyCta(String storeName) {
    return 'Ir a la $storeName';
  }

  @override
  String storeCartItemSize(Object size) {
    return 'Talla $size';
  }

  @override
  String storeCartItemNumber(Object number) {
    return 'n.º $number';
  }

  @override
  String get storeRemoveItemTitle => 'Quitar artículo';

  @override
  String storeRemoveItemMessage(Object productName) {
    return '¿Quitar \"$productName\" de la bolsa?';
  }

  @override
  String storeRemoveItemAction(Object productName) {
    return 'Quitar $productName de la bolsa';
  }

  @override
  String get storeRemove => 'Quitar';

  @override
  String get storeCouponHint => 'Código de descuento';

  @override
  String get storeCouponApply => 'Aplicar';

  @override
  String get storeCouponInvalid => 'Código inválido o vencido.';

  @override
  String get storeCheckoutCta => 'Finalizar compra';

  @override
  String get storeSubtotal => 'Subtotal';

  @override
  String get storeDiscountGeneric => 'Descuento';

  @override
  String storeDiscountLabel(Object code) {
    return 'Descuento ($code)';
  }

  @override
  String get storeTotal => 'Total';

  @override
  String storeFreeShippingNote(Object amount) {
    return 'Envío gratis a partir de $amount.';
  }

  @override
  String get storeFree => 'Gratis';

  @override
  String get storeShippingLabel => 'Envío';

  @override
  String get storePickupWord => 'Retiro';

  @override
  String get storeStepIdentification => 'Identificación';

  @override
  String get storeStepDelivery => 'Entrega';

  @override
  String get storeStepPayment => 'Pago';

  @override
  String get storeStepReview => 'Revisión';

  @override
  String get storeContinueButton => 'Continuar';

  @override
  String get storeFullNameLabel => 'Nombre completo';

  @override
  String get storeCpfLabel => 'CPF';

  @override
  String get storePhoneLabel => 'Teléfono / WhatsApp';

  @override
  String get storeDeliveryToHome => 'Recibir en casa';

  @override
  String get storePickupAtStore => 'Retirar en la tienda';

  @override
  String get storeDeliveryAddressLabel => 'Dirección de entrega';

  @override
  String get storeAddAddress => 'Agregar dirección';

  @override
  String storeZipCodePrefix(Object zip) {
    return 'CP $zip';
  }

  @override
  String get storePickupResponsibleLabel => 'Quién va a retirar';

  @override
  String get storePickupSelf => 'Yo mismo';

  @override
  String get storePickupOther => 'Otra persona';

  @override
  String get storePickupResponsibleNameField => 'Nombre de quien va a retirar';

  @override
  String get storePickupResponsibleCpfField => 'CPF de quien va a retirar';

  @override
  String get storePickupSectionTitle => 'Retiro en tienda';

  @override
  String get storePickupBySelf => 'Retiro por el propio titular';

  @override
  String storePickupByOther(Object name) {
    return 'Retiro por $name';
  }

  @override
  String storePickupAddressPrefix(Object address) {
    return 'Retirar en: $address';
  }

  @override
  String get storePaymentPix => 'Pix';

  @override
  String get storeCreditCard => 'Tarjeta de crédito';

  @override
  String get storeDemoDisclaimer =>
      'Entorno de demostración. No se realizará ningún cobro.';

  @override
  String get storeQrCodeNote =>
      'Código QR simulado — escanéalo en la app de tu banco.';

  @override
  String get storeSimulatePixButton => 'Simular pago con Pix';

  @override
  String get storePixApproved => 'Pago con Pix simulado con éxito.';

  @override
  String get storeCardNumberLabel => 'Número de la tarjeta';

  @override
  String get storeCardHolderLabel => 'Nombre impreso en la tarjeta';

  @override
  String get storeCardExpiryLabel => 'Vencimiento (MM/AA)';

  @override
  String get storeCardCvvLabel => 'CVV';

  @override
  String get storeInstallmentsFieldLabel => 'Cuotas';

  @override
  String storeInstallmentsCash(Object price) {
    return 'Al contado — $price';
  }

  @override
  String storeInstallmentsNoInterest(Object count, Object price) {
    return '${count}x de $price sin intereses';
  }

  @override
  String get storeSimulatePaymentButton => 'Simular pago';

  @override
  String get storeCardApprovedGeneric => 'Tarjeta aprobada (simulado).';

  @override
  String storeCardApprovedWithDigits(Object digits) {
    return 'Tarjeta terminada en $digits aprobada (simulado).';
  }

  @override
  String storeCardFinalDigits(Object digits) {
    return 'Tarjeta de crédito terminada en $digits';
  }

  @override
  String storeCardSummaryLine(Object digits, Object installments) {
    return 'Tarjeta de crédito terminada en $digits · ${installments}x';
  }

  @override
  String get storeConfirmOrderButton => 'Confirmar pedido';

  @override
  String get storeEdit => 'Editar';

  @override
  String storeAcceptTerms(String storeName) {
    return 'Leí y acepto los términos de compra de la $storeName.';
  }

  @override
  String get storeOrderConfirmedTitle => '¡Pedido confirmado!';

  @override
  String get storeItemsLabel => 'Artículos';

  @override
  String storeItemsCountLabel(Object count) {
    return 'Artículos ($count)';
  }

  @override
  String get storeTrackOrderButton => 'Seguir pedido';

  @override
  String get storeContinueShoppingButton => 'Seguir comprando';

  @override
  String get storeBackHomeButton => 'Volver al inicio';

  @override
  String get storeOrdersTitle => 'MIS PEDIDOS';

  @override
  String get storeOrdersEmptyTitle => 'Todavía no has hecho ningún pedido';

  @override
  String storeOrdersEmptyMessage(String storeName) {
    return 'Tus pedidos de la $storeName aparecerán aquí.';
  }

  @override
  String get storeOrdersLoadError => 'No se pudieron cargar tus pedidos';

  @override
  String get storeOrderCancelled => 'Pedido cancelado';

  @override
  String get storeCustomerLabel => 'Cliente';

  @override
  String get storeStatusStepDone => 'completado';

  @override
  String get storeStatusStepPending => 'pendiente';

  @override
  String get storeStatusCreated => 'Pedido realizado';

  @override
  String get storeStatusPaymentPending => 'Esperando pago';

  @override
  String get storeStatusPaid => 'Pago aprobado';

  @override
  String get storeStatusPreparing => 'En preparación';

  @override
  String get storeStatusReadyForPickup => 'Listo para retirar';

  @override
  String get storeStatusShipped => 'Enviado';

  @override
  String get storeStatusDeliveredPickup => 'Retirado';

  @override
  String get storeStatusDeliveredShipping => 'Entregado';

  @override
  String get storeStatusCancelled => 'Cancelado';

  @override
  String get storeAddressesTitle => 'DIRECCIONES DE ENTREGA';

  @override
  String get storeAddressesSubtitle =>
      'Elige dónde deseas recibir tus pedidos.';

  @override
  String get storeAddressesEmptyTitle => 'Ninguna dirección guardada';

  @override
  String get storeAddressesEmptyMessage =>
      'Agrega una dirección para agilizar tus próximas compras.';

  @override
  String get storeRemoveAddressTitle => 'Quitar dirección';

  @override
  String storeRemoveAddressMessage(Object address) {
    return '¿Quitar \"$address\"?';
  }

  @override
  String get storeDefaultBadge => 'PREDETERMINADA';

  @override
  String get storeMakeDefault => 'Hacer predeterminada';

  @override
  String get storeNewAddressTitle => 'NUEVA DIRECCIÓN';

  @override
  String get storeEditAddressTitle => 'EDITAR DIRECCIÓN';

  @override
  String get storeZipCodeLabel => 'Código postal';

  @override
  String get storeStreetLabel => 'Calle';

  @override
  String get storeNumberLabel => 'Número';

  @override
  String get storeComplementLabel => 'Complemento (opcional)';

  @override
  String get storeNeighborhoodLabel => 'Barrio';

  @override
  String get storeCityLabel => 'Ciudad';

  @override
  String get storeStateLabel => 'Estado';

  @override
  String get storeSaveAddressButton => 'Guardar dirección';

  @override
  String get storeAddressLabelField => 'Apodo (opcional)';

  @override
  String get storeAddressLabelHint => 'Ej.: Casa, Trabajo';

  @override
  String get storeUseResidentialAddress => 'Usar mi dirección residencial';

  @override
  String get storeDeliveryAddressSummaryTitle => 'DIRECCIÓN DE ENTREGA';

  @override
  String get storeChangeAddressButton => 'Cambiar';

  @override
  String get storeChooseDeliveryAddressTitle => 'ELIGE DÓNDE RECIBIR';

  @override
  String get storeNoDeliveryAddressTitle =>
      'Todavía no tienes una dirección de entrega.';

  @override
  String get storeAddAnotherAddress => 'Agregar otra dirección';

  @override
  String get storeValFullNameRequired => 'Ingresa tu nombre completo.';

  @override
  String get storeValFullNameIncomplete => 'Ingresa tu nombre y apellido.';

  @override
  String get storeValPhoneInvalid => 'Teléfono inválido.';

  @override
  String get storeValCpfRequired => 'Ingresa el CPF.';

  @override
  String get storeValCpfInvalid => 'CPF inválido.';

  @override
  String get storeValZipInvalid => 'Código postal inválido.';

  @override
  String get releaseGateTitle => 'Actualización necesaria';

  @override
  String get releaseGateMessage =>
      'Esta versión de la app ya no es compatible. Actualiza para continuar.';

  @override
  String get releaseGateUpdateButton => 'Actualizar ahora';

  @override
  String tacticalQ01(String club) {
    return 'El rival presiona tu salida y cierra los pases cortos. ¿Qué hace tu $club?';
  }

  @override
  String get tacticalQ01A =>
      'Sigue saliendo en corto, atrayendo la presión hasta encontrar al hombre libre.';

  @override
  String get tacticalQ01B =>
      'Intenta salir en corto, pero si la presión aprieta busca enseguida el espacio a la espalda.';

  @override
  String get tacticalQ01C =>
      'Va directo al delantero o al carril y prepara al equipo para ganar la segunda pelota.';

  @override
  String get tacticalQ01D =>
      'Detecta dónde la presión rival es más frágil y sale por ahí, en corto o en largo.';

  @override
  String get tacticalQ02 =>
      'Tu equipo recupera en el mediocampo con el rival todavía desordenado. ¿Cuál es la primera idea?';

  @override
  String get tacticalQ02A =>
      'Retiene la pelota, junta al equipo y arma el ataque.';

  @override
  String get tacticalQ02B =>
      'Busca el pase hacia adelante si hay ventaja; si no la hay, conserva la posesión.';

  @override
  String get tacticalQ02C =>
      'Acelera de inmediato e intenta llegar al gol en pocos pases.';

  @override
  String get tacticalQ02D =>
      'Decide según dónde están los rivales y quién tiene superioridad en esa jugada.';

  @override
  String tacticalQ03(String club) {
    return 'El $club gana 1 a 0 como visitante a los 75 minutos.';
  }

  @override
  String get tacticalQ03A =>
      'No cambia nada. Si el plan dio la ventaja, el plan sigue.';

  @override
  String get tacticalQ03B =>
      'Pasa a controlar con más posesión y hace correr al rival detrás de la pelota.';

  @override
  String get tacticalQ03C =>
      'Cierra mejor los espacios y prepara transiciones para liquidar el partido.';

  @override
  String get tacticalQ03D =>
      'Sigue presionando y va por el segundo antes de que el rival crezca.';

  @override
  String get tacticalQ04 =>
      'El rival se plantó con dos líneas cerca de su área. ¿Cómo rompes el bloque?';

  @override
  String get tacticalQ04A =>
      'Circula con paciencia hasta que aparezca el espacio justo.';

  @override
  String get tacticalQ04B =>
      'Cambia posiciones y genera superioridad entre líneas o por afuera.';

  @override
  String get tacticalQ04C =>
      'Sube el ritmo: centros, profundidad y disputa de rebotes.';

  @override
  String get tacticalQ04D =>
      'Mete más presencia en el área y cambia el camino del ataque según reaccione la defensa.';

  @override
  String get tacticalQ05 =>
      'Visitas a un rival claramente superior con la pelota.';

  @override
  String get tacticalQ05A =>
      'Mantiene su propuesta de control y salida jugada; así juega este equipo.';

  @override
  String get tacticalQ05B =>
      'Sigue queriendo la pelota, pero ajusta la presión y la posición al rival.';

  @override
  String get tacticalQ05C =>
      'Acepta tener menos posesión, protege los espacios y prioriza la transición.';

  @override
  String get tacticalQ05D =>
      'Presiona alto y ataca rápido, aun asumiendo el riesgo.';

  @override
  String get tacticalQ06 =>
      'Tu mejor jugador define partidos, pero casi no vuelve a marcar. ¿Qué haces?';

  @override
  String get tacticalQ06A =>
      'El modelo va primero; si no cumple la función, puede perder el puesto.';

  @override
  String get tacticalQ06B =>
      'Le cambia la función para conservar el talento sin desequilibrar al equipo.';

  @override
  String get tacticalQ06C =>
      'Reordena a los compañeros para compensar y lo deja arriba, en zona de ataque.';

  @override
  String get tacticalQ06D =>
      'Le da libertad. A los jugadores especiales se los trata de manera especial.';

  @override
  String tacticalQ07(String club) {
    return 'Entretiempo. El $club pierde 1 a 0, pero juega bien y genera ocasiones.';
  }

  @override
  String get tacticalQ07A =>
      'No toca nada. El plan funciona y el gol va a llegar.';

  @override
  String get tacticalQ07B =>
      'Hace pequeños ajustes de posición sin abandonar la idea inicial.';

  @override
  String get tacticalQ07C =>
      'Suma profundidad u otro delantero y empieza a llegar más rápido.';

  @override
  String get tacticalQ07D =>
      'Acelera la circulación y pone más jugadores entre líneas.';

  @override
  String get tacticalQ08 =>
      'Tu equipo pierde la pelota cerca del área rival. ¿Qué reacción esperas?';

  @override
  String get tacticalQ08A =>
      'Presión inmediata para recuperarla ahí mismo, sea quien sea el rival.';

  @override
  String get tacticalQ08B =>
      'Presiona si hay suficientes jugadores cerca; si no, se reordena.';

  @override
  String get tacticalQ08C =>
      'Primero rearma el bloque y cierra el centro del campo.';

  @override
  String get tacticalQ08D =>
      'Corta la transición para que el rival nunca llegue a acelerar.';

  @override
  String tacticalQ09(String club) {
    return 'Faltan diez minutos y el $club necesita un gol.';
  }

  @override
  String get tacticalQ09A =>
      'Mantiene la construcción paciente. El desorden no es una solución.';

  @override
  String get tacticalQ09B =>
      'Pone jugadores más ofensivos, pero mantiene la pelota abajo y la estructura.';

  @override
  String get tacticalQ09C =>
      'Se instala en campo rival, juega más directo y ataca primera y segunda pelota.';

  @override
  String get tacticalQ09D =>
      'Cambia el dibujo y alterna ataques cortos y directos según el espacio que den.';

  @override
  String get tacticalQ10 =>
      '¿Qué frase representa mejor tu manera de pensar el fútbol?';

  @override
  String get tacticalQ10A =>
      'Primero está nuestra manera de jugar; después pensamos en el rival.';

  @override
  String get tacticalQ10B =>
      'Los principios se mantienen, pero el esquema y la estrategia pueden cambiar.';

  @override
  String get tacticalQ10C =>
      'Llegar rápido al gol vale más que tener la pelota por tenerla.';

  @override
  String get tacticalQ10D =>
      'El mejor fútbol es el que potencia a nuestros jugadores y ataca las debilidades del rival.';
}
