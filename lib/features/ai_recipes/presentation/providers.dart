import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/units.dart';
import '../../fridge/domain/fridge_item.dart';
import '../../fridge/presentation/providers.dart';
import '../../shelf/domain/shelf_item.dart';
import '../../shelf/presentation/providers.dart';
import '../data/gemini_service.dart';
import '../data/settings_repo.dart';
import '../domain/ai_recipe.dart';

// ── Состояние генерации ──────────────────────────────────────────────────────

enum AiGenerationStatus { idle, loading, success, error }

class AiGenerationState {
  final AiGenerationStatus status;
  final List<AiRecipe> recipes;
  final String? errorMessage;

  const AiGenerationState({
    this.status = AiGenerationStatus.idle,
    this.recipes = const [],
    this.errorMessage,
  });

  AiGenerationState copyWith({
    AiGenerationStatus? status,
    List<AiRecipe>? recipes,
    String? errorMessage,
  }) {
    return AiGenerationState(
      status: status ?? this.status,
      recipes: recipes ?? this.recipes,
      errorMessage: errorMessage,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class AiRecipesNotifier extends AsyncNotifier<AiGenerationState> {
  @override
  Future<AiGenerationState> build() async {
    return const AiGenerationState();
  }

  Future<void> generate({String? extraWish}) async {
    final apiKey = await ref.read(geminiApiKeyProvider.future);
    final fridgeItems = ref.read(fridgeListProvider);
    final shelfItems = ref.read(shelfListProvider);

    state = const AsyncValue.loading();

    final fridgeStrings = _formatFridgeItems(fridgeItems);
    final shelfStrings = _formatShelfItems(shelfItems);

    try {
      final service = GeminiService(apiKey: apiKey);
      final recipes = await service.generateRecipes(
        fridgeItems: fridgeStrings,
        shelfItems: shelfStrings,
        count: 3,
        extraWish: extraWish,
      );
      state = AsyncValue.data(
        AiGenerationState(
          status: AiGenerationStatus.success,
          recipes: recipes,
        ),
      );
    } on GeminiException catch (e) {
      state = AsyncValue.data(
        AiGenerationState(
          status: AiGenerationStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        AiGenerationState(
          status: AiGenerationStatus.error,
          errorMessage: 'Неожиданная ошибка: ${e.toString()}',
        ),
      );
    }
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
