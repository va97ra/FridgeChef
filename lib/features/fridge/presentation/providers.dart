import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/fridge_item.dart';
import '../domain/photo_import_result.dart';
import '../domain/photo_source.dart';
import '../data/fridge_repo.dart';
import '../data/fridge_photo_import_coordinator.dart';

class FridgeListNotifier extends StateNotifier<List<FridgeItem>> {
  final FridgeRepo _repo;

  FridgeListNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  Future<void> addItem(FridgeItem item) async {
    await _repo.upsert(item);
    _load();
  }

  Future<void> updateItem(FridgeItem item) async {
    await _repo.upsert(item);
    _load();
  }

  Future<void> removeItem(String id) async {
    await _repo.delete(id);
    _load();
  }
}

final fridgeListProvider =
    StateNotifierProvider<FridgeListNotifier, List<FridgeItem>>((ref) {
  final repo = ref.watch(fridgeRepoProvider);
  return FridgeListNotifier(repo);
});

enum PhotoImportStatus { idle, loading, success, error }

class PhotoImportState {
  final PhotoImportStatus status;
  final PhotoImportResult? result;
  final String? errorMessage;

  const PhotoImportState({
    this.status = PhotoImportStatus.idle,
    this.result,
    this.errorMessage,
  });

  PhotoImportState copyWith({
    PhotoImportStatus? status,
    PhotoImportResult? result,
    String? errorMessage,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return PhotoImportState(
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PhotoImportNotifier extends StateNotifier<PhotoImportState> {
  final Ref _ref;

  PhotoImportNotifier(this._ref) : super(const PhotoImportState());

  Future<PhotoImportResult?> importFromPhoto(PhotoSource source) async {
    state = state.copyWith(
      status: PhotoImportStatus.loading,
      clearError: true,
      clearResult: true,
    );

    try {
      final result = await _ref
          .read(fridgePhotoImportCoordinatorProvider)
          .importFromPhoto(source: source);
      if (result == null) {
        state = state.copyWith(
          status: PhotoImportStatus.idle,
          clearResult: true,
          clearError: true,
        );
        return null;
      }

      state = state.copyWith(
        status: PhotoImportStatus.success,
        result: result,
        clearError: true,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        status: PhotoImportStatus.error,
        errorMessage: e.toString(),
      );
      return null;
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
