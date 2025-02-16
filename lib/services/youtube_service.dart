import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:async';

class YouTubeService {
  static final YouTubeService _instance = YouTubeService._internal();
  factory YouTubeService() => _instance;

  final _yt = YoutubeExplode();
  bool _isInitialized = false;

  YouTubeService._internal() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// Searches for videos based on query. Returns trending music if query is empty.
  Future<List<Video>> searchVideos(String query) async {
    if (query.trim().isEmpty) {
      return getTrendingMusic();
    }

    try {
      final searchList = await _yt.search.search(
        '$query music',
        filter: TypeFilters.video,
      );

      final results = await searchList.take(20).toList();

      return results
          .where((video) => video.title.isNotEmpty && video.author.isNotEmpty)
          .toList();
    } catch (e) {
      print('❌ Error searching videos: $e');
      return []; // Return an empty list instead of throwing an error
    }
  }

  /// Retrieves trending music videos.
  Future<List<Video>> getTrendingMusic() async {
    try {
      final trendingList = await _yt.search.search(
        'trending music 2024',
        filter: TypeFilters.video,
      );

      final results = await trendingList.take(20).toList();

      return results
          .where((video) => video.title.isNotEmpty && video.author.isNotEmpty)
          .toList();
    } catch (e) {
      print('❌ Error getting trending videos: $e');
      return [];
    }
  }

  /// Retrieves video details, including audio stream URL.
  Future<Map<String, dynamic>> getVideoDetails(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // Try getting the highest bitrate audio-only stream
      String? audioUrl;
      try {
        audioUrl = manifest.audioOnly.withHighestBitrate().url.toString();
      } catch (audioError) {
        print('⚠️ Failed to get audio-only stream, trying muxed stream...');
        try {
          final sortedMuxed = manifest.muxed.toList()
            ..sort((a, b) => b.bitrate.compareTo(a.bitrate));
          if (sortedMuxed.isNotEmpty) {
            audioUrl = sortedMuxed.first.url.toString();
          } else {
            throw 'No muxed stream available';
          }
        } catch (muxedError) {
          print('❌ No valid audio stream found for video ID: $videoId');
          return {};
        }
      }

      return {
        'id': video.id.value,
        'title': video.title,
        'author': video.author,
        'duration': video.duration ?? Duration.zero,
        'thumbnailUrl': video.thumbnails.highResUrl,
        'audioStreamUrl': audioUrl,
      };
    } catch (e) {
      print('❌ Error getting video details for ID: $videoId -> $e');
      return {};
    }
  }

  /// Retry function to handle temporary failures (rate limits, timeouts, etc.)
  Future<T> retry<T>(Future<T> Function() task, {int retries = 3}) async {
    for (var attempt = 0; attempt < retries; attempt++) {
      try {
        return await task();
      } catch (e) {
        print('⚠️ Retry attempt ${attempt + 1} failed: $e');
        if (attempt == retries - 1) rethrow;
        await Future.delayed(
            Duration(seconds: 2 * (attempt + 1))); // Exponential backoff
      }
    }
    throw Exception('Retries exhausted');
  }

  /// Closes YouTube Explode instance
  void dispose() {
    _yt.close();
  }
}

class YouTubeTrack {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final Duration duration;
  final String audioStreamUrl;

  YouTubeTrack({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.duration,
    required this.audioStreamUrl,
  });

  factory YouTubeTrack.fromVideo(Map<String, dynamic> videoDetails) {
    return YouTubeTrack(
      id: videoDetails['id'],
      title: videoDetails['title'],
      author: videoDetails['author'],
      thumbnailUrl: videoDetails['thumbnailUrl'],
      duration: videoDetails['duration'] ?? Duration.zero,
      audioStreamUrl: videoDetails['audioStreamUrl'],
    );
  }
}
