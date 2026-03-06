import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../fridge/presentation/providers.dart';
import '../../recipes/data/user_recipes_repo.dart';
import '../../shelf/presentation/providers.dart';
import '../data/settings_repo.dart';
import '../domain/ai_generation_source.dart';
import '../domain/ai_recipe.dart';
import '../presentation/providers.dart';
import 'ai_save_recipe_flow.dart';
import 'ai_recipe_detail_screen.dart';
import 'settings_screen.dart';

class AiGenerateScreen extends ConsumerStatefulWidget {
  const AiGenerateScreen({super.key});

  @override
  ConsumerState<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends ConsumerState<AiGenerateScreen>
    with TickerProviderStateMixin {
  final _wishController = TextEditingController();
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _wishController.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(aiRecipesProvider);
    final iamTokenAsync = ref.watch(yandexIamTokenProvider);
    final folderIdAsync = ref.watch(yandexFolderIdProvider);
    final fridgeItems = ref.watch(fridgeListProvider);
    final shelfItems = ref.watch(shelfListProvider);

    final hasIamToken = iamTokenAsync.valueOrNull?.isNotEmpty == true;
    final hasFolderId = folderIdAsync.valueOrNull?.isNotEmpty == true;
    final hasConfig = hasIamToken && hasFolderId;
    final fridgeCount = fridgeItems.where((i) => i.amount > 0).length;
    final shelfCount = shelfItems.where((i) => i.inStock).length;

    return AppScaffold(
      title: 'AI-Рецепты',
      actions: [
        IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTokens.surface.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings_rounded,
              color: hasConfig ? const Color(0xFF667EEA) : AppTokens.warn,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        const SizedBox(width: 4),
      ],
      body: stateAsync.when(
        loading: () => _buildLoading(),
        error: (e, _) => _buildError(e.toString()),
        data: (state) {
          if (state.status == AiGenerationStatus.loading &&
              state.recipes.isEmpty) {
            return _buildLoading();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Заголовок с описанием ───────────────────────────────────
              _HeaderSection(
                fridgeCount: fridgeCount,
                shelfCount: shelfCount,
                hasApiKey: hasConfig,
              ),

              if (state.lastUpdatedAt != null || state.source != AiGenerationSource.none) ...[
                const SizedBox(height: 10),
                _GenerationMeta(
                  source: state.source,
                  lastUpdatedAt: state.lastUpdatedAt,
                ),
              ],

              if (state.isRefreshing && state.recipes.isNotEmpty) ...[
                const SizedBox(height: 10),
                const _RefreshingHint(),
              ],

              const SizedBox(height: 16),

              // ── Поле пожелания ──────────────────────────────────────────
              if (hasConfig) ...[
                _WishField(controller: _wishController),
                const SizedBox(height: 16),
              ],

              // ── Кнопка генерации ────────────────────────────────────────
              if (!hasConfig)
                _NoKeyBanner(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                )
              else if (fridgeCount == 0)
                _EmptyFridgeBanner()
              else
                PrimaryButton(
                  text: '✨ Обновить сейчас',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: () {
                    if (state.isRefreshing) {
                      return;
                    }
                    ref.read(aiRecipesProvider.notifier).generateNow(
                          isAuto: false,
                          extraWish: _wishController.text,
                        );
                  },
                ),

              const SizedBox(height: 20),

              // ── Результаты ──────────────────────────────────────────────
              if (state.errorMessage != null)
                _ErrorBanner(message: state.errorMessage ?? 'Ошибка'),

              if (state.recipes.isNotEmpty) ...[
                Text(
                  'Вот что можно приготовить',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.text,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.recipes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) => _AiRecipeCard(
                      recipe: state.recipes[i],
                      index: i,
                      onSave: () => _saveAiRecipe(state.recipes[i]),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AiRecipeDetailScreen(recipe: state.recipes[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else if (state.status == AiGenerationStatus.error) ...[
                const Spacer(),
                const Center(
                  child: Text(
                    'Не удалось подобрать рецепты',
                    style: TextStyle(
                      color: AppTokens.textLight,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
              ] else
                const Spacer(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Анимированный значок AI
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (context, child) {
              return Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    colors: const [
                      Color(0xFF667EEA),
                      Color(0xFF764BA2),
                      Color(0xFFFF5A5A),
                      Color(0xFF667EEA),
                    ],
                    startAngle: 0,
                    endAngle: 3.14 * 2,
                    transform: GradientRotation(
                      _shimmerCtrl.value * 3.14 * 2,
                    ),
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 36)),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'AI придумывает рецепты…',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Анализирую твои продукты',
            style: TextStyle(color: AppTokens.textLight, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😞', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Повторить',
            onPressed: () => ref
                .read(aiRecipesProvider.notifier)
                .generateNow(isAuto: false),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAiRecipe(AiRecipe recipe) async {
    final result = await saveAiRecipeWithDialog(
      context: context,
      ref: ref,
      aiRecipe: recipe,
    );
    if (!mounted || result == null) {
      return;
    }

    final message = switch (result.action) {
      SaveAction.updatedExisting => 'Рецепт обновлён в списке',
      SaveAction.createdCopy => 'Сохранена копия рецепта',
      SaveAction.created => 'Рецепт сохранён',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// ── Вспомогательные виджеты ───────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final int fridgeCount;
  final int shelfCount;
  final bool hasApiKey;

  const _HeaderSection({
    required this.fridgeCount,
    required this.shelfCount,
    required this.hasApiKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667EEA).withValues(alpha: 0.14),
            const Color(0xFF764BA2).withValues(alpha: 0.09),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(
          color: const Color(0xFF667EEA).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Рецепты от AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTokens.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasApiKey
                      ? 'Найдено: $fridgeCount продуктов, $shelfCount специй'
                      : 'Подключи YandexGPT в настройках',
                  style: const TextStyle(
                    color: AppTokens.textLight,
                    fontSize: 13,
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

class _GenerationMeta extends StatelessWidget {
  final AiGenerationSource source;
  final DateTime? lastUpdatedAt;

  const _GenerationMeta({
    required this.source,
    required this.lastUpdatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final ts = lastUpdatedAt == null
        ? '—'
        : DateFormat('dd.MM HH:mm').format(lastUpdatedAt!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTokens.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTokens.r12),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 16, color: AppTokens.textLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Источник: ${source.label} · Автообновлено: $ts',
              style: const TextStyle(
                color: AppTokens.textLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshingHint extends StatelessWidget {
  const _RefreshingHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTokens.r12),
        border: Border.all(color: const Color(0xFF667EEA).withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF667EEA),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Фоновое обновление рецептов...',
            style: TextStyle(
              color: AppTokens.textLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WishField extends StatelessWidget {
  final TextEditingController controller;
  const _WishField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 2,
      minLines: 1,
      decoration: InputDecoration(
        hintText: 'Пожелание (необязательно): "хочу что-то лёгкое и быстрое"',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 8),
          child: Text('💬', style: TextStyle(fontSize: 20)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

class _NoKeyBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _NoKeyBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTokens.warn.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(color: AppTokens.warn.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Text('🔑', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Нужен IAM токен YandexGPT',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTokens.warn,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Нажми, чтобы настроить — работает в РФ!',
                    style: TextStyle(
                      color: AppTokens.textLight,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppTokens.warn),
          ],
        ),
      ),
    );
  }
}

class _EmptyFridgeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTokens.r16),
      ),
      child: const Row(
        children: [
          Text('🧊', style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Холодильник пустой',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppTokens.text),
                ),
                SizedBox(height: 2),
                Text(
                  'Добавь продукты в холодильник, потом AI придумает рецепты',
                  style: TextStyle(color: AppTokens.textLight, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(maxHeight: 200), // Ограничиваем высоту
      decoration: BoxDecoration(
        color: AppTokens.warn.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.warn.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                message,
                style: const TextStyle(
                  color: AppTokens.warn,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Карточка AI-рецепта ───────────────────────────────────────────────────────

class _AiRecipeCard extends StatefulWidget {
  final AiRecipe recipe;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onSave;

  const _AiRecipeCard({
    required this.recipe,
    required this.index,
    required this.onTap,
    this.onSave,
  });

  @override
  State<_AiRecipeCard> createState() => _AiRecipeCardState();
}

class _AiRecipeCardState extends State<_AiRecipeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  static const _gradients = [
    LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFF5A5A), Color(0xFFFF9A5C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF06D6A0), Color(0xFF0097B2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  static const _emojis = ['🍳', '🥘', '🍲', '🥗', '🫕', '🍜'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[widget.index % _gradients.length];
    final emoji = _emojis[widget.index % _emojis.length];

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: AppTokens.surface,
            borderRadius: BorderRadius.circular(AppTokens.r20),
            boxShadow: AppTokens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Шапка с градиентом
              Container(
                height: 72,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTokens.r20),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.recipe.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.onSave != null) ...[
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: widget.onSave,
                            icon: const Icon(
                              Icons.bookmark_add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            tooltip: 'Сохранить в мои рецепты',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Мета-информация
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _MetaChip(
                          icon: Icons.timer_rounded,
                          label: '${widget.recipe.timeMin} мин',
                        ),
                        const SizedBox(width: 8),
                        _MetaChip(
                          icon: Icons.people_rounded,
                          label: '${widget.recipe.servings} порц.',
                        ),
                        const SizedBox(width: 8),
                        _MetaChip(
                          icon: Icons.list_rounded,
                          label: '${widget.recipe.steps.length} шагов',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Предпросмотр ингредиентов
                    Text(
                      widget.recipe.ingredients.take(3).join(' · ') +
                          (widget.recipe.ingredients.length > 3 ? ' …' : ''),
                      style: const TextStyle(
                        color: AppTokens.textLight,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTokens.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTokens.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTokens.textLight),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTokens.text,
            ),
          ),
        ],
      ),
    );
  }
}
