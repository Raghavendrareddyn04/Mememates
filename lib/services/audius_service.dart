import 'dart:convert';
import 'package:http/http.dart' as http;

class AudiusService {
  static const List<String> _hosts = [
    "https://discoveryprovider3.audius.co",
    "https://audius-metadata-2.figment.io",
    "https://audius-dn1.tikilabs.com",
    "https://dn0.mainnet.audiusindex.org",
    "https://dn1.monophonic.digital",
    "https://audius-metadata-5.figment.io",
    "https://audius-metadata-3.figment.io",
    "https://discoveryprovider.audius.co",
    "https://discoveryprovider2.audius.co"
  ];

  String? _currentHost;

  Future<String> _getWorkingHost() async {
    if (_currentHost != null) {
      return _currentHost!;
    }

    for (var host in _hosts) {
      try {
        final response = await http.get(
          Uri.parse('$host/v1/tracks/trending?app_name=MEMEMATES'),
        );
        if (response.statusCode == 200) {
          _currentHost = host;
          return host;
        }
      } catch (e) {
        continue;
      }
    }
    throw Exception('No working Audius host found');
  }

  Future<List<Map<String, dynamic>>> getTrendingTracks() async {
    try {
      final host = await _getWorkingHost();
      final response = await http.get(
        Uri.parse('$host/v1/tracks/trending?app_name=MEMEMATES'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tracks = data['data'] ?? [];

        return tracks.map((track) {
          final artwork = track['artwork'] as Map<String, dynamic>?;
          final user = track['user'] as Map<String, dynamic>?;

          return {
            'id': track['id']?.toString() ?? '',
            'title': track['title'] ?? 'Unknown Title',
            'artist': user?['name'] ?? 'Unknown Artist',
            'artwork': artwork?['480x480'] ?? '',
            'duration': track['duration'] ?? 0,
            'genre': track['genre'] ?? '',
            'playCount': track['play_count'] ?? 0,
            'description': track['description'] ?? '',
            'artistHandle': user?['handle'] ?? '',
            'isVerifiedArtist': user?['is_verified'] ?? false,
          };
        }).toList();
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching trending tracks: $e');
      return [];
    }
  }

  Future<String> getStreamUrl(String trackId) async {
    try {
      final host = await _getWorkingHost();
      return '$host/v1/tracks/$trackId/stream?app_name=MEMEMATES';
    } catch (e) {
      throw Exception('Failed to get stream URL: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTrackList() async {
    try {
      final tracks = await getTrendingTracks();
      return tracks
          .take(100)
          .map((track) => {
                'id': track['id'],
                'title': track['title'],
                'artist': track['artist'],
                'artwork': track['artwork'],
                'duration': track['duration'],
              })
          .toList();
    } catch (e) {
      print("Error creating track list: $e");
      return [];
    }
  }
}
