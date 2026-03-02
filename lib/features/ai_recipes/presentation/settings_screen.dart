import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../data/settings_repo.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _controller;
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyAsync = ref.watch(geminiApiKeyProvider);

    keyAsync.whenData((key) {
      if (_controller.text.isEmpty && key.isNotEmpty) {
        _controller.text = key;
      }
    });

    return AppScaffold(
      title: 'Настройки',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 8),

          // ── Заголовок секции ──────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.psychology_rounded,
            title: 'AI-генерация рецептов',
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),

          const SizedBox(height: 16),

          // ── Карточка с объяснением ────────────────────────────────────────
          _InfoCard(),

          const SizedBox(height: 20),

          // ── Поле API-ключа ────────────────────────────────────────────────
          Text(
            'Google Gemini API Key',
            style: TextStyle(
              color: AppTokens.text,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.r16),
              boxShadow: AppTokens.cardShadow,
            ),
            child: TextField(
              controller: _controller,
              obscureText: _obscure,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppTokens.text,
              ),
              decoration: InputDecoration(
                hintText: 'AIza...',
                hintStyle: const TextStyle(color: AppTokens.textLight),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTokens.textLight,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Кнопки ───────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Сохранить',
                  icon: Icons.check_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  glowColor: const Color(0xFF667EEA),
                  loading: _saving,
                  onTap: () async {
                    final key = _controller.text.trim();
                    if (key.isEmpty) {
                      _showSnack('Введи API-ключ', isError: true);
                      return;
                    }
                    setState(() => _saving = true);
                    await ref.read(geminiApiKeyProvider.notifier).save(key);
                    setState(() => _saving = false);
                    HapticFeedback.lightImpact();
                    if (mounted) {
                      _showSnack('API-ключ сохранён ✓');
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              _ClearButton(
                onTap: () async {
                  _controller.clear();
                  await ref.read(geminiApiKeyProvider.notifier).clear();
                  HapticFeedback.lightImpact();
                  if (mounted) _showSnack('Ключ удалён');
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Ссылка на получение ключа ─────────────────────────────────────
          _GetKeyHint(),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTokens.warn : const Color(0xFF667EEA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r12),
        ),
      ),
    );
  }
}

// ── Виджеты ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final LinearGradient gradient;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppTokens.r12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTokens.text,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667EEA).withValues(alpha: 0.12),
            const Color(0xFF764BA2).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(
          color: const Color(0xFF667EEA).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🤖 Как это работает?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI анализирует продукты в твоём холодильнике и специи на полке, '
            'затем придумывает уникальные рецепты специально для тебя.\n\n'
            'Используется Google Gemini — бесплатно до 1500 запросов в день.',
            style: TextStyle(
              color: AppTokens.textLight,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
    this.loading = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
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
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(AppTokens.r16),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ClearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppTokens.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTokens.r16),
          boxShadow: AppTokens.cardShadow,
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppTokens.warn,
          size: 22,
        ),
      ),
    );
  }
}

class _GetKeyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        boxShadow: AppTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔑 Где взять ключ?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Зайди на aistudio.google.com\n'
            '2. Нажми "Get API Key"\n'
            '3. Создай ключ и вставь сюда\n\n'
            'Бесплатный план: 1500 запросов / день',
            style: TextStyle(
              color: AppTokens.textLight,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
