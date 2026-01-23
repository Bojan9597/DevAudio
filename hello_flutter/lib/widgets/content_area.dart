import 'package:flutter/material.dart';
import '../states/layout_state.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../repositories/book_repository.dart';
import '../repositories/category_repository.dart';
import '../services/auth_service.dart';
import '../services/download_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/category_translations.dart';

import '../screens/profile_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/upload_book_screen.dart';
import '../screens/playlist_screen.dart';
import '../screens/home_screen.dart';
import '../screens/categories_screen.dart';

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
  bool _isAdmin = false;

  // Library view mode toggles (separate from global grid/list setting)
  bool _isLibraryGridView = true;
  int? _userId;

  int _lastRefreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadBooks();
    _loadCategories(); // Load categories for filtering

    // Listen for refresh triggers
    globalLayoutState.addListener(_handleLayoutChange);
    _lastRefreshVersion = globalLayoutState.refreshVersion;
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AuthService().isAdmin();
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  @override
  void dispose() {
    globalLayoutState.removeListener(_handleLayoutChange);
    super.dispose();
  }

  void _handleLayoutChange() {
    if (globalLayoutState.refreshVersion != _lastRefreshVersion) {
      _lastRefreshVersion = globalLayoutState.refreshVersion;
      // Show loading state to indicate refresh
      if (mounted) setState(() => _isLoading = true);
      _loadBooks(); // Reload data
      _loadCategories(); // Reload categories
    }
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
      _userId = userId;

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

        if (categoryId == 'home') {
          return const HomeScreen();
        }

        if (categoryId == 'categories') {
          return const CategoriesScreen();
        }

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
          return RefreshIndicator(
            onRefresh: _loadBooks,
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
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
                          AppLocalizations.of(context)!.noBooksFoundInCategory(
                            _getCategoryTitle(categoryId),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadBooks,
          child: Container(
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
                        AppLocalizations.of(
                          context,
                        )!.booksInCategory(_getCategoryTitle(categoryId)),
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
                          ? AppLocalizations.of(context)!.switchToList
                          : AppLocalizations.of(context)!.switchToGrid,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildBookGridOrList(filteredBooks)),
              ],
            ),
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

  String _getCategoryTitle(String categoryId) {
    // Recursively search for category title by ID
    Category? findCategory(List<Category> categories, String id) {
      for (final cat in categories) {
        if (cat.id == id) return cat;
        if (cat.children != null) {
          final found = findCategory(cat.children!, id);
          if (found != null) return found;
        }
      }
      return null;
    }

    final category = findCategory(_categories, categoryId);
    if (category != null) {
      return translateCategoryTitle(
        category.title,
        AppLocalizations.of(context)!,
      );
    }
    return categoryId; // Fallback to ID if not found
  }

  Widget _buildLibraryView() {
    final favoriteBooks = _allBooks.where((b) => b.isFavorite == true).toList();

    // "My Books" = Purchased Books EXCLUDING my own uploads (if admin)
    final uploadedIds = _isAdmin
        ? _uploadedBooks.map((b) => b.id).toSet()
        : <String>{};

    final myBooks = _allBooks
        .where(
          (b) => _purchasedIds.contains(b.id) && !uploadedIds.contains(b.id),
        )
        .toList();

    // Build tabs list - only include Uploaded tab for admin
    final tabs = <Tab>[
      Tab(
        icon: const Icon(Icons.favorite),
        text: AppLocalizations.of(context)!.favorites,
      ),
      Tab(
        icon: const Icon(Icons.menu_book),
        text: AppLocalizations.of(context)!.myBooks,
      ),
      if (_isAdmin)
        Tab(
          icon: const Icon(Icons.cloud_upload),
          text: AppLocalizations.of(context)!.uploaded,
        ),
    ];

    // Build tab views - only include Uploaded view for admin
    final tabViews = <Widget>[
      // Favorites Tab with list/grid toggle and clickable hearts
      _buildFavoritesTab(favoriteBooks),
      // My Books Tab - show only downloaded books
      _buildMyBooksTab(myBooks),
      // Uploaded Tab with FAB (only for admin)
      if (_isAdmin)
        Stack(
          children: [
            _uploadedBooks.isEmpty
                ? Center(
                    child: Text(AppLocalizations.of(context)!.noUploadedBooks),
                  )
                : Padding(
                    padding: const EdgeInsets.only(
                      top: 16.0,
                      left: 16.0,
                      right: 16.0,
                      bottom: 130,
                    ),
                    child: ListView.builder(
                      itemCount: _uploadedBooks.length,
                      itemBuilder: (context, index) {
                        final book = _uploadedBooks[index];
                        return _buildMyBookTile(book);
                      },
                    ),
                  ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UploadBookScreen(),
                      ),
                    );

                    if (result == true) {
                      await Future.delayed(const Duration(milliseconds: 500));
                      globalLayoutState.triggerRefresh();
                    }
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(
                    AppLocalizations.of(context)!.uploadAudioBook,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
    ];

    return DefaultTabController(
      length: tabs.length,
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
              tabs: tabs,
            ),
          ),
          Expanded(child: TabBarView(children: tabViews)),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(List<Book> favoriteBooks) {
    if (favoriteBooks.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noFavoriteBooks));
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // View toggle row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  _isLibraryGridView ? Icons.view_list : Icons.grid_view,
                ),
                onPressed: () =>
                    setState(() => _isLibraryGridView = !_isLibraryGridView),
                tooltip: _isLibraryGridView
                    ? AppLocalizations.of(context)!.switchToList
                    : AppLocalizations.of(context)!.switchToGrid,
              ),
            ],
          ),
          Expanded(
            child: _isLibraryGridView
                ? _buildBookGridWithClickableHearts(favoriteBooks)
                : _buildBookListWithClickableHearts(favoriteBooks),
          ),
        ],
      ),
    );
  }

  Widget _buildMyBooksTab(List<Book> myBooks) {
    return FutureBuilder<List<Book>>(
      future: _filterDownloadedBooks(myBooks),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final downloadedBooks = snapshot.data ?? [];
        if (downloadedBooks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.download_done, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.noDownloadedBooks),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.booksDownloadedAppearHere,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // View toggle row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      _isLibraryGridView ? Icons.view_list : Icons.grid_view,
                    ),
                    onPressed: () => setState(
                      () => _isLibraryGridView = !_isLibraryGridView,
                    ),
                    tooltip: _isLibraryGridView
                        ? AppLocalizations.of(context)!.switchToList
                        : AppLocalizations.of(context)!.switchToGrid,
                  ),
                ],
              ),
              Expanded(
                child: _isLibraryGridView
                    ? _buildBookGrid(downloadedBooks)
                    : ListView.builder(
                        itemCount: downloadedBooks.length,
                        itemBuilder: (context, index) {
                          final book = downloadedBooks[index];
                          return _buildMyBookTile(book);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Book>> _filterDownloadedBooks(List<Book> books) async {
    final downloadService = DownloadService();
    final downloadedBooks = <Book>[];
    for (final book in books) {
      // Check if playlist is downloaded for this book (using current userId)
      final isPlaylistDownloaded = await downloadService.isPlaylistDownloaded(
        book.id,
        userId: _userId,
      );
      // Also check if book itself is downloaded
      final isBookDownloaded = await downloadService.isBookDownloaded(book.id);
      if (isPlaylistDownloaded || isBookDownloaded) {
        downloadedBooks.add(book);
      }
    }
    return downloadedBooks;
  }

  Widget _buildBookGridWithClickableHearts(List<Book> books) {
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
            return _buildBookCardWithClickableHeart(book);
          },
        );
      },
    );
  }

  Widget _buildBookListWithClickableHearts(List<Book> books) {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookListTileWithClickableHeart(book);
      },
    );
  }

  Widget _buildBookCardWithClickableHeart(Book book) {
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
                  child:
                      (book.absoluteCoverUrlThumbnail != null &&
                          book.absoluteCoverUrlThumbnail!.isNotEmpty)
                      ? Image.network(
                          book.absoluteCoverUrlThumbnail!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (ctx, _, __) => Icon(
                            Icons.menu_book,
                            size: 50,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : Icon(
                          Icons.menu_book,
                          size: 50,
                          color: Theme.of(context).colorScheme.onPrimary,
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
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
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
                          ),
                        ),
                        // Clickable heart button in title area
                        GestureDetector(
                          onTap: () => _toggleFavorite(book),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              book.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                              size: 22,
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

  Widget _buildBookListTileWithClickableHeart(Book book) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => _openPlayer(book),
        leading: Container(
          width: 50,
          height: 50,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              (book.absoluteCoverUrlThumbnail != null &&
                  book.absoluteCoverUrlThumbnail!.isNotEmpty)
              ? Image.network(
                  book.absoluteCoverUrlThumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.menu_book,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Icon(
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
            // Clickable heart button
            IconButton(
              icon: Icon(
                book.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => _toggleFavorite(book),
              tooltip: book.isFavorite
                  ? AppLocalizations.of(context)!.removeFromFavorites
                  : AppLocalizations.of(context)!.addToFavorites,
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(Book book) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.pleaseLoginToUseFavorites,
          ),
        ),
      );
      return;
    }

    // Optimistic update
    final index = _allBooks.indexWhere((b) => b.id == book.id);
    if (index == -1) return;

    setState(() {
      _allBooks[index] = _allBooks[index].copyWith(
        isFavorite: !book.isFavorite,
      );
    });

    final success = await BookRepository().toggleFavorite(
      _userId!,
      book.id,
      book.isFavorite, // Pass current state (if it was favorite, we want to remove)
    );

    if (!success) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _allBooks[index] = _allBooks[index].copyWith(
            isFavorite: book.isFavorite,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToUpdateFavorite),
          ),
        );
      }
    }
  }

  Widget _buildBookGrid(List<Book> books) {
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
        leading: Container(
          width: 50,
          height: 50,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          child:
              (book.absoluteCoverUrlThumbnail != null &&
                  book.absoluteCoverUrlThumbnail!.isNotEmpty)
              ? Image.network(
                  book.absoluteCoverUrlThumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.play_circle_fill,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : Icon(
                  Icons.play_circle_fill,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
    // Let's  void _openPlayer(Book book) async {
    // "Unified Playlist Mode": All books open as a playlist first.
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaylistScreen(book: book)),
    );
    // After returning, reload to update stats
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
                  child:
                      (book.absoluteCoverUrlThumbnail != null &&
                          book.absoluteCoverUrlThumbnail!.isNotEmpty)
                      ? Image.network(
                          book.absoluteCoverUrlThumbnail!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (ctx, _, __) => Icon(
                            Icons.menu_book,
                            size: 50,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : Icon(
                          Icons.menu_book,
                          size: 50,
                          color: Theme.of(context).colorScheme.onPrimary,
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
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
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
                          ),
                        ),
                        // Clickable heart button in title area
                        GestureDetector(
                          onTap: () => _toggleFavorite(book),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              book.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                              size: 22,
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
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              (book.absoluteCoverUrlThumbnail != null &&
                  book.absoluteCoverUrlThumbnail!.isNotEmpty)
              ? Image.network(
                  book.absoluteCoverUrlThumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.menu_book,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Icon(
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
            // Clickable heart button
            GestureDetector(
              onTap: () => _toggleFavorite(book),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  book.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
