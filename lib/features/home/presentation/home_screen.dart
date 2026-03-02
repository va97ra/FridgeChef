import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/animated_tile.dart';
import '../../../app/routes.dart';
import '../../ai_recipes/presentation/ai_generate_screen.dart';
import 'widgets/home_action_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Фон с градиентом
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppTokens.bgGradient),
          ),

          // Декоративный верхний блоб
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTokens.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Мелкий блоб снизу
          Positioned(
            bottom: 60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTokens.secondary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.p20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Hero-заголовок
                  _buildHeader(context),

                  const SizedBox(height: 40),

                  // Карточки-кнопки
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        AnimatedTile(
                          delay: const Duration(milliseconds: 80),
                          child: HomeActionButton(
                            title: 'Мой холодильник',
                            subtitle: 'Продукты, из которых будем готовить',
                            icon: Icons.kitchen_rounded,
                            gradient: AppTokens.fridgeGradient,
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.fridge),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedTile(
                          delay: const Duration(milliseconds: 180),
                          child: HomeActionButton(
                            title: 'Полка',
                            subtitle: 'Соль, перец, соусы и приправы',
                            icon: Icons.eco_rounded,
                            gradient: AppTokens.shelfGradient,
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.shelf),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedTile(
                          delay: const Duration(milliseconds: 280),
                          child: HomeActionButton(
                            title: 'Помоги приготовить',
                            subtitle: 'Подобрать рецепт по продуктам',
                            icon: Icons.restaurant_menu_rounded,
                            gradient: AppTokens.primaryGradient,
                            isPrimary: true,
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.cook),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedTile(
                          delay: const Duration(milliseconds: 380),
                          child: HomeActionButton(
                            title: 'AI-Рецепты ✨',
                            subtitle:
                                'Gemini придумает блюдо из твоих продуктов',
                            icon: Icons.auto_awesome_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            isPrimary: false,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AiGenerateScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Тег "приложение для готовки"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTokens.primary.withValues(alpha: 0.15),
                AppTokens.secondary.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTokens.r12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍳', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Умный холодильник',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Основной заголовок
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTokens.primaryGradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            'Помоги\nприготовить',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 40,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Добавь продукты и получи идеи\nдля вкусных блюд',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTokens.textLight,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}
