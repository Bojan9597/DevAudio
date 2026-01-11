import 'package:flutter/material.dart';
import '../states/layout_state.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import 'player_screen.dart';

import '../screens/profile_screen.dart';

class ContentArea extends StatefulWidget {
  const ContentArea({super.key});

  @override
  State<ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<ContentArea> {
  List<Book> _allBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await BookRepository().getBooks();
      if (mounted) {
        setState(() {
          _allBooks = books;
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

        if (categoryId == 'profile') {
          return const ProfileScreen();
        }

        if (categoryId == 'library') {
          return _buildPlaceholder(categoryId);
        }

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredBooks = BookRepository().filterBooks(
          categoryId,
          _allBooks,
        );

        if (filteredBooks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.book_outlined, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No books found in "$categoryId"',
                  style: const TextStyle(color: Colors.grey, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Books in $categoryId',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      globalLayoutState.isGridView
                          ? Icons.view_list
                          : Icons.grid_view,
                    ),
                    onPressed: () => globalLayoutState.toggleViewMode(),
                    tooltip: globalLayoutState.isGridView
                        ? 'Switch to List'
                        : 'Switch to Grid',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: globalLayoutState.isGridView
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate column count targeting ~200px width
                          int crossAxisCount = (constraints.maxWidth / 200)
                              .toInt();
                          // Enforce minimum of 2 columns
                          if (crossAxisCount < 2) crossAxisCount = 2;

                          return GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                ),
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = filteredBooks[index];
                              return _buildBookCard(book);
                            },
                          );
                        },
                      )
                    : ListView.builder(
                        itemCount: filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = filteredBooks[index];
                          return _buildBookListTile(book);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(String title) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _openPlayer(Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerScreen(book: book),
    );
  }

  Widget _buildBookCard(Book book) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPlayer(book),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(color: Colors.blueAccent.shade100),
                child: const Center(
                  child: Icon(Icons.menu_book, size: 50, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // If space is too small, hide text completely
                    if (constraints.maxHeight < 35) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              book.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              book.author,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          decoration: BoxDecoration(
            color: Colors.blueAccent.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.menu_book, color: Colors.white),
        ),
        title: Text(
          book.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(book.author),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
