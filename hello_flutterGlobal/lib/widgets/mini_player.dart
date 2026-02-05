import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart';
import '../utils/api_constants.dart';
import 'player_screen.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  bool _isHidden = false;
  String? _lastMediaId;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final miniPlayerHeight = screenHeight * 0.16; // 16% of screen height

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;

        // Reset visibility if media item changes
        if (mediaItem?.id != _lastMediaId) {
          if (mounted && _isHidden && mediaItem != null) {
            // Use addPostFrameCallback to avoid setState during build if needed,
            // but since we are in builder, simple assignment or deferred set is safe?
            // Actually, modifying state during build is bad.
            // But _isHidden is local state.
            // Safe pattern:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isHidden = false;
                  _lastMediaId = mediaItem?.id;
                });
              }
            });
          } else {
            // First load or already visible
            _lastMediaId = mediaItem?.id;
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
                child: Container(
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
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: 8,
                          bottom: 4,
                        ),
                        child: Column(
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
                                      value: progress,
                                      onChanged: (value) {
                                        final newPosition = Duration(
                                          milliseconds:
                                              (value * duration.inMilliseconds)
                                                  .toInt(),
                                        );
                                        audioHandler.seek(newPosition);
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
                                // Skip back 10s
                                IconButton(
                                  icon: const Icon(
                                    Icons.replay_10,
                                    color: Colors.white,
                                    size: 20,
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
                                        const Duration(seconds: 10);
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

                                // Skip forward 30s
                                IconButton(
                                  icon: const Icon(
                                    Icons.forward_30,
                                    color: Colors.white,
                                    size: 20,
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
                                        const Duration(seconds: 30);
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
                        ),
                      ),

                      // Close Button (Small X on top right)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isHidden = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 16,
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
}
