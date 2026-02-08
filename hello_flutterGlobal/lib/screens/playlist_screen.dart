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
import '../widgets/mini_player.dart';
import '../services/connectivity_service.dart';
import '../services/subscription_service.dart';

import '../widgets/subscription_bottom_sheet.dart';
import '../widgets/content_area.dart';
import 'pdf_viewer_screen.dart';

class PlaylistScreen extends StatefulWidget {
  final Book book;
  final int? resumeFromTrackId;

  const PlaylistScreen({Key? key, required this.book, this.resumeFromTrackId})
    : super(key: key);

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
  // late VideoPlayerController _completionVideoController; // Removed
  bool _isVideoInitialized = false;
  // bool _isCompletionVideoInitialized = false; // Removed
  // bool _showCompletionOverlay = false; // Removed
  // bool _showCompletionOverlay = false;
  bool _isDownloading = false;
  String? _pdfUrl;
  bool _hasAutoResumed = false; // Prevent auto-resuming multiple times

  // Optimistic update state to handle stale cache
  final Set<String> _recentlyCompletedTrackIds = {};
  final Set<String> _recentlyPassedQuizTrackIds = {};
  bool _recentlyPassedBookQuiz = false;

  void _downloadFullPlaylist() async {
    print(
      '[PlaylistScreen] _downloadFullPlaylist called. _isCheckingAccess=$_isCheckingAccess, _hasAccess=$_hasAccess, isPremium=${widget.book.isPremium}',
    );

    // Wait for access check to complete if still checking
    if (_isCheckingAccess) {
      print('[PlaylistScreen] Access check still in progress, waiting...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isCheckingAccess) {
        print(
          '[PlaylistScreen] Still checking access for download after delay',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait, checking subscription status...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    print('[PlaylistScreen] Access check complete. _hasAccess=$_hasAccess');

    // For DOWNLOADING (not playing), check subscription without considering isDownloaded
    // This prevents users from downloading premium content just because it's partially cached
    if (widget.book.isPremium) {
      final isAdmin = _isAdmin;
      final isSubscribed = await SubscriptionService().isSubscribed();
      final canDownload = isAdmin || isSubscribed;

      print(
        '[PlaylistScreen] Download permission check: isPremium=true, isAdmin=$isAdmin, isSubscribed=$isSubscribed, canDownload=$canDownload',
      );

      if (!canDownload) {
        print(
          '[PlaylistScreen] ❌ DOWNLOAD ACCESS DENIED - Premium book requires subscription',
        );
        _showSubscriptionSheet();
        return;
      }
    }

    print(
      '[PlaylistScreen] ✅ Download access granted, proceeding with download check',
    );

    // 1. Check if already downloaded
    bool isFullyDownloaded = false;
    try {
      // Cast safely
      final List<Map<String, dynamic>> playlist = _tracks
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

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

      // Invalidate library cache so "My Books" updates immediately
      ContentArea.invalidateLibraryCache();

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
    // _initCompletionVideo(); // Removed
  }

  Future<void> _checkAccess({bool forceRefresh = false}) async {
    print(
      '[PlaylistScreen] DEBUG: Checking access for "${widget.book.title}". isPremium: ${widget.book.isPremium}',
    );

    // 1. Immediate check for Free Books
    if (!widget.book.isPremium) {
      print('[PlaylistScreen] Book is FREE, granting access');
      if (mounted) {
        setState(() {
          _hasAccess = true;
          _isCheckingAccess = false;
        });
      }
      return;
    }

    try {
      final userId = await AuthService().getCurrentUserId();
      print('[PlaylistScreen] User ID: $userId');

      final isAdmin = await AuthService().isAdmin();
      print('[PlaylistScreen] isAdmin: $isAdmin');

      final isSubscribed = await SubscriptionService().isSubscribed(
        forceRefresh: forceRefresh,
      );
      print('[PlaylistScreen] isSubscribed: $isSubscribed');

      // Optimization: If user has access via subscription or admin, grant immediately
      // knowing that we can stream whatever we want.
      if (isAdmin || isSubscribed) {
        if (mounted) {
          setState(() {
            _isAdmin = isAdmin;
            _hasAccess = true;
            _isCheckingAccess = false;
          });
        }
        return;
      }

      // Check if downloaded locally (Verify actual files on disk, not just metadata)
      final downloadService = DownloadService();
      bool isDownloaded = false;

      // Get saved playlist JSON and verify ALL tracks exist on disk
      final playlistData = await downloadService.getPlaylistJson(
        widget.book.id,
        userId: userId,
      );

      if (playlistData != null) {
        final List<Map<String, dynamic>>? playlist =
            (playlistData['tracks'] as List?)?.cast<Map<String, dynamic>>();

        if (playlist != null && playlist.isNotEmpty) {
          isDownloaded = await downloadService.isPlaylistFullyDownloaded(
            playlist,
            userId: userId,
            bookId: widget.book.id,
          );
        }
      }

      // Fallback for single-track books
      if (!isDownloaded) {
        isDownloaded = await downloadService.isBookDownloaded(
          widget.book.id,
          userId: userId,
          bookId: widget.book.id,
        );
      }

      print('[PlaylistScreen] isDownloaded (verified on disk): $isDownloaded');

      // Access Rules:
      // 1. Admin always has access
      // 2. Subscriber has access
      // 3. Downloaded content (verified on disk) has access
      final hasAccess = isDownloaded; // isAdmin and isSubscribed handled above

      print(
        '[PlaylistScreen] FINAL ACCESS DECISION: isAdmin=$isAdmin, isSubscribed=$isSubscribed, isDownloaded=$isDownloaded, hasAccess=$hasAccess',
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
          // Fallback - deny access on error for security
          _hasAccess = false;
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
    // No-op
  }

  @override
  void dispose() {
    // _completionVideoController.dispose(); // Removed
    super.dispose();
  }

  Future<void> _loadTracks({bool skipVideoUpdate = false}) async {
    try {
      final userId = await AuthService().getCurrentUserId();
      _userId = userId;

      // 1. Try to load from offline cache FIRST for immediate speed
      try {
        final cachedData = await DownloadService().getPlaylistJson(
          widget.book.id,
          userId: userId,
        );
        if (cachedData != null && mounted) {
          print('[PlaylistScreen] Loaded playlist from cache');
          _processPlaylistData(cachedData, skipVideoUpdate: skipVideoUpdate);
        }
      } catch (e) {
        print('[PlaylistScreen] Cache load error: $e');
      }

      // Offline Check - if offline, we are done
      if (ConnectivityService().isOffline) {
        if (_tracks.isEmpty) {
          throw Exception('No offline data found. Please download book first.');
        }
        return;
      }

      // 2. Fetch from server to ensure fresh data (sync progress, new tracks)
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
        // If we have cached tracks, don't throw exception, just log error
        if (_tracks.isNotEmpty) {
          print(
            'Failed to update playlist from server: ${response.statusCode}',
          );
        } else {
          throw Exception('Failed to load playlist');
        }
      }
    } catch (e) {
      if (mounted) {
        // If we have cached tracks, just log error
        if (_tracks.isNotEmpty) {
          print('Error updating playlist: $e');
        } else {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
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
      _tracks = (data['tracks'] as List).cast<Map<String, dynamic>>();

      // Optimistic merge: Restore locally completed tracks if server is stale
      for (var track in _tracks) {
        if (_recentlyCompletedTrackIds.contains(track['id'].toString())) {
          track['is_completed'] = true;
        }
      }

      _hasQuiz = data['has_quiz'] ?? false;
      _trackQuizzes = Map<String, dynamic>.from(data['track_quizzes'] ?? {});

      // Optimistic merge: Restore locally passed track quizzes
      for (var trackId in _recentlyPassedQuizTrackIds) {
        if (_trackQuizzes.containsKey(trackId)) {
          var qData = Map<String, dynamic>.from(_trackQuizzes[trackId]);
          qData['is_passed'] = true;
          _trackQuizzes[trackId] = qData;
        }
      }

      if (_tracks.isEmpty) {
        _areTracksCompleted = false;
      } else {
        _areTracksCompleted = _tracks.every(
          (track) => track['is_completed'] == true,
        );
      }

      // Must set _isQuizPassed BEFORE calculating _isBookCompleted
      _isQuizPassed = data['quiz_passed'] ?? false;
      if (_recentlyPassedBookQuiz) {
        _isQuizPassed = true;
      }
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

    // Auto-resume playback if resumeFromTrackId is set
    if (!_hasAutoResumed &&
        widget.resumeFromTrackId != null &&
        _tracks.isNotEmpty &&
        _hasAccess) {
      _hasAutoResumed = true;

      print('DEBUG: Auto-resuming from track ID: ${widget.resumeFromTrackId}');

      // Find the track index matching resumeFromTrackId
      int initialIndex = -1;
      for (int i = 0; i < _tracks.length; i++) {
        // Robust comparison: handle string/int mismatch
        final trackId = _tracks[i]['id'];
        if (trackId.toString() == widget.resumeFromTrackId.toString()) {
          initialIndex = i;
          print(
            'DEBUG: Found match at index $initialIndex (trackId: $trackId)',
          );
          break;
        }
      }

      if (initialIndex != -1) {
        // Delay slightly to ensure state is fully updated before opening player
        Future.microtask(() {
          if (mounted) {
            _playTrack(_tracks[initialIndex], initialIndex);
          }
        });
      } else {
        print(
          'DEBUG: Could not find track with ID ${widget.resumeFromTrackId} in playlist',
        );
      }
    }
  }

  void _onQuizTap() async {
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
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizTakerScreen(bookId: widget.book.id),
        ),
      );

      if (mounted) {
        if (result == true) {
          setState(() {
            _isQuizPassed = true;
            _recentlyPassedBookQuiz = true;
          });
        }
        _loadTracks(skipVideoUpdate: true);
      }
    }
  }

  void _onTrackQuizTap(int trackId) async {
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
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              QuizTakerScreen(bookId: widget.book.id, playlistItemId: trackId),
        ),
      );

      if (mounted) {
        if (result == true) {
          // Optimistic update: Mark as passed immediately
          setState(() {
            _trackQuizzes[trackId.toString()] = {
              'has_quiz': true,
              'is_passed': true,
            };
            _recentlyPassedQuizTrackIds.add(trackId.toString());
          });
        }
        _loadTracks(skipVideoUpdate: true);
      }
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
      // Background.png is now a local asset, no download needed
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

  // Background.png is now bundled as an asset, no download needed

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
      isPremium:
          widget.book.isPremium, // CRITICAL: Pass premium status to player
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
          // Optimistic update: Mark locally as completed immediately
          setState(() {
            _tracks[completedIndex]['is_completed'] = true;
            _recentlyCompletedTrackIds.add(
              _tracks[completedIndex]['id'].toString(),
            );
          });

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

    print(
      '[PlaylistScreen] _openPdfViewer called. _isCheckingAccess=$_isCheckingAccess, _hasAccess=$_hasAccess, isPremium=${widget.book.isPremium}',
    );

    // Wait for access check to complete if still checking
    if (_isCheckingAccess) {
      print(
        '[PlaylistScreen] Access check still in progress for PDF, waiting...',
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isCheckingAccess) {
        print('[PlaylistScreen] Still checking access for PDF after delay');
        return;
      }
    }

    print('[PlaylistScreen] PDF access check complete. _hasAccess=$_hasAccess');

    // For PDF access, check subscription without considering isDownloaded
    // This prevents users from viewing/downloading premium PDFs just because audio is cached
    if (widget.book.isPremium) {
      final isAdmin = _isAdmin;
      final isSubscribed = await SubscriptionService().isSubscribed();

      // Check if PDF is already downloaded locally (allow offline viewing)
      final isPdfDownloaded = await DownloadService().isPdfDownloaded(
        widget.book.id,
        userId: _userId,
      );

      final canAccessPdf = isAdmin || isSubscribed || isPdfDownloaded;

      print(
        '[PlaylistScreen] PDF access check: isPremium=true, isAdmin=$isAdmin, isSubscribed=$isSubscribed, isPdfDownloaded=$isPdfDownloaded, canAccessPdf=$canAccessPdf',
      );

      if (!canAccessPdf) {
        print(
          '[PlaylistScreen] ❌ PDF ACCESS DENIED - Premium PDF requires subscription',
        );
        _showSubscriptionSheet();
        return;
      }
    }

    print(
      '[PlaylistScreen] ✅ PDF access granted, proceeding with download/view',
    );

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
          // Background Image (loaded from local assets)
          if (_isVideoInitialized)
            SizedBox.expand(
              child: Image.asset(
                'assets/Background.png',
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
        ],
      ),
      floatingActionButton: null,
      // floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
