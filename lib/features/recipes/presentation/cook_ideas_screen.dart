import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/user_recipes_repo.dart';
import '../domain/recipe.dart';
import '../domain/recipe_matcher.dart';
import 'providers.dart';
import 'recipe_detail_screen.dart';
import 'widgets/recipe_card.dart';

class CookIdeasScreen extends ConsumerStatefulWidget {
  const CookIdeasScreen({super.key});

  @override
  ConsumerState<CookIdeasScreen> createState() => _CookIdeasScreenState();
}

class _CookIdeasScreenState extends ConsumerState<CookIdeasScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(recipeMatchesProvider);
    final isLoading = ref.watch(recipesProvider).isLoading;
    final selectedFilters = ref.watch(cookFiltersProvider);
    final query = ref.watch(cookQueryProvider);

    return AppScaffold(
      title: 'Помоги приготовить',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Кнопка «Подобрать»
          PrimaryButton(
            text: 'Подобрать',
            icon: Icons.auto_awesome_rounded,
            onPressed: () => ref.invalidate(recipeMatchesProvider),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _searchController,
            onChanged: (value) =>
                ref.read(cookQueryProvider.notifier).state = value,
            decoration: InputDecoration(
              hintText: 'Поиск по рецептам',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(cookQueryProvider.notifier).state = '';
                      },
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Фильтр-чипсы
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _FilterPill(
                  label: 'до 15 минут',
                  icon: Icons.timer_outlined,
                  selected: selectedFilters.contains(CookFilter.upTo15Min),
                  onChanged: () =>
                      _toggleFilter(ref, selectedFilters, CookFilter.upTo15Min),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'без духовки',
                  icon: Icons.no_food_outlined,
                  selected: selectedFilters.contains(CookFilter.noOven),
                  onChanged: () =>
                      _toggleFilter(ref, selectedFilters, CookFilter.noOven),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: '1 сковорода',
                  icon: Icons.lunch_dining_outlined,
                  selected: selectedFilters.contains(CookFilter.onePan),
                  onChanged: () =>
                      _toggleFilter(ref, selectedFilters, CookFilter.onePan),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Список рецептов
          Expanded(
            child: isLoading
                ? _buildLoading()
                : matches.isEmpty
                    ? _buildEmpty(hasQuery: query.trim().isNotEmpty)
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: matches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          return RecipeCard(
                            match: match,
                            onTap: () {
                              Navigator.push(
                                context,
                                AppRoutes.fadeThroughRoute(
                                  page:
                                      RecipeDetailScreen(recipe: match.recipe),
                                ),
                              );
                            },
                            onRename: match.recipe.isUserEditable
                                ? () => _renameRecipe(match.recipe)
                                : null,
                            onDelete: match.recipe.isUserEditable
                                ? () => _deleteRecipe(match.recipe)
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppTokens.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppTokens.primaryGlowShadow,
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Подбираем рецепты…',
            style: TextStyle(
              color: AppTokens.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty({required bool hasQuery}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppTokens.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🥗', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет подходящих рецептов',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasQuery
                ? 'Смени запрос или убери фильтры'
                : 'Попробуй убрать фильтры\nили добавь продукты в холодильник',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTokens.textLight, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _toggleFilter(
    WidgetRef ref,
    Set<CookFilter> selectedFilters,
    CookFilter filter,
  ) {
    final updated = {...selectedFilters};
    if (updated.contains(filter)) {
      updated.remove(filter);
    } else {
      updated.add(filter);
    }
    ref.read(cookFiltersProvider.notifier).state = updated;
  }

  Future<void> _renameRecipe(Recipe recipe) async {
    final controller = TextEditingController(text: recipe.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Переименовать рецепт'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Новое название',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (newTitle == null || newTitle.trim().isEmpty) {
      return;
    }

    await ref.read(userRecipesRepoProvider).renameUserRecipe(recipe.id, newTitle);
    ref.invalidate(recipesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Название обновлено')),
      );
    }
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить рецепт?'),
          content: Text('Рецепт "${recipe.title}" будет удалён.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(userRecipesRepoProvider).deleteUserRecipe(recipe.id);
    ref.invalidate(recipesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Рецепт удалён')),
      );
    }
  }
}

// ── Кастомный pill-фильтр ──────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onChanged;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppTokens.primaryGradient : null,
          color: selected ? null : AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.r20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppTokens.textLight.withValues(alpha: 0.25),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTokens.primary.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppTokens.textLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTokens.text,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
