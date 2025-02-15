import 'package:flutter/material.dart';
import '../services/spotify_service.dart';

class SpotifyTrackPicker extends StatefulWidget {
  final Function(SpotifyTrack) onTrackSelected;

  const SpotifyTrackPicker({
    super.key,
    required this.onTrackSelected,
  });

  @override
  State<SpotifyTrackPicker> createState() => _SpotifyTrackPickerState();
}

class _SpotifyTrackPickerState extends State<SpotifyTrackPicker> {
  final _spotifyService = SpotifyService();
  final _searchController = TextEditingController();
  List<SpotifyTrack> _searchResults = [];
  bool _isLoading = false;
  String _error = '';
  bool _showSearchField = false;

  Future<void> _searchTracks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final results = await _spotifyService.searchTracks(query);
      setState(() {
        _searchResults = results.map((track) {
          final images = track.album?.images ?? [];
          final imageUrl = images.isNotEmpty ? images.first.url ?? '' : '';

          return SpotifyTrack(
            id: track.id ?? '',
            name: track.name ?? 'Unknown Track',
            artist: track.artists?.firstOrNull?.name ?? 'Unknown Artist',
            albumArt: imageUrl,
            uri: track.uri ?? '',
            duration:
                Duration(milliseconds: track.duration?.inMilliseconds ?? 0),
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error searching tracks: $e';
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_showSearchField)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 64,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'What song represents you?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a song that matches your vibe',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _showSearchField = true);
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Search for a Song'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _showSearchField = false;
                          _searchController.clear();
                          _searchResults = [];
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Search Songs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a song name...',
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
                              _searchTracks('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    _searchTracks(value);
                  },
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
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
                  final track = _searchResults[index];
                  return Card(
                    color: Colors.white.withOpacity(0.1),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      leading: track.albumArt.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                track.albumArt,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.withOpacity(0.3),
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.withOpacity(0.3),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                              ),
                            ),
                      title: Text(
                        track.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        track.artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatDuration(track.duration),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        widget.onTrackSelected(track);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
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
    super.dispose();
  }
}
