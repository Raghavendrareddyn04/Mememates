import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;

  late final CloudinaryPublic cloudinary;

  CloudinaryService._internal() {
    cloudinary = CloudinaryPublic(
      'drbkajmvf', // Your cloud name
      'Mememates', // Use 'ml_default' as the upload preset
      cache: false,
    );
  }

  Future<String> uploadImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'mememates', // Add a folder to organize uploads
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }
}
