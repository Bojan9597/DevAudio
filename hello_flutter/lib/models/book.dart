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
  final bool isFavorite;
  final String? postedBy;
  final String? description;
  final double? price;
  final String? postedByUserId;
  final String? coverUrl;
  final bool isPlaylist;

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
    this.isFavorite = false,
    this.postedBy,
    this.description,
    this.price,
    this.postedByUserId,
    this.coverUrl,
    this.isPlaylist = false,
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
      isFavorite: json['isFavorite'] as bool? ?? false,
      postedBy: json['postedBy'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      postedByUserId: json['postedByUserId'] as String?,
      coverUrl: json['coverUrl'] as String?,
    );
  }

  Book copyWith({
    bool? isFavorite,
    int? lastPosition,
    int? durationSeconds,
    DateTime? lastAccessed,
    String? postedBy,
    String? description,
    double? price,
    String? postedByUserId,
    String? coverUrl,
  }) {
    return Book(
      id: id,
      title: title,
      author: author,
      audioUrl: audioUrl,
      categoryId: categoryId,
      subcategoryIds: subcategoryIds,
      lastPosition: lastPosition ?? this.lastPosition,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isFavorite: isFavorite ?? this.isFavorite,
      postedBy: postedBy ?? this.postedBy,
      description: description ?? this.description,
      price: price ?? this.price,
      postedByUserId: postedByUserId ?? this.postedByUserId,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }
}
