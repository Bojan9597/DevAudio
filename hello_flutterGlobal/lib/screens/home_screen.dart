import 'dart:async';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../repositories/book_repository.dart';
import '../repositories/category_repository.dart';
import '../states/layout_state.dart';
import '../services/auth_service.dart';

import 'playlist_screen.dart';
import 'login_screen.dart';
import '../widgets/subscription_bottom_sheet.dart';
import '../services/subscription_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/generated/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookRepository _bookRepository = BookRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final AuthService _authService = AuthService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<Book> _books = [];
  List<Book> _newReleases = [];
  List<Book> _topPicks = [];
  List<Book> _listenHistory = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;

  bool _isLoggedIn = false;
  bool _isSubscribed = false;
  int _playerFeatureIndex = 0;

  // Hardcoded image names - elemental thumbnails
  final List<String> _heroImages = [
    'air.jpg',
    'water.jpg',
    'earth.jpg',
    'fire.jpg',
  ];

  List<String> _localHeroImagePaths = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadCategories();
    _loadBooks();
    _loadHeroImages();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _loadHeroImages() {
    // Hero images are now bundled as local assets - no download needed
    // Set the asset paths directly
    if (mounted) {
      setState(() {
        _localHeroImagePaths = _heroImages
            .map((name) => 'assets/homeImages/$name')
            .toList();
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    bool subscribed = false;
    if (loggedIn) {
      subscribed = await _subscriptionService.isSubscribed();
    }
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _isSubscribed = subscribed;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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

  Future<void> _loadCategories() async {
    try {
      final cats = await _categoryRepository.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print("Error loading categories: $e");
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _resetAndLoad() async {
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

      // Cache subscription and favorites
      _authService.setSubscriptionStatus(isSubscribed);
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
              return progress < 0.95; // Only show books < 95% complete
            }).toList();
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
      }
    }
  }

  Future<void> _loadMoreBooks() async {
    if (_isLoading || !_hasMore) return;
    _currentPage++;
    await _loadBooks();
  }

  void _onCategoryTap(Category category) {
    globalLayoutState.setCategoryId(category.id);
  }

  void _navigateToSubscription() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubscriptionBottomSheet(
        onSubscribed: () {
          Navigator.pop(context); // Close sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.subscriptionActivated,
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh checking status
          _checkLoginStatus();
        },
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    ).then((_) => _checkLoginStatus());
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchForBooks,
                  hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: textColor.withOpacity(0.7),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
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
            ),

            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _resetAndLoad,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Hero Section (Only show if not searching)
                    if (_searchController.text.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                          child: Column(
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.getYourImaginationGoing,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.homeHeroDescription,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor.withOpacity(0.8),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Dynamic Button and Text
                              _buildSubscriptionCTA(textColor),

                              const SizedBox(height: 30),

                              // 2x2 Image Grid
                              if (_localHeroImagePaths.length >= 4)
                                _buildHeroImageGrid()
                              else
                                const SizedBox(height: 200),

                              const SizedBox(height: 50),

                              // Feature Highlights
                              _buildFeatureItem(
                                context,
                                Icons.all_inclusive,
                                AppLocalizations.of(context)!.unlimitedAccess,
                                AppLocalizations.of(
                                  context,
                                )!.unlimitedAccessDescription,
                              ),
                              _buildFeatureItem(
                                context,
                                Icons.download_for_offline,
                                AppLocalizations.of(context)!.listenOffline,
                                AppLocalizations.of(
                                  context,
                                )!.listenOfflineDescription,
                              ),
                              _buildFeatureItem(
                                context,
                                Icons.quiz,
                                AppLocalizations.of(
                                  context,
                                )!.interactiveQuizzes,
                                AppLocalizations.of(
                                  context,
                                )!.interactiveQuizzesDescription,
                              ),

                              const SizedBox(height: 30),
                              // Secondary CTA
                              _buildSubscriptionCTA(textColor),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                    // New Sections (Replaces Categories & Book List when not searching)
                    if (_searchController.text.isEmpty) ...[
                      // Player Feature Carousel
                      SliverToBoxAdapter(
                        child: _buildPlayerFeatureSlider(textColor),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 30)),

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

                      _buildSectionHeader(
                        AppLocalizations.of(context)!.newReleases,
                        textColor,
                      ),
                      _buildHorizontalBookList(
                        _newReleases,
                        cardColor,
                        textColor,
                      ),

                      _buildSectionHeader(
                        AppLocalizations.of(context)!.topPicks,
                        textColor,
                      ),
                      _buildHorizontalBookList(_topPicks, cardColor, textColor),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],

                    // Search Results (Only when searching)
                    if (_searchController.text.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.searchResults,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      if (_books.isEmpty && !_isLoading)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.noBooksFound,
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            if (index == _books.length) {
                              return _isLoading
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }
                            return _buildBookItem(
                              _books[index],
                              cardColor,
                              textColor,
                            );
                          }, childCount: _books.length + (_isLoading ? 1 : 0)),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: textColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalBookList(
    List<Book> books,
    Color cardColor,
    Color textColor,
  ) {
    if (books.isEmpty && !_isLoading) {
      return SliverToBoxAdapter(child: SizedBox(height: 0));
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 312,
        child: _isLoading && books.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final book = books[index % books.length];
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
      return SliverToBoxAdapter(child: SizedBox(height: 0));
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 336,
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
          const SizedBox(height: 4),
          _buildPremiumBadge(book, textColor),
          if (book.isPremium && !_isSubscribed) const SizedBox(height: 4),
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

  Widget _buildPremiumBadge(Book book, Color textColor) {
    if (!book.isPremium) return const SizedBox.shrink();

    // If user is already subscribed, don't show clickable badge
    if (_isSubscribed) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _navigateToSubscription(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium, size: 14, color: Colors.amber[700]),
            const SizedBox(width: 3),
            Text(
              'Premium',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.amber[700],
              ),
            ),
          ],
        ),
      ),
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
      book.isFavorite,
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
        ).then((_) => _checkLoginStatus());
      }
      return;
    }

    final result = await _bookRepository.rateBook(userId, book.id, stars);

    if (!result.containsKey('error') && mounted) {
      // Update stars immediately in all lists
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
            (result['error'] as String?) ?? AppLocalizations.of(context)!.failedToSubmitRating,
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

  Widget _buildHeroImageGrid() {
    List<Widget> images = [];

    for (var path in _localHeroImagePaths.take(4)) {
      images.add(_buildHeroImageAsset(path));
    }

    // 2. Add 2 random books (prefer new releases or top picks) - REMOVED as per user request
    // We only want local assets now.

    // 3. Fill up to 6 if needed by reusing local images
    while (images.length < 6 && _localHeroImagePaths.isNotEmpty) {
      images.add(
        _buildHeroImageAsset(
          _localHeroImagePaths[images.length % _localHeroImagePaths.length],
        ),
      );
    }

    // Ensure we have exactly 6 for the layout
    if (images.length < 6) return const SizedBox.shrink();

    // The layout: 2 Rows of 3 images
    final double tiltAngle = 0.35; // ~20 degrees, varying side

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        children: [
          // Row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left Column (Lowest -> Offset down)
              _buildRotatedImageWrapper(
                images[0],
                angle: tiltAngle,
                scale: 0.9,
                offsetY: 25.0,
              ),
              // Middle Column (Mid -> Offset mid)
              _buildRotatedImageWrapper(
                images[4],
                angle: tiltAngle,
                scale: 1.0,
                offsetY: 12.5,
              ),
              // Right Column (Highest -> Offset 0)
              _buildRotatedImageWrapper(
                images[2],
                angle: tiltAngle,
                scale: 0.85,
                offsetY: 0,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2 (apply same offsets to columns)
          // Row 2 (apply same offsets to columns)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRotatedImageWrapper(
                images[3],
                angle: tiltAngle,
                scale: 0.85,
                offsetY: 25.0,
              ),
              _buildRotatedImageWrapper(
                images[1],
                angle: tiltAngle,
                scale: 1.0,
                offsetY: 12.5,
              ),
              _buildRotatedImageWrapper(
                images[5],
                angle: tiltAngle,
                scale: 0.9,
                offsetY: 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRotatedImageWrapper(
    Widget image, {
    double angle = 0,
    double scale = 1.0,
    double offsetY = 0,
    int zIndex = 1,
  }) {
    return Expanded(
      child: Transform.translate(
        offset: Offset(0, offsetY),
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: image,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImageAsset(String assetPath) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey[800]),
        ),
      ),
    );
  }

  Widget _buildBookItem(Book book, Color cardColor, Color textColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child:
              (book.absoluteCoverUrlThumbnail != null &&
                  book.absoluteCoverUrlThumbnail!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: book.absoluteCoverUrlThumbnail!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Icon(
                    Icons.play_circle_fill,
                    color: Theme.of(context).colorScheme.primary,
                    size: 40,
                  ),
                )
              : Icon(
                  Icons.play_circle_fill,
                  color: Theme.of(context).colorScheme.primary,
                  size: 40,
                ),
        ),
        title: Text(
          book.title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              book.author,
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 4),
            // Optional: Posted by info
          ],
        ),
        onTap: () => _openPlayer(book),
      ),
    );
  }

  void _openPlayer(Book book) {
    // If book is premium and user is not subscribed, show subscription sheet
    if (book.isPremium && !_isSubscribed) {
      _navigateToSubscription();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaylistScreen(book: book)),
    ).then((_) => _resetAndLoad());
  }

  Widget _buildSubscriptionCTA(Color textColor) {
    if (!_isLoggedIn) {
      return Column(
        children: [
          ElevatedButton(
            onPressed: _navigateToLogin, // Or free trial flow
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.continueToFreeTrial,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.autoRenewsInfo,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
          ),
        ],
      );
    } else if (!_isSubscribed) {
      return Column(
        children: [
          ElevatedButton(
            onPressed: _navigateToSubscription,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.subscribe,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.monthlySubscriptionInfo,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerFeatureSlider(Color textColor) {
    return Column(
      children: [
        SizedBox(
          height: 500, // Increased height for the UI mockup
          child: PageView(
            onPageChanged: (index) {
              setState(() => _playerFeatureIndex = index);
            },
            children: [
              _buildPlayerFeatureSlide(
                textColor,
                highlightTarget: 'speed',
                title: AppLocalizations.of(context)!.findTheRightSpeed,
                description: AppLocalizations.of(
                  context,
                )!.findTheRightSpeedDescription,
              ),
              _buildPlayerFeatureSlide(
                textColor,
                highlightTarget: 'sleep',
                title: AppLocalizations.of(context)!.sleepTimer,
                description: AppLocalizations.of(
                  context,
                )!.sleepTimerDescription,
              ),
              _buildPlayerFeatureSlide(
                textColor,
                highlightTarget: 'favorites',
                title: AppLocalizations.of(context)!.favoritesFeature,
                description: AppLocalizations.of(
                  context,
                )!.favoritesFeatureDescription,
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 24, // Line width
              height: 4, // Line height
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _playerFeatureIndex == index
                    ? Colors.amber[700]
                    : Colors.grey.withOpacity(0.5),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPlayerFeatureSlide(
    Color textColor, {
    required String highlightTarget,
    required String title,
    required String description,
  }) {
    // Determine card background color
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[200];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // UI Mockup
          Expanded(child: _buildMockPlayerUI(highlightTarget, isDark)),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildMockPlayerUI(String highlightTarget, bool isDark) {
    final highlightColor = Colors.amber[700];
    final iconColor = isDark ? Colors.white : Colors.black87;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Album Art Placeholder
          Expanded(
            flex: 5,
            child: Center(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage('assets/homeImages/fire.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          // Controls
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Progress Bar
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.replay_10, color: iconColor),
                    Icon(Icons.skip_previous, color: iconColor, size: 30),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: iconColor,
                      child: Icon(
                        Icons.play_arrow,
                        color: isDark ? Colors.black : Colors.white,
                        size: 30,
                      ),
                    ),
                    Icon(Icons.skip_next, color: iconColor, size: 30),
                    Icon(Icons.forward_30, color: iconColor),
                  ],
                ),

                // Bottom Actions with Highlight
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Speed
                    _buildMockActionButton(
                      icon: Icons.speed,
                      label: '1.0x',
                      isSelected: highlightTarget == 'speed',
                      color: iconColor,
                      highlightColor: highlightColor,
                      isPill: true,
                    ),
                    // Sleep
                    _buildMockActionButton(
                      icon: Icons.mode_night_outlined,
                      isSelected: highlightTarget == 'sleep',
                      color: iconColor,
                      highlightColor: highlightColor,
                    ),
                    // Favorites
                    _buildMockActionButton(
                      icon: Icons.favorite_border,
                      isSelected: highlightTarget == 'favorites',
                      color: iconColor,
                      highlightColor: highlightColor,
                    ),
                    // More
                    _buildMockActionButton(
                      icon: Icons.more_vert,
                      isSelected: false,
                      color: iconColor,
                      highlightColor: highlightColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockActionButton({
    required IconData icon,
    String? label,
    required bool isSelected,
    required Color color,
    Color? highlightColor,
    bool isPill = false,
  }) {
    if (isSelected) {
      return Container(
        padding: isPill
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: highlightColor!, width: 2),
          borderRadius: BorderRadius.circular(isPill ? 20 : 50),
          //color: highlightColor.withOpacity(0.2), // Optional bg fill
        ),
        child: isPill
            ? Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label ?? '',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Icon(icon, size: 22, color: color),
      );
    } else {
      if (isPill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(
                label ?? '',
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }
      return Icon(icon, size: 22, color: color.withOpacity(0.7));
    }
  }
}
