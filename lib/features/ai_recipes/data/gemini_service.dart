import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/ai_recipe.dart';

class GeminiService {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  final String apiKey;

  const GeminiService({required this.apiKey});

  /// Генерирует список рецептов на основе доступных продуктов.
  /// [fridgeItems] — продукты из холодильника ("помидоры 200г", "яйца 3шт")
  /// [shelfItems] — специи/приправы ("соль", "перец", "масло")
  /// [count] — сколько рецептов сгенерировать (1–5)
  Future<List<AiRecipe>> generateRecipes({
    required List<String> fridgeItems,
    required List<String> shelfItems,
    int count = 3,
    String? extraWish,
  }) async {
    if (apiKey.isEmpty) {
      throw const GeminiException('API-ключ не задан. Зайди в Настройки.');
    }

    final fridgeStr =
        fridgeItems.isEmpty ? 'холодильник пустой' : fridgeItems.join(', ');
    final shelfStr = shelfItems.isEmpty ? 'специй нет' : shelfItems.join(', ');
    final wishStr = extraWish != null && extraWish.trim().isNotEmpty
        ? extraWish.trim()
        : '';

    final prompt = '''
Ты — опытный шеф-повар. Придумай $count вкусных рецепта ТОЛЬКО из тех продуктов, которые есть у пользователя.
Не включай ингредиенты, которых нет в списке.

Холодильник: $fridgeStr
Специи и приправы: $shelfStr
${wishStr.isNotEmpty ? 'Пожелание пользователя: $wishStr' : ''}

Верни ТОЛЬКО валидный JSON-массив без каких-либо пояснений и markdown-блоков.
Каждый элемент массива — объект с полями:
- "title": string (название блюда на русском)
- "timeMin": number (время приготовления в минутах)
- "servings": number (на сколько порций)
- "ingredients": array of strings (каждый элемент — ингредиент с количеством, например "Яйца — 3 шт")
- "steps": array of strings (шаги приготовления, каждый — отдельная строка)
- "tip": string или null (необязательный совет шефа)

Пример формата одного рецепта:
{"title":"Яичница с помидорами","timeMin":10,"servings":2,"ingredients":["Яйца — 3 шт","Помидоры — 1 шт (150 г)","Соль — по вкусу","Масло растительное — 1 ст.л."],"steps":["Разогрей сковороду на среднем огне и добавь масло.","Нарежь помидоры кубиками и обжаривай 2 минуты.","Разбей яйца, посоли и жарь до готовности 3–4 минуты."],"tip":"Добавь щепотку орегано для аромата."}
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.9,
        'maxOutputTokens': 4096,
      },
    });

    final uri = Uri.parse('$_baseUrl?key=$apiKey');

    late final http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 45));
    } catch (e) {
      throw GeminiException('Ошибка сети: ${e.toString()}');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const GeminiException(
          'Неверный или просроченный API-ключ. Проверь настройки.');
    }
    if (response.statusCode != 200) {
      throw GeminiException(
          'Ошибка Gemini API: ${response.statusCode}\n${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const GeminiException('AI не вернул ни одного рецепта.');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text =
        parts?.isNotEmpty == true ? parts![0]['text'] as String? : null;

    if (text == null || text.isEmpty) {
      throw const GeminiException('AI вернул пустой ответ.');
    }

    return _parseRecipes(text);
  }

  List<AiRecipe> _parseRecipes(String text) {
    // Очищаем от возможных markdown-оберток ```json ... ```
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '');
    }

    try {
      final list = jsonDecode(cleaned) as List<dynamic>;
      return list
          .map((e) => AiRecipe.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Попытка найти JSON-массив внутри текста
      final match = RegExp(r'\[[\s\S]+\]').firstMatch(cleaned);
      if (match != null) {
        try {
          final list = jsonDecode(match.group(0)!) as List<dynamic>;
          return list
              .map((e) => AiRecipe.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
      throw const GeminiException(
          'Не удалось разобрать ответ AI. Попробуй снова.');
    }
  }
}

class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);

  @override
  String toString() => message;
}
