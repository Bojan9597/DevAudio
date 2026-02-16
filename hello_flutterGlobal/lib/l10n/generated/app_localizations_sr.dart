// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get appTitle => 'Echoes Of History';

  @override
  String get library => 'Biblioteka';

  @override
  String get profile => 'Profil';

  @override
  String get categories => 'Kategorije';

  @override
  String get settings => 'Podešavanja';

  @override
  String get language => 'Jezik';

  @override
  String get theme => 'Tema';

  @override
  String get logout => 'Odjavi se';

  @override
  String get login => 'Prijavi se';

  @override
  String get myBooks => 'Moje Knjige';

  @override
  String get favorites => 'Omiljeno';

  @override
  String get allBooks => 'Sve Knjige';

  @override
  String get changePassword => 'Promeni Lozinku';

  @override
  String get confirmNewPassword => 'Potvrdi Novu Lozinku';

  @override
  String get currentPassword => 'Trenutna Lozinka';

  @override
  String get newPassword => 'Nova Lozinka';

  @override
  String get home => 'Početna';

  @override
  String get discover => 'Otkrij';

  @override
  String get uploadAudioBook => 'Otpremi audio knjigu';

  @override
  String get themeSystem => 'Sistemska';

  @override
  String get themeLight => 'Svetla';

  @override
  String get themeDark => 'Tamna';

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
  String get enteringOfflineMode => 'Ulazak u režim van mreže';

  @override
  String get backOnline => 'Ponovo na mreži';

  @override
  String get signInWithGoogle => 'Prijavi se sa Google-om';

  @override
  String get googleLoginFailed => 'Google prijava nije uspela';

  @override
  String get searchForBooks => 'Pretraži knjige...';

  @override
  String get searchByTitle => 'Pretraži po naslovu...';

  @override
  String get searchResults => 'Rezultati pretrage';

  @override
  String get noBooksFound => 'Nema pronađenih knjiga.';

  @override
  String noBooksFoundInCategory(String categoryId) {
    return 'Nema knjiga u \"$categoryId\"';
  }

  @override
  String booksInCategory(String categoryId) {
    return 'Knjige u $categoryId';
  }

  @override
  String get switchToList => 'Prebaci na listu';

  @override
  String get switchToGrid => 'Prebaci na mrežu';

  @override
  String get getYourImaginationGoing => 'Pustite mašti na volju';

  @override
  String get homeHeroDescription =>
      'Najbolje audio knjige i originali. Najbolja zabava. Podkasti koje želite da čujete.';

  @override
  String get continueToFreeTrial => 'Nastavi na besplatni probni period';

  @override
  String get autoRenewsInfo =>
      'Automatski se obnavlja po ceni od \$14.95/mesečno nakon 30 dana. Otkažite bilo kada.';

  @override
  String get subscribe => 'Pretplati se';

  @override
  String get monthlySubscriptionInfo =>
      'Mesečna pretplata od \$14.95/mesečno. Otkažite bilo kada.';

  @override
  String get subscriptionActivated => 'Pretplata aktivirana!';

  @override
  String get unlimitedAccess => 'Neograničen pristup';

  @override
  String get unlimitedAccessDescription =>
      'Strimujte ceo naš katalog bestselera i originala bez reklama. Bez potrebe za kreditima.';

  @override
  String get listenOffline => 'Slušajte van mreže';

  @override
  String get listenOfflineDescription =>
      'Preuzmite naslove na vaš uređaj i nosite biblioteku sa sobom gde god idete.';

  @override
  String get interactiveQuizzes => 'Interaktivni kvizovi';

  @override
  String get interactiveQuizzesDescription =>
      'Testirajte svoje znanje i učvrstite naučeno interaktivnim kvizovima.';

  @override
  String get findTheRightSpeed => 'Pronađite pravu brzinu';

  @override
  String get findTheRightSpeedDescription =>
      'Usporite naraciju ili ubrzajte tempo.';

  @override
  String get sleepTimer => 'Tajmer za spavanje';

  @override
  String get sleepTimerDescription => 'Zaspite bez propuštanja.';

  @override
  String get favoritesFeature => 'Omiljeno';

  @override
  String get favoritesFeatureDescription =>
      'Držite svoje najbolje izbore pri ruci.';

  @override
  String get newReleases => 'Nova izdanja';

  @override
  String get topPicks => 'Najbolji izbori';

  @override
  String get continueListening => 'Nastavi';

  @override
  String get nowPlaying => 'SADA SE PUŠTA';

  @override
  String get returnToLessonMap => 'Povratak na mapu lekcija';

  @override
  String get notAvailableOffline => 'Nije dostupno van mreže';

  @override
  String errorLoadingBooks(String error) {
    return 'Greška pri učitavanju knjiga: $error';
  }

  @override
  String postedBy(String name) {
    return 'Objavio $name';
  }

  @override
  String get guestUser => 'Gost korisnik';

  @override
  String get noEmail => 'Nema emaila';

  @override
  String get admin => 'Administrator';

  @override
  String get upgradeToPremium => 'Nadogradi na Premium';

  @override
  String premiumUntil(String date) {
    return 'Premium do $date';
  }

  @override
  String get lifetimePremium => 'Doživotni Premium';

  @override
  String get listenHistory => 'Istorija slušanja';

  @override
  String get stats => 'Statistike';

  @override
  String get badges => 'Značke';

  @override
  String get noListeningHistory => 'Još nema istorije slušanja.';

  @override
  String get listeningStats => 'Statistike slušanja';

  @override
  String totalTime(String time) {
    return 'Ukupno vreme: $time';
  }

  @override
  String booksCompleted(int count) {
    return 'Završene knjige: $count';
  }

  @override
  String get noBadgesYet => 'Još nema značaka';

  @override
  String get subscriptionDetails => 'Detalji pretplate';

  @override
  String get planType => 'Tip plana';

  @override
  String get status => 'Status';

  @override
  String get active => 'Aktivna';

  @override
  String get expiringSoon => 'Uskoro ističe';

  @override
  String get expired => 'Istekla';

  @override
  String get started => 'Počela';

  @override
  String get expires => 'Ističe';

  @override
  String get autoRenew => 'Auto obnova';

  @override
  String get on => 'Uključeno';

  @override
  String get off => 'Isključeno';

  @override
  String get cancelAutoRenewal => 'Otkaži auto obnovu';

  @override
  String get turnOffAutoRenewal => 'Isključiti auto obnovu?';

  @override
  String get subscriptionWillRemainActive =>
      'Vaša pretplata će ostati aktivna do kraja trenutnog perioda naplate.';

  @override
  String get keepOn => 'Zadrži uključeno';

  @override
  String get turnOff => 'Isključi';

  @override
  String get close => 'Zatvori';

  @override
  String lastListened(String date) {
    return 'Poslednje slušano: $date';
  }

  @override
  String progress(String current, String total) {
    return 'Napredak: $current / $total';
  }

  @override
  String earnedOn(String date) {
    return 'Osvojeno $date';
  }

  @override
  String get unlockAllAudiobooks => 'Otključajte sve audio knjige';

  @override
  String get subscribeToGetAccess =>
      'Pretplatite se za neograničen pristup celoj biblioteci';

  @override
  String get subscribeNow => 'Pretplati se sada';

  @override
  String get maybeLater => 'Možda kasnije';

  @override
  String get subscriptionActivatedSuccess =>
      'Pretplata aktivirana! Uživajte u neograničenom pristupu.';

  @override
  String get subscriptionFailed => 'Pretplata nije uspela';

  @override
  String get bestValue => 'NAJBOLJA VREDNOST';

  @override
  String get planTestMinuteTitle => 'Test od 2 minuta';

  @override
  String get planTestMinuteSubtitle => 'Za testiranje - ističe za 2 minuta';

  @override
  String get planMonthlyTitle => 'Mesečno';

  @override
  String get planMonthlySubtitle => 'Mesečna naplata, otkažite bilo kada';

  @override
  String get planYearlyTitle => 'Godišnje';

  @override
  String get planYearlySubtitle => 'Uštedite 33%';

  @override
  String get planLifetimeTitle => 'Doživotno';

  @override
  String get planLifetimeSubtitle => 'Jednokratno plaćanje, zauvek pristup';

  @override
  String get badgeEarned => 'ZNAČKA OSVOJENA!';

  @override
  String get awesome => 'Odlično!';

  @override
  String get noFavoriteBooks => 'Još nema omiljenih knjiga';

  @override
  String get noUploadedBooks => 'Nema otpremljenih knjiga';

  @override
  String get noDownloadedBooks => 'Nema preuzetih knjiga';

  @override
  String get booksDownloadedAppearHere =>
      'Knjige koje preuzmete će se pojaviti ovde';

  @override
  String get uploaded => 'Otpremljeno';

  @override
  String get removeFromFavorites => 'Ukloni iz omiljenih';

  @override
  String get addToFavorites => 'Dodaj u omiljeno';

  @override
  String get pleaseLoginToUseFavorites =>
      'Prijavite se da biste koristili omiljeno';

  @override
  String get failedToUpdateFavorite => 'Neuspešno ažuriranje omiljenog';

  @override
  String get quizResults => 'Rezultati kviza';

  @override
  String youScored(int score, int total) {
    return 'Postigli ste $score od $total!';
  }

  @override
  String scorePercentage(String percentage) {
    return 'Rezultat: $percentage%';
  }

  @override
  String get passed => 'POLOŽENO!';

  @override
  String get keepTrying => 'Nastavite da pokušavate!';

  @override
  String get returnToQuiz => 'Vrati se na kviz';

  @override
  String get finish => 'Završi';

  @override
  String get previous => 'Prethodno';

  @override
  String get nextQuestion => 'Sledeće pitanje';

  @override
  String get submitQuiz => 'Pošalji kviz';

  @override
  String get questionAdded => 'Pitanje dodato!';

  @override
  String get addAtLeastOneQuestion => 'Dodajte bar jedno pitanje.';

  @override
  String get quizSavedSuccessfully => 'Kviz uspešno sačuvan!';

  @override
  String get saving => 'Čuvanje...';

  @override
  String get finishAndSave => 'Završi i sačuvaj';

  @override
  String get purchaseSuccessful => 'Kupovina uspešna! Preuzimanje plejliste...';

  @override
  String get noTracksFound => 'Nema pronađenih pesama';

  @override
  String error(String message) {
    return 'Greška: $message';
  }

  @override
  String get uploadBook => 'Otpremi knjigu';

  @override
  String get free => 'BESPLATNO';

  @override
  String get catProgramming => 'Programiranje';

  @override
  String get catOperatingSystems => 'Operativni sistemi';

  @override
  String get catLinux => 'Linux';

  @override
  String get catNetworking => 'Umrežavanje';

  @override
  String get catFileSystems => 'Sistemi fajlova';

  @override
  String get catSecurity => 'Sigurnost';

  @override
  String get catShellScripting => 'Shell skriptovanje';

  @override
  String get catSystemAdministration => 'Sistemska administracija';

  @override
  String get catWindows => 'Windows';

  @override
  String get catInternals => 'Interni sistemi';

  @override
  String get catPowerShell => 'PowerShell';

  @override
  String get catMacOS => 'macOS';

  @override
  String get catShellAndScripting => 'Shell i skriptovanje';

  @override
  String get catProgrammingLanguages => 'Programski jezici';

  @override
  String get catPython => 'Python';

  @override
  String get catBasics => 'Osnove';

  @override
  String get catAdvancedTopics => 'Napredne teme';

  @override
  String get catWebDevelopment => 'Web razvoj';

  @override
  String get catDataScience => 'Nauka o podacima';

  @override
  String get catScriptingAndAutomation => 'Skriptovanje i automatizacija';

  @override
  String get catCCpp => 'C / C++';

  @override
  String get catCBasics => 'C osnove';

  @override
  String get catCppBasics => 'C++ osnove';

  @override
  String get catCppAdvanced => 'C++ napredni';

  @override
  String get catSTL => 'STL';

  @override
  String get catSystemProgramming => 'Sistemsko programiranje';

  @override
  String get catJava => 'Java';

  @override
  String get catOOP => 'Objektno-orijentisano programiranje';

  @override
  String get catConcurrencyAndThreads => 'Konkurentnost i niti';

  @override
  String get catJavaScript => 'JavaScript';

  @override
  String get catBrowserAndDOM => 'Pretraživač i DOM';

  @override
  String get catNodeJs => 'Node.js';

  @override
  String get catFrameworks => 'Radni okviri (React, Vue, Angular)';

  @override
  String get browseByCategory => 'Pretražite audio knjige po kategoriji';

  @override
  String get noCategoriesFound => 'Nema pronađenih kategorija';

  @override
  String get rateThisBook => 'Oceni ovu knjigu';

  @override
  String get submit => 'Pošalji';

  @override
  String get cancel => 'Otkaži';

  @override
  String get pleaseLogInToRateBooks => 'Prijavite se da biste ocenili knjige';

  @override
  String thanksForRating(int stars) {
    return 'Hvala na oceni od $stars zvezdica!';
  }

  @override
  String get failedToSubmitRating => 'Neuspešno slanje ocene';

  @override
  String get rate => 'Oceni';

  @override
  String get pleaseLogInToManageFavorites =>
      'Prijavite se da biste upravljali omiljenim';

  @override
  String get downloadingForOffline => 'Preuzimanje za offline reprodukciju...';

  @override
  String get downloadComplete =>
      'Preuzimanje završeno! Reprodukujem lokalni fajl.';

  @override
  String downloadFailed(String error) {
    return 'Preuzimanje neuspešno: $error';
  }

  @override
  String get details => 'Detalji';

  @override
  String failedToLoadAudio(String error) {
    return 'Neuspešno učitavanje zvuka: $error';
  }

  @override
  String get contactSupport => 'Kontaktirajte podršku';

  @override
  String get sendUsAMessage => 'Pošaljite nam poruku';

  @override
  String get messageSentSuccessfully => 'Poruka uspešno poslata!';

  @override
  String get send => 'Pošalji';

  @override
  String get pleaseSelectCategory => 'Molimo izaberite kategoriju';

  @override
  String get pleaseSelectAudioFile =>
      'Molimo izaberite bar jednu audio datoteku';

  @override
  String get uploadSuccessful => 'Otpremanje uspešno!';

  @override
  String uploadFailed(String error) {
    return 'Otpremanje neuspešno: $error';
  }

  @override
  String get noQuizAvailable => 'Nema dostupnog kviza za ovu stavku.';

  @override
  String questionNumber(int current, int total) {
    return 'Pitanje $current/$total';
  }

  @override
  String get planMonthly => 'Mesečna';

  @override
  String get planYearly => 'Godišnja';

  @override
  String get planLifetime => 'Doživotna';

  @override
  String get planTestMinute => '2-minutni test';

  @override
  String badgeReadBooks(int count) {
    return 'Pročitaj $count knjiga';
  }

  @override
  String badgeListenHours(int count) {
    return 'Slušaj $count sati';
  }

  @override
  String get badgeCompleteQuiz => 'Završi kviz';

  @override
  String get badgeFirstBook => 'Završi svoju prvu knjigu';

  @override
  String badgeStreak(int count) {
    return '$count dana zaredom';
  }

  @override
  String get download => 'Preuzmi';

  @override
  String get downloading => 'Preuzimanje...';

  @override
  String get supportMessageDescription =>
      'Pošaljite poruku našem timu za podršku. Javićemo vam se u najkraćem mogućem roku.';

  @override
  String get yourMessage => 'Vaša poruka';

  @override
  String get describeIssue => 'Opišite vaš problem ili pitanje...';

  @override
  String get enterMessage => 'Molimo unesite poruku';

  @override
  String get messageTooShort => 'Poruka mora imati bar 10 karaktera';

  @override
  String get accountInfoIncluded =>
      'Vaši podaci o nalogu će biti automatski uključeni.';

  @override
  String get searchInPdf => 'Pretraži PDF...';

  @override
  String get noMatchesFound => 'Nema pronađenih rezultata';

  @override
  String matchCount(int current, int total) {
    return '$current od $total';
  }

  @override
  String get noListeningHistoryTitle => 'Nema istorije slušanja';

  @override
  String get booksYouStartListeningAppearHere =>
      'Knjige koje počnete da slušate pojaviće se ovde';

  @override
  String get playlistCompleted => 'Plejlista završena!';

  @override
  String get downloadingFullPlaylist => 'Preuzimanje cele plejliste...';

  @override
  String get downloadingForOfflinePlayback =>
      'Preuzimanje za offline reprodukciju...';

  @override
  String get downloadCompleteAvailableOffline =>
      'Preuzimanje završeno! Dostupno offline.';

  @override
  String get bookInformation => 'Informacije o knjizi';

  @override
  String get noDescriptionAvailable => 'Nema dostupnog opisa.';

  @override
  String priceLabel(String price) {
    return 'Cena: \$$price';
  }

  @override
  String categoryLabel(String category) {
    return 'Kategorija: $category';
  }

  @override
  String get subscribeToListen => 'Pretplatite se da slušate';

  @override
  String get getUnlimitedAccessToAllAudiobooks =>
      'Dobijte neograničen pristup svim audio knjigama';

  @override
  String get backgroundMusic => 'Pozadinska muzika';

  @override
  String get none => 'Ništa';

  @override
  String get subscribeToListenToReels =>
      'Pretplatite se da slušate kratke klipove';

  @override
  String get noReelsAvailable => 'Nema dostupnih kratkih klipova';

  @override
  String get audioUpload => 'Otpremanje zvuka';

  @override
  String get backgroundMusicUpload => 'Otpremanje pozadinske muzike';

  @override
  String get titleRequired => 'Naslov *';

  @override
  String get authorRequired => 'Autor *';

  @override
  String get categoryRequired => 'Kategorija *';

  @override
  String get description => 'Opis';

  @override
  String get price => 'Cena';

  @override
  String get defaultBackgroundMusicOptional =>
      'Podrazumevana pozadinska muzika (opciono)';

  @override
  String get premiumContent => 'Premium sadržaj';

  @override
  String get onlySubscribersCanAccess =>
      'Samo pretplatnici mogu pristupiti ovoj knjizi';

  @override
  String get selectAudioFiles => 'Izaberite audio fajl(ove) *';

  @override
  String audioSelected(String filename) {
    return 'Audio izabran: ...$filename';
  }

  @override
  String audioFilesSelected(int count) {
    return '$count audio fajlova izabrano';
  }

  @override
  String get selectCoverImageOptional => 'Izaberite naslovnu sliku (opciono)';

  @override
  String coverSelected(String filename) {
    return 'Naslovna izabrana: ...$filename';
  }

  @override
  String get selectPdfOptional => 'Izaberite PDF (opciono)';

  @override
  String pdfSelected(String filename) {
    return 'PDF izabran: ...$filename';
  }

  @override
  String get musicTitleRequired => 'Naslov muzike *';

  @override
  String get selectBackgroundMusicFile => 'Izaberite fajl pozadinske muzike *';

  @override
  String fileSelected(String filename) {
    return 'Fajl: ...$filename';
  }

  @override
  String get uploadBackgroundMusic => 'Otpremi pozadinsku muziku';

  @override
  String get backgroundMusicUploaded => 'Pozadinska muzika otpremljena!';

  @override
  String get pleaseSelectFileAndEnterTitle =>
      'Molimo izaberite fajl i unesite naslov';

  @override
  String get createLessonQuiz => 'Napravi kviz lekcije';

  @override
  String get createBookQuiz => 'Napravi kviz knjige';

  @override
  String get addNewQuestion => 'Dodaj novo pitanje';

  @override
  String get questionText => 'Tekst pitanja';

  @override
  String get correctAnswer => 'Tačan odgovor';

  @override
  String optionLabel(String letter) {
    return 'Opcija $letter';
  }

  @override
  String get required => 'Obavezno';

  @override
  String get miniQuiz => 'Mini kviz';

  @override
  String get startQuiz => 'Započni kviz';

  @override
  String get bookQuiz => 'Kviz knjige';

  @override
  String errorSavingResult(String error) {
    return 'Greška pri čuvanju rezultata: $error';
  }

  @override
  String get sessionExpired => 'Sesija istekla';

  @override
  String get sessionExpiredMessage =>
      'Vaša sesija je istekla. Molimo prijavite se ponovo.';

  @override
  String get ok => 'U redu';

  @override
  String get unknown => 'Nepoznato';

  @override
  String speedLabel(String speed) {
    return '${speed}x';
  }

  @override
  String get notifications => 'Obavestenja';

  @override
  String get notificationSettings => 'Podesavanja obavestenja';

  @override
  String get enableNotifications => 'Ukljuci obavestenja';

  @override
  String get dailyMotivation => 'Dnevna motivacija';

  @override
  String get dailyMotivationSubtitle =>
      'Primajte inspirativni istorijski citat dnevno';

  @override
  String get continueListeningNotification => 'Podsetnici za slusanje';

  @override
  String get continueListeningSubtitle =>
      'Primite podsetnik da nastavite sa slusanjem';

  @override
  String get notificationTime => 'Vreme obavestenja';

  @override
  String get notificationTimeSubtitle =>
      'Kada poceti slanje dnevnih obavestenja';

  @override
  String get notificationPermissionRequired =>
      'Dozvola za obavestenja je neophodna za slanje podsetnika';

  @override
  String get manageSubscription => 'Upravljanje pretplatom';

  @override
  String get currentMembership => 'Trenutno članstvo';

  @override
  String get youAreNotAMember => 'Trenutno niste član';

  @override
  String get getTheMostOut => 'Iskoristite maksimum od Echoes of History';

  @override
  String get cancelAnytime => 'Otkažite bilo kada.';

  @override
  String get advanced => 'Napredno';

  @override
  String get autoRenewal => 'Auto-obnova';

  @override
  String renewsOn(String date) {
    return 'Obnavlja se $date';
  }

  @override
  String expiresOn(String date) {
    return 'Ističe $date';
  }

  @override
  String get alreadyMember => 'Već ste član';

  @override
  String get cancelCurrentMembershipFirst =>
      'Otkažite ovo članstvo da biste uzeli drugo.';

  @override
  String get getAMembership => 'Uzmi članstvo';

  @override
  String get turnOffAutoRenewQuestion => 'Isključi auto-obnovu?';

  @override
  String get keepSubscription => 'Zadrži pretplatu';

  @override
  String get benefits => 'Pogodnosti';

  @override
  String get subscriptionCanceled => 'Pretplata otkazana';

  @override
  String get managedSubscriptionUpdate => 'Pretplata ažurirana';

  @override
  String get privacyPolicy => 'Politika privatnosti';

  @override
  String get conditionsOfUse => 'Uslovi korišćenja';

  @override
  String get privacyPolicyText =>
      'Cenimo vašu privatnost. Prikupljamo minimalne podatke neophodne za pružanje naših usluga. Ne prodajemo vaše lične podatke trećim licima.';

  @override
  String get conditionsOfUseText =>
      'Korišćenjem ove aplikacije pristajete na naše uslove. Sadržaj je samo za ličnu upotrebu. Neovlašćena distribucija je zabranjena.';

  @override
  String get legal => 'Pravno';

  @override
  String get subscribeMonthly => 'Pretplati se mesečno';

  @override
  String get subscribeYearly => 'Pretplati se godišnje';

  @override
  String get getLifetimeAccess => 'Dobij doživotni pristup';

  @override
  String savePercent(int percent) {
    return 'Uštedi $percent%';
  }

  @override
  String get answerToLifeUniverseEverything =>
      'Odgovor na život, univerzum i sve ostalo';

  @override
  String get legalDisclaimer =>
      'Prijavljivanjem pristajete na naše Uslove korišćenja. Molimo pogledajte naša Pravila privatnosti.';

  @override
  String get expiresIn2Minutes => 'Ističe za 2 minuta';

  @override
  String get appSettings => 'Podešavanja aplikacije';

  @override
  String get membership => 'Članstvo';

  @override
  String get customerSupport => 'Korisnička podrška';

  @override
  String get emailNotifications => 'Email obaveštenja';

  @override
  String get getNotifications => 'Primaj obaveštenja';

  @override
  String get seeWhatIsTrending => 'Pogledajte šta je popularno danas';

  @override
  String get seeWhatIsNew => 'Pogledajte šta je novo';

  @override
  String get trendingToday => 'Popularno danas';

  @override
  String get emailSettingsSaved => 'Podešavanja sačuvana';

  @override
  String get listeningNotifications => 'Obaveštenja za slušanje';

  @override
  String get listeningActivity => 'Listening Activity';

  @override
  String get weeklyProgress => 'Weekly Progress';

  @override
  String get topGenres => 'Top Genres';

  @override
  String get knowledgeMastery => 'Knowledge Mastery';

  @override
  String get booksRead => 'Books Read';

  @override
  String get quizzesPassed => 'Quizzes Passed';

  @override
  String get minutes => 'minutes';

  @override
  String get less => 'Less';

  @override
  String get more => 'More';

  @override
  String get noStatsData =>
      'No statistics data available yet. Start listening to see your progress!';

  @override
  String get recommendToFriend => 'Recommend to Friend';

  @override
  String get friendEmail => 'Friend\'s Email';

  @override
  String get personalMessage => 'Personal Message (Optional)';

  @override
  String get personalMessageHint => 'Write something nice...';

  @override
  String get sendRecommendation => 'Send Recommendation';

  @override
  String get shareSuccess =>
      'Chapter shared successfully! Your friend will receive an email.';

  @override
  String get shareError => 'Failed to share chapter. Please try again.';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get downloadCancelled => 'Preuzimanje otkazano';

  @override
  String get bookAlreadyDownloaded => 'Knjiga je već preuzeta.';

  @override
  String get userPreferences => 'User Preferences';

  @override
  String get dailyGoal => 'Daily Goal';

  @override
  String get primaryGoal => 'Primary Goal';

  @override
  String get interests => 'Interests';

  @override
  String get preferencesSaved => 'Preferences saved successfully';

  @override
  String get failedToSavePreferences => 'Failed to save preferences';

  @override
  String get save => 'Save';

  @override
  String get custom => 'Custom';
}
