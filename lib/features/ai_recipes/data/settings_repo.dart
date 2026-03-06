import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kIamToken = 'yandex_iam_token';
const _kFolderId = 'yandex_folder_id';

/// Провайдер IAM токена YandexGPT.
final yandexIamTokenProvider =
    AsyncNotifierProvider<YandexIamTokenNotifier, String>(
  YandexIamTokenNotifier.new,
);

class YandexIamTokenNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kIamToken) ?? '';
  }

  Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kIamToken, token.trim());
    state = AsyncValue.data(token.trim());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIamToken);
    state = const AsyncValue.data('');
  }
}

/// Провайдер Folder ID для YandexGPT.
final yandexFolderIdProvider =
    AsyncNotifierProvider<YandexFolderIdNotifier, String>(
  YandexFolderIdNotifier.new,
);

class YandexFolderIdNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kFolderId) ?? '';
  }

  Future<void> save(String folderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFolderId, folderId.trim());
    state = AsyncValue.data(folderId.trim());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kFolderId);
    state = const AsyncValue.data('');
  }
}
