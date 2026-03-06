import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ai_generation_source.dart';
import '../domain/ai_recipe.dart';

const _kAiAutoCacheKey = 'ai_auto_cache_entry';

final aiCacheRepoProvider = Provider<AiCacheRepo>((ref) {
  return const AiCacheRepo();
});

class CachedAiRecipes {
  final String fingerprint;
  final List<AiRecipe> recipes;
  final AiGenerationSource source;
  final DateTime updatedAt;
  final bool isAuto;

  const CachedAiRecipes({
    required this.fingerprint,
    required this.recipes,
    required this.source,
    required this.updatedAt,
    required this.isAuto,
  });

  Map<String, dynamic> toJson() {
    return {
      'fingerprint': fingerprint,
      'recipes': recipes.map((e) => e.toJson()).toList(),
      'source': source.storageValue,
      'updatedAt': updatedAt.toIso8601String(),
      'isAuto': isAuto,
    };
  }

  factory CachedAiRecipes.fromJson(Map<String, dynamic> json) {
    return CachedAiRecipes(
      fingerprint: json['fingerprint'] as String? ?? '',
      recipes: (json['recipes'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => AiRecipe.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      source: AiGenerationSourceX.fromStorage(json['source'] as String?),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isAuto: json['isAuto'] as bool? ?? true,
    );
  }
}

class AiCacheRepo {
  const AiCacheRepo();

  Future<CachedAiRecipes?> loadByFingerprint(String fingerprint) async {
    final entry = await loadLast();
    if (entry == null) {
      return null;
    }
    if (entry.fingerprint != fingerprint) {
      return null;
    }
    return entry;
  }

  Future<CachedAiRecipes?> loadLast() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAiAutoCacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return CachedAiRecipes.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(CachedAiRecipes entry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAiAutoCacheKey, jsonEncode(entry.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAiAutoCacheKey);
  }
}
