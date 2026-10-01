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

  /// No description provided for @authSignInErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível entrar'**
  String get authSignInErrorTitle;

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
  /// **'CRIAR MINHA CONTA'**
  String get authRegisterButton;

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

  /// No description provided for @authStepPersonal.
  ///
  /// In pt, this message translates to:
  /// **'Seus dados'**
  String get authStepPersonal;

  /// No description provided for @authStepContact.
  ///
  /// In pt, this message translates to:
  /// **'Contato'**
  String get authStepContact;

  /// No description provided for @authStepSecurity.
  ///
  /// In pt, this message translates to:
  /// **'Segurança'**
  String get authStepSecurity;

  /// No description provided for @authMarketingOptIn.
  ///
  /// In pt, this message translates to:
  /// **'Quero receber novidades, promoções e informações do {clubShortName}'**
  String authMarketingOptIn(String clubShortName);

  /// No description provided for @authPasswordRequirementLength.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo de {count} caracteres'**
  String authPasswordRequirementLength(int count);

  /// No description provided for @authCpfLabel.
  ///
  /// In pt, this message translates to:
  /// **'CPF'**
  String get authCpfLabel;

  /// No description provided for @authBirthDateHint.
  ///
  /// In pt, this message translates to:
  /// **'DD/MM/AAAA'**
  String get authBirthDateHint;

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

  /// No description provided for @navStore.
  ///
  /// In pt, this message translates to:
  /// **'Loja'**
  String get navStore;

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

  /// No description provided for @homeCompactMatchToday.
  ///
  /// In pt, this message translates to:
  /// **'HOJE'**
  String get homeCompactMatchToday;

  /// No description provided for @homeCompactMatchFinished.
  ///
  /// In pt, this message translates to:
  /// **'Fim de jogo'**
  String get homeCompactMatchFinished;

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

  /// No description provided for @matchTabCalendar.
  ///
  /// In pt, this message translates to:
  /// **'CALENDÁRIO'**
  String get matchTabCalendar;

  /// No description provided for @matchTabStandings.
  ///
  /// In pt, this message translates to:
  /// **'CLASSIFICAÇÃO'**
  String get matchTabStandings;

  /// No description provided for @matchCalendarHome.
  ///
  /// In pt, this message translates to:
  /// **'CASA'**
  String get matchCalendarHome;

  /// No description provided for @matchCalendarAway.
  ///
  /// In pt, this message translates to:
  /// **'FORA'**
  String get matchCalendarAway;

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
  /// **'DETALHES DO JOGO'**
  String get matchDetailsShort;

  /// No description provided for @matchFollowLive.
  ///
  /// In pt, this message translates to:
  /// **'ACOMPANHAR JOGO'**
  String get matchFollowLive;

  /// No description provided for @matchViewDetails.
  ///
  /// In pt, this message translates to:
  /// **'VER DETALHES'**
  String get matchViewDetails;

  /// No description provided for @matchFinishedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Finalizado'**
  String get matchFinishedLabel;

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

  /// No description provided for @matchStatsTitle.
  ///
  /// In pt, this message translates to:
  /// **'ESTATÍSTICAS'**
  String get matchStatsTitle;

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

  /// No description provided for @otherCompetitionsCta.
  ///
  /// In pt, this message translates to:
  /// **'Ver outros campeonatos'**
  String get otherCompetitionsCta;

  /// No description provided for @otherCompetitionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Campeonatos'**
  String get otherCompetitionsTitle;

  /// No description provided for @otherCompetitionsSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar campeonato'**
  String get otherCompetitionsSearchHint;

  /// No description provided for @otherCompetitionsYourCompetitions.
  ///
  /// In pt, this message translates to:
  /// **'SUAS COMPETIÇÕES'**
  String get otherCompetitionsYourCompetitions;

  /// No description provided for @otherCompetitionsSearchEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum campeonato encontrado.'**
  String get otherCompetitionsSearchEmpty;

  /// No description provided for @knockoutFirstLeg.
  ///
  /// In pt, this message translates to:
  /// **'Ida'**
  String get knockoutFirstLeg;

  /// No description provided for @knockoutSecondLeg.
  ///
  /// In pt, this message translates to:
  /// **'Volta'**
  String get knockoutSecondLeg;

  /// No description provided for @knockoutAggregateShort.
  ///
  /// In pt, this message translates to:
  /// **'Placar'**
  String get knockoutAggregateShort;

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

  /// No description provided for @matchCurrentRound.
  ///
  /// In pt, this message translates to:
  /// **'Rodada atual'**
  String get matchCurrentRound;

  /// No description provided for @commonSave.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR'**
  String get commonSave;

  /// No description provided for @commonSaving.
  ///
  /// In pt, this message translates to:
  /// **'Salvando...'**
  String get commonSaving;

  /// No description provided for @commonCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonContinue.
  ///
  /// In pt, this message translates to:
  /// **'CONTINUAR'**
  String get commonContinue;

  /// No description provided for @commonDemoTag.
  ///
  /// In pt, this message translates to:
  /// **'Demonstração'**
  String get commonDemoTag;

  /// No description provided for @commonDemoBannerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Demonstração'**
  String get commonDemoBannerTitle;

  /// No description provided for @profileTitle.
  ///
  /// In pt, this message translates to:
  /// **'PERFIL'**
  String get profileTitle;

  /// No description provided for @profileMyAccount.
  ///
  /// In pt, this message translates to:
  /// **'MINHA CONTA'**
  String get profileMyAccount;

  /// No description provided for @profilePersonalData.
  ///
  /// In pt, this message translates to:
  /// **'Dados pessoais'**
  String get profilePersonalData;

  /// No description provided for @profileMyAddress.
  ///
  /// In pt, this message translates to:
  /// **'Endereço residencial'**
  String get profileMyAddress;

  /// No description provided for @profileDeliveryAddresses.
  ///
  /// In pt, this message translates to:
  /// **'Endereços de entrega'**
  String get profileDeliveryAddresses;

  /// No description provided for @profileSecurity.
  ///
  /// In pt, this message translates to:
  /// **'Segurança'**
  String get profileSecurity;

  /// No description provided for @profileAppearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get profileAppearance;

  /// No description provided for @profileNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get profileNotifications;

  /// No description provided for @profileMyJourney.
  ///
  /// In pt, this message translates to:
  /// **'MINHA JORNADA'**
  String get profileMyJourney;

  /// No description provided for @profilePreferences.
  ///
  /// In pt, this message translates to:
  /// **'PREFERÊNCIAS'**
  String get profilePreferences;

  /// No description provided for @profilePurchasesAndServices.
  ///
  /// In pt, this message translates to:
  /// **'COMPRAS E SERVIÇOS'**
  String get profilePurchasesAndServices;

  /// No description provided for @profileMyTickets.
  ///
  /// In pt, this message translates to:
  /// **'Meus ingressos'**
  String get profileMyTickets;

  /// No description provided for @profileVersion.
  ///
  /// In pt, this message translates to:
  /// **'Versão {version}'**
  String profileVersion(Object version);

  /// No description provided for @profileLegal.
  ///
  /// In pt, this message translates to:
  /// **'LEGAL'**
  String get profileLegal;

  /// No description provided for @profileAccount.
  ///
  /// In pt, this message translates to:
  /// **'CONTA'**
  String get profileAccount;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta?'**
  String get profileDeleteConfirmTitle;

  /// No description provided for @profileDeleteConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Ao excluir sua conta, seus dados e seu progresso serão removidos permanentemente. Essa ação não pode ser desfeita.'**
  String get profileDeleteConfirmMessage;

  /// No description provided for @profileSignOutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sair da conta?'**
  String get profileSignOutTitle;

  /// No description provided for @profileSignOutMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você precisará entrar novamente para acessar sua conta.'**
  String get profileSignOutMessage;

  /// No description provided for @profileSignOutConfirm.
  ///
  /// In pt, this message translates to:
  /// **'SAIR'**
  String get profileSignOutConfirm;

  /// No description provided for @profileSignOut.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get profileSignOut;

  /// No description provided for @authSessionExpiredTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua sessão expirou'**
  String get authSessionExpiredTitle;

  /// No description provided for @authSessionExpiredMessage.
  ///
  /// In pt, this message translates to:
  /// **'Por segurança, precisamos confirmar seu acesso novamente. Entre na sua conta para continuar usando todos os recursos do {club}.'**
  String authSessionExpiredMessage(String club);

  /// No description provided for @authSessionExpiredCta.
  ///
  /// In pt, this message translates to:
  /// **'Entrar novamente'**
  String get authSessionExpiredCta;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou senha incorretos.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorCurrentPasswordIncorrect.
  ///
  /// In pt, this message translates to:
  /// **'Senha atual incorreta.'**
  String get authErrorCurrentPasswordIncorrect;

  /// No description provided for @authErrorPasswordIncorrect.
  ///
  /// In pt, this message translates to:
  /// **'Senha incorreta.'**
  String get authErrorPasswordIncorrect;

  /// No description provided for @authErrorEmailAlreadyRegistered.
  ///
  /// In pt, this message translates to:
  /// **'Este e-mail já possui uma conta.'**
  String get authErrorEmailAlreadyRegistered;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In pt, this message translates to:
  /// **'A senha não atende aos requisitos mínimos.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In pt, this message translates to:
  /// **'Informe um e-mail válido.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorRateLimited.
  ///
  /// In pt, this message translates to:
  /// **'Já enviamos um código recentemente. Aguarde um pouco antes de solicitar outro.'**
  String get authErrorRateLimited;

  /// No description provided for @authErrorOtpInvalidOrExpired.
  ///
  /// In pt, this message translates to:
  /// **'Este código não é válido ou já expirou. Confira e tente novamente, ou solicite um novo código.'**
  String get authErrorOtpInvalidOrExpired;

  /// No description provided for @authErrorSessionExpired.
  ///
  /// In pt, this message translates to:
  /// **'Sua sessão expirou. Faça login novamente.'**
  String get authErrorSessionExpired;

  /// No description provided for @authErrorSignupDisabled.
  ///
  /// In pt, this message translates to:
  /// **'Novos cadastros estão temporariamente indisponíveis.'**
  String get authErrorSignupDisabled;

  /// No description provided for @authErrorEmailNotConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Confirme seu e-mail antes de entrar.'**
  String get authErrorEmailNotConfirmed;

  /// No description provided for @authErrorServiceUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'O serviço está temporariamente indisponível. Tente novamente em instantes.'**
  String get authErrorServiceUnavailable;

  /// No description provided for @authErrorNewPasswordSameAsCurrent.
  ///
  /// In pt, this message translates to:
  /// **'A nova senha precisa ser diferente da atual.'**
  String get authErrorNewPasswordSameAsCurrent;

  /// No description provided for @authErrorCpfAlreadyTaken.
  ///
  /// In pt, this message translates to:
  /// **'Este CPF já está cadastrado em outra conta.'**
  String get authErrorCpfAlreadyTaken;

  /// No description provided for @authErrorAccountDeletionFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível excluir sua conta. Tente novamente em alguns instantes.'**
  String get authErrorAccountDeletionFailed;

  /// No description provided for @authErrorNetwork.
  ///
  /// In pt, this message translates to:
  /// **'Verifique sua conexão com a internet.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir agora. Tente novamente.'**
  String get authErrorGeneric;

  /// No description provided for @personalDataTitle.
  ///
  /// In pt, this message translates to:
  /// **'DADOS PESSOAIS'**
  String get personalDataTitle;

  /// No description provided for @personalDataLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seus dados.'**
  String get personalDataLoadError;

  /// No description provided for @personalFieldCpf.
  ///
  /// In pt, this message translates to:
  /// **'CPF (opcional)'**
  String get personalFieldCpf;

  /// No description provided for @personalFieldBirthDate.
  ///
  /// In pt, this message translates to:
  /// **'Data de nascimento'**
  String get personalFieldBirthDate;

  /// No description provided for @personalFieldPhone.
  ///
  /// In pt, this message translates to:
  /// **'Celular'**
  String get personalFieldPhone;

  /// No description provided for @personalEmailLocked.
  ///
  /// In pt, this message translates to:
  /// **'O e-mail é vinculado à sua conta.'**
  String get personalEmailLocked;

  /// No description provided for @personalNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu nome completo.'**
  String get personalNameRequired;

  /// No description provided for @personalCpfRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu CPF.'**
  String get personalCpfRequired;

  /// No description provided for @personalCpfInvalid.
  ///
  /// In pt, this message translates to:
  /// **'CPF inválido.'**
  String get personalCpfInvalid;

  /// No description provided for @personalUpdateSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Dados atualizados com sucesso.'**
  String get personalUpdateSuccess;

  /// No description provided for @securityTitle.
  ///
  /// In pt, this message translates to:
  /// **'SEGURANÇA'**
  String get securityTitle;

  /// No description provided for @securitySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{Altere a senha da sua conta Goiás EC.} other{Altere a senha da sua conta {club}.}}'**
  String securitySubtitle(String clubCode, String club);

  /// No description provided for @securityCurrentPassword.
  ///
  /// In pt, this message translates to:
  /// **'Senha atual'**
  String get securityCurrentPassword;

  /// No description provided for @securityCurrentPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Confirme sua senha atual'**
  String get securityCurrentPasswordHint;

  /// No description provided for @securityNewPassword.
  ///
  /// In pt, this message translates to:
  /// **'Nova senha'**
  String get securityNewPassword;

  /// No description provided for @securityConfirmNewPassword.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar nova senha'**
  String get securityConfirmNewPassword;

  /// No description provided for @securityConfirmNewPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Repita a nova senha'**
  String get securityConfirmNewPasswordHint;

  /// No description provided for @securitySaveButton.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR NOVA SENHA'**
  String get securitySaveButton;

  /// No description provided for @securityChangeSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Senha alterada com sucesso.'**
  String get securityChangeSuccess;

  /// No description provided for @addressTitle.
  ///
  /// In pt, this message translates to:
  /// **'ENDEREÇO RESIDENCIAL'**
  String get addressTitle;

  /// No description provided for @addressResidentialSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Seu endereço principal cadastrado na conta.'**
  String get addressResidentialSubtitle;

  /// No description provided for @addressLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seu endereço.'**
  String get addressLoadError;

  /// No description provided for @addressCepNotFound.
  ///
  /// In pt, this message translates to:
  /// **'CEP não encontrado.'**
  String get addressCepNotFound;

  /// No description provided for @addressSaveSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Endereço salvo com sucesso.'**
  String get addressSaveSuccess;

  /// No description provided for @addressFieldCep.
  ///
  /// In pt, this message translates to:
  /// **'CEP'**
  String get addressFieldCep;

  /// No description provided for @addressFieldStreet.
  ///
  /// In pt, this message translates to:
  /// **'Logradouro'**
  String get addressFieldStreet;

  /// No description provided for @addressFieldNumber.
  ///
  /// In pt, this message translates to:
  /// **'Número'**
  String get addressFieldNumber;

  /// No description provided for @addressFieldComplement.
  ///
  /// In pt, this message translates to:
  /// **'Complemento (opcional)'**
  String get addressFieldComplement;

  /// No description provided for @addressFieldNeighborhood.
  ///
  /// In pt, this message translates to:
  /// **'Bairro'**
  String get addressFieldNeighborhood;

  /// No description provided for @addressFieldState.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get addressFieldState;

  /// No description provided for @addressSelectState.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar estado'**
  String get addressSelectState;

  /// No description provided for @addressFieldCity.
  ///
  /// In pt, this message translates to:
  /// **'Cidade'**
  String get addressFieldCity;

  /// No description provided for @addressSaveButton.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR ENDEREÇO'**
  String get addressSaveButton;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'EXCLUIR CONTA'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirmWord.
  ///
  /// In pt, this message translates to:
  /// **'EXCLUIR'**
  String get deleteAccountConfirmWord;

  /// No description provided for @deleteAccountInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Essa ação é permanente. Confirme sua senha e digite {word} para excluir sua conta e todo o seu progresso.'**
  String deleteAccountInstruction(String word);

  /// No description provided for @deleteAccountPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Confirme sua senha'**
  String get deleteAccountPasswordHint;

  /// No description provided for @deleteAccountTypeWordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Digite {word} para confirmar'**
  String deleteAccountTypeWordLabel(String word);

  /// No description provided for @deleteAccountConfirmButton.
  ///
  /// In pt, this message translates to:
  /// **'EXCLUIR MINHA CONTA'**
  String get deleteAccountConfirmButton;

  /// No description provided for @deleteAccountDeleting.
  ///
  /// In pt, this message translates to:
  /// **'EXCLUINDO CONTA...'**
  String get deleteAccountDeleting;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In pt, this message translates to:
  /// **'NOTIFICAÇÕES'**
  String get settingsNotificationsTitle;

  /// No description provided for @notificationsLiveMatchesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Jogos ao vivo'**
  String get notificationsLiveMatchesTitle;

  /// No description provided for @notificationsLiveMatchesDescription.
  ///
  /// In pt, this message translates to:
  /// **'Ative para receber os avisos abaixo em tempo real, com o placar do {club}.'**
  String notificationsLiveMatchesDescription(String club);

  /// No description provided for @notificationsKickoffTitle.
  ///
  /// In pt, this message translates to:
  /// **'Início da partida'**
  String get notificationsKickoffTitle;

  /// No description provided for @notificationsKickoffDescription.
  ///
  /// In pt, this message translates to:
  /// **'Aviso assim que a bola rolar.'**
  String get notificationsKickoffDescription;

  /// No description provided for @notificationsGoalForTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gols do {club}'**
  String notificationsGoalForTitle(String club);

  /// No description provided for @notificationsGoalForDescription.
  ///
  /// In pt, this message translates to:
  /// **'Aviso a cada gol marcado pelo {club}.'**
  String notificationsGoalForDescription(String club);

  /// No description provided for @notificationsGoalAgainstTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gols do adversário'**
  String get notificationsGoalAgainstTitle;

  /// No description provided for @notificationsGoalAgainstDescription.
  ///
  /// In pt, this message translates to:
  /// **'Aviso a cada gol sofrido.'**
  String get notificationsGoalAgainstDescription;

  /// No description provided for @notificationsHalfTimeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo'**
  String get notificationsHalfTimeTitle;

  /// No description provided for @notificationsHalfTimeDescription.
  ///
  /// In pt, this message translates to:
  /// **'Aviso no intervalo, com o placar parcial.'**
  String get notificationsHalfTimeDescription;

  /// No description provided for @notificationsSecondHalfTitle.
  ///
  /// In pt, this message translates to:
  /// **'Início do segundo tempo'**
  String get notificationsSecondHalfTitle;

  /// No description provided for @notificationsSecondHalfDescription.
  ///
  /// In pt, this message translates to:
  /// **'Aviso quando a bola voltar a rolar.'**
  String get notificationsSecondHalfDescription;

  /// No description provided for @notificationsFullTimeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fim de jogo'**
  String get notificationsFullTimeTitle;

  /// No description provided for @notificationsFullTimeDescription.
  ///
  /// In pt, this message translates to:
  /// **'Aviso com o placar final.'**
  String get notificationsFullTimeDescription;

  /// No description provided for @notificationsTicketsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ingressos e check-in'**
  String get notificationsTicketsTitle;

  /// No description provided for @notificationsTicketsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Avisos quando a venda ou o check-in abrirem.'**
  String get notificationsTicketsDescription;

  /// No description provided for @notificationsOsBlockedMessage.
  ///
  /// In pt, this message translates to:
  /// **'As notificações estão desativadas nas configurações do sistema — você não vai receber nada até reativar.'**
  String get notificationsOsBlockedMessage;

  /// No description provided for @notificationsOpenSettings.
  ///
  /// In pt, this message translates to:
  /// **'Abrir configurações'**
  String get notificationsOpenSettings;

  /// No description provided for @notificationsForegroundCta.
  ///
  /// In pt, this message translates to:
  /// **'Ver'**
  String get notificationsForegroundCta;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In pt, this message translates to:
  /// **'TEMA'**
  String get settingsThemeTitle;

  /// No description provided for @themeModeAuto.
  ///
  /// In pt, this message translates to:
  /// **'Automático'**
  String get themeModeAuto;

  /// No description provided for @themeModeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeModeDark;

  /// No description provided for @themeModeAutoDesc.
  ///
  /// In pt, this message translates to:
  /// **'Segue o tema do seu celular'**
  String get themeModeAutoDesc;

  /// No description provided for @themeModeLightDesc.
  ///
  /// In pt, this message translates to:
  /// **'Sempre com fundo claro'**
  String get themeModeLightDesc;

  /// No description provided for @themeModeDarkDesc.
  ///
  /// In pt, this message translates to:
  /// **'Sempre com fundo escuro'**
  String get themeModeDarkDesc;

  /// No description provided for @avatarTakePhoto.
  ///
  /// In pt, this message translates to:
  /// **'Tirar foto'**
  String get avatarTakePhoto;

  /// No description provided for @avatarChooseFromGallery.
  ///
  /// In pt, this message translates to:
  /// **'Escolher da galeria'**
  String get avatarChooseFromGallery;

  /// No description provided for @socialFollowTitle.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{SIGA O GOIÁS} other{SIGA O {club}}}'**
  String socialFollowTitle(String clubCode, String club);

  /// No description provided for @socialFollowSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{Acompanhe o Verdão também nas redes sociais.} other{Acompanhe o {club} também nas redes sociais.}}'**
  String socialFollowSubtitle(String clubCode, String club);

  /// No description provided for @socialOpenLink.
  ///
  /// In pt, this message translates to:
  /// **'Abrir {name}'**
  String socialOpenLink(String name);

  /// No description provided for @arenaTitle.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{Arena Esmeraldina} other{Arena {club}}}'**
  String arenaTitle(String clubCode, String club);

  /// No description provided for @arenaGamesSectionSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{Teste seus conhecimentos sobre o Verdão.} other{Teste seus conhecimentos sobre o {club}.}}'**
  String arenaGamesSectionSubtitle(String clubCode, String club);

  /// No description provided for @arenaNextMatchBadge.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMO JOGO'**
  String get arenaNextMatchBadge;

  /// No description provided for @arenaHighlightViewLineup.
  ///
  /// In pt, this message translates to:
  /// **'Ver escalação'**
  String get arenaHighlightViewLineup;

  /// No description provided for @arenaPlay.
  ///
  /// In pt, this message translates to:
  /// **'JOGAR'**
  String get arenaPlay;

  /// No description provided for @arenaRankingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ranking da Torcida'**
  String get arenaRankingTitle;

  /// No description provided for @arenaRankingEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ranking ainda vazio'**
  String get arenaRankingEmpty;

  /// No description provided for @arenaRankingEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Jogue e seja o primeiro a aparecer no ranking da torcida.'**
  String get arenaRankingEmptyMessage;

  /// No description provided for @arenaAchievementTitle.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{LENDA ESMERALDINA} other{LENDA DO {club}}}'**
  String arenaAchievementTitle(String clubCode, String club);

  /// No description provided for @arenaAchievementMessage.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{Você completou 100% da Arena Esmeraldina — Quiz do Verdão, Adivinhe a Escalação e Adivinhe o Jogador. Essa conquista é permanente.} other{Você completou 100% da Arena {club} — Quiz, Adivinhe a Escalação e Adivinhe o Jogador. Essa conquista é permanente.}}'**
  String arenaAchievementMessage(String clubCode, String club);

  /// No description provided for @arenaAchievementConfirm.
  ///
  /// In pt, this message translates to:
  /// **'SHOW DE BOLA!'**
  String get arenaAchievementConfirm;

  /// No description provided for @arenaPlayFirstTime.
  ///
  /// In pt, this message translates to:
  /// **'Jogue pela primeira vez'**
  String get arenaPlayFirstTime;

  /// No description provided for @arenaStatMatchesCorrect.
  ///
  /// In pt, this message translates to:
  /// **'{played} partidas · {correct} acertos'**
  String arenaStatMatchesCorrect(int played, int correct);

  /// No description provided for @arenaHeaderSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Jogue, participe e viva o {club}.'**
  String arenaHeaderSubtitle(String club);

  /// No description provided for @arenaSpotlightEyebrow.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{Arena Esmeraldina} other{Arena {club}}}'**
  String arenaSpotlightEyebrow(String clubCode, String club);

  /// No description provided for @arenaSpotlightHeadline.
  ///
  /// In pt, this message translates to:
  /// **'A sua paixão entra em campo'**
  String get arenaSpotlightHeadline;

  /// No description provided for @arenaSpotlightSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{Jogue, participe e dispute seu lugar entre os Esmeraldinos.} bragantino{Jogue, participe e dispute seu lugar entre a Massa Bruta.} other{Jogue, participe e dispute seu lugar entre os torcedores do {club}.}}'**
  String arenaSpotlightSubtitle(String clubCode, String club);

  /// No description provided for @arenaSpotlightCta.
  ///
  /// In pt, this message translates to:
  /// **'Entrar na Arena'**
  String get arenaSpotlightCta;

  /// No description provided for @arenaLineupHeroEyebrow.
  ///
  /// In pt, this message translates to:
  /// **'ESCALAÇÃO DA TORCIDA'**
  String get arenaLineupHeroEyebrow;

  /// No description provided for @arenaLineupHeroCta.
  ///
  /// In pt, this message translates to:
  /// **'Montar minha escalação'**
  String get arenaLineupHeroCta;

  /// No description provided for @arenaLineupHeroEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sem jogo por enquanto'**
  String get arenaLineupHeroEmptyTitle;

  /// No description provided for @arenaLineupHeroEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Assim que a próxima partida for confirmada, você já pode montar sua escalação aqui.'**
  String get arenaLineupHeroEmptyMessage;

  /// No description provided for @arenaChallengesSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desafios'**
  String get arenaChallengesSectionTitle;

  /// No description provided for @arenaChallengeCtaContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get arenaChallengeCtaContinue;

  /// No description provided for @arenaChallengeCtaStart.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get arenaChallengeCtaStart;

  /// No description provided for @arenaChallengeCtaCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get arenaChallengeCtaCompleted;

  /// No description provided for @arenaGameQuizTitle.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{Quiz do Verdão} other{Quiz do {club}}}'**
  String arenaGameQuizTitle(String clubCode, String club);

  /// No description provided for @arenaGameQuizTagline.
  ///
  /// In pt, this message translates to:
  /// **'Teste o quanto você conhece o {club}.'**
  String arenaGameQuizTagline(String club);

  /// No description provided for @arenaGameLineupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adivinhe a Escalação'**
  String get arenaGameLineupTitle;

  /// No description provided for @arenaGameLineupTagline.
  ///
  /// In pt, this message translates to:
  /// **'Descubra os 11 titulares de uma partida histórica do {club}.'**
  String arenaGameLineupTagline(String club);

  /// No description provided for @arenaGameCareerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adivinhe o Jogador'**
  String get arenaGameCareerTitle;

  /// No description provided for @arenaGameCareerTagline.
  ///
  /// In pt, this message translates to:
  /// **'Descubra o jogador pela trajetória na carreira.'**
  String get arenaGameCareerTagline;

  /// No description provided for @arenaGuessPlayerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quem Vestiu o Manto?'**
  String get arenaGuessPlayerTitle;

  /// No description provided for @arenaGuessPlayerTagline.
  ///
  /// In pt, this message translates to:
  /// **'Descubra o jogador secreto pela foto embaçada e pelas pistas.'**
  String get arenaGuessPlayerTagline;

  /// No description provided for @arenaRankingWeekly.
  ///
  /// In pt, this message translates to:
  /// **'Semanal'**
  String get arenaRankingWeekly;

  /// No description provided for @arenaRankingMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get arenaRankingMonthly;

  /// No description provided for @arenaRankingAllTime.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get arenaRankingAllTime;

  /// No description provided for @arenaRankingPoints.
  ///
  /// In pt, this message translates to:
  /// **'pts'**
  String get arenaRankingPoints;

  /// No description provided for @arenaRankingYourPosition.
  ///
  /// In pt, this message translates to:
  /// **'SUA POSIÇÃO'**
  String get arenaRankingYourPosition;

  /// No description provided for @arenaRankingMemberBadge.
  ///
  /// In pt, this message translates to:
  /// **'Sócio'**
  String get arenaRankingMemberBadge;

  /// No description provided for @arenaRankingUnknownFan.
  ///
  /// In pt, this message translates to:
  /// **'Torcedor'**
  String get arenaRankingUnknownFan;

  /// No description provided for @passportCardCta.
  ///
  /// In pt, this message translates to:
  /// **'Abrir passaporte'**
  String get passportCardCta;

  /// No description provided for @passportRankingCta.
  ///
  /// In pt, this message translates to:
  /// **'Ranking do Passaporte'**
  String get passportRankingCta;

  /// No description provided for @passportLoadErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o passaporte'**
  String get passportLoadErrorTitle;

  /// No description provided for @passportEmptyCatalogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma temporada disponível ainda'**
  String get passportEmptyCatalogTitle;

  /// No description provided for @passportNoMatchesForFilter.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma partida encontrada com esse filtro'**
  String get passportNoMatchesForFilter;

  /// No description provided for @passportSummaryTotalMatches.
  ///
  /// In pt, this message translates to:
  /// **'Partidas registradas'**
  String get passportSummaryTotalMatches;

  /// No description provided for @passportSummaryYearsCount.
  ///
  /// In pt, this message translates to:
  /// **'Anos com presença'**
  String get passportSummaryYearsCount;

  /// No description provided for @passportSummaryFirstMatch.
  ///
  /// In pt, this message translates to:
  /// **'Primeira partida'**
  String get passportSummaryFirstMatch;

  /// No description provided for @passportSummaryLastMatch.
  ///
  /// In pt, this message translates to:
  /// **'Última partida'**
  String get passportSummaryLastMatch;

  /// No description provided for @passportFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get passportFilterAll;

  /// No description provided for @passportFilterAttended.
  ///
  /// In pt, this message translates to:
  /// **'Marcados'**
  String get passportFilterAttended;

  /// No description provided for @passportFilterNotAttended.
  ///
  /// In pt, this message translates to:
  /// **'Não marcados'**
  String get passportFilterNotAttended;

  /// No description provided for @passportFilterHome.
  ///
  /// In pt, this message translates to:
  /// **'Casa'**
  String get passportFilterHome;

  /// No description provided for @passportFilterAway.
  ///
  /// In pt, this message translates to:
  /// **'Fora'**
  String get passportFilterAway;

  /// No description provided for @passportFilterAllCompetitions.
  ///
  /// In pt, this message translates to:
  /// **'Todas as competições'**
  String get passportFilterAllCompetitions;

  /// No description provided for @passportStatusScheduled.
  ///
  /// In pt, this message translates to:
  /// **'Agendado'**
  String get passportStatusScheduled;

  /// No description provided for @passportStatusPostponed.
  ///
  /// In pt, this message translates to:
  /// **'Adiado'**
  String get passportStatusPostponed;

  /// No description provided for @passportStatusCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get passportStatusCancelled;

  /// No description provided for @passportOutcomeWin.
  ///
  /// In pt, this message translates to:
  /// **'Vitória'**
  String get passportOutcomeWin;

  /// No description provided for @passportOutcomeDraw.
  ///
  /// In pt, this message translates to:
  /// **'Empate'**
  String get passportOutcomeDraw;

  /// No description provided for @passportOutcomeLoss.
  ///
  /// In pt, this message translates to:
  /// **'Derrota'**
  String get passportOutcomeLoss;

  /// No description provided for @passportSaveGenericLabel.
  ///
  /// In pt, this message translates to:
  /// **'Salvar alterações'**
  String get passportSaveGenericLabel;

  /// No description provided for @passportSaveCountLabel.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Salvar 1 partida} other{Salvar {count} partidas}}'**
  String passportSaveCountLabel(num count);

  /// No description provided for @passportSaveSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Passaporte atualizado.'**
  String get passportSaveSuccess;

  /// No description provided for @passportDiscardChangesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Descartar alterações?'**
  String get passportDiscardChangesTitle;

  /// No description provided for @passportDiscardChangesMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você marcou partidas que ainda não foram salvas. Se sair agora, essas marcações são perdidas.'**
  String get passportDiscardChangesMessage;

  /// No description provided for @passportDiscardChangesConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Descartar'**
  String get passportDiscardChangesConfirm;

  /// No description provided for @passportRankingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ranking do Passaporte'**
  String get passportRankingTitle;

  /// No description provided for @passportRankingPeriodOverall.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get passportRankingPeriodOverall;

  /// No description provided for @passportRankingMatchCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 partida} other{{count} partidas}}'**
  String passportRankingMatchCount(num count);

  /// No description provided for @passportRankingEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém no ranking ainda'**
  String get passportRankingEmptyTitle;

  /// No description provided for @passportRankingEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Marque suas partidas no Passaporte pra aparecer aqui.'**
  String get passportRankingEmptyMessage;

  /// No description provided for @passportStatsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minha trajetória'**
  String get passportStatsTitle;

  /// No description provided for @passportStatsWins.
  ///
  /// In pt, this message translates to:
  /// **'Vitórias'**
  String get passportStatsWins;

  /// No description provided for @passportStatsDraws.
  ///
  /// In pt, this message translates to:
  /// **'Empates'**
  String get passportStatsDraws;

  /// No description provided for @passportStatsLosses.
  ///
  /// In pt, this message translates to:
  /// **'Derrotas'**
  String get passportStatsLosses;

  /// No description provided for @passportStatsHomeGames.
  ///
  /// In pt, this message translates to:
  /// **'Em casa'**
  String get passportStatsHomeGames;

  /// No description provided for @passportStatsAwayGames.
  ///
  /// In pt, this message translates to:
  /// **'Fora de casa'**
  String get passportStatsAwayGames;

  /// No description provided for @passportStatsGoalsFor.
  ///
  /// In pt, this message translates to:
  /// **'Gols marcados'**
  String get passportStatsGoalsFor;

  /// No description provided for @passportStatsGoalsAgainst.
  ///
  /// In pt, this message translates to:
  /// **'Gols sofridos'**
  String get passportStatsGoalsAgainst;

  /// No description provided for @passportStatsGoalDifference.
  ///
  /// In pt, this message translates to:
  /// **'Saldo'**
  String get passportStatsGoalDifference;

  /// No description provided for @passportStatsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua trajetória começa aqui'**
  String get passportStatsEmptyTitle;

  /// No description provided for @passportStatsEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Marque partidas como \"Eu fui\" pra ver suas estatísticas.'**
  String get passportStatsEmptyMessage;

  /// No description provided for @passportTrajectoryGames.
  ///
  /// In pt, this message translates to:
  /// **'Jogos'**
  String get passportTrajectoryGames;

  /// No description provided for @passportTrajectoryStadiums.
  ///
  /// In pt, this message translates to:
  /// **'Estádios'**
  String get passportTrajectoryStadiums;

  /// No description provided for @passportTrajectorySeasons.
  ///
  /// In pt, this message translates to:
  /// **'Temporadas'**
  String get passportTrajectorySeasons;

  /// No description provided for @passportTrajectoryMemorableMatch.
  ///
  /// In pt, this message translates to:
  /// **'Jogo mais memorável'**
  String get passportTrajectoryMemorableMatch;

  /// No description provided for @passportTrajectoryMemorableEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Escolha seu jogo mais memorável'**
  String get passportTrajectoryMemorableEmpty;

  /// No description provided for @passportTrajectoryPickMatch.
  ///
  /// In pt, this message translates to:
  /// **'Escolha seu jogo mais memorável'**
  String get passportTrajectoryPickMatch;

  /// No description provided for @passportTrajectoryMostVisitedStadium.
  ///
  /// In pt, this message translates to:
  /// **'Estádio mais visitado'**
  String get passportTrajectoryMostVisitedStadium;

  /// No description provided for @passportTrajectoryStadiumUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não temos essa informação'**
  String get passportTrajectoryStadiumUnavailable;

  /// No description provided for @passportTrajectoryGamesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 jogo} other{{count} jogos}}'**
  String passportTrajectoryGamesCount(int count);

  /// No description provided for @passportTrajectoryListEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum jogo por aqui ainda'**
  String get passportTrajectoryListEmpty;

  /// No description provided for @passportTrajectoryShareAction.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get passportTrajectoryShareAction;

  /// No description provided for @passportTrajectoryOfUser.
  ///
  /// In pt, this message translates to:
  /// **'Trajetória de {name}'**
  String passportTrajectoryOfUser(String name);

  /// No description provided for @passportTrajectoryMemorableEmptyReadOnly.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não escolheu um jogo memorável'**
  String get passportTrajectoryMemorableEmptyReadOnly;

  /// No description provided for @passportCoverEyebrow.
  ///
  /// In pt, this message translates to:
  /// **'MEU PASSAPORTE'**
  String get passportCoverEyebrow;

  /// No description provided for @passportEmptyHeadline.
  ///
  /// In pt, this message translates to:
  /// **'Todo torcedor tem uma história.'**
  String get passportEmptyHeadline;

  /// No description provided for @passportChangeSeasonCta.
  ///
  /// In pt, this message translates to:
  /// **'Trocar temporada'**
  String get passportChangeSeasonCta;

  /// No description provided for @passportSeasonProgressLine.
  ///
  /// In pt, this message translates to:
  /// **'{marked} de {total} jogos registrados'**
  String passportSeasonProgressLine(Object marked, Object total);

  /// No description provided for @passportSeasonTotalOnly.
  ///
  /// In pt, this message translates to:
  /// **'{total} jogos'**
  String passportSeasonTotalOnly(Object total);

  /// No description provided for @passportSealLabel.
  ///
  /// In pt, this message translates to:
  /// **'EU FUI'**
  String get passportSealLabel;

  /// No description provided for @passportSealActionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Eu fui'**
  String get passportSealActionLabel;

  /// No description provided for @passportRoundSemifinal.
  ///
  /// In pt, this message translates to:
  /// **'Semifinal'**
  String get passportRoundSemifinal;

  /// No description provided for @passportRoundQuarterfinal.
  ///
  /// In pt, this message translates to:
  /// **'Quartas de final'**
  String get passportRoundQuarterfinal;

  /// No description provided for @passportRoundFinal.
  ///
  /// In pt, this message translates to:
  /// **'Final'**
  String get passportRoundFinal;

  /// No description provided for @passportRoundPlayoff.
  ///
  /// In pt, this message translates to:
  /// **'Repescagem'**
  String get passportRoundPlayoff;

  /// No description provided for @passportRoundOf16.
  ///
  /// In pt, this message translates to:
  /// **'Oitavas de final'**
  String get passportRoundOf16;

  /// No description provided for @passportRoundPhase.
  ///
  /// In pt, this message translates to:
  /// **'{n}ª fase'**
  String passportRoundPhase(int n);

  /// No description provided for @passportRoundMatchday.
  ///
  /// In pt, this message translates to:
  /// **'Rodada {n}'**
  String passportRoundMatchday(int n);

  /// No description provided for @passportRoundGroup.
  ///
  /// In pt, this message translates to:
  /// **'Grupo {letter}'**
  String passportRoundGroup(String letter);

  /// No description provided for @arenaRankingDetailFirstTry.
  ///
  /// In pt, this message translates to:
  /// **'Acertos de primeira'**
  String get arenaRankingDetailFirstTry;

  /// No description provided for @arenaRankingDetailReview.
  ///
  /// In pt, this message translates to:
  /// **'Acertos na revisão'**
  String get arenaRankingDetailReview;

  /// No description provided for @arenaRankingDetailAbandoned.
  ///
  /// In pt, this message translates to:
  /// **'Revelados/desistências'**
  String get arenaRankingDetailAbandoned;

  /// No description provided for @arenaRankingYouTag.
  ///
  /// In pt, this message translates to:
  /// **'VOCÊ'**
  String get arenaRankingYouTag;

  /// No description provided for @arenaRankingPlace.
  ///
  /// In pt, this message translates to:
  /// **'{rank}º lugar'**
  String arenaRankingPlace(int rank);

  /// No description provided for @arenaRankingPointsFull.
  ///
  /// In pt, this message translates to:
  /// **'pontos'**
  String get arenaRankingPointsFull;

  /// No description provided for @arenaRankingPeriodOverall.
  ///
  /// In pt, this message translates to:
  /// **'Ranking Geral'**
  String get arenaRankingPeriodOverall;

  /// No description provided for @arenaRankingPeriodWeek.
  ///
  /// In pt, this message translates to:
  /// **'Esta semana'**
  String get arenaRankingPeriodWeek;

  /// No description provided for @arenaRankingByGame.
  ///
  /// In pt, this message translates to:
  /// **'Pontuação por jogo'**
  String get arenaRankingByGame;

  /// No description provided for @arenaRankingHowScoredSelf.
  ///
  /// In pt, this message translates to:
  /// **'Como você pontuou'**
  String get arenaRankingHowScoredSelf;

  /// No description provided for @arenaRankingHowScoredOther.
  ///
  /// In pt, this message translates to:
  /// **'Como {name} pontuou'**
  String arenaRankingHowScoredOther(String name);

  /// No description provided for @arenaRankingGamePointsShare.
  ///
  /// In pt, this message translates to:
  /// **'{score} pts • {percent}% do total'**
  String arenaRankingGamePointsShare(int score, int percent);

  /// No description provided for @arenaRankingNoPointsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum ponto neste período'**
  String get arenaRankingNoPointsTitle;

  /// No description provided for @arenaRankingNoPointsOther.
  ///
  /// In pt, this message translates to:
  /// **'Este torcedor ainda não pontuou nos jogos durante o período selecionado.'**
  String get arenaRankingNoPointsOther;

  /// No description provided for @arenaRankingNoPointsSelf.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não pontuou nos jogos durante o período selecionado.'**
  String get arenaRankingNoPointsSelf;

  /// No description provided for @arenaRankingGapToNext.
  ///
  /// In pt, this message translates to:
  /// **'{points} pts para alcançar o {rank}º'**
  String arenaRankingGapToNext(int points, int rank);

  /// No description provided for @commonClose.
  ///
  /// In pt, this message translates to:
  /// **'FECHAR'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get commonRetry;

  /// No description provided for @commonComingSoon.
  ///
  /// In pt, this message translates to:
  /// **'Em breve'**
  String get commonComingSoon;

  /// No description provided for @commonComingSoonMessage.
  ///
  /// In pt, this message translates to:
  /// **'Essa área ainda está sendo preparada.'**
  String get commonComingSoonMessage;

  /// No description provided for @featureUnavailableTitle.
  ///
  /// In pt, this message translates to:
  /// **'Indisponível'**
  String get featureUnavailableTitle;

  /// No description provided for @featureUnavailableMessage.
  ///
  /// In pt, this message translates to:
  /// **'Essa área não está disponível.'**
  String get featureUnavailableMessage;

  /// No description provided for @commonLinkOpenError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir este link.'**
  String get commonLinkOpenError;

  /// No description provided for @commonLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os dados'**
  String get commonLoadError;

  /// No description provided for @commonSelectPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar'**
  String get commonSelectPlaceholder;

  /// No description provided for @commonNoDataFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum dado encontrado.'**
  String get commonNoDataFound;

  /// No description provided for @membershipCheckInAction.
  ///
  /// In pt, this message translates to:
  /// **'FAZER CHECK-IN'**
  String get membershipCheckInAction;

  /// No description provided for @quizChooseLevel.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o nível'**
  String get quizChooseLevel;

  /// No description provided for @quizChooseLevelHint.
  ///
  /// In pt, this message translates to:
  /// **'Cada nível tem seu próprio banco de perguntas — quanto mais alto, mais difícil.'**
  String get quizChooseLevelHint;

  /// No description provided for @quizDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get quizDone;

  /// No description provided for @quizSeeResult.
  ///
  /// In pt, this message translates to:
  /// **'VER RESULTADO'**
  String get quizSeeResult;

  /// No description provided for @quizNext.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMA'**
  String get quizNext;

  /// No description provided for @quizHits.
  ///
  /// In pt, this message translates to:
  /// **'ACERTOS'**
  String get quizHits;

  /// No description provided for @quizPerfect.
  ///
  /// In pt, this message translates to:
  /// **'Perfeito!'**
  String get quizPerfect;

  /// No description provided for @quizScore.
  ///
  /// In pt, this message translates to:
  /// **'PONTUAÇÃO'**
  String get quizScore;

  /// No description provided for @quizNewRecord.
  ///
  /// In pt, this message translates to:
  /// **'Novo recorde'**
  String get quizNewRecord;

  /// No description provided for @quizReviewErrors.
  ///
  /// In pt, this message translates to:
  /// **'REVISAR ERROS'**
  String get quizReviewErrors;

  /// No description provided for @quizPlayAgain.
  ///
  /// In pt, this message translates to:
  /// **'JOGAR NOVAMENTE'**
  String get quizPlayAgain;

  /// No description provided for @quizReviewMore.
  ///
  /// In pt, this message translates to:
  /// **'REVISAR MAIS'**
  String get quizReviewMore;

  /// No description provided for @quizBackToLevels.
  ///
  /// In pt, this message translates to:
  /// **'VOLTAR AOS NÍVEIS'**
  String get quizBackToLevels;

  /// No description provided for @quizMoreQuestions.
  ///
  /// In pt, this message translates to:
  /// **'MAIS PERGUNTAS'**
  String get quizMoreQuestions;

  /// No description provided for @quizBackToArena.
  ///
  /// In pt, this message translates to:
  /// **'VOLTAR À ARENA'**
  String get quizBackToArena;

  /// No description provided for @quizLevelDescTorcedor.
  ///
  /// In pt, this message translates to:
  /// **'Fatos básicos, títulos e campanhas que todo torcedor conhece.'**
  String get quizLevelDescTorcedor;

  /// No description provided for @quizLevelDescEsmeraldino.
  ///
  /// In pt, this message translates to:
  /// **'História, ídolos e jogos marcantes pra quem manja do clube.'**
  String get quizLevelDescEsmeraldino;

  /// No description provided for @quizLevelDescFanatico.
  ///
  /// In pt, this message translates to:
  /// **'Recordes e números pra quem não erra nenhuma.'**
  String get quizLevelDescFanatico;

  /// No description provided for @quizLevelName.
  ///
  /// In pt, this message translates to:
  /// **'Nível {level}'**
  String quizLevelName(String level);

  /// No description provided for @quizQuestionProgress.
  ///
  /// In pt, this message translates to:
  /// **'Pergunta {current} de {total}'**
  String quizQuestionProgress(int current, int total);

  /// No description provided for @quizAnsweredCount.
  ///
  /// In pt, this message translates to:
  /// **'{answered}/{total} perguntas'**
  String quizAnsweredCount(int answered, int total);

  /// No description provided for @quizPendingReview.
  ///
  /// In pt, this message translates to:
  /// **'{count} para revisar'**
  String quizPendingReview(int count);

  /// No description provided for @quizLevelCompleted.
  ///
  /// In pt, this message translates to:
  /// **'NÍVEL {level} CONCLUÍDO'**
  String quizLevelCompleted(String level);

  /// No description provided for @quizAllAnswered.
  ///
  /// In pt, this message translates to:
  /// **'Você respondeu todas as {total} perguntas deste nível.'**
  String quizAllAnswered(int total);

  /// No description provided for @quizCorrectCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} acertadas'**
  String quizCorrectCount(int count);

  /// No description provided for @quizReviewLevel.
  ///
  /// In pt, this message translates to:
  /// **'Revisão · Nível {level}'**
  String quizReviewLevel(String level);

  /// No description provided for @quizFinalResultLevel.
  ///
  /// In pt, this message translates to:
  /// **'Resultado final · Nível {level}'**
  String quizFinalResultLevel(String level);

  /// No description provided for @quizScoreLine.
  ///
  /// In pt, this message translates to:
  /// **'Você acertou {correct} de {total} perguntas'**
  String quizScoreLine(int correct, int total);

  /// No description provided for @quizLevelQuestions.
  ///
  /// In pt, this message translates to:
  /// **'{answered}/{total} perguntas do nível'**
  String quizLevelQuestions(int answered, int total);

  /// No description provided for @quizBestRecord.
  ///
  /// In pt, this message translates to:
  /// **'Recorde: {best} pts'**
  String quizBestRecord(int best);

  /// No description provided for @tacticalIdentityGameTitle.
  ///
  /// In pt, this message translates to:
  /// **'Identidade Futebolística'**
  String get tacticalIdentityGameTitle;

  /// No description provided for @tacticalIdentityCardSubtitleNew.
  ///
  /// In pt, this message translates to:
  /// **'Que tipo de futebol você acredita?'**
  String get tacticalIdentityCardSubtitleNew;

  /// No description provided for @tacticalIdentityCardCtaStart.
  ///
  /// In pt, this message translates to:
  /// **'Descobrir meu perfil'**
  String get tacticalIdentityCardCtaStart;

  /// No description provided for @tacticalIdentityCardCtaViewResult.
  ///
  /// In pt, this message translates to:
  /// **'Ver resultado'**
  String get tacticalIdentityCardCtaViewResult;

  /// No description provided for @tacticalIdentityCardCtaRedo.
  ///
  /// In pt, this message translates to:
  /// **'Refazer'**
  String get tacticalIdentityCardCtaRedo;

  /// No description provided for @tacticalIdentityYourProfile.
  ///
  /// In pt, this message translates to:
  /// **'Seu perfil: {name}'**
  String tacticalIdentityYourProfile(String name);

  /// No description provided for @tacticalIntroTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qual é a sua identidade futebolística?'**
  String get tacticalIntroTitle;

  /// No description provided for @tacticalIntroDescription.
  ///
  /// In pt, this message translates to:
  /// **'10 decisões. Nenhuma resposta certa. Descubra como você enxerga o jogo e com quais técnicos que passaram pelo {club} sua filosofia mais se aproxima.'**
  String tacticalIntroDescription(String club);

  /// No description provided for @tacticalIntroMeta.
  ///
  /// In pt, this message translates to:
  /// **'10 perguntas • ~3 minutos'**
  String get tacticalIntroMeta;

  /// No description provided for @tacticalIntroNoRightWrong.
  ///
  /// In pt, this message translates to:
  /// **'Não existem respostas certas ou erradas.'**
  String get tacticalIntroNoRightWrong;

  /// No description provided for @tacticalIntroStart.
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get tacticalIntroStart;

  /// No description provided for @tacticalQuestionContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get tacticalQuestionContinue;

  /// No description provided for @tacticalProcessingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Analisando sua identidade...'**
  String get tacticalProcessingTitle;

  /// No description provided for @tacticalResultYourProfile.
  ///
  /// In pt, this message translates to:
  /// **'SEU PERFIL'**
  String get tacticalResultYourProfile;

  /// No description provided for @tacticalResultTacticalMap.
  ///
  /// In pt, this message translates to:
  /// **'MAPA TÁTICO'**
  String get tacticalResultTacticalMap;

  /// No description provided for @tacticalResultMainReference.
  ///
  /// In pt, this message translates to:
  /// **'Sua principal referência do {club}'**
  String tacticalResultMainReference(String club);

  /// No description provided for @tacticalResultOtherReferences.
  ///
  /// In pt, this message translates to:
  /// **'OUTRAS REFERÊNCIAS'**
  String get tacticalResultOtherReferences;

  /// No description provided for @tacticalIdentityAffinityLabel.
  ///
  /// In pt, this message translates to:
  /// **'{percent}% de afinidade tática'**
  String tacticalIdentityAffinityLabel(String percent);

  /// No description provided for @tacticalResultShare.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar resultado'**
  String get tacticalResultShare;

  /// No description provided for @tacticalAxisPossession.
  ///
  /// In pt, this message translates to:
  /// **'POSSE'**
  String get tacticalAxisPossession;

  /// No description provided for @tacticalAxisVertical.
  ///
  /// In pt, this message translates to:
  /// **'VERTICAL'**
  String get tacticalAxisVertical;

  /// No description provided for @tacticalAxisDogmatic.
  ///
  /// In pt, this message translates to:
  /// **'DOGMÁTICO'**
  String get tacticalAxisDogmatic;

  /// No description provided for @tacticalAxisPragmatic.
  ///
  /// In pt, this message translates to:
  /// **'PRAGMÁTICO'**
  String get tacticalAxisPragmatic;

  /// No description provided for @playerIdentityGameTitle.
  ///
  /// In pt, this message translates to:
  /// **'Que craque do {club} você é?'**
  String playerIdentityGameTitle(String club);

  /// No description provided for @playerIdentityCardSubtitleNew.
  ///
  /// In pt, this message translates to:
  /// **'10 situações de jogo. Descubra com qual ídolo do {club} seu estilo mais combina.'**
  String playerIdentityCardSubtitleNew(String club);

  /// No description provided for @playerIdentityCardCtaStart.
  ///
  /// In pt, this message translates to:
  /// **'Descobrir meu perfil'**
  String get playerIdentityCardCtaStart;

  /// No description provided for @playerIdentityCardCtaViewResult.
  ///
  /// In pt, this message translates to:
  /// **'Ver resultado'**
  String get playerIdentityCardCtaViewResult;

  /// No description provided for @playerIdentityCardCtaRedo.
  ///
  /// In pt, this message translates to:
  /// **'Refazer'**
  String get playerIdentityCardCtaRedo;

  /// No description provided for @playerIdentityYourProfile.
  ///
  /// In pt, this message translates to:
  /// **'Seu perfil: {name}'**
  String playerIdentityYourProfile(String name);

  /// No description provided for @playerIntroTitle.
  ///
  /// In pt, this message translates to:
  /// **'Que craque do {club} você é?'**
  String playerIntroTitle(String club);

  /// No description provided for @playerIntroDescription.
  ///
  /// In pt, this message translates to:
  /// **'Cada jogador enxerga a partida de um jeito. Responda 10 situações de jogo e descubra qual nome que marcou a história do {club} mais combina com suas escolhas.'**
  String playerIntroDescription(String club);

  /// No description provided for @playerIntroMeta.
  ///
  /// In pt, this message translates to:
  /// **'10 perguntas • ~3 minutos'**
  String get playerIntroMeta;

  /// No description provided for @playerIntroNoRightWrong.
  ///
  /// In pt, this message translates to:
  /// **'Não existem respostas certas.'**
  String get playerIntroNoRightWrong;

  /// No description provided for @playerIntroStart.
  ///
  /// In pt, this message translates to:
  /// **'Começar teste'**
  String get playerIntroStart;

  /// No description provided for @playerProcessingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Calculando seu estilo...'**
  String get playerProcessingTitle;

  /// No description provided for @playerResultYourProfile.
  ///
  /// In pt, this message translates to:
  /// **'SEU PERFIL'**
  String get playerResultYourProfile;

  /// No description provided for @playerResultReferencesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Referências do {club}'**
  String playerResultReferencesTitle(String club);

  /// No description provided for @playerResultTraitsTitle.
  ///
  /// In pt, this message translates to:
  /// **'SUAS MARCAS'**
  String get playerResultTraitsTitle;

  /// No description provided for @playerIdentityAffinityLabel.
  ///
  /// In pt, this message translates to:
  /// **'{percent}% afinidade de estilo'**
  String playerIdentityAffinityLabel(String percent);

  /// No description provided for @playerResultShare.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar resultado'**
  String get playerResultShare;

  /// No description provided for @playerReferenceDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Os atributos são referências editoriais utilizadas nesta experiência e não avaliações oficiais do jogador.'**
  String get playerReferenceDisclaimer;

  /// No description provided for @lineupPlayerHeading.
  ///
  /// In pt, this message translates to:
  /// **'JOGADOR'**
  String get lineupPlayerHeading;

  /// No description provided for @lineupShirt.
  ///
  /// In pt, this message translates to:
  /// **'CAMISA {number}'**
  String lineupShirt(int number);

  /// No description provided for @lineupTypePlayerName.
  ///
  /// In pt, this message translates to:
  /// **'Digite o nome do jogador'**
  String get lineupTypePlayerName;

  /// No description provided for @lineupBackToField.
  ///
  /// In pt, this message translates to:
  /// **'VOLTAR AO CAMPO'**
  String get lineupBackToField;

  /// No description provided for @lineupGiveUp.
  ///
  /// In pt, this message translates to:
  /// **'DESISTIR DA PARTIDA'**
  String get lineupGiveUp;

  /// No description provided for @lineupGiveUpTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desistir da partida?'**
  String get lineupGiveUpTitle;

  /// No description provided for @lineupGiveUpMessage.
  ///
  /// In pt, this message translates to:
  /// **'Os jogadores restantes serão revelados e a partida será encerrada.'**
  String get lineupGiveUpMessage;

  /// No description provided for @lineupGiveUpConfirm.
  ///
  /// In pt, this message translates to:
  /// **'DESISTIR'**
  String get lineupGiveUpConfirm;

  /// No description provided for @lineupKeepPlaying.
  ///
  /// In pt, this message translates to:
  /// **'Continuar jogando'**
  String get lineupKeepPlaying;

  /// No description provided for @lineupMatchProgress.
  ///
  /// In pt, this message translates to:
  /// **'PARTIDA {current} DE {total}'**
  String lineupMatchProgress(int current, int total);

  /// No description provided for @lineupWordCount.
  ///
  /// In pt, this message translates to:
  /// **'{words, plural, =1{1 palavra} other{{words} palavras}} • {letters, plural, =1{1 letra} other{{letters} letras}}'**
  String lineupWordCount(int words, int letters);

  /// No description provided for @lineupComplete.
  ///
  /// In pt, this message translates to:
  /// **'ESCALAÇÃO COMPLETA'**
  String get lineupComplete;

  /// No description provided for @lineupDiscovered.
  ///
  /// In pt, this message translates to:
  /// **'DESCOBERTOS'**
  String get lineupDiscovered;

  /// No description provided for @lineupAttempts.
  ///
  /// In pt, this message translates to:
  /// **'TENTATIVAS'**
  String get lineupAttempts;

  /// No description provided for @lineupTime.
  ///
  /// In pt, this message translates to:
  /// **'TEMPO'**
  String get lineupTime;

  /// No description provided for @lineupResultCopied.
  ///
  /// In pt, this message translates to:
  /// **'Resultado copiado.'**
  String get lineupResultCopied;

  /// No description provided for @lineupCopyResult.
  ///
  /// In pt, this message translates to:
  /// **'Copiar resultado'**
  String get lineupCopyResult;

  /// No description provided for @lineupShareResult.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar resultado'**
  String get lineupShareResult;

  /// No description provided for @lineupNextMatch.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMO JOGO'**
  String get lineupNextMatch;

  /// No description provided for @lineupPreviousMatch.
  ///
  /// In pt, this message translates to:
  /// **'ANTERIOR'**
  String get lineupPreviousMatch;

  /// No description provided for @lineupNoNumber.
  ///
  /// In pt, this message translates to:
  /// **'Jogador sem número confirmado'**
  String get lineupNoNumber;

  /// No description provided for @lineupNotDiscovered.
  ///
  /// In pt, this message translates to:
  /// **'{shirt}, não descoberto'**
  String lineupNotDiscovered(String shirt);

  /// No description provided for @lineupShirtLabel.
  ///
  /// In pt, this message translates to:
  /// **'Camisa {number}'**
  String lineupShirtLabel(int number);

  /// No description provided for @lineupA11yRevealed.
  ///
  /// In pt, this message translates to:
  /// **'{shirt}, {name}, descoberto'**
  String lineupA11yRevealed(String shirt, String name);

  /// No description provided for @lineupA11yPending.
  ///
  /// In pt, this message translates to:
  /// **'{shirt}, {position}, ainda não descoberto'**
  String lineupA11yPending(String shirt, String position);

  /// No description provided for @lineupTileCorrect.
  ///
  /// In pt, this message translates to:
  /// **'posição correta'**
  String get lineupTileCorrect;

  /// No description provided for @lineupTilePresent.
  ///
  /// In pt, this message translates to:
  /// **'letra existe, posição errada'**
  String get lineupTilePresent;

  /// No description provided for @lineupTileAbsent.
  ///
  /// In pt, this message translates to:
  /// **'letra não existe'**
  String get lineupTileAbsent;

  /// No description provided for @lineupTileEmpty.
  ///
  /// In pt, this message translates to:
  /// **'vazio'**
  String get lineupTileEmpty;

  /// No description provided for @keyboardDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get keyboardDelete;

  /// No description provided for @keyboardConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get keyboardConfirm;

  /// No description provided for @commonCloseLabel.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get commonCloseLabel;

  /// No description provided for @careerSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Descubra pela carreira'**
  String get careerSubtitle;

  /// No description provided for @careerSelectFromList.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um jogador da lista.'**
  String get careerSelectFromList;

  /// No description provided for @careerRevealTitle.
  ///
  /// In pt, this message translates to:
  /// **'Revelar jogador?'**
  String get careerRevealTitle;

  /// No description provided for @careerRevealMessage.
  ///
  /// In pt, this message translates to:
  /// **'Ao revelar a resposta, esta rodada será considerada encerrada.'**
  String get careerRevealMessage;

  /// No description provided for @careerReveal.
  ///
  /// In pt, this message translates to:
  /// **'REVELAR'**
  String get careerReveal;

  /// No description provided for @careerRevealPlayer.
  ///
  /// In pt, this message translates to:
  /// **'Revelar jogador'**
  String get careerRevealPlayer;

  /// No description provided for @careerGuess.
  ///
  /// In pt, this message translates to:
  /// **'CHUTAR'**
  String get careerGuess;

  /// No description provided for @careerNextPlayer.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMO JOGADOR'**
  String get careerNextPlayer;

  /// No description provided for @careerWrongGuessFeedback.
  ///
  /// In pt, this message translates to:
  /// **'Não é {name} · Restam {remaining}'**
  String careerWrongGuessFeedback(String name, int remaining);

  /// No description provided for @careerTriedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Já tentou'**
  String get careerTriedLabel;

  /// No description provided for @careerAttemptsRemaining.
  ///
  /// In pt, this message translates to:
  /// **'Tentativas · Restam {remaining}'**
  String careerAttemptsRemaining(int remaining);

  /// No description provided for @careerCorrectTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você acertou!'**
  String get careerCorrectTitle;

  /// No description provided for @careerCorrectFirstTry.
  ///
  /// In pt, this message translates to:
  /// **'Acertou de primeira!'**
  String get careerCorrectFirstTry;

  /// No description provided for @careerCorrectInAttempts.
  ///
  /// In pt, this message translates to:
  /// **'Você acertou em {attempts} tentativas.'**
  String careerCorrectInAttempts(int attempts);

  /// No description provided for @careerWrongTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi dessa vez'**
  String get careerWrongTitle;

  /// No description provided for @careerUsedAllAttempts.
  ///
  /// In pt, this message translates to:
  /// **'Você usou as {max} tentativas.'**
  String careerUsedAllAttempts(int max);

  /// No description provided for @careerPlayerRevealed.
  ///
  /// In pt, this message translates to:
  /// **'Jogador revelado'**
  String get careerPlayerRevealed;

  /// No description provided for @careerRoundEnded.
  ///
  /// In pt, this message translates to:
  /// **'Rodada encerrada.'**
  String get careerRoundEnded;

  /// No description provided for @careerYouGotIt.
  ///
  /// In pt, this message translates to:
  /// **'Você acertou'**
  String get careerYouGotIt;

  /// No description provided for @careerWas.
  ///
  /// In pt, this message translates to:
  /// **'Era'**
  String get careerWas;

  /// No description provided for @careerAnswer.
  ///
  /// In pt, this message translates to:
  /// **'Resposta'**
  String get careerAnswer;

  /// No description provided for @careerNationalTeam.
  ///
  /// In pt, this message translates to:
  /// **'Seleção nacional'**
  String get careerNationalTeam;

  /// No description provided for @careerYears.
  ///
  /// In pt, this message translates to:
  /// **'Anos'**
  String get careerYears;

  /// No description provided for @careerClubs.
  ///
  /// In pt, this message translates to:
  /// **'Clubes'**
  String get careerClubs;

  /// No description provided for @careerGames.
  ///
  /// In pt, this message translates to:
  /// **'Jogos'**
  String get careerGames;

  /// No description provided for @careerGoals.
  ///
  /// In pt, this message translates to:
  /// **'Gols'**
  String get careerGoals;

  /// No description provided for @careerOnLoan.
  ///
  /// In pt, this message translates to:
  /// **'{team} (emp.)'**
  String careerOnLoan(String team);

  /// No description provided for @careerAggregateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Totais agregados'**
  String get careerAggregateTitle;

  /// No description provided for @careerAggregateLine.
  ///
  /// In pt, this message translates to:
  /// **'{club} ({spells}): {apps} jogos · {goals} gols'**
  String careerAggregateLine(
    String club,
    String spells,
    String apps,
    String goals,
  );

  /// No description provided for @commonBack.
  ///
  /// In pt, this message translates to:
  /// **'VOLTAR'**
  String get commonBack;

  /// No description provided for @guessCorrectTitle.
  ///
  /// In pt, this message translates to:
  /// **'ACERTOU!'**
  String get guessCorrectTitle;

  /// No description provided for @guessOutOfAttempts.
  ///
  /// In pt, this message translates to:
  /// **'Fim das tentativas'**
  String get guessOutOfAttempts;

  /// No description provided for @guessCorrectDetail.
  ///
  /// In pt, this message translates to:
  /// **'Você acertou em {used} de {max} tentativas.'**
  String guessCorrectDetail(int used, int max);

  /// No description provided for @guessNoPlayers.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum jogador disponível pra essa arena ainda.'**
  String get guessNoPlayers;

  /// No description provided for @guessRoundEnded.
  ///
  /// In pt, this message translates to:
  /// **'Rodada encerrada'**
  String get guessRoundEnded;

  /// No description provided for @guessAttemptsRemaining.
  ///
  /// In pt, this message translates to:
  /// **'{remaining} tentativas restantes'**
  String guessAttemptsRemaining(int remaining);

  /// No description provided for @guessThePlayerWas.
  ///
  /// In pt, this message translates to:
  /// **'O jogador era: '**
  String get guessThePlayerWas;

  /// No description provided for @guessTypePlayer.
  ///
  /// In pt, this message translates to:
  /// **'Digite um jogador...'**
  String get guessTypePlayer;

  /// No description provided for @guessColPos.
  ///
  /// In pt, this message translates to:
  /// **'POS'**
  String get guessColPos;

  /// No description provided for @guessColShirt.
  ///
  /// In pt, this message translates to:
  /// **'CAMISA'**
  String get guessColShirt;

  /// No description provided for @guessColBase.
  ///
  /// In pt, this message translates to:
  /// **'BASE'**
  String get guessColBase;

  /// No description provided for @guessColDebut.
  ///
  /// In pt, this message translates to:
  /// **'ESTREIA'**
  String get guessColDebut;

  /// No description provided for @dateMinutesAgo.
  ///
  /// In pt, this message translates to:
  /// **'{minutes}min atrás'**
  String dateMinutesAgo(int minutes);

  /// No description provided for @dateHoursAgo.
  ///
  /// In pt, this message translates to:
  /// **'{hours}h atrás'**
  String dateHoursAgo(int hours);

  /// No description provided for @dateDaysAgo.
  ///
  /// In pt, this message translates to:
  /// **'{days, plural, =1{1 dia atrás} other{{days} dias atrás}}'**
  String dateDaysAgo(int days);

  /// No description provided for @datePrepositionFull.
  ///
  /// In pt, this message translates to:
  /// **'{day} de {month}'**
  String datePrepositionFull(int day, String month);

  /// No description provided for @socialMediaTitle.
  ///
  /// In pt, this message translates to:
  /// **'MÍDIA'**
  String get socialMediaTitle;

  /// No description provided for @socialFeedLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o feed'**
  String get socialFeedLoadError;

  /// No description provided for @socialEmptyState.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe o {club} nas redes'**
  String socialEmptyState(String club);

  /// No description provided for @socialViewsM.
  ///
  /// In pt, this message translates to:
  /// **'{value}M visualizações'**
  String socialViewsM(String value);

  /// No description provided for @socialViewsK.
  ///
  /// In pt, this message translates to:
  /// **'{value}K visualizações'**
  String socialViewsK(String value);

  /// No description provided for @socialViewsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} visualizações'**
  String socialViewsCount(int count);

  /// No description provided for @socialPlatformInstagram.
  ///
  /// In pt, this message translates to:
  /// **'INSTAGRAM'**
  String get socialPlatformInstagram;

  /// No description provided for @socialPlatformYoutube.
  ///
  /// In pt, this message translates to:
  /// **'YOUTUBE'**
  String get socialPlatformYoutube;

  /// No description provided for @socialPlatformX.
  ///
  /// In pt, this message translates to:
  /// **'X'**
  String get socialPlatformX;

  /// No description provided for @newsTitle.
  ///
  /// In pt, this message translates to:
  /// **'NOTÍCIAS'**
  String get newsTitle;

  /// No description provided for @newsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as notícias'**
  String get newsLoadError;

  /// No description provided for @newsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma notícia por aqui ainda'**
  String get newsEmptyTitle;

  /// No description provided for @newsEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Volte mais tarde para conferir as novidades do {club}.'**
  String newsEmptyMessage(String club);

  /// No description provided for @newsSourceLabel.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{FONTE: GOIÁS ESPORTE CLUBE} other{FONTE: {club}}}'**
  String newsSourceLabel(String clubCode, String club);

  /// No description provided for @newsOpenOriginal.
  ///
  /// In pt, this message translates to:
  /// **'Abrir matéria original'**
  String get newsOpenOriginal;

  /// No description provided for @newsPdfLoadErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o PDF'**
  String get newsPdfLoadErrorTitle;

  /// No description provided for @newsPdfShareButton.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar PDF'**
  String get newsPdfShareButton;

  /// No description provided for @relTimeNow.
  ///
  /// In pt, this message translates to:
  /// **'agora'**
  String get relTimeNow;

  /// No description provided for @relTimeMinutes.
  ///
  /// In pt, this message translates to:
  /// **'{n}min'**
  String relTimeMinutes(int n);

  /// No description provided for @relTimeHours.
  ///
  /// In pt, this message translates to:
  /// **'{n}h'**
  String relTimeHours(int n);

  /// No description provided for @relTimeDays.
  ///
  /// In pt, this message translates to:
  /// **'{n}d'**
  String relTimeDays(int n);

  /// No description provided for @relTimeWeeks.
  ///
  /// In pt, this message translates to:
  /// **'{n}sem'**
  String relTimeWeeks(int n);

  /// No description provided for @relTimeMonths.
  ///
  /// In pt, this message translates to:
  /// **'{n}m'**
  String relTimeMonths(int n);

  /// No description provided for @partnersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Parceiros do {clubName}'**
  String partnersTitle(String clubName);

  /// No description provided for @partnersSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Marcas que caminham junto com o {clubName}.'**
  String partnersSubtitle(String clubName);

  /// No description provided for @partnersOpenInstagram.
  ///
  /// In pt, this message translates to:
  /// **'Abrir Instagram de {name}'**
  String partnersOpenInstagram(String name);

  /// No description provided for @partnersOpenWebsite.
  ///
  /// In pt, this message translates to:
  /// **'Abrir site de {name}'**
  String partnersOpenWebsite(String name);

  /// No description provided for @partnersTierInstitutional.
  ///
  /// In pt, this message translates to:
  /// **'Institucional'**
  String get partnersTierInstitutional;

  /// No description provided for @partnersTierPremium.
  ///
  /// In pt, this message translates to:
  /// **'Patrocinadores Premium'**
  String get partnersTierPremium;

  /// No description provided for @partnersTierRegional.
  ///
  /// In pt, this message translates to:
  /// **'Patrocinadores Regionais'**
  String get partnersTierRegional;

  /// No description provided for @partnersTierOfficialSupplier.
  ///
  /// In pt, this message translates to:
  /// **'Fornecedores Oficiais'**
  String get partnersTierOfficialSupplier;

  /// No description provided for @squadTitle.
  ///
  /// In pt, this message translates to:
  /// **'ELENCO'**
  String get squadTitle;

  /// No description provided for @squadLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o elenco'**
  String get squadLoadError;

  /// No description provided for @squadEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Elenco indisponível no momento'**
  String get squadEmpty;

  /// No description provided for @squadClubHistory.
  ///
  /// In pt, this message translates to:
  /// **'Carreira'**
  String get squadClubHistory;

  /// No description provided for @squadAboutSection.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get squadAboutSection;

  /// No description provided for @squadCareerStatsLine.
  ///
  /// In pt, this message translates to:
  /// **'{matches} jogos · {goals} gols'**
  String squadCareerStatsLine(String matches, String goals);

  /// No description provided for @squadNumber.
  ///
  /// In pt, this message translates to:
  /// **'Número'**
  String get squadNumber;

  /// No description provided for @squadAge.
  ///
  /// In pt, this message translates to:
  /// **'Idade'**
  String get squadAge;

  /// No description provided for @squadAgeValue.
  ///
  /// In pt, this message translates to:
  /// **'{age} anos'**
  String squadAgeValue(int age);

  /// No description provided for @squadNationality.
  ///
  /// In pt, this message translates to:
  /// **'Nacionalidade'**
  String get squadNationality;

  /// No description provided for @squadHeight.
  ///
  /// In pt, this message translates to:
  /// **'Altura'**
  String get squadHeight;

  /// No description provided for @squadFoot.
  ///
  /// In pt, this message translates to:
  /// **'Pé'**
  String get squadFoot;

  /// No description provided for @squadLoanTag.
  ///
  /// In pt, this message translates to:
  /// **'(emp.)'**
  String get squadLoanTag;

  /// No description provided for @squadDataUnconfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Dado não confirmado na fonte.'**
  String get squadDataUnconfirmed;

  /// No description provided for @squadGroupGoalkeepers.
  ///
  /// In pt, this message translates to:
  /// **'Goleiros'**
  String get squadGroupGoalkeepers;

  /// No description provided for @squadGroupDefenders.
  ///
  /// In pt, this message translates to:
  /// **'Zagueiros'**
  String get squadGroupDefenders;

  /// No description provided for @squadGroupRightBacks.
  ///
  /// In pt, this message translates to:
  /// **'Laterais-direitos'**
  String get squadGroupRightBacks;

  /// No description provided for @squadGroupLeftBacks.
  ///
  /// In pt, this message translates to:
  /// **'Laterais-esquerdos'**
  String get squadGroupLeftBacks;

  /// No description provided for @squadGroupDefensiveMids.
  ///
  /// In pt, this message translates to:
  /// **'Volantes'**
  String get squadGroupDefensiveMids;

  /// No description provided for @squadGroupMidfielders.
  ///
  /// In pt, this message translates to:
  /// **'Meios-campistas'**
  String get squadGroupMidfielders;

  /// No description provided for @squadGroupForwards.
  ///
  /// In pt, this message translates to:
  /// **'Atacantes'**
  String get squadGroupForwards;

  /// No description provided for @squadInstagramLabel.
  ///
  /// In pt, this message translates to:
  /// **'Instagram'**
  String get squadInstagramLabel;

  /// No description provided for @validatorNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu nome completo.'**
  String get validatorNameRequired;

  /// No description provided for @validatorEmailRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu e-mail.'**
  String get validatorEmailRequired;

  /// No description provided for @validatorEmailInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Informe um e-mail válido.'**
  String get validatorEmailInvalid;

  /// No description provided for @validatorPasswordRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe sua senha.'**
  String get validatorPasswordRequired;

  /// No description provided for @validatorPasswordCreate.
  ///
  /// In pt, this message translates to:
  /// **'Crie uma senha.'**
  String get validatorPasswordCreate;

  /// No description provided for @validatorPasswordMinLength.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter ao menos {min} caracteres.'**
  String validatorPasswordMinLength(int min);

  /// No description provided for @validatorConfirmRequired.
  ///
  /// In pt, this message translates to:
  /// **'Confirme sua senha.'**
  String get validatorConfirmRequired;

  /// No description provided for @validatorPasswordsDoNotMatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem.'**
  String get validatorPasswordsDoNotMatch;

  /// No description provided for @validatorPhoneRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu telefone.'**
  String get validatorPhoneRequired;

  /// No description provided for @validatorZipRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o CEP.'**
  String get validatorZipRequired;

  /// No description provided for @checkEmailResent.
  ///
  /// In pt, this message translates to:
  /// **'E-mail reenviado. Confira sua caixa de entrada.'**
  String get checkEmailResent;

  /// No description provided for @checkEmailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirme seu e-mail'**
  String get checkEmailTitle;

  /// No description provided for @checkEmailResending.
  ///
  /// In pt, this message translates to:
  /// **'Reenviando...'**
  String get checkEmailResending;

  /// No description provided for @checkEmailResendIn.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar em {seconds}s'**
  String checkEmailResendIn(int seconds);

  /// No description provided for @checkEmailResend.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar código'**
  String get checkEmailResend;

  /// No description provided for @checkEmailOtpSentTo.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um código de 6 dígitos para'**
  String get checkEmailOtpSentTo;

  /// No description provided for @checkEmailConfirmButton.
  ///
  /// In pt, this message translates to:
  /// **'CONFIRMAR CÓDIGO'**
  String get checkEmailConfirmButton;

  /// No description provided for @checkEmailDidNotReceive.
  ///
  /// In pt, this message translates to:
  /// **'Não recebeu o código?'**
  String get checkEmailDidNotReceive;

  /// No description provided for @checkEmailChangeEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail incorreto? Alterar e-mail'**
  String get checkEmailChangeEmail;

  /// No description provided for @checkEmailChangeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alterar e-mail?'**
  String get checkEmailChangeTitle;

  /// No description provided for @checkEmailChangeMessage.
  ///
  /// In pt, this message translates to:
  /// **'Isso encerra este cadastro e abre um novo, pra você digitar o e-mail correto.'**
  String get checkEmailChangeMessage;

  /// No description provided for @checkEmailChangeConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Alterar e-mail'**
  String get checkEmailChangeConfirm;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar nova senha'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma nova senha para acessar sua conta.'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetPasswordSuccessTitle.
  ///
  /// In pt, this message translates to:
  /// **'Senha alterada com sucesso'**
  String get resetPasswordSuccessTitle;

  /// No description provided for @resetPasswordSuccessMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sua senha foi atualizada. Entre novamente para continuar.'**
  String get resetPasswordSuccessMessage;

  /// No description provided for @forgotVerifyEmailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confira seu e-mail'**
  String get forgotVerifyEmailTitle;

  /// No description provided for @forgotSentDescription.
  ///
  /// In pt, this message translates to:
  /// **'Se este e-mail tiver uma conta no aplicativo do {club}, você vai receber um link de redefinição em instantes:'**
  String forgotSentDescription(String club);

  /// No description provided for @forgotNotReceived.
  ///
  /// In pt, this message translates to:
  /// **'Não recebeu?'**
  String get forgotNotReceived;

  /// No description provided for @forgotResendSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Se a conta existir, reenviamos o e-mail.'**
  String get forgotResendSuccess;

  /// No description provided for @commonGotIt.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get commonGotIt;

  /// No description provided for @forgotTitle.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar senha'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Digite seu e-mail para receber o link de redefinição.'**
  String get forgotSubtitle;

  /// No description provided for @forgotSendButton.
  ///
  /// In pt, this message translates to:
  /// **'Enviar link'**
  String get forgotSendButton;

  /// No description provided for @forgotSending.
  ///
  /// In pt, this message translates to:
  /// **'Enviando...'**
  String get forgotSending;

  /// No description provided for @authShowPassword.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar senha'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar senha'**
  String get authHidePassword;

  /// No description provided for @ticketsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os ingressos.'**
  String get ticketsLoadError;

  /// No description provided for @ticketsNextEvent.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMO EVENTO'**
  String get ticketsNextEvent;

  /// No description provided for @ticketsQuickAccess.
  ///
  /// In pt, this message translates to:
  /// **'ACESSO RÁPIDO'**
  String get ticketsQuickAccess;

  /// No description provided for @ticketsMyTickets.
  ///
  /// In pt, this message translates to:
  /// **'Meus ingressos'**
  String get ticketsMyTickets;

  /// No description provided for @ticketsMyTicketsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ingressos para partidas do {club}'**
  String ticketsMyTicketsSubtitle(String club);

  /// No description provided for @ticketsMyOrders.
  ///
  /// In pt, this message translates to:
  /// **'Meus pedidos'**
  String get ticketsMyOrders;

  /// No description provided for @ticketsMyOrdersSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico das suas compras'**
  String get ticketsMyOrdersSubtitle;

  /// No description provided for @ticketsNoEvents.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum evento disponível no momento'**
  String get ticketsNoEvents;

  /// No description provided for @ticketsNoEventsMessage.
  ///
  /// In pt, this message translates to:
  /// **'Quando uma nova partida estiver disponível para venda ou check-in, ela aparecerá aqui.'**
  String get ticketsNoEventsMessage;

  /// No description provided for @ticketsMyTicketsTitle.
  ///
  /// In pt, this message translates to:
  /// **'MEUS INGRESSOS'**
  String get ticketsMyTicketsTitle;

  /// No description provided for @ticketsMyTicketsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seus ingressos'**
  String get ticketsMyTicketsLoadError;

  /// No description provided for @ticketsMyTicketsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não possui ingressos'**
  String get ticketsMyTicketsEmpty;

  /// No description provided for @ticketsMyTicketsEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Seus ingressos para partidas do {club} aparecerão aqui.'**
  String ticketsMyTicketsEmptyMessage(String club);

  /// No description provided for @ticketsMyOrdersTitle.
  ///
  /// In pt, this message translates to:
  /// **'MEUS PEDIDOS'**
  String get ticketsMyOrdersTitle;

  /// No description provided for @ticketsMyOrdersLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seus pedidos'**
  String get ticketsMyOrdersLoadError;

  /// No description provided for @ticketsMyOrdersEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum pedido encontrado'**
  String get ticketsMyOrdersEmpty;

  /// No description provided for @ticketsMyOrdersEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Suas compras de ingressos aparecerão aqui.'**
  String get ticketsMyOrdersEmptyMessage;

  /// No description provided for @ticketsOrderNumber.
  ///
  /// In pt, this message translates to:
  /// **'Pedido {number}'**
  String ticketsOrderNumber(String number);

  /// No description provided for @ticketStatusValid.
  ///
  /// In pt, this message translates to:
  /// **'Válido'**
  String get ticketStatusValid;

  /// No description provided for @ticketStatusUsed.
  ///
  /// In pt, this message translates to:
  /// **'Utilizado'**
  String get ticketStatusUsed;

  /// No description provided for @ticketStatusCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get ticketStatusCancelled;

  /// No description provided for @ticketStatusExpired.
  ///
  /// In pt, this message translates to:
  /// **'Expirado'**
  String get ticketStatusExpired;

  /// No description provided for @ticketStatusRefunded.
  ///
  /// In pt, this message translates to:
  /// **'Reembolsado'**
  String get ticketStatusRefunded;

  /// No description provided for @orderStatusConfirmed.
  ///
  /// In pt, this message translates to:
  /// **'Confirmado'**
  String get orderStatusConfirmed;

  /// No description provided for @orderStatusPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get orderStatusPending;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusRefunded.
  ///
  /// In pt, this message translates to:
  /// **'Reembolsado'**
  String get orderStatusRefunded;

  /// No description provided for @ticketsCheckinUnavailableLabel.
  ///
  /// In pt, this message translates to:
  /// **'CHECK-IN AINDA NÃO DISPONÍVEL'**
  String get ticketsCheckinUnavailableLabel;

  /// No description provided for @ticketsCheckinUnavailableButton.
  ///
  /// In pt, this message translates to:
  /// **'Check-in em breve'**
  String get ticketsCheckinUnavailableButton;

  /// No description provided for @ticketsCheckinAvailableFrom.
  ///
  /// In pt, this message translates to:
  /// **'Disponível a partir de {date} às {time}'**
  String ticketsCheckinAvailableFrom(String date, String time);

  /// No description provided for @ticketsCheckinAvailableLabel.
  ///
  /// In pt, this message translates to:
  /// **'SEU PLANO PERMITE ACESSO A ESTA PARTIDA'**
  String get ticketsCheckinAvailableLabel;

  /// No description provided for @ticketsCheckInButton.
  ///
  /// In pt, this message translates to:
  /// **'Fazer check-in'**
  String get ticketsCheckInButton;

  /// No description provided for @ticketsDeclinedLabel.
  ///
  /// In pt, this message translates to:
  /// **'VOCÊ MARCOU QUE NÃO VAI DESTA VEZ'**
  String get ticketsDeclinedLabel;

  /// No description provided for @ticketsChangedMindButton.
  ///
  /// In pt, this message translates to:
  /// **'Mudei de ideia'**
  String get ticketsChangedMindButton;

  /// No description provided for @ticketsCheckinClosedLabel.
  ///
  /// In pt, this message translates to:
  /// **'CHECK-IN ENCERRADO PARA ESTA PARTIDA'**
  String get ticketsCheckinClosedLabel;

  /// No description provided for @ticketsCheckinClosedButton.
  ///
  /// In pt, this message translates to:
  /// **'Check-in encerrado'**
  String get ticketsCheckinClosedButton;

  /// No description provided for @ticketsCheckinAwayGameLabel.
  ///
  /// In pt, this message translates to:
  /// **'CHECK-IN DISPONÍVEL SÓ NO JOGO EM CASA'**
  String get ticketsCheckinAwayGameLabel;

  /// No description provided for @ticketsViewTicketButton.
  ///
  /// In pt, this message translates to:
  /// **'Visualizar ingresso'**
  String get ticketsViewTicketButton;

  /// No description provided for @ticketsSaleUpcomingLabel.
  ///
  /// In pt, this message translates to:
  /// **'VENDA AINDA NÃO ABERTA'**
  String get ticketsSaleUpcomingLabel;

  /// No description provided for @ticketsSaleUpcomingButton.
  ///
  /// In pt, this message translates to:
  /// **'Venda em breve'**
  String get ticketsSaleUpcomingButton;

  /// No description provided for @ticketsSaleStartsAt.
  ///
  /// In pt, this message translates to:
  /// **'Início da venda: {date} às {time}'**
  String ticketsSaleStartsAt(String date, String time);

  /// No description provided for @ticketsSaleOpenLabel.
  ///
  /// In pt, this message translates to:
  /// **'INGRESSOS DISPONÍVEIS'**
  String get ticketsSaleOpenLabel;

  /// No description provided for @ticketsBuyTicketButton.
  ///
  /// In pt, this message translates to:
  /// **'Comprar ingresso'**
  String get ticketsBuyTicketButton;

  /// No description provided for @ticketsSoldOutLabel.
  ///
  /// In pt, this message translates to:
  /// **'INGRESSOS ESGOTADOS'**
  String get ticketsSoldOutLabel;

  /// No description provided for @ticketsSoldOutButton.
  ///
  /// In pt, this message translates to:
  /// **'Esgotado'**
  String get ticketsSoldOutButton;

  /// No description provided for @ticketsSaleClosedLabel.
  ///
  /// In pt, this message translates to:
  /// **'VENDA ENCERRADA PARA ESTA PARTIDA'**
  String get ticketsSaleClosedLabel;

  /// No description provided for @ticketsSaleClosedButton.
  ///
  /// In pt, this message translates to:
  /// **'Venda encerrada'**
  String get ticketsSaleClosedButton;

  /// No description provided for @ticketsSaleAwayGameLabel.
  ///
  /// In pt, this message translates to:
  /// **'INGRESSOS SÓ COM O CLUBE MANDANTE'**
  String get ticketsSaleAwayGameLabel;

  /// No description provided for @ticketsCheckinConfirmedLabel.
  ///
  /// In pt, this message translates to:
  /// **'CHECK-IN CONFIRMADO'**
  String get ticketsCheckinConfirmedLabel;

  /// No description provided for @ticketsUndoCheckInButton.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer check-in'**
  String get ticketsUndoCheckInButton;

  /// No description provided for @ticketsChangeCheckInButton.
  ///
  /// In pt, this message translates to:
  /// **'Alterar check-in'**
  String get ticketsChangeCheckInButton;

  /// No description provided for @ticketsConfirmPresenceTitle.
  ///
  /// In pt, this message translates to:
  /// **'CONFIRMAR PRESENÇA'**
  String get ticketsConfirmPresenceTitle;

  /// No description provided for @ticketsGoToMatchButton.
  ///
  /// In pt, this message translates to:
  /// **'Vou ao jogo'**
  String get ticketsGoToMatchButton;

  /// No description provided for @ticketsNotThisTimeButton.
  ///
  /// In pt, this message translates to:
  /// **'Não dessa vez'**
  String get ticketsNotThisTimeButton;

  /// No description provided for @ticketsDeclineConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que não vai?'**
  String get ticketsDeclineConfirmTitle;

  /// No description provided for @ticketsDeclineConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{A Serrinha fica diferente com você lá. O Goiás conta com o apoio da Nação Esmeraldina! 💚\n\nVocê ainda poderá mudar de ideia enquanto o check-in estiver aberto.} other{O estádio fica diferente com você lá. O {club} conta com o apoio da torcida! 💚\n\nVocê ainda poderá mudar de ideia enquanto o check-in estiver aberto.}}'**
  String ticketsDeclineConfirmMessage(String clubCode, String club);

  /// No description provided for @ticketsWantToGoButton.
  ///
  /// In pt, this message translates to:
  /// **'Quero ir ao jogo'**
  String get ticketsWantToGoButton;

  /// No description provided for @ticketsConfirmDeclineButton.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar que não vou'**
  String get ticketsConfirmDeclineButton;

  /// No description provided for @ticketsCheckinSuccessTitle.
  ///
  /// In pt, this message translates to:
  /// **'Check-in realizado!'**
  String get ticketsCheckinSuccessTitle;

  /// No description provided for @ticketsCheckinSuccessMessage.
  ///
  /// In pt, this message translates to:
  /// **'O ingresso também está disponível no menu Meus Ingressos.'**
  String get ticketsCheckinSuccessMessage;

  /// No description provided for @ticketsCloseButton.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get ticketsCloseButton;

  /// No description provided for @ticketsSaveTicketButton.
  ///
  /// In pt, this message translates to:
  /// **'Salvar ingresso'**
  String get ticketsSaveTicketButton;

  /// No description provided for @ticketsSectorPickerTitle.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{Onde você quer apoiar o Verdão?} other{Onde você quer apoiar o {club}?}}'**
  String ticketsSectorPickerTitle(String clubCode, String club);

  /// No description provided for @ticketsSectorPickerSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o setor para esta partida.'**
  String get ticketsSectorPickerSubtitle;

  /// No description provided for @ticketsConfirmCheckInButton.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar check-in'**
  String get ticketsConfirmCheckInButton;

  /// No description provided for @ticketsViewTicketTitle.
  ///
  /// In pt, this message translates to:
  /// **'MEU INGRESSO'**
  String get ticketsViewTicketTitle;

  /// No description provided for @ticketsMatchInfoTitle.
  ///
  /// In pt, this message translates to:
  /// **'INFORMAÇÕES DA PARTIDA'**
  String get ticketsMatchInfoTitle;

  /// No description provided for @ticketsHomeCrowdLabel.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{TORCIDA DO GOIÁS} other{TORCIDA DO {club}}}'**
  String ticketsHomeCrowdLabel(String clubCode, String club);

  /// No description provided for @ticketsAwayCrowdLabel.
  ///
  /// In pt, this message translates to:
  /// **'TORCIDA VISITANTE'**
  String get ticketsAwayCrowdLabel;

  /// No description provided for @ticketsContinueButton.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get ticketsContinueButton;

  /// No description provided for @ticketsTicketCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 ingresso} other{{count} ingressos}}'**
  String ticketsTicketCount(num count);

  /// No description provided for @ticketsSummaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'RESUMO DA COMPRA'**
  String get ticketsSummaryTitle;

  /// No description provided for @ticketsTotalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get ticketsTotalLabel;

  /// No description provided for @ticketsHolderDataTitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{DADOS DO TITULAR} other{DADOS DOS TITULARES}}'**
  String ticketsHolderDataTitle(int count);

  /// No description provided for @ticketsHolderSlotLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ingresso {index} · {sector} · {category}'**
  String ticketsHolderSlotLabel(int index, String sector, String category);

  /// No description provided for @ticketsHolderIsSelfCheckbox.
  ///
  /// In pt, this message translates to:
  /// **'Este ingresso é para mim'**
  String get ticketsHolderIsSelfCheckbox;

  /// No description provided for @ticketsDocumentLabel.
  ///
  /// In pt, this message translates to:
  /// **'CPF ou passaporte'**
  String get ticketsDocumentLabel;

  /// No description provided for @ticketsNominalWarning.
  ///
  /// In pt, this message translates to:
  /// **'O ingresso é nominal e intransferível. Confira os dados antes de continuar.'**
  String get ticketsNominalWarning;

  /// No description provided for @ticketsFinalizePurchaseButton.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar compra'**
  String get ticketsFinalizePurchaseButton;

  /// No description provided for @ticketsPurchaseSuccessTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ingresso comprado!'**
  String get ticketsPurchaseSuccessTitle;

  /// No description provided for @ticketsPurchaseSuccessMessage.
  ///
  /// In pt, this message translates to:
  /// **'O ingresso também está disponível no menu Meus Ingressos.'**
  String get ticketsPurchaseSuccessMessage;

  /// No description provided for @ticketsTabUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'Próximos'**
  String get ticketsTabUpcoming;

  /// No description provided for @ticketsTabHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get ticketsTabHistory;

  /// No description provided for @ticketsUndoCheckInConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer check-in?'**
  String get ticketsUndoCheckInConfirmTitle;

  /// No description provided for @ticketsUndoCheckInConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Seu acesso para esta partida será cancelado e sua vaga poderá ser disponibilizada novamente.\n\nVocê poderá realizar um novo check-in enquanto o período permanecer aberto.'**
  String get ticketsUndoCheckInConfirmMessage;

  /// No description provided for @ticketsKeepCheckInButton.
  ///
  /// In pt, this message translates to:
  /// **'Manter check-in'**
  String get ticketsKeepCheckInButton;

  /// No description provided for @ticketsOriginCheckIn.
  ///
  /// In pt, this message translates to:
  /// **'Check-in Sócio'**
  String get ticketsOriginCheckIn;

  /// No description provided for @ticketsOriginPurchase.
  ///
  /// In pt, this message translates to:
  /// **'Compra'**
  String get ticketsOriginPurchase;

  /// No description provided for @ticketsViewRelatedTicket.
  ///
  /// In pt, this message translates to:
  /// **'Ver ingresso'**
  String get ticketsViewRelatedTicket;

  /// No description provided for @ticketsLoadUserDataError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seus dados. Tente novamente.'**
  String get ticketsLoadUserDataError;

  /// No description provided for @ticketsNotMemberTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não é sócio'**
  String get ticketsNotMemberTitle;

  /// No description provided for @ticketsNotMemberMessage.
  ///
  /// In pt, this message translates to:
  /// **'O check-in é exclusivo pra quem já tem o {programName} ativo.'**
  String ticketsNotMemberMessage(String programName);

  /// No description provided for @ticketsNotMemberGoToMembershipButton.
  ///
  /// In pt, this message translates to:
  /// **'Conhecer os planos'**
  String get ticketsNotMemberGoToMembershipButton;

  /// No description provided for @ticketsRequestRefundButton.
  ///
  /// In pt, this message translates to:
  /// **'Solicitar reembolso'**
  String get ticketsRequestRefundButton;

  /// No description provided for @ticketsRefundConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Solicitar reembolso'**
  String get ticketsRefundConfirmTitle;

  /// No description provided for @ticketsRefundConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza de que deseja solicitar o reembolso deste ingresso?\n\nApós a confirmação, este ingresso deixará de ser válido.'**
  String get ticketsRefundConfirmMessage;

  /// No description provided for @ticketsRefundConfirmButton.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar reembolso'**
  String get ticketsRefundConfirmButton;

  /// No description provided for @ticketsRefundCancelButton.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get ticketsRefundCancelButton;

  /// No description provided for @ticketsRefundErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível reembolsar'**
  String get ticketsRefundErrorTitle;

  /// No description provided for @ticketsRefundErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir o reembolso deste ingresso. Tente novamente.'**
  String get ticketsRefundErrorMessage;

  /// No description provided for @ticketsViewDetailsButton.
  ///
  /// In pt, this message translates to:
  /// **'Ver detalhes'**
  String get ticketsViewDetailsButton;

  /// No description provided for @ticketsRefundDetailsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ingresso reembolsado'**
  String get ticketsRefundDetailsTitle;

  /// No description provided for @ticketsRefundDetailsStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get ticketsRefundDetailsStatusLabel;

  /// No description provided for @ticketsRefundDetailsMatchLabel.
  ///
  /// In pt, this message translates to:
  /// **'Jogo'**
  String get ticketsRefundDetailsMatchLabel;

  /// No description provided for @ticketsRefundDetailsTicketLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ingresso'**
  String get ticketsRefundDetailsTicketLabel;

  /// No description provided for @ticketsRefundDetailsRequestedAtLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data da solicitação'**
  String get ticketsRefundDetailsRequestedAtLabel;

  /// No description provided for @ticketsDemoDisclaimerBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta compra é simulada. Nenhuma cobrança será realizada e o ingresso gerado não é válido para entrada no estádio.'**
  String get ticketsDemoDisclaimerBody;

  /// No description provided for @ticketsDemoTag.
  ///
  /// In pt, this message translates to:
  /// **'Ingresso demonstrativo'**
  String get ticketsDemoTag;

  /// No description provided for @ticketsRefundDemoNotice.
  ///
  /// In pt, this message translates to:
  /// **'Esta simulação não envolve nenhum valor real — nada será estornado.'**
  String get ticketsRefundDemoNotice;

  /// No description provided for @ticketsRefundDemoConcludedNote.
  ///
  /// In pt, this message translates to:
  /// **'Reembolso demonstrativo — nenhum valor foi movimentado.'**
  String get ticketsRefundDemoConcludedNote;

  /// No description provided for @ticketsHalfPriceTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de meia-entrada'**
  String get ticketsHalfPriceTypeLabel;

  /// No description provided for @ticketsHalfPriceLawOption.
  ///
  /// In pt, this message translates to:
  /// **'Por lei'**
  String get ticketsHalfPriceLawOption;

  /// No description provided for @ticketsHalfPricePromotionalOption.
  ///
  /// In pt, this message translates to:
  /// **'Promocional'**
  String get ticketsHalfPricePromotionalOption;

  /// No description provided for @ticketsHalfPriceProofLabel.
  ///
  /// In pt, this message translates to:
  /// **'Comprovante de meia-entrada (obrigatório)'**
  String get ticketsHalfPriceProofLabel;

  /// No description provided for @ticketsHalfPriceProofUploadButton.
  ///
  /// In pt, this message translates to:
  /// **'Anexar comprovante'**
  String get ticketsHalfPriceProofUploadButton;

  /// No description provided for @ticketsHalfPriceProofUploaded.
  ///
  /// In pt, this message translates to:
  /// **'Comprovante enviado'**
  String get ticketsHalfPriceProofUploaded;

  /// No description provided for @ticketPdfDemoWatermark.
  ///
  /// In pt, this message translates to:
  /// **'DEMONSTRAÇÃO\nNÃO VÁLIDO PARA ENTRADA'**
  String get ticketPdfDemoWatermark;

  /// No description provided for @ticketPdfDemoQrCaption.
  ///
  /// In pt, this message translates to:
  /// **'QR demonstrativo'**
  String get ticketPdfDemoQrCaption;

  /// No description provided for @ticketPdfFieldVenue.
  ///
  /// In pt, this message translates to:
  /// **'Local'**
  String get ticketPdfFieldVenue;

  /// No description provided for @ticketPdfFieldGate.
  ///
  /// In pt, this message translates to:
  /// **'Portão'**
  String get ticketPdfFieldGate;

  /// No description provided for @ticketPdfFieldCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get ticketPdfFieldCategory;

  /// No description provided for @ticketPdfFieldDocument.
  ///
  /// In pt, this message translates to:
  /// **'CPF/Passaporte'**
  String get ticketPdfFieldDocument;

  /// No description provided for @ticketPdfFieldOrigin.
  ///
  /// In pt, this message translates to:
  /// **'Origem'**
  String get ticketPdfFieldOrigin;

  /// No description provided for @ticketPdfFieldAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get ticketPdfFieldAmount;

  /// No description provided for @ticketPdfFieldCode.
  ///
  /// In pt, this message translates to:
  /// **'Código'**
  String get ticketPdfFieldCode;

  /// No description provided for @ticketPdfAntiScalpingTitle.
  ///
  /// In pt, this message translates to:
  /// **'NÃO COMPRE\nDE CAMBISTAS!'**
  String get ticketPdfAntiScalpingTitle;

  /// No description provided for @ticketPdfAntiScalpingSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'O ingresso pode ser falso.'**
  String get ticketPdfAntiScalpingSubtitle;

  /// No description provided for @ticketPdfFooterNotice.
  ///
  /// In pt, this message translates to:
  /// **'Ingresso pessoal e intransferível. Obrigatória a apresentação de documento com foto na entrada. Permitida somente camisa do {club} ou da Seleção Brasileira.'**
  String ticketPdfFooterNotice(String club);

  /// No description provided for @ticketPdfInvalidTicket.
  ///
  /// In pt, this message translates to:
  /// **'INGRESSO\nINVÁLIDO'**
  String get ticketPdfInvalidTicket;

  /// No description provided for @penaltyFinalResult.
  ///
  /// In pt, this message translates to:
  /// **'RESULTADO FINAL'**
  String get penaltyFinalResult;

  /// No description provided for @penaltyConverted.
  ///
  /// In pt, this message translates to:
  /// **'Você converteu {goals} de {total} cobranças'**
  String penaltyConverted(int goals, int total);

  /// No description provided for @penaltyScoreLabel.
  ///
  /// In pt, this message translates to:
  /// **'PÊNALTIS'**
  String get penaltyScoreLabel;

  /// No description provided for @penaltyDragToShoot.
  ///
  /// In pt, this message translates to:
  /// **'Arraste a bola para chutar'**
  String get penaltyDragToShoot;

  /// No description provided for @penaltyGoalsCount.
  ///
  /// In pt, this message translates to:
  /// **'{goals, plural, =1{1 Gol} other{{goals} Gols}}'**
  String penaltyGoalsCount(int goals);

  /// No description provided for @penaltyGoalsCountUpper.
  ///
  /// In pt, this message translates to:
  /// **'{goals, plural, =1{1 GOL} other{{goals} GOLS}}'**
  String penaltyGoalsCountUpper(int goals);

  /// No description provided for @penaltyResultGoal.
  ///
  /// In pt, this message translates to:
  /// **'GOL!'**
  String get penaltyResultGoal;

  /// No description provided for @penaltyResultSave.
  ///
  /// In pt, this message translates to:
  /// **'DEFESA!'**
  String get penaltyResultSave;

  /// No description provided for @penaltyResultOut.
  ///
  /// In pt, this message translates to:
  /// **'PRA FORA!'**
  String get penaltyResultOut;

  /// No description provided for @penaltyResultPost.
  ///
  /// In pt, this message translates to:
  /// **'NA TRAVE!'**
  String get penaltyResultPost;

  /// No description provided for @penaltyResultGoalShort.
  ///
  /// In pt, this message translates to:
  /// **'Gol'**
  String get penaltyResultGoalShort;

  /// No description provided for @penaltyResultSaveShort.
  ///
  /// In pt, this message translates to:
  /// **'Defesa'**
  String get penaltyResultSaveShort;

  /// No description provided for @penaltyResultOutShort.
  ///
  /// In pt, this message translates to:
  /// **'Fora'**
  String get penaltyResultOutShort;

  /// No description provided for @penaltyResultPostShort.
  ///
  /// In pt, this message translates to:
  /// **'Trave'**
  String get penaltyResultPostShort;

  /// No description provided for @playerPositionGolFull.
  ///
  /// In pt, this message translates to:
  /// **'Goleiro'**
  String get playerPositionGolFull;

  /// No description provided for @playerPositionGolShort.
  ///
  /// In pt, this message translates to:
  /// **'GOL'**
  String get playerPositionGolShort;

  /// No description provided for @playerPositionZagFull.
  ///
  /// In pt, this message translates to:
  /// **'Zagueiro'**
  String get playerPositionZagFull;

  /// No description provided for @playerPositionZagShort.
  ///
  /// In pt, this message translates to:
  /// **'ZAG'**
  String get playerPositionZagShort;

  /// No description provided for @playerPositionLdFull.
  ///
  /// In pt, this message translates to:
  /// **'Lateral-direito'**
  String get playerPositionLdFull;

  /// No description provided for @playerPositionLdShort.
  ///
  /// In pt, this message translates to:
  /// **'LD'**
  String get playerPositionLdShort;

  /// No description provided for @playerPositionLeFull.
  ///
  /// In pt, this message translates to:
  /// **'Lateral-esquerdo'**
  String get playerPositionLeFull;

  /// No description provided for @playerPositionLeShort.
  ///
  /// In pt, this message translates to:
  /// **'LE'**
  String get playerPositionLeShort;

  /// No description provided for @playerPositionAldFull.
  ///
  /// In pt, this message translates to:
  /// **'Ala-direito'**
  String get playerPositionAldFull;

  /// No description provided for @playerPositionAldShort.
  ///
  /// In pt, this message translates to:
  /// **'ALD'**
  String get playerPositionAldShort;

  /// No description provided for @playerPositionAleFull.
  ///
  /// In pt, this message translates to:
  /// **'Ala-esquerdo'**
  String get playerPositionAleFull;

  /// No description provided for @playerPositionAleShort.
  ///
  /// In pt, this message translates to:
  /// **'ALE'**
  String get playerPositionAleShort;

  /// No description provided for @playerPositionVolFull.
  ///
  /// In pt, this message translates to:
  /// **'Volante'**
  String get playerPositionVolFull;

  /// No description provided for @playerPositionVolShort.
  ///
  /// In pt, this message translates to:
  /// **'VOL'**
  String get playerPositionVolShort;

  /// No description provided for @playerPositionMcFull.
  ///
  /// In pt, this message translates to:
  /// **'Meio-campista'**
  String get playerPositionMcFull;

  /// No description provided for @playerPositionMcShort.
  ///
  /// In pt, this message translates to:
  /// **'MC'**
  String get playerPositionMcShort;

  /// No description provided for @playerPositionMeiFull.
  ///
  /// In pt, this message translates to:
  /// **'Meia'**
  String get playerPositionMeiFull;

  /// No description provided for @playerPositionMeiShort.
  ///
  /// In pt, this message translates to:
  /// **'MEI'**
  String get playerPositionMeiShort;

  /// No description provided for @playerPositionMdFull.
  ///
  /// In pt, this message translates to:
  /// **'Meia-direita'**
  String get playerPositionMdFull;

  /// No description provided for @playerPositionMdShort.
  ///
  /// In pt, this message translates to:
  /// **'MD'**
  String get playerPositionMdShort;

  /// No description provided for @playerPositionMeFull.
  ///
  /// In pt, this message translates to:
  /// **'Meia-esquerda'**
  String get playerPositionMeFull;

  /// No description provided for @playerPositionMeShort.
  ///
  /// In pt, this message translates to:
  /// **'ME'**
  String get playerPositionMeShort;

  /// No description provided for @playerPositionPdFull.
  ///
  /// In pt, this message translates to:
  /// **'Ponta-direita'**
  String get playerPositionPdFull;

  /// No description provided for @playerPositionPdShort.
  ///
  /// In pt, this message translates to:
  /// **'PD'**
  String get playerPositionPdShort;

  /// No description provided for @playerPositionPeFull.
  ///
  /// In pt, this message translates to:
  /// **'Ponta-esquerda'**
  String get playerPositionPeFull;

  /// No description provided for @playerPositionPeShort.
  ///
  /// In pt, this message translates to:
  /// **'PE'**
  String get playerPositionPeShort;

  /// No description provided for @playerPositionSaFull.
  ///
  /// In pt, this message translates to:
  /// **'Segundo atacante'**
  String get playerPositionSaFull;

  /// No description provided for @playerPositionSaShort.
  ///
  /// In pt, this message translates to:
  /// **'SA'**
  String get playerPositionSaShort;

  /// No description provided for @playerPositionAtaFull.
  ///
  /// In pt, this message translates to:
  /// **'Atacante'**
  String get playerPositionAtaFull;

  /// No description provided for @playerPositionAtaShort.
  ///
  /// In pt, this message translates to:
  /// **'ATA'**
  String get playerPositionAtaShort;

  /// No description provided for @crowdTitle.
  ///
  /// In pt, this message translates to:
  /// **'ESCALAÇÃO DA TORCIDA'**
  String get crowdTitle;

  /// No description provided for @crowdTabEscale.
  ///
  /// In pt, this message translates to:
  /// **'ESCALE'**
  String get crowdTabEscale;

  /// No description provided for @crowdSubmissionsLabel.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{escalação enviada} other{escalações enviadas}}'**
  String crowdSubmissionsLabel(int count);

  /// No description provided for @crowdMostVotedFormation.
  ///
  /// In pt, this message translates to:
  /// **'formação escolhida'**
  String get crowdMostVotedFormation;

  /// No description provided for @crowdNoVotes.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há votos'**
  String get crowdNoVotes;

  /// No description provided for @crowdNoVotesMessage.
  ///
  /// In pt, this message translates to:
  /// **'Seja o primeiro a escalar o {club} e ajude a formar o time da torcida.'**
  String crowdNoVotesMessage(String club);

  /// No description provided for @crowdVotingClosed.
  ///
  /// In pt, this message translates to:
  /// **'Votação encerrada — esta é a escalação que você enviou.'**
  String get crowdVotingClosed;

  /// No description provided for @crowdUpdateLineup.
  ///
  /// In pt, this message translates to:
  /// **'ATUALIZAR ESCALAÇÃO'**
  String get crowdUpdateLineup;

  /// No description provided for @crowdConfirmLineup.
  ///
  /// In pt, this message translates to:
  /// **'CONFIRMAR ESCALAÇÃO'**
  String get crowdConfirmLineup;

  /// No description provided for @crowdPickPlayer.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o jogador para esta posição'**
  String get crowdPickPlayer;

  /// No description provided for @crowdSelectedPlayer.
  ///
  /// In pt, this message translates to:
  /// **'Escalado'**
  String get crowdSelectedPlayer;

  /// No description provided for @crowdAlsoCanPlaySection.
  ///
  /// In pt, this message translates to:
  /// **'TAMBÉM PODE ATUAR'**
  String get crowdAlsoCanPlaySection;

  /// No description provided for @crowdCanAlsoPlayBadge.
  ///
  /// In pt, this message translates to:
  /// **'Pode atuar'**
  String get crowdCanAlsoPlayBadge;

  /// No description provided for @crowdCardDescVoted.
  ///
  /// In pt, this message translates to:
  /// **'Veja como a torcida está escalando o {club} para o próximo jogo.'**
  String crowdCardDescVoted(String club);

  /// No description provided for @crowdCardDescNew.
  ///
  /// In pt, this message translates to:
  /// **'Escale o {club} para o próximo jogo e veja o time mais escalado pela torcida.'**
  String crowdCardDescNew(String club);

  /// No description provided for @clubSectionHistory.
  ///
  /// In pt, this message translates to:
  /// **'História'**
  String get clubSectionHistory;

  /// No description provided for @clubSectionSquad.
  ///
  /// In pt, this message translates to:
  /// **'Elenco'**
  String get clubSectionSquad;

  /// No description provided for @clubSectionTitles.
  ///
  /// In pt, this message translates to:
  /// **'Títulos'**
  String get clubSectionTitles;

  /// No description provided for @clubSectionPartners.
  ///
  /// In pt, this message translates to:
  /// **'Parceiros'**
  String get clubSectionPartners;

  /// No description provided for @clubSectionBoard.
  ///
  /// In pt, this message translates to:
  /// **'Diretoria'**
  String get clubSectionBoard;

  /// No description provided for @clubBoardSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Conselhos, presidência e diretoria do clube.'**
  String get clubBoardSubtitle;

  /// No description provided for @clubBoardLoadErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a diretoria'**
  String get clubBoardLoadErrorTitle;

  /// No description provided for @clubBoardEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Diretoria em atualização'**
  String get clubBoardEmptyTitle;

  /// No description provided for @clubBoardEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Volte em breve para conferir a diretoria do clube.'**
  String get clubBoardEmptyMessage;

  /// No description provided for @clubSectionTransparency.
  ///
  /// In pt, this message translates to:
  /// **'Transparência'**
  String get clubSectionTransparency;

  /// No description provided for @clubTransparencySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Balanços, atas e demonstrativos contábeis.'**
  String get clubTransparencySubtitle;

  /// No description provided for @clubTransparencyLoadErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a transparência'**
  String get clubTransparencyLoadErrorTitle;

  /// No description provided for @clubTransparencyEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum documento disponível'**
  String get clubTransparencyEmptyTitle;

  /// No description provided for @clubTransparencyEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Volte em breve para conferir os documentos.'**
  String get clubTransparencyEmptyMessage;

  /// No description provided for @clubTransparencyDocumentCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhum documento} =1{1 documento} other{{count} documentos}}'**
  String clubTransparencyDocumentCount(num count);

  /// No description provided for @clubTransparencyShareButton.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar PDF'**
  String get clubTransparencyShareButton;

  /// No description provided for @clubSectionTimeline.
  ///
  /// In pt, this message translates to:
  /// **'Linha do Tempo'**
  String get clubSectionTimeline;

  /// No description provided for @clubSectionSongs.
  ///
  /// In pt, this message translates to:
  /// **'Hino & Músicas'**
  String get clubSectionSongs;

  /// No description provided for @clubHistorySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'De {year} até os dias de hoje.'**
  String clubHistorySubtitle(String year);

  /// No description provided for @clubSquadSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Os jogadores que vestem a camisa.'**
  String get clubSquadSubtitle;

  /// No description provided for @clubTitlesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{count} conquistas ao longo da história.'**
  String clubTitlesSubtitle(int count);

  /// No description provided for @clubPartnersSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Quem caminha junto com o {clubName}.'**
  String clubPartnersSubtitle(String clubName);

  /// No description provided for @clubSongsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Hino e músicas que embalam a torcida.'**
  String get clubSongsSubtitle;

  /// No description provided for @clubSectionIdols.
  ///
  /// In pt, this message translates to:
  /// **'Ídolos'**
  String get clubSectionIdols;

  /// No description provided for @clubIdolsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Nomes que marcaram a história do clube.'**
  String get clubIdolsSubtitle;

  /// No description provided for @clubIdolsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 ídolo} other{{count} ídolos}}'**
  String clubIdolsCount(int count);

  /// No description provided for @clubIdolMatches.
  ///
  /// In pt, this message translates to:
  /// **'Jogos'**
  String get clubIdolMatches;

  /// No description provided for @clubIdolGoals.
  ///
  /// In pt, this message translates to:
  /// **'Gols'**
  String get clubIdolGoals;

  /// No description provided for @clubIdolTitles.
  ///
  /// In pt, this message translates to:
  /// **'TÍTULOS'**
  String get clubIdolTitles;

  /// No description provided for @clubIdolHighlights.
  ///
  /// In pt, this message translates to:
  /// **'CAMPANHAS E MOMENTOS'**
  String get clubIdolHighlights;

  /// No description provided for @clubIdolStory.
  ///
  /// In pt, this message translates to:
  /// **'HISTÓRIA'**
  String get clubIdolStory;

  /// No description provided for @clubIdolStatsAsOf.
  ///
  /// In pt, this message translates to:
  /// **'Números até {date}'**
  String clubIdolStatsAsOf(String date);

  /// No description provided for @clubAnthemSection.
  ///
  /// In pt, this message translates to:
  /// **'HINO'**
  String get clubAnthemSection;

  /// No description provided for @clubSongsSection.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{MÚSICAS ESMERALDINAS} other{MÚSICAS DO {club}}}'**
  String clubSongsSection(String clubCode, String club);

  /// No description provided for @clubLyricsLabel.
  ///
  /// In pt, this message translates to:
  /// **'LETRA'**
  String get clubLyricsLabel;

  /// No description provided for @clubLyricsUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Letra ainda não disponível.'**
  String get clubLyricsUnavailable;

  /// No description provided for @clubAudioUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Áudio indisponível no momento.'**
  String get clubAudioUnavailable;

  /// No description provided for @clubPlaybackError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível reproduzir esta música.'**
  String get clubPlaybackError;

  /// No description provided for @clubMuteSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Silenciar'**
  String get clubMuteSemantics;

  /// No description provided for @clubUnmuteSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Ativar som'**
  String get clubUnmuteSemantics;

  /// No description provided for @clubVolumeSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Controle de volume'**
  String get clubVolumeSemantics;

  /// No description provided for @clubPlaySongSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Reproduzir {title}'**
  String clubPlaySongSemantics(String title);

  /// No description provided for @clubPauseSongSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Pausar {title}'**
  String clubPauseSongSemantics(String title);

  /// No description provided for @clubMainTitles.
  ///
  /// In pt, this message translates to:
  /// **'TÍTULOS PRINCIPAIS'**
  String get clubMainTitles;

  /// No description provided for @clubHistoricCampaigns.
  ///
  /// In pt, this message translates to:
  /// **'CAMPANHAS HISTÓRICAS'**
  String get clubHistoricCampaigns;

  /// No description provided for @clubTimesChampion.
  ///
  /// In pt, this message translates to:
  /// **'{count}× CAMPEÃO'**
  String clubTimesChampion(int count);

  /// No description provided for @clubEntryTitle.
  ///
  /// In pt, this message translates to:
  /// **'O CLUBE'**
  String get clubEntryTitle;

  /// No description provided for @clubEntrySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'História, títulos, elenco e identidade do {clubName}.'**
  String clubEntrySubtitle(String clubName);

  /// No description provided for @clubEntryCta.
  ///
  /// In pt, this message translates to:
  /// **'CONHECER O {clubName}'**
  String clubEntryCta(String clubName);

  /// No description provided for @membershipLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o {programName}.'**
  String membershipLoadError(String programName);

  /// No description provided for @membershipPlansTitle.
  ///
  /// In pt, this message translates to:
  /// **'PLANOS'**
  String get membershipPlansTitle;

  /// No description provided for @membershipSector.
  ///
  /// In pt, this message translates to:
  /// **'Setor {sector}'**
  String membershipSector(String sector);

  /// No description provided for @membershipMostChosen.
  ///
  /// In pt, this message translates to:
  /// **'MAIS ESCOLHIDO'**
  String get membershipMostChosen;

  /// No description provided for @membershipPerMonth.
  ///
  /// In pt, this message translates to:
  /// **'/mês'**
  String get membershipPerMonth;

  /// No description provided for @membershipOrAnnual.
  ///
  /// In pt, this message translates to:
  /// **'ou {price} no plano anual'**
  String membershipOrAnnual(String price);

  /// No description provided for @membershipAnnualContractInfo.
  ///
  /// In pt, this message translates to:
  /// **'Adesão anual de {total} — parcelamento equivalente a este valor por mês'**
  String membershipAnnualContractInfo(String total);

  /// No description provided for @membershipBenefits.
  ///
  /// In pt, this message translates to:
  /// **'BENEFÍCIOS'**
  String get membershipBenefits;

  /// No description provided for @membershipSeeFullRegulation.
  ///
  /// In pt, this message translates to:
  /// **'Consulte o regulamento completo →'**
  String get membershipSeeFullRegulation;

  /// No description provided for @membershipStillHaveDoubts.
  ///
  /// In pt, this message translates to:
  /// **'Ainda tem dúvidas sobre este plano?'**
  String get membershipStillHaveDoubts;

  /// No description provided for @membershipSeeFaq.
  ///
  /// In pt, this message translates to:
  /// **'VER DÚVIDAS FREQUENTES'**
  String get membershipSeeFaq;

  /// No description provided for @membershipWantToJoin.
  ///
  /// In pt, this message translates to:
  /// **'QUERO SER SÓCIO'**
  String get membershipWantToJoin;

  /// No description provided for @membershipNoStadiumAccess.
  ///
  /// In pt, this message translates to:
  /// **'Sem acesso ao estádio'**
  String get membershipNoStadiumAccess;

  /// No description provided for @membershipViewPlan.
  ///
  /// In pt, this message translates to:
  /// **'CONHECER PLANO'**
  String get membershipViewPlan;

  /// No description provided for @membershipOtherOptions.
  ///
  /// In pt, this message translates to:
  /// **'OUTRAS OPÇÕES'**
  String get membershipOtherOptions;

  /// No description provided for @membershipMyMembership.
  ///
  /// In pt, this message translates to:
  /// **'Minha associação'**
  String get membershipMyMembership;

  /// No description provided for @membershipDependents.
  ///
  /// In pt, this message translates to:
  /// **'Dependentes'**
  String get membershipDependents;

  /// No description provided for @membershipDependentsPrep.
  ///
  /// In pt, this message translates to:
  /// **'A gestão de dependentes ainda está sendo preparada.'**
  String get membershipDependentsPrep;

  /// No description provided for @membershipPayments.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos'**
  String get membershipPayments;

  /// No description provided for @membershipPaymentsPrep.
  ///
  /// In pt, this message translates to:
  /// **'O histórico de pagamentos ainda está sendo preparado.'**
  String get membershipPaymentsPrep;

  /// No description provided for @membershipCheckinHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de check-ins'**
  String get membershipCheckinHistory;

  /// No description provided for @membershipAreaPrep.
  ///
  /// In pt, this message translates to:
  /// **'Essa área ainda está sendo preparada.'**
  String get membershipAreaPrep;

  /// No description provided for @membershipSeeOtherPlans.
  ///
  /// In pt, this message translates to:
  /// **'Conhecer outros planos'**
  String get membershipSeeOtherPlans;

  /// No description provided for @membershipHeroTitle.
  ///
  /// In pt, this message translates to:
  /// **'Esteja ainda mais próximo\ndo {club}.'**
  String membershipHeroTitle(String club);

  /// No description provided for @membershipHeroSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Faça parte dessa história com prioridade de acesso ao estádio, economia em ingressos, descontos e experiências exclusivas.'**
  String get membershipHeroSubtitle;

  /// No description provided for @membershipChoosePlan.
  ///
  /// In pt, this message translates to:
  /// **'ESCOLHA SEU PLANO'**
  String get membershipChoosePlan;

  /// No description provided for @membershipChosenPlan.
  ///
  /// In pt, this message translates to:
  /// **'PLANO ESCOLHIDO'**
  String get membershipChosenPlan;

  /// No description provided for @membershipChangePlan.
  ///
  /// In pt, this message translates to:
  /// **'ALTERAR PLANO'**
  String get membershipChangePlan;

  /// No description provided for @membershipStep1Access.
  ///
  /// In pt, this message translates to:
  /// **'1 de 3 · Dados de acesso'**
  String get membershipStep1Access;

  /// No description provided for @membershipStep2Personal.
  ///
  /// In pt, this message translates to:
  /// **'2 de 3 · Dados cadastrais'**
  String get membershipStep2Personal;

  /// No description provided for @membershipStep3Address.
  ///
  /// In pt, this message translates to:
  /// **'3 de 3 · Endereço'**
  String get membershipStep3Address;

  /// No description provided for @membershipCpf.
  ///
  /// In pt, this message translates to:
  /// **'CPF'**
  String get membershipCpf;

  /// No description provided for @membershipNationality.
  ///
  /// In pt, this message translates to:
  /// **'Nacionalidade'**
  String get membershipNationality;

  /// No description provided for @membershipPassport.
  ///
  /// In pt, this message translates to:
  /// **'Passaporte'**
  String get membershipPassport;

  /// No description provided for @membershipPassportOptional.
  ///
  /// In pt, this message translates to:
  /// **'Passaporte (opcional)'**
  String get membershipPassportOptional;

  /// No description provided for @membershipContactEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail de contato'**
  String get membershipContactEmail;

  /// No description provided for @membershipNickname.
  ///
  /// In pt, this message translates to:
  /// **'Apelido (opcional)'**
  String get membershipNickname;

  /// No description provided for @membershipBirthdateHint.
  ///
  /// In pt, this message translates to:
  /// **'DD/MM/AAAA'**
  String get membershipBirthdateHint;

  /// No description provided for @membershipGender.
  ///
  /// In pt, this message translates to:
  /// **'Sexo'**
  String get membershipGender;

  /// No description provided for @membershipGenderMale.
  ///
  /// In pt, this message translates to:
  /// **'Masculino'**
  String get membershipGenderMale;

  /// No description provided for @membershipGenderFemale.
  ///
  /// In pt, this message translates to:
  /// **'Feminino'**
  String get membershipGenderFemale;

  /// No description provided for @membershipHomePhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone residencial (opcional)'**
  String get membershipHomePhone;

  /// No description provided for @membershipNewsletter.
  ///
  /// In pt, this message translates to:
  /// **'Desejo receber notícias do clube e do {programName} por e-mail.'**
  String membershipNewsletter(String programName);

  /// No description provided for @membershipCountry.
  ///
  /// In pt, this message translates to:
  /// **'País'**
  String get membershipCountry;

  /// No description provided for @membershipPostalCode.
  ///
  /// In pt, this message translates to:
  /// **'Código postal'**
  String get membershipPostalCode;

  /// No description provided for @membershipDontKnowCep.
  ///
  /// In pt, this message translates to:
  /// **'Não sei meu CEP'**
  String get membershipDontKnowCep;

  /// No description provided for @membershipLoadingCities.
  ///
  /// In pt, this message translates to:
  /// **'Carregando cidades...'**
  String get membershipLoadingCities;

  /// No description provided for @membershipSelectStateFirst.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o estado primeiro'**
  String get membershipSelectStateFirst;

  /// No description provided for @membershipSelectCity.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar cidade'**
  String get membershipSelectCity;

  /// No description provided for @membershipConfirmAssociation.
  ///
  /// In pt, this message translates to:
  /// **'CONFIRMAR ASSOCIAÇÃO'**
  String get membershipConfirmAssociation;

  /// No description provided for @membershipReviewTitle.
  ///
  /// In pt, this message translates to:
  /// **'REVISE SUA ASSOCIAÇÃO'**
  String get membershipReviewTitle;

  /// No description provided for @membershipPlanLabel.
  ///
  /// In pt, this message translates to:
  /// **'Plano'**
  String get membershipPlanLabel;

  /// No description provided for @membershipSectorLabel.
  ///
  /// In pt, this message translates to:
  /// **'Setor'**
  String get membershipSectorLabel;

  /// No description provided for @membershipOptionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Opção'**
  String get membershipOptionLabel;

  /// No description provided for @membershipHolderData.
  ///
  /// In pt, this message translates to:
  /// **'DADOS DO TITULAR'**
  String get membershipHolderData;

  /// No description provided for @membershipName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get membershipName;

  /// No description provided for @membershipBirthLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nascimento'**
  String get membershipBirthLabel;

  /// No description provided for @membershipContact.
  ///
  /// In pt, this message translates to:
  /// **'CONTATO'**
  String get membershipContact;

  /// No description provided for @membershipAddressLabel.
  ///
  /// In pt, this message translates to:
  /// **'Endereço'**
  String get membershipAddressLabel;

  /// No description provided for @membershipCityUf.
  ///
  /// In pt, this message translates to:
  /// **'Cidade/UF'**
  String get membershipCityUf;

  /// No description provided for @membershipValue.
  ///
  /// In pt, this message translates to:
  /// **'VALOR'**
  String get membershipValue;

  /// No description provided for @membershipMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get membershipMonthly;

  /// No description provided for @membershipAnnual.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get membershipAnnual;

  /// No description provided for @membershipTerms.
  ///
  /// In pt, this message translates to:
  /// **'TERMOS DA ASSOCIAÇÃO'**
  String get membershipTerms;

  /// No description provided for @membershipAcceptRegulation.
  ///
  /// In pt, this message translates to:
  /// **'Li e aceito o Regulamento do {programName}'**
  String membershipAcceptRegulation(String programName);

  /// No description provided for @membershipReadFullRegulation.
  ///
  /// In pt, this message translates to:
  /// **'Ler regulamento completo →'**
  String get membershipReadFullRegulation;

  /// No description provided for @membershipDemoDisclaimerBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta adesão é simulada e não cria vínculo com o {programName}. Nenhuma cobrança será realizada.'**
  String membershipDemoDisclaimerBody(String programName);

  /// No description provided for @membershipRegulationDemoNote.
  ///
  /// In pt, this message translates to:
  /// **'A visualização/aceite nesta demonstração não constitui adesão oficial ao {programName}.'**
  String membershipRegulationDemoNote(String programName);

  /// No description provided for @membershipStatusDemoBadge.
  ///
  /// In pt, this message translates to:
  /// **'Modo Sócio — Demonstração'**
  String get membershipStatusDemoBadge;

  /// No description provided for @membershipYourMembership.
  ///
  /// In pt, this message translates to:
  /// **'SUA ASSOCIAÇÃO'**
  String get membershipYourMembership;

  /// No description provided for @membershipYourBenefits.
  ///
  /// In pt, this message translates to:
  /// **'SEUS BENEFÍCIOS'**
  String get membershipYourBenefits;

  /// No description provided for @membershipGoToMemberArea.
  ///
  /// In pt, this message translates to:
  /// **'IR PARA MINHA ÁREA DE SÓCIO'**
  String get membershipGoToMemberArea;

  /// No description provided for @membershipBackToHome.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para o início'**
  String get membershipBackToHome;

  /// No description provided for @membershipWelcome.
  ///
  /// In pt, this message translates to:
  /// **'BEM-VINDO AO\n{programName}'**
  String membershipWelcome(String programName);

  /// No description provided for @membershipSuccessMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sua associação foi concluída com sucesso.\nAgora você está ainda mais perto do {club}.'**
  String membershipSuccessMessage(String club);

  /// No description provided for @membershipAnnualPlan.
  ///
  /// In pt, this message translates to:
  /// **'Plano anual • {price}'**
  String membershipAnnualPlan(String price);

  /// No description provided for @membershipHolder.
  ///
  /// In pt, this message translates to:
  /// **'Titular'**
  String get membershipHolder;

  /// No description provided for @membershipAssociatedSince.
  ///
  /// In pt, this message translates to:
  /// **'Associado desde'**
  String get membershipAssociatedSince;

  /// No description provided for @membershipStatusActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get membershipStatusActive;

  /// No description provided for @membershipSeeAllBenefits.
  ///
  /// In pt, this message translates to:
  /// **'Ver todos os benefícios →'**
  String get membershipSeeAllBenefits;

  /// No description provided for @membershipWhatNow.
  ///
  /// In pt, this message translates to:
  /// **'E AGORA?'**
  String get membershipWhatNow;

  /// No description provided for @membershipWhatNowMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sua área de sócio já está disponível. Acompanhe seu plano e seus benefícios e, quando disponível, faça o check-in nos jogos.'**
  String get membershipWhatNowMessage;

  /// No description provided for @membershipSituation.
  ///
  /// In pt, this message translates to:
  /// **'Situação'**
  String get membershipSituation;

  /// No description provided for @membershipMemberNumber.
  ///
  /// In pt, this message translates to:
  /// **'Número do sócio'**
  String get membershipMemberNumber;

  /// No description provided for @membershipMonthlyFee.
  ///
  /// In pt, this message translates to:
  /// **'Mensalidade'**
  String get membershipMonthlyFee;

  /// No description provided for @membershipAnnualFee.
  ///
  /// In pt, this message translates to:
  /// **'Anuidade'**
  String get membershipAnnualFee;

  /// No description provided for @membershipMemberSince.
  ///
  /// In pt, this message translates to:
  /// **'Sócio desde'**
  String get membershipMemberSince;

  /// No description provided for @membershipRegulationName.
  ///
  /// In pt, this message translates to:
  /// **'Regulamento do {programName}'**
  String membershipRegulationName(String programName);

  /// No description provided for @membershipMatchAccessNotice.
  ///
  /// In pt, this message translates to:
  /// **'Seu plano permite acesso a esta partida.'**
  String get membershipMatchAccessNotice;

  /// No description provided for @membershipCardNumber.
  ///
  /// In pt, this message translates to:
  /// **'Nº {number}'**
  String membershipCardNumber(String number);

  /// No description provided for @membershipRegulationPageTitle.
  ///
  /// In pt, this message translates to:
  /// **'REGULAMENTO'**
  String get membershipRegulationPageTitle;

  /// No description provided for @membershipRegulationEffectiveSince.
  ///
  /// In pt, this message translates to:
  /// **'Em vigor desde {date}'**
  String membershipRegulationEffectiveSince(String date);

  /// No description provided for @membershipRegulationTableOfContents.
  ///
  /// In pt, this message translates to:
  /// **'CONTEÚDO'**
  String get membershipRegulationTableOfContents;

  /// No description provided for @membershipCancelWhatsapp.
  ///
  /// In pt, this message translates to:
  /// **'Olá, gostaria de cancelar minha associação {programName} ({plan}).'**
  String membershipCancelWhatsapp(String plan, String programName);

  /// No description provided for @membershipCancel.
  ///
  /// In pt, this message translates to:
  /// **'CANCELAR ASSOCIAÇÃO'**
  String get membershipCancel;

  /// No description provided for @membershipCancelInfo.
  ///
  /// In pt, this message translates to:
  /// **'O cancelamento é feito com o atendimento pelo WhatsApp, sem cobrança de multa fora dos prazos previstos no Regulamento.'**
  String get membershipCancelInfo;

  /// No description provided for @membershipStatusPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get membershipStatusPending;

  /// No description provided for @membershipStatusSuspended.
  ///
  /// In pt, this message translates to:
  /// **'Suspenso'**
  String get membershipStatusSuspended;

  /// No description provided for @membershipStatusCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get membershipStatusCancelled;

  /// No description provided for @membershipFaqTitle.
  ///
  /// In pt, this message translates to:
  /// **'DÚVIDAS FREQUENTES'**
  String get membershipFaqTitle;

  /// No description provided for @membershipFaqSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Encontre respostas sobre planos, pagamentos, check-in e benefícios.'**
  String get membershipFaqSubtitle;

  /// No description provided for @membershipFaqLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as dúvidas frequentes.'**
  String get membershipFaqLoadError;

  /// No description provided for @membershipFaqNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma dúvida encontrada'**
  String get membershipFaqNoResults;

  /// No description provided for @membershipFaqNoResultsMessage.
  ///
  /// In pt, this message translates to:
  /// **'Tente outro termo ou fale com o atendimento do {programName}.'**
  String membershipFaqNoResultsMessage(String programName);

  /// No description provided for @membershipTalkToSupport.
  ///
  /// In pt, this message translates to:
  /// **'FALAR COM O ATENDIMENTO'**
  String get membershipTalkToSupport;

  /// No description provided for @membershipTalkToSupportMenu.
  ///
  /// In pt, this message translates to:
  /// **'Falar com o atendimento'**
  String get membershipTalkToSupportMenu;

  /// No description provided for @membershipDontStayInDoubt.
  ///
  /// In pt, this message translates to:
  /// **'NÃO FIQUE NA DÚVIDA'**
  String get membershipDontStayInDoubt;

  /// No description provided for @membershipDidntFindAnswer.
  ///
  /// In pt, this message translates to:
  /// **'Não encontrou a resposta que procurava?'**
  String get membershipDidntFindAnswer;

  /// No description provided for @membershipFaqScopeNote.
  ///
  /// In pt, this message translates to:
  /// **'Dúvidas sobre o clube, categorias de base, elenco e outros assuntos fora do {programName} não são respondidas por este canal.'**
  String membershipFaqScopeNote(String programName);

  /// No description provided for @membershipFaqAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get membershipFaqAll;

  /// No description provided for @membershipFaqChipGeneral.
  ///
  /// In pt, this message translates to:
  /// **'Gerais'**
  String get membershipFaqChipGeneral;

  /// No description provided for @membershipFaqChipPayment.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento'**
  String get membershipFaqChipPayment;

  /// No description provided for @membershipFaqChipSupport.
  ///
  /// In pt, this message translates to:
  /// **'Atendimento'**
  String get membershipFaqChipSupport;

  /// No description provided for @membershipFaqChipActions.
  ///
  /// In pt, this message translates to:
  /// **'Ações'**
  String get membershipFaqChipActions;

  /// No description provided for @membershipFaqChipStadium.
  ///
  /// In pt, this message translates to:
  /// **'Estádio'**
  String get membershipFaqChipStadium;

  /// No description provided for @membershipFaqChipBenefits.
  ///
  /// In pt, this message translates to:
  /// **'Benefícios'**
  String get membershipFaqChipBenefits;

  /// No description provided for @membershipFaqChipPlans.
  ///
  /// In pt, this message translates to:
  /// **'Planos'**
  String get membershipFaqChipPlans;

  /// No description provided for @membershipFaqChipFacial.
  ///
  /// In pt, this message translates to:
  /// **'Facial'**
  String get membershipFaqChipFacial;

  /// No description provided for @membershipFaqChipRating.
  ///
  /// In pt, this message translates to:
  /// **'Rating'**
  String get membershipFaqChipRating;

  /// No description provided for @membershipFaqChipNoShow.
  ///
  /// In pt, this message translates to:
  /// **'No-Show'**
  String get membershipFaqChipNoShow;

  /// No description provided for @membershipStepAccess.
  ///
  /// In pt, this message translates to:
  /// **'Acesso'**
  String get membershipStepAccess;

  /// No description provided for @membershipStepPersonal.
  ///
  /// In pt, this message translates to:
  /// **'Cadastro'**
  String get membershipStepPersonal;

  /// No description provided for @membershipStepAddress.
  ///
  /// In pt, this message translates to:
  /// **'Endereço'**
  String get membershipStepAddress;

  /// No description provided for @membershipFaqSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar uma dúvida...'**
  String get membershipFaqSearchHint;

  /// No description provided for @membershipHelpTitle.
  ///
  /// In pt, this message translates to:
  /// **'AJUDA E INFORMAÇÕES'**
  String get membershipHelpTitle;

  /// No description provided for @membershipFaqMenuItem.
  ///
  /// In pt, this message translates to:
  /// **'Dúvidas frequentes'**
  String get membershipFaqMenuItem;

  /// No description provided for @membershipFindCepTitle.
  ///
  /// In pt, this message translates to:
  /// **'ENCONTRAR MEU CEP'**
  String get membershipFindCepTitle;

  /// No description provided for @membershipFindCepSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu endereço para encontrarmos o CEP correspondente.'**
  String get membershipFindCepSubtitle;

  /// No description provided for @membershipStreetLabel.
  ///
  /// In pt, this message translates to:
  /// **'Rua / Logradouro'**
  String get membershipStreetLabel;

  /// No description provided for @membershipSearchCep.
  ///
  /// In pt, this message translates to:
  /// **'BUSCAR CEP'**
  String get membershipSearchCep;

  /// No description provided for @membershipFoundAddresses.
  ///
  /// In pt, this message translates to:
  /// **'ENCONTRAMOS ESTES ENDEREÇOS'**
  String get membershipFoundAddresses;

  /// No description provided for @membershipNoAddressFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum endereço encontrado.'**
  String get membershipNoAddressFound;

  /// No description provided for @membershipNoAddressHint.
  ///
  /// In pt, this message translates to:
  /// **'Confira o estado, a cidade e o logradouro informados.'**
  String get membershipNoAddressHint;

  /// No description provided for @membershipAddressSearchError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível buscar o endereço.'**
  String get membershipAddressSearchError;

  /// No description provided for @membershipValCpfRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu CPF.'**
  String get membershipValCpfRequired;

  /// No description provided for @membershipValNationality.
  ///
  /// In pt, this message translates to:
  /// **'Selecione sua nacionalidade.'**
  String get membershipValNationality;

  /// No description provided for @membershipValPassport.
  ///
  /// In pt, this message translates to:
  /// **'Informe um passaporte válido.'**
  String get membershipValPassport;

  /// No description provided for @membershipValContactEmail.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu e-mail de contato.'**
  String get membershipValContactEmail;

  /// No description provided for @membershipValNameInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Informe um nome válido.'**
  String get membershipValNameInvalid;

  /// No description provided for @membershipValBirthRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe sua data de nascimento.'**
  String get membershipValBirthRequired;

  /// No description provided for @membershipValBirthInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Informe uma data válida.'**
  String get membershipValBirthInvalid;

  /// No description provided for @membershipValMinAge.
  ///
  /// In pt, this message translates to:
  /// **'O titular precisa ter 18 anos ou mais.'**
  String get membershipValMinAge;

  /// No description provided for @membershipValSelectOption.
  ///
  /// In pt, this message translates to:
  /// **'Selecione uma opção.'**
  String get membershipValSelectOption;

  /// No description provided for @membershipValPhoneRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu celular.'**
  String get membershipValPhoneRequired;

  /// No description provided for @membershipValPhoneInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Informe um celular válido.'**
  String get membershipValPhoneInvalid;

  /// No description provided for @membershipValCountry.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o país.'**
  String get membershipValCountry;

  /// No description provided for @membershipValCep8.
  ///
  /// In pt, this message translates to:
  /// **'Informe um CEP com 8 dígitos.'**
  String get membershipValCep8;

  /// No description provided for @membershipCepLookupError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível consultar o CEP.'**
  String get membershipCepLookupError;

  /// No description provided for @membershipValStreet.
  ///
  /// In pt, this message translates to:
  /// **'Informe o logradouro.'**
  String get membershipValStreet;

  /// No description provided for @membershipValNumber.
  ///
  /// In pt, this message translates to:
  /// **'Informe o número.'**
  String get membershipValNumber;

  /// No description provided for @membershipValNeighborhood.
  ///
  /// In pt, this message translates to:
  /// **'Informe o bairro.'**
  String get membershipValNeighborhood;

  /// No description provided for @membershipValState.
  ///
  /// In pt, this message translates to:
  /// **'Informe o estado.'**
  String get membershipValState;

  /// No description provided for @membershipValCity.
  ///
  /// In pt, this message translates to:
  /// **'Informe a cidade.'**
  String get membershipValCity;

  /// No description provided for @lineupShareStats.
  ///
  /// In pt, this message translates to:
  /// **'{solved}/{total} descobertos · {attempts} tentativas · {time}'**
  String lineupShareStats(int solved, int total, int attempts, String time);

  /// No description provided for @crowdShareCrowd.
  ///
  /// In pt, this message translates to:
  /// **'Confira a escalação da torcida pro {club}! 💚'**
  String crowdShareCrowd(String club);

  /// No description provided for @crowdShareMine.
  ///
  /// In pt, this message translates to:
  /// **'Essa é a minha escalação pro {club}! 💚'**
  String crowdShareMine(String club);

  /// No description provided for @crowdSubmitted.
  ///
  /// In pt, this message translates to:
  /// **'Escalação enviada!'**
  String get crowdSubmitted;

  /// No description provided for @storeHomeEntryBadge.
  ///
  /// In pt, this message translates to:
  /// **'{storeName}'**
  String storeHomeEntryBadge(String storeName);

  /// No description provided for @storeHomeEntryTitle.
  ///
  /// In pt, this message translates to:
  /// **'O manto te espera'**
  String get storeHomeEntryTitle;

  /// No description provided for @storeHomeEntryDescription.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{Leve o Verdão com você dentro e fora de campo.} other{Leve o {club} com você dentro e fora de campo.}}'**
  String storeHomeEntryDescription(String clubCode, String club);

  /// No description provided for @storeHomeEntryCta.
  ///
  /// In pt, this message translates to:
  /// **'Conhecer a loja'**
  String get storeHomeEntryCta;

  /// No description provided for @storeProfileMyOrders.
  ///
  /// In pt, this message translates to:
  /// **'Meus pedidos'**
  String get storeProfileMyOrders;

  /// No description provided for @storeHomeLoadErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a loja'**
  String get storeHomeLoadErrorTitle;

  /// No description provided for @storeHomeEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Loja em preparação'**
  String get storeHomeEmptyTitle;

  /// No description provided for @storeHomeEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Volte em breve para conferir os produtos oficiais.'**
  String get storeHomeEmptyMessage;

  /// No description provided for @storeMyPurchasesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minhas Compras'**
  String get storeMyPurchasesTitle;

  /// No description provided for @storeSectionCategories.
  ///
  /// In pt, this message translates to:
  /// **'Categorias'**
  String get storeSectionCategories;

  /// No description provided for @storeSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar na {storeName}'**
  String storeSearchHint(String storeName);

  /// No description provided for @storeListingDefaultTitle.
  ///
  /// In pt, this message translates to:
  /// **'Produtos'**
  String get storeListingDefaultTitle;

  /// No description provided for @storeSearchEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Busque por produtos'**
  String get storeSearchEmptyTitle;

  /// No description provided for @storeSearchEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Nome, categoria, coleção ou tipo de peça.'**
  String get storeSearchEmptyMessage;

  /// No description provided for @storeListingNoResultsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto encontrado'**
  String get storeListingNoResultsTitle;

  /// No description provided for @storeListingNoResultsMessage.
  ///
  /// In pt, this message translates to:
  /// **'Tente ajustar sua busca ou remover alguns filtros.'**
  String get storeListingNoResultsMessage;

  /// No description provided for @storeListingProductCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 produto} other{{count} produtos}}'**
  String storeListingProductCount(num count);

  /// No description provided for @storeItemCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} itens}}'**
  String storeItemCount(num count);

  /// No description provided for @storeOrdersMoreItems.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{+ 1 item} other{+ {count} itens}}'**
  String storeOrdersMoreItems(num count);

  /// No description provided for @storeSortLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar'**
  String get storeSortLabel;

  /// No description provided for @storeFiltersLabel.
  ///
  /// In pt, this message translates to:
  /// **'Filtros'**
  String get storeFiltersLabel;

  /// No description provided for @storeFiltersLabelCount.
  ///
  /// In pt, this message translates to:
  /// **'Filtros ({count})'**
  String storeFiltersLabelCount(Object count);

  /// No description provided for @storeSortSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por'**
  String get storeSortSheetTitle;

  /// No description provided for @storeFiltersSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Filtros'**
  String get storeFiltersSheetTitle;

  /// No description provided for @storeClearFilters.
  ///
  /// In pt, this message translates to:
  /// **'Limpar filtros'**
  String get storeClearFilters;

  /// No description provided for @storeFilterAudienceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Público'**
  String get storeFilterAudienceLabel;

  /// No description provided for @storeFilterTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get storeFilterTypeLabel;

  /// No description provided for @storeFilterUniformLabel.
  ///
  /// In pt, this message translates to:
  /// **'Uniforme'**
  String get storeFilterUniformLabel;

  /// No description provided for @storeUniform01.
  ///
  /// In pt, this message translates to:
  /// **'Uniforme 01'**
  String get storeUniform01;

  /// No description provided for @storeUniform02.
  ///
  /// In pt, this message translates to:
  /// **'Uniforme 02'**
  String get storeUniform02;

  /// No description provided for @storeUniform03.
  ///
  /// In pt, this message translates to:
  /// **'Uniforme 03'**
  String get storeUniform03;

  /// No description provided for @storeFilterSizeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho'**
  String get storeFilterSizeLabel;

  /// No description provided for @storeFilterOnlyAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Somente disponíveis'**
  String get storeFilterOnlyAvailable;

  /// No description provided for @storeFilterOnlyOnSale.
  ///
  /// In pt, this message translates to:
  /// **'Somente promoções'**
  String get storeFilterOnlyOnSale;

  /// No description provided for @storeApplyFilters.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar filtros'**
  String get storeApplyFilters;

  /// No description provided for @storeSortRelevance.
  ///
  /// In pt, this message translates to:
  /// **'Relevância'**
  String get storeSortRelevance;

  /// No description provided for @storeSortNewest.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos'**
  String get storeSortNewest;

  /// No description provided for @storeSortPriceLowToHigh.
  ///
  /// In pt, this message translates to:
  /// **'Menor preço'**
  String get storeSortPriceLowToHigh;

  /// No description provided for @storeSortPriceHighToLow.
  ///
  /// In pt, this message translates to:
  /// **'Maior preço'**
  String get storeSortPriceHighToLow;

  /// No description provided for @storeSortBiggestDiscount.
  ///
  /// In pt, this message translates to:
  /// **'Maior desconto'**
  String get storeSortBiggestDiscount;

  /// No description provided for @storeAudienceMasculine.
  ///
  /// In pt, this message translates to:
  /// **'Masculino'**
  String get storeAudienceMasculine;

  /// No description provided for @storeAudienceFeminine.
  ///
  /// In pt, this message translates to:
  /// **'Feminino'**
  String get storeAudienceFeminine;

  /// No description provided for @storeAudienceKids.
  ///
  /// In pt, this message translates to:
  /// **'Infantil'**
  String get storeAudienceKids;

  /// No description provided for @storeAudienceUnisex.
  ///
  /// In pt, this message translates to:
  /// **'Unissex'**
  String get storeAudienceUnisex;

  /// No description provided for @storeTypeMatchJersey.
  ///
  /// In pt, this message translates to:
  /// **'Jogo'**
  String get storeTypeMatchJersey;

  /// No description provided for @storeTypeGoalkeeper.
  ///
  /// In pt, this message translates to:
  /// **'Goleiro'**
  String get storeTypeGoalkeeper;

  /// No description provided for @storeTypeTraining.
  ///
  /// In pt, this message translates to:
  /// **'Treino'**
  String get storeTypeTraining;

  /// No description provided for @storeTypeCasual.
  ///
  /// In pt, this message translates to:
  /// **'Casual'**
  String get storeTypeCasual;

  /// No description provided for @storeTypeAccessory.
  ///
  /// In pt, this message translates to:
  /// **'Acessório'**
  String get storeTypeAccessory;

  /// No description provided for @storeTypeSouvenir.
  ///
  /// In pt, this message translates to:
  /// **'Souvenir'**
  String get storeTypeSouvenir;

  /// No description provided for @storeCategoryLaunches.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos'**
  String get storeCategoryLaunches;

  /// No description provided for @storeCategoryUniforms.
  ///
  /// In pt, this message translates to:
  /// **'Uniformes'**
  String get storeCategoryUniforms;

  /// No description provided for @storeCategoryAccessories.
  ///
  /// In pt, this message translates to:
  /// **'Acessórios'**
  String get storeCategoryAccessories;

  /// No description provided for @storeCategorySouvenirs.
  ///
  /// In pt, this message translates to:
  /// **'Souvenires'**
  String get storeCategorySouvenirs;

  /// No description provided for @storeCategoryPersonalizable.
  ///
  /// In pt, this message translates to:
  /// **'Personalizáveis'**
  String get storeCategoryPersonalizable;

  /// No description provided for @storeCollectionFan.
  ///
  /// In pt, this message translates to:
  /// **'Torcedor'**
  String get storeCollectionFan;

  /// No description provided for @storeCollectionPlayer.
  ///
  /// In pt, this message translates to:
  /// **'Jogador'**
  String get storeCollectionPlayer;

  /// No description provided for @storeCollectionTrainingTravel.
  ///
  /// In pt, this message translates to:
  /// **'Treino, viagem e concentração'**
  String get storeCollectionTrainingTravel;

  /// No description provided for @storeCollectionSocksGloves.
  ///
  /// In pt, this message translates to:
  /// **'Meias e luvas'**
  String get storeCollectionSocksGloves;

  /// No description provided for @storeShippingEconomyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Econômica'**
  String get storeShippingEconomyLabel;

  /// No description provided for @storeShippingStandardLabel.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get storeShippingStandardLabel;

  /// No description provided for @storeShippingExpressLabel.
  ///
  /// In pt, this message translates to:
  /// **'Expressa'**
  String get storeShippingExpressLabel;

  /// No description provided for @storeShippingEconomyEta.
  ///
  /// In pt, this message translates to:
  /// **'7 a 10 dias úteis'**
  String get storeShippingEconomyEta;

  /// No description provided for @storeShippingStandardEta.
  ///
  /// In pt, this message translates to:
  /// **'4 a 7 dias úteis'**
  String get storeShippingStandardEta;

  /// No description provided for @storeShippingExpressEta.
  ///
  /// In pt, this message translates to:
  /// **'2 a 3 dias úteis'**
  String get storeShippingExpressEta;

  /// No description provided for @storeBadgeSoldOut.
  ///
  /// In pt, this message translates to:
  /// **'Esgotado'**
  String get storeBadgeSoldOut;

  /// No description provided for @storeBadgeOnSale.
  ///
  /// In pt, this message translates to:
  /// **'Promoção'**
  String get storeBadgeOnSale;

  /// No description provided for @storeInstallmentsLabel.
  ///
  /// In pt, this message translates to:
  /// **'em até {count}x de {value}'**
  String storeInstallmentsLabel(Object count, Object value);

  /// No description provided for @storeProductLoadErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar este produto'**
  String get storeProductLoadErrorTitle;

  /// No description provided for @storeProductLoadErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'Volte e tente novamente.'**
  String get storeProductLoadErrorMessage;

  /// No description provided for @storeOrderCreateErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível confirmar seu pedido'**
  String get storeOrderCreateErrorTitle;

  /// No description provided for @storeOrderCreateErrorMessage.
  ///
  /// In pt, this message translates to:
  /// **'Verifique sua conexão e tente novamente. Sua sacola continua salva.'**
  String get storeOrderCreateErrorMessage;

  /// No description provided for @storeBackToStoreButton.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para a loja'**
  String get storeBackToStoreButton;

  /// No description provided for @storeProductSoldOut.
  ///
  /// In pt, this message translates to:
  /// **'Este produto está esgotado no momento.'**
  String get storeProductSoldOut;

  /// No description provided for @storeProductPhotoLabel.
  ///
  /// In pt, this message translates to:
  /// **'{name}, foto {index} de {total}'**
  String storeProductPhotoLabel(String name, int index, int total);

  /// No description provided for @storeZoomImageHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque para ampliar'**
  String get storeZoomImageHint;

  /// No description provided for @storeShareProduct.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar produto'**
  String get storeShareProduct;

  /// No description provided for @storeReferenceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ref.'**
  String get storeReferenceLabel;

  /// No description provided for @storeDeliveryOrPickupLabel.
  ///
  /// In pt, this message translates to:
  /// **'Entrega ou retirada'**
  String get storeDeliveryOrPickupLabel;

  /// No description provided for @storePickupFreeNote.
  ///
  /// In pt, this message translates to:
  /// **'Retirada grátis'**
  String get storePickupFreeNote;

  /// No description provided for @storeSizeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho'**
  String get storeSizeLabel;

  /// No description provided for @storeQuantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get storeQuantityLabel;

  /// No description provided for @storeDetailsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes'**
  String get storeDetailsLabel;

  /// No description provided for @storePersonalizationLabel.
  ///
  /// In pt, this message translates to:
  /// **'Personalização (opcional)'**
  String get storePersonalizationLabel;

  /// No description provided for @storePersonalizationNameField.
  ///
  /// In pt, this message translates to:
  /// **'Nome na camisa (+ {price})'**
  String storePersonalizationNameField(Object price);

  /// No description provided for @storePersonalizationNumberField.
  ///
  /// In pt, this message translates to:
  /// **'Número na camisa (+ {price})'**
  String storePersonalizationNumberField(Object price);

  /// No description provided for @storePersonalizationSurchargeNote.
  ///
  /// In pt, this message translates to:
  /// **'Acréscimo de personalização: {price}'**
  String storePersonalizationSurchargeNote(Object price);

  /// No description provided for @storeAddedToCartSnackbar.
  ///
  /// In pt, this message translates to:
  /// **'Produto adicionado à sacola.'**
  String get storeAddedToCartSnackbar;

  /// No description provided for @storeAddToCartButton.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar na sacola'**
  String get storeAddToCartButton;

  /// No description provided for @storeSeeCartAction.
  ///
  /// In pt, this message translates to:
  /// **'Ver sacola'**
  String get storeSeeCartAction;

  /// No description provided for @storeChooseSizeMessage.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um tamanho antes de adicionar à sacola.'**
  String get storeChooseSizeMessage;

  /// No description provided for @storeBuyNowButton.
  ///
  /// In pt, this message translates to:
  /// **'Comprar agora'**
  String get storeBuyNowButton;

  /// No description provided for @storeVariationSoldOut.
  ///
  /// In pt, this message translates to:
  /// **'Essa variação está esgotada.'**
  String get storeVariationSoldOut;

  /// No description provided for @storeCartTitle.
  ///
  /// In pt, this message translates to:
  /// **'SACOLA'**
  String get storeCartTitle;

  /// No description provided for @storeCartEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua sacola está vazia'**
  String get storeCartEmptyTitle;

  /// No description provided for @storeCartEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'{clubCode, select, goias{Escolha seus produtos oficiais e carregue o Verdão com você.} other{Escolha seus produtos oficiais e carregue o {club} com você.}}'**
  String storeCartEmptyMessage(String clubCode, String club);

  /// No description provided for @storeCartEmptyCta.
  ///
  /// In pt, this message translates to:
  /// **'Ir para a {storeName}'**
  String storeCartEmptyCta(String storeName);

  /// No description provided for @storeCartItemSize.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho {size}'**
  String storeCartItemSize(Object size);

  /// No description provided for @storeCartItemNumber.
  ///
  /// In pt, this message translates to:
  /// **'nº {number}'**
  String storeCartItemNumber(Object number);

  /// No description provided for @storeRemoveItemTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover item'**
  String get storeRemoveItemTitle;

  /// No description provided for @storeRemoveItemMessage.
  ///
  /// In pt, this message translates to:
  /// **'Remover \"{productName}\" da sacola?'**
  String storeRemoveItemMessage(Object productName);

  /// No description provided for @storeRemoveItemAction.
  ///
  /// In pt, this message translates to:
  /// **'Remover {productName} da sacola'**
  String storeRemoveItemAction(Object productName);

  /// No description provided for @storeRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get storeRemove;

  /// No description provided for @storeCouponHint.
  ///
  /// In pt, this message translates to:
  /// **'Cupom de desconto'**
  String get storeCouponHint;

  /// No description provided for @storeCouponApply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get storeCouponApply;

  /// No description provided for @storeCouponInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Cupom inválido ou expirado.'**
  String get storeCouponInvalid;

  /// No description provided for @storeCheckoutCta.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar compra'**
  String get storeCheckoutCta;

  /// No description provided for @storeSubtotal.
  ///
  /// In pt, this message translates to:
  /// **'Subtotal'**
  String get storeSubtotal;

  /// No description provided for @storeDiscountGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Desconto'**
  String get storeDiscountGeneric;

  /// No description provided for @storeDiscountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Desconto ({code})'**
  String storeDiscountLabel(Object code);

  /// No description provided for @storeTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get storeTotal;

  /// No description provided for @storeFreeShippingNote.
  ///
  /// In pt, this message translates to:
  /// **'Frete grátis a partir de {amount}.'**
  String storeFreeShippingNote(Object amount);

  /// No description provided for @storeFree.
  ///
  /// In pt, this message translates to:
  /// **'Grátis'**
  String get storeFree;

  /// No description provided for @storeShippingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Frete'**
  String get storeShippingLabel;

  /// No description provided for @storePickupWord.
  ///
  /// In pt, this message translates to:
  /// **'Retirada'**
  String get storePickupWord;

  /// No description provided for @storeStepIdentification.
  ///
  /// In pt, this message translates to:
  /// **'Identificação'**
  String get storeStepIdentification;

  /// No description provided for @storeStepDelivery.
  ///
  /// In pt, this message translates to:
  /// **'Entrega'**
  String get storeStepDelivery;

  /// No description provided for @storeStepPayment.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento'**
  String get storeStepPayment;

  /// No description provided for @storeStepReview.
  ///
  /// In pt, this message translates to:
  /// **'Revisão'**
  String get storeStepReview;

  /// No description provided for @storeContinueButton.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get storeContinueButton;

  /// No description provided for @storeFullNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo'**
  String get storeFullNameLabel;

  /// No description provided for @storeCpfLabel.
  ///
  /// In pt, this message translates to:
  /// **'CPF'**
  String get storeCpfLabel;

  /// No description provided for @storePhoneLabel.
  ///
  /// In pt, this message translates to:
  /// **'Telefone / WhatsApp'**
  String get storePhoneLabel;

  /// No description provided for @storeDeliveryToHome.
  ///
  /// In pt, this message translates to:
  /// **'Receber em casa'**
  String get storeDeliveryToHome;

  /// No description provided for @storePickupAtStore.
  ///
  /// In pt, this message translates to:
  /// **'Retirar na loja'**
  String get storePickupAtStore;

  /// No description provided for @storeDeliveryAddressLabel.
  ///
  /// In pt, this message translates to:
  /// **'Endereço de entrega'**
  String get storeDeliveryAddressLabel;

  /// No description provided for @storeAddAddress.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar endereço'**
  String get storeAddAddress;

  /// No description provided for @storeZipCodePrefix.
  ///
  /// In pt, this message translates to:
  /// **'CEP {zip}'**
  String storeZipCodePrefix(Object zip);

  /// No description provided for @storePickupResponsibleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quem vai retirar'**
  String get storePickupResponsibleLabel;

  /// No description provided for @storePickupSelf.
  ///
  /// In pt, this message translates to:
  /// **'Eu mesmo'**
  String get storePickupSelf;

  /// No description provided for @storePickupOther.
  ///
  /// In pt, this message translates to:
  /// **'Outra pessoa'**
  String get storePickupOther;

  /// No description provided for @storePickupResponsibleNameField.
  ///
  /// In pt, this message translates to:
  /// **'Nome de quem vai retirar'**
  String get storePickupResponsibleNameField;

  /// No description provided for @storePickupResponsibleCpfField.
  ///
  /// In pt, this message translates to:
  /// **'CPF de quem vai retirar'**
  String get storePickupResponsibleCpfField;

  /// No description provided for @storePickupSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Retirada na loja'**
  String get storePickupSectionTitle;

  /// No description provided for @storePickupBySelf.
  ///
  /// In pt, this message translates to:
  /// **'Retirada pelo próprio titular'**
  String get storePickupBySelf;

  /// No description provided for @storePickupByOther.
  ///
  /// In pt, this message translates to:
  /// **'Retirada por {name}'**
  String storePickupByOther(Object name);

  /// No description provided for @storePickupAddressPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Retirar em: {address}'**
  String storePickupAddressPrefix(Object address);

  /// No description provided for @storePaymentPix.
  ///
  /// In pt, this message translates to:
  /// **'Pix'**
  String get storePaymentPix;

  /// No description provided for @storeCreditCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão de crédito'**
  String get storeCreditCard;

  /// No description provided for @storeDemoDisclaimer.
  ///
  /// In pt, this message translates to:
  /// **'Ambiente demonstrativo. Nenhuma cobrança será realizada.'**
  String get storeDemoDisclaimer;

  /// No description provided for @storeQrCodeNote.
  ///
  /// In pt, this message translates to:
  /// **'QR Code simulado — escaneie no app do seu banco.'**
  String get storeQrCodeNote;

  /// No description provided for @storeSimulatePixButton.
  ///
  /// In pt, this message translates to:
  /// **'Simular pagamento Pix'**
  String get storeSimulatePixButton;

  /// No description provided for @storePixApproved.
  ///
  /// In pt, this message translates to:
  /// **'Pix simulado com sucesso.'**
  String get storePixApproved;

  /// No description provided for @storeCardNumberLabel.
  ///
  /// In pt, this message translates to:
  /// **'Número do cartão'**
  String get storeCardNumberLabel;

  /// No description provided for @storeCardHolderLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome impresso no cartão'**
  String get storeCardHolderLabel;

  /// No description provided for @storeCardExpiryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Validade (MM/AA)'**
  String get storeCardExpiryLabel;

  /// No description provided for @storeCardCvvLabel.
  ///
  /// In pt, this message translates to:
  /// **'CVV'**
  String get storeCardCvvLabel;

  /// No description provided for @storeInstallmentsFieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'Parcelas'**
  String get storeInstallmentsFieldLabel;

  /// No description provided for @storeInstallmentsCash.
  ///
  /// In pt, this message translates to:
  /// **'À vista — {price}'**
  String storeInstallmentsCash(Object price);

  /// No description provided for @storeInstallmentsNoInterest.
  ///
  /// In pt, this message translates to:
  /// **'{count}x de {price} sem juros'**
  String storeInstallmentsNoInterest(Object count, Object price);

  /// No description provided for @storeSimulatePaymentButton.
  ///
  /// In pt, this message translates to:
  /// **'Simular pagamento'**
  String get storeSimulatePaymentButton;

  /// No description provided for @storeCardApprovedGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Cartão aprovado (simulado).'**
  String get storeCardApprovedGeneric;

  /// No description provided for @storeCardApprovedWithDigits.
  ///
  /// In pt, this message translates to:
  /// **'Cartão final {digits} aprovado (simulado).'**
  String storeCardApprovedWithDigits(Object digits);

  /// No description provided for @storeCardFinalDigits.
  ///
  /// In pt, this message translates to:
  /// **'Cartão de crédito final {digits}'**
  String storeCardFinalDigits(Object digits);

  /// No description provided for @storeCardSummaryLine.
  ///
  /// In pt, this message translates to:
  /// **'Cartão de crédito final {digits} · {installments}x'**
  String storeCardSummaryLine(Object digits, Object installments);

  /// No description provided for @storeConfirmOrderButton.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar pedido'**
  String get storeConfirmOrderButton;

  /// No description provided for @storeEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get storeEdit;

  /// No description provided for @storeAcceptTerms.
  ///
  /// In pt, this message translates to:
  /// **'Li e aceito os termos de compra da {storeName}.'**
  String storeAcceptTerms(String storeName);

  /// No description provided for @storeOrderConfirmedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pedido confirmado!'**
  String get storeOrderConfirmedTitle;

  /// No description provided for @storeItemsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Itens'**
  String get storeItemsLabel;

  /// No description provided for @storeItemsCountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Itens ({count})'**
  String storeItemsCountLabel(Object count);

  /// No description provided for @storeTrackOrderButton.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhar pedido'**
  String get storeTrackOrderButton;

  /// No description provided for @storeContinueShoppingButton.
  ///
  /// In pt, this message translates to:
  /// **'Continuar comprando'**
  String get storeContinueShoppingButton;

  /// No description provided for @storeBackHomeButton.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao início'**
  String get storeBackHomeButton;

  /// No description provided for @storeOrdersTitle.
  ///
  /// In pt, this message translates to:
  /// **'MEUS PEDIDOS'**
  String get storeOrdersTitle;

  /// No description provided for @storeOrdersEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não fez nenhum pedido'**
  String get storeOrdersEmptyTitle;

  /// No description provided for @storeOrdersEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Seus pedidos na {storeName} aparecerão aqui.'**
  String storeOrdersEmptyMessage(String storeName);

  /// No description provided for @storeOrdersLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seus pedidos'**
  String get storeOrdersLoadError;

  /// No description provided for @storeOrderCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Pedido cancelado'**
  String get storeOrderCancelled;

  /// No description provided for @storeCustomerLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cliente'**
  String get storeCustomerLabel;

  /// No description provided for @storeStatusStepDone.
  ///
  /// In pt, this message translates to:
  /// **'concluído'**
  String get storeStatusStepDone;

  /// No description provided for @storeStatusStepPending.
  ///
  /// In pt, this message translates to:
  /// **'pendente'**
  String get storeStatusStepPending;

  /// No description provided for @storeStatusCreated.
  ///
  /// In pt, this message translates to:
  /// **'Pedido realizado'**
  String get storeStatusCreated;

  /// No description provided for @storeStatusPaymentPending.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando pagamento'**
  String get storeStatusPaymentPending;

  /// No description provided for @storeStatusPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento aprovado'**
  String get storeStatusPaid;

  /// No description provided for @storeStatusPreparing.
  ///
  /// In pt, this message translates to:
  /// **'Em preparação'**
  String get storeStatusPreparing;

  /// No description provided for @storeStatusReadyForPickup.
  ///
  /// In pt, this message translates to:
  /// **'Pronto para retirada'**
  String get storeStatusReadyForPickup;

  /// No description provided for @storeStatusShipped.
  ///
  /// In pt, this message translates to:
  /// **'Enviado'**
  String get storeStatusShipped;

  /// No description provided for @storeStatusDeliveredPickup.
  ///
  /// In pt, this message translates to:
  /// **'Retirado'**
  String get storeStatusDeliveredPickup;

  /// No description provided for @storeStatusDeliveredShipping.
  ///
  /// In pt, this message translates to:
  /// **'Entregue'**
  String get storeStatusDeliveredShipping;

  /// No description provided for @storeStatusCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get storeStatusCancelled;

  /// No description provided for @storeAddressesTitle.
  ///
  /// In pt, this message translates to:
  /// **'ENDEREÇOS DE ENTREGA'**
  String get storeAddressesTitle;

  /// No description provided for @storeAddressesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha onde deseja receber seus pedidos.'**
  String get storeAddressesSubtitle;

  /// No description provided for @storeAddressesEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum endereço salvo'**
  String get storeAddressesEmptyTitle;

  /// No description provided for @storeAddressesEmptyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Adicione um endereço pra agilizar suas próximas compras.'**
  String get storeAddressesEmptyMessage;

  /// No description provided for @storeRemoveAddressTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover endereço'**
  String get storeRemoveAddressTitle;

  /// No description provided for @storeRemoveAddressMessage.
  ///
  /// In pt, this message translates to:
  /// **'Remover \"{address}\"?'**
  String storeRemoveAddressMessage(Object address);

  /// No description provided for @storeDefaultBadge.
  ///
  /// In pt, this message translates to:
  /// **'PADRÃO'**
  String get storeDefaultBadge;

  /// No description provided for @storeMakeDefault.
  ///
  /// In pt, this message translates to:
  /// **'Tornar padrão'**
  String get storeMakeDefault;

  /// No description provided for @storeNewAddressTitle.
  ///
  /// In pt, this message translates to:
  /// **'NOVO ENDEREÇO'**
  String get storeNewAddressTitle;

  /// No description provided for @storeEditAddressTitle.
  ///
  /// In pt, this message translates to:
  /// **'EDITAR ENDEREÇO'**
  String get storeEditAddressTitle;

  /// No description provided for @storeZipCodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'CEP'**
  String get storeZipCodeLabel;

  /// No description provided for @storeStreetLabel.
  ///
  /// In pt, this message translates to:
  /// **'Rua / Avenida'**
  String get storeStreetLabel;

  /// No description provided for @storeNumberLabel.
  ///
  /// In pt, this message translates to:
  /// **'Número'**
  String get storeNumberLabel;

  /// No description provided for @storeComplementLabel.
  ///
  /// In pt, this message translates to:
  /// **'Complemento (opcional)'**
  String get storeComplementLabel;

  /// No description provided for @storeNeighborhoodLabel.
  ///
  /// In pt, this message translates to:
  /// **'Bairro'**
  String get storeNeighborhoodLabel;

  /// No description provided for @storeCityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cidade'**
  String get storeCityLabel;

  /// No description provided for @storeStateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get storeStateLabel;

  /// No description provided for @storeSaveAddressButton.
  ///
  /// In pt, this message translates to:
  /// **'Salvar endereço'**
  String get storeSaveAddressButton;

  /// No description provided for @storeAddressLabelField.
  ///
  /// In pt, this message translates to:
  /// **'Apelido (opcional)'**
  String get storeAddressLabelField;

  /// No description provided for @storeAddressLabelHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Casa, Trabalho'**
  String get storeAddressLabelHint;

  /// No description provided for @storeUseResidentialAddress.
  ///
  /// In pt, this message translates to:
  /// **'Usar meu endereço residencial'**
  String get storeUseResidentialAddress;

  /// No description provided for @storeDeliveryAddressSummaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'ENDEREÇO DE ENTREGA'**
  String get storeDeliveryAddressSummaryTitle;

  /// No description provided for @storeChangeAddressButton.
  ///
  /// In pt, this message translates to:
  /// **'Alterar'**
  String get storeChangeAddressButton;

  /// No description provided for @storeChooseDeliveryAddressTitle.
  ///
  /// In pt, this message translates to:
  /// **'ESCOLHA ONDE RECEBER'**
  String get storeChooseDeliveryAddressTitle;

  /// No description provided for @storeNoDeliveryAddressTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não possui endereço de entrega.'**
  String get storeNoDeliveryAddressTitle;

  /// No description provided for @storeAddAnotherAddress.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar outro endereço'**
  String get storeAddAnotherAddress;

  /// No description provided for @storeValFullNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome completo.'**
  String get storeValFullNameRequired;

  /// No description provided for @storeValFullNameIncomplete.
  ///
  /// In pt, this message translates to:
  /// **'Informe nome e sobrenome.'**
  String get storeValFullNameIncomplete;

  /// No description provided for @storeValPhoneInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Telefone inválido.'**
  String get storeValPhoneInvalid;

  /// No description provided for @storeValCpfRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o CPF.'**
  String get storeValCpfRequired;

  /// No description provided for @storeValCpfInvalid.
  ///
  /// In pt, this message translates to:
  /// **'CPF inválido.'**
  String get storeValCpfInvalid;

  /// No description provided for @storeValZipInvalid.
  ///
  /// In pt, this message translates to:
  /// **'CEP inválido.'**
  String get storeValZipInvalid;

  /// No description provided for @releaseGateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atualização necessária'**
  String get releaseGateTitle;

  /// No description provided for @releaseGateMessage.
  ///
  /// In pt, this message translates to:
  /// **'Esta versão do app não é mais suportada. Atualize para continuar.'**
  String get releaseGateMessage;

  /// No description provided for @releaseGateUpdateButton.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar agora'**
  String get releaseGateUpdateButton;

  /// Pergunta da Identidade Futebolística que cita o clube ativo.
  ///
  /// In pt, this message translates to:
  /// **'O adversário pressiona sua saída de bola e fecha os passes curtos. O que seu {club} faz?'**
  String tacticalQ01(String club);

  /// No description provided for @tacticalQ01A.
  ///
  /// In pt, this message translates to:
  /// **'Continua saindo curto, atraindo a pressão até encontrar o homem livre.'**
  String get tacticalQ01A;

  /// No description provided for @tacticalQ01B.
  ///
  /// In pt, this message translates to:
  /// **'Tenta sair curto, mas se a pressão encaixar busca imediatamente o espaço nas costas.'**
  String get tacticalQ01B;

  /// No description provided for @tacticalQ01C.
  ///
  /// In pt, this message translates to:
  /// **'Aciona o atacante ou o corredor diretamente e prepara a equipe para ganhar a segunda bola.'**
  String get tacticalQ01C;

  /// No description provided for @tacticalQ01D.
  ///
  /// In pt, this message translates to:
  /// **'Identifica onde a pressão rival é mais vulnerável e escolhe a saída por ali, curta ou longa.'**
  String get tacticalQ01D;

  /// No description provided for @tacticalQ02.
  ///
  /// In pt, this message translates to:
  /// **'Seu time recupera a bola no meio-campo com o adversário ainda desorganizado. Qual é a primeira ideia?'**
  String get tacticalQ02;

  /// No description provided for @tacticalQ02A.
  ///
  /// In pt, this message translates to:
  /// **'Retém a bola, aproxima o time e organiza o ataque.'**
  String get tacticalQ02A;

  /// No description provided for @tacticalQ02B.
  ///
  /// In pt, this message translates to:
  /// **'Procura o passe para frente se houver vantagem; se não houver, mantém a posse.'**
  String get tacticalQ02B;

  /// No description provided for @tacticalQ02C.
  ///
  /// In pt, this message translates to:
  /// **'Acelera imediatamente e tenta chegar ao gol em poucos passes.'**
  String get tacticalQ02C;

  /// No description provided for @tacticalQ02D.
  ///
  /// In pt, this message translates to:
  /// **'Decide pela posição dos adversários e pela superioridade numérica daquele lance.'**
  String get tacticalQ02D;

  /// Pergunta da Identidade Futebolística que cita o clube ativo.
  ///
  /// In pt, this message translates to:
  /// **'O {club} vence por 1 a 0 fora de casa aos 75 minutos.'**
  String tacticalQ03(String club);

  /// No description provided for @tacticalQ03A.
  ///
  /// In pt, this message translates to:
  /// **'Não muda o comportamento. Se o plano trouxe a vantagem, continua igual.'**
  String get tacticalQ03A;

  /// No description provided for @tacticalQ03B.
  ///
  /// In pt, this message translates to:
  /// **'Passa a controlar o jogo com mais posse e faz o adversário correr atrás da bola.'**
  String get tacticalQ03B;

  /// No description provided for @tacticalQ03C.
  ///
  /// In pt, this message translates to:
  /// **'Fecha melhor os espaços e prepara transições para matar o jogo.'**
  String get tacticalQ03C;

  /// No description provided for @tacticalQ03D.
  ///
  /// In pt, this message translates to:
  /// **'Continua pressionando e buscando o segundo gol antes que o rival cresça.'**
  String get tacticalQ03D;

  /// No description provided for @tacticalQ04.
  ///
  /// In pt, this message translates to:
  /// **'O rival estacionou duas linhas perto da própria área. Como furar o bloqueio?'**
  String get tacticalQ04;

  /// No description provided for @tacticalQ04A.
  ///
  /// In pt, this message translates to:
  /// **'Circula pacientemente até surgir o espaço certo.'**
  String get tacticalQ04A;

  /// No description provided for @tacticalQ04B.
  ///
  /// In pt, this message translates to:
  /// **'Muda posicionamentos e cria superioridade entre linhas ou pelos lados.'**
  String get tacticalQ04B;

  /// No description provided for @tacticalQ04C.
  ///
  /// In pt, this message translates to:
  /// **'Aumenta velocidade, cruzamentos, profundidade e disputa de rebotes.'**
  String get tacticalQ04C;

  /// No description provided for @tacticalQ04D.
  ///
  /// In pt, this message translates to:
  /// **'Coloca mais presença na área e muda a rota do ataque conforme a defesa reage.'**
  String get tacticalQ04D;

  /// No description provided for @tacticalQ05.
  ///
  /// In pt, this message translates to:
  /// **'Você vai enfrentar fora de casa um adversário claramente superior tecnicamente.'**
  String get tacticalQ05;

  /// No description provided for @tacticalQ05A.
  ///
  /// In pt, this message translates to:
  /// **'Mantém sua proposta de controle e saída com bola; é assim que o time joga.'**
  String get tacticalQ05A;

  /// No description provided for @tacticalQ05B.
  ///
  /// In pt, this message translates to:
  /// **'Continua tentando ter a bola, mas ajusta pressão e posicionamento ao rival.'**
  String get tacticalQ05B;

  /// No description provided for @tacticalQ05C.
  ///
  /// In pt, this message translates to:
  /// **'Aceita ter menos posse, protege os espaços e prioriza a transição.'**
  String get tacticalQ05C;

  /// No description provided for @tacticalQ05D.
  ///
  /// In pt, this message translates to:
  /// **'Pressiona alto e procura atacar rapidamente, mesmo assumindo risco.'**
  String get tacticalQ05D;

  /// No description provided for @tacticalQ06.
  ///
  /// In pt, this message translates to:
  /// **'Seu melhor jogador decide partidas, mas participa pouco da recomposição. O que fazer?'**
  String get tacticalQ06;

  /// No description provided for @tacticalQ06A.
  ///
  /// In pt, this message translates to:
  /// **'O modelo vem primeiro; se não cumprir a função, pode perder a vaga.'**
  String get tacticalQ06A;

  /// No description provided for @tacticalQ06B.
  ///
  /// In pt, this message translates to:
  /// **'Muda a função dele para manter o talento sem desequilibrar o coletivo.'**
  String get tacticalQ06B;

  /// No description provided for @tacticalQ06C.
  ///
  /// In pt, this message translates to:
  /// **'Reorganiza os companheiros para compensar e preserva o craque em zonas ofensivas.'**
  String get tacticalQ06C;

  /// No description provided for @tacticalQ06D.
  ///
  /// In pt, this message translates to:
  /// **'Dá liberdade. Jogadores especiais precisam ser tratados de maneira especial.'**
  String get tacticalQ06D;

  /// Pergunta da Identidade Futebolística que cita o clube ativo.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo. O {club} perde por 1 a 0, mas está jogando bem e criando chances.'**
  String tacticalQ07(String club);

  /// No description provided for @tacticalQ07A.
  ///
  /// In pt, this message translates to:
  /// **'Não mexe. O plano funciona e o gol será consequência.'**
  String get tacticalQ07A;

  /// No description provided for @tacticalQ07B.
  ///
  /// In pt, this message translates to:
  /// **'Faz pequenos ajustes de posicionamento sem abandonar a ideia inicial.'**
  String get tacticalQ07B;

  /// No description provided for @tacticalQ07C.
  ///
  /// In pt, this message translates to:
  /// **'Coloca mais profundidade ou outro atacante e passa a chegar mais rápido.'**
  String get tacticalQ07C;

  /// No description provided for @tacticalQ07D.
  ///
  /// In pt, this message translates to:
  /// **'Aumenta a velocidade da circulação e coloca mais jogadores entre as linhas.'**
  String get tacticalQ07D;

  /// No description provided for @tacticalQ08.
  ///
  /// In pt, this message translates to:
  /// **'Seu time perde a bola perto da área adversária. Qual reação você espera?'**
  String get tacticalQ08;

  /// No description provided for @tacticalQ08A.
  ///
  /// In pt, this message translates to:
  /// **'Pressão imediata para recuperar ali mesmo, independentemente do rival.'**
  String get tacticalQ08A;

  /// No description provided for @tacticalQ08B.
  ///
  /// In pt, this message translates to:
  /// **'Pressiona se houver jogadores suficientes perto; caso contrário, recompõe.'**
  String get tacticalQ08B;

  /// No description provided for @tacticalQ08C.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro reorganiza o bloco e fecha o centro do campo.'**
  String get tacticalQ08C;

  /// No description provided for @tacticalQ08D.
  ///
  /// In pt, this message translates to:
  /// **'Interrompe a transição e impede que o adversário consiga acelerar.'**
  String get tacticalQ08D;

  /// Pergunta da Identidade Futebolística que cita o clube ativo.
  ///
  /// In pt, this message translates to:
  /// **'Faltam dez minutos e o {club} precisa de um gol.'**
  String tacticalQ09(String club);

  /// No description provided for @tacticalQ09A.
  ///
  /// In pt, this message translates to:
  /// **'Mantém a construção paciente. Desorganização não é solução.'**
  String get tacticalQ09A;

  /// No description provided for @tacticalQ09B.
  ///
  /// In pt, this message translates to:
  /// **'Coloca jogadores mais ofensivos, mas mantém a bola no chão e a estrutura.'**
  String get tacticalQ09B;

  /// No description provided for @tacticalQ09C.
  ///
  /// In pt, this message translates to:
  /// **'Ocupa o campo adversário, joga mais direto e ataca primeira e segunda bolas.'**
  String get tacticalQ09C;

  /// No description provided for @tacticalQ09D.
  ///
  /// In pt, this message translates to:
  /// **'Muda o desenho e alterna ataques curtos e diretos conforme a defesa oferecer espaço.'**
  String get tacticalQ09D;

  /// No description provided for @tacticalQ10.
  ///
  /// In pt, this message translates to:
  /// **'Qual frase mais representa sua maneira de pensar futebol?'**
  String get tacticalQ10;

  /// No description provided for @tacticalQ10A.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro vem a nossa maneira de jogar; depois pensamos no adversário.'**
  String get tacticalQ10A;

  /// No description provided for @tacticalQ10B.
  ///
  /// In pt, this message translates to:
  /// **'Os princípios permanecem, mas esquema e estratégia podem mudar.'**
  String get tacticalQ10B;

  /// No description provided for @tacticalQ10C.
  ///
  /// In pt, this message translates to:
  /// **'Chegar ao gol rapidamente vale mais do que ter a bola por ter.'**
  String get tacticalQ10C;

  /// No description provided for @tacticalQ10D.
  ///
  /// In pt, this message translates to:
  /// **'O melhor futebol é o que potencializa nossas peças e ataca as fraquezas do rival.'**
  String get tacticalQ10D;
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
