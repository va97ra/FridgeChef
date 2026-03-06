import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/ai_recipes/presentation/providers.dart';
import '../features/fridge/domain/fridge_item.dart';
import '../features/fridge/presentation/providers.dart';
import '../features/shelf/domain/shelf_item.dart';
import '../features/shelf/presentation/providers.dart';
import 'routes.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  ProviderSubscription<List<FridgeItem>>? _fridgeSub;
  ProviderSubscription<List<ShelfItem>>? _shelfSub;

  @override
  void initState() {
    super.initState();

    _fridgeSub = ref.listenManual<List<FridgeItem>>(
      fridgeListProvider,
      (_, __) => _scheduleAutoSync('fridge-updated'),
    );
    _shelfSub = ref.listenManual<List<ShelfItem>>(
      shelfListProvider,
      (_, __) => _scheduleAutoSync('shelf-updated'),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleAutoSync('startup');
    });
  }

  @override
  void dispose() {
    _fridgeSub?.close();
    _shelfSub?.close();
    super.dispose();
  }

  void _scheduleAutoSync(String reason) {
    ref
        .read(aiRecipesProvider.notifier)
        .scheduleAutoGenerate(reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Помоги приготовить',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
