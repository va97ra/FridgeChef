import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import 'providers.dart';
import 'widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class CookIdeasScreen extends ConsumerWidget {
  const CookIdeasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(recipeMatchesProvider);
    final isLoading = ref.watch(recipesProvider).isLoading;

    return AppScaffold(
      title: 'Помоги приготовить',
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : matches.isEmpty
              ? const Center(
                  child: Text(
                    'Пока нет рецептов.\nДобавьте продукты в холодильник.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return RecipeCard(
                      match: match,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RecipeDetailScreen(recipe: match.recipe),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
