import 'package:flutter/material.dart' hide Badge;
import '../models/badge.dart';
import '../l10n/generated/app_localizations.dart';

class BadgeDialog extends StatelessWidget {
  final Badge badge;

  const BadgeDialog({super.key, required this.badge});

  static void show(BuildContext context, Badge badge) {
    showDialog(
      context: context,
      builder: (context) => BadgeDialog(badge: badge),
    );
  }

  @override
  Widget build(BuildContext context) {
    // For newly earned badges, current value >= threshold.
    // If badge.currentValue is 0 (default in model if missing), we might want to hide progress or show 100%.
    // Since this dialog is "You Earned It!", we can show "Completed!".

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.badgeEarned,
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.amber,
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            badge.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.awesome),
        ),
      ],
    );
  }
}
