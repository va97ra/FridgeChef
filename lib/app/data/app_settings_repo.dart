import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appSettingsRepoProvider = Provider<AppSettingsRepo>((ref) {
  return const AppSettingsRepo();
});

class AppSettingsRepo {
  static const onboardingDoneKey = 'app_onboarding_done';
  static const lastExportAtKey = 'app_last_export_at';

  const AppSettingsRepo();

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<bool> isOnboardingDone() async {
    return (await _prefs()).getBool(onboardingDoneKey) ?? false;
  }

  Future<void> setOnboardingDone(bool value) async {
    await (await _prefs()).setBool(onboardingDoneKey, value);
  }

  Future<DateTime?> getLastExportAt() async {
    final raw = (await _prefs()).getString(lastExportAtKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> setLastExportAt(DateTime value) async {
    await (await _prefs()).setString(lastExportAtKey, value.toIso8601String());
  }

  Future<void> clearLocalFlags() async {
    final prefs = await _prefs();
    await prefs.remove(onboardingDoneKey);
    await prefs.remove(lastExportAtKey);
  }
}
