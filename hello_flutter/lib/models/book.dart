import '../utils/url_helper.dart';

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
  final String? coverUrlThumbnail;
  final bool isPlaylist;
  final bool isEncrypted;
  final double averageRating;
  final int ratingCount;
  final String? pdfUrl;
  final bool isPremium;

  /// Returns the absolute cover URL with base URL prepended if needed
  String get absoluteCoverUrl => ensureAbsoluteUrl(coverUrl);

  /// Returns the absolute thumbnail URL with base URL prepended if needed
  String get absoluteCoverUrlThumbnail =>
      ensureAbsoluteUrl(coverUrlThumbnail ?? coverUrl);

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
    this.coverUrlThumbnail,
    this.isPlaylist = false,
    this.isEncrypted = false,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.pdfUrl,
    this.isPremium = false,
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
      coverUrlThumbnail: json['coverUrlThumbnail'] as String?,
      isPlaylist: json['isPlaylist'] as bool? ?? false,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      pdfUrl: json['pdfUrl'] as String?,
      isPremium: (json['premium'] as int?) == 1 || (json['isPremium'] as bool? ?? false),
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
    bool? isEncrypted,
    String? pdfUrl,
    bool? isPremium,
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
      coverUrlThumbnail: coverUrlThumbnail,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      averageRating: averageRating,
      ratingCount: ratingCount,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
