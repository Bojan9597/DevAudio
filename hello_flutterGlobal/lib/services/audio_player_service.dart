import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();

  // Global flag to track if background audio is available
  bool _useBackgroundAudio = false;
  bool get useBackgroundAudio => _useBackgroundAudio;

  factory AudioPlayerService() {
    return _instance;
  }

  AudioPlayerService._internal();

  /// Access the singleton instance
  static AudioPlayerService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();

  /// Expose the player to the UI
  AudioPlayer get player => _player;

  /// Track the currently playing item ID to avoid reloading the same track
  String? _currentUniqueId;
  String? get currentUniqueId => _currentUniqueId;

  void setBackgroundAudioEnabled(bool enabled) {
    _useBackgroundAudio = enabled;
  }

  /// Start playing a new source.
  /// [uniqueId] is a unique identifier for this specific audio (e.g. book ID or track ID).
  /// If [uniqueId] matches the currently playing ID, we don't reload.
  /// [forceReload] can be used to restart the same track.
  Future<void> playAudio(
    AudioSource source, {
    required String uniqueId,
    bool forceReload = false,
  }) async {
    if (_currentUniqueId == uniqueId && !forceReload) {
      if (!_player.playing) {
        _player.play();
      }
      return;
    }

    try {
      // Stop previous playback
      // await _player.stop(); // setAudioSource usually handles stopping implicitly or smoothly switches

      await _player.setAudioSource(source);
      _currentUniqueId = uniqueId;
      _player.play();
    } catch (e) {
      print("Error managing audio source: $e");
      rethrow;
    }
  }

  /// Stop playback and clear the current ID tracking
  Future<void> stop() async {
    await _player.stop();
    // We might not want to clear ID if we want to support "resume" later?
    // But for "closing" the active session logic, maybe.
    // For now, let's keep ID so if they come back it *could* resume if we wanted,
    // but the UI typically reloads if it thinks it's a new session.
    // Actually, if we stop, we probably want to clear to force reload if they click play again?
    // Or just let it be paused.
  }
}
