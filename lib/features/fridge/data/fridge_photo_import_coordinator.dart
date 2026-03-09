import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/photo_import_result.dart';
import '../domain/photo_source.dart';
import 'local_product_recognition_service.dart';
import 'photo_input_service.dart';

final fridgePhotoImportCoordinatorProvider =
    Provider<FridgePhotoImportCoordinator>((ref) {
  return FridgePhotoImportCoordinator(
    photoInputService: ref.watch(photoInputServiceProvider),
    localRecognitionService: ref.watch(localProductRecognitionServiceProvider),
  );
});

class FridgePhotoImportCoordinator {
  final PhotoInputService photoInputService;
  final LocalProductRecognitionService localRecognitionService;

  const FridgePhotoImportCoordinator({
    required this.photoInputService,
    required this.localRecognitionService,
  });

  Future<PhotoImportAttempt> importFromPhoto({
    required PhotoSource source,
  }) async {
    final inputResult = source == PhotoSource.camera
        ? await photoInputService.pickFromCamera()
        : await photoInputService.pickFromGallery();
    if (!inputResult.hasImage) {
      return PhotoImportAttempt(
        source: source,
        permissionState: inputResult.permissionState,
        cancelled: inputResult.cancelled,
      );
    }

    final result =
        await localRecognitionService.detectFromImage(inputResult.imagePath!);
    return PhotoImportAttempt(
      source: source,
      permissionState: inputResult.permissionState,
      result: result,
    );
  }
}

class PhotoImportAttempt {
  final PhotoSource source;
  final PhotoImportResult? result;
  final PhotoPermissionState permissionState;
  final bool cancelled;

  const PhotoImportAttempt({
    required this.source,
    required this.permissionState,
    this.result,
    this.cancelled = false,
  });

  bool get hasResult => result != null;
}
