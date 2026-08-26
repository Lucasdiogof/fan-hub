// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get settingsLanguageTitle => 'LANGUAGE';

  @override
  String get settingsLanguageMenu => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose the app language';

  @override
  String get languageSystemLabel => 'System default';

  @override
  String get languageSystemDescription => 'Follows your device language';

  @override
  String get commonEmailLabel => 'Email';

  @override
  String get commonEmailHint => 'youremail@email.com';

  @override
  String get commonPasswordLabel => 'Password';

  @override
  String get authTagline =>
      'Follow everything about the biggest club in the Central-West';

  @override
  String get authRegisterSubtitle =>
      'Follow everything about the biggest club in the Central-West.';

  @override
  String get authForgotPassword => 'Forgot password';

  @override
  String get authSignInButton => 'SIGN IN';

  @override
  String get authSigningIn => 'Signing in...';

  @override
  String get authNoAccountQuestion => 'Don\'t have an account yet? ';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authFullNameLabel => 'Full name';

  @override
  String get authFullNameHint => 'Your name';

  @override
  String authPasswordMinHint(int count) {
    return 'At least $count characters';
  }

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authConfirmPasswordHint => 'Repeat the password';

  @override
  String get authRegisterButton => 'CREATE ACCOUNT';

  @override
  String get authCreatingAccount => 'Creating...';

  @override
  String get authTermsPrefix => 'I have read and accept the ';

  @override
  String get authTermsLink => 'Terms of Use';

  @override
  String get authTermsConnector => ' and the ';

  @override
  String get authPrivacyLink => 'Privacy Policy';

  @override
  String get authTermsSuffix => '.';
}
