import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class CompletionVideoOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const CompletionVideoOverlay({Key? key, required this.onDismiss})
    : super(key: key);

  @override
  State<CompletionVideoOverlay> createState() => _CompletionVideoOverlayState();
}

class _CompletionVideoOverlayState extends State<CompletionVideoOverlay> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Load local asset video
    _controller = VideoPlayerController.asset('assets/happy_owl.mp4')
      ..initialize()
          .then((_) {
            setState(() {
              _initialized = true;
            });
            _controller.play();
            _controller.setLooping(
              true,
            ); // Assuming loop, or we can listen for end
          })
          .catchError((error) {
            debugPrint("Error loading completion video: $error");
            // If video fails, just dismiss immediately to avoid blocking user
            widget.onDismiss();
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ); // Or empty container
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video Centered
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),

          // Close button - Top Right Safe Area
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: widget.onDismiss,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
