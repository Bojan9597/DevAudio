class Subscription {
  final int? id;
  final int userId;
  final String planType; // 'monthly', 'yearly', 'lifetime'
  final String status; // 'active', 'expired', 'cancelled', 'none'
  final int? startDate;
  final int? endDate;
  final bool autoRenew;
  final bool isActive;

  Subscription({
    this.id,
    required this.userId,
    required this.planType,
    required this.status,
    this.startDate,
    this.endDate,
    this.autoRenew = true,
    required this.isActive,
  });

  /// Check if subscription grants access to content
  bool get hasAccess => isActive;

  /// Check if subscription is expiring soon (within 1 day)
  bool get isExpiringSoon {
    if (endDate == null || !isActive) return false;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final secondsUntilExpiry = endDate! - nowSeconds;
    final daysUntilExpiry = secondsUntilExpiry / (24 * 3600);
    return daysUntilExpiry <= 1 && daysUntilExpiry > 0;
  }

  /// Get human-readable plan name
  String get planDisplayName {
    switch (planType) {
      case 'test_minute':
        return '2 Minute Test';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      case 'lifetime':
        return 'Lifetime';
      default:
        return planType;
    }
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    // Parse timestamps safely (handle if they come as strings or ints)
    int? parseTimestamp(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is String) {
        // Try parsing as int first, fallback to ISO if needed?
        // User said "use timestamp", so backend sends int.
        return int.tryParse(val);
      }
      return null;
    }

    return Subscription(
      id: json['id'],
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id'].toString()) ?? 0,
      planType: json['plan_type'] ?? 'monthly',
      status: json['status'] ?? 'none',
      startDate: parseTimestamp(json['start_date']),
      endDate: parseTimestamp(json['end_date']),
      autoRenew: json['auto_renew'] ?? true,
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_type': planType,
      'status': status,
      'start_date': startDate,
      'end_date': endDate,
      'auto_renew': autoRenew,
      'is_active': isActive,
    };
  }

  /// Create a "no subscription" instance
  factory Subscription.none(int userId) {
    return Subscription(
      userId: userId,
      planType: 'none',
      status: 'none',
      isActive: false,
    );
  }
}
