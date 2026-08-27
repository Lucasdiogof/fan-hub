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
  String get matchDetailsShort => 'MATCH DETAILS';

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
  String get debugMockMembershipTitle => 'Active member (mock)';

  @override
  String get debugMockMembershipDescription =>
      'Simulates an active Sócio Esmeralda member while there\'s no real integration with the program.';

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
  String get arenaHighlightsSectionTitle => 'Fan Highlights';

  @override
  String get arenaGamesSectionTitle => 'Arena Games';

  @override
  String get arenaGamesSectionSubtitle => 'Test your Goiás knowledge.';

  @override
  String get arenaNextMatchBadge => 'NEXT MATCH';

  @override
  String get arenaHighlightViewLineup => 'View lineup';

  @override
  String get arenaHighlightEscaleLineup => 'Line up now';

  @override
  String get arenaHighlightViewRanking => 'View ranking';

  @override
  String get arenaRankingHighlightDesc =>
      'See who\'s dominating the minigames.';

  @override
  String get arenaRankingPlayToRank => 'Play to enter the ranking';

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
  String get arenaSubtitleCareer => '30 players';

  @override
  String get arenaSubtitleGuessPlayer => 'Uncover the player from the clues';

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
  String get arenaRankingDetailFirstTry => 'First-try correct';

  @override
  String get arenaRankingDetailReview => 'Review correct answers';

  @override
  String get arenaRankingDetailAbandoned => 'Revealed/abandoned';

  @override
  String get arenaRankingDetailTotal => 'TOTAL';

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
    return '$score pts • $percent%';
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
  String get commonLinkOpenError => 'Couldn\'t open this link.';

  @override
  String get commonLoadError => 'Couldn\'t load the data';

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
  String get socialMediaSubtitle => 'Goiás Online';

  @override
  String get socialFeedLoadError => 'Couldn\'t load the feed';

  @override
  String get socialEmptyState => 'Follow Goiás on social media';

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
  String get newsTitle => 'NEWS';

  @override
  String get newsLoadError => 'Couldn\'t load the news';

  @override
  String get newsEmptyTitle => 'No news here yet';

  @override
  String get newsEmptyMessage =>
      'Check back later for the latest Goiás updates.';

  @override
  String get newsSourceLabel => 'SOURCE: GOIÁS ESPORTE CLUBE';

  @override
  String get newsOpenOriginal => 'Open original article';

  @override
  String get newsSeeMore => 'See more';

  @override
  String get commonNoConnection => 'No internet connection.';

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
  String get partnersTitle => 'Goiás Partners';

  @override
  String get partnersSubtitle => 'Brands that walk alongside Goiás.';

  @override
  String get partnersSectionTitle => 'GOIÁS PARTNERS';

  @override
  String get partnersSeeAll => 'See all';

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
  String get squadClubHistory => 'CLUB HISTORY';

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
  String get squadHistoryYears => 'Years';

  @override
  String get squadHistoryClubs => 'Clubs';

  @override
  String get squadHistoryMatches => 'Apps';

  @override
  String get squadHistoryGoals => 'Goals';

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
  String get checkEmailResent => 'Email resent. Check your inbox.';

  @override
  String get checkEmailTitle => 'Confirm your email';

  @override
  String get checkEmailSentTo => 'We sent a confirmation link to:';

  @override
  String get checkEmailInstruction =>
      'Open your inbox and confirm your email to activate the account.';

  @override
  String get checkEmailBackToLogin => 'Back to login';

  @override
  String get checkEmailResending => 'Resending...';

  @override
  String checkEmailResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get checkEmailResend => 'Resend email';

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
  String get forgotSentDescription => 'We sent a reset link to';

  @override
  String get forgotNotReceived => 'Didn\'t get it?';

  @override
  String get forgotResendSuccess => 'Email resent.';

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
  String get ticketsMyTicketsSubtitle => 'Tickets for Goiás matches';

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
  String get ticketsMyTicketsEmptyMessage =>
      'Your tickets for Goiás matches will show up here.';

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
  String get ticketsHasOwnTicketLabel =>
      'YOU ALREADY HAVE A TICKET FOR THIS MATCH';

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
  String get ticketsCheckinConfirmedLabel => 'CHECK-IN CONFIRMED';

  @override
  String get ticketsUndoCheckInButton => 'Undo check-in';

  @override
  String get ticketsConfirmPresenceTitle => 'CONFIRM ATTENDANCE';

  @override
  String get ticketsGoToMatchButton => 'I\'m going';

  @override
  String get ticketsNotThisTimeButton => 'Not this time';

  @override
  String get ticketsDeclineConfirmTitle => 'Are you sure you\'re not going?';

  @override
  String get ticketsDeclineConfirmMessage =>
      'Serrinha isn\'t the same without you. Goiás counts on the support of Nação Esmeraldina! 💚\n\nYou can still change your mind while check-in is open.';

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
  String get ticketsSectorPickerTitle =>
      'Where do you want to support the Verdão?';

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
  String get ticketsHomeCrowdLabel => 'GOIÁS SUPPORTERS';

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
  String get ticketsHolderDataTitle => 'TICKET HOLDER DETAILS';

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
  String get ticketPdfFooterNotice =>
      'This ticket is personal and non-transferable. Photo ID is required for entry. Only Goiás or Brazilian national team jerseys are allowed.';

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
  String get crowdMostVotedFormation => 'most voted formation';

  @override
  String get crowdNoVotes => 'No votes yet';

  @override
  String get crowdNoVotesMessage =>
      'Be the first to line up Goiás and help build the fans\' team.';

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
  String get crowdCardTitleVoted => 'Fans\' Lineup';

  @override
  String get crowdCardTitleNew => 'Build the fans\' lineup';

  @override
  String get crowdCardDescVoted =>
      'See how the fans are lining up Goiás for the next match.';

  @override
  String get crowdCardDescNew =>
      'Line up Goiás for the next match and see the fans\' most-picked team.';

  @override
  String get crowdCardCtaView => 'VIEW FANS\' LINEUP';

  @override
  String get crowdCardCtaEscale => 'LINE UP NOW';

  @override
  String get clubSectionHistory => 'History';

  @override
  String get clubSectionSquad => 'Squad';

  @override
  String get clubSectionTitles => 'Titles';

  @override
  String get clubSectionPartners => 'Partners';

  @override
  String get clubSectionTimeline => 'Timeline';

  @override
  String get clubSectionSongs => 'Anthem & Songs';

  @override
  String get clubHistorySubtitle => 'From 1943 to today.';

  @override
  String get clubSquadSubtitle => 'The players who wear the shirt.';

  @override
  String clubTitlesSubtitle(int count) {
    return '$count trophies throughout history.';
  }

  @override
  String get clubPartnersSubtitle => 'Who stands with Goiás.';

  @override
  String get clubSongsSubtitle => 'The anthem and songs that carry the fans.';

  @override
  String get clubAnthemSection => 'ANTHEM';

  @override
  String get clubSongsSection => 'ESMERALDINA SONGS';

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
  String get clubCampaignsSubtitle =>
      'Great Goiás runs that didn\'t end in a title.';

  @override
  String clubTimesChampion(int count) {
    return '$count× CHAMPION';
  }

  @override
  String get clubEntryTitle => 'THE CLUB';

  @override
  String get clubEntrySubtitle =>
      'History, titles, squad and identity of Goiás.';

  @override
  String get clubEntryCta => 'GET TO KNOW GOIÁS';

  @override
  String get clubHeaderTagline => 'THE BIGGEST IN THE CENTRAL-WEST';

  @override
  String get membershipLoadError => 'Couldn\'t load Sócio Esmeralda.';

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
  String get membershipStadiumAccess => 'Stadium access';

  @override
  String get membershipNoStadiumAccess => 'No stadium access';

  @override
  String get membershipViewPlan => 'VIEW PLAN';

  @override
  String get membershipCheckinUnavailable =>
      'Sócio Esmeralda check-in isn\'t available in the app yet.';

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
  String get membershipHeroTitle => 'Get even closer\nto Goiás.';

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
  String get membershipNewsletter =>
      'I want to receive news from the club and Sócio Esmeralda by email.';

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
  String get membershipAcceptRegulation =>
      'I have read and accept the Sócio Esmeralda Regulation';

  @override
  String get membershipReadFullRegulation => 'Read the full regulation →';

  @override
  String get membershipYourMembership => 'YOUR MEMBERSHIP';

  @override
  String get membershipYourBenefits => 'YOUR BENEFITS';

  @override
  String get membershipGoToMemberArea => 'GO TO MY MEMBER AREA';

  @override
  String get membershipBackToHome => 'Back to home';

  @override
  String get membershipWelcome => 'WELCOME TO\nSÓCIO ESMERALDA';

  @override
  String get membershipSuccessMessage =>
      'Your membership was completed successfully.\nNow you\'re even closer to Goiás.';

  @override
  String membershipAnnualPlan(String price) {
    return 'Annual plan • $price';
  }

  @override
  String get membershipHolder => 'Holder';

  @override
  String membershipCpfMasked(String cpf) {
    return 'CPF $cpf';
  }

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
  String get membershipRegulationName => 'Sócio Esmeralda Regulation';

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
  String get membershipProgramName => 'Sócio Esmeralda';

  @override
  String membershipRegulationEffectiveSince(String date) {
    return 'In effect since $date';
  }

  @override
  String get membershipRegulationTableOfContents => 'CONTENTS';

  @override
  String membershipCancelWhatsapp(String plan) {
    return 'Hi, I\'d like to cancel my Sócio Esmeralda membership ($plan).';
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
  String get membershipFaqNoResultsMessage =>
      'Try another term or contact Sócio Esmeralda support.';

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
  String get membershipFaqScopeNote =>
      'Questions about the club, youth academy, squad and other topics outside Sócio Esmeralda aren\'t answered through this channel.';

  @override
  String get membershipFaqAll => 'All';

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
  String arenaYouMarker(String name) {
    return '$name (you)';
  }

  @override
  String arenaYourPosition(int rank) {
    return '#$rank your position';
  }

  @override
  String lineupShareStats(int solved, int total, int attempts, String time) {
    return '$solved/$total found · $attempts attempts · $time';
  }

  @override
  String get crowdShareCrowd => 'Check out the fans\' lineup for Goiás! 💚';

  @override
  String get crowdShareMine => 'This is my lineup for Goiás! 💚';

  @override
  String get crowdSubmitted => 'Lineup submitted!';
}
