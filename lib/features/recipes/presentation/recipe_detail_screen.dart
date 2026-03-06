import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/units.dart';
import '../data/user_recipes_repo.dart';
import '../domain/recipe.dart';
import 'providers.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

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
    _checkedSteps
        .addAll(List.generate(_recipe.steps.length, (_) => false));
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _targetServings / _recipe.servingsBase;

    return Scaffold(
      backgroundColor: AppTokens.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(AppTokens.p20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Info badges
                _buildInfoBadges(context),
                const SizedBox(height: 28),

                // Порции
                _buildServingSelector(context),
                const SizedBox(height: 28),

                // Ингредиенты
                _buildSectionTitle(context, '🥘 Ингредиенты'),
                const SizedBox(height: 14),
                _buildIngredients(context, ratio),
                const SizedBox(height: 28),

                // Приготовление
                _buildSectionTitle(context, '👨‍🍳 Приготовление'),
                const SizedBox(height: 14),
                ...List.generate(_recipe.steps.length, (index) {
                  return _buildStep(context, index);
                }),
                const SizedBox(height: 60),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── SliverAppBar ────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: AppTokens.primary,
      leading: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 16),
        ),
      ),
      actions: [
        if (_recipe.source == RecipeSource.aiSaved)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTokens.r12),
              ),
              alignment: Alignment.center,
              child: const Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        if (_recipe.isUserEditable)
          PopupMenuButton<_DetailRecipeAction>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
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
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, right: 20, bottom: 16),
        title: Text(
          _recipe.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            shadows: [Shadow(color: Colors.black26, blurRadius: 6)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Основной градиент
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5A5A), Color(0xFFFF9A5C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Иконка блюда
            Center(
              child: Opacity(
                opacity: 0.20,
                child: const Text('🍽️', style: TextStyle(fontSize: 100)),
              ),
            ),
            // Декоративный кружок
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info badges ─────────────────────────────────────────────────────────────
  Widget _buildInfoBadges(BuildContext context) {
    return Row(
      children: [
        _InfoPill(
          icon: Icons.timer_rounded,
          label: '${_recipe.timeMin} мин',
          gradient: AppTokens.primaryGradient,
        ),
        if (_recipe.tags.isNotEmpty) ...[
          const SizedBox(width: 10),
          _InfoPill(
            icon: Icons.label_rounded,
            label: _recipe.tags.first,
            gradient: AppTokens.shelfGradient,
          ),
        ],
        if (_recipe.source == RecipeSource.aiSaved) ...[
          const SizedBox(width: 10),
          _InfoPill(
            icon: Icons.smart_toy_rounded,
            label: 'AI',
            gradient: AppTokens.primaryGradient,
          ),
        ],
      ],
    );
  }

  // ── Секция порций ───────────────────────────────────────────────────────────
  Widget _buildServingSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.p16, vertical: AppTokens.p16),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.r20),
        boxShadow: AppTokens.cardShadow,
      ),
      child: Row(
        children: [
          const Text(
            'Порции',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTokens.text,
            ),
          ),
          const Spacer(),
          Row(
            children: _servingOptions.map((option) {
              final selected = _targetServings == option;
              return GestureDetector(
                onTap: () => setState(() => _targetServings = option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(left: 8),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: selected ? AppTokens.primaryGradient : null,
                    color: selected ? null : AppTokens.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    boxShadow: selected ? AppTokens.primaryGlowShadow : null,
                  ),
                  child: Center(
                    child: Text(
                      '$option',
                      style: TextStyle(
                        color: selected ? Colors.white : AppTokens.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Ингредиенты ─────────────────────────────────────────────────────────────
  Widget _buildIngredients(BuildContext context, double ratio) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.p16),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.r20),
        boxShadow: AppTokens.cardShadow,
      ),
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
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTokens.primaryGradient,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ing.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.text,
                        ),
                      ),
                    ),
                    Text(
                      '${_fmtNum(amount)} ${ing.unit.label}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTokens.text,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: AppTokens.textLight.withValues(alpha: 0.12),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Шаг приготовления ───────────────────────────────────────────────────────
  Widget _buildStep(BuildContext context, int index) {
    final checked = _checkedSteps[index];
    return GestureDetector(
      onTap: () => setState(() => _checkedSteps[index] = !checked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(AppTokens.p16),
        decoration: BoxDecoration(
          color: checked
              ? AppTokens.accent.withValues(alpha: 0.08)
              : AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(
            color: checked
                ? AppTokens.accent.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
          boxShadow: checked ? null : AppTokens.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Номер шага
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: checked ? null : AppTokens.primaryGradient,
                color:
                    checked ? AppTokens.accent.withValues(alpha: 0.15) : null,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: checked
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: AppTokens.accent)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: checked ? AppTokens.textLight : AppTokens.text,
                      decoration: checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _recipe.steps[index],
                    style: TextStyle(
                      fontSize: 14,
                      color: checked ? AppTokens.textLight : AppTokens.text,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                      decoration: checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    await ref
        .read(userRecipesRepoProvider)
        .renameUserRecipe(_recipe.id, newTitle.trim());
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

enum _DetailRecipeAction { rename, delete }

// ── Info Pill ────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTokens.r20),
        boxShadow: [
          BoxShadow(
            color: (gradient is LinearGradient
                    ? (gradient as LinearGradient).colors.first
                    : Colors.grey)
                .withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
