import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

final localFileStorageServiceProvider = Provider(
  (ref) => LocalFileStorageService(),
);

class LocalFileStorageService {
  Future<String> saveProfileImage(XFile imageFile) async {
    return _copyToAppDirectory(
      imageFile,
      folderName: 'profile_images',
      fileNamePrefix: 'profile_picture',
    );
  }

  Future<String> saveMealImage({
    required XFile imageFile,
    required String mealId,
  }) async {
    return _copyToAppDirectory(
      imageFile,
      folderName: 'meal_images',
      fileNamePrefix: 'meal_$mealId',
    );
  }

  Future<void> deleteIfManaged(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    if (!filePath.startsWith('file://')) return;

    final file = File(Uri.parse(filePath).toFilePath());
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> _copyToAppDirectory(
    XFile imageFile, {
    required String folderName,
    required String fileNamePrefix,
  }) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final targetDirectory = Directory('${appDirectory.path}/$folderName');
    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final extension = _extensionFor(imageFile);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetPath =
        '${targetDirectory.path}/$fileNamePrefix-$timestamp$extension';
    final savedFile = await File(imageFile.path).copy(targetPath);
    return savedFile.uri.toString();
  }

  String _extensionFor(XFile imageFile) {
    final name = imageFile.name.isNotEmpty ? imageFile.name : imageFile.path;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1) return '.jpg';
    return name.substring(dotIndex);
  }
}
