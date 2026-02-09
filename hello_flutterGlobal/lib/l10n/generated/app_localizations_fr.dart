// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Echoes Of History';

  @override
  String get library => 'Bibliothèque';

  @override
  String get profile => 'Profil';

  @override
  String get categories => 'Catégories';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get login => 'Se connecter';

  @override
  String get myBooks => 'Mes Livres';

  @override
  String get favorites => 'Favoris';

  @override
  String get allBooks => 'Tous les Livres';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get home => 'Accueil';

  @override
  String get discover => 'Découvrir';

  @override
  String get uploadAudioBook => 'Télécharger un livre audio';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

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
  String get enteringOfflineMode => 'Passage en mode hors ligne';

  @override
  String get backOnline => 'De retour en ligne';

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String get googleLoginFailed => 'Échec de la connexion Google';

  @override
  String get searchForBooks => 'Rechercher des livres...';

  @override
  String get searchByTitle => 'Rechercher par titre...';

  @override
  String get searchResults => 'Résultats de recherche';

  @override
  String get noBooksFound => 'Aucun livre trouvé.';

  @override
  String noBooksFoundInCategory(String categoryId) {
    return 'Aucun livre trouvé dans \"$categoryId\"';
  }

  @override
  String booksInCategory(String categoryId) {
    return 'Livres dans $categoryId';
  }

  @override
  String get switchToList => 'Passer à la liste';

  @override
  String get switchToGrid => 'Passer à la grille';

  @override
  String get getYourImaginationGoing =>
      'Laissez libre cours à votre imagination';

  @override
  String get homeHeroDescription =>
      'Les meilleurs livres audio et originaux. Le meilleur divertissement. Les podcasts que vous voulez entendre.';

  @override
  String get continueToFreeTrial => 'Continuer vers l\'essai gratuit';

  @override
  String get autoRenewsInfo =>
      'Renouvellement automatique à 14,95\$/mois après 30 jours. Annulez à tout moment.';

  @override
  String get subscribe => 'S\'abonner';

  @override
  String get monthlySubscriptionInfo =>
      'Abonnement mensuel à partir de 14,95\$/mois. Annulez à tout moment.';

  @override
  String get subscriptionActivated => 'Abonnement activé!';

  @override
  String get unlimitedAccess => 'Accès illimité';

  @override
  String get unlimitedAccessDescription =>
      'Diffusez tout notre catalogue de best-sellers et d\'originaux sans publicité. Aucun crédit requis.';

  @override
  String get listenOffline => 'Écouter hors ligne';

  @override
  String get listenOfflineDescription =>
      'Téléchargez des titres sur votre appareil et emportez votre bibliothèque partout.';

  @override
  String get interactiveQuizzes => 'Quiz interactifs';

  @override
  String get interactiveQuizzesDescription =>
      'Testez vos connaissances et renforcez ce que vous avez appris avec des quiz interactifs.';

  @override
  String get findTheRightSpeed => 'Trouvez la bonne vitesse';

  @override
  String get findTheRightSpeedDescription =>
      'Ralentissez la narration ou accélérez le rythme.';

  @override
  String get sleepTimer => 'Minuterie de sommeil';

  @override
  String get sleepTimerDescription => 'Endormez-vous sans manquer un moment.';

  @override
  String get favoritesFeature => 'Favoris';

  @override
  String get favoritesFeatureDescription =>
      'Gardez vos meilleurs choix à portée de main.';

  @override
  String get newReleases => 'Nouvelles sorties';

  @override
  String get topPicks => 'Meilleurs choix';

  @override
  String get continueListening => 'Continuer l\'écoute';

  @override
  String get nowPlaying => 'EN COURS';

  @override
  String get returnToLessonMap => 'Retour à la carte des leçons';

  @override
  String get notAvailableOffline => 'Non disponible en mode hors ligne';

  @override
  String errorLoadingBooks(String error) {
    return 'Erreur lors du chargement des livres: $error';
  }

  @override
  String postedBy(String name) {
    return 'Publié par $name';
  }

  @override
  String get guestUser => 'Utilisateur invité';

  @override
  String get noEmail => 'Pas d\'email';

  @override
  String get admin => 'Administrateur';

  @override
  String get upgradeToPremium => 'Passer à Premium';

  @override
  String premiumUntil(String date) {
    return 'Premium jusqu\'au $date';
  }

  @override
  String get lifetimePremium => 'Premium à vie';

  @override
  String get listenHistory => 'Historique d\'écoute';

  @override
  String get stats => 'Statistiques';

  @override
  String get badges => 'Badges';

  @override
  String get noListeningHistory => 'Pas encore d\'historique d\'écoute.';

  @override
  String get listeningStats => 'Statistiques d\'écoute';

  @override
  String totalTime(String time) {
    return 'Temps total: $time';
  }

  @override
  String booksCompleted(int count) {
    return 'Livres terminés: $count';
  }

  @override
  String get noBadgesYet => 'Pas encore de badges';

  @override
  String get subscriptionDetails => 'Détails de l\'abonnement';

  @override
  String get planType => 'Type de forfait';

  @override
  String get status => 'Statut';

  @override
  String get active => 'Actif';

  @override
  String get expiringSoon => 'Expire bientôt';

  @override
  String get expired => 'Expiré';

  @override
  String get started => 'Commencé';

  @override
  String get expires => 'Expire';

  @override
  String get autoRenew => 'Renouvellement auto';

  @override
  String get on => 'Activé';

  @override
  String get off => 'Désactivé';

  @override
  String get cancelAutoRenewal => 'Annuler le renouvellement auto';

  @override
  String get turnOffAutoRenewal => 'Désactiver le renouvellement auto?';

  @override
  String get subscriptionWillRemainActive =>
      'Votre abonnement restera actif jusqu\'à la fin de la période de facturation en cours.';

  @override
  String get keepOn => 'Garder activé';

  @override
  String get turnOff => 'Désactiver';

  @override
  String get close => 'Fermer';

  @override
  String lastListened(String date) {
    return 'Dernière écoute: $date';
  }

  @override
  String progress(String current, String total) {
    return 'Progression: $current / $total';
  }

  @override
  String earnedOn(String date) {
    return 'Obtenu le $date';
  }

  @override
  String get unlockAllAudiobooks => 'Débloquez tous les livres audio';

  @override
  String get subscribeToGetAccess =>
      'Abonnez-vous pour obtenir un accès illimité à toute notre bibliothèque';

  @override
  String get subscribeNow => 'S\'abonner maintenant';

  @override
  String get maybeLater => 'Peut-être plus tard';

  @override
  String get subscriptionActivatedSuccess =>
      'Abonnement activé! Profitez d\'un accès illimité.';

  @override
  String get subscriptionFailed => 'Échec de l\'abonnement';

  @override
  String get bestValue => 'MEILLEURE OFFRE';

  @override
  String get planTestMinuteTitle => 'Test de 2 minutes';

  @override
  String get planTestMinuteSubtitle => 'Pour test - expire dans 2 minutes';

  @override
  String get planMonthlyTitle => 'Mensuel';

  @override
  String get planMonthlySubtitle =>
      'Facturation mensuelle, annulez à tout moment';

  @override
  String get planYearlyTitle => 'Annuel';

  @override
  String get planYearlySubtitle => 'Économisez 33% - Meilleure offre!';

  @override
  String get planLifetimeTitle => 'À vie';

  @override
  String get planLifetimeSubtitle => 'Paiement unique, accès permanent';

  @override
  String get badgeEarned => 'BADGE OBTENU!';

  @override
  String get awesome => 'Génial!';

  @override
  String get noFavoriteBooks => 'Pas encore de livres favoris';

  @override
  String get noUploadedBooks => 'Pas de livres téléchargés';

  @override
  String get noDownloadedBooks => 'Pas de livres téléchargés';

  @override
  String get booksDownloadedAppearHere =>
      'Les livres que vous téléchargez apparaîtront ici';

  @override
  String get uploaded => 'Téléchargés';

  @override
  String get removeFromFavorites => 'Retirer des favoris';

  @override
  String get addToFavorites => 'Ajouter aux favoris';

  @override
  String get pleaseLoginToUseFavorites =>
      'Veuillez vous connecter pour utiliser les favoris';

  @override
  String get failedToUpdateFavorite => 'Échec de la mise à jour du favori';

  @override
  String get quizResults => 'Résultats du quiz';

  @override
  String youScored(int score, int total) {
    return 'Vous avez obtenu $score sur $total!';
  }

  @override
  String scorePercentage(String percentage) {
    return 'Score: $percentage%';
  }

  @override
  String get passed => 'RÉUSSI!';

  @override
  String get keepTrying => 'Continuez d\'essayer!';

  @override
  String get returnToQuiz => 'Retourner au quiz';

  @override
  String get finish => 'Terminer';

  @override
  String get previous => 'Précédent';

  @override
  String get nextQuestion => 'Question suivante';

  @override
  String get submitQuiz => 'Soumettre le quiz';

  @override
  String get questionAdded => 'Question ajoutée!';

  @override
  String get addAtLeastOneQuestion => 'Ajoutez au moins une question.';

  @override
  String get quizSavedSuccessfully => 'Quiz enregistré avec succès!';

  @override
  String get saving => 'Enregistrement...';

  @override
  String get finishAndSave => 'Terminer et enregistrer';

  @override
  String get purchaseSuccessful =>
      'Achat réussi! Téléchargement de la playlist...';

  @override
  String get noTracksFound => 'Aucune piste trouvée';

  @override
  String error(String message) {
    return 'Erreur: $message';
  }

  @override
  String get uploadBook => 'Télécharger le livre';

  @override
  String get free => 'GRATUIT';

  @override
  String get catProgramming => 'Programmation';

  @override
  String get catOperatingSystems => 'Systèmes d\'exploitation';

  @override
  String get catLinux => 'Linux';

  @override
  String get catNetworking => 'Réseaux';

  @override
  String get catFileSystems => 'Systèmes de fichiers';

  @override
  String get catSecurity => 'Sécurité';

  @override
  String get catShellScripting => 'Scripts Shell';

  @override
  String get catSystemAdministration => 'Administration système';

  @override
  String get catWindows => 'Windows';

  @override
  String get catInternals => 'Internes';

  @override
  String get catPowerShell => 'PowerShell';

  @override
  String get catMacOS => 'macOS';

  @override
  String get catShellAndScripting => 'Shell et Scripts';

  @override
  String get catProgrammingLanguages => 'Langages de programmation';

  @override
  String get catPython => 'Python';

  @override
  String get catBasics => 'Bases';

  @override
  String get catAdvancedTopics => 'Sujets avancés';

  @override
  String get catWebDevelopment => 'Développement Web';

  @override
  String get catDataScience => 'Science des données';

  @override
  String get catScriptingAndAutomation => 'Scripts et automatisation';

  @override
  String get catCCpp => 'C / C++';

  @override
  String get catCBasics => 'Bases de C';

  @override
  String get catCppBasics => 'Bases de C++';

  @override
  String get catCppAdvanced => 'C++ avancé';

  @override
  String get catSTL => 'STL';

  @override
  String get catSystemProgramming => 'Programmation système';

  @override
  String get catJava => 'Java';

  @override
  String get catOOP => 'Programmation orientée objet';

  @override
  String get catConcurrencyAndThreads => 'Concurrence et threads';

  @override
  String get catJavaScript => 'JavaScript';

  @override
  String get catBrowserAndDOM => 'Navigateur et DOM';

  @override
  String get catNodeJs => 'Node.js';

  @override
  String get catFrameworks => 'Frameworks (React, Vue, Angular)';

  @override
  String get browseByCategory => 'Parcourir les livres audio par catégorie';

  @override
  String get noCategoriesFound => 'Aucune catégorie trouvée';

  @override
  String get rateThisBook => 'Noter ce livre';

  @override
  String get submit => 'Envoyer';

  @override
  String get cancel => 'Annuler';

  @override
  String get pleaseLogInToRateBooks => 'Connectez-vous pour noter les livres';

  @override
  String thanksForRating(int stars) {
    return 'Merci pour votre note de $stars étoiles!';
  }

  @override
  String get failedToSubmitRating => 'Échec de l\'envoi de la note';

  @override
  String get rate => 'Noter';

  @override
  String get pleaseLogInToManageFavorites =>
      'Connectez-vous pour gérer les favoris';

  @override
  String get downloadingForOffline =>
      'Téléchargement pour lecture hors ligne...';

  @override
  String get downloadComplete =>
      'Téléchargement terminé! Lecture du fichier local.';

  @override
  String downloadFailed(String error) {
    return 'Échec du téléchargement: $error';
  }

  @override
  String get details => 'Détails';

  @override
  String failedToLoadAudio(String error) {
    return 'Échec du chargement audio: $error';
  }

  @override
  String get contactSupport => 'Contacter le support';

  @override
  String get sendUsAMessage => 'Envoyez-nous un message';

  @override
  String get messageSentSuccessfully => 'Message envoyé avec succès!';

  @override
  String get send => 'Envoyer';

  @override
  String get pleaseSelectCategory => 'Veuillez sélectionner une catégorie';

  @override
  String get pleaseSelectAudioFile =>
      'Veuillez sélectionner au moins un fichier audio';

  @override
  String get uploadSuccessful => 'Téléversement réussi!';

  @override
  String uploadFailed(String error) {
    return 'Échec du téléversement: $error';
  }

  @override
  String get noQuizAvailable => 'Aucun quiz disponible pour cet élément.';

  @override
  String questionNumber(int current, int total) {
    return 'Question $current/$total';
  }

  @override
  String get planMonthly => 'Mensuel';

  @override
  String get planYearly => 'Annuel';

  @override
  String get planLifetime => 'À vie';

  @override
  String get planTestMinute => 'Test de 2 minutes';

  @override
  String badgeReadBooks(int count) {
    return 'Lire $count livres';
  }

  @override
  String badgeListenHours(int count) {
    return 'Écouter $count heures';
  }

  @override
  String get badgeCompleteQuiz => 'Terminer un quiz';

  @override
  String get badgeFirstBook => 'Terminer votre premier livre';

  @override
  String badgeStreak(int count) {
    return '$count jours consécutifs';
  }

  @override
  String get download => 'Télécharger';

  @override
  String get downloading => 'Téléchargement...';

  @override
  String get supportMessageDescription =>
      'Envoyez un message à notre équipe de support. Nous vous répondrons dès que possible.';

  @override
  String get yourMessage => 'Votre message';

  @override
  String get describeIssue => 'Décrivez votre problème ou question...';

  @override
  String get enterMessage => 'Veuillez entrer un message';

  @override
  String get messageTooShort =>
      'Le message doit contenir au moins 10 caractères';

  @override
  String get accountInfoIncluded =>
      'Les informations de votre compte seront automatiquement incluses.';

  @override
  String get searchInPdf => 'Rechercher dans le PDF...';

  @override
  String get noMatchesFound => 'Aucun résultat trouvé';

  @override
  String matchCount(int current, int total) {
    return '$current sur $total';
  }

  @override
  String get noListeningHistoryTitle => 'Pas d\'historique d\'écoute';

  @override
  String get booksYouStartListeningAppearHere =>
      'Les livres que vous commencez à écouter apparaîtront ici';

  @override
  String get playlistCompleted => 'Playlist terminée !';

  @override
  String get downloadingFullPlaylist =>
      'Téléchargement de la playlist complète...';

  @override
  String get downloadingForOfflinePlayback =>
      'Téléchargement pour lecture hors ligne...';

  @override
  String get downloadCompleteAvailableOffline =>
      'Téléchargement terminé ! Disponible hors ligne.';

  @override
  String get bookInformation => 'Informations sur le livre';

  @override
  String get noDescriptionAvailable => 'Aucune description disponible.';

  @override
  String priceLabel(String price) {
    return 'Prix : \$$price';
  }

  @override
  String categoryLabel(String category) {
    return 'Catégorie : $category';
  }

  @override
  String get subscribeToListen => 'Abonnez-vous pour écouter';

  @override
  String get getUnlimitedAccessToAllAudiobooks =>
      'Obtenez un accès illimité à tous les livres audio';

  @override
  String get backgroundMusic => 'Musique de fond';

  @override
  String get none => 'Aucune';

  @override
  String get subscribeToListenToReels => 'Abonnez-vous pour écouter les Reels';

  @override
  String get noReelsAvailable => 'Aucun reel disponible';

  @override
  String get audioUpload => 'Téléverser l\'audio';

  @override
  String get backgroundMusicUpload => 'Téléverser la musique de fond';

  @override
  String get titleRequired => 'Titre *';

  @override
  String get authorRequired => 'Auteur *';

  @override
  String get categoryRequired => 'Catégorie *';

  @override
  String get description => 'Description';

  @override
  String get price => 'Prix';

  @override
  String get defaultBackgroundMusicOptional =>
      'Musique de fond par défaut (optionnel)';

  @override
  String get premiumContent => 'Contenu Premium';

  @override
  String get onlySubscribersCanAccess =>
      'Seuls les abonnés peuvent accéder à ce livre';

  @override
  String get selectAudioFiles => 'Sélectionner fichier(s) audio *';

  @override
  String audioSelected(String filename) {
    return 'Audio sélectionné : ...$filename';
  }

  @override
  String audioFilesSelected(int count) {
    return '$count fichiers audio sélectionnés';
  }

  @override
  String get selectCoverImageOptional =>
      'Sélectionner l\'image de couverture (optionnel)';

  @override
  String coverSelected(String filename) {
    return 'Couverture sélectionnée : ...$filename';
  }

  @override
  String get selectPdfOptional => 'Sélectionner un PDF (optionnel)';

  @override
  String pdfSelected(String filename) {
    return 'PDF sélectionné : ...$filename';
  }

  @override
  String get musicTitleRequired => 'Titre de la musique *';

  @override
  String get selectBackgroundMusicFile =>
      'Sélectionner le fichier de musique de fond *';

  @override
  String fileSelected(String filename) {
    return 'Fichier : ...$filename';
  }

  @override
  String get uploadBackgroundMusic => 'Téléverser la musique de fond';

  @override
  String get backgroundMusicUploaded => 'Musique de fond téléversée !';

  @override
  String get pleaseSelectFileAndEnterTitle =>
      'Veuillez sélectionner un fichier et entrer le titre';

  @override
  String get createLessonQuiz => 'Créer un quiz de leçon';

  @override
  String get createBookQuiz => 'Créer un quiz de livre';

  @override
  String get addNewQuestion => 'Ajouter une nouvelle question';

  @override
  String get questionText => 'Texte de la question';

  @override
  String get correctAnswer => 'Bonne réponse';

  @override
  String optionLabel(String letter) {
    return 'Option $letter';
  }

  @override
  String get required => 'Obligatoire';

  @override
  String get miniQuiz => 'Mini quiz';

  @override
  String get startQuiz => 'Commencer le quiz';

  @override
  String get bookQuiz => 'Quiz du livre';

  @override
  String errorSavingResult(String error) {
    return 'Erreur lors de la sauvegarde du résultat : $error';
  }

  @override
  String get sessionExpired => 'Session expirée';

  @override
  String get sessionExpiredMessage =>
      'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get ok => 'OK';

  @override
  String get unknown => 'Inconnu';

  @override
  String speedLabel(String speed) {
    return '${speed}x';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationSettings => 'Parametres de notifications';

  @override
  String get enableNotifications => 'Activer les notifications';

  @override
  String get dailyMotivation => 'Motivation quotidienne';

  @override
  String get dailyMotivationSubtitle =>
      'Recevez une citation historique inspirante par jour';

  @override
  String get continueListeningNotification => 'Rappels d\'ecoute';

  @override
  String get continueListeningSubtitle =>
      'Recevez un rappel pour continuer votre livre audio';

  @override
  String get notificationTime => 'Heure de notification';

  @override
  String get notificationTimeSubtitle =>
      'Quand commencer a envoyer les notifications quotidiennes';

  @override
  String get notificationPermissionRequired =>
      'L\'autorisation de notification est requise pour envoyer des rappels';
}
