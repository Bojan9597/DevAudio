import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user_stats.dart';
import '../../utils/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

class WeeklyBarChart extends StatelessWidget {
  final List<WeeklyStat> weeklyData;

  const WeeklyBarChart({Key? key, required this.weeklyData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty) {
      return const Center(
        child: Text(
          "No activity this week",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    // Find max Y for scaling
    double maxY = 0;
    for (var stat in weeklyData) {
      if (stat.minutes.toDouble() > maxY) maxY = stat.minutes.toDouble();
    }
    maxY = (maxY * 1.2).ceilToDouble(); // Add buffer
    if (maxY < 60) maxY = 60; // Min chart height

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.cardBackground,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()} ${l10n.minutes}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= weeklyData.length)
                  return const SizedBox();

                final dateStr = weeklyData[index].date;
                final dayName = _getDayName(dateStr);

                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    dayName,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 4).clamp(10, double.infinity),
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: weeklyData.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: stat.minutes.toDouble(),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 14,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ],
          );
        }).toList(),
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutBack,
    );
  }

  String _getDayName(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } catch (e) {
      return '';
    }
  }
}
