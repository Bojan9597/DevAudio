// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Audiolibros';

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
}
