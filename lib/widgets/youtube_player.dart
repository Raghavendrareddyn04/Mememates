import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../services/youtube_service.dart';

class YouTubePlayer extends StatefulWidget {
  final String videoId;
  final String title;
  final String author;
  final String thumbnailUrl;
  final String audioStreamUrl;

  const YouTubePlayer({
    super.key,
    required this.videoId,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.audioStreamUrl,
  });

  @override
  State<YouTubePlayer> createState() => _YouTubePlayerState();
}

class _YouTubePlayerState extends State<YouTubePlayer> {
  final _audioPlayer = AudioPlayer();
  final _youtubeService = YouTubeService();
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _audioUrl;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() => _isLoading = true);

      // Get video details if we don't have an audio URL
      if (widget.audioStreamUrl.isEmpty) {
        final videoDetails =
            await _youtubeService.getVideoDetails(widget.videoId);
        _audioUrl = videoDetails['audioStreamUrl'];
      } else {
        _audioUrl = widget.audioStreamUrl;
      }

      if (_audioUrl == null || _audioUrl!.isEmpty) {
        throw 'No audio stream available';
      }

      // Initialize audio player with the stream URL
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(_audioUrl!)),
      );

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });

      _audioPlayer.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() => _duration = duration);
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() => _isPlaying = state.playing);
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing player: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing player: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.thumbnailUrl.isNotEmpty
                            ? widget.thumbnailUrl
                            : 'https://img.youtube.com/vi/${widget.videoId}/hqdefault.jpg',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.withOpacity(0.3),
                          child:
                              const Icon(Icons.music_note, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.author,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.pink,
                        size: 48,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ProgressBar(
                  progress: _position,
                  total: _duration,
                  onSeek: (duration) {
                    _audioPlayer.seek(duration);
                  },
                  baseBarColor: Colors.white.withOpacity(0.2),
                  progressBarColor: Colors.pink,
                  bufferedBarColor: Colors.pink.withOpacity(0.3),
                  thumbColor: Colors.pink,
                  timeLabelTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
