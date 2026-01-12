import 'dart:async';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/player_screen.dart';

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
  final int _limit = 5;

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading books: $e')));
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
    // Determine theme colors (reusing styles from LoginScreen logic broadly)
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title...',
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

          // List
          Expanded(
            child: _books.isEmpty && !_isLoading
                ? Center(
                    child: Text(
                      'No books found.',
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                  )
                : ListView.builder(
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

                      final book = _books[index];
                      return _buildBookItem(book, cardColor, textColor);
                    },
                  ),
          ),
        ],
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
          child: (book.coverUrl != null && book.coverUrl!.isNotEmpty)
              ? Image.network(
                  book.coverUrl!,
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
                  'Posted by ${book.postedBy ?? "Unknown"}',
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

  void _openPlayer(Book book) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerScreen(book: book),
    );
  }
}
