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
import 'package:cached_network_image/cached_network_image.dart';

import '../screens/profile_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/upload_book_screen.dart';
import '../screens/playlist_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import 'category_details_view.dart';

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
  bool _isSubscribed = false;

  // Library view mode toggles (separate from global grid/list setting)
  bool _isLibraryGridView = true;
  int? _userId;

  int _lastRefreshVersion = 0;
  String _lastCategoryId = '';

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _checkSubscriptionStatus();
    _loadBooks();
    _loadCategories(); // Load categories for filtering

    // Listen for refresh triggers
    globalLayoutState.addListener(_handleLayoutChange);
    _lastRefreshVersion = globalLayoutState.refreshVersion;
    _lastCategoryId = globalLayoutState.selectedCategoryId;
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AuthService().isAdmin();
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    final isSubscribed = await AuthService().isSubscribed();
    if (mounted) {
      setState(() => _isSubscribed = isSubscribed);
    }
  }

  @override
  void dispose() {
    globalLayoutState.removeListener(_handleLayoutChange);
    super.dispose();
  }

  void _handleLayoutChange() {
    bool shouldReload = false;
    // Check for explicit refresh trigger
    if (globalLayoutState.refreshVersion != _lastRefreshVersion) {
      _lastRefreshVersion = globalLayoutState.refreshVersion;
      shouldReload = true;
    }
    // Check if switching TO library from something else
    // We want to ensure library data (favorites/downloads) is fresh
    if (globalLayoutState.selectedCategoryId == 'library' &&
        _lastCategoryId != 'library') {
      shouldReload = true;
    }
    _lastCategoryId = globalLayoutState.selectedCategoryId;

    if (shouldReload) {
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

        if (categoryId == 'categories' || categoryId == 'discover') {
          return const DiscoverScreen();
        }

        if (categoryId == 'profile') {
          return const ProfileScreen();
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
          allCategories: _categories,
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

    // FIX: For "My Books" (Downloads), we should check ALL books for download status,
    // not just the ones the server says we "purchased". This ensures books locally
    // downloaded (e.g. from previous subscription) still appear.
    final booksToCheckForDownloads = _allBooks
        .where((b) => !uploadedIds.contains(b.id))
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
      _buildMyBooksTab(booksToCheckForDownloads),
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

    // Parallelize checks for performance
    // Returns List<Book?> where null means not downloaded
    final results = await Future.wait(
      books.map((book) async {
        // Check if playlist is downloaded for this book
        final isPlaylistDownloaded = await downloadService.isPlaylistDownloaded(
          book.id,
          userId: _userId,
        );
        if (isPlaylistDownloaded) return book;

        // Also check if book itself is downloaded
        final isBookDownloaded = await downloadService.isBookDownloaded(
          book.id,
          userId: _userId,
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
      MaterialPageRoute(builder: (_) => PlaylistScreen(book: book)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.thanksForRating(stars)} ⭐',
          ),
        ),
      );
      _loadBooks();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (result['error'] as String?) ?? AppLocalizations.of(context)!.failedToSubmitRating,
          ),
        ),
      );
    }
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
