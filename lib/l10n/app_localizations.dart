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
  /// **'Meu endereço'**
  String get profileMyAddress;

  /// No description provided for @profileSecurity.
  ///
  /// In pt, this message translates to:
  /// **'Segurança'**
  String get profileSecurity;

  /// No description provided for @profileTheme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get profileTheme;

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

  /// No description provided for @personalSelectDate.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar data'**
  String get personalSelectDate;

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
  /// **'Altere a senha da sua conta Goiás EC.'**
  String get securitySubtitle;

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
  /// **'MEU ENDEREÇO'**
  String get addressTitle;

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
  /// **'SIGA O GOIÁS'**
  String get socialFollowTitle;

  /// No description provided for @socialFollowSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe o Verdão também nas redes sociais.'**
  String get socialFollowSubtitle;

  /// No description provided for @socialOpenLink.
  ///
  /// In pt, this message translates to:
  /// **'Abrir {name}'**
  String socialOpenLink(String name);

  /// No description provided for @arenaSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Minigames rápidos para o torcedor.'**
  String get arenaSubtitle;

  /// No description provided for @arenaSectionPlayNow.
  ///
  /// In pt, this message translates to:
  /// **'JOGUE AGORA'**
  String get arenaSectionPlayNow;

  /// No description provided for @arenaSectionMoreChallenges.
  ///
  /// In pt, this message translates to:
  /// **'MAIS DESAFIOS'**
  String get arenaSectionMoreChallenges;

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

  /// No description provided for @arenaRankingBannerSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Veja os melhores da torcida nos minigames.'**
  String get arenaRankingBannerSubtitle;

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
  /// **'LENDA ESMERALDINA'**
  String get arenaAchievementTitle;

  /// No description provided for @arenaAchievementMessage.
  ///
  /// In pt, this message translates to:
  /// **'Você completou 100% da Arena Esmeraldina — Quiz do Verdão, Adivinhe a Escalação e Adivinhe o Jogador. Essa conquista é permanente.'**
  String get arenaAchievementMessage;

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

  /// No description provided for @arenaGameQuizTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quiz do Verdão'**
  String get arenaGameQuizTitle;

  /// No description provided for @arenaGameQuizTagline.
  ///
  /// In pt, this message translates to:
  /// **'Teste o quanto você conhece o Goiás.'**
  String get arenaGameQuizTagline;

  /// No description provided for @arenaGameLineupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adivinhe a Escalação'**
  String get arenaGameLineupTitle;

  /// No description provided for @arenaGameLineupTagline.
  ///
  /// In pt, this message translates to:
  /// **'Descubra os 11 titulares de uma partida histórica do Goiás.'**
  String get arenaGameLineupTagline;

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

  /// No description provided for @arenaSubtitleQuiz.
  ///
  /// In pt, this message translates to:
  /// **'60 perguntas'**
  String get arenaSubtitleQuiz;

  /// No description provided for @arenaSubtitleLineup.
  ///
  /// In pt, this message translates to:
  /// **'31 escalações'**
  String get arenaSubtitleLineup;

  /// No description provided for @arenaSubtitleCareer.
  ///
  /// In pt, this message translates to:
  /// **'23 jogadores'**
  String get arenaSubtitleCareer;

  /// No description provided for @arenaSubtitleGuessPlayer.
  ///
  /// In pt, this message translates to:
  /// **'Descubra o jogador pelas pistas'**
  String get arenaSubtitleGuessPlayer;

  /// No description provided for @commonClose.
  ///
  /// In pt, this message translates to:
  /// **'FECHAR'**
  String get commonClose;

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

  /// No description provided for @socialMediaSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Goiás na Rede'**
  String get socialMediaSubtitle;

  /// No description provided for @socialFeedLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o feed'**
  String get socialFeedLoadError;

  /// No description provided for @socialEmptyState.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe o Goiás nas redes'**
  String get socialEmptyState;

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
  /// **'Volte mais tarde para conferir as novidades do Goiás.'**
  String get newsEmptyMessage;

  /// No description provided for @newsSourceLabel.
  ///
  /// In pt, this message translates to:
  /// **'FONTE: GOIÁS ESPORTE CLUBE'**
  String get newsSourceLabel;

  /// No description provided for @newsOpenOriginal.
  ///
  /// In pt, this message translates to:
  /// **'Abrir matéria original'**
  String get newsOpenOriginal;

  /// No description provided for @newsSeeMore.
  ///
  /// In pt, this message translates to:
  /// **'Ver mais'**
  String get newsSeeMore;

  /// No description provided for @commonNoConnection.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a internet.'**
  String get commonNoConnection;

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
