import 'dart:math';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../l10n/generated/app_localizations.dart';

class LessonMapWidget extends StatelessWidget {
  final List<dynamic> tracks;
  final Function(int) onTrackTap;
  final ScrollController? scrollController;
  final bool hasQuiz;
  final bool isBookCompleted;
  final bool isQuizPassed;
  final VoidCallback? onQuizTap;

  // Track Quizzes: Map<String, dynamic> where key is trackId
  // Value: {'has_quiz': bool, 'is_passed': bool}
  final Map<String, dynamic> trackQuizzes;
  final Function(int)? onTrackQuizTap;
  final bool isOwner;

  // Download button
  final String? bookTitle;
  final VoidCallback? onDownloadTap;
  final bool isDownloading;

  const LessonMapWidget({
    Key? key,
    required this.tracks,
    required this.onTrackTap,
    this.scrollController,
    this.hasQuiz = false,
    this.isBookCompleted = false,
    this.isQuizPassed = false,
    this.onQuizTap,
    this.trackQuizzes = const {},
    this.onTrackQuizTap,
    this.isOwner = false,
    this.bookTitle,
    this.onDownloadTap,
    this.isDownloading = false,
  }) : super(key: key);

  static const double itemHeight = 160.0;
  static const double padding = 40.0;

  @override
  Widget build(BuildContext context) {
    // Find the first non-completed track index (the "next up" to listen)
    final int nextUpIndex = tracks.indexWhere(
      (t) => t['is_completed'] != true,
    );

    return Column(
      children: [
        // Header with title and download button
        if (bookTitle != null || onDownloadTap != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (bookTitle != null)
                  Expanded(
                    flex: 7,
                    child: Text(
                      bookTitle!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (onDownloadTap != null)
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: TextButton.icon(
                          onPressed: isDownloading ? null : onDownloadTap,
                          icon: isDownloading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.download,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          label: Text(
                            isDownloading
                                ? (AppLocalizations.of(context)?.downloading ??
                                      'Downloading...')
                                : (AppLocalizations.of(context)?.download ??
                                      'Download'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black45,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        // Map content
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final int totalItems = tracks.length + (hasQuiz ? 1 : 0);

              final totalHeight = max(
                totalItems * itemHeight + padding * 2,
                constraints.maxHeight,
              );

              final List<Offset> positions = [];
              final random = Random(42);

              final int itemCount = tracks.length + (hasQuiz ? 1 : 0);

              for (int i = 0; i < itemCount; i++) {
                final double y = padding + i * itemHeight;
                // 10% padding from left, 30% padding from right
                final double leftPadding = width * 0.1;
                final double rightPadding = width * 0.3;
                final double usableWidth = width - leftPadding - rightPadding;
                final double center = leftPadding + (usableWidth / 2);
                final double amplitude = min(usableWidth / 2, 100.0);
                final double wiggle = (random.nextDouble() * 2 - 1) * 0.3;
                final double sine = sin(i * 0.8 + wiggle);
                final double x = center + (sine * amplitude);
                positions.add(Offset(x, y));
              }

              return SingleChildScrollView(
                controller: scrollController,
                child: SizedBox(
                  height: totalHeight,
                  child: Stack(
                    children: [
                      // 1. Draw Path
                      CustomPaint(
                        size: Size(width, totalHeight),
                        painter: _MapPathPainter(positions: positions),
                      ),
                      // 2. Draw Stars (Interactive)
                      ...List.generate(tracks.length, (index) {
                        final pos = positions[index];
                        final track = tracks[index];
                        final isCompleted = track['is_completed'] == true;
                        final title = track['title'] ?? 'Lesson ${index + 1}';

                        // Check Track Quiz Status
                        final trackId = track['id'].toString();
                        final quizData = trackQuizzes[trackId];
                        final bool hasTrackQuiz =
                            quizData != null && quizData['has_quiz'] == true;
                        final bool isTrackQuizPassed =
                            quizData != null && quizData['is_passed'] == true;
                        // Locked if track is not completed
                        final bool isTrackQuizLocked = !isCompleted;

                        return Positioned(
                          left: pos.dx - 70, // Center 140px wide widget
                          top:
                              pos.dy -
                              40, // Center 80px tall icon (ignoring text)
                          child: _LessonNode(
                            title: title,
                            index: index, // Pass index for image selection
                            isCompleted: isCompleted,
                            isNextUp: index == nextUpIndex,
                            onTap: () => onTrackTap(index),
                            // Track Quiz Args
                            hasTrackQuiz: hasTrackQuiz,
                            isTrackQuizLocked: isTrackQuizLocked,
                            isTrackQuizPassed: isTrackQuizPassed,
                            isOwner: isOwner,
                            onTrackQuizTap: () {
                              // Owner can always tap to Add/Edit
                              if (isOwner && onTrackQuizTap != null) {
                                onTrackQuizTap!(track['id']);
                                return;
                              }

                              if (onTrackQuizTap != null && hasTrackQuiz) {
                                if (isTrackQuizLocked) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Finish this lesson first to unlock the quiz!",
                                      ),
                                    ),
                                  );
                                } else {
                                  onTrackQuizTap!(track['id']);
                                }
                              }
                            },
                          ),
                        );
                      }),

                      // 3. Draw Main Quiz Node
                      if (hasQuiz && positions.isNotEmpty)
                        Positioned(
                          left: positions.last.dx - 70,
                          top: positions.last.dy - 40,
                          child: _LessonNode(
                            title: "Final Quiz",
                            index:
                                0, // Default or specific image for final quiz?
                            isCompleted: isQuizPassed,
                            isQuiz: true,
                            isLocked: !isBookCompleted,
                            onTap: () {
                              // Owner can edit final quiz via AppBar usually,
                              // but we could allow tap here too?
                              // For now keep standard behavior for final quiz.
                              if (isOwner && onQuizTap != null) {
                                onQuizTap!();
                                return;
                              }

                              if (isBookCompleted && onQuizTap != null) {
                                onQuizTap!();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Finish all chapters to unlock the quiz!",
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MapPathPainter extends CustomPainter {
  final List<Offset> positions;

  _MapPathPainter({required this.positions});

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.isEmpty) return;

    final paint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(positions[0].dx, positions[0].dy);

    for (int i = 0; i < positions.length - 1; i++) {
      final p1 = positions[i];
      final p2 = positions[i + 1];

      final controlPoint1 = Offset(p1.dx, (p1.dy + p2.dy) / 2);
      final controlPoint2 = Offset(p2.dx, (p1.dy + p2.dy) / 2);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LessonNode extends StatelessWidget {
  final String title;
  final int index;
  final bool isCompleted;
  final bool isNextUp;
  final VoidCallback onTap;

  final bool isQuiz;
  final bool isLocked;

  // Track Quiz Props
  final bool hasTrackQuiz;
  final bool isTrackQuizLocked;
  final bool isTrackQuizPassed;
  final VoidCallback? onTrackQuizTap;
  final bool isOwner;

  const _LessonNode({
    required this.title,
    required this.index,
    required this.isCompleted,
    this.isNextUp = false,
    required this.onTap,
    this.isQuiz = false,
    this.isLocked = false,
    this.hasTrackQuiz = false,
    this.isTrackQuizLocked = false,
    this.isTrackQuizPassed = false,
    this.onTrackQuizTap,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    // If it's a MAIN quiz, render simple circle.
    // If it's a TRACK, render Row of [Star, Quiz] (if quiz exists).

    if (isQuiz) {
      return _buildMainNode();
    }

    // Determine if we show a side node
    bool showSideNode = hasTrackQuiz || isOwner;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Star Node
        _buildMainNode(),

        // Optional Quiz Node to the right
        if (showSideNode) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTrackQuizTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
                boxShadow: [
                  BoxShadow(
                    color: (isOwner || !isTrackQuizLocked)
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.black12,
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: _buildSideIcon(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSideIcon() {
    if (isOwner && !hasTrackQuiz) {
      return const Icon(Icons.add, color: Colors.white70, size: 24);
    }
    if (isOwner && hasTrackQuiz) {
      return const Icon(Icons.edit, color: Colors.amber, size: 20);
    }

    // User View
    return Icon(
      isTrackQuizLocked ? Icons.lock : Icons.quiz,
      size: 24,
      color: isTrackQuizLocked
          ? Colors.grey
          : (isTrackQuizPassed ? Colors.amber : Colors.amber.shade200),
    );
  }

  Widget _buildMainNode() {
    // Logic for the main node (Star or Big Quiz)
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container
            Container(
              width: 80,
              height: 80,
              child: isQuiz
                  ? Icon(
                      isLocked ? Icons.lock : Icons.quiz,
                      size: 50,
                      color: isCompleted ? Colors.amber : Colors.grey,
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        // Island background: 3D model only for next-up, PNG for rest
                        _IslandImage(index: index, isNextUp: isNextUp),
                        // Centered star icon
                        Icon(
                          Icons.star_rounded,
                          size: 30,
                          color: isCompleted
                              ? Colors.amber
                              : Colors.grey.shade700,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              displayTitle(title),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLocked
                    ? Colors.grey
                    : ((isCompleted || isQuiz) ? Colors.white : Colors.white70),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: const [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black,
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String displayTitle(String raw) {
    if (raw.length > 20) {
      return raw.substring(0, 18) + "...";
    }
    return raw;
  }
}

// Island image widget - uses 3D model only for next-up node, static PNG for all others
class _IslandImage extends StatelessWidget {
  final int index;
  final bool isNextUp;
  const _IslandImage({required this.index, this.isNextUp = false});

  @override
  Widget build(BuildContext context) {
    if (isNextUp) {
      // 3D rotating shield only for the next track to listen
      return SizedBox(
        width: 80,
        height: 80,
        child: ModelViewer(
          src: 'assets/models/medieval_shield.glb',
          alt: 'Medieval Shield',
          autoRotate: true,
          autoRotateDelay: 0,
          rotationPerSecond: '90deg',
          cameraControls: false,
          disableZoom: true,
          backgroundColor: Colors.transparent,
        ),
      );
    }
    // Static PNG for all other nodes (fast loading)
    return SizedBox(
      width: 80,
      height: 80,
      child: Image.asset(
        'assets/shield_background_removed.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
