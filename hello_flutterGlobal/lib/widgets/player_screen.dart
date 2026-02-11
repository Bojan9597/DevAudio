import 'package:flutter/material.dart' hide Badge;
import 'package:screen_brightness/screen_brightness.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../l10n/generated/app_localizations.dart';
import '../models/book.dart';

import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:ui'; // For BackdropFilter
import '../repositories/book_repository.dart';
import '../services/auth_service.dart';
import '../services/player_preferences.dart';
import 'badge_dialog.dart';
import 'subscription_bottom_sheet.dart';
// import '../models/badge.dart'; // Unused
import '../services/download_service.dart';
import '../utils/api_constants.dart';
import '../services/subscription_service.dart';
import '../screens/quiz_taker_screen.dart'; // Import QuizTakerScreen
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart'; // Import for audioHandler

class PlayerScreen extends StatefulWidget {
  final Book book;
  final String uniqueAudioId;
  final VoidCallback? onPurchaseSuccess;
  final List<Map<String, dynamic>>? playlist;
  final int initialIndex;

  /// Track if the app is in foreground (shared across instances)
  static bool isAppInForeground = true;
  final Function(int)? onPlaybackComplete;
  final Map<String, dynamic> trackQuizzes;
  final String? bookTitle; // Add bookTitle parameter

  const PlayerScreen({
    super.key,
    required this.book,
    required this.uniqueAudioId,
    this.onPurchaseSuccess,
    this.playlist,
    this.initialIndex = 0,
    this.onPlaybackComplete,
    this.trackQuizzes = const {},
    this.bookTitle, // Initialize
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  // Use global audio handler
  AudioPlayer get _player => audioHandler.player;
  late Book _currentBook;
  late int _currentIndex;

  bool _isSleepTimerActive = false;
  double _playbackSpeed = 1.0;
  double? _originalBrightness;
  bool _isPopping = false; // Prevent double pops on completion
  // ... brightness methods ...
  Future<void> _resetBrightness() async {
    if (kIsWeb) return; // Skip on web
    if (_originalBrightness != null) {
      try {
        await ScreenBrightness().setScreenBrightness(_originalBrightness!);
      } catch (e) {
        debugPrint('Failed to reset brightness: $e');
        await ScreenBrightness().resetScreenBrightness();
      }
    } else {
      try {
        await ScreenBrightness().resetScreenBrightness();
      } catch (e) {
        /* ignore */
      }
    }
  }

  Future<void> _toggleSleepMode() async {
    setState(() {
      _isSleepTimerActive = !_isSleepTimerActive;
    });

    if (kIsWeb) return; // Skip brightness logic on web

    try {
      if (_isSleepTimerActive) {
        // Turning ON: Save current and dim
        _originalBrightness = await ScreenBrightness().current;
        await ScreenBrightness().setScreenBrightness(
          0.01,
        ); // Minimum brightness
      } else {
        // Turning OFF: Restore
        await _resetBrightness();
      }
    } catch (e) {
      debugPrint('Error toggling sleep mode brightness: $e');
    }
  }

  // Purchase/Subscription State
  bool _isPurchased = false;
  bool _isLoadingOwnership = true;
  bool _isAdmin = false;
  int? _userId;
  bool _isFavorite = false;
  bool _isDownloading = false;
  String? _lastError; // Track last error to avoid duplicate messages
  bool _isInitializingPlayer = false; // Prevent concurrent player init
  bool _isHandlingCompletion =
      false; // Prevent double-handling of track completion
  bool _isDraggingSlider = false; // Track when user is dragging progress slider
  double _dragSliderValue = 0.0; // Temporary value while dragging

  final GlobalKey _speedButtonKey = GlobalKey();
  final GlobalKey _moreButtonKey = GlobalKey();

  late PageController _pageController;
  Timer? _progressTimer;

  // Background Music - managed by audioHandler for background continuity
  List<Map<String, dynamic>> _bgMusicList = [];
  // Volume and selectedBgMusicId are accessed via audioHandler

  // Player Preferences
  int _skipBackwardSeconds = 10;

  int _skipForwardSeconds = 30;
  int? _userPreferredBgMusicId; // Store user preference from server

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentBook = widget.book;
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _isFavorite = widget.book.isFavorite;
    _loadPlayerPreferences(); // Load preferences first
    _initializeAll();

    // Listen to speed changes to keep UI in sync
    _speedSubscription = _player.speedStream.listen((speed) {
      if (mounted) {
        setState(() {
          _playbackSpeed = speed;
        });
      }
    });
  }

  Future<void> _loadPlayerPreferences() async {
    final prefs = PlayerPreferences();
    final backward = await prefs.getSkipBackward();
    final forward = await prefs.getSkipForward();
    final defaultSpeed = await prefs.getDefaultSpeed();

    if (mounted) {
      setState(() {
        _skipBackwardSeconds = backward;
        _skipForwardSeconds = forward;
        // Only set speed if it's the default 1.0 (meaning user hasn't changed it for this session yet)
        if (_playbackSpeed == 1.0 && defaultSpeed != 1.0) {
          _playbackSpeed = defaultSpeed;
          _player.setSpeed(defaultSpeed);
        }
      });
    }
  }

  /// Initialize everything in the correct order
  Future<void> _initializeAll() async {
    try {
      // First, load the background music list - needed by both _initBgMusic and _initPlayer
      try {
        _bgMusicList = await BookRepository().getBackgroundMusicList();
      } catch (e) {
        debugPrint("[PlayerScreen] Failed to load background music list: $e");
        // Don't block player init if bg music fails
      }

      // Now initialize player (bg music is started inside _initPlayer right after play())
      await _init();
    } catch (e) {
      debugPrint("[PlayerScreen] Fatal error in _initializeAll: $e");
      if (mounted) {
        setState(() {
          _isInitializingPlayer = false; // Ensure spinner disappears
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error initializing player: $e")),
        );
      }
    }
  }

  Future<void> _init() async {
    await _initPlayer();
    _checkOwnership();

    // Listen for completion
    _playerStateSubscription = _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        if (!mounted) return;

        // Prevent double-handling (e.g., after returning from quiz)
        if (_isHandlingCompletion) return;
        _isHandlingCompletion = true;

        // Capture the current track index NOW before any async operations
        final completedIndex = _currentIndex;
        final completedTrackId = widget.playlist != null
            ? widget.playlist![completedIndex]['id'].toString()
            : null;

        // Mark track as completed in backend
        Future<List<dynamic>>? badgeFuture;
        if (_userId != null && completedTrackId != null) {
          badgeFuture = BookRepository().completeTrack(
            _userId!,
            completedTrackId,
          );
        }

        // Handle Single Book Completion (Show Overlay)
        if (widget.playlist == null) {
          // Playlist Track Completion or Single Book Completion
          // Show badges immediately if any
          if (badgeFuture != null) {
            badgeFuture.then((newBadges) {
              if (mounted && newBadges.isNotEmpty) {
                for (var badge in newBadges) {
                  BadgeDialog.show(context, badge);
                }
              }
            });
          }
          _isHandlingCompletion = false;
        } else {
          // Playlist Track Completion
          // Show badges immediately for track (if any)
          if (badgeFuture != null) {
            badgeFuture.then((newBadges) {
              if (mounted && newBadges.isNotEmpty) {
                for (var badge in newBadges) {
                  BadgeDialog.show(context, badge);
                }
              }
            });
          }

          if (widget.onPlaybackComplete != null) {
            widget.onPlaybackComplete!(completedIndex);
          }

          // Check for Quiz on the track that JUST finished
          bool hasQuiz = false;
          bool isPassed = false;

          if (widget.playlist != null &&
              widget.trackQuizzes != null && // Removed redundant check
              completedTrackId != null) {
            if (widget.trackQuizzes!.containsKey(completedTrackId)) {
              hasQuiz =
                  widget.trackQuizzes![completedTrackId]['has_quiz'] ?? false;
              isPassed =
                  widget.trackQuizzes![completedTrackId]['is_passed'] ?? false;
            }
          }

          if (hasQuiz && !isPassed && PlayerScreen.isAppInForeground) {
            // Stop audio before navigating to quiz (only in foreground)
            await _player.stop();

            // Navigate to Quiz for the COMPLETED track
            Future.microtask(() async {
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizTakerScreen(
                      bookId: widget.book.id,
                      playlistItemId: int.parse(completedTrackId!),
                    ),
                  ),
                );

                // After quiz, advance to next track using existing flow
                _isHandlingCompletion = false;
                if (mounted && widget.playlist != null) {
                  // Use same flow as non-quiz path - this properly handles page transition and audio loading
                  _playNext();
                  // Auto-play the next track and start background music
                  await Future.delayed(
                    const Duration(milliseconds: 500),
                  ); // Wait for player to load
                  if (mounted) {
                    await audioHandler.play();
                  }
                }
              }
            });
          } else {
            // In background mode OR no quiz: just advance to next track
            _isHandlingCompletion = false;
            if (widget.playlist != null &&
                _currentIndex < widget.playlist!.length - 1) {
              _playNext();
            } else {
              // End of playlist handled in _playNext usually, but if we are here and its end?
              // _playNext checks this logic too.
              _playNext();
            }
          }
        }
      }
    });
  }

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<double>? _speedSubscription;

  String _getUniqueAudioId() {
    if (widget.playlist != null && widget.playlist!.isNotEmpty) {
      final track = widget.playlist![_currentIndex];
      return "track_${track['id']}";
    }
    return widget.uniqueAudioId ?? widget.book.id;
  }

  String _getAbsoluteUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${ApiConstants.baseUrl}${path.startsWith('/') ? '' : '/'}$path';
  }

  void _playNext() {
    if (widget.playlist == null) return;

    if (_currentIndex >= widget.playlist!.length - 1) {
      if (_isPopping) return;
      _isPopping = true;

      // End of playlist - save progress and stop
      _saveProgressImmediately();

      // Stop playback and seek to start of track to appear "reset"
      _player.pause();
      _player.seek(Duration.zero);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.playlistCompleted),
            duration: const Duration(seconds: 2),
          ),
        );
        // Optionally pop? The user didn't explicitly ask to close, just "stop playing".
        // If we pop, we return to map.
        Navigator.pop(context);
      }
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Save progress immediately (used when book finishes)
  Future<void> _saveProgressImmediately() async {
    if (_userId == null) return;

    final position = _player.position.inSeconds;
    final duration = _player.duration?.inSeconds;

    String? playlistItemId;
    if (widget.playlist != null && widget.playlist!.isNotEmpty) {
      final currentTrack = widget.playlist![_currentIndex];
      playlistItemId = currentTrack['id'].toString();
    }

    try {
      await BookRepository().updateProgress(
        _userId!,
        widget.book.id,
        position,
        duration,
        playlistItemId: playlistItemId,
      );
    } catch (e) {
      debugPrint('Error saving final progress: $e');
    }
  }

  void _playPrevious() {
    if (widget.playlist == null || _currentIndex <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Book _getBookAtIndex(int index) {
    if (widget.playlist == null) return widget.book;

    final track = widget.playlist![index];
    final trackUrl = _getAbsoluteUrl(track['file_path']);

    return Book(
      id: widget.book.id, // Same parent ID
      title: track['title'],
      author: widget.book.author,
      audioUrl: trackUrl,
      coverUrl: widget.book.absoluteCoverUrl,
      categoryId: widget.book.categoryId,
      subcategoryIds: const [],
      postedBy: widget.book.postedBy,
      description: widget.book.description,
      price: widget.book.price,
      postedByUserId: widget.book.postedByUserId,
      isPlaylist: false,
      isFavorite: _isFavorite,
    );
  }

  void _onPageChanged(int index) {
    if (widget.playlist != null && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
        _loadTrackAtIndex(_currentIndex);
      });
    }
  }

  void _loadTrackAtIndex(int index) {
    // Create new book object for state
    _currentBook = _getBookAtIndex(index);

    _initPlayer();
    // Ownership check shouldn't change for same album, but download status might.
    // So _initPlayer handles loading local file or URL.
  }

  Future<void> _checkOwnership() async {
    try {
      final userId = await AuthService().getCurrentUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoadingOwnership = false;
            _isPurchased = false;
          });
        }
        return;
      }

      if (mounted) {
        _userId = userId;

        // Set userId on audioHandler for background progress sync
        audioHandler.setUserId(userId);
      }

      // Check if user is admin - admin always has access
      final isAdmin = await AuthService().isAdmin();

      // Parallel fetch for better performance
      final results = await Future.wait([
        BookRepository().getPurchasedBookIds(userId),
        BookRepository().getFavoriteBookIds(userId),
      ]);

      final purchasedIds = results[0] as List<String>;
      final favoriteIds =
          results[1] as List<int>; // getFavoriteBookIds returns List<int>

      final isOwned = purchasedIds.contains(widget.book.id);
      // Ensure we compare int to int or string to string. widget.book.id is String.
      final isFav = favoriteIds.contains(int.tryParse(widget.book.id) ?? -1);

      // Check access logic:
      // 1. Admin always has access
      // 2. Free books (!isPremium) always have access
      // 3. Purchased books always have access
      // 4. Subscribed users have access (checked in PlaylistScreen, passed implicitly via 'isSubscribed' check there? No, we check here too)

      // Wait, PlayerScreen checks ownership via api calls.
      // But PlaylistScreen ALREADY checked access.
      // If we are in PlayerScreen, we SHOULD assume access is granted unless we want to double check.
      // However, PlayerScreen handles "Subscription Overlay" itself (lines 1492+).

      // We need to verify if user is SUBSCRIBED here too, OR trust the caller.
      // Currently, it only checks `getPurchasedBookIds`. It DOES NOT check SubscriptionService.
      // We should check SubscriptionService OR check isPremium.

      final isSubscribed = await SubscriptionService().isSubscribed();
      final isFree = !widget.book.isPremium;

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isPurchased = isAdmin || isOwned || isSubscribed || isFree;
          _isFavorite = isFav; // Update favorite status from backend
          _isLoadingOwnership = false;
        });
      }

      if (_isPurchased && mounted) {
        _startProgressSync();
      } else if (!_isPurchased && mounted) {
        // Stop playback if user doesn't have access
        await _player.stop();
      }
    } catch (e) {
      print("Error checking ownership/favorites: $e");
      if (mounted) {
        setState(() => _isLoadingOwnership = false);
      }
    }
  }

  void _showSubscriptionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubscriptionBottomSheet(
        onSubscribed: () {
          Navigator.pop(context); // Close bottom sheet
          _onSubscriptionSuccess();
        },
      ),
    );
  }

  Future<void> _onSubscriptionSuccess() async {
    // Refresh subscription status and unlock content
    setState(() {
      _isPurchased = true;
    });
    _startProgressSync();

    // Add book to user's library for tracking
    if (_userId != null) {
      try {
        final newBadges = await BookRepository().buyBook(
          _userId!,
          widget.book.id,
        );

        if (mounted) {
          for (var badge in newBadges) {
            BadgeDialog.show(context, badge);
          }
        }
      } catch (e) {
        // Ignore errors - subscription is active, book access is granted
        print('Error adding book to library: $e');
      }
    }

    if (widget.onPurchaseSuccess != null) {
      widget.onPurchaseSuccess!();
    } else {
      _downloadBook();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.subscriptionActivatedSuccess,
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showDownloadingMessage({bool isPlaylist = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPlaylist
              ? AppLocalizations.of(context)!.downloadingFullPlaylist
              : AppLocalizations.of(context)!.downloadingForOfflinePlayback,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadBook() async {
    setState(() => _isDownloading = true);
    try {
      if (widget.playlist != null && widget.playlist!.isNotEmpty) {
        // Download entire playlist
        _showDownloadingMessage(isPlaylist: true);
        await DownloadService().downloadPlaylist(
          widget.playlist!,
          widget.book.id,
          userId: _userId,
        );
      } else {
        // Download single book
        _showDownloadingMessage();
        await DownloadService().downloadBook(
          _getUniqueAudioId(),
          _currentBook.audioUrl,
          userId: _userId,
          bookId: widget.book.id,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.downloadCompleteAvailableOffline,
            ),
          ),
        );
        // Re-init player to pickup local file if currently playing
        _initPlayer();
      }
    } catch (e) {
      print("Download error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _initPlayer() async {
    // Prevent concurrent initialization
    if (_isInitializingPlayer) {
      print("[DEBUG][PlayerScreen] Already initializing, skipping");
      return;
    }
    _isInitializingPlayer = true;

    try {
      String url = _currentBook.audioUrl;
      final uniqueAudioId = _getUniqueAudioId();

      // Check if this exact track is already loaded - if so, don't reload
      if (audioHandler.currentUniqueAudioId == widget.uniqueAudioId &&
          audioHandler.currentIndex == _currentIndex &&
          _player.processingState != ProcessingState.idle) {
        // Same track is already loaded, don't reload
        print(
          "[DEBUG][PlayerScreen] Same track already loaded, skipping reload",
        );

        // FIX: Fetch latest user preference for BG music even if track is loaded
        try {
          _userId ??= await AuthService().getCurrentUserId();
          if (_userId != null) {
            final status = await BookRepository().getBookStatus(
              _userId!,
              widget.book.id,
            );
            if (status.containsKey('background_music_id')) {
              final rawId = status['background_music_id'];
              print(
                '[DEBUG][PlayerScreen] (Early) Found stored BG music preference: $rawId',
              );
              if (rawId is int) {
                _userPreferredBgMusicId = rawId;
              }
            }
          }
        } catch (e) {
          print("[DEBUG] Error fetching status in early return: $e");
        }

        // Still ensure bg music is synced (fire and forget)
        await _initBgMusic();
        _isInitializingPlayer = false;
        return;
      }

      // Create MediaItem for notification
      final mediaItem = MediaItem(
        id: uniqueAudioId,
        album: widget.book.title,
        title: _currentBook.title,
        artist: widget.book.author,
        artUri:
            (widget.book.absoluteCoverUrl != null &&
                widget.book.absoluteCoverUrl!.isNotEmpty)
            ? Uri.parse(widget.book.absoluteCoverUrl!)
            : null,
        extras: {'launchId': DateTime.now().millisecondsSinceEpoch.toString()},
      );

      // Store context in audioHandler for mini player
      audioHandler.currentBook = _currentBook;
      audioHandler.currentPlaylist = widget.playlist;
      audioHandler.currentIndex = _currentIndex;
      audioHandler.currentUniqueAudioId = widget.uniqueAudioId;

      final authService = AuthService();

      // Ensure we have userId for user-specific storage lookup
      // This fixes race condition where _initPlayer runs before _checkOwnership completes
      _userId ??= await authService.getCurrentUserId();

      // Check for local file (user-specific storage)
      final storageId = _getUniqueAudioId();
      final downloadService = DownloadService();
      final isDownloaded = await downloadService.isBookDownloaded(
        storageId,
        userId: _userId,
        bookId: widget.book.id,
      );

      print(
        "[DEBUG][PlayerScreen] isDownloaded=$isDownloaded, url=$url, userId=$_userId, storageId=$storageId",
      );

      if (isDownloaded) {
        // Play from local file (user explicitly downloaded this book)
        final playPath = await downloadService.getLocalBookPath(
          storageId,
          userId: _userId,
          bookId: widget.book.id,
        );
        print("[DEBUG][PlayerScreen] Playing from local file: $playPath");
        await audioHandler.loadLocalFile(playPath, mediaItem);
      } else {
        // Stream from URL (no auto-download)
        final cleanUrl = url.startsWith('http')
            ? url
            : '${ApiConstants.baseUrl}$url';
        print("[DEBUG][PlayerScreen] Streaming from URL: $cleanUrl");
        await audioHandler.loadAudio(cleanUrl, mediaItem);
      }

      // Load background music BEFORE auto-play to ensure proper sync
      // This ensures background music is ready when main player starts
      await _initBgMusic();

      // Auto-play when player screen is opened
      await audioHandler.play();

      // Clear any previous error since we succeeded
      _lastError = null;

      // Resume logic
      if (_userId != null) {
        String? trackId = widget.playlist != null
            ? widget.playlist![_currentIndex]['id'].toString()
            : null;

        final status = await BookRepository().getBookStatus(
          _userId!,
          widget.book.id,
          trackId: trackId,
        );

        final savedPosition = status['position_seconds'] as int? ?? 0;

        // If user has a saved bg music preference, switch to it
        if (status.containsKey('background_music_id')) {
          final rawId = status['background_music_id'];
          print(
            '[DEBUG][PlayerScreen] Found stored BG music preference: $rawId',
          );
          if (rawId is int) {
            _userPreferredBgMusicId = rawId;
            // Update bg music if user preference differs from what was loaded
            if (rawId != audioHandler.selectedBgMusicId) {
              print(
                '[DEBUG][PlayerScreen] Switching BG music to preferred: $rawId',
              );
              _updateBgMusicSource(rawId);
            } else {
              print(
                '[DEBUG][PlayerScreen] Preferred BG music already active: $rawId',
              );
            }
          } else if (rawId == null) {
            // Handle explicit "None" if needed, though null usually means "default"
            print(
              '[DEBUG][PlayerScreen] Stored BG music is NULL (Default/None)',
            );
          }
        } else {
          print(
            '[DEBUG][PlayerScreen] No background_music_id in status response',
          );
        }

        if (savedPosition > 0) {
          await _player.seek(Duration(seconds: savedPosition));
        }
      }

      // Safety net: after all async ops (load, play, seek) settle,
      // force-sync bg music in case the retry loop in setBgMusicSource
      // was beaten by a concurrent state change (e.g., seek buffering).
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) audioHandler.syncBgMusic();
      });
    } catch (e) {
      final errorMsg = e.toString();
      debugPrint("[DEBUG][PlayerScreen] Error loading audio: $errorMsg");

      // Only show error if it's different from last error (avoid spam)
      if (_lastError != errorMsg && mounted) {
        _lastError = errorMsg;
        await _player.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load audio: $errorMsg")),
        );
      }
    } finally {
      _isInitializingPlayer = false;
    }
  }

  void _startProgressSync() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _saveProgress();
    });
  }

  Future<void> _saveProgress() async {
    if (_userId != null && _player.playing) {
      final position = _player.position.inSeconds;
      final duration = _player.duration?.inSeconds;
      if (position > 0) {
        // Get playlist_item_id if this is a playlist track
        String? playlistItemId;
        if (widget.playlist != null && widget.playlist!.isNotEmpty) {
          final currentTrack = widget.playlist![_currentIndex];
          playlistItemId = currentTrack['id'].toString();
        }

        final newBadges = await BookRepository().updateProgress(
          _userId!,
          widget.book.id,
          position,
          duration,
          playlistItemId: playlistItemId,
        );

        if (newBadges.isNotEmpty && mounted) {
          // If we earned a badge, maybe pause? Or just show dialog over it.
          // Dialog over it is fine.
          for (var badge in newBadges) {
            BadgeDialog.show(context, badge);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resetBrightness(); // Reset brightness on exit
    _progressTimer?.cancel();
    _playerStateSubscription?.cancel();
    _speedSubscription?.cancel();
    _saveProgress(); // Try to save on exit
    _pageController.dispose();
    // Don't dispose handler players - they're global (both main and background music)
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Track app foreground/background state for quiz handling
    PlayerScreen.isAppInForeground = (state == AppLifecycleState.resumed);
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$minutes:$seconds";
  }

  void _toggleFavorite() async {
    if (_userId == null) {
      // Prompt logic? Or just return.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to use favorites')),
      );
      return;
    }

    // Optimistic update
    setState(() {
      _isFavorite = !_isFavorite;
    });

    final success = await BookRepository().toggleFavorite(
      _userId!,
      widget.book.id,
      !_isFavorite, // Pass OLD state (if it was favorite, we pass true to remove)
    );

    if (!success) {
      // Revert if failed
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorite')),
        );
      }
    }
  }

  void _showSpeedMenu() async {
    // ... (keep existing)
    final RenderBox button =
        _speedButtonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final double? selectedSpeed = await showMenu<double>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(value: 0.5, child: Text('0.5x')),
        const PopupMenuItem(value: 1.0, child: Text('1.0x')),
        const PopupMenuItem(value: 2.0, child: Text('2.0x')),
      ],
      elevation: 8.0,
    );

    if (selectedSpeed != null) {
      _player.setSpeed(selectedSpeed);
      // Sync to preferences
      await PlayerPreferences().setDefaultSpeed(selectedSpeed);
      setState(() {
        _playbackSpeed = selectedSpeed;
      });
    }
  }

  void _showMoreMenu() async {
    final RenderBox button =
        _moreButtonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    // Calculate position to spawn menu right above the button
    final buttonRect =
        button.localToGlobal(Offset.zero, ancestor: overlay) & button.size;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(
        buttonRect.left,
        buttonRect.top - 110, // Shift up by approx menu height (2 items)
        buttonRect.width,
        buttonRect.height,
      ),
      Offset.zero & overlay.size,
    );

    final String? selectedValue = await showMenu<String>(
      context: context,
      position: position,
      items: [
        if (_isPurchased) // Only show Rate for subscribed users
          PopupMenuItem(
            value: 'rate',
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.rate),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.black54),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.details),
            ],
          ),
        ),
      ],
      elevation: 8.0,
    );

    if (selectedValue == 'rate') {
      _showRatingDialog();
    } else if (selectedValue == 'details') {
      _showBookDetailsDialog();
    }
  }

  void _showRatingDialog() {
    int selectedStars = 0;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.brown.shade900, Colors.black],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rate this book',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.book.title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedStars = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              index < selectedStars
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 40,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: selectedStars > 0
                              ? () async {
                                  Navigator.of(context).pop();
                                  await _submitRating(selectedStars);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitRating(int stars) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return;

      final response =
          await Dio(
            BaseOptions(
              headers: {
                ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
              },
            ),
          ).post(
            '${ApiConstants.baseUrl}/books/${widget.book.id}/rate',
            data: {'user_id': userId, 'stars': stars},
            options: Options(headers: await _getAuthHeaders()),
          );

      if (response.statusCode == 200 && mounted) {
        // Update local book rating if response includes updated rating
        if (response.data != null && response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          if (data['averageRating'] != null) {
            setState(() {
              _currentBook = _currentBook.copyWith(
                averageRating: (data['averageRating'] as num).toDouble(),
                ratingCount:
                    data['ratingCount'] as int? ?? _currentBook.ratingCount,
              );
            });
          }
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Thanks for rating! ⭐' * stars)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit rating: $e')));
      }
    }
  }

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {'Authorization': 'Bearer $token'};
  }

  void _showBookDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.brown.shade900, Colors.black],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.bookInformation,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.book.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.book.author,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      widget.book.description ?? 'No description available.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.book.price != null && widget.book.price! > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.sell, color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Price: \$${widget.book.price!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.category, color: Colors.white54, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Category: ${_currentBook.categoryId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: widget.playlist?.length ?? 1,
        itemBuilder: (context, index) {
          return _buildPlayerPage(context, index);
        },
      ),
    );
  }

  Widget _buildPlayerPage(BuildContext context, int index) {
    final localBook = _getBookAtIndex(index);
    final isCurrent = index == _currentIndex;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.brown.shade800,
                  Colors.brown.shade900,
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Down Arrow (Left)
                            IconButton(
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),

                            // 2. Center Content (Return to Lesson Map)
                            Expanded(
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(
                                    Icons.map_outlined,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  label: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.returnToLessonMap,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 3. Dummy Right Widget (Balance for centering)
                            const SizedBox(width: 48), // Approx IconButton size
                          ],
                        ),

                        // Removed the "Title" Text widget below as requested ("put it instead of...")
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Album Art
                  // Album Art - 35% of screen height, square
                  Column(
                    children: [
                      // Background Music Button (Moved here, closer to cover)
                      GestureDetector(
                        onTap: _showBgMusicSettings,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, // Bigger horizontal padding
                            vertical: 10, // Bigger vertical padding
                          ),
                          decoration: BoxDecoration(
                            color: audioHandler.selectedBgMusicId != null
                                ? Colors.blueAccent.withOpacity(0.4)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              30,
                            ), // More rounded
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 20, // Bigger icon
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.backgroundMusic,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14, // Bigger text
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ), // Spacing between button and art
                      Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        width: MediaQuery.of(context).size.height * 0.35,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child:
                            (localBook.coverUrl != null &&
                                localBook.coverUrl!.isNotEmpty)
                            ? Image.network(
                                localBook.absoluteCoverUrl,
                                headers: ApiConstants.imageHeaders,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.music_note,
                                      size: 80,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                              )
                            : Icon(
                                Icons.music_note,
                                size: 80,
                                color: Colors.white.withOpacity(0.5),
                              ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // Title and Author
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Container(
                          height: 40,
                          alignment: Alignment.center,
                          child: _ScrollingText(
                            text: localBook.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localBook.author,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Progress Bar (StreamBuilder)
                  if (isCurrent)
                    StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = _player.duration ?? Duration.zero;

                        // Limit slider value to duration
                        double sliderValue = position.inSeconds.toDouble();
                        double maxDuration = duration.inSeconds.toDouble();
                        if (sliderValue > maxDuration)
                          sliderValue = maxDuration;
                        if (maxDuration <= 0)
                          maxDuration = 1; // Avoid div by zero

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.white.withOpacity(0.2),
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                ),
                                child: Slider(
                                  value:
                                      (_isDraggingSlider
                                              ? _dragSliderValue
                                              : sliderValue)
                                          .clamp(0.0, maxDuration),
                                  min: 0.0,
                                  max: maxDuration,
                                  onChangeStart: (v) {
                                    setState(() {
                                      _isDraggingSlider = true;
                                      _dragSliderValue = v;
                                    });
                                  },
                                  onChanged: (v) {
                                    setState(() {
                                      _dragSliderValue = v;
                                    });
                                  },
                                  onChangeEnd: (v) {
                                    _player.seek(Duration(seconds: v.toInt()));
                                    setState(() {
                                      _isDraggingSlider = false;
                                    });
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatTime(position),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(duration - position),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                            ),
                            child: Slider(
                              value: 0,
                              min: 0.0,
                              max: 100.0,
                              onChanged: null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "00:00",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "00:00",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Playback Controls
                  if (isCurrent)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.replay, size: 32),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '$_skipBackwardSeconds',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          color: Colors.white,
                          iconSize: 32,
                          onPressed: () {
                            _player.seek(
                              _player.position -
                                  Duration(seconds: _skipBackwardSeconds),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          color: Colors.white,
                          iconSize: 40,
                          onPressed: _playPrevious,
                        ),

                        // Play/Pause Button
                        StreamBuilder<PlayerState>(
                          stream: _player.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final processingState =
                                playerState?.processingState;
                            final playing = playerState?.playing;

                            // Only show spinner if we are loading/buffering AND NOT playing.
                            // If we are playing but buffering (e.g. slow network), we still want to show Pause button
                            // to allow user to stop it.
                            bool isBuffering =
                                processingState == ProcessingState.loading ||
                                processingState == ProcessingState.buffering;

                            if (isBuffering && playing != true) {
                              return Container(
                                width: 70,
                                height: 70,
                                padding: const EdgeInsets.all(20),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            } else if (playing != true) {
                              return GestureDetector(
                                onTap: () async {
                                  // Check if user has access before playing
                                  if (!_isPurchased) {
                                    _showSubscriptionSheet();
                                    return;
                                  }
                                  // Check if player has audio loaded
                                  if (_player.processingState ==
                                      ProcessingState.idle) {
                                    // No audio loaded - initialize player (will stream)
                                    _initPlayer();
                                    return;
                                  }
                                  // Player ready, just play
                                  // USE HANDLER TO ENSURE SYNC
                                  audioHandler.play();
                                },
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              );
                            } else {
                              return GestureDetector(
                                // USE HANDLER TO ENSURE SYNC
                                onTap: audioHandler.pause,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.pause,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              );
                            }
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          color: Colors.white,
                          iconSize: 40,
                          onPressed: _playNext,
                        ),
                        IconButton(
                          icon: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(3.14159), // Pi
                                child: const Icon(Icons.replay, size: 32),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '$_skipForwardSeconds',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          color: Colors.white,
                          iconSize: 32,
                          onPressed: () {
                            _player.seek(
                              _player.position +
                                  Duration(seconds: _skipForwardSeconds),
                            );
                          },
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const IconButton(
                          icon: Icon(Icons.replay_10),
                          color: Colors.white54,
                          iconSize: 32,
                          onPressed: null,
                        ),
                        const IconButton(
                          icon: Icon(Icons.skip_previous),
                          color: Colors.white54,
                          iconSize: 40,
                          onPressed: null,
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white54,
                            size: 40,
                          ),
                        ),
                        const IconButton(
                          icon: Icon(Icons.skip_next),
                          color: Colors.white54,
                          iconSize: 40,
                          onPressed: null,
                        ),
                        const IconButton(
                          icon: Icon(Icons.forward_30),
                          color: Colors.white54,
                          iconSize: 32,
                          onPressed: null,
                        ),
                      ],
                    ),

                  const SizedBox(height: 30),

                  // Bottom Options
                  Padding(
                    // Added Padding for bottom navigation overlap
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          key: isCurrent ? _speedButtonKey : null,
                          onTap: isCurrent ? _showSpeedMenu : null,
                          child: _buildBottomOption(
                            Icons.speed,
                            '${_playbackSpeed.toString().replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "")}x',
                            isCurrent && _playbackSpeed != 1.0,
                          ),
                        ),
                        GestureDetector(
                          onTap: isCurrent ? _toggleSleepMode : null,
                          child: _buildBottomOption(
                            Icons.bedtime,
                            '',
                            isCurrent && _isSleepTimerActive,
                          ),
                        ),
                        GestureDetector(
                          onTap: isCurrent ? _toggleFavorite : null,
                          child: _buildBottomOption(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            '',
                            _isFavorite,
                          ),
                        ),
                        GestureDetector(
                          key: isCurrent ? _moreButtonKey : null,
                          onTap: isCurrent ? _showMoreMenu : null,
                          child: _buildBottomOption(Icons.more_vert, '', false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20), // Extra safety margin
                ],
              ),
            ),
          ),
          // Subscription Overlay (replaces Purchase Overlay)
          if (!_isLoadingOwnership && !_isPurchased)
            Positioned.fill(
              child: Stack(
                children: [
                  // Blur Effect
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withOpacity(0.6)),
                  ),
                  // Subscribe Content
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 48,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.subscribeToListen,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.getUnlimitedAccessToAllAudiobooks,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _showSubscriptionSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.subscribeNow,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // if (_isLoadingOwnership)
          //   const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildBottomOption(IconData icon, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.blueAccent.withOpacity(0.4)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 20),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _initBgMusic() async {
    try {
      // _bgMusicList is already loaded by _initializeAll() - no need to fetch again
      // Just verify it's not empty to be safe
      if (_bgMusicList.isEmpty) {
        _bgMusicList = await BookRepository().getBackgroundMusicList();
      }

      // Always prioritize User Preference -> Book Default -> Global Default
      // We do NOT use audioHandler.selectedBgMusicId here because it might be holding
      // the music from the *previous* screen (e.g. Reels), which we want to override.
      int? bgMusicId = _userPreferredBgMusicId ?? widget.book.backgroundMusicId;
      print(
        '[DEBUG][_initBgMusic] UserPref: $_userPreferredBgMusicId, BookDef: ${widget.book.backgroundMusicId}, Resolved: $bgMusicId',
      );

      // If no default on book, use Global Default
      if (bgMusicId == null && _bgMusicList.isNotEmpty) {
        final defaultTrack = _bgMusicList.firstWhere(
          (e) => e['isDefault'] == true,
          orElse: () => {},
        );
        if (defaultTrack.isNotEmpty) {
          bgMusicId = defaultTrack['id'];
          print('[DEBUG][_initBgMusic] Using Global Default: $bgMusicId');
        }
      }

      // Set the background music source via audioHandler (handles looping, syncing, etc.)
      // Note: audioHandler.setBgMusicSource checks if the ID is the same and avoids reloading if so.
      print('[DEBUG][_initBgMusic] Setting BG Source to: $bgMusicId');
      await audioHandler.setBgMusicSource(bgMusicId, _bgMusicList);

      if (mounted) setState(() {});
    } catch (e) {
      print("Error initializing BG music: $e");
    }
  }

  Future<void> _updateBgMusicSource(int? bgMusicId) async {
    // Delegate to audioHandler - it handles caching, looping, and syncing with main player
    await audioHandler.setBgMusicSource(bgMusicId, _bgMusicList);
    if (mounted) setState(() {});
  }

  void _showBgMusicSettings() {
    // Use local variables to track state within modal, synced from audioHandler
    double modalVolume = audioHandler.bgVolume;
    int? modalSelectedId = audioHandler.selectedBgMusicId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.of(context)!.backgroundMusic,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Volume Slider
                  Row(
                    children: [
                      const Icon(Icons.volume_down, color: Colors.white70),
                      Expanded(
                        child: Slider(
                          value: modalVolume,
                          onChanged: (val) {
                            setModalState(() => modalVolume = val);
                            audioHandler.setBgMusicVolume(val);
                            setState(() {}); // Refresh parent UI if needed
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up, color: Colors.white70),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Track Selection
                  DropdownButton<int?>(
                    value: modalSelectedId,
                    isExpanded: true,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(AppLocalizations.of(context)!.none),
                      ),
                      ..._bgMusicList.map(
                        (bg) => DropdownMenuItem<int>(
                          value: bg['id'] as int,
                          child: Text(
                            bg['title'] ??
                                AppLocalizations.of(context)!.unknown,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) async {
                      setModalState(() => modalSelectedId = val);
                      await _updateBgMusicSource(val);

                      // Save Preference
                      try {
                        BookRepository().updateUserBackgroundMusic(
                          int.parse(widget.book.id),
                          val,
                        );
                      } catch (e) {
                        print("Error saving music pref: $e");
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _ScrollingText({required this.text, required this.style});

  @override
  State<_ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<_ScrollingText> {
  late ScrollController _scrollController;
  Timer? _timer;
  double _textWidth = 0.0;
  final double _gap = 50.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureText();
      _startScrolling();
    });
  }

  @override
  void didUpdateWidget(_ScrollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _measureText();
    }
  }

  void _measureText() {
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    if (mounted) {
      setState(() {
        _textWidth = textPainter.width;
      });
    }
  }

  void _startScrolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_scrollController.hasClients || _textWidth == 0) return;

      final maxExtent = _textWidth + _gap;
      double newOffset = _scrollController.offset + 20.0;

      if (newOffset >= maxExtent) {
        newOffset -= maxExtent;
        _scrollController.jumpTo(newOffset);
      } else {
        _scrollController.animateTo(
          newOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_textWidth == 0 || _textWidth <= constraints.maxWidth) {
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              Text(widget.text, style: widget.style),
              SizedBox(width: _gap),
              Text(widget.text, style: widget.style),
              if (_textWidth + _gap < constraints.maxWidth) ...[
                SizedBox(width: _gap),
                Text(widget.text, style: widget.style),
              ],
            ],
          ),
        );
      },
    );
  }
}
