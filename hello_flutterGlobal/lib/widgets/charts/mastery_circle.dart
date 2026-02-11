import 'package:flutter/material.dart';
import '../../models/user_stats.dart';
import '../../l10n/generated/app_localizations.dart';

class MasteryCircle extends StatelessWidget {
  final MasteryStat mastery;

  const MasteryCircle({Key? key, required this.mastery}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double bookProgress = mastery.booksTotal > 0
        ? mastery.booksRead / mastery.booksTotal
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildCircle(
            l10n.booksRead,
            mastery.booksRead,
            mastery.booksTotal,
            bookProgress,
            Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            l10n.quizzesPassed,
            "${mastery.quizzesPassed}",
            Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildCircle(
    String title,
    int current,
    int total,
    double progress,
    Color color,
  ) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: color,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "$current",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "/ $total",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, color: color.withOpacity(0.5), size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
