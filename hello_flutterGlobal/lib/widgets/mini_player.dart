import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart';
import '../utils/api_constants.dart';
import '../services/player_preferences.dart';
import 'player_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  bool _isHidden = false;
  bool _isExpanded = true; // Start expanded by default
  String? _lastMediaId;
  bool _isDraggingSlider = false;
  double _dragSliderValue = 0.0;
  int _skipBackwardSeconds = PlayerPreferences.defaultSkipBackward;
  int _skipForwardSeconds = PlayerPreferences.defaultSkipForward;

  @override
  void initState() {
    super.initState();
    _loadPlayerPreferences();
  }

  Future<void> _loadPlayerPreferences() async {
    final prefs = PlayerPreferences();
    final backward = await prefs.getSkipBackward();
    final forward = await prefs.getSkipForward();
    if (mounted) {
      setState(() {
        _skipBackwardSeconds = backward;
        _skipForwardSeconds = forward;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final miniPlayerHeight = _isExpanded
        ? screenHeight * 0.16  // 16% when expanded
        : 70.0;                 // Fixed compact height when collapsed

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;

        // Reset visibility if media item changes (ID OR launchId)
        // Check launchId to force show even for same track
        final currentLaunchId = mediaItem?.extras?['launchId'];
        final prevLaunchId = _lastMediaId?.split('|').length == 2
            ? _lastMediaId?.split('|')[1]
            : null;

        if (mediaItem?.id != _lastMediaId?.split('|')[0] ||
            currentLaunchId != prevLaunchId) {
          if (mounted && _isHidden && mediaItem != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isHidden = false;
                  // Store composite ID to detect re-launch of same track
                  _lastMediaId = '${mediaItem.id}|$currentLaunchId';
                });
              }
            });
          } else {
            // First load or already visible
            _lastMediaId = '${mediaItem?.id}|$currentLaunchId';
          }
        }

        // Don't show mini player if no media is loaded or user hid it
        if (mediaItem == null || _isHidden) {
          return const SizedBox.shrink();
        }

        return Dismissible(
          key: Key(mediaItem.id),
          direction: DismissDirection.down,
          onDismissed: (direction) {
            setState(() {
              _isHidden = true;
            });
          },
          child: StreamBuilder<PlaybackState>(
            stream: audioHandler.playbackState,
            builder: (context, playbackSnapshot) {
              final playbackState = playbackSnapshot.data;
              final playing = playbackState?.playing ?? false;

              return GestureDetector(
                onTap: () {
                  // Reopen the full player if we have book context
                  if (audioHandler.currentBook != null) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PlayerScreen(
                        book: audioHandler.currentBook!,
                        uniqueAudioId: audioHandler.currentUniqueAudioId ?? '',
                        playlist: audioHandler.currentPlaylist,
                        initialIndex: audioHandler.currentIndex,
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: miniPlayerHeight,
                  color: Colors.grey[900], // Fallback background
                  child: Stack(
                    children: [
                      // Background image with blur
                      if (mediaItem.artUri != null)
                        Container(
                          height: miniPlayerHeight,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                mediaItem.artUri.toString(),
                                headers: ApiConstants.imageHeaders,
                              ),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {},
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.black.withOpacity(0.85),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Content overlay
                      Container(
                        height: miniPlayerHeight,
                        padding: EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: _isExpanded ? 8 : 12,
                          bottom: _isExpanded ? 4 : 12,
                        ),
                        child: _isExpanded
                            ? _buildExpandedLayout(
                                mediaItem,
                                playing,
                              )
                            : _buildCollapsedLayout(
                                mediaItem,
                                playing,
                              ),
                      ),

                      // Collapse/Expand Button (replaces close X)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Collapsed layout - compact version
  Widget _buildCollapsedLayout(MediaItem mediaItem, bool playing) {
    return Row(
      children: [
        // Album Art Thumbnail
        if (mediaItem.artUri != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              mediaItem.artUri.toString(),
              headers: ApiConstants.imageHeaders,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 46,
                  height: 46,
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white54,
                    size: 24,
                  ),
                );
              },
            ),
          ),
        const SizedBox(width: 12),

        // Title and Artist
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mediaItem.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                mediaItem.artist ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Play/Pause Button (large)
        IconButton(
          icon: Icon(
            playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: Colors.white,
            size: 44,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          onPressed: () {
            if (playing) {
              audioHandler.pause();
            } else {
              audioHandler.play();
            }
          },
        ),

        const SizedBox(width: 8),
      ],
    );
  }

  // Expanded layout - full controls
  Widget _buildExpandedLayout(MediaItem mediaItem, bool playing) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Title and Artist Row (at top)
        Row(
                              children: [
                                // Album Art Thumbnail
                                if (mediaItem.artUri != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      mediaItem.artUri.toString(),
                                      headers: ApiConstants.imageHeaders,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 40,
                                              height: 40,
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                Icons.music_note,
                                                color: Colors.white54,
                                                size: 20,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                const SizedBox(width: 10),

                                // Title and Artist
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        mediaItem.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        mediaItem.artist ?? '',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Progress Slider
                            StreamBuilder<Duration>(
                              stream: audioHandler.player.positionStream,
                              builder: (context, positionSnapshot) {
                                final position =
                                    positionSnapshot.data ?? Duration.zero;
                                final duration =
                                    audioHandler.player.duration ??
                                    Duration.zero;
                                final progress = duration.inMilliseconds > 0
                                    ? (position.inMilliseconds /
                                              duration.inMilliseconds)
                                          .clamp(0.0, 1.0)
                                    : 0.0;

                                return SizedBox(
                                  height: 20,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 5,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 10,
                                          ),
                                      activeTrackColor: Colors.amber[700],
                                      inactiveTrackColor: Colors.white
                                          .withOpacity(0.3),
                                      thumbColor: Colors.amber[700],
                                    ),
                                    child: Slider(
                                      value: _isDraggingSlider
                                          ? _dragSliderValue
                                          : progress,
                                      onChangeStart: (value) {
                                        setState(() {
                                          _isDraggingSlider = true;
                                          _dragSliderValue = value;
                                        });
                                      },
                                      onChanged: (value) {
                                        setState(() {
                                          _dragSliderValue = value;
                                        });
                                      },
                                      onChangeEnd: (value) {
                                        final newPosition = Duration(
                                          milliseconds:
                                              (value * duration.inMilliseconds)
                                                  .toInt(),
                                        );
                                        audioHandler.seek(newPosition);
                                        setState(() {
                                          _isDraggingSlider = false;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Controls Row - matching big player order
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Skip back
                                IconButton(
                                  icon: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(Icons.replay, size: 20),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 1),
                                        child: Text(
                                          '$_skipBackwardSeconds',
                                          style: const TextStyle(
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  onPressed: () async {
                                    final currentPosition =
                                        audioHandler.player.position;
                                    final newPosition =
                                        currentPosition -
                                        Duration(seconds: _skipBackwardSeconds);
                                    await audioHandler.seek(
                                      newPosition < Duration.zero
                                          ? Duration.zero
                                          : newPosition,
                                    );
                                  },
                                ),

                                // Previous Track
                                IconButton(
                                  icon: const Icon(
                                    Icons.skip_previous,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  onPressed: () async {
                                    await audioHandler.playPreviousTrack();
                                  },
                                ),

                                // Play/Pause
                                IconButton(
                                  icon: Icon(
                                    playing
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_filled,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                  onPressed: () {
                                    if (playing) {
                                      audioHandler.pause();
                                    } else {
                                      audioHandler.play();
                                    }
                                  },
                                ),

                                // Next Track
                                IconButton(
                                  icon: const Icon(
                                    Icons.skip_next,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  onPressed: () async {
                                    await audioHandler.playNextTrack();
                                  },
                                ),

                                // Skip forward
                                IconButton(
                                  icon: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.rotationY(3.14159),
                                        child: const Icon(
                                          Icons.replay,
                                          size: 20,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 1),
                                        child: Text(
                                          '$_skipForwardSeconds',
                                          style: const TextStyle(
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  onPressed: () async {
                                    final currentPosition =
                                        audioHandler.player.position;
                                    final duration =
                                        audioHandler.player.duration ??
                                        Duration.zero;
                                    final newPosition =
                                        currentPosition +
                                        Duration(seconds: _skipForwardSeconds);
                                    await audioHandler.seek(
                                      newPosition > duration
                                          ? duration
                                          : newPosition,
                                    );
                                  },
                                ),
                              ],
                            ),
      ],
    );
  }
}
