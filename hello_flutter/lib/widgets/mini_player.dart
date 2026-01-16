import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart';
import 'player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;

        // Don't show mini player if no media is loaded
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<PlaybackState>(
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
                      uniqueAudioId: audioHandler.currentUniqueAudioId,
                      playlist: audioHandler.currentPlaylist,
                      initialIndex: audioHandler.currentIndex,
                    ),
                  );
                }
              },
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Album Art
                    if (mediaItem.artUri != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            mediaItem.artUri.toString(),
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 54,
                                height: 54,
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white54,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // Title and Artist (clickable area)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mediaItem.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mediaItem.artist ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Controls Column
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Top row: Previous, Play/Pause, Next
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Previous Track
                            IconButton(
                              icon: const Icon(Icons.skip_previous, size: 24),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                // Navigate to previous track if in playlist
                                if (audioHandler.currentPlaylist != null &&
                                    audioHandler.currentIndex > 0) {
                                  // TODO: Implement previous track navigation
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Previous track - coming soon',
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 8),

                            // Play/Pause
                            IconButton(
                              icon: Icon(
                                playing ? Icons.pause : Icons.play_arrow,
                                size: 32,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                if (playing) {
                                  audioHandler.pause();
                                } else {
                                  audioHandler.play();
                                }
                              },
                            ),
                            const SizedBox(width: 8),

                            // Next Track
                            IconButton(
                              icon: const Icon(Icons.skip_next, size: 24),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                // Navigate to next track if in playlist
                                if (audioHandler.currentPlaylist != null &&
                                    audioHandler.currentIndex <
                                        audioHandler.currentPlaylist!.length -
                                            1) {
                                  // TODO: Implement next track navigation
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Next track - coming soon'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),

                        // Bottom row: Skip Back, Stop, Skip Forward
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Skip backward 10s
                            IconButton(
                              icon: const Icon(Icons.replay_10, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
                            const SizedBox(width: 12),

                            // Stop
                            IconButton(
                              icon: const Icon(Icons.stop, size: 22),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                audioHandler.stop();
                              },
                            ),
                            const SizedBox(width: 12),

                            // Skip forward 30s
                            IconButton(
                              icon: const Icon(Icons.forward_30, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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

                    const SizedBox(width: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
