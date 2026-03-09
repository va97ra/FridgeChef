import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_settings_repo.dart';
import '../../features/fridge/data/fridge_hive_dto.dart';
import '../../features/fridge/data/user_product_memory_repo.dart';
import '../../features/recipes/data/user_recipe_hive_dto.dart';
import '../../features/recipes/data/recipe_feedback_repo.dart';
import '../../features/shelf/data/shelf_hive_dto.dart';

final appBootstrapServiceProvider = Provider<AppBootstrapService>((ref) {
  return const AppBootstrapService();
});

class AppBootstrapService {
  static const fridgeBoxName = 'fridgeBox';
  static const shelfBoxName = 'shelfBox';
  static const userRecipesBoxName = 'userRecipesBox';
  static bool _hiveInitialized = false;

  const AppBootstrapService();

  Future<void> initialize() async {
    if (!_hiveInitialized) {
      await Hive.initFlutter();
      _hiveInitialized = true;
    }

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FridgeHiveDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ShelfHiveDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserRecipeHiveDtoAdapter());
    }

    if (!Hive.isBoxOpen(fridgeBoxName)) {
      await Hive.openBox<FridgeHiveDto>(fridgeBoxName);
    }
    if (!Hive.isBoxOpen(shelfBoxName)) {
      await Hive.openBox<ShelfHiveDto>(shelfBoxName);
    }
    if (!Hive.isBoxOpen(userRecipesBoxName)) {
      await Hive.openBox<UserRecipeHiveDto>(userRecipesBoxName);
    }
  }

  Future<void> resetLocalData() async {
    for (final boxName in [
      fridgeBoxName,
      shelfBoxName,
      userRecipesBoxName,
    ]) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<dynamic>(boxName).close();
      }
      await Hive.deleteBoxFromDisk(boxName);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppSettingsRepo.onboardingDoneKey);
    await prefs.remove(AppSettingsRepo.lastExportAtKey);
    await prefs.remove(RecipeFeedbackRepo.storageKey);
    await prefs.remove(UserProductMemoryRepo.storageKey);
  }
}
