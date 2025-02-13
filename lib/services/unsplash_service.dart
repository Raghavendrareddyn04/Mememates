import 'package:http/http.dart' as http;
import 'dart:convert';

class UnsplashService {
  static const String _accessKey =
      '3bHeSiVm-5now0JJmxkmK39mj4GGvuxeLeeZzVYHmDA';
  static const String _baseUrl = 'https://api.unsplash.com';

  Future<List<UnsplashImage>> searchImages(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/photos?query=$query&per_page=30'),
        headers: {'Authorization': 'Client-ID $_accessKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .map((image) => UnsplashImage.fromJson(image))
            .toList();
      } else {
        throw 'Failed to search images: ${response.statusCode}';
      }
    } catch (e) {
      throw 'Error searching images: $e';
    }
  }
}

class UnsplashImage {
  final String id;
  final String url;
  final String thumbUrl;
  final String photographer;

  UnsplashImage({
    required this.id,
    required this.url,
    required this.thumbUrl,
    required this.photographer,
  });

  factory UnsplashImage.fromJson(Map<String, dynamic> json) {
    return UnsplashImage(
      id: json['id'],
      url: json['urls']['regular'],
      thumbUrl: json['urls']['thumb'],
      photographer: json['user']['name'],
    );
  }
}
