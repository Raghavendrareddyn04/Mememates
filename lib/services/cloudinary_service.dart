import 'dart:convert';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;

  late final CloudinaryPublic cloudinary;
  final String cloudName = 'drbkajmvf';
  final String _uploadPreset = 'Mememates';

  CloudinaryService._internal() {
    cloudinary = CloudinaryPublic(
      cloudName,
      _uploadPreset,
      cache: false,
    );
  }

  Future<String> uploadVideo(String videoPath) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          videoPath,
          resourceType: CloudinaryResourceType.Video,
          folder: 'mememates/videos',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary video upload error: $e');
      throw 'Failed to upload video: $e';
    }
  }

  Future<String> uploadImage(String imagePath) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imagePath,
          resourceType: CloudinaryResourceType.Image,
          folder: 'mememates/memes',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      throw 'Failed to upload image: $e';
    }
  }

  Future<String> uploadImageWithTransformations(
    String imagePath,
    List<String> transformations,
  ) async {
    try {
      // First upload the image
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imagePath,
          resourceType: CloudinaryResourceType.Image,
          folder: 'mememates/memes',
        ),
      );

      // Then construct the transformed URL
      final publicId = _extractPublicId(response.secureUrl);
      final transformationString = transformations.join(",");

      return 'https://res.cloudinary.com/$cloudName/image/upload/$transformationString/v1/$publicId';
    } catch (e) {
      print('Cloudinary upload error: $e');
      throw 'Failed to upload image: $e';
    }
  }

  Future<String> processImage(
    String url, {
    int? width,
    int? height,
    String? crop,
  }) async {
    try {
      final publicId = _extractPublicId(url);
      final List<String> transformations = [];

      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      if (crop != null) transformations.add('c_$crop');

      return 'https://res.cloudinary.com/$cloudName/image/upload/${transformations.join(",")}/v1/$publicId';
    } catch (e) {
      throw 'Failed to process image: $e';
    }
  }

  Future<String> addTextOverlay(
    String imageUrl, {
    String? topText,
    String? bottomText,
    Color textColor = Colors.white,
  }) async {
    try {
      final publicId = _extractPublicId(imageUrl);
      final List<String> transformations = [];

      // Convert color to RGB format
      final colorString =
          'co_rgb:${(textColor.red / 255).toStringAsFixed(2)}_${(textColor.green / 255).toStringAsFixed(2)}_${(textColor.blue / 255).toStringAsFixed(2)}';

      if (topText != null && topText.isNotEmpty) {
        final encodedText = Uri.encodeComponent(topText);
        transformations.add(
          'l_text:Arial_70_bold:$encodedText/$colorString/g_north,y_50/fl_layer_apply',
        );
      }

      if (bottomText != null && bottomText.isNotEmpty) {
        final encodedText = Uri.encodeComponent(bottomText);
        transformations.add(
          'l_text:Arial_70_bold:$encodedText/$colorString/g_south,y_50/fl_layer_apply',
        );
      }

      if (transformations.isEmpty) {
        return imageUrl;
      }

      return 'https://res.cloudinary.com/$cloudName/image/upload/${transformations.join("/")}/v1/$publicId';
    } catch (e) {
      throw 'Failed to add text overlay: $e';
    }
  }

  Future<String> addOverlay(
    String baseImage, {
    String? text,
    String? overlay,
    required Offset position,
  }) async {
    try {
      if (baseImage.isEmpty && text == null && overlay == null) {
        throw 'No content to overlay';
      }

      final List<String> transformations = [];
      final basePublicId =
          baseImage.isEmpty ? 'blank' : _extractPublicId(baseImage);

      if (text != null) {
        final encodedText = Uri.encodeComponent(text);
        transformations.add(
            'l_text:Arial_50_bold:$encodedText/co_white/x_${position.dx.toInt()}/y_${position.dy.toInt()}/fl_layer_apply');
      }

      if (overlay != null) {
        if (overlay.contains('res.cloudinary.com/$cloudName')) {
          final overlayPublicId = _extractPublicId(overlay);
          transformations.add(
              'l_$overlayPublicId/w_300/h_300/x_${position.dx.toInt()}/y_${position.dy.toInt()}/fl_layer_apply');
        } else {
          final encodedUrl = Uri.encodeComponent(overlay);
          transformations.add(
              'l_fetch:$encodedUrl/w_300/h_300/x_${position.dx.toInt()}/y_${position.dy.toInt()}/fl_layer_apply');
        }
      }

      return 'https://res.cloudinary.com/$cloudName/image/upload/${transformations.join("/")}/v1/$basePublicId';
    } catch (e) {
      throw 'Failed to add overlay: $e';
    }
  }

  String _extractPublicId(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;

    // Find the index after 'upload' in the path
    final uploadIndex = pathSegments.indexOf('upload');
    if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
      // Join all segments after 'upload', excluding any version numbers
      final remainingSegments = pathSegments
          .sublist(uploadIndex + 1)
          .where((segment) => !segment.startsWith('v'))
          .join('/');

      // Remove file extension if present
      return remainingSegments.replaceAll(RegExp(r'\.[^.]+$'), '');
    }

    // Fallback: return the last path segment without extension
    final lastSegment = pathSegments.last;
    return lastSegment.replaceAll(RegExp(r'\.[^.]+$'), '');
  }

  Future<String> generateMoodBoard(
      String backgroundColor, List<String> elements) async {
    try {
      final List<String> transformations = [];
      transformations.add('b_rgb:$backgroundColor');

      for (var i = 0; i < elements.length; i++) {
        final element = elements[i];
        final x = (i % 2) * 300;
        final y = (i ~/ 2) * 300;

        if (element.contains("res.cloudinary.com/$cloudName")) {
          final publicId = _extractPublicId(element);
          transformations
              .add('l_$publicId/w_300/h_300/x_$x/y_$y/fl_layer_apply');
        } else {
          final encodedUrl = Uri.encodeComponent(element);
          transformations
              .add('l_fetch:$encodedUrl/w_300/h_300/x_$x/y_$y/fl_layer_apply');
        }
      }

      return 'https://res.cloudinary.com/$cloudName/image/upload/${transformations.join("/")}/blank.jpg';
    } catch (e) {
      throw 'Failed to generate mood board: $e';
    }
  }

  Future<String> storeMoodBoard(String moodBoardUrl) async {
    try {
      final apiUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final params = {
        'file': moodBoardUrl,
        'timestamp': timestamp.toString(),
        'upload_preset': _uploadPreset,
        'type': 'fetch',
      };

      final response = await http.post(Uri.parse(apiUrl), body: params);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['secure_url'];
      } else {
        throw 'Failed to store mood board: ${response.body}';
      }
    } catch (e) {
      throw 'Failed to store mood board: $e';
    }
  }

  Future<String> generateVideoThumbnail(String videoUrl) async {
    try {
      final publicId = _extractPublicId(videoUrl);
      return 'https://res.cloudinary.com/$cloudName/video/upload/w_640,h_360,c_fill,q_auto,f_jpg/v1/$publicId.jpg';
    } catch (e) {
      throw 'Failed to generate video thumbnail: $e';
    }
  }
}
