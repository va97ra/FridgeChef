import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/fridge_photo_import_coordinator.dart';
import 'package:help_to_cook/features/fridge/data/local_product_recognition_service.dart';
import 'package:help_to_cook/features/fridge/data/photo_input_service.dart';
import 'package:help_to_cook/features/fridge/data/product_catalog_repo.dart';
import 'package:help_to_cook/features/fridge/domain/detected_product_draft.dart';
import 'package:help_to_cook/features/fridge/domain/photo_import_result.dart';
import 'package:help_to_cook/features/fridge/domain/photo_source.dart';

void main() {
  test('returns local recognition result for gallery import', () async {
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
    final coordinator = FridgePhotoImportCoordinator(
      photoInputService: const _FakePhotoInputService(
        PhotoInputPickResult(
          permissionState: PhotoPermissionState.granted,
          imagePath: '/tmp/photo.jpg',
        ),
      ),
      localRecognitionService: _FakeLocalRecognitionService(localResult),
    );

    final result = await coordinator.importFromPhoto(source: PhotoSource.gallery);
    expect(result.hasResult, isTrue);
    expect(result.result!.imagePath, '/tmp/photo.jpg');
    expect(result.result!.drafts.first.name, 'Яйца');
    expect(result.result!.drafts.first.source, DetectionSource.local);
  });

  test('returns null when user cancels camera pick', () async {
    final coordinator = FridgePhotoImportCoordinator(
      photoInputService: const _FakePhotoInputService(
        PhotoInputPickResult(
          permissionState: PhotoPermissionState.granted,
          cancelled: true,
        ),
      ),
      localRecognitionService: _FakeLocalRecognitionService(
        const PhotoImportResult(imagePath: '', drafts: []),
      ),
    );

    final result = await coordinator.importFromPhoto(source: PhotoSource.camera);
    expect(result.hasResult, isFalse);
    expect(result.cancelled, isTrue);
  });

  test('returns denied attempt when camera permission is not granted', () async {
    final coordinator = FridgePhotoImportCoordinator(
      photoInputService: const _FakePhotoInputService(
        PhotoInputPickResult(
          permissionState: PhotoPermissionState.denied,
        ),
      ),
      localRecognitionService: _FakeLocalRecognitionService(
        const PhotoImportResult(imagePath: '', drafts: []),
      ),
    );

    final result = await coordinator.importFromPhoto(source: PhotoSource.camera);

    expect(result.hasResult, isFalse);
    expect(result.permissionState, PhotoPermissionState.denied);
    expect(result.cancelled, isFalse);
  });
}

class _FakePhotoInputService extends PhotoInputService {
  final PhotoInputPickResult result;

  const _FakePhotoInputService(this.result);

  @override
  Future<PhotoInputPickResult> pickFromCamera() async => result;

  @override
  Future<PhotoInputPickResult> pickFromGallery() async => result;
}

class _FakeLocalRecognitionService extends LocalProductRecognitionService {
  final PhotoImportResult result;

  _FakeLocalRecognitionService(this.result)
      : super(catalogRepo: const ProductCatalogRepo());

  @override
  Future<PhotoImportResult> detectFromImage(String imagePath) async => result;
}
