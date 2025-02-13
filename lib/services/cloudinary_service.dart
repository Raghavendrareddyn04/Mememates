import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;

  late final CloudinaryPublic cloudinary;
  final String _cloudName = 'drbkajmvf';

  CloudinaryService._internal() {
    cloudinary = CloudinaryPublic(
      _cloudName,
      'Mememates',
      cache: false,
    );
  }

  String _createTextOverlay(String text, {bool isTop = true}) {
    // Encode the text for URL
    final encodedText = Uri.encodeComponent(text)
        .replaceAll('.', '%2E')
        .replaceAll('-', '%2D')
        .replaceAll('_', '%5F');

    return 'l_text:Arial_70_bold:$encodedText,co_white,g_${isTop ? 'north' : 'south'},y_40';
  }

  Future<String> uploadImage(String imagePath,
      {String? topText, String? bottomText}) async {
    try {
      final file = File(imagePath);

      // Upload the original image first
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'mememates',
        ),
      );

      // If no text overlays are needed, return the URL as is
      if ((topText == null || topText.isEmpty) &&
          (bottomText == null || bottomText.isEmpty)) {
        return response.secureUrl;
      }

      // Start building the transformation URL
      final publicId = response.publicId;
      String transformUrl =
          'https://res.cloudinary.com/$_cloudName/image/upload';

      // Add text overlays if provided
      if (topText != null && topText.isNotEmpty) {
        transformUrl += '/${_createTextOverlay(topText, isTop: true)}';
      }
      if (bottomText != null && bottomText.isNotEmpty) {
        transformUrl += '/${_createTextOverlay(bottomText, isTop: false)}';
      }

      // Add the public ID at the end
      transformUrl += '/$publicId';

      return transformUrl;
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }
}
