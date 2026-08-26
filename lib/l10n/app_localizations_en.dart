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

  @override
  String get navHome => 'Home';

  @override
  String get navMatches => 'Matches';

  @override
  String get navMembership => 'Member';

  @override
  String get navMedia => 'Media';

  @override
  String get navArena => 'Arena';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeNextMatch => 'NEXT MATCH';

  @override
  String get homeDateToBeConfirmed => 'DATE TO BE CONFIRMED';

  @override
  String get homeMatchDetails => 'MATCH DETAILS';

  @override
  String get homeTickets => 'TICKETS';

  @override
  String get homeCountdownTitle => 'THE MATCH STARTS IN';

  @override
  String get homeCountdownDays => 'DAYS';

  @override
  String get homeCountdownHours => 'HOURS';

  @override
  String get homeCountdownMinutes => 'MIN';

  @override
  String get homeCountdownSeconds => 'SEC';

  @override
  String get homeMembershipPitch =>
      'Get even closer to Goiás\nand be part of this story!';

  @override
  String get homeMembershipBenefit1 => 'Priority access to the stadium';

  @override
  String get homeMembershipBenefit2 => 'Savings on ticket prices';

  @override
  String get homeMembershipBenefit3 => 'Exclusive discounts and much more';

  @override
  String get homeMembershipCta => 'BECOME A MEMBER';

  @override
  String get matchGamesTitle => 'MATCHES';

  @override
  String get matchTabMatches => 'MATCHES';

  @override
  String get matchTabStandings => 'STANDINGS';

  @override
  String get matchLoadError => 'Couldn\'t load the matches';

  @override
  String get matchNoMatches => 'No matches found.';

  @override
  String get matchDetailsLoadError => 'Couldn\'t load the match.';

  @override
  String get matchBuyTicket => 'BUY TICKET';

  @override
  String get matchDetailsShort => 'DETAILS';

  @override
  String get matchDateToBeConfirmed => 'Date to be confirmed';

  @override
  String get matchToBeConfirmed => 'To be confirmed';

  @override
  String get matchInfoTitle => 'INFORMATION';

  @override
  String get matchFieldDate => 'Date';

  @override
  String get matchFieldTime => 'Time';

  @override
  String get matchFieldStadium => 'Stadium';

  @override
  String get matchFieldCity => 'City';

  @override
  String get matchFieldCompetition => 'Competition';

  @override
  String get matchFieldRound => 'Round';

  @override
  String get matchFieldStatus => 'Status';

  @override
  String get matchEventsTitle => 'MATCH EVENTS';

  @override
  String get matchEventGoal => 'Goal';

  @override
  String get matchEventCard => 'Card';

  @override
  String matchEventSubstitution(String playerIn, String playerOut) {
    return '$playerIn comes on for $playerOut';
  }

  @override
  String get matchLineupsTitle => 'LINEUPS';

  @override
  String get standingsClub => 'CLUB';

  @override
  String get standingsColPoints => 'Pts';

  @override
  String get standingsColPlayed => 'P';

  @override
  String get standingsColWins => 'W';

  @override
  String get standingsColGoalDiff => 'GD';

  @override
  String get standingsUnavailable => 'Standings unavailable right now.';

  @override
  String get matchStatusScheduled => 'Scheduled';

  @override
  String get matchStatusLive => 'Live';

  @override
  String get matchStatusHalfTime => 'Half-time';

  @override
  String get matchStatusFinished => 'Finished';

  @override
  String get matchStatusPostponed => 'Postponed';

  @override
  String get matchStatusCancelled => 'Cancelled';

  @override
  String get matchStatusSuspended => 'Suspended';

  @override
  String get matchStatusUnknown => 'Undefined';
}
