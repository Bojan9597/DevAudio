// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Echoes Of History';

  @override
  String get library => 'Bibliothek';

  @override
  String get profile => 'Profil';

  @override
  String get categories => 'Kategorien';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get theme => 'Thema';

  @override
  String get logout => 'Abmelden';

  @override
  String get login => 'Anmelden';

  @override
  String get myBooks => 'Meine Bücher';

  @override
  String get favorites => 'Favoriten';

  @override
  String get allBooks => 'Alle Bücher';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get confirmNewPassword => 'Neues Passwort bestätigen';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get home => 'Startseite';

  @override
  String get discover => 'Entdecken';

  @override
  String get uploadAudioBook => 'Hörbuch hochladen';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

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
  String get enteringOfflineMode => 'Offline-Modus wird aktiviert';

  @override
  String get backOnline => 'Wieder online';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get googleLoginFailed => 'Google-Anmeldung fehlgeschlagen';

  @override
  String get searchForBooks => 'Nach Büchern suchen...';

  @override
  String get searchByTitle => 'Nach Titel suchen...';

  @override
  String get searchResults => 'Suchergebnisse';

  @override
  String get noBooksFound => 'Keine Bücher gefunden.';

  @override
  String noBooksFoundInCategory(String categoryId) {
    return 'Keine Bücher in \"$categoryId\" gefunden';
  }

  @override
  String booksInCategory(String categoryId) {
    return 'Bücher in $categoryId';
  }

  @override
  String get switchToList => 'Zur Liste wechseln';

  @override
  String get switchToGrid => 'Zum Raster wechseln';

  @override
  String get getYourImaginationGoing => 'Lass deiner Fantasie freien Lauf';

  @override
  String get homeHeroDescription =>
      'Die besten Hörbücher und Originale. Die beste Unterhaltung. Die Podcasts, die du hören möchtest.';

  @override
  String get continueToFreeTrial => 'Zur kostenlosen Testversion';

  @override
  String get autoRenewsInfo =>
      'Automatische Verlängerung für 14,95\$/Monat nach 30 Tagen. Jederzeit kündbar.';

  @override
  String get subscribe => 'Abonnieren';

  @override
  String get monthlySubscriptionInfo =>
      'Monatliches Abo ab 14,95\$/Monat. Jederzeit kündbar.';

  @override
  String get subscriptionActivated => 'Abonnement aktiviert!';

  @override
  String get unlimitedAccess => 'Unbegrenzter Zugang';

  @override
  String get unlimitedAccessDescription =>
      'Streame unseren gesamten Katalog von Bestsellern und Originalen werbefrei. Keine Guthaben erforderlich.';

  @override
  String get listenOffline => 'Offline hören';

  @override
  String get listenOfflineDescription =>
      'Lade Titel auf dein Gerät herunter und nimm deine Bibliothek überall mit.';

  @override
  String get interactiveQuizzes => 'Interaktive Quiz';

  @override
  String get interactiveQuizzesDescription =>
      'Teste dein Wissen und festige das Gelernte mit interaktiven Quiz.';

  @override
  String get findTheRightSpeed => 'Finde die richtige Geschwindigkeit';

  @override
  String get findTheRightSpeedDescription =>
      'Verlangsame die Erzählung oder beschleunige das Tempo.';

  @override
  String get sleepTimer => 'Schlaf-Timer';

  @override
  String get sleepTimerDescription => 'Schlafe ein, ohne etwas zu verpassen.';

  @override
  String get favoritesFeature => 'Favoriten';

  @override
  String get favoritesFeatureDescription =>
      'Behalte deine Top-Auswahl griffbereit.';

  @override
  String get newReleases => 'Neuerscheinungen';

  @override
  String get topPicks => 'Top-Auswahl';

  @override
  String get continueListening => 'Weiterhören';

  @override
  String get nowPlaying => 'WIRD ABGESPIELT';

  @override
  String get returnToLessonMap => 'Zurück zur Lektionskarte';

  @override
  String get notAvailableOffline => 'Im Offline-Modus nicht verfügbar';

  @override
  String errorLoadingBooks(String error) {
    return 'Fehler beim Laden der Bücher: $error';
  }

  @override
  String postedBy(String name) {
    return 'Veröffentlicht von $name';
  }

  @override
  String get guestUser => 'Gastbenutzer';

  @override
  String get noEmail => 'Keine E-Mail';

  @override
  String get admin => 'Administrator';

  @override
  String get upgradeToPremium => 'Auf Premium upgraden';

  @override
  String premiumUntil(String date) {
    return 'Premium bis $date';
  }

  @override
  String get lifetimePremium => 'Lebenslanges Premium';

  @override
  String get listenHistory => 'Hörverlauf';

  @override
  String get stats => 'Statistiken';

  @override
  String get badges => 'Abzeichen';

  @override
  String get noListeningHistory => 'Noch kein Hörverlauf.';

  @override
  String get listeningStats => 'Hörstatistiken';

  @override
  String totalTime(String time) {
    return 'Gesamtzeit: $time';
  }

  @override
  String booksCompleted(int count) {
    return 'Abgeschlossene Bücher: $count';
  }

  @override
  String get noBadgesYet => 'Noch keine Abzeichen';

  @override
  String get subscriptionDetails => 'Abonnementdetails';

  @override
  String get planType => 'Plantyp';

  @override
  String get status => 'Status';

  @override
  String get active => 'Aktiv';

  @override
  String get expiringSoon => 'Läuft bald ab';

  @override
  String get expired => 'Abgelaufen';

  @override
  String get started => 'Gestartet';

  @override
  String get expires => 'Läuft ab';

  @override
  String get autoRenew => 'Auto-Verlängerung';

  @override
  String get on => 'An';

  @override
  String get off => 'Aus';

  @override
  String get cancelAutoRenewal => 'Auto-Verlängerung kündigen';

  @override
  String get turnOffAutoRenewal => 'Auto-Verlängerung deaktivieren?';

  @override
  String get subscriptionWillRemainActive =>
      'Dein Abonnement bleibt bis zum Ende des aktuellen Abrechnungszeitraums aktiv.';

  @override
  String get keepOn => 'Aktiviert lassen';

  @override
  String get turnOff => 'Deaktivieren';

  @override
  String get close => 'Schließen';

  @override
  String lastListened(String date) {
    return 'Zuletzt gehört: $date';
  }

  @override
  String progress(String current, String total) {
    return 'Fortschritt: $current / $total';
  }

  @override
  String earnedOn(String date) {
    return 'Erhalten am $date';
  }

  @override
  String get unlockAllAudiobooks => 'Alle Hörbücher freischalten';

  @override
  String get subscribeToGetAccess =>
      'Abonniere, um unbegrenzten Zugang zu unserer gesamten Bibliothek zu erhalten';

  @override
  String get subscribeNow => 'Jetzt abonnieren';

  @override
  String get maybeLater => 'Vielleicht später';

  @override
  String get subscriptionActivatedSuccess =>
      'Abonnement aktiviert! Genieße unbegrenzten Zugang.';

  @override
  String get subscriptionFailed => 'Abonnement fehlgeschlagen';

  @override
  String get bestValue => 'BESTES ANGEBOT';

  @override
  String get planTestMinuteTitle => '2-Minuten-Test';

  @override
  String get planTestMinuteSubtitle => 'Zum Testen - läuft nach 2 Minuten ab';

  @override
  String get planMonthlyTitle => 'Monatlich';

  @override
  String get planMonthlySubtitle => 'Monatliche Abrechnung, jederzeit kündbar';

  @override
  String get planYearlyTitle => 'Jährlich';

  @override
  String get planYearlySubtitle => '33% sparen - Bestes Angebot!';

  @override
  String get planLifetimeTitle => 'Lebenslang';

  @override
  String get planLifetimeSubtitle => 'Einmalzahlung, ewiger Zugang';

  @override
  String get badgeEarned => 'ABZEICHEN ERHALTEN!';

  @override
  String get awesome => 'Toll!';

  @override
  String get noFavoriteBooks => 'Noch keine Lieblingsbücher';

  @override
  String get noUploadedBooks => 'Keine hochgeladenen Bücher';

  @override
  String get noDownloadedBooks => 'Keine heruntergeladenen Bücher';

  @override
  String get booksDownloadedAppearHere =>
      'Heruntergeladene Bücher erscheinen hier';

  @override
  String get uploaded => 'Hochgeladen';

  @override
  String get removeFromFavorites => 'Von Favoriten entfernen';

  @override
  String get addToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get pleaseLoginToUseFavorites =>
      'Bitte anmelden, um Favoriten zu nutzen';

  @override
  String get failedToUpdateFavorite =>
      'Favorit konnte nicht aktualisiert werden';

  @override
  String get quizResults => 'Quiz-Ergebnisse';

  @override
  String youScored(int score, int total) {
    return 'Du hast $score von $total erreicht!';
  }

  @override
  String scorePercentage(String percentage) {
    return 'Punktzahl: $percentage%';
  }

  @override
  String get passed => 'BESTANDEN!';

  @override
  String get keepTrying => 'Weiter versuchen!';

  @override
  String get returnToQuiz => 'Zurück zum Quiz';

  @override
  String get finish => 'Beenden';

  @override
  String get previous => 'Zurück';

  @override
  String get nextQuestion => 'Nächste Frage';

  @override
  String get submitQuiz => 'Quiz abschicken';

  @override
  String get questionAdded => 'Frage hinzugefügt!';

  @override
  String get addAtLeastOneQuestion => 'Füge mindestens eine Frage hinzu.';

  @override
  String get quizSavedSuccessfully => 'Quiz erfolgreich gespeichert!';

  @override
  String get saving => 'Speichern...';

  @override
  String get finishAndSave => 'Beenden und speichern';

  @override
  String get purchaseSuccessful =>
      'Kauf erfolgreich! Playlist wird heruntergeladen...';

  @override
  String get noTracksFound => 'Keine Titel gefunden';

  @override
  String error(String message) {
    return 'Fehler: $message';
  }

  @override
  String get uploadBook => 'Buch hochladen';

  @override
  String get free => 'KOSTENLOS';

  @override
  String get catProgramming => 'Programmierung';

  @override
  String get catOperatingSystems => 'Betriebssysteme';

  @override
  String get catLinux => 'Linux';

  @override
  String get catNetworking => 'Netzwerke';

  @override
  String get catFileSystems => 'Dateisysteme';

  @override
  String get catSecurity => 'Sicherheit';

  @override
  String get catShellScripting => 'Shell-Skripting';

  @override
  String get catSystemAdministration => 'Systemverwaltung';

  @override
  String get catWindows => 'Windows';

  @override
  String get catInternals => 'Interna';

  @override
  String get catPowerShell => 'PowerShell';

  @override
  String get catMacOS => 'macOS';

  @override
  String get catShellAndScripting => 'Shell & Skripting';

  @override
  String get catProgrammingLanguages => 'Programmiersprachen';

  @override
  String get catPython => 'Python';

  @override
  String get catBasics => 'Grundlagen';

  @override
  String get catAdvancedTopics => 'Fortgeschrittene Themen';

  @override
  String get catWebDevelopment => 'Webentwicklung';

  @override
  String get catDataScience => 'Data Science';

  @override
  String get catScriptingAndAutomation => 'Skripting & Automatisierung';

  @override
  String get catCCpp => 'C / C++';

  @override
  String get catCBasics => 'C Grundlagen';

  @override
  String get catCppBasics => 'C++ Grundlagen';

  @override
  String get catCppAdvanced => 'C++ Fortgeschritten';

  @override
  String get catSTL => 'STL';

  @override
  String get catSystemProgramming => 'Systemprogrammierung';

  @override
  String get catJava => 'Java';

  @override
  String get catOOP => 'Objektorientierte Programmierung';

  @override
  String get catConcurrencyAndThreads => 'Nebenläufigkeit & Threads';

  @override
  String get catJavaScript => 'JavaScript';

  @override
  String get catBrowserAndDOM => 'Browser & DOM';

  @override
  String get catNodeJs => 'Node.js';

  @override
  String get catFrameworks => 'Frameworks (React, Vue, Angular)';

  @override
  String get browseByCategory => 'Hörbücher nach Kategorie durchsuchen';

  @override
  String get noCategoriesFound => 'Keine Kategorien gefunden';

  @override
  String get rateThisBook => 'Dieses Buch bewerten';

  @override
  String get submit => 'Absenden';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get pleaseLogInToRateBooks =>
      'Bitte melden Sie sich an, um Bücher zu bewerten';

  @override
  String thanksForRating(int stars) {
    return 'Danke für Ihre $stars-Sterne-Bewertung!';
  }

  @override
  String get failedToSubmitRating => 'Bewertung konnte nicht gesendet werden';

  @override
  String get rate => 'Bewerten';

  @override
  String get pleaseLogInToManageFavorites =>
      'Bitte melden Sie sich an, um Favoriten zu verwalten';

  @override
  String get downloadingForOffline =>
      'Wird für Offline-Wiedergabe heruntergeladen...';

  @override
  String get downloadComplete =>
      'Download abgeschlossen! Lokale Datei wird abgespielt.';

  @override
  String downloadFailed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get details => 'Details';

  @override
  String failedToLoadAudio(String error) {
    return 'Audio konnte nicht geladen werden: $error';
  }

  @override
  String get contactSupport => 'Support kontaktieren';

  @override
  String get sendUsAMessage => 'Senden Sie uns eine Nachricht';

  @override
  String get messageSentSuccessfully => 'Nachricht erfolgreich gesendet!';

  @override
  String get send => 'Senden';

  @override
  String get pleaseSelectCategory => 'Bitte wählen Sie eine Kategorie';

  @override
  String get pleaseSelectAudioFile =>
      'Bitte wählen Sie mindestens eine Audiodatei';

  @override
  String get uploadSuccessful => 'Upload erfolgreich!';

  @override
  String uploadFailed(String error) {
    return 'Upload fehlgeschlagen: $error';
  }

  @override
  String get noQuizAvailable => 'Kein Quiz für dieses Element verfügbar.';

  @override
  String questionNumber(int current, int total) {
    return 'Frage $current/$total';
  }

  @override
  String get planMonthly => 'Monatlich';

  @override
  String get planYearly => 'Jährlich';

  @override
  String get planLifetime => 'Lebenslang';

  @override
  String get planTestMinute => '2-Minuten-Test';

  @override
  String badgeReadBooks(int count) {
    return '$count Bücher lesen';
  }

  @override
  String badgeListenHours(int count) {
    return '$count Stunden hören';
  }

  @override
  String get badgeCompleteQuiz => 'Ein Quiz abschließen';

  @override
  String get badgeFirstBook => 'Dein erstes Buch beenden';

  @override
  String badgeStreak(int count) {
    return '$count Tage in Folge';
  }

  @override
  String get download => 'Herunterladen';

  @override
  String get downloading => 'Wird heruntergeladen...';

  @override
  String get supportMessageDescription =>
      'Senden Sie eine Nachricht an unser Support-Team. Wir melden uns so schnell wie möglich.';

  @override
  String get yourMessage => 'Ihre Nachricht';

  @override
  String get describeIssue => 'Beschreiben Sie Ihr Problem oder Ihre Frage...';

  @override
  String get enterMessage => 'Bitte geben Sie eine Nachricht ein';

  @override
  String get messageTooShort =>
      'Die Nachricht muss mindestens 10 Zeichen lang sein';

  @override
  String get accountInfoIncluded =>
      'Ihre Kontoinformationen werden automatisch beigefügt.';

  @override
  String get searchInPdf => 'Im PDF suchen...';

  @override
  String get noMatchesFound => 'Keine Treffer gefunden';

  @override
  String matchCount(int current, int total) {
    return '$current von $total';
  }

  @override
  String get noListeningHistoryTitle => 'Kein Hörverlauf';

  @override
  String get booksYouStartListeningAppearHere =>
      'Bücher, die du anfängst zu hören, erscheinen hier';

  @override
  String get playlistCompleted => 'Playlist abgeschlossen!';

  @override
  String get downloadingFullPlaylist =>
      'Gesamte Playlist wird heruntergeladen...';

  @override
  String get downloadingForOfflinePlayback =>
      'Wird für Offline-Wiedergabe heruntergeladen...';

  @override
  String get downloadCompleteAvailableOffline =>
      'Download abgeschlossen! Offline verfügbar.';

  @override
  String get bookInformation => 'Buchinformationen';

  @override
  String get noDescriptionAvailable => 'Keine Beschreibung verfügbar.';

  @override
  String priceLabel(String price) {
    return 'Preis: \$$price';
  }

  @override
  String categoryLabel(String category) {
    return 'Kategorie: $category';
  }

  @override
  String get subscribeToListen => 'Abonnieren zum Hören';

  @override
  String get getUnlimitedAccessToAllAudiobooks =>
      'Erhalte unbegrenzten Zugang zu allen Hörbüchern';

  @override
  String get backgroundMusic => 'Hintergrundmusik';

  @override
  String get none => 'Keine';

  @override
  String get subscribeToListenToReels => 'Abonniere, um Reels zu hören';

  @override
  String get noReelsAvailable => 'Keine Reels verfügbar';

  @override
  String get audioUpload => 'Audio hochladen';

  @override
  String get backgroundMusicUpload => 'Hintergrundmusik hochladen';

  @override
  String get titleRequired => 'Titel *';

  @override
  String get authorRequired => 'Autor *';

  @override
  String get categoryRequired => 'Kategorie *';

  @override
  String get description => 'Beschreibung';

  @override
  String get price => 'Preis';

  @override
  String get defaultBackgroundMusicOptional =>
      'Standard-Hintergrundmusik (optional)';

  @override
  String get premiumContent => 'Premium-Inhalt';

  @override
  String get onlySubscribersCanAccess =>
      'Nur Abonnenten können auf dieses Buch zugreifen';

  @override
  String get selectAudioFiles => 'Audiodatei(en) auswählen *';

  @override
  String audioSelected(String filename) {
    return 'Audio ausgewählt: ...$filename';
  }

  @override
  String audioFilesSelected(int count) {
    return '$count Audiodateien ausgewählt';
  }

  @override
  String get selectCoverImageOptional => 'Coverbild auswählen (optional)';

  @override
  String coverSelected(String filename) {
    return 'Cover ausgewählt: ...$filename';
  }

  @override
  String get selectPdfOptional => 'PDF auswählen (optional)';

  @override
  String pdfSelected(String filename) {
    return 'PDF ausgewählt: ...$filename';
  }

  @override
  String get musicTitleRequired => 'Musiktitel *';

  @override
  String get selectBackgroundMusicFile => 'Hintergrundmusik-Datei auswählen *';

  @override
  String fileSelected(String filename) {
    return 'Datei: ...$filename';
  }

  @override
  String get uploadBackgroundMusic => 'Hintergrundmusik hochladen';

  @override
  String get backgroundMusicUploaded => 'Hintergrundmusik hochgeladen!';

  @override
  String get pleaseSelectFileAndEnterTitle =>
      'Bitte Datei auswählen und Titel eingeben';

  @override
  String get createLessonQuiz => 'Lektionsquiz erstellen';

  @override
  String get createBookQuiz => 'Buchquiz erstellen';

  @override
  String get addNewQuestion => 'Neue Frage hinzufügen';

  @override
  String get questionText => 'Fragetext';

  @override
  String get correctAnswer => 'Richtige Antwort';

  @override
  String optionLabel(String letter) {
    return 'Option $letter';
  }

  @override
  String get required => 'Erforderlich';

  @override
  String get miniQuiz => 'Mini-Quiz';

  @override
  String get startQuiz => 'Quiz starten';

  @override
  String get bookQuiz => 'Buchquiz';

  @override
  String errorSavingResult(String error) {
    return 'Fehler beim Speichern des Ergebnisses: $error';
  }

  @override
  String get sessionExpired => 'Sitzung abgelaufen';

  @override
  String get sessionExpiredMessage =>
      'Ihre Sitzung ist abgelaufen. Bitte melden Sie sich erneut an.';

  @override
  String get ok => 'OK';

  @override
  String get unknown => 'Unbekannt';

  @override
  String speedLabel(String speed) {
    return '${speed}x';
  }

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notificationSettings => 'Benachrichtigungseinstellungen';

  @override
  String get enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get dailyMotivation => 'Tagliche Motivation';

  @override
  String get dailyMotivationSubtitle =>
      'Erhalten Sie taglich 5 inspirierende historische Zitate';

  @override
  String get continueListeningNotification => 'Erinnerungen zum Weiterhoren';

  @override
  String get continueListeningSubtitle =>
      'Erhalten Sie eine Erinnerung, Ihr Horbuch fortzusetzen';

  @override
  String get notificationTime => 'Benachrichtigungszeit';

  @override
  String get notificationTimeSubtitle =>
      'Wann die taglichen Benachrichtigungen gesendet werden sollen';

  @override
  String get notificationPermissionRequired =>
      'Benachrichtigungsberechtigung ist erforderlich, um Erinnerungen zu senden';
}
