import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/fridge_item.dart';
import '../data/fridge_repo.dart';

class FridgeListNotifier extends StateNotifier<List<FridgeItem>> {
  final FridgeRepo _repo;

  FridgeListNotifier(this._repo) : super([]) {
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  void addItem(FridgeItem item) {
    _repo.upsert(item);
    _load();
  }

  void updateItem(FridgeItem item) {
    _repo.upsert(item);
    _load();
  }

  void removeItem(String id) {
    _repo.delete(id);
    _load();
  }
}

final fridgeListProvider = StateNotifierProvider<FridgeListNotifier, List<FridgeItem>>((ref) {
  final repo = ref.watch(fridgeRepoProvider);
  return FridgeListNotifier(repo);
});
