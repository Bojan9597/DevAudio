import 'package:flutter/material.dart';
import '../services/subscription_service.dart';

class SubscriptionBottomSheet extends StatefulWidget {
  final VoidCallback onSubscribed;

  const SubscriptionBottomSheet({super.key, required this.onSubscribed});

  @override
  State<SubscriptionBottomSheet> createState() => _SubscriptionBottomSheetState();
}

class _SubscriptionBottomSheetState extends State<SubscriptionBottomSheet> {
  String _selectedPlan = 'monthly';
  bool _isLoading = false;

  final Map<String, Map<String, String>> _planDetails = {
    'test_minute': {
      'title': '1 Minute Test',
      'price': 'FREE',
      'subtitle': 'For testing - expires in 1 minute',
    },
    'monthly': {
      'title': 'Monthly',
      'price': '\$9.99/month',
      'subtitle': 'Billed monthly, cancel anytime',
    },
    'yearly': {
      'title': 'Yearly',
      'price': '\$79.99/year',
      'subtitle': 'Save 33% - Best value!',
    },
    'lifetime': {
      'title': 'Lifetime',
      'price': '\$199.99',
      'subtitle': 'One-time payment, forever access',
    },
  };

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);

    try {
      final result = await SubscriptionService().subscribe(_selectedPlan);

      if (result['success'] == true) {
        widget.onSubscribed();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription activated! Enjoy unlimited access.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Subscription failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Icon(
              Icons.star_rounded,
              size: 48,
              color: Colors.amber.shade600,
            ),
            const SizedBox(height: 12),
            Text(
              'Unlock All Audiobooks',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to get unlimited access to our entire library',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Plan options
            ..._planDetails.entries.map((entry) =>
                _buildPlanTile(entry.key, entry.value, theme)),

            const SizedBox(height: 24),

            // Subscribe button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _subscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Subscribe Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Cancel button
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),

            // Safe area padding for bottom
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTile(
      String value, Map<String, String> details, ThemeData theme) {
    final isSelected = _selectedPlan == value;
    final isDark = theme.brightness == Brightness.dark;
    final isYearly = value == 'yearly';

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Plan details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        details['title']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (isYearly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BEST VALUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details['subtitle']!,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Price
            Text(
              details['price']!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
