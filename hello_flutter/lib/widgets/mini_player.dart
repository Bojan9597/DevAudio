import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart';
import 'player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final miniPlayerHeight = screenHeight * 0.15; // 15% of screen height

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
              child: Stack(
                children: [
                  // Background image with blur
                  if (mediaItem.artUri != null)
                    Container(
                      height: miniPlayerHeight,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(mediaItem.artUri.toString()),
                          fit: BoxFit.cover,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Title and Artist Row
                        Row(
                          children: [
                            // Album Art Thumbnail
                            if (mediaItem.artUri != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  mediaItem.artUri.toString(),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
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
                          ],
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
                                size: 24,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
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
                                size: 28,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
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
                                size: 48,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
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
                                size: 28,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
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
                                size: 24,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
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
                ],
              ),
            );
          },
        );
      },
    );
  }
}
