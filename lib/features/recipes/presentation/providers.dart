import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/recipe.dart';
import '../domain/recipe_match.dart';
import '../data/recipes_loader.dart';
import '../../fridge/presentation/providers.dart';
import '../../shelf/presentation/providers.dart';
import '../../fridge/domain/fridge_item.dart';
import '../../shelf/domain/shelf_item.dart';

final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  return await RecipesLoader.loadRecipes();
});

final recipeMatchesProvider = Provider<List<RecipeMatch>>((ref) {
  final recipesAsync = ref.watch(recipesProvider);
  final fridgeItems = ref.watch(fridgeListProvider);
  final shelfItems =
      ref.watch(shelfListProvider).where((e) => e.inStock).toList();

  return recipesAsync.maybeWhen(
    data: (recipes) {
      if (recipes.isEmpty) return [];

      final availableMap = <String, double>{};

      // Добавляем из холодильника
      for (var item in fridgeItems) {
        final key = item.name.toLowerCase();
        availableMap[key] = (availableMap[key] ?? 0) + item.amount;
      }

      // Добавляем с полки (считаем, что полка дает "бесконечное" количество)
      for (var item in shelfItems) {
        availableMap[item.name.toLowerCase()] = 999999.0;
      }

      final matches = <RecipeMatch>[];

      for (var recipe in recipes) {
        int matchedReq = 0;
        int reqCount = 0;
        int matchedOpt = 0;
        int optCount = 0;

        List<RecipeIngredient> missing = [];

        for (var ing in recipe.ingredients) {
          final key = ing.name.toLowerCase();
          final hasAmount = availableMap[key] ?? 0.0;

          bool isMatched = false;
          // Для простоты MVP сопоставляем только по имени
          // (без строгой конвертации g -> kg, если единицы разные)
          // В реальности тут нужна таблица конвертации (units.dart может помочь)
          if (hasAmount > 0 && hasAmount >= ing.amount * 0.8) {
            // Считаем, что есть (допускаем -20% нехватки)
            isMatched = true;
          }

          if (ing.required) {
            reqCount++;
            if (isMatched) {
              matchedReq++;
            } else {
              missing.add(ing);
            }
          } else {
            optCount++;
            if (isMatched) {
              matchedOpt++;
            }
          }
        }

        // Подсчет score (как указано в ТЗ)
        double reqMatchScore = reqCount > 0 ? (matchedReq / reqCount) : 1.0;
        double optMatchScore = optCount > 0 ? (matchedOpt / optCount) : 1.0;

        double score = 0.75 * reqMatchScore + 0.25 * optMatchScore;
        if (reqMatchScore == 1.0) {
          score += 0.05;
        }

        matches.add(RecipeMatch(
          recipe: recipe,
          score: score.clamp(0.0, 1.0),
          missingIngredients: missing,
          matchedCount: matchedReq + matchedOpt,
          totalCount: reqCount + optCount,
        ));
      }

      // Сортировка по score desc, timeMin asc
      matches.sort((a, b) {
        int cmp = b.score.compareTo(a.score);
        if (cmp != 0) return cmp;
        return a.recipe.timeMin.compareTo(b.recipe.timeMin);
      });

      return matches;
    },
    orElse: () => [],
  );
});
