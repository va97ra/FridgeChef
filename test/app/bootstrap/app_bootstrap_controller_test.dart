import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/app/bootstrap/app_bootstrap_controller.dart';
import 'package:help_to_cook/app/bootstrap/app_bootstrap_service.dart';

void main() {
  test('bootstrap controller enters fatalError when initialization fails', () async {
    final controller = AppBootstrapController(_FakeBootstrapService(failInit: true));
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.status, AppBootstrapStatus.fatalError);
    expect(controller.state.message, contains('bootstrap failed'));
  });

  test('resetLocalData retries bootstrap and returns to ready state', () async {
    final service = _FakeBootstrapService(failInit: true);
    final controller = AppBootstrapController(service);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.status, AppBootstrapStatus.fatalError);

    service.failInit = false;
    await controller.resetLocalData();

    expect(service.resetCalls, 1);
    expect(controller.state.status, AppBootstrapStatus.ready);
  });
}

class _FakeBootstrapService extends AppBootstrapService {
  bool failInit;
  int resetCalls = 0;

  _FakeBootstrapService({required this.failInit});

  @override
  Future<void> initialize() async {
    if (failInit) {
      throw Exception('bootstrap failed');
    }
  }

  @override
  Future<void> resetLocalData() async {
    resetCalls++;
  }
}
