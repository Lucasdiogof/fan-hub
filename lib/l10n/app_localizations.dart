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

  /// No description provided for @navHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navHome;

  /// No description provided for @navMatches.
  ///
  /// In pt, this message translates to:
  /// **'Jogos'**
  String get navMatches;

  /// No description provided for @navMembership.
  ///
  /// In pt, this message translates to:
  /// **'Sócio'**
  String get navMembership;

  /// No description provided for @navMedia.
  ///
  /// In pt, this message translates to:
  /// **'Mídia'**
  String get navMedia;

  /// No description provided for @navArena.
  ///
  /// In pt, this message translates to:
  /// **'Arena'**
  String get navArena;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In pt, this message translates to:
  /// **'Bom dia'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In pt, this message translates to:
  /// **'Boa tarde'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In pt, this message translates to:
  /// **'Boa noite'**
  String get homeGreetingEvening;

  /// No description provided for @homeNextMatch.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMO JOGO'**
  String get homeNextMatch;

  /// No description provided for @homeDateToBeConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'DATA A CONFIRMAR'**
  String get homeDateToBeConfirmed;

  /// No description provided for @homeMatchDetails.
  ///
  /// In pt, this message translates to:
  /// **'DETALHES DO JOGO'**
  String get homeMatchDetails;

  /// No description provided for @homeTickets.
  ///
  /// In pt, this message translates to:
  /// **'INGRESSOS'**
  String get homeTickets;

  /// No description provided for @homeCountdownTitle.
  ///
  /// In pt, this message translates to:
  /// **'O JOGO COMEÇA EM'**
  String get homeCountdownTitle;

  /// No description provided for @homeCountdownDays.
  ///
  /// In pt, this message translates to:
  /// **'DIAS'**
  String get homeCountdownDays;

  /// No description provided for @homeCountdownHours.
  ///
  /// In pt, this message translates to:
  /// **'HORAS'**
  String get homeCountdownHours;

  /// No description provided for @homeCountdownMinutes.
  ///
  /// In pt, this message translates to:
  /// **'MIN'**
  String get homeCountdownMinutes;

  /// No description provided for @homeCountdownSeconds.
  ///
  /// In pt, this message translates to:
  /// **'SEG'**
  String get homeCountdownSeconds;

  /// No description provided for @homeMembershipPitch.
  ///
  /// In pt, this message translates to:
  /// **'Esteja ainda mais perto do Goiás\ne faça parte dessa história!'**
  String get homeMembershipPitch;

  /// No description provided for @homeMembershipBenefit1.
  ///
  /// In pt, this message translates to:
  /// **'Prioridade de acesso ao estádio'**
  String get homeMembershipBenefit1;

  /// No description provided for @homeMembershipBenefit2.
  ///
  /// In pt, this message translates to:
  /// **'Economia no valor do ingresso'**
  String get homeMembershipBenefit2;

  /// No description provided for @homeMembershipBenefit3.
  ///
  /// In pt, this message translates to:
  /// **'Descontos exclusivos e muito mais'**
  String get homeMembershipBenefit3;

  /// No description provided for @homeMembershipCta.
  ///
  /// In pt, this message translates to:
  /// **'SEJA SÓCIO ESMERALDINO'**
  String get homeMembershipCta;

  /// No description provided for @matchGamesTitle.
  ///
  /// In pt, this message translates to:
  /// **'JOGOS'**
  String get matchGamesTitle;

  /// No description provided for @matchTabMatches.
  ///
  /// In pt, this message translates to:
  /// **'PARTIDAS'**
  String get matchTabMatches;

  /// No description provided for @matchTabStandings.
  ///
  /// In pt, this message translates to:
  /// **'CLASSIFICAÇÃO'**
  String get matchTabStandings;

  /// No description provided for @matchLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os jogos'**
  String get matchLoadError;

  /// No description provided for @matchNoMatches.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma partida encontrada.'**
  String get matchNoMatches;

  /// No description provided for @matchDetailsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a partida.'**
  String get matchDetailsLoadError;

  /// No description provided for @matchBuyTicket.
  ///
  /// In pt, this message translates to:
  /// **'COMPRAR INGRESSO'**
  String get matchBuyTicket;

  /// No description provided for @matchDetailsShort.
  ///
  /// In pt, this message translates to:
  /// **'DETALHES'**
  String get matchDetailsShort;

  /// No description provided for @matchDateToBeConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Data a confirmar'**
  String get matchDateToBeConfirmed;

  /// No description provided for @matchToBeConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'A confirmar'**
  String get matchToBeConfirmed;

  /// No description provided for @matchInfoTitle.
  ///
  /// In pt, this message translates to:
  /// **'INFORMAÇÕES'**
  String get matchInfoTitle;

  /// No description provided for @matchFieldDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get matchFieldDate;

  /// No description provided for @matchFieldTime.
  ///
  /// In pt, this message translates to:
  /// **'Horário'**
  String get matchFieldTime;

  /// No description provided for @matchFieldStadium.
  ///
  /// In pt, this message translates to:
  /// **'Estádio'**
  String get matchFieldStadium;

  /// No description provided for @matchFieldCity.
  ///
  /// In pt, this message translates to:
  /// **'Cidade'**
  String get matchFieldCity;

  /// No description provided for @matchFieldCompetition.
  ///
  /// In pt, this message translates to:
  /// **'Competição'**
  String get matchFieldCompetition;

  /// No description provided for @matchFieldRound.
  ///
  /// In pt, this message translates to:
  /// **'Rodada'**
  String get matchFieldRound;

  /// No description provided for @matchFieldStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get matchFieldStatus;

  /// No description provided for @matchEventsTitle.
  ///
  /// In pt, this message translates to:
  /// **'EVENTOS DA PARTIDA'**
  String get matchEventsTitle;

  /// No description provided for @matchEventGoal.
  ///
  /// In pt, this message translates to:
  /// **'Gol'**
  String get matchEventGoal;

  /// No description provided for @matchEventCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão'**
  String get matchEventCard;

  /// No description provided for @matchEventSubstitution.
  ///
  /// In pt, this message translates to:
  /// **'{playerIn} entra no lugar de {playerOut}'**
  String matchEventSubstitution(String playerIn, String playerOut);

  /// No description provided for @matchLineupsTitle.
  ///
  /// In pt, this message translates to:
  /// **'ESCALAÇÕES'**
  String get matchLineupsTitle;

  /// No description provided for @standingsClub.
  ///
  /// In pt, this message translates to:
  /// **'CLUBE'**
  String get standingsClub;

  /// No description provided for @standingsColPoints.
  ///
  /// In pt, this message translates to:
  /// **'P'**
  String get standingsColPoints;

  /// No description provided for @standingsColPlayed.
  ///
  /// In pt, this message translates to:
  /// **'J'**
  String get standingsColPlayed;

  /// No description provided for @standingsColWins.
  ///
  /// In pt, this message translates to:
  /// **'V'**
  String get standingsColWins;

  /// No description provided for @standingsColGoalDiff.
  ///
  /// In pt, this message translates to:
  /// **'SG'**
  String get standingsColGoalDiff;

  /// No description provided for @standingsUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Classificação indisponível no momento.'**
  String get standingsUnavailable;

  /// No description provided for @matchStatusScheduled.
  ///
  /// In pt, this message translates to:
  /// **'Agendada'**
  String get matchStatusScheduled;

  /// No description provided for @matchStatusLive.
  ///
  /// In pt, this message translates to:
  /// **'Ao vivo'**
  String get matchStatusLive;

  /// No description provided for @matchStatusHalfTime.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo'**
  String get matchStatusHalfTime;

  /// No description provided for @matchStatusFinished.
  ///
  /// In pt, this message translates to:
  /// **'Encerrada'**
  String get matchStatusFinished;

  /// No description provided for @matchStatusPostponed.
  ///
  /// In pt, this message translates to:
  /// **'Adiada'**
  String get matchStatusPostponed;

  /// No description provided for @matchStatusCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelada'**
  String get matchStatusCancelled;

  /// No description provided for @matchStatusSuspended.
  ///
  /// In pt, this message translates to:
  /// **'Suspensa'**
  String get matchStatusSuspended;

  /// No description provided for @matchStatusUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Indefinido'**
  String get matchStatusUnknown;
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
