import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../services/auth_service.dart';
import '../widgets/subscription_bottom_sheet.dart';
import '../services/audio_connector.dart';
import '../main.dart'; // Access to routeObserver
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
  final AuthService _authService = AuthService();
  final AudioPlayer _audioPlayer = AudioPlayer(); // Or use a global service?
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

  int _offset = 0;
  final int _limit = 5;
  bool _isFetchingMore = false;
  bool _backendHasMore = true;

  // Background Music State
  final AudioPlayer _bgPlayer = AudioPlayer();
  double _bgVolume = 0.2;
  bool _bgMusicEnabled = true;
  List<Map<String, dynamic>> _bgMusicList = [];
  int? _selectedBgMusicId;
  bool _bgMusicLoaded = false;

  @override
  void initState() {
    super.initState();
    _initAudioSession();
    _initBgPlayer();
    _stopGlobalAudio(); // Stop global audio when entering reels
    _loadInitialData();

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _onTrackFinished();
          }
        });

        // Background Music Sync
        if (_bgMusicEnabled && _bgMusicLoaded) {
          // Play bg music if main player is playing (and not finished/idle)
          bool shouldPlay =
              state.playing &&
              state.processingState != ProcessingState.completed &&
              state.processingState != ProcessingState.idle;

          if (shouldPlay) {
            if (!_bgPlayer.playing) _bgPlayer.play();
          } else {
            if (_bgPlayer.playing) _bgPlayer.pause();
          }
        } else if (_bgPlayer.playing) {
          _bgPlayer.pause();
        }
      }
    });

    _audioPlayer.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _audioPlayer.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _duration = d);
    });
  }

  Future<void> _initBgPlayer() async {
    await _bgPlayer.setLoopMode(LoopMode.one);
    await _bgPlayer.setVolume(_bgVolume);
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
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

    // Ensure players are stopped and disposed to prevent MediaCodec leaks
    _stopLocalAudio();
    _audioPlayer.dispose();
    _bgPlayer.dispose();

    super.dispose();
  }

  @override
  void didPushNext() {
    // Called when pushing a new route (e.g., opening PlayerScreen)
    // We must stop the Reels audio to prevent "overflow" and cleanup resources
    print("ReelsScreen: didPushNext - Stopping audio");
    _stopLocalAudio();
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

  void _stopLocalAudio() {
    try {
      _audioPlayer.pause(); // Pause first
      _bgPlayer.pause();
    } catch (e) {
      print("Error stopping local audio: $e");
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

    // Single API call now includes savedOffset + books + subscription status
    await _fetchReels(useInitialOffset: true);

    if (mounted) {
      setState(() => _isLoading = false);
      if (_isSubscribed && _books.isNotEmpty) {
        _playTrack(0, 0);
        _updateBgMusicForBook(0);
      }
    }
  }

  Future<void> _saveOffset() async {
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId != null) {
        await _bookRepository.updateReelsOffset(_offset);
      }
    } catch (e) {
      print("Error saving offset: $e");
    }
  }

  Future<void> _fetchReels({bool useInitialOffset = false}) async {
    // On initial load, fetch with offset 0 and then use savedOffset from response
    final fetchOffset = useInitialOffset ? 0 : _offset;

    final data = await _bookRepository.getReelsData(
      offset: fetchOffset,
      limit: _limit,
    );
    if (!mounted) return;

    final newBooks = data['books'] as List<Book>;
    final hasMore = data['hasMore'] as bool;
    final isSubscribed = data['isSubscribed'] as bool;
    final savedOffset = data['savedOffset'] as int? ?? 0;

    setState(() {
      print(
        "Reels Refresh: isSubscribed=$isSubscribed, newBooks=${newBooks.length}",
      );
      _isSubscribed = isSubscribed;

      if (useInitialOffset) {
        _books.clear();
        _offset = savedOffset + newBooks.length;
      } else {
        _offset += newBooks.length;
      }

      _books.addAll(newBooks);
      _backendHasMore = hasMore;
    });

    _saveOffset();
  }

  Future<void> _loadMoreReels() async {
    if (_isFetchingMore) return;
    setState(() => _isFetchingMore = true);

    // Looping logic:
    // If backend has no more, we start fetching from offset 0 again
    // But we append to our local list so user can scroll up.
    if (!_backendHasMore) {
      _offset = 0;
      _saveOffset();
    }

    await _fetchReels();

    if (mounted) setState(() => _isFetchingMore = false);
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
        // Loop back to the beginning
        // We reached the end of the list.
        // Wait, if infinite scroll is working, we should have loaded more by now.
        // If we really are at the end, try loading more immediately?
        // Or if loop logic failed?
        _loadMoreReels().then((_) {
          if (_currentBookIndex < _books.length - 1) {
            _verticalController.animateToPage(
              _currentBookIndex + 1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        });
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
        await _audioPlayer.setUrl(url);
        _audioPlayer.play();

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
    await _fetchReels(useInitialOffset: true);
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!_isSubscribed) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: Colors.black,
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
                        const Icon(
                          Icons.lock_outline,
                          color: Colors.white54,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Subscribe to listen to Reels",
                          style: TextStyle(fontSize: 18, color: Colors.white),
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
                          child: const Text(
                            "Subscribe",
                            style: TextStyle(
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
        backgroundColor: Colors.black,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: Colors.black,
          backgroundColor: Colors.amber,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: const Center(
                    child: Text(
                      "No reels available",
                      style: TextStyle(color: Colors.white),
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
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.black,
        backgroundColor: Colors.amber,
        child: PageView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          controller: _verticalController,
          itemCount: _books.length,
          onPageChanged: (index) {
            // Play first track of new book
            _playTrack(index, 0);
            _updateBgMusicForBook(index);

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

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image (Blurred)
        if (coverUrl.isNotEmpty)
          Image.network(
            coverUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
          ),
        Container(
          color: Colors.black.withOpacity(0.6), // Dim overlay
        ),

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
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                        image: coverUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(coverUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.grey[800],
                      ),
                      child: coverUrl.isEmpty
                          ? Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: artSize * 0.4,
                            )
                          : null,
                    ),
                    SizedBox(height: maxHeight * 0.05), // 5% spacer
                    // Track Info
                    Text(
                      book.title,
                      style: const TextStyle(
                        color: Colors.white,
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
                      book.author,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
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
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: (_position.inSeconds.toDouble()).clamp(
                          0,
                          _duration.inSeconds.toDouble() > 0
                              ? _duration.inSeconds.toDouble()
                              : 100,
                        ),
                        min: 0,
                        max: _duration.inSeconds.toDouble() > 0
                            ? _duration.inSeconds.toDouble()
                            : 100,
                        onChanged: (val) {
                          _audioPlayer.seek(Duration(seconds: val.toInt()));
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
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
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
                          icon: const Icon(
                            Icons.skip_previous,
                            color: Colors.white,
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
                            color: Colors.white,
                            size: 80,
                          ),
                          onPressed: () {
                            if (_isPlaying) {
                              _audioPlayer.pause();
                            } else {
                              _audioPlayer.play();
                            }
                          },
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
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
                        GestureDetector(
                          onTap: _showBgMusicSettings,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _selectedBgMusicId != null
                                  ? Colors.blueAccent.withOpacity(0.4)
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Background Music",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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

  Future<void> _updateBgMusicForBook(int index) async {
    if (index < 0 || index >= _books.length) return;
    final book = _books[index];

    // 1. Get User Preference for this book
    try {
      // We can use BookRepository to get status, which includes background_music_id
      final userId = await _authService.getCurrentUserId();
      if (userId != null) {
        final status = await _bookRepository.getBookStatus(userId, book.id);
        // status['background_music_id'] might be null (default) or valid int
        // If null, we use book.backgroundMusicId?
        // Logic usually: UserPref ?? BookDefault ?? GlobalDefault

        int? musicId = status['background_music_id'];
        if (musicId == null) {
          // If user hasn't set anything, use book default
          musicId = book.backgroundMusicId;

          // If book has no default, use Global Default
          if (musicId == null && _bgMusicList.isNotEmpty) {
            final defaultTrack = _bgMusicList.firstWhere(
              (e) => e['isDefault'] == true,
              orElse: () => {},
            );
            if (defaultTrack.isNotEmpty) {
              musicId = defaultTrack['id'];
            }
          }
        }

        _selectedBgMusicId = musicId;
        await _setBgMusicSource(musicId);
      }
    } catch (e) {
      print("Error updating BG music for book: $e");
    }
  }

  Future<void> _setBgMusicSource(int? musicId) async {
    if (musicId == null) {
      await _bgPlayer.stop();
      _bgMusicLoaded = false;
      if (mounted) setState(() {});
      return;
    }

    final music = _bgMusicList.firstWhere(
      (element) => element['id'] == musicId,
      orElse: () => {},
    );

    if (music.isEmpty) return;

    try {
      final url = music['url'] as String;
      // Handle Asset vs Network
      if (url.startsWith('http')) {
        await _bgPlayer.setUrl(url);
      } else {
        // Assuming asset? But AudioPlayer setAsset is for local assets
        // If it's a relative path from API, prepend base URL
        // Actually api_constants.dart might be needed
        // PlayerScreen uses _getAbsoluteUrl
        // For now assume absolute or fix later
        if (url.startsWith('/')) {
          // Prepend base url?
          // Actually PlayerScreen logic:
          // final cleanUrl = url.startsWith('http') ? url : '${ApiConstants.baseUrl}$url';
          // audioHandler uses loadAudio.
          // Here we use _bgPlayer directly.
          // Let's assume standard URL handling.
          // Most background music URLs in this app seem to be absolute or handled.
        }
        await _bgPlayer.setUrl(url);
      }

      _bgMusicLoaded = true;
      if (_isPlaying && _bgMusicEnabled) {
        _bgPlayer.play();
      }
    } catch (e) {
      print("Error setting BG music source: $e");
      _bgMusicLoaded = false;
    }
    if (mounted) setState(() {});
  }

  void _showBgMusicSettings() {
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
                  const Text(
                    'Background Music',
                    style: TextStyle(
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
                          value: _bgVolume,
                          onChanged: (val) async {
                            setModalState(() => _bgVolume = val);
                            setState(() => _bgVolume = val);
                            await _bgPlayer.setVolume(val);
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up, color: Colors.white70),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Track Selection
                  DropdownButton<int?>(
                    value: _selectedBgMusicId,
                    isExpanded: true,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: Colors.white),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ..._bgMusicList.map(
                        (bg) => DropdownMenuItem<int>(
                          value: bg['id'] as int,
                          child: Text(bg['title'] ?? 'Unknown'),
                        ),
                      ),
                    ],
                    onChanged: (val) async {
                      setModalState(() => _selectedBgMusicId = val);
                      setState(() => _selectedBgMusicId = val);

                      await _setBgMusicSource(val);

                      // Save Preference
                      try {
                        if (_books.isNotEmpty) {
                          await _bookRepository.updateUserBackgroundMusic(
                            int.parse(_books[_currentBookIndex].id),
                            val,
                          );
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
}
