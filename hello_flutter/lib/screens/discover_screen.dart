import 'dart:async';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
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
      final newBooks = await _bookRepository.getDiscoverBooks(
        page: _currentPage,
        limit: _limit,
        query: _searchController.text,
      );

      if (mounted) {
        setState(() {
          _books.addAll(newBooks);
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

        // Books Grid/List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _resetAndLoad,
            child: _books.isEmpty && !_isLoading
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.noBooksFound,
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                          ),
                        ),
                      ),
                    ],
                  )
                : _isGridView
                ? _buildGridView(cardColor, textColor)
                : _buildListView(cardColor, textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildGridView(Color cardColor, Color textColor) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
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
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPlayer(book),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child:
                  (book.absoluteCoverUrlThumbnail != null &&
                      book.absoluteCoverUrlThumbnail!.isNotEmpty)
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
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
