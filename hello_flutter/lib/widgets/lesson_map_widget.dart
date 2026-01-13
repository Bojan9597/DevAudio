import 'dart:math';
import 'package:flutter/material.dart';

class LessonMapWidget extends StatelessWidget {
  final List<dynamic> tracks;
  final Function(int) onTrackTap;
  final ScrollController? scrollController;
  final bool hasQuiz;
  final bool isBookCompleted;
  final bool isQuizPassed;
  final VoidCallback? onQuizTap;

  const LessonMapWidget({
    Key? key,
    required this.tracks,
    required this.onTrackTap,
    this.scrollController,
    this.hasQuiz = false,
    this.isBookCompleted = false,
    this.isQuizPassed = false,
    this.onQuizTap,
  }) : super(key: key);

  static const double itemHeight = 160.0;
  static const double padding = 40.0;

  @override
  Widget build(BuildContext context) {
    // Generate positions based on width
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int totalItems = tracks.length + (hasQuiz ? 1 : 0);

        final totalHeight = max(
          totalItems * itemHeight + padding * 2,
          constraints.maxHeight,
        ); // Ensure at least screen height

        // Pre-calculate positions to ensure line matches icons
        final List<Offset> positions = [];
        final random = Random(42); // Fixed seed for consistency

        final int itemCount = tracks.length + (hasQuiz ? 1 : 0);

        for (int i = 0; i < itemCount; i++) {
          final double y = padding + i * itemHeight;
          // Sine wave pattern
          // Center is width / 2
          // Amplitude is (width - padding) / 2

          final double center = width / 2;
          final double amplitude = min(width / 3, 120.0);

          // Use sine + consistent random offset
          // wiggle: -1 to 1
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

                  return Positioned(
                    left: pos.dx - 40, // Center 80px wide widget
                    top: pos.dy - 40,
                    child: _LessonNode(
                      title: title,
                      isCompleted: isCompleted,
                      onTap: () => onTrackTap(index),
                    ),
                  );
                }),

                // 3. Draw Quiz Node (Last item if hasQuiz)
                if (hasQuiz && positions.isNotEmpty)
                  Positioned(
                    left: positions.last.dx - 40,
                    top: positions.last.dy - 40,
                    child: _LessonNode(
                      title: "Final Quiz",
                      // For Quiz, isCompleted means "Passed" (>50%)
                      isCompleted: isQuizPassed,
                      isQuiz: true,
                      isLocked: !isBookCompleted,
                      onTap: () {
                        if (isBookCompleted && onQuizTap != null) {
                          onQuizTap!();
                        } else {
                          // Show locked message
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

      // Curvy connection
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
  final bool isCompleted;
  final VoidCallback onTap;
  final bool isQuiz;
  final bool isLocked;

  const _LessonNode({
    required this.title,
    required this.isCompleted,
    required this.onTap,
    this.isQuiz = false,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54, // Backing for contrast
                boxShadow: [
                  BoxShadow(
                    color: (isCompleted || (isQuiz && !isLocked))
                        ? Colors.orange.withOpacity(0.4)
                        : Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isQuiz
                    ? (isLocked ? Icons.lock : Icons.quiz)
                    : Icons.star_rounded,
                size: 50,
                // Color Logic:
                // Quiz: Passed (isCompleted) -> Amber. Else (regardless of Lock) -> Grey.
                // Star: Completed -> Amber. Else -> Grey.
                color: isQuiz
                    ? (isCompleted ? Colors.amber : Colors.grey)
                    : (isCompleted ? Colors.amber : Colors.grey.shade700),
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
    return raw;
  }
}
