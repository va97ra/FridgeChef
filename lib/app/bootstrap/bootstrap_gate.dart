import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_surface.dart';
import '../../features/home/presentation/home_screen.dart';
import 'app_bootstrap_controller.dart';

class BootstrapGate extends ConsumerWidget {
  const BootstrapGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appBootstrapProvider);

    return switch (state.status) {
      AppBootstrapStatus.ready => const HomeScreen(),
      AppBootstrapStatus.loading => const _BootstrapLoadingScreen(),
      AppBootstrapStatus.fatalError => _BootstrapFailureScreen(state: state),
    };
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      body: Center(
        child: SectionSurface(
          padding: const EdgeInsets.all(AppTokens.p24),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppTokens.p16),
              Text(
                'Подготавливаю офлайн-данные...',
                style: TextStyle(
                  color: AppTokens.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootstrapFailureScreen extends ConsumerWidget {
  final AppBootstrapState state;

  const _BootstrapFailureScreen({
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.p20),
          child: Center(
            child: SectionSurface(
              tone: SectionSurfaceTone.warnSoft,
              padding: const EdgeInsets.all(AppTokens.p24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppTokens.warn,
                    size: 30,
                  ),
                  const SizedBox(height: AppTokens.p16),
                  Text(
                    'Не удалось открыть локальные данные',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 24,
                        ),
                  ),
                  const SizedBox(height: AppTokens.p8),
                  Text(
                    state.message ?? 'Произошла неизвестная ошибка при запуске.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTokens.p20),
                  PrimaryButton(
                    text: 'Попробовать снова',
                    onPressed: () => ref
                        .read(appBootstrapProvider.notifier)
                        .initialize(),
                  ),
                  if (state.canResetData) ...[
                    const SizedBox(height: AppTokens.p12),
                    PrimaryButton(
                      text: 'Сбросить локальные данные',
                      variant: PrimaryButtonVariant.secondary,
                      onPressed: () => _confirmReset(context, ref),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Сбросить локальные данные?'),
          content: const Text(
            'Холодильник, полка и сохранённые рецепты будут очищены. Это действие необратимо.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Сбросить'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref.read(appBootstrapProvider.notifier).resetLocalData();
    }
  }
}
