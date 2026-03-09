import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/app/data/app_settings_repo.dart';
import 'package:help_to_cook/app/data/backup_service.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/data/fridge_repo.dart';
import 'package:help_to_cook/features/fridge/data/user_product_memory_repo.dart';
import 'package:help_to_cook/features/fridge/domain/fridge_item.dart';
import 'package:help_to_cook/features/fridge/domain/user_product_memory_entry.dart';
import 'package:help_to_cook/features/recipes/data/generated_recipe_draft_parser.dart';
import 'package:help_to_cook/features/recipes/data/recipe_feedback_repo.dart';
import 'package:help_to_cook/features/recipes/data/user_recipes_repo.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/taste_profile.dart';
import 'package:help_to_cook/features/shelf/data/shelf_repo.dart';
import 'package:help_to_cook/features/shelf/domain/shelf_item.dart';

void main() {
  test('loadImportPreview rejects schema 1 backups', () async {
    final service = BackupService(
      fridgeRepo: _FakeFridgeRepo(),
      shelfRepo: _FakeShelfRepo(),
      userRecipesRepo: _FakeUserRecipesRepo(),
      recipeFeedbackRepo: _FakeRecipeFeedbackRepo(),
      userProductMemoryRepo: _FakeUserProductMemoryRepo(),
      appSettingsRepo: _FakeAppSettingsRepo(),
    );
    final path = await _writeBackupFile({
      'schemaVersion': 1,
      'exportedAt': '2026-03-09T10:00:00.000Z',
      'appVersion': '0.9.0+1',
      'fridgeItems': const [],
      'shelfItems': const [],
      'userRecipes': const [],
    });

    addTearDown(() => File(path).deleteSync());

    await expectLater(
      service.loadImportPreview(path),
      throwsA(
        isA<BackupFormatException>().having(
          (error) => error.message,
          'message',
          contains('Неподдерживаемая версия'),
        ),
      ),
    );
  });

  test('round-trips v2 feedback votes and product memory', () {
    final payload = BackupPayloadV2(
      schemaVersion: BackupService.schemaVersion,
      exportedAt: DateTime.parse('2026-03-09T10:00:00.000Z'),
      appVersion: '1.0.0+1',
      fridgeItems: const [
        FridgeItem(id: 'f1', name: 'Яйца', amount: 6, unit: Unit.pcs),
      ],
      shelfItems: const [
        ShelfItem(id: 's1', name: 'Соль', inStock: true),
      ],
      userRecipes: const [
        Recipe(
          id: 'r1',
          title: 'Шеф-омлет',
          timeMin: 10,
          tags: ['generated_local'],
          servingsBase: 2,
          ingredients: [
            RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
          ],
          steps: ['Шаг 1'],
          source: RecipeSource.generatedSaved,
          isUserEditable: true,
        ),
      ],
      recipeFeedbackVotes: const {
        'r1': RecipeFeedbackVote.liked,
      },
      userProductMemory: [
        UserProductMemoryEntry(
          key: 'catalog:egg',
          name: 'Яйца',
          productId: 'egg',
          lastUnit: Unit.pcs,
          lastAmount: 6,
          frequency: 3,
          lastUsedAt: DateTime.parse('2026-03-09T09:00:00.000Z'),
        ),
      ],
    );

    final restored = BackupPayloadV2.fromJson(payload.toJson());

    expect(restored.recipeFeedbackVotes['r1'], RecipeFeedbackVote.liked);
    expect(restored.userProductMemory.single.name, 'Яйца');
    expect(restored.userProductMemory.single.lastAmount, 6);
  });

  test('replaceAllData restores feedback votes and product memory', () async {
    final fridgeRepo = _FakeFridgeRepo();
    final shelfRepo = _FakeShelfRepo();
    final recipesRepo = _FakeUserRecipesRepo();
    final feedbackRepo = _FakeRecipeFeedbackRepo();
    final memoryRepo = _FakeUserProductMemoryRepo();
    final settingsRepo = _FakeAppSettingsRepo();
    final service = BackupService(
      fridgeRepo: fridgeRepo,
      shelfRepo: shelfRepo,
      userRecipesRepo: recipesRepo,
      recipeFeedbackRepo: feedbackRepo,
      userProductMemoryRepo: memoryRepo,
      appSettingsRepo: settingsRepo,
    );

    await service.replaceAllData(
      BackupPayloadV2(
        schemaVersion: BackupService.schemaVersion,
        exportedAt: DateTime.parse('2026-03-09T10:00:00.000Z'),
        appVersion: '1.0.0+1',
        fridgeItems: const [
          FridgeItem(id: 'f1', name: 'Яйца', amount: 6, unit: Unit.pcs),
        ],
        shelfItems: const [
          ShelfItem(id: 's1', name: 'Соль', inStock: true),
        ],
        userRecipes: const [
          Recipe(
            id: 'r1',
            title: 'Шеф-омлет',
            timeMin: 10,
            tags: ['generated_local'],
            servingsBase: 2,
            ingredients: [
              RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
            ],
            steps: ['Шаг 1'],
          ),
        ],
        recipeFeedbackVotes: const {
          'r1': RecipeFeedbackVote.disliked,
        },
        userProductMemory: [
          UserProductMemoryEntry(
            key: 'catalog:egg',
            name: 'Яйца',
            productId: 'egg',
            lastUnit: Unit.pcs,
            lastAmount: 6,
            frequency: 2,
            lastUsedAt: DateTime.parse('2026-03-09T09:00:00.000Z'),
          ),
        ],
      ),
    );

    expect(fridgeRepo.items.single.name, 'Яйца');
    expect(shelfRepo.items.single.name, 'Соль');
    expect(recipesRepo.items.single.title, 'Шеф-омлет');
    expect(feedbackRepo.votes['r1'], RecipeFeedbackVote.disliked);
    expect(memoryRepo.items.single.productId, 'egg');
  });

  test('loadImportPreview rejects legacy recipe sources', () async {
    final service = BackupService(
      fridgeRepo: _FakeFridgeRepo(),
      shelfRepo: _FakeShelfRepo(),
      userRecipesRepo: _FakeUserRecipesRepo(),
      recipeFeedbackRepo: _FakeRecipeFeedbackRepo(),
      userProductMemoryRepo: _FakeUserProductMemoryRepo(),
      appSettingsRepo: _FakeAppSettingsRepo(),
    );
    final path = await _writeBackupFile({
      'schemaVersion': BackupService.schemaVersion,
      'exportedAt': '2026-03-09T10:00:00.000Z',
      'appVersion': '1.0.0+1',
      'fridgeItems': const [],
      'shelfItems': const [],
      'userRecipes': [
        {
          'id': 'r1',
          'title': 'Старый рецепт',
          'timeMin': 10,
          'tags': ['quick'],
          'servingsBase': 2,
          'ingredients': const [
            {
              'name': 'Яйцо',
              'amount': 2.0,
              'unit': 'pcs',
              'required': true,
            },
          ],
          'steps': const ['Шаг 1'],
          'source': 'ai_saved',
        },
      ],
    });

    addTearDown(() => File(path).deleteSync());

    await expectLater(
      service.loadImportPreview(path),
      throwsA(
        isA<BackupFormatException>().having(
          (error) => error.message,
          'message',
          contains('неподдерживаемые рецепты'),
        ),
      ),
    );
  });

  test('clearAllData clears feedback memory and app flags', () async {
    final service = BackupService(
      fridgeRepo: _FakeFridgeRepo(),
      shelfRepo: _FakeShelfRepo(),
      userRecipesRepo: _FakeUserRecipesRepo(),
      recipeFeedbackRepo: _FakeRecipeFeedbackRepo(),
      userProductMemoryRepo: _FakeUserProductMemoryRepo(),
      appSettingsRepo: _FakeAppSettingsRepo(),
    );

    await service.clearAllData();

    expect((service.fridgeRepo as _FakeFridgeRepo).cleared, isTrue);
    expect((service.shelfRepo as _FakeShelfRepo).cleared, isTrue);
    expect((service.userRecipesRepo as _FakeUserRecipesRepo).cleared, isTrue);
    expect((service.recipeFeedbackRepo as _FakeRecipeFeedbackRepo).cleared, isTrue);
    expect(
      (service.userProductMemoryRepo as _FakeUserProductMemoryRepo).cleared,
      isTrue,
    );
    expect((service.appSettingsRepo as _FakeAppSettingsRepo).cleared, isTrue);
  });

  test('replaceAllData rejects payloads below schema 2', () async {
    final service = BackupService(
      fridgeRepo: _FakeFridgeRepo(),
      shelfRepo: _FakeShelfRepo(),
      userRecipesRepo: _FakeUserRecipesRepo(),
      recipeFeedbackRepo: _FakeRecipeFeedbackRepo(),
      userProductMemoryRepo: _FakeUserProductMemoryRepo(),
      appSettingsRepo: _FakeAppSettingsRepo(),
    );

    await expectLater(
      service.replaceAllData(
        BackupPayloadV2(
          schemaVersion: 1,
          exportedAt: DateTime.parse('2026-03-09T10:00:00.000Z'),
          appVersion: '0.9.0+1',
          fridgeItems: const [],
          shelfItems: const [],
          userRecipes: const [],
        ),
      ),
      throwsA(isA<BackupFormatException>()),
    );
  });
}

Future<String> _writeBackupFile(Map<String, dynamic> payload) async {
  final dir = await Directory.systemTemp.createTemp('backup_service_test');
  final file = File('${dir.path}${Platform.pathSeparator}backup.json');
  await file.writeAsString(jsonEncode(payload));
  return file.path;
}

class _FakeFridgeRepo extends FridgeRepo {
  List<FridgeItem> items = [];
  bool cleared = false;

  _FakeFridgeRepo() : super(boxName: 'unused');

  @override
  List<FridgeItem> getAll() => items;

  @override
  Future<void> replaceAll(List<FridgeItem> items) async {
    this.items = items;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    items = [];
  }
}

class _FakeShelfRepo extends ShelfRepo {
  List<ShelfItem> items = [];
  bool cleared = false;

  _FakeShelfRepo() : super(boxName: 'unused');

  @override
  List<ShelfItem> getAll() => items;

  @override
  Future<void> replaceAll(List<ShelfItem> items) async {
    this.items = items;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    items = [];
  }
}

class _FakeUserRecipesRepo extends UserRecipesRepo {
  List<Recipe> items = [];
  bool cleared = false;

  _FakeUserRecipesRepo()
      : super(
          boxName: 'unused',
          parser: const GeneratedRecipeDraftParser(),
        );

  @override
  Future<List<Recipe>> getAllUserRecipes() async => items;

  @override
  Future<void> replaceAllUserRecipes(List<Recipe> recipes) async {
    items = recipes;
  }

  @override
  Future<void> clearAll() async {
    cleared = true;
    items = [];
  }
}

class _FakeRecipeFeedbackRepo extends RecipeFeedbackRepo {
  Map<String, RecipeFeedbackVote> votes = {};
  bool cleared = false;

  @override
  Future<Map<String, RecipeFeedbackVote>> loadAll() async => votes;

  @override
  Future<void> replaceAll(Map<String, RecipeFeedbackVote> votes) async {
    this.votes = votes;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    votes = {};
  }
}

class _FakeUserProductMemoryRepo extends UserProductMemoryRepo {
  List<UserProductMemoryEntry> items = [];
  bool cleared = false;

  @override
  Future<List<UserProductMemoryEntry>> loadAll() async => items;

  @override
  Future<void> replaceAll(List<UserProductMemoryEntry> items) async {
    this.items = items;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    items = [];
  }
}

class _FakeAppSettingsRepo extends AppSettingsRepo {
  bool cleared = false;

  @override
  Future<void> clearLocalFlags() async {
    cleared = true;
  }
}
