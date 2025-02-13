import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;

  late final CloudinaryPublic cloudinary;
  final String _cloudName =
      'drbkajmvf'; // Replace with your Cloudinary cloud name

  CloudinaryService._internal() {
    cloudinary = CloudinaryPublic(
      _cloudName,
      'Mememates',
      cache: false,
    );
  }

  /// ✅ Upload Image to Cloudinary
  Future<String> uploadImage(String imagePath,
      {String? topText, String? bottomText}) async {
    try {
      final file = File(imagePath);
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'mememates/moodboard',
        ),
      );
      print('Uploaded Image URL: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }

  /// ✅ Apply Transformations (Crop, Resize)
  Future<String> processImage(
    String publicId, {
    int? width,
    int? height,
    String? crop,
  }) async {
    try {
      final List<String> transformations = [];
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      if (crop != null) transformations.add('c_$crop');

      final transformedUrl =
          'https://res.cloudinary.com/$_cloudName/image/upload/${transformations.join(",")}/$publicId.jpg';

      print('Processed Image URL: $transformedUrl');
      return transformedUrl;
    } catch (e) {
      throw 'Failed to process image: $e';
    }
  }

  /// ✅ Add Text & Sticker Overlays
  Future<String> addOverlay(
    String publicId, {
    String? text,
    String? stickerUrl,
    required Offset position,
    String? overlay,
  }) async {
    try {
      final List<String> transformations = [];

      if (text != null) {
        final encodedText = Uri.encodeComponent(text);
        transformations.add(
          'l_text:Arial_50_bold:$encodedText,co_white,x_${position.dx.toInt()},y_${position.dy.toInt()}',
        );
      }

      if (stickerUrl != null) {
        final encodedSticker = Uri.encodeComponent(stickerUrl);
        transformations.add(
          'l_fetch:$encodedSticker,x_${position.dx.toInt()},y_${position.dy.toInt()}',
        );
      }

      final transformedUrl =
          'https://res.cloudinary.com/$_cloudName/image/upload/${transformations.join(",")}/$publicId.jpg';

      print('Overlay Image URL: $transformedUrl');
      return transformedUrl;
    } catch (e) {
      throw 'Failed to add overlay: $e';
    }
  }

  /// ✅ Generate Final Mood Board URL
  Future<String> generateMoodBoard(
      String baseImageId, List<String> elements) async {
    try {
      final List<String> transformations = [];

      for (var element in elements) {
        transformations.add('l_$element');
      }

      final moodBoardUrl =
          'https://res.cloudinary.com/$_cloudName/image/upload/${transformations.join(",")}/$baseImageId.jpg';

      print('Final Mood Board URL: $moodBoardUrl');
      return moodBoardUrl;
    } catch (e) {
      throw 'Failed to generate mood board: $e';
    }
  }
}
