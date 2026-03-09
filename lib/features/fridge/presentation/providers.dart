import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/fridge_item.dart';
import '../domain/photo_import_result.dart';
import '../domain/photo_source.dart';
import '../data/fridge_repo.dart';
import '../data/fridge_photo_import_coordinator.dart';
import '../data/photo_input_service.dart';
import '../data/user_product_memory_repo.dart';

class FridgeListNotifier extends StateNotifier<List<FridgeItem>> {
  final FridgeRepo _repo;
  final UserProductMemoryRepo _memoryRepo;

  FridgeListNotifier(this._repo, this._memoryRepo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  Future<void> addItem(FridgeItem item, {String? productId}) async {
    await _repo.upsert(item);
    await _recordProductMemorySafely(item, productId: productId);
    _load();
  }

  Future<void> updateItem(FridgeItem item, {String? productId}) async {
    await _repo.upsert(item);
    await _recordProductMemorySafely(item, productId: productId);
    _load();
  }

  Future<void> removeItem(String id) async {
    await _repo.delete(id);
    _load();
  }

  Future<void> _recordProductMemorySafely(
    FridgeItem item, {
    String? productId,
  }) async {
    try {
      await _memoryRepo.recordProduct(
        name: item.name,
        unit: item.unit,
        amount: item.amount,
        productId: productId,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to record fridge product memory: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

final fridgeListProvider =
    StateNotifierProvider<FridgeListNotifier, List<FridgeItem>>((ref) {
  final repo = ref.watch(fridgeRepoProvider);
  final memoryRepo = ref.watch(userProductMemoryRepoProvider);
  return FridgeListNotifier(repo, memoryRepo);
});

enum PhotoImportStatus { idle, loading, success, error }

class PhotoImportState {
  final PhotoImportStatus status;
  final PhotoImportResult? result;
  final String? errorMessage;
  final PhotoPermissionState? permissionState;
  final PhotoSource? source;
  final bool cancelled;

  const PhotoImportState({
    this.status = PhotoImportStatus.idle,
    this.result,
    this.errorMessage,
    this.permissionState,
    this.source,
    this.cancelled = false,
  });

  PhotoImportState copyWith({
    PhotoImportStatus? status,
    PhotoImportResult? result,
    String? errorMessage,
    PhotoPermissionState? permissionState,
    PhotoSource? source,
    bool? cancelled,
    bool clearError = false,
    bool clearResult = false,
    bool clearPermission = false,
  }) {
    return PhotoImportState(
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      permissionState: clearPermission
          ? null
          : (permissionState ?? this.permissionState),
      source: source ?? this.source,
      cancelled: cancelled ?? this.cancelled,
    );
  }
}

class PhotoImportNotifier extends StateNotifier<PhotoImportState> {
  final Ref _ref;

  PhotoImportNotifier(this._ref) : super(const PhotoImportState());

  Future<PhotoImportAttempt> importFromPhoto(PhotoSource source) async {
    state = state.copyWith(
      status: PhotoImportStatus.loading,
      clearError: true,
      clearResult: true,
      clearPermission: true,
      source: source,
      cancelled: false,
    );

    try {
      final attempt = await _ref
          .read(fridgePhotoImportCoordinatorProvider)
          .importFromPhoto(source: source);
      if (!attempt.hasResult) {
        if (attempt.cancelled) {
          state = state.copyWith(
            status: PhotoImportStatus.idle,
            clearResult: true,
            clearError: true,
            clearPermission: true,
            cancelled: true,
          );
          return attempt;
        }

        state = state.copyWith(
          status: PhotoImportStatus.error,
          clearResult: true,
          clearError: true,
          permissionState: attempt.permissionState,
          source: attempt.source,
          cancelled: false,
        );
        return attempt;
      }

      state = state.copyWith(
        status: PhotoImportStatus.success,
        result: attempt.result,
        clearError: true,
        permissionState: attempt.permissionState,
        source: attempt.source,
        cancelled: false,
      );
      return attempt;
    } catch (e) {
      state = state.copyWith(
        status: PhotoImportStatus.error,
        errorMessage: e.toString(),
        cancelled: false,
      );
      return PhotoImportAttempt(
        source: source,
        permissionState: PhotoPermissionState.granted,
      );
    }
  }

  void reset() {
    state = const PhotoImportState();
  }
}

final photoImportStateProvider =
    StateNotifierProvider<PhotoImportNotifier, PhotoImportState>((ref) {
  return PhotoImportNotifier(ref);
});
