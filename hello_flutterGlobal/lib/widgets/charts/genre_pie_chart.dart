import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user_stats.dart';
import '../../utils/app_colors.dart';

class GenrePieChart extends StatefulWidget {
  final List<GenreStat> genres;

  const GenrePieChart({Key? key, required this.genres}) : super(key: key);

  @override
  State<GenrePieChart> createState() => _GenrePieChartState();
}

class _GenrePieChartState extends State<GenrePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.genres.isEmpty) {
      return const Center(
        child: Text(
          "No genres recorded yet",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: _showingSections(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.genres.asMap().entries.map((entry) {
              final index = entry.key;
              final genre = entry.value;
              final isTouched = index == touchedIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _Indicator(
                  color: _getGenreColor(index),
                  text: genre.name,
                  isSquare: false,
                  size: isTouched ? 14 : 10,
                  textColor: isTouched ? Colors.white : Colors.white70,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _showingSections() {
    return List.generate(widget.genres.length, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 65.0 : 55.0;
      final genre = widget.genres[i];

      return PieChartSectionData(
        color: _getGenreColor(i),
        value: genre.count.toDouble(),
        title: isTouched ? '${genre.count}' : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
        ),
      );
    });
  }

  Color _getGenreColor(int index) {
    const colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.tealAccent,
      Colors.amberAccent,
    ];
    return colors[index % colors.length];
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color textColor;

  const _Indicator({
    Key? key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 10,
    this.textColor = Colors.white70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: textColor == Colors.white
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
