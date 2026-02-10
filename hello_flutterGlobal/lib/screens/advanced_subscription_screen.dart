import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../models/subscription.dart';
import '../l10n/generated/app_localizations.dart';

class AdvancedSubscriptionScreen extends StatefulWidget {
  const AdvancedSubscriptionScreen({super.key});

  @override
  State<AdvancedSubscriptionScreen> createState() =>
      _AdvancedSubscriptionScreenState();
}

class _AdvancedSubscriptionScreenState
    extends State<AdvancedSubscriptionScreen> {
  final _subscriptionService = SubscriptionService();
  Subscription? _subscription;
  bool _isLoading = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() => _isLoading = true);
    final sub = await _subscriptionService.getSubscriptionStatus(
      forceRefresh: true,
    );
    if (mounted) {
      setState(() {
        _subscription = sub;
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAutoRenewal() async {
    final l10n = AppLocalizations.of(context)!;

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.turnOffAutoRenewQuestion),
        content: Text(l10n.subscriptionWillRemainActive),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepSubscription),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.turnOff),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    try {
      final result = await _subscriptionService.cancelSubscription();
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.subscriptionCanceled),
              backgroundColor: Colors.green,
            ),
          );
          _loadSubscription();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Cancellation failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.advanced), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(l10n, theme),
                  const SizedBox(height: 32),

                  if (_subscription?.isActive == true) ...[
                    // Cancel Auto-Renewal Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isCancelling ? null : _cancelAutoRenewal,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.red,
                        ),
                        child: _isCancelling
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n.cancelAutoRenewal,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        l10n.subscriptionWillRemainActive,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else ...[
                    // Get Membership Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context), // Go back to manage screen
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors
                              .amber[700], // Updated to match Home/PlanCard
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.getAMembership,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(AppLocalizations l10n, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.currentMembership,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_subscription?.isActive == true) ...[
            Text(
              _subscription!.planDisplayName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.active,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailRow(
              l10n.started,
              _subscription!.startDate != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      _subscription!.startDate! * 1000,
                    ).toString().split(' ')[0]
                  : '-',
              theme,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              l10n.expires,
              _subscription!.endDate != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      _subscription!.endDate! * 1000,
                    ).toString().split(' ')[0]
                  : '-',
              theme,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              l10n.autoRenewal,
              _subscription!.autoRenew ? l10n.on : l10n.off,
              theme,
            ),
          ] else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.youAreNotAMember,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.subscribeToGetAccess,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
