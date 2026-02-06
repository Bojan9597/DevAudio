import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/api_constants.dart';
import '../models/book.dart';
import '../l10n/generated/app_localizations.dart';
import '../screens/playlist_screen.dart';
import '../states/layout_state.dart';
import '../services/auth_service.dart';
import '../repositories/book_repository.dart';
import '../screens/login_screen.dart';

class CategoryDetailsView extends StatefulWidget {
  final String categoryId;
  final String categoryTitle; // Pre-resolved title
  final List<Book> books;
  final Future<void> Function() onRefresh;

  const CategoryDetailsView({
    Key? key,
    required this.categoryId,
    required this.categoryTitle,
    required this.books,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<CategoryDetailsView> createState() => _CategoryDetailsViewState();
}

class _CategoryDetailsViewState extends State<CategoryDetailsView> {
  final TextEditingController _searchController = TextEditingController();
  final BookRepository _bookRepository = BookRepository();
  String _searchQuery = '';
  bool _isSubscribed = false;
  late List<Book> _localBooks;

  @override
  void initState() {
    super.initState();
    _localBooks = List.from(widget.books);
    _checkSubscriptionStatus();
  }

  @override
  void didUpdateWidget(CategoryDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.books != oldWidget.books) {
      _localBooks = List.from(widget.books);
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
    _searchController.dispose();
    super.dispose();
  }

  void _openPlayer(Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaylistScreen(book: book)),
    );
    // Refresh parent if needed (e.g. for progress updates),
    // but here we just trigger the generic refresh
    await widget.onRefresh();
  }

  String _formatDuration(int? totalSeconds) {
    if (totalSeconds == null || totalSeconds == 0) return '';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m'; // e.g. "5h 30m"
    }
    return '${minutes} min'; // e.g. "30 min"
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Filter books locally using our internal mutable list
    final filteredBooks = _localBooks.where((book) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return book.title.toLowerCase().contains(q) ||
          book.author.toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Search Bar & Controls
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
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Global view toggle (list/grid)
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
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(
                    context,
                  )!.booksInCategory(widget.categoryTitle),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Results
            Expanded(child: _buildBookGridOrList(filteredBooks)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookGridOrList(List<Book> books) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.book_outlined,
              size: 60,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? AppLocalizations.of(context)!.noBooksFound
                  : AppLocalizations.of(
                      context,
                    )!.noBooksFoundInCategory(widget.categoryTitle),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    // Since we are using globalLayoutState for this preference, we can just check it directly
    // NOTE: If we want to listen to it *inside* this widget for the view toggle to rebuild the list,
    // we need to wrap this part in a ListenableBuilder OR just rely on the parent's rebuild if the parent is listening.
    // The previous implementation had the whole ContentArea in ListenableBuilder(globalLayoutState).
    // If we want to decouple, we should use a ListenableBuilder *here* around the list part,
    // OR just pass the boolean in.
    // Let's use ListenableBuilder here to ensure responsive toggle.

    return ListenableBuilder(
      listenable: globalLayoutState,
      builder: (context, _) {
        if (globalLayoutState.isGridView) {
          return LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = (constraints.maxWidth / 200).toInt();
              if (crossAxisCount < 2) crossAxisCount = 2;

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12, // Added vertical spacing
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  return _buildBookCard(books[index]);
                },
              );
            },
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return _buildBookListTile(books[index]);
            },
          );
        }
      },
    );
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
          // Duration
          if (book.durationSeconds != null && book.durationSeconds! > 0)
            Text(
              _formatDuration(book.durationSeconds),
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
          // Star Rating & Favorite Row
          Row(
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
                    color: book.isFavorite
                        ? Colors.red
                        : textColor.withOpacity(0.5),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookListTile(Book book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: AspectRatio(
          aspectRatio: 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: book.absoluteCoverUrlThumbnail.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: book.absoluteCoverUrlThumbnail,
                    httpHeaders: ApiConstants.imageHeaders,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Icon(Icons.book),
                  )
                : const Icon(Icons.book),
          ),
        ),
        title: Text(
          book.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.author),
            if (book.durationSeconds != null && book.durationSeconds! > 0)
              Text(
                _formatDuration(book.durationSeconds),
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.6),
                ),
              ),
          ],
        ),
        trailing: book.isFavorite
            ? const Icon(Icons.favorite, color: Colors.red)
            : null,
        onTap: () => _openPlayer(book),
      ),
    );
  }

  // --- Rating & Favorite Logic ---

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
    final index = _localBooks.indexWhere((b) => b.id == bookId);
    if (index != -1) {
      _localBooks[index] = _localBooks[index].copyWith(
        isFavorite: !_localBooks[index].isFavorite,
      );
    }
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
        );
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
    final index = _localBooks.indexWhere((b) => b.id == bookId);
    if (index != -1) {
      _localBooks[index] = _localBooks[index].copyWith(
        averageRating: averageRating,
        ratingCount: ratingCount,
      );
    }
  }
}
