import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'upload_book_screen.dart';
import '../states/layout_state.dart';
import '../l10n/generated/app_localizations.dart';
import '../main.dart'; // For audioHandler
import '../widgets/support_dialog.dart';

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
      // Stop audio playback and clear mini player state
      await audioHandler.clearState();

      await _authService.logout();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(AppLocalizations.of(context)!.language),
                  trailing: Text(
                    _getLanguageName(globalLayoutState.locale?.languageCode),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: Text(AppLocalizations.of(context)!.language),
                          children: [
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('en'));
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!.languageEnglish),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('es'));
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!.languageSpanish),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('sr'));
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!.languageSerbian),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('fr'));
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!.languageFrench),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('de'));
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!.languageGerman),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: Text(AppLocalizations.of(context)!.theme),
                  trailing: Text(_getThemeName(globalLayoutState.themeMode)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          title: Text(AppLocalizations.of(context)!.theme),
                          children: [
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setThemeMode(
                                  ThemeMode.system,
                                );
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!.themeSystem),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setThemeMode(ThemeMode.light);
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!.themeLight),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setThemeMode(ThemeMode.dark);
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!.themeDark),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const Divider(),
                // Only show upload option for admin user
                if (_isAdmin)
                  ListTile(
                    leading: const Icon(Icons.cloud_upload),
                    title: Text(AppLocalizations.of(context)!.uploadAudioBook),
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
                        // Optional: Navigate to My Uploads?
                        // globalLayoutState.setCategoryId('library');
                      }
                    },
                  ),

                // Contact Support - Available for all users
                ListTile(
                  leading: const Icon(Icons.support_agent, color: Colors.blue),
                  title: Text(AppLocalizations.of(context)!.contactSupport),
                  subtitle: Text(AppLocalizations.of(context)!.sendUsAMessage),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const SupportDialog(),
                    );
                  },
                ),

                const Divider(),
                const SizedBox(height: 40),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    AppLocalizations.of(context)!.logout,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: _logout,
                ),
              ],
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
