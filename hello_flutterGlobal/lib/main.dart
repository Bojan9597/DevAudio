import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'states/layout_state.dart';
import 'app_layout.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

import 'services/connectivity_service.dart';
import 'package:audio_service/audio_service.dart';
import 'services/audio_handler.dart';
import 'services/audio_connector.dart';
import 'package:workmanager/workmanager.dart';
import 'services/notification_service.dart';
import 'services/notification_preferences.dart';
import 'services/player_preferences.dart';
import 'services/notification_workmanager.dart';

// Global audio handler instance - Late initialization required
late MyAudioHandler audioHandler;

// Global RouteObserver for navigation awareness
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  // Move SystemChrome to AuthWrapper to ensure main() is strictly non-blocking
  // await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLayoutState,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'AudioBooks',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: globalLayoutState.themeMode,
          locale: globalLayoutState.locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('es'), // Spanish
            Locale('sr'), // Serbian
            Locale('fr'), // French
            Locale('de'), // German
          ],
          navigatorObservers: [routeObserver],
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    // Render first frame immediately, THEN init everything
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndCheckAuth();
    });
  }

  Future<void> _initAndCheckAuth() async {
    // 0. Initialize AudioHandler (Main Thread, but post-frame)
    // This creates the players. If it hangs, at least the spinner is already visible.
    // 0. Initialize AudioHandler (Main Thread, but post-frame)
    // This creates the players. If it hangs, at least the spinner is already visible.
    try {
      // PROPER INITIALIZATION: Use AudioService.init to start the background service
      audioHandler = await AudioService.init(
        builder: () => MyAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.velorus.echoeshistory.audio',
          androidNotificationChannelName: 'Audio Playback',
          androidNotificationOngoing: true,
          notificationColor: Color(0xFF000000), // Optional: match app theme
        ),
      );
      AudioConnector.setHandler(audioHandler);
    } catch (e) {
      print('[AuthWrapper] Failed to create MyAudioHandler: $e');
    }

    // 1. Init NotificationService (awaited, with timeout)
    await _safeInit(
      () => NotificationService().initialize().timeout(
        const Duration(milliseconds: 1000),
        onTimeout: () => print('[AuthWrapper] Notification init timed out'),
      ),
    );

    // 2. Init Workmanager (awaited, with timeout)
    await _safeInit(
      () => Workmanager()
          .initialize(callbackDispatcher, isInDebugMode: false)
          .timeout(
            const Duration(milliseconds: 1000),
            onTimeout: () => print('[AuthWrapper] Workmanager init timed out'),
          ),
    );

    // 3. Init AudioService (fire-and-forget, slow)
    _initAudioService();

    // 4. Init Connectivity & Orientation (fire-and-forget)
    _safeInit(() => ConnectivityService().initialize());
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // 5. Check Auth
    await _checkAuth();
  }

  Future<void> _safeInit(Future<void> Function() init) async {
    try {
      await init();
    } catch (e) {
      print('[AuthWrapper] Service init failed: $e');
    }
  }

  Future<void> _initAudioService() async {
    // Load preferences for notification controls
    final prefs =
        NotificationPreferences(); // Use existing import if available or create PlayerPreferences instance
    // Note: PlayerPreferences is in a different file. I need to make sure I import it or use SharedPreferences directly/via helper.
    // I check imports in main.dart: it has 'services/notification_preferences.dart' but not 'services/player_preferences.dart'.
    // I will add the import first in a separate step or just include it if I can.
    // For now I'll assume I can add the import.

    // Correction: I should check if I added PlayerPreferences import to main.dart. I did not.
    // I will do that in a separate tool call to be safe, or just add it here if I am editing imports.
    // I can't edit imports here easily without scrolling up.
    // I will use SharedPreferences directly to avoid import issues or simpler:
    // Just use the defaults for now? NO, that's the bug.
    // I will use PlayerPreferences.

    // Wait, I can't use PlayerPreferences without import.
    // I will use a separate step to add the import first.
    return;
  }

  Future<void> _checkAuth() async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    if (isLoggedIn) {
      final userId = await authService.getCurrentUserId();
      if (userId != null) {
        await globalLayoutState.updateUser(userId.toString());

        final locale = globalLayoutState.locale?.languageCode ?? 'en';
        await NotificationPreferences().syncForBackground(
          userId.toString(),
          locale,
        );
        await NotificationService().registerNotificationTasks(
          userId.toString(),
        );
      }
    } else {
      await globalLayoutState.updateUser(null);
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });
      if (isLoggedIn) {
        NotificationService().processPendingPayload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isLoggedIn!) {
      return const AppLayout();
    }
    return const LoginScreen();
  }
}
