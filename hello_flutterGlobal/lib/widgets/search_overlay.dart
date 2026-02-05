import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/api_constants.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../screens/playlist_screen.dart';
import '../l10n/generated/app_localizations.dart';

class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final BookRepository _bookRepository = BookRepository();
  Timer? _debounce;
  List<Book> _results = [];
  List<Book> _topPicks = [];
  List<Book> _newReleases = [];
  bool _isLoading = false;
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final topPicks = await _bookRepository.getDiscoverBooks(
        limit: 5,
        sort: 'popular',
      );
      final newReleases = await _bookRepository.getDiscoverBooks(
        limit: 6,
        sort: 'newest',
      );
      if (mounted) {
        setState(() {
          _topPicks = topPicks;
          _newReleases = newReleases;
          _isLoadingInitial = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _bookRepository.getDiscoverBooks(
        query: query,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openBook(Book book) {
    Navigator.pop(context); // Close overlay
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaylistScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    final bool isSearching = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(color: textColor, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.searchByTitle,
                          hintStyle: TextStyle(color: subtitleColor),
                          prefixIcon: Icon(Icons.search, color: subtitleColor),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close, color: subtitleColor),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _results = []);
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {}); // Update clear button visibility
                          _onSearchChanged(value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: _isLoading || _isLoadingInitial
                  ? const Center(child: CircularProgressIndicator())
                  : isSearching
                      ? _buildSearchResults(textColor, subtitleColor!)
                      : _buildDefaultContent(textColor, subtitleColor!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultContent(Color textColor, Color subtitleColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Best Choices Section
          if (_topPicks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                AppLocalizations.of(context)!.topPicks,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final book = _topPicks[index % _topPicks.length];
                  return _buildHorizontalBookCard(book, textColor, subtitleColor);
                },
              ),
            ),
          ],

          // New Releases Section (list view)
          if (_newReleases.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                AppLocalizations.of(context)!.newReleases,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...List.generate(
              _newReleases.length,
              (index) => _buildSearchResultTile(
                _newReleases[index],
                textColor,
                subtitleColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHorizontalBookCard(Book book, Color textColor, Color subtitleColor) {
    return GestureDetector(
      onTap: () => _openBook(book),
      child: Container(
        width: 192,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover (square aspect ratio)
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.absoluteCoverUrlThumbnail.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: book.absoluteCoverUrlThumbnail,
                        httpHeaders: ApiConstants.imageHeaders,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: Icon(
                            Icons.book,
                            color: subtitleColor,
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: Icon(Icons.book, color: subtitleColor, size: 40),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              book.title,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Author
            Text(
              book.author,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(Color textColor, Color subtitleColor) {
    if (_results.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noBooksFound,
          style: TextStyle(color: subtitleColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final book = _results[index];
        return _buildSearchResultTile(book, textColor, subtitleColor);
      },
    );
  }

  Widget _buildSearchResultTile(
    Book book,
    Color textColor,
    Color subtitleColor,
  ) {
    return InkWell(
      onTap: () => _openBook(book),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Book cover thumbnail
            Container(
              width: 70,
              height: 70,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[800],
              ),
              child: book.absoluteCoverUrlThumbnail.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: book.absoluteCoverUrlThumbnail,
                      httpHeaders: ApiConstants.imageHeaders,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(
                        Icons.book,
                        color: subtitleColor,
                        size: 28,
                      ),
                    )
                  : Icon(Icons.book, color: subtitleColor, size: 28),
            ),
            const SizedBox(width: 16),
            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'By ${book.author}',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 14,
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
}
