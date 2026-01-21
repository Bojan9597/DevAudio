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
  /// **'AudioBooks'**
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
  /// **'Save 33% - Best value!'**
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
