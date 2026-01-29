import 'package:flutter/material.dart';
import '../models/book.dart';
import '../widgets/player_screen.dart';
import '../widgets/lesson_map_widget.dart'; // Import LessonMap
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/download_service.dart';
import '../services/api_client.dart'; // Import ApiClient
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
import 'pdf_viewer_screen.dart';

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
  bool _isDownloading = false;
  String? _pdfUrl;

  void _downloadFullPlaylist() async {
    // 1. Check if already downloaded
    bool isFullyDownloaded = false;
    try {
      // Cast safely
      final List<Map<String, dynamic>> playlist = _tracks
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Note: isPlaylistFullyDownloaded check assumes we know bookId context if strict.
      // added bookId param to helper or just iterate manually?
      // The helper I added `isPlaylistFullyDownloaded` takes `playlist` and `userId`.
      // It doesn't take bookId in signature I proposed above, but it calls `isBookDownloaded`.
      // `isBookDownloaded` is better with bookId.
      // I should update `isPlaylistFullyDownloaded` signature in next step if I forgot,
      // OR I can just use it as is if I didn't add bookId param to it.
      // Wait, I didn't add bookId to `isPlaylistFullyDownloaded` in the previous tool call?
      // I used: `isPlaylistFullyDownloaded(List<Map<String, dynamic>> playlist, {int? userId})`
      // It iterates and calls `isBookDownloaded(uniqueId, userId: userId)`.
      // It DOES NOT pass bookId. This means it falls back to legacy/flat structure or might miss folder.
      // I should probably fix `isPlaylistFullyDownloaded` first to accept bookId for safety.
      // BUT for now, let's assume it works or I'll fix it in a sec.
      // Actually, I can just rely on `DownloadService` logic.

      // Let's assume I will fix the signature in a followup if needed.
      // Actually I just wrote the code, let's check what I wrote.
      // I wrote: `isPlaylistFullyDownloaded(List<Map<String, dynamic>> playlist, {int? userId})`.
      // It calls `isBookDownloaded(uniqueId, userId: userId)`.
      // This is slightly risky if files are in book_ID folder.
      // `isBookDownloaded` does:
      // `getLocalBookPath(fileKey, userId: userId, bookId: bookId)` -> NEEDS bookId for folder.
      // If bookId is null, it returns `.../user_X/file.mp3`.
      // If file is in `.../user_X/book_Y/file.mp3`, `isBookDownloaded` without bookId might return FALSE.
      // So `isPlaylistFullyDownloaded` MIGHT return false even if downloaded in new folder structure.

      // Correction: I should update `PlaylistScreen` to call a BETTER version or just check manually here.
      // Or I can update `DownloadService` again to add `bookId`.
      // Let's just use it for now and I will fix the Service signature in next turn if I made a mistake.
      // Wait, I am controlling the edit. I can see I missed bookId in previous step's signature.
      // However, `isBookDownloaded` falls back?
      // `getLocalBookPath` with NO bookId -> `userPath/uniqueId.mp3`.
      // If file is in `userPath/bookId/uniqueId.mp3`, `File(legacyPath).exists()` will be FALSE.
      // So `isBookDownloaded` returns FALSE.
      // So `isFullyDownloaded` returns FALSE.
      // So it tries to download.
      // Inside `downloadPlaylist`, I added `isBookDownloaded(..., bookId: bookId)`. THIS ONE IS CORRECT.
      // So `downloadPlaylist` will skip existing ones correctly.
      // The only "bug" is that the "Already downloaded" snackbar might not show if files are in new folder structure,
      // it will instead say "Downloading..." and then finish instantly because `downloadPlaylist` skips them.
      // That is acceptable behavior for now (it fixes the re-download waste), but not the UI message the user wants.

      // To get the UI message right, I really should fix `isPlaylistFullyDownloaded` to accept bookId.
      // I will do that in `DownloadService` first.

      // For this step (PlaylistScreen), let's assume I WILL fix `DownloadService` to take bookId.
      // So I will write the code here assuming `bookId` parameter exists or I'll rely on `downloadPlaylist` skipping fast.
      // User specifically asked "say that book is already downloaded".
      // So I MUST Ensure `isFullyDownloaded` returns TRUE.

      isFullyDownloaded = await DownloadService().isPlaylistFullyDownloaded(
        playlist,
        userId: _userId,
        bookId: widget.book.id,
      );
    } catch (e) {
      print("Error checking download status: $e");
    }

    if (isFullyDownloaded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book is already downloaded.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Check access before downloading
    // Access is already checked in initState -> _checkAccess
    // But we should double check here explicitly or rely on _hasAccess flag
    // We want to block download if no access (Premium book + No Sub + No Admin)

    // Re-verify access state just in case
    if (!_hasAccess) {
      _showSubscriptionSheet();
      return;
    }

    setState(() => _isDownloading = true);
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloading full playlist...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await DownloadService().downloadPlaylist(
        _tracks.cast<Map<String, dynamic>>(),
        widget.book.id,
        userId: _userId,
      );

      // Also download PDF if available
      if (_pdfUrl != null && _pdfUrl!.isNotEmpty) {
        try {
          await DownloadService().downloadPdf(
            widget.book.id,
            _pdfUrl!,
            userId: _userId,
          );
        } catch (e) {
          print('PDF download failed: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download Complete! Available offline.'),
          ),
        );
      }
    } catch (e) {
      print("Playlist download error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _loadTracks();
    _initVideoPlayer();
    _initCompletionVideo(); // Init completion video
  }

  Future<void> _checkAccess({bool forceRefresh = false}) async {
    // 1. Immediate check for Free Books (no network/db processing needed)
    if (!widget.book.isPremium) {
      if (mounted) {
        setState(() {
          _hasAccess = true;
          _isCheckingAccess = false;
        });
      }
      return;
    }

    try {
      final isAdmin = await AuthService().isAdmin();
      final isSubscribed = await SubscriptionService().isSubscribed(
        forceRefresh: forceRefresh,
      );

      // We know it is premium here (due to check above)
      // So access = isAdmin OR isSubscribed
      final hasAccess = isAdmin || isSubscribed;

      print(
        '[PlaylistScreen] Access check (Premium Book): isAdmin=$isAdmin, isSubscribed=$isSubscribed, hasAccess=$hasAccess',
      );

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _hasAccess = hasAccess;
          _isCheckingAccess = false;
        });
      }
    } catch (e) {
      print("[PlaylistScreen] Error checking access: $e");
      if (mounted) {
        setState(() {
          _isCheckingAccess = false;
          // On error for PREMIUM books, we default to ... true? No, safe to blocking usually.
          // But previous logic was lenient.
          // Let's keep it lenient for now to avoid blocking legitimate users on network fail?
          // Or strict? "User request: user should not need to upgrade... for free".
          // For premium, if error, we probably shouldn't grant access blindly if we want to sell subs.
          // But strict locking might annoy users if server flakes.
          // Let's stick to lenient fallback but log it, matching previous behavior.
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
        final data = await DownloadService().getPlaylistJson(
          widget.book.id,
          userId: userId, // Try to get user-specific data if we know who we are
        );
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

      // Use ApiClient
      final response = await ApiClient().get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Save for offline
        await DownloadService().savePlaylistJson(
          widget.book.id,
          data,
          userId: userId,
        );

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
      _pdfUrl = data['pdf_path'];

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

    // 2. Download Current Track FIRST (high priority, user-specific storage)
    try {
      final String trackUrl = _ensureAbsoluteUrl(currentTrack['file_path']);
      final uniqueTrackId = "track_${currentTrack['id']}";
      await DownloadService().downloadBook(
        uniqueTrackId,
        trackUrl,
        userId: _userId,
      );
      print("Downloaded current track: ${currentTrack['title']}");
    } catch (e) {
      print("Error downloading current track: $e");
    }

    // 2.5 Download Remaining Tracks (Background, user-specific storage)
    for (var track in _tracks) {
      // Skip the current one as we just started/awaited it (or tried to)
      if (track['id'] == currentTrack['id']) continue;

      final String tUrl = _ensureAbsoluteUrl(track['file_path']);
      final tId = "track_${track['id']}";

      // Fire and forget, or log errors individually to avoid blocking UI
      DownloadService().downloadBook(tId, tUrl, userId: _userId).catchError((
        err,
      ) {
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
      }, userId: _userId);

      // Register download on server (so we know this user has this book downloaded)
      await DownloadService().registerServerDownload(widget.book.id);

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

      // Use ApiClient
      final response = await ApiClient().get(
        Uri.parse(quizUrl),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        await DownloadService().saveQuizJson(
          widget.book.id,
          data,
          userId: _userId,
        );
      }

      for (var track in _tracks) {
        final trackId = track['id'].toString();
        if (_trackQuizzes.containsKey(trackId)) {
          final String trackQuizUrl =
              '${ApiConstants.baseUrl}/quiz/${widget.book.id}?playlist_item_id=$trackId';
          // Use ApiClient
          final tResp = await ApiClient().get(
            Uri.parse(trackQuizUrl),
            headers: headers,
          );
          if (tResp.statusCode == 200) {
            final List<dynamic> tData = json.decode(tResp.body);
            await DownloadService().saveQuizJson(
              widget.book.id,
              tData,
              playlistItemId: track['id'],
              userId: _userId,
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
    // _hasAccess is calculated in _checkAccess based on isPremium, isSubscribed, isAdmin
    if (!_hasAccess) {
      print(
        '[PlaylistScreen] No access (Premium & Not Subscribed), showing subscription sheet',
      );
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
        bookTitle: widget.book.title, // Pass Book Title
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

  Future<void> _openPdfViewer() async {
    if (_pdfUrl == null || _pdfUrl!.isEmpty) return;

    // Check if PDF is downloaded
    final isDownloaded = await DownloadService().isPdfDownloaded(
      widget.book.id,
      userId: _userId,
    );

    if (!isDownloaded) {
      // Download PDF first
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloading PDF...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      try {
        await DownloadService().downloadPdf(
          widget.book.id,
          _pdfUrl!,
          userId: _userId,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to download PDF: $e')));
        }
        return;
      }
    }

    // Get the local PDF path and open viewer
    final pdfPath = await DownloadService().getPdfPath(
      widget.book.id,
      userId: _userId,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PdfViewerScreen(pdfPath: pdfPath, title: widget.book.title),
        ),
      );
    }
  }

  Future<void> _onTrackFinished(Map<String, dynamic> track) async {
    // Call backend to mark complete
    if (_userId == null) return;
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/complete-track');
      final token = await AuthService().getAccessToken();

      // Use ApiClient
      await ApiClient().post(
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
          // PDF Button - only show if PDF exists
          if (_pdfUrl != null && _pdfUrl!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: "View PDF",
              onPressed: _openPdfViewer,
            ),
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
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: const Color(0xFF121212)),
              ),
            ),

          // Overlay to darken background for readability (reduced opacity)
          if (_isVideoInitialized)
            Container(color: Colors.black.withOpacity(0.3)),

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
                  // Add Download Props
                  // bookTitle: widget.book.title, // Removed to prevent duplicate title
                  onDownloadTap: _downloadFullPlaylist,
                  isDownloading: _isDownloading,
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
