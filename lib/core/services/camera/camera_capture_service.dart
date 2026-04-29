import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cameraCaptureServiceProvider = Provider(
  (ref) => CameraCaptureService(ImagePicker()),
);

class CameraCaptureService {
  CameraCaptureService(this._picker);
  final ImagePicker _picker;

  Future<XFile?> captureFromCamera() async {
    return await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
  }

  Future<XFile?> selectFromGallery() async {
    return await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
  }
}
