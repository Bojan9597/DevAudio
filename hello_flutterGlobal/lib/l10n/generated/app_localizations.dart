import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_sr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('sr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Echoes Of History'**
  String get appTitle;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @myBooks.
  ///
  /// In en, this message translates to:
  /// **'My Books'**
  String get myBooks;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @allBooks.
  ///
  /// In en, this message translates to:
  /// **'All Books'**
  String get allBooks;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @uploadAudioBook.
  ///
  /// In en, this message translates to:
  /// **'Upload Audio Book'**
  String get uploadAudioBook;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English (US)'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageSerbian.
  ///
  /// In en, this message translates to:
  /// **'Srpski'**
  String get languageSerbian;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @enteringOfflineMode.
  ///
  /// In en, this message translates to:
  /// **'Entering offline mode'**
  String get enteringOfflineMode;

  /// No description provided for @backOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get backOnline;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @googleLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Google Login Failed'**
  String get googleLoginFailed;

  /// No description provided for @searchForBooks.
  ///
  /// In en, this message translates to:
  /// **'Search for books...'**
  String get searchForBooks;

  /// No description provided for @searchByTitle.
  ///
  /// In en, this message translates to:
  /// **'Search by title...'**
  String get searchByTitle;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @noBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No books found.'**
  String get noBooksFound;

  /// No description provided for @noBooksFoundInCategory.
  ///
  /// In en, this message translates to:
  /// **'No books found in \"{categoryId}\"'**
  String noBooksFoundInCategory(String categoryId);

  /// No description provided for @booksInCategory.
  ///
  /// In en, this message translates to:
  /// **'Books in {categoryId}'**
  String booksInCategory(String categoryId);

  /// No description provided for @switchToList.
  ///
  /// In en, this message translates to:
  /// **'Switch to List'**
  String get switchToList;

  /// No description provided for @switchToGrid.
  ///
  /// In en, this message translates to:
  /// **'Switch to Grid'**
  String get switchToGrid;

  /// No description provided for @getYourImaginationGoing.
  ///
  /// In en, this message translates to:
  /// **'Get your imagination going'**
  String get getYourImaginationGoing;

  /// No description provided for @homeHeroDescription.
  ///
  /// In en, this message translates to:
  /// **'The best audiobooks and Originals. The most entertainment. The podcasts you want to hear.'**
  String get homeHeroDescription;

  /// No description provided for @continueToFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Continue to free trial'**
  String get continueToFreeTrial;

  /// No description provided for @autoRenewsInfo.
  ///
  /// In en, this message translates to:
  /// **'Auto-renews at \$14.95/month after 30 days. Cancel anytime.'**
  String get autoRenewsInfo;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @monthlySubscriptionInfo.
  ///
  /// In en, this message translates to:
  /// **'Monthly subscription from \$14.95/month. Cancel anytime.'**
  String get monthlySubscriptionInfo;

  /// No description provided for @subscriptionActivated.
  ///
  /// In en, this message translates to:
  /// **'Subscription activated!'**
  String get subscriptionActivated;

  /// No description provided for @unlimitedAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Access'**
  String get unlimitedAccess;

  /// No description provided for @unlimitedAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Stream our entire catalog of bestsellers and originals ad-free. No credits required.'**
  String get unlimitedAccessDescription;

  /// No description provided for @listenOffline.
  ///
  /// In en, this message translates to:
  /// **'Listen Offline'**
  String get listenOffline;

  /// No description provided for @listenOfflineDescription.
  ///
  /// In en, this message translates to:
  /// **'Download titles to your device and take your library with you wherever you go.'**
  String get listenOfflineDescription;

  /// No description provided for @interactiveQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Interactive Quizzes'**
  String get interactiveQuizzes;

  /// No description provided for @interactiveQuizzesDescription.
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge and reinforce what you\'ve learned with interactive quizzes.'**
  String get interactiveQuizzesDescription;

  /// No description provided for @findTheRightSpeed.
  ///
  /// In en, this message translates to:
  /// **'Find the right speed'**
  String get findTheRightSpeed;

  /// No description provided for @findTheRightSpeedDescription.
  ///
  /// In en, this message translates to:
  /// **'Slow down the narration or pick up the pace.'**
  String get findTheRightSpeedDescription;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// No description provided for @sleepTimerDescription.
  ///
  /// In en, this message translates to:
  /// **'Fall asleep without missing a beat.'**
  String get sleepTimerDescription;

  /// No description provided for @favoritesFeature.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesFeature;

  /// No description provided for @favoritesFeatureDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep your top picks handy.'**
  String get favoritesFeatureDescription;

  /// No description provided for @newReleases.
  ///
  /// In en, this message translates to:
  /// **'New Releases'**
  String get newReleases;

  /// No description provided for @topPicks.
  ///
  /// In en, this message translates to:
  /// **'Top Picks'**
  String get topPicks;

  /// No description provided for @continueListening.
  ///
  /// In en, this message translates to:
  /// **'Continue Listening'**
  String get continueListening;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get nowPlaying;

  /// No description provided for @returnToLessonMap.
  ///
  /// In en, this message translates to:
  /// **'Return to Lesson Map'**
  String get returnToLessonMap;

  /// No description provided for @notAvailableOffline.
  ///
  /// In en, this message translates to:
  /// **'Not available in offline mode'**
  String get notAvailableOffline;

  /// No description provided for @errorLoadingBooks.
  ///
  /// In en, this message translates to:
  /// **'Error loading books: {error}'**
  String errorLoadingBooks(String error);

  /// No description provided for @postedBy.
  ///
  /// In en, this message translates to:
  /// **'Posted by {name}'**
  String postedBy(String name);

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No Email'**
  String get noEmail;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @premiumUntil.
  ///
  /// In en, this message translates to:
  /// **'Premium until {date}'**
  String premiumUntil(String date);

  /// No description provided for @lifetimePremium.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Premium'**
  String get lifetimePremium;

  /// No description provided for @listenHistory.
  ///
  /// In en, this message translates to:
  /// **'Listen History'**
  String get listenHistory;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @noListeningHistory.
  ///
  /// In en, this message translates to:
  /// **'No listening history yet.'**
  String get noListeningHistory;

  /// No description provided for @listeningStats.
  ///
  /// In en, this message translates to:
  /// **'Listening Stats'**
  String get listeningStats;

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'Total Time: {time}'**
  String totalTime(String time);

  /// No description provided for @booksCompleted.
  ///
  /// In en, this message translates to:
  /// **'Books Completed: {count}'**
  String booksCompleted(int count);

  /// No description provided for @noBadgesYet.
  ///
  /// In en, this message translates to:
  /// **'No badges loaded yet'**
  String get noBadgesYet;

  /// No description provided for @subscriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Subscription Details'**
  String get subscriptionDetails;

  /// No description provided for @planType.
  ///
  /// In en, this message translates to:
  /// **'Plan Type'**
  String get planType;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get expiringSoon;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @autoRenew.
  ///
  /// In en, this message translates to:
  /// **'Auto-Renew'**
  String get autoRenew;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @cancelAutoRenewal.
  ///
  /// In en, this message translates to:
  /// **'Cancel Auto-Renewal'**
  String get cancelAutoRenewal;

  /// No description provided for @turnOffAutoRenewal.
  ///
  /// In en, this message translates to:
  /// **'Turn Off Auto-Renewal?'**
  String get turnOffAutoRenewal;

  /// No description provided for @subscriptionWillRemainActive.
  ///
  /// In en, this message translates to:
  /// **'Your subscription will remain active until the end of the current billing period.'**
  String get subscriptionWillRemainActive;

  /// No description provided for @keepOn.
  ///
  /// In en, this message translates to:
  /// **'Keep On'**
  String get keepOn;

  /// No description provided for @turnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn Off'**
  String get turnOff;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @lastListened.
  ///
  /// In en, this message translates to:
  /// **'Last listened: {date}'**
  String lastListened(String date);

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress: {current} / {total}'**
  String progress(String current, String total);

  /// No description provided for @earnedOn.
  ///
  /// In en, this message translates to:
  /// **'Earned on {date}'**
  String earnedOn(String date);

  /// No description provided for @unlockAllAudiobooks.
  ///
  /// In en, this message translates to:
  /// **'Unlock All Audiobooks'**
  String get unlockAllAudiobooks;

  /// No description provided for @subscribeToGetAccess.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to get unlimited access to our entire library'**
  String get subscribeToGetAccess;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @subscriptionActivatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Subscription activated! Enjoy unlimited access.'**
  String get subscriptionActivatedSuccess;

  /// No description provided for @subscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Subscription failed'**
  String get subscriptionFailed;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get bestValue;

  /// No description provided for @planTestMinuteTitle.
  ///
  /// In en, this message translates to:
  /// **'2 Minute Test'**
  String get planTestMinuteTitle;

  /// No description provided for @planTestMinuteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For testing - expires in 2 minutes'**
  String get planTestMinuteSubtitle;

  /// No description provided for @planMonthlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthlyTitle;

  /// No description provided for @planMonthlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Billed monthly, cancel anytime'**
  String get planMonthlySubtitle;

  /// No description provided for @planYearlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get planYearlyTitle;

  /// No description provided for @planYearlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save 33%'**
  String get planYearlySubtitle;

  /// No description provided for @planLifetimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get planLifetimeTitle;

  /// No description provided for @planLifetimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-time payment, forever access'**
  String get planLifetimeSubtitle;

  /// No description provided for @badgeEarned.
  ///
  /// In en, this message translates to:
  /// **'BADGE EARNED!'**
  String get badgeEarned;

  /// No description provided for @awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get awesome;

  /// No description provided for @noFavoriteBooks.
  ///
  /// In en, this message translates to:
  /// **'No favorite books yet'**
  String get noFavoriteBooks;

  /// No description provided for @noUploadedBooks.
  ///
  /// In en, this message translates to:
  /// **'No uploaded books'**
  String get noUploadedBooks;

  /// No description provided for @noDownloadedBooks.
  ///
  /// In en, this message translates to:
  /// **'No downloaded books'**
  String get noDownloadedBooks;

  /// No description provided for @booksDownloadedAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Books you download will appear here'**
  String get booksDownloadedAppearHere;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @pleaseLoginToUseFavorites.
  ///
  /// In en, this message translates to:
  /// **'Please login to use favorites'**
  String get pleaseLoginToUseFavorites;

  /// No description provided for @failedToUpdateFavorite.
  ///
  /// In en, this message translates to:
  /// **'Failed to update favorite'**
  String get failedToUpdateFavorite;

  /// No description provided for @quizResults.
  ///
  /// In en, this message translates to:
  /// **'Quiz Results'**
  String get quizResults;

  /// No description provided for @youScored.
  ///
  /// In en, this message translates to:
  /// **'You scored {score} out of {total}!'**
  String youScored(int score, int total);

  /// No description provided for @scorePercentage.
  ///
  /// In en, this message translates to:
  /// **'Score: {percentage}%'**
  String scorePercentage(String percentage);

  /// No description provided for @passed.
  ///
  /// In en, this message translates to:
  /// **'PASSED!'**
  String get passed;

  /// No description provided for @keepTrying.
  ///
  /// In en, this message translates to:
  /// **'Keep trying!'**
  String get keepTrying;

  /// No description provided for @returnToQuiz.
  ///
  /// In en, this message translates to:
  /// **'Return to Quiz'**
  String get returnToQuiz;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @nextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get nextQuestion;

  /// No description provided for @submitQuiz.
  ///
  /// In en, this message translates to:
  /// **'Submit Quiz'**
  String get submitQuiz;

  /// No description provided for @questionAdded.
  ///
  /// In en, this message translates to:
  /// **'Question added!'**
  String get questionAdded;

  /// No description provided for @addAtLeastOneQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add at least one question.'**
  String get addAtLeastOneQuestion;

  /// No description provided for @quizSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Quiz saved successfully!'**
  String get quizSavedSuccessfully;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @finishAndSave.
  ///
  /// In en, this message translates to:
  /// **'Finish & Save'**
  String get finishAndSave;

  /// No description provided for @purchaseSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Purchase Successful! Downloading playlist...'**
  String get purchaseSuccessful;

  /// No description provided for @noTracksFound.
  ///
  /// In en, this message translates to:
  /// **'No tracks found'**
  String get noTracksFound;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// No description provided for @uploadBook.
  ///
  /// In en, this message translates to:
  /// **'Upload Book'**
  String get uploadBook;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @catProgramming.
  ///
  /// In en, this message translates to:
  /// **'Programming'**
  String get catProgramming;

  /// No description provided for @catOperatingSystems.
  ///
  /// In en, this message translates to:
  /// **'Operating Systems'**
  String get catOperatingSystems;

  /// No description provided for @catLinux.
  ///
  /// In en, this message translates to:
  /// **'Linux'**
  String get catLinux;

  /// No description provided for @catNetworking.
  ///
  /// In en, this message translates to:
  /// **'Networking'**
  String get catNetworking;

  /// No description provided for @catFileSystems.
  ///
  /// In en, this message translates to:
  /// **'File Systems'**
  String get catFileSystems;

  /// No description provided for @catSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get catSecurity;

  /// No description provided for @catShellScripting.
  ///
  /// In en, this message translates to:
  /// **'Shell Scripting'**
  String get catShellScripting;

  /// No description provided for @catSystemAdministration.
  ///
  /// In en, this message translates to:
  /// **'System Administration'**
  String get catSystemAdministration;

  /// No description provided for @catWindows.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get catWindows;

  /// No description provided for @catInternals.
  ///
  /// In en, this message translates to:
  /// **'Internals'**
  String get catInternals;

  /// No description provided for @catPowerShell.
  ///
  /// In en, this message translates to:
  /// **'PowerShell'**
  String get catPowerShell;

  /// No description provided for @catMacOS.
  ///
  /// In en, this message translates to:
  /// **'macOS'**
  String get catMacOS;

  /// No description provided for @catShellAndScripting.
  ///
  /// In en, this message translates to:
  /// **'Shell & Scripting'**
  String get catShellAndScripting;

  /// No description provided for @catProgrammingLanguages.
  ///
  /// In en, this message translates to:
  /// **'Programming Languages'**
  String get catProgrammingLanguages;

  /// No description provided for @catPython.
  ///
  /// In en, this message translates to:
  /// **'Python'**
  String get catPython;

  /// No description provided for @catBasics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get catBasics;

  /// No description provided for @catAdvancedTopics.
  ///
  /// In en, this message translates to:
  /// **'Advanced Topics'**
  String get catAdvancedTopics;

  /// No description provided for @catWebDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Web Development'**
  String get catWebDevelopment;

  /// No description provided for @catDataScience.
  ///
  /// In en, this message translates to:
  /// **'Data Science'**
  String get catDataScience;

  /// No description provided for @catScriptingAndAutomation.
  ///
  /// In en, this message translates to:
  /// **'Scripting & Automation'**
  String get catScriptingAndAutomation;

  /// No description provided for @catCCpp.
  ///
  /// In en, this message translates to:
  /// **'C / C++'**
  String get catCCpp;

  /// No description provided for @catCBasics.
  ///
  /// In en, this message translates to:
  /// **'C Basics'**
  String get catCBasics;

  /// No description provided for @catCppBasics.
  ///
  /// In en, this message translates to:
  /// **'C++ Basics'**
  String get catCppBasics;

  /// No description provided for @catCppAdvanced.
  ///
  /// In en, this message translates to:
  /// **'C++ Advanced'**
  String get catCppAdvanced;

  /// No description provided for @catSTL.
  ///
  /// In en, this message translates to:
  /// **'STL'**
  String get catSTL;

  /// No description provided for @catSystemProgramming.
  ///
  /// In en, this message translates to:
  /// **'System Programming'**
  String get catSystemProgramming;

  /// No description provided for @catJava.
  ///
  /// In en, this message translates to:
  /// **'Java'**
  String get catJava;

  /// No description provided for @catOOP.
  ///
  /// In en, this message translates to:
  /// **'Object-Oriented Programming'**
  String get catOOP;

  /// No description provided for @catConcurrencyAndThreads.
  ///
  /// In en, this message translates to:
  /// **'Concurrency & Threads'**
  String get catConcurrencyAndThreads;

  /// No description provided for @catJavaScript.
  ///
  /// In en, this message translates to:
  /// **'JavaScript'**
  String get catJavaScript;

  /// No description provided for @catBrowserAndDOM.
  ///
  /// In en, this message translates to:
  /// **'Browser & DOM'**
  String get catBrowserAndDOM;

  /// No description provided for @catNodeJs.
  ///
  /// In en, this message translates to:
  /// **'Node.js'**
  String get catNodeJs;

  /// No description provided for @catFrameworks.
  ///
  /// In en, this message translates to:
  /// **'Frameworks (React, Vue, Angular)'**
  String get catFrameworks;

  /// No description provided for @browseByCategory.
  ///
  /// In en, this message translates to:
  /// **'Browse audiobooks by category'**
  String get browseByCategory;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get noCategoriesFound;

  /// No description provided for @rateThisBook.
  ///
  /// In en, this message translates to:
  /// **'Rate this book'**
  String get rateThisBook;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @pleaseLogInToRateBooks.
  ///
  /// In en, this message translates to:
  /// **'Please log in to rate books'**
  String get pleaseLogInToRateBooks;

  /// No description provided for @thanksForRating.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your {stars}-star rating!'**
  String thanksForRating(int stars);

  /// No description provided for @failedToSubmitRating.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit rating'**
  String get failedToSubmitRating;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @pleaseLogInToManageFavorites.
  ///
  /// In en, this message translates to:
  /// **'Please log in to manage favorites'**
  String get pleaseLogInToManageFavorites;

  /// No description provided for @downloadingForOffline.
  ///
  /// In en, this message translates to:
  /// **'Downloading for offline playback...'**
  String get downloadingForOffline;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete! Playing local file.'**
  String get downloadComplete;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @failedToLoadAudio.
  ///
  /// In en, this message translates to:
  /// **'Failed to load audio: {error}'**
  String failedToLoadAudio(String error);

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @sendUsAMessage.
  ///
  /// In en, this message translates to:
  /// **'Send us a message'**
  String get sendUsAMessage;

  /// No description provided for @messageSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Message sent successfully!'**
  String get messageSentSuccessfully;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @pleaseSelectAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one audio file'**
  String get pleaseSelectAudioFile;

  /// No description provided for @uploadSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Upload successful!'**
  String get uploadSuccessful;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// No description provided for @noQuizAvailable.
  ///
  /// In en, this message translates to:
  /// **'No quiz available for this item.'**
  String get noQuizAvailable;

  /// No description provided for @questionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question {current}/{total}'**
  String questionNumber(int current, int total);

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @planYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get planYearly;

  /// No description provided for @planLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get planLifetime;

  /// No description provided for @planTestMinute.
  ///
  /// In en, this message translates to:
  /// **'2 Minute Test'**
  String get planTestMinute;

  /// No description provided for @badgeReadBooks.
  ///
  /// In en, this message translates to:
  /// **'Read {count} books'**
  String badgeReadBooks(int count);

  /// No description provided for @badgeListenHours.
  ///
  /// In en, this message translates to:
  /// **'Listen for {count} hours'**
  String badgeListenHours(int count);

  /// No description provided for @badgeCompleteQuiz.
  ///
  /// In en, this message translates to:
  /// **'Complete a quiz'**
  String get badgeCompleteQuiz;

  /// No description provided for @badgeFirstBook.
  ///
  /// In en, this message translates to:
  /// **'Finish your first book'**
  String get badgeFirstBook;

  /// No description provided for @badgeStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String badgeStreak(int count);

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// No description provided for @supportMessageDescription.
  ///
  /// In en, this message translates to:
  /// **'Send a message to our support team. We\'ll get back to you as soon as possible.'**
  String get supportMessageDescription;

  /// No description provided for @yourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Message'**
  String get yourMessage;

  /// No description provided for @describeIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue or question...'**
  String get describeIssue;

  /// No description provided for @enterMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message'**
  String get enterMessage;

  /// No description provided for @messageTooShort.
  ///
  /// In en, this message translates to:
  /// **'Message must be at least 10 characters'**
  String get messageTooShort;

  /// No description provided for @accountInfoIncluded.
  ///
  /// In en, this message translates to:
  /// **'Your account information will be automatically included.'**
  String get accountInfoIncluded;

  /// No description provided for @searchInPdf.
  ///
  /// In en, this message translates to:
  /// **'Search in PDF...'**
  String get searchInPdf;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesFound;

  /// No description provided for @matchCount.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String matchCount(int current, int total);

  /// No description provided for @noListeningHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No listening history'**
  String get noListeningHistoryTitle;

  /// No description provided for @booksYouStartListeningAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Books you start listening to will appear here'**
  String get booksYouStartListeningAppearHere;

  /// No description provided for @playlistCompleted.
  ///
  /// In en, this message translates to:
  /// **'Playlist completed!'**
  String get playlistCompleted;

  /// No description provided for @downloadingFullPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Downloading full playlist...'**
  String get downloadingFullPlaylist;

  /// No description provided for @downloadingForOfflinePlayback.
  ///
  /// In en, this message translates to:
  /// **'Downloading for offline playback...'**
  String get downloadingForOfflinePlayback;

  /// No description provided for @downloadCompleteAvailableOffline.
  ///
  /// In en, this message translates to:
  /// **'Download Complete! Available offline.'**
  String get downloadCompleteAvailableOffline;

  /// No description provided for @bookInformation.
  ///
  /// In en, this message translates to:
  /// **'Book Information'**
  String get bookInformation;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price: \${price}'**
  String priceLabel(String price);

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String categoryLabel(String category);

  /// No description provided for @subscribeToListen.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to Listen'**
  String get subscribeToListen;

  /// No description provided for @getUnlimitedAccessToAllAudiobooks.
  ///
  /// In en, this message translates to:
  /// **'Get unlimited access to all audiobooks'**
  String get getUnlimitedAccessToAllAudiobooks;

  /// No description provided for @backgroundMusic.
  ///
  /// In en, this message translates to:
  /// **'Background Music'**
  String get backgroundMusic;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @subscribeToListenToReels.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to listen to Reels'**
  String get subscribeToListenToReels;

  /// No description provided for @noReelsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No reels available'**
  String get noReelsAvailable;

  /// No description provided for @audioUpload.
  ///
  /// In en, this message translates to:
  /// **'Audio Upload'**
  String get audioUpload;

  /// No description provided for @backgroundMusicUpload.
  ///
  /// In en, this message translates to:
  /// **'Background Music Upload'**
  String get backgroundMusicUpload;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleRequired;

  /// No description provided for @authorRequired.
  ///
  /// In en, this message translates to:
  /// **'Author *'**
  String get authorRequired;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Category *'**
  String get categoryRequired;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @defaultBackgroundMusicOptional.
  ///
  /// In en, this message translates to:
  /// **'Default Background Music (Optional)'**
  String get defaultBackgroundMusicOptional;

  /// No description provided for @premiumContent.
  ///
  /// In en, this message translates to:
  /// **'Premium Content'**
  String get premiumContent;

  /// No description provided for @onlySubscribersCanAccess.
  ///
  /// In en, this message translates to:
  /// **'Only subscribers can access this book'**
  String get onlySubscribersCanAccess;

  /// No description provided for @selectAudioFiles.
  ///
  /// In en, this message translates to:
  /// **'Select Audio File(s) *'**
  String get selectAudioFiles;

  /// No description provided for @audioSelected.
  ///
  /// In en, this message translates to:
  /// **'Audio Selected: ...{filename}'**
  String audioSelected(String filename);

  /// No description provided for @audioFilesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} Audio Files Selected'**
  String audioFilesSelected(int count);

  /// No description provided for @selectCoverImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Select Cover Image (Optional)'**
  String get selectCoverImageOptional;

  /// No description provided for @coverSelected.
  ///
  /// In en, this message translates to:
  /// **'Cover Selected: ...{filename}'**
  String coverSelected(String filename);

  /// No description provided for @selectPdfOptional.
  ///
  /// In en, this message translates to:
  /// **'Select PDF (Optional)'**
  String get selectPdfOptional;

  /// No description provided for @pdfSelected.
  ///
  /// In en, this message translates to:
  /// **'PDF Selected: ...{filename}'**
  String pdfSelected(String filename);

  /// No description provided for @musicTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Music Title *'**
  String get musicTitleRequired;

  /// No description provided for @selectBackgroundMusicFile.
  ///
  /// In en, this message translates to:
  /// **'Select Background Music File *'**
  String get selectBackgroundMusicFile;

  /// No description provided for @fileSelected.
  ///
  /// In en, this message translates to:
  /// **'File: ...{filename}'**
  String fileSelected(String filename);

  /// No description provided for @uploadBackgroundMusic.
  ///
  /// In en, this message translates to:
  /// **'Upload Background Music'**
  String get uploadBackgroundMusic;

  /// No description provided for @backgroundMusicUploaded.
  ///
  /// In en, this message translates to:
  /// **'Background music uploaded!'**
  String get backgroundMusicUploaded;

  /// No description provided for @pleaseSelectFileAndEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please select file and enter title'**
  String get pleaseSelectFileAndEnterTitle;

  /// No description provided for @createLessonQuiz.
  ///
  /// In en, this message translates to:
  /// **'Create Lesson Quiz'**
  String get createLessonQuiz;

  /// No description provided for @createBookQuiz.
  ///
  /// In en, this message translates to:
  /// **'Create Book Quiz'**
  String get createBookQuiz;

  /// No description provided for @addNewQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add New Question'**
  String get addNewQuestion;

  /// No description provided for @questionText.
  ///
  /// In en, this message translates to:
  /// **'Question Text'**
  String get questionText;

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer'**
  String get correctAnswer;

  /// No description provided for @optionLabel.
  ///
  /// In en, this message translates to:
  /// **'Option {letter}'**
  String optionLabel(String letter);

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @miniQuiz.
  ///
  /// In en, this message translates to:
  /// **'Mini Quiz'**
  String get miniQuiz;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get startQuiz;

  /// No description provided for @bookQuiz.
  ///
  /// In en, this message translates to:
  /// **'Book Quiz'**
  String get bookQuiz;

  /// No description provided for @errorSavingResult.
  ///
  /// In en, this message translates to:
  /// **'Error saving result: {error}'**
  String errorSavingResult(String error);

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session Expired'**
  String get sessionExpired;

  /// No description provided for @sessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get sessionExpiredMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @speedLabel.
  ///
  /// In en, this message translates to:
  /// **'{speed}x'**
  String speedLabel(String speed);

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @dailyMotivation.
  ///
  /// In en, this message translates to:
  /// **'Daily Motivation'**
  String get dailyMotivation;

  /// No description provided for @dailyMotivationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get an inspirational history quote daily'**
  String get dailyMotivationSubtitle;

  /// No description provided for @continueListeningNotification.
  ///
  /// In en, this message translates to:
  /// **'Continue Listening Reminders'**
  String get continueListeningNotification;

  /// No description provided for @continueListeningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get reminded to continue your audiobook'**
  String get continueListeningSubtitle;

  /// No description provided for @notificationTime.
  ///
  /// In en, this message translates to:
  /// **'Notification Time'**
  String get notificationTime;

  /// No description provided for @notificationTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When to start sending daily notifications'**
  String get notificationTimeSubtitle;

  /// No description provided for @notificationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required to send reminders'**
  String get notificationPermissionRequired;
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
      <String>['de', 'en', 'es', 'fr', 'sr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'sr':
      return AppLocalizationsSr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
