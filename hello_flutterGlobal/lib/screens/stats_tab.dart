import 'package:flutter/material.dart';
import '../models/user_stats.dart';
import '../services/stats_service.dart';
import '../widgets/charts/activity_heatmap.dart';
import '../widgets/charts/genre_pie_chart.dart';
import '../widgets/charts/weekly_bar_chart.dart';
import '../widgets/charts/mastery_circle.dart';
import '../l10n/generated/app_localizations.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({Key? key}) : super(key: key);

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab>
    with AutomaticKeepAliveClientMixin {
  final StatsService _statsService = StatsService();
  Future<UserStats?>? _statsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _statsFuture = _statsService.getUserStats();
    });
    await _statsFuture;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<UserStats?>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.noStatsData,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadStats,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data!;

        return RefreshIndicator(
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('${l10n.listeningActivity} 📅'),
                const SizedBox(height: 8),
                ActivityHeatmap(heatmapData: stats.heatmap),
                const SizedBox(height: 32),

                _buildSectionTitle('${l10n.weeklyProgress} 📊'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: WeeklyBarChart(weeklyData: stats.weekly),
                ),
                const SizedBox(height: 32),

                _buildSectionTitle('${l10n.topGenres} 🍩'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 250,
                  child: GenrePieChart(genres: stats.genres),
                ),
                const SizedBox(height: 32),

                _buildSectionTitle('${l10n.knowledgeMastery} 🎯'),
                const SizedBox(height: 16),
                MasteryCircle(mastery: stats.mastery),
                const SizedBox(height: 48),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }
}
