import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../utils/api_constants.dart';
import '../l10n/generated/app_localizations.dart';

class SupportDialog extends StatefulWidget {
  const SupportDialog({super.key});

  @override
  State<SupportDialog> createState() => _SupportDialogState();
}

class _SupportDialogState extends State<SupportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _authService = AuthService();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSending = true);

    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${_authService.baseUrl}/send-support-email'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
        },
        body: json.encode({'message': _messageController.text.trim()}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Success
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.messageSentSuccessfully,
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Error
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to send message');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close dialog first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.support_agent, color: Colors.blue),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              AppLocalizations.of(context)!.contactSupport,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.supportMessageDescription,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  maxLines: 8,
                  maxLength: 5000,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.yourMessage,
                    hintText: AppLocalizations.of(context)!.describeIssue,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                    errorMaxLines: 2,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context)!.enterMessage;
                    }
                    if (value.trim().length < 10) {
                      return AppLocalizations.of(context)!.messageTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.accountInfoIncluded,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendMessage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(AppLocalizations.of(context)!.send),
        ),
      ],
    );
  }
}
