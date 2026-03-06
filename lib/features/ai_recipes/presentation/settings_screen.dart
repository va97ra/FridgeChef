import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../fridge/data/qwen_api_repo.dart';
import '../data/settings_repo.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _iamTokenController;
  late final TextEditingController _folderIdController;
  late final TextEditingController _qwenApiKeyController;
  late final TextEditingController _qwenVisionUrlController;
  late final TextEditingController _qwenModelController;
  bool _obscureToken = true;
  bool _obscureQwenApiKey = true;
  bool _saving = false;
  bool _qwenSavingConfig = false;

  @override
  void initState() {
    super.initState();
    _iamTokenController = TextEditingController();
    _folderIdController = TextEditingController();
    _qwenApiKeyController = TextEditingController();
    _qwenVisionUrlController = TextEditingController();
    _qwenModelController = TextEditingController();
  }

  @override
  void dispose() {
    _iamTokenController.dispose();
    _folderIdController.dispose();
    _qwenApiKeyController.dispose();
    _qwenVisionUrlController.dispose();
    _qwenModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iamTokenAsync = ref.watch(yandexIamTokenProvider);
    final folderIdAsync = ref.watch(yandexFolderIdProvider);
    final qwenConnectedAsync = ref.watch(qwenApiConnectionProvider);
    final qwenConfigAsync = ref.watch(qwenApiConfigProvider);

    iamTokenAsync.whenData((token) {
      if (_iamTokenController.text.isEmpty && token.isNotEmpty) {
        _iamTokenController.text = token;
      }
    });

    folderIdAsync.whenData((folderId) {
      if (_folderIdController.text.isEmpty && folderId.isNotEmpty) {
        _folderIdController.text = folderId;
      }
    });

    qwenConfigAsync.whenData((config) {
      if (_qwenApiKeyController.text.isEmpty && config.apiKey.isNotEmpty) {
        _qwenApiKeyController.text = config.apiKey;
      }
      if (_qwenVisionUrlController.text.isEmpty) {
        _qwenVisionUrlController.text = config.visionUrl;
      }
      if (_qwenModelController.text.isEmpty) {
        _qwenModelController.text = config.model;
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
            title: 'AI-настройки',
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTokens.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppTokens.r12),
              border: Border.all(
                color: AppTokens.primary.withValues(alpha: 0.15),
              ),
            ),
            child: const Text(
              'Рецепты генерируются через YandexGPT, а распознавание продуктов по фото работает через Qwen API.',
              style: TextStyle(
                color: AppTokens.text,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Карточка с объяснением ────────────────────────────────────────
          _InfoCard(),

          const SizedBox(height: 20),

          // ── Поле IAM токена ────────────────────────────────────────────────
          Text(
            'YandexGPT IAM токен (для рецептов)',
            style: TextStyle(
              color: AppTokens.text,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: AppTokens.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTokens.r12),
              border: Border.all(
                color: AppTokens.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _iamTokenController,
              obscureText: _obscureToken,
              style: const TextStyle(color: AppTokens.text),
              decoration: InputDecoration(
                hintText: 'Вставь IAM токен из Яндекс Облака',
                hintStyle: TextStyle(color: AppTokens.textLight),
                prefixIcon:
                    const Icon(Icons.key_rounded, color: Color(0xFF667EEA)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureToken
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: AppTokens.textLight,
                  ),
                  onPressed: () =>
                      setState(() => _obscureToken = !_obscureToken),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Поле Folder ID ────────────────────────────────────────────────
          Text(
            'Yandex Cloud Folder ID (для рецептов)',
            style: TextStyle(
              color: AppTokens.text,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: AppTokens.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTokens.r12),
              border: Border.all(
                color: AppTokens.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _folderIdController,
              style: const TextStyle(color: AppTokens.text),
              decoration: InputDecoration(
                hintText: 'b1gxxxxxxxxxxxxxxxxxx',
                hintStyle: TextStyle(color: AppTokens.textLight),
                prefixIcon:
                    const Icon(Icons.cloud_rounded, color: Color(0xFF667EEA)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Qwen API (для фото-распознавания продуктов)',
            style: TextStyle(
              color: AppTokens.text,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.r12),
              border: Border.all(
                color: AppTokens.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Статус: ',
                      style: TextStyle(
                        color: AppTokens.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    qwenConnectedAsync.when(
                      data: (connected) => Text(
                        connected ? 'Подключено' : 'Не подключено',
                        style: TextStyle(
                          color: connected ? AppTokens.accent : AppTokens.warn,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      loading: () => const Text('Проверка...'),
                      error: (_, __) => const Text('Ошибка'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _AdvancedField(
                  controller: _qwenApiKeyController,
                  label: 'API Key',
                  obscureText: _obscureQwenApiKey,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureQwenApiKey
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 18,
                      color: AppTokens.textLight,
                    ),
                    onPressed: () {
                      setState(() => _obscureQwenApiKey = !_obscureQwenApiKey);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _AdvancedField(
                  controller: _qwenVisionUrlController,
                  label: 'Vision URL',
                ),
                const SizedBox(height: 8),
                _AdvancedField(
                  controller: _qwenModelController,
                  label: 'Model',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _qwenSavingConfig
                            ? null
                            : () => _saveQwenConfig(context),
                        icon: _qwenSavingConfig
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text('Сохранить Qwen'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _qwenSavingConfig
                            ? null
                            : () => _clearQwenApiKey(context),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Очистить ключ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Кнопки ────────────────────────────────────────────────────────
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
                    final iamToken = _iamTokenController.text.trim();
                    final folderId = _folderIdController.text.trim();

                    if (iamToken.isEmpty) {
                      _showSnack('Введи IAM токен YandexGPT', isError: true);
                      return;
                    }
                    if (folderId.isEmpty) {
                      _showSnack('Введи Folder ID Yandex Cloud', isError: true);
                      return;
                    }

                    setState(() => _saving = true);
                    await ref
                        .read(yandexIamTokenProvider.notifier)
                        .save(iamToken);
                    await ref
                        .read(yandexFolderIdProvider.notifier)
                        .save(folderId);
                    setState(() => _saving = false);
                    HapticFeedback.lightImpact();
                    if (mounted) {
                      _showSnack('Настройки YandexGPT сохранены ✓');
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              _ClearButton(
                onTap: () async {
                  _iamTokenController.clear();
                  _folderIdController.clear();
                  await ref.read(yandexIamTokenProvider.notifier).clear();
                  await ref.read(yandexFolderIdProvider.notifier).clear();
                  HapticFeedback.lightImpact();
                  if (mounted) _showSnack('Настройки YandexGPT сброшены');
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Ссылка на получение токена ─────────────────────────────────────
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

  Future<void> _saveQwenConfig(BuildContext context) async {
    final config = QwenApiConfig(
      apiKey: _qwenApiKeyController.text.trim(),
      visionUrl: _qwenVisionUrlController.text.trim(),
      model: _qwenModelController.text.trim(),
    );

    setState(() => _qwenSavingConfig = true);
    try {
      await ref.read(qwenApiConfigProvider.notifier).save(config);
      ref.invalidate(qwenApiConnectionProvider);
      if (mounted) {
        _showSnack('Qwen API настройки сохранены');
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _qwenSavingConfig = false);
      }
    }
  }

  Future<void> _clearQwenApiKey(BuildContext context) async {
    await ref.read(qwenApiRepoProvider).clear();
    _qwenApiKeyController.clear();
    ref.invalidate(qwenApiConnectionProvider);
    if (mounted) {
      _showSnack('Qwen API key очищен');
    }
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
            color: Colors.white,
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
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(
          color: AppTokens.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppTokens.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Как подключить YandexGPT для рецептов',
                style: TextStyle(
                  color: AppTokens.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StepRow(
            num: 1,
            text: 'Зайди на cloud.yandex.ru',
          ),
          const SizedBox(height: 8),
          _StepRow(
            num: 2,
            text: 'Создай облако или выбери существующее',
          ),
          const SizedBox(height: 8),
          _StepRow(
            num: 3,
            text: 'Получи IAM токен в разделе "Сервисные аккаунты"',
          ),
          const SizedBox(height: 8),
          _StepRow(
            num: 4,
            text: 'Скопируй Folder ID своего облака',
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // Можно открыть ссылку в браузере
            },
            child: Text(
              '📖 Подробная инструкция в документации Яндекс',
              style: TextStyle(
                color: AppTokens.primary,
                decoration: TextDecoration.underline,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int num;
  final String text;

  const _StepRow({required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTokens.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            '$num',
            style: TextStyle(
              color: AppTokens.surface,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTokens.textLight,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _GetKeyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Открыть инструкцию
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTokens.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(
            color: AppTokens.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.open_in_new_rounded,
              color: Color(0xFF667EEA),
              size: 18,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Как получить IAM токен и Folder ID',
                style: TextStyle(
                  color: AppTokens.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF667EEA),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvancedField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final Widget? suffix;

  const _AdvancedField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: AppTokens.text, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: suffix,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
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
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: loading ? null : gradient,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          boxShadow: loading
              ? null
              : [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(
            color: AppTokens.warn.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppTokens.warn,
          size: 20,
        ),
      ),
    );
  }
}
