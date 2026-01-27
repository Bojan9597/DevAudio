import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../app_layout.dart';
import '../states/layout_state.dart';
import '../l10n/generated/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();

  // State
  bool _isLoading = false;

  // Controllers

  // Colors
  static const Color _orangeColor = Color(0xFFF09A38);
  static const Color _darkGrey = Color(0xFF222222);

  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      final success = await _authService.loginWithGoogle();
      if (success && mounted) {
        final userId = await _authService.getCurrentUserId();
        if (userId != null) {
          await globalLayoutState.updateUser(userId.toString());
        }
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const AppLayout()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.googleLoginFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _orangeColor),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Logo
                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/icon/logo1.png',
                        height: 120, // Adjust size as needed
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Dev',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Audio',
                          style: TextStyle(
                            color: _orangeColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Google Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _googleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orangeColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.signInWithGoogle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
