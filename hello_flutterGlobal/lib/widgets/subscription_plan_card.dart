import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isBestValue;
  final String buttonText;

  const SubscriptionPlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.subtitle,
    required this.features,
    required this.isSelected,
    required this.onTap,
    this.isBestValue = false,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    // Hardcoded colors to match "Premium Plus" dark theme style from image
    final backgroundColor = const Color(0xFF0C1929); // Dark blue/black
    final textColor = Colors.white;
    final buttonColor = Colors.amber[700]; // Matched to Home Screen button

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Optional "Best Value" / Top Tag
          if (isBestValue)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Text(
                'BEST VALUE', // Localize if needed, but "30 DAYS FREE" in image was hardcoded
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          else
            const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                if (isBestValue) const SizedBox(height: 10),
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Price
                Text(
                  price,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle (e.g. "after free trial")
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                // Features
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Legal / disclaimer text
                Text(
                  AppLocalizations.of(context)!.legalDisclaimer,
                  style: TextStyle(
                    color: textColor.withOpacity(0.5),
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Subscribe Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor, // The "yellow" button
                      foregroundColor: Colors.black, // Dark text on yellow
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
