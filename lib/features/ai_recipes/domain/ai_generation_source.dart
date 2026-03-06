enum AiGenerationSource {
  none,
  ai,
  localFallback,
  cache,
}

extension AiGenerationSourceX on AiGenerationSource {
  String get storageValue {
    switch (this) {
      case AiGenerationSource.none:
        return 'none';
      case AiGenerationSource.ai:
        return 'ai';
      case AiGenerationSource.localFallback:
        return 'local_fallback';
      case AiGenerationSource.cache:
        return 'cache';
    }
  }

  String get label {
    switch (this) {
      case AiGenerationSource.none:
        return 'Нет данных';
      case AiGenerationSource.ai:
        return 'AI';
      case AiGenerationSource.localFallback:
        return 'Локально';
      case AiGenerationSource.cache:
        return 'Кеш';
    }
  }

  static AiGenerationSource fromStorage(String? value) {
    switch (value) {
      case 'ai':
        return AiGenerationSource.ai;
      case 'local_fallback':
        return AiGenerationSource.localFallback;
      case 'cache':
        return AiGenerationSource.cache;
      default:
        return AiGenerationSource.none;
    }
  }
}
