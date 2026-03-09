import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/bootstrap_gate.dart';
import '../core/theme/app_theme.dart';
import 'routes.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Холодильник',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const BootstrapGate(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
