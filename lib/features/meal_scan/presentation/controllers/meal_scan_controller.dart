import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mealmitra/core/services/camera/camera_capture_service.dart';
import 'package:mealmitra/core/services/api/api_client.dart';
import 'package:mealmitra/features/meal_scan/data/meal_scan_repository.dart';
import 'package:mealmitra/features/meal_scan/domain/meal_analysis.dart';

final cameraCaptureServiceProvider = Provider((ref) => CameraCaptureService(ImagePicker()));

final mealScanRepositoryProvider = Provider((ref) => MealScanRepository(
  ref.watch(apiClientProvider),
));

final mealScanControllerProvider = ChangeNotifierProvider((ref) => MealScanController(ref.watch(mealScanRepositoryProvider)));

enum MealScanStatus { idle, uploading, analyzing, completed, failed }

class MealScanState {
  const MealScanState({
    this.status = MealScanStatus.idle,
    this.result,
    this.errorMessage,
    this.imageFile,
  });

  final MealScanStatus status;
  final MealAnalysis? result;
  final String? errorMessage;
  final File? imageFile;
}

class MealScanController extends ChangeNotifier {
  MealScanController.fake({required MealAnalysis result})
      : _demoResult = result,
        _repository = null,
        state = const MealScanState();

  MealScanController(this._repository) : _demoResult = null, state = const MealScanState();

  final MealScanRepository? _repository;
  final MealAnalysis? _demoResult;
  MealScanState state;

  Future<void> scanDemoMeal() async {
    state = const MealScanState(status: MealScanStatus.analyzing);
    notifyListeners();
    state = MealScanState(status: MealScanStatus.completed, result: _demoResult);
    notifyListeners();
  }

  Future<void> scan({
    required String uid,
    required File imageFile,
    required String mealType,
  }) async {
    try {
      state = MealScanState(status: MealScanStatus.uploading, imageFile: imageFile);
      notifyListeners();
      final result = await _repository!.analyzeMeal(
        uid: uid,
        imageFile: imageFile,
        mealType: mealType,
      );
      state = MealScanState(status: MealScanStatus.completed, result: result, imageFile: imageFile);
      notifyListeners();
    } catch (error) {
      state = MealScanState(
        status: MealScanStatus.failed,
        errorMessage: error.toString(),
        imageFile: imageFile,
      );
      notifyListeners();
    }
  }

  void reset() {
    state = const MealScanState();
    notifyListeners();
  }
}
