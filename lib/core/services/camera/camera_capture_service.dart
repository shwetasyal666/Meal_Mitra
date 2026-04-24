import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraCaptureService {
  CameraCaptureService(this._picker);
  final ImagePicker _picker;

  Future<File?> captureFromCamera() async {
    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    return image == null ? null : File(image.path);
  }

  Future<File?> selectFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    return image == null ? null : File(image.path);
  }
}
