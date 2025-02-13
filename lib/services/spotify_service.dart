import 'package:spotify/spotify.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyService {
  static final SpotifyService _instance = SpotifyService._internal();
  factory SpotifyService() => _instance;

  final String clientId = 'cdafc815f790419fab34c7970596b9cd';
  final String clientSecret = '53d751ecf45c4eecb2f0b6336e363d7b';
  late SpotifyApi spotify;

  SpotifyService._internal() {
    _initializeSpotify();
  }

  Future<void> _initializeSpotify() async {
    spotify = SpotifyApi(
      SpotifyApiCredentials(clientId, clientSecret),
    );
  }

  Future<List<Track>> searchTracks(String query) async {
    try {
      if (!query.trim().isNotEmpty) return [];

      final searchResults = await spotify.search.get(query).first(10);

      if (searchResults.isEmpty) return [];

      final pages = await searchResults.toList();
      if (pages.isEmpty) return [];

      final firstPage = pages.first;
      final tracks = firstPage.items ?? [];

      return tracks.whereType<Track>().toList();
    } catch (e) {
      print('Error searching tracks: $e');
      throw 'Failed to search tracks. Please try again.';
    }
  }

  Future<void> connectToSpotify() async {
    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: 'mememates://callback',
        scope:
            'app-remote-control,user-modify-playback-state,playlist-read-private',
      );
    } catch (e) {
      throw 'Failed to connect to Spotify: $e';
    }
  }

  Future<void> playTrack(String trackUri) async {
    try {
      await SpotifySdk.play(spotifyUri: trackUri);
    } catch (e) {
      throw 'Failed to play track: $e';
    }
  }

  Future<void> pauseTrack() async {
    try {
      await SpotifySdk.pause();
    } catch (e) {
      throw 'Failed to pause track: $e';
    }
  }

  Future<bool> isSpotifyInstalled() async {
    try {
      final token = await SpotifySdk.getAuthenticationToken(
        clientId: clientId,
        redirectUrl: 'mememates://callback',
        scope:
            'app-remote-control,user-modify-playback-state,playlist-read-private',
      );
      return token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Stream<PlayerState> subscribeToPlayerState() {
    return SpotifySdk.subscribePlayerState();
  }

  Future<void> seekTo(int positionedMilliseconds) async {
    try {
      await SpotifySdk.seekTo(positionedMilliseconds: positionedMilliseconds);
    } catch (e) {
      throw 'Failed to seek: $e';
    }
  }

  Future<void> setRepeatMode(RepeatMode repeatMode) async {
    try {
      await SpotifySdk.setRepeatMode(
        repeatMode: repeatMode,
      );
    } catch (e) {
      throw 'Failed to set repeat mode: $e';
    }
  }

  Future<void> setShuffle(bool shuffle) async {
    try {
      await SpotifySdk.setShuffle(
        shuffle: shuffle,
      );
    } catch (e) {
      throw 'Failed to set shuffle: $e';
    }
  }

  Future<void> disconnect() async {
    try {
      await SpotifySdk.disconnect();
    } catch (e) {
      throw 'Failed to disconnect: $e';
    }
  }
}

class SpotifyTrack {
  final String id;
  final String name;
  final String artist;
  final String albumArt;
  final String uri;
  final Duration duration;

  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.albumArt,
    required this.uri,
    required this.duration,
  });
}
