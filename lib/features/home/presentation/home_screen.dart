import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../app/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Text(
            'Помоги\nприготовить 👨‍🍳',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  height: 1.2,
                  fontSize: 36,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавь продукты и получи идеи\nдля вкусных блюд!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTokens.textLight,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: ListView(
              children: [
                _HomeActionButton(
                  title: 'Мой холодильник',
                  subtitle: 'Продукты, из которых будем готовить',
                  icon: Icons.kitchen,
                  color: const Color(0xFF4ECDC4),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.fridge),
                ),
                const SizedBox(height: 16),
                _HomeActionButton(
                  title: 'Полка со специями',
                  subtitle: 'Соль, перец, соусы и приправы',
                  icon: Icons.eco,
                  color: const Color(0xFFFFB703),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.shelf),
                ),
                const SizedBox(height: 16),
                _HomeActionButton(
                  title: 'Помоги приготовить',
                  subtitle: 'Подобрать рецепт по продуктам',
                  icon: Icons.restaurant_menu,
                  color: AppTokens.primary,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.cook),
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HomeActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  State<_HomeActionButton> createState() => _HomeActionButtonState();
}

class _HomeActionButtonState extends State<_HomeActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: widget.isPrimary ? widget.color : AppTokens.surface,
            borderRadius: BorderRadius.circular(AppTokens.r24),
            boxShadow: [
              BoxShadow(
                color: widget.isPrimary
                    ? widget.color.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.p20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isPrimary
                        ? Colors.white.withOpacity(0.2)
                        : widget.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 32,
                    color: widget.isPrimary ? Colors.white : widget.color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: widget.isPrimary ? Colors.white : null,
                              fontSize: 20,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: widget.isPrimary
                                  ? Colors.white.withOpacity(0.8)
                                  : AppTokens.textLight,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: widget.isPrimary
                      ? Colors.white.withOpacity(0.5)
                      : AppTokens.textLight.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
