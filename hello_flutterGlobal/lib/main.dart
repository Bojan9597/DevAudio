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
    try {
      audioHandler = MyAudioHandler();
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

  void _initAudioService() {
    AudioService.init(
          builder: () =>
              MyAudioHandler(), // Used for background isolation if needed
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.example.dev_audio.channel.audio',
            androidNotificationChannelName: 'Audio playback',
            androidNotificationOngoing: true,
          ),
        )
        .timeout(const Duration(seconds: 8))
        .then((handler) {
          // Note: In this aggressive fix, we already created audioHandler locally.
          // The service returns a proxy or the same handler.
          // We update the reference to ensure we have the service-connected one.
          audioHandler = handler as MyAudioHandler;
          AudioConnector.setHandler(handler);
        })
        .catchError((e) {
          print('[AuthWrapper] AudioService.init failed or timed out: $e');
        });
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
