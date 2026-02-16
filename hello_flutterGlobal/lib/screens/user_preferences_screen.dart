import 'package:flutter/material.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../services/auth_service.dart';
import '../l10n/generated/app_localizations.dart';

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  final AuthService _authService = AuthService();
  final CategoryRepository _categoryRepository = CategoryRepository();

  bool _isLoading = true;
  bool _isSaving = false;

  // Data
  List<Category> _allCategories = [];

  // State
  final Set<String> _selectedCategories = {};
  int _dailyGoalMinutes = 15;
  String _primaryGoal = '';

  // Constants (matching Onboarding)
  static const Color _accentColor = Color(0xFFF09A38);
  static const Color _cardColor = Color(0xFF1E1E1E);

  final List<Map<String, dynamic>> _goalOptions = [
    {'label': '15 min', 'minutes': 15},
    {'label': '30 min', 'minutes': 30},
    {'label': '1 hr', 'minutes': 60},
  ];
  bool _showCustomSlider = false;

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Load Categories
      final categories = await _categoryRepository.getCategories();
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

      // 2. Load User Preferences
      final prefs = await _authService.getUserPreferences();

      setState(() {
        _allCategories = flat;

        if (prefs.isNotEmpty) {
          if (prefs['categories'] != null) {
            _selectedCategories.addAll(List<String>.from(prefs['categories']));
          }
          if (prefs['daily_goal_minutes'] != null) {
            _dailyGoalMinutes = prefs['daily_goal_minutes'];
            _showCustomSlider = !_goalOptions.any((o) => o['minutes'] == _dailyGoalMinutes);
          }
          if (prefs['primary_goal'] != null) {
            _primaryGoal = prefs['primary_goal'];
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      print("Error loading preferences: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    // Capture l10n before async gap or check mounted
    // We can't capture it here easily if context is invalid, but checking mounted helps.

    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) return;

      final success = await _authService.saveUserPreferences(
        userId: userId,
        categories: _selectedCategories.toList(),
        dailyGoalMinutes: _dailyGoalMinutes,
        primaryGoal: _primaryGoal,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.preferencesSaved)));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.failedToSavePreferences)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.userPreferences),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.save,
                    style: const TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(l10n.dailyGoal),
          _buildDailyGoalSection(),
          const SizedBox(height: 24),

          _buildSectionHeader(l10n.primaryGoal),
          _buildPrimaryGoalSection(),
          const SizedBox(height: 24),

          _buildSectionHeader(l10n.interests),
          _buildCategoriesSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDailyGoalSection() {
    final l10n = AppLocalizations.of(context)!;
    final isPreset = _goalOptions.any((o) => o['minutes'] == _dailyGoalMinutes);
    return Column(
      children: [
        Row(
          children: [
            ..._goalOptions.map((option) {
              final isSelected = !_showCustomSlider && _dailyGoalMinutes == option['minutes'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _showCustomSlider = false;
                    _dailyGoalMinutes = option['minutes'];
                  }),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _accentColor : _cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? _accentColor : Colors.white12,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      option['label'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showCustomSlider = true),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _showCustomSlider || !isPreset ? _accentColor : _cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _showCustomSlider || !isPreset ? _accentColor : Colors.white12,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.custom,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _showCustomSlider || !isPreset ? Colors.black : Colors.white,
                      fontWeight: _showCustomSlider || !isPreset
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_showCustomSlider || !isPreset) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _dailyGoalMinutes.toDouble().clamp(1, 120),
                  min: 1,
                  max: 120,
                  activeColor: _accentColor,
                  inactiveColor: _cardColor,
                  onChanged: (val) =>
                      setState(() => _dailyGoalMinutes = val.round()),
                ),
              ),
              Text(
                "$_dailyGoalMinutes min",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPrimaryGoalSection() {
    return Column(
      children: _goalChoices.map((goal) {
        final isSelected = _primaryGoal == goal['label'];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _accentColor : Colors.transparent,
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Text(goal['icon']!, style: const TextStyle(fontSize: 24)),
            title: Text(
              goal['label']!,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Text(
              goal['desc']!,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: _accentColor)
                : null,
            onTap: () => setState(() => _primaryGoal = goal['label']!),
            dense: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoriesSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allCategories.map((cat) {
        final isSelected = _selectedCategories.contains(cat.id);
        return FilterChip(
          label: Text(cat.title),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedCategories.add(cat.id);
              } else {
                _selectedCategories.remove(cat.id);
              }
            });
          },
          backgroundColor: _cardColor,
          selectedColor: _accentColor,
          labelStyle: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          checkmarkColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isSelected ? _accentColor : Colors.white12),
          ),
        );
      }).toList(),
    );
  }
}
