import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/book.dart';
import '../utils/api_constants.dart';
import '../repositories/book_repository.dart';

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  // Track the current book and playlist for mini player tap
  Book? currentBook;
  List<Map<String, dynamic>>? currentPlaylist;
  int currentIndex = 0;
  String? currentUniqueAudioId;

  // Background progress sync
  Timer? _progressTimer;
  int? _userId;

  MyAudioHandler() {
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

    // Load and play
    final cleanUrl = trackUrl.startsWith('http')
        ? trackUrl
        : '${ApiConstants.baseUrl}$trackUrl';

    // Stream directly (no encryption)
    await loadAudio(cleanUrl, mediaItem);

    await play();
  }
}
