import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/utils/units.dart';
import '../domain/detected_product_draft.dart';
import 'qwen_api_repo.dart';

final cloudRefinementServiceProvider = Provider<CloudRefinementService>((ref) {
  final qwenApiRepo = ref.watch(qwenApiRepoProvider);
  return CloudRefinementService(qwenApiRepo: qwenApiRepo);
});

class CloudRefinementService {
  final QwenApiRepo qwenApiRepo;

  const CloudRefinementService({
    required this.qwenApiRepo,
  });

  Future<List<DetectedProductDraft>> refineWithQwenApi({
    required String imagePath,
    required List<DetectedProductDraft> localDrafts,
  }) async {
    final hasConnection = await _hasConnection();
    if (!hasConnection) {
      throw const CloudRefineException('Нет сети');
    }

    final apiKey = await qwenApiRepo.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw const CloudRefineException('Qwen API key не задан');
    }

    final config = await qwenApiRepo.getConfig();
    final bytes = await File(imagePath).readAsBytes();
    final imageBase64 = base64Encode(bytes);
    final localItems = localDrafts
        .map((d) => '${d.name} ${d.amount.toStringAsFixed(2)} ${d.unit.name}')
        .join(', ');
    final prompt = '''
Верни только JSON-массив продуктов без markdown.
Используй фото и список локальных кандидатов: $localItems

Формат массива:
[
 {"name":"Молоко","amount":1,"unit":"l","confidence":0.9}
]

Ограничения:
- до 15 элементов
- unit только: g, kg, ml, l, pcs
- confidence от 0 до 1
''';

    final body = jsonEncode({
      'model': config.model,
      'temperature': 0.1,
      'messages': [
        {
          'role': 'system',
          'content':
              'Ты ассистент распознавания продуктов. Отвечай только JSON-массивом.',
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': prompt,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,$imageBase64',
              },
            },
          ],
        },
      ],
    });

    final response = await http
        .post(
          Uri.parse(config.visionUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 35));

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const CloudRefineException('Qwen API key недействителен');
    }
    if (response.statusCode >= 400) {
      throw CloudRefineException(
        'Cloud refine error ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractMessageContent(decoded);
    final parsed = _parseDrafts(content);
    if (parsed.isEmpty) {
      throw const CloudRefineException('Пустой ответ cloud refine');
    }
    return parsed;
  }

  Future<bool> _hasConnection() async {
    final dynamic raw = await Connectivity().checkConnectivity();
    if (raw is ConnectivityResult) {
      return raw != ConnectivityResult.none;
    }
    if (raw is List<ConnectivityResult>) {
      return raw.any((entry) => entry != ConnectivityResult.none);
    }
    return true;
  }

  String _extractMessageContent(Map<String, dynamic> json) {
    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const CloudRefineException('Ответ cloud refine без choices');
    }

    final message = (choices.first as Map<String, dynamic>)['message'];
    if (message is! Map<String, dynamic>) {
      throw const CloudRefineException('Ответ cloud refine без message');
    }

    final content = message['content'];
    if (content is String) {
      return content;
    }
    if (content is List) {
      final text = content
          .map((entry) => entry is Map<String, dynamic> ? entry['text'] : null)
          .whereType<String>()
          .join('\n');
      if (text.isNotEmpty) {
        return text;
      }
    }

    throw const CloudRefineException('Ответ cloud refine без content');
  }

  List<DetectedProductDraft> _parseDrafts(String content) {
    var cleaned = content.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '');
    }

    dynamic parsed;
    try {
      parsed = jsonDecode(cleaned);
    } catch (_) {
      final match = RegExp(r'\[[\s\S]+\]').firstMatch(cleaned);
      if (match == null) {
        throw const CloudRefineException('Cloud refine JSON parse error');
      }
      parsed = jsonDecode(match.group(0)!);
    }

    if (parsed is! List) {
      throw const CloudRefineException('Cloud refine payload is not a list');
    }

    final uuid = const Uuid();
    final drafts = <DetectedProductDraft>[];
    for (final entry in parsed.take(15)) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final name = (entry['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        continue;
      }
      final amount =
          (((entry['amount'] as num?)?.toDouble() ?? 1).clamp(0.01, 9999))
              .toDouble();
      final unit = _parseUnit((entry['unit'] as String?) ?? 'pcs');
      final confidence = ((entry['confidence'] as num?)?.toDouble() ?? 0.6)
          .clamp(0.0, 1.0)
          .toDouble();

      drafts.add(
        DetectedProductDraft(
          id: uuid.v4(),
          name: name,
          amount: amount,
          unit: unit,
          confidence: confidence,
          rawTokens: const [],
          source: DetectionSource.cloudRefined,
        ),
      );
    }

    return drafts;
  }

  Unit _parseUnit(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'g':
      case 'гр':
      case 'г':
        return Unit.g;
      case 'kg':
      case 'кг':
        return Unit.kg;
      case 'ml':
      case 'мл':
        return Unit.ml;
      case 'l':
      case 'л':
        return Unit.l;
      default:
        return Unit.pcs;
    }
  }
}

class CloudRefineException implements Exception {
  final String message;
  const CloudRefineException(this.message);

  @override
  String toString() => message;
}
