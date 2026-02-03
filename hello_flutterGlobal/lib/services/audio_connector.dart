import 'audio_handler.dart';

/// A global accessor for the AudioHandler instance.
/// This avoids circular dependencies and allows access from anywhere.
class AudioConnector {
  static MyAudioHandler? _handler;

  static void setHandler(MyAudioHandler handler) {
    _handler = handler;
  }

  static MyAudioHandler? get handler => _handler;
}
