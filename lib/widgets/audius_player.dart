import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_auth/services/audius_service.dart';

class AudiusPlayer extends StatefulWidget {
  final String trackId;
  final String title;
  final String artistName;
  final String? artwork;

  const AudiusPlayer({
    super.key,
    required this.trackId,
    required this.title,
    required this.artistName,
    this.artwork,
  });

  @override
  State<AudiusPlayer> createState() => _AudiusPlayerState();
}

class _AudiusPlayerState extends State<AudiusPlayer> {
  final _audiusService = AudiusService();
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _error;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null && _mounted) {
        setState(() => _duration = duration);
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (_mounted) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.playerStateStream.listen((playerState) {
      if (_mounted) {
        setState(() {
          _isPlaying = playerState.playing;
        });
      }
    });
  }

  Future<void> _initializePlayer() async {
    if (!_mounted) return;

    setState(() => _isLoading = true);
    try {
      final streamUrl = await _audiusService.getStreamUrl(widget.trackId);
      await _audioPlayer.setUrl(streamUrl);
      if (_mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load track: $e';
        });
      }
    }
  }

  void _togglePlayPause() async {
    if (_error != null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      if (_mounted) {
        setState(() => _error = 'Playback error: $e');
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _mounted = false;
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (widget.artwork != null && widget.artwork!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.artwork!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white54,
                          size: 30,
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white54,
                    size: 30,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
                  _isLoading
                      ? Icons.hourglass_empty
                      : (_isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled),
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: _isLoading ? null : _togglePlayPause,
              ),
            ],
          ),
          if (!_isLoading && _error == null) ...[
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                trackHeight: 2.0,
              ),
              child: Slider(
                value: _position.inSeconds.toDouble(),
                max: _duration.inSeconds.toDouble(),
                onChanged: (value) {
                  _audioPlayer.seek(Duration(seconds: value.toInt()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
