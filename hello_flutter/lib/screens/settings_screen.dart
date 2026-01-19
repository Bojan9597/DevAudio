import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'upload_book_screen.dart';
import '../states/layout_state.dart';
import '../l10n/generated/app_localizations.dart';

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

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmNewPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isObscureCurrent = true;
    bool isObscureNew = true;
    bool isObscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            isObscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              isObscureCurrent = !isObscureCurrent;
                            });
                          },
                        ),
                      ),
                      obscureText: isObscureCurrent,
                      validator: (v) =>
                          v!.isEmpty ? 'Enter current password' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            isObscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              isObscureNew = !isObscureNew;
                            });
                          },
                        ),
                      ),
                      obscureText: isObscureNew,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter new password';
                        String pattern =
                            r'''^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_+={}\[\]:;"'<>,.?/\\|~-]).{8,}$''';
                        RegExp regex = RegExp(pattern);
                        if (!regex.hasMatch(v)) {
                          return 'Min 8 chars, 1 Upper, 1 Number, 1 Special';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmNewPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            isObscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              isObscureConfirm = !isObscureConfirm;
                            });
                          },
                        ),
                      ),
                      obscureText: isObscureConfirm,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Confirm new password';
                        if (v != newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context); // Close dialog first
                      await _changePassword(
                        currentPasswordController.text,
                        newPasswordController.text,
                      );
                    }
                  },
                  child: const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changePassword(String current, String newPass) async {
    setState(() => _isLoading = true);
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId != null) {
        await _authService.changePassword(userId, current, newPass);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password changed successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
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
        title: const Text('Settings'),
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
                              child: const Text('English (US)'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('es'));
                                Navigator.pop(context);
                              },
                              child: const Text('Español'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('sr'));
                                Navigator.pop(context);
                              },
                              child: const Text('Srpski'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('fr'));
                                Navigator.pop(context);
                              },
                              child: const Text('Français'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setLocale(const Locale('de'));
                                Navigator.pop(context);
                              },
                              child: const Text('Deutsch'),
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
                              child: const Text('System'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setThemeMode(ThemeMode.light);
                                Navigator.pop(context);
                              },
                              child: const Text('Light'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                globalLayoutState.setThemeMode(ThemeMode.dark);
                                Navigator.pop(context);
                              },
                              child: const Text('Dark'),
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
                    title: const Text('Upload Audio Book'),
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
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: Text(AppLocalizations.of(context)!.changePassword),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showChangePasswordDialog,
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
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System';
    }
  }

  String _getLanguageName(String? code) {
    switch (code) {
      case 'es':
        return 'Español';
      case 'sr':
        return 'Srpski';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return 'English (US)';
    }
  }
}
