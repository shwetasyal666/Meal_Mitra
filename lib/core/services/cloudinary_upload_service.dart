import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mealmitra/core/config/app_config.dart';

final cloudinaryUploadServiceProvider = Provider(
  (ref) => CloudinaryUploadService(),
);

class CloudinaryUploadService {
  Future<String> uploadMealImage({
    required String uid,
    required String mealId,
    required XFile imageFile,
  }) {
    return _uploadImage(imageFile: imageFile, folder: 'mealmitra/meals/$uid');
  }

  Future<String> uploadProfileImage({
    required String uid,
    required XFile imageFile,
  }) {
    return _uploadImage(
      imageFile: imageFile,
      folder: 'mealmitra/profiles/$uid',
    );
  }

  Future<String> _uploadImage({
    required XFile imageFile,
    required String folder,
  }) async {
    if (AppConfig.cloudinaryCloudName.isEmpty ||
        AppConfig.cloudinaryUploadPreset.isEmpty) {
      throw Exception(
        'Image uploads are not configured. Missing cloud name or upload preset.',
      );
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
            ),
          )
          ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
          ..fields['folder'] = folder
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              await imageFile.readAsBytes(),
              filename: _safeFileName(imageFile),
            ),
          );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Image upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = decoded['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Image upload did not return a secure URL.');
    }

    return secureUrl;
  }

  String _safeFileName(XFile imageFile) {
    if (imageFile.name.isNotEmpty) return imageFile.name;
    final path = imageFile.path;
    if (path.isEmpty) return 'image.jpg';
    return path.split('/').last;
  }
}
