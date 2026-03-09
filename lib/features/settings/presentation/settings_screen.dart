import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/data/app_settings_repo.dart';
import '../../../app/data/backup_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/section_surface.dart';
import '../../fridge/presentation/providers.dart';
import '../../recipes/presentation/providers.dart';
import '../../shelf/presentation/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Future<_SettingsMeta> _metaFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _metaFuture = _loadMeta();
  }

  Future<_SettingsMeta> _loadMeta() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final lastExport = await ref.read(appSettingsRepoProvider).getLastExportAt();
    return _SettingsMeta(
      versionLabel: '${packageInfo.version}+${packageInfo.buildNumber}',
      lastExportAt: lastExport,
    );
  }

  Future<void> _refreshMeta() async {
    setState(() {
      _metaFuture = _loadMeta();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Настройки',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppTokens.p20),
          child: AppIconButtonPlaceholder(
            busy: _busy,
          ),
        ),
      ],
      body: FutureBuilder<_SettingsMeta>(
        future: _metaFuture,
        builder: (context, snapshot) {
          final meta = snapshot.data;
          return ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: AppTokens.p8),
              SectionSurface(
                tone: SectionSurfaceTone.muted,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Холодильник',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 26,
                          ),
                    ),
                    const SizedBox(height: AppTokens.p8),
                    Text(
                      'Офлайн-приложение для дома: продукты, полка, подбор блюд и сохранение рецептов без сети.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTokens.p16),
                    _MetaRow(
                      label: 'Версия приложения',
                      value: meta?.versionLabel ?? 'Загрузка...',
                    ),
                    const SizedBox(height: AppTokens.p8),
                    _MetaRow(
                      label: 'Последний экспорт',
                      value: meta?.lastExportLabel ?? 'Ещё не делали',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.p16),
              SectionSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Данные',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppTokens.p12),
                    _ActionTile(
                      icon: Icons.ios_share_rounded,
                      title: 'Экспортировать данные',
                      subtitle: 'Сохранить холодильник, полку и свои рецепты в JSON',
                      onTap: _busy ? null : _exportData,
                    ),
                    const SizedBox(height: AppTokens.p8),
                    _ActionTile(
                      icon: Icons.download_rounded,
                      title: 'Импортировать данные',
                      subtitle: 'Полностью заменить локальные данные из резервной копии',
                      onTap: _busy ? null : _importData,
                    ),
                    const SizedBox(height: AppTokens.p8),
                    _ActionTile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Очистить все данные',
                      subtitle: 'Удалить холодильник, полку и сохранённые рецепты',
                      tone: SectionSurfaceTone.warnSoft,
                      onTap: _busy ? null : _resetAllData,
                    ),
                  ],
                ),
              ),
              if (_busy) ...[
                const SizedBox(height: AppTokens.p16),
                const LinearProgressIndicator(minHeight: 2),
              ],
              const SizedBox(height: AppTokens.p24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportData() async {
    await _runBusy(() async {
      final backupService = ref.read(backupServiceProvider);
      final file = await backupService.exportAllData();
      await backupService.shareExportFile(file);
      await _refreshMeta();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Экспорт готов: ${file.path.split('\\').last}')),
      );
    });
  }

  Future<void> _importData() async {
    await _runBusy(() async {
      final backupService = ref.read(backupServiceProvider);
      final path = await backupService.pickImportPath();
      if (path == null || path.isEmpty) {
        return;
      }

      final preview = await backupService.loadImportPreview(path);
      if (!mounted) {
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Импортировать резервную копию?'),
            content: Text(
              'Локальные данные будут полностью заменены.\n\n'
              'Холодильник: ${preview.fridgeCount}\n'
              'Полка: ${preview.shelfCount}\n'
              'Мои рецепты: ${preview.recipesCount}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Импортировать'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      await backupService.replaceAllData(preview.payload);
      _invalidateData();
      await _refreshMeta();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные восстановлены из резервной копии')),
      );
    });
  }

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Очистить все данные?'),
          content: const Text(
            'Холодильник, полка и сохранённые рецепты будут удалены без возможности восстановления.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Очистить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _runBusy(() async {
      await ref.read(backupServiceProvider).clearAllData();
      _invalidateData();
      await _refreshMeta();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Локальные данные очищены')),
      );
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) {
      return;
    }

    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _invalidateData() {
    ref.invalidate(fridgeListProvider);
    ref.invalidate(shelfListProvider);
    ref.invalidate(recipesProvider);
    ref.invalidate(recipeFeedbackProvider);
    ref.invalidate(recipeMatchesProvider);
  }
}

class _SettingsMeta {
  final String versionLabel;
  final DateTime? lastExportAt;

  const _SettingsMeta({
    required this.versionLabel,
    required this.lastExportAt,
  });

  String get lastExportLabel {
    final value = lastExportAt;
    if (value == null) {
      return 'Ещё не делали';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.textLight,
                ),
          ),
        ),
        const SizedBox(width: AppTokens.p12),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final SectionSurfaceTone tone;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tone = SectionSurfaceTone.base,
  });

  @override
  Widget build(BuildContext context) {
    return SectionSurface(
      tone: tone,
      padding: EdgeInsets.zero,
      withShadow: false,
      child: ListTile(
        leading: Icon(icon, color: AppTokens.text),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class AppIconButtonPlaceholder extends StatelessWidget {
  final bool busy;

  const AppIconButtonPlaceholder({
    super.key,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    if (!busy) {
      return const SizedBox(width: 42, height: 42);
    }
    return const SizedBox(
      width: 42,
      height: 42,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
