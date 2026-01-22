import 'package:flutter/material.dart';
import '../models/book.dart';
import '../widgets/player_screen.dart';
import '../widgets/lesson_map_widget.dart'; // Import LessonMap
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/download_service.dart';
import '../services/auth_service.dart';
import 'quiz_creator_screen.dart';
import 'quiz_taker_screen.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../services/connectivity_service.dart';
import '../services/subscription_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/subscription_bottom_sheet.dart';

class PlaylistScreen extends StatefulWidget {
  final Book book;

  const PlaylistScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<dynamic> _tracks = [];
  Map<String, dynamic> _trackQuizzes = {};
  bool _isLoading = true;
  String? _error;
  bool _hasQuiz = false;
  bool _isBookCompleted = false;
  bool _areTracksCompleted = false;
  bool _isFirstLoad = true; // Flag to prevent overlay on startup
  bool _isQuizPassed = false;
  int? _userId;
  bool _isAdmin = false;
  bool _hasAccess = false;
  bool _isCheckingAccess = true;
  late VideoPlayerController _completionVideoController;
  bool _isVideoInitialized = false;
  bool _isCompletionVideoInitialized = false;
  bool _showCompletionOverlay = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _loadTracks();
    _initVideoPlayer();
    _initCompletionVideo(); // Init completion video
  }

  Future<void> _checkAccess({bool forceRefresh = false}) async {
    try {
      final isAdmin = await AuthService().isAdmin();
      final isSubscribed = await SubscriptionService().isSubscribed(
        forceRefresh: forceRefresh,
      );

      print(
        '[PlaylistScreen] Access check (force=$forceRefresh): isAdmin=$isAdmin, isSubscribed=$isSubscribed',
      );

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _hasAccess = isAdmin || isSubscribed;
          _isCheckingAccess = false;
        });
      }
    } catch (e) {
      print("[PlaylistScreen] Error checking access: $e");
      if (mounted) {
        setState(() {
          _isCheckingAccess = false;
          // On error, don't block access - let server handle it
          _hasAccess = true;
        });
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
          Navigator.pop(context);
          _checkAccess(forceRefresh: true); // Refresh access status
        },
      ),
    );
  }

  Future<void> _initCompletionVideo() async {
    final String fileName = 'bookFinished.mp4';
    final videoUrl = '${ApiConstants.baseUrl}/static/Animations/$fileName';

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        _completionVideoController = VideoPlayerController.file(file);
      } else {
        if (ConnectivityService().isOffline) return; // Skip if offline

        try {
          await Dio().download(videoUrl, filePath);
          _completionVideoController = VideoPlayerController.file(file);
        } catch (e) {
          print("Download completion video failed, fallback to network: $e");
          _completionVideoController = VideoPlayerController.networkUrl(
            Uri.parse(videoUrl),
          );
        }
      }

      await _completionVideoController.initialize();
      _completionVideoController.setVolume(1.0);

      if (mounted) {
        setState(() {
          _isCompletionVideoInitialized = true;
        });
      }
    } catch (e) {
      print("Error initializing completion video: $e");
    }
  }

  Future<void> _initVideoPlayer() async {
    // Background.png is now used as a static image, so we don't need video initialization
    // The image will be loaded directly in the build method
    if (mounted) {
      setState(() {
        _isVideoInitialized = true; // Mark as "initialized" to show background
      });
    }
  }

  Future<void> _updateBackgroundLoop(bool isBookCompleted) async {
    // Since we're using a static background image, we don't need to manage video loops
    // Just trigger completion sequence if book is completed
    if (isBookCompleted) {
      _playCompletionSequence();
    }
  }

  void _playCompletionSequence() {
    if (_isCompletionVideoInitialized) {
      setState(() {
        _showCompletionOverlay = true;
      });
      _completionVideoController.seekTo(Duration.zero);
      _completionVideoController.play();
    }
  }

  @override
  void dispose() {
    _completionVideoController.dispose();
    super.dispose();
  }

  Future<void> _loadTracks({bool skipVideoUpdate = false}) async {
    try {
      final userId = await AuthService().getCurrentUserId();
      _userId = userId;

      // Offline Check
      if (ConnectivityService().isOffline) {
        final data = await DownloadService().getPlaylistJson(widget.book.id);
        if (data != null) {
          if (mounted)
            _processPlaylistData(data, skipVideoUpdate: skipVideoUpdate);
          return;
        } else {
          // No offline data
          throw Exception('No offline data found. Please download book first.');
        }
      }

      final String url =
          '${ApiConstants.baseUrl}/playlist/${widget.book.id}' +
          (userId != null ? '?user_id=$userId' : '');

      final uri = Uri.parse(url);
      final token = await AuthService().getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Save for offline
        await DownloadService().savePlaylistJson(widget.book.id, data);

        if (mounted) {
          _processPlaylistData(data, skipVideoUpdate: skipVideoUpdate);
        }
      } else {
        throw Exception('Failed to load playlist');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _processPlaylistData(
    Map<String, dynamic> data, {
    bool skipVideoUpdate = false,
  }) {
    // If not mounted, do nothing
    if (!mounted) return;

    setState(() {
      _tracks = data['tracks'];
      _hasQuiz = data['has_quiz'] ?? false;
      _trackQuizzes = Map<String, dynamic>.from(data['track_quizzes'] ?? {});

      if (_tracks.isEmpty) {
        _areTracksCompleted = false;
      } else {
        _areTracksCompleted = _tracks.every(
          (track) => track['is_completed'] == true,
        );
      }

      // Must set _isQuizPassed BEFORE calculating _isBookCompleted
      _isQuizPassed = data['quiz_passed'] ?? false;

      if (_hasQuiz) {
        _isBookCompleted = _areTracksCompleted && _isQuizPassed;
      } else {
        _isBookCompleted = _areTracksCompleted;
      }
      _isLoading = false;
      _isFirstLoad = false;
    });

    if (!skipVideoUpdate) {
      _updateBackgroundLoop(_isBookCompleted);
    }
  }

  void _onQuizTap() {
    // Check ownership
    bool isOwner = false;
    if (_userId != null && widget.book.postedByUserId == _userId.toString()) {
      isOwner = true;
    }

    if (isOwner) {
      // Navigate to Creator
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizCreatorScreen(bookId: widget.book.id),
        ),
      ).then((_) => _loadTracks()); // Reload to update hasQuiz status
    } else {
      // Navigate to Taker
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizTakerScreen(bookId: widget.book.id),
        ),
      ).then(
        (_) => _loadTracks(),
      ); // Reload to update status (e.g. if they passed)
    }
  }

  void _onTrackQuizTap(int trackId) {
    bool isOwner =
        _userId != null && widget.book.postedByUserId == _userId.toString();

    if (isOwner) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizCreatorScreen(
            bookId: widget.book.id,
            playlistItemId: trackId,
          ),
        ),
      ).then((_) => _loadTracks());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              QuizTakerScreen(bookId: widget.book.id, playlistItemId: trackId),
        ),
      ).then((_) => _loadTracks());
    }
  }

  String _ensureAbsoluteUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${ApiConstants.baseUrl}$url';
  }

  Future<void> _handlePurchaseSuccess(Map<String, dynamic> currentTrack) async {
    // 1. Show message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase Successful! Downloading playlist...'),
          duration: Duration(seconds: 4),
        ),
      );
    }

    // 2. Download Current Track FIRST (high priority)
    try {
      final String trackUrl = _ensureAbsoluteUrl(currentTrack['file_path']);
      final uniqueTrackId = "track_${currentTrack['id']}";
      await DownloadService().downloadBook(uniqueTrackId, trackUrl);
      print("Downloaded current track: ${currentTrack['title']}");
    } catch (e) {
      print("Error downloading current track: $e");
    }

    // 2.5 Download Remaining Tracks (Background)
    for (var track in _tracks) {
      // Skip the current one as we just started/awaited it (or tried to)
      if (track['id'] == currentTrack['id']) continue;

      final String tUrl = _ensureAbsoluteUrl(track['file_path']);
      final tId = "track_${track['id']}";

      // Fire and forget, or log errors individually to avoid blocking UI
      DownloadService().downloadBook(tId, tUrl).catchError((err) {
        print("Failed to background download track ${track['title']}: $err");
      });
    }

    // 3. Save Metadata and Download Assets
    try {
      // We need updated playlist data to save properly (flags etc)
      // Current state might be stale if we just purchased?
      // Safe to assume current state is okay-ish or fetch fresh?
      // Step 334 logic saved state variables.
      await DownloadService().savePlaylistJson(widget.book.id, {
        'tracks': _tracks,
        'has_quiz': _hasQuiz,
        'track_quizzes': _trackQuizzes,
        'quiz_passed': _isQuizPassed,
      });

      _downloadQuizData();
      _downloadBackgroundAssets();
    } catch (e) {
      print("Error triggering background downloads: $e");
    }
  }

  Future<void> _downloadQuizData() async {
    if (ConnectivityService().isOffline) return;
    try {
      final String quizUrl = '${ApiConstants.baseUrl}/quiz/${widget.book.id}';
      final token = await AuthService().getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(Uri.parse(quizUrl), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        await DownloadService().saveQuizJson(widget.book.id, data);
      }

      for (var track in _tracks) {
        final trackId = track['id'].toString();
        if (_trackQuizzes.containsKey(trackId)) {
          final String trackQuizUrl =
              '${ApiConstants.baseUrl}/quiz/${widget.book.id}?playlist_item_id=$trackId';
          final tResp = await http.get(
            Uri.parse(trackQuizUrl),
            headers: headers,
          );
          if (tResp.statusCode == 200) {
            final List<dynamic> tData = json.decode(tResp.body);
            await DownloadService().saveQuizJson(
              widget.book.id,
              tData,
              playlistItemId: track['id'],
            );
          }
        }
      }
    } catch (e) {
      print("Error downloading quiz data: $e");
    }
  }

  Future<void> _downloadBackgroundAssets() async {
    if (ConnectivityService().isOffline) return;
    final String fileName = 'Background.png';
    final imageUrl = '${ApiConstants.baseUrl}/static/Animations/$fileName';
    await DownloadService().downloadFile(imageUrl, fileName);
  }

  void _playTrack(Map<String, dynamic> track, int index) async {
    // Wait for access check to complete if still checking
    if (_isCheckingAccess) {
      // Show a brief loading indicator or just wait
      await Future.delayed(const Duration(milliseconds: 500));
      // Re-check after delay
      if (_isCheckingAccess) {
        print('[PlaylistScreen] Still checking access, please wait...');
        return;
      }
    }

    // Check subscription access before playing
    if (!_hasAccess) {
      print('[PlaylistScreen] No access, showing subscription sheet');
      _showSubscriptionSheet();
      return;
    }

    // Construct a temporary Book object for the Player
    final String trackUrl = _ensureAbsoluteUrl(track['file_path']);
    final trackTitle = track['title'];
    final uniqueTrackId = "track_${track['id']}";

    // If 'is_completed' is not in Book model, we don't pass it there.
    // It's used for the map UI.

    final singleTrackBook = Book(
      id: widget.book.id, // Use REAL Book ID
      title: trackTitle,
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
      isFavorite: widget.book.isFavorite,
      isEncrypted: widget.book.isEncrypted,
    );

    bool justFinishedLastTrack = false;

    // Refresh tracks when player closes to update stars
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerScreen(
        book: singleTrackBook,
        uniqueAudioId: uniqueTrackId,
        onPurchaseSuccess: () => _handlePurchaseSuccess(track),
        playlist: _tracks.cast<Map<String, dynamic>>(),
        initialIndex: index,
        onPlaybackComplete: (completedIndex) async {
          await _onTrackFinished(_tracks[completedIndex]);

          // Check if it's the last track
          if (completedIndex == _tracks.length - 1) {
            justFinishedLastTrack = true;
            // Do NOT pop here. PlayerScreen will pop itself when it hits end of playlist
            // (after handling any track quiz).
          }
        },
        trackQuizzes: _trackQuizzes, // Pass all track quizzes
      ),
    );

    // Check if we are going to auto-navigate
    // If yes, we SKIP the video update in _loadTracks to avoid premature playback
    // The video update will happen when we return from Quiz (on pop).
    bool willAutoNav = justFinishedLastTrack && _hasQuiz;

    // Reload tracks
    await _loadTracks(skipVideoUpdate: willAutoNav);

    // Auto-navigate to Final Quiz if last track finished
    // Even if quiz is passed, user might want to see result/retake
    if (willAutoNav) {
      _onQuizTap();
    }
  }

  Future<void> _onTrackFinished(Map<String, dynamic> track) async {
    // Call backend to mark complete
    if (_userId == null) return;
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/complete-track');
      final token = await AuthService().getAccessToken();
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'user_id': _userId, 'track_id': track['id']}),
      );
    } catch (e) {
      print("Error marking track complete: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          Builder(
            builder: (context) {
              bool isOwner =
                  _userId != null &&
                  widget.book.postedByUserId == _userId.toString();
              if (isOwner) {
                return IconButton(
                  icon: const Icon(Icons.edit_note),
                  tooltip: "Manage Quiz",
                  onPressed: _onQuizTap,
                );
              }
              // User quiz access is now via the Map, removed AppBar button for takers
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      // Use gradient background for map feel
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background Image
          if (_isVideoInitialized)
            SizedBox.expand(
              child: Image.network(
                '${ApiConstants.baseUrl}/static/Animations/Background.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF121212),
                ),
              ),
            ),

          // Overlay to darken background for readability
          if (_isVideoInitialized)
            Container(color: Colors.black.withOpacity(0.6)),

          // Content
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text('Error: $_error'))
              : _tracks.isEmpty
              ? const Center(child: Text('No tracks found'))
              : LessonMapWidget(
                  tracks: _tracks,
                  onTrackTap: (index) => _playTrack(_tracks[index], index),
                  hasQuiz: _hasQuiz,
                  isBookCompleted:
                      _areTracksCompleted, // Use tracks completion to unlock final quiz
                  isQuizPassed: _isQuizPassed,
                  onQuizTap: _onQuizTap,
                  trackQuizzes: _trackQuizzes,
                  onTrackQuizTap: _onTrackQuizTap,
                  isOwner:
                      _userId != null &&
                      widget.book.postedByUserId == _userId.toString(),
                ),
          // Completion Overlay Video
          if (_showCompletionOverlay && _isCompletionVideoInitialized)
            Container(
              // Container for black background behind overlay? Or transparent?
              color: Colors
                  .black, // Opaque black background for the "new screen" feel
              child: Center(
                child: AspectRatio(
                  aspectRatio: _completionVideoController.value.aspectRatio,
                  child: VideoPlayer(_completionVideoController),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _showCompletionOverlay
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showCompletionOverlay = false;
                  _completionVideoController.pause();
                  _completionVideoController.seekTo(Duration.zero);
                });
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.close, color: Colors.black),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
