import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/book.dart';
import '../utils/api_constants.dart';
import '../repositories/book_repository.dart';
import 'download_service.dart';

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
    _bgSyncSubscription = _player.playingStream.listen((playing) {
      if (!_bgMusicLoaded || !_bgMusicEnabled) return;
      if (playing) {
        _bgPlayer.play();
      } else {
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
    _selectedBgMusicId = bgMusicId;

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
        // Fallback to URL
        await _bgPlayer.setUrl(url);
      }

      _bgMusicLoaded = true;

      // Start playing if main player is playing
      if (_player.playing && _bgMusicEnabled) {
        _bgPlayer.play();
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
      _saveProgressInBackground();
    });
  }

  /// Save progress even when app is in background
  Future<void> _saveProgressInBackground() async {
    if (_userId == null || !_player.playing || currentBook == null) return;

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
    } catch (e) {
      print('[AudioHandler] Failed to save background progress: $e');
    }
  }

  // Play the current audio source
  @override
  Future<void> play() => _player.play();

  // Pause playback
  @override
  Future<void> pause() => _player.pause();

  // Stop playback and reset
  @override
  Future<void> stop() async {
    await _player.stop();
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

  // Seek to position
  @override
  Future<void> seek(Duration position) => _player.seek(position);

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

    // Load the audio
    await _player.setUrl(url);
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
}
