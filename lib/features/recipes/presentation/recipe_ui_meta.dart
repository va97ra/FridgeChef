import '../domain/recipe.dart';

List<String> buildRecipeMoodBadges(Recipe recipe) {
  final tags = recipe.tags.map((tag) => tag.toLowerCase()).toSet();
  final ingredientNames = recipe.ingredients
      .map((ingredient) => ingredient.name.toLowerCase().replaceAll('ё', 'е'))
      .toList();
  final badges = <String>[];

  void add(String label) {
    if (!badges.contains(label)) {
      badges.add(label);
    }
  }

  if (tags.contains('breakfast')) {
    add('Завтрак');
  }
  if (tags.contains('kids')) {
    add('Детям');
  }
  if (tags.contains('quick') || tags.contains('easy') || recipe.timeMin <= 15) {
    add('Легко');
  }
  if (tags.contains('one_pan')) {
    add('Одна сковорода');
  }
  if (_isHearty(ingredientNames)) {
    add('Сытно');
  }
  if (!tags.contains('breakfast') && _isDinnerLike(recipe, ingredientNames)) {
    add('Ужин');
  }

  return badges.take(3).toList();
}

String? buildStepHint(String step) {
  final text = step.toLowerCase().replaceAll('ё', 'е');

  if (text.contains('обжар')) {
    return 'Жарь до золотистой корочки и не перегружай сковороду.';
  }
  if (text.contains('взбей')) {
    return 'Смешивай до однородности, но не переусердствуй, чтобы текстура осталась нежной.';
  }
  if (text.contains('варите') ||
      text.contains('отварите') ||
      text.contains('доведите до кипения')) {
    return 'После закипания убавь огонь, чтобы продукт приготовился ровно.';
  }
  if (text.contains('туш') || text.contains('под крышк')) {
    return 'Готовь на умеренном огне под крышкой, чтобы сохранить сочность.';
  }
  if (text.contains('чеснок')) {
    return 'Чеснок лучше долго не жарить: как только пошёл аромат, двигайся дальше.';
  }
  if (text.contains('сыр')) {
    return 'Сыр лучше добавлять ближе к концу, чтобы он расплавился, но не пересох.';
  }
  if (text.contains('смешайте') || text.contains('перемешайте')) {
    return 'Перемешивай аккуратно, чтобы сохранить текстуру и не размять ингредиенты.';
  }
  if (text.contains('перевер')) {
    return 'Переворачивай, когда нижняя сторона уже держит форму и хорошо схватилась.';
  }
  if (text.contains('пода') || text.contains('дайте постоять')) {
    return 'Дай блюду минуту постоять перед подачей, чтобы вкус собрался.';
  }

  return null;
}

bool _isHearty(List<String> ingredientNames) {
  const heartyTokens = [
    'картоф',
    'рис',
    'макарон',
    'паста',
    'куриц',
    'говядин',
    'свинин',
    'индейк',
    'тунец',
    'чечевиц',
    'фасол',
    'гречк',
    'фарш',
    'творог',
  ];

  return ingredientNames.any(
    (name) => heartyTokens.any(name.contains),
  );
}

bool _isDinnerLike(Recipe recipe, List<String> ingredientNames) {
  if (recipe.timeMin >= 18) {
    return true;
  }
  return ingredientNames.any(
    (name) =>
        name.contains('куриц') ||
        name.contains('говядин') ||
        name.contains('свинин') ||
        name.contains('фарш') ||
        name.contains('рис') ||
        name.contains('макарон'),
  );
}
