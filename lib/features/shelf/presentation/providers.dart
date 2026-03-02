import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/shelf_item.dart';
import '../data/shelf_repo.dart';

class ShelfListNotifier extends StateNotifier<List<ShelfItem>> {
  final ShelfRepo _repo;

  ShelfListNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  void addItem(ShelfItem item) {
    _repo.upsert(item);
    _load();
  }

  void updateItem(ShelfItem item) {
    _repo.upsert(item);
    _load();
  }

  void toggleItem(ShelfItem item) {
    _repo.upsert(item.copyWith(inStock: !item.inStock));
    _load();
  }

  void removeItem(String id) {
    _repo.delete(id);
    _load();
  }
}

final shelfListProvider =
    StateNotifierProvider<ShelfListNotifier, List<ShelfItem>>((ref) {
  final repo = ref.watch(shelfRepoProvider);
  return ShelfListNotifier(repo);
});
