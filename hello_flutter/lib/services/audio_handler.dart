import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

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
}
