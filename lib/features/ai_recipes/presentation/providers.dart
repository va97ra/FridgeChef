import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/units.dart';
import '../../fridge/domain/fridge_item.dart';
import '../../fridge/presentation/providers.dart';
import '../../recipes/data/recipes_repo.dart';
import '../../shelf/domain/shelf_item.dart';
import '../../shelf/presentation/providers.dart';
import '../data/ai_cache_repo.dart';
import '../data/gemini_service.dart';
import '../data/settings_repo.dart';
import '../domain/ai_generation_source.dart';
import '../domain/ai_recipe.dart';
import '../domain/auto_generation_utils.dart';

final yandexServiceFactoryProvider =
    Provider<YandexGPTService Function(String iamToken, String folderId)>((ref) {
  return (iamToken, folderId) =>
      YandexGPTService(iamToken: iamToken, folderId: folderId);
});

enum AiGenerationStatus { idle, loading, success, error }

class AiGenerationState {
  final AiGenerationStatus status;
  final List<AiRecipe> recipes;
  final String? errorMessage;
  final AiGenerationSource source;
  final DateTime? lastUpdatedAt;
  final String? fingerprint;
  final bool isAuto;
  final bool isRefreshing;

  const AiGenerationState({
    this.status = AiGenerationStatus.idle,
    this.recipes = const [],
    this.errorMessage,
    this.source = AiGenerationSource.none,
    this.lastUpdatedAt,
    this.fingerprint,
    this.isAuto = true,
    this.isRefreshing = false,
  });

  AiGenerationState copyWith({
    AiGenerationStatus? status,
    List<AiRecipe>? recipes,
    String? errorMessage,
    bool clearError = false,
    AiGenerationSource? source,
    DateTime? lastUpdatedAt,
    String? fingerprint,
    bool? isAuto,
    bool? isRefreshing,
  }) {
    return AiGenerationState(
      status: status ?? this.status,
      recipes: recipes ?? this.recipes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      source: source ?? this.source,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      fingerprint: fingerprint ?? this.fingerprint,
      isAuto: isAuto ?? this.isAuto,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class AiRecipesNotifier extends AsyncNotifier<AiGenerationState> {
  Timer? _debounceTimer;
  bool _generationInFlight = false;
  bool _pendingSync = false;

  @override
  Future<AiGenerationState> build() async {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const AiGenerationState();
  }

  Future<void> scheduleAutoGenerate({required String reason}) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 2500), () {
      unawaited(generateNow(isAuto: true));
    });
  }

  Future<void> generateNow({String? extraWish, bool isAuto = false}) async {
    await syncWithCurrentInventory(
      forceAi: !isAuto,
      extraWish: extraWish,
      isAuto: isAuto,
    );
  }

  Future<void> syncWithCurrentInventory({
    required bool forceAi,
    String? extraWish,
    bool isAuto = true,
  }) async {
    if (_generationInFlight) {
      _pendingSync = true;
      return;
    }
    _generationInFlight = true;

    final previous = state.valueOrNull ?? const AiGenerationState();
    final hasPreviousRecipes = previous.recipes.isNotEmpty;

    state = AsyncValue.data(
      previous.copyWith(
        status: hasPreviousRecipes
            ? AiGenerationStatus.success
            : AiGenerationStatus.loading,
        isRefreshing: true,
        isAuto: isAuto,
        clearError: true,
      ),
    );

    try {
      final fridgeItems = ref.read(fridgeListProvider);
      final shelfItems = ref.read(shelfListProvider);
      final activeFridge = fridgeItems.where((item) => item.amount > 0).toList();
      final fingerprint = buildInventoryFingerprint(
        fridgeItems: fridgeItems,
        shelfItems: shelfItems,
      );

      final cacheRepo = ref.read(aiCacheRepoProvider);
      if (activeFridge.isEmpty) {
        state = AsyncValue.data(
          previous.copyWith(
            status: AiGenerationStatus.idle,
            recipes: const [],
            source: AiGenerationSource.none,
            lastUpdatedAt: DateTime.now(),
            fingerprint: fingerprint,
            isAuto: isAuto,
            isRefreshing: false,
            clearError: true,
          ),
        );
        return;
      }

      if (!forceAi) {
        final cached = await cacheRepo.loadByFingerprint(fingerprint);
        if (cached != null && cached.recipes.isNotEmpty) {
          state = AsyncValue.data(
            previous.copyWith(
              status: AiGenerationStatus.success,
              recipes: cached.recipes,
              source: AiGenerationSource.cache,
              lastUpdatedAt: cached.updatedAt,
              fingerprint: cached.fingerprint,
              isAuto: isAuto,
              isRefreshing: false,
              clearError: true,
            ),
          );
          return;
        }
      }

      final recipeCount = computeAutoRecipeCount(activeFridge.length);
      final fallbackRecipes = await _buildLocalFallback(
        fridgeItems: fridgeItems,
        shelfItems: shelfItems,
        count: recipeCount,
      );

      final iamToken = await ref.read(yandexIamTokenProvider.future);
      final folderId = await ref.read(yandexFolderIdProvider.future);
      final hasAiConfig = iamToken.trim().isNotEmpty && folderId.trim().isNotEmpty;

      List<AiRecipe> finalRecipes = fallbackRecipes;
      var source = AiGenerationSource.localFallback;
      String? warningMessage;

      if (hasAiConfig) {
        final prioritySignals = derivePrioritySignals(
          fridgeItems: fridgeItems,
          shelfItems: shelfItems,
        );
        final allowedNames = buildAllowedIngredientNames(
          fridgeItems: fridgeItems,
          shelfItems: shelfItems,
        );
        final fridgeStrings = _formatFridgeItems(fridgeItems);
        final shelfStrings = _formatShelfItems(shelfItems);

        try {
          final serviceFactory = ref.read(yandexServiceFactoryProvider);
          final service = serviceFactory(iamToken, folderId);
          final aiRecipes = await service.generateRecipes(
            fridgeItems: fridgeStrings,
            shelfItems: shelfStrings,
            priorityItems: prioritySignals.priorityItems,
            pairHints: prioritySignals.pairHints,
            count: recipeCount,
            extraWish: isAuto ? null : extraWish,
          );

          final validity = calculateIngredientValidity(
            recipes: aiRecipes,
            allowedIngredientNames: allowedNames,
          );

          if (validity >= kAiIngredientValidityThreshold) {
            finalRecipes = aiRecipes;
            source = AiGenerationSource.ai;
          } else {
            warningMessage =
                'AI вернул нерелевантные ингредиенты (${(validity * 100).round()}%), показаны локальные рецепты.';
          }
        } on YandexGPTException catch (e) {
          warningMessage = 'AI недоступен: ${e.message}. Показаны локальные рецепты.';
        } catch (_) {
          warningMessage = 'AI недоступен, показаны локальные рецепты.';
        }
      } else {
        warningMessage = 'AI не настроен, показаны локальные рецепты.';
      }

      if (finalRecipes.isEmpty) {
        final lastSuccess = await cacheRepo.loadLast();
        if (lastSuccess != null && lastSuccess.recipes.isNotEmpty) {
          finalRecipes = lastSuccess.recipes;
          source = AiGenerationSource.cache;
          warningMessage ??=
              'Локальный подбор пуст, показан последний успешный результат.';
        }
      }

      if (finalRecipes.isEmpty) {
        state = AsyncValue.data(
          previous.copyWith(
            status: AiGenerationStatus.error,
            recipes: const [],
            errorMessage: warningMessage ?? 'Не удалось подобрать рецепты.',
            source: AiGenerationSource.none,
            lastUpdatedAt: DateTime.now(),
            fingerprint: fingerprint,
            isAuto: isAuto,
            isRefreshing: false,
          ),
        );
        return;
      }

      final updatedAt = DateTime.now();
      state = AsyncValue.data(
        previous.copyWith(
          status: AiGenerationStatus.success,
          recipes: finalRecipes,
          errorMessage: warningMessage,
          clearError: warningMessage == null,
          source: source,
          lastUpdatedAt: updatedAt,
          fingerprint: fingerprint,
          isAuto: isAuto,
          isRefreshing: false,
        ),
      );

      await cacheRepo.save(
        CachedAiRecipes(
          fingerprint: fingerprint,
          recipes: finalRecipes,
          source: source,
          updatedAt: updatedAt,
          isAuto: isAuto,
        ),
      );
    } catch (e) {
      final fallbackState = state.valueOrNull ?? previous;
      state = AsyncValue.data(
        fallbackState.copyWith(
          status: fallbackState.recipes.isEmpty
              ? AiGenerationStatus.error
              : AiGenerationStatus.success,
          errorMessage: 'Неожиданная ошибка: ${e.toString()}',
          isRefreshing: false,
        ),
      );
    } finally {
      _generationInFlight = false;
      if (_pendingSync) {
        _pendingSync = false;
        unawaited(scheduleAutoGenerate(reason: 'pending-sync'));
      }
    }
  }

  Future<List<AiRecipe>> _buildLocalFallback({
    required List<FridgeItem> fridgeItems,
    required List<ShelfItem> shelfItems,
    required int count,
  }) async {
    final recipes = await ref.read(recipesRepoProvider).getAll();
    if (recipes.isEmpty) {
      return const [];
    }

    return buildLocalFallbackRecipes(
      recipes: recipes,
      fridgeItems: fridgeItems,
      shelfItems: shelfItems,
      count: count,
    );
  }

  List<String> _formatFridgeItems(List<FridgeItem> items) {
    return items
        .where((i) => i.amount > 0)
        .map((i) => '${i.name} — ${_formatAmount(i.amount, i.unit.label)}')
        .toList();
  }

  List<String> _formatShelfItems(List<ShelfItem> items) {
    return items.where((i) => i.inStock).map((i) => i.name).toList();
  }

  String _formatAmount(double amount, String unit) {
    if (amount == amount.truncateToDouble()) {
      return '${amount.toInt()} $unit';
    }
    return '${amount.toStringAsFixed(1)} $unit';
  }
}

final aiRecipesProvider =
    AsyncNotifierProvider<AiRecipesNotifier, AiGenerationState>(
  AiRecipesNotifier.new,
);
