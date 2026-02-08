// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Echoes Of History';

  @override
  String get library => 'Library';

  @override
  String get profile => 'Profile';

  @override
  String get categories => 'Categories';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get logout => 'Logout';

  @override
  String get login => 'Login';

  @override
  String get myBooks => 'My Books';

  @override
  String get favorites => 'Favorites';

  @override
  String get allBooks => 'All Books';

  @override
  String get changePassword => 'Change Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get home => 'Home';

  @override
  String get discover => 'Discover';

  @override
  String get uploadAudioBook => 'Upload Audio Book';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageEnglish => 'English (US)';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSerbian => 'Srpski';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get enteringOfflineMode => 'Entering offline mode';

  @override
  String get backOnline => 'Back online';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get googleLoginFailed => 'Google Login Failed';

  @override
  String get searchForBooks => 'Search for books...';

  @override
  String get searchByTitle => 'Search by title...';

  @override
  String get searchResults => 'Search Results';

  @override
  String get noBooksFound => 'No books found.';

  @override
  String noBooksFoundInCategory(String categoryId) {
    return 'No books found in \"$categoryId\"';
  }

  @override
  String booksInCategory(String categoryId) {
    return 'Books in $categoryId';
  }

  @override
  String get switchToList => 'Switch to List';

  @override
  String get switchToGrid => 'Switch to Grid';

  @override
  String get getYourImaginationGoing => 'Get your imagination going';

  @override
  String get homeHeroDescription =>
      'The best audiobooks and Originals. The most entertainment. The podcasts you want to hear.';

  @override
  String get continueToFreeTrial => 'Continue to free trial';

  @override
  String get autoRenewsInfo =>
      'Auto-renews at \$14.95/month after 30 days. Cancel anytime.';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get monthlySubscriptionInfo =>
      'Monthly subscription from \$14.95/month. Cancel anytime.';

  @override
  String get subscriptionActivated => 'Subscription activated!';

  @override
  String get unlimitedAccess => 'Unlimited Access';

  @override
  String get unlimitedAccessDescription =>
      'Stream our entire catalog of bestsellers and originals ad-free. No credits required.';

  @override
  String get listenOffline => 'Listen Offline';

  @override
  String get listenOfflineDescription =>
      'Download titles to your device and take your library with you wherever you go.';

  @override
  String get interactiveQuizzes => 'Interactive Quizzes';

  @override
  String get interactiveQuizzesDescription =>
      'Test your knowledge and reinforce what you\'ve learned with interactive quizzes.';

  @override
  String get findTheRightSpeed => 'Find the right speed';

  @override
  String get findTheRightSpeedDescription =>
      'Slow down the narration or pick up the pace.';

  @override
  String get sleepTimer => 'Sleep Timer';

  @override
  String get sleepTimerDescription => 'Fall asleep without missing a beat.';

  @override
  String get favoritesFeature => 'Favorites';

  @override
  String get favoritesFeatureDescription => 'Keep your top picks handy.';

  @override
  String get newReleases => 'New Releases';

  @override
  String get topPicks => 'Top Picks';

  @override
  String get continueListening => 'Continue Listening';

  @override
  String get nowPlaying => 'NOW PLAYING';

  @override
  String get returnToLessonMap => 'Return to Lesson Map';

  @override
  String get notAvailableOffline => 'Not available in offline mode';

  @override
  String errorLoadingBooks(String error) {
    return 'Error loading books: $error';
  }

  @override
  String postedBy(String name) {
    return 'Posted by $name';
  }

  @override
  String get guestUser => 'Guest User';

  @override
  String get noEmail => 'No Email';

  @override
  String get admin => 'Admin';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String premiumUntil(String date) {
    return 'Premium until $date';
  }

  @override
  String get lifetimePremium => 'Lifetime Premium';

  @override
  String get listenHistory => 'Listen History';

  @override
  String get stats => 'Stats';

  @override
  String get badges => 'Badges';

  @override
  String get noListeningHistory => 'No listening history yet.';

  @override
  String get listeningStats => 'Listening Stats';

  @override
  String totalTime(String time) {
    return 'Total Time: $time';
  }

  @override
  String booksCompleted(int count) {
    return 'Books Completed: $count';
  }

  @override
  String get noBadgesYet => 'No badges loaded yet';

  @override
  String get subscriptionDetails => 'Subscription Details';

  @override
  String get planType => 'Plan Type';

  @override
  String get status => 'Status';

  @override
  String get active => 'Active';

  @override
  String get expiringSoon => 'Expiring Soon';

  @override
  String get expired => 'Expired';

  @override
  String get started => 'Started';

  @override
  String get expires => 'Expires';

  @override
  String get autoRenew => 'Auto-Renew';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get cancelAutoRenewal => 'Cancel Auto-Renewal';

  @override
  String get turnOffAutoRenewal => 'Turn Off Auto-Renewal?';

  @override
  String get subscriptionWillRemainActive =>
      'Your subscription will remain active until the end of the current billing period.';

  @override
  String get keepOn => 'Keep On';

  @override
  String get turnOff => 'Turn Off';

  @override
  String get close => 'Close';

  @override
  String lastListened(String date) {
    return 'Last listened: $date';
  }

  @override
  String progress(String current, String total) {
    return 'Progress: $current / $total';
  }

  @override
  String earnedOn(String date) {
    return 'Earned on $date';
  }

  @override
  String get unlockAllAudiobooks => 'Unlock All Audiobooks';

  @override
  String get subscribeToGetAccess =>
      'Subscribe to get unlimited access to our entire library';

  @override
  String get subscribeNow => 'Subscribe Now';

  @override
  String get maybeLater => 'Maybe Later';

  @override
  String get subscriptionActivatedSuccess =>
      'Subscription activated! Enjoy unlimited access.';

  @override
  String get subscriptionFailed => 'Subscription failed';

  @override
  String get bestValue => 'BEST VALUE';

  @override
  String get planTestMinuteTitle => '2 Minute Test';

  @override
  String get planTestMinuteSubtitle => 'For testing - expires in 2 minutes';

  @override
  String get planMonthlyTitle => 'Monthly';

  @override
  String get planMonthlySubtitle => 'Billed monthly, cancel anytime';

  @override
  String get planYearlyTitle => 'Yearly';

  @override
  String get planYearlySubtitle => 'Save 33%';

  @override
  String get planLifetimeTitle => 'Lifetime';

  @override
  String get planLifetimeSubtitle => 'One-time payment, forever access';

  @override
  String get badgeEarned => 'BADGE EARNED!';

  @override
  String get awesome => 'Awesome!';

  @override
  String get noFavoriteBooks => 'No favorite books yet';

  @override
  String get noUploadedBooks => 'No uploaded books';

  @override
  String get noDownloadedBooks => 'No downloaded books';

  @override
  String get booksDownloadedAppearHere => 'Books you download will appear here';

  @override
  String get uploaded => 'Uploaded';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get pleaseLoginToUseFavorites => 'Please login to use favorites';

  @override
  String get failedToUpdateFavorite => 'Failed to update favorite';

  @override
  String get quizResults => 'Quiz Results';

  @override
  String youScored(int score, int total) {
    return 'You scored $score out of $total!';
  }

  @override
  String scorePercentage(String percentage) {
    return 'Score: $percentage%';
  }

  @override
  String get passed => 'PASSED!';

  @override
  String get keepTrying => 'Keep trying!';

  @override
  String get returnToQuiz => 'Return to Quiz';

  @override
  String get finish => 'Finish';

  @override
  String get previous => 'Previous';

  @override
  String get nextQuestion => 'Next Question';

  @override
  String get submitQuiz => 'Submit Quiz';

  @override
  String get questionAdded => 'Question added!';

  @override
  String get addAtLeastOneQuestion => 'Add at least one question.';

  @override
  String get quizSavedSuccessfully => 'Quiz saved successfully!';

  @override
  String get saving => 'Saving...';

  @override
  String get finishAndSave => 'Finish & Save';

  @override
  String get purchaseSuccessful =>
      'Purchase Successful! Downloading playlist...';

  @override
  String get noTracksFound => 'No tracks found';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get uploadBook => 'Upload Book';

  @override
  String get free => 'FREE';

  @override
  String get catProgramming => 'Programming';

  @override
  String get catOperatingSystems => 'Operating Systems';

  @override
  String get catLinux => 'Linux';

  @override
  String get catNetworking => 'Networking';

  @override
  String get catFileSystems => 'File Systems';

  @override
  String get catSecurity => 'Security';

  @override
  String get catShellScripting => 'Shell Scripting';

  @override
  String get catSystemAdministration => 'System Administration';

  @override
  String get catWindows => 'Windows';

  @override
  String get catInternals => 'Internals';

  @override
  String get catPowerShell => 'PowerShell';

  @override
  String get catMacOS => 'macOS';

  @override
  String get catShellAndScripting => 'Shell & Scripting';

  @override
  String get catProgrammingLanguages => 'Programming Languages';

  @override
  String get catPython => 'Python';

  @override
  String get catBasics => 'Basics';

  @override
  String get catAdvancedTopics => 'Advanced Topics';

  @override
  String get catWebDevelopment => 'Web Development';

  @override
  String get catDataScience => 'Data Science';

  @override
  String get catScriptingAndAutomation => 'Scripting & Automation';

  @override
  String get catCCpp => 'C / C++';

  @override
  String get catCBasics => 'C Basics';

  @override
  String get catCppBasics => 'C++ Basics';

  @override
  String get catCppAdvanced => 'C++ Advanced';

  @override
  String get catSTL => 'STL';

  @override
  String get catSystemProgramming => 'System Programming';

  @override
  String get catJava => 'Java';

  @override
  String get catOOP => 'Object-Oriented Programming';

  @override
  String get catConcurrencyAndThreads => 'Concurrency & Threads';

  @override
  String get catJavaScript => 'JavaScript';

  @override
  String get catBrowserAndDOM => 'Browser & DOM';

  @override
  String get catNodeJs => 'Node.js';

  @override
  String get catFrameworks => 'Frameworks (React, Vue, Angular)';

  @override
  String get browseByCategory => 'Browse audiobooks by category';

  @override
  String get noCategoriesFound => 'No categories found';

  @override
  String get rateThisBook => 'Rate this book';

  @override
  String get submit => 'Submit';

  @override
  String get cancel => 'Cancel';

  @override
  String get pleaseLogInToRateBooks => 'Please log in to rate books';

  @override
  String thanksForRating(int stars) {
    return 'Thanks for your $stars-star rating!';
  }

  @override
  String get failedToSubmitRating => 'Failed to submit rating';

  @override
  String get rate => 'Rate';

  @override
  String get pleaseLogInToManageFavorites =>
      'Please log in to manage favorites';

  @override
  String get downloadingForOffline => 'Downloading for offline playback...';

  @override
  String get downloadComplete => 'Download complete! Playing local file.';

  @override
  String downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get details => 'Details';

  @override
  String failedToLoadAudio(String error) {
    return 'Failed to load audio: $error';
  }

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get sendUsAMessage => 'Send us a message';

  @override
  String get messageSentSuccessfully => 'Message sent successfully!';

  @override
  String get send => 'Send';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get pleaseSelectAudioFile => 'Please select at least one audio file';

  @override
  String get uploadSuccessful => 'Upload successful!';

  @override
  String uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get noQuizAvailable => 'No quiz available for this item.';

  @override
  String questionNumber(int current, int total) {
    return 'Question $current/$total';
  }

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planYearly => 'Yearly';

  @override
  String get planLifetime => 'Lifetime';

  @override
  String get planTestMinute => '2 Minute Test';

  @override
  String badgeReadBooks(int count) {
    return 'Read $count books';
  }

  @override
  String badgeListenHours(int count) {
    return 'Listen for $count hours';
  }

  @override
  String get badgeCompleteQuiz => 'Complete a quiz';

  @override
  String get badgeFirstBook => 'Finish your first book';

  @override
  String badgeStreak(int count) {
    return '$count day streak';
  }

  @override
  String get download => 'Download';

  @override
  String get downloading => 'Downloading...';

  @override
  String get supportMessageDescription =>
      'Send a message to our support team. We\'ll get back to you as soon as possible.';

  @override
  String get yourMessage => 'Your Message';

  @override
  String get describeIssue => 'Describe your issue or question...';

  @override
  String get enterMessage => 'Please enter a message';

  @override
  String get messageTooShort => 'Message must be at least 10 characters';

  @override
  String get accountInfoIncluded =>
      'Your account information will be automatically included.';

  @override
  String get searchInPdf => 'Search in PDF...';

  @override
  String get noMatchesFound => 'No matches found';

  @override
  String matchCount(int current, int total) {
    return '$current of $total';
  }

  @override
  String get noListeningHistoryTitle => 'No listening history';

  @override
  String get booksYouStartListeningAppearHere =>
      'Books you start listening to will appear here';

  @override
  String get playlistCompleted => 'Playlist completed!';

  @override
  String get downloadingFullPlaylist => 'Downloading full playlist...';

  @override
  String get downloadingForOfflinePlayback =>
      'Downloading for offline playback...';

  @override
  String get downloadCompleteAvailableOffline =>
      'Download Complete! Available offline.';

  @override
  String get bookInformation => 'Book Information';

  @override
  String get noDescriptionAvailable => 'No description available.';

  @override
  String priceLabel(String price) {
    return 'Price: \$$price';
  }

  @override
  String categoryLabel(String category) {
    return 'Category: $category';
  }

  @override
  String get subscribeToListen => 'Subscribe to Listen';

  @override
  String get getUnlimitedAccessToAllAudiobooks =>
      'Get unlimited access to all audiobooks';

  @override
  String get backgroundMusic => 'Background Music';

  @override
  String get none => 'None';

  @override
  String get subscribeToListenToReels => 'Subscribe to listen to Reels';

  @override
  String get noReelsAvailable => 'No reels available';

  @override
  String get audioUpload => 'Audio Upload';

  @override
  String get backgroundMusicUpload => 'Background Music Upload';

  @override
  String get titleRequired => 'Title *';

  @override
  String get authorRequired => 'Author *';

  @override
  String get categoryRequired => 'Category *';

  @override
  String get description => 'Description';

  @override
  String get price => 'Price';

  @override
  String get defaultBackgroundMusicOptional =>
      'Default Background Music (Optional)';

  @override
  String get premiumContent => 'Premium Content';

  @override
  String get onlySubscribersCanAccess =>
      'Only subscribers can access this book';

  @override
  String get selectAudioFiles => 'Select Audio File(s) *';

  @override
  String audioSelected(String filename) {
    return 'Audio Selected: ...$filename';
  }

  @override
  String audioFilesSelected(int count) {
    return '$count Audio Files Selected';
  }

  @override
  String get selectCoverImageOptional => 'Select Cover Image (Optional)';

  @override
  String coverSelected(String filename) {
    return 'Cover Selected: ...$filename';
  }

  @override
  String get selectPdfOptional => 'Select PDF (Optional)';

  @override
  String pdfSelected(String filename) {
    return 'PDF Selected: ...$filename';
  }

  @override
  String get musicTitleRequired => 'Music Title *';

  @override
  String get selectBackgroundMusicFile => 'Select Background Music File *';

  @override
  String fileSelected(String filename) {
    return 'File: ...$filename';
  }

  @override
  String get uploadBackgroundMusic => 'Upload Background Music';

  @override
  String get backgroundMusicUploaded => 'Background music uploaded!';

  @override
  String get pleaseSelectFileAndEnterTitle =>
      'Please select file and enter title';

  @override
  String get createLessonQuiz => 'Create Lesson Quiz';

  @override
  String get createBookQuiz => 'Create Book Quiz';

  @override
  String get addNewQuestion => 'Add New Question';

  @override
  String get questionText => 'Question Text';

  @override
  String get correctAnswer => 'Correct Answer';

  @override
  String optionLabel(String letter) {
    return 'Option $letter';
  }

  @override
  String get required => 'Required';

  @override
  String get miniQuiz => 'Mini Quiz';

  @override
  String get startQuiz => 'Start Quiz';

  @override
  String get bookQuiz => 'Book Quiz';

  @override
  String errorSavingResult(String error) {
    return 'Error saving result: $error';
  }

  @override
  String get sessionExpired => 'Session Expired';

  @override
  String get sessionExpiredMessage =>
      'Your session has expired. Please log in again.';

  @override
  String get ok => 'OK';

  @override
  String get unknown => 'Unknown';

  @override
  String speedLabel(String speed) {
    return '${speed}x';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get dailyMotivation => 'Daily Motivation';

  @override
  String get dailyMotivationSubtitle =>
      'Receive 5 inspiring history quotes daily';

  @override
  String get continueListeningNotification => 'Continue Listening Reminders';

  @override
  String get continueListeningSubtitle =>
      'Get reminded to continue your audiobook';

  @override
  String get notificationTime => 'Notification Time';

  @override
  String get notificationTimeSubtitle =>
      'When to start sending daily notifications';

  @override
  String get notificationPermissionRequired =>
      'Notification permission is required to send reminders';
}
