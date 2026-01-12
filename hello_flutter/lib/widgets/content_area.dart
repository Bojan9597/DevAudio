import 'package:flutter/material.dart';
import '../states/layout_state.dart';
import '../models/book.dart';
import '../models/category.dart'; // Import Category
import '../repositories/book_repository.dart';
import '../repositories/category_repository.dart'; // Import CategoryRepository
import '../services/auth_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'player_screen.dart';

import '../screens/profile_screen.dart';
import '../screens/discover_screen.dart';

class ContentArea extends StatefulWidget {
  const ContentArea({super.key});

  @override
  State<ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<ContentArea> {
  List<Book> _allBooks = [];
  List<String> _purchasedIds = [];
  List<Book> _historyBooks = [];
  List<Book> _uploadedBooks = [];
  List<Category> _categories = []; // State for recursive filtering
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _loadCategories(); // Load categories for filtering
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryRepository().getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (e) {
      print("Error loading categories in ContentArea: $e");
    }
  }

  Future<void> _loadBooks() async {
    try {
      final books = await BookRepository().getBooks();
      final userId = await AuthService().getCurrentUserId();

      List<int> favoriteIds = [];
      List<String> purchasedIds = [];
      List<Book> history = [];
      List<Book> uploaded = [];

      if (userId != null) {
        favoriteIds = await BookRepository().getFavoriteBookIds(userId);
        purchasedIds = await BookRepository().getPurchasedBookIds(userId);
        history = await BookRepository().getListenHistory(userId);
        uploaded = await BookRepository().getMyUploadedBooks(userId.toString());
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
          _uploadedBooks = uploaded;
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

        if (categoryId == 'discover') {
          return const DiscoverScreen();
        }

        if (categoryId == 'library') {
          return _buildLibraryView();
        }

        // Filter
        final filteredBooks = BookRepository().filterBooks(
          categoryId,
          _allBooks,
          allCategories: _categories,
        );

        if (filteredBooks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 60,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No books found in "$categoryId"',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
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
      length: 3,
      child: Column(
        children: [
          Container(
            color:
                Theme.of(context).cardTheme.color ??
                Theme.of(context).cardColor,
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: [
                Tab(
                  icon: const Icon(Icons.favorite),
                  text: AppLocalizations.of(context)!.favorites,
                ),
                Tab(
                  icon: const Icon(Icons.menu_book),
                  text: AppLocalizations.of(context)!.myBooks,
                ),
                const Tab(icon: Icon(Icons.cloud_upload), text: 'Uploaded'),
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
                        padding: const EdgeInsets.all(16.0),
                        child: ListView.builder(
                          itemCount: myBooks.length,
                          itemBuilder: (context, index) {
                            final book = myBooks[index];
                            return _buildMyBookTile(book);
                          },
                        ),
                      ),
                // Uploaded Tab
                _uploadedBooks.isEmpty
                    ? const Center(child: Text('No uploaded books'))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView.builder(
                          itemCount: _uploadedBooks.length,
                          itemBuilder: (context, index) {
                            // Reuse MyBookTile style for consistency
                            final book = _uploadedBooks[index];
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
        leading: Icon(
          Icons.play_circle_fill,
          color: Theme.of(context).colorScheme.primary,
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
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 50,
                        color: Theme.of(context).colorScheme.onPrimary,
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
                              style: TextStyle(
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
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.menu_book,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
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
