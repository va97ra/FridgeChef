import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../app/data/app_settings_repo.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_surface.dart';
import '../../fridge/presentation/providers.dart';
import '../../recipes/domain/recipe_match.dart';
import '../../recipes/presentation/providers.dart';
import '../../recipes/presentation/recipe_detail_screen.dart';
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
          const SizedBox(height: AppTokens.p16),
          _TodayCard(
            bestMatch: bestMatch,
            fridgeCount: fridgeItems.length,
            shelfCount: inStockShelf,
            onPrimaryAction: () {
              if (fridgeItems.isEmpty) {
                Navigator.pushNamed(context, AppRoutes.fridge);
                return;
              }
              if (bestMatch != null) {
                Navigator.push(
                  context,
                  AppRoutes.fadeThroughRoute(
                    page: RecipeDetailScreen(
                      recipe: bestMatch.recipe,
                      why: bestMatch.why,
                    ),
                  ),
                );
                return;
              }
              Navigator.pushNamed(context, AppRoutes.cook);
            },
          ),
          const SizedBox(height: AppTokens.p24),
          HomeActionButton(
            title: 'Мой холодильник',
            subtitle: fridgeItems.isEmpty
                ? 'Добавь продукты, чтобы начать подбор блюд'
                : '${fridgeItems.length} продуктов, $expiringSoon скоро использовать',
            icon: Icons.kitchen_outlined,
            accentColor: AppTokens.accent,
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
            metaLabel: bestMatch == null
                ? 'Оффлайн'
                : '${(bestMatch.score * 100).round()}%',
            isPrimary: true,
            semanticLabel: 'Открыть раздел Помоги приготовить. '
                '${bestMatch == null ? 'Оффлайн подбор' : '${(bestMatch.score * 100).round()} процентов совпадение'}. '
                '${bestMatch == null ? 'Подберём лучшее блюдо, когда дома появятся продукты' : 'Сейчас лучший вариант: ${bestMatch.recipe.title}'}',
            onTap: () => Navigator.pushNamed(context, AppRoutes.cook),
          ),
          const SizedBox(height: AppTokens.p24),
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
          child: Text(
            'Что готовим сегодня?',
            style: Theme.of(context).textTheme.displayLarge,
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

class _TodayCard extends StatelessWidget {
  final RecipeMatch? bestMatch;
  final int fridgeCount;
  final int shelfCount;
  final VoidCallback onPrimaryAction;

  const _TodayCard({
    required this.bestMatch,
    required this.fridgeCount,
    required this.shelfCount,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final readyToCook = bestMatch != null;
    final title = readyToCook
        ? 'Сейчас лучше всего: ${bestMatch!.recipe.title}'
        : fridgeCount == 0
            ? 'Сначала добавь продукты'
            : shelfCount == 0
                ? 'Добавь полку для более точных рецептов'
                : 'Можно перейти к подбору рецептов';
    final subtitle = readyToCook
        ? bestMatch!.why.take(2).join(' • ')
        : fridgeCount == 0
            ? 'Заполни холодильник хотя бы несколькими продуктами, и приложение сразу предложит лучший вариант.'
            : shelfCount == 0
                ? 'Специи, масла и соусы заметно повышают точность и вкус офлайн-рекомендаций.'
                : 'Холодильник уже заполнен. Открой подбор и посмотри лучший вариант из того, что есть дома.';

    return Semantics(
      container: true,
      label:
          '${readyToCook ? 'Сегодняшний выбор' : 'Следующий шаг'}. $title. $subtitle',
      child: SectionSurface(
        tone: readyToCook
            ? SectionSurfaceTone.primarySoft
            : SectionSurfaceTone.muted,
        padding: const EdgeInsets.all(AppTokens.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.p8,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: readyToCook
                    ? AppTokens.insetSurfaceStrong.withValues(alpha: 0.94)
                    : AppTokens.insetSurface,
                borderRadius: BorderRadius.circular(AppTokens.pill),
                border: Border.all(color: AppTokens.insetBorder),
              ),
              child: Text(
                readyToCook ? 'Сегодняшний выбор' : 'Следующий шаг',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          readyToCook ? AppTokens.primary : AppTokens.textLight,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: AppTokens.p12),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 22,
                  ),
            ),
            const SizedBox(height: AppTokens.p8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTokens.p16),
            Row(
              children: [
                if (readyToCook)
                  _InfoBox(
                    label: '${bestMatch!.recipe.timeMin} мин',
                    icon: Icons.timer_outlined,
                  ),
                if (readyToCook) const SizedBox(width: AppTokens.p8),
                _InfoBox(
                  label: readyToCook
                      ? '${(bestMatch!.score * 100).round()}% совпадение'
                      : '$fridgeCount продуктов добавлено',
                  icon: readyToCook
                      ? Icons.auto_awesome_outlined
                      : Icons.inventory_2_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.p16),
            PrimaryButton(
              text: readyToCook ? 'Открыть лучший рецепт' : 'Перейти дальше',
              onPressed: onPrimaryAction,
              icon: readyToCook
                  ? Icons.arrow_forward_rounded
                  : Icons.chevron_right_rounded,
            ),
          ],
        ),
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

class _InfoBox extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoBox({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.p12,
        vertical: AppTokens.p8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.insetSurface,
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: AppTokens.insetBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTokens.textLight),
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
