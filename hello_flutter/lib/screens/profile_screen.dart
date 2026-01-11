import 'package:flutter/material.dart' hide Badge;
import 'settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../repositories/book_repository.dart';
import '../models/book.dart';
import '../models/badge.dart';
import '../widgets/player_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  List<Book> _history = [];
  List<Badge> _badges = [];
  Map<String, dynamic> _stats = {
    'total_listening_time_seconds': 0,
    'books_completed': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadHistory();
    _loadStats();
    _loadBadges();
  }

  Future<void> _loadUser() async {
    try {
      final user = await AuthService().getUser();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final userId = await AuthService().getCurrentUserId();
      if (userId != null) {
        final stats = await BookRepository().getUserStats(userId);
        if (mounted) {
          setState(() {
            _stats = stats;
          });
        }
      }
    } catch (e) {
      print("Error loading stats: $e");
    }
  }

  Future<void> _loadHistory() async {
    try {
      final userId = await AuthService().getCurrentUserId();
      if (userId != null) {
        final history = await BookRepository().getListenHistory(userId);
        if (mounted) {
          setState(() {
            _history = history;
          });
        }
      }
    } catch (e) {
      print("Error loading history: $e");
    }
  }

  Future<void> _loadBadges() async {
    try {
      final userId = await AuthService().getCurrentUserId();
      if (userId != null) {
        final badges = await BookRepository().getBadges(userId);
        if (mounted) {
          setState(() {
            _badges = badges;
          });
        }
      }
    } catch (e) {
      print("Error loading badges: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        setState(() => _isLoading = true);
        final File imageFile = File(pickedFile.path);

        if (_user != null && _user!['id'] != null) {
          await AuthService().uploadProfilePicture(imageFile, _user!['id']);
          await _loadUser();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String _getProfilePictureUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    // Remove leading slash if present to avoid double slash with baseUrl
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${AuthService().baseUrl}/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Default to placeholders if user data is missing
    final userName = _user?['name'] ?? 'Guest User';
    final userEmail = _user?['email'] ?? 'No Email';

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Upper part - 30% of screen
          // We can use Flexible or SizedBox with MediaQuery relative height
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.30,
            width: double.infinity,
            child: Container(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blueAccent.shade100,
                              backgroundImage:
                                  _user?['profile_picture_url'] != null
                                  ? NetworkImage(
                                      _getProfilePictureUrl(
                                        _user!['profile_picture_url'],
                                      ),
                                    )
                                  : null,
                              child: _user?['profile_picture_url'] == null
                                  ? Text(
                                      userName.isNotEmpty
                                          ? userName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.white,
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, size: 15),
                                  onPressed: _pickImage,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.grey),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueAccent,
              tabs: [
                Tab(icon: Icon(Icons.history), text: 'Listen History'),
                Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
                Tab(icon: Icon(Icons.emoji_events), text: 'Badges'),
              ],
            ),
          ),

          // Lower part - Tab Views
          Expanded(
            child: TabBarView(
              children: [
                _buildHistoryTab(),
                _buildStatsTab(),
                _buildAchievementsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return const Center(child: Text('No listening history yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final book = _history[index];
        final position = book.lastPosition ?? 0;
        final duration = book.durationSeconds ?? 1; // avoid zero div
        final percent = (position / duration * 100)
            .clamp(0, 100)
            .toStringAsFixed(0);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(
              Icons.play_circle_fill,
              color: Colors.blueAccent,
            ),
            title: Text(book.title),
            subtitle: Text(
              'Last listened: ${book.lastAccessed?.toString().split('.')[0] ?? '?'}\nProgress: ${_formatDuration(position)} / ${_formatDuration(duration)}',
            ),
            trailing: Text('$percent%'),
            onTap: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(builder: (_) => PlayerScreen(book: book)),
                  )
                  .then((_) => _loadHistory()); // Reload history when returning
            },
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    if (seconds == 1 && _history.isEmpty)
      return "0:00"; // Hack for default 1 if duration missing
    final d = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final sec = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${twoDigits(d.inHours)}:' : ''}$minutes:$sec";
  }

  Widget _buildStatsTab() {
    final totalSeconds = _stats['total_listening_time_seconds'] as int? ?? 0;
    final totalBooks = _stats['books_completed'] as int? ?? 0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Listening Stats',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Time: ${_formatDuration(totalSeconds)}',
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            'Books Completed: $totalBooks',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    if (_badges.isEmpty) {
      return const Center(child: Text('No badges loaded yet'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _badges.length,
      itemBuilder: (context, index) {
        final badge = _badges[index];
        final isEarned = badge.isEarned;

        return InkWell(
          onTap: () => _showBadgeDetails(badge),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: isEarned ? Colors.amber : Colors.grey.shade300,
                child: Icon(
                  Icons.emoji_events,
                  color: isEarned ? Colors.white : Colors.grey,
                  size: 30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
                  color: isEarned ? Colors.black : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBadgeDetails(Badge badge) {
    showDialog(
      context: context,
      builder: (context) {
        double current = 0;
        if (badge.currentValue is num) {
          current = (badge.currentValue as num).toDouble();
        }
        final double progress = (current / badge.threshold).clamp(0.0, 1.0);
        final bool isEarned = badge.isEarned;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                size: 60,
                color: isEarned ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                badge.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: Colors.amber,
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                '${current.toStringAsFixed(0)} / ${badge.threshold}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (isEarned) ...[
                const SizedBox(height: 8),
                Text(
                  'Earned on ${badge.earnedAt?.toString().split(" ")[0] ?? ""}',
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
