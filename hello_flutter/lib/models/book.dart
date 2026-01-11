class Book {
  final String id;
  final String title;
  final String author;
  final String audioUrl;
  final String categoryId;
  final List<String> subcategoryIds;
  final int? lastPosition;
  final DateTime? lastAccessed;
  final int? durationSeconds;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.audioUrl,
    required this.categoryId,
    required this.subcategoryIds,
    this.lastPosition,
    this.lastAccessed,
    this.durationSeconds,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      audioUrl: json['audioUrl'] as String? ?? '',
      categoryId: json['categoryId'] as String,
      subcategoryIds:
          (json['subcategoryIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastPosition: json['lastPosition'] as int?,
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.tryParse(json['lastAccessed'] as String)
          : null,
      durationSeconds: json['duration'] as int?,
    );
  }
}
