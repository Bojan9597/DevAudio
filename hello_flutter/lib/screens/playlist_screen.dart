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
  late VideoPlayerController _videoController;
  late VideoPlayerController _completionVideoController; // New controller
  bool _isVideoInitialized = false;
  bool _isCompletionVideoInitialized = false;
  bool _showCompletionOverlay = false;
  VoidCallback? _backgroundLoopListener;
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    _loadTracks();
    _initVideoPlayer();
    _initCompletionVideo(); // Init completion video
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
    final String fileName = 'backgroundAudioBookPlaylist.mp4';
    final videoUrl = '${ApiConstants.baseUrl}/static/Animations/$fileName';

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        _videoController = VideoPlayerController.file(file);
      } else {
        try {
          await Dio().download(videoUrl, filePath);
          _videoController = VideoPlayerController.file(file);
        } catch (e) {
          print("Download bg video failed, fallback to network: $e");
          _videoController = VideoPlayerController.networkUrl(
            Uri.parse(videoUrl),
          );
        }
      }

      await _videoController.initialize();
      await _videoController.setVolume(0.0); // Mute background video
      await _videoController.play();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        _updateBackgroundLoop(false);
      }
    } catch (e) {
      print("Error initializing video background: $e");
    }
  }

  Future<void> _updateBackgroundLoop(bool isBookCompleted) async {
    if (!_isVideoInitialized) return;

    if (_backgroundLoopListener != null) {
      _videoController.removeListener(_backgroundLoopListener!);
      _backgroundLoopListener = null;
    }

    if (!isBookCompleted) {
      // Loop 0-2s
      _backgroundLoopListener = () {
        final position = _videoController.value.position;
        if (!_isSeeking && position >= const Duration(seconds: 2)) {
          _isSeeking = true;
          _videoController.seekTo(Duration.zero).then((_) {
            // Optional: Ensure it plays if it stopped?
            // _videoController.play();
            // Small delay to let position update reflect 0 safely?
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) _isSeeking = false;
            });
          });
        }
      };
      _videoController.addListener(_backgroundLoopListener!);
    } else {
      // Logic when book is completed:
      // 1. Seek to 2s (start of "completion" segment).
      // 2. Play to End.
      // 3. When playback finishes -> Trigger completion overlay sequence.

      // Ensure specific start point BEFORE adding listener
      await _videoController.seekTo(const Duration(seconds: 2));
      await _videoController.play();

      _backgroundLoopListener = () {
        if (_videoController.value.position >=
            _videoController.value.duration) {
          // Video finished
          _playCompletionSequence();

          if (_backgroundLoopListener != null) {
            _videoController.removeListener(_backgroundLoopListener!);
            _backgroundLoopListener = null;
          }
        }
      };

      _videoController.addListener(_backgroundLoopListener!);
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
    _videoController.dispose();
    _completionVideoController.dispose();
    super.dispose();
  }

  Future<void> _loadTracks({bool skipVideoUpdate = false}) async {
    try {
      final userId = await AuthService().getCurrentUserId();
      _userId = userId;

      final String url =
          '${ApiConstants.baseUrl}/playlist/${widget.book.id}' +
          (userId != null ? '?user_id=$userId' : '');

      final uri = Uri.parse(url);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          response.body,
        ); // Changed to Map
        if (mounted) {
          final bool wasCompleted = _isBookCompleted;

          setState(() {
            _tracks = data['tracks'];
            _hasQuiz = data['has_quiz'] ?? false;
            _trackQuizzes = Map<String, dynamic>.from(
              data['track_quizzes'] ?? {},
            );

            // Calculate if tracks are completed
            if (_tracks.isEmpty) {
              _areTracksCompleted = false;
            } else {
              _areTracksCompleted = _tracks.every(
                (track) => track['is_completed'] == true,
              );
            }

            // _isBookCompleted determines if we SHOW THE ANIMATION (Everything done)
            if (_hasQuiz) {
              _isBookCompleted = _areTracksCompleted && _isQuizPassed;
            } else {
              _isBookCompleted = _areTracksCompleted;
            }

            _isQuizPassed = data['quiz_passed'] ?? false;

            _isLoading = false;

            _isFirstLoad = false;
          });

          // Update Video Loop Logic OUTSIDE setState to allow async operations
          // and prevent blocking UI
          if (!skipVideoUpdate) {
            _updateBackgroundLoop(_isBookCompleted);
          }
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

    // 3. Download ALL tracks in background
    // _downloadAllTracks(); // Removed feature
  }

  void _playTrack(Map<String, dynamic> track, int index) async {
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
      coverUrl: widget.book.coverUrl,
      categoryId: widget.book.categoryId,
      subcategoryIds: const [],
      postedBy: widget.book.postedBy,
      description: widget.book.description,
      price: widget.book.price,
      postedByUserId: widget.book.postedByUserId,
      isPlaylist: false,
      isFavorite: widget.book.isFavorite,
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
        playlist: _tracks,
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
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
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
      backgroundColor: Colors.grey.shade900,
      body: Stack(
        children: [
          // Background Video
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),
            ),

          // Overlay to darken video for readability
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
    );
  }
}
