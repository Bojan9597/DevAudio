import 'package:flutter/material.dart';
import '../services/player_preferences.dart';
import '../l10n/generated/app_localizations.dart';
import '../main.dart'; // Access to audioHandler

class PlayerSettingsScreen extends StatefulWidget {
  const PlayerSettingsScreen({super.key});

  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends State<PlayerSettingsScreen> {
  final _prefs = PlayerPreferences();
  bool _isLoading = true;

  int _skipBackward = PlayerPreferences.defaultSkipBackward;
  int _skipForward = PlayerPreferences.defaultSkipForward;
  double _defaultSpeed = PlayerPreferences.defaultSpeed;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final back = await _prefs.getSkipBackward();
    final forward = await _prefs.getSkipForward();
    final speed = await _prefs.getDefaultSpeed();

    if (mounted) {
      setState(() {
        _skipBackward = back;
        _skipForward = forward;
        _defaultSpeed = speed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settings,
        ), // Reusing "Settings" or similar, context implies Player
      ),
      body: ListView(
        children: [
          _buildSectionHeader(
            context,
            "Skip Intervals",
          ), // TODO: Localize if key exists or add new

          ListTile(
            title: Text("Skip Backward"),
            subtitle: Text("${_skipBackward}s"),
            trailing: DropdownButton<int>(
              value: _skipBackward,
              items: [5, 10, 15, 30].map((e) {
                return DropdownMenuItem(value: e, child: Text("${e}s"));
              }).toList(),
              onChanged: (val) async {
                if (val != null) {
                  await _prefs.setSkipBackward(val);
                  setState(() => _skipBackward = val);
                }
              },
            ),
          ),

          ListTile(
            title: Text("Skip Forward"),
            subtitle: Text("${_skipForward}s"),
            trailing: DropdownButton<int>(
              value: _skipForward,
              items: [10, 30, 45, 60].map((e) {
                return DropdownMenuItem(value: e, child: Text("${e}s"));
              }).toList(),
              onChanged: (val) async {
                if (val != null) {
                  await _prefs.setSkipForward(val);
                  setState(() => _skipForward = val);
                }
              },
            ),
          ),

          const Divider(),
          _buildSectionHeader(context, "Playback Speed"),

          ListTile(
            title: Text("Default Speed"),
            subtitle: Text("${_defaultSpeed}x"),
          ),
          Slider(
            value: _defaultSpeed,
            min: 0.5,
            max: 3.0,
            divisions: 10, // (3.0 - 0.5) / 0.25 = 10 steps
            label: "${_defaultSpeed}x",
            onChanged: (val) async {
              // Snap to nearest 0.25
              // slider with divisions does this auto, but let's ensure clean double
              await _prefs.setDefaultSpeed(val);
              setState(() => _defaultSpeed = val);
              // Update active player immediately
              await audioHandler.setSpeed(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
