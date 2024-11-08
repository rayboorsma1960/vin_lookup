import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final bool isLocalFile;

  const VideoPlayerScreen({
    Key? key,
    required this.videoPath,
    this.isLocalFile = false,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.isLocalFile) {
      _controller = VideoPlayerController.file(File(widget.videoPath));
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
    }

    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing video: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crash Test Video'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _controller.pause();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 60.0,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}