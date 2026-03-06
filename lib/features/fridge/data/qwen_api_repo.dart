import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kQwenApiKey = 'qwen_api_key';
const _kQwenVisionUrl = 'qwen_vision_url';
const _kQwenModel = 'qwen_model';

final qwenApiRepoProvider = Provider<QwenApiRepo>((ref) {
  return const QwenApiRepo();
});

final qwenApiConnectionProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(qwenApiRepoProvider);
  return repo.isConnected();
});

final qwenApiConfigProvider =
    AsyncNotifierProvider<QwenApiConfigNotifier, QwenApiConfig>(
  QwenApiConfigNotifier.new,
);

class QwenApiConfigNotifier extends AsyncNotifier<QwenApiConfig> {
  @override
  Future<QwenApiConfig> build() async {
    return ref.read(qwenApiRepoProvider).getConfig();
  }

  Future<void> save(QwenApiConfig config) async {
    await ref.read(qwenApiRepoProvider).saveConfig(config);
    state = AsyncValue.data(config);
  }
}

class QwenApiConfig {
  final String apiKey;
  final String visionUrl;
  final String model;

  const QwenApiConfig({
    required this.apiKey,
    required this.visionUrl,
    required this.model,
  });

  factory QwenApiConfig.defaults() {
    return const QwenApiConfig(
      apiKey: '',
      visionUrl:
          'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
      model: 'qwen-vl-max-latest',
    );
  }

  QwenApiConfig copyWith({
    String? apiKey,
    String? visionUrl,
    String? model,
  }) {
    return QwenApiConfig(
      apiKey: apiKey ?? this.apiKey,
      visionUrl: visionUrl ?? this.visionUrl,
      model: model ?? this.model,
    );
  }
}

class QwenApiRepo {
  const QwenApiRepo();

  Future<bool> isConnected() async {
    final key = await getApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_kQwenApiKey)?.trim() ?? '';
    if (key.isEmpty) {
      return null;
    }
    return key;
  }

  Future<QwenApiConfig> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = QwenApiConfig.defaults();
    return QwenApiConfig(
      apiKey: prefs.getString(_kQwenApiKey) ?? defaults.apiKey,
      visionUrl: prefs.getString(_kQwenVisionUrl) ?? defaults.visionUrl,
      model: prefs.getString(_kQwenModel) ?? defaults.model,
    );
  }

  Future<void> saveConfig(QwenApiConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kQwenApiKey, config.apiKey.trim());
    await prefs.setString(_kQwenVisionUrl, config.visionUrl.trim());
    await prefs.setString(_kQwenModel, config.model.trim());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kQwenApiKey);
  }
}
