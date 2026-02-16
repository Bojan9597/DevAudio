import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../services/content_key_manager.dart';
import '../repositories/book_repository.dart';
import 'login_screen.dart';
import 'user_preferences_screen.dart';
import 'profile_screen.dart';
import 'upload_book_screen.dart';
import '../states/layout_state.dart';
import '../l10n/generated/app_localizations.dart';
import '../main.dart'; // For audioHandler
import '../widgets/support_dialog.dart';
import '../services/notification_service.dart';
import 'notification_settings_screen.dart';
import 'player_settings_screen.dart';
import 'manage_subscription_screen.dart';
import 'email_notification_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'conditions_of_use_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _authService.isAdmin();
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      // Get user ID before clearing auth (needed for key cleanup)
      final userId = await _authService.getCurrentUserId();

      // Stop audio playback and clear mini player state
      await audioHandler.clearState();

      // Clear subscription cache
      await SubscriptionService().clearCache();

      // Clear content encryption keys for this user
      if (userId != null) {
        await ContentKeyManager().clearUserKey(userId);
      }

      // Clear favorites cache
      BookRepository().clearFavoritesCache();

      // Clear profile screen static cache
      ProfileScreenCache.clear();

      // Cancel all notification tasks
      await NotificationService().cancelAllTasks();

      // Logout (clears tokens and user data)
      await _authService.logout();

      // Clear layout state
      await globalLayoutState.updateUser(null);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader(l10n.appSettings),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: Text(l10n.userPreferences),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserPreferencesScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  trailing: Text(
                    _getLanguageName(globalLayoutState.locale?.languageCode),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: Text(l10n.language),
                          children: [
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('en'));
                                Navigator.pop(context);
                              },
                              child: Text(l10n.languageEnglish),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('es'));
                                Navigator.pop(context);
                              },
                              child: Text(l10n.languageSpanish),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('sr'));
                                Navigator.pop(context);
                              },
                              child: Text(l10n.languageSerbian),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('fr'));
                                Navigator.pop(context);
                              },
                              child: Text(l10n.languageFrench),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('de'));
                                Navigator.pop(context);
                              },
                              child: Text(l10n.languageGerman),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: Text(l10n.theme),
                  trailing: Text(_getThemeName(globalLayoutState.themeMode)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: Text(l10n.theme),
                          children: [
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setThemeMode(
                                  ThemeMode.system,
                                );
                                Navigator.pop(context);
                              },
                              child: Text(l10n.themeSystem),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setThemeMode(ThemeMode.light);
                                Navigator.pop(context);
                              },
                              child: Text(l10n.themeLight),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setThemeMode(ThemeMode.dark);
                                Navigator.pop(context);
                              },
                              child: Text(l10n.themeDark),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text("Player"), // TODO: Localize
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlayerSettingsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),

                _buildSectionHeader(l10n.notifications),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(l10n.emailNotifications),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmailNotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(l10n.listeningNotifications),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),

                _buildSectionHeader(l10n.membership),
                ListTile(
                  leading: const Icon(Icons.card_membership),
                  title: Text(l10n.manageSubscription),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageSubscriptionScreen(),
                      ),
                    );
                  },
                ),

                // Only show upload option for admin user (keeping it separate or under membership/admin?)
                // Keeping it as is or maybe under a hidden section?
                // I'll put it at the bottom of membership or just conditionally
                if (_isAdmin) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cloud_upload),
                    title: Text(l10n.uploadAudioBook),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UploadBookScreen(),
                        ),
                      );

                      if (result == true) {
                        // Wait a bit to ensure backend consistency and UI readiness
                        await Future.delayed(const Duration(milliseconds: 500));
                        // Trigger app-wide refresh
                        globalLayoutState.triggerRefresh();
                      }
                    },
                  ),
                ],

                const Divider(),

                _buildSectionHeader(l10n.customerSupport),
                ListTile(
                  leading: const Icon(Icons.support_agent, color: Colors.blue),
                  title: Text(l10n.contactSupport),
                  subtitle: Text(l10n.sendUsAMessage),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const SupportDialog(),
                    );
                  },
                ),

                const Divider(),

                _buildSectionHeader(l10n.legal),
                ListTile(
                  title: Text(l10n.privacyPolicy),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: Text(l10n.conditionsOfUse),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConditionsOfUseScreen(),
                      ),
                    );
                  },
                ),

                const Divider(),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    l10n.logout,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: _logout,
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      default:
        return l10n.themeSystem;
    }
  }

  String _getLanguageName(String? code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case 'es':
        return l10n.languageSpanish;
      case 'sr':
        return l10n.languageSerbian;
      case 'fr':
        return l10n.languageFrench;
      case 'de':
        return l10n.languageGerman;
      default:
        return l10n.languageEnglish;
    }
  }
}
