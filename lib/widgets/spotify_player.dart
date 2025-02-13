import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../services/spotify_service.dart';

class SpotifyPlayer extends StatefulWidget {
  final String trackUri;
  final String trackName;
  final String artistName;
  final String albumArt;

  const SpotifyPlayer({
    super.key,
    required this.trackUri,
    required this.trackName,
    required this.artistName,
    required this.albumArt,
  });

  @override
  State<SpotifyPlayer> createState() => _SpotifyPlayerState();
}

class _SpotifyPlayerState extends State<SpotifyPlayer> {
  final _spotifyService = SpotifyService();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() => _isLoading = true);
      final isInstalled = await _spotifyService.isSpotifyInstalled();
      if (!isInstalled) {
        throw 'Spotify is not installed';
      }

      await _spotifyService.connectToSpotify();
      _subscribeToPlayerState();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _subscribeToPlayerState() {
    _spotifyService.subscribeToPlayerState().listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = !state.isPaused;
          _position = state.playbackPosition as Duration;
          _duration = state.track?.duration as Duration? ?? Duration.zero;
        });
      }
    });
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _spotifyService.pauseTrack();
      } else {
        await _spotifyService.playTrack(widget.trackUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.albumArt,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.trackName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.artistName,
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
                        color: Colors.white,
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
                    _spotifyService.seekTo(duration.inMilliseconds);
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
    _spotifyService.disconnect();
    super.dispose();
  }
}
