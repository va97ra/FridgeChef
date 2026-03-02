import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kApiKeyPref = 'gemini_api_key';

/// Провайдер API-ключа Gemini (хранится в SharedPreferences).
final geminiApiKeyProvider =
    AsyncNotifierProvider<GeminiApiKeyNotifier, String>(
  GeminiApiKeyNotifier.new,
);

class GeminiApiKeyNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kApiKeyPref) ?? '';
  }

  Future<void> save(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiKeyPref, key.trim());
    state = AsyncValue.data(key.trim());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kApiKeyPref);
    state = const AsyncValue.data('');
  }
}
