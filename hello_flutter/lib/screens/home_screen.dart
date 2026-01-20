import 'dart:async';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../repositories/book_repository.dart';
import '../repositories/category_repository.dart';
import '../states/layout_state.dart';
import '../utils/api_constants.dart';

import 'playlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookRepository _bookRepository = BookRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<Book> _books = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;

  // Hardcoded image names from the directory listing
  final List<String> _heroImages = [
    '1768942167_20251226_203128.jpg',
    '1768943401_20260120_192824.jpg',
    '1768942167_20251226_203128 copy.jpg',
    '1768943401_20260120_192824 copy.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
                  hintText: 'Search for books...',
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
                              'Get your imagination going',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'The best audiobooks and Originals. The most entertainment. The podcasts you want to hear.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor.withOpacity(0.8),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                // Action for trial
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[700],
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Continue to free trial',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Auto-renews at \$12.45/month after 30 days. Cancel anytime.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Image Collage
                            SizedBox(
                              height: 200,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // We'll place images in a fan-like or collage layout
                                  if (_heroImages.length >= 4) ...[
                                    _buildTiltImage(
                                      ApiConstants.baseUrl +
                                          '/static/homeImages/' +
                                          _heroImages[0],
                                      -15,
                                      -60,
                                      20,
                                    ),
                                    _buildTiltImage(
                                      ApiConstants.baseUrl +
                                          '/static/homeImages/' +
                                          _heroImages[1],
                                      -5,
                                      -20,
                                      10,
                                    ),
                                    _buildTiltImage(
                                      ApiConstants.baseUrl +
                                          '/static/homeImages/' +
                                          _heroImages[2],
                                      5,
                                      20,
                                      10,
                                    ),
                                    _buildTiltImage(
                                      ApiConstants.baseUrl +
                                          '/static/homeImages/' +
                                          _heroImages[3],
                                      15,
                                      60,
                                      20,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Categories Section
                  if (!_isLoadingCategories &&
                      _categories.isNotEmpty &&
                      _searchController.text.isEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: ActionChip(
                                    label: Text(cat.title),
                                    onPressed: () => _onCategoryTap(cat),
                                    backgroundColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    labelStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                  // Book List Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        _searchController.text.isNotEmpty
                            ? 'Search Results'
                            : 'All Books',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),

                  // Book List
                  if (_books.isEmpty && !_isLoading)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No books found.',
                          style: TextStyle(color: textColor.withOpacity(0.7)),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiltImage(
    String url,
    double angleDeg,
    double offsetX,
    double offsetY,
  ) {
    return Positioned(
      left: 0,
      right: 0,
      child: Transform.translate(
        offset: Offset(offsetX, offsetY),
        child: Transform.rotate(
          angle: angleDeg * 3.14159 / 180,
          child: Center(
            child: Container(
              height: 120,
              width: 120,
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
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, __) => Container(color: Colors.grey),
              ),
            ),
          ),
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
}
