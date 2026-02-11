import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/generated/app_localizations.dart';

class ActivityHeatmap extends StatelessWidget {
  final Map<String, int> heatmapData;

  const ActivityHeatmap({Key? key, required this.heatmapData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    // Show last 26 weeks (half year) to fit screen better without too much scroll
    final startDate = now.subtract(const Duration(days: 182));

    // Align to start of week (Sunday)
    final alignedStartDate = startDate.subtract(
      Duration(days: startDate.weekday % 7),
    );
    final dayCount = now.difference(alignedStartDate).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 130, // Adjust based on box size
          child: Column(
            children: [
              // Month labels
              SizedBox(
                height: 20,
                child: _buildMonthLabels(alignedStartDate, dayCount),
              ),
              const SizedBox(height: 4),
              // Heatmap grid
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: (dayCount / 7).ceil(),
                  itemBuilder: (context, weekIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Column(
                        children: List.generate(7, (dayIndex) {
                          final currentDayIndex = weekIndex * 7 + dayIndex;
                          if (currentDayIndex >= dayCount) {
                            return const SizedBox(width: 12, height: 12);
                          }

                          final date = alignedStartDate.add(
                            Duration(days: currentDayIndex),
                          );
                          if (date.isAfter(now)) {
                            return const SizedBox(width: 12, height: 12);
                          }

                          final dateStr = DateFormat('yyyy-MM-dd').format(date);
                          final minutes = heatmapData[dateStr] ?? 0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Tooltip(
                              message:
                                  '${DateFormat('MMM d, yyyy').format(date)}: $minutes ${l10n.minutes}',
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getColor(minutes),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${l10n.less} ',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            _buildLegendBox(0),
            _buildLegendBox(15),
            _buildLegendBox(30),
            _buildLegendBox(60),
            Text(
              ' ${l10n.more}',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthLabels(DateTime startDate, int dayCount) {
    List<Widget> labels = [];
    int lastMonth = -1;

    for (int i = 0; i < dayCount; i += 7) {
      final date = startDate.add(Duration(days: i));
      if (date.month != lastMonth) {
        labels.add(
          SizedBox(
            width: 15 * 4, // Roughly 4 weeks
            child: Text(
              DateFormat('MMM').format(date),
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
        );
        lastMonth = date.month;
      }
    }

    return Row(children: labels);
  }

  Widget _buildLegendBox(int value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _getColor(value),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getColor(int minutes) {
    if (minutes == 0) return Colors.white10;
    if (minutes < 15) return Colors.green.withOpacity(0.3);
    if (minutes < 30) return Colors.green.withOpacity(0.5);
    if (minutes < 60) return Colors.green.withOpacity(0.8);
    return Colors.green;
  }
}
