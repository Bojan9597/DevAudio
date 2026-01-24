import 'dart:async';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'playlist_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  List<Book> _books = [];
  List<Book> _newReleases = [];
  List<Book> _topPicks = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
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
      final userId = await AuthService().getCurrentUserId();
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
        // Fetch specific lists only on initial load/refresh
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
        // Search Bar + View Toggle
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchByTitle,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                onPressed: () => setState(() => _isGridView = !_isGridView),
                tooltip: _isGridView
                    ? AppLocalizations.of(context)!.switchToList
                    : AppLocalizations.of(context)!.switchToGrid,
              ),
            ],
          ),
        ),

        // Books Section with horizontal carousels + grid/list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _resetAndLoad,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // New Releases Section
                _buildSectionHeader('New Releases', textColor),
                _buildHorizontalBookList(_newReleases, cardColor, textColor),

                // Top Picks Section
                _buildSectionHeader('Top Picks', textColor),
                _buildHorizontalBookList(_topPicks, cardColor, textColor),

                // All Books Grid/List
                _buildSectionHeader('All Books', textColor),
                _isGridView
                    ? _buildSliverGrid(cardColor, textColor)
                    : _buildSliverList(cardColor, textColor),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
        height: 280,
        child: _isLoading && _books.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: booksToShow.length,
                itemBuilder: (context, index) {
                  final book = booksToShow[index];
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
          childAspectRatio: 0.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
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

  Widget _buildSliverList(Color cardColor, Color textColor) {
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

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == _books.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildBookItem(_books[index], cardColor, textColor);
      }, childCount: _books.length + (_isLoading ? 1 : 0)),
    );
  }

  Widget _buildGridView(Color cardColor, Color textColor) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _books.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _books.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildBookCard(_books[index], cardColor, textColor);
      },
    );
  }

  Widget _buildListView(Color cardColor, Color textColor) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      itemCount: _books.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _books.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildBookItem(_books[index], cardColor, textColor);
      },
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
      book.isFavorite, // Pass OLD state (logic: if isFavorite, we delete)
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

  Widget _buildBookItem(Book book, Color cardColor, Color textColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        // Leading Image (Placeholder if no url)
        // Leading Image (Placeholder if no url)
        leading: Container(
          width: 50,
          height: 50,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child:
              (book.absoluteCoverUrlThumbnail != null &&
                  book.absoluteCoverUrlThumbnail!.isNotEmpty)
              ? Image.network(
                  book.absoluteCoverUrlThumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
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
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppTheme.orangeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.postedBy(book.postedBy ?? "Unknown"),
                  style: TextStyle(
                    color: AppTheme.orangeColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
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
}
