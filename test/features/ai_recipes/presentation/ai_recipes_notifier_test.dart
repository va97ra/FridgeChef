import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/ai_recipes/data/ai_cache_repo.dart';
import 'package:help_to_cook/features/ai_recipes/data/gemini_service.dart';
import 'package:help_to_cook/features/ai_recipes/data/settings_repo.dart';
import 'package:help_to_cook/features/ai_recipes/domain/ai_generation_source.dart';
import 'package:help_to_cook/features/ai_recipes/domain/ai_recipe.dart';
import 'package:help_to_cook/features/ai_recipes/presentation/providers.dart';
import 'package:help_to_cook/features/fridge/data/fridge_repo.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/recipes/data/recipes_loader.dart';
import 'package:help_to_cook/features/recipes/data/recipes_repo.dart';
import 'package:help_to_cook/features/recipes/data/ai_to_recipe_parser.dart';
import 'package:help_to_cook/features/recipes/data/user_recipes_repo.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/shelf/data/shelf_repo.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';

void main() {
  test('falls back to local recipes when IAM/Folder are empty', () async {
    final fakeService = _FakeYandexService(
      response: const [],
      throwError: false,
    );
    final container = _createContainer(
      iamToken: '',
      folderId: '',
      fakeService: fakeService,
    );
    addTearDown(container.dispose);

    await container.read(aiRecipesProvider.notifier).syncWithCurrentInventory(
          forceAi: false,
        );

    final state = container.read(aiRecipesProvider).valueOrNull;
    expect(state, isNotNull);
    expect(state!.status, AiGenerationStatus.success);
    expect(state.source, AiGenerationSource.localFallback);
    expect(state.recipes, isNotEmpty);
    expect(fakeService.callCount, 0);
  });

  test('uses cache for unchanged fingerprint and avoids duplicate AI call',
      () async {
    final fakeService = _FakeYandexService(
      response: const [
        AiRecipe(
          title: 'AI Омлет',
          timeMin: 10,
          servings: 2,
          ingredients: ['Яйцо — 2 шт'],
          steps: ['Шаг 1'],
        ),
      ],
      throwError: false,
    );
    final container = _createContainer(
      iamToken: 'iam',
      folderId: 'folder',
      fakeService: fakeService,
    );
    addTearDown(container.dispose);

    final notifier = container.read(aiRecipesProvider.notifier);
    await notifier.syncWithCurrentInventory(forceAi: false);
    expect(fakeService.callCount, 1);
    expect(
      container.read(aiRecipesProvider).valueOrNull?.source,
      AiGenerationSource.ai,
    );

    await notifier.syncWithCurrentInventory(forceAi: false);
    expect(fakeService.callCount, 1);
    expect(
      container.read(aiRecipesProvider).valueOrNull?.source,
      AiGenerationSource.cache,
    );
  });

  test('falls back to local recipes when AI throws', () async {
    final fakeService = _FakeYandexService(
      response: const [],
      throwError: true,
    );
    final container = _createContainer(
      iamToken: 'iam',
      folderId: 'folder',
      fakeService: fakeService,
    );
    addTearDown(container.dispose);

    await container.read(aiRecipesProvider.notifier).syncWithCurrentInventory(
          forceAi: false,
        );

    final state = container.read(aiRecipesProvider).valueOrNull;
    expect(state, isNotNull);
    expect(state!.source, AiGenerationSource.localFallback);
    expect(state.recipes, isNotEmpty);
    expect(state.errorMessage, contains('AI недоступен'));
  });

  test('debounce schedules a single generation for rapid updates', () async {
    final fakeService = _FakeYandexService(
      response: const [
        AiRecipe(
          title: 'AI Омлет',
          timeMin: 10,
          servings: 2,
          ingredients: ['Яйцо — 2 шт'],
          steps: ['Шаг 1'],
        ),
      ],
      throwError: false,
    );
    final container = _createContainer(
      iamToken: 'iam',
      folderId: 'folder',
      fakeService: fakeService,
    );
    addTearDown(container.dispose);

    final notifier = container.read(aiRecipesProvider.notifier);
    await notifier.scheduleAutoGenerate(reason: 'test-1');
    await notifier.scheduleAutoGenerate(reason: 'test-2');
    await notifier.scheduleAutoGenerate(reason: 'test-3');

    await Future<void>.delayed(const Duration(milliseconds: 3400));
    expect(fakeService.callCount, 1);
  });
}

ProviderContainer _createContainer({
  required String iamToken,
  required String folderId,
  required _FakeYandexService fakeService,
}) {
  final fallbackRecipes = <Recipe>[
    Recipe(
      id: 'r1',
      title: 'Локальная яичница',
      timeMin: 8,
      tags: const ['quick'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(
          name: 'Яйцо',
          amount: 2,
          unit: Unit.pcs,
          required: true,
        ),
      ],
      steps: const ['Пожарь яйцо'],
    ),
  ];

  return ProviderContainer(
    overrides: [
      fridgeRepoProvider.overrideWithValue(
        _FakeFridgeRepo(
          const [
            FridgeItem(id: 'f1', name: 'Яйцо', amount: 4, unit: Unit.pcs),
            FridgeItem(id: 'f2', name: 'Молоко', amount: 250, unit: Unit.ml),
          ],
        ),
      ),
      shelfRepoProvider.overrideWithValue(
        _FakeShelfRepo(
          const [
            ShelfItem(id: 's1', name: 'Соль', inStock: true),
          ],
        ),
      ),
      recipesRepoProvider.overrideWithValue(
        RecipesRepo(
          loader: _FakeRecipesLoader(fallbackRecipes),
          userRecipesRepo: _FakeUserRecipesRepo(),
        ),
      ),
      aiCacheRepoProvider.overrideWithValue(_InMemoryAiCacheRepo()),
      yandexIamTokenProvider.overrideWith(
        () => _StaticYandexIamTokenNotifier(iamToken),
      ),
      yandexFolderIdProvider.overrideWith(
        () => _StaticYandexFolderIdNotifier(folderId),
      ),
      yandexServiceFactoryProvider.overrideWithValue(
        (iam, folder) => fakeService,
      ),
    ],
  );
}

class _FakeFridgeRepo extends FridgeRepo {
  final List<FridgeItem> items;

  _FakeFridgeRepo(this.items) : super(boxName: 'test');

  @override
  List<FridgeItem> getAll() => List<FridgeItem>.from(items);
}

class _FakeShelfRepo extends ShelfRepo {
  final List<ShelfItem> items;

  _FakeShelfRepo(this.items) : super(boxName: 'test');

  @override
  List<ShelfItem> getAll() => List<ShelfItem>.from(items);
}

class _StaticYandexIamTokenNotifier extends YandexIamTokenNotifier {
  final String value;

  _StaticYandexIamTokenNotifier(this.value);

  @override
  Future<String> build() async => value;

  @override
  Future<void> save(String token) async {
    state = AsyncValue.data(token);
  }

  @override
  Future<void> clear() async {
    state = const AsyncValue.data('');
  }
}

class _StaticYandexFolderIdNotifier extends YandexFolderIdNotifier {
  final String value;

  _StaticYandexFolderIdNotifier(this.value);

  @override
  Future<String> build() async => value;

  @override
  Future<void> save(String folderId) async {
    state = AsyncValue.data(folderId);
  }

  @override
  Future<void> clear() async {
    state = const AsyncValue.data('');
  }
}

class _FakeRecipesLoader extends RecipesLoader {
  final List<Recipe> recipes;

  const _FakeRecipesLoader(this.recipes);

  @override
  Future<List<Recipe>> loadRecipes() async => recipes;
}

class _FakeUserRecipesRepo extends UserRecipesRepo {
  _FakeUserRecipesRepo()
      : super(
          boxName: 'unused',
          parser: const AiToRecipeParser(),
        );

  @override
  Future<List<Recipe>> getAllUserRecipes() async => const [];
}

class _InMemoryAiCacheRepo extends AiCacheRepo {
  CachedAiRecipes? _entry;

  @override
  Future<CachedAiRecipes?> loadByFingerprint(String fingerprint) async {
    final entry = _entry;
    if (entry == null || entry.fingerprint != fingerprint) {
      return null;
    }
    return entry;
  }

  @override
  Future<CachedAiRecipes?> loadLast() async => _entry;

  @override
  Future<void> save(CachedAiRecipes entry) async {
    _entry = entry;
  }

  @override
  Future<void> clear() async {
    _entry = null;
  }
}

class _FakeYandexService extends YandexGPTService {
  final List<AiRecipe> response;
  final bool throwError;
  int callCount = 0;

  _FakeYandexService({
    required this.response,
    required this.throwError,
  }) : super(iamToken: 'token', folderId: 'folder');

  @override
  Future<List<AiRecipe>> generateRecipes({
    required List<String> fridgeItems,
    required List<String> shelfItems,
    required List<String> priorityItems,
    required List<String> pairHints,
    int count = 3,
    String? extraWish,
  }) async {
    callCount++;
    if (throwError) {
      throw const YandexGPTException('boom');
    }
    return response;
  }
}
