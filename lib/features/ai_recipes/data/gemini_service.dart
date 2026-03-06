import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/ai_recipe.dart';

class YandexGPTService {
  static const _baseUrl =
      'https://llm.api.cloud.yandex.net/foundationModels/v1/completion';

  final String iamToken;
  final String folderId;

  const YandexGPTService({required this.iamToken, required this.folderId});

  Future<List<AiRecipe>> generateRecipes({
    required List<String> fridgeItems,
    required List<String> shelfItems,
    required List<String> priorityItems,
    required List<String> pairHints,
    int count = 3,
    String? extraWish,
  }) async {
    if (iamToken.isEmpty || folderId.isEmpty) {
      throw const YandexGPTException(
        'IAM токен или Folder ID не заданы. Зайди в Настройки.',
      );
    }

    final fridgeStr =
        fridgeItems.isEmpty ? 'холодильник пустой' : fridgeItems.join(', ');
    final shelfStr = shelfItems.isEmpty ? 'специй нет' : shelfItems.join(', ');
    final priorityStr =
        priorityItems.isEmpty ? 'нет' : priorityItems.join(', ');
    final pairsStr = pairHints.isEmpty ? 'нет' : pairHints.join('; ');
    final wishStr = extraWish != null && extraWish.trim().isNotEmpty
        ? extraWish.trim()
        : '';

    final prompt = '''
Ты — опытный шеф-повар. Придумай $count вкусных рецепта ТОЛЬКО из тех продуктов, которые есть у пользователя.
Категорически не добавляй ингредиенты, которых нет в списке.
Приоритет: сначала используй продукты с высоким приоритетом и удачные сочетания.

Холодильник: $fridgeStr
Специи и приправы: $shelfStr
Приоритетные продукты: $priorityStr
Удачные сочетания: $pairsStr
${wishStr.isNotEmpty ? 'Пожелание пользователя: $wishStr' : ''}

Верни ТОЛЬКО валидный JSON-массив без каких-либо пояснений и markdown-блоков.
Каждый элемент массива — объект с полями:
- "title": string (название блюда на русском)
- "timeMin": number (время приготовления в минутах)
- "servings": number (на сколько порций)
- "ingredients": array of strings (каждый элемент — ингредиент с количеством, например "Яйца — 3 шт")
- "steps": array of strings (шаги приготовления, каждый — отдельная строка)
- "tip": string или null (необязательный совет шефа)
''';

    final body = jsonEncode({
      'modelUri': 'gpt://$folderId/yandexgpt/latest',
      'completionOptions': {
        'stream': false,
        'temperature': 0.8,
        'maxTokens': '2000',
      },
      'messages': [
        {
          'role': 'system',
          'content':
              'Ты кулинарный ассистент. Отвечай только валидным JSON-массивом без текста до и после.',
        },
        {'role': 'user', 'content': prompt},
      ],
    });

    final uri = Uri.parse(_baseUrl);

    late final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $iamToken',
              'x-cloud-folder-id': folderId,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 45));
    } catch (e) {
      throw YandexGPTException('Ошибка сети: ${e.toString()}');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const YandexGPTException('Неверный IAM токен. Проверь настройки.');
    }

    if (response.statusCode == 429) {
      throw const YandexGPTException(
          'Превышен лимит запросов к YandexGPT API (429). Подожди немного.');
    }

    if (response.statusCode != 200) {
      String errorMsg = 'Ошибка ${response.statusCode}';
      try {
        final errJson = jsonDecode(response.body);
        final innerMsg = errJson['error']?['message'] ?? response.body;
        errorMsg += '\n$innerMsg';
      } catch (_) {
        errorMsg += '\n${response.body}';
      }
      throw YandexGPTException(errorMsg);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final result = decoded['result'] as Map<String, dynamic>?;
    final alternatives = result?['alternatives'] as List<dynamic>?;

    if (alternatives == null || alternatives.isEmpty) {
      throw const YandexGPTException('AI не вернул ни одного рецепта.');
    }

    final text = alternatives[0]['message']?['text'] as String?;

    if (text == null || text.isEmpty) {
      throw const YandexGPTException('AI вернул пустой ответ.');
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
      throw const YandexGPTException(
          'Не удалось разобрать ответ YandexGPT. Попробуй снова.');
    }
  }
}

class YandexGPTException implements Exception {
  final String message;
  const YandexGPTException(this.message);

  @override
  String toString() => message;
}
