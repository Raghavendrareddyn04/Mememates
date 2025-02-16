import 'package:flutter/material.dart';
import '../services/youtube_service.dart';

class YouTubeTrackPicker extends StatefulWidget {
  final Function(YouTubeTrack) onTrackSelected;

  const YouTubeTrackPicker({
    super.key,
    required this.onTrackSelected,
  });

  @override
  State<YouTubeTrackPicker> createState() => _YouTubeTrackPickerState();
}

class _YouTubeTrackPickerState extends State<YouTubeTrackPicker> {
  final _youtubeService = YouTubeService();
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = true;
  String _error = '';
  bool _showSearchField = false;

  @override
  void initState() {
    super.initState();
    _loadTrendingMusic();
  }

  Future<void> _loadTrendingMusic() async {
    try {
      setState(() => _isLoading = true);
      final results = await _youtubeService.getTrendingMusic();
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading trending music: $e';
      });
    }
  }

  Future<void> _searchVideos(String query) async {
    if (query.isEmpty) {
      _loadTrendingMusic();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final results = await _youtubeService.searchVideos(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error searching videos: $e';
        _searchResults = [];
      });
    }
  }

  Future<void> _selectVideo(dynamic video) async {
    try {
      setState(() => _isLoading = true);
      final videoDetails =
          await _youtubeService.getVideoDetails(video.id.value);
      final track = YouTubeTrack.fromVideo(videoDetails);
      widget.onTrackSelected(track);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_showSearchField)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _showSearchField = false;
                          _searchController.clear();
                          _loadTrendingMusic();
                        });
                      },
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _showSearchField ? 'Search Songs' : 'Featured Songs',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!_showSearchField)
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        setState(() => _showSearchField = true);
                      },
                    ),
                ],
              ),
              if (_showSearchField) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search for a song...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon:
                                const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              _loadTrendingMusic();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: _searchVideos,
                  onChanged: (value) {
                    if (value.length >= 3) {
                      _searchVideos(value);
                    } else if (value.isEmpty) {
                      _loadTrendingMusic();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        if (_isLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            ),
          )
        else if (_error.isNotEmpty)
          Expanded(
            child: Center(
              child: Text(
                _error,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No results found for "${_searchController.text}"',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final video = _searchResults[index];
                return Card(
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        video.thumbnails.highResUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.withOpacity(0.3),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      video.author,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatDuration(video.duration ?? Duration.zero),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => _selectVideo(video),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _youtubeService.dispose();
    super.dispose();
  }
}
