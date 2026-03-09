import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_surface.dart';
import '../data/user_recipes_repo.dart';
import '../domain/cook_filter.dart';
import '../domain/recipe.dart';
import '../domain/recipe_interaction_event.dart';
import '../domain/recipe_match.dart';
import 'providers.dart';
import 'recipe_detail_screen.dart';
import 'widgets/rename_recipe_dialog.dart';
import 'widgets/match_bar.dart';
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
    final isLoading = ref.watch(recipesProvider).isLoading ||
        ref.watch(productCatalogProvider).isLoading ||
        ref.watch(pantryCatalogProvider).isLoading;
    final selectedFilters = ref.watch(cookFiltersProvider);
    final query = ref.watch(cookQueryProvider);
    final bestMatch = matches.isNotEmpty ? matches.first : null;
    final remainingMatches =
        matches.length > 1 ? matches.sublist(1) : const <RecipeMatch>[];
    final generatedMatches = matches
        .where((match) => match.source == RecipeMatchSource.generated)
        .toList();
    final displayedGeneratedMatches = remainingMatches
        .where((match) => match.source == RecipeMatchSource.generated)
        .toList();
    final recipeAlternatives = remainingMatches
        .where((match) => match.source != RecipeMatchSource.generated)
        .toList();

    return AppScaffold(
      title: 'Помоги приготовить',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTokens.p8),
          SectionSurface(
            tone: SectionSurfaceTone.base,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            ref.read(cookQueryProvider.notifier).state = value,
                        decoration: InputDecoration(
                          hintText: 'Поиск по рецептам',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(cookQueryProvider.notifier).state =
                                        '';
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.p12),
                    AppIconButton(
                      icon: Icons.refresh_rounded,
                      onPressed: () async {
                        await _refreshChefIdeas(generatedMatches);
                      },
                      tone: AppIconButtonTone.secondary,
                      tooltip: 'Пересобрать шеф-идеи',
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.p12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _FilterPill(
                        label: 'до 15 минут',
                        icon: Icons.timer_outlined,
                        selected:
                            selectedFilters.contains(CookFilter.upTo15Min),
                        onChanged: () => _toggleFilter(
                          ref,
                          selectedFilters,
                          CookFilter.upTo15Min,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: 'без духовки',
                        icon: Icons.outbox_outlined,
                        selected: selectedFilters.contains(CookFilter.noOven),
                        onChanged: () => _toggleFilter(
                          ref,
                          selectedFilters,
                          CookFilter.noOven,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: '1 сковорода',
                        icon: Icons.lunch_dining_outlined,
                        selected: selectedFilters.contains(CookFilter.onePan),
                        onChanged: () => _toggleFilter(
                          ref,
                          selectedFilters,
                          CookFilter.onePan,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.p16),
          Expanded(
            child: isLoading
                ? _buildLoading()
                : matches.isEmpty
                    ? _buildEmpty(hasQuery: query.trim().isNotEmpty)
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          if (bestMatch != null) ...[
                            _SectionHeader(
                              title: 'Лучшее блюдо сегодня',
                              subtitle:
                                  'Главный вариант из того, что уже есть дома',
                            ),
                            const SizedBox(height: 12),
                            _BestRecipeHero(
                              match: bestMatch,
                              onTap: () => _openRecipe(bestMatch),
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (generatedMatches.isNotEmpty) ...[
                            const _SectionHeader(
                              title: 'Шеф предлагает',
                              subtitle:
                                  'Новые офлайн-рецепты, собранные из твоих продуктов и полки',
                            ),
                            const SizedBox(height: 12),
                            if (displayedGeneratedMatches.isEmpty &&
                                bestMatch?.source ==
                                    RecipeMatchSource.generated) ...[
                              const _InlineInfoCard(
                                icon: Icons.lightbulb_outline_rounded,
                                title: 'Главная шеф-идея уже сверху',
                                subtitle:
                                    'Ниже останутся рецепты из базы, если захочется сравнить варианты.',
                              ),
                              const SizedBox(height: 20),
                            ] else ...[
                              ...displayedGeneratedMatches.map(
                                (match) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: RecipeCard(
                                    match: match,
                                    onTap: () => _openRecipe(match),
                                    onRename: match.recipe.isUserEditable
                                        ? () => _renameRecipe(match.recipe)
                                        : null,
                                    onDelete: match.recipe.isUserEditable
                                        ? () => _deleteRecipe(match.recipe)
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ],
                          if (recipeAlternatives.isNotEmpty) ...[
                            const _SectionHeader(
                              title: 'Другие хорошие варианты',
                              subtitle:
                                  'Альтернативы, если хочется другой вкус или формат',
                            ),
                            const SizedBox(height: 12),
                            ...recipeAlternatives.map(
                              (match) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: RecipeCard(
                                  match: match,
                                  onTap: () => _openRecipe(match),
                                  onRename: match.recipe.isUserEditable
                                      ? () => _renameRecipe(match.recipe)
                                      : null,
                                  onDelete: match.recipe.isUserEditable
                                      ? () => _deleteRecipe(match.recipe)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  void _openRecipe(RecipeMatch match) {
    Navigator.push(
      context,
      AppRoutes.fadeThroughRoute(
        page: RecipeDetailScreen(
          recipe: match.recipe,
          why: match.why,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmpty({required bool hasQuery}) {
    return Center(
      child: SectionSurface(
        tone: SectionSurfaceTone.muted,
        padding: const EdgeInsets.all(AppTokens.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTokens.accentSoft,
                borderRadius: BorderRadius.circular(AppTokens.r16),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: AppTokens.accent,
                size: 28,
              ),
            ),
            const SizedBox(height: AppTokens.p16),
            const Text(
              'Нет подходящих рецептов',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppTokens.text,
              ),
            ),
            const SizedBox(height: AppTokens.p8),
            Text(
              hasQuery
                  ? 'Смени запрос или убери фильтры.'
                  : 'Добавь продукты в холодильник и на полку, чтобы получить лучший офлайн-рейтинг.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTokens.textLight,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            if (!hasQuery) ...[
              const SizedBox(height: AppTokens.p16),
              PrimaryButton(
                text: 'Перейти в холодильник',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.fridge),
              ),
            ],
          ],
        ),
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
    final newTitle = await showRenameRecipeDialog(
      context,
      initialTitle: recipe.title,
    );

    if (newTitle == null || newTitle.trim().isEmpty) {
      return;
    }

    final updatedRecipe = recipe.copyWith(
      title: newTitle.trim(),
      updatedAt: DateTime.now(),
    );

    await ref
        .read(userRecipesRepoProvider)
        .renameUserRecipe(recipe.id, newTitle);
    await ref.read(recipeInteractionHistoryProvider.notifier).record(
          type: RecipeInteractionType.renamed,
          recipe: updatedRecipe,
        );
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
    await ref.read(recipeInteractionHistoryProvider.notifier).record(
          type: RecipeInteractionType.deleted,
          recipe: recipe,
        );
    ref.invalidate(recipesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Рецепт удалён')),
      );
    }
  }

  Future<void> _refreshChefIdeas(List<RecipeMatch> generatedMatches) async {
    final ignoredRecipes = generatedMatches
        .take(3)
        .map((match) => match.recipe)
        .toList(growable: false);
    if (ignoredRecipes.isNotEmpty) {
      await ref.read(recipeInteractionHistoryProvider.notifier).recordMany(
            type: RecipeInteractionType.ignored,
            recipes: ignoredRecipes,
          );
    }

    final notifier = ref.read(chefGenerationSeedProvider.notifier);
    notifier.state = notifier.state + 1;
  }
}

class _InlineInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InlineInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SectionSurface(
      tone: SectionSurfaceTone.accentSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppTokens.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTokens.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTokens.textLight,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BestRecipeHero extends StatelessWidget {
  final RecipeMatch match;
  final VoidCallback onTap;

  const _BestRecipeHero({
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final confidence = (match.score * 100).round().clamp(0, 100);

    return Semantics(
      button: true,
      label: 'Открыть лучший рецепт ${match.recipe.title}. '
          '${match.recipe.timeMin} минут. '
          '$confidence процентов совпадение. '
          'Совпадение ${match.matchedCount} из ${match.totalCount}.',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.r24),
          child: SectionSurface(
            tone: SectionSurfaceTone.primarySoft,
            padding: const EdgeInsets.all(AppTokens.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SourceBadge(match: match),
                          const SizedBox(height: 10),
                          Text(
                            match.recipe.title,
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  fontSize: 26,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.restaurant_menu_rounded,
                      color: AppTokens.primary,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.p16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroInfoPill(
                      icon: Icons.timer_outlined,
                      label: '${match.recipe.timeMin} мин',
                    ),
                    _HeroInfoPill(
                      icon: Icons.auto_awesome_outlined,
                      label: '$confidence%',
                    ),
                    _HeroInfoPill(
                      icon: Icons.checklist_rounded,
                      label: '${match.matchedCount}/${match.totalCount}',
                    ),
                  ],
                ),
                if (match.why.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.p16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: match.why.take(3).map((reason) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.p12,
                          vertical: AppTokens.p8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTokens.insetSurface,
                          borderRadius: BorderRadius.circular(
                            AppTokens.pill,
                          ),
                          border: Border.all(color: AppTokens.insetBorder),
                        ),
                        child: Text(
                          reason,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTokens.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: AppTokens.p16),
                Row(
                  children: [
                    Expanded(child: MatchBar(score: match.score)),
                    const SizedBox(width: AppTokens.p12),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppTokens.textLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTokens.textLight,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _HeroInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroInfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTokens.insetSurface,
        borderRadius: BorderRadius.circular(AppTokens.pill),
        border: Border.all(color: AppTokens.insetBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTokens.textLight, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.text,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final RecipeMatch match;

  const _SourceBadge({required this.match});

  @override
  Widget build(BuildContext context) {
    final isIdea = match.source == RecipeMatchSource.generated;
    final isSaved = match.recipe.source == RecipeSource.generatedSaved;
    final label = isIdea
        ? 'Шеф-идея'
        : isSaved
            ? 'Сохранён'
            : 'База';
    final background = isIdea
        ? AppTokens.accentSoft
        : isSaved
            ? AppTokens.secondarySoft
            : AppTokens.insetSurface;
    final color = isIdea
        ? AppTokens.accent
        : isSaved
            ? AppTokens.secondaryDark
            : AppTokens.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.pill),
        border: Border.all(color: AppTokens.insetBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

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
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTokens.primarySoft : AppTokens.insetSurface,
          borderRadius: BorderRadius.circular(AppTokens.pill),
          border: Border.all(
            color: selected ? AppTokens.primaryLight : AppTokens.insetBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppTokens.primary : AppTokens.textLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? AppTokens.primary : AppTokens.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
