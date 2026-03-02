import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'features/fridge/data/fridge_hive_dto.dart';
import 'features/shelf/data/shelf_hive_dto.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(FridgeHiveDtoAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ShelfHiveDtoAdapter());
  }

  await Hive.openBox<FridgeHiveDto>('fridgeBox');
  await Hive.openBox<ShelfHiveDto>('shelfBox');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
