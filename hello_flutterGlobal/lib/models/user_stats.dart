class UserStats {
  final Map<String, int> heatmap;
  final List<GenreStat> genres;
  final List<WeeklyStat> weekly;
  final MasteryStat mastery;

  UserStats({
    required this.heatmap,
    required this.genres,
    required this.weekly,
    required this.mastery,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      heatmap: Map<String, int>.from(json['heatmap'] ?? {}),
      genres:
          (json['genres'] as List?)
              ?.map((e) => GenreStat.fromJson(e))
              .toList() ??
          [],
      weekly:
          (json['weekly'] as List?)
              ?.map((e) => WeeklyStat.fromJson(e))
              .toList() ??
          [],
      mastery: MasteryStat.fromJson(json['mastery'] ?? {}),
    );
  }
}

class GenreStat {
  final String slug;
  final String name;
  final int count;

  GenreStat({required this.slug, required this.name, required this.count});

  factory GenreStat.fromJson(Map<String, dynamic> json) {
    return GenreStat(
      slug: json['slug'] ?? '',
      name: json['name'] ?? 'Unknown',
      count: json['count'] ?? 0,
    );
  }
}

class WeeklyStat {
  final String date;
  final int minutes;
  final int dow;

  WeeklyStat({required this.date, required this.minutes, required this.dow});

  factory WeeklyStat.fromJson(Map<String, dynamic> json) {
    return WeeklyStat(
      date: json['date'] ?? '',
      minutes: json['minutes'] ?? 0,
      dow: json['dow'] ?? 0,
    );
  }
}

class MasteryStat {
  final int booksRead;
  final int booksTotal;
  final int quizzesPassed;

  MasteryStat({
    required this.booksRead,
    required this.booksTotal,
    required this.quizzesPassed,
  });

  factory MasteryStat.fromJson(Map<String, dynamic> json) {
    return MasteryStat(
      booksRead: json['books_read'] ?? 0,
      booksTotal: json['books_total'] ?? 0,
      quizzesPassed: json['quizzes_passed'] ?? 0,
    );
  }
}
