class Badge {
  final int id;
  final String category;
  final String name;
  final String description;
  final String code;
  final bool isEarned;
  final DateTime? earnedAt;

  Badge({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.code,
    required this.isEarned,
    this.earnedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      category: json['category'],
      name: json['name'],
      description: json['description'],
      code: json['code'],
      isEarned: json['isEarned'],
      earnedAt: json['earnedAt'] != null
          ? DateTime.tryParse(json['earnedAt'].toString())
          : null,
    );
  }
}
