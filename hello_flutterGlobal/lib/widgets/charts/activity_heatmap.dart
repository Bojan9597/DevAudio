import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/generated/app_localizations.dart';

class ActivityHeatmap extends StatefulWidget {
  final Map<String, int> heatmapData;

  const ActivityHeatmap({Key? key, required this.heatmapData})
    : super(key: key);

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
      setState(() {
        _currentMonth = nextMonth;
      });
    }
  }

  bool get _canGoNext {
    final now = DateTime.now();
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    return nextMonth.isBefore(DateTime(now.year, now.month + 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    // First day of the current month view
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // Last day of the current month view
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;

    // Weekday of the first day (0=Sun, 6=Sat using % 7 from DateTime.monday=1)
    final firstWeekday = firstDay.weekday % 7; // 0=Sun

    // Number of weeks needed (rows of days, cols of weeks)
    final totalSlots = firstWeekday + daysInMonth;
    final weeksCount = (totalSlots / 7).ceil();

    // Day labels
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month navigation header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
              onPressed: _previousMonth,
              splashRadius: 20,
            ),
            Text(
              DateFormat('MMMM yyyy').format(_currentMonth),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: _canGoNext ? Colors.white70 : Colors.white24,
              ),
              onPressed: _canGoNext ? _nextMonth : null,
              splashRadius: 20,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Day-of-week header
        Row(
          children: dayLabels.map((label) {
            return Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),

        // Calendar grid
        ...List.generate(weeksCount, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: List.generate(7, (dayIndex) {
                final slotIndex = weekIndex * 7 + dayIndex;
                final dayNum = slotIndex - firstWeekday + 1;

                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 28));
                }

                final date = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  dayNum,
                );

                // Don't show future dates
                if (date.isAfter(now)) {
                  return Expanded(
                    child: Container(
                      height: 28,
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }

                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                final minutes = widget.heatmapData[dateStr] ?? 0;

                return Expanded(
                  child: Tooltip(
                    message:
                        '${DateFormat('MMM d').format(date)}: $minutes ${l10n.minutes}',
                    child: Container(
                      height: 28,
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: _getColor(minutes),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            color: minutes > 0
                                ? Colors.white.withOpacity(0.9)
                                : Colors.white38,
                            fontSize: 10,
                            fontWeight: minutes > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),

        const SizedBox(height: 12),
        // Legend
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
