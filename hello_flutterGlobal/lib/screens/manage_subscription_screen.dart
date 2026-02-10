import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../models/subscription.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/subscription_plan_card.dart';
import 'advanced_subscription_screen.dart';

class ManageSubscriptionScreen extends StatefulWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  State<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState extends State<ManageSubscriptionScreen> {
  final _subscriptionService = SubscriptionService();
  Subscription? _subscription;
  bool _isLoading = true;
  bool _isSubscribing = false;

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

  Future<void> _subscribe(String planId) async {
    if (_subscription?.isActive == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.alreadyMember),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubscribing = true);
    try {
      final result = await _subscriptionService.subscribe(planId);
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.subscriptionActivated,
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadSubscription();
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
        setState(() => _isSubscribing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageSubscription), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Membership Status
                  _buildCurrentMembershipSection(l10n, theme),
                  const SizedBox(height: 32),

                  // "Get the most out..." Header
                  Text(
                    l10n.getTheMostOut,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.cancelAnytime,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Plans List
                  _buildPlanList(l10n),

                  const SizedBox(height: 24),

                  // Advanced Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdvancedSubscriptionScreen(),
                          ),
                        ).then((_) => _loadSubscription());
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.advanced,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentMembershipSection(
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_subscription == null) return const SizedBox.shrink();

    final isMember = _subscription!.isActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
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
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (isMember) ...[
            Text(
              _subscription!.planDisplayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              // Assuming endDate is available and parsing logic exists or handled in localization
              _subscription!.endDate != null
                  ? l10n.renewsOn(
                      DateTime.fromMillisecondsSinceEpoch(
                        _subscription!.endDate! * 1000,
                      ).toString().split(' ')[0],
                    )
                  : l10n.active,
              style: theme.textTheme.bodyMedium,
            ),
          ] else
            Text(
              l10n.youAreNotAMember,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanList(AppLocalizations l10n) {
    // Hardcoded plan details for now, ideally fetched from server/config
    final plans = [
      {
        'id': 'test_minute',
        'title': l10n.planTestMinuteTitle,
        'price': l10n.free,
        'subtitle': l10n.planTestMinuteSubtitle,
        'features': [
          l10n.unlimitedAccess,
          l10n.listenOffline,
          l10n.expiresIn2Minutes,
        ],
        'isBestValue': false,
        'buttonText': l10n.planTestMinute,
      },
      {
        'id': 'monthly',
        'title': l10n.planMonthlyTitle,
        'price': '\$12.45/month',
        'subtitle': l10n.planMonthlySubtitle,
        'features': [l10n.unlimitedAccess, l10n.listenOffline],
        'isBestValue': false,
        'buttonText': l10n.subscribeMonthly,
      },
      {
        'id': 'yearly',
        'title': l10n.planYearlyTitle,
        'price': '\$79.99/year',
        'subtitle': l10n.planYearlySubtitle,
        'features': [
          l10n.unlimitedAccess,
          l10n.listenOffline,
          l10n.savePercent(33),
        ],
        'isBestValue': true,
        'buttonText': l10n.subscribeYearly,
      },
      {
        'id': 'lifetime',
        'title': l10n.planLifetimeTitle,
        'price': '\$199.99',
        'subtitle': l10n.planLifetimeSubtitle,
        'features': [
          l10n.unlimitedAccess,
          l10n.listenOffline,
          l10n.answerToLifeUniverseEverything,
        ],
        'isBestValue': false,
        'buttonText': l10n.getLifetimeAccess,
      },
    ];

    return Column(
      children: plans.map<Widget>((plan) {
        return _isSubscribing
            ? const Center(child: LinearProgressIndicator())
            : SubscriptionPlanCard(
                title: plan['title'] as String,
                price: plan['price'] as String,
                subtitle: plan['subtitle'] as String,
                features: plan['features'] as List<String>,
                isSelected:
                    _subscription?.planType ==
                    plan['id'], // Highlight if current plan?
                isBestValue: plan['isBestValue'] as bool,
                buttonText: plan['buttonText'] as String,
                onTap: () => _subscribe(plan['id'] as String),
              );
      }).toList(),
    );
  }
}
