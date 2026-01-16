import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/book.dart';

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  // Track the current book and playlist for mini player tap
  Book? currentBook;
  List<Map<String, dynamic>>? currentPlaylist;
  int currentIndex = 0;
  String? currentUniqueAudioId;

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

    // Listen for track completion to auto-advance
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // Track finished - try to play next track
        playNextTrack();
      }
    });
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

  // Seek to position
  @override
  Future<void> seek(Duration position) => _player.seek(position);

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
    // Update the media item
    this.mediaItem.add(mediaItem);

    // Load the local file
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
    );

    currentBook = trackBook;

    // Create MediaItem
    final mediaItem = MediaItem(
      id: 'track_${track['id']}',
      album: currentBook!.title,
      title: trackTitle,
      artist: currentBook!.author,
      artUri: Uri.parse(currentBook!.coverUrl ?? ''),
    );

    // Load and play
    final cleanUrl = trackUrl.startsWith('http')
        ? trackUrl
        : 'http://10.54.45.89:5000$trackUrl';
    await loadAudio(cleanUrl, mediaItem);
    await play();
  }
}
