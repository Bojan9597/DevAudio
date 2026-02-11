class Book {
  final String id;
  final String title;
  final int? backgroundMusicId;

  Book({required this.id, required this.title, this.backgroundMusicId});

  Book copyWith({String? id, String? title, int? backgroundMusicId}) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      backgroundMusicId: backgroundMusicId ?? this.backgroundMusicId,
    );
  }

  @override
  String toString() => 'Book(id: $id, bg: $backgroundMusicId)';
}

void main() {
  // Test 1: Initial null, update to value
  var b1 = Book(id: '1', title: 'Test');
  print('Initial: $b1');

  var b2 = b1.copyWith(backgroundMusicId: 2);
  print('Updated 2: $b2');

  if (b2.backgroundMusicId != 2) {
    print('FAIL: Update to 2 failed');
  } else {
    print('PASS: Update to 2 succeeded');
  }

  // Test 2: Value to different value
  var b3 = b2.copyWith(backgroundMusicId: 3);
  print('Updated 3: $b3');

  // Test 3: Attempt to clear (pass null) - known issue with ?? syntax
  // var b4 = b3.copyWith(backgroundMusicId: null);
  // print('Updated null: $b4');
  // Expect: 3 because null ?? 3 -> 3.
}
