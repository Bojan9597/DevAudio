import 'package:flutter/material.dart' hide Badge;
import 'settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../repositories/book_repository.dart';
import '../models/book.dart';
import '../models/badge.dart';
import '../models/subscription.dart';
import '../screens/playlist_screen.dart';
import '../widgets/subscription_bottom_sheet.dart';
import '../l10n/generated/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isAdmin = false;
  List<Book> _history = [];
  List<Badge> _badges = [];
  Subscription? _subscription;
  Map<String, dynamic> _stats = {
    'total_listening_time_seconds': 0,
    'books_completed': 0,
  };
  int _imageCacheKey = 0; // To force image refresh

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadHistory();
    _loadStats();
    _loadBadges();
    _loadSubscription();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AuthService().isAdmin();
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

  Future<void> _loadSubscription() async {
    try {
      final sub = await SubscriptionService().getSubscriptionStatus();
      if (mounted) {
        setState(() {
          _subscription = sub;
        });
      }
    } catch (e) {
      print("Error loading subscription: $e");
    }
  }

  void _showSubscriptionSheet({VoidCallback? onSubscribed}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubscriptionBottomSheet(
        onSubscribed: () {
          Navigator.pop(context);
          _loadSubscription(); // Refresh subscription status
          if (onSubscribed != null) {
            onSubscribed();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.subscriptionActivated,
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openBookWithSubscriptionCheck(Book book) async {
    // Admin always has access
    if (_isAdmin) {
      _navigateToBook(book);
      return;
    }

    // Check subscription
    final isSubscribed = await SubscriptionService().isSubscribed(
      forceRefresh: true,
    );
    if (isSubscribed) {
      _navigateToBook(book);
    } else {
      // Show subscription sheet, navigate after subscribing
      _showSubscriptionSheet(onSubscribed: () => _navigateToBook(book));
    }
  }

  void _navigateToBook(Book book) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => PlaylistScreen(book: book)))
        .then((_) => _loadHistory());
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
    // Compress image to avoid large upload failures
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024, // limit width
      maxHeight: 1024, // limit height
      imageQuality: 70, // compress quality
    );

    if (pickedFile != null) {
      try {
        setState(() => _isLoading = true);
        final File imageFile = File(pickedFile.path);

        if (_user != null && _user!['id'] != null) {
          await AuthService().uploadProfilePicture(imageFile, _user!['id']);
          await _loadUser();
          setState(() {
            _imageCacheKey++; // Increment to invalidate cache
          });
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

  String _formatSubscriptionDate(int timestamp) {
    // Server sends UTC timestamp
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    );
    final localDate = date.toLocal();
    final now = DateTime.now();
    final difference = localDate.difference(now);

    if (difference.inHours < 24) {
      // Show date and time for short subscriptions
      return '${localDate.day}/${localDate.month}/${localDate.year} ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    } else {
      // Show just date for longer subscriptions
      return '${localDate.day}/${localDate.month}/${localDate.year}';
    }
  }

  void _showSubscriptionDetails(Subscription sub) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.subscriptionDetails,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  AppLocalizations.of(context)!.planType,
                  _getLocalizedPlanName(sub.planType),
                ),
                _buildDetailRow(
                  AppLocalizations.of(context)!.status,
                  sub.isActive
                      ? (sub.isExpiringSoon
                            ? AppLocalizations.of(context)!.expiringSoon
                            : AppLocalizations.of(context)!.active)
                      : AppLocalizations.of(context)!.expired,
                ),
                if (sub.startDate != null)
                  _buildDetailRow(
                    AppLocalizations.of(context)!.started,
                    _formatSubscriptionDate(sub.startDate!),
                  ),
                if (sub.endDate != null)
                  _buildDetailRow(
                    AppLocalizations.of(context)!.expires,
                    _formatSubscriptionDate(sub.endDate!),
                  ),
                _buildDetailRow(
                  AppLocalizations.of(context)!.autoRenew,
                  sub.autoRenew
                      ? AppLocalizations.of(context)!.on
                      : AppLocalizations.of(context)!.off,
                ),

                const SizedBox(height: 24),

                if (sub.isActive && sub.autoRenew)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        _confirmCancelSubscription();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancelAutoRenewal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getLocalizedPlanName(String planType) {
    final l10n = AppLocalizations.of(context)!;
    switch (planType) {
      case 'test_minute':
        return l10n.planTestMinute;
      case 'monthly':
        return l10n.planMonthly;
      case 'yearly':
        return l10n.planYearly;
      case 'lifetime':
        return l10n.planLifetime;
      default:
        return planType;
    }
  }

  String _getLocalizedBadgeName(Badge badge) {
    final l10n = AppLocalizations.of(context)!;
    // Localize based on badge code pattern
    final code = badge.code.toLowerCase();
    if (code.contains('read') || code.contains('book')) {
      return l10n.badgeReadBooks(badge.threshold);
    } else if (code.contains('listen') || code.contains('hour')) {
      return l10n.badgeListenHours(badge.threshold);
    } else if (code.contains('quiz')) {
      return l10n.badgeCompleteQuiz;
    } else if (code.contains('first')) {
      return l10n.badgeFirstBook;
    } else if (code.contains('streak')) {
      return l10n.badgeStreak(badge.threshold);
    }
    // Fallback to server name
    return badge.name;
  }

  void _confirmCancelSubscription() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.turnOffAutoRenewal),
        content: Text(
          AppLocalizations.of(context)!.subscriptionWillRemainActive,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.keepOn),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelSubscription();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.turnOff),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSubscription() async {
    setState(() => _isLoading = true);
    try {
      final result = await SubscriptionService().cancelSubscription();
      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result['message'])));
          _loadSubscription(); // Refresh to see cancelled status
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Failed to cancel')),
          );
        }
      }
    } catch (e) {
      print('Error cancelling: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getProfilePictureUrl(String path) {
    String url;
    if (path.startsWith('http')) {
      url = path;
    } else {
      // Remove leading slash if present to avoid double slash with baseUrl
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      url = '${AuthService().baseUrl}/$cleanPath';
    }

    // Append cache busting query param
    return '$url?v=$_imageCacheKey';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Default to placeholders if user data is missing
    final userName = _user?['name'] ?? AppLocalizations.of(context)!.guestUser;
    final userEmail = _user?['email'] ?? AppLocalizations.of(context)!.noEmail;

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
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.5),
                              child: _user?['profile_picture_url'] != null
                                  ? ClipOval(
                                      child: Image.network(
                                        _getProfilePictureUrl(
                                          _user!['profile_picture_url'],
                                        ),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Text(
                                                userName.isNotEmpty
                                                    ? userName[0].toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  fontSize: 40,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            },
                                      ),
                                    )
                                  : Text(
                                      userName.isNotEmpty
                                          ? userName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 40,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: Theme.of(context).cardColor,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.camera_alt,
                                    size: 15,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  onPressed: _pickImage,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Subscription Status Badge (not shown for admin)
                        if (_isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade600,
                                  Colors.deepPurple.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.admin_panel_settings,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context)!.admin,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_subscription?.isActive == true)
                          InkWell(
                            onTap: () =>
                                _showSubscriptionDetails(_subscription!),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade600,
                                    Colors.orange.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _subscription!.endDate != null
                                        ? AppLocalizations.of(
                                            context,
                                          )!.premiumUntil(
                                            _formatSubscriptionDate(
                                              _subscription!.endDate!,
                                            ),
                                          )
                                        : AppLocalizations.of(
                                            context,
                                          )!.lifetimePremium,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          TextButton.icon(
                            onPressed: _showSubscriptionSheet,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: Icon(
                              Icons.star_border_rounded,
                              color: Colors.amber.shade600,
                              size: 18,
                            ),
                            label: Text(
                              AppLocalizations.of(context)!.upgradeToPremium,
                              style: TextStyle(
                                color: Colors.amber.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: Icon(
                        Icons.settings,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
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
            color:
                Theme.of(context).cardTheme.color ??
                Theme.of(context).cardColor,
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: [
                Tab(
                  icon: const Icon(Icons.history),
                  text: AppLocalizations.of(context)!.listenHistory,
                ),
                Tab(
                  icon: const Icon(Icons.bar_chart),
                  text: AppLocalizations.of(context)!.stats,
                ),
                Tab(
                  icon: const Icon(Icons.emoji_events),
                  text: AppLocalizations.of(context)!.badges,
                ),
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
      return RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Text(AppLocalizations.of(context)!.noListeningHistory),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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
              leading: Container(
                width: 50,
                height: 50,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                child: (book.coverUrl != null && book.coverUrl!.isNotEmpty)
                    ? Image.network(
                        book.absoluteCoverUrlThumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.play_circle_fill,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : Icon(
                        Icons.play_circle_fill,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
              title: Text(book.title),
              subtitle: Text(
                'Last listened: ${book.lastAccessed?.toString().split('.')[0] ?? '?'}\nProgress: ${_formatDuration(position)} / ${_formatDuration(duration)}',
              ),
              trailing: Text('$percent%'),
              onTap: () => _openBookWithSubscriptionCheck(book),
            ),
          );
        },
      ),
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

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bar_chart, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.listeningStats,
                    style: const TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.totalTime(_formatDuration(totalSeconds)),
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    AppLocalizations.of(context)!.booksCompleted(totalBooks),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    if (_badges.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadBadges,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Text(AppLocalizations.of(context)!.noBadgesYet),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBadges,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  backgroundColor: isEarned
                      ? Colors.amber
                      : Theme.of(context).disabledColor,
                  child: Icon(
                    Icons.emoji_events,
                    color: isEarned
                        ? Colors.white
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getLocalizedBadgeName(badge),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
                    color: isEarned
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
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
                color: isEarned
                    ? Colors.amber
                    : Theme.of(context).disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                _getLocalizedBadgeName(badge),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
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
                  AppLocalizations.of(context)!.earnedOn(badge.earnedAt?.toString().split(" ")[0] ?? ""),
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        );
      },
    );
  }
}
