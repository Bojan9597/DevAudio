// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Echoes Of History';

  @override
  String get library => 'Biblioteca';

  @override
  String get profile => 'Perfil';

  @override
  String get categories => 'Categorías';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Tema';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get myBooks => 'Mis libros';

  @override
  String get favorites => 'Favoritos';

  @override
  String get allBooks => 'Todos los libros';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get confirmNewPassword => 'Confirmar nueva contraseña';

  @override
  String get currentPassword => 'Contraseña actual';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get home => 'Inicio';

  @override
  String get discover => 'Descubrir';

  @override
  String get uploadAudioBook => 'Subir audiolibro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

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
  String get enteringOfflineMode => 'Entrando en modo sin conexión';

  @override
  String get backOnline => 'De vuelta en línea';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get googleLoginFailed => 'Error al iniciar sesión con Google';

  @override
  String get searchForBooks => 'Buscar libros...';

  @override
  String get searchByTitle => 'Buscar por título...';

  @override
  String get searchResults => 'Resultados de búsqueda';

  @override
  String get noBooksFound => 'No se encontraron libros.';

  @override
  String noBooksFoundInCategory(String categoryId) {
    return 'No se encontraron libros en \"$categoryId\"';
  }

  @override
  String booksInCategory(String categoryId) {
    return 'Libros en $categoryId';
  }

  @override
  String get switchToList => 'Cambiar a lista';

  @override
  String get switchToGrid => 'Cambiar a cuadrícula';

  @override
  String get getYourImaginationGoing => 'Deja volar tu imaginación';

  @override
  String get homeHeroDescription =>
      'Los mejores audiolibros y originales. El mejor entretenimiento. Los podcasts que quieres escuchar.';

  @override
  String get continueToFreeTrial => 'Continuar a prueba gratuita';

  @override
  String get autoRenewsInfo =>
      'Se renueva automáticamente a \$14.95/mes después de 30 días. Cancela cuando quieras.';

  @override
  String get subscribe => 'Suscribirse';

  @override
  String get monthlySubscriptionInfo =>
      'Suscripción mensual desde \$14.95/mes. Cancela cuando quieras.';

  @override
  String get subscriptionActivated => '¡Suscripción activada!';

  @override
  String get unlimitedAccess => 'Acceso ilimitado';

  @override
  String get unlimitedAccessDescription =>
      'Transmite todo nuestro catálogo de bestsellers y originales sin anuncios. Sin créditos requeridos.';

  @override
  String get listenOffline => 'Escuchar sin conexión';

  @override
  String get listenOfflineDescription =>
      'Descarga títulos a tu dispositivo y lleva tu biblioteca contigo donde vayas.';

  @override
  String get interactiveQuizzes => 'Cuestionarios interactivos';

  @override
  String get interactiveQuizzesDescription =>
      'Pon a prueba tus conocimientos y refuerza lo aprendido con cuestionarios interactivos.';

  @override
  String get findTheRightSpeed => 'Encuentra la velocidad correcta';

  @override
  String get findTheRightSpeedDescription =>
      'Reduce la velocidad de la narración o acelera el ritmo.';

  @override
  String get sleepTimer => 'Temporizador de sueño';

  @override
  String get sleepTimerDescription => 'Duerme sin perderte nada.';

  @override
  String get favoritesFeature => 'Favoritos';

  @override
  String get favoritesFeatureDescription =>
      'Mantén tus mejores selecciones a mano.';

  @override
  String get newReleases => 'Nuevos lanzamientos';

  @override
  String get topPicks => 'Mejores selecciones';

  @override
  String get continueListening => 'Continuar escuchando';

  @override
  String get nowPlaying => 'REPRODUCIENDO';

  @override
  String get returnToLessonMap => 'Volver al mapa de lecciones';

  @override
  String get notAvailableOffline => 'No disponible en modo sin conexión';

  @override
  String errorLoadingBooks(String error) {
    return 'Error al cargar libros: $error';
  }

  @override
  String postedBy(String name) {
    return 'Publicado por $name';
  }

  @override
  String get guestUser => 'Usuario invitado';

  @override
  String get noEmail => 'Sin correo';

  @override
  String get admin => 'Administrador';

  @override
  String get upgradeToPremium => 'Actualizar a Premium';

  @override
  String premiumUntil(String date) {
    return 'Premium hasta $date';
  }

  @override
  String get lifetimePremium => 'Premium de por vida';

  @override
  String get listenHistory => 'Historial de escucha';

  @override
  String get stats => 'Estadísticas';

  @override
  String get badges => 'Insignias';

  @override
  String get noListeningHistory => 'Aún no hay historial de escucha.';

  @override
  String get listeningStats => 'Estadísticas de escucha';

  @override
  String totalTime(String time) {
    return 'Tiempo total: $time';
  }

  @override
  String booksCompleted(int count) {
    return 'Libros completados: $count';
  }

  @override
  String get noBadgesYet => 'Aún no hay insignias';

  @override
  String get subscriptionDetails => 'Detalles de la suscripción';

  @override
  String get planType => 'Tipo de plan';

  @override
  String get status => 'Estado';

  @override
  String get active => 'Activo';

  @override
  String get expiringSoon => 'Por vencer';

  @override
  String get expired => 'Expirado';

  @override
  String get started => 'Iniciado';

  @override
  String get expires => 'Expira';

  @override
  String get autoRenew => 'Renovación automática';

  @override
  String get on => 'Activado';

  @override
  String get off => 'Desactivado';

  @override
  String get cancelAutoRenewal => 'Cancelar renovación automática';

  @override
  String get turnOffAutoRenewal => '¿Desactivar renovación automática?';

  @override
  String get subscriptionWillRemainActive =>
      'Tu suscripción permanecerá activa hasta el final del período de facturación actual.';

  @override
  String get keepOn => 'Mantener activada';

  @override
  String get turnOff => 'Desactivar';

  @override
  String get close => 'Cerrar';

  @override
  String lastListened(String date) {
    return 'Última escucha: $date';
  }

  @override
  String progress(String current, String total) {
    return 'Progreso: $current / $total';
  }

  @override
  String earnedOn(String date) {
    return 'Obtenida el $date';
  }

  @override
  String get unlockAllAudiobooks => 'Desbloquear todos los audiolibros';

  @override
  String get subscribeToGetAccess =>
      'Suscríbete para obtener acceso ilimitado a toda nuestra biblioteca';

  @override
  String get subscribeNow => 'Suscribirse ahora';

  @override
  String get maybeLater => 'Quizás después';

  @override
  String get subscriptionActivatedSuccess =>
      '¡Suscripción activada! Disfruta del acceso ilimitado.';

  @override
  String get subscriptionFailed => 'Error en la suscripción';

  @override
  String get bestValue => 'MEJOR VALOR';

  @override
  String get planTestMinuteTitle => 'Prueba de 2 minutos';

  @override
  String get planTestMinuteSubtitle => 'Para pruebas - expira en 2 minutos';

  @override
  String get planMonthlyTitle => 'Mensual';

  @override
  String get planMonthlySubtitle =>
      'Facturación mensual, cancela cuando quieras';

  @override
  String get planYearlyTitle => 'Anual';

  @override
  String get planYearlySubtitle => '¡Ahorra 33% - Mejor valor!';

  @override
  String get planLifetimeTitle => 'De por vida';

  @override
  String get planLifetimeSubtitle => 'Pago único, acceso para siempre';

  @override
  String get badgeEarned => '¡INSIGNIA OBTENIDA!';

  @override
  String get awesome => '¡Genial!';

  @override
  String get noFavoriteBooks => 'Aún no hay libros favoritos';

  @override
  String get noUploadedBooks => 'No hay libros subidos';

  @override
  String get noDownloadedBooks => 'No hay libros descargados';

  @override
  String get booksDownloadedAppearHere =>
      'Los libros que descargues aparecerán aquí';

  @override
  String get uploaded => 'Subidos';

  @override
  String get removeFromFavorites => 'Quitar de favoritos';

  @override
  String get addToFavorites => 'Añadir a favoritos';

  @override
  String get pleaseLoginToUseFavorites =>
      'Por favor inicia sesión para usar favoritos';

  @override
  String get failedToUpdateFavorite => 'Error al actualizar favorito';

  @override
  String get quizResults => 'Resultados del cuestionario';

  @override
  String youScored(int score, int total) {
    return '¡Obtuviste $score de $total!';
  }

  @override
  String scorePercentage(String percentage) {
    return 'Puntuación: $percentage%';
  }

  @override
  String get passed => '¡APROBADO!';

  @override
  String get keepTrying => '¡Sigue intentando!';

  @override
  String get returnToQuiz => 'Volver al cuestionario';

  @override
  String get finish => 'Terminar';

  @override
  String get previous => 'Anterior';

  @override
  String get nextQuestion => 'Siguiente pregunta';

  @override
  String get submitQuiz => 'Enviar cuestionario';

  @override
  String get questionAdded => '¡Pregunta añadida!';

  @override
  String get addAtLeastOneQuestion => 'Añade al menos una pregunta.';

  @override
  String get quizSavedSuccessfully => '¡Cuestionario guardado exitosamente!';

  @override
  String get saving => 'Guardando...';

  @override
  String get finishAndSave => 'Terminar y guardar';

  @override
  String get purchaseSuccessful =>
      '¡Compra exitosa! Descargando lista de reproducción...';

  @override
  String get noTracksFound => 'No se encontraron pistas';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get uploadBook => 'Subir libro';

  @override
  String get free => 'GRATIS';

  @override
  String get catProgramming => 'Programación';

  @override
  String get catOperatingSystems => 'Sistemas Operativos';

  @override
  String get catLinux => 'Linux';

  @override
  String get catNetworking => 'Redes';

  @override
  String get catFileSystems => 'Sistemas de Archivos';

  @override
  String get catSecurity => 'Seguridad';

  @override
  String get catShellScripting => 'Scripting de Shell';

  @override
  String get catSystemAdministration => 'Administración de Sistemas';

  @override
  String get catWindows => 'Windows';

  @override
  String get catInternals => 'Internos';

  @override
  String get catPowerShell => 'PowerShell';

  @override
  String get catMacOS => 'macOS';

  @override
  String get catShellAndScripting => 'Shell y Scripting';

  @override
  String get catProgrammingLanguages => 'Lenguajes de Programación';

  @override
  String get catPython => 'Python';

  @override
  String get catBasics => 'Fundamentos';

  @override
  String get catAdvancedTopics => 'Temas Avanzados';

  @override
  String get catWebDevelopment => 'Desarrollo Web';

  @override
  String get catDataScience => 'Ciencia de Datos';

  @override
  String get catScriptingAndAutomation => 'Scripting y Automatización';

  @override
  String get catCCpp => 'C / C++';

  @override
  String get catCBasics => 'Fundamentos de C';

  @override
  String get catCppBasics => 'Fundamentos de C++';

  @override
  String get catCppAdvanced => 'C++ Avanzado';

  @override
  String get catSTL => 'STL';

  @override
  String get catSystemProgramming => 'Programación de Sistemas';

  @override
  String get catJava => 'Java';

  @override
  String get catOOP => 'Programación Orientada a Objetos';

  @override
  String get catConcurrencyAndThreads => 'Concurrencia y Hilos';

  @override
  String get catJavaScript => 'JavaScript';

  @override
  String get catBrowserAndDOM => 'Navegador y DOM';

  @override
  String get catNodeJs => 'Node.js';

  @override
  String get catFrameworks => 'Frameworks (React, Vue, Angular)';

  @override
  String get browseByCategory => 'Explorar audiolibros por categoría';

  @override
  String get noCategoriesFound => 'No se encontraron categorías';

  @override
  String get rateThisBook => 'Calificar este libro';

  @override
  String get submit => 'Enviar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get pleaseLogInToRateBooks => 'Inicia sesión para calificar libros';

  @override
  String thanksForRating(int stars) {
    return '¡Gracias por tu calificación de $stars estrellas!';
  }

  @override
  String get failedToSubmitRating => 'Error al enviar la calificación';

  @override
  String get rate => 'Calificar';

  @override
  String get pleaseLogInToManageFavorites =>
      'Inicia sesión para gestionar favoritos';

  @override
  String get downloadingForOffline =>
      'Descargando para reproducción sin conexión...';

  @override
  String get downloadComplete =>
      '¡Descarga completa! Reproduciendo archivo local.';

  @override
  String downloadFailed(String error) {
    return 'Error en la descarga: $error';
  }

  @override
  String get details => 'Detalles';

  @override
  String failedToLoadAudio(String error) {
    return 'Error al cargar el audio: $error';
  }

  @override
  String get contactSupport => 'Contactar soporte';

  @override
  String get sendUsAMessage => 'Envíanos un mensaje';

  @override
  String get messageSentSuccessfully => '¡Mensaje enviado correctamente!';

  @override
  String get send => 'Enviar';

  @override
  String get pleaseSelectCategory => 'Por favor selecciona una categoría';

  @override
  String get pleaseSelectAudioFile =>
      'Por favor selecciona al menos un archivo de audio';

  @override
  String get uploadSuccessful => '¡Subida exitosa!';

  @override
  String uploadFailed(String error) {
    return 'Error en la subida: $error';
  }

  @override
  String get noQuizAvailable =>
      'No hay cuestionario disponible para este elemento.';

  @override
  String questionNumber(int current, int total) {
    return 'Pregunta $current/$total';
  }

  @override
  String get planMonthly => 'Mensual';

  @override
  String get planYearly => 'Anual';

  @override
  String get planLifetime => 'De por vida';

  @override
  String get planTestMinute => 'Prueba de 2 minutos';

  @override
  String badgeReadBooks(int count) {
    return 'Leer $count libros';
  }

  @override
  String badgeListenHours(int count) {
    return 'Escuchar $count horas';
  }

  @override
  String get badgeCompleteQuiz => 'Completar un cuestionario';

  @override
  String get badgeFirstBook => 'Terminar tu primer libro';

  @override
  String badgeStreak(int count) {
    return '$count días seguidos';
  }

  @override
  String get download => 'Descargar';

  @override
  String get downloading => 'Descargando...';

  @override
  String get supportMessageDescription =>
      'Envía un mensaje a nuestro equipo de soporte. Te responderemos lo antes posible.';

  @override
  String get yourMessage => 'Tu mensaje';

  @override
  String get describeIssue => 'Describe tu problema o pregunta...';

  @override
  String get enterMessage => 'Por favor ingresa un mensaje';

  @override
  String get messageTooShort => 'El mensaje debe tener al menos 10 caracteres';

  @override
  String get accountInfoIncluded =>
      'La información de tu cuenta se incluirá automáticamente.';

  @override
  String get searchInPdf => 'Buscar en PDF...';

  @override
  String get noMatchesFound => 'No se encontraron coincidencias';

  @override
  String matchCount(int current, int total) {
    return '$current de $total';
  }

  @override
  String get noListeningHistoryTitle => 'Sin historial de escucha';

  @override
  String get booksYouStartListeningAppearHere =>
      'Los libros que empieces a escuchar aparecerán aquí';

  @override
  String get playlistCompleted => '¡Lista de reproducción completada!';

  @override
  String get downloadingFullPlaylist => 'Descargando lista completa...';

  @override
  String get downloadingForOfflinePlayback =>
      'Descargando para reproducción sin conexión...';

  @override
  String get downloadCompleteAvailableOffline =>
      '¡Descarga completa! Disponible sin conexión.';

  @override
  String get bookInformation => 'Información del libro';

  @override
  String get noDescriptionAvailable => 'No hay descripción disponible.';

  @override
  String priceLabel(String price) {
    return 'Precio: \$$price';
  }

  @override
  String categoryLabel(String category) {
    return 'Categoría: $category';
  }

  @override
  String get subscribeToListen => 'Suscríbete para escuchar';

  @override
  String get getUnlimitedAccessToAllAudiobooks =>
      'Obtén acceso ilimitado a todos los audiolibros';

  @override
  String get backgroundMusic => 'Música de fondo';

  @override
  String get none => 'Ninguna';

  @override
  String get subscribeToListenToReels => 'Suscríbete para escuchar Reels';

  @override
  String get noReelsAvailable => 'No hay reels disponibles';

  @override
  String get audioUpload => 'Subir audio';

  @override
  String get backgroundMusicUpload => 'Subir música de fondo';

  @override
  String get titleRequired => 'Título *';

  @override
  String get authorRequired => 'Autor *';

  @override
  String get categoryRequired => 'Categoría *';

  @override
  String get description => 'Descripción';

  @override
  String get price => 'Precio';

  @override
  String get defaultBackgroundMusicOptional =>
      'Música de fondo predeterminada (opcional)';

  @override
  String get premiumContent => 'Contenido Premium';

  @override
  String get onlySubscribersCanAccess =>
      'Solo los suscriptores pueden acceder a este libro';

  @override
  String get selectAudioFiles => 'Seleccionar archivo(s) de audio *';

  @override
  String audioSelected(String filename) {
    return 'Audio seleccionado: ...$filename';
  }

  @override
  String audioFilesSelected(int count) {
    return '$count archivos de audio seleccionados';
  }

  @override
  String get selectCoverImageOptional =>
      'Seleccionar imagen de portada (opcional)';

  @override
  String coverSelected(String filename) {
    return 'Portada seleccionada: ...$filename';
  }

  @override
  String get selectPdfOptional => 'Seleccionar PDF (opcional)';

  @override
  String pdfSelected(String filename) {
    return 'PDF seleccionado: ...$filename';
  }

  @override
  String get musicTitleRequired => 'Título de música *';

  @override
  String get selectBackgroundMusicFile =>
      'Seleccionar archivo de música de fondo *';

  @override
  String fileSelected(String filename) {
    return 'Archivo: ...$filename';
  }

  @override
  String get uploadBackgroundMusic => 'Subir música de fondo';

  @override
  String get backgroundMusicUploaded => '¡Música de fondo subida!';

  @override
  String get pleaseSelectFileAndEnterTitle =>
      'Por favor selecciona un archivo e ingresa el título';

  @override
  String get createLessonQuiz => 'Crear cuestionario de lección';

  @override
  String get createBookQuiz => 'Crear cuestionario de libro';

  @override
  String get addNewQuestion => 'Añadir nueva pregunta';

  @override
  String get questionText => 'Texto de la pregunta';

  @override
  String get correctAnswer => 'Respuesta correcta';

  @override
  String optionLabel(String letter) {
    return 'Opción $letter';
  }

  @override
  String get required => 'Obligatorio';

  @override
  String get miniQuiz => 'Mini cuestionario';

  @override
  String get startQuiz => 'Iniciar cuestionario';

  @override
  String get bookQuiz => 'Cuestionario del libro';

  @override
  String errorSavingResult(String error) {
    return 'Error al guardar resultado: $error';
  }

  @override
  String get sessionExpired => 'Sesión expirada';

  @override
  String get sessionExpiredMessage =>
      'Tu sesión ha expirado. Por favor inicia sesión de nuevo.';

  @override
  String get ok => 'OK';

  @override
  String get unknown => 'Desconocido';

  @override
  String speedLabel(String speed) {
    return '${speed}x';
  }

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notificationSettings => 'Ajustes de Notificaciones';

  @override
  String get enableNotifications => 'Activar Notificaciones';

  @override
  String get dailyMotivation => 'Motivacion Diaria';

  @override
  String get dailyMotivationSubtitle =>
      'Recibe una cita histórica inspiradora al día';

  @override
  String get continueListeningNotification => 'Recordatorios de Escucha';

  @override
  String get continueListeningSubtitle =>
      'Recibe un recordatorio para continuar tu audiolibro';

  @override
  String get notificationTime => 'Hora de Notificacion';

  @override
  String get notificationTimeSubtitle =>
      'Cuando comenzar a enviar notificaciones diarias';

  @override
  String get notificationPermissionRequired =>
      'Se requiere permiso de notificacion para enviar recordatorios';
}
