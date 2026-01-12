import 'package:flutter/material.dart';
import '../models/book.dart';
import '../widgets/player_screen.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaylistScreen extends StatefulWidget {
  final Book book;

  const PlaylistScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<dynamic> _tracks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/playlist/${widget.book.id}',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _tracks = data;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load playlist');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _playTrack(Map<String, dynamic> track) async {
    // Construct a temporary Book object for the Player

    // 1. Ensure Absolute URL
    String trackUrl = track['file_path'];
    if (!trackUrl.startsWith('http')) {
      // If relative, prepend base URL.
      // Note: ApiConstants.baseUrl might or might not have trailing slash.
      // Usually it does. trackUrl usually starts with 'static/'.
      trackUrl = '${ApiConstants.baseUrl}$trackUrl';
    }

    final trackTitle = track['title'];

    // 2. Use Track ID as Book ID to prevent collision with main book's progress/downloads
    // We use a prefix or just the track ID string.
    final String uniqueTrackId = "track_${track['id']}";

    final singleTrackBook = Book(
      id: widget
          .book
          .id, // Use REAL Book ID for backend ownership/progress checks
      title: trackTitle,
      author: widget.book.author,
      audioUrl: trackUrl,
      coverUrl: widget.book.coverUrl,
      categoryId: widget.book.categoryId,
      subcategoryIds: const [], // Default empty or pass from widget.book
      postedBy: widget.book.postedBy,
      description: widget.book.description,
      price: widget.book.price,
      postedByUserId: widget.book.postedByUserId,
      isPlaylist: false, // It's a single track context
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerScreen(
        book: singleTrackBook,
        uniqueAudioId:
            uniqueTrackId, // Pass unique ID for local storage/playback
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : _tracks.isEmpty
          ? const Center(child: Text('No tracks found'))
          : ListView.builder(
              itemCount: _tracks.length,
              itemBuilder: (context, index) {
                final track = _tracks[index];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(track['title'] ?? 'Track ${index + 1}'),
                  subtitle: Text(
                    "Duration: ${_formatDuration(track['duration_seconds'] ?? 0)}",
                  ),
                  onTap: () => _playTrack(track),
                );
              },
            ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return "0:00";
    final d = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final sec = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${twoDigits(d.inHours)}:' : ''}$minutes:$sec";
  }
}
