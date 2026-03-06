import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/photo_import_result.dart';
import '../domain/photo_source.dart';
import 'cloud_refinement_service.dart';
import 'local_product_recognition_service.dart';
import 'photo_input_service.dart';
import 'qwen_api_repo.dart';

final fridgePhotoImportCoordinatorProvider =
    Provider<FridgePhotoImportCoordinator>((ref) {
  return FridgePhotoImportCoordinator(
    photoInputService: ref.watch(photoInputServiceProvider),
    localRecognitionService: ref.watch(localProductRecognitionServiceProvider),
    cloudRefinementService: ref.watch(cloudRefinementServiceProvider),
    qwenApiRepo: ref.watch(qwenApiRepoProvider),
  );
});

class FridgePhotoImportCoordinator {
  final PhotoInputService photoInputService;
  final LocalProductRecognitionService localRecognitionService;
  final CloudRefinementService cloudRefinementService;
  final QwenApiRepo qwenApiRepo;

  const FridgePhotoImportCoordinator({
    required this.photoInputService,
    required this.localRecognitionService,
    required this.cloudRefinementService,
    required this.qwenApiRepo,
  });

  Future<PhotoImportResult?> importFromPhoto({
    required PhotoSource source,
  }) async {
    final imagePath = source == PhotoSource.camera
        ? await photoInputService.pickFromCamera()
        : await photoInputService.pickFromGallery();
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    final localResult = await localRecognitionService.detectFromImage(imagePath);
    final warnings = [...localResult.warnings];
    final connected = await qwenApiRepo.isConnected();
    if (!connected) {
      return localResult.copyWith(warnings: warnings);
    }

    try {
      final refined = await cloudRefinementService.refineWithQwenApi(
        imagePath: imagePath,
        localDrafts: localResult.drafts,
      );
      if (refined.isNotEmpty) {
        return localResult.copyWith(
          drafts: refined,
          warnings: warnings,
        );
      }
      return localResult.copyWith(warnings: warnings);
    } catch (_) {
      warnings.add(
        'Облачное уточнение недоступно, использован локальный режим.',
      );
      return localResult.copyWith(warnings: warnings);
    }
  }
}
