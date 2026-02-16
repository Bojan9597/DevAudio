import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../repositories/book_repository.dart';
import '../repositories/category_repository.dart';
import '../models/category.dart';
import '../services/auth_service.dart';
import '../app_layout.dart';
import '../states/layout_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color _accentColor = Color(0xFFF09A38);
  static const Color _bgColor = Color(0xFF111111);
  static const Color _cardColor = Color(0xFF1E1E1E);
  static const Color _surfaceColor = Color(0xFF2A2A2A);

  final PageController _pageController = PageController();
  final BookRepository _bookRepository = BookRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final AuthService _authService = AuthService();

  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1: Category selection
  List<Category> _allCategories = [];
  final Set<String> _selectedCategories = {};
  bool _loadingCategories = true;

  // Step 2: Daily listening goal
  int _selectedGoalMinutes = 15;
  bool _customGoal = false;
  double _customSliderValue = 30;
  final List<Map<String, dynamic>> _goalOptions = [
    {'label': '15 min', 'subtitle': 'Quick listener', 'minutes': 15},
    {'label': '30 min', 'subtitle': 'Casual listener', 'minutes': 30},
    {'label': '1 hr', 'subtitle': 'Deep diver', 'minutes': 60},
  ];

  // Step 3: Primary goal
  String _selectedGoal = '';
  final List<Map<String, String>> _goalChoices = [
    {
      'label': 'Entertainment',
      'icon': '🎭',
      'desc': 'Enjoy fascinating stories',
    },
    {
      'label': 'Learn new skills',
      'icon': '📚',
      'desc': 'Expand your knowledge',
    },
    {
      'label': 'Relaxation',
      'icon': '🧘',
      'desc': 'Unwind with calming content',
    },
    {'label': 'Personal growth', 'icon': '🌱', 'desc': 'Develop yourself'},
  ];

  // Step 4 (bonus): Book picks
  List<Map<String, dynamic>> _onboardingBooks = [];
  final Set<int> _selectedBookIds = {};
  bool _loadingBooks = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryRepository.getCategories();
      // Flatten: collect leaf categories (no children or empty children)
      final flat = <Category>[];
      void collectLeaves(List<Category> cats) {
        for (final cat in cats) {
          if (cat.children == null || cat.children!.isEmpty) {
            flat.add(cat);
          } else {
            collectLeaves(cat.children!);
          }
        }
      }

      collectLeaves(categories);
      if (mounted) {
        setState(() {
          _allCategories = flat;
          _loadingCategories = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadOnboardingBooks() async {
    if (_loadingBooks || _onboardingBooks.isNotEmpty) return;
    setState(() => _loadingBooks = true);
    try {
      // Show all books so user has a good selection
      final books = await _bookRepository.getOnboardingBooks();
      if (mounted) {
        setState(() {
          _onboardingBooks = books;
          _loadingBooks = false;
        });
      }
    } catch (e) {
      print('Error loading onboarding books: $e');
      if (mounted) setState(() => _loadingBooks = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedCategories.isEmpty) {
      _showSnack('Please select at least one topic');
      return;
    }
    if (_currentStep == 1 && _selectedGoal.isEmpty) {
      _showSnack('Please select your primary goal');
      return;
    }
    if (_currentStep == 2) {
      // Load books for step 3
      _onboardingBooks = [];
      _loadOnboardingBooks();
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isSaving = true);
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) return;

      await _bookRepository.savePreferences(
        userId: userId,
        categories: _selectedCategories.toList(),
        dailyGoalMinutes: _selectedGoalMinutes,
        primaryGoal: _selectedGoal,
        bookIds: _selectedBookIds.toList(),
      );

      // Always mark locally so user never gets stuck in onboarding loop
      await _authService.setHasPreferences(true);

      if (mounted) {
        await globalLayoutState.updateUser(userId.toString());
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const AppLayout()));
      }
    } catch (e) {
      // Still mark as complete locally to avoid infinite onboarding loop
      await _authService.setHasPreferences(true);
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const AppLayout()));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: i <= _currentStep ? _accentColor : _surfaceColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCategoryStep(),
                  _buildGoalStep(),
                  _buildListeningTimeStep(),
                  _buildBookPicksStep(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : (_currentStep < 3 ? _nextStep : _finishOnboarding),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              _currentStep < 3 ? 'Continue' : 'Get Started',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============= STEP 1: Categories =============
  Widget _buildCategoryStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What topics\ninterest you?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick at least one to personalize your experience',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _loadingCategories
                ? const Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _allCategories.map((cat) {
                        final selected = _selectedCategories.contains(cat.id);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedCategories.remove(cat.id);
                              } else {
                                _selectedCategories.add(cat.id);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? _accentColor : _cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? _accentColor : Colors.white12,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              _formatCategoryName(cat.title),
                              style: TextStyle(
                                color: selected ? Colors.black : Colors.white,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============= STEP 2: Primary Goal =============
  Widget _buildGoalStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your\nprimary goal?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us recommend the right content',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: _goalChoices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = _goalChoices[index];
                final selected = _selectedGoal == goal['label'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedGoal = goal['label']!);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: selected
                          ? _accentColor.withValues(alpha: 0.15)
                          : _cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? _accentColor : Colors.white10,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          goal['icon']!,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal['label']!,
                                style: TextStyle(
                                  color: selected ? _accentColor : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                goal['desc']!,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle,
                            color: _accentColor,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============= STEP 3: Listening Time (Options + Custom) =============
  Widget _buildListeningTimeStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How much do you\nlisten daily?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your daily listening target',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                // Preset options
                ..._goalOptions.map((option) {
                  final selected =
                      !_customGoal &&
                      _selectedGoalMinutes == option['minutes'] as int;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _customGoal = false;
                          _selectedGoalMinutes = option['minutes'] as int;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: selected
                              ? _accentColor.withValues(alpha: 0.15)
                              : _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? _accentColor : Colors.white10,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: selected
                                    ? _accentColor.withValues(alpha: 0.2)
                                    : _surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.headphones,
                                color: selected ? _accentColor : Colors.white38,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option['label'] as String,
                                    style: TextStyle(
                                      color: selected
                                          ? _accentColor
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    option['subtitle'] as String,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle,
                                color: _accentColor,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Custom option
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _customGoal = true;
                      _selectedGoalMinutes = _customSliderValue.round();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _customGoal
                          ? _accentColor.withValues(alpha: 0.15)
                          : _cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _customGoal ? _accentColor : Colors.white10,
                        width: _customGoal ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _customGoal
                                    ? _accentColor.withValues(alpha: 0.2)
                                    : _surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.tune,
                                color: _customGoal
                                    ? _accentColor
                                    : Colors.white38,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Custom',
                                    style: TextStyle(
                                      color: _customGoal
                                          ? _accentColor
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _customGoal
                                        ? '${_customSliderValue.round()} min'
                                        : 'Set your own target',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_customGoal)
                              Icon(
                                Icons.check_circle,
                                color: _accentColor,
                                size: 24,
                              ),
                          ],
                        ),
                        if (_customGoal) ...[
                          const SizedBox(height: 16),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: _accentColor,
                              inactiveTrackColor: _surfaceColor,
                              thumbColor: _accentColor,
                              overlayColor: _accentColor.withValues(alpha: 0.2),
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12,
                              ),
                            ),
                            child: Slider(
                              value: _customSliderValue,
                              min: 1,
                              max: 120,
                              divisions: 119,
                              onChanged: (value) {
                                setState(() {
                                  _customSliderValue = value;
                                  _selectedGoalMinutes = value.round();
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '1 min',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '2h',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============= STEP 4: Book Picks =============
  Widget _buildBookPicksStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pick books\nyou\'d enjoy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select books that catch your eye (optional)',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _loadingBooks
                ? const Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  )
                : _onboardingBooks.isEmpty
                ? Center(
                    child: Text(
                      'No books available yet',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(right: 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.62,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    itemCount: _onboardingBooks.length,
                    itemBuilder: (context, index) {
                      final book = _onboardingBooks[index];
                      final bookId =
                          int.tryParse(book['id']?.toString() ?? '') ?? 0;
                      final selected = _selectedBookIds.contains(bookId);
                      final coverUrl =
                          book['coverUrlThumbnail'] ?? book['coverUrl'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedBookIds.remove(bookId);
                            } else {
                              _selectedBookIds.add(bookId);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? _accentColor
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Cover image
                                coverUrl != null && coverUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: coverUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, _) => Container(
                                          color: _surfaceColor,
                                          child: const Icon(
                                            Icons.book,
                                            color: Colors.white24,
                                            size: 40,
                                          ),
                                        ),
                                        errorWidget: (_, _, _) => Container(
                                          color: _surfaceColor,
                                          child: const Icon(
                                            Icons.book,
                                            color: Colors.white24,
                                            size: 40,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: _surfaceColor,
                                        child: const Icon(
                                          Icons.book,
                                          color: Colors.white24,
                                          size: 40,
                                        ),
                                      ),

                                // Title overlay at bottom
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.85),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      book['title'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                // Selection checkmark
                                if (selected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: _accentColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.black,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatCategoryName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }
}
