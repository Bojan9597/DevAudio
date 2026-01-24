import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../repositories/book_repository.dart';
import '../repositories/category_repository.dart';
import '../states/layout_state.dart';
import '../utils/api_constants.dart';
import '../services/auth_service.dart';

import 'playlist_screen.dart';
import 'login_screen.dart';
import '../widgets/subscription_bottom_sheet.dart';
import '../services/subscription_service.dart';
import 'package:hello_flutter/services/connectivity_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

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
    _downloadHeroImages();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _downloadHeroImages() async {
    final List<String> localPaths = [];
    final directory = await getApplicationDocumentsDirectory();

    for (final imageName in _heroImages) {
      final filePath = '${directory.path}/homeImages_thumb_$imageName';
      final file = File(filePath);

      try {
        if (await file.exists()) {
          localPaths.add(filePath);
        } else {
          if (!ConnectivityService().isOffline) {
            // Load from thumbnails folder for faster performance
            final imageUrl =
                '${ApiConstants.baseUrl}/static/homeImages/thumbnails/$imageName';
            await Dio().download(imageUrl, filePath);
            localPaths.add(filePath);
          }
        }
      } catch (e) {
        print('Error downloading hero image $imageName: $e');
      }
    }

    if (mounted) {
      setState(() {
        _localHeroImagePaths = localPaths;
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
      final userId = await _authService.getCurrentUserId();
      List<int> favIds = [];
      if (userId != null) {
        favIds = await _bookRepository.getFavoriteBookIds(userId);
      }

      final newBooksRaw = await _bookRepository.getDiscoverBooks(
        page: _currentPage,
        limit: _limit,
        query: _searchController.text,
      );

      List<Book> mergeFavs(List<Book> list) {
        return list.map((b) {
          final isFav = favIds.contains(int.tryParse(b.id) ?? -1);
          return b.copyWith(isFavorite: isFav);
        }).toList();
      }

      final newBooks = mergeFavs(newBooksRaw);

      List<Book> newReleases = _newReleases;
      List<Book> topPicks = _topPicks;

      if (_currentPage == 1) {
        final newReleasesRaw = await _bookRepository.getDiscoverBooks(
          limit: 5,
          sort: 'newest',
          query: _searchController.text,
        );
        newReleases = mergeFavs(newReleasesRaw);

        final topPicksRaw = await _bookRepository.getDiscoverBooks(
          limit: 5,
          sort: 'popular',
          query: _searchController.text,
        );
        topPicks = mergeFavs(topPicksRaw);
      }

      if (mounted) {
        setState(() {
          if (_currentPage == 1) {
            _books = newBooks;
            _newReleases = newReleases;
            _topPicks = topPicks;
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

                      _buildSectionHeader(
                        AppLocalizations.of(context)!.newReleases,
                        textColor,
                      ),
                      _buildHorizontalBookList(
                        _newReleases,
                        cardColor,
                        textColor,
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      _buildSectionHeader(
                        AppLocalizations.of(context)!.topPicks,
                        textColor,
                      ),
                      _buildHorizontalBookList(
                        _topPicks,
                        cardColor,
                        textColor,
                      ), // Simulate different content

                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        height: 280,
        child: _isLoading && books.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    child: _buildBookCard(book, cardColor, textColor),
                  );
                },
              ),
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
        GestureDetector(
          onTap: () => _showRatingDialog(book),
          child: Row(
            children: [
              ...List.generate(5, (index) {
                if (index < book.averageRating.floor()) {
                  return const Icon(Icons.star, size: 19, color: Colors.amber);
                } else if (index < book.averageRating) {
                  return const Icon(
                    Icons.star_half,
                    size: 19,
                    color: Colors.amber,
                  );
                } else {
                  return const Icon(
                    Icons.star_border,
                    size: 19,
                    color: Colors.amber,
                  );
                }
              }),
              const SizedBox(width: 5),
              Text(
                book.ratingCount > 0 ? _formatCount(book.ratingCount) : 'Rate',
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ],
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
          const SnackBar(content: Text('Please log in to manage favorites')),
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
        const SnackBar(content: Text('Failed to update favorite')),
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
                      'Rate this book',
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
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white54),
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
                          child: const Text('Submit'),
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
          const SnackBar(content: Text('Please log in to rate books')),
        );
      }
      return;
    }

    final success = await _bookRepository.rateBook(userId, book.id, stars);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thanks for your $stars-star rating! ⭐')),
      );
      _resetAndLoad();
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to submit rating')));
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  Widget _buildHeroImageGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: _localHeroImagePaths.take(4).map((path) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[800]),
              ),
            ),
          );
        }).toList(),
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaylistScreen(book: book)),
    );
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
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      ApiConstants.baseUrl +
                          '/static/homeImages/thumbnails/fire.jpg',
                    ),
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
