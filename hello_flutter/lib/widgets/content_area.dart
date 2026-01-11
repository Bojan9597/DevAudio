import 'package:flutter/material.dart';
import '../states/layout_state.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../services/auth_service.dart';
import 'player_screen.dart';

import '../screens/profile_screen.dart';

class ContentArea extends StatefulWidget {
  const ContentArea({super.key});

  @override
  State<ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<ContentArea> {
  List<Book> _allBooks = [];
  List<String> _purchasedIds = [];
  List<Book> _historyBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await BookRepository().getBooks();
      final userId = await AuthService().getCurrentUserId();

      List<int> favoriteIds = [];
      List<String> purchasedIds = [];
      List<Book> history = [];

      if (userId != null) {
        favoriteIds = await BookRepository().getFavoriteBookIds(userId);
        purchasedIds = await BookRepository().getPurchasedBookIds(userId);
        history = await BookRepository().getListenHistory(userId);
      }

      // Map favorites and merge history progress
      final updatedBooks = books.map((book) {
        final isFav = favoriteIds.contains(int.tryParse(book.id) ?? -1);

        // Find if we have history for this book to get progress
        final historyBook = history.firstWhere(
          (h) => h.id == book.id,
          orElse: () => book, // fallback to current book (no progress)
        );

        return book.copyWith(
          isFavorite: isFav,
          lastPosition: historyBook.lastPosition,
          durationSeconds: historyBook.durationSeconds,
          lastAccessed: historyBook.lastAccessed,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _allBooks = updatedBooks;
          _purchasedIds = purchasedIds;
          _historyBooks = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading books: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLayoutState,
      builder: (context, child) {
        final categoryId = globalLayoutState.selectedCategoryId;

        if (categoryId == 'profile') {
          return const ProfileScreen();
        }

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (categoryId == 'library') {
          return _buildLibraryView();
        }

        final filteredBooks = BookRepository().filterBooks(
          categoryId,
          _allBooks,
        );

        if (filteredBooks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.book_outlined, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No books found in "$categoryId"',
                  style: const TextStyle(color: Colors.grey, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Books in $categoryId',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      globalLayoutState.isGridView
                          ? Icons.view_list
                          : Icons.grid_view,
                    ),
                    onPressed: () => globalLayoutState.toggleViewMode(),
                    tooltip: globalLayoutState.isGridView
                        ? 'Switch to List'
                        : 'Switch to Grid',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildBookGridOrList(filteredBooks)),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return "0:00";
    final d = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final sec = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${twoDigits(d.inHours)}:' : ''}$minutes:$sec";
  }

  Widget _buildLibraryView() {
    final favoriteBooks = _allBooks.where((b) => b.isFavorite == true).toList();

    // "My Books" = Purchased Books
    final myBooks = _allBooks
        .where((b) => _purchasedIds.contains(b.id))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueAccent,
              tabs: [
                Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
                Tab(icon: Icon(Icons.menu_book), text: 'My Books'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Favorites Tab
                favoriteBooks.isEmpty
                    ? const Center(child: Text('No favorite books yet'))
                    : Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: _buildBookGridOrList(favoriteBooks),
                      ),
                // My Books Tab
                myBooks.isEmpty
                    ? const Center(child: Text('No purchased books'))
                    : Padding(
                        padding: const EdgeInsets.all(
                          16.0,
                        ), // Match profile padding
                        child: ListView.builder(
                          itemCount: myBooks.length,
                          itemBuilder: (context, index) {
                            final book = myBooks[index];
                            return _buildMyBookTile(book);
                          },
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyBookTile(Book book) {
    final position = book.lastPosition ?? 0;
    final duration = book.durationSeconds ?? 1;
    final percent = (duration > 0 ? (position / duration * 100) : 0)
        .clamp(0, 100)
        .toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(
          Icons.play_circle_fill,
          color: Colors.blueAccent,
          size: 40,
        ),
        title: Text(
          book.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.author),
            if (position > 0)
              Text(
                'Progress: ${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Text('$percent%'),
        onTap: () => _openPlayer(book),
      ),
    );
  }

  Widget _buildBookGridOrList(List<Book> books) {
    if (globalLayoutState.isGridView) {
      return LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = (constraints.maxWidth / 200).toInt();
          if (crossAxisCount < 2) crossAxisCount = 2;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.75,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return _buildBookCard(book);
            },
          );
        },
      );
    } else {
      return ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return _buildBookListTile(book);
        },
      );
    }
  }

  void _openPlayer(Book book) async {
    // We need to pass the most up-to-date book state (fav status)
    // Actually, passing 'book' is fine, but if we toggle fav in player, we want to reflect that back here?
    // PlayerScreen can accept a callback or we reload on close?
    // Let's reload on close for simplicity.

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerScreen(book: book),
    );
    // After player closes, reload to refresh favorites/progress
    _loadBooks();
  }

  Widget _buildBookCard(Book book) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPlayer(book),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(color: Colors.blueAccent.shade100),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.menu_book,
                        size: 50,
                        color: Colors.white,
                      ),
                      if (book.isFavorite)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxHeight < 35) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              book.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              book.author,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookListTile(Book book) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => _openPlayer(book),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blueAccent.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.menu_book, color: Colors.white),
        ),
        title: Text(
          book.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(book.author),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (book.isFavorite)
              const Icon(Icons.favorite, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
