class Subscription {
  final int? id;
  final int userId;
  final String planType; // 'monthly', 'yearly', 'lifetime'
  final String status; // 'active', 'expired', 'cancelled', 'none'
  final DateTime? startDate;
  final DateTime? endDate;
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

  /// Check if subscription is expiring soon (within 7 days)
  bool get isExpiringSoon {
    if (endDate == null || !isActive) return false;
    final daysUntilExpiry = endDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }

  /// Get human-readable plan name
  String get planDisplayName {
    switch (planType) {
      case 'test_minute':
        return '1 Minute Test';
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
    return Subscription(
      id: json['id'],
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id'].toString()) ?? 0,
      planType: json['plan_type'] ?? 'monthly',
      status: json['status'] ?? 'none',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())
          : null,
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
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
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
