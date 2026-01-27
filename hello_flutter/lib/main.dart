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
import 'package:syncfusion_flutter_core/core.dart';

// Global audio handler instance
late MyAudioHandler audioHandler;

void main() async {
  print("=== 1. APP STARTING ===");

  try {
    print("=== 2. Initializing Flutter binding ===");
    WidgetsFlutterBinding.ensureInitialized();
    print("=== 3. Flutter binding initialized ===");

    // Register Syncfusion community license key
    // Get your free key at: https://www.syncfusion.com/account/claim-license-key
    SyncfusionLicense.registerLicense('YOUR_LICENSE_KEY_HERE');

    print("=== 4. Starting AudioService initialization ===");
    audioHandler = await AudioService.init(
      builder: () {
        print("=== 5. Creating MyAudioHandler instance ===");
        final handler = MyAudioHandler();
        print("=== 6. MyAudioHandler created ===");
        return handler;
      },
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.dev_audio.channel.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
      ),
    );
    print("=== 7. AudioService initialized successfully! ===");
  } catch (e, stackTrace) {
    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    print("!!! FATAL ERROR DURING INITIALIZATION !!!");
    print("!!! Error: $e");
    print("!!! Stack trace:");
    print(stackTrace);
    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    // Create a fallback handler without the service
    print("=== Creating fallback handler without AudioService ===");
    audioHandler = MyAudioHandler();
    print("=== Fallback handler created ===");
  }

  print("=== 8. Initializing ConnectivityService ===");
  await ConnectivityService().initialize();
  print("=== 9. ConnectivityService initialized ===");

  print("=== 10. Setting screen orientation ===");
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  print("=== 11. Screen orientation set ===");

  print("=== 12. Running app ===");
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
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    if (isLoggedIn) {
      final userId = await authService.getCurrentUserId();
      if (userId != null) {
        await globalLayoutState.updateUser(userId.toString());
      }
    } else {
      // Ensure logged out state
      await globalLayoutState.updateUser(null);
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });
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
