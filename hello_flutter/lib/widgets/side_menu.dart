import 'package:flutter/material.dart';
import '../states/layout_state.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../services/auth_service.dart';
import '../main.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  List<Category> _categories = [];
  bool _isLoading = true;

  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryRepository().getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleExpansion(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLayoutState,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isCollapsed = globalLayoutState.isCollapsed;
        // 0 width when collapsed, 60% when expanded
        final width = isCollapsed ? 0.0 : (screenWidth * 0.75);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: width,
          color: Colors.blueGrey.shade900,
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Dynamic Categories - Takes up available space
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: _categories
                            .map((c) => _buildCategoryItem(c, 0, isCollapsed))
                            .toList(),
                      ),
              ),
              const Divider(color: Colors.white24),
              _buildLogoutItem(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(Category category, int level, bool isCollapsed) {
    // If collapsed, we only show top-level items
    if (isCollapsed && level > 0) return const SizedBox.shrink();

    final isSelected = globalLayoutState.selectedCategoryId == category.id;
    final hasChildren =
        category.children != null && category.children!.isNotEmpty;
    final isExpanded = _expandedIds.contains(category.id);

    Widget item = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Select the category
          globalLayoutState.setCategoryId(category.id);
          // Toggle expansion if it has children
          if (hasChildren && !isCollapsed) {
            _toggleExpansion(category.id);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: isSelected ? Colors.blueGrey.shade800 : null,
          padding: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: isCollapsed ? 10 : 10 + (level * 16.0),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showExpanded = !isCollapsed && constraints.maxWidth > 80;

              return Row(
                mainAxisAlignment: showExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    category.hasBooks ? Icons.book : Icons.folder,
                    color: isSelected ? Colors.blueAccent : Colors.white70,
                    size: 20,
                  ),
                  if (showExpanded) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category.title,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.white70,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasChildren)
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        color: Colors.white54,
                        size: 16,
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );

    if (hasChildren && isExpanded && !isCollapsed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          item,
          ...category.children!.map(
            (c) => _buildCategoryItem(c, level + 1, false),
          ),
        ],
      );
    }

    return item;
  }

  Widget _buildLogoutItem() {
    final isCollapsed = globalLayoutState.isCollapsed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await AuthService().logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthWrapper()),
              (route) => false,
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Row(
            mainAxisAlignment: isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              const Icon(Icons.logout, color: Colors.redAccent),
              if (!isCollapsed) ...[
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
