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

  if (normalizedTitle.contains('суп') ||
      normalizedTitle.contains('щи') ||
      normalizedTitle.contains('свекольник') ||
      normalizedTitle.contains('борщ') ||
      normalizedTitle.contains('уха') ||
      normalizedTitle.contains('рассольник') ||
      normalizedTitle.contains('солянка')) {
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
      normalizedTitle.contains('оливье') ||
      normalizedTitle.contains('винегрет') ||
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
      normalizedTitle.contains('туш') ||
      normalizedTitle.contains('жарк') ||
      normalizedTitle.contains('гуляш') ||
      normalizedTitle.contains('тефтел') ||
      normalizedTitle.contains('бефстроган') ||
      normalizedTitle.contains('голубц') ||
      normalizedTitle.contains('котлет') ||
      normalizedTags.contains('stew') ||
      ingredientSet.contains('чечевица')) {
    return DishProfile.stew;
  }
  if (normalizedTags.contains('breakfast') ||
      normalizedTitle.contains('завтрак') ||
      normalizedTitle.contains('каша') ||
      normalizedTitle.contains('сырник')) {
    return DishProfile.breakfast;
  }
  if (ingredientSet.contains('рис') ||
      ingredientSet.contains('гречка') ||
      ingredientSet.contains('перловка') ||
      ingredientSet.contains('кускус')) {
    return DishProfile.grainBowl;
  }
  if (normalizedTags.contains('one pan') ||
      normalizedTitle.contains('сковород') ||
      normalizedTitle.contains('омлет') ||
      normalizedTitle.contains('драник')) {
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
    allCanonicals,
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
  String title = '',
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
    title: title,
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
  final isSvekolnik = _isSvekolnikDish(recipeCanonicals);
  final friedDishKind = _detectFriedDishKind(profile, recipeCanonicals);
  final grainDishKind = _detectGrainDishKind(profile, recipeCanonicals);
  final soupKind = _detectSoupKind(recipeCanonicals);
  final stewDishKind = _detectStewDishKind(profile, recipeCanonicals);
  final isCharlotte = _isCharlotteDish(recipeCanonicals);
  final isLiverCake = _isLiverCakeDish(recipeCanonicals);
  final isSauerkrautPreserve = _isSauerkrautPreserveDish(recipeCanonicals);
  final isLightlySaltedCucumbers =
      _isLightlySaltedCucumberDish(recipeCanonicals);
  final isMors = _isMorsDish(recipeCanonicals);

  if (isMors) {
    var score = 0.24;
    if (_containsAny(matchedCanonicals, _morsBerryCanonicals)) {
      score += 0.34;
    }
    if (recipeCanonicals.contains('сахар')) {
      score += 0.18;
    }
    if (recipeCanonicals.contains('лимон')) {
      score += 0.08;
    }
    if (ingredientCount >= 2 && ingredientCount <= 4) {
      score += 0.10;
    }
    if (!_hasMorsDrift(recipeCanonicals)) {
      score += 0.08;
    }
    return score.clamp(0.0, 1.0);
  }

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
      if (isSvekolnik) {
        if (matchedCanonicals.contains('свекла') &&
            matchedCanonicals.contains('картофель') &&
            matchedCanonicals.contains('огурец')) {
          score += 0.18;
        }
        if (matchedCanonicals.contains('яйцо')) {
          score += 0.08;
        }
        if (_containsAny(matchedCanonicals, _coldSoupBaseCanonicals)) {
          score += 0.08;
        }
        if (hasCreamy || _containsAny(matchedCanonicals, _herbCanonicals)) {
          score += 0.06;
        }
        break;
      }
      switch (soupKind) {
        case _SoupKind.greenShchi:
          if (matchedCanonicals.contains('щавель') && matchedVegetables >= 2) {
            score += 0.16;
          }
          if (_containsAny(matchedCanonicals, const {'яйцо', 'курица'})) {
            score += 0.08;
          }
          if (hasCreamy || _containsAny(matchedCanonicals, _herbCanonicals)) {
            score += 0.06;
          }
          break;
        case _SoupKind.mushroom:
          if (matchedCanonicals.contains('грибы') &&
              matchedCanonicals.contains('картофель') &&
              _containsAny(matchedCanonicals, const {'лук', 'морковь'})) {
            score += 0.16;
          }
          if (hasCreamy || _containsAny(matchedCanonicals, _herbCanonicals)) {
            score += 0.06;
          }
          break;
        case _SoupKind.peaSmoked:
          if (matchedCanonicals.contains('горох') &&
              _containsAny(matchedCanonicals, const {'колбаса', 'сосиски'}) &&
              _containsAny(matchedCanonicals, const {'лук', 'морковь'})) {
            score += 0.16;
          }
          if (matchedCanonicals.contains('картофель')) {
            score += 0.04;
          }
          if (hasCreamy || _containsAny(matchedCanonicals, _herbCanonicals)) {
            score += 0.06;
          }
          break;
        case _SoupKind.shchi:
          if (matchedCanonicals.contains('капуста') && matchedVegetables >= 2) {
            score += 0.14;
          }
          if (hasCreamy || _containsAny(matchedCanonicals, _herbCanonicals)) {
            score += 0.06;
          }
          break;
        case _SoupKind.borscht:
          if (matchedCanonicals.contains('свекла') &&
              matchedCanonicals.contains('капуста')) {
            score += 0.16;
          }
          if (_containsAny(matchedCanonicals, _tomatoDepthCanonicals) ||
              hasCreamy) {
            score += 0.08;
          }
          break;
        case _SoupKind.ukha:
          if (matchedCanonicals.contains('рыба') && matchedVegetables >= 2) {
            score += 0.12;
          }
          break;
        case _SoupKind.rassolnik:
          if (matchedCanonicals.contains('перловка') &&
              matchedCanonicals.contains('огурец')) {
            score += 0.14;
          }
          break;
        case _SoupKind.solyanka:
          if (_containsAny(
                matchedCanonicals,
                const {'колбаса', 'сосиски', 'говядина'},
              ) &&
              matchedCanonicals.contains('огурец')) {
            score += 0.16;
          }
          if (_containsAny(matchedCanonicals, _tomatoDepthCanonicals) ||
              matchedCanonicals.contains('оливки') ||
              matchedCanonicals.contains('лимон')) {
            score += 0.08;
          }
          break;
        case _SoupKind.none:
          break;
      }
      break;
    case DishProfile.salad:
      if (isSauerkrautPreserve) {
        if (matchedCanonicals.contains('капуста')) {
          score += 0.30;
        }
        if (supportPlan.seasoningCanonicals.contains('соль') ||
            recipeCanonicals.contains('соль')) {
          score += 0.16;
        }
        if (matchedCanonicals.contains('морковь')) {
          score += 0.10;
        }
        if (ingredientCount >= 2 && ingredientCount <= 4) {
          score += 0.10;
        }
        break;
      }
      if (isLightlySaltedCucumbers) {
        if (matchedCanonicals.contains('огурец')) {
          score += 0.28;
        }
        if (matchedCanonicals.contains('укроп') &&
            matchedCanonicals.contains('чеснок')) {
          score += 0.22;
        }
        if (supportPlan.seasoningCanonicals.contains('соль') ||
            recipeCanonicals.contains('соль')) {
          score += 0.14;
        }
        if (ingredientCount >= 3 && ingredientCount <= 5) {
          score += 0.08;
        }
        break;
      }
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
      if (isCharlotte) {
        if (matchedCanonicals.contains('яблоко') &&
            matchedCanonicals.contains('яйцо') &&
            matchedCanonicals.contains('мука')) {
          score += 0.34;
        }
        if (hasBinder) {
          score += 0.12;
        }
        if (matchedFresh > 0) {
          score += 0.10;
        }
        if (ingredientCount >= 3 && ingredientCount <= 6) {
          score += 0.10;
        }
        break;
      }
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
      if (grainDishKind == _GrainDishKind.buckwheatRustic) {
        if (matchedCanonicals.contains('гречка') &&
            _containsAny(
              matchedCanonicals,
              const {'грибы', 'лук', 'морковь'},
            )) {
          score += 0.18;
        }
        if (_containsAny(
          matchedCanonicals,
          const {'грибы', 'курица', 'говядина', 'сосиски'},
        )) {
          score += 0.08;
        }
      }
      break;
    case DishProfile.breakfast:
      switch (friedDishKind) {
        case _FriedDishKind.blini:
          if (_containsAny(matchedCanonicals, const {'мука'}) &&
              matchedCanonicals.contains('яйцо') &&
              matchedCanonicals.contains('молоко')) {
            score += 0.30;
          }
          if (hasBinder || hasCreamy) {
            score += 0.12;
          }
          if (ingredientCount >= 3 && ingredientCount <= 6) {
            score += 0.10;
          }
          break;
        case _FriedDishKind.oladyi:
          if (_containsAny(matchedCanonicals, const {'мука'}) &&
              matchedCanonicals.contains('яйцо') &&
              matchedCanonicals.contains('кефир')) {
            score += 0.30;
          }
          if (_containsAny(matchedCanonicals, _sweetCanonicals) || hasCreamy) {
            score += 0.12;
          }
          if (ingredientCount >= 3 && ingredientCount <= 6) {
            score += 0.10;
          }
          break;
        case _FriedDishKind.syrniki:
          if (matchedCanonicals.contains('творог') &&
              matchedCanonicals.contains('яйцо')) {
            score += 0.30;
          }
          if (_containsAny(matchedCanonicals, _sweetCanonicals) || hasCreamy) {
            score += 0.14;
          }
          if (ingredientCount >= 2 && ingredientCount <= 5) {
            score += 0.10;
          }
          break;
        case _FriedDishKind.none:
        case _FriedDishKind.draniki:
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
      switch (stewDishKind) {
        case _StewDishKind.stewedCabbage:
          if (matchedCanonicals.contains('капуста') &&
              _containsAny(matchedCanonicals, const {'лук', 'морковь'})) {
            score += 0.24;
          }
          if (_containsAny(
            matchedCanonicals,
            const {'томатная паста', 'колбаса', 'сосиски', 'курица', 'свинина'},
          )) {
            score += 0.10;
          }
          if (hasAromatics ||
              _containsAny(matchedCanonicals, _herbCanonicals)) {
            score += 0.06;
          }
          break;
        case _StewDishKind.lazyCabbageRolls:
          if (matchedCanonicals.contains('фарш') &&
              matchedCanonicals.contains('рис') &&
              matchedCanonicals.contains('капуста')) {
            score += 0.26;
          }
          if (_containsAny(matchedCanonicals, _tomatoDepthCanonicals) ||
              hasCreamy) {
            score += 0.08;
          }
          break;
        case _StewDishKind.zrazy:
          if (matchedCanonicals.contains('фарш') &&
              _containsAny(
                matchedCanonicals,
                const {'картофель', 'гречка'},
              ) &&
              _containsAny(
                matchedCanonicals,
                const {'яйцо', 'грибы'},
              )) {
            score += 0.28;
          }
          if (matchedVegetables > 0 || hasAromatics) {
            score += 0.08;
          }
          if (hasCreamy || _containsAny(matchedCanonicals, _fatCanonicals)) {
            score += 0.06;
          }
          break;
        case _StewDishKind.homeCutlets:
          if (matchedCanonicals.contains('фарш') &&
              _containsAny(
                  matchedCanonicals, const {'картофель', 'гречка', 'рис'})) {
            score += 0.26;
          }
          if (matchedVegetables > 0 || hasAromatics) {
            score += 0.08;
          }
          break;
        case _StewDishKind.tefteli:
          if (matchedCanonicals.contains('фарш') &&
              matchedCanonicals.contains('рис')) {
            score += 0.24;
          }
          if (_containsAny(
            matchedCanonicals,
            const {'томатная паста', 'сметана'},
          )) {
            score += 0.10;
          }
          if (matchedVegetables > 0 || hasAromatics) {
            score += 0.08;
          }
          break;
        case _StewDishKind.goulash:
          if (_containsAny(
                matchedCanonicals,
                const {'говядина', 'свинина'},
              ) &&
              matchedCanonicals.contains('лук')) {
            score += 0.24;
          }
          if (_containsAny(
            matchedCanonicals,
            const {'паприка', 'томатная паста'},
          )) {
            score += 0.10;
          }
          if (matchedVegetables > 0 || hasAromatics) {
            score += 0.08;
          }
          break;
        case _StewDishKind.stroganoff:
          if (matchedCanonicals.contains('говядина') &&
              matchedCanonicals.contains('лук')) {
            score += 0.24;
          }
          if (matchedCanonicals.contains('сметана')) {
            score += 0.10;
          }
          if (matchedCanonicals.contains('грибы') || hasAromatics) {
            score += 0.08;
          }
          break;
        case _StewDishKind.zharkoe:
          if (matchedCanonicals.contains('картофель') &&
              _containsAny(
                matchedCanonicals,
                const {'говядина', 'свинина', 'курица'},
              )) {
            score += 0.28;
          }
          if (matchedVegetables > 0 || hasAromatics) {
            score += 0.08;
          }
          break;
        case _StewDishKind.none:
          break;
      }
      break;
    case DishProfile.skillet:
    case DishProfile.general:
      if (isLiverCake) {
        if (matchedCanonicals.contains('печень') &&
            matchedCanonicals.contains('яйцо') &&
            matchedCanonicals.contains('мука')) {
          score += 0.30;
        }
        if (matchedCanonicals.contains('лук') &&
            matchedCanonicals.contains('морковь')) {
          score += 0.18;
        }
        if (_containsAny(matchedCanonicals, const {'майонез', 'сметана'})) {
          score += 0.12;
        }
        if (ingredientCount >= 5 && ingredientCount <= 7) {
          score += 0.10;
        }
      } else if (friedDishKind == _FriedDishKind.draniki) {
        if (matchedCanonicals.contains('картофель')) {
          score += 0.28;
        }
        if (matchedCanonicals.contains('лук')) {
          score += 0.16;
        }
        if (hasBinder || hasCreamy) {
          score += 0.10;
        }
        if (ingredientCount >= 2 && ingredientCount <= 5) {
          score += 0.10;
        }
      } else {
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
      }
      break;
  }

  if (matchedProteins == 0 &&
      matchedBases == 0 &&
      profile != DishProfile.salad &&
      profile != DishProfile.breakfast &&
      !isMors) {
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
  final isCharlotte = _isCharlotteDish(recipeCanonicals);
  final isSauerkrautPreserve = _isSauerkrautPreserveDish(recipeCanonicals);
  final isLightlySaltedCucumbers =
      _isLightlySaltedCucumberDish(recipeCanonicals);
  final isMors = _isMorsDish(recipeCanonicals);
  final recommended =
      _recommendedSeasonings(profile, recipeCanonicals).take(3).toList();
  if (recommended.isEmpty) {
    return 0.6;
  }

  var score = 0.18;
  final matchedRecommended =
      recommended.where(availableSeasonings.contains).length;
  score += (matchedRecommended / recommended.length) * 0.48;

  if (isSauerkrautPreserve) {
    if (availableSeasonings.contains('соль')) {
      score += 0.24;
    }
    if (recipeCanonicals.contains('морковь')) {
      score += 0.08;
    }
    return score.clamp(0.0, 1.0);
  }

  if (isLightlySaltedCucumbers) {
    if (availableSeasonings.contains('соль')) {
      score += 0.18;
    }
    if (availableSeasonings.contains('укроп')) {
      score += 0.10;
    }
    if (availableSeasonings.contains('чеснок')) {
      score += 0.10;
    }
    return score.clamp(0.0, 1.0);
  }

  if (isCharlotte) {
    if (availableSeasonings.contains('сахар')) {
      score += 0.16;
    }
    if (availableSeasonings.contains('корица')) {
      score += 0.12;
    }
    if (availableSeasonings.contains('соль')) {
      score += 0.06;
    }
    return score.clamp(0.0, 1.0);
  }

  if (isMors) {
    if (availableSeasonings.contains('сахар')) {
      score += 0.30;
    }
    if (availableSeasonings.contains('лимон')) {
      score += 0.12;
    }
    return score.clamp(0.0, 1.0);
  }

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
  String title = '',
  required Set<String> recipeCanonicals,
  required List<String> steps,
}) {
  final normalizedSteps = steps
      .map(normalizeIngredientText)
      .where((step) => step.isNotEmpty)
      .toList();
  final normalizedTitle = normalizeIngredientText(title);
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
  final hasColdAssembly = _containsAnyKeyword(
    stepText,
    const ['остуд', 'охлад', 'в холод', 'холодн'],
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
  final isColdSoup = _isColdSoupDish(recipeCanonicals);
  final isSvekolnik = _isSvekolnikDish(recipeCanonicals);
  final friedDishKind = _detectFriedDishKind(profile, recipeCanonicals);
  final grainDishKind = _detectGrainDishKind(profile, recipeCanonicals);
  final soupKind = _detectSoupKind(recipeCanonicals);
  final stewDishKind = _detectStewDishKind(profile, recipeCanonicals);
  final isPanBatter = friedDishKind == _FriedDishKind.blini;
  final isFritterBatter = friedDishKind == _FriedDishKind.oladyi;
  final isCurdFritter = friedDishKind == _FriedDishKind.syrniki;
  final isPotatoFritter = friedDishKind == _FriedDishKind.draniki;
  final isCharlotte = _isCharlotteDish(recipeCanonicals);
  final isLiverCake = _isLiverCakeDish(recipeCanonicals);
  final isSauerkrautPreserve = _isSauerkrautPreserveDish(recipeCanonicals);
  final isLightlySaltedCucumbers =
      _isLightlySaltedCucumberDish(recipeCanonicals);
  final isMors = _isMorsDish(recipeCanonicals);
  final isBitochki =
      normalizedTitle.contains('биточ') || _containsKeyword(stepText, 'биточ');

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

  if (isMors) {
    score = 0.28;
    if (_containsAnyKeyword(stepText, const ['разомни', 'раздав', 'протри'])) {
      score += 0.14;
      addReason('ягоды сначала раскрываются, а не варятся без подготовки');
    } else {
      addWarning('морсу нужно сначала раздавить ягоды');
      hardPenalty *= 0.80;
    }
    if (_containsAnyKeyword(
      stepText,
      const ['отдели сок', 'убери его в холод', 'сохрани сок'],
    )) {
      score += 0.14;
      addReason('часть ягодного сока сохраняется для живого вкуса');
    } else {
      addWarning('морсу полезно отдельно сохранить ягодный сок');
      hardPenalty *= 0.82;
    }
    if ((_containsKeyword(stepText, 'залей') ||
            _containsKeyword(stepText, 'влей')) &&
        _containsKeyword(stepText, 'вод')) {
      score += 0.12;
      addReason(
          'ягодная основа собирается на воде, а не уходит в густую массу');
    } else {
      addWarning('морсу нужна явная водная основа');
      hardPenalty *= 0.84;
    }
    if (_containsAnyKeyword(stepText, const ['процеди', 'процеж'])) {
      score += 0.12;
      addReason('основа процеживается и остаётся чистой по текстуре');
    } else {
      addWarning('морс нужно процедить после прогрева ягодной основы');
      hardPenalty *= 0.82;
    }
    if (_containsAnyKeyword(stepText, const ['остуди', 'охлади', 'в холод'])) {
      score += 0.12;
      addReason('напиток успевает остыть и сохраняет холодный профиль');
    } else {
      addWarning('морс нужно охладить перед подачей');
      hardPenalty *= 0.80;
    }
    if (_containsAnyKeyword(
      stepText,
      const ['бурно кипяти', 'сильном огне'],
    )) {
      addWarning('морс нельзя агрессивно кипятить, иначе вкус уйдёт в компот');
      hardPenalty *= 0.76;
    }
    if (_containsAnyKeyword(
      stepText,
      const ['молок', 'кефир', 'йогурт', 'крахмал'],
    )) {
      addWarning('морс не должен уходить в молочный напиток или кисель');
      hardPenalty *= 0.72;
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

  switch (profile) {
    case DishProfile.soup:
      if (isColdSoup) {
        if (_containsAnyKeyword(stepText, const ['отвари', 'вари'])) {
          score += 0.10;
        } else {
          addWarning(
              'холодному супу нужно отдельно довести основу до готовности');
          hardPenalty *= 0.84;
        }
        if (hasLiquidBase ||
            _containsKeyword(stepText, 'кефир') ||
            _containsKeyword(stepText, 'квас')) {
          score += 0.08;
          addReason(
              'жидкая холодная база добавляется осознанно, а не случайно');
        } else {
          addWarning('холодному супу не хватает явной жидкой базы');
          hardPenalty *= 0.84;
        }
        if (hasColdAssembly) {
          score += 0.12;
          addReason('холодный суп остужается и собирается без потери свежести');
        } else {
          addWarning('холодный суп должен охлаждаться перед подачей');
          hardPenalty *= 0.80;
        }
        if (hasFinishLayer || _containsAny(recipeCanonicals, _herbCanonicals)) {
          score += 0.08;
          addReason('свежий финиш не теряется в горячей обработке');
        }
        if (_containsAnyKeyword(
          stepText,
          const ['кипяти', 'доведи до кипения', 'бурно кип'],
        )) {
          addWarning('холодный суп нельзя кипятить после сборки');
          hardPenalty *= 0.74;
        }
        if (isSvekolnik) {
          if (_containsAnyKeyword(
                stepText,
                const ['остуди', 'полностью остуди', 'охлади'],
              ) &&
              _containsKeyword(stepText, 'свекл')) {
            score += 0.10;
            addReason('свекольная основа охлаждается отдельно и не мутнеет');
          } else {
            addWarning('свекольнику нужно отдельно остудить свекольную основу');
            hardPenalty *= 0.82;
          }
          if ((_containsKeyword(stepText, 'влей') &&
                  _containsAnyKeyword(stepText, const ['кефир', 'квас'])) ||
              (_containsAnyKeyword(stepText, const ['кефир', 'квас']) &&
                  hasColdAssembly)) {
            score += 0.08;
            addReason(
                'свекольник собирается на холодной базе, а не как горячий суп');
          } else {
            addWarning(
                'свекольник должен собираться на холодной базе после охлаждения');
            hardPenalty *= 0.84;
          }
        }
        break;
      }
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
        addReason(
            'суп доводится ярким акцентом в конце, а не теряет его в варке');
      }
      switch (soupKind) {
        case _SoupKind.greenShchi:
          if (_containsAnyKeyword(
                stepText,
                const ['в конце', 'за 2-3 минуты', 'в последние 2-3 минуты'],
              ) &&
              _containsKeyword(stepText, 'щавел')) {
            score += 0.12;
            addReason('щавель входит в суп поздно и сохраняет свежую кислоту');
          } else {
            addWarning('щавелевые щи требуют позднего добавления щавеля');
            hardPenalty *= 0.82;
          }
          if (_containsAnyKeyword(stepText, const ['сметан', 'укроп', 'яйц'])) {
            score += 0.06;
            addReason('щавелевые щи получают мягкий домашний финиш');
          }
          break;
        case _SoupKind.mushroom:
          if (_containsKeyword(stepText, 'гриб') &&
              _containsAnyKeyword(
                stepText,
                const ['прогрей', 'обжар', 'выпар'],
              )) {
            score += 0.10;
            addReason('грибы сначала раскрываются с ароматической базой');
          } else {
            addWarning(
                'грибному супу нужно сначала прогреть грибы, а не варить их сырыми');
            hardPenalty *= 0.86;
          }
          if (_containsAnyKeyword(
              stepText, const ['сметан', 'укроп', 'лавров'])) {
            score += 0.06;
            addReason('грибной суп получает мягкий домашний финиш');
          } else {
            addWarning('грибному супу не хватает мягкого домашнего финиша');
            hardPenalty *= 0.88;
          }
          break;
        case _SoupKind.peaSmoked:
          if (_containsAnyKeyword(
                stepText,
                const ['промой горох', 'замочи горох', 'промой'],
              ) &&
              _containsKeyword(stepText, 'горох')) {
            score += 0.10;
            addReason(
                'горох подготовлен заранее и не даёт супу грубую текстуру');
          } else {
            addWarning(
                'гороховому супу нужно промыть или замочить горох до варки');
            hardPenalty *= 0.84;
          }
          if (_containsAnyKeyword(
                stepText,
                const [
                  '35-45 минут',
                  '40-45 минут',
                  '35-40 минут',
                  '30-35 минут',
                ],
              ) &&
              _containsKeyword(stepText, 'горох')) {
            score += 0.12;
            addReason('горох томится достаточно долго и успевает стать мягким');
          } else {
            addWarning('гороховому супу нужна длинная спокойная варка гороха');
            hardPenalty *= 0.82;
          }
          if (_containsAnyKeyword(
                stepText,
                const ['копч', 'охотнич', 'сервелат', 'ветчин'],
              ) &&
              _containsAnyKeyword(
                stepText,
                const ['прогрей', 'обжар', 'добавь'],
              )) {
            score += 0.10;
            addReason('копчёная основа раскрывается до основной варки');
          } else {
            addWarning(
                'гороховому супу нужна явная копчёная основа, раскрытая до варки');
            hardPenalty *= 0.84;
          }
          if (_containsAnyKeyword(stepText, const ['укроп', 'сметан'])) {
            score += 0.06;
            addReason('гороховый суп получает мягкий домашний финиш');
          }
          break;
        case _SoupKind.shchi:
          if (recipeCanonicals.contains('капуста') && hasGentleHeat) {
            score += 0.08;
            addReason(
                'щи варятся спокойно и сохраняют мягкую капустную основу');
          } else if (recipeCanonicals.contains('капуста')) {
            addWarning('щам нужна спокойная варка без резкого кипения');
            hardPenalty *= 0.88;
          }
          if (_containsAnyKeyword(
            stepText,
            const ['сметан', 'укроп', 'лавров'],
          )) {
            score += 0.06;
            addReason('у щей есть домашний капустный финиш');
          }
          break;
        case _SoupKind.borscht:
          if (_containsAnyKeyword(
                stepText,
                const ['прогрей', 'обжар'],
              ) &&
              (_containsAny(recipeCanonicals, _tomatoDepthCanonicals)
                  ? _containsAnyKeyword(stepText, const ['томатн'])
                  : true)) {
            score += 0.10;
            addReason('свекольная и томатная база раскрывается до варки');
          } else {
            addWarning(
                'борщу полезно прогреть свекольную базу до основной варки');
            hardPenalty *= 0.88;
          }
          if (_containsAnyKeyword(stepText, const ['сметан', 'укроп'])) {
            score += 0.08;
            addReason('борщ получает мягкий домашний финиш в конце');
          } else {
            addWarning('борщу не хватает мягкого домашнего финиша');
            hardPenalty *= 0.88;
          }
          break;
        case _SoupKind.ukha:
        case _SoupKind.rassolnik:
          break;
        case _SoupKind.solyanka:
          if (_containsAny(recipeCanonicals, _tomatoDepthCanonicals) &&
              _containsAnyKeyword(stepText, const ['томатн', 'прогрей'])) {
            score += 0.10;
            addReason('соляно-томатная база собирается до основной варки');
          } else {
            addWarning('солянке не хватает собранной томатной базы');
            hardPenalty *= 0.88;
          }
          if (_containsAnyKeyword(
                  stepText, const ['в конце', 'перед подачей']) &&
              _containsAnyKeyword(
                  stepText, const ['олив', 'маслин', 'лимон'])) {
            score += 0.10;
            addReason('яркий соляно-кислый финиш добавляется в самом конце');
          } else {
            addWarning('солянке нужен яркий лимонный или оливковый финиш');
            hardPenalty *= 0.86;
          }
          break;
        case _SoupKind.none:
          break;
      }
      break;
    case DishProfile.salad:
      if (isSauerkrautPreserve) {
        if (_containsAnyKeyword(
          stepText,
          const ['перетри капусту', 'пока она не даст сок', 'даст сок'],
        )) {
          score += 0.16;
          addReason('капуста перетирается с солью и даёт собственный сок');
        } else {
          addWarning(
              'квашеной капусте нужно дать собственный сок через перетирание');
          hardPenalty *= 0.78;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['утрамбуй', 'под соком', 'прижми так'],
        )) {
          score += 0.14;
          addReason('капуста утрамбовывается и остаётся под соком');
        } else {
          addWarning('квашеную капусту нужно утрамбовать и держать под соком');
          hardPenalty *= 0.80;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['2-3 дня', 'при комнатной температуре'],
        )) {
          score += 0.14;
          addReason('ферментация получает нужную выдержку, а не спешит');
        } else {
          addWarning(
              'квашеной капусте нужна выдержка 2-3 дня при комнатной температуре');
          hardPenalty *= 0.76;
        }
        if (_containsAnyKeyword(
            stepText, const ['прокалывай', 'выпуская газ'])) {
          score += 0.08;
          addReason('во время ферментации из капусты выпускается лишний газ');
        } else {
          addWarning('квашеную капусту нужно прокалывать во время ферментации');
          hardPenalty *= 0.86;
        }
        if (hasColdAssembly ||
            _containsAnyKeyword(
              stepText,
              const ['в холод', 'подавай холодной'],
            )) {
          score += 0.08;
          addReason('после ферментации капуста стабилизируется в холоде');
        } else {
          addWarning('после ферментации квашеную капусту нужно охладить');
        }
        if (_containsAnyKeyword(
          stepText,
          const ['уксус', 'маринуй', 'обжар', 'сковород', 'запекай', 'майонез'],
        )) {
          addWarning(
              'квашеная капуста не должна уходить в уксусный маринад, жарку или салатную заправку');
          hardPenalty *= 0.72;
        }
        break;
      }
      if (isLightlySaltedCucumbers) {
        if (_containsAnyKeyword(
          stepText,
          const ['срежь кончики', 'кончики у огурцов'],
        )) {
          score += 0.10;
          addReason(
              'огурцы подготавливаются для ровного и быстрого просаливания');
        } else {
          addWarning(
              'малосольным огурцам нужно срезать кончики перед засолкой');
          hardPenalty *= 0.84;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['слоями', 'укропом', 'чесноком'],
        )) {
          score += 0.10;
          addReason('огурцы собираются слоями с укропом и чесноком');
        } else {
          addWarning(
              'малосольным огурцам нужна слоёная укропно-чесночная сборка');
        }
        if (_containsAnyKeyword(
          stepText,
          const ['залей огурцы рассолом', 'рассолом', 'полностью покрыты'],
        )) {
          score += 0.16;
          addReason(
              'огурцы солятся в явном рассоле, а не просто приправляются');
        } else {
          addWarning(
              'малосольным огурцам нужен рассол, который покрывает огурцы');
          hardPenalty *= 0.78;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['8-12 часов', 'на ночь', 'при комнатной температуре'],
        )) {
          score += 0.14;
          addReason('огурцы получают короткую засолку без потери хруста');
        } else {
          addWarning('малосольным огурцам нужно постоять 8-12 часов или ночь');
          hardPenalty *= 0.80;
        }
        if (hasColdAssembly ||
            _containsAnyKeyword(
              stepText,
              const [
                'в холод минимум',
                'убери малосольные огурцы в холод',
                'охлажден'
              ],
            )) {
          score += 0.10;
          addReason('после засолки огурцы охлаждаются и остаются хрустящими');
        } else {
          addWarning('после засолки малосольные огурцы нужно охладить');
          hardPenalty *= 0.86;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['уксус', 'маринуй', 'обжар', 'сковород', 'заправь'],
        )) {
          addWarning(
              'малосольные огурцы не должны уходить в уксусный маринад, жарку или салатную заправку');
          hardPenalty *= 0.72;
        }
        break;
      }
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
      if (isCharlotte) {
        if (_containsAnyKeyword(
              stepText,
              const ['взбей яйца', 'пышную массу', 'светлую пышную массу'],
            ) &&
            (_containsKeyword(stepText, 'сахар') ||
                recipeCanonicals.contains('сахар'))) {
          score += 0.16;
          addReason(
              'яйца взбиваются в пышную основу, поэтому мякиш не тяжелеет');
        } else {
          addWarning('шарлотке нужно отдельно взбить яйца с сахаром');
          hardPenalty *= 0.78;
        }
        if (_containsAnyKeyword(
          stepText,
          const [
            'аккуратно вмешай муку',
            'вмешай муку лопаткой',
            'воздушное тесто'
          ],
        )) {
          score += 0.12;
          addReason('мука входит мягко и не сажает бисквит');
        } else {
          addWarning(
              'шарлотке нужно аккуратно вмешать муку, а не забить тесто');
          hardPenalty *= 0.80;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['разложи яблоки', 'яблоки в форме', 'вылей тесто на яблоки'],
        )) {
          score += 0.14;
          addReason(
              'яблоки лежат отдельным фруктовым слоем, а не теряются в массе');
        } else {
          addWarning(
              'шарлотке нужно выложить яблоки в форму и залить их тестом');
          hardPenalty *= 0.78;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['30-35 минут', '35-40 минут', 'золотистой корочки', 'подъём'],
        )) {
          score += 0.10;
          addReason(
              'бисквит успевает подняться и допекается до румяной корочки');
        } else {
          addWarning('шарлотке нужно допечься до подъёма и золотистой корочки');
          hardPenalty *= 0.82;
        }
        if (hasRest ||
            _containsAnyKeyword(
              stepText,
              const ['10 минут', 'перед нарезкой', 'дай постоять'],
            )) {
          score += 0.08;
          addReason(
              'после духовки шарлотка немного стабилизируется перед нарезкой');
        } else {
          addWarning('шарлотке полезно дать короткий отдых перед нарезкой');
        }
        if (_containsAnyKeyword(
          stepText,
          const ['сковород', 'обжар', 'раскатай', 'защипни края'],
        )) {
          addWarning(
              'шарлотка не должна жариться или превращаться в пирог на раскатанном тесте');
          hardPenalty *= 0.76;
        }
        break;
      }
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
        addReason(
          _describeBakeMoistureReason(
            recipeCanonicals: recipeCanonicals,
            stepText: stepText,
          ),
        );
      } else {
        addWarning(
          'духовочному блюду не хватает соуса, связки или более мягкого запекания',
        );
        hardPenalty *= 0.84;
      }
      if (_containsAny(recipeCanonicals, _redMeatCanonicals)) {
        if (hasCover || hasGentleHeat || _containsKeyword(stepText, 'марина')) {
          score += 0.10;
          addReason(_describeBakedMeatReason(stepText: stepText));
        } else {
          addWarning(
              'мясо в духовке лучше накрыть, замариновать или готовить мягче, чтобы оно не вышло сухим');
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
      if (grainDishKind == _GrainDishKind.buckwheatRustic) {
        if ((_containsKeyword(stepText, 'вари') &&
                _containsKeyword(stepText, 'гречк')) ||
            _containsAnyKeyword(
                stepText, const ['15-18 минут', 'под крышкой'])) {
          score += 0.10;
          addReason('гречка варится отдельно до рассыпчатой текстуры');
        } else {
          addWarning(
              'гречке по-домашнему нужна отдельная варка до рассыпчатости');
          hardPenalty *= 0.82;
        }
        if (_containsAnyKeyword(
          stepText,
          const [
            'вмешай гречку',
            'собери ароматическую базу',
            'прогрей все вместе'
          ],
        )) {
          score += 0.10;
          addReason(
              'гречка вмешивается в ароматическую базу, а не подаётся отдельно');
        } else {
          addWarning(
              'гречка по-домашнему должна собираться через вмешивание готовой крупы');
          hardPenalty *= 0.82;
        }
      }
      break;
    case DishProfile.breakfast:
      if (isPanBatter) {
        if (_containsAnyKeyword(
          stepText,
          const ['тесто', 'без комков', 'размешай', 'взбей'],
        )) {
          score += 0.12;
          addReason('тесто собирается в гладкую массу, а не идёт кусками');
        } else {
          addWarning('тесту не хватает явного этапа смешивания');
          hardPenalty *= 0.82;
        }
        if (_containsAnyKeyword(stepText, const ['постоять', 'отдохнуть'])) {
          score += 0.10;
          addReason(
              'тесту дают коротко постоять, чтобы жареное тесто было ровнее');
        } else {
          addWarning('тесту полезно дать короткий отдых перед жаркой');
          hardPenalty *= 0.88;
        }
        if (_containsAnyKeyword(
            stepText, const ['сковород', 'с каждой стороны'])) {
          score += 0.12;
        } else {
          addWarning(
              'жареное тесто должно готовиться на сковороде с двух сторон');
          hardPenalty *= 0.80;
        }
        if (_containsAnyKeyword(
          stepText,
          const [
            'густое тесто',
            'держало форму',
            'небольшими порциями',
            'ложкой'
          ],
        )) {
          score += 0.06;
          addReason(
              'тесто удерживает форму и жарится контролируемыми порциями');
        }
      } else if (isFritterBatter) {
        if (_containsAnyKeyword(
          stepText,
          const ['густое тесто', 'держало форму', 'без комков'],
        )) {
          score += 0.12;
          addReason('тесто для оладий держит форму и не уходит в жидкость');
        } else {
          addWarning('оладьям не хватает густого теста с понятной структурой');
          hardPenalty *= 0.82;
        }
        if (_containsAnyKeyword(stepText, const ['постоять', 'отдохнуть'])) {
          score += 0.10;
          addReason('тесту дают коротко постоять перед жаркой');
        } else {
          addWarning('тесту для оладий полезен короткий отдых');
          hardPenalty *= 0.88;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['небольшими порциями', 'ложкой', 'с каждой стороны'],
        )) {
          score += 0.12;
          addReason('оладьи жарятся порционно и успевают подняться');
        } else {
          addWarning(
              'оладьи должны жариться небольшими порциями с двух сторон');
          hardPenalty *= 0.80;
        }
      } else if (isCurdFritter) {
        if (_containsAnyKeyword(
          stepText,
          const ['творожную массу', 'плотную творожную массу'],
        )) {
          score += 0.12;
          addReason('творог держит форму и не расползается в жидкое тесто');
        } else {
          addWarning('сырникам нужна плотная творожная масса');
          hardPenalty *= 0.82;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['сформируй', 'шайбы', 'влажными руками'],
        )) {
          score += 0.12;
          addReason('сырники формуются порционно, а не жарятся как оладьи');
        } else {
          addWarning('сырникам нужна ручная формовка небольших шайб');
          hardPenalty *= 0.80;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['2-3 минуты с каждой стороны', 'умерен'],
        )) {
          score += 0.10;
        } else {
          addWarning('сырники должны коротко жариться на умеренном огне');
          hardPenalty *= 0.84;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['ложкой', 'густое тесто', 'вылей'],
        )) {
          addWarning('сырники не должны уходить в технику оладий');
          hardPenalty *= 0.80;
        }
      } else if (_isSweetBreakfast(recipeCanonicals)) {
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
      switch (stewDishKind) {
        case _StewDishKind.stewedCabbage:
          if (_containsAnyKeyword(
                stepText,
                const ['под крышкой', '20-25 минут', 'туши капусту'],
              ) &&
              (_containsKeyword(stepText, 'туш') ||
                  (hasHeat && hasGentleHeat))) {
            score += 0.16;
            addReason('капуста спокойно доходит под крышкой и не пересыхает');
          } else {
            addWarning(
                'тушёной капусте нужно спокойное тушение под крышкой 20-25 минут');
            hardPenalty *= 0.78;
          }
          if (_containsAnyKeyword(
            stepText,
            const ['томатн', 'колбас', 'сосиск', 'лавров'],
          )) {
            score += 0.10;
            addReason(
                'домашняя база капусты получает томатную или мясную глубину');
          } else {
            addWarning(
                'тушёной капусте не хватает томатной или мясной глубины');
            hardPenalty *= 0.84;
          }
          if (_containsAnyKeyword(stepText, const ['майонез', 'холодн'])) {
            addWarning(
                'тушёная капуста не должна уходить в майонезную или холодную подачу');
            hardPenalty *= 0.78;
          }
          break;
        case _StewDishKind.lazyCabbageRolls:
          final hasLazyAssembly = hasMix &&
              _containsAnyKeyword(
                stepText,
                const ['ленивые голубцы', 'плотную основу'],
              );
          final hasWrappedAssembly = _containsAnyKeyword(
            stepText,
            const [
              'сними крупные листья',
              'кипящую воду',
              'уложи на листья',
              'заверни голубцы',
              'швом вниз',
            ],
          );
          if (hasLazyAssembly || hasWrappedAssembly) {
            score += 0.12;
            addReason(
              hasWrappedAssembly
                  ? 'голубцы держат форму через подготовленные листья и отдельную начинку'
                  : 'голубцы сначала собираются в единую мясо-рисовую основу',
            );
          } else {
            addWarning(
                'голубцам не хватает этапа сборки: либо общей массы, либо заворачивания в листья');
            hardPenalty *= 0.80;
          }
          final hasLazyCoveredBraise = _containsAnyKeyword(
                stepText,
                const ['18-22 минуты', 'под крышкой'],
              ) &&
              (_containsKeyword(stepText, 'туш') || (hasHeat && hasGentleHeat));
          final hasClassicCoveredBraise = _containsAnyKeyword(
                stepText,
                const ['30-35 минут', 'под крышкой', 'швом вниз'],
              ) &&
              (_containsKeyword(stepText, 'туш') || (hasHeat && hasGentleHeat));
          if (hasLazyCoveredBraise || hasClassicCoveredBraise) {
            score += 0.16;
            addReason(
                'голубцы спокойно доходят под крышкой и не разваливаются');
          } else {
            addWarning('голубцам не хватает спокойного тушения под крышкой');
            hardPenalty *= 0.78;
          }
          if (_containsAnyKeyword(stepText, const ['томатн', 'сметан'])) {
            score += 0.10;
          } else {
            addWarning(
                'ленивым голубцам не хватает соусной томатной или сметанной сборки');
            hardPenalty *= 0.84;
          }
          break;
        case _StewDishKind.zrazy:
          if (_containsAnyKeyword(
            stepText,
            const ['в центр', 'начинк', 'закрой края', 'мясной оболочк'],
          )) {
            score += 0.18;
            addReason(
                'зразы собираются вокруг начинки, а не как плоские котлеты');
          } else {
            addWarning(
                'зразам нужен отдельный этап с начинкой в центре и закрытыми краями');
            hardPenalty *= 0.74;
          }
          if (_containsAnyKeyword(
            stepText,
            const [
              'сформируй зразы',
              'обжарь зразы',
              '4-5 минут с каждой стороны'
            ],
          )) {
            score += 0.14;
            addReason(
                'зразы проходят через отдельную формовку и уверенную обжарку');
          } else {
            addWarning(
                'зразам не хватает отдельной формовки и обжарки с двух сторон');
            hardPenalty *= 0.80;
          }
          if (_containsAnyKeyword(
            stepText,
            const ['6-8 минут', 'мягком огне', 'с гарниром'],
          )) {
            score += 0.10;
          } else {
            addWarning(
                'зразам не хватает мягкой доводки и подачи с отдельным гарниром');
            hardPenalty *= 0.84;
          }
          if (_containsAnyKeyword(
            stepText,
            const ['подливк', 'круглые биточки', 'рис и капуст'],
          )) {
            addWarning(
                'зразы не должны уходить в технику биточков или голубцов');
            hardPenalty *= 0.80;
          }
          break;
        case _StewDishKind.homeCutlets:
          if (isBitochki) {
            if (_containsAnyKeyword(stepText,
                const ['сформируй круглые биточки', 'сформируй биточки'])) {
              score += 0.14;
              addReason('биточки держат более деликатную округлую форму');
            } else {
              addWarning(
                  'биточкам нужна отдельная формовка в более мягкую круглую форму');
              hardPenalty *= 0.80;
            }
            if (_containsAnyKeyword(stepText,
                const ['3-4 минуты с каждой стороны', 'обжарь биточки'])) {
              score += 0.12;
              addReason('биточки только схватываются корочкой перед подливкой');
            } else {
              addWarning('биточкам нужна короткая обжарка перед подливкой');
              hardPenalty *= 0.82;
            }
            if (_containsAnyKeyword(
                    stepText, const ['8-10 минут', 'подливк', 'обволоч']) &&
                _containsAnyKeyword(stepText, const ['мягком огне', 'соус'])) {
              score += 0.14;
              addReason('подливка доводит биточки мягко и не забивает мясо');
            } else {
              addWarning(
                  'биточкам нужна мягкая подливка и короткая доводка в ней');
              hardPenalty *= 0.76;
            }
            if (_containsAnyKeyword(
              stepText,
              const ['начинк', 'в центр', 'закрой края'],
            )) {
              addWarning('биточки не должны уходить в технику зраз с начинкой');
              hardPenalty *= 0.80;
            }
            if (_containsAnyKeyword(
              stepText,
              const ['гарнир', 'подавай вместе с гарниром'],
            )) {
              score += 0.08;
            }
            break;
          }
          if (_containsAnyKeyword(stepText,
              const ['сформируй котлеты', '4-5 минут с каждой стороны'])) {
            score += 0.16;
            addReason('котлеты идут через правильную формовку и обжаривание');
          } else {
            addWarning(
                'котлетам не хватает формовки и уверенной обжарки с двух сторон');
            hardPenalty *= 0.76;
          }
          if (_containsAnyKeyword(
              stepText, const ['6-8 минут', 'мягком огне'])) {
            score += 0.10;
            addReason('после корочки котлеты мягко доводятся до готовности');
          } else {
            addWarning('котлетам не хватает мягкой доводки после обжарки');
            hardPenalty *= 0.84;
          }
          if (_containsAnyKeyword(stepText, const [
            'гарнир',
            'отдохнуть 1-2 минуты',
            'подавай вместе с гарниром'
          ])) {
            score += 0.10;
          } else {
            addWarning(
                'котлетному ужину не хватает явной подачи с гарниром и короткого отдыха');
            hardPenalty *= 0.86;
          }
          break;
        case _StewDishKind.tefteli:
          if (_containsAnyKeyword(
                stepText,
                const ['сформируй небольшие тефтели', 'сформируй тефтели'],
              ) &&
              !_containsAnyKeyword(
                stepText,
                const ['смешай всё вместе', 'россыпью'],
              )) {
            score += 0.16;
            addReason('тефтели держат форму и не разваливаются в соусе');
          } else {
            addWarning(
                'тефтелям не хватает отдельной формовки перед соусным тушением');
            hardPenalty *= 0.76;
          }
          if (_containsAnyKeyword(
                  stepText, const ['18-22 минуты', 'под крышкой']) &&
              (_containsKeyword(stepText, 'туш') || hasGentleHeat)) {
            score += 0.16;
            addReason('тефтели спокойно доходят в соусе под крышкой');
          } else {
            addWarning('тефтелям не хватает спокойного тушения в соусе');
            hardPenalty *= 0.78;
          }
          if (_containsAnyKeyword(
              stepText, const ['томатн', 'сметан', 'соус'])) {
            score += 0.10;
          } else {
            addWarning('тефтелям не хватает явной соусной основы');
            hardPenalty *= 0.84;
          }
          if (_containsAnyKeyword(
            stepText,
            const ['обволакива', 'соус успеет собраться', 'обволочь тефтели'],
          )) {
            score += 0.10;
            addReason('соус у тефтелей собирается и мягко держит форму блюда');
          } else {
            addWarning(
                'тефтелям не хватает собранного соуса, который обволакивает их');
            hardPenalty *= 0.82;
          }
          break;
        case _StewDishKind.goulash:
          if (_containsAnyKeyword(
              stepText, const ['обжарь мясо', '5-6 минут'])) {
            score += 0.16;
            addReason('гуляш начинает вкус с уверенной обжарки мяса');
          } else {
            addWarning('гуляшу не хватает стартовой обжарки мяса');
            hardPenalty *= 0.78;
          }
          if (_containsAnyKeyword(
                  stepText, const ['25-30 минут', 'под крышкой']) &&
              (_containsKeyword(stepText, 'туш') || hasGentleHeat)) {
            score += 0.16;
            addReason(
                'гуляш набирает глубину через спокойное тушение под крышкой');
          } else {
            addWarning('гуляшу не хватает долгого спокойного тушения');
            hardPenalty *= 0.78;
          }
          if (_containsAnyKeyword(
              stepText, const ['паприк', 'томат', 'соус'])) {
            score += 0.10;
          } else {
            addWarning('гуляшу не хватает папрично-томатной соусной базы');
            hardPenalty *= 0.84;
          }
          if (_containsAnyKeyword(
            stepText,
            const [
              'гуще и глубже',
              'лишняя жидкость не выпарится',
              'соус не станет гуще'
            ],
          )) {
            score += 0.10;
            addReason(
                'гуляш уводит соус в густую глубину, а не в жидкий бульон');
          } else {
            addWarning('гуляшу не хватает уваренного густого соуса');
            hardPenalty *= 0.82;
          }
          if (_containsAnyKeyword(
            stepText,
            const ['белом соусе', 'белый соус'],
          )) {
            addWarning('гуляш не должен уходить в белый сметанный соус');
            hardPenalty *= 0.80;
          }
          if (_containsAnyKeyword(
            stepText,
            const ['тонкими полосками', 'не давая соусу бурно кипеть'],
          )) {
            addWarning('гуляш не должен уходить в технику бефстроганова');
            hardPenalty *= 0.78;
          }
          break;
        case _StewDishKind.stroganoff:
          if (_containsAnyKeyword(
              stepText, const ['тонкими полосками', 'полосками'])) {
            score += 0.14;
            addReason('бефстроганов идёт через тонкую нарезку мяса');
          } else {
            addWarning('бефстроганову нужна тонкая нарезка мяса');
            hardPenalty *= 0.80;
          }
          if (_containsAnyKeyword(
              stepText, const ['3-4 минуты', 'быстро обжарь'])) {
            score += 0.14;
            addReason('мясо быстро схватывается, а не уходит в долгую варку');
          } else {
            addWarning('бефстроганову не хватает быстрой короткой обжарки');
            hardPenalty *= 0.78;
          }
          if (_containsAnyKeyword(
                stepText,
                const [
                  '5-7 минут',
                  'не давая соусу бурно кипеть',
                  'мягком огне'
                ],
              ) &&
              _containsAnyKeyword(stepText, const ['сметан', 'соус'])) {
            score += 0.16;
            addReason('сметанный соус держится мягко и не расслаивается');
          } else {
            addWarning(
                'бефстроганову не хватает мягкого сметанного финиша без сильного кипения');
            hardPenalty *= 0.76;
          }
          if (_containsAnyKeyword(
            stepText,
            const ['гладк', 'собраться 1-2 минуты'],
          )) {
            score += 0.10;
            addReason(
                'бефстроганов держит гладкий пан-соус, а не тяжёлую подливу');
          } else {
            addWarning('бефстроганову не хватает гладкого собранного соуса');
            hardPenalty *= 0.82;
          }
          if (_containsKeyword(stepText, 'под крышкой') &&
              _containsAnyKeyword(
                  stepText, const ['25-30 минут', '22-26 минут'])) {
            addWarning('бефстроганов начинает тушиться как гуляш');
            hardPenalty *= 0.78;
          }
          if (_containsKeyword(stepText, 'томат')) {
            addWarning('бефстроганов не должен уходить в томатный профиль');
            hardPenalty *= 0.78;
          }
          break;
        case _StewDishKind.zharkoe:
          if (_containsAnyKeyword(stepText, const ['обжарь', '5-6 минут'])) {
            score += 0.14;
            addReason('жаркое начинает вкус через отдельную обжарку мяса');
          } else {
            addWarning('жаркому не хватает стартовой обжарки мяса');
            hardPenalty *= 0.80;
          }
          if (_containsAnyKeyword(
                  stepText, const ['22-26 минут', 'под крышкой']) &&
              (_containsKeyword(stepText, 'туш') || hasGentleHeat)) {
            score += 0.16;
            addReason('жаркое доходит под крышкой и собирает густой соус');
          } else {
            addWarning('жаркому не хватает спокойного доведения под крышкой');
            hardPenalty *= 0.78;
          }
          if (hasRest || hasFinishLayer) {
            score += 0.08;
          } else {
            addWarning(
                'жаркому не хватает короткого финиша или отдыха перед подачей');
          }
          break;
        case _StewDishKind.none:
          if (hasAromaticStart) {
            score += 0.10;
          }
          if (_containsKeyword(stepText, 'туш') || (hasHeat && hasGentleHeat)) {
            score += 0.14;
            addReason(
                'техника даёт продуктам спокойно дойти и обменяться вкусом');
          } else {
            addWarning('для тушения не хватает мягкого доведения под крышкой');
            hardPenalty *= 0.80;
          }
          break;
      }
      break;
    case DishProfile.skillet:
      if (isPotatoFritter) {
        if (_containsAnyKeyword(
          stepText,
          const ['натри', 'тёрт', 'картофельную массу'],
        )) {
          score += 0.14;
          addReason(
              'картофельная основа идёт через тёртую массу, как и должна');
        } else {
          addWarning('драникам нужна тёртая картофельная основа');
          hardPenalty *= 0.80;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['без лишней влаги', 'отожми'],
        )) {
          score += 0.10;
          addReason('лишняя влага контролируется и корочка выйдет увереннее');
        } else {
          addWarning('драникам нужно убрать лишнюю влагу перед жаркой');
          hardPenalty *= 0.84;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['небольшие порции', '3-4 минуты с каждой стороны'],
        )) {
          score += 0.12;
        } else {
          addWarning('драники должны жариться порционно и с двух сторон');
          hardPenalty *= 0.80;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['густое тесто', 'без комков', 'постоять'],
        )) {
          addWarning('драники не должны идти по логике блинного теста');
          hardPenalty *= 0.78;
        }
      } else {
        if (hasHeat) {
          score += 0.14;
        } else {
          addWarning('для сковороды не хватает явной обжарки или прогрева');
          hardPenalty *= 0.82;
        }
        if (hasAromaticStart || hasMix) {
          score += 0.08;
        }
      }
      break;
    case DishProfile.general:
      if (isLiverCake) {
        if (_containsAnyKeyword(
              stepText,
              const ['пробей', 'блендер', 'гладкое печеночное'],
            ) &&
            _containsKeyword(stepText, 'печен')) {
          score += 0.14;
          addReason('печень сначала собирается в гладкую основу для коржей');
        } else {
          addWarning(
              'печеночному торту нужно гладкое печеночное тесто для тонких коржей');
          hardPenalty *= 0.80;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['тонкие коржи', 'тонким слоем', '1-2 минуты с каждой стороны'],
        )) {
          score += 0.16;
          addReason(
              'печеночные коржи жарятся отдельно и не превращаются в одну массу');
        } else {
          addWarning(
              'печеночному торту нужны тонкие отдельно обжаренные коржи');
          hardPenalty *= 0.78;
        }
        if (_containsAnyKeyword(
              stepText,
              const ['слоями', 'собери печеночный торт', 'каждый корж'],
            ) &&
            _containsAnyKeyword(
              stepText,
              const ['лук', 'морковь', 'овощную прослойку'],
            )) {
          score += 0.14;
          addReason(
              'овощная прослойка и сборка слоями держат торт структурным');
        } else {
          addWarning(
              'печеночному торту нужны овощная прослойка и сборка слоями');
          hardPenalty *= 0.78;
        }
        if (hasColdAssembly &&
            _containsAnyKeyword(
              stepText,
              const ['холодильник', '2-3 часа', 'холодным', 'прохладным'],
            )) {
          score += 0.12;
          addReason('слоеная закуска успевает собраться и подается прохладной');
        } else {
          addWarning('печеночному торту нужно охлаждение перед подачей');
          hardPenalty *= 0.78;
        }
        if (_containsAnyKeyword(stepText, const ['духов', 'вылей в форму'])) {
          addWarning(
              'печеночный торт не должен превращаться в одну запеченную массу');
          hardPenalty *= 0.76;
        }
        if (_containsAnyKeyword(
          stepText,
          const ['подавай горячим', 'горячим со сковороды'],
        )) {
          addWarning(
              'печеночный торт не должен подаваться сразу горячим со сковороды');
          hardPenalty *= 0.78;
        }
      } else {
        if (hasHeat || hasMix) {
          score += 0.10;
        }
        if (!hasHeat &&
            !_containsAny(recipeCanonicals, _freshReadyCanonicals)) {
          addWarning('техника описана слишком общо');
          hardPenalty *= 0.90;
        }
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

  if (hasSauceElements && friedDishKind == _FriedDishKind.none) {
    if (hasSauceBindingAction) {
      score += 0.10;
      addReason(
          'соусная часть действительно связывает блюдо, а не лежит отдельно');
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
      friedDishKind == _FriedDishKind.none &&
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
  final isMors = _isMorsDish(matchedCanonicals);
  final isSweetBake = profile == DishProfile.bake &&
      supportPlan.aromaticCanonicals.isEmpty &&
      supportPlan.seasoningCanonicals.contains('сахар') &&
      supportPlan.seasoningCanonicals.contains('корица');
  if (supportPlan.aromaticCanonicals.isEmpty &&
      profile != DishProfile.salad &&
      profile != DishProfile.breakfast &&
      !isSweetBake &&
      !isMors) {
    warnings.add('нет ароматической базы');
  }
  if (supportPlan.seasoningCanonicals.isEmpty) {
    warnings.add('нечем усилить вкус');
  }
  if (!_containsAny(matchedCanonicals, _proteinCanonicals) &&
      !_containsAny(matchedCanonicals, _baseCanonicals) &&
      profile != DishProfile.salad &&
      !isMors) {
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

String _describeBakeMoistureReason({
  required Set<String> recipeCanonicals,
  required String stepText,
}) {
  if (_containsAnyKeyword(stepText, const ['накр', 'под крыш', 'фольг'])) {
    return 'запекание под крышкой или фольгой поможет блюду остаться сочнее';
  }
  if (_containsAnyKeyword(
    stepText,
    const ['соус', 'сметан', 'бульон', 'слив'],
  )) {
    return 'соус или жидкая основа помогут блюду не пересохнуть в духовке';
  }

  final hasEgg = recipeCanonicals.contains('яйцо');
  final hasMilk = recipeCanonicals.contains('молоко');
  final hasCurd = recipeCanonicals.contains('творог');
  if (hasEgg && hasMilk) {
    return 'яично-молочная основа поможет блюду не пересохнуть в духовке';
  }
  if (hasEgg && hasCurd) {
    return 'яично-творожная основа поможет блюду остаться нежным после духовки';
  }
  if (_containsAny(
      recipeCanonicals, const {'яйцо', 'молоко', 'сметана', 'творог'})) {
    return 'мягкая связка поможет блюду остаться нежным после духовки';
  }
  if (_containsAny(recipeCanonicals, _fatCanonicals)) {
    return 'небольшая жирность смягчит запекание и не даст блюду выйти сухим';
  }
  return 'в рецепте есть основа, которая поможет блюду остаться сочным в духовке';
}

String _describeBakedMeatReason({
  required String stepText,
}) {
  if (_containsAnyKeyword(stepText, const ['накр', 'под крыш', 'фольг'])) {
    return 'мясо запекается под крышкой или фольгой и теряет меньше сока';
  }
  if (_containsKeyword(stepText, 'марина')) {
    return 'маринад поможет мясу запечься мягче и сочнее';
  }
  return 'мягкий режим запекания поможет мясу остаться сочнее';
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
  final isColdSoup = _isColdSoupDish(recipeCanonicals);
  final isSvekolnik = _isSvekolnikDish(recipeCanonicals);
  final friedDishKind = _detectFriedDishKind(profile, recipeCanonicals);
  final grainDishKind = _detectGrainDishKind(profile, recipeCanonicals);
  final soupKind = _detectSoupKind(recipeCanonicals);
  final stewDishKind = _detectStewDishKind(profile, recipeCanonicals);
  final isPanBatter = friedDishKind == _FriedDishKind.blini;
  final isFritterBatter = friedDishKind == _FriedDishKind.oladyi;
  final isCurdFritter = friedDishKind == _FriedDishKind.syrniki;
  final isPotatoFritter = friedDishKind == _FriedDishKind.draniki;
  final isCharlotte = _isCharlotteDish(recipeCanonicals);
  final isLiverCake = _isLiverCakeDish(recipeCanonicals);
  final isSauerkrautPreserve = _isSauerkrautPreserveDish(recipeCanonicals);
  final isLightlySaltedCucumbers =
      _isLightlySaltedCucumberDish(recipeCanonicals);
  final isMors = _isMorsDish(recipeCanonicals);

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

  if (isMors) {
    if (_containsAny(recipeCanonicals, _morsBerryCanonicals)) {
      score += 0.22;
      addReason('ягодная база даёт морсу настоящий фруктовый центр');
    } else {
      addWarning('морсу не хватает явной ягодной базы');
      hardPenalty *= 0.78;
    }
    if (availableSet.contains('сахар')) {
      score += 0.18;
      addReason('сахар собирает ягодную кислоту и убирает резкость');
    } else {
      addWarning('морсу не хватает сладости, которая собирает ягодный вкус');
      hardPenalty *= 0.80;
    }
    if (hasAcid || recipeCanonicals.contains('лимон')) {
      score += 0.12;
      addReason('кислотный штрих удерживает морс живым и не приторным');
    } else {
      addWarning('морсу не хватает свежего кислого контура');
      hardPenalty *= 0.88;
    }
    if (recipeCanonicals.contains('лимон') || hasBrightFinish) {
      score += 0.08;
      addReason('цитрусовый финиш делает ягодный вкус чище и длиннее');
    } else {
      addWarning('морсу не хватает яркого финишного штриха');
    }
    if (freshCount > 0 || hasBrightFinish) {
      score += 0.10;
      addReason('ягодная свежесть остаётся слышной после прогрева основы');
    } else {
      addWarning('морсу не хватает ощущения свежести');
      hardPenalty *= 0.88;
    }
    if (hasFat || hasCreamy || hasTomatoDepth || hasWarmSpice) {
      addWarning(
          'жирные, томатные или пряные ноты спорят с чистым профилем морса');
      hardPenalty *= 0.74;
    } else {
      score += 0.08;
    }
    if (_hasMorsDrift(recipeCanonicals)) {
      addWarning(
          'чужие молочные или savory-добавки ломают ягодный профиль морса');
      hardPenalty *= 0.72;
    }
    return _BalanceAnalysis(
      score: score.clamp(0.0, 1.0),
      hardPenalty: hardPenalty.clamp(0.0, 1.0),
      reasons: reasons,
      warnings: warnings,
    );
  }

  switch (profile) {
    case DishProfile.soup:
      if (isColdSoup) {
        if (hasCreamy || hasAcid) {
          score += 0.20;
          addReason('холодная база держит суп свежим и собранным');
        } else {
          addWarning(
              'холодному супу не хватает собранной кислой или мягкой базы');
          hardPenalty *= 0.82;
        }
        if (hasHerbs || freshCount > 0) {
          score += 0.14;
          addReason('свежие овощи и зелень не дают вкусу стать плоским');
        } else {
          addWarning(
              'холодному супу не хватает свежего овощного или травяного слоя');
          hardPenalty *= 0.84;
        }
        if (hasSalt) {
          score += 0.08;
        } else {
          addWarning('холодному супу нужна базовая приправа');
        }
        if (hasProtein || hasBase) {
          score += 0.10;
        }
        if (hasFinishingSupport || hasBrightFinish) {
          score += 0.08;
        }
        if (isSvekolnik) {
          if (recipeCanonicals.contains('свекла') &&
              (hasCreamy || hasAcid) &&
              (hasHerbs || hasFinishingSupport)) {
            score += 0.10;
            addReason(
                'свекольник держит холодную свекольную базу собранной и свежей');
          } else {
            addWarning(
                'свекольнику не хватает холодного свекольного баланса и зелёного финиша');
            hardPenalty *= 0.84;
          }
        }
        break;
      }
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
      switch (soupKind) {
        case _SoupKind.greenShchi:
          if ((hasAcid || hasBrightFinish || hasHerbs) &&
              (hasCreamy || hasFinishingSupport)) {
            score += 0.10;
            addReason(
                'щавелевая кислота удерживается сметанным или травяным финишем');
          } else {
            addWarning(
                'щавелевым щам не хватает мягкого финиша к зелёной кислоте');
            hardPenalty *= 0.84;
          }
          break;
        case _SoupKind.mushroom:
          if (hasAromatics) {
            score += 0.08;
            addReason(
                'у грибного супа есть ароматическая база для грибной глубины');
          } else {
            addWarning('грибному супу не хватает луково-морковной базы');
            hardPenalty *= 0.88;
          }
          if (hasFinishingSupport || hasCreamy || hasHerbs) {
            score += 0.08;
            addReason(
                'грибной суп получает мягкий сметанный или травяной финиш');
          } else {
            addWarning(
                'грибному супу не хватает мягкого финиша к грибной глубине');
            hardPenalty *= 0.88;
          }
          break;
        case _SoupKind.peaSmoked:
          if (_containsAny(recipeCanonicals, const {'лук', 'морковь'})) {
            score += 0.08;
            addReason(
                'гороховый суп опирается на спокойную луково-морковную базу');
          } else {
            addWarning('гороховому супу не хватает овощной базы для мягкости');
            hardPenalty *= 0.88;
          }
          if (hasFinishingSupport || hasCreamy || hasHerbs) {
            score += 0.08;
            addReason('густой гороховый вкус смягчается домашним финишем');
          } else {
            addWarning('гороховому супу не хватает мягкого домашнего финиша');
            hardPenalty *= 0.88;
          }
          if (hasTomatoDepth ||
              _containsAny(recipeCanonicals, const {'оливки', 'лимон'})) {
            addWarning(
                'гороховый суп с копчёностями не должен сваливаться в соляночный или томатный контур');
            hardPenalty *= 0.84;
          }
          break;
        case _SoupKind.shchi:
          if (freshCount > 0 ||
              _containsAny(recipeCanonicals, _herbCanonicals)) {
            score += 0.08;
            addReason('капустная основа щей не уходит в плоский вкус');
          }
          if (hasCreamy || hasFinishingSupport) {
            score += 0.08;
            addReason('щи получают спокойный сметанный или травяной финиш');
          } else {
            addWarning('щам не хватает мягкого домашнего финиша');
            hardPenalty *= 0.88;
          }
          break;
        case _SoupKind.borscht:
          if (hasTomatoDepth) {
            score += 0.10;
            addReason('томатная глубина собирает свекольную сладость борща');
          } else {
            addWarning('борщу не хватает томатной глубины');
            hardPenalty *= 0.88;
          }
          if (hasCreamy || hasAcid) {
            score += 0.08;
            addReason('борщ получает мягкий кислый контраст к сладости свеклы');
          } else {
            addWarning('борщу не хватает мягкого кислого контраста');
            hardPenalty *= 0.88;
          }
          break;
        case _SoupKind.ukha:
        case _SoupKind.rassolnik:
          break;
        case _SoupKind.solyanka:
          if (hasTomatoDepth && hasAcid) {
            score += 0.10;
            addReason('солянка держит нужный кислый и томатный контур');
          } else {
            addWarning('солянке не хватает томатно-кислой опоры');
            hardPenalty *= 0.86;
          }
          if (hasBrightFinish || hasFinishingSupport) {
            score += 0.08;
            addReason('солянка получает яркий финиш и не кажется глухой');
          } else {
            addWarning('солянке не хватает яркого финиша');
            hardPenalty *= 0.88;
          }
          break;
        case _SoupKind.none:
          break;
      }
      break;
    case DishProfile.salad:
      if (isSauerkrautPreserve) {
        if (hasSalt) {
          score += 0.18;
          addReason(
              'соль удерживает капустную ферментацию в собранном контуре');
        } else {
          addWarning('квашеной капусте нужна соль как опора ферментации');
          hardPenalty *= 0.76;
        }
        if (recipeCanonicals.contains('капуста')) {
          score += 0.14;
        }
        if (recipeCanonicals.contains('морковь')) {
          score += 0.08;
          addReason('морковь смягчает солёно-кислый профиль');
        }
        if (!hasFat && !hasCreamy && !hasDressingSupport) {
          score += 0.12;
          addReason('капустный баланс не смазан жирной салатной заправкой');
        } else {
          addWarning('квашеной капусте не нужна жирная салатная заправка');
          hardPenalty *= 0.78;
        }
        if (_hasSauerkrautPreserveDrift(recipeCanonicals)) {
          addWarning(
              'квашеная капуста уходит в чужой салатный или горячий контур');
          hardPenalty *= 0.74;
        }
        break;
      }
      if (isLightlySaltedCucumbers) {
        if (hasSalt) {
          score += 0.18;
          addReason('рассол даёт огурцам чистую и ровную соль');
        } else {
          addWarning('малосольным огурцам нужна соль как основа рассола');
          hardPenalty *= 0.76;
        }
        if (hasHerbs && recipeCanonicals.contains('чеснок')) {
          score += 0.16;
          addReason('укроп и чеснок собирают классический малосольный профиль');
        } else {
          addWarning('малосольным огурцам не хватает укропа и чеснока');
          hardPenalty *= 0.80;
        }
        if (!hasFat && !hasCreamy && !hasDressingSupport) {
          score += 0.12;
        } else {
          addWarning('малосольным огурцам не нужна жирная салатная заправка');
          hardPenalty *= 0.78;
        }
        if (freshCount > 0 || recipeCanonicals.contains('огурец')) {
          score += 0.10;
          addReason(
              'огуречная свежесть остаётся главной, а не маскируется соусом');
        }
        if (_hasLightlySaltedCucumberDrift(recipeCanonicals)) {
          addWarning(
              'малосольные огурцы уводятся в салатный или горячий дрейф');
          hardPenalty *= 0.74;
        }
        break;
      }
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
      if (isCharlotte) {
        if (hasBinder && availableSet.contains('сахар')) {
          score += 0.24;
          addReason(
              'бисквитная база держится на яйце и сахаре, а не на тяжёлой смеси');
        } else {
          addWarning(
              'шарлотке нужна сладкая яичная база для воздушного бисквита');
          hardPenalty *= 0.78;
        }
        if (recipeCanonicals.contains('яблоко')) {
          score += 0.14;
          addReason('яблоки дают шарлотке сочный фруктовый центр');
        } else {
          addWarning('шарлотке не хватает яблочной основы');
          hardPenalty *= 0.80;
        }
        if (hasWarmSpice || availableSet.contains('корица')) {
          score += 0.10;
          addReason('тёплая специя поддерживает яблочный профиль');
        }
        if (hasFat || availableSet.contains('масло сливочное')) {
          score += 0.08;
          addReason('небольшая жирность помогает сохранить мягкий мякиш');
        }
        if (_containsAny(
          availableSet,
          const {'сыр', 'майонез', 'чеснок', 'лук'},
        )) {
          addWarning('savory-акценты спорят с яблочным профилем шарлотки');
          hardPenalty *= 0.80;
        }
        break;
      }
      if (hasBinder || hasCreamy || hasFat) {
        score += 0.24;
        addReason(
          _describeBakeMoistureReason(
            recipeCanonicals: availableSet,
            stepText: '',
          ),
        );
      } else {
        addWarning('для запекания не хватает связки или более сочной основы');
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
      if (grainDishKind == _GrainDishKind.buckwheatRustic) {
        if (_containsAny(
          recipeCanonicals,
          const {'грибы', 'курица', 'говядина', 'сосиски'},
        )) {
          score += 0.10;
          addReason(
              'гречневая база получает сытный акцент и не кажется пустой');
        } else {
          addWarning(
              'гречке по-домашнему не хватает грибного или мясного акцента');
          hardPenalty *= 0.84;
        }
        if (hasCreamy || hasFat || hasFinishingSupport) {
          score += 0.08;
        } else {
          addWarning('гречке по-домашнему не хватает мягкой домашней опоры');
        }
      }
      break;
    case DishProfile.breakfast:
      if (isPanBatter) {
        if (_containsAny(matchedCanonicals, const {'мука'}) &&
            hasBinder &&
            _containsAny(matchedCanonicals, const {'молоко', 'кефир'})) {
          score += 0.24;
          addReason('есть полная база жареного теста: мука, жидкость и связка');
        } else {
          addWarning(
              'жареному тесту не хватает полной базы для правильной структуры');
          hardPenalty *= 0.78;
        }
        if (hasFat || hasCreamy) {
          score += 0.14;
          addReason('у теста есть мягкая опора, чтобы оно не было сухим');
        } else {
          addWarning('жареному тесту не хватает мягкой жирной опоры');
          hardPenalty *= 0.86;
        }
        if (availableSet.contains('соль')) {
          score += 0.08;
        }
        if (availableSet.contains('сахар')) {
          score += 0.06;
        }
        if (hasFinishingSupport) {
          score += 0.08;
        }
        break;
      }
      if (isFritterBatter) {
        if (_containsAny(matchedCanonicals, const {'мука'}) &&
            matchedCanonicals.contains('яйцо') &&
            matchedCanonicals.contains('кефир')) {
          score += 0.24;
          addReason('есть база оладий: мука, кефир и яйцо');
        } else {
          addWarning('оладьям не хватает полной кефирной базы');
          hardPenalty *= 0.78;
        }
        if (hasFat || hasCreamy) {
          score += 0.14;
          addReason('для оладий есть мягкая опора против сухости');
        } else {
          addWarning('оладьям не хватает мягкой жирной опоры');
          hardPenalty *= 0.86;
        }
        if (availableSet.contains('соль')) {
          score += 0.08;
        }
        if (availableSet.contains('сахар')) {
          score += 0.06;
        }
        if (hasFinishingSupport) {
          score += 0.08;
        }
        break;
      }
      if (isCurdFritter) {
        if (matchedCanonicals.contains('творог') &&
            matchedCanonicals.contains('яйцо')) {
          score += 0.26;
          addReason('есть правильная сырниковая база: творог и яйцо');
        } else {
          addWarning('сырникам не хватает творожной базы или связки');
          hardPenalty *= 0.78;
        }
        if (hasCreamy || hasFat) {
          score += 0.14;
          addReason('сырники поддержаны мягкой сливочной подачей');
        } else {
          addWarning('сырникам не хватает мягкой подачи или жирной опоры');
          hardPenalty *= 0.86;
        }
        if (_containsAny(availableSet, const {'сахар', 'корица', 'яблоко'})) {
          score += 0.10;
        }
        if (hasFinishingSupport) {
          score += 0.08;
        }
        break;
      }
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
      switch (stewDishKind) {
        case _StewDishKind.stewedCabbage:
          if (hasAromatics) {
            score += 0.18;
            addReason('капуста опирается на луково-морковную домашнюю базу');
          } else {
            addWarning(
                'тушёной капусте не хватает домашней ароматической базы');
            hardPenalty *= 0.82;
          }
          if (hasTomatoDepth ||
              _containsAny(
                matchedCanonicals,
                const {'колбаса', 'сосиски', 'курица', 'свинина'},
              )) {
            score += 0.16;
            addReason('тушёная капуста получает томатную или мясную глубину');
          } else {
            addWarning(
                'тушёной капусте не хватает томатной или мясной глубины');
            hardPenalty *= 0.82;
          }
          if (hasFinishingSupport || hasHerbs || hasCreamy) {
            score += 0.08;
          }
          break;
        case _StewDishKind.lazyCabbageRolls:
          if (hasAromatics) {
            score += 0.18;
            addReason('голубцы опираются на спокойную луково-морковную базу');
          } else {
            addWarning(
                'ленивым голубцам не хватает домашней ароматической базы');
            hardPenalty *= 0.80;
          }
          if (hasTomatoDepth || hasCreamy) {
            score += 0.18;
            addReason(
                'томатная или сметанная связка собирает капусту, рис и мясо');
          } else {
            addWarning(
                'ленивым голубцам не хватает томатной или сметанной связки');
            hardPenalty *= 0.78;
          }
          if (hasSalt && hasPepper) {
            score += 0.08;
          }
          if (hasFinishingSupport || hasHerbs) {
            score += 0.08;
          }
          break;
        case _StewDishKind.zrazy:
          if (hasAromatics || matchedCanonicals.contains('лук')) {
            score += 0.18;
            addReason(
                'зразы держатся на домашней луковой базе и отдельной начинке');
          } else {
            addWarning('зразам не хватает ароматической луковой базы');
            hardPenalty *= 0.80;
          }
          if (_containsAny(matchedCanonicals, const {'яйцо', 'грибы'})) {
            score += 0.18;
            addReason(
                'начинка даёт зразам внутренний контраст, а не плоский вкус');
          } else {
            addWarning(
                'зразам не хватает отдельной начинки для правильной структуры');
            hardPenalty *= 0.78;
          }
          if (_containsAny(matchedCanonicals, const {'картофель', 'гречка'})) {
            score += 0.10;
          } else {
            addWarning(
                'зразам нужен отдельный гарнир, а не одиночная мясная подача');
            hardPenalty *= 0.82;
          }
          if (hasSalt && hasPepper) {
            score += 0.08;
          }
          if (hasCreamy || hasFinishingSupport) {
            score += 0.08;
          }
          break;
        case _StewDishKind.homeCutlets:
          if (hasAromatics) {
            score += 0.16;
            addReason('котлетный ужин поддержан овощной поджаркой');
          } else {
            addWarning('котлетному ужину не хватает ароматической базы');
            hardPenalty *= 0.82;
          }
          if (hasFat || hasCreamy) {
            score += 0.16;
            addReason('котлеты и гарнир не будут сухими');
          } else {
            addWarning(
                'котлетному ужину не хватает жирной или сметанной опоры');
            hardPenalty *= 0.80;
          }
          if (_containsAny(
              matchedCanonicals, const {'картофель', 'гречка', 'рис'})) {
            score += 0.12;
          } else {
            addWarning('котлетному ужину не хватает настоящего гарнира');
            hardPenalty *= 0.80;
          }
          if (hasSalt && hasPepper) {
            score += 0.08;
          }
          break;
        case _StewDishKind.tefteli:
          if (hasAromatics) {
            score += 0.18;
            addReason('тефтели держатся на домашней луково-морковной базе');
          } else {
            addWarning('тефтелям не хватает ароматической овощной базы');
            hardPenalty *= 0.80;
          }
          if (hasTomatoDepth || hasCreamy) {
            score += 0.18;
            addReason(
                'соус собирает фарш и рис в одно блюдо, а не в сухую массу');
          } else {
            addWarning(
                'тефтелям не хватает томатной или сметанной соусной связки');
            hardPenalty *= 0.78;
          }
          if (hasSalt && hasPepper) {
            score += 0.08;
          }
          if (hasFinishingSupport || hasHerbs) {
            score += 0.08;
          }
          break;
        case _StewDishKind.goulash:
          if (hasAromatics) {
            score += 0.18;
            addReason(
                'гуляш опирается на лук и ароматику, а не только на мясо');
          } else {
            addWarning('гуляшу не хватает ароматической базы');
            hardPenalty *= 0.80;
          }
          if (hasTomatoDepth || availableSet.contains('паприка')) {
            score += 0.18;
            addReason('паприка и томатная глубина собирают вкус гуляша');
          } else {
            addWarning('гуляшу не хватает паприки или томатной глубины');
            hardPenalty *= 0.78;
          }
          if (hasSalt && hasPepper) {
            score += 0.08;
          }
          if (hasFinishingSupport ||
              hasHerbs ||
              availableSet.contains('чеснок')) {
            score += 0.08;
          }
          break;
        case _StewDishKind.stroganoff:
          if (hasAromatics || recipeCanonicals.contains('лук')) {
            score += 0.16;
            addReason('лук и мягкая база поддерживают мясо, не перегружая его');
          } else {
            addWarning('бефстроганову не хватает луковой базы');
            hardPenalty *= 0.80;
          }
          if (hasCreamy || availableSet.contains('сметана')) {
            score += 0.18;
            addReason('сметанная связка удерживает соус мягким и цельным');
          } else {
            addWarning('бефстроганову не хватает сметанной опоры');
            hardPenalty *= 0.78;
          }
          if (hasSalt && hasPepper) {
            score += 0.08;
          }
          if (matchedCanonicals.contains('грибы') ||
              availableSet.contains('горчица')) {
            score += 0.08;
          }
          break;
        case _StewDishKind.zharkoe:
          if (hasAromatics) {
            score += 0.18;
            addReason(
                'жаркое держится на домашней подложке из овощей и ароматики');
          } else {
            addWarning('жаркому не хватает ароматической базы');
            hardPenalty *= 0.80;
          }
          if (hasSauceSupport) {
            score += 0.16;
            addReason('у жаркого есть соусная связка для картофеля и мяса');
          } else {
            addWarning('жаркому не хватает соусной или мягкой связки');
            hardPenalty *= 0.80;
          }
          if (hasSalt && hasPepper) {
            score += 0.08;
          }
          if (hasFinishingSupport || hasHerbs) {
            score += 0.08;
          }
          break;
        case _StewDishKind.none:
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
      }
      break;
    case DishProfile.skillet:
    case DishProfile.general:
      if (isLiverCake) {
        if (hasAromatics ||
            _containsAny(recipeCanonicals, const {'лук', 'морковь'})) {
          score += 0.18;
          addReason(
              'лук и морковь смягчают печеночную плотность и держат вкус домашним');
        } else {
          addWarning(
              'печеночному торту не хватает луково-морковной овощной прослойки');
          hardPenalty *= 0.82;
        }
        if (_containsAny(availableSet, const {'майонез', 'сметана'})) {
          score += 0.18;
          addReason(
              'мягкая холодная прослойка не дает печени уйти в сухую тяжесть');
        } else {
          addWarning(
              'печеночному торту не хватает мягкой майонезной или сметанной прослойки');
          hardPenalty *= 0.78;
        }
        if (hasSalt && hasPepper) {
          score += 0.10;
        } else {
          addWarning(
              'печеночному торту нужна простая соль и перец без сладкого дрейфа');
        }
        if (hasFinishingSupport || hasHerbs || availableSet.contains('укроп')) {
          score += 0.08;
        }
        if (hasSweet) {
          addWarning('сладость спорит с savory-профилем печеночного торта');
          hardPenalty *= 0.84;
        }
      } else if (isPotatoFritter) {
        if (matchedCanonicals.contains('картофель') &&
            matchedCanonicals.contains('лук')) {
          score += 0.24;
          addReason('есть картофельная и луковая база драников');
        } else {
          addWarning('драникам не хватает картофельной или луковой опоры');
          hardPenalty *= 0.78;
        }
        if (hasFat || hasCreamy) {
          score += 0.16;
          addReason('у драников есть жирность или сметанная поддержка');
        } else {
          addWarning('драникам не хватает жирной или сметанной опоры');
          hardPenalty *= 0.82;
        }
        if (hasSalt) {
          score += 0.08;
        } else {
          addWarning('драникам нужна базовая приправа');
        }
        if (hasPepper || hasFinishingSupport) {
          score += 0.08;
        }
      } else {
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

  if (!hasProtein && !hasBase && profile != DishProfile.salad && !isMors) {
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
  final hasBrightFinish = _containsAny(availableSet, _brightFinishCanonicals);
  final isColdSoup = _isColdSoupDish(recipeCanonicals);
  final isSvekolnik = _isSvekolnikDish(recipeCanonicals);
  final friedDishKind = _detectFriedDishKind(profile, recipeCanonicals);
  final grainDishKind = _detectGrainDishKind(profile, recipeCanonicals);
  final soupKind = _detectSoupKind(recipeCanonicals);
  final stewDishKind = _detectStewDishKind(profile, recipeCanonicals);
  final isPanBatter = friedDishKind == _FriedDishKind.blini;
  final isFritterBatter = friedDishKind == _FriedDishKind.oladyi;
  final isCurdFritter = friedDishKind == _FriedDishKind.syrniki;
  final isPotatoFritter = friedDishKind == _FriedDishKind.draniki;
  final isCharlotte = _isCharlotteDish(recipeCanonicals);
  final isLiverCake = _isLiverCakeDish(recipeCanonicals);
  final isSauerkrautPreserve = _isSauerkrautPreserveDish(recipeCanonicals);
  final isLightlySaltedCucumbers =
      _isLightlySaltedCucumberDish(recipeCanonicals);
  final isMors = _isMorsDish(recipeCanonicals);

  if (isMors) {
    if (freshness >= 0.18 || acidity >= 0.18) {
      score += 0.24;
      addReason('ягоды дают морсу живую свежесть и чистую кислоту');
    } else {
      addWarning('морсу не хватает яркой ягодной свежести');
      hardPenalty *= 0.82;
    }
    if (sweetness >= 0.14) {
      score += 0.18;
      addReason('сладость удерживает кислоту и не даёт вкусу стать резким');
    } else {
      addWarning('морсу не хватает сладкого баланса к ягодной кислоте');
      hardPenalty *= 0.84;
    }
    if (recipeCanonicals.contains('лимон') || hasBrightFinish) {
      score += 0.10;
      addReason('цитрусовый штрих делает ягодный вкус чище и ярче');
    } else {
      addWarning('морсу не хватает яркого лимонного или финишного акцента');
    }
    if (fat >= 0.08 || creaminess >= 0.08 || umami >= 0.12 || spice >= 0.10) {
      addWarning('молочные, жирные или savoury-ноты ломают чистый вкус морса');
      hardPenalty *= 0.74;
    } else {
      score += 0.12;
    }
    if (_hasMorsDrift(recipeCanonicals)) {
      addWarning('чужие добавки уводят морс из ягодного напитка в другой жанр');
      hardPenalty *= 0.72;
    }
    return _FlavorAnalysis(
      score: score.clamp(0.0, 1.0),
      hardPenalty: hardPenalty.clamp(0.0, 1.0),
      reasons: reasons,
      warnings: warnings,
    );
  }

  switch (profile) {
    case DishProfile.salad:
      if (isSauerkrautPreserve) {
        if (recipeCanonicals.contains('капуста') &&
            availableSet.contains('соль')) {
          score += 0.16;
          addReason(
              'капустная свежесть собирается в чистый солёный ферментный контур');
        } else {
          addWarning(
              'квашеной капусте не хватает чистого солёно-капустного ядра');
          hardPenalty *= 0.80;
        }
        if (recipeCanonicals.contains('морковь')) {
          score += 0.10;
          addReason('морковь смягчает резкость и даёт естественную сладость');
        }
        if (crunch >= 0.18) {
          score += 0.16;
          addReason('хруст удерживает квашеную капусту живой, а не вялой');
        } else {
          addWarning('квашеной капусте не хватает уверенного хруста');
          hardPenalty *= 0.86;
        }
        if (fat >= 0.12 || creaminess >= 0.08) {
          addWarning('жирная заправка глушит чистый вкус квашеной капусты');
          hardPenalty *= 0.82;
        } else {
          score += 0.10;
        }
        if (_hasSauerkrautPreserveDrift(recipeCanonicals)) {
          addWarning(
              'чужие салатные или горячие добавки ломают вкус квашеной капусты');
          hardPenalty *= 0.74;
        }
        break;
      }
      if (isLightlySaltedCucumbers) {
        if (crunch >= 0.18) {
          score += 0.20;
          addReason('огурцы сохраняют правильный хруст после короткой засолки');
        } else {
          addWarning('малосольным огурцам не хватает хруста');
          hardPenalty *= 0.84;
        }
        if (freshness >= 0.20) {
          score += 0.12;
          addReason('огуречная свежесть остаётся явной даже после засолки');
        } else {
          addWarning('малосольным огурцам не хватает огуречной свежести');
          hardPenalty *= 0.86;
        }
        if (herbiness >= 0.08 && spice >= 0.08) {
          score += 0.14;
          addReason('укроп и чеснок собирают классический малосольный аромат');
        } else {
          addWarning(
              'малосольным огурцам не хватает укропно-чесночного профиля');
          hardPenalty *= 0.82;
        }
        if (fat >= 0.12 || creaminess >= 0.08) {
          addWarning(
              'жирная заправка спорит с чистым вкусом малосольных огурцов');
          hardPenalty *= 0.82;
        } else {
          score += 0.08;
        }
        if (_hasLightlySaltedCucumberDrift(recipeCanonicals)) {
          addWarning(
              'чужие салатные или горячие добавки ломают вкус малосольных огурцов');
          hardPenalty *= 0.74;
        }
        break;
      }
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
      if (isColdSoup) {
        if (freshness >= 0.16) {
          score += 0.18;
          addReason('холодный суп держится на явной свежести, а не на тяжести');
        } else {
          addWarning('холодному супу не хватает свежего вкуса');
          hardPenalty *= 0.84;
        }
        if (acidity >= 0.14 || creaminess >= 0.18) {
          score += 0.14;
          addReason('холодная база даёт окрошке чистый и собранный вкус');
        } else {
          addWarning('холодному супу не хватает собранной холодной базы');
          hardPenalty *= 0.86;
        }
        if (herbiness >= 0.08) {
          score += 0.10;
          addReason('зелень удерживает вкус холодного супа ярким');
        } else {
          addWarning('холодному супу не хватает травяного акцента');
        }
        if (umami >= 0.10 || fat >= 0.08) {
          score += 0.08;
        } else {
          addWarning(
              'холодному супу не хватает опоры, чтобы вкус не был водянистым');
        }
        if (isSvekolnik) {
          if (recipeCanonicals.contains('свекла') &&
              (freshness >= 0.14 || acidity >= 0.10) &&
              (creaminess >= 0.10 || herbiness >= 0.08)) {
            score += 0.10;
            addReason(
                'свекольник держит холодную свекольную свежесть без водянистости');
          } else {
            addWarning(
                'свекольнику не хватает свекольной свежести и мягкого финиша');
            hardPenalty *= 0.84;
          }
          if (spice >= 0.14) {
            addWarning('свекольник перегружается лишней пряностью');
            hardPenalty *= 0.88;
          }
        }
        break;
      }
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
      switch (soupKind) {
        case _SoupKind.greenShchi:
          final hasSoftGreenFinish = recipeCanonicals.contains('сметана') ||
              recipeCanonicals.contains('укроп');
          if ((freshness >= 0.12 || acidity >= 0.10) &&
              (creaminess >= 0.10 || herbiness >= 0.08)) {
            score += 0.10;
            addReason('щавелевые щи держат зелёную кислоту мягкой и собранной');
          } else {
            addWarning('щавелевым щам не хватает мягкого зелёного баланса');
            hardPenalty *= 0.84;
          }
          if (recipeCanonicals.contains('яйцо') && hasSoftGreenFinish) {
            score += 0.08;
            addReason('яйцо и мягкий финиш собирают зелёную щавелевую кислоту');
          } else if (!hasSoftGreenFinish) {
            score -= 0.04;
          }
          if (recipeCanonicals.contains('лук') &&
              recipeCanonicals.contains('морковь')) {
            score += 0.06;
            addReason('луково-морковная база смягчает зелёную кислоту щей');
          }
          if (sweetness >= 0.18 &&
              herbiness < 0.10 &&
              creaminess < 0.12 &&
              acidity < 0.16) {
            addWarning(
                'сладость спорит с зелёной кислой природой щавелевых щей');
            hardPenalty *= 0.88;
          }
          break;
        case _SoupKind.mushroom:
          final hasSoftMushroomFinish = availableSet.contains('сметана') ||
              availableSet.contains('укроп') ||
              availableSet.contains('лавровый лист');
          if (hasSoftMushroomFinish) {
            score += 0.12;
            addReason('грибной суп держит глубину без сырой водянистости');
          } else {
            addWarning(
                'грибному супу не хватает мягкого или травяного баланса к грибной глубине');
            hardPenalty *= 0.86;
          }
          if (recipeCanonicals.contains('лук') &&
              recipeCanonicals.contains('морковь')) {
            score += 0.06;
            addReason('луково-морковная база смягчает грибную глубину');
          }
          if (hasTomatoDepth || acidity >= 0.14) {
            addWarning(
                'грибной суп перегружается томатной или слишком резкой кислой нотой');
            hardPenalty *= 0.88;
          }
          break;
        case _SoupKind.peaSmoked:
          final hasSoftPeaFinish = availableSet.contains('сметана') ||
              availableSet.contains('укроп') ||
              availableSet.contains('лавровый лист');
          if (((recipeCanonicals.contains('горох') &&
                      _containsAny(
                        recipeCanonicals,
                        const {'колбаса', 'сосиски'},
                      )) ||
                  umami >= 0.18) &&
              (fat >= 0.10 || creaminess >= 0.08) &&
              hasSoftPeaFinish) {
            score += 0.12;
            addReason(
                'гороховый суп держит плотный копчёный вкус мягким и собранным');
          } else {
            addWarning(
                'гороховому супу не хватает мягкого баланса к копчёной и бобовой плотности');
            hardPenalty *= 0.86;
          }
          if (recipeCanonicals.contains('лук') &&
              recipeCanonicals.contains('морковь')) {
            score += 0.06;
            addReason('лук и морковь смягчают густую гороховую основу');
          }
          if (availableSet.contains('сметана') ||
              availableSet.contains('укроп')) {
            score += 0.06;
            addReason('сметана или укроп смягчают копчёную густоту гороха');
          } else {
            addWarning(
                'гороховому супу не хватает сметанного или травяного финиша');
            hardPenalty *= 0.90;
          }
          if (hasTomatoDepth || acidity >= 0.18) {
            addWarning(
                'гороховый суп перегружается лишней томатной или кислой нотой');
            hardPenalty *= 0.88;
          }
          break;
        case _SoupKind.shchi:
          if (freshness >= 0.12 && (creaminess >= 0.12 || herbiness >= 0.10)) {
            score += 0.08;
            addReason('щи держат мягкий капустный вкус без лишней тяжести');
          } else {
            addWarning('щам не хватает мягкого капустного баланса');
            hardPenalty *= 0.88;
          }
          break;
        case _SoupKind.borscht:
          if (recipeCanonicals.contains('свекла') &&
              recipeCanonicals.contains('капуста') &&
              hasTomatoDepth &&
              (acidity >= 0.06 ||
                  creaminess >= 0.06 ||
                  herbiness >= 0.08 ||
                  availableSet.contains('сметана'))) {
            score += 0.12;
            addReason(
                'борщ балансирует свекольную сладость кислотой и глубиной');
          } else {
            addWarning(
                'борщу не хватает баланса между свеклой, кислотой и томатом');
            hardPenalty *= 0.86;
          }
          break;
        case _SoupKind.ukha:
        case _SoupKind.rassolnik:
          break;
        case _SoupKind.solyanka:
          if (umami >= 0.18 &&
              acidity >= 0.12 &&
              (freshness >= 0.10 || hasBrightFinish)) {
            score += 0.10;
            addReason('солянка держит яркий мясной вкус без глухой тяжести');
          } else {
            addWarning('солянке не хватает яркого мясного и кислого баланса');
            hardPenalty *= 0.86;
          }
          break;
        case _SoupKind.none:
          break;
      }
      break;
    case DishProfile.bake:
      if (isCharlotte) {
        if (sweetness >= 0.18 && freshness >= 0.08) {
          score += 0.20;
          addReason('яблочная сладость и свежесть держат шарлотку живой');
        } else {
          addWarning('шарлотке не хватает яблочной сладости и свежести');
          hardPenalty *= 0.84;
        }
        if (fat >= 0.08 || creaminess >= 0.08) {
          score += 0.12;
          addReason(
              'небольшая жирность делает мякиш мягче и не даёт ему крошиться');
        } else {
          addWarning('шарлотке не хватает мягкой жировой опоры');
          hardPenalty *= 0.86;
        }
        if (acidity >= 0.05 || freshness >= 0.10) {
          score += 0.10;
          addReason('яблочный контраст не дает шарлотке стать приторной');
        } else {
          addWarning('шарлотке не хватает яблочного контраста против сладости');
          hardPenalty *= 0.84;
        }
        if (hasWarmSpice || availableSet.contains('корица')) {
          score += 0.08;
          addReason('тёплая специя собирает печёный яблочный аромат');
        }
        if (_containsAny(
          recipeCanonicals,
          const {'сыр', 'майонез', 'чеснок', 'лук'},
        )) {
          addWarning('savory-ноты спорят с фруктовым вкусом шарлотки');
          hardPenalty *= 0.80;
        }
        break;
      }
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
    case DishProfile.skillet:
    case DishProfile.general:
      if (isLiverCake) {
        if (recipeCanonicals.contains('печень') || umami >= 0.18) {
          score += 0.18;
          addReason(
              'печень дает торту плотную savory-глубину, а не пустой вкус');
        } else {
          addWarning(
              'печеночному торту не хватает выраженной печеночной глубины');
          hardPenalty *= 0.86;
        }
        if (creaminess >= 0.12 ||
            fat >= 0.12 ||
            _containsAny(availableSet, const {'майонез', 'сметана'})) {
          score += 0.16;
          addReason('мягкая прослойка собирает печеночный вкус без сухости');
        } else {
          addWarning('печеночному торту не хватает мягкой жирной прослойки');
          hardPenalty *= 0.84;
        }
        if (recipeCanonicals.contains('морковь') || sweetness >= 0.06) {
          score += 0.08;
          addReason('морковь добавляет мягкий сладковатый контраст к печени');
        }
        if (creaminess >= 0.12 || acidity >= 0.04) {
          score += 0.08;
          addReason('холодная прослойка удерживает вкус торта собранным');
        }
        if (herbiness >= 0.04 || availableSet.contains('укроп')) {
          score += 0.06;
          addReason('зелень не дает печеночному торту уйти в тяжесть');
        } else {
          addWarning(
              'печеночному торту не хватает легкого свежего или травяного акцента');
        }
        if (_containsAny(recipeCanonicals, const {'сахар', 'корица'})) {
          addWarning(
              'сладкий акцент спорит с домашним профилем печеночного торта');
          hardPenalty *= 0.82;
        }
      } else if (grainDishKind == _GrainDishKind.buckwheatRustic) {
        if (umami >= 0.16) {
          score += 0.18;
          addReason('грибы или мясной акцент дают гречке домашнюю глубину');
        } else {
          addWarning(
              'гречке по-домашнему не хватает грибной или мясной насыщенности');
          hardPenalty *= 0.86;
        }
        if (fat >= 0.10 || creaminess >= 0.10) {
          score += 0.12;
        } else {
          addWarning('гречке по-домашнему не хватает мягкой жирной опоры');
        }
        if (freshness >= 0.06 || herbiness >= 0.08 || acidity >= 0.06) {
          score += 0.08;
        } else {
          addWarning(
              'гречке по-домашнему не хватает свежего или травяного акцента');
        }
        if (sweetness >= 0.18) {
          addWarning('сладость спорит с домашним savoury-профилем гречки');
          hardPenalty *= 0.86;
        }
      } else if (isPotatoFritter) {
        if (umami >= 0.12 || spice >= 0.06) {
          score += 0.14;
          addReason('картофель и лук дают драникам домашнюю насыщенность');
        } else {
          addWarning('драникам не хватает насыщенности картофеля и лука');
          hardPenalty *= 0.88;
        }
        if (fat >= 0.14 || creaminess >= 0.12) {
          score += 0.14;
        } else {
          addWarning('драникам не хватает жирной или сметанной мягкости');
        }
        if (acidity >= 0.08 || freshness >= 0.10 || creaminess >= 0.12) {
          score += 0.08;
        } else {
          addWarning('драникам не хватает лёгкого контраста к жареной базе');
        }
        if (sweetness >= 0.18) {
          addWarning('сладость спорит с картофельной природой драников');
          hardPenalty *= 0.82;
        }
      } else {
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
      }
      break;
    case DishProfile.stew:
      switch (stewDishKind) {
        case _StewDishKind.stewedCabbage:
          if (umami >= 0.14 ||
              _containsAny(
                recipeCanonicals,
                const {'колбаса', 'сосиски', 'курица', 'свинина'},
              )) {
            score += 0.18;
            addReason(
                'капуста получает мясную или грибную глубину и не кажется пустой');
          } else {
            addWarning('тушёной капусте не хватает глубины вкуса');
            hardPenalty *= 0.86;
          }
          if (fat >= 0.10 || creaminess >= 0.08) {
            score += 0.12;
          } else {
            addWarning('тушёной капусте не хватает мягкой домашней опоры');
          }
          if (acidity >= 0.08 || hasTomatoDepth || herbiness >= 0.06) {
            score += 0.10;
            addReason(
                'томат и зелень удерживают капусту собранной, а не ватной');
          } else {
            addWarning(
                'тушёной капусте не хватает томатного или травяного контраста');
            hardPenalty *= 0.84;
          }
          if (sweetness >= 0.24) {
            addWarning(
                'сладость начинает спорить с домашним профилем тушёной капусты');
            hardPenalty *= 0.88;
          }
          break;
        case _StewDishKind.lazyCabbageRolls:
          if (umami >= 0.18) {
            score += 0.18;
            addReason(
                'капуста, мясо и рис дают голубцам спокойную насыщенность');
          } else {
            addWarning('ленивым голубцам не хватает мясной и овощной глубины');
            hardPenalty *= 0.86;
          }
          if (fat >= 0.14 || creaminess >= 0.12) {
            score += 0.12;
          } else {
            addWarning('ленивым голубцам не хватает мягкости и соусной опоры');
          }
          if (acidity >= 0.08 || hasTomatoDepth || creaminess >= 0.12) {
            score += 0.10;
            addReason(
                'томатный или сметанный слой удерживает голубцы собранными');
          } else {
            addWarning(
                'ленивым голубцам не хватает томатного или сметанного баланса');
            hardPenalty *= 0.84;
          }
          if (sweetness >= 0.22) {
            addWarning(
                'сладость начинает спорить с домашним профилем голубцов');
            hardPenalty *= 0.88;
          }
          break;
        case _StewDishKind.zrazy:
          if (umami >= 0.14 || recipeCanonicals.contains('фарш')) {
            score += 0.18;
            addReason('фарш даёт зразам плотную мясную основу');
          } else {
            addWarning('зразам не хватает мясной насыщенности');
            hardPenalty *= 0.86;
          }
          if (_containsAny(recipeCanonicals, const {'яйцо', 'грибы'})) {
            score += 0.12;
            addReason('начинка добавляет зразам нужный внутренний контраст');
          } else {
            addWarning(
                'зразам не хватает начинки, которая раскрывает вкус внутри');
            hardPenalty *= 0.84;
          }
          if (fat >= 0.10 ||
              creaminess >= 0.08 ||
              availableSet.contains('сметана') ||
              availableSet.contains('масло')) {
            score += 0.10;
          } else {
            addWarning('зразам не хватает мягкости и домашней жирной опоры');
          }
          if (freshness >= 0.04 ||
              herbiness >= 0.04 ||
              availableSet.contains('сметана')) {
            score += 0.08;
          }
          if (acidity >= 0.18) {
            addWarning('кислота начинает спорить с домашним профилем зраз');
            hardPenalty *= 0.90;
          }
          break;
        case _StewDishKind.homeCutlets:
          if (umami >= 0.12 || _containsAny(recipeCanonicals, const {'фарш'})) {
            score += 0.18;
            addReason('котлеты дают нужную мясную насыщенность');
          } else {
            addWarning('котлетному ужину не хватает мясной насыщенности');
            hardPenalty *= 0.86;
          }
          if (fat >= 0.10 ||
              creaminess >= 0.08 ||
              availableSet.contains('сметана') ||
              availableSet.contains('масло')) {
            score += 0.12;
          } else {
            addWarning('котлетному ужину не хватает мягкости и жирной опоры');
          }
          if (_containsAny(recipeCanonicals, const {'лук', 'морковь'})) {
            score += 0.08;
            addReason(
                'овощная поджарка делает котлетный вкус домашним, а не плоским');
          }
          if (herbiness >= 0.04 ||
              freshness >= 0.06 ||
              creaminess >= 0.08 ||
              availableSet.contains('сметана')) {
            score += 0.08;
          } else {
            addWarning(
                'котлетному ужину не хватает мягкого финиша к мясу и гарниру');
          }
          if (acidity >= 0.18) {
            addWarning(
                'кислота начинает спорить с домашним котлетным профилем');
            hardPenalty *= 0.90;
          }
          break;
        case _StewDishKind.tefteli:
          if (umami >= 0.14 || recipeCanonicals.contains('фарш')) {
            score += 0.18;
            addReason('фарш даёт тефтелям уверенную мясную основу');
          } else {
            addWarning('тефтелям не хватает мясной насыщенности');
            hardPenalty *= 0.86;
          }
          if (fat >= 0.10 ||
              creaminess >= 0.10 ||
              availableSet.contains('сметана')) {
            score += 0.12;
          } else {
            addWarning('тефтелям не хватает мягкости и соусной опоры');
          }
          if (acidity >= 0.08 || hasTomatoDepth || creaminess >= 0.10) {
            score += 0.10;
            addReason('соус даёт тефтелям правильный томатно-сметанный баланс');
          } else {
            addWarning('тефтелям не хватает собранного соусного баланса');
            hardPenalty *= 0.84;
          }
          if (herbiness >= 0.04 ||
              freshness >= 0.06 ||
              availableSet.contains('укроп')) {
            score += 0.08;
          }
          if (sweetness >= 0.22) {
            addWarning('сладость спорит с домашним профилем тефтелей');
            hardPenalty *= 0.88;
          }
          break;
        case _StewDishKind.goulash:
          if (umami >= 0.16 ||
              _containsAny(recipeCanonicals, const {'говядина', 'свинина'})) {
            score += 0.18;
            addReason('гуляш держит плотную мясную глубину');
          } else {
            addWarning('гуляшу не хватает мясной насыщенности');
            hardPenalty *= 0.86;
          }
          if (fat >= 0.10 || creaminess >= 0.08) {
            score += 0.10;
          } else {
            addWarning('гуляшу не хватает мягкой жирной опоры');
          }
          if (spice >= 0.08 ||
              hasTomatoDepth ||
              availableSet.contains('паприка') ||
              availableSet.contains('томатная паста')) {
            score += 0.12;
            addReason('паприка и томат дают гуляшу тёплую густую глубину');
          } else {
            addWarning('гуляшу не хватает папрично-томатной глубины');
            hardPenalty *= 0.84;
          }
          if (freshness >= 0.04 ||
              herbiness >= 0.04 ||
              availableSet.contains('чеснок')) {
            score += 0.08;
          }
          if (sweetness >= 0.20) {
            addWarning('сладость спорит с плотным мясным профилем гуляша');
            hardPenalty *= 0.88;
          }
          break;
        case _StewDishKind.stroganoff:
          if (umami >= 0.14 || recipeCanonicals.contains('говядина')) {
            score += 0.18;
            addReason('говядина даёт бефстроганову нужную мясную глубину');
          } else {
            addWarning('бефстроганову не хватает говяжьей насыщенности');
            hardPenalty *= 0.86;
          }
          if (creaminess >= 0.14 || availableSet.contains('сметана')) {
            score += 0.14;
            addReason('сметана даёт соусу мягкость без тяжести');
          } else {
            addWarning('бефстроганову не хватает мягкой сметанной опоры');
            hardPenalty *= 0.84;
          }
          if (umami >= 0.18 ||
              recipeCanonicals.contains('лук') ||
              recipeCanonicals.contains('грибы')) {
            score += 0.08;
          }
          if (acidity >= 0.06 || availableSet.contains('горчица')) {
            score += 0.08;
            addReason('лёгкая кислинка или горчица не дают соусу стать ватным');
          }
          if (spice >= 0.12 || hasTomatoDepth) {
            addWarning(
                'бефстроганов перегружается лишней пряностью или томатом');
            hardPenalty *= 0.86;
          }
          break;
        case _StewDishKind.zharkoe:
          if (umami >= 0.14 ||
              _containsAny(
                recipeCanonicals,
                const {'говядина', 'свинина', 'курица'},
              )) {
            score += 0.18;
            addReason('жаркое держит насыщенный мясной вкус');
          } else {
            addWarning('жаркому не хватает мясной насыщенности');
            hardPenalty *= 0.86;
          }
          if (fat >= 0.10 ||
              creaminess >= 0.08 ||
              availableSet.contains('сметана')) {
            score += 0.12;
          } else {
            addWarning('жаркому не хватает мягкой жирной опоры');
          }
          if (_containsAny(recipeCanonicals, const {'лук', 'морковь'})) {
            score += 0.08;
            addReason('овощная подложка удерживает жаркое от плоского вкуса');
          }
          if (spice >= 0.04 ||
              herbiness >= 0.04 ||
              freshness >= 0.06 ||
              availableSet.contains('чеснок')) {
            score += 0.08;
          } else {
            addWarning('жаркому не хватает специй или финального акцента');
          }
          if (sweetness >= 0.20) {
            addWarning('сладость спорит с густым мясным профилем жаркого');
            hardPenalty *= 0.88;
          }
          break;
        case _StewDishKind.none:
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
      }
      break;
    case DishProfile.breakfast:
      if (isPanBatter) {
        if (fat >= 0.12 || creaminess >= 0.16) {
          score += 0.16;
          addReason('жареное тесто не будет сухим и останется мягким');
        } else {
          addWarning('жареному тесту не хватает мягкости и жирной опоры');
          hardPenalty *= 0.86;
        }
        if (sweetness >= 0.04 && sweetness <= 0.26) {
          score += 0.10;
          addReason('сладость остаётся деликатной и не забивает тесто');
        } else if (sweetness > 0.30) {
          addWarning(
              'для жареного теста сладость выходит слишком прямолинейной');
          hardPenalty *= 0.90;
        }
        if (acidity >= 0.10 && recipeCanonicals.contains('кефир')) {
          score += 0.08;
          addReason('кефир даёт тесту живой и собранный вкус');
        }
        if (spice >= 0.14 || herbiness >= 0.12) {
          addWarning('тесто перегружается лишней пряностью');
          hardPenalty *= 0.84;
        }
      } else if (isFritterBatter) {
        if (fat >= 0.12 || creaminess >= 0.14) {
          score += 0.16;
          addReason('оладьи останутся мягкими и не уйдут в сухость');
        } else {
          addWarning('оладьям не хватает мягкости и жирной опоры');
          hardPenalty *= 0.86;
        }
        if (sweetness >= 0.04 && sweetness <= 0.24) {
          score += 0.10;
          addReason('сладость у оладий остаётся деликатной');
        } else if (sweetness > 0.30) {
          addWarning('для оладий сладость выходит слишком прямой');
          hardPenalty *= 0.90;
        }
        if (acidity >= 0.10) {
          score += 0.08;
          addReason('кефир удерживает вкус оладий живым');
        }
        if (spice >= 0.14 || herbiness >= 0.12) {
          addWarning('оладьи перегружаются лишней пряностью');
          hardPenalty *= 0.84;
        }
      } else if (isCurdFritter) {
        if (creaminess >= 0.18 || fat >= 0.12) {
          score += 0.16;
          addReason('творожная база остаётся нежной и не сухой');
        } else {
          addWarning('сырникам не хватает мягкости и сливочной опоры');
          hardPenalty *= 0.86;
        }
        if (sweetness >= 0.06 && sweetness <= 0.26) {
          score += 0.10;
          addReason('сладость поддерживает творог и не спорит с ним');
        } else if (sweetness > 0.30) {
          addWarning('сырники рискуют уйти в приторную сладость');
          hardPenalty *= 0.90;
        }
        if (acidity >= 0.08 || freshness >= 0.10 || creaminess >= 0.18) {
          score += 0.08;
        } else {
          addWarning('сырникам не хватает свежего или сметанного контраста');
        }
        if (spice >= 0.16 || herbiness >= 0.12) {
          addWarning('сырники перегружаются лишней пряностью');
          hardPenalty *= 0.84;
        }
      } else if (isSweetBreakfast) {
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
        addReason(
            'у основы есть яркий акцент, поэтому вкус не уходит в тяжесть');
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
        addWarning(
            'основе не хватает одной из опор: насыщенности, связки или контраста');
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
          addReason(
              'сладкий завтрак сбалансирован мягкостью и свежим контрастом');
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

bool _isColdSoupDish(Set<String> ingredientCanonicals) {
  return _containsAny(ingredientCanonicals, _coldSoupBaseCanonicals) &&
      ingredientCanonicals.contains('огурец') &&
      ingredientCanonicals.contains('картофель');
}

bool _isSvekolnikDish(Set<String> ingredientCanonicals) {
  return _isColdSoupDish(ingredientCanonicals) &&
      ingredientCanonicals.contains('свекла') &&
      ingredientCanonicals.contains('яйцо');
}

bool _isSauerkrautPreserveDish(Set<String> ingredientCanonicals) {
  return ingredientCanonicals.contains('капуста') &&
      ingredientCanonicals.contains('соль') &&
      ingredientCanonicals.every(_sauerkrautAllowedCanonicals.contains);
}

bool _isLightlySaltedCucumberDish(Set<String> ingredientCanonicals) {
  return ingredientCanonicals.contains('огурец') &&
      ingredientCanonicals.contains('укроп') &&
      ingredientCanonicals.contains('чеснок') &&
      ingredientCanonicals.contains('соль') &&
      ingredientCanonicals
          .every(_lightlySaltedCucumberAllowedCanonicals.contains);
}

bool _hasSauerkrautPreserveDrift(Set<String> ingredientCanonicals) {
  return ingredientCanonicals
      .any((canonical) => !_sauerkrautAllowedCanonicals.contains(canonical));
}

bool _hasLightlySaltedCucumberDrift(Set<String> ingredientCanonicals) {
  return ingredientCanonicals.any(
    (canonical) => !_lightlySaltedCucumberAllowedCanonicals.contains(canonical),
  );
}

bool _isMorsDish(Set<String> ingredientCanonicals) {
  return _containsAny(ingredientCanonicals, _morsBerryCanonicals) &&
      ingredientCanonicals.contains('сахар') &&
      ingredientCanonicals.every(_morsAllowedCanonicals.contains);
}

bool _hasMorsDrift(Set<String> ingredientCanonicals) {
  return ingredientCanonicals
      .any((canonical) => !_morsAllowedCanonicals.contains(canonical));
}

bool _isGreenShchiDish(Set<String> ingredientCanonicals) {
  return ingredientCanonicals.contains('щавель') &&
      !_containsAny(ingredientCanonicals, _coldSoupBaseCanonicals) &&
      _containsAny(
        ingredientCanonicals,
        const {'картофель', 'лук', 'морковь'},
      );
}

bool _isCharlotteDish(Set<String> ingredientCanonicals) {
  return ingredientCanonicals.contains('яблоко') &&
      ingredientCanonicals.contains('яйцо') &&
      ingredientCanonicals.contains('мука') &&
      !ingredientCanonicals.contains('творог') &&
      !ingredientCanonicals.contains('сыр') &&
      !ingredientCanonicals.contains('лук') &&
      !ingredientCanonicals.contains('чеснок') &&
      !ingredientCanonicals.contains('печень') &&
      !ingredientCanonicals.contains('капуста') &&
      !ingredientCanonicals.contains('картофель') &&
      !_containsAny(ingredientCanonicals, _redMeatCanonicals) &&
      !_containsAny(ingredientCanonicals, _fishCanonicals);
}

bool _isMushroomSoupDish(Set<String> ingredientCanonicals) {
  return ingredientCanonicals.contains('грибы') &&
      ingredientCanonicals.contains('картофель') &&
      _containsAny(ingredientCanonicals, const {'лук', 'морковь'}) &&
      !ingredientCanonicals.contains('свекла') &&
      !ingredientCanonicals.contains('капуста') &&
      !ingredientCanonicals.contains('огурец') &&
      !ingredientCanonicals.contains('перловка') &&
      !_containsAny(
        ingredientCanonicals,
        const {'рыба', 'колбаса', 'сосиски'},
      );
}

bool _isLiverCakeDish(Set<String> ingredientCanonicals) {
  return ingredientCanonicals.contains('печень') &&
      ingredientCanonicals.contains('яйцо') &&
      ingredientCanonicals.contains('мука') &&
      ingredientCanonicals.contains('лук') &&
      ingredientCanonicals.contains('морковь') &&
      !ingredientCanonicals.contains('картофель') &&
      !ingredientCanonicals.contains('кефир') &&
      !ingredientCanonicals.contains('творог');
}

enum _FriedDishKind {
  none,
  blini,
  oladyi,
  syrniki,
  draniki,
}

enum _SoupKind {
  none,
  greenShchi,
  mushroom,
  peaSmoked,
  shchi,
  borscht,
  ukha,
  rassolnik,
  solyanka,
}

enum _GrainDishKind {
  none,
  buckwheatRustic,
}

enum _StewDishKind {
  none,
  stewedCabbage,
  lazyCabbageRolls,
  tefteli,
  zrazy,
  homeCutlets,
  zharkoe,
  goulash,
  stroganoff,
}

_FriedDishKind _detectFriedDishKind(
  DishProfile profile,
  Set<String> ingredientCanonicals,
) {
  if (profile == DishProfile.breakfast) {
    if (ingredientCanonicals.contains('творог') &&
        ingredientCanonicals.contains('яйцо') &&
        !ingredientCanonicals.contains('картофель')) {
      return _FriedDishKind.syrniki;
    }
    if (ingredientCanonicals.contains('мука') &&
        ingredientCanonicals.contains('яйцо')) {
      if (ingredientCanonicals.contains('молоко')) {
        return _FriedDishKind.blini;
      }
      if (ingredientCanonicals.contains('кефир')) {
        return _FriedDishKind.oladyi;
      }
    }
  }
  if (profile == DishProfile.skillet &&
      ingredientCanonicals.contains('картофель') &&
      ingredientCanonicals.contains('лук') &&
      _containsAny(ingredientCanonicals, const {'яйцо', 'мука'})) {
    return _FriedDishKind.draniki;
  }
  return _FriedDishKind.none;
}

_SoupKind _detectSoupKind(Set<String> ingredientCanonicals) {
  if (_isColdSoupDish(ingredientCanonicals)) {
    return _SoupKind.none;
  }
  if (_isGreenShchiDish(ingredientCanonicals)) {
    return _SoupKind.greenShchi;
  }
  if (ingredientCanonicals.contains('рыба')) {
    return _SoupKind.ukha;
  }
  if (ingredientCanonicals.contains('перловка') &&
      ingredientCanonicals.contains('огурец')) {
    return _SoupKind.rassolnik;
  }
  if (ingredientCanonicals.contains('свекла') &&
      ingredientCanonicals.contains('капуста')) {
    return _SoupKind.borscht;
  }
  if (_containsAny(
          ingredientCanonicals, const {'колбаса', 'сосиски', 'говядина'}) &&
      ingredientCanonicals.contains('огурец') &&
      _containsAny(
          ingredientCanonicals, const {'оливки', 'лимон', 'томатная паста'})) {
    return _SoupKind.solyanka;
  }
  if (_isMushroomSoupDish(ingredientCanonicals)) {
    return _SoupKind.mushroom;
  }
  if (ingredientCanonicals.contains('горох') &&
      _containsAny(ingredientCanonicals, const {'колбаса', 'сосиски'}) &&
      _containsAny(ingredientCanonicals, const {'лук', 'морковь'})) {
    return _SoupKind.peaSmoked;
  }
  if (ingredientCanonicals.contains('капуста') &&
      !ingredientCanonicals.contains('свекла')) {
    return _SoupKind.shchi;
  }
  return _SoupKind.none;
}

_GrainDishKind _detectGrainDishKind(
  DishProfile profile,
  Set<String> ingredientCanonicals,
) {
  if (profile != DishProfile.grainBowl) {
    return _GrainDishKind.none;
  }
  if (ingredientCanonicals.contains('гречка') &&
      _containsAny(
        ingredientCanonicals,
        const {'грибы', 'лук', 'морковь', 'курица', 'говядина', 'сосиски'},
      )) {
    return _GrainDishKind.buckwheatRustic;
  }
  return _GrainDishKind.none;
}

_StewDishKind _detectStewDishKind(
  DishProfile profile,
  Set<String> ingredientCanonicals,
) {
  if (profile != DishProfile.stew) {
    return _StewDishKind.none;
  }
  if (ingredientCanonicals.contains('фарш') &&
      ingredientCanonicals.contains('рис') &&
      ingredientCanonicals.contains('капуста')) {
    return _StewDishKind.lazyCabbageRolls;
  }
  if (ingredientCanonicals.contains('капуста') &&
      _containsAny(ingredientCanonicals, const {'лук', 'морковь'}) &&
      !ingredientCanonicals.contains('рис') &&
      !ingredientCanonicals.contains('фарш')) {
    return _StewDishKind.stewedCabbage;
  }
  if (ingredientCanonicals.contains('фарш') &&
      _containsAny(
        ingredientCanonicals,
        const {'картофель', 'гречка'},
      ) &&
      _containsAny(
        ingredientCanonicals,
        const {'яйцо', 'грибы'},
      ) &&
      !ingredientCanonicals.contains('рис') &&
      !ingredientCanonicals.contains('капуста')) {
    return _StewDishKind.zrazy;
  }
  if (ingredientCanonicals.contains('фарш') &&
      ingredientCanonicals.contains('рис') &&
      !ingredientCanonicals.contains('капуста') &&
      _containsAny(
        ingredientCanonicals,
        const {'томатная паста', 'сметана'},
      )) {
    return _StewDishKind.tefteli;
  }
  if (ingredientCanonicals.contains('говядина') &&
      ingredientCanonicals.contains('лук') &&
      ingredientCanonicals.contains('сметана') &&
      !_containsAny(
        ingredientCanonicals,
        const {'паприка', 'томатная паста', 'лимон', 'укроп', 'зелень'},
      ) &&
      !ingredientCanonicals.contains('картофель')) {
    return _StewDishKind.stroganoff;
  }
  if (ingredientCanonicals.contains('картофель') &&
      _containsAny(
        ingredientCanonicals,
        const {'говядина', 'свинина', 'курица'},
      ) &&
      !ingredientCanonicals.contains('фарш')) {
    return _StewDishKind.zharkoe;
  }
  if (_containsAny(
        ingredientCanonicals,
        const {'говядина', 'свинина'},
      ) &&
      ingredientCanonicals.contains('лук') &&
      _containsAny(
        ingredientCanonicals,
        const {'паприка', 'томатная паста'},
      ) &&
      !ingredientCanonicals.contains('картофель')) {
    return _StewDishKind.goulash;
  }
  if (ingredientCanonicals.contains('фарш') &&
      _containsAny(
        ingredientCanonicals,
        const {'картофель', 'гречка', 'рис'},
      ) &&
      !ingredientCanonicals.contains('капуста')) {
    return _StewDishKind.homeCutlets;
  }
  return _StewDishKind.none;
}

bool _isFriedSkilletDish(
  DishProfile profile,
  Set<String> ingredientCanonicals,
) {
  return _detectFriedDishKind(profile, ingredientCanonicals) !=
      _FriedDishKind.none;
}

List<String> _recommendedAromatics(
  DishProfile profile,
  Set<String> ingredientCanonicals,
) {
  final soupKind = _detectSoupKind(ingredientCanonicals);
  final grainDishKind = _detectGrainDishKind(profile, ingredientCanonicals);
  final stewDishKind = _detectStewDishKind(profile, ingredientCanonicals);
  if (_isMorsDish(ingredientCanonicals) ||
      _isSauerkrautPreserveDish(ingredientCanonicals) ||
      _isLightlySaltedCucumberDish(ingredientCanonicals)) {
    return const [];
  }
  if (_isCharlotteDish(ingredientCanonicals)) {
    return const [];
  }
  if (_isLiverCakeDish(ingredientCanonicals)) {
    return const ['лук', 'морковь'];
  }
  if (_isColdSoupDish(ingredientCanonicals) ||
      _isFriedSkilletDish(profile, ingredientCanonicals)) {
    return const [];
  }
  switch (stewDishKind) {
    case _StewDishKind.stewedCabbage:
      return const ['лук', 'морковь'];
    case _StewDishKind.lazyCabbageRolls:
      return const ['лук', 'морковь'];
    case _StewDishKind.tefteli:
      return const ['лук', 'морковь'];
    case _StewDishKind.zrazy:
      return const ['лук', 'грибы'];
    case _StewDishKind.homeCutlets:
      return const ['лук', 'морковь'];
    case _StewDishKind.zharkoe:
      return const ['лук', 'морковь', 'чеснок'];
    case _StewDishKind.goulash:
      return const ['лук', 'морковь', 'чеснок'];
    case _StewDishKind.stroganoff:
      return const ['лук', 'грибы'];
    case _StewDishKind.none:
      break;
  }
  if (profile == DishProfile.soup) {
    switch (soupKind) {
      case _SoupKind.greenShchi:
        return const ['лук', 'морковь'];
      case _SoupKind.mushroom:
        return const ['лук', 'морковь'];
      case _SoupKind.peaSmoked:
        return const ['лук', 'морковь'];
      case _SoupKind.shchi:
      case _SoupKind.borscht:
      case _SoupKind.ukha:
      case _SoupKind.rassolnik:
        return const ['лук', 'морковь'];
      case _SoupKind.solyanka:
        return const ['лук'];
      case _SoupKind.none:
        break;
    }
  }
  if (grainDishKind == _GrainDishKind.buckwheatRustic) {
    return const ['лук', 'морковь'];
  }
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
  final friedDishKind = _detectFriedDishKind(profile, ingredientCanonicals);
  final grainDishKind = _detectGrainDishKind(profile, ingredientCanonicals);
  final soupKind = _detectSoupKind(ingredientCanonicals);
  final stewDishKind = _detectStewDishKind(profile, ingredientCanonicals);
  if (_isMorsDish(ingredientCanonicals)) {
    return const ['сахар', 'лимон'];
  }
  if (_isSauerkrautPreserveDish(ingredientCanonicals)) {
    return const ['соль'];
  }
  if (_isLightlySaltedCucumberDish(ingredientCanonicals)) {
    return const ['соль', 'укроп', 'чеснок'];
  }
  if (_isCharlotteDish(ingredientCanonicals)) {
    return const ['сахар', 'корица', 'соль'];
  }
  if (_isLiverCakeDish(ingredientCanonicals)) {
    return const ['соль', 'перец', 'укроп'];
  }
  if (_isSvekolnikDish(ingredientCanonicals)) {
    return const ['соль', 'перец', 'укроп', 'сметана'];
  }
  if (_isColdSoupDish(ingredientCanonicals)) {
    return const ['соль', 'перец', 'укроп', 'зелень'];
  }
  switch (stewDishKind) {
    case _StewDishKind.stewedCabbage:
      return const ['соль', 'перец', 'лавровый лист', 'томатная паста'];
    case _StewDishKind.lazyCabbageRolls:
      return const ['соль', 'перец', 'томатная паста', 'лавровый лист'];
    case _StewDishKind.tefteli:
      return const ['соль', 'перец', 'томатная паста', 'лавровый лист'];
    case _StewDishKind.zrazy:
      return const ['соль', 'перец', 'чеснок'];
    case _StewDishKind.homeCutlets:
      return const ['соль', 'перец', 'чеснок'];
    case _StewDishKind.zharkoe:
      return const ['соль', 'перец', 'лавровый лист', 'чеснок', 'паприка'];
    case _StewDishKind.goulash:
      return const [
        'соль',
        'перец',
        'паприка',
        'томатная паста',
        'лавровый лист'
      ];
    case _StewDishKind.stroganoff:
      return const ['соль', 'перец', 'горчица'];
    case _StewDishKind.none:
      break;
  }
  if (profile == DishProfile.soup) {
    switch (soupKind) {
      case _SoupKind.greenShchi:
        return const ['соль', 'перец', 'лавровый лист', 'укроп'];
      case _SoupKind.mushroom:
        return const ['соль', 'перец', 'лавровый лист', 'укроп'];
      case _SoupKind.peaSmoked:
        return const ['соль', 'перец', 'лавровый лист', 'укроп'];
      case _SoupKind.shchi:
        return const ['соль', 'перец', 'лавровый лист', 'укроп'];
      case _SoupKind.borscht:
        return const [
          'соль',
          'перец',
          'лавровый лист',
          'укроп',
          'томатная паста',
        ];
      case _SoupKind.ukha:
        return const ['соль', 'перец', 'лавровый лист', 'укроп', 'лимон'];
      case _SoupKind.rassolnik:
        return const ['соль', 'перец', 'лавровый лист'];
      case _SoupKind.solyanka:
        return const [
          'соль',
          'перец',
          'лавровый лист',
          'томатная паста',
          'лимон',
        ];
      case _SoupKind.none:
        break;
    }
  }
  if (grainDishKind == _GrainDishKind.buckwheatRustic) {
    return const ['соль', 'перец', 'укроп'];
  }
  switch (friedDishKind) {
    case _FriedDishKind.blini:
    case _FriedDishKind.oladyi:
      return const ['соль', 'сахар'];
    case _FriedDishKind.syrniki:
      return const ['сахар', 'корица', 'соль'];
    case _FriedDishKind.draniki:
      return const ['соль', 'перец'];
    case _FriedDishKind.none:
      break;
  }
  if (profile == DishProfile.breakfast &&
      _isSweetBreakfast(ingredientCanonicals)) {
    return const ['сахар', 'корица', 'соль'];
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
  final friedDishKind = _detectFriedDishKind(profile, ingredientCanonicals);
  final grainDishKind = _detectGrainDishKind(profile, ingredientCanonicals);
  final soupKind = _detectSoupKind(ingredientCanonicals);
  final stewDishKind = _detectStewDishKind(profile, ingredientCanonicals);
  if (_isMorsDish(ingredientCanonicals)) {
    return const ['лимон'];
  }
  if (_isSauerkrautPreserveDish(ingredientCanonicals) ||
      _isLightlySaltedCucumberDish(ingredientCanonicals)) {
    return const [];
  }
  if (_isCharlotteDish(ingredientCanonicals)) {
    return const ['масло сливочное', 'корица', 'сахар'];
  }
  if (_isLiverCakeDish(ingredientCanonicals)) {
    return const ['майонез', 'сметана', 'укроп'];
  }
  if (_isSvekolnikDish(ingredientCanonicals)) {
    return const ['сметана', 'укроп'];
  }
  if (_isColdSoupDish(ingredientCanonicals)) {
    return const ['укроп', 'зелень', 'сметана'];
  }
  switch (stewDishKind) {
    case _StewDishKind.stewedCabbage:
      return const ['укроп', 'сметана'];
    case _StewDishKind.lazyCabbageRolls:
      return const ['сметана', 'укроп'];
    case _StewDishKind.tefteli:
      return const ['сметана', 'укроп'];
    case _StewDishKind.zrazy:
      return const ['сметана', 'масло'];
    case _StewDishKind.homeCutlets:
      return const ['сметана', 'масло'];
    case _StewDishKind.zharkoe:
      return const ['сметана', 'укроп', 'чеснок'];
    case _StewDishKind.goulash:
      return const ['сметана', 'укроп'];
    case _StewDishKind.stroganoff:
      return const ['сметана', 'горчица'];
    case _StewDishKind.none:
      break;
  }
  if (profile == DishProfile.soup) {
    switch (soupKind) {
      case _SoupKind.greenShchi:
        return const ['сметана', 'укроп'];
      case _SoupKind.mushroom:
        return const ['сметана', 'укроп'];
      case _SoupKind.peaSmoked:
        return const ['сметана', 'укроп'];
      case _SoupKind.shchi:
      case _SoupKind.borscht:
        return const ['сметана', 'укроп'];
      case _SoupKind.ukha:
        return const ['лимон', 'укроп'];
      case _SoupKind.rassolnik:
        return const ['сметана'];
      case _SoupKind.solyanka:
        return const ['сметана', 'лимон', 'оливки'];
      case _SoupKind.none:
        break;
    }
  }
  if (grainDishKind == _GrainDishKind.buckwheatRustic) {
    return const ['сметана', 'укроп', 'масло сливочное'];
  }
  switch (friedDishKind) {
    case _FriedDishKind.blini:
    case _FriedDishKind.oladyi:
    case _FriedDishKind.syrniki:
      return const ['масло сливочное', 'сметана'];
    case _FriedDishKind.draniki:
      return const ['сметана'];
    case _FriedDishKind.none:
      break;
  }
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
  'печень',
  'тунец',
  'яйцо',
  'фасоль',
  'чечевица',
  'сыр',
  'творог',
  'сосиски',
  'колбаса',
};

const Set<String> _sauerkrautAllowedCanonicals = {
  'капуста',
  'морковь',
  'соль',
  'вода',
};

const Set<String> _lightlySaltedCucumberAllowedCanonicals = {
  'огурец',
  'укроп',
  'чеснок',
  'соль',
  'вода',
};

const Set<String> _morsBerryCanonicals = {
  'клюква',
  'брусника',
  'смородина',
  'вишня',
  'малина',
  'черника',
  'облепиха',
};

const Set<String> _morsAllowedCanonicals = {
  'клюква',
  'брусника',
  'смородина',
  'вишня',
  'малина',
  'черника',
  'облепиха',
  'сахар',
  'вода',
  'лимон',
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
  'перловка',
  'горох',
  'пшено',
  'манная крупа',
  'овсяные хлопья',
  'хлеб',
};

const Set<String> _vegetableCanonicals = {
  'помидор',
  'огурец',
  'лук',
  'морковь',
  'капуста',
  'свекла',
  'кабачок',
  'брокколи',
  'перец сладкий',
  'грибы',
  'горошек',
  'яблоко',
  'оливки',
};

const Set<String> _freshCanonicals = {
  'помидор',
  'огурец',
  'капуста',
  'горошек',
  'яблоко',
  'апельсин',
  'перец сладкий',
  'кукуруза',
  'клюква',
  'брусника',
  'смородина',
  'вишня',
  'малина',
  'черника',
  'облепиха',
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
  'квас',
};

const Set<String> _coldSoupBaseCanonicals = {
  'кефир',
  'квас',
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
  'квас',
  'апельсин',
  'томатная паста',
  'кетчуп',
  'яблоко',
  'клюква',
  'брусника',
  'смородина',
  'вишня',
  'малина',
  'черника',
  'облепиха',
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
  'пшено',
  'манная крупа',
  'овсяные хлопья',
};

const Set<String> _legumeCanonicals = {
  'горох',
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
  'свекла':
      _FlavorVector(sweetness: 0.30, acidity: 0.06, umami: 0.08, crunch: 0.08),
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
  'перловка': _FlavorVector(umami: 0.10, crunch: 0.06, sweetness: 0.02),
  'пшено': _FlavorVector(sweetness: 0.10, creaminess: 0.12, crunch: 0.04),
  'манная крупа': _FlavorVector(sweetness: 0.08, creaminess: 0.18),
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
  'колбаса': _FlavorVector(umami: 0.56, fat: 0.32),
  'печень': _FlavorVector(umami: 0.60, fat: 0.18, sweetness: 0.04),
  'фарш': _FlavorVector(umami: 0.58, fat: 0.26),
  'яйцо': _FlavorVector(umami: 0.42, fat: 0.26, creaminess: 0.18),
  'сыр': _FlavorVector(umami: 0.78, fat: 0.68, creaminess: 0.46, crunch: 0.04),
  'творог':
      _FlavorVector(umami: 0.26, fat: 0.24, acidity: 0.16, creaminess: 0.58),
  'молоко': _FlavorVector(fat: 0.26, sweetness: 0.16, creaminess: 0.30),
  'сметана': _FlavorVector(acidity: 0.22, fat: 0.56, creaminess: 0.74),
  'майонез': _FlavorVector(acidity: 0.12, fat: 0.86, creaminess: 0.80),
  'оливки':
      _FlavorVector(acidity: 0.08, umami: 0.20, fat: 0.18, freshness: 0.08),
  'йогурт': _FlavorVector(
      acidity: 0.24, fat: 0.18, freshness: 0.12, creaminess: 0.34),
  'кефир': _FlavorVector(
      acidity: 0.28, fat: 0.12, freshness: 0.16, creaminess: 0.28),
  'квас': _FlavorVector(
      acidity: 0.18, sweetness: 0.10, freshness: 0.20, umami: 0.02),
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
  'горох': _FlavorVector(
      umami: 0.22, sweetness: 0.06, creaminess: 0.14, freshness: 0.04),
  'горошек': _FlavorVector(sweetness: 0.18, freshness: 0.20, creaminess: 0.06),
  'кукуруза': _FlavorVector(sweetness: 0.24, freshness: 0.14, crunch: 0.14),
  'капуста': _FlavorVector(freshness: 0.30, sweetness: 0.08, crunch: 0.56),
  'кабачок': _FlavorVector(freshness: 0.20, sweetness: 0.06, crunch: 0.08),
  'яблоко': _FlavorVector(
      acidity: 0.24, sweetness: 0.46, freshness: 0.44, crunch: 0.28),
  'банан': _FlavorVector(sweetness: 0.62, freshness: 0.16, creaminess: 0.24),
  'апельсин': _FlavorVector(
      acidity: 0.30, sweetness: 0.42, freshness: 0.36, crunch: 0.06),
  'клюква': _FlavorVector(acidity: 0.62, sweetness: 0.10, freshness: 0.38),
  'брусника': _FlavorVector(acidity: 0.54, sweetness: 0.14, freshness: 0.34),
  'смородина': _FlavorVector(acidity: 0.48, sweetness: 0.18, freshness: 0.36),
  'вишня': _FlavorVector(acidity: 0.32, sweetness: 0.34, freshness: 0.28),
  'малина': _FlavorVector(acidity: 0.34, sweetness: 0.30, freshness: 0.34),
  'черника': _FlavorVector(acidity: 0.20, sweetness: 0.26, freshness: 0.24),
  'облепиха': _FlavorVector(acidity: 0.64, sweetness: 0.12, freshness: 0.36),
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
  final normalizedText = normalizeIngredientText(text);
  final normalizedKeyword = normalizeIngredientText(keyword);
  if (normalizedText.isEmpty || normalizedKeyword.isEmpty) {
    return false;
  }
  return normalizedText.contains(normalizedKeyword);
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
