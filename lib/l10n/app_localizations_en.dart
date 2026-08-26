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

  @override
  String get commonSave => 'SAVE';

  @override
  String get commonSaving => 'Saving...';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonContinue => 'CONTINUE';

  @override
  String get profileTitle => 'PROFILE';

  @override
  String get profileMyAccount => 'MY ACCOUNT';

  @override
  String get profilePersonalData => 'Personal data';

  @override
  String get profileMyAddress => 'My address';

  @override
  String get profileSecurity => 'Security';

  @override
  String get profileTheme => 'Theme';

  @override
  String get profileLegal => 'LEGAL';

  @override
  String get profileAccount => 'ACCOUNT';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileDeleteConfirmTitle => 'Delete account?';

  @override
  String get profileDeleteConfirmMessage =>
      'Deleting your account permanently removes your data and progress. This action can\'t be undone.';

  @override
  String get profileSignOutTitle => 'Sign out?';

  @override
  String get profileSignOutMessage =>
      'You\'ll need to sign in again to access your account.';

  @override
  String get profileSignOutConfirm => 'SIGN OUT';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get personalDataTitle => 'PERSONAL DATA';

  @override
  String get personalDataLoadError => 'Couldn\'t load your data.';

  @override
  String get personalFieldCpf => 'CPF (optional)';

  @override
  String get personalFieldBirthDate => 'Date of birth';

  @override
  String get personalSelectDate => 'Select date';

  @override
  String get personalFieldPhone => 'Mobile';

  @override
  String get personalEmailLocked => 'The email is linked to your account.';

  @override
  String get personalNameRequired => 'Enter your full name.';

  @override
  String get personalCpfInvalid => 'Invalid CPF.';

  @override
  String get personalUpdateSuccess => 'Data updated successfully.';

  @override
  String get securityTitle => 'SECURITY';

  @override
  String get securitySubtitle => 'Change your Goiás EC account password.';

  @override
  String get securityCurrentPassword => 'Current password';

  @override
  String get securityCurrentPasswordHint => 'Confirm your current password';

  @override
  String get securityNewPassword => 'New password';

  @override
  String get securityConfirmNewPassword => 'Confirm new password';

  @override
  String get securityConfirmNewPasswordHint => 'Repeat the new password';

  @override
  String get securitySaveButton => 'SAVE NEW PASSWORD';

  @override
  String get securityChangeSuccess => 'Password changed successfully.';

  @override
  String get addressTitle => 'MY ADDRESS';

  @override
  String get addressLoadError => 'Couldn\'t load your address.';

  @override
  String get addressCepNotFound => 'Postal code not found.';

  @override
  String get addressSaveSuccess => 'Address saved successfully.';

  @override
  String get addressFieldCep => 'Postal code';

  @override
  String get addressFieldStreet => 'Street';

  @override
  String get addressFieldNumber => 'Number';

  @override
  String get addressFieldComplement => 'Complement (optional)';

  @override
  String get addressFieldNeighborhood => 'Neighborhood';

  @override
  String get addressFieldState => 'State';

  @override
  String get addressSelectState => 'Select state';

  @override
  String get addressFieldCity => 'City';

  @override
  String get addressSaveButton => 'SAVE ADDRESS';

  @override
  String get deleteAccountTitle => 'DELETE ACCOUNT';

  @override
  String get deleteAccountConfirmWord => 'DELETE';

  @override
  String deleteAccountInstruction(String word) {
    return 'This action is permanent. Confirm your password and type $word to delete your account and all your progress.';
  }

  @override
  String get deleteAccountPasswordHint => 'Confirm your password';

  @override
  String deleteAccountTypeWordLabel(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get deleteAccountConfirmButton => 'DELETE MY ACCOUNT';

  @override
  String get deleteAccountDeleting => 'DELETING ACCOUNT...';

  @override
  String get settingsThemeTitle => 'THEME';

  @override
  String get themeModeAuto => 'Automatic';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeAutoDesc => 'Follows your phone\'s theme';

  @override
  String get themeModeLightDesc => 'Always a light background';

  @override
  String get themeModeDarkDesc => 'Always a dark background';

  @override
  String get avatarTakePhoto => 'Take a photo';

  @override
  String get avatarChooseFromGallery => 'Choose from gallery';

  @override
  String get socialFollowTitle => 'FOLLOW GOIÁS';

  @override
  String get socialFollowSubtitle => 'Follow Goiás on social media too.';

  @override
  String socialOpenLink(String name) {
    return 'Open $name';
  }

  @override
  String get arenaSubtitle => 'Quick minigames for the fans.';

  @override
  String get arenaSectionPlayNow => 'PLAY NOW';

  @override
  String get arenaSectionMoreChallenges => 'MORE CHALLENGES';

  @override
  String get arenaPlay => 'PLAY';

  @override
  String get arenaRankingTitle => 'Fans\' Ranking';

  @override
  String get arenaRankingBannerSubtitle => 'See the top fans in the minigames.';

  @override
  String get arenaRankingEmpty => 'Ranking is still empty';

  @override
  String get arenaRankingEmptyMessage =>
      'Play and be the first to appear in the fans\' ranking.';

  @override
  String get arenaAchievementTitle => 'ESMERALDINA LEGEND';

  @override
  String get arenaAchievementMessage =>
      'You completed 100% of the Arena Esmeraldina — Goiás Quiz, Guess the Lineup and Guess the Player. This achievement is permanent.';

  @override
  String get arenaAchievementConfirm => 'AWESOME!';

  @override
  String get arenaPlayFirstTime => 'Play for the first time';

  @override
  String arenaStatMatchesCorrect(int played, int correct) {
    return '$played matches · $correct correct';
  }

  @override
  String get arenaGameQuizTitle => 'Goiás Quiz';

  @override
  String get arenaGameQuizTagline => 'Test how well you know Goiás.';

  @override
  String get arenaGameLineupTitle => 'Guess the Lineup';

  @override
  String get arenaGameLineupTagline =>
      'Figure out the starting 11 from a historic Goiás match.';

  @override
  String get arenaGameCareerTitle => 'Guess the Player';

  @override
  String get arenaGameCareerTagline =>
      'Figure out the player from their career path.';

  @override
  String get arenaGuessPlayerTitle => 'Who Wore the Shirt?';

  @override
  String get arenaGuessPlayerTagline =>
      'Uncover the secret player from a blurred photo and clues.';

  @override
  String get arenaSubtitleQuiz => '60 questions';

  @override
  String get arenaSubtitleLineup => '31 lineups';

  @override
  String get arenaSubtitleCareer => '23 players';

  @override
  String get arenaSubtitleGuessPlayer => 'Uncover the player from the clues';
}
