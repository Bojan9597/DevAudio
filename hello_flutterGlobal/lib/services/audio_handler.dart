import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/book.dart';
import '../utils/api_constants.dart';
import '../repositories/book_repository.dart';
import 'download_service.dart';
import 'player_preferences.dart';
import '../widgets/content_area.dart';
import 'daily_goal_service.dart';

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  // Background music player - managed separately for background playback
  final AudioPlayer _bgPlayer = AudioPlayer();
  double _bgVolume = 0.2;
  bool _bgMusicEnabled = true;
  bool _bgMusicLoaded = false;
  int? _selectedBgMusicId;
  StreamSubscription? _bgSyncSubscription;

  AudioPlayer get player => _player;
  AudioPlayer get bgPlayer => _bgPlayer;
  double get bgVolume => _bgVolume;
  bool get bgMusicEnabled => _bgMusicEnabled;
  int? get selectedBgMusicId => _selectedBgMusicId;

  // Stream to notify listeners of track completion
  final StreamController<String> _trackCompletionController =
      StreamController<String>.broadcast();
  Stream<String> get trackCompletionStream => _trackCompletionController.stream;

  // Track the current book and playlist for mini player tap
  Book? currentBook;
  List<Map<String, dynamic>>? currentPlaylist;
  int currentIndex = 0;
  String? currentUniqueAudioId;

  // Background progress sync
  Timer? _progressTimer;
  int? _userId;

  MyAudioHandler() {
    // Initialize background music player settings
    _bgPlayer.setLoopMode(LoopMode.one);
    _bgPlayer.setVolume(_bgVolume);

    // Sync background music with main player
    _bgSyncSubscription = _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = state.processingState;

      // Only play if:
      // 1. Player is actively playing
      // 2. Audio is NOT finished (completed)
      // 3. Audio is NOT empty (idle)
      bool shouldPlay =
          playing &&
          processingState != ProcessingState.completed &&
          processingState != ProcessingState.idle;

      if (shouldPlay) {
        // Only play if loaded and enabled
        if (_bgMusicLoaded && _bgMusicEnabled) {
          _bgPlayer.play();
        }
      } else {
        // ALWAYS pause background music if main player stops or finishes
        _bgPlayer.pause();
      }
    });

    // Listen to player state and update audio service
    _player.playbackEventStream.listen((event) {
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (_player.playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: _player.playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: 0,
        ),
      );
    });

    // Auto-advance to next track when current one is completed
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // Emit completion event for UI (e.g., LessonMap)
        if (currentPlaylist != null &&
            currentIndex >= 0 &&
            currentIndex < currentPlaylist!.length) {
          final trackId = currentPlaylist![currentIndex]['id'].toString();
          _trackCompletionController.add(trackId);
        }

        // Automatically skip to next track
        skipToNext();
      }
    });

    // Update MediaItem with duration when it becomes available (for lock screen progress)
    _player.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null) {
        final currentItem = mediaItem.value!;
        if (currentItem.duration != duration) {
          mediaItem.add(currentItem.copyWith(duration: duration));
        }
      }
    });

    // Start background progress sync timer
    _startBackgroundProgressSync();
  }

  // ============ Background Music Methods ============

  /// Set background music source from URL or local file
  Future<void> setBgMusicSource(
    int? bgMusicId,
    List<Map<String, dynamic>> bgMusicList,
  ) async {
    // Avoid reloading if same source
    if (_selectedBgMusicId == bgMusicId && _bgMusicLoaded) {
      // Check if we need to sync play state (e.g. if main player is playing but bg is not)
      if (_bgMusicEnabled) {
        final mainPlaying =
            _player.playing ||
            _player.processingState == ProcessingState.loading ||
            _player.processingState == ProcessingState.buffering;
        if (mainPlaying && !_bgPlayer.playing) {
          _bgPlayer.play();
        }
      }
      return;
    }

    _selectedBgMusicId = bgMusicId;
    _bgMusicLoaded = false;
    await _bgPlayer.stop(); // FORCE STOP immediately when switching

    if (bgMusicId == null) {
      await stopBgMusic();
      return;
    }

    final track = bgMusicList.firstWhere(
      (e) => e['id'] == bgMusicId,
      orElse: () => {},
    );
    if (track.isEmpty || track['url'] == null) {
      await stopBgMusic();
      return;
    }

    // Handle URL (ensure absolute)
    String url = track['url'];
    if (!url.startsWith('http')) {
      url = '${ApiConstants.baseUrl}$url';
    }

    try {
      // Cache Logic
      final String fileName = 'bg_music_${track['id']}.mp3';
      final downloadService = DownloadService();

      // Check cache first to avoid redundant download calls
      final String filePath = await downloadService.getLocalFilePath(fileName);
      final file = File(filePath);

      if (!await file.exists()) {
        // Download if not exists
        await downloadService.downloadFile(url, fileName);
      }

      if (await file.exists()) {
        await _bgPlayer.setFilePath(filePath);
      } else {
        // Fallback to URL with headers
        await _bgPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            headers: {
              ApiConstants.appSourceHeader: ApiConstants.appSourceValue,
            },
          ),
        );
      }

      _bgMusicLoaded = true;

      // After loading, check current main player state and sync
      // Use longer delay with retry to handle buffering scenarios
      // Retry for up to 5 seconds (10 checks * 500ms)
      for (int attempt = 0; attempt < 10; attempt++) {
        // Check IMMEDIATELY on first attempt, then wait
        if (attempt > 0)
          await Future.delayed(const Duration(milliseconds: 500));

        final isMainPlayerPlaying = _player.playing;
        // RELAXED CONDITION: Allow sync even if processingState is buffering.
        // The main player handles its own UI (we just fixed that), so bg music
        // should try to start if the intent is to play.

        if (isMainPlayerPlaying && _bgMusicEnabled) {
          if (!_bgPlayer.playing) {
            // Seek to 0 only if not already playing (to avoid stutter on re-sync)
            // But if it's a fresh load, position is 0 anyway.
            // await _bgPlayer.seek(Duration.zero);
            _bgPlayer.play();
            print(
              '[AudioHandler] BG music started (post-load sync, attempt ${attempt + 1})',
            );
          }
          break; // Successfully started, exit retry loop
        } else {
          print(
            '[AudioHandler] BG sync retry ${attempt + 1}: main player not playing yet (state: ${_player.processingState})',
          );
          // If we've tried for 2 seconds and still nothing, maybe pause BG just in case
          if (attempt >= 4 && _bgPlayer.playing) {
            _bgPlayer.pause();
          }
        }
      }

      print('[AudioHandler] Background music loaded: ${track['title']}');
    } catch (e) {
      print('[AudioHandler] Error loading BG music source: $e');
      _bgMusicLoaded = false;
    }
  }

  /// Set background music volume
  Future<void> setBgMusicVolume(double volume) async {
    _bgVolume = volume;
    await _bgPlayer.setVolume(volume);
  }

  /// Stop background music
  Future<void> stopBgMusic() async {
    await _bgPlayer.stop();
    _bgMusicLoaded = false;
    _selectedBgMusicId = null;
  }

  /// Force-sync background music with main player.
  /// Call after all initialization is complete to ensure bg music is playing.
  void syncBgMusic() {
    if (_bgMusicLoaded && _bgMusicEnabled && _player.playing) {
      if (!_bgPlayer.playing) {
        _bgPlayer.play();
        print('[AudioHandler] BG music force-synced');
      }
    }
  }

  /// Toggle background music enabled state
  void toggleBgMusicEnabled(bool enabled) {
    _bgMusicEnabled = enabled;
    if (!enabled) {
      _bgPlayer.pause();
    } else if (_bgMusicLoaded && _player.playing) {
      _bgPlayer.play();
    }
  }

  /// Initialize user ID for background progress sync
  Future<void> setUserId(int? userId) async {
    _userId = userId;
  }

  /// Start periodic background progress sync (every 15 seconds)
  void _startBackgroundProgressSync() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_player.playing) {
        _performSave();
        // Track daily goal progress
        DailyGoalService().addSeconds(15);
      }
    });
  }

  Future<void> _saveProgressInBackground() async {
    await _performSave();
  }

  Future<void> _performSave() async {
    if (_userId == null || currentBook == null) return;

    final position = _player.position.inSeconds;
    final duration = _player.duration?.inSeconds;

    if (position <= 0) return;

    // Get playlist_item_id if playing a playlist track
    String? playlistItemId;
    if (currentPlaylist != null && currentPlaylist!.isNotEmpty) {
      final currentTrack = currentPlaylist![currentIndex];
      playlistItemId = currentTrack['id']?.toString();
    }

    try {
      await BookRepository().updateProgress(
        _userId!,
        currentBook!.id,
        position,
        duration,
        playlistItemId: playlistItemId,
      );
      print('[AudioHandler] Background progress saved: $position seconds');
      // Invalidate Library Cache so UI updates on next visit
      ContentArea.invalidateLibraryCache();
    } catch (e) {
      print('[AudioHandler] Failed to save background progress: $e');
    }
  }

  // Play the current audio source
  @override
  Future<void> play() async {
    await _player.play();

    // Ensure background music starts if enabled
    if (_bgMusicEnabled && _bgMusicLoaded && !_bgPlayer.playing) {
      _bgPlayer.play();
    }
  }

  // Pause playback
  @override
  Future<void> pause() async {
    // Save progress *before* stopping playback to capture final position
    await _performSave();

    await _player.pause();
    await _bgPlayer.pause(); // Explicitly pause background music
  }

  // Stop playback and reset
  @override
  Future<void> stop() async {
    await _player.stop();
    await stopBgMusic();
    await super.stop();
  }

  /// Clear all playback state (used on logout)
  Future<void> clearState() async {
    await _player.stop();
    await stopBgMusic();
    _bgSyncSubscription?.cancel();
    mediaItem.add(null); // Clear media item to hide mini player
    currentBook = null;
    currentPlaylist = null;
    currentIndex = 0;
    currentUniqueAudioId = null;
    _userId = null;
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> seekForward(bool begin) async {
    final prefs = PlayerPreferences();
    final interval = await prefs.getSkipForward();
    final newPos = _player.position + Duration(seconds: interval);
    // Clamp to duration
    final duration = _player.duration;
    if (duration != null && newPos > duration) {
      _player.seek(duration);
    } else {
      _player.seek(newPos);
    }
  }

  @override
  Future<void> seekBackward(bool begin) async {
    final prefs = PlayerPreferences();
    final interval = await prefs.getSkipBackward();
    final newPos = _player.position - Duration(seconds: interval);
    // Clamp to 0
    if (newPos < Duration.zero) {
      _player.seek(Duration.zero);
    } else {
      _player.seek(newPos);
    }
  }

  @override
  Future<void> skipToNext() => playNextTrack();

  @override
  Future<void> skipToPrevious() => playPreviousTrack();

  // Set playback speed
  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  // Custom method to load audio with metadata
  Future<void> loadAudio(String url, MediaItem mediaItem) async {
    // Update the media item in the audio service
    this.mediaItem.add(mediaItem);

    // Load the audio with custom headers for WAF
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(url),
        headers: {ApiConstants.appSourceHeader: ApiConstants.appSourceValue},
      ),
    );
  }

  // Custom method to load local file
  Future<void> loadLocalFile(String filePath, MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
    await _player.setFilePath(filePath);
  }

  // Navigate to next track in playlist
  Future<bool> playNextTrack() async {
    if (currentPlaylist == null ||
        currentIndex >= currentPlaylist!.length - 1) {
      return false; // No next track
    }

    currentIndex++;
    await _loadAndPlayTrack(currentIndex);
    return true;
  }

  // Navigate to previous track in playlist
  Future<bool> playPreviousTrack() async {
    if (currentPlaylist == null || currentIndex <= 0) {
      return false; // No previous track
    }

    currentIndex--;
    await _loadAndPlayTrack(currentIndex);
    return true;
  }

  // Helper to load and play a track from the playlist
  Future<void> _loadAndPlayTrack(int index) async {
    if (currentPlaylist == null || currentBook == null) return;

    final track = currentPlaylist![index];
    final trackUrl = track['file_path'];
    final trackTitle = track['title'];

    // Create updated Book for this track
    final trackBook = Book(
      id: currentBook!.id,
      title: trackTitle,
      author: currentBook!.author,
      audioUrl: trackUrl,
      coverUrl: currentBook!.coverUrl,
      categoryId: currentBook!.categoryId,
      subcategoryIds: const [],
      postedBy: currentBook!.postedBy,
      description: currentBook!.description,
      price: currentBook!.price,
      postedByUserId: currentBook!.postedByUserId,
      isPlaylist: false,
      isFavorite: currentBook!.isFavorite,
      isEncrypted: currentBook!.isEncrypted, // Propagate encryption status
    );

    currentBook = trackBook;

    // Create MediaItem
    final mediaItem = MediaItem(
      id: 'track_${track['id']}',
      album: currentBook!.title,
      title: trackTitle,
      artist: currentBook!.author,
      artUri:
          (currentBook!.coverUrl != null && currentBook!.coverUrl!.isNotEmpty)
          ? Uri.parse(currentBook!.absoluteCoverUrl)
          : null,
    );

    // Check if track is already downloaded locally
    final downloadService = DownloadService();
    final trackStorageId = 'track_${track['id']}';
    final userId = _userId;
    final bookId = currentBook!.id;
    final isDownloaded = await downloadService.isBookDownloaded(
      trackStorageId,
      userId: userId,
      bookId: bookId,
    );

    if (isDownloaded) {
      final localPath = await downloadService.getLocalBookPath(
        trackStorageId,
        userId: userId,
        bookId: bookId,
      );
      await loadLocalFile(localPath, mediaItem);
    } else {
      // Stream from URL
      final cleanUrl = trackUrl.startsWith('http')
          ? trackUrl
          : '${ApiConstants.baseUrl}$trackUrl';
      await loadAudio(cleanUrl, mediaItem);
    }

    await play();
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
}
