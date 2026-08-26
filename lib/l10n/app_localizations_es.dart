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
}
