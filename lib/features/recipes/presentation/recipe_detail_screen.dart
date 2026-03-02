import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../domain/recipe.dart';
import '../../../core/utils/units.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _targetServings = 2; // Default for view
  final List<bool> _checkedSteps = [];

  @override
  void initState() {
    super.initState();
    _targetServings = widget.recipe.servingsBase;
    _checkedSteps
        .addAll(List.generate(widget.recipe.steps.length, (_) => false));
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _targetServings / widget.recipe.servingsBase;

    return AppScaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTokens.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.recipe.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTokens.primary, Color(0xFFFF8A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppTokens.p16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Info badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _InfoBadge(
                        icon: Icons.timer,
                        text: '${widget.recipe.timeMin} мин'),
                    if (widget.recipe.tags.isNotEmpty)
                      _InfoBadge(
                          icon: Icons.tag, text: widget.recipe.tags.first),
                  ],
                ),
                const SizedBox(height: 32),

                // Switcher Portions
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTokens.surface,
                    borderRadius: BorderRadius.circular(AppTokens.r16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Порции:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _targetServings > 1
                                ? () => setState(() => _targetServings--)
                                : null,
                          ),
                          Text(
                            '$_targetServings',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => _targetServings++),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Ingredients
                Text('Ингредиенты',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(AppTokens.p16),
                  decoration: BoxDecoration(
                    color: AppTokens.surface,
                    borderRadius: BorderRadius.circular(AppTokens.r16),
                  ),
                  child: Column(
                    children: widget.recipe.ingredients.map((ing) {
                      final calculatedAmount = ing.amount * ratio;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(ing.name,
                                    style: const TextStyle(fontSize: 16))),
                            Text(
                              '${calculatedAmount.toStringAsFixed(calculatedAmount.truncateToDouble() == calculatedAmount ? 0 : 1)} ${ing.unit.label}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 32),

                // Steps
                Text('Приготовление',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ...List.generate(widget.recipe.steps.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CheckboxListTile(
                      title: Text(
                        'Шаг ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: _checkedSteps[index]
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        widget.recipe.steps[index],
                        style: TextStyle(
                          decoration: _checkedSteps[index]
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      value: _checkedSteps[index],
                      onChanged: (val) {
                        setState(() {
                          _checkedSteps[index] = val ?? false;
                        });
                      },
                      activeColor: Colors.green,
                      contentPadding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                      ),
                      tileColor: AppTokens.surface,
                    ),
                  );
                }),

                const SizedBox(height: 48), // Bottom padding
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTokens.secondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTokens.r16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTokens.text),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
