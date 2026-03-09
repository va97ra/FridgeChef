import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_bootstrap_service.dart';

enum AppBootstrapStatus { loading, ready, fatalError }

class AppBootstrapState {
  final AppBootstrapStatus status;
  final String? message;
  final bool canResetData;

  const AppBootstrapState({
    required this.status,
    this.message,
    this.canResetData = false,
  });

  const AppBootstrapState.loading()
      : this(status: AppBootstrapStatus.loading);

  const AppBootstrapState.ready()
      : this(status: AppBootstrapStatus.ready);

  const AppBootstrapState.fatalError({
    required String message,
    bool canResetData = true,
  }) : this(
          status: AppBootstrapStatus.fatalError,
          message: message,
          canResetData: canResetData,
        );
}

class AppBootstrapController extends StateNotifier<AppBootstrapState> {
  final AppBootstrapService _service;

  AppBootstrapController(this._service) : super(const AppBootstrapState.loading()) {
    initialize();
  }

  Future<void> initialize() async {
    state = const AppBootstrapState.loading();
    try {
      await _service.initialize();
      state = const AppBootstrapState.ready();
    } catch (error) {
      state = AppBootstrapState.fatalError(message: error.toString());
    }
  }

  Future<void> resetLocalData() async {
    state = const AppBootstrapState.loading();
    try {
      await _service.resetLocalData();
      await _service.initialize();
      state = const AppBootstrapState.ready();
    } catch (error) {
      state = AppBootstrapState.fatalError(message: error.toString());
    }
  }
}

final appBootstrapProvider =
    StateNotifierProvider<AppBootstrapController, AppBootstrapState>((ref) {
  return AppBootstrapController(ref.watch(appBootstrapServiceProvider));
});
