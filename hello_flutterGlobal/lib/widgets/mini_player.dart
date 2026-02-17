import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart';
import '../utils/api_constants.dart';
import 'player_screen.dart';
import '../services/player_preferences.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  bool _isHidden = false;
  bool _isExpanded = false; // Start collapsed (notification style)
  String? _lastMediaId;

  // For slider interaction in expanded mode
  bool _isDraggingSlider = false;
  double _dragSliderValue = 0.0;
  int _skipBackwardSeconds = 10;
  int _skipForwardSeconds = 30;

  @override
  void initState() {
    super.initState();
    _loadPlayerPreferences();
  }

  Future<void> _loadPlayerPreferences() async {
    try {
      final prefs = PlayerPreferences();
      final backward = await prefs.getSkipBackward();
      final forward = await prefs.getSkipForward();
      if (mounted) {
        setState(() {
          _skipBackwardSeconds = backward;
          _skipForwardSeconds = forward;
        });
      }
    } catch (e) {
      debugPrint('Error loading player preferences: $e');
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _expand() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
    }
  }

  void _collapse() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 65 for collapsed, 150 for expanded
    final double miniPlayerHeight = _isExpanded ? 150.0 : 65.0;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;

        // Reset visibility if media item changes (ID OR launchId)
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
                  _lastMediaId = '${mediaItem.id}|$currentLaunchId';
                });
              }
            });
          } else {
            _lastMediaId = '${mediaItem?.id}|$currentLaunchId';
          }
        }

        if (mediaItem == null || _isHidden) {
          return const SizedBox.shrink();
        }

        return Dismissible(
          key: Key('${mediaItem.id}_${mediaItem.extras?['launchId'] ?? ''}'),
          // Allow swipe left/right to dismiss
          direction: DismissDirection.horizontal,
          onDismissed: (direction) {
            setState(() {
              _isHidden = true;
            });
            audioHandler.stop();
          },
          child: StreamBuilder<PlaybackState>(
            stream: audioHandler.playbackState,
            builder: (context, playbackSnapshot) {
              final playbackState = playbackSnapshot.data;
              final playing = playbackState?.playing ?? false;

              return GestureDetector(
                // Vertical Swipes for Expand/Collapse
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    // Swiped Up -> Expand
                    _expand();
                  } else if (details.primaryVelocity! > 0) {
                    // Swiped Down -> Collapse
                    _collapse();
                  }
                },
                onTap: () {
                  // Open full player on tap
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
                  color: Colors.grey[900],
                  // Wrap in SingleChildScrollView to prevent overflow errors during animation
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      height: miniPlayerHeight,
                      child: Stack(
                        children: [
                          // Background Image (Blurred)
                          if (mediaItem.artUri != null)
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.3,
                                child: Image.network(
                                  mediaItem.artUri.toString(),
                                  headers: ApiConstants.imageHeaders,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox(),
                                ),
                              ),
                            ),

                          // Main Content
                          _isExpanded
                              ? _buildExpandedLayout(mediaItem, playing)
                              : _buildCollapsedLayout(mediaItem, playing),

                          // Toggle Button (Chevron) - Above 'Next' button
                          Positioned(
                            top: 2,
                            right: 12, // Align with the controls padding
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                iconSize: 20,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  _isExpanded
                                      ? Icons.keyboard_arrow_down
                                      : Icons.keyboard_arrow_up,
                                  color: Colors.white54,
                                ),
                                onPressed: _toggleExpanded,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 1. Collapsed Layout (Notification Style)
  Widget _buildCollapsedLayout(MediaItem mediaItem, bool playing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          // Cover Photo (Fixed small size)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            height: 44, // Slightly increased from 40
            width: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: mediaItem.artUri != null
                  ? Image.network(
                      mediaItem.artUri.toString(),
                      headers: ApiConstants.imageHeaders,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
            ),
          ),

          // Title and Author
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    right: 24.0,
                  ), // Space for toggle button
                  child: Text(
                    mediaItem.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  mediaItem.artist ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  color: Colors.white,
                  iconSize: 28,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: audioHandler.skipToPrevious,
                ),
                const SizedBox(width: 0),
                IconButton(
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  color: Colors.white,
                  iconSize: 32,
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
                const SizedBox(width: 0),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  color: Colors.white,
                  iconSize: 28,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: audioHandler.skipToNext,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Expanded Layout (Controls + Slider)
  Widget _buildExpandedLayout(MediaItem mediaItem, bool playing) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Top: Title/Artist + Artwork (Small)
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: mediaItem.artUri != null
                    ? Image.network(
                        mediaItem.artUri.toString(),
                        headers: ApiConstants.imageHeaders,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.grey[800]),
                      )
                    : Container(color: Colors.grey[800], width: 40, height: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 32.0),
                      child: Text(
                        mediaItem.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
        ),

        // Middle & Bottom: Slider and Controls wrapped in StreamBuilder for position access
        StreamBuilder<Duration>(
          stream: AudioService.position,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration = mediaItem.duration ?? Duration.zero;
            double sliderValue = position.inSeconds.toDouble();
            double maxDuration = duration.inSeconds.toDouble();
            if (sliderValue > maxDuration) sliderValue = maxDuration;
            if (maxDuration <= 0) maxDuration = 1;

            return Column(
              mainAxisSize: MainAxisSize.min, // Important for layout
              children: [
                // Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 16,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        trackHeight: 2, // Thinner track
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ), // Smaller thumb
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10,
                        ),
                      ),
                      child: Slider(
                        value:
                            (_isDraggingSlider ? _dragSliderValue : sliderValue)
                                .clamp(0.0, maxDuration),
                        min: 0.0,
                        max: maxDuration,
                        onChangeStart: (v) {
                          setState(() {
                            _isDraggingSlider = true;
                            _dragSliderValue = v;
                          });
                        },
                        onChanged: (v) {
                          setState(() {
                            _dragSliderValue = v;
                          });
                        },
                        onChangeEnd: (v) {
                          audioHandler.seek(Duration(seconds: v.toInt()));
                          setState(() {
                            _isDraggingSlider = false;
                          });
                        },
                      ),
                    ),
                  ),
                ),

                // Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10),
                        color: Colors.white,
                        iconSize: 22,
                        onPressed: () {
                          audioHandler.seek(
                            position - Duration(seconds: _skipBackwardSeconds),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        color: Colors.white,
                        iconSize: 28,
                        onPressed: audioHandler.skipToPrevious,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                          color: Colors.white,
                          iconSize: 32,
                          onPressed: () {
                            if (playing)
                              audioHandler.pause();
                            else
                              audioHandler.play();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        color: Colors.white,
                        iconSize: 28,
                        onPressed: audioHandler.skipToNext,
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_30),
                        color: Colors.white,
                        iconSize: 22,
                        onPressed: () {
                          audioHandler.seek(
                            position + Duration(seconds: _skipForwardSeconds),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
