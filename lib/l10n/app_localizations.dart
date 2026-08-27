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

  /// No description provided for @debugMockMembershipTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sócio ativo (mock)'**
  String get debugMockMembershipTitle;

  /// No description provided for @debugMockMembershipDescription.
  ///
  /// In pt, this message translates to:
  /// **'Simula um sócio esmeraldino ativo enquanto não há integração real com o programa.'**
  String get debugMockMembershipDescription;

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
  /// **'30 jogadores'**
  String get arenaSubtitleCareer;

  /// No description provided for @arenaSubtitleGuessPlayer.
  ///
  /// In pt, this message translates to:
  /// **'Descubra o jogador pelas pistas'**
  String get arenaSubtitleGuessPlayer;

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

  /// No description provided for @arenaRankingDetailTotal.
  ///
  /// In pt, this message translates to:
  /// **'TOTAL'**
  String get arenaRankingDetailTotal;

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
  /// **'{score} pts • {percent}%'**
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

  /// No description provided for @partnersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Parceiros do Goiás'**
  String get partnersTitle;

  /// No description provided for @partnersSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Marcas que caminham junto com o Verdão.'**
  String get partnersSubtitle;

  /// No description provided for @partnersSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'PARCEIROS DO GOIÁS'**
  String get partnersSectionTitle;

  /// No description provided for @partnersSeeAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todos'**
  String get partnersSeeAll;

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
  /// **'HISTÓRICO DE CLUBES'**
  String get squadClubHistory;

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

  /// No description provided for @squadHistoryYears.
  ///
  /// In pt, this message translates to:
  /// **'Anos'**
  String get squadHistoryYears;

  /// No description provided for @squadHistoryClubs.
  ///
  /// In pt, this message translates to:
  /// **'Clubes'**
  String get squadHistoryClubs;

  /// No description provided for @squadHistoryMatches.
  ///
  /// In pt, this message translates to:
  /// **'Jogos'**
  String get squadHistoryMatches;

  /// No description provided for @squadHistoryGoals.
  ///
  /// In pt, this message translates to:
  /// **'Gols'**
  String get squadHistoryGoals;

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

  /// No description provided for @checkEmailSentTo.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um link de confirmação para:'**
  String get checkEmailSentTo;

  /// No description provided for @checkEmailInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Abra sua caixa de entrada e confirme seu e-mail para ativar a conta.'**
  String get checkEmailInstruction;

  /// No description provided for @checkEmailBackToLogin.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para o login'**
  String get checkEmailBackToLogin;

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
  /// **'Reenviar e-mail'**
  String get checkEmailResend;

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
  /// **'Enviamos um link de redefinição para'**
  String get forgotSentDescription;

  /// No description provided for @forgotNotReceived.
  ///
  /// In pt, this message translates to:
  /// **'Não recebeu?'**
  String get forgotNotReceived;

  /// No description provided for @forgotResendSuccess.
  ///
  /// In pt, this message translates to:
  /// **'E-mail reenviado.'**
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
  /// **'Ingressos para partidas do Goiás'**
  String get ticketsMyTicketsSubtitle;

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
  /// **'Seus ingressos para partidas do Goiás aparecerão aqui.'**
  String get ticketsMyTicketsEmptyMessage;

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

  /// No description provided for @ticketsHasOwnTicketLabel.
  ///
  /// In pt, this message translates to:
  /// **'VOCÊ JÁ TEM INGRESSO PARA ESTA PARTIDA'**
  String get ticketsHasOwnTicketLabel;

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
  /// **'A Serrinha fica diferente com você lá. O Goiás conta com o apoio da Nação Esmeraldina! 💚\n\nVocê ainda poderá mudar de ideia enquanto o check-in estiver aberto.'**
  String get ticketsDeclineConfirmMessage;

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
  /// **'Onde você quer apoiar o Verdão?'**
  String get ticketsSectorPickerTitle;

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
  /// **'TORCIDA DO GOIÁS'**
  String get ticketsHomeCrowdLabel;

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
  /// **'DADOS DO TITULAR'**
  String get ticketsHolderDataTitle;

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
  /// **'formação mais votada'**
  String get crowdMostVotedFormation;

  /// No description provided for @crowdNoVotes.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há votos'**
  String get crowdNoVotes;

  /// No description provided for @crowdNoVotesMessage.
  ///
  /// In pt, this message translates to:
  /// **'Seja o primeiro a escalar o Goiás e ajude a formar o time da torcida.'**
  String get crowdNoVotesMessage;

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

  /// No description provided for @crowdCardTitleVoted.
  ///
  /// In pt, this message translates to:
  /// **'Escalação da Torcida'**
  String get crowdCardTitleVoted;

  /// No description provided for @crowdCardTitleNew.
  ///
  /// In pt, this message translates to:
  /// **'Monte a escalação da torcida'**
  String get crowdCardTitleNew;

  /// No description provided for @crowdCardDescVoted.
  ///
  /// In pt, this message translates to:
  /// **'Veja como a torcida está escalando o Goiás para o próximo jogo.'**
  String get crowdCardDescVoted;

  /// No description provided for @crowdCardDescNew.
  ///
  /// In pt, this message translates to:
  /// **'Escale o Goiás para o próximo jogo e veja o time mais escalado pela torcida.'**
  String get crowdCardDescNew;

  /// No description provided for @crowdCardCtaView.
  ///
  /// In pt, this message translates to:
  /// **'VER ESCALAÇÃO DA TORCIDA'**
  String get crowdCardCtaView;

  /// No description provided for @crowdCardCtaEscale.
  ///
  /// In pt, this message translates to:
  /// **'ESCALAR AGORA'**
  String get crowdCardCtaEscale;

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
  /// **'De 1943 até os dias de hoje.'**
  String get clubHistorySubtitle;

  /// No description provided for @clubSquadSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Os jogadores que vestem o manto.'**
  String get clubSquadSubtitle;

  /// No description provided for @clubTitlesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{count} conquistas ao longo da história.'**
  String clubTitlesSubtitle(int count);

  /// No description provided for @clubPartnersSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Quem caminha junto com o Verdão.'**
  String get clubPartnersSubtitle;

  /// No description provided for @clubAnthemSection.
  ///
  /// In pt, this message translates to:
  /// **'HINO'**
  String get clubAnthemSection;

  /// No description provided for @clubSongsSection.
  ///
  /// In pt, this message translates to:
  /// **'MÚSICAS ESMERALDINAS'**
  String get clubSongsSection;

  /// No description provided for @clubViewLyrics.
  ///
  /// In pt, this message translates to:
  /// **'VER LETRA'**
  String get clubViewLyrics;

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

  /// No description provided for @clubCampaignsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Grandes campanhas do Goiás que não resultaram em título.'**
  String get clubCampaignsSubtitle;

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
  /// **'História, títulos, elenco e identidade do Verdão.'**
  String get clubEntrySubtitle;

  /// No description provided for @clubEntryCta.
  ///
  /// In pt, this message translates to:
  /// **'CONHECER O GOIÁS'**
  String get clubEntryCta;

  /// No description provided for @clubHeaderTagline.
  ///
  /// In pt, this message translates to:
  /// **'O MAIOR DO CENTRO-OESTE'**
  String get clubHeaderTagline;

  /// No description provided for @membershipLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o Sócio Esmeralda.'**
  String get membershipLoadError;

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

  /// No description provided for @membershipStadiumAccess.
  ///
  /// In pt, this message translates to:
  /// **'Acesso ao estádio'**
  String get membershipStadiumAccess;

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

  /// No description provided for @membershipCheckinUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'O check-in do Sócio Esmeralda ainda não está disponível no app.'**
  String get membershipCheckinUnavailable;

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
  /// **'Esteja ainda mais próximo\ndo Goiás.'**
  String get membershipHeroTitle;

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
  /// **'Desejo receber notícias do clube e do Sócio Esmeralda por e-mail.'**
  String get membershipNewsletter;

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
  /// **'Li e aceito o Regulamento do Sócio Esmeralda'**
  String get membershipAcceptRegulation;

  /// No description provided for @membershipReadFullRegulation.
  ///
  /// In pt, this message translates to:
  /// **'Ler regulamento completo →'**
  String get membershipReadFullRegulation;

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
  /// **'BEM-VINDO AO\nSÓCIO ESMERALDA'**
  String get membershipWelcome;

  /// No description provided for @membershipSuccessMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sua associação foi concluída com sucesso.\nAgora você está ainda mais perto do Verdão.'**
  String get membershipSuccessMessage;

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

  /// No description provided for @membershipCpfMasked.
  ///
  /// In pt, this message translates to:
  /// **'CPF {cpf}'**
  String membershipCpfMasked(String cpf);

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
  /// **'Regulamento do Sócio Esmeralda'**
  String get membershipRegulationName;

  /// No description provided for @membershipCancelWhatsapp.
  ///
  /// In pt, this message translates to:
  /// **'Olá, gostaria de cancelar minha associação Sócio Esmeralda ({plan}).'**
  String membershipCancelWhatsapp(String plan);

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
  /// **'Tente outro termo ou fale com o atendimento do Sócio Esmeralda.'**
  String get membershipFaqNoResultsMessage;

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
  /// **'Dúvidas sobre o clube, categorias de base, elenco e outros assuntos fora do Sócio Esmeralda não são respondidas por este canal.'**
  String get membershipFaqScopeNote;

  /// No description provided for @membershipFaqAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get membershipFaqAll;

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

  /// No description provided for @arenaYouMarker.
  ///
  /// In pt, this message translates to:
  /// **'{name} (você)'**
  String arenaYouMarker(String name);

  /// No description provided for @arenaYourPosition.
  ///
  /// In pt, this message translates to:
  /// **'#{rank} sua posição'**
  String arenaYourPosition(int rank);

  /// No description provided for @lineupShareStats.
  ///
  /// In pt, this message translates to:
  /// **'{solved}/{total} descobertos · {attempts} tentativas · {time}'**
  String lineupShareStats(int solved, int total, int attempts, String time);

  /// No description provided for @crowdShareCrowd.
  ///
  /// In pt, this message translates to:
  /// **'Confira a escalação da torcida pro Goiás! 💚'**
  String get crowdShareCrowd;

  /// No description provided for @crowdShareMine.
  ///
  /// In pt, this message translates to:
  /// **'Essa é a minha escalação pro Goiás! 💚'**
  String get crowdShareMine;

  /// No description provided for @crowdSubmitted.
  ///
  /// In pt, this message translates to:
  /// **'Escalação enviada!'**
  String get crowdSubmitted;
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
