import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MemeMedia extends StatefulWidget {
  final String url;
  final bool isVideo;

  const MemeMedia({
    Key? key,
    required this.url,
    required this.isVideo,
  }) : super(key: key);

  @override
  State<MemeMedia> createState() => _MemeMediaState();
}

class _MemeMediaState extends State<MemeMedia> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.network(widget.url);
    await _videoController!.initialize();
    setState(() {});

    _videoController!.addListener(() {
      if (mounted) {
        setState(() {
          _isPlaying = _videoController!.value.isPlaying;
        });
      }
    });
  }

  void _togglePlay() {
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {
      _isPlaying = _videoController!.value.isPlaying;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isVideo) {
      if (_videoController == null || !_videoController!.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
          ),
        );
      }

      return GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            if (_showControls)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: _togglePlay,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text(
                            _formatDuration(_videoController!.value.position),
                            style: const TextStyle(color: Colors.white),
                          ),
                          Expanded(
                            child: Slider(
                              value: _videoController!.value.position.inSeconds
                                  .toDouble(),
                              min: 0.0,
                              max: _videoController!.value.duration.inSeconds
                                  .toDouble(),
                              activeColor: Colors.pink,
                              inactiveColor: Colors.white.withOpacity(0.3),
                              onChanged: (value) {
                                _videoController!
                                    .seekTo(Duration(seconds: value.toInt()));
                              },
                            ),
                          ),
                          Text(
                            _formatDuration(_videoController!.value.duration),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    } else {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[900],
            child: Icon(
              Icons.error_outline,
              color: Colors.white.withOpacity(0.5),
              size: 32,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[900],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
