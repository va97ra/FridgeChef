import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Hive
  await Hive.initFlutter();
  
  // Открытие boxes
  await Hive.openBox('fridgeBox');
  await Hive.openBox('shelfBox');
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
