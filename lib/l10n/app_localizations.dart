import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// Nome deste idioma, exibido no seletor de idioma.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get languageName;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In pt, this message translates to:
  /// **'IDIOMA'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageMenu.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settingsLanguageMenu;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o idioma do aplicativo'**
  String get settingsLanguageSubtitle;

  /// No description provided for @languageSystemLabel.
  ///
  /// In pt, this message translates to:
  /// **'Padrão do sistema'**
  String get languageSystemLabel;

  /// No description provided for @languageSystemDescription.
  ///
  /// In pt, this message translates to:
  /// **'Segue o idioma do seu aparelho'**
  String get languageSystemDescription;

  /// No description provided for @commonEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get commonEmailLabel;

  /// No description provided for @commonEmailHint.
  ///
  /// In pt, this message translates to:
  /// **'seuemail@email.com'**
  String get commonEmailHint;

  /// No description provided for @commonPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get commonPasswordLabel;

  /// No description provided for @authTagline.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe tudo sobre o maior do Centro-Oeste'**
  String get authTagline;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe tudo sobre o maior do Centro-Oeste.'**
  String get authRegisterSubtitle;

  /// No description provided for @authForgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci a senha'**
  String get authForgotPassword;

  /// No description provided for @authSignInButton.
  ///
  /// In pt, this message translates to:
  /// **'ENTRAR'**
  String get authSignInButton;

  /// No description provided for @authSigningIn.
  ///
  /// In pt, this message translates to:
  /// **'Entrando...'**
  String get authSigningIn;

  /// No description provided for @authNoAccountQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não possui uma conta? '**
  String get authNoAccountQuestion;

  /// No description provided for @authCreateAccount.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get authCreateAccount;

  /// No description provided for @authRegisterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get authRegisterTitle;

  /// No description provided for @authFullNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo'**
  String get authFullNameLabel;

  /// No description provided for @authFullNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Seu nome'**
  String get authFullNameHint;

  /// No description provided for @authPasswordMinHint.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo {count} caracteres'**
  String authPasswordMinHint(int count);

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar senha'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Repita a senha'**
  String get authConfirmPasswordHint;

  /// No description provided for @authRegisterButton.
  ///
  /// In pt, this message translates to:
  /// **'CRIAR CONTA'**
  String get authRegisterButton;

  /// No description provided for @authCreatingAccount.
  ///
  /// In pt, this message translates to:
  /// **'Criando...'**
  String get authCreatingAccount;

  /// No description provided for @authTermsPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Li e aceito os '**
  String get authTermsPrefix;

  /// No description provided for @authTermsLink.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso'**
  String get authTermsLink;

  /// No description provided for @authTermsConnector.
  ///
  /// In pt, this message translates to:
  /// **' e a '**
  String get authTermsConnector;

  /// No description provided for @authPrivacyLink.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get authPrivacyLink;

  /// No description provided for @authTermsSuffix.
  ///
  /// In pt, this message translates to:
  /// **'.'**
  String get authTermsSuffix;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
