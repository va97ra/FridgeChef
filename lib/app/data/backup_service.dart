import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/fridge/data/fridge_repo.dart';
import '../../features/fridge/data/user_product_memory_repo.dart';
import '../../features/fridge/domain/fridge_item.dart';
import '../../features/fridge/domain/user_product_memory_entry.dart';
import '../../features/recipes/data/recipe_feedback_repo.dart';
import '../../features/recipes/data/user_recipes_repo.dart';
import '../../features/recipes/domain/recipe.dart';
import '../../features/recipes/domain/taste_profile.dart';
import '../../features/shelf/data/shelf_repo.dart';
import '../../features/shelf/domain/shelf_item.dart';
import 'app_settings_repo.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    fridgeRepo: ref.watch(fridgeRepoProvider),
    shelfRepo: ref.watch(shelfRepoProvider),
    userRecipesRepo: ref.watch(userRecipesRepoProvider),
    recipeFeedbackRepo: ref.watch(recipeFeedbackRepoProvider),
    userProductMemoryRepo: ref.watch(userProductMemoryRepoProvider),
    appSettingsRepo: ref.watch(appSettingsRepoProvider),
  );
});

class BackupPayloadV2 {
  final int schemaVersion;
  final DateTime exportedAt;
  final String appVersion;
  final List<FridgeItem> fridgeItems;
  final List<ShelfItem> shelfItems;
  final List<Recipe> userRecipes;
  final Map<String, RecipeFeedbackVote> recipeFeedbackVotes;
  final List<UserProductMemoryEntry> userProductMemory;

  const BackupPayloadV2({
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.fridgeItems,
    required this.shelfItems,
    required this.userRecipes,
    this.recipeFeedbackVotes = const {},
    this.userProductMemory = const [],
  });

  factory BackupPayloadV2.fromJson(Map<String, dynamic> json) {
    final feedback = <String, RecipeFeedbackVote>{};
    final rawFeedback = json['recipeFeedbackVotes'];
    if (rawFeedback is Map<String, dynamic>) {
      for (final entry in rawFeedback.entries) {
        final vote = RecipeFeedbackVoteX.fromStorage(entry.value as String?);
        if (vote != null) {
          feedback[entry.key] = vote;
        }
      }
    }

    return BackupPayloadV2(
      schemaVersion: json['schemaVersion'] as int? ?? 0,
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      appVersion: json['appVersion'] as String? ?? 'unknown',
      fridgeItems: ((json['fridgeItems'] as List<dynamic>?) ?? const [])
          .map((item) => FridgeItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      shelfItems: ((json['shelfItems'] as List<dynamic>?) ?? const [])
          .map((item) => ShelfItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      userRecipes: ((json['userRecipes'] as List<dynamic>?) ?? const [])
          .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
          .toList(),
      recipeFeedbackVotes: feedback,
      userProductMemory: ((json['userProductMemory'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(UserProductMemoryEntry.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'appVersion': appVersion,
      'fridgeItems': fridgeItems.map((item) => item.toJson()).toList(),
      'shelfItems': shelfItems.map((item) => item.toJson()).toList(),
      'userRecipes': userRecipes.map((recipe) => recipe.toJson()).toList(),
      'recipeFeedbackVotes': {
        for (final entry in recipeFeedbackVotes.entries)
          entry.key: entry.value.storageValue,
      },
      'userProductMemory':
          userProductMemory.map((entry) => entry.toJson()).toList(),
    };
  }
}

class BackupPreview {
  final BackupPayloadV2 payload;

  const BackupPreview({required this.payload});

  int get fridgeCount => payload.fridgeItems.length;
  int get shelfCount => payload.shelfItems.length;
  int get recipesCount => payload.userRecipes.length;
}

class BackupService {
  static const schemaVersion = 2;

  final FridgeRepo fridgeRepo;
  final ShelfRepo shelfRepo;
  final UserRecipesRepo userRecipesRepo;
  final RecipeFeedbackRepo recipeFeedbackRepo;
  final UserProductMemoryRepo userProductMemoryRepo;
  final AppSettingsRepo appSettingsRepo;

  const BackupService({
    required this.fridgeRepo,
    required this.shelfRepo,
    required this.userRecipesRepo,
    required this.recipeFeedbackRepo,
    required this.userProductMemoryRepo,
    required this.appSettingsRepo,
  });

  Future<File> exportAllData() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final payload = BackupPayloadV2(
      schemaVersion: schemaVersion,
      exportedAt: DateTime.now(),
      appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
      fridgeItems: fridgeRepo.getAll(),
      shelfItems: shelfRepo.getAll(),
      userRecipes: await userRecipesRepo.getAllUserRecipes(),
      recipeFeedbackVotes: await recipeFeedbackRepo.loadAll(),
      userProductMemory: await userProductMemoryRepo.loadAll(),
    );

    final directory = await getTemporaryDirectory();
    final stamp = _timestamp(payload.exportedAt);
    final file = File('${directory.path}${Platform.pathSeparator}fridgechef_backup_$stamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload.toJson()),
    );
    await appSettingsRepo.setLastExportAt(payload.exportedAt);
    return file;
  }

  Future<void> shareExportFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Резервная копия FridgeChef',
    );
  }

  Future<String?> pickImportPath() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Выбери резервную копию FridgeChef',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );
    return result?.files.single.path;
  }

  Future<BackupPreview> loadImportPreview(String path) async {
    final raw = await File(path).readAsString();
    final payload = BackupPayloadV2.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    if (payload.schemaVersion < 1 || payload.schemaVersion > schemaVersion) {
      throw const BackupFormatException('Неподдерживаемая версия резервной копии');
    }
    return BackupPreview(payload: payload);
  }

  Future<void> replaceAllData(BackupPayloadV2 payload) async {
    if (payload.schemaVersion < 1 || payload.schemaVersion > schemaVersion) {
      throw const BackupFormatException('Неподдерживаемая версия резервной копии');
    }

    await fridgeRepo.replaceAll(payload.fridgeItems);
    await shelfRepo.replaceAll(payload.shelfItems);
    await userRecipesRepo.replaceAllUserRecipes(payload.userRecipes);
    await recipeFeedbackRepo.replaceAll(payload.recipeFeedbackVotes);
    await userProductMemoryRepo.replaceAll(payload.userProductMemory);
  }

  Future<void> clearAllData() async {
    await fridgeRepo.clear();
    await shelfRepo.clear();
    await userRecipesRepo.clearAll();
    await recipeFeedbackRepo.clear();
    await userProductMemoryRepo.clear();
    await appSettingsRepo.clearLocalFlags();
  }

  String _timestamp(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$y$m$d' '_$h$min';
  }
}

class BackupFormatException implements Exception {
  final String message;

  const BackupFormatException(this.message);

  @override
  String toString() => message;
}
