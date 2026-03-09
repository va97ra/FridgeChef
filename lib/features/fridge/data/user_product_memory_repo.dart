import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/units.dart';
import '../domain/photo_import_utils.dart';
import '../domain/user_product_memory_entry.dart';

final userProductMemoryRepoProvider = Provider<UserProductMemoryRepo>((ref) {
  return const UserProductMemoryRepo();
});

class UserProductMemoryRepo {
  static const storageKey = 'fridge_user_product_memory_v1';

  const UserProductMemoryRepo();

  Future<List<UserProductMemoryEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return <UserProductMemoryEntry>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return <UserProductMemoryEntry>[];
    }

    return decoded
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .map(UserProductMemoryEntry.fromJson)
        .where((entry) => entry.key.isNotEmpty && entry.name.isNotEmpty)
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  }

  Future<void> recordProduct({
    required String name,
    required Unit unit,
    required double amount,
    String? productId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final items = [...await loadAll()];
    final normalizedName = normalizeProductToken(name);
    if (normalizedName.isEmpty) {
      return;
    }

    final key = (productId != null && productId.isNotEmpty)
        ? 'catalog:$productId'
        : 'name:$normalizedName';
    final existingIndex = items.indexWhere((entry) => entry.key == key);
    final now = DateTime.now();

    if (existingIndex >= 0) {
      final existing = items[existingIndex];
      items[existingIndex] = existing.copyWith(
        name: name.trim(),
        productId: productId ?? existing.productId,
        lastUnit: unit,
        lastAmount: amount > 0 ? amount : existing.lastAmount,
        frequency: existing.frequency + 1,
        lastUsedAt: now,
      );
    } else {
      items.add(
        UserProductMemoryEntry(
          key: key,
          name: name.trim(),
          productId: productId,
          lastUnit: unit,
          lastAmount: amount > 0 ? amount : null,
          frequency: 1,
          lastUsedAt: now,
        ),
      );
    }

    items.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    final encoded = jsonEncode(items.map((entry) => entry.toJson()).toList());
    await prefs.setString(storageKey, encoded);
  }

  Future<void> replaceAll(List<UserProductMemoryEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = [...items]..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    final encoded = jsonEncode(sorted.map((entry) => entry.toJson()).toList());
    await prefs.setString(storageKey, encoded);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
