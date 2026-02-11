import 'package:flutter/material.dart';
import '../models/user_stats.dart';
import '../services/stats_service.dart';
import '../widgets/charts/activity_heatmap.dart';
import '../widgets/charts/genre_pie_chart.dart';
import '../widgets/charts/weekly_bar_chart.dart';
import '../widgets/charts/mastery_circle.dart';
import '../l10n/generated/app_localizations.dart';

class StatsTab extends StatefulWidget {
  final UserStats? chartStats;
  final Future<void> Function()? onRefresh;

  const StatsTab({Key? key, this.chartStats, this.onRefresh}) : super(key: key);

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab>
    with AutomaticKeepAliveClientMixin {
  final StatsService _statsService = StatsService();
  UserStats? _stats;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.chartStats != null) {
      _stats = widget.chartStats;
    } else {
      _loadStatsFallback();
    }
  }

  @override
  void didUpdateWidget(covariant StatsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chartStats != null &&
        widget.chartStats != oldWidget.chartStats) {
      setState(() => _stats = widget.chartStats);
    }
  }

  /// Fallback: fetch stats independently if not provided by parent
  Future<void> _loadStatsFallback() async {
    setState(() => _isLoading = true);
    final result = await _statsService.getUserStats();
    if (mounted) {
      setState(() {
        _stats = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    } else {
      await _loadStatsFallback();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading && _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats == null) {
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
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final stats = _stats!;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
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
            SizedBox(height: 250, child: GenrePieChart(genres: stats.genres)),
            const SizedBox(height: 32),

            _buildSectionTitle('${l10n.knowledgeMastery} 🎯'),
            const SizedBox(height: 16),
            MasteryCircle(mastery: stats.mastery),
            const SizedBox(height: 48),
          ],
        ),
      ),
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
