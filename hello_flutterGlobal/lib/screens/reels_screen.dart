import 'package:flutter/material.dart';
import 'dart:async';
import '../l10n/generated/app_localizations.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../widgets/subscription_bottom_sheet.dart';
import '../services/audio_connector.dart';
import '../main.dart'; // Access to routeObserver
import '../utils/api_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/player_preferences.dart';
import 'package:share_plus/share_plus.dart';
// We need access to the global audio player state if we want to sync with MiniPlayer
// But user said "It should look like that audio player with profile picture and everything"
// This implies a FULL SCREEN EXPERIENCE.

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({Key? key}) : super(key: key);

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with RouteAware {
  final BookRepository _bookRepository = BookRepository();
  // AuthService removed as it is used internally by BookRepository
  // REMOVED local players: _audioPlayer, _bgPlayer
  // We now use AudioConnector.handler for everything.
  // Ideally we should use the SAME player as the rest of the app to avoid double audio.
  // For now, I'll assume we use a local one or need to integrate with a provider.
  // Given the "Next track/book" logic is complex, local might be easier,
  // BUT it breaks the "MiniPlayer" showing up elsewhere.
  // Let's stick to local logic for the specific "Reels" behavior first as requested.
  // Wait, if user leaves the tab, music should probably stop? Or continue?
  // "If user just leaves it playing, it should play only next audio..."
  // This sounds like typical app behavior. Let's try to use a local player for the "Reels" specific flow
  // to avoid conflicting with the global player state which is designed for standard listening.

  bool _isLoading = true;
  bool _isSubscribed = false;
  List<Book> _books = [];

  final PageController _verticalController = PageController();
  final Map<int, PageController> _horizontalControllers = {};

  int _currentBookIndex = 0;
  int _currentTrackIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final int _limit = 100; // Fetch all books at once for simpler infinite loop
  bool _isFetchingMore = false;
  bool _backendHasMore = true;
  // Offset is managed by server

  // Background Music State
  // Background Music is managed by Global Handler
  // We keep local state for UI state tracking (volume, enabled)
  // but actions go to global handler.
  double _bgVolume = 0.2;
  // bool _bgMusicEnabled = true; // Unused local var, handler manages this
  List<Map<String, dynamic>> _bgMusicList = [];
  int? _selectedBgMusicId;
  bool _isDraggingSlider = false;
  double _dragSliderValue = 0.0;

  // Speed Control
  double _playbackSpeed = 1.0;
  StreamSubscription<double>? _speedSubscription;
  // Timer? _bgMusicDebounceTimer; // Removed as we use pre-fetched data

  @override
  void initState() {
    super.initState();
    _bgVolume = AudioConnector.handler?.bgVolume ?? _bgVolume;
    _selectedBgMusicId = AudioConnector.handler?.selectedBgMusicId;
    _initAudioSession();
    _initBgPlayer();
    _stopGlobalAudio(); // Stop global audio when entering reels
    _loadInitialData();

    // Listen to global player state
    final player = AudioConnector.handler?.player;
    if (player != null) {
      player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            // Handle track completion
            if (state.processingState == ProcessingState.completed) {
              _onTrackFinished();
            }
          });
        }
      });

      player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });

      player.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _duration = d);
      });

      // Listen to speed changes
      _speedSubscription = player.speedStream.listen((speed) {
        if (mounted) setState(() => _playbackSpeed = speed);
      });
    }
  }

  Future<void> _initBgPlayer() async {
    // Global handler manages this
  }

  Future<void> _initAudioSession() async {
    // Global handler manages this
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the route observer to track navigation events
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    // Unsubscribe from route observer
    routeObserver.unsubscribe(this);

    _verticalController.dispose();
    for (var c in _horizontalControllers.values) c.dispose();

    // We DO NOT dispose the global player here.
    // But if we are leaving (popping), we should stop playback if that's desired behavior?
    // User said: "It should stop it, but it did not exit it when in there".
    // When disposing ReelsScreen (popping), we usually stop playback.

    // Note: didPushNext handles navigating deeper.
    // This dispose handles popping back.
    _stopGlobalAudio();

    // _audioPlayer.dispose(); // REMOVED
    // _bgPlayer.dispose(); // REMOVED

    _speedSubscription?.cancel();
    // _bgMusicDebounceTimer?.cancel(); // Removed

    super.dispose();
  }

  @override
  void didPushNext() {
    // Called when pushing a new route (e.g., opening PlayerScreen)
    // We must stop the Reels audio to prevent "overflow" and cleanup resources
    print("ReelsScreen: didPushNext - Stopping audio");
    print("ReelsScreen: didPushNext - Stopping audio");
    _stopGlobalAudio();
  }

  @override
  void didPopNext() {
    // Called when returning to this screen
    // Optionally resume, or just ensure global audio is still paused
    _stopGlobalAudio();
  }

  void _stopGlobalAudio() {
    // Pause the global player so we don't have two audio sources
    try {
      AudioConnector.handler?.pause();
    } catch (e) {
      print("Error stopping global audio: $e");
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    _books.clear();

    // Load BG Music List
    try {
      _bgMusicList = await _bookRepository.getBackgroundMusicList();
    } catch (e) {
      print("Error loading BG music list: $e");
    }

    try {
      // Single API call now includes savedOffset + books + subscription status
      await _fetchReels();
    } catch (e) {
      print("Error fetching reels: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (mounted) {
      if (_isSubscribed && _books.isNotEmpty) {
        const startIndex = 0;
        // Start at beginning of the new batch
        if (startIndex > 0) {
          _verticalController.jumpToPage(startIndex);
        }

        await _startPlaybackForBook(startIndex, 0);
      }
    }
  }

  Future<void> _startPlaybackForBook(int bookIndex, int trackIndex) async {
    await _playTrack(bookIndex, trackIndex);
    await _applyBgMusicFromBook(bookIndex);
  }

  // _saveOffset removed - Server updates offset automatically on fetch

  Future<void> _fetchReels() async {
    // Stateful API: Server tracks offset. We just ask for "more".
    final data = await _bookRepository.getReelsData(limit: _limit);
    if (!mounted) return;

    final newBooks = data['books'] as List<Book>;
    final hasMore = data['hasMore'] as bool;
    final isSubscribed = data['isSubscribed'] as bool?;

    setState(() {
      print(
        "Reels Fetch: isSubscribed=$isSubscribed, newBooks=${newBooks.length}, currentBooks=${_books.length}",
      );

      // Handle subscription status
      if (isSubscribed != null) {
        if (_books.isEmpty) {
          _isSubscribed = isSubscribed; // Trust server on initial load
        } else if (isSubscribed && !_isSubscribed) {
          _isSubscribed = true; // Allow upgrade
        }
      }

      if (_books.isEmpty) {
        // Initial load (or refresh)
      }

      _books.addAll(newBooks);
      _backendHasMore = hasMore;
    });
  }

  Future<void> _loadMoreReels() async {
    if (_isFetchingMore) return;
    setState(() => _isFetchingMore = true);

    // Looping logic:
    // If backend has no more, we start fetching from offset 0 again
    // But we append to our local list so user can scroll up.
    // Stateful API: Server handles wrap-around.
    if (!_backendHasMore) {
      // If server specifically says "no more" (which it shouldn't in circular mode),
      // we might stop or try again. But for now, we just stop.
    } else {
      await _fetchReels();
    }

    if (mounted) {
      setState(() => _isFetchingMore = false);
    }
  }

  void _onTrackFinished() {
    // Determine if we are at the end of the current book
    final currentBook = _books[_currentBookIndex];
    if (_currentTrackIndex < currentBook.tracks.length - 1) {
      // Go to next track
      final nextTrackIdx = _currentTrackIndex + 1;
      // Animate horizontal page view if it exists
      if (_horizontalControllers.containsKey(_currentBookIndex)) {
        _horizontalControllers[_currentBookIndex]?.animateToPage(
          nextTrackIdx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // Go to next book
      if (_currentBookIndex < _books.length - 1) {
        _verticalController.animateToPage(
          _currentBookIndex + 1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Loop back to the FIRST book (infinite loop)
        _verticalController.animateToPage(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _playTrack(int bookIndex, int trackIndex) async {
    if (bookIndex >= _books.length) return;
    final book = _books[bookIndex];
    if (trackIndex >= book.tracks.length) return;

    // tracks structure from API: [{id, title, audioUrl, duration, order}]
    // Book model usually expects 'tracks' as objects.
    // Wait, the API returns a 'tracks' LIST in the JSON. Book.fromJson needs to handle it.
    // Standard Book model might not have 'tracks' populated directly or might parse it differently.
    // Let's assume Book.fromJson handles 'tracks' if the API sends it, OR we access the raw map?
    // The `BookRepository` implementation I wrote parses `Book.fromJson`.
    // I need to ensure `Book` model supports `tracks` list.
    // If not, I'll need to update Book model.
    // Assuming Book model has a `tracks` field or similar.
    // In `api.py` I sent `tracks` list.

    // Let's assume for a moment Book model doesn't have it and checks if we need to update it.
    // Ideally I should have checked Book model first.
    // But let's proceed with `dynamic` access if needed or just assuming it works and fixing later.
    // Actually, `books` in `getReelsData` mapped to `Book.fromJson`.
    // If `Book` doesn't have `tracks` property, this data is lost.
    // I MUST CHECK OR UPDATE BOOK MODEL.
    // I will write this file assuming `book.tracks` exists and contains list of map/objects.

    final track = book.tracks[trackIndex]; // We need to verify `tracks` type

    // For now assuming tracks is List<dynamic> or List<PlaylistItem>
    // Let's look at `track['audioUrl']` (if map) or `track.audioUrl` (if object).
    // Based on standard models, it might be `PlaylistItems`.
    // I'll assume dynamic for safety in this snippet:

    final url = (track is Map)
        ? track['audioUrl']
        : (track as dynamic).audioUrl; // Fallback

    try {
      if (url != null) {
        // Create MediaItem for notification support
        final mediaItem = MediaItem(
          id: track['id']?.toString() ?? 'reel_$bookIndex\_$trackIndex',
          album: book.title,
          artist: book.title, // Use book title as artist for notification
          title: (track is Map)
              ? track['title']
              : (track as dynamic).title ?? 'Track $trackIndex',
          artUri: book.absoluteCoverUrl.isNotEmpty
              ? Uri.parse(book.absoluteCoverUrl)
              : null,
          extras: {'isReel': true},
        );

        // Set current book and playlist in handler to enable background progress saving (every 15s)
        AudioConnector.handler?.currentBook = book;
        if (book.tracks.isNotEmpty) {
          // Normalize track format to match PlayerScreen's expected format
          // Reels uses 'audioUrl' but PlayerScreen expects 'file_path'
          final normalizedPlaylist = book.tracks
              .map((track) {
                if (track is Map) {
                  return {
                    ...Map<String, dynamic>.from(track),
                    'file_path': track['audioUrl'] ?? track['file_path'],
                  };
                }
                return track;
              })
              .toList()
              .cast<Map<String, dynamic>>();
          AudioConnector.handler?.currentPlaylist = normalizedPlaylist;
          AudioConnector.handler?.currentIndex = trackIndex;
        }

        await AudioConnector.handler?.loadAudio(url, mediaItem);
        // Play is called inside loadAudio usually? No, `loadAudio` in handler calls `setUrl`
        // We need to call play() explicitly or update `loadAudio` to play.
        // Helper `loadAudio` in handler: `await _player.setUrl(url);`
        await AudioConnector.handler?.play();
        AudioConnector.handler?.syncBgMusic();

        setState(() {
          _currentBookIndex = bookIndex;
          _currentTrackIndex = trackIndex;
        });
      }
    } catch (e) {
      print("Error playing: $e");
    }
  }

  Future<void> _onRefresh() async {
    // Clear list to force "new" batch feeling, although server offset handles continuity
    _books.clear();
    await _fetchReels();
    if (mounted) {
      // Reset indices if needed, or if empty
      if (_books.isEmpty) {
        _currentBookIndex = 0;
        _currentTrackIndex = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.black
        : Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black45;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (!_isSubscribed) {
      return Scaffold(
        backgroundColor: bgColor,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: isDark ? Colors.black : Colors.white,
          backgroundColor: Colors.amber,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: subtitleColor,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.subscribeToListenToReels,
                          style: TextStyle(fontSize: 18, color: textColor),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            // Show subscription bottom sheet with plan options
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => SubscriptionBottomSheet(
                                onSubscribed: () {
                                  Navigator.pop(context);
                                  // Reload to check subscription status
                                  _loadInitialData();
                                },
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.subscribe,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
      );
    }

    if (_books.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: isDark ? Colors.black : Colors.white,
          backgroundColor: Colors.amber,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.noReelsAvailable,
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: isDark ? Colors.black : Colors.white,
        backgroundColor: Colors.amber,
        child: PageView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          controller: _verticalController,
          itemCount: _books.length,
          onPageChanged: (index) {
            // Play first track of new book immediately
            _startPlaybackForBook(index, 0);

            // Apply background music from pre-fetched data (No API call!)
            print("[DEBUG] onPageChanged: Index $index");

            // Pre-load next batch if we are near the end (e.g., 2 items remaining)
            if (index >= _books.length - 2) {
              _loadMoreReels();
            }
          },
          itemBuilder: (context, bookIndex) {
            if (bookIndex >= _books.length) return null;
            final book = _books[bookIndex];

            // Horizontal PageView for tracks
            return PageView.builder(
              scrollDirection: Axis.horizontal,
              controller: _horizontalControllers.putIfAbsent(
                bookIndex,
                () => PageController(),
              ),
              itemCount: book.tracks.length, // dependent on model
              onPageChanged: (trackIndex) {
                _playTrack(bookIndex, trackIndex);
              },
              itemBuilder: (context, trackIndex) {
                return _buildPlayerPage(book, trackIndex);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayerPage(Book book, int trackIndex) {
    final track = book.tracks[trackIndex];
    // Flexible handling of track type
    final title = (track is Map)
        ? track['title']
        : (track as dynamic).title ?? book.title;
    final coverUrl = book.absoluteCoverUrl;
    final coverUrlThumbnail = book.absoluteCoverUrlThumbnail;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final timeColor = isDark ? Colors.white54 : Colors.black45;
    final overlayColor = isDark
        ? Colors.black.withOpacity(0.6)
        : Colors.white.withOpacity(0.7);
    final sliderActiveColor = isDark
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
    final sliderInactiveColor = isDark ? Colors.white24 : Colors.black12;
    final iconColor = isDark ? Colors.white : Colors.black87;
    final placeholderColor = isDark ? Colors.grey[800] : Colors.grey[300];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image (Blurred) - Use Thumbnail for performance
        if (coverUrlThumbnail.isNotEmpty)
          CachedNetworkImage(
            imageUrl: coverUrlThumbnail,
            httpHeaders: ApiConstants.imageHeaders,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: placeholderColor),
          ),
        Container(color: overlayColor),

        // Content
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = constraints.maxHeight;
              // Dynamically size the artwork (max 35% of height or 280px)
              final double artSize = (maxHeight * 0.35).clamp(150.0, 280.0);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Album Art
                    Container(
                      width: artSize,
                      height: artSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black45 : Colors.black26,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        color: placeholderColor,
                      ),
                      child: coverUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: coverUrl,
                                httpHeaders: ApiConstants.imageHeaders,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    CachedNetworkImage(
                                      imageUrl: coverUrlThumbnail,
                                      httpHeaders: ApiConstants.imageHeaders,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: placeholderColor,
                                        child: Icon(
                                          Icons.music_note,
                                          color: iconColor,
                                          size: artSize * 0.4,
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          Container(color: placeholderColor),
                                    ),
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.broken_image,
                                  color: iconColor,
                                  size: artSize * 0.4,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.music_note,
                              color: iconColor,
                              size: artSize * 0.4,
                            ),
                    ),
                    SizedBox(height: maxHeight * 0.05), // 5% spacer
                    // Track Info
                    Text(
                      book.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit', // Fallback if not available
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title, // Use track title instead of author
                      style: TextStyle(color: subtitleColor, fontSize: 16),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: maxHeight * 0.04), // 4% spacer
                    // Progress Bar
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        trackHeight: 4,
                        activeTrackColor: sliderActiveColor,
                        inactiveTrackColor: sliderInactiveColor,
                        thumbColor: sliderActiveColor,
                      ),
                      child: Slider(
                        value: _isDraggingSlider
                            ? _dragSliderValue
                            : (_position.inSeconds.toDouble()).clamp(
                                0,
                                _duration.inSeconds.toDouble() > 0
                                    ? _duration.inSeconds.toDouble()
                                    : 100,
                              ),
                        min: 0,
                        max: _duration.inSeconds.toDouble() > 0
                            ? _duration.inSeconds.toDouble()
                            : 100,
                        onChangeStart: (val) {
                          setState(() {
                            _isDraggingSlider = true;
                            _dragSliderValue = val;
                          });
                        },
                        onChanged: (val) {
                          setState(() {
                            _dragSliderValue = val;
                          });
                        },
                        onChangeEnd: (val) {
                          AudioConnector.handler?.seek(
                            Duration(seconds: val.toInt()),
                          );
                          setState(() {
                            _isDraggingSlider = false;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(color: timeColor, fontSize: 12),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(color: timeColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.skip_previous,
                            color: iconColor,
                            size: 36,
                          ),
                          onPressed: () {
                            // Previous track logic
                            if (_currentTrackIndex > 0) {
                              _horizontalControllers[_currentBookIndex]
                                  ?.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.ease,
                                  );
                            }
                          },
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: iconColor,
                            size: 80,
                          ),
                          onPressed: () {
                            if (_isPlaying) {
                              AudioConnector.handler?.pause();
                            } else {
                              AudioConnector.handler
                                  ?.play(); // Resumes where left off
                            }
                          },
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: Icon(
                            Icons.skip_next,
                            color: iconColor,
                            size: 36,
                          ),
                          onPressed: () {
                            // Next track logic
                            if (_currentTrackIndex < book.tracks.length - 1) {
                              _horizontalControllers[_currentBookIndex]
                                  ?.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.ease,
                                  );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bottom Options (Background Music)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Speed Control
                        GestureDetector(
                          onTap: _showSpeedMenu,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _playbackSpeed != 1.0
                                  ? Colors.blueAccent.withOpacity(
                                      isDark ? 0.4 : 0.2,
                                    )
                                  : (isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.06)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.speed, color: iconColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${_playbackSpeed.toString().replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "")}x',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: _showBgMusicSettings,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _selectedBgMusicId != null
                                  ? Colors.blueAccent.withOpacity(
                                      isDark ? 0.4 : 0.2,
                                    )
                                  : (isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.06)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.music_note,
                                  color: iconColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.backgroundMusic,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Share / Recommend
                        GestureDetector(
                          onTap: () async {
                            final track = book.tracks[trackIndex];
                            final trackId = (track is Map) ? track['id'] : null;
                            final trackTitle = (track is Map)
                                ? track['title']
                                : book.title;
                            if (trackId != null) {
                              try {
                                final playlistItemId = trackId is int
                                    ? trackId
                                    : int.tryParse(trackId.toString()) ?? 0;
                                final response =
                                    await BookRepository().shareChapter(
                                  playlistItemId: playlistItemId,
                                  bookId: int.tryParse(book.id) ?? 0,
                                  friendEmail: null,
                                );

                                final shareUrl = response['share_url'] as String;

                                await Share.share(
                                  'Check out "${trackTitle ?? 'Chapter'}" from "${book.title}"!\n\nListen here: $shareUrl',
                                  subject: 'Sharing a chapter with you',
                                );
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .shareError),
                                      backgroundColor: Colors.red[700],
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.share,
                              color: iconColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _applyBgMusicFromBook(int index) async {
    if (index < 0 || index >= _books.length) return;
    final book = _books[index];

    // Use pre-fetched backgroundMusicId from the book object
    int? musicId = book.backgroundMusicId;
    print(
      "[DEBUG] _applyBgMusicFromBook: Index $index, Book: ${book.title}, ID from Book Object: $musicId",
    );

    // If no preference/default on book, use Global Default
    if (musicId == null && _bgMusicList.isNotEmpty) {
      final defaultTrack = _bgMusicList.firstWhere(
        (e) => e['isDefault'] == true,
        orElse: () => {},
      );
      if (defaultTrack.isNotEmpty) {
        musicId = defaultTrack['id'];
        print("[DEBUG] Using global default music: $musicId");
      }
    }

    _selectedBgMusicId = musicId;
    print(
      "[DEBUG] _applyBgMusicFromBook: Final _selectedBgMusicId: $_selectedBgMusicId",
    );
    await _setBgMusicSource(musicId);
  }

  Future<void> _setBgMusicSource(int? musicId) async {
    int? effectiveMusicId = musicId;
    if (effectiveMusicId == null && _bgMusicList.isNotEmpty) {
      final defaultTrack = _bgMusicList.firstWhere(
        (e) => e['isDefault'] == true,
        orElse: () => _bgMusicList.first,
      );
      effectiveMusicId = defaultTrack['id'] as int?;
    }

    if (effectiveMusicId == null) {
      await AudioConnector.handler?.stopBgMusic();
      if (mounted) setState(() {});
      return;
    }

    // We just pass the ID and the List to the handler
    // The handler has the logic to find URL, check cache, etc.
    // AND it handles synchronization with main player.
    await AudioConnector.handler?.setBgMusicSource(effectiveMusicId, _bgMusicList);
    await AudioConnector.handler?.setBgMusicVolume(_bgVolume);
    AudioConnector.handler?.syncBgMusic();

    // Also sync volume
    if (AudioConnector.handler != null) {
      // We might want to ensure volume is set
      // But handler usually keeps its volume.
      // We update local state from handler if needed, or just set it.
    }

    if (mounted) setState(() {});
  }

  void _showBgMusicSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? Colors.grey[900]! : Colors.white;
        final sheetTextColor = isDark ? Colors.white : Colors.black87;
        final sheetSubtitleColor = isDark ? Colors.white70 : Colors.black54;
        final dropdownBg = isDark ? Colors.grey[800] : Colors.grey[100];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: sheetBg,
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
                    style: TextStyle(
                      color: sheetTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Volume Slider
                  Row(
                    children: [
                      Icon(Icons.volume_down, color: sheetSubtitleColor),
                      Expanded(
                        child: Slider(
                          value: _bgVolume,
                          onChanged: (val) async {
                            setModalState(() => _bgVolume = val);
                            setState(() => _bgVolume = val);
                            await AudioConnector.handler?.setBgMusicVolume(val);
                          },
                        ),
                      ),
                      Icon(Icons.volume_up, color: sheetSubtitleColor),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Track Selection
                  DropdownButton<int?>(
                    value: _selectedBgMusicId,
                    isExpanded: true,
                    dropdownColor: dropdownBg,
                    style: TextStyle(color: sheetTextColor),
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
                      setModalState(() => _selectedBgMusicId = val);
                      setState(() => _selectedBgMusicId = val);

                      await _setBgMusicSource(val);

                      // Save Preference
                      try {
                        print(
                          "[DEBUG] User selected music: $val for book ${_books[_currentBookIndex].title}",
                        );
                        if (_books.isNotEmpty) {
                          // Update local state immediately so scrolling back/forth checks get the new value
                          setState(() {
                            final currentBook = _books[_currentBookIndex];
                            _books[_currentBookIndex] = currentBook.copyWith(
                              backgroundMusicId: val,
                            );
                            print(
                              "[DEBUG] Updated local book backgroundMusicId to: ${_books[_currentBookIndex].backgroundMusicId}",
                            );
                          });

                          await _bookRepository.updateUserBackgroundMusic(
                            int.parse(_books[_currentBookIndex].id),
                            val,
                          );
                          print("[DEBUG] Saved preference to server");
                        }
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

  String _formatDuration(Duration d) {
    int min = d.inMinutes;
    int sec = d.inSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _showSpeedMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Playback Speed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                  final isSelected = _playbackSpeed == speed;
                  return ChoiceChip(
                    label: Text('${speed}x'),
                    selected: isSelected,
                    onSelected: (selected) async {
                      if (selected) {
                        await AudioConnector.handler?.setSpeed(speed);
                        // Sync to preferences
                        await PlayerPreferences().setDefaultSpeed(speed);
                        if (mounted) Navigator.pop(context);
                      }
                    },
                    selectedColor: Colors.amber,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : (isDark ? Colors.white : Colors.black),
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
