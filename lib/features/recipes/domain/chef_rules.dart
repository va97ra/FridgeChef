import 'ingredient_knowledge.dart';

enum DishProfile {
  skillet,
  soup,
  salad,
  bake,
  pasta,
  grainBowl,
  breakfast,
  stew,
  general,
}

class ChefSupportPlan {
  final DishProfile profile;
  final List<String> aromaticCanonicals;
  final List<String> seasoningCanonicals;
  final List<String> finishingCanonicals;

  const ChefSupportPlan({
    required this.profile,
    required this.aromaticCanonicals,
    required this.seasoningCanonicals,
    required this.finishingCanonicals,
  });

  List<String> get optionalCanonicals {
    final values = <String>[];
    for (final canonical in [
      ...seasoningCanonicals,
      ...finishingCanonicals,
    ]) {
      if (!values.contains(canonical)) {
        values.add(canonical);
      }
    }
    return values;
  }
}

class ChefRulesAssessment {
  final DishProfile profile;
  final double seasoningScore;
  final double techniqueScore;
  final double structureScore;
  final double balanceScore;
  final double flavorScore;
  final double score;
  final List<String> reasons;
  final List<String> warnings;
  final ChefSupportPlan supportPlan;

  const ChefRulesAssessment({
    required this.profile,
    required this.seasoningScore,
    required this.techniqueScore,
    required this.structureScore,
    required this.balanceScore,
    required this.flavorScore,
    required this.score,
    required this.reasons,
    required this.warnings,
    required this.supportPlan,
  });
}

DishProfile inferDishProfile({
  required String title,
  required List<String> tags,
  required Iterable<String> ingredientCanonicals,
}) {
  final normalizedTitle = normalizeIngredientText(title);
  final normalizedTags =
      tags.map(normalizeIngredientText).where((tag) => tag.isNotEmpty).toSet();
  final ingredientSet =
      ingredientCanonicals.map(normalizeIngredientText).toSet();

  if (normalizedTitle.contains('суп')) {
    return DishProfile.soup;
  }
  if (normalizedTags.contains('soup')) {
    return DishProfile.soup;
  }
  if (normalizedTitle.contains('запекан') ||
      normalizedTitle.contains('в духовке') ||
      normalizedTags.contains('oven') ||
      normalizedTags.contains('bake')) {
    return DishProfile.bake;
  }
  if (normalizedTitle.contains('салат') ||
      normalizedTags.contains('salad') ||
      (normalizedTags.contains('light') &&
          !normalizedTags.contains('one pan') &&
          !ingredientSet.contains('макароны') &&
          !ingredientSet.contains('рис'))) {
    return DishProfile.salad;
  }
  if (normalizedTitle.contains('паста') ||
      normalizedTags.contains('pasta') ||
      ingredientSet.contains('макароны')) {
    return DishProfile.pasta;
  }
  if (normalizedTitle.contains('рагу') ||
      normalizedTags.contains('stew') ||
      ingredientSet.contains('чечевица')) {
    return DishProfile.stew;
  }
  if (normalizedTags.contains('breakfast') ||
      normalizedTitle.contains('завтрак') ||
      normalizedTitle.contains('каша')) {
    return DishProfile.breakfast;
  }
  if (ingredientSet.contains('рис') ||
      ingredientSet.contains('гречка') ||
      ingredientSet.contains('кускус')) {
    return DishProfile.grainBowl;
  }
  if (normalizedTags.contains('one pan') ||
      normalizedTitle.contains('сковород') ||
      normalizedTitle.contains('омлет')) {
    return DishProfile.skillet;
  }
  return DishProfile.general;
}

ChefSupportPlan buildChefSupportPlan({
  required DishProfile profile,
  required Set<String> ingredientCanonicals,
  required Set<String> supportCanonicals,
}) {
  final ingredientSet =
      ingredientCanonicals.map(normalizeIngredientText).toSet();
  final supportSet = supportCanonicals.map(normalizeIngredientText).toSet();
  final allCanonicals = {...ingredientSet, ...supportSet};

  final aromatics = _pickOrdered(
    _recommendedAromatics(profile, ingredientSet),
    ingredientSet,
    limit: 2,
  );
  final seasonings = _pickOrdered(
    _recommendedSeasonings(profile, ingredientSet),
    allCanonicals,
    limit: 3,
  );
  final finishes = _pickOrdered(
    _recommendedFinishes(profile, ingredientSet),
    allCanonicals.difference(ingredientSet),
    limit: 2,
  );

  return ChefSupportPlan(
    profile: profile,
    aromaticCanonicals: aromatics,
    seasoningCanonicals: seasonings,
    finishingCanonicals: finishes,
  );
}

ChefRulesAssessment assessChefRules({
  required DishProfile profile,
  required Set<String> recipeCanonicals,
  required Set<String> matchedCanonicals,
  required Set<String> supportCanonicals,
  required Map<String, String> displayByCanonical,
  required List<String> steps,
}) {
  final recipeSet = recipeCanonicals.map(normalizeIngredientText).toSet();
  final matchedSet = matchedCanonicals.map(normalizeIngredientText).toSet();
  final supportSet = supportCanonicals.map(normalizeIngredientText).toSet();
  final supportPlan = buildChefSupportPlan(
    profile: profile,
    ingredientCanonicals: recipeSet,
    supportCanonicals: supportSet,
  );

  final structureScore = _scoreStructure(
    profile: profile,
    recipeCanonicals: recipeSet,
    matchedCanonicals: matchedSet,
    supportPlan: supportPlan,
  );
  final seasoningScore = _scoreSeasoning(
    profile: profile,
    recipeCanonicals: recipeSet,
    matchedCanonicals: matchedSet,
    supportCanonicals: supportSet,
    supportPlan: supportPlan,
  );
  final techniqueAnalysis = _analyzeTechnique(
    profile: profile,
    recipeCanonicals: recipeSet,
    steps: steps,
  );
  final balanceAnalysis = _analyzeBalance(
    profile: profile,
    recipeCanonicals: recipeSet,
    matchedCanonicals: matchedSet,
    supportCanonicals: supportSet,
    supportPlan: supportPlan,
  );
  final flavorAnalysis = _analyzeFlavor(
    profile: profile,
    recipeCanonicals: recipeSet,
    matchedCanonicals: matchedSet,
    supportCanonicals: supportSet,
  );
  final totalScore = (((structureScore * 0.26) +
              (seasoningScore * 0.18) +
              (techniqueAnalysis.score * 0.20) +
              (balanceAnalysis.score * 0.18) +
              (flavorAnalysis.score * 0.18)) *
          balanceAnalysis.hardPenalty *
          techniqueAnalysis.hardPenalty *
          flavorAnalysis.hardPenalty)
      .clamp(0.0, 1.0);

  return ChefRulesAssessment(
    profile: profile,
    seasoningScore: seasoningScore,
    techniqueScore: techniqueAnalysis.score,
    structureScore: structureScore,
    balanceScore: balanceAnalysis.score,
    flavorScore: flavorAnalysis.score,
    score: totalScore,
    reasons: _buildReasons(
      profile: profile,
      matchedCanonicals: matchedSet,
      supportCanonicals: supportSet,
      displayByCanonical: displayByCanonical,
      supportPlan: supportPlan,
      techniqueAnalysis: techniqueAnalysis,
      balanceAnalysis: balanceAnalysis,
      flavorAnalysis: flavorAnalysis,
    ),
    warnings: _buildWarnings(
      profile: profile,
      matchedCanonicals: matchedSet,
      supportPlan: supportPlan,
      techniqueAnalysis: techniqueAnalysis,
      balanceAnalysis: balanceAnalysis,
      flavorAnalysis: flavorAnalysis,
    ),
    supportPlan: supportPlan,
  );
}

double _scoreStructure({
  required DishProfile profile,
  required Set<String> recipeCanonicals,
  required Set<String> matchedCanonicals,
  required ChefSupportPlan supportPlan,
}) {
  final matchedProteins = _countMatches(matchedCanonicals, _proteinCanonicals);
  final matchedBases = _countMatches(matchedCanonicals, _baseCanonicals);
  final matchedVegetables =
      _countMatches(matchedCanonicals, _vegetableCanonicals);
  final matchedFresh = _countMatches(matchedCanonicals, _freshCanonicals);
  final hasBinder = _containsAny(matchedCanonicals, _binderCanonicals);
  final hasCreamy = _containsAny(matchedCanonicals, _creamyCanonicals);
  final hasAromatics = supportPlan.aromaticCanonicals.isNotEmpty;
  final ingredientCount = recipeCanonicals.length;

  var score = 0.22;
  switch (profile) {
    case DishProfile.soup:
      if (matchedProteins > 0 || matchedBases > 0) {
        score += 0.22;
      }
      if (matchedVegetables >= 2) {
        score += 0.24;
      } else if (matchedVegetables == 1) {
        score += 0.12;
      }
      if (hasAromatics) {
        score += 0.14;
      }
      if (ingredientCount >= 3 && ingredientCount <= 8) {
        score += 0.08;
      }
      break;
    case DishProfile.salad:
      if (matchedFresh >= 2) {
        score += 0.22;
      } else if (matchedFresh == 1) {
        score += 0.10;
      }
      if (matchedProteins > 0) {
        score += 0.20;
      }
      if (hasCreamy || _containsAny(matchedCanonicals, _fatCanonicals)) {
        score += 0.18;
      }
      if (ingredientCount >= 3 && ingredientCount <= 7) {
        score += 0.08;
      }
      break;
    case DishProfile.bake:
      if (matchedBases > 0 || matchedProteins > 0) {
        score += 0.24;
      }
      if (matchedBases > 0 && matchedProteins > 0) {
        score += 0.12;
      }
      if (matchedVegetables > 0) {
        score += 0.12;
      }
      if (hasBinder || hasCreamy) {
        score += 0.16;
      }
      if (ingredientCount >= 3 && ingredientCount <= 8) {
        score += 0.08;
      }
      break;
    case DishProfile.pasta:
    case DishProfile.grainBowl:
      if (matchedBases > 0) {
        score += 0.26;
      }
      if (matchedProteins > 0 || matchedVegetables > 0) {
        score += 0.20;
      }
      if (hasAromatics || hasCreamy) {
        score += 0.16;
      }
      if (ingredientCount >= 3 && ingredientCount <= 7) {
        score += 0.08;
      }
      break;
    case DishProfile.breakfast:
      if (matchedProteins > 0 || matchedBases > 0 || hasCreamy) {
        score += 0.22;
      }
      if (_containsAny(matchedCanonicals, _sweetCanonicals) ||
          _containsAny(matchedCanonicals, _savoryBreakfastCanonicals)) {
        score += 0.18;
      }
      if (hasBinder || hasCreamy) {
        score += 0.12;
      }
      if (ingredientCount >= 2 && ingredientCount <= 6) {
        score += 0.10;
      }
      break;
    case DishProfile.stew:
      if (matchedProteins > 0 || matchedBases > 0) {
        score += 0.22;
      }
      if (matchedVegetables >= 2) {
        score += 0.20;
      }
      if (hasAromatics) {
        score += 0.14;
      }
      if (hasCreamy || _containsAny(matchedCanonicals, _acidCanonicals)) {
        score += 0.10;
      }
      if (ingredientCount >= 3 && ingredientCount <= 8) {
        score += 0.08;
      }
      break;
    case DishProfile.skillet:
    case DishProfile.general:
      if (matchedBases > 0 || matchedProteins > 0) {
        score += 0.22;
      }
      if (matchedVegetables > 0) {
        score += 0.18;
      }
      if (hasAromatics) {
        score += 0.12;
      }
      if (hasBinder ||
          hasCreamy ||
          _containsAny(matchedCanonicals, _fatCanonicals)) {
        score += 0.10;
      }
      if (ingredientCount >= 3 && ingredientCount <= 7) {
        score += 0.10;
      }
      break;
  }

  if (matchedProteins == 0 &&
      matchedBases == 0 &&
      profile != DishProfile.salad &&
      profile != DishProfile.breakfast) {
    score -= 0.14;
  }
  if (matchedCanonicals.isEmpty) {
    score = 0.0;
  }

  return score.clamp(0.0, 1.0);
}

double _scoreSeasoning({
  required DishProfile profile,
  required Set<String> recipeCanonicals,
  required Set<String> matchedCanonicals,
  required Set<String> supportCanonicals,
  required ChefSupportPlan supportPlan,
}) {
  final availableSeasonings = {
    ...matchedCanonicals,
    ...supportCanonicals,
  };
  final recommended =
      _recommendedSeasonings(profile, recipeCanonicals).take(3).toList();
  if (recommended.isEmpty) {
    return 0.6;
  }

  var score = 0.18;
  final matchedRecommended =
      recommended.where(availableSeasonings.contains).length;
  score += (matchedRecommended / recommended.length) * 0.48;

  final hasSavoryFoundation =
      _containsAny(recipeCanonicals, _proteinCanonicals) ||
          _containsAny(recipeCanonicals, _baseCanonicals) ||
          profile == DishProfile.soup ||
          profile == DishProfile.stew ||
          profile == DishProfile.bake;
  final hasSalt = availableSeasonings.contains('соль');
  final hasPepper = availableSeasonings.contains('перец');
  if (hasSavoryFoundation && hasSalt && hasPepper) {
    score += 0.16;
  }
  if (supportPlan.aromaticCanonicals.isNotEmpty) {
    score += 0.10;
  }
  if (profile == DishProfile.breakfast &&
      _containsAny(recipeCanonicals, _sweetCanonicals) &&
      availableSeasonings.contains('корица')) {
    score += 0.12;
  }

  return score.clamp(0.0, 1.0);
}

_TechniqueAnalysis _analyzeTechnique({
  required DishProfile profile,
  required Set<String> recipeCanonicals,
  required List<String> steps,
}) {
  final normalizedSteps = steps
      .map(normalizeIngredientText)
      .where((step) => step.isNotEmpty)
      .toList();
  final stepText = normalizedSteps.join(' ');
  if (stepText.isEmpty) {
    return const _TechniqueAnalysis(
      score: 0.0,
      hardPenalty: 0.76,
      warnings: ['нет шагов приготовления'],
    );
  }

  final expected = switch (profile) {
    DishProfile.soup => ['нареж', 'вар', 'пода'],
    DishProfile.salad => ['нареж', 'смеш', 'заправ'],
    DishProfile.bake => ['подготов', 'запек', 'пода'],
    DishProfile.pasta => ['отвар', 'смеш', 'пода'],
    DishProfile.grainBowl => ['подготов', 'вмеш', 'пода'],
    DishProfile.breakfast => ['смеш', 'жар', 'пода'],
    DishProfile.stew => ['нареж', 'туш', 'пода'],
    DishProfile.skillet => ['нареж', 'обжар', 'пода'],
    DishProfile.general => ['подготов', 'готов', 'пода'],
  };

  var matchedKeywords = 0;
  for (final keyword in expected) {
    if (_containsKeyword(stepText, keyword)) {
      matchedKeywords++;
    }
  }

  final reasons = <String>[];
  final warnings = <String>[];
  var hardPenalty = 1.0;
  var score = 0.20 + ((matchedKeywords / expected.length) * 0.40);
  if (steps.length >= 3) {
    score += 0.12;
  } else if (steps.length == 2) {
    score += 0.06;
  }

  final hasHeat = _containsAnyKeyword(
    stepText,
    const ['жар', 'обжар', 'туш', 'вар', 'запек', 'печ', 'кип', 'прогре'],
  );
  final hasServe = _containsAnyKeyword(
    stepText,
    const ['пода', 'посып', 'довед', 'разлож'],
  );
  final hasMix = _containsAnyKeyword(
    stepText,
    const ['смеш', 'вмеш', 'соед', 'взб', 'заправ'],
  );
  final hasAromaticStart = _containsAnyKeyword(
    stepText,
    const ['обжар', 'пассер', 'прогре'],
  );
  final hasGentleHeat = _containsAnyKeyword(
    stepText,
    const ['умерен', 'слаб', 'под крыш', 'накр', 'том'],
  );
  final hasBoilBase = _containsAnyKeyword(
    stepText,
    const ['отвар', 'свар', 'залей', 'запарь', 'слей'],
  );
  final hasSauceAction = _containsAnyKeyword(
    stepText,
    const ['соус', 'эмульс', 'смеш', 'вмеш', 'добав', 'заправ'],
  );
  final hasMoistureProtection = _containsAnyKeyword(
    stepText,
    const ['соус', 'сметан', 'масл', 'накр', 'бульон', 'слив', 'под крыш'],
  );
  final hasCookThrough = _containsAnyKeyword(
    stepText,
    const ['до готов', 'обжар', 'прожар', 'туш', 'вар', 'запек'],
  );
  final hasFinishLayer = _containsAnyKeyword(
    stepText,
    const ['в конце', 'перед подач', 'сразу пода', 'довед'],
  );
  final hasReduction = _containsAnyKeyword(
    stepText,
    const ['увар', 'выпар', 'загуст', 'сгущ', 'эмульс'],
  );
  final hasLiquidBase = _containsAnyKeyword(
    stepText,
    const ['бульон', 'вода', 'залей', 'долей'],
  );
  final hasCover = _containsAnyKeyword(
    stepText,
    const ['накр', 'под крыш', 'фольг'],
  );
  final hasRest = _containsAnyKeyword(
    stepText,
    const ['отдох', 'дай посто', 'дай полеж'],
  );
  final hasSauceBindingAction =
      hasReduction || _containsKeyword(stepText, 'соус') || (hasMix && hasHeat);
  final hasSauceElements = _containsAny(
        recipeCanonicals,
        _sauceDrivenCanonicals,
      ) &&
      profile != DishProfile.salad &&
      !(profile == DishProfile.breakfast &&
          _isSweetBreakfast(recipeCanonicals));

  void addReason(String value) {
    if (!reasons.contains(value)) {
      reasons.add(value);
    }
  }

  void addWarning(String value) {
    if (!warnings.contains(value)) {
      warnings.add(value);
    }
  }

  switch (profile) {
    case DishProfile.soup:
      if (_containsAny(recipeCanonicals, _aromaticCanonicals)) {
        if (hasAromaticStart) {
          score += 0.10;
          addReason('ароматика раскрывается до варки, а не теряется в воде');
        } else {
          addWarning('для супа ароматику лучше прогреть перед варкой');
        }
      }
      if (_containsAnyKeyword(stepText, const ['вар', 'кип'])) {
        score += 0.12;
      } else {
        addWarning('супу не хватает явной варки основы');
        hardPenalty *= 0.82;
      }
      if (hasLiquidBase) {
        score += 0.05;
      } else {
        addWarning('супу не хватает понятной жидкой основы');
      }
      if (hasGentleHeat) {
        score += 0.08;
        addReason('техника не перегружает суп резким кипением');
      }
      if ((_containsAny(recipeCanonicals, _acidCanonicals) ||
              _containsAny(recipeCanonicals, _herbCanonicals)) &&
          hasFinishLayer) {
        score += 0.08;
        addReason('суп доводится ярким акцентом в конце, а не теряет его в варке');
      }
      break;
    case DishProfile.salad:
      if (hasMix) {
        score += 0.10;
      }
      if (_containsKeyword(stepText, 'заправ')) {
        score += 0.12;
        addReason('салат доводится заправкой прямо перед подачей');
      } else {
        addWarning('салат не доводится заправкой перед подачей');
        hardPenalty *= 0.86;
      }
      break;
    case DishProfile.bake:
      if (_containsAnyKeyword(stepText, const ['запек', 'духов'])) {
        score += 0.14;
      } else {
        addWarning('для духовки не описана основная термообработка');
        hardPenalty *= 0.82;
      }
      if (hasMoistureProtection ||
          _containsAny(recipeCanonicals, _binderCanonicals) ||
          _containsAny(recipeCanonicals, _fatCanonicals)) {
        score += 0.10;
        addReason('есть защита от пересушивания в духовке');
      } else {
        addWarning('духовочному блюду не хватает защиты от пересушивания');
        hardPenalty *= 0.84;
      }
      if (_containsAny(recipeCanonicals, _redMeatCanonicals)) {
        if (hasCover || hasGentleHeat || _containsKeyword(stepText, 'марина')) {
          score += 0.10;
          addReason('мясо в духовке защищено от жёсткого пересушивания');
        } else {
          addWarning('мясу в духовке лучше дать защиту: накрыть, мариновать или готовить мягче');
          hardPenalty *= 0.82;
        }
        if (hasRest) {
          score += 0.06;
          addReason('после духовки мясо отдыхает и теряет меньше сока');
        } else {
          addWarning('после духовки мясу часто полезно дать короткий отдых');
        }
      }
      break;
    case DishProfile.pasta:
      if (hasBoilBase) {
        score += 0.14;
      } else {
        addWarning('пасте не хватает нормальной варки основы');
        hardPenalty *= 0.84;
      }
      if (hasSauceAction) {
        score += 0.14;
        addReason(
            'паста собирается через соус или эмульсию, а не остаётся сухой');
      } else {
        addWarning('пасту лучше собрать соусом или эмульсией');
        hardPenalty *= 0.80;
      }
      break;
    case DishProfile.grainBowl:
      if (hasBoilBase) {
        score += 0.12;
      } else {
        addWarning('основе из крупы не хватает нормального приготовления');
        hardPenalty *= 0.84;
      }
      if (hasMix) {
        score += 0.10;
      } else {
        addWarning('блюдо из крупы не собирается в цельную подачу');
      }
      break;
    case DishProfile.breakfast:
      if (_isSweetBreakfast(recipeCanonicals)) {
        if (hasMix || hasBoilBase || hasHeat) {
          score += 0.12;
        } else {
          addWarning('завтрак описан слишком формально, без понятной техники');
          hardPenalty *= 0.84;
        }
      } else {
        if (hasHeat || hasMix) {
          score += 0.12;
        } else {
          addWarning('завтраку не хватает понятной техники приготовления');
          hardPenalty *= 0.84;
        }
      }
      break;
    case DishProfile.stew:
      if (hasAromaticStart) {
        score += 0.10;
      }
      if (_containsKeyword(stepText, 'туш') || (hasHeat && hasGentleHeat)) {
        score += 0.14;
        addReason('техника даёт продуктам спокойно дойти и обменяться вкусом');
      } else {
        addWarning('для тушения не хватает мягкого доведения под крышкой');
        hardPenalty *= 0.80;
      }
      break;
    case DishProfile.skillet:
      if (hasHeat) {
        score += 0.14;
      } else {
        addWarning('для сковороды не хватает явной обжарки или прогрева');
        hardPenalty *= 0.82;
      }
      if (hasAromaticStart || hasMix) {
        score += 0.08;
      }
      break;
    case DishProfile.general:
      if (hasHeat || hasMix) {
        score += 0.10;
      }
      if (!hasHeat && !_containsAny(recipeCanonicals, _freshReadyCanonicals)) {
        addWarning('техника описана слишком общо');
        hardPenalty *= 0.90;
      }
      break;
  }

  if (_containsAny(recipeCanonicals, const {'курица', 'фарш'})) {
    if (hasCookThrough) {
      score += 0.10;
      addReason('основной белок доводится до готовности, а не остаётся сырым');
    } else {
      addWarning(
          'основному белку не хватает явной термообработки до готовности');
      hardPenalty *= 0.76;
    }
  }

  if (_containsAny(recipeCanonicals, _fishCanonicals)) {
    if (hasCookThrough) {
      score += 0.08;
    } else {
      addWarning('рыбе не хватает явной доводки до готовности');
      hardPenalty *= 0.80;
    }
    if (profile == DishProfile.soup && !hasGentleHeat) {
      addWarning('рыбный суп лучше не кипятить агрессивно');
      hardPenalty *= 0.86;
    }
    if (_containsAny(recipeCanonicals, _acidCanonicals) ||
        _containsAnyKeyword(stepText, const ['лимон', 'соус', 'марина'])) {
      score += 0.08;
      addReason('рыба поддержана кислотой или соусом, вкус будет чище');
    } else {
      addWarning('рыбе часто нужен кислотный или соусный акцент');
    }
  }

  if (_containsAny(recipeCanonicals, _redMeatCanonicals)) {
    if (hasGentleHeat || _containsKeyword(stepText, 'марина')) {
      score += 0.08;
      addReason(
          'мясо готовится через мягкую доводку, а не только грубый нагрев');
    } else if (profile == DishProfile.bake || profile == DishProfile.stew) {
      addWarning('мясу не хватает мягкой доводки или маринада');
      hardPenalty *= 0.84;
    }
  }

  if (_containsAny(recipeCanonicals, _leanProteinCanonicals) &&
      (profile == DishProfile.bake || profile == DishProfile.skillet)) {
    if (hasMoistureProtection ||
        _containsAny(recipeCanonicals, _fatCanonicals) ||
        _containsAny(recipeCanonicals, _acidCanonicals)) {
      score += 0.08;
    } else {
      addWarning('постному белку не хватает защиты от сухости');
      hardPenalty *= 0.84;
    }
  }

  if (hasSauceElements) {
    if (hasSauceBindingAction) {
      score += 0.10;
      addReason('соусная часть действительно связывает блюдо, а не лежит отдельно');
    } else {
      addWarning('соусная часть не доводится и не собирает блюдо');
      hardPenalty *= 0.84;
    }
  }

  if (recipeCanonicals.contains('грибы') && !hasHeat) {
    addWarning('грибам не хватает прогрева или обжарки');
    hardPenalty *= 0.88;
  }

  if (recipeCanonicals.contains('яйцо') &&
      profile != DishProfile.salad &&
      !_containsAnyKeyword(stepText, const ['взб', 'жар', 'вар', 'запек'])) {
    addWarning('яйцу не хватает понятной техники приготовления');
    hardPenalty *= 0.86;
  }

  if (!hasServe) {
    addWarning('не хватает финального шага подачи или доведения вкуса');
  }

  return _TechniqueAnalysis(
    score: score.clamp(0.0, 1.0),
    hardPenalty: hardPenalty.clamp(0.0, 1.0),
    reasons: reasons,
    warnings: warnings,
  );
}

List<String> _buildReasons({
  required DishProfile profile,
  required Set<String> matchedCanonicals,
  required Set<String> supportCanonicals,
  required Map<String, String> displayByCanonical,
  required ChefSupportPlan supportPlan,
  required _TechniqueAnalysis techniqueAnalysis,
  required _BalanceAnalysis balanceAnalysis,
  required _FlavorAnalysis flavorAnalysis,
}) {
  final reasons = <String>[];
  if (supportPlan.aromaticCanonicals.isNotEmpty) {
    reasons.add(
      'есть ароматическая база: ${_formatCanonicals(supportPlan.aromaticCanonicals, displayByCanonical)}',
    );
  }

  final shelfBoosts = supportPlan.seasoningCanonicals
      .where(supportCanonicals.contains)
      .take(2)
      .toList();
  if (shelfBoosts.isNotEmpty) {
    reasons.add(
      'полка усиливает вкус: ${_formatCanonicals(shelfBoosts, displayByCanonical)}',
    );
  }

  switch (profile) {
    case DishProfile.soup:
      if (_containsAny(matchedCanonicals, _proteinCanonicals) ||
          _containsAny(matchedCanonicals, _baseCanonicals)) {
        reasons.add('для супа хватает основы и овощей');
      }
      break;
    case DishProfile.salad:
      if (_countMatches(matchedCanonicals, _freshCanonicals) >= 2) {
        reasons.add('для салата есть свежая база и хруст');
      }
      break;
    case DishProfile.bake:
      if (_containsAny(matchedCanonicals, _binderCanonicals) ||
          _containsAny(matchedCanonicals, _creamyCanonicals)) {
        reasons.add('для духовки есть связка и румяный финиш');
      }
      break;
    case DishProfile.pasta:
    case DishProfile.grainBowl:
      if (_containsAny(matchedCanonicals, _baseCanonicals)) {
        reasons.add('есть база и чем собрать вкус в цельное блюдо');
      }
      break;
    case DishProfile.breakfast:
      reasons.add('собирается в понятный домашний завтрак');
      break;
    case DishProfile.stew:
      reasons.add('мягкое тушение делает вкус глубже и спокойнее');
      break;
    case DishProfile.skillet:
    case DishProfile.general:
      if (_containsAny(matchedCanonicals, _proteinCanonicals) ||
          _containsAny(matchedCanonicals, _baseCanonicals)) {
        reasons.add('для сковороды есть база и продукты для обжарки');
      }
      break;
  }

  for (final techniqueReason in techniqueAnalysis.reasons) {
    if (reasons.length >= 4) {
      break;
    }
    if (!reasons.contains(techniqueReason)) {
      reasons.add(techniqueReason);
    }
  }

  for (final balanceReason in balanceAnalysis.reasons) {
    if (reasons.length >= 4) {
      break;
    }
    if (!reasons.contains(balanceReason)) {
      reasons.add(balanceReason);
    }
  }

  for (final flavorReason in flavorAnalysis.reasons) {
    if (reasons.length >= 4) {
      break;
    }
    if (!reasons.contains(flavorReason)) {
      reasons.add(flavorReason);
    }
  }

  return reasons.take(3).toList();
}

List<String> _buildWarnings({
  required DishProfile profile,
  required Set<String> matchedCanonicals,
  required ChefSupportPlan supportPlan,
  required _TechniqueAnalysis techniqueAnalysis,
  required _BalanceAnalysis balanceAnalysis,
  required _FlavorAnalysis flavorAnalysis,
}) {
  final warnings = <String>[];
  if (supportPlan.aromaticCanonicals.isEmpty &&
      profile != DishProfile.salad &&
      profile != DishProfile.breakfast) {
    warnings.add('нет ароматической базы');
  }
  if (supportPlan.seasoningCanonicals.isEmpty) {
    warnings.add('нечем усилить вкус');
  }
  if (!_containsAny(matchedCanonicals, _proteinCanonicals) &&
      !_containsAny(matchedCanonicals, _baseCanonicals) &&
      profile != DishProfile.salad) {
    warnings.add('не хватает опорного ингредиента');
  }
  for (final warning in techniqueAnalysis.warnings) {
    if (!warnings.contains(warning)) {
      warnings.add(warning);
    }
  }
  for (final warning in balanceAnalysis.warnings) {
    if (!warnings.contains(warning)) {
      warnings.add(warning);
    }
  }
  for (final warning in flavorAnalysis.warnings) {
    if (!warnings.contains(warning)) {
      warnings.add(warning);
    }
  }
  return warnings;
}

_BalanceAnalysis _analyzeBalance({
  required DishProfile profile,
  required Set<String> recipeCanonicals,
  required Set<String> matchedCanonicals,
  required Set<String> supportCanonicals,
  required ChefSupportPlan supportPlan,
}) {
  final availableSet = {...matchedCanonicals, ...supportCanonicals};
  final freshCount = _countMatches(matchedCanonicals, _freshCanonicals);
  final hasProtein = _containsAny(matchedCanonicals, _proteinCanonicals);
  final hasBase = _containsAny(matchedCanonicals, _baseCanonicals);
  final hasFat = _containsAny(availableSet, _fatCanonicals);
  final hasAcid = _containsAny(availableSet, _acidCanonicals);
  final hasBinder = _containsAny(availableSet, _binderCanonicals);
  final hasCreamy = _containsAny(availableSet, _creamyCanonicals);
  final hasSalt = availableSet.contains('соль');
  final hasPepper = availableSet.contains('перец');
  final hasAromatics = supportPlan.aromaticCanonicals.isNotEmpty;
  final hasSweet = _containsAny(recipeCanonicals, _sweetCanonicals);
  final hasSavoryBreakfast = _containsAny(
    matchedCanonicals,
    _savoryBreakfastCanonicals,
  );
  final hasDressingSupport = _containsAny(availableSet, _dressingCanonicals);
  final hasSauceSupport = hasFat || hasAcid || hasCreamy;
  final hasFinishingSupport = supportPlan.finishingCanonicals.isNotEmpty;
  final hasHerbs = _containsAny(availableSet, _herbCanonicals);
  final hasFish = _containsAny(recipeCanonicals, _fishCanonicals);
  final hasRedMeat = _containsAny(recipeCanonicals, _redMeatCanonicals);
  final hasLegumes = _containsAny(recipeCanonicals, _legumeCanonicals);
  final hasWarmSpice = _containsAny(availableSet, _warmSpiceCanonicals);
  final hasTomatoDepth = _containsAny(availableSet, _tomatoDepthCanonicals);
  final hasBrightFinish = _containsAny(availableSet, _brightFinishCanonicals);
  final isSweetBreakfast =
      profile == DishProfile.breakfast && _isSweetBreakfast(recipeCanonicals);

  final reasons = <String>[];
  final warnings = <String>[];
  var score = 0.24;
  var hardPenalty = 1.0;

  void addReason(String value) {
    if (!reasons.contains(value)) {
      reasons.add(value);
    }
  }

  void addWarning(String value) {
    if (!warnings.contains(value)) {
      warnings.add(value);
    }
  }

  switch (profile) {
    case DishProfile.soup:
      if (hasAromatics) {
        score += 0.18;
      } else {
        addWarning('для супа не хватает ароматической базы');
        hardPenalty *= 0.86;
      }
      if (hasSalt && hasPepper) {
        score += 0.12;
      } else {
        addWarning('супу не хватает базовой приправы');
      }
      if (hasFinishingSupport) {
        score += 0.10;
        addReason('есть финиш, который собирает вкус супа');
      }
      if (hasBrightFinish || hasAcid || hasHerbs) {
        score += 0.08;
      } else {
        addWarning('супу не хватает яркого акцента в конце');
      }
      if (hasLegumes) {
        if (hasTomatoDepth || hasAcid || hasHerbs) {
          score += 0.08;
          addReason('бобовая основа не уйдёт в тяжёлый и глухой вкус');
        } else {
          addWarning(
              'бобовому супу не хватает томатного, кислого или травяного акцента');
          hardPenalty *= 0.86;
        }
      }
      if (hasProtein || hasBase) {
        score += 0.10;
      }
      break;
    case DishProfile.salad:
      if (freshCount >= 2) {
        score += 0.18;
      } else {
        addWarning('для салата мало свежей базы');
        hardPenalty *= 0.88;
      }
      if (hasDressingSupport) {
        score += 0.28;
        addReason('есть заправка или мягкая связка для салата');
      } else {
        addWarning('для салата не хватает заправки или соуса');
        hardPenalty *= 0.72;
      }
      if (hasProtein) {
        score += 0.12;
      }
      if (hasAcid || _hasFreshElement(recipeCanonicals, matchedCanonicals)) {
        score += 0.08;
      } else {
        addWarning('салату не хватает свежести или кислотности');
      }
      break;
    case DishProfile.bake:
      if (hasBinder || hasCreamy || hasFat) {
        score += 0.24;
        addReason('для духовки есть связка и защита от сухости');
      } else {
        addWarning('для духовки не хватает связки или защиты от сухости');
        hardPenalty *= 0.70;
      }
      if (hasAromatics) {
        score += 0.12;
      } else {
        addWarning('запеканке не хватает ароматической базы');
      }
      if (hasFinishingSupport) {
        score += 0.10;
      }
      if (hasProtein || hasBase) {
        score += 0.08;
      }
      break;
    case DishProfile.pasta:
    case DishProfile.grainBowl:
      if (hasSauceSupport) {
        score += 0.24;
        addReason('есть чем собрать основу в цельное блюдо');
      } else {
        addWarning('не хватает соуса или жирной связки');
        hardPenalty *= 0.74;
      }
      if (hasAromatics) {
        score += 0.14;
        addReason('ароматика даст глубину вкуса основе');
      } else {
        addWarning('основе не хватает ароматики');
      }
      if (hasSalt && hasPepper) {
        score += 0.08;
      }
      if (hasAcid || freshCount > 0) {
        score += 0.08;
      } else {
        addWarning('не хватает контраста или свежего акцента');
      }
      break;
    case DishProfile.breakfast:
      if (hasSweet && !hasSavoryBreakfast) {
        if (hasCreamy || hasFat) {
          score += 0.22;
          addReason('для сладкого завтрака есть мягкая сливочность');
        } else {
          addWarning('сладкому завтраку не хватает мягкой связки');
          hardPenalty *= 0.82;
        }
        if (availableSet.contains('корица')) {
          score += 0.10;
        }
      } else {
        if (hasFat || hasCreamy || hasBinder) {
          score += 0.18;
          addReason('завтрак не будет сухим или плоским');
        } else {
          addWarning('завтраку не хватает мягкой связки');
          hardPenalty *= 0.82;
        }
        if (hasSalt && hasPepper) {
          score += 0.10;
        }
        if (_hasFreshElement(recipeCanonicals, matchedCanonicals)) {
          score += 0.08;
        }
      }
      break;
    case DishProfile.stew:
      if (hasAromatics) {
        score += 0.18;
        addReason('тушение опирается на хорошую ароматическую базу');
      } else {
        addWarning('для тушения не хватает ароматической базы');
        hardPenalty *= 0.80;
      }
      if (hasSauceSupport) {
        score += 0.16;
      } else {
        addWarning('тушёному блюду не хватает соуса или мягкой связки');
        hardPenalty *= 0.80;
      }
      if (hasAcid) {
        score += 0.08;
      }
      if (hasSalt && hasPepper) {
        score += 0.08;
      }
      if (hasLegumes) {
        if (hasTomatoDepth || hasAcid || hasHerbs) {
          score += 0.08;
        } else {
          addWarning('бобовому блюду не хватает яркого акцента');
          hardPenalty *= 0.86;
        }
      }
      break;
    case DishProfile.skillet:
    case DishProfile.general:
      if (hasAromatics) {
        score += 0.16;
        addReason('есть ароматика для глубины вкуса');
      } else {
        addWarning('для сковороды не хватает ароматической базы');
        hardPenalty *= 0.82;
      }
      if (hasFat || hasCreamy) {
        score += 0.16;
        addReason('есть жир или мягкая связка, чтобы вкус раскрылся');
      } else {
        addWarning('не хватает жира или мягкой связки');
        hardPenalty *= 0.80;
      }
      if (hasAcid || freshCount > 0) {
        score += 0.08;
      }
      if (hasSalt && hasPepper) {
        score += 0.08;
      }
      break;
  }

  if (hasFish) {
    if (hasAcid || hasHerbs) {
      score += 0.10;
      addReason('рыба получает свежий акцент и не уходит в плоский вкус');
    } else {
      addWarning('рыбе не хватает кислоты или травяного акцента');
      hardPenalty *= 0.88;
    }
    if (hasSauceSupport || hasFinishingSupport) {
      score += 0.08;
    }
    if (hasHerbs && (hasAcid || hasCreamy || hasBrightFinish)) {
      score += 0.10;
      addReason('рыба собрана через травы и мягкий финиш');
    } else {
      addWarning('рыбному блюду не хватает травяного или мягкого финиша');
    }
  }

  if (hasRedMeat) {
    if (hasAromatics) {
      score += 0.08;
    } else {
      addWarning('мясу не хватает ароматической базы');
    }
    if (hasAcid || _containsAny(availableSet, _sauceCanonicals)) {
      score += 0.06;
      addReason('есть акцент, который собирает мясную жирность');
    } else {
      addWarning('мясу не хватает соусного или кислотного акцента');
      hardPenalty *= 0.90;
    }
    if (hasAromatics && (hasWarmSpice || hasAcid || hasTomatoDepth)) {
      score += 0.10;
      addReason('мясной вкус поддержан ароматикой и тёплой специей');
    } else {
      addWarning('красному мясу не хватает ароматики или тёплой специи');
      hardPenalty *= 0.88;
    }
  }

  if (isSweetBreakfast &&
      _containsAny(
          availableSet, const {'корица', 'яблоко', 'банан', 'апельсин'})) {
    score += 0.08;
    addReason(
        'сладкий завтрак опирается не только на сладость, но и на аромат');
  }

  if (!hasProtein && !hasBase && profile != DishProfile.salad) {
    hardPenalty *= 0.82;
  }

  return _BalanceAnalysis(
    score: score.clamp(0.0, 1.0),
    hardPenalty: hardPenalty.clamp(0.0, 1.0),
    reasons: reasons,
    warnings: warnings,
  );
}

_FlavorAnalysis _analyzeFlavor({
  required DishProfile profile,
  required Set<String> recipeCanonicals,
  required Set<String> matchedCanonicals,
  required Set<String> supportCanonicals,
}) {
  final availableSet = {...matchedCanonicals, ...supportCanonicals};
  final reasons = <String>[];
  final warnings = <String>[];
  var totalWeight = 0.0;
  var acidity = 0.0;
  var fat = 0.0;
  var sweetness = 0.0;
  var umami = 0.0;
  var freshness = 0.0;
  var spice = 0.0;
  var creaminess = 0.0;
  var herbiness = 0.0;
  var crunch = 0.0;

  void addVector(String canonical, double weight) {
    final vector = _flavorVectors[canonical];
    if (vector == null) {
      return;
    }
    totalWeight += weight;
    acidity += vector.acidity * weight;
    fat += vector.fat * weight;
    sweetness += vector.sweetness * weight;
    umami += vector.umami * weight;
    freshness += vector.freshness * weight;
    spice += vector.spice * weight;
    creaminess += vector.creaminess * weight;
    herbiness += vector.herbiness * weight;
    crunch += vector.crunch * weight;
  }

  for (final canonical in matchedCanonicals) {
    addVector(canonical, 1.0);
  }
  for (final canonical in supportCanonicals.difference(matchedCanonicals)) {
    addVector(canonical, 0.6);
  }

  if (totalWeight <= 0) {
    return const _FlavorAnalysis(
      score: 0.25,
      hardPenalty: 0.82,
      warnings: ['вкусовой профиль блюда пока слишком плоский'],
    );
  }

  acidity /= totalWeight;
  fat /= totalWeight;
  sweetness /= totalWeight;
  umami /= totalWeight;
  freshness /= totalWeight;
  spice /= totalWeight;
  creaminess /= totalWeight;
  herbiness /= totalWeight;
  crunch /= totalWeight;

  var score = 0.24;
  var hardPenalty = 1.0;

  void addReason(String value) {
    if (!reasons.contains(value)) {
      reasons.add(value);
    }
  }

  void addWarning(String value) {
    if (!warnings.contains(value)) {
      warnings.add(value);
    }
  }

  final isSweetBreakfast =
      profile == DishProfile.breakfast && _isSweetBreakfast(recipeCanonicals);
  final hasFish = _containsAny(recipeCanonicals, _fishCanonicals);
  final hasRedMeat = _containsAny(recipeCanonicals, _redMeatCanonicals);
  final hasLegumes = _containsAny(recipeCanonicals, _legumeCanonicals);
  final hasWarmSpice = _containsAny(availableSet, _warmSpiceCanonicals);
  final hasTomatoDepth = _containsAny(availableSet, _tomatoDepthCanonicals);

  switch (profile) {
    case DishProfile.salad:
      if (freshness >= 0.32) {
        score += 0.20;
        addReason('есть свежесть, за счёт которой салат не будет скучным');
      } else {
        score -= 0.04;
        addWarning('салату не хватает свежести');
        hardPenalty *= 0.88;
      }
      if (acidity >= 0.12) {
        score += 0.14;
        addReason('есть кислотность для живого вкуса');
      } else {
        score -= 0.02;
        addWarning('салату не хватает кислотности');
      }
      if (fat >= 0.12) {
        score += 0.14;
      } else if (creaminess >= 0.08) {
        score += 0.08;
      } else {
        score -= 0.04;
        addWarning('салату не хватает жирной опоры');
        hardPenalty *= 0.86;
      }
      if (crunch >= 0.18) {
        score += 0.16;
        addReason('есть хруст, который делает салат живее');
      } else {
        score -= 0.06;
        addWarning('салату не хватает текстурного хруста');
      }
      if (herbiness >= 0.10) {
        score += 0.10;
        addReason('травяной акцент держит салат собранным и свежим');
      }
      if (umami >= 0.12) {
        score += 0.10;
      }
      break;
    case DishProfile.soup:
      if (umami >= 0.20) {
        score += 0.20;
        addReason('есть глубина вкуса и насыщенность');
      } else {
        addWarning('супу не хватает глубины вкуса');
        hardPenalty *= 0.88;
      }
      if (fat >= 0.14) {
        score += 0.12;
      } else {
        addWarning('супу не хватает мягкой жирной опоры');
      }
      if (freshness >= 0.10 || acidity >= 0.10) {
        score += 0.10;
      } else {
        addWarning('супу не хватает свежего или кислого акцента');
      }
      if (herbiness >= 0.08) {
        score += 0.08;
        addReason('травяной акцент помогает супу не казаться тяжёлым');
      }
      if (hasLegumes) {
        if (acidity >= 0.12 || herbiness >= 0.10 || hasTomatoDepth) {
          score += 0.08;
          addReason('бобовая основа не кажется тяжёлой и глухой');
        } else {
          addWarning('бобовому супу не хватает яркого акцента');
          hardPenalty *= 0.86;
        }
      }
      break;
    case DishProfile.bake:
      if (fat >= 0.22) {
        score += 0.18;
        addReason('есть жирность, которая удержит блюдо сочным');
      } else {
        addWarning('духовочному блюду не хватает сочности и жирной опоры');
        hardPenalty *= 0.84;
      }
      if (umami >= 0.22) {
        score += 0.16;
      } else {
        addWarning('запеканию не хватает насыщенного вкуса');
      }
      if (acidity >= 0.08 || freshness >= 0.10) {
        score += 0.08;
      }
      if (creaminess >= 0.16) {
        score += 0.10;
      } else if (_containsAny(recipeCanonicals, _leanProteinCanonicals)) {
        addWarning('запеканию не хватает мягкой сливочной поддержки');
      }
      break;
    case DishProfile.pasta:
    case DishProfile.grainBowl:
    case DishProfile.stew:
    case DishProfile.skillet:
    case DishProfile.general:
      if (umami >= 0.18) {
        score += 0.18;
        addReason('есть насыщенность, которая делает вкус цельным');
      } else {
        addWarning('не хватает умами и насыщенности');
        hardPenalty *= 0.88;
      }
      if (fat >= 0.16) {
        score += 0.14;
      } else {
        addWarning('не хватает жирной опоры');
      }
      if (acidity >= 0.10 || freshness >= 0.14) {
        score += 0.10;
      } else {
        addWarning('не хватает контраста, который освежает вкус');
      }
      if (creaminess >= 0.12) {
        score += 0.08;
      }
      if (spice >= 0.08) {
        score += 0.06;
      }
      if (herbiness >= 0.08) {
        score += 0.06;
      }
      break;
    case DishProfile.breakfast:
      if (isSweetBreakfast) {
        if (sweetness >= 0.18) {
          score += 0.18;
          addReason('есть мягкая сладость для комфортного завтрака');
        } else {
          addWarning('сладкому завтраку не хватает мягкой сладости');
        }
        if (fat >= 0.12) {
          score += 0.12;
        } else {
          addWarning('сладкому завтраку не хватает мягкости');
        }
        if (creaminess >= 0.16) {
          score += 0.10;
          addReason('есть сливочность, которая связывает сладкий завтрак');
        }
        if (freshness >= 0.10 || acidity >= 0.08) {
          score += 0.08;
        }
      } else {
        if (umami >= 0.14) {
          score += 0.16;
          addReason('завтрак не будет пресным');
        } else {
          addWarning('завтраку не хватает насыщенности');
        }
        if (fat >= 0.14) {
          score += 0.12;
        } else {
          addWarning('завтраку не хватает мягкой текстуры');
        }
        if (herbiness >= 0.08 || crunch >= 0.10) {
          score += 0.08;
        }
        if (freshness >= 0.08 || acidity >= 0.08) {
          score += 0.08;
        }
      }
      break;
  }

  if (!isSweetBreakfast &&
      sweetness >= 0.32 &&
      umami >= 0.12 &&
      acidity < 0.12 &&
      freshness < 0.12) {
    addWarning('сладость спорит с основным вкусом блюда');
    hardPenalty *= 0.76;
  }
  if (profile == DishProfile.salad && crunch < 0.10 && freshness < 0.20) {
    addWarning('салат выходит слишком мягким по текстуре');
    hardPenalty *= 0.88;
  }
  if (profile != DishProfile.breakfast && spice >= 0.34 && freshness < 0.12) {
    addWarning('пряность забивает остальные вкусы');
    hardPenalty *= 0.86;
  }
  if (hasFish) {
    if (herbiness >= 0.08 && (acidity >= 0.10 || creaminess >= 0.18)) {
      score += 0.10;
      addReason('рыбный вкус собран мягко и остаётся чистым');
    } else {
      addWarning('рыбному блюду не хватает травяного или соусного акцента');
      hardPenalty *= 0.88;
    }
  }
  if (hasRedMeat) {
    if (spice >= 0.08 || hasWarmSpice || acidity >= 0.12) {
      score += 0.08;
      addReason('мясной вкус поддержан специей и контрастом');
    } else {
      addWarning('мясному блюду не хватает тёплой специи или контраста');
      hardPenalty *= 0.88;
    }
  }
  if (profile == DishProfile.pasta &&
      creaminess < 0.08 &&
      fat < 0.12 &&
      acidity < 0.12) {
    addWarning('паста может выйти сухой и без связки');
    hardPenalty *= 0.84;
  }
  if (hasFish) {
    if (acidity >= 0.12 || herbiness >= 0.12) {
      score += 0.10;
      addReason('рыба поддержана кислотой или травами и звучит чище');
    } else {
      addWarning('рыбе не хватает свежего или травяного акцента');
      hardPenalty *= 0.88;
    }
    if (creaminess >= 0.12 || fat >= 0.18) {
      score += 0.06;
    }
  }
  if (hasRedMeat) {
    if (umami >= 0.24 && fat >= 0.18) {
      score += 0.10;
      addReason('мясная база звучит глубоко и собранно');
    }
    if (spice >= 0.08 || acidity >= 0.10 || herbiness >= 0.08) {
      score += 0.08;
    } else {
      addWarning('мясу не хватает акцента, который освежает жирность');
      hardPenalty *= 0.90;
    }
  }
  if (isSweetBreakfast &&
      sweetness >= 0.36 &&
      acidity < 0.10 &&
      freshness < 0.16) {
    addWarning('сладкому завтраку не хватает свежего контраста');
    hardPenalty *= 0.90;
  }

  final richness = (fat * 0.38) + (creaminess * 0.22) + (umami * 0.40);
  final brightLift = _maxValue([
    acidity,
    freshness,
    herbiness * 0.78,
    crunch * 0.62,
  ]);
  final hasBindingCore = fat >= 0.14 || creaminess >= 0.14;
  final hasContrastCore = acidity >= 0.10 || freshness >= 0.12;
  final hasFreshFinish = herbiness >= 0.10 || freshness >= 0.16;

  if (profile != DishProfile.salad && !isSweetBreakfast) {
    if (richness >= 0.34 && brightLift < 0.16) {
      addWarning('вкусу не хватает яркого финиша и блюдо может выйти тяжёлым');
      hardPenalty *= 0.82;
    } else if (richness >= 0.24 && brightLift >= 0.18) {
      score += 0.08;
      addReason('насыщенность поддержана свежим или кислым финишем');
    }
  }

  switch (profile) {
    case DishProfile.salad:
      if ((acidity >= 0.12 || freshness >= 0.26) &&
          (fat >= 0.12 || creaminess >= 0.14) &&
          (crunch >= 0.16 || herbiness >= 0.10)) {
        score += 0.12;
        addReason('салат собран по балансу: свежесть, связка и текстура');
      } else if (acidity < 0.08 &&
          freshness < 0.20 &&
          crunch < 0.12 &&
          herbiness < 0.08) {
        addWarning('салат получается плоским по вкусу и текстуре');
        hardPenalty *= 0.84;
      }
      break;
    case DishProfile.soup:
    case DishProfile.stew:
      if (umami >= 0.18 && (hasContrastCore || herbiness >= 0.10)) {
        score += 0.08;
        addReason('у основы есть яркий акцент, поэтому вкус не уходит в тяжесть');
      } else if (umami >= 0.18 && acidity < 0.08 && freshness < 0.10) {
        addWarning('основа получается тяжёлой: не хватает яркого акцента');
        hardPenalty *= 0.88;
      }
      break;
    case DishProfile.pasta:
    case DishProfile.grainBowl:
    case DishProfile.skillet:
    case DishProfile.general:
      if (umami >= 0.16 && hasBindingCore && hasContrastCore) {
        score += 0.08;
        addReason('основа собрана через насыщенность, связку и контраст');
      } else if (umami < 0.12 ||
          (!hasBindingCore && fat < 0.12) ||
          (!hasContrastCore && freshness < 0.10)) {
        addWarning('основе не хватает одной из опор: насыщенности, связки или контраста');
        hardPenalty *= 0.88;
      }
      break;
    case DishProfile.bake:
      if (_containsAny(recipeCanonicals, _leanProteinCanonicals) &&
          !hasBindingCore &&
          acidity < 0.10 &&
          creaminess < 0.12) {
        addWarning('постный белок в духовке рискует выйти сухим и плоским');
        hardPenalty *= 0.84;
      }
      if (hasBindingCore && hasFreshFinish) {
        score += 0.08;
        addReason('запекание поддержано сочностью и свежим финишем');
      }
      break;
    case DishProfile.breakfast:
      if (isSweetBreakfast) {
        if (sweetness >= 0.24 &&
            creaminess >= 0.14 &&
            (freshness >= 0.14 || acidity >= 0.10)) {
          score += 0.10;
          addReason('сладкий завтрак сбалансирован мягкостью и свежим контрастом');
        } else if (sweetness >= 0.28 && creaminess < 0.12) {
          addWarning('сладкий завтрак может выйти приторным и сухим');
          hardPenalty *= 0.88;
        }
      } else if (umami >= 0.14 &&
          hasBindingCore &&
          (freshness >= 0.08 || crunch >= 0.10 || herbiness >= 0.08)) {
        score += 0.08;
        addReason('завтрак собран по вкусу и текстуре');
      }
      break;
  }

  if (hasFish &&
      spice >= 0.28 &&
      acidity < 0.10 &&
      herbiness < 0.08 &&
      freshness < 0.12) {
    addWarning('рыба перегружается специей и теряет чистоту вкуса');
    hardPenalty *= 0.82;
  }
  if (hasRedMeat &&
      fat >= 0.24 &&
      acidity < 0.10 &&
      herbiness < 0.08 &&
      spice < 0.08) {
    addWarning('мясной вкус остаётся тяжёлым без акцента и специй');
    hardPenalty *= 0.84;
  }

  return _FlavorAnalysis(
    score: score.clamp(0.0, 1.0),
    hardPenalty: hardPenalty.clamp(0.0, 1.0),
    reasons: reasons,
    warnings: warnings,
  );
}

bool _hasFreshElement(
  Set<String> recipeCanonicals,
  Set<String> matchedCanonicals,
) {
  return _containsAny(matchedCanonicals, _freshCanonicals) ||
      _containsAny(recipeCanonicals, _acidCanonicals);
}

List<String> _recommendedAromatics(
  DishProfile profile,
  Set<String> ingredientCanonicals,
) {
  switch (profile) {
    case DishProfile.soup:
    case DishProfile.stew:
    case DishProfile.skillet:
    case DishProfile.bake:
    case DishProfile.pasta:
    case DishProfile.grainBowl:
      return const ['лук', 'чеснок', 'морковь', 'перец сладкий'];
    case DishProfile.breakfast:
      if (_isSweetBreakfast(ingredientCanonicals)) {
        return const [];
      }
      return const ['лук', 'чеснок'];
    case DishProfile.salad:
    case DishProfile.general:
      return const ['чеснок', 'лук'];
  }
}

List<String> _recommendedSeasonings(
  DishProfile profile,
  Set<String> ingredientCanonicals,
) {
  if (profile == DishProfile.breakfast &&
      _isSweetBreakfast(ingredientCanonicals)) {
    return const ['корица', 'соль'];
  }

  if (_containsAny(ingredientCanonicals, _fishCanonicals)) {
    return const ['соль', 'перец', 'лимон', 'укроп', 'чеснок'];
  }
  if (_containsAny(ingredientCanonicals, _legumeCanonicals)) {
    return const ['соль', 'перец', 'паприка', 'чеснок', 'томатная паста'];
  }
  if (_containsAny(ingredientCanonicals, _redMeatCanonicals)) {
    return const ['соль', 'перец', 'паприка', 'чеснок'];
  }
  if (ingredientCanonicals.contains('индейка')) {
    return const ['соль', 'перец', 'чеснок', 'паприка'];
  }

  switch (profile) {
    case DishProfile.soup:
      return const ['соль', 'перец', 'укроп', 'чеснок', 'паприка'];
    case DishProfile.salad:
      return const ['соль', 'перец', 'укроп', 'чеснок'];
    case DishProfile.bake:
      return const ['соль', 'перец', 'паприка', 'чеснок'];
    case DishProfile.pasta:
      return const ['соль', 'перец', 'чеснок'];
    case DishProfile.grainBowl:
      return const ['соль', 'перец', 'чеснок', 'укроп'];
    case DishProfile.breakfast:
      return const ['соль', 'перец', 'укроп'];
    case DishProfile.stew:
      return const ['соль', 'перец', 'паприка', 'чеснок'];
    case DishProfile.skillet:
    case DishProfile.general:
      return const ['соль', 'перец', 'паприка', 'чеснок'];
  }
}

List<String> _recommendedFinishes(
  DishProfile profile,
  Set<String> ingredientCanonicals,
) {
  if (profile == DishProfile.breakfast &&
      _isSweetBreakfast(ingredientCanonicals)) {
    return const ['масло сливочное', 'молоко', 'сметана'];
  }

  if (_containsAny(ingredientCanonicals, _fishCanonicals)) {
    return const ['лимон', 'укроп', 'оливковое масло', 'сметана'];
  }
  if (_containsAny(ingredientCanonicals, _legumeCanonicals)) {
    return const ['укроп', 'лимон', 'сметана', 'йогурт'];
  }
  if (_containsAny(ingredientCanonicals, _redMeatCanonicals)) {
    return const ['сметана', 'масло', 'паприка'];
  }

  switch (profile) {
    case DishProfile.soup:
      return const ['сметана', 'укроп', 'масло сливочное'];
    case DishProfile.salad:
      return const ['масло', 'оливковое масло', 'сметана', 'майонез', 'лимон'];
    case DishProfile.bake:
      return const ['сыр', 'сметана', 'масло'];
    case DishProfile.pasta:
      return const ['сыр', 'масло', 'оливковое масло'];
    case DishProfile.grainBowl:
      return const ['масло', 'сыр', 'сметана'];
    case DishProfile.breakfast:
      return const ['сыр', 'сметана', 'масло'];
    case DishProfile.stew:
      return const ['сметана', 'укроп', 'масло'];
    case DishProfile.skillet:
    case DishProfile.general:
      return const ['сыр', 'сметана', 'масло'];
  }
}

List<String> _pickOrdered(
  List<String> preferred,
  Set<String> available, {
  required int limit,
}) {
  final picked = <String>[];
  for (final canonical in preferred) {
    if (available.contains(canonical) && !picked.contains(canonical)) {
      picked.add(canonical);
    }
    if (picked.length >= limit) {
      break;
    }
  }
  return picked;
}

bool _containsAny(Set<String> values, Set<String> targets) {
  for (final value in values) {
    if (targets.contains(value)) {
      return true;
    }
  }
  return false;
}

int _countMatches(Set<String> values, Set<String> targets) {
  var count = 0;
  for (final value in values) {
    if (targets.contains(value)) {
      count++;
    }
  }
  return count;
}

String _formatCanonicals(
  List<String> canonicals,
  Map<String, String> displayByCanonical,
) {
  return canonicals
      .map((canonical) => displayByCanonical[canonical] ?? canonical)
      .join(', ');
}

bool _isSweetBreakfast(Set<String> ingredientCanonicals) {
  final hasSweetAnchor = ingredientCanonicals.contains('сахар') ||
      ingredientCanonicals.contains('яблоко') ||
      ingredientCanonicals.contains('корица') ||
      ingredientCanonicals.contains('овсяные хлопья');
  final hasSavoryAnchor = ingredientCanonicals.contains('яйцо') ||
      ingredientCanonicals.contains('сыр') ||
      ingredientCanonicals.contains('помидор') ||
      ingredientCanonicals.contains('лук');
  return hasSweetAnchor && !hasSavoryAnchor;
}

class _BalanceAnalysis {
  final double score;
  final double hardPenalty;
  final List<String> reasons;
  final List<String> warnings;

  const _BalanceAnalysis({
    required this.score,
    required this.hardPenalty,
    required this.reasons,
    required this.warnings,
  });
}

class _TechniqueAnalysis {
  final double score;
  final double hardPenalty;
  final List<String> reasons;
  final List<String> warnings;

  const _TechniqueAnalysis({
    required this.score,
    required this.hardPenalty,
    this.reasons = const [],
    this.warnings = const [],
  });
}

class _FlavorAnalysis {
  final double score;
  final double hardPenalty;
  final List<String> reasons;
  final List<String> warnings;

  const _FlavorAnalysis({
    required this.score,
    required this.hardPenalty,
    this.reasons = const [],
    this.warnings = const [],
  });
}

class _FlavorVector {
  final double acidity;
  final double fat;
  final double sweetness;
  final double umami;
  final double freshness;
  final double spice;
  final double creaminess;
  final double herbiness;
  final double crunch;

  const _FlavorVector({
    this.acidity = 0.0,
    this.fat = 0.0,
    this.sweetness = 0.0,
    this.umami = 0.0,
    this.freshness = 0.0,
    this.spice = 0.0,
    this.creaminess = 0.0,
    this.herbiness = 0.0,
    this.crunch = 0.0,
  });
}

const Set<String> _proteinCanonicals = {
  'курица',
  'рыба',
  'индейка',
  'говядина',
  'свинина',
  'фарш',
  'тунец',
  'яйцо',
  'фасоль',
  'чечевица',
  'сыр',
  'творог',
  'сосиски',
};

const Set<String> _aromaticCanonicals = {
  'лук',
  'чеснок',
  'морковь',
  'перец сладкий',
};

const Set<String> _baseCanonicals = {
  'картофель',
  'рис',
  'макароны',
  'кускус',
  'гречка',
  'овсяные хлопья',
  'хлеб',
};

const Set<String> _vegetableCanonicals = {
  'помидор',
  'огурец',
  'лук',
  'морковь',
  'капуста',
  'кабачок',
  'брокколи',
  'перец сладкий',
  'грибы',
  'яблоко',
};

const Set<String> _freshCanonicals = {
  'помидор',
  'огурец',
  'капуста',
  'яблоко',
  'апельсин',
  'перец сладкий',
  'кукуруза',
};

const Set<String> _freshReadyCanonicals = {
  'огурец',
  'помидор',
  'яблоко',
  'апельсин',
  'банан',
  'творог',
  'тунец',
  'сыр',
  'йогурт',
  'кефир',
};

const Set<String> _fatCanonicals = {
  'масло',
  'оливковое масло',
  'масло сливочное',
  'сметана',
  'майонез',
  'сыр',
  'жирная связка',
};

const Set<String> _acidCanonicals = {
  'помидор',
  'сметана',
  'лимон',
  'йогурт',
  'кефир',
  'апельсин',
  'томатная паста',
  'кетчуп',
  'яблоко',
  'горчица',
  'уксус',
  'кислотный акцент',
};

const Set<String> _dressingCanonicals = {
  'масло',
  'оливковое масло',
  'сметана',
  'майонез',
  'йогурт',
  'кефир',
  'лимон',
  'горчица',
  'уксус',
  'жирная связка',
  'мягкая связка',
  'кислотный акцент',
};

const Set<String> _binderCanonicals = {
  'яйцо',
  'сыр',
  'сметана',
  'мука',
  'молоко',
  'творог',
};

const Set<String> _creamyCanonicals = {
  'сметана',
  'сыр',
  'творог',
  'молоко',
  'йогурт',
  'кефир',
  'масло сливочное',
  'мягкая связка',
};

const Set<String> _sauceCanonicals = {
  'сметана',
  'йогурт',
  'майонез',
  'кетчуп',
  'томатная паста',
  'масло',
  'оливковое масло',
  'молоко',
  'соевый соус',
  'горчица',
  'уксус',
  'томатная глубина',
  'мягкая связка',
  'умами акцент',
};

const Set<String> _sauceDrivenCanonicals = {
  'сметана',
  'йогурт',
  'майонез',
  'кетчуп',
  'томатная паста',
  'масло',
  'оливковое масло',
  'молоко',
  'соевый соус',
  'горчица',
  'уксус',
  'томатная глубина',
  'мягкая связка',
  'жирная связка',
  'умами акцент',
};

const Set<String> _herbCanonicals = {
  'укроп',
  'зелень',
  'базилик',
  'орегано',
  'итальянские травы',
  'прованские травы',
  'травяной акцент',
};

const Set<String> _sweetCanonicals = {
  'сахар',
  'яблоко',
  'банан',
  'апельсин',
  'корица',
  'овсяные хлопья',
};

const Set<String> _legumeCanonicals = {
  'фасоль',
  'чечевица',
};

const Set<String> _warmSpiceCanonicals = {
  'паприка',
  'перец',
  'чеснок',
  'корица',
  'карри',
  'хмели сунели',
  'приправа для курицы',
  'тёплая специя',
};

const Set<String> _tomatoDepthCanonicals = {
  'томатная паста',
  'помидор',
  'кетчуп',
  'томатная глубина',
};

const Set<String> _brightFinishCanonicals = {
  'лимон',
  'укроп',
  'зелень',
  'йогурт',
  'базилик',
  'орегано',
  'кислотный акцент',
  'травяной акцент',
};

const Set<String> _savoryBreakfastCanonicals = {
  'яйцо',
  'сыр',
  'помидор',
  'лук',
};

const Set<String> _fishCanonicals = {
  'рыба',
  'тунец',
};

const Set<String> _redMeatCanonicals = {
  'говядина',
  'свинина',
  'фарш',
};

const Set<String> _leanProteinCanonicals = {
  'курица',
  'индейка',
  'рыба',
};

const Map<String, _FlavorVector> _flavorVectors = {
  'помидор':
      _FlavorVector(acidity: 0.45, umami: 0.24, freshness: 0.48, crunch: 0.14),
  'огурец': _FlavorVector(freshness: 0.68, acidity: 0.06, crunch: 0.46),
  'лимон': _FlavorVector(acidity: 0.95, freshness: 0.34),
  'лук': _FlavorVector(umami: 0.16, sweetness: 0.10, spice: 0.08),
  'чеснок': _FlavorVector(umami: 0.22, freshness: 0.06, spice: 0.18),
  'морковь': _FlavorVector(sweetness: 0.24, freshness: 0.14, crunch: 0.10),
  'перец сладкий':
      _FlavorVector(freshness: 0.34, sweetness: 0.14, crunch: 0.22),
  'укроп': _FlavorVector(freshness: 0.42, herbiness: 0.92),
  'зелень': _FlavorVector(freshness: 0.36, herbiness: 0.84),
  'паприка': _FlavorVector(umami: 0.08, sweetness: 0.06, spice: 0.22),
  'картофель': _FlavorVector(sweetness: 0.06, umami: 0.04, crunch: 0.04),
  'рис': _FlavorVector(),
  'макароны': _FlavorVector(),
  'кускус': _FlavorVector(),
  'гречка': _FlavorVector(umami: 0.08, crunch: 0.04),
  'овсяные хлопья': _FlavorVector(sweetness: 0.08, fat: 0.06, creaminess: 0.12),
  'хлеб': _FlavorVector(umami: 0.04, crunch: 0.22),
  'лаваш': _FlavorVector(umami: 0.04, crunch: 0.10),
  'курица': _FlavorVector(umami: 0.54, fat: 0.18, creaminess: 0.04),
  'рыба':
      _FlavorVector(umami: 0.62, fat: 0.16, freshness: 0.08, creaminess: 0.04),
  'индейка': _FlavorVector(umami: 0.52, fat: 0.10),
  'говядина': _FlavorVector(umami: 0.68, fat: 0.28),
  'свинина': _FlavorVector(umami: 0.62, fat: 0.34),
  'тунец': _FlavorVector(umami: 0.72, fat: 0.16),
  'фарш': _FlavorVector(umami: 0.58, fat: 0.26),
  'яйцо': _FlavorVector(umami: 0.42, fat: 0.26, creaminess: 0.18),
  'сыр': _FlavorVector(umami: 0.78, fat: 0.68, creaminess: 0.46, crunch: 0.04),
  'творог':
      _FlavorVector(umami: 0.26, fat: 0.24, acidity: 0.16, creaminess: 0.58),
  'молоко': _FlavorVector(fat: 0.26, sweetness: 0.16, creaminess: 0.30),
  'сметана': _FlavorVector(acidity: 0.22, fat: 0.56, creaminess: 0.74),
  'майонез': _FlavorVector(acidity: 0.12, fat: 0.86, creaminess: 0.80),
  'йогурт': _FlavorVector(
      acidity: 0.24, fat: 0.18, freshness: 0.12, creaminess: 0.34),
  'кефир': _FlavorVector(
      acidity: 0.28, fat: 0.12, freshness: 0.16, creaminess: 0.28),
  'масло': _FlavorVector(fat: 0.92, creaminess: 0.10),
  'оливковое масло': _FlavorVector(fat: 0.92, creaminess: 0.06),
  'масло сливочное':
      _FlavorVector(fat: 0.95, sweetness: 0.04, creaminess: 0.18),
  'кетчуп':
      _FlavorVector(acidity: 0.22, sweetness: 0.18, umami: 0.18, spice: 0.08),
  'грибы': _FlavorVector(umami: 0.70, creaminess: 0.06),
  'брокколи': _FlavorVector(freshness: 0.30, umami: 0.10, crunch: 0.20),
  'чечевица': _FlavorVector(umami: 0.26),
  'фасоль': _FlavorVector(umami: 0.24),
  'кукуруза': _FlavorVector(sweetness: 0.24, freshness: 0.14, crunch: 0.14),
  'капуста': _FlavorVector(freshness: 0.30, sweetness: 0.08, crunch: 0.56),
  'кабачок': _FlavorVector(freshness: 0.20, sweetness: 0.06, crunch: 0.08),
  'яблоко': _FlavorVector(
      acidity: 0.24, sweetness: 0.46, freshness: 0.44, crunch: 0.28),
  'банан': _FlavorVector(sweetness: 0.62, freshness: 0.16, creaminess: 0.24),
  'апельсин': _FlavorVector(
      acidity: 0.30, sweetness: 0.42, freshness: 0.36, crunch: 0.06),
  'сахар': _FlavorVector(sweetness: 1.0),
  'томатная паста': _FlavorVector(acidity: 0.30, umami: 0.66, spice: 0.04),
  'перец': _FlavorVector(freshness: 0.02, spice: 0.36),
  'соевый соус': _FlavorVector(umami: 0.82, acidity: 0.06, sweetness: 0.06),
  'горчица': _FlavorVector(acidity: 0.26, spice: 0.24, umami: 0.10),
  'уксус': _FlavorVector(acidity: 0.86, freshness: 0.10),
  'базилик': _FlavorVector(freshness: 0.20, herbiness: 0.88),
  'орегано': _FlavorVector(freshness: 0.12, herbiness: 0.80, spice: 0.06),
  'итальянские травы':
      _FlavorVector(freshness: 0.16, herbiness: 0.86, spice: 0.06),
  'прованские травы':
      _FlavorVector(freshness: 0.14, herbiness: 0.84, spice: 0.06),
  'карри': _FlavorVector(umami: 0.16, spice: 0.34, herbiness: 0.10),
  'хмели сунели': _FlavorVector(umami: 0.14, spice: 0.18, herbiness: 0.32),
  'приправа для курицы':
      _FlavorVector(umami: 0.14, spice: 0.22, herbiness: 0.16),
  'тёплая специя': _FlavorVector(spice: 0.20, umami: 0.08),
  'травяной акцент': _FlavorVector(herbiness: 0.72, freshness: 0.14),
  'жирная связка': _FlavorVector(fat: 0.42, creaminess: 0.12),
  'мягкая связка': _FlavorVector(creaminess: 0.46, fat: 0.12, acidity: 0.08),
  'кислотный акцент': _FlavorVector(acidity: 0.46, freshness: 0.10),
  'томатная глубина': _FlavorVector(umami: 0.42, acidity: 0.16),
  'умами акцент': _FlavorVector(umami: 0.42),
  'сладкий акцент': _FlavorVector(sweetness: 0.34),
};

bool _containsKeyword(String text, String keyword) {
  return text.contains(keyword);
}

bool _containsAnyKeyword(String text, List<String> keywords) {
  for (final keyword in keywords) {
    if (_containsKeyword(text, keyword)) {
      return true;
    }
  }
  return false;
}

double _maxValue(List<double> values) {
  var current = 0.0;
  for (final value in values) {
    if (value > current) {
      current = value;
    }
  }
  return current;
}
