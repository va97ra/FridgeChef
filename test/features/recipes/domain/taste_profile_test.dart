import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/core/utils/units.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/chef_rules.dart';
import 'package:help_to_cook/features/recipes/domain/recipe.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_interaction_event.dart';
import 'package:help_to_cook/features/recipes/domain/taste_profile.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient_canonicalizer.dart';

void main() {
  test('taste profile prefers recipes similar to liked ones', () {
    final likedRecipe = Recipe(
      id: 'liked',
      title: 'Омлет с сыром',
      timeMin: 10,
      tags: const ['breakfast', 'one_pan'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Сыр', amount: 40, unit: Unit.g),
      ],
      steps: const ['Взбей', 'Пожарь'],
    );
    final similarRecipe = Recipe(
      id: 'similar',
      title: 'Яичница с помидорами',
      timeMin: 9,
      tags: const ['breakfast', 'one_pan'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Помидор', amount: 120, unit: Unit.g),
      ],
      steps: const ['Пожарь', 'Подавай'],
    );
    final distantRecipe = Recipe(
      id: 'distant',
      title: 'Сладкая овсянка',
      timeMin: 8,
      tags: const ['breakfast'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Овсяные хлопья', amount: 60, unit: Unit.g),
        RecipeIngredient(name: 'Сахар', amount: 10, unit: Unit.g),
      ],
      steps: const ['Свари', 'Подавай'],
    );

    final catalog = const [
      ProductCatalogEntry(
        id: 'egg',
        name: 'Яйцо',
        canonicalName: 'Яйцо',
        synonyms: ['Яйца'],
        defaultUnit: Unit.pcs,
      ),
      ProductCatalogEntry(
        id: 'cheese',
        name: 'Сыр',
        canonicalName: 'Сыр',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'tomato',
        name: 'Помидор',
        canonicalName: 'Помидор',
        synonyms: ['Помидоры'],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'oats',
        name: 'Овсяные хлопья',
        canonicalName: 'Овсяные хлопья',
        synonyms: ['Овсянка'],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'sugar',
        name: 'Сахар',
        canonicalName: 'Сахар',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
    ];

    final profile = buildTasteProfile(
      feedbackByRecipeId: const {'liked': RecipeFeedbackVote.liked},
      recipes: [likedRecipe, similarRecipe, distantRecipe],
      catalog: catalog,
    );

    final canonicalizer = RecipeIngredientCanonicalizer(catalog);
    final similarAnalysis = profile.analyzeRecipe(
      recipe: similarRecipe,
      canonicalizer: canonicalizer,
    );
    final distantAnalysis = profile.analyzeRecipe(
      recipe: distantRecipe,
      canonicalizer: canonicalizer,
    );

    expect(similarAnalysis.score, greaterThan(distantAnalysis.score));
    expect(similarAnalysis.reasons, isNotEmpty);
    expect(profile.pairPreference('яйцо', 'сыр'), greaterThan(0));
  });

  test('taste profile learns from saved edited recipes without explicit vote',
      () {
    final now = DateTime.now();
    final savedRecipe = Recipe(
      id: 'saved_omelet',
      title: 'Мой омлет с сыром',
      timeMin: 12,
      tags: const ['breakfast', 'one_pan'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Сыр', amount: 40, unit: Unit.g),
      ],
      steps: const ['Взбей', 'Пожарь', 'Дай постоять минуту и подавай'],
      source: RecipeSource.generatedSaved,
      isUserEditable: true,
      createdAt: now.subtract(const Duration(days: 3, minutes: 20)),
      updatedAt: now.subtract(const Duration(days: 2)),
    );
    final similarRecipe = Recipe(
      id: 'similar_breakfast',
      title: 'Яичница с помидором',
      timeMin: 10,
      tags: const ['breakfast', 'one_pan'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Яйцо', amount: 2, unit: Unit.pcs),
        RecipeIngredient(name: 'Помидор', amount: 120, unit: Unit.g),
      ],
      steps: const ['Разогрей сковороду', 'Пожарь', 'Подавай'],
    );
    final distantRecipe = Recipe(
      id: 'distant_porridge',
      title: 'Сладкая овсянка',
      timeMin: 8,
      tags: const ['breakfast'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Овсяные хлопья', amount: 60, unit: Unit.g),
        RecipeIngredient(name: 'Сахар', amount: 10, unit: Unit.g),
      ],
      steps: const ['Свари', 'Подавай'],
    );

    final catalog = const [
      ProductCatalogEntry(
        id: 'egg',
        name: 'Яйцо',
        canonicalName: 'Яйцо',
        synonyms: ['Яйца'],
        defaultUnit: Unit.pcs,
      ),
      ProductCatalogEntry(
        id: 'cheese',
        name: 'Сыр',
        canonicalName: 'Сыр',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'tomato',
        name: 'Помидор',
        canonicalName: 'Помидор',
        synonyms: ['Помидоры'],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'oats',
        name: 'Овсяные хлопья',
        canonicalName: 'Овсяные хлопья',
        synonyms: ['Овсянка'],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'sugar',
        name: 'Сахар',
        canonicalName: 'Сахар',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
    ];

    final profile = buildTasteProfile(
      feedbackByRecipeId: const {},
      recipes: [savedRecipe, similarRecipe, distantRecipe],
      catalog: catalog,
      referenceTime: now,
    );
    final canonicalizer = RecipeIngredientCanonicalizer(catalog);

    final similarAnalysis = profile.analyzeRecipe(
      recipe: similarRecipe,
      canonicalizer: canonicalizer,
    );
    final distantAnalysis = profile.analyzeRecipe(
      recipe: distantRecipe,
      canonicalizer: canonicalizer,
    );

    expect(profile.ingredientPreference('яйцо'), greaterThan(0));
    expect(profile.pairPreference('яйцо', 'сыр'), greaterThan(0));
    expect(profile.profilePreference(DishProfile.breakfast), greaterThan(0));
    expect(similarAnalysis.score, greaterThan(distantAnalysis.score));
  });

  test('taste profile learns disliked pairs and preferred dish style', () {
    final likedRecipe = Recipe(
      id: 'liked_soup',
      title: 'Куриный суп',
      timeMin: 35,
      tags: const ['soup'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Курица', amount: 250, unit: Unit.g),
        RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
        RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
      ],
      steps: const [
        'Нарежь',
        'Вари на слабом огне',
        'Дай настояться и подавай'
      ],
    );
    final dislikedRecipe = Recipe(
      id: 'disliked_sweet',
      title: 'Сладкая овсянка',
      timeMin: 8,
      tags: const ['breakfast'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Овсяные хлопья', amount: 60, unit: Unit.g),
        RecipeIngredient(name: 'Сахар', amount: 10, unit: Unit.g),
      ],
      steps: const ['Свари', 'Подавай'],
    );

    final catalog = const [
      ProductCatalogEntry(
        id: 'chicken',
        name: 'Курица',
        canonicalName: 'Курица',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'onion',
        name: 'Лук',
        canonicalName: 'Лук',
        synonyms: [],
        defaultUnit: Unit.pcs,
      ),
      ProductCatalogEntry(
        id: 'carrot',
        name: 'Морковь',
        canonicalName: 'Морковь',
        synonyms: [],
        defaultUnit: Unit.pcs,
      ),
      ProductCatalogEntry(
        id: 'oats',
        name: 'Овсяные хлопья',
        canonicalName: 'Овсяные хлопья',
        synonyms: ['Овсянка'],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'sugar',
        name: 'Сахар',
        canonicalName: 'Сахар',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
    ];

    final profile = buildTasteProfile(
      feedbackByRecipeId: const {
        'liked_soup': RecipeFeedbackVote.liked,
        'disliked_sweet': RecipeFeedbackVote.disliked,
      },
      recipes: [likedRecipe, dislikedRecipe],
      catalog: catalog,
    );

    expect(profile.pairPreference('курица', 'лук'), greaterThan(0));
    expect(profile.pairPreference('овсяные хлопья', 'сахар'), lessThan(0));
    expect(
      profile.profilePreference(DishProfile.soup),
      greaterThan(profile.profilePreference(DishProfile.breakfast)),
    );
  });

  test('taste profile rewards familiar technique patterns', () {
    final likedRecipe = Recipe(
      id: 'liked_fish',
      title: 'Рыба в духовке',
      timeMin: 28,
      tags: const ['oven'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Рыба', amount: 300, unit: Unit.g),
        RecipeIngredient(name: 'Лимон', amount: 1, unit: Unit.pcs),
      ],
      steps: const [
        'Подготовь рыбу',
        'Запекай под крышкой до готовности',
        'Дай постоять и подавай',
      ],
    );
    final similarRecipe = Recipe(
      id: 'similar_fish',
      title: 'Запечённая рыба с лимоном',
      timeMin: 30,
      tags: const ['oven'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Рыба', amount: 320, unit: Unit.g),
        RecipeIngredient(name: 'Лимон', amount: 1, unit: Unit.pcs),
      ],
      steps: const [
        'Подготовь рыбу',
        'Запекай до готовности',
        'Перед подачей дай постоять',
      ],
    );
    final distantRecipe = Recipe(
      id: 'distant_fish',
      title: 'Жареная рыба',
      timeMin: 12,
      tags: const ['one_pan'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Рыба', amount: 300, unit: Unit.g),
      ],
      steps: const [
        'Разогрей сковороду',
        'Обжарь на сильном огне',
        'Подавай сразу',
      ],
    );

    final catalog = const [
      ProductCatalogEntry(
        id: 'fish',
        name: 'Рыба',
        canonicalName: 'Рыба',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'lemon',
        name: 'Лимон',
        canonicalName: 'Лимон',
        synonyms: [],
        defaultUnit: Unit.pcs,
      ),
    ];

    final profile = buildTasteProfile(
      feedbackByRecipeId: const {'liked_fish': RecipeFeedbackVote.liked},
      recipes: [likedRecipe, similarRecipe, distantRecipe],
      catalog: catalog,
    );
    final canonicalizer = RecipeIngredientCanonicalizer(catalog);

    final similarAnalysis = profile.analyzeRecipe(
      recipe: similarRecipe,
      canonicalizer: canonicalizer,
    );
    final distantAnalysis = profile.analyzeRecipe(
      recipe: distantRecipe,
      canonicalizer: canonicalizer,
    );

    expect(similarAnalysis.score, greaterThan(distantAnalysis.score));
    expect(
      similarAnalysis.reasons.any(
        (reason) => reason.contains('способ приготовления'),
      ),
      isTrue,
    );
  });

  test(
      'taste profile learns from recook and ignore history without recipe list',
      () {
    final now = DateTime(2026, 3, 9, 12);
    final recookedSoup = Recipe(
      id: 'soup_memory',
      title: 'Куриный суп',
      timeMin: 35,
      tags: const ['soup'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Курица', amount: 250, unit: Unit.g),
        RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
        RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
      ],
      steps: const [
        'Нарежь овощи',
        'Вари на слабом огне',
        'Дай настояться и подавай',
      ],
    );
    final ignoredSweet = Recipe(
      id: 'ignored_breakfast',
      title: 'Сладкая овсянка',
      timeMin: 8,
      tags: const ['breakfast'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Овсяные хлопья', amount: 60, unit: Unit.g),
        RecipeIngredient(name: 'Сахар', amount: 10, unit: Unit.g),
      ],
      steps: const ['Свари', 'Подавай'],
    );
    final soupCandidate = Recipe(
      id: 'candidate_soup',
      title: 'Домашний суп с курицей',
      timeMin: 32,
      tags: const ['soup'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Курица', amount: 220, unit: Unit.g),
        RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
      ],
      steps: const ['Подготовь', 'Вари на тихом огне', 'Подавай'],
    );
    final porridgeCandidate = Recipe(
      id: 'candidate_porridge',
      title: 'Овсяная каша',
      timeMin: 7,
      tags: const ['breakfast'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Овсяные хлопья', amount: 55, unit: Unit.g),
        RecipeIngredient(name: 'Сахар', amount: 8, unit: Unit.g),
      ],
      steps: const ['Свари', 'Подавай'],
    );

    final catalog = const [
      ProductCatalogEntry(
        id: 'chicken',
        name: 'Курица',
        canonicalName: 'Курица',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'onion',
        name: 'Лук',
        canonicalName: 'Лук',
        synonyms: [],
        defaultUnit: Unit.pcs,
      ),
      ProductCatalogEntry(
        id: 'carrot',
        name: 'Морковь',
        canonicalName: 'Морковь',
        synonyms: [],
        defaultUnit: Unit.pcs,
      ),
      ProductCatalogEntry(
        id: 'oats',
        name: 'Овсяные хлопья',
        canonicalName: 'Овсяные хлопья',
        synonyms: ['Овсянка'],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'sugar',
        name: 'Сахар',
        canonicalName: 'Сахар',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
    ];

    final profile = buildTasteProfile(
      feedbackByRecipeId: const {},
      recipes: const [],
      catalog: catalog,
      interactionHistory: [
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: recookedSoup,
          occurredAt: now.subtract(const Duration(days: 2)),
        ),
        RecipeInteractionEvent(
          type: RecipeInteractionType.ignored,
          recipeSnapshot: ignoredSweet,
          occurredAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      referenceTime: now,
    );
    final canonicalizer = RecipeIngredientCanonicalizer(catalog);

    final soupAnalysis = profile.analyzeRecipe(
      recipe: soupCandidate,
      canonicalizer: canonicalizer,
    );
    final porridgeAnalysis = profile.analyzeRecipe(
      recipe: porridgeCandidate,
      canonicalizer: canonicalizer,
    );

    expect(profile.profilePreference(DishProfile.soup), greaterThan(0));
    expect(profile.pairPreference('овсяные хлопья', 'сахар'), lessThan(0));
    expect(soupAnalysis.score, greaterThan(porridgeAnalysis.score));
  });

  test('repeated recook memory strengthens stable preferences', () {
    final now = DateTime(2026, 3, 9, 12);
    final recookedSoup = Recipe(
      id: 'recook_soup',
      title: 'Куриный суп',
      timeMin: 35,
      tags: const ['soup'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Курица', amount: 250, unit: Unit.g),
        RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
        RecipeIngredient(name: 'Морковь', amount: 1, unit: Unit.pcs),
      ],
      steps: const ['Нарежь', 'Вари на слабом огне', 'Дай настояться'],
    );

    final catalog = const [
      ProductCatalogEntry(
        id: 'chicken',
        name: 'Курица',
        canonicalName: 'Курица',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'onion',
        name: 'Лук',
        canonicalName: 'Лук',
        synonyms: [],
        defaultUnit: Unit.pcs,
      ),
      ProductCatalogEntry(
        id: 'carrot',
        name: 'Морковь',
        canonicalName: 'Морковь',
        synonyms: [],
        defaultUnit: Unit.pcs,
      ),
    ];

    final singleProfile = buildTasteProfile(
      feedbackByRecipeId: const {},
      recipes: const [],
      catalog: catalog,
      interactionHistory: [
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: recookedSoup,
          occurredAt: now.subtract(const Duration(days: 2)),
        ),
      ],
      referenceTime: now,
    );
    final repeatedProfile = buildTasteProfile(
      feedbackByRecipeId: const {},
      recipes: const [],
      catalog: catalog,
      interactionHistory: [
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: recookedSoup,
          occurredAt: now.subtract(const Duration(days: 4)),
        ),
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: recookedSoup,
          occurredAt: now.subtract(const Duration(days: 2)),
        ),
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: recookedSoup,
          occurredAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      referenceTime: now,
    );

    expect(
      repeatedProfile.profilePreference(DishProfile.soup),
      greaterThan(singleProfile.profilePreference(DishProfile.soup)),
    );
    expect(
      repeatedProfile.ingredientPreference('курица'),
      greaterThan(singleProfile.ingredientPreference('курица')),
    );
  });

  test('recent interaction memory outweighs stale old favorites', () {
    final now = DateTime(2026, 3, 9, 12);
    final oldBreakfast = Recipe(
      id: 'old_breakfast',
      title: 'Сладкая овсянка',
      timeMin: 8,
      tags: const ['breakfast'],
      servingsBase: 1,
      ingredients: const [
        RecipeIngredient(name: 'Овсяные хлопья', amount: 60, unit: Unit.g),
        RecipeIngredient(name: 'Сахар', amount: 10, unit: Unit.g),
      ],
      steps: const ['Свари', 'Подавай'],
    );
    final recentSoup = Recipe(
      id: 'recent_soup',
      title: 'Куриный суп',
      timeMin: 35,
      tags: const ['soup'],
      servingsBase: 2,
      ingredients: const [
        RecipeIngredient(name: 'Курица', amount: 250, unit: Unit.g),
        RecipeIngredient(name: 'Лук', amount: 1, unit: Unit.pcs),
      ],
      steps: const ['Нарежь', 'Вари на слабом огне', 'Подавай'],
    );

    final catalog = const [
      ProductCatalogEntry(
        id: 'chicken',
        name: 'Курица',
        canonicalName: 'Курица',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'onion',
        name: 'Лук',
        canonicalName: 'Лук',
        synonyms: [],
        defaultUnit: Unit.pcs,
      ),
      ProductCatalogEntry(
        id: 'oats',
        name: 'Овсяные хлопья',
        canonicalName: 'Овсяные хлопья',
        synonyms: ['Овсянка'],
        defaultUnit: Unit.g,
      ),
      ProductCatalogEntry(
        id: 'sugar',
        name: 'Сахар',
        canonicalName: 'Сахар',
        synonyms: [],
        defaultUnit: Unit.g,
      ),
    ];

    final profile = buildTasteProfile(
      feedbackByRecipeId: const {},
      recipes: const [],
      catalog: catalog,
      interactionHistory: [
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: oldBreakfast,
          occurredAt: now.subtract(const Duration(days: 220)),
        ),
        RecipeInteractionEvent(
          type: RecipeInteractionType.recooked,
          recipeSnapshot: recentSoup,
          occurredAt: now.subtract(const Duration(days: 3)),
        ),
      ],
      referenceTime: now,
    );

    expect(
      profile.profilePreference(DishProfile.soup),
      greaterThan(profile.profilePreference(DishProfile.breakfast)),
    );
    expect(
      profile.ingredientPreference('курица'),
      greaterThan(profile.ingredientPreference('овсяные хлопья')),
    );
  });
}
