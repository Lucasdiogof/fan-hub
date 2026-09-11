// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsLanguageTitle => 'LANGUAGE';

  @override
  String get settingsLanguageMenu => 'Language';

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
  String get authForgotPassword => 'Forgot password';

  @override
  String get authSignInButton => 'SIGN IN';

  @override
  String get authSignInErrorTitle => 'Couldn\'t sign in';

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
  String get authRegisterButton => 'CREATE MY ACCOUNT';

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
  String get authStepPersonal => 'Your info';

  @override
  String get authStepContact => 'Contact';

  @override
  String get authStepSecurity => 'Security';

  @override
  String authMarketingOptIn(String clubShortName) {
    return 'I want to receive news, promotions and information from $clubShortName';
  }

  @override
  String authPasswordRequirementLength(int count) {
    return 'At least $count characters';
  }

  @override
  String get authCpfLabel => 'CPF';

  @override
  String get authBirthDateHint => 'DD/MM/YYYY';

  @override
  String get navHome => 'Home';

  @override
  String get navMatches => 'Matches';

  @override
  String get navMembership => 'Member';

  @override
  String get navMedia => 'Media';

  @override
  String get navStore => 'Store';

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
  String get homeCompactMatchToday => 'TODAY';

  @override
  String get homeCompactMatchFinished => 'Full time';

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
  String get matchGamesTitle => 'MATCHES';

  @override
  String get matchTabMatches => 'MATCHES';

  @override
  String get matchTabCalendar => 'CALENDAR';

  @override
  String get matchTabStandings => 'STANDINGS';

  @override
  String get matchCalendarHome => 'HOME';

  @override
  String get matchCalendarAway => 'AWAY';

  @override
  String get matchLoadError => 'Couldn\'t load the matches';

  @override
  String get matchNoMatches => 'No matches found.';

  @override
  String get matchDetailsLoadError => 'Couldn\'t load the match.';

  @override
  String get matchBuyTicket => 'BUY TICKET';

  @override
  String get matchDetailsShort => 'MATCH DETAILS';

  @override
  String get matchFollowLive => 'FOLLOW MATCH';

  @override
  String get matchViewDetails => 'VIEW DETAILS';

  @override
  String get matchFinishedLabel => 'Finished';

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
  String get matchStatsTitle => 'STATISTICS';

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
  String get otherCompetitionsCta => 'See other competitions';

  @override
  String get otherCompetitionsTitle => 'Competitions';

  @override
  String get otherCompetitionsSearchHint => 'Search competitions';

  @override
  String get otherCompetitionsYourCompetitions => 'YOUR COMPETITIONS';

  @override
  String get otherCompetitionsSearchEmpty => 'No competitions found.';

  @override
  String get knockoutFirstLeg => '1st leg';

  @override
  String get knockoutSecondLeg => '2nd leg';

  @override
  String get knockoutAggregateShort => 'Score';

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
  String get matchCurrentRound => 'Current round';

  @override
  String get commonSave => 'SAVE';

  @override
  String get commonSaving => 'Saving...';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonContinue => 'CONTINUE';

  @override
  String get commonDemoTag => 'Demo';

  @override
  String get commonDemoBannerTitle => 'Demo';

  @override
  String get profileTitle => 'PROFILE';

  @override
  String get profileMyAccount => 'MY ACCOUNT';

  @override
  String get profilePersonalData => 'Personal data';

  @override
  String get profileMyAddress => 'Home address';

  @override
  String get profileDeliveryAddresses => 'Delivery addresses';

  @override
  String get profileSecurity => 'Security';

  @override
  String get profileAppearance => 'Appearance';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileMyJourney => 'MY JOURNEY';

  @override
  String get profilePreferences => 'PREFERENCES';

  @override
  String get profilePurchasesAndServices => 'PURCHASES & SERVICES';

  @override
  String get profileMyTickets => 'My tickets';

  @override
  String profileVersion(Object version) {
    return 'Version $version';
  }

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
  String get authSessionExpiredTitle => 'Your session has expired';

  @override
  String authSessionExpiredMessage(String club) {
    return 'For your security, we need to confirm your access again. Sign in to keep using every feature of $club.';
  }

  @override
  String get authSessionExpiredCta => 'Sign in again';

  @override
  String get authErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authErrorCurrentPasswordIncorrect =>
      'Current password is incorrect.';

  @override
  String get authErrorPasswordIncorrect => 'Incorrect password.';

  @override
  String get authErrorEmailAlreadyRegistered =>
      'This email already has an account.';

  @override
  String get authErrorWeakPassword =>
      'Password doesn\'t meet the minimum requirements.';

  @override
  String get authErrorInvalidEmail => 'Enter a valid email address.';

  @override
  String get authErrorRateLimited =>
      'We already sent a code recently. Wait a bit before requesting another one.';

  @override
  String get authErrorOtpInvalidOrExpired =>
      'This code isn\'t valid or has expired. Check it and try again, or request a new code.';

  @override
  String get authErrorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get authErrorSignupDisabled =>
      'New sign-ups are temporarily unavailable.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Confirm your email before signing in.';

  @override
  String get authErrorServiceUnavailable =>
      'The service is temporarily unavailable. Please try again shortly.';

  @override
  String get authErrorNewPasswordSameAsCurrent =>
      'The new password must be different from the current one.';

  @override
  String get authErrorCpfAlreadyTaken =>
      'This CPF is already registered to another account.';

  @override
  String get authErrorAccountDeletionFailed =>
      'Couldn\'t delete your account. Please try again shortly.';

  @override
  String get authErrorNetwork => 'Check your internet connection.';

  @override
  String get authErrorGeneric =>
      'Couldn\'t complete this right now. Please try again.';

  @override
  String get personalDataTitle => 'PERSONAL DATA';

  @override
  String get personalDataLoadError => 'Couldn\'t load your data.';

  @override
  String get personalFieldCpf => 'CPF (optional)';

  @override
  String get personalFieldBirthDate => 'Date of birth';

  @override
  String get personalFieldPhone => 'Mobile';

  @override
  String get personalEmailLocked => 'The email is linked to your account.';

  @override
  String get personalNameRequired => 'Enter your full name.';

  @override
  String get personalCpfRequired => 'Enter your CPF.';

  @override
  String get personalCpfInvalid => 'Invalid CPF.';

  @override
  String get personalUpdateSuccess => 'Data updated successfully.';

  @override
  String get securityTitle => 'SECURITY';

  @override
  String securitySubtitle(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'Change your Goiás EC account password.',
      'other': 'Change your $club account password.',
    });
    return '$_temp0';
  }

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
  String get addressTitle => 'HOME ADDRESS';

  @override
  String get addressResidentialSubtitle =>
      'Your main address registered on the account.';

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
  String get settingsNotificationsTitle => 'NOTIFICATIONS';

  @override
  String get notificationsLiveMatchesTitle => 'Live matches';

  @override
  String notificationsLiveMatchesDescription(String club) {
    return 'Turn on to get the alerts below in real time, with $club\'s score.';
  }

  @override
  String get notificationsKickoffTitle => 'Kickoff';

  @override
  String get notificationsKickoffDescription =>
      'Alert as soon as the match starts.';

  @override
  String notificationsGoalForTitle(String club) {
    return '$club goals';
  }

  @override
  String notificationsGoalForDescription(String club) {
    return 'Alert on every goal scored by $club.';
  }

  @override
  String get notificationsGoalAgainstTitle => 'Opponent goals';

  @override
  String get notificationsGoalAgainstDescription =>
      'Alert on every goal conceded.';

  @override
  String get notificationsHalfTimeTitle => 'Half-time';

  @override
  String get notificationsHalfTimeDescription =>
      'Alert at half-time, with the partial score.';

  @override
  String get notificationsSecondHalfTitle => 'Second half kickoff';

  @override
  String get notificationsSecondHalfDescription =>
      'Alert when the second half starts.';

  @override
  String get notificationsFullTimeTitle => 'Full time';

  @override
  String get notificationsFullTimeDescription => 'Alert with the final score.';

  @override
  String get notificationsTicketsTitle => 'Tickets and check-in';

  @override
  String get notificationsTicketsDescription =>
      'Alerts when sales or check-in open.';

  @override
  String get notificationsOsBlockedMessage =>
      'Notifications are turned off in your system settings — you won\'t receive anything until you turn them back on.';

  @override
  String get notificationsOpenSettings => 'Open settings';

  @override
  String get notificationsForegroundCta => 'View';

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
  String socialFollowTitle(String clubCode, String club) {
    return 'FOLLOW $club';
  }

  @override
  String socialFollowSubtitle(String clubCode, String club) {
    return 'Follow $club on social media too.';
  }

  @override
  String socialOpenLink(String name) {
    return 'Open $name';
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
      'goias': 'Test your Goiás knowledge.',
      'other': 'Test your $club knowledge.',
    });
    return '$_temp0';
  }

  @override
  String get arenaNextMatchBadge => 'NEXT MATCH';

  @override
  String get arenaHighlightViewLineup => 'View lineup';

  @override
  String get arenaPlay => 'PLAY';

  @override
  String get arenaRankingTitle => 'Fans\' Ranking';

  @override
  String get arenaRankingEmpty => 'Ranking is still empty';

  @override
  String get arenaRankingEmptyMessage =>
      'Play and be the first to appear in the fans\' ranking.';

  @override
  String arenaAchievementTitle(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'ESMERALDINA LEGEND',
      'other': '$club LEGEND',
    });
    return '$_temp0';
  }

  @override
  String arenaAchievementMessage(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias':
          'You completed 100% of the Arena Esmeraldina — Goiás Quiz, Guess the Lineup and Guess the Player. This achievement is permanent.',
      'other':
          'You completed 100% of the $club Arena — Quiz, Guess the Lineup and Guess the Player. This achievement is permanent.',
    });
    return '$_temp0';
  }

  @override
  String get arenaAchievementConfirm => 'AWESOME!';

  @override
  String get arenaPlayFirstTime => 'Play for the first time';

  @override
  String arenaStatMatchesCorrect(int played, int correct) {
    return '$played matches · $correct correct';
  }

  @override
  String arenaHeaderSubtitle(String club) {
    return 'Play, take part and live $club.';
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
  String get arenaSpotlightHeadline => 'Your passion takes the field';

  @override
  String arenaSpotlightSubtitle(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'Play, take part, and earn your place among the Esmeraldinos.',
      'bragantino':
          'Play, take part, and earn your place among the Massa Bruta.',
      'other': 'Play, take part, and earn your place among $club fans.',
    });
    return '$_temp0';
  }

  @override
  String get arenaSpotlightCta => 'Enter the Arena';

  @override
  String get arenaLineupHeroEyebrow => 'FANS\' LINEUP';

  @override
  String get arenaLineupHeroCta => 'Build my lineup';

  @override
  String get arenaLineupHeroEmptyTitle => 'No match for now';

  @override
  String get arenaLineupHeroEmptyMessage =>
      'As soon as the next match is confirmed, you\'ll be able to build your lineup here.';

  @override
  String get arenaChallengesSectionTitle => 'Challenges';

  @override
  String get arenaChallengeCtaContinue => 'Continue';

  @override
  String get arenaChallengeCtaStart => 'Start';

  @override
  String get arenaChallengeCtaCompleted => 'Completed';

  @override
  String arenaGameQuizTitle(String clubCode, String club) {
    return '$club Quiz';
  }

  @override
  String arenaGameQuizTagline(String club) {
    return 'Test how well you know $club.';
  }

  @override
  String get arenaGameLineupTitle => 'Guess the Lineup';

  @override
  String arenaGameLineupTagline(String club) {
    return 'Figure out the starting 11 from a historic $club match.';
  }

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
  String get arenaRankingWeekly => 'Weekly';

  @override
  String get arenaRankingMonthly => 'Monthly';

  @override
  String get arenaRankingAllTime => 'All-time';

  @override
  String get arenaRankingPoints => 'pts';

  @override
  String get arenaRankingYourPosition => 'YOUR POSITION';

  @override
  String get arenaRankingMemberBadge => 'Member';

  @override
  String get arenaRankingUnknownFan => 'Fan';

  @override
  String get passportCardCta => 'Open passport';

  @override
  String get passportRankingCta => 'Passport ranking';

  @override
  String get passportLoadErrorTitle => 'We couldn\'t load the passport';

  @override
  String get passportEmptyCatalogTitle => 'No season available yet';

  @override
  String get passportNoMatchesForFilter => 'No match found with this filter';

  @override
  String get passportSummaryTotalMatches => 'Matches registered';

  @override
  String get passportSummaryYearsCount => 'Years attended';

  @override
  String get passportSummaryFirstMatch => 'First match';

  @override
  String get passportSummaryLastMatch => 'Last match';

  @override
  String get passportFilterAll => 'All';

  @override
  String get passportFilterAttended => 'Attended';

  @override
  String get passportFilterNotAttended => 'Not attended';

  @override
  String get passportFilterHome => 'Home';

  @override
  String get passportFilterAway => 'Away';

  @override
  String get passportFilterAllCompetitions => 'All competitions';

  @override
  String get passportStatusScheduled => 'Scheduled';

  @override
  String get passportStatusPostponed => 'Postponed';

  @override
  String get passportStatusCancelled => 'Cancelled';

  @override
  String get passportOutcomeWin => 'Win';

  @override
  String get passportOutcomeDraw => 'Draw';

  @override
  String get passportOutcomeLoss => 'Loss';

  @override
  String get passportSaveGenericLabel => 'Save changes';

  @override
  String passportSaveCountLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Save $count matches',
      one: 'Save 1 match',
    );
    return '$_temp0';
  }

  @override
  String get passportSaveSuccess => 'Passport updated.';

  @override
  String get passportDiscardChangesTitle => 'Discard changes?';

  @override
  String get passportDiscardChangesMessage =>
      'You\'ve marked matches that haven\'t been saved yet. If you leave now, those marks are lost.';

  @override
  String get passportDiscardChangesConfirm => 'Discard';

  @override
  String get passportRankingTitle => 'Passport ranking';

  @override
  String get passportRankingPeriodOverall => 'Overall';

  @override
  String passportRankingMatchCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
    );
    return '$_temp0';
  }

  @override
  String get passportRankingEmptyTitle => 'No one on the ranking yet';

  @override
  String get passportRankingEmptyMessage =>
      'Mark your matches in the Passport to show up here.';

  @override
  String get passportStatsTitle => 'My journey';

  @override
  String get passportStatsWins => 'Wins';

  @override
  String get passportStatsDraws => 'Draws';

  @override
  String get passportStatsLosses => 'Losses';

  @override
  String get passportStatsHomeGames => 'Home games';

  @override
  String get passportStatsAwayGames => 'Away games';

  @override
  String get passportStatsGoalsFor => 'Goals scored';

  @override
  String get passportStatsGoalsAgainst => 'Goals conceded';

  @override
  String get passportStatsGoalDifference => 'Goal difference';

  @override
  String get passportStatsEmptyTitle => 'Your journey starts here';

  @override
  String get passportStatsEmptyMessage =>
      'Mark matches as \"I was there\" to see your stats.';

  @override
  String get passportTrajectoryGames => 'Games';

  @override
  String get passportTrajectoryStadiums => 'Stadiums';

  @override
  String get passportTrajectorySeasons => 'Seasons';

  @override
  String get passportTrajectoryMemorableMatch => 'Most memorable game';

  @override
  String get passportTrajectoryMemorableEmpty =>
      'Choose your most memorable game';

  @override
  String get passportTrajectoryPickMatch => 'Choose your most memorable game';

  @override
  String get passportTrajectoryMostVisitedStadium => 'Most visited stadium';

  @override
  String get passportTrajectoryStadiumUnavailable =>
      'We don\'t have this information yet';

  @override
  String passportTrajectoryGamesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: '1 game',
    );
    return '$_temp0';
  }

  @override
  String get passportTrajectoryListEmpty => 'No games here yet';

  @override
  String get passportTrajectoryShareAction => 'Share';

  @override
  String passportTrajectoryOfUser(String name) {
    return '$name\'s journey';
  }

  @override
  String get passportTrajectoryMemorableEmptyReadOnly =>
      'Hasn\'t picked a favorite match yet';

  @override
  String get passportCoverEyebrow => 'MY PASSPORT';

  @override
  String get passportEmptyHeadline => 'Every fan has a story.';

  @override
  String get passportChangeSeasonCta => 'Change season';

  @override
  String passportSeasonProgressLine(Object marked, Object total) {
    return '$marked of $total matches logged';
  }

  @override
  String passportSeasonTotalOnly(Object total) {
    return '$total matches';
  }

  @override
  String get passportSealLabel => 'I WAS THERE';

  @override
  String get passportSealActionLabel => 'I was there';

  @override
  String get passportRoundSemifinal => 'Semifinal';

  @override
  String get passportRoundQuarterfinal => 'Quarterfinals';

  @override
  String get passportRoundFinal => 'Final';

  @override
  String get passportRoundPlayoff => 'Playoff';

  @override
  String get passportRoundOf16 => 'Round of 16';

  @override
  String passportRoundPhase(int n) {
    return 'Phase $n';
  }

  @override
  String passportRoundMatchday(int n) {
    return 'Round $n';
  }

  @override
  String passportRoundGroup(String letter) {
    return 'Group $letter';
  }

  @override
  String get arenaRankingDetailFirstTry => 'First-try correct';

  @override
  String get arenaRankingDetailReview => 'Review correct answers';

  @override
  String get arenaRankingDetailAbandoned => 'Revealed/abandoned';

  @override
  String get arenaRankingYouTag => 'YOU';

  @override
  String arenaRankingPlace(int rank) {
    return 'Place #$rank';
  }

  @override
  String get arenaRankingPointsFull => 'points';

  @override
  String get arenaRankingPeriodOverall => 'Overall ranking';

  @override
  String get arenaRankingPeriodWeek => 'This week';

  @override
  String get arenaRankingByGame => 'Points by game';

  @override
  String get arenaRankingHowScoredSelf => 'How you scored';

  @override
  String arenaRankingHowScoredOther(String name) {
    return 'How $name scored';
  }

  @override
  String arenaRankingGamePointsShare(int score, int percent) {
    return '$score pts • $percent% of total';
  }

  @override
  String get arenaRankingNoPointsTitle => 'No points this period';

  @override
  String get arenaRankingNoPointsOther =>
      'This supporter hasn\'t scored in the games during the selected period yet.';

  @override
  String get arenaRankingNoPointsSelf =>
      'You haven\'t scored in the games during the selected period yet.';

  @override
  String arenaRankingGapToNext(int points, int rank) {
    return '$points pts to reach #$rank';
  }

  @override
  String get commonClose => 'CLOSE';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonComingSoon => 'Coming soon';

  @override
  String get commonComingSoonMessage => 'This area is still being prepared.';

  @override
  String get featureUnavailableTitle => 'Unavailable';

  @override
  String get featureUnavailableMessage => 'This area isn\'t available.';

  @override
  String get commonLinkOpenError => 'Couldn\'t open this link.';

  @override
  String get commonLoadError => 'Couldn\'t load the data';

  @override
  String get commonSelectPlaceholder => 'Select';

  @override
  String get commonNoDataFound => 'No data found.';

  @override
  String get membershipCheckInAction => 'CHECK IN';

  @override
  String get quizChooseLevel => 'Choose the level';

  @override
  String get quizChooseLevelHint =>
      'Each level has its own question bank — the higher you go, the harder it gets.';

  @override
  String get quizDone => 'Completed';

  @override
  String get quizSeeResult => 'SEE RESULT';

  @override
  String get quizNext => 'NEXT';

  @override
  String get quizHits => 'CORRECT';

  @override
  String get quizPerfect => 'Perfect!';

  @override
  String get quizScore => 'SCORE';

  @override
  String get quizNewRecord => 'New record';

  @override
  String get quizReviewErrors => 'REVIEW MISTAKES';

  @override
  String get quizPlayAgain => 'PLAY AGAIN';

  @override
  String get quizReviewMore => 'REVIEW MORE';

  @override
  String get quizBackToLevels => 'BACK TO LEVELS';

  @override
  String get quizMoreQuestions => 'MORE QUESTIONS';

  @override
  String get quizBackToArena => 'BACK TO ARENA';

  @override
  String get quizLevelDescTorcedor =>
      'Basic facts, titles and campaigns every fan knows.';

  @override
  String get quizLevelDescEsmeraldino =>
      'History, idols and memorable matches for those who know the club.';

  @override
  String get quizLevelDescFanatico =>
      'Records and numbers for those who never miss one.';

  @override
  String quizLevelName(String level) {
    return 'Level $level';
  }

  @override
  String quizQuestionProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String quizAnsweredCount(int answered, int total) {
    return '$answered/$total questions';
  }

  @override
  String quizPendingReview(int count) {
    return '$count to review';
  }

  @override
  String quizLevelCompleted(String level) {
    return 'LEVEL $level COMPLETED';
  }

  @override
  String quizAllAnswered(int total) {
    return 'You answered all $total questions in this level.';
  }

  @override
  String quizCorrectCount(int count) {
    return '$count correct';
  }

  @override
  String quizReviewLevel(String level) {
    return 'Review · Level $level';
  }

  @override
  String quizFinalResultLevel(String level) {
    return 'Final result · Level $level';
  }

  @override
  String quizScoreLine(int correct, int total) {
    return 'You got $correct of $total questions right';
  }

  @override
  String quizLevelQuestions(int answered, int total) {
    return '$answered/$total level questions';
  }

  @override
  String quizBestRecord(int best) {
    return 'Best: $best pts';
  }

  @override
  String get tacticalIdentityGameTitle => 'Football Identity';

  @override
  String get tacticalIdentityCardSubtitleNew =>
      'What kind of football do you believe in?';

  @override
  String get tacticalIdentityCardCtaStart => 'Discover my profile';

  @override
  String get tacticalIdentityCardCtaViewResult => 'View result';

  @override
  String get tacticalIdentityCardCtaRedo => 'Redo';

  @override
  String tacticalIdentityYourProfile(String name) {
    return 'Your profile: $name';
  }

  @override
  String get tacticalIntroTitle => 'What\'s your football identity?';

  @override
  String tacticalIntroDescription(String club) {
    return '10 decisions. No right answer. Discover how you see the game and which coaches who managed $club your philosophy is closest to.';
  }

  @override
  String get tacticalIntroMeta => '10 questions • ~3 minutes';

  @override
  String get tacticalIntroNoRightWrong =>
      'There are no right or wrong answers.';

  @override
  String get tacticalIntroStart => 'Start';

  @override
  String get tacticalQuestionContinue => 'Continue';

  @override
  String get tacticalProcessingTitle => 'Analyzing your identity...';

  @override
  String get tacticalResultYourProfile => 'YOUR PROFILE';

  @override
  String get tacticalResultTacticalMap => 'TACTICAL MAP';

  @override
  String tacticalResultMainReference(String club) {
    return 'Your main $club reference';
  }

  @override
  String get tacticalResultOtherReferences => 'OTHER REFERENCES';

  @override
  String tacticalIdentityAffinityLabel(String percent) {
    return '$percent% tactical affinity';
  }

  @override
  String get tacticalResultShare => 'Share result';

  @override
  String get tacticalAxisPossession => 'POSSESSION';

  @override
  String get tacticalAxisVertical => 'VERTICAL';

  @override
  String get tacticalAxisDogmatic => 'DOGMATIC';

  @override
  String get tacticalAxisPragmatic => 'PRAGMATIC';

  @override
  String playerIdentityGameTitle(String club) {
    return 'Which $club legend are you?';
  }

  @override
  String playerIdentityCardSubtitleNew(String club) {
    return '10 game situations. Find out which $club idol your style matches most.';
  }

  @override
  String get playerIdentityCardCtaStart => 'Discover my profile';

  @override
  String get playerIdentityCardCtaViewResult => 'See result';

  @override
  String get playerIdentityCardCtaRedo => 'Retake';

  @override
  String playerIdentityYourProfile(String name) {
    return 'Your profile: $name';
  }

  @override
  String playerIntroTitle(String club) {
    return 'Which $club legend are you?';
  }

  @override
  String playerIntroDescription(String club) {
    return 'Every player sees the match differently. Answer 10 game situations and find out which name that marked $club history matches your choices most.';
  }

  @override
  String get playerIntroMeta => '10 questions • ~3 minutes';

  @override
  String get playerIntroNoRightWrong => 'There are no right answers.';

  @override
  String get playerIntroStart => 'Start test';

  @override
  String get playerProcessingTitle => 'Calculating your style...';

  @override
  String get playerResultYourProfile => 'YOUR PROFILE';

  @override
  String playerResultReferencesTitle(String club) {
    return '$club references';
  }

  @override
  String get playerResultTraitsTitle => 'YOUR TRAITS';

  @override
  String playerIdentityAffinityLabel(String percent) {
    return '$percent% style affinity';
  }

  @override
  String get playerResultShare => 'Share result';

  @override
  String get playerReferenceDisclaimer =>
      'These attributes are editorial references used in this experience and not the player\'s official ratings.';

  @override
  String get lineupPlayerHeading => 'PLAYER';

  @override
  String lineupShirt(int number) {
    return 'SHIRT $number';
  }

  @override
  String get lineupTypePlayerName => 'Type the player\'s name';

  @override
  String get lineupBackToField => 'BACK TO THE FIELD';

  @override
  String get lineupGiveUp => 'GIVE UP THE MATCH';

  @override
  String get lineupGiveUpTitle => 'Give up the match?';

  @override
  String get lineupGiveUpMessage =>
      'The remaining players will be revealed and the match will end.';

  @override
  String get lineupGiveUpConfirm => 'GIVE UP';

  @override
  String get lineupKeepPlaying => 'Keep playing';

  @override
  String lineupMatchProgress(int current, int total) {
    return 'MATCH $current OF $total';
  }

  @override
  String lineupWordCount(int words, int letters) {
    String _temp0 = intl.Intl.pluralLogic(
      words,
      locale: localeName,
      other: '$words words',
      one: '1 word',
    );
    String _temp1 = intl.Intl.pluralLogic(
      letters,
      locale: localeName,
      other: '$letters letters',
      one: '1 letter',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String get lineupComplete => 'LINEUP COMPLETE';

  @override
  String get lineupDiscovered => 'REVEALED';

  @override
  String get lineupAttempts => 'ATTEMPTS';

  @override
  String get lineupTime => 'TIME';

  @override
  String get lineupResultCopied => 'Result copied.';

  @override
  String get lineupCopyResult => 'Copy result';

  @override
  String get lineupShareResult => 'Share result';

  @override
  String get lineupNextMatch => 'NEXT MATCH';

  @override
  String get lineupPreviousMatch => 'PREVIOUS';

  @override
  String get lineupNoNumber => 'Player with no confirmed number';

  @override
  String lineupNotDiscovered(String shirt) {
    return '$shirt, not revealed';
  }

  @override
  String lineupShirtLabel(int number) {
    return 'Shirt $number';
  }

  @override
  String lineupA11yRevealed(String shirt, String name) {
    return '$shirt, $name, revealed';
  }

  @override
  String lineupA11yPending(String shirt, String position) {
    return '$shirt, $position, not revealed yet';
  }

  @override
  String get lineupTileCorrect => 'correct position';

  @override
  String get lineupTilePresent => 'letter exists, wrong position';

  @override
  String get lineupTileAbsent => 'letter not in the word';

  @override
  String get lineupTileEmpty => 'empty';

  @override
  String get keyboardDelete => 'Delete';

  @override
  String get keyboardConfirm => 'Confirm';

  @override
  String get commonCloseLabel => 'Close';

  @override
  String get careerSubtitle => 'Guess from the career';

  @override
  String get careerSelectFromList => 'Select a player from the list.';

  @override
  String get careerRevealTitle => 'Reveal player?';

  @override
  String get careerRevealMessage => 'Revealing the answer will end this round.';

  @override
  String get careerReveal => 'REVEAL';

  @override
  String get careerRevealPlayer => 'Reveal player';

  @override
  String get careerGuess => 'GUESS';

  @override
  String get careerNextPlayer => 'NEXT PLAYER';

  @override
  String careerAttemptsRemaining(int remaining) {
    return 'Attempts · $remaining left';
  }

  @override
  String get careerCorrectTitle => 'You got it!';

  @override
  String get careerCorrectFirstTry => 'Got it on the first try!';

  @override
  String careerCorrectInAttempts(int attempts) {
    return 'You got it in $attempts attempts.';
  }

  @override
  String get careerWrongTitle => 'Not this time';

  @override
  String careerUsedAllAttempts(int max) {
    return 'You used all $max attempts.';
  }

  @override
  String get careerPlayerRevealed => 'Player revealed';

  @override
  String get careerRoundEnded => 'Round ended.';

  @override
  String get careerYouGotIt => 'You got it';

  @override
  String get careerWas => 'It was';

  @override
  String get careerAnswer => 'Answer';

  @override
  String get careerNationalTeam => 'National team';

  @override
  String get careerYears => 'Years';

  @override
  String get careerClubs => 'Clubs';

  @override
  String get careerGames => 'Games';

  @override
  String get careerGoals => 'Goals';

  @override
  String careerOnLoan(String team) {
    return '$team (loan)';
  }

  @override
  String get careerAggregateTitle => 'Combined totals';

  @override
  String careerAggregateLine(
    String club,
    String spells,
    String apps,
    String goals,
  ) {
    return '$club ($spells): $apps apps · $goals goals';
  }

  @override
  String get commonBack => 'BACK';

  @override
  String get guessCorrectTitle => 'YOU GOT IT!';

  @override
  String get guessOutOfAttempts => 'Out of attempts';

  @override
  String guessCorrectDetail(int used, int max) {
    return 'You got it in $used of $max attempts.';
  }

  @override
  String get guessNoPlayers => 'No players available for this arena yet.';

  @override
  String get guessRoundEnded => 'Round ended';

  @override
  String guessAttemptsRemaining(int remaining) {
    return '$remaining attempts left';
  }

  @override
  String get guessThePlayerWas => 'The player was: ';

  @override
  String get guessTypePlayer => 'Type a player...';

  @override
  String get guessColPos => 'POS';

  @override
  String get guessColShirt => 'SHIRT';

  @override
  String get guessColBase => 'YOUTH';

  @override
  String get guessColDebut => 'DEBUT';

  @override
  String dateMinutesAgo(int minutes) {
    return '${minutes}min ago';
  }

  @override
  String dateHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String dateDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String datePrepositionFull(int day, String month) {
    return '$month $day';
  }

  @override
  String get socialMediaTitle => 'MEDIA';

  @override
  String get socialFeedLoadError => 'Couldn\'t load the feed';

  @override
  String socialEmptyState(String club) {
    return 'Follow $club on social media';
  }

  @override
  String socialViewsM(String value) {
    return '${value}M views';
  }

  @override
  String socialViewsK(String value) {
    return '${value}K views';
  }

  @override
  String socialViewsCount(int count) {
    return '$count views';
  }

  @override
  String get socialPlatformInstagram => 'INSTAGRAM';

  @override
  String get socialPlatformYoutube => 'YOUTUBE';

  @override
  String get socialPlatformX => 'X';

  @override
  String get newsTitle => 'NEWS';

  @override
  String get newsLoadError => 'Couldn\'t load the news';

  @override
  String get newsEmptyTitle => 'No news here yet';

  @override
  String newsEmptyMessage(String club) {
    return 'Check back later for the latest $club updates.';
  }

  @override
  String newsSourceLabel(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'SOURCE: GOIÁS ESPORTE CLUBE',
      'other': 'SOURCE: $club',
    });
    return '$_temp0';
  }

  @override
  String get newsOpenOriginal => 'Open original article';

  @override
  String get newsPdfLoadErrorTitle => 'Couldn\'t load the PDF';

  @override
  String get newsPdfShareButton => 'Share PDF';

  @override
  String get relTimeNow => 'now';

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
    return '${n}wk';
  }

  @override
  String relTimeMonths(int n) {
    return '${n}mo';
  }

  @override
  String partnersTitle(String clubName) {
    return '$clubName Partners';
  }

  @override
  String partnersSubtitle(String clubName) {
    return 'Brands that walk alongside $clubName.';
  }

  @override
  String partnersOpenInstagram(String name) {
    return 'Open $name on Instagram';
  }

  @override
  String partnersOpenWebsite(String name) {
    return 'Open $name website';
  }

  @override
  String get squadTitle => 'SQUAD';

  @override
  String get squadLoadError => 'Could not load the squad';

  @override
  String get squadEmpty => 'Squad unavailable at the moment';

  @override
  String get squadClubHistory => 'Career';

  @override
  String get squadAboutSection => 'About';

  @override
  String squadCareerStatsLine(String matches, String goals) {
    return '$matches matches · $goals goals';
  }

  @override
  String get squadNumber => 'Number';

  @override
  String get squadAge => 'Age';

  @override
  String squadAgeValue(int age) {
    return '$age years old';
  }

  @override
  String get squadNationality => 'Nationality';

  @override
  String get squadHeight => 'Height';

  @override
  String get squadFoot => 'Foot';

  @override
  String get squadLoanTag => '(loan)';

  @override
  String get squadDataUnconfirmed => 'Data not confirmed by source.';

  @override
  String get squadGroupGoalkeepers => 'Goalkeepers';

  @override
  String get squadGroupDefenders => 'Centre-backs';

  @override
  String get squadGroupRightBacks => 'Right-backs';

  @override
  String get squadGroupLeftBacks => 'Left-backs';

  @override
  String get squadGroupDefensiveMids => 'Defensive midfielders';

  @override
  String get squadGroupMidfielders => 'Midfielders';

  @override
  String get squadGroupForwards => 'Forwards';

  @override
  String get squadInstagramLabel => 'Instagram';

  @override
  String get validatorNameRequired => 'Enter your full name.';

  @override
  String get validatorEmailRequired => 'Enter your email.';

  @override
  String get validatorEmailInvalid => 'Enter a valid email.';

  @override
  String get validatorPasswordRequired => 'Enter your password.';

  @override
  String get validatorPasswordCreate => 'Create a password.';

  @override
  String validatorPasswordMinLength(int min) {
    return 'The password must be at least $min characters.';
  }

  @override
  String get validatorConfirmRequired => 'Confirm your password.';

  @override
  String get validatorPasswordsDoNotMatch => 'The passwords don\'t match.';

  @override
  String get validatorPhoneRequired => 'Enter your phone number.';

  @override
  String get validatorZipRequired => 'Enter your zip code.';

  @override
  String get checkEmailResent => 'Email resent. Check your inbox.';

  @override
  String get checkEmailTitle => 'Confirm your email';

  @override
  String get checkEmailResending => 'Resending...';

  @override
  String checkEmailResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get checkEmailResend => 'Resend code';

  @override
  String get checkEmailOtpSentTo => 'We sent a 6-digit code to';

  @override
  String get checkEmailConfirmButton => 'CONFIRM CODE';

  @override
  String get checkEmailDidNotReceive => 'Didn\'t receive the code?';

  @override
  String get checkEmailChangeEmail => 'Wrong email? Change email';

  @override
  String get checkEmailChangeTitle => 'Change email?';

  @override
  String get checkEmailChangeMessage =>
      'This ends this signup and starts a new one, so you can enter the correct email.';

  @override
  String get checkEmailChangeConfirm => 'Change email';

  @override
  String get resetPasswordTitle => 'Create new password';

  @override
  String get resetPasswordSubtitle =>
      'Choose a new password to access your account.';

  @override
  String get resetPasswordSuccessTitle => 'Password changed successfully';

  @override
  String get resetPasswordSuccessMessage =>
      'Your password has been updated. Sign in again to continue.';

  @override
  String get forgotVerifyEmailTitle => 'Check your email';

  @override
  String forgotSentDescription(String club) {
    return 'If this email has an account with the $club app, you\'ll receive a reset link shortly:';
  }

  @override
  String get forgotNotReceived => 'Didn\'t get it?';

  @override
  String get forgotResendSuccess =>
      'If the account exists, we resent the email.';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get forgotTitle => 'Recover password';

  @override
  String get forgotSubtitle => 'Enter your email to get the reset link.';

  @override
  String get forgotSendButton => 'Send link';

  @override
  String get forgotSending => 'Sending...';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get ticketsLoadError => 'Couldn\'t load the tickets.';

  @override
  String get ticketsNextEvent => 'NEXT EVENT';

  @override
  String get ticketsQuickAccess => 'QUICK ACCESS';

  @override
  String get ticketsMyTickets => 'My tickets';

  @override
  String ticketsMyTicketsSubtitle(String club) {
    return 'Tickets for $club matches';
  }

  @override
  String get ticketsMyOrders => 'My orders';

  @override
  String get ticketsMyOrdersSubtitle => 'Your purchase history';

  @override
  String get ticketsNoEvents => 'No events available right now';

  @override
  String get ticketsNoEventsMessage =>
      'When a new match becomes available for sale or check-in, it\'ll show up here.';

  @override
  String get ticketsMyTicketsTitle => 'MY TICKETS';

  @override
  String get ticketsMyTicketsLoadError => 'Couldn\'t load your tickets';

  @override
  String get ticketsMyTicketsEmpty => 'You don\'t have any tickets yet';

  @override
  String ticketsMyTicketsEmptyMessage(String club) {
    return 'Your tickets for $club matches will show up here.';
  }

  @override
  String get ticketsMyOrdersTitle => 'MY ORDERS';

  @override
  String get ticketsMyOrdersLoadError => 'Couldn\'t load your orders';

  @override
  String get ticketsMyOrdersEmpty => 'No orders found';

  @override
  String get ticketsMyOrdersEmptyMessage =>
      'Your ticket purchases will show up here.';

  @override
  String ticketsOrderNumber(String number) {
    return 'Order $number';
  }

  @override
  String get ticketStatusValid => 'Valid';

  @override
  String get ticketStatusUsed => 'Used';

  @override
  String get ticketStatusCancelled => 'Cancelled';

  @override
  String get ticketStatusExpired => 'Expired';

  @override
  String get ticketStatusRefunded => 'Refunded';

  @override
  String get orderStatusConfirmed => 'Confirmed';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderStatusRefunded => 'Refunded';

  @override
  String get ticketsCheckinUnavailableLabel => 'CHECK-IN NOT YET AVAILABLE';

  @override
  String get ticketsCheckinUnavailableButton => 'Check-in coming soon';

  @override
  String ticketsCheckinAvailableFrom(String date, String time) {
    return 'Available from $date at $time';
  }

  @override
  String get ticketsCheckinAvailableLabel =>
      'YOUR PLAN GIVES YOU ACCESS TO THIS MATCH';

  @override
  String get ticketsCheckInButton => 'Check in';

  @override
  String get ticketsDeclinedLabel => 'YOU MARKED THAT YOU WON\'T GO THIS TIME';

  @override
  String get ticketsChangedMindButton => 'I changed my mind';

  @override
  String get ticketsCheckinClosedLabel => 'CHECK-IN CLOSED FOR THIS MATCH';

  @override
  String get ticketsCheckinClosedButton => 'Check-in closed';

  @override
  String get ticketsCheckinAwayGameLabel =>
      'CHECK-IN ONLY AVAILABLE FOR HOME MATCHES';

  @override
  String get ticketsViewTicketButton => 'View ticket';

  @override
  String get ticketsSaleUpcomingLabel => 'SALES NOT OPEN YET';

  @override
  String get ticketsSaleUpcomingButton => 'Sales coming soon';

  @override
  String ticketsSaleStartsAt(String date, String time) {
    return 'Sales start: $date at $time';
  }

  @override
  String get ticketsSaleOpenLabel => 'TICKETS AVAILABLE';

  @override
  String get ticketsBuyTicketButton => 'Buy ticket';

  @override
  String get ticketsSoldOutLabel => 'TICKETS SOLD OUT';

  @override
  String get ticketsSoldOutButton => 'Sold out';

  @override
  String get ticketsSaleClosedLabel => 'SALES CLOSED FOR THIS MATCH';

  @override
  String get ticketsSaleClosedButton => 'Sales closed';

  @override
  String get ticketsSaleAwayGameLabel => 'TICKETS ONLY FROM THE HOME CLUB';

  @override
  String get ticketsCheckinConfirmedLabel => 'CHECK-IN CONFIRMED';

  @override
  String get ticketsUndoCheckInButton => 'Undo check-in';

  @override
  String get ticketsChangeCheckInButton => 'Change check-in';

  @override
  String get ticketsConfirmPresenceTitle => 'CONFIRM ATTENDANCE';

  @override
  String get ticketsGoToMatchButton => 'I\'m going';

  @override
  String get ticketsNotThisTimeButton => 'Not this time';

  @override
  String get ticketsDeclineConfirmTitle => 'Are you sure you\'re not going?';

  @override
  String ticketsDeclineConfirmMessage(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias':
          'Serrinha isn\'t the same without you. Goiás counts on the support of Nação Esmeraldina! 💚\n\nYou can still change your mind while check-in is open.',
      'other':
          'The stadium isn\'t the same without you. $club counts on the fans\' support! 💚\n\nYou can still change your mind while check-in is open.',
    });
    return '$_temp0';
  }

  @override
  String get ticketsWantToGoButton => 'I want to go';

  @override
  String get ticketsConfirmDeclineButton => 'Confirm I\'m not going';

  @override
  String get ticketsCheckinSuccessTitle => 'Check-in complete!';

  @override
  String get ticketsCheckinSuccessMessage =>
      'The ticket is also available in the My Tickets menu.';

  @override
  String get ticketsCloseButton => 'Close';

  @override
  String get ticketsSaveTicketButton => 'Save ticket';

  @override
  String ticketsSectorPickerTitle(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'Where do you want to support the Verdão?',
      'other': 'Where do you want to support $club?',
    });
    return '$_temp0';
  }

  @override
  String get ticketsSectorPickerSubtitle =>
      'Choose the section for this match.';

  @override
  String get ticketsConfirmCheckInButton => 'Confirm check-in';

  @override
  String get ticketsViewTicketTitle => 'MY TICKET';

  @override
  String get ticketsMatchInfoTitle => 'MATCH INFORMATION';

  @override
  String ticketsHomeCrowdLabel(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'GOIÁS SUPPORTERS',
      'other': '$club SUPPORTERS',
    });
    return '$_temp0';
  }

  @override
  String get ticketsAwayCrowdLabel => 'AWAY SUPPORTERS';

  @override
  String get ticketsContinueButton => 'Continue';

  @override
  String ticketsTicketCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets',
      one: '1 ticket',
    );
    return '$_temp0';
  }

  @override
  String get ticketsSummaryTitle => 'PURCHASE SUMMARY';

  @override
  String get ticketsTotalLabel => 'Total';

  @override
  String ticketsHolderDataTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'TICKET HOLDERS\' DETAILS',
      one: 'TICKET HOLDER DETAILS',
    );
    return '$_temp0';
  }

  @override
  String ticketsHolderSlotLabel(int index, String sector, String category) {
    return 'Ticket $index · $sector · $category';
  }

  @override
  String get ticketsHolderIsSelfCheckbox => 'This ticket is for me';

  @override
  String get ticketsDocumentLabel => 'ID or passport number';

  @override
  String get ticketsNominalWarning =>
      'This ticket is personal and non-transferable. Check the details before continuing.';

  @override
  String get ticketsFinalizePurchaseButton => 'Finish purchase';

  @override
  String get ticketsPurchaseSuccessTitle => 'Ticket purchased!';

  @override
  String get ticketsPurchaseSuccessMessage =>
      'The ticket is also available in the My Tickets menu.';

  @override
  String get ticketsTabUpcoming => 'Upcoming';

  @override
  String get ticketsTabHistory => 'History';

  @override
  String get ticketsUndoCheckInConfirmTitle => 'Undo check-in?';

  @override
  String get ticketsUndoCheckInConfirmMessage =>
      'Your access to this match will be cancelled and your spot may become available again.\n\nYou can check in again while the period remains open.';

  @override
  String get ticketsKeepCheckInButton => 'Keep check-in';

  @override
  String get ticketsOriginCheckIn => 'Member check-in';

  @override
  String get ticketsOriginPurchase => 'Purchase';

  @override
  String get ticketsViewRelatedTicket => 'View ticket';

  @override
  String get ticketsLoadUserDataError =>
      'Couldn\'t load your data. Please try again.';

  @override
  String get ticketsNotMemberTitle => 'You\'re not a member yet';

  @override
  String ticketsNotMemberMessage(String programName) {
    return 'Check-in is exclusive to members with an active $programName.';
  }

  @override
  String get ticketsNotMemberGoToMembershipButton => 'See membership plans';

  @override
  String get ticketsRequestRefundButton => 'Request refund';

  @override
  String get ticketsRefundConfirmTitle => 'Request refund';

  @override
  String get ticketsRefundConfirmMessage =>
      'Are you sure you want to request a refund for this ticket?\n\nOnce confirmed, this ticket will no longer be valid.';

  @override
  String get ticketsRefundConfirmButton => 'Confirm refund';

  @override
  String get ticketsRefundCancelButton => 'Back';

  @override
  String get ticketsRefundErrorTitle => 'Couldn\'t process the refund';

  @override
  String get ticketsRefundErrorMessage =>
      'We couldn\'t complete the refund for this ticket. Please try again.';

  @override
  String get ticketsViewDetailsButton => 'View details';

  @override
  String get ticketsRefundDetailsTitle => 'Refunded ticket';

  @override
  String get ticketsRefundDetailsStatusLabel => 'Status';

  @override
  String get ticketsRefundDetailsMatchLabel => 'Match';

  @override
  String get ticketsRefundDetailsTicketLabel => 'Ticket';

  @override
  String get ticketsRefundDetailsRequestedAtLabel => 'Requested on';

  @override
  String get ticketsDemoDisclaimerBody =>
      'This purchase is simulated. No charge will be made and the generated ticket is not valid for stadium entry.';

  @override
  String get ticketsDemoTag => 'Demo ticket';

  @override
  String get ticketsRefundDemoNotice =>
      'This simulation involves no real money — nothing will be refunded.';

  @override
  String get ticketsRefundDemoConcludedNote =>
      'Demo refund — no money was moved.';

  @override
  String get ticketsHalfPriceTypeLabel => 'Half-price type';

  @override
  String get ticketsHalfPriceLawOption => 'By law';

  @override
  String get ticketsHalfPricePromotionalOption => 'Promotional';

  @override
  String get ticketsHalfPriceProofLabel => 'Half-price proof (required)';

  @override
  String get ticketsHalfPriceProofUploadButton => 'Attach proof';

  @override
  String get ticketsHalfPriceProofUploaded => 'Proof uploaded';

  @override
  String get ticketPdfDemoWatermark => 'DEMO\nNOT VALID FOR ENTRY';

  @override
  String get ticketPdfDemoQrCaption => 'Demo QR code';

  @override
  String get ticketPdfFieldVenue => 'Venue';

  @override
  String get ticketPdfFieldGate => 'Gate';

  @override
  String get ticketPdfFieldCategory => 'Category';

  @override
  String get ticketPdfFieldDocument => 'ID/Passport';

  @override
  String get ticketPdfFieldOrigin => 'Origin';

  @override
  String get ticketPdfFieldAmount => 'Amount';

  @override
  String get ticketPdfFieldCode => 'Code';

  @override
  String get ticketPdfAntiScalpingTitle => 'DON\'T BUY\nFROM SCALPERS!';

  @override
  String get ticketPdfAntiScalpingSubtitle => 'This ticket may be fake.';

  @override
  String ticketPdfFooterNotice(String club) {
    return 'This ticket is personal and non-transferable. Photo ID is required for entry. Only $club or Brazilian national team jerseys are allowed.';
  }

  @override
  String get ticketPdfInvalidTicket => 'INVALID\nTICKET';

  @override
  String get penaltyFinalResult => 'FINAL RESULT';

  @override
  String penaltyConverted(int goals, int total) {
    return 'You scored $goals of $total kicks';
  }

  @override
  String get penaltyScoreLabel => 'PENALTIES';

  @override
  String get penaltyDragToShoot => 'Drag the ball to shoot';

  @override
  String penaltyGoalsCount(int goals) {
    String _temp0 = intl.Intl.pluralLogic(
      goals,
      locale: localeName,
      other: '$goals Goals',
      one: '1 Goal',
    );
    return '$_temp0';
  }

  @override
  String penaltyGoalsCountUpper(int goals) {
    String _temp0 = intl.Intl.pluralLogic(
      goals,
      locale: localeName,
      other: '$goals GOALS',
      one: '1 GOAL',
    );
    return '$_temp0';
  }

  @override
  String get penaltyResultGoal => 'GOAL!';

  @override
  String get penaltyResultSave => 'SAVE!';

  @override
  String get penaltyResultOut => 'MISS!';

  @override
  String get penaltyResultPost => 'POST!';

  @override
  String get penaltyResultGoalShort => 'Goal';

  @override
  String get penaltyResultSaveShort => 'Save';

  @override
  String get penaltyResultOutShort => 'Miss';

  @override
  String get penaltyResultPostShort => 'Post';

  @override
  String get playerPositionGolFull => 'Goalkeeper';

  @override
  String get playerPositionGolShort => 'GK';

  @override
  String get playerPositionZagFull => 'Centre-back';

  @override
  String get playerPositionZagShort => 'CB';

  @override
  String get playerPositionLdFull => 'Right-back';

  @override
  String get playerPositionLdShort => 'RB';

  @override
  String get playerPositionLeFull => 'Left-back';

  @override
  String get playerPositionLeShort => 'LB';

  @override
  String get playerPositionAldFull => 'Right wing-back';

  @override
  String get playerPositionAldShort => 'RWB';

  @override
  String get playerPositionAleFull => 'Left wing-back';

  @override
  String get playerPositionAleShort => 'LWB';

  @override
  String get playerPositionVolFull => 'Defensive midfielder';

  @override
  String get playerPositionVolShort => 'DM';

  @override
  String get playerPositionMcFull => 'Midfielder';

  @override
  String get playerPositionMcShort => 'MF';

  @override
  String get playerPositionMeiFull => 'Attacking midfielder';

  @override
  String get playerPositionMeiShort => 'AM';

  @override
  String get playerPositionMdFull => 'Right midfielder';

  @override
  String get playerPositionMdShort => 'RM';

  @override
  String get playerPositionMeFull => 'Left midfielder';

  @override
  String get playerPositionMeShort => 'LM';

  @override
  String get playerPositionPdFull => 'Right winger';

  @override
  String get playerPositionPdShort => 'RW';

  @override
  String get playerPositionPeFull => 'Left winger';

  @override
  String get playerPositionPeShort => 'LW';

  @override
  String get playerPositionSaFull => 'Second striker';

  @override
  String get playerPositionSaShort => 'SS';

  @override
  String get playerPositionAtaFull => 'Striker';

  @override
  String get playerPositionAtaShort => 'ST';

  @override
  String get crowdTitle => 'FANS\' LINEUP';

  @override
  String get crowdTabEscale => 'PICK';

  @override
  String crowdSubmissionsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lineups submitted',
      one: 'lineup submitted',
    );
    return '$_temp0';
  }

  @override
  String get crowdMostVotedFormation => 'chosen formation';

  @override
  String get crowdNoVotes => 'No votes yet';

  @override
  String crowdNoVotesMessage(String club) {
    return 'Be the first to line up $club and help build the fans\' team.';
  }

  @override
  String get crowdVotingClosed =>
      'Voting closed — this is the lineup you submitted.';

  @override
  String get crowdUpdateLineup => 'UPDATE LINEUP';

  @override
  String get crowdConfirmLineup => 'CONFIRM LINEUP';

  @override
  String get crowdPickPlayer => 'Choose the player for this position';

  @override
  String get crowdSelectedPlayer => 'Selected';

  @override
  String get crowdAlsoCanPlaySection => 'CAN ALSO PLAY HERE';

  @override
  String get crowdCanAlsoPlayBadge => 'Can play';

  @override
  String crowdCardDescVoted(String club) {
    return 'See how the fans are lining up $club for the next match.';
  }

  @override
  String crowdCardDescNew(String club) {
    return 'Line up $club for the next match and see the fans\' most-picked team.';
  }

  @override
  String get clubSectionHistory => 'History';

  @override
  String get clubSectionSquad => 'Squad';

  @override
  String get clubSectionTitles => 'Titles';

  @override
  String get clubSectionPartners => 'Partners';

  @override
  String get clubSectionBoard => 'Board';

  @override
  String get clubBoardSubtitle => 'Councils, presidency and the club\'s board.';

  @override
  String get clubBoardLoadErrorTitle => 'We couldn\'t load the board';

  @override
  String get clubBoardEmptyTitle => 'Board being updated';

  @override
  String get clubBoardEmptyMessage => 'Check back soon for the club\'s board.';

  @override
  String get clubSectionTransparency => 'Transparency';

  @override
  String get clubTransparencySubtitle =>
      'Balance sheets, minutes and financial statements.';

  @override
  String get clubTransparencyLoadErrorTitle => 'We couldn\'t load transparency';

  @override
  String get clubTransparencyEmptyTitle => 'No documents available';

  @override
  String get clubTransparencyEmptyMessage =>
      'Check back soon for the documents.';

  @override
  String clubTransparencyDocumentCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
    );
    return '$_temp0';
  }

  @override
  String get clubTransparencyShareButton => 'Share PDF';

  @override
  String get clubSectionTimeline => 'Timeline';

  @override
  String get clubSectionSongs => 'Anthem & Songs';

  @override
  String clubHistorySubtitle(String year) {
    return 'From $year to today.';
  }

  @override
  String get clubSquadSubtitle => 'The players who wear the shirt.';

  @override
  String clubTitlesSubtitle(int count) {
    return '$count trophies throughout history.';
  }

  @override
  String clubPartnersSubtitle(String clubName) {
    return 'Who stands with $clubName.';
  }

  @override
  String get clubSongsSubtitle => 'The anthem and songs that carry the fans.';

  @override
  String get clubSectionIdols => 'Idols';

  @override
  String get clubIdolsSubtitle => 'Names that shaped the club\'s history.';

  @override
  String clubIdolsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count idols',
      one: '1 idol',
    );
    return '$_temp0';
  }

  @override
  String get clubAnthemSection => 'ANTHEM';

  @override
  String clubSongsSection(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'ESMERALDINA SONGS',
      'other': '$club SONGS',
    });
    return '$_temp0';
  }

  @override
  String get clubLyricsLabel => 'LYRICS';

  @override
  String get clubLyricsUnavailable => 'Lyrics not available yet.';

  @override
  String get clubAudioUnavailable => 'Audio not available yet.';

  @override
  String get clubPlaybackError => 'Couldn\'t play this song.';

  @override
  String get clubMuteSemantics => 'Mute';

  @override
  String get clubUnmuteSemantics => 'Unmute';

  @override
  String get clubVolumeSemantics => 'Volume control';

  @override
  String clubPlaySongSemantics(String title) {
    return 'Play $title';
  }

  @override
  String clubPauseSongSemantics(String title) {
    return 'Pause $title';
  }

  @override
  String get clubMainTitles => 'MAIN TITLES';

  @override
  String get clubHistoricCampaigns => 'HISTORIC RUNS';

  @override
  String clubTimesChampion(int count) {
    return '$count× CHAMPION';
  }

  @override
  String get clubEntryTitle => 'THE CLUB';

  @override
  String clubEntrySubtitle(String clubName) {
    return 'History, titles, squad and identity of $clubName.';
  }

  @override
  String clubEntryCta(String clubName) {
    return 'GET TO KNOW $clubName';
  }

  @override
  String membershipLoadError(String programName) {
    return 'Couldn\'t load $programName.';
  }

  @override
  String get membershipPlansTitle => 'PLANS';

  @override
  String membershipSector(String sector) {
    return 'Sector $sector';
  }

  @override
  String get membershipMostChosen => 'MOST CHOSEN';

  @override
  String get membershipPerMonth => '/mo';

  @override
  String membershipOrAnnual(String price) {
    return 'or $price on the annual plan';
  }

  @override
  String get membershipBenefits => 'BENEFITS';

  @override
  String get membershipSeeFullRegulation => 'See the full regulation →';

  @override
  String get membershipStillHaveDoubts =>
      'Still have questions about this plan?';

  @override
  String get membershipSeeFaq => 'SEE FAQ';

  @override
  String get membershipWantToJoin => 'I WANT TO JOIN';

  @override
  String get membershipNoStadiumAccess => 'No stadium access';

  @override
  String get membershipViewPlan => 'VIEW PLAN';

  @override
  String get membershipOtherOptions => 'OTHER OPTIONS';

  @override
  String get membershipMyMembership => 'My membership';

  @override
  String get membershipDependents => 'Dependents';

  @override
  String get membershipDependentsPrep =>
      'Dependent management is still being prepared.';

  @override
  String get membershipPayments => 'Payments';

  @override
  String get membershipPaymentsPrep =>
      'The payment history is still being prepared.';

  @override
  String get membershipCheckinHistory => 'Check-in history';

  @override
  String get membershipAreaPrep => 'This area is still being prepared.';

  @override
  String get membershipSeeOtherPlans => 'See other plans';

  @override
  String membershipHeroTitle(String club) {
    return 'Get even closer\nto $club.';
  }

  @override
  String get membershipHeroSubtitle =>
      'Be part of this story with priority stadium access, ticket savings, discounts and exclusive experiences.';

  @override
  String get membershipChoosePlan => 'CHOOSE YOUR PLAN';

  @override
  String get membershipChosenPlan => 'CHOSEN PLAN';

  @override
  String get membershipChangePlan => 'CHANGE PLAN';

  @override
  String get membershipStep1Access => '1 of 3 · Access data';

  @override
  String get membershipStep2Personal => '2 of 3 · Registration data';

  @override
  String get membershipStep3Address => '3 of 3 · Address';

  @override
  String get membershipCpf => 'CPF';

  @override
  String get membershipNationality => 'Nationality';

  @override
  String get membershipPassport => 'Passport';

  @override
  String get membershipPassportOptional => 'Passport (optional)';

  @override
  String get membershipContactEmail => 'Contact email';

  @override
  String get membershipNickname => 'Nickname (optional)';

  @override
  String get membershipBirthdateHint => 'DD/MM/YYYY';

  @override
  String get membershipGender => 'Gender';

  @override
  String get membershipGenderMale => 'Male';

  @override
  String get membershipGenderFemale => 'Female';

  @override
  String get membershipHomePhone => 'Home phone (optional)';

  @override
  String membershipNewsletter(String programName) {
    return 'I want to receive news from the club and $programName by email.';
  }

  @override
  String get membershipCountry => 'Country';

  @override
  String get membershipPostalCode => 'Postal code';

  @override
  String get membershipDontKnowCep => 'I don\'t know my postal code';

  @override
  String get membershipLoadingCities => 'Loading cities...';

  @override
  String get membershipSelectStateFirst => 'Select the state first';

  @override
  String get membershipSelectCity => 'Select city';

  @override
  String get membershipConfirmAssociation => 'CONFIRM MEMBERSHIP';

  @override
  String get membershipReviewTitle => 'REVIEW YOUR MEMBERSHIP';

  @override
  String get membershipPlanLabel => 'Plan';

  @override
  String get membershipSectorLabel => 'Sector';

  @override
  String get membershipOptionLabel => 'Option';

  @override
  String get membershipHolderData => 'HOLDER DATA';

  @override
  String get membershipName => 'Name';

  @override
  String get membershipBirthLabel => 'Birth';

  @override
  String get membershipContact => 'CONTACT';

  @override
  String get membershipAddressLabel => 'Address';

  @override
  String get membershipCityUf => 'City/State';

  @override
  String get membershipValue => 'AMOUNT';

  @override
  String get membershipMonthly => 'Monthly';

  @override
  String get membershipAnnual => 'Annual';

  @override
  String get membershipTerms => 'MEMBERSHIP TERMS';

  @override
  String membershipAcceptRegulation(String programName) {
    return 'I have read and accept the $programName Regulation';
  }

  @override
  String get membershipReadFullRegulation => 'Read the full regulation →';

  @override
  String membershipDemoDisclaimerBody(String programName) {
    return 'This membership is simulated and does not create a bond with $programName. No charge will be made.';
  }

  @override
  String membershipRegulationDemoNote(String programName) {
    return 'Viewing/accepting this in the demo does not constitute an official membership with $programName.';
  }

  @override
  String get membershipStatusDemoBadge => 'Member Mode — Demo';

  @override
  String get membershipYourMembership => 'YOUR MEMBERSHIP';

  @override
  String get membershipYourBenefits => 'YOUR BENEFITS';

  @override
  String get membershipGoToMemberArea => 'GO TO MY MEMBER AREA';

  @override
  String get membershipBackToHome => 'Back to home';

  @override
  String membershipWelcome(String programName) {
    return 'WELCOME TO\n$programName';
  }

  @override
  String membershipSuccessMessage(String club) {
    return 'Your membership was completed successfully.\nNow you\'re even closer to $club.';
  }

  @override
  String membershipAnnualPlan(String price) {
    return 'Annual plan • $price';
  }

  @override
  String get membershipHolder => 'Holder';

  @override
  String get membershipAssociatedSince => 'Member since';

  @override
  String get membershipStatusActive => 'Active';

  @override
  String get membershipSeeAllBenefits => 'See all benefits →';

  @override
  String get membershipWhatNow => 'WHAT NOW?';

  @override
  String get membershipWhatNowMessage =>
      'Your member area is now available. Follow your plan and benefits and, when available, check in at matches.';

  @override
  String get membershipSituation => 'Status';

  @override
  String get membershipMemberNumber => 'Member number';

  @override
  String get membershipMonthlyFee => 'Monthly fee';

  @override
  String get membershipAnnualFee => 'Annual fee';

  @override
  String get membershipMemberSince => 'Member since';

  @override
  String membershipRegulationName(String programName) {
    return '$programName Regulation';
  }

  @override
  String get membershipMatchAccessNotice =>
      'Your plan gives you access to this match.';

  @override
  String membershipCardNumber(String number) {
    return 'No. $number';
  }

  @override
  String get membershipRegulationPageTitle => 'REGULATIONS';

  @override
  String membershipRegulationEffectiveSince(String date) {
    return 'In effect since $date';
  }

  @override
  String get membershipRegulationTableOfContents => 'CONTENTS';

  @override
  String membershipCancelWhatsapp(String plan, String programName) {
    return 'Hi, I\'d like to cancel my $programName membership ($plan).';
  }

  @override
  String get membershipCancel => 'CANCEL MEMBERSHIP';

  @override
  String get membershipCancelInfo =>
      'Cancellation is done through WhatsApp support, with no penalty outside the deadlines in the Regulation.';

  @override
  String get membershipStatusPending => 'Pending';

  @override
  String get membershipStatusSuspended => 'Suspended';

  @override
  String get membershipStatusCancelled => 'Cancelled';

  @override
  String get membershipFaqTitle => 'FAQ';

  @override
  String get membershipFaqSubtitle =>
      'Find answers about plans, payments, check-in and benefits.';

  @override
  String get membershipFaqLoadError => 'Couldn\'t load the FAQ.';

  @override
  String get membershipFaqNoResults => 'No questions found';

  @override
  String membershipFaqNoResultsMessage(String programName) {
    return 'Try another term or contact $programName support.';
  }

  @override
  String get membershipTalkToSupport => 'TALK TO SUPPORT';

  @override
  String get membershipTalkToSupportMenu => 'Talk to support';

  @override
  String get membershipDontStayInDoubt => 'DON\'T STAY IN DOUBT';

  @override
  String get membershipDidntFindAnswer =>
      'Didn\'t find the answer you were looking for?';

  @override
  String membershipFaqScopeNote(String programName) {
    return 'Questions about the club, youth academy, squad and other topics outside $programName aren\'t answered through this channel.';
  }

  @override
  String get membershipFaqAll => 'All';

  @override
  String get membershipFaqChipGeneral => 'General';

  @override
  String get membershipFaqChipPayment => 'Payment';

  @override
  String get membershipFaqChipSupport => 'Support';

  @override
  String get membershipFaqChipActions => 'Actions';

  @override
  String get membershipFaqChipStadium => 'Stadium';

  @override
  String get membershipFaqChipBenefits => 'Benefits';

  @override
  String get membershipFaqChipPlans => 'Plans';

  @override
  String get membershipFaqChipFacial => 'Facial';

  @override
  String get membershipFaqChipRating => 'Rating';

  @override
  String get membershipFaqChipNoShow => 'No-Show';

  @override
  String get membershipStepAccess => 'Access';

  @override
  String get membershipStepPersonal => 'Sign-up';

  @override
  String get membershipStepAddress => 'Address';

  @override
  String get membershipFaqSearchHint => 'Search a question...';

  @override
  String get membershipHelpTitle => 'HELP & INFO';

  @override
  String get membershipFaqMenuItem => 'FAQ';

  @override
  String get membershipFindCepTitle => 'FIND MY POSTAL CODE';

  @override
  String get membershipFindCepSubtitle =>
      'Enter your address and we\'ll find the matching postal code.';

  @override
  String get membershipStreetLabel => 'Street / Address';

  @override
  String get membershipSearchCep => 'SEARCH POSTAL CODE';

  @override
  String get membershipFoundAddresses => 'WE FOUND THESE ADDRESSES';

  @override
  String get membershipNoAddressFound => 'No address found.';

  @override
  String get membershipNoAddressHint =>
      'Check the state, city and street you entered.';

  @override
  String get membershipAddressSearchError => 'Couldn\'t search the address.';

  @override
  String get membershipValCpfRequired => 'Enter your CPF.';

  @override
  String get membershipValNationality => 'Select your nationality.';

  @override
  String get membershipValPassport => 'Enter a valid passport.';

  @override
  String get membershipValContactEmail => 'Enter your contact email.';

  @override
  String get membershipValNameInvalid => 'Enter a valid name.';

  @override
  String get membershipValBirthRequired => 'Enter your date of birth.';

  @override
  String get membershipValBirthInvalid => 'Enter a valid date.';

  @override
  String get membershipValMinAge => 'The holder must be 18 or older.';

  @override
  String get membershipValSelectOption => 'Select an option.';

  @override
  String get membershipValPhoneRequired => 'Enter your phone.';

  @override
  String get membershipValPhoneInvalid => 'Enter a valid phone.';

  @override
  String get membershipValCountry => 'Select the country.';

  @override
  String get membershipValCep8 => 'Enter an 8-digit postal code.';

  @override
  String get membershipCepLookupError => 'Couldn\'t look up the postal code.';

  @override
  String get membershipValStreet => 'Enter the street.';

  @override
  String get membershipValNumber => 'Enter the number.';

  @override
  String get membershipValNeighborhood => 'Enter the neighborhood.';

  @override
  String get membershipValState => 'Enter the state.';

  @override
  String get membershipValCity => 'Enter the city.';

  @override
  String lineupShareStats(int solved, int total, int attempts, String time) {
    return '$solved/$total found · $attempts attempts · $time';
  }

  @override
  String crowdShareCrowd(String club) {
    return 'Check out the fans\' lineup for $club! 💚';
  }

  @override
  String crowdShareMine(String club) {
    return 'This is my lineup for $club! 💚';
  }

  @override
  String get crowdSubmitted => 'Lineup submitted!';

  @override
  String storeHomeEntryBadge(String storeName) {
    return '$storeName';
  }

  @override
  String get storeHomeEntryTitle => 'The kit awaits';

  @override
  String storeHomeEntryDescription(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'Wear the Green on and off the pitch.',
      'other': 'Wear $club on and off the pitch.',
    });
    return '$_temp0';
  }

  @override
  String get storeHomeEntryCta => 'Visit the store';

  @override
  String get storeProfileMyOrders => 'My orders';

  @override
  String get storeHomeLoadErrorTitle => 'We couldn\'t load the store';

  @override
  String get storeHomeEmptyTitle => 'Store coming soon';

  @override
  String get storeHomeEmptyMessage => 'Check back soon for official products.';

  @override
  String get storeMyPurchasesTitle => 'My Purchases';

  @override
  String get storeSectionCategories => 'Categories';

  @override
  String storeSearchHint(String storeName) {
    return 'Search the $storeName';
  }

  @override
  String get storeListingDefaultTitle => 'Products';

  @override
  String get storeSearchEmptyTitle => 'Search for products';

  @override
  String get storeSearchEmptyMessage =>
      'Name, category, collection, or product type.';

  @override
  String get storeListingNoResultsTitle => 'No products found';

  @override
  String get storeListingNoResultsMessage =>
      'Try adjusting your search or removing some filters.';

  @override
  String storeListingProductCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
    );
    return '$_temp0';
  }

  @override
  String storeItemCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String storeOrdersMoreItems(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count items',
      one: '+ 1 item',
    );
    return '$_temp0';
  }

  @override
  String get storeSortLabel => 'Sort';

  @override
  String get storeFiltersLabel => 'Filters';

  @override
  String storeFiltersLabelCount(Object count) {
    return 'Filters ($count)';
  }

  @override
  String get storeSortSheetTitle => 'Sort by';

  @override
  String get storeFiltersSheetTitle => 'Filters';

  @override
  String get storeClearFilters => 'Clear filters';

  @override
  String get storeFilterAudienceLabel => 'Audience';

  @override
  String get storeFilterTypeLabel => 'Type';

  @override
  String get storeFilterUniformLabel => 'Kit';

  @override
  String get storeUniform01 => 'Kit 01';

  @override
  String get storeUniform02 => 'Kit 02';

  @override
  String get storeUniform03 => 'Kit 03';

  @override
  String get storeFilterSizeLabel => 'Size';

  @override
  String get storeFilterOnlyAvailable => 'In stock only';

  @override
  String get storeFilterOnlyOnSale => 'On sale only';

  @override
  String get storeApplyFilters => 'Apply filters';

  @override
  String get storeSortRelevance => 'Relevance';

  @override
  String get storeSortNewest => 'New arrivals';

  @override
  String get storeSortPriceLowToHigh => 'Lowest price';

  @override
  String get storeSortPriceHighToLow => 'Highest price';

  @override
  String get storeSortBiggestDiscount => 'Biggest discount';

  @override
  String get storeAudienceMasculine => 'Men';

  @override
  String get storeAudienceFeminine => 'Women';

  @override
  String get storeAudienceKids => 'Kids';

  @override
  String get storeAudienceUnisex => 'Unisex';

  @override
  String get storeTypeMatchJersey => 'Match';

  @override
  String get storeTypeGoalkeeper => 'Goalkeeper';

  @override
  String get storeTypeTraining => 'Training';

  @override
  String get storeTypeCasual => 'Casual';

  @override
  String get storeTypeAccessory => 'Accessory';

  @override
  String get storeTypeSouvenir => 'Souvenir';

  @override
  String get storeCategoryLaunches => 'New arrivals';

  @override
  String get storeCategoryUniforms => 'Jerseys';

  @override
  String get storeCategoryAccessories => 'Accessories';

  @override
  String get storeCategorySouvenirs => 'Souvenirs';

  @override
  String get storeCategoryPersonalizable => 'Customizable';

  @override
  String get storeCollectionFan => 'Fan';

  @override
  String get storeCollectionPlayer => 'Player';

  @override
  String get storeCollectionTrainingTravel => 'Training, travel & pre-match';

  @override
  String get storeCollectionSocksGloves => 'Socks & gloves';

  @override
  String get storeShippingEconomyLabel => 'Economy';

  @override
  String get storeShippingStandardLabel => 'Standard';

  @override
  String get storeShippingExpressLabel => 'Express';

  @override
  String get storeShippingEconomyEta => '7 to 10 business days';

  @override
  String get storeShippingStandardEta => '4 to 7 business days';

  @override
  String get storeShippingExpressEta => '2 to 3 business days';

  @override
  String get storeBadgeSoldOut => 'Sold out';

  @override
  String get storeBadgeOnSale => 'Sale';

  @override
  String storeInstallmentsLabel(Object count, Object value) {
    return 'up to ${count}x of $value';
  }

  @override
  String get storeProductLoadErrorTitle => 'We couldn\'t load this product';

  @override
  String get storeProductLoadErrorMessage => 'Go back and try again.';

  @override
  String get storeOrderCreateErrorTitle => 'We couldn\'t confirm your order';

  @override
  String get storeOrderCreateErrorMessage =>
      'Check your connection and try again. Your bag is still saved.';

  @override
  String get storeBackToStoreButton => 'Back to the store';

  @override
  String get storeProductSoldOut => 'This product is currently sold out.';

  @override
  String storeProductPhotoLabel(String name, int index, int total) {
    return '$name, photo $index of $total';
  }

  @override
  String get storeZoomImageHint => 'Tap to zoom';

  @override
  String get storeShareProduct => 'Share product';

  @override
  String get storeReferenceLabel => 'Ref.';

  @override
  String get storeDeliveryOrPickupLabel => 'Delivery or pickup';

  @override
  String get storePickupFreeNote => 'Free pickup';

  @override
  String get storeSizeLabel => 'Size';

  @override
  String get storeQuantityLabel => 'Quantity';

  @override
  String get storeDetailsLabel => 'Details';

  @override
  String get storePersonalizationLabel => 'Personalization (optional)';

  @override
  String storePersonalizationNameField(Object price) {
    return 'Name on jersey (+ $price)';
  }

  @override
  String storePersonalizationNumberField(Object price) {
    return 'Number on jersey (+ $price)';
  }

  @override
  String storePersonalizationSurchargeNote(Object price) {
    return 'Personalization surcharge: $price';
  }

  @override
  String get storeAddedToCartSnackbar => 'Product added to your bag.';

  @override
  String get storeAddToCartButton => 'Add to bag';

  @override
  String get storeSeeCartAction => 'View bag';

  @override
  String get storeChooseSizeMessage =>
      'Select a size before adding to your bag.';

  @override
  String get storeBuyNowButton => 'Buy now';

  @override
  String get storeVariationSoldOut => 'This variation is sold out.';

  @override
  String get storeCartTitle => 'BAG';

  @override
  String get storeCartEmptyTitle => 'Your bag is empty';

  @override
  String storeCartEmptyMessage(String clubCode, String club) {
    String _temp0 = intl.Intl.selectLogic(clubCode, {
      'goias': 'Pick your official gear and carry the Green with you.',
      'other': 'Pick your official $club gear with you.',
    });
    return '$_temp0';
  }

  @override
  String storeCartEmptyCta(String storeName) {
    return 'Go to the $storeName';
  }

  @override
  String storeCartItemSize(Object size) {
    return 'Size $size';
  }

  @override
  String storeCartItemNumber(Object number) {
    return '#$number';
  }

  @override
  String get storeRemoveItemTitle => 'Remove item';

  @override
  String storeRemoveItemMessage(Object productName) {
    return 'Remove \"$productName\" from your bag?';
  }

  @override
  String storeRemoveItemAction(Object productName) {
    return 'Remove $productName from bag';
  }

  @override
  String get storeRemove => 'Remove';

  @override
  String get storeCouponHint => 'Discount code';

  @override
  String get storeCouponApply => 'Apply';

  @override
  String get storeCouponInvalid => 'Invalid or expired code.';

  @override
  String get storeCheckoutCta => 'Checkout';

  @override
  String get storeSubtotal => 'Subtotal';

  @override
  String get storeDiscountGeneric => 'Discount';

  @override
  String storeDiscountLabel(Object code) {
    return 'Discount ($code)';
  }

  @override
  String get storeTotal => 'Total';

  @override
  String storeFreeShippingNote(Object amount) {
    return 'Free shipping over $amount.';
  }

  @override
  String get storeFree => 'Free';

  @override
  String get storeShippingLabel => 'Shipping';

  @override
  String get storePickupWord => 'Pickup';

  @override
  String get storeStepIdentification => 'Identification';

  @override
  String get storeStepDelivery => 'Delivery';

  @override
  String get storeStepPayment => 'Payment';

  @override
  String get storeStepReview => 'Review';

  @override
  String get storeContinueButton => 'Continue';

  @override
  String get storeFullNameLabel => 'Full name';

  @override
  String get storeCpfLabel => 'CPF';

  @override
  String get storePhoneLabel => 'Phone / WhatsApp';

  @override
  String get storeDeliveryToHome => 'Deliver to my address';

  @override
  String get storePickupAtStore => 'Pick up in store';

  @override
  String get storeDeliveryAddressLabel => 'Delivery address';

  @override
  String get storeAddAddress => 'Add address';

  @override
  String storeZipCodePrefix(Object zip) {
    return 'ZIP $zip';
  }

  @override
  String get storePickupResponsibleLabel => 'Who will pick it up';

  @override
  String get storePickupSelf => 'Myself';

  @override
  String get storePickupOther => 'Someone else';

  @override
  String get storePickupResponsibleNameField =>
      'Name of the person picking it up';

  @override
  String get storePickupResponsibleCpfField =>
      'CPF of the person picking it up';

  @override
  String get storePickupSectionTitle => 'Store pickup';

  @override
  String get storePickupBySelf => 'Pickup by the account holder';

  @override
  String storePickupByOther(Object name) {
    return 'Pickup by $name';
  }

  @override
  String storePickupAddressPrefix(Object address) {
    return 'Pick up at: $address';
  }

  @override
  String get storePaymentPix => 'Pix';

  @override
  String get storeCreditCard => 'Credit card';

  @override
  String get storeDemoDisclaimer => 'Demo environment. No charge will be made.';

  @override
  String get storeQrCodeNote =>
      'Simulated QR code — scan it in your bank\'s app.';

  @override
  String get storeSimulatePixButton => 'Simulate Pix payment';

  @override
  String get storePixApproved => 'Pix payment simulated successfully.';

  @override
  String get storeCardNumberLabel => 'Card number';

  @override
  String get storeCardHolderLabel => 'Name on card';

  @override
  String get storeCardExpiryLabel => 'Expiry (MM/YY)';

  @override
  String get storeCardCvvLabel => 'CVV';

  @override
  String get storeInstallmentsFieldLabel => 'Installments';

  @override
  String storeInstallmentsCash(Object price) {
    return 'Full payment — $price';
  }

  @override
  String storeInstallmentsNoInterest(Object count, Object price) {
    return '${count}x of $price, no interest';
  }

  @override
  String get storeSimulatePaymentButton => 'Simulate payment';

  @override
  String get storeCardApprovedGeneric => 'Card approved (simulated).';

  @override
  String storeCardApprovedWithDigits(Object digits) {
    return 'Card ending in $digits approved (simulated).';
  }

  @override
  String storeCardFinalDigits(Object digits) {
    return 'Credit card ending in $digits';
  }

  @override
  String storeCardSummaryLine(Object digits, Object installments) {
    return 'Credit card ending in $digits · ${installments}x';
  }

  @override
  String get storeConfirmOrderButton => 'Confirm order';

  @override
  String get storeEdit => 'Edit';

  @override
  String storeAcceptTerms(String storeName) {
    return 'I\'ve read and accept the $storeName purchase terms.';
  }

  @override
  String get storeOrderConfirmedTitle => 'Order confirmed!';

  @override
  String get storeItemsLabel => 'Items';

  @override
  String storeItemsCountLabel(Object count) {
    return 'Items ($count)';
  }

  @override
  String get storeTrackOrderButton => 'Track order';

  @override
  String get storeContinueShoppingButton => 'Continue shopping';

  @override
  String get storeBackHomeButton => 'Back to home';

  @override
  String get storeOrdersTitle => 'MY ORDERS';

  @override
  String get storeOrdersEmptyTitle => 'You haven\'t placed any orders yet';

  @override
  String storeOrdersEmptyMessage(String storeName) {
    return 'Your $storeName orders will show up here.';
  }

  @override
  String get storeOrdersLoadError => 'We couldn\'t load your orders';

  @override
  String get storeOrderCancelled => 'Order cancelled';

  @override
  String get storeCustomerLabel => 'Customer';

  @override
  String get storeStatusStepDone => 'done';

  @override
  String get storeStatusStepPending => 'pending';

  @override
  String get storeStatusCreated => 'Order placed';

  @override
  String get storeStatusPaymentPending => 'Awaiting payment';

  @override
  String get storeStatusPaid => 'Payment approved';

  @override
  String get storeStatusPreparing => 'Preparing';

  @override
  String get storeStatusReadyForPickup => 'Ready for pickup';

  @override
  String get storeStatusShipped => 'Shipped';

  @override
  String get storeStatusDeliveredPickup => 'Picked up';

  @override
  String get storeStatusDeliveredShipping => 'Delivered';

  @override
  String get storeStatusCancelled => 'Cancelled';

  @override
  String get storeAddressesTitle => 'DELIVERY ADDRESSES';

  @override
  String get storeAddressesSubtitle =>
      'Choose where you\'d like to receive your orders.';

  @override
  String get storeAddressesEmptyTitle => 'No saved addresses';

  @override
  String get storeAddressesEmptyMessage =>
      'Add an address to speed up your next purchases.';

  @override
  String get storeRemoveAddressTitle => 'Remove address';

  @override
  String storeRemoveAddressMessage(Object address) {
    return 'Remove \"$address\"?';
  }

  @override
  String get storeDefaultBadge => 'DEFAULT';

  @override
  String get storeMakeDefault => 'Make default';

  @override
  String get storeNewAddressTitle => 'NEW ADDRESS';

  @override
  String get storeEditAddressTitle => 'EDIT ADDRESS';

  @override
  String get storeZipCodeLabel => 'ZIP code';

  @override
  String get storeStreetLabel => 'Street';

  @override
  String get storeNumberLabel => 'Number';

  @override
  String get storeComplementLabel => 'Complement (optional)';

  @override
  String get storeNeighborhoodLabel => 'Neighborhood';

  @override
  String get storeCityLabel => 'City';

  @override
  String get storeStateLabel => 'State';

  @override
  String get storeSaveAddressButton => 'Save address';

  @override
  String get storeAddressLabelField => 'Label (optional)';

  @override
  String get storeAddressLabelHint => 'E.g.: Home, Work';

  @override
  String get storeUseResidentialAddress => 'Use my home address';

  @override
  String get storeDeliveryAddressSummaryTitle => 'DELIVERY ADDRESS';

  @override
  String get storeChangeAddressButton => 'Change';

  @override
  String get storeChooseDeliveryAddressTitle => 'CHOOSE WHERE TO RECEIVE';

  @override
  String get storeNoDeliveryAddressTitle =>
      'You don\'t have a delivery address yet.';

  @override
  String get storeAddAnotherAddress => 'Add another address';

  @override
  String get storeValFullNameRequired => 'Enter your full name.';

  @override
  String get storeValFullNameIncomplete => 'Enter your first and last name.';

  @override
  String get storeValPhoneInvalid => 'Invalid phone number.';

  @override
  String get storeValCpfRequired => 'Enter your CPF.';

  @override
  String get storeValCpfInvalid => 'Invalid CPF.';

  @override
  String get storeValZipInvalid => 'Invalid ZIP code.';

  @override
  String get releaseGateTitle => 'Update required';

  @override
  String get releaseGateMessage =>
      'This version of the app is no longer supported. Update to continue.';

  @override
  String get releaseGateUpdateButton => 'Update now';

  @override
  String tacticalQ01(String club) {
    return 'The opposition presses your build-up and shuts down the short passes. What does your $club do?';
  }

  @override
  String get tacticalQ01A =>
      'Keep playing out short, drawing the press in until the free man appears.';

  @override
  String get tacticalQ01B =>
      'Try to play out short, but the moment the press bites, go for the space in behind.';

  @override
  String get tacticalQ01C =>
      'Go straight to the striker or the channel and set the team up to win the second ball.';

  @override
  String get tacticalQ01D =>
      'Find where their press is weakest and build out through there, short or long.';

  @override
  String get tacticalQ02 =>
      'Your side wins the ball in midfield with the opposition still out of shape. What is the first thought?';

  @override
  String get tacticalQ02A =>
      'Keep the ball, bring the team up and build the attack.';

  @override
  String get tacticalQ02B =>
      'Look for the forward pass if the advantage is on; if not, keep possession.';

  @override
  String get tacticalQ02C =>
      'Go at once and try to reach goal in a handful of passes.';

  @override
  String get tacticalQ02D =>
      'Decide by where their players are and who has the extra man in that moment.';

  @override
  String tacticalQ03(String club) {
    return '$club lead 1-0 away from home with 75 minutes gone.';
  }

  @override
  String get tacticalQ03A =>
      'Change nothing. If the plan built the lead, the plan stays.';

  @override
  String get tacticalQ03B =>
      'Take control with more of the ball and make them chase it.';

  @override
  String get tacticalQ03C =>
      'Close the spaces tighter and set up transitions to kill the game.';

  @override
  String get tacticalQ03D =>
      'Keep pressing for the second goal before they grow into it.';

  @override
  String get tacticalQ04 =>
      'They have parked two banks close to their own box. How do you break it down?';

  @override
  String get tacticalQ04A =>
      'Circulate patiently until the right gap opens up.';

  @override
  String get tacticalQ04B =>
      'Shift positions and create an overload between the lines or out wide.';

  @override
  String get tacticalQ04C =>
      'Raise the tempo — crosses, runs in behind and second balls.';

  @override
  String get tacticalQ04D =>
      'Put more bodies in the box and switch the route of the attack as they react.';

  @override
  String get tacticalQ05 =>
      'You are away to a side that is clearly better on the ball.';

  @override
  String get tacticalQ05A =>
      'Stick to control and playing out. That is how this team plays.';

  @override
  String get tacticalQ05B =>
      'Still try to have the ball, but adjust the press and the shape to them.';

  @override
  String get tacticalQ05C =>
      'Accept less possession, protect the spaces and live off the transition.';

  @override
  String get tacticalQ05D => 'Press high and go at them quickly, risk and all.';

  @override
  String get tacticalQ06 =>
      'Your best player wins matches but barely tracks back. What do you do?';

  @override
  String get tacticalQ06A =>
      'The model comes first. No defensive work, no place in the side.';

  @override
  String get tacticalQ06B =>
      'Change his role so the talent stays without unbalancing the team.';

  @override
  String get tacticalQ06C =>
      'Reorganise the others to cover for him and keep him high up the pitch.';

  @override
  String get tacticalQ06D =>
      'Give him licence. Special players are handled in a special way.';

  @override
  String tacticalQ07(String club) {
    return 'Half-time. $club are 1-0 down, but playing well and creating chances.';
  }

  @override
  String get tacticalQ07A =>
      'Leave it. The plan is working and the goal will come.';

  @override
  String get tacticalQ07B =>
      'Small positional tweaks, without giving up the original idea.';

  @override
  String get tacticalQ07C =>
      'Add depth or another forward and start getting there quicker.';

  @override
  String get tacticalQ07D =>
      'Move the ball faster and put more players between the lines.';

  @override
  String get tacticalQ08 =>
      'Your team loses the ball near the opposition box. What reaction do you want?';

  @override
  String get tacticalQ08A =>
      'Press instantly and win it back right there, whoever the opponent is.';

  @override
  String get tacticalQ08B =>
      'Press if there are enough bodies close by; otherwise drop and reset.';

  @override
  String get tacticalQ08C =>
      'Get the block back in shape first and shut the middle of the pitch.';

  @override
  String get tacticalQ08D =>
      'Break up the transition so they never get to run at you.';

  @override
  String tacticalQ09(String club) {
    return 'Ten minutes left and $club need a goal.';
  }

  @override
  String get tacticalQ09A => 'Keep building patiently. Chaos is not a plan.';

  @override
  String get tacticalQ09B =>
      'Bring on more attacking players, but keep the ball down and the shape intact.';

  @override
  String get tacticalQ09C =>
      'Camp in their half, go more direct and attack first and second balls.';

  @override
  String get tacticalQ09D =>
      'Change the shape and mix short and direct depending on what they give you.';

  @override
  String get tacticalQ10 =>
      'Which line best describes the way you think about football?';

  @override
  String get tacticalQ10A =>
      'Our way of playing comes first; the opponent comes after.';

  @override
  String get tacticalQ10B =>
      'The principles hold, but the shape and the plan can change.';

  @override
  String get tacticalQ10C =>
      'Reaching the goal quickly is worth more than having the ball for its own sake.';

  @override
  String get tacticalQ10D =>
      'The best football is the one that suits our players and hurts their weaknesses.';
}
