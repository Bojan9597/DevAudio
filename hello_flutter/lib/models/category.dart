class Category {
  final String id;
  final String title;
  final List<Category>? children;
  final bool hasBooks;

  const Category({
    required this.id,
    required this.title,
    this.children,
    this.hasBooks = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      title: json['title'] as String,
      hasBooks: json['hasBooks'] as bool? ?? false,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
