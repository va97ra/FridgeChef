import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/section_surface.dart';
import '../domain/taste_profile.dart';
import '../data/user_recipes_repo.dart';
import '../domain/recipe.dart';
import 'providers.dart';
import 'recipe_ui_meta.dart';
import 'save_generated_recipe_flow.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;
  final List<String> why;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.why = const [],
  });

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  static const _servingOptions = <int>[1, 2, 4, 6];
  late Recipe _recipe;
  int _targetServings = 2;
  final List<bool> _checkedSteps = [];

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _targetServings = _recipe.servingsBase;
    _checkedSteps.addAll(List.generate(_recipe.steps.length, (_) => false));
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _targetServings / _recipe.servingsBase;
    final moodBadges = buildRecipeMoodBadges(_recipe);
    final feedback = ref.watch(recipeFeedbackProvider)[_recipe.id];

    return AppScaffold(
      title: _recipe.title,
      actions: [
        if (_recipe.isUserEditable)
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: PopupMenuButton<_DetailRecipeAction>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: _handleRecipeAction,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _DetailRecipeAction.rename,
                  child: Text('Переименовать'),
                ),
                PopupMenuItem(
                  value: _DetailRecipeAction.delete,
                  child: Text('Удалить'),
                ),
              ],
            ),
          ),
      ],
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: AppTokens.p8),
          SectionSurface(
            tone: SectionSurfaceTone.primarySoft,
            padding: const EdgeInsets.all(AppTokens.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.timer_outlined,
                      label: '${_recipe.timeMin} мин',
                      color: AppTokens.primary,
                      background: AppTokens.surface,
                    ),
                    for (final badge in moodBadges.take(2))
                      _InfoPill(
                        icon: _iconForBadge(badge),
                        label: badge,
                        color: AppTokens.secondaryDark,
                        background: AppTokens.secondarySoft,
                      ),
                    if (_recipe.source == RecipeSource.generatedDraft)
                      _InfoPill(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Шеф-идея',
                        color: AppTokens.accent,
                        background: AppTokens.accentSoft,
                      ),
                    if (_recipe.source == RecipeSource.generatedSaved)
                      _InfoPill(
                        icon: Icons.bookmark_added_outlined,
                        label: 'Сохранён',
                        color: AppTokens.accent,
                        background: AppTokens.accentSoft,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.p20),
          SectionSurface(
            child: Row(
              children: [
                Text(
                  'Порции',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  children: _servingOptions.map((option) {
                    final selected = _targetServings == option;
                    return ChoiceChip(
                      label: Text('$option'),
                      selected: selected,
                      onSelected: (_) => setState(() => _targetServings = option),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.p20),
          _buildSectionTitle(context, 'О блюде'),
          const SizedBox(height: AppTokens.p12),
          _buildDescriptionCard(context),
          if (_recipe.source == RecipeSource.generatedDraft) ...[
            const SizedBox(height: AppTokens.p16),
            FilledButton.icon(
              onPressed: _saveGeneratedRecipe,
              icon: const Icon(Icons.bookmark_add_rounded),
              label: const Text('Сохранить в мои рецепты'),
            ),
          ],
          if (_recipe.anchorIngredients.isNotEmpty ||
              _recipe.implicitPantryItems.isNotEmpty ||
              (_recipe.chefProfile?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: AppTokens.p20),
            _buildSectionTitle(context, 'Что учёл шеф'),
            const SizedBox(height: AppTokens.p12),
            _buildChefContextCard(context),
          ],
          const SizedBox(height: AppTokens.p20),
          _buildSectionTitle(context, 'Оценка вкуса'),
          const SizedBox(height: AppTokens.p12),
          _buildFeedbackCard(context, feedback),
          if (widget.why.isNotEmpty) ...[
            const SizedBox(height: AppTokens.p20),
            _buildSectionTitle(context, 'Почему этот рецепт наверху'),
            const SizedBox(height: AppTokens.p12),
            _buildWhyCard(context),
          ],
          const SizedBox(height: AppTokens.p20),
          _buildSectionTitle(context, 'Ингредиенты'),
          const SizedBox(height: AppTokens.p12),
          _buildIngredients(context, ratio),
          const SizedBox(height: AppTokens.p20),
          _buildSectionTitle(context, 'Приготовление'),
          const SizedBox(height: AppTokens.p12),
          ...List.generate(_recipe.steps.length, (index) {
            return _buildStep(context, index);
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(
    BuildContext context,
    RecipeFeedbackVote? feedback,
  ) {
    return SectionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Учту это в следующих подборках.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTokens.textLight,
                ),
          ),
          const SizedBox(height: AppTokens.p12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeedbackChip(
                label: 'Не понравилось',
                icon: Icons.thumb_down_alt_outlined,
                selected: feedback == RecipeFeedbackVote.disliked,
                onTap: () => _setFeedback(RecipeFeedbackVote.disliked),
              ),
              _FeedbackChip(
                label: 'Без оценки',
                icon: Icons.remove_circle_outline_rounded,
                selected: feedback == null,
                onTap: () => _setFeedback(null),
              ),
              _FeedbackChip(
                label: 'Вкусно',
                icon: Icons.thumb_up_alt_outlined,
                selected: feedback == RecipeFeedbackVote.liked,
                onTap: () => _setFeedback(RecipeFeedbackVote.liked),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return SectionSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTokens.primarySoft,
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_outlined,
              color: AppTokens.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              (_recipe.description ?? 'Пошаговый офлайн-рецепт из твоих продуктов.').trim(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTokens.text,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyCard(BuildContext context) {
    return SectionSurface(
      tone: SectionSurfaceTone.accentSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.why.take(4).map((reason) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.p8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppTokens.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reason,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTokens.text,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChefContextCard(BuildContext context) {
    final rows = <Widget>[];
    final profileLabel = _chefProfileLabel(_recipe.chefProfile);
    if (profileLabel != null) {
      rows.add(_ChefContextRow(label: 'Формат', value: profileLabel));
    }
    if (_recipe.anchorIngredients.isNotEmpty) {
      rows.add(
        _ChefContextRow(
          label: 'В основе',
          value: _recipe.anchorIngredients.join(', '),
        ),
      );
    }
    if (_recipe.implicitPantryItems.isNotEmpty) {
      rows.add(
        _ChefContextRow(
          label: 'Базовые мелочи',
          value: _recipe.implicitPantryItems.join(', '),
        ),
      );
    }

    return SectionSurface(
      tone: SectionSurfaceTone.accentSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.p8),
                child: row,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildIngredients(BuildContext context, double ratio) {
    return SectionSurface(
      child: Column(
        children: _recipe.ingredients.asMap().entries.map((entry) {
          final idx = entry.key;
          final ing = entry.value;
          final amount = ing.amount * ratio;
          final isLast = idx == _recipe.ingredients.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTokens.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ing.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTokens.text,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Text(
                      '${_fmtNum(amount)} ${ing.unit.label}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTokens.text,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(color: AppTokens.border.withValues(alpha: 0.8)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStep(BuildContext context, int index) {
    final checked = _checkedSteps[index];
    final stepHint = buildStepHint(_recipe.steps[index]);

    return GestureDetector(
      onTap: () => setState(() => _checkedSteps[index] = !checked),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTokens.p12),
        child: SectionSurface(
          tone: checked ? SectionSurfaceTone.accentSoft : SectionSurfaceTone.base,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: checked ? AppTokens.successSoft : AppTokens.primarySoft,
                  borderRadius: BorderRadius.circular(AppTokens.pill),
                ),
                alignment: Alignment.center,
                child: checked
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: AppTokens.success,
                      )
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppTokens.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Шаг ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: checked ? AppTokens.textLight : AppTokens.text,
                            decoration: checked ? TextDecoration.lineThrough : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _recipe.steps[index],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: checked ? AppTokens.textLight : AppTokens.text,
                            decoration: checked ? TextDecoration.lineThrough : null,
                          ),
                    ),
                    if (stepHint != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: checked ? AppTokens.surface : AppTokens.secondarySoft,
                          borderRadius: BorderRadius.circular(AppTokens.r12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.tips_and_updates_rounded,
                              size: 14,
                              color: checked ? AppTokens.textLight : AppTokens.secondaryDark,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                stepHint,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: checked
                                          ? AppTokens.textLight
                                          : AppTokens.secondaryDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRecipeAction(_DetailRecipeAction action) async {
    if (action == _DetailRecipeAction.rename) {
      await _renameCurrentRecipe();
      return;
    }
    if (action == _DetailRecipeAction.delete) {
      await _deleteCurrentRecipe();
    }
  }

  Future<void> _renameCurrentRecipe() async {
    final controller = TextEditingController(text: _recipe.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Переименовать рецепт'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Новое название'),
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

    await ref.read(userRecipesRepoProvider).renameUserRecipe(
          _recipe.id,
          newTitle.trim(),
        );
    ref.invalidate(recipesProvider);
    if (!mounted) {
      return;
    }

    setState(() {
      _recipe = _recipe.copyWith(
        title: newTitle.trim(),
        updatedAt: DateTime.now(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Название обновлено')),
    );
  }

  Future<void> _deleteCurrentRecipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить рецепт?'),
          content: Text('Рецепт "${_recipe.title}" будет удалён.'),
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

    await ref.read(userRecipesRepoProvider).deleteUserRecipe(_recipe.id);
    ref.invalidate(recipesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Рецепт удалён')),
      );
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _saveGeneratedRecipe() async {
    if (_recipe.source != RecipeSource.generatedDraft) {
      return;
    }

    final result = await saveGeneratedRecipeWithDialog(
      context: context,
      ref: ref,
      recipe: _recipe,
    );
    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _recipe = result.recipe;
    });

    final message = switch (result.action) {
      SaveAction.updatedExisting => 'Рецепт обновлён в списке',
      SaveAction.createdCopy => 'Сохранена копия рецепта',
      SaveAction.created => 'Рецепт сохранён',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _setFeedback(RecipeFeedbackVote? vote) async {
    await ref.read(recipeFeedbackProvider.notifier).setVote(_recipe.id, vote);
    if (!mounted) {
      return;
    }
    final text = switch (vote) {
      RecipeFeedbackVote.liked => 'Учёл: рецепт понравился',
      RecipeFeedbackVote.disliked => 'Учёл: рецепт не понравился',
      null => 'Оценка рецепта очищена',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
    );
  }

  static String _fmtNum(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

String? _chefProfileLabel(String? raw) {
  switch (raw) {
    case 'skillet':
      return 'Сковорода';
    case 'soup':
      return 'Суп';
    case 'salad':
      return 'Салат';
    case 'bake':
      return 'Запекание';
    case 'pasta':
      return 'Паста';
    case 'grainBowl':
      return 'Зерновая миска';
    case 'breakfast':
      return 'Завтрак';
    case 'stew':
      return 'Рагу';
    case 'general':
      return 'Домашнее блюдо';
    default:
      return null;
  }
}

IconData _iconForBadge(String label) {
  switch (label) {
    case 'Завтрак':
      return Icons.wb_sunny_outlined;
    case 'Детям':
      return Icons.child_care_outlined;
    case 'Легко':
      return Icons.flash_on_outlined;
    case 'Сытно':
      return Icons.dinner_dining_outlined;
    case 'Ужин':
      return Icons.nightlight_outlined;
    case 'Одна сковорода':
      return Icons.lunch_dining_outlined;
    default:
      return Icons.label_outline_rounded;
  }
}

enum _DetailRecipeAction { rename, delete }

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FeedbackChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ChefContextRow extends StatelessWidget {
  final String label;
  final String value;

  const _ChefContextRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTokens.textLight,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTokens.text,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}
