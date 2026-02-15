import 'package:flutter/material.dart';
import '../states/layout_state.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../repositories/book_repository.dart';
import '../services/auth_service.dart';
import '../services/download_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/category_translations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/api_constants.dart';

import '../screens/profile_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/upload_book_screen.dart';
import '../screens/playlist_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/reels_screen.dart';
import 'category_details_view.dart';

class ContentArea extends StatefulWidget {
  const ContentArea({super.key});

  /// Invalidate the library cache so "My Books" refreshes immediately
  /// Call this after downloading a book
  static void invalidateLibraryCache() {
    _ContentAreaState.invalidateCache();
  }

  @override
  State<ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<ContentArea> {
  // Static cache for library data (30 seconds)
  static const Duration _cacheDuration = Duration(seconds: 30);
  static DateTime? _lastFetchTime;
  static List<Book> _cachedAllBooks = [];
  static List<String> _cachedPurchasedIds = [];
  static List<Book> _cachedHistoryBooks = [];
  static List<Book> _cachedUploadedBooks = [];
  static bool _cachedIsSubscribed = false;

  /// Invalidate the library cache so it refreshes on next view
  /// Call this after downloading a book so "My Books" updates immediately
  static void invalidateCache() {
    _lastFetchTime = null;
  }

  List<Book> _allBooks = [];
  List<String> _purchasedIds = [];
  List<Book> _historyBooks = [];
  List<Book> _uploadedBooks = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isSubscribed = false;

  // Library view mode toggles (separate from global grid/list setting)
  bool _isLibraryGridView = true;
  int? _userId;

  int _lastRefreshVersion = 0;
  String _lastCategoryId = '';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    // Restore from cache if valid, otherwise load fresh
    if (_isCacheValid()) {
      _restoreFromCache();
    } else {
      _loadBooks();
    }

    // Listen for refresh triggers
    globalLayoutState.addListener(_handleLayoutChange);
    _lastRefreshVersion = globalLayoutState.refreshVersion;
    _lastCategoryId = globalLayoutState.selectedCategoryId;

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  /// Check if cache is valid (within 30 seconds)
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    final cacheAge = DateTime.now().difference(_lastFetchTime!);
    return cacheAge < _cacheDuration && _cachedAllBooks.isNotEmpty;
  }

  /// Restore data from static cache
  void _restoreFromCache() {
    setState(() {
      _allBooks = List.from(_cachedAllBooks);
      _purchasedIds = List.from(_cachedPurchasedIds);
      _historyBooks = List.from(_cachedHistoryBooks);
      _uploadedBooks = List.from(_cachedUploadedBooks);
      _isSubscribed = _cachedIsSubscribed;
      _isLoading = false;
    });
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AuthService().isAdmin();
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    globalLayoutState.removeListener(_handleLayoutChange);
    super.dispose();
  }

  void _handleLayoutChange() {
    bool shouldReload = false;
    bool forceRefresh = false;

    // Check for explicit refresh trigger (pull-to-refresh or manual)
    if (globalLayoutState.refreshVersion != _lastRefreshVersion) {
      _lastRefreshVersion = globalLayoutState.refreshVersion;
      shouldReload = true;
      forceRefresh = true; // User explicitly requested refresh
    }
    // Check if switching TO library from something else
    // Use cache if available, otherwise load
    if (globalLayoutState.selectedCategoryId == 'library' &&
        _lastCategoryId != 'library') {
      if (!_isCacheValid()) {
        shouldReload = true;
      }
    }
    _lastCategoryId = globalLayoutState.selectedCategoryId;

    if (shouldReload) {
      if (mounted) setState(() => _isLoading = true);
      _loadBooks(forceRefresh: forceRefresh);
    }
  }

  Future<void> _loadBooks({bool forceRefresh = false}) async {
    // Skip if cache is valid and not forcing refresh
    if (!forceRefresh && _isCacheValid()) {
      _restoreFromCache();
      return;
    }

    try {
      // Single API call gets everything we need!
      final libraryData = await BookRepository().getLibraryData();

      final List<Book> allBooks = libraryData['allBooks'] as List<Book>;
      final List<String> purchasedIds =
          libraryData['purchasedIds'] as List<String>;
      final List<Book> history = libraryData['listenHistory'] as List<Book>;
      final List<Book> uploaded = libraryData['uploadedBooks'] as List<Book>;

      final userId = await AuthService().getCurrentUserId();
      _userId = userId;

      // Merge history progress into all books
      final updatedBooks = allBooks.map((book) {
        // Find if we have history for this book to get progress
        final historyBook = history.firstWhere(
          (h) => h.id == book.id,
          orElse: () => book, // fallback to current book (no progress)
        );

        return book.copyWith(
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
          _isSubscribed = libraryData['isSubscribed'] as bool? ?? false;
          _isLoading = false;
        });

        // Update cache
        _lastFetchTime = DateTime.now();
        _cachedAllBooks = List.from(updatedBooks);
        _cachedPurchasedIds = List.from(purchasedIds);
        _cachedHistoryBooks = List.from(history);
        _cachedUploadedBooks = List.from(uploaded);
        _cachedIsSubscribed = _isSubscribed;
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

        if (categoryId == 'categories' || categoryId == 'discover') {
          return const DiscoverScreen();
        }

        if (categoryId == 'profile') {
          return const ProfileScreen();
        }

        if (categoryId == 'reels') {
          return const ReelsScreen();
        }

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (categoryId == 'library') {
          return _buildLibraryView();
        }

        // Filter by category
        var filteredBooks = BookRepository().filterBooks(
          categoryId,
          _allBooks,
          allCategories: globalLayoutState.categories,
        );

        return CategoryDetailsView(
          key: Key(categoryId),
          categoryId: categoryId,
          categoryTitle: _getCategoryTitle(categoryId),
          books: filteredBooks,
          onRefresh: _loadBooks,
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

    final category = findCategory(globalLayoutState.categories, categoryId);
    if (category != null) {
      return translateCategoryTitle(
        category.title,
        AppLocalizations.of(context)!,
      );
    }
    return categoryId; // Fallback to ID if not found
  }

  Widget _buildLibraryView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    bool matchesSearch(Book b) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return b.title.toLowerCase().contains(query) ||
          b.author.toLowerCase().contains(query);
    }

    final favoriteBooks = _allBooks
        .where((b) => b.isFavorite == true && matchesSearch(b))
        .toList();

    // "My Books" = Purchased Books EXCLUDING my own uploads (if admin)
    final uploadedIds = _isAdmin
        ? _uploadedBooks.map((b) => b.id).toSet()
        : <String>{};

    // FIX: For "My Books" (Downloads), we should check ALL books for download status,
    // not just the ones the server says we "purchased". This ensures books locally
    // downloaded (e.g. from previous subscription) still appear.
    // Also filter by search query
    final booksToCheckForDownloads = _allBooks
        .where((b) => !uploadedIds.contains(b.id) && matchesSearch(b))
        .toList();

    // Filter history by search query
    final historyFiltered = _historyBooks.where(matchesSearch).toList();

    // Filter uploaded books by search query
    final uploadedFiltered = _uploadedBooks.where(matchesSearch).toList();

    // Build tabs list - only include Uploaded tab for admin
    final tabs = <Tab>[
      Tab(
        icon: const Icon(Icons.favorite),
        text: AppLocalizations.of(context)!.favorites,
      ),
      Tab(
        icon: const Icon(Icons.play_circle_outline),
        text: AppLocalizations.of(context)!.continueListening,
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
    // Each tab is wrapped with RefreshIndicator for pull-to-refresh
    final tabViews = <Widget>[
      // Favorites Tab with list/grid toggle and clickable hearts
      RefreshIndicator(
        onRefresh: () => _loadBooks(forceRefresh: true),
        child: _buildFavoritesTab(favoriteBooks),
      ),
      // Continue Listening Tab - show books with listening progress
      RefreshIndicator(
        onRefresh: () => _loadBooks(forceRefresh: true),
        child: _buildContinueListeningTab(historyFiltered),
      ),
      // My Books Tab - show only downloaded books
      RefreshIndicator(
        onRefresh: () => _loadBooks(forceRefresh: true),
        child: _buildMyBooksTab(booksToCheckForDownloads),
      ),
      // Uploaded Tab with FAB (only for admin)
      if (_isAdmin)
        RefreshIndicator(
          onRefresh: () => _loadBooks(forceRefresh: true),
          child: Stack(
            children: [
              uploadedFiltered.isEmpty
                  ? ListView(
                      // Need scrollable for RefreshIndicator to work
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.noUploadedBooks,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.only(
                        top: 16.0,
                        left: 16.0,
                        right: 16.0,
                        bottom: 130,
                      ),
                      child: ListView.builder(
                        itemCount: uploadedFiltered.length,
                        itemBuilder: (context, index) {
                          final book = uploadedFiltered[index];
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
        ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          // Search Header (Icon or Expanded Bar)
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isSearchExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        autofocus: true,
                        controller: _searchController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.searchForBooks,
                          hintStyle: TextStyle(
                            color: textColor.withOpacity(0.5),
                          ),
                          prefixIcon: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: textColor.withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(() {
                                _isSearchExpanded = false;
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 0,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(Icons.search, color: textColor),
                        onPressed: () {
                          setState(() {
                            _isSearchExpanded = true;
                          });
                        },
                      ),
                    ),
            ),
          ),
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Text(AppLocalizations.of(context)!.noFavoriteBooks),
            ),
          ),
        ],
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
                ? _buildBookGrid(favoriteBooks)
                : ListView.builder(
                    itemCount: favoriteBooks.length,
                    itemBuilder: (context, index) {
                      final book = favoriteBooks[index];
                      return _buildBookListTile(book);
                    },
                  ),
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
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.download_done,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.noDownloadedBooks),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.booksDownloadedAppearHere,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildContinueListeningTab(List<Book> historyBooks) {
    if (historyBooks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.noListeningHistoryTitle),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.booksYouStartListeningAppearHere,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
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
                ? _buildBookGrid(historyBooks)
                : ListView.builder(
                    itemCount: historyBooks.length,
                    itemBuilder: (context, index) {
                      final book = historyBooks[index];
                      return _buildMyBookTile(book);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<List<Book>> _filterDownloadedBooks(List<Book> books) async {
    final downloadService = DownloadService();

    // Parallelize checks for performance
    // Returns List<Book?> where null means not downloaded
    final results = await Future.wait(
      books.map((book) async {
        // Get saved playlist JSON for this book
        final playlistData = await downloadService.getPlaylistJson(
          book.id,
          userId: _userId,
        );

        if (playlistData != null) {
          // Extract playlist tracks from saved JSON
          final List<Map<String, dynamic>>? playlist =
              (playlistData['tracks'] as List?)?.cast<Map<String, dynamic>>();

          if (playlist != null && playlist.isNotEmpty) {
            // Check if ALL tracks are actually downloaded on disk
            final isFullyDownloaded = await downloadService
                .isPlaylistFullyDownloaded(
                  playlist,
                  userId: _userId,
                  bookId: book.id,
                );

            if (isFullyDownloaded) return book;
          }
        }

        // Fallback for single-track books: check if book itself is downloaded
        final isBookDownloaded = await downloadService.isBookDownloaded(
          book.id,
          userId: _userId,
          bookId: book.id,
        );

        if (isBookDownloaded) return book;

        return null;
      }),
    );

    // Filter out nulls
    return results.whereType<Book>().toList();
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
            childAspectRatio: 0.6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 0,
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
                  headers: ApiConstants.imageHeaders,
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

  void _openPlayer(Book book) async {
    // We need to pass the most up-to-date book state (fav status)
    // Actually, passing 'book' is fine, but if we toggle fav in player, we want to reflect that back here?
    // PlayerScreen can accept a callback or we reload on close?
    // Let's  void _openPlayer(Book book) async {
    // "Unified Playlist Mode": All books open as a playlist first.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistScreen(
          book: book,
          resumeFromTrackId: book.currentPlaylistItemId,
        ),
      ),
    );
    // After returning, reload to update stats
    _loadBooks();
  }

  Widget _buildBookCard(Book book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: () => _openPlayer(book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.absoluteCoverUrlThumbnail.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: book.absoluteCoverUrlThumbnail!,
                      httpHeaders: ApiConstants.imageHeaders,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorWidget: (context, url, error) => Container(
                        color: textColor.withOpacity(0.1),
                        child: Icon(Icons.book, size: 40, color: textColor),
                      ),
                    )
                  : Container(
                      color: textColor.withOpacity(0.1),
                      child: Center(
                        child: Icon(Icons.book, size: 40, color: textColor),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          _buildDurationText(book, textColor),
          if (book.isPremium && !_isSubscribed)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Premium',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          const SizedBox(height: 4),
          _buildStarRating(book, textColor),
        ],
      ),
    );
  }

  String _formatBookDuration(int? totalSeconds) {
    if (totalSeconds == null || totalSeconds == 0) return '';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes} min';
  }

  Widget _buildDurationText(Book book, Color textColor) {
    final durationText = _formatBookDuration(book.durationSeconds);
    if (durationText.isEmpty) return const SizedBox.shrink();
    return Text(
      durationText,
      style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6)),
    );
  }

  Widget _buildStarRating(Book book, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () => _showRatingDialog(book),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(5, (index) {
                  if (index < book.averageRating.floor()) {
                    return const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    );
                  } else if (index < book.averageRating) {
                    return const Icon(
                      Icons.star_half,
                      size: 16,
                      color: Colors.amber,
                    );
                  } else {
                    return const Icon(
                      Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    );
                  }
                }),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    book.ratingCount > 0
                        ? _formatCount(book.ratingCount)
                        : AppLocalizations.of(context)!.rate,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _toggleFavorite(book),
          child: Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Icon(
              book.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: book.isFavorite ? Colors.red : textColor.withOpacity(0.5),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  void _showRatingDialog(Book book) {
    int selectedStars = 0;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.brown.shade900, Colors.black],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.rateThisBook,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedStars = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              index < selectedStars
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 36,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: selectedStars > 0
                              ? () async {
                                  Navigator.of(ctx).pop();
                                  await _submitRating(book, selectedStars);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(AppLocalizations.of(context)!.submit),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitRating(Book book, int stars) async {
    final userId = await AuthService().getCurrentUserId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseLogInToRateBooks),
          ),
        );
        // Navigate to login screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ).then((_) => _loadBooks());
      }
      return;
    }

    final result = await BookRepository().rateBook(userId, book.id, stars);

    if (!result.containsKey('error') && mounted) {
      final newAvg = result['averageRating'] as double;
      final newCount = result['ratingCount'] as int;
      setState(() {
        _updateBookRating(book.id, newAvg, newCount);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.thanksForRating(stars)} ⭐',
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (result['error'] as String?) ??
                AppLocalizations.of(context)!.failedToSubmitRating,
          ),
        ),
      );
    }
  }

  void _updateBookRating(String bookId, double averageRating, int ratingCount) {
    void updateList(List<Book> list) {
      final index = list.indexWhere((b) => b.id == bookId);
      if (index != -1) {
        list[index] = list[index].copyWith(
          averageRating: averageRating,
          ratingCount: ratingCount,
        );
      }
    }

    updateList(_allBooks);
    updateList(_historyBooks);
    updateList(_uploadedBooks);
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
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
                  headers: ApiConstants.imageHeaders,
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
