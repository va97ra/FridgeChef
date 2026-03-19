import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../app/data/app_settings_repo.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../fridge/presentation/providers.dart';
import '../../recipes/domain/recipe_match.dart';
import '../../recipes/presentation/providers.dart';
import '../../shelf/presentation/providers.dart';
import 'widgets/home_action_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _onboardingChecked = false;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final fridgeItems = ref.watch(fridgeListProvider);
    final shelfItems = ref.watch(shelfListProvider);
    final matches = ref.watch(recipeMatchesProvider);
    final bestMatch = matches.isNotEmpty ? matches.first : null;
    final inStockShelf = shelfItems.where((item) => item.inStock).length;
    final expiringSoon = fridgeItems.where((item) {
      if (item.expiresAt == null) {
        return false;
      }
      final now = DateTime.now();
      final base = DateTime(now.year, now.month, now.day);
      final expiry = DateTime(
        item.expiresAt!.year,
        item.expiresAt!.month,
        item.expiresAt!.day,
      );
      return expiry.difference(base).inDays <= 3;
    }).length;

    if (!_onboardingChecked && fridgeItems.isEmpty && shelfItems.isEmpty) {
      _onboardingChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowOnboarding();
      });
    }

    return AppScaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: AppTokens.p8),
          _Header(
            onOpenSettings: () => Navigator.pushNamed(
              context,
              AppRoutes.settings,
            ),
          ),
          const SizedBox(height: AppTokens.p12),
          _KitchenStatusStrip(
            fridgeCount: fridgeItems.length,
            shelfCount: inStockShelf,
            expiringSoon: expiringSoon,
            bestMatch: bestMatch,
          ),
          const SizedBox(height: AppTokens.p20),
          HomeActionButton(
            title: 'Мой холодильник',
            subtitle: fridgeItems.isEmpty
                ? 'Добавь продукты, чтобы начать подбор блюд'
                : '${fridgeItems.length} продуктов, $expiringSoon скоро использовать',
            icon: Icons.kitchen_outlined,
            accentColor: AppTokens.accent,
            gradient: AppTokens.fridgeGradient,
            metaLabel: fridgeItems.isEmpty ? 'Пусто' : '${fridgeItems.length}',
            semanticLabel: 'Открыть раздел Мой холодильник. '
                '${fridgeItems.isEmpty ? 'Пусто' : '${fridgeItems.length} продуктов'}. '
                '${fridgeItems.isEmpty ? 'Добавь продукты, чтобы начать подбор блюд' : '$expiringSoon скоро использовать'}',
            onTap: () => Navigator.pushNamed(context, AppRoutes.fridge),
          ),
          const SizedBox(height: AppTokens.p12),
          HomeActionButton(
            title: 'Полка',
            subtitle: inStockShelf == 0
                ? 'Добавь специи, масла и соусы для точных рецептов'
                : '$inStockShelf позиций в наличии для усиления вкуса',
            icon: Icons.spa_outlined,
            accentColor: AppTokens.secondaryDark,
            gradient: AppTokens.shelfGradient,
            metaLabel: inStockShelf == 0 ? 'Нужно' : '$inStockShelf',
            semanticLabel: 'Открыть раздел Полка. '
                '${inStockShelf == 0 ? 'Нужно' : '$inStockShelf позиций'}. '
                '${inStockShelf == 0 ? 'Добавь специи, масла и соусы для точных рецептов' : '$inStockShelf позиций в наличии для усиления вкуса'}',
            onTap: () => Navigator.pushNamed(context, AppRoutes.shelf),
          ),
          const SizedBox(height: AppTokens.p12),
          HomeActionButton(
            title: 'Помоги приготовить',
            subtitle: bestMatch == null
                ? 'Подберём лучшее блюдо, когда дома появятся продукты'
                : 'Сейчас лучший вариант: ${bestMatch.recipe.title}',
            icon: Icons.restaurant_menu_rounded,
            accentColor: AppTokens.primary,
            gradient: AppTokens.primaryGradient,
            metaLabel: bestMatch == null
                ? 'Оффлайн'
                : '${(bestMatch.score * 100).round()}%',
            isPrimary: true,
            semanticLabel: 'Открыть раздел Помоги приготовить. '
                '${bestMatch == null ? 'Оффлайн подбор' : '${(bestMatch.score * 100).round()} процентов совпадение'}. '
                '${bestMatch == null ? 'Подберём лучшее блюдо, когда дома появятся продукты' : 'Сейчас лучший вариант: ${bestMatch.recipe.title}'}',
            onTap: () => Navigator.pushNamed(context, AppRoutes.cook),
          ),
          const SizedBox(height: AppTokens.p20),
        ],
      ),
    );
  }

  Future<void> _maybeShowOnboarding() async {
    final settingsRepo = ref.read(appSettingsRepoProvider);
    final isDone = await settingsRepo.isOnboardingDone();
    if (!mounted || isDone) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.p20,
              AppTokens.p20,
              AppTokens.p20,
              AppTokens.p24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'С чего начать',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 24,
                      ),
                ),
                const SizedBox(height: AppTokens.p12),
                const _OnboardingStep(
                  index: 1,
                  text: 'Добавь продукты в холодильник',
                ),
                const SizedBox(height: AppTokens.p8),
                const _OnboardingStep(
                  index: 2,
                  text: 'Заполни полку специями, маслами и соусами',
                ),
                const SizedBox(height: AppTokens.p8),
                const _OnboardingStep(
                  index: 3,
                  text: 'Открой “Помоги приготовить” и посмотри лучший вариант',
                ),
                const SizedBox(height: AppTokens.p20),
                PrimaryButton(
                  text: 'Понятно',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );

    await settingsRepo.setOnboardingDone(true);
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _Header({
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Что готовим сегодня?',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: AppTokens.p8),
              Text(
                'Офлайн-шеф собирает лучший вариант из того, что уже есть дома.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTokens.textLight,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTokens.p12),
        AppIconButton(
          icon: Icons.settings_outlined,
          onPressed: onOpenSettings,
          tooltip: 'Настройки',
        ),
      ],
    );
  }
}

class _KitchenStatusStrip extends StatelessWidget {
  final int fridgeCount;
  final int shelfCount;
  final int expiringSoon;
  final RecipeMatch? bestMatch;

  const _KitchenStatusStrip({
    required this.fridgeCount,
    required this.shelfCount,
    required this.expiringSoon,
    required this.bestMatch,
  });

  @override
  Widget build(BuildContext context) {
    final matchPercent =
        bestMatch == null ? 'Оффлайн' : '${(bestMatch!.score * 100).round()}%';

    return Row(
      children: [
        Expanded(
          child: _StatusTile(
            icon: Icons.kitchen_outlined,
            title: 'Холодильник',
            value: '$fridgeCount',
            hint: expiringSoon > 0 ? '$expiringSoon скоро' : 'спокоен',
            accent: AppTokens.accent,
          ),
        ),
        const SizedBox(width: AppTokens.p8),
        Expanded(
          child: _StatusTile(
            icon: Icons.spa_outlined,
            title: 'Полка',
            value: '$shelfCount',
            hint: shelfCount == 0 ? 'пора заполнить' : 'усиливает вкус',
            accent: AppTokens.secondaryDark,
          ),
        ),
        const SizedBox(width: AppTokens.p8),
        Expanded(
          child: _StatusTile(
            icon: Icons.auto_awesome_rounded,
            title: 'Шеф',
            value: matchPercent,
            hint: bestMatch == null ? 'ждёт продукты' : 'лучший вариант',
            accent: AppTokens.primary,
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String hint;
  final Color accent;

  const _StatusTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.hint,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.p12,
        AppTokens.p12,
        AppTokens.p12,
        AppTokens.p12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: AppTokens.border.withValues(alpha: 0.9)),
        boxShadow: AppTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTokens.r12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: AppTokens.p8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.textLight,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  final int index;
  final String text;

  const _OnboardingStep({
    required this.index,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTokens.primarySoft,
            borderRadius: BorderRadius.circular(AppTokens.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: const TextStyle(
              color: AppTokens.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppTokens.p12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTokens.text,
                ),
          ),
        ),
      ],
    );
  }
}
