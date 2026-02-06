import 'dart:async';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../services/auth_service.dart';
import 'playlist_screen.dart';
import 'login_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/api_constants.dart';
import '../states/layout_state.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final BookRepository _bookRepository = BookRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  // Static cache to persist data across tab switches (30 second cache)
  static const Duration _cacheDuration = Duration(seconds: 30);
  static DateTime? _lastFetchTime;
  static String _lastSearchQuery = '';
  static List<Book> _cachedBooks = [];
  static List<Book> _cachedNewReleases = [];
  static List<Book> _cachedTopPicks = [];
  static List<Book> _cachedListenHistory = [];
  static bool _cachedIsSubscribed = false;

  List<Book> _books = [];
  List<Book> _newReleases = [];
  List<Book> _topPicks = [];
  List<Book> _listenHistory = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isSubscribed = false;
  int _currentPage = 1;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    // Load persisted subscription state immediately to prevent UI flash
    _loadInitialSubscriptionState();

    // Restore from cache if valid, otherwise load fresh
    if (_isCacheValid()) {
      _restoreFromCache();
    } else {
      _loadBooks();
    }
    _scrollController.addListener(_onScroll);
    globalLayoutState.addListener(_onSearchChanged);
  }

  Future<void> _loadInitialSubscriptionState() async {
    final isSubscribed = await AuthService().getPersistentSubscriptionStatus();
    if (mounted && isSubscribed) {
      setState(() {
        _isSubscribed = true;
      });
    }
  }

  /// Check if cache is valid (within 30 seconds and same search query)
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    final currentQuery = globalLayoutState.searchQuery;
    final cacheAge = DateTime.now().difference(_lastFetchTime!);
    return cacheAge < _cacheDuration &&
        _lastSearchQuery == currentQuery &&
        _cachedBooks.isNotEmpty;
  }

  /// Restore data from static cache
  void _restoreFromCache() {
    setState(() {
      _books = List.from(_cachedBooks);
      _newReleases = List.from(_cachedNewReleases);
      _topPicks = List.from(_cachedTopPicks);
      _listenHistory = List.from(_cachedListenHistory);
      _isSubscribed = _cachedIsSubscribed;
      _hasMore = _cachedBooks.length == _limit;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    globalLayoutState.removeListener(_onSearchChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreBooks();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _resetAndLoad();
    });
  }

  Future<void> _resetAndLoad() async {
    // Invalidate cache to force fresh fetch
    _lastFetchTime = null;
    setState(() {
      _books.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadBooks();
  }

  Future<void> _loadBooks() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // Single API call gets everything we need!
      final discoverData = await _bookRepository.getDiscoverData(
        page: _currentPage,
        limit: _limit,
      );

      // Extract data from combined response
      final List<Book> allBooks = discoverData['allBooks'] as List<Book>;
      final List<int> favIds = discoverData['favorites'] as List<int>;
      final bool isSubscribed = discoverData['isSubscribed'] as bool;

      // Cache subscription status so other screens don't need to re-fetch
      AuthService().setSubscriptionStatus(isSubscribed);

      // Cache favorites so other screens don't need to re-fetch
      _bookRepository.setFavorites(favIds);

      // Merge favorite status into books
      List<Book> mergeFavs(List<Book> list) {
        return list.map((b) {
          final isFav = favIds.contains(int.tryParse(b.id) ?? -1);
          return b.copyWith(isFavorite: isFav);
        }).toList();
      }

      final newBooks = mergeFavs(allBooks);

      if (mounted) {
        setState(() {
          _isSubscribed = isSubscribed;

          if (_currentPage == 1) {
            _books = newBooks;
            _newReleases = mergeFavs(discoverData['newReleases'] as List<Book>);
            _topPicks = mergeFavs(discoverData['topPicks'] as List<Book>);

            // Filter listen history to exclude finished books
            final historyWithFavs = mergeFavs(
              discoverData['listenHistory'] as List<Book>,
            );
            _listenHistory = historyWithFavs.where((book) {
              if (book.lastPosition == null ||
                  book.durationSeconds == null ||
                  book.durationSeconds == 0) {
                return true; // Include if no progress data
              }
              final progress = book.lastPosition! / book.durationSeconds!;
              return progress <
                  0.95; // Only show books that are less than 95% complete
            }).toList();

            // Update static cache for tab switching
            _cachedBooks = List.from(_books);
            _cachedNewReleases = List.from(_newReleases);
            _cachedTopPicks = List.from(_topPicks);
            _cachedListenHistory = List.from(_listenHistory);
            _cachedIsSubscribed = isSubscribed;
            _lastFetchTime = DateTime.now();
            _lastSearchQuery = globalLayoutState.searchQuery;
          } else {
            _books.addAll(newBooks);
          }
          _hasMore = newBooks.length == _limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorLoadingBooks(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreBooks() async {
    if (_isLoading || !_hasMore) return;
    _currentPage++;
    await _loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Column(
      children: [
        // View Toggle in header if needed, or remove completely if not desired.
        // User asked to "Move search", implies search bar removal.
        // View toggle was right next to it. Let's keep View toggle perhaps?
        // Actually, AppLayout has BottomNav. ContentArea handles most stuff.
        // DiscoverScreen is just content.
        // Let's add a small row for View Toggle if we want to keep it locally?
        // Or maybe just remove the search bar row entirely.
        // BUT wait, usage was:
        // Padding(child: Row(children: [TextField, IconButton(view)]))
        // If we remove TextField, we still might want the View Switcher?
        // The user didn't mention the View Switcher.
        // Let's keep the View Switcher for now but maybe make it cleaner?
        // Actually, looking at ContentArea, there is a view switcher there too?
        // ContentArea has its own view switcher for categories.
        // DiscoverScreen has one for its results.
        // Let's keep the view switcher but remove the search field.

        // Books Section with horizontal carousels + grid/list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _resetAndLoad,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // New Releases Section
                _buildSectionHeader(
                  AppLocalizations.of(context)!.newReleases,
                  textColor,
                ),
                _buildHorizontalBookList(_newReleases, cardColor, textColor),

                // Top Picks Section (Best Choices)
                _buildSectionHeader(
                  AppLocalizations.of(context)!.topPicks,
                  textColor,
                ),
                _buildHorizontalBookList(_topPicks, cardColor, textColor),

                // Continue Listening Section (only show if user has history)
                if (_listenHistory.isNotEmpty) ...[
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.continueListening,
                    textColor,
                  ),
                  _buildContinueListeningList(
                    _listenHistory,
                    cardColor,
                    textColor,
                  ),
                ],

                // All Books Grid/List
                _buildSectionHeader(
                  AppLocalizations.of(context)!.allBooks,
                  textColor,
                ),
                _buildSliverGrid(cardColor, textColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalBookList(
    List<Book> booksToShow,
    Color cardColor,
    Color textColor,
  ) {
    if (booksToShow.isEmpty && !_isLoading) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.noBooksFound,
              style: TextStyle(color: textColor.withOpacity(0.5)),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height:
            310, // Increased from 296 to accommodate multi-line titles and tags
        child: _isLoading && _books.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final book = booksToShow[index % booksToShow.length];
                  return Container(
                    width: 192,
                    margin: const EdgeInsets.only(right: 12),
                    child: _buildBookCard(book, cardColor, textColor),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildContinueListeningList(
    List<Book> books,
    Color cardColor,
    Color textColor,
  ) {
    if (books.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox(height: 0));
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 350, // Increased from 336 to prevent overflow
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return Container(
              width: 192,
              margin: const EdgeInsets.only(right: 12),
              child: _buildContinueListeningCard(book, cardColor, textColor),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContinueListeningCard(
    Book book,
    Color cardColor,
    Color textColor,
  ) {
    final progress =
        (book.lastPosition != null &&
            book.durationSeconds != null &&
            book.durationSeconds! > 0)
        ? (book.lastPosition! / book.durationSeconds!).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => _openPlayer(book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book.absoluteCoverUrlThumbnail.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: book.absoluteCoverUrlThumbnail,
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
              // Play button overlay
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: textColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[700]!),
              minHeight: 4,
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
          Text(
            _formatRemainingTime(book),
            style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6)),
          ),
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

  String _formatRemainingTime(Book book) {
    if (book.lastPosition == null || book.durationSeconds == null) {
      return '';
    }
    final remaining = book.durationSeconds! - book.lastPosition!;
    if (remaining <= 0) return '';
    final hours = remaining ~/ 3600;
    final minutes = (remaining % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m left';
    }
    return '${minutes} min left';
  }

  Widget _buildSliverGrid(Color cardColor, Color textColor) {
    if (_books.isEmpty && !_isLoading) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.noBooksFound,
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio:
              0.58, // Adjusted from 0.6 to provide more vertical space
          crossAxisSpacing: 12,
          mainAxisSpacing: 0,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == _books.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildBookCard(_books[index], cardColor, textColor);
        }, childCount: _books.length + (_isLoading ? 1 : 0)),
      ),
    );
  }

  Widget _buildBookCard(Book book, Color cardColor, Color textColor) {
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
                      imageUrl: book.absoluteCoverUrlThumbnail,
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

  String _formatDuration(int? totalSeconds) {
    if (totalSeconds == null || totalSeconds == 0) return '';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes} min';
  }

  Widget _buildDurationText(Book book, Color textColor) {
    final durationText = _formatDuration(book.durationSeconds);
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

  Future<void> _toggleFavorite(Book book) async {
    final userId = await AuthService().getCurrentUserId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.pleaseLogInToManageFavorites,
            ),
          ),
        );
      }
      return;
    }

    // Optimistic update
    setState(() {
      _updateBookInLists(book.id);
    });

    final success = await _bookRepository.toggleFavorite(
      userId,
      book.id,
      book.isFavorite, // Pass OLD state (logic: if isFavorite, we delete)
    );

    if (!success && mounted) {
      // Revert if failed
      setState(() {
        _updateBookInLists(book.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToUpdateFavorite),
        ),
      );
    }
  }

  void _updateBookInLists(String bookId) {
    void updateList(List<Book> list) {
      final index = list.indexWhere((b) => b.id == bookId);
      if (index != -1) {
        list[index] = list[index].copyWith(isFavorite: !list[index].isFavorite);
      }
    }

    updateList(_books);
    updateList(_newReleases);
    updateList(_topPicks);
    updateList(_listenHistory);
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
        ).then((_) => _resetAndLoad());
      }
      return;
    }

    final result = await _bookRepository.rateBook(userId, book.id, stars);

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

    updateList(_books);
    updateList(_newReleases);
    updateList(_topPicks);
    updateList(_listenHistory);
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  void _openPlayer(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaylistScreen(book: book)),
    );
  }
}
