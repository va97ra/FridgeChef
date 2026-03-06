import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/cloud_refinement_service.dart';
import 'package:help_to_cook/features/fridge/data/fridge_photo_import_coordinator.dart';
import 'package:help_to_cook/features/fridge/data/local_product_recognition_service.dart';
import 'package:help_to_cook/features/fridge/data/photo_input_service.dart';
import 'package:help_to_cook/features/fridge/data/qwen_api_repo.dart';
import 'package:help_to_cook/features/fridge/domain/detected_product_draft.dart';
import 'package:help_to_cook/features/fridge/domain/photo_import_result.dart';
import 'package:help_to_cook/features/fridge/domain/photo_source.dart';

void main() {
  test('returns local result when oauth is disconnected', () async {
    final localResult = PhotoImportResult(
      imagePath: '/tmp/photo.jpg',
      drafts: const [
        DetectedProductDraft(
          id: 'd1',
          name: 'Яйца',
          amount: 3,
          unit: Unit.pcs,
          confidence: 0.8,
          rawTokens: ['яйца'],
          source: DetectionSource.local,
        ),
      ],
    );
    final cloud = _FakeCloudRefinementService();
    final coordinator = FridgePhotoImportCoordinator(
      photoInputService: _FakePhotoInputService('/tmp/photo.jpg'),
      localRecognitionService: _FakeLocalRecognitionService(localResult),
      cloudRefinementService: cloud,
      qwenApiRepo: _FakeApiRepo(false),
    );

    final result = await coordinator.importFromPhoto(source: PhotoSource.gallery);
    expect(result, isNotNull);
    expect(result!.drafts.first.name, 'Яйца');
    expect(cloud.callCount, 0);
  });

  test('falls back to local result when cloud refine throws', () async {
    final localResult = PhotoImportResult(
      imagePath: '/tmp/photo.jpg',
      drafts: const [
        DetectedProductDraft(
          id: 'd1',
          name: 'Молоко',
          amount: 1,
          unit: Unit.l,
          confidence: 0.8,
          rawTokens: ['молоко'],
          source: DetectionSource.local,
        ),
      ],
    );
    final coordinator = FridgePhotoImportCoordinator(
      photoInputService: _FakePhotoInputService('/tmp/photo.jpg'),
      localRecognitionService: _FakeLocalRecognitionService(localResult),
      cloudRefinementService: _FakeCloudRefinementService(throwError: true),
      qwenApiRepo: _FakeApiRepo(true),
    );

    final result = await coordinator.importFromPhoto(source: PhotoSource.camera);
    expect(result, isNotNull);
    expect(result!.drafts.first.source, DetectionSource.local);
    expect(result.warnings, isNotEmpty);
  });
}

class _FakePhotoInputService extends PhotoInputService {
  final String? path;

  const _FakePhotoInputService(this.path);

  @override
  Future<String?> pickFromCamera() async => path;

  @override
  Future<String?> pickFromGallery() async => path;
}

class _FakeLocalRecognitionService extends LocalProductRecognitionService {
  final PhotoImportResult result;

  const _FakeLocalRecognitionService(this.result);

  @override
  Future<PhotoImportResult> detectFromImage(String imagePath) async => result;
}

class _FakeCloudRefinementService extends CloudRefinementService {
  final bool throwError;
  int callCount = 0;

  _FakeCloudRefinementService({this.throwError = false})
      : super(qwenApiRepo: const QwenApiRepo());

  @override
  Future<List<DetectedProductDraft>> refineWithQwenApi({
    required String imagePath,
    required List<DetectedProductDraft> localDrafts,
  }) async {
    callCount++;
    if (throwError) {
      throw const CloudRefineException('boom');
    }
    return localDrafts
        .map((draft) => draft.copyWith(source: DetectionSource.cloudRefined))
        .toList();
  }
}

class _FakeApiRepo extends QwenApiRepo {
  final bool connected;

  const _FakeApiRepo(this.connected);

  @override
  Future<bool> isConnected() async => connected;
}
