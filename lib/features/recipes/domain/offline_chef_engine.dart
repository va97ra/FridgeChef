import '../../../core/utils/units.dart';
import '../../fridge/domain/fridge_item.dart';
import '../../fridge/domain/product_catalog_entry.dart';
import '../../shelf/domain/pantry_catalog_entry.dart';
import '../../shelf/domain/shelf_item.dart';
import 'chef_rules.dart';
import 'cook_filter.dart';
import 'ingredient_knowledge.dart';
import 'offline_chef_blueprints.dart';
import 'recipe.dart';
import 'recipe_ingredient.dart';
import 'recipe_ingredient_canonicalizer.dart';
import 'taste_profile.dart';

class OfflineChefRequest {
  final List<Recipe> baseRecipes;
  final List<FridgeItem> fridgeItems;
  final List<ShelfItem> shelfItems;
  final List<ProductCatalogEntry> productCatalog;
  final List<PantryCatalogEntry> pantryCatalog;
  final Set<CookFilter> filters;
  final TasteProfile tasteProfile;
  final int seed;

  const OfflineChefRequest({
    required this.baseRecipes,
    required this.fridgeItems,
    required this.shelfItems,
    required this.productCatalog,
    required this.pantryCatalog,
    this.filters = const {},
    this.tasteProfile = const TasteProfile.empty(),
    this.seed = 0,
  });
}

class GeneratedRecipeCandidate {
  final Recipe recipe;
  final List<String> anchorCanonicals;
  final List<String> implicitPantryStarters;
  final double priorityScore;
  final List<String> reasons;

  const GeneratedRecipeCandidate({
    required this.recipe,
    required this.anchorCanonicals,
    required this.implicitPantryStarters,
    required this.priorityScore,
    this.reasons = const [],
  });
}

class OfflineChefEngine {
  const OfflineChefEngine();

  List<GeneratedRecipeCandidate> generate(OfflineChefRequest request) {
    final inventory = _ChefInventory.build(
      fridgeItems: request.fridgeItems,
      shelfItems: request.shelfItems,
      productCatalog: request.productCatalog,
      pantryCatalog: request.pantryCatalog,
    );
    if (inventory.fridgeCanonicals.isEmpty) {
      return const [];
    }

    final knownIdentities = {
      for (final recipe in request.baseRecipes)
        _recipeIdentity(
          recipe,
          inventory.canonicalizer,
          ignoredCanonicals: inventory.pantryByCanonical.keys.toSet(),
        ),
    };
    final generated = <GeneratedRecipeCandidate>[];

    for (var index = 0; index < chefBlueprints.length; index++) {
      final candidate = _buildCandidate(
        blueprint: chefBlueprints[index],
        request: request,
        inventory: inventory,
        seedSalt: index,
      );
      if (candidate == null) {
        continue;
      }

      final identity = _recipeIdentity(
        candidate.recipe,
        inventory.canonicalizer,
        ignoredCanonicals: inventory.pantryByCanonical.keys.toSet(),
      );
      if (!knownIdentities.add(identity)) {
        continue;
      }
      generated.add(candidate);
    }

    generated.sort((a, b) {
      final byScore = b.priorityScore.compareTo(a.priorityScore);
      if (byScore != 0) {
        return byScore;
      }
      return a.recipe.title.compareTo(b.recipe.title);
    });
    return generated.take(6).toList();
  }

  GeneratedRecipeCandidate? _buildCandidate({
    required ChefBlueprint blueprint,
    required OfflineChefRequest request,
    required _ChefInventory inventory,
    required int seedSalt,
  }) {
    final selectedBySlot = <String, List<String>>{};
    final usedCanonicals = <String>{};

    for (var slotIndex = 0; slotIndex < blueprint.slots.length; slotIndex++) {
      final slot = blueprint.slots[slotIndex];
      final selected = _pickSlotItems(
        slot: slot,
        selectedBySlot: selectedBySlot,
        usedCanonicals: usedCanonicals,
        inventory: inventory,
        seed: request.seed + seedSalt + slotIndex,
      );
      if (selected.length < slot.minCount) {
        return null;
      }
      if (selected.isNotEmpty) {
        selectedBySlot[slot.key] = selected;
        usedCanonicals.addAll(selected);
      }
    }

    final anchorCanonicals = [
      ...selectedBySlot[blueprint.anchorSlot] ?? const <String>[],
      ...selectedBySlot[blueprint.secondaryAnchorSlot] ?? const <String>[],
    ];
    if (anchorCanonicals.isEmpty) {
      return null;
    }

    final starters = _resolveStarters(
      blueprint: blueprint,
      inventory: inventory,
      seed: request.seed + seedSalt,
    );
    final ingredients = _buildIngredients(
      blueprint: blueprint,
      selectedBySlot: selectedBySlot,
      starters: starters,
      inventory: inventory,
    );
    final recipe = Recipe(
      id: _buildRecipeId(blueprint.id, usedCanonicals, starters.includedCanonicals),
      title: _buildTitle(blueprint, selectedBySlot, inventory),
      description: blueprint.description,
      timeMin: blueprint.timeMin,
      tags: blueprint.tags,
      servingsBase: blueprint.servingsBase,
      ingredients: ingredients,
      steps: _buildSteps(
        blueprint: blueprint,
        selectedBySlot: selectedBySlot,
        starters: starters,
        inventory: inventory,
      ),
      source: RecipeSource.generatedDraft,
      anchorIngredients:
          anchorCanonicals.map(inventory.displayName).toList(growable: false),
      implicitPantryItems:
          starters.missingCanonicals.map(inventory.displayName).toList(),
      chefProfile: blueprint.profile.name,
    );

    if (!matchesCookFilters(recipe, request.filters)) {
      return null;
    }

    final recipeCanonicals = usedCanonicals.toSet()
      ..addAll(starters.includedCanonicals);
    if (!_passesPairingValidation(recipeCanonicals)) {
      return null;
    }

    final chefAssessment = assessChefRules(
      profile: blueprint.profile,
      recipeCanonicals: recipeCanonicals,
      matchedCanonicals: {
        ...usedCanonicals,
        ...starters.availableCanonicals,
      },
      supportCanonicals: {
        ...inventory.shelfSupportCanonicals,
        ...starters.supportCanonicals,
      },
      displayByCanonical: {
        ...inventory.displayByCanonical,
        for (final canonical in recipeCanonicals)
          canonical: inventory.displayName(canonical),
      },
      steps: recipe.steps,
    );
    if (chefAssessment.score < 0.45 || chefAssessment.flavorScore < 0.32) {
      return null;
    }

    final tasteAnalysis = request.tasteProfile.analyzeRecipe(
      recipe: recipe,
      canonicalizer: inventory.canonicalizer,
    );
    final anchorPriority = anchorCanonicals.isEmpty
        ? 0.0
        : anchorCanonicals
                .map((canonical) => inventory.priorityByCanonical[canonical] ?? 0.0)
                .fold<double>(0.0, (sum, value) => sum + value) /
            anchorCanonicals.length;
    final priorityScore = ((anchorPriority * 0.45) +
            (_pairScore(recipeCanonicals) * 0.25) +
            (chefAssessment.score * 0.20) +
            (tasteAnalysis.score * 0.10) -
            (starters.missingCanonicals.length * 0.08))
        .clamp(0.0, 1.0);

    return GeneratedRecipeCandidate(
      recipe: recipe,
      anchorCanonicals: anchorCanonicals,
      implicitPantryStarters: starters.missingCanonicals,
      priorityScore: priorityScore,
      reasons: _buildCandidateReasons(
        inventory: inventory,
        anchors: anchorCanonicals,
        starters: starters,
      ),
    );
  }

  List<String> _pickSlotItems({
    required ChefSlot slot,
    required Map<String, List<String>> selectedBySlot,
    required Set<String> usedCanonicals,
    required _ChefInventory inventory,
    required int seed,
  }) {
    final currentCanonicals = {
      for (final entry in selectedBySlot.values) ...entry,
    };
    final available = slot.candidates
        .where(inventory.hasAvailableCore)
        .where((canonical) => !usedCanonicals.contains(canonical))
        .toList();
    if (available.isEmpty) {
      return const [];
    }

    available.sort((a, b) {
      final aScore = _slotScore(
        canonical: a,
        slot: slot,
        currentCanonicals: currentCanonicals,
        inventory: inventory,
      );
      final bScore = _slotScore(
        canonical: b,
        slot: slot,
        currentCanonicals: currentCanonicals,
        inventory: inventory,
      );
      final byScore = bScore.compareTo(aScore);
      if (byScore != 0) {
        return byScore;
      }
      return a.compareTo(b);
    });

    final rotated = _rotate(available, seed);
    final maxAllowed = slot.maxCount < rotated.length ? slot.maxCount : rotated.length;
    if (maxAllowed < slot.minCount) {
      return rotated.take(maxAllowed).toList();
    }
    final extraCapacity = maxAllowed - slot.minCount;
    final targetCount =
        slot.minCount + (extraCapacity <= 0 ? 0 : (seed % (extraCapacity + 1)));
    return rotated.take(targetCount.clamp(slot.minCount, maxAllowed)).toList();
  }

  double _slotScore({
    required String canonical,
    required ChefSlot slot,
    required Set<String> currentCanonicals,
    required _ChefInventory inventory,
  }) {
    final priority = inventory.priorityByCanonical[canonical] ?? 0.0;
    if (slot.isAnchor) {
      return priority + (inventory.expiryByCanonical[canonical] ?? 0) * 0.12;
    }

    var synergy = 0.0;
    for (final selected in currentCanonicals) {
      if (forbiddenPairingsFor(canonical).contains(toPairingKey(selected)) ||
          forbiddenPairingsFor(selected).contains(toPairingKey(canonical))) {
        return -10;
      }
      if (pairedIngredientsFor(canonical).contains(toPairingKey(selected)) ||
          pairedIngredientsFor(selected).contains(toPairingKey(canonical))) {
        synergy += 0.35;
      }
      if (weaklyPairedIngredientsFor(canonical).contains(toPairingKey(selected)) ||
          weaklyPairedIngredientsFor(selected).contains(toPairingKey(canonical))) {
        synergy -= 0.15;
      }
    }
    return priority + synergy;
  }

  _ResolvedStarters _resolveStarters({
    required ChefBlueprint blueprint,
    required _ChefInventory inventory,
    required int seed,
  }) {
    final preferred = _rotate(blueprint.preferredStarters, seed);
    final included = <String>[];
    final missing = <String>[];
    final available = <String>[];
    final support = <String>{};

    for (final canonical in preferred) {
      if (inventory.hasShelfCanonical(canonical)) {
        included.add(canonical);
        available.add(canonical);
        support.addAll(inventory.supportCanonicalsFor(canonical));
        continue;
      }
      if (missing.length >= blueprint.maxImplicitPantryStarters ||
          !inventory.isPantryStarter(canonical)) {
        continue;
      }
      included.add(canonical);
      missing.add(canonical);
      support.addAll(inventory.supportCanonicalsFor(canonical));
    }

    return _ResolvedStarters(
      includedCanonicals: included,
      missingCanonicals: missing,
      availableCanonicals: available,
      supportCanonicals: support,
    );
  }

  bool _passesPairingValidation(Set<String> canonicals) {
    final pairKeys = canonicals.map(toPairingKey).toList()..sort();
    var strongPairs = 0;
    var weakPairs = 0;

    for (var i = 0; i < pairKeys.length; i++) {
      for (var j = i + 1; j < pairKeys.length; j++) {
        final a = pairKeys[i];
        final b = pairKeys[j];
        if (forbiddenPairingsFor(a).contains(b) ||
            forbiddenPairingsFor(b).contains(a)) {
          return false;
        }
        if (pairedIngredientsFor(a).contains(b) ||
            pairedIngredientsFor(b).contains(a)) {
          strongPairs++;
          continue;
        }
        if (weaklyPairedIngredientsFor(a).contains(b) ||
            weaklyPairedIngredientsFor(b).contains(a)) {
          weakPairs++;
        }
      }
    }

    if (pairKeys.length >= 3 && strongPairs == 0) {
      return false;
    }
    if (weakPairs > strongPairs + 1) {
      return false;
    }
    return true;
  }

  double _pairScore(Set<String> canonicals) {
    final pairKeys = canonicals.map(toPairingKey).toList()..sort();
    if (pairKeys.length < 2) {
      return 0.2;
    }

    var totalPairs = 0;
    var strongPairs = 0;
    for (var i = 0; i < pairKeys.length; i++) {
      for (var j = i + 1; j < pairKeys.length; j++) {
        totalPairs++;
        final a = pairKeys[i];
        final b = pairKeys[j];
        if (pairedIngredientsFor(a).contains(b) ||
            pairedIngredientsFor(b).contains(a)) {
          strongPairs++;
        }
      }
    }

    if (totalPairs == 0) {
      return 0.2;
    }
    return (strongPairs / totalPairs).clamp(0.0, 1.0);
  }

  List<RecipeIngredient> _buildIngredients({
    required ChefBlueprint blueprint,
    required Map<String, List<String>> selectedBySlot,
    required _ResolvedStarters starters,
    required _ChefInventory inventory,
  }) {
    final ingredients = <RecipeIngredient>[];
    for (final slot in blueprint.slots) {
      for (final canonical in selectedBySlot[slot.key] ?? const <String>[]) {
        ingredients.add(
          inventory.ingredient(
            canonical,
            amount: _defaultAmountFor(canonical),
            unit: _defaultUnitFor(canonical),
          ),
        );
      }
    }
    for (final canonical in starters.includedCanonicals) {
      ingredients.add(
        inventory.ingredient(
          canonical,
          amount: _supportAmountFor(canonical),
          unit: _supportUnitFor(canonical),
          required: false,
        ),
      );
    }
    return ingredients;
  }

  String _buildTitle(
    ChefBlueprint blueprint,
    Map<String, List<String>> selectedBySlot,
    _ChefInventory inventory,
  ) {
    final anchor = _displayList(
      selectedBySlot[blueprint.anchorSlot] ?? const <String>[],
      inventory,
      limit: 1,
    );
    final secondary = _displayList(
      selectedBySlot[blueprint.secondaryAnchorSlot] ?? const <String>[],
      inventory,
      limit: 2,
    );

    switch (blueprint.titleStyle) {
      case ChefTitleStyle.anchorWithSecondary:
        if (secondary.isEmpty) {
          return blueprint.titlePrefix;
        }
        return '${blueprint.titlePrefix} с $secondary';
      case ChefTitleStyle.anchorWithFocus:
        if (anchor.isEmpty) {
          return blueprint.titlePrefix;
        }
        if (secondary.isEmpty) {
          return '${blueprint.titlePrefix} с $anchor';
        }
        return '${blueprint.titlePrefix} с $anchor и $secondary';
      case ChefTitleStyle.inventoryLead:
        final focus = _displayList(
          [
            ...(selectedBySlot[blueprint.anchorSlot] ?? const <String>[]),
            ...(selectedBySlot[blueprint.secondaryAnchorSlot] ?? const <String>[]),
          ],
          inventory,
          limit: 3,
        );
        return focus.isEmpty
            ? blueprint.titlePrefix
            : '${blueprint.titlePrefix}: $focus';
    }
  }

  List<String> _buildSteps({
    required ChefBlueprint blueprint,
    required Map<String, List<String>> selectedBySlot,
    required _ResolvedStarters starters,
    required _ChefInventory inventory,
  }) {
    final anchor = _displayList(
      selectedBySlot[blueprint.anchorSlot] ?? const <String>[],
      inventory,
      limit: 2,
    );
    final secondary = _displayList(
      selectedBySlot[blueprint.secondaryAnchorSlot] ?? const <String>[],
      inventory,
      limit: 3,
    );
    final support = _displayList(
      selectedBySlot[blueprint.supportSlot] ?? const <String>[],
      inventory,
      limit: 2,
    );
    final startersText = _displayList(
      starters.includedCanonicals,
      inventory,
      limit: 3,
    );

    switch (blueprint.stepStyle) {
      case ChefStepStyle.eggSkillet:
        return [
          'Подготовь $secondary, прогрей сковороду и быстро обжарь добавки 3-4 минуты.',
          'Отдельно слегка взбей $anchor, затем влей на сковороду и аккуратно распределяй массу лопаткой.',
          startersText.isEmpty
              ? 'Готовь до мягкой текстуры и подавай сразу.'
              : 'В конце доведи вкус: $startersText, затем дай блюду минуту отдохнуть и подавай.',
        ];
      case ChefStepStyle.potatoSkillet:
        return [
          'Нарежь $anchor крупными кусочками и начни обжаривать до золотистой корочки.',
          'Добавь $secondary, убавь огонь и доведи всё вместе до мягкости.',
          startersText.isEmpty
              ? 'Подавай горячим, когда картофель станет румяным и собранным по вкусу.'
              : 'В конце аккуратно добавь $startersText, чтобы вкус стал глубже и цельнее.',
        ];
      case ChefStepStyle.freshSalad:
        return [
          'Подготовь и нарежь $anchor${secondary.isEmpty ? '' : ', $secondary'} удобными кусочками.',
          'Сложи всё в большую миску и аккуратно перемешай, чтобы текстуры остались разными.',
          startersText.isEmpty
              ? 'Подавай сразу, пока блюдо остаётся свежим.'
              : 'Перед подачей добавь $startersText, чтобы собрать вкус и аромат.',
        ];
      case ChefStepStyle.grainPan:
        return [
          'Подготовь основу: $anchor, а отдельно нарежь $secondary${support.isEmpty ? '' : ' и $support'}.',
          'Сначала прогрей добавки, затем вмешай основу и собери блюдо на умеренном огне.',
          startersText.isEmpty
              ? 'Доведи до готовности и подавай как сытное домашнее блюдо.'
              : 'В конце доведи вкус: $startersText, чтобы текстура и аромат стали собраннее.',
        ];
      case ChefStepStyle.pastaPan:
        return [
          'Отвари $anchor до состояния al dente и параллельно подготовь $secondary.',
          'Соедини основу с добавками на сковороде и быстро прогрей всё вместе.',
          startersText.isEmpty
              ? 'Оставь блюдо на минуту после выключения огня и подавай.'
              : 'Перед подачей добавь $startersText, чтобы вкус стал ярче и мягче одновременно.',
        ];
      case ChefStepStyle.soup:
        return [
          'Подготовь $anchor${secondary.isEmpty ? '' : ', $secondary'} и начни прогревать основу на спокойном огне.',
          'Добавь овощи${support.isEmpty ? '' : ' и $support'}, влей воду и вари до мягкости ингредиентов.',
          startersText.isEmpty
              ? 'Когда суп станет собранным по текстуре, сними с огня и дай ему постоять пару минут.'
              : 'В самом конце аккуратно добавь $startersText и дай супу настояться перед подачей.',
        ];
      case ChefStepStyle.bake:
        return [
          'Подготовь $anchor${secondary.isEmpty ? '' : ', $secondary'} и сложи всё в форму одним ровным слоем.',
          'Добавь связующие ингредиенты${support.isEmpty ? '' : ' и $support'}, чтобы блюдо держало форму и не пересохло.',
          startersText.isEmpty
              ? 'Запекай до румяной поверхности и дай блюду постоять 3-4 минуты перед подачей.'
              : 'Перед духовкой или в самом конце добавь $startersText, чтобы запекание дало более яркий аромат.',
        ];
      case ChefStepStyle.breakfast:
        return [
          'Собери основу: $anchor${secondary.isEmpty ? '' : ', $secondary'} и добейся приятной текстуры.',
          'Если нужно, слегка прогрей массу или оставь её свежей, чтобы сохранить мягкость блюда.',
          startersText.isEmpty
              ? 'Подавай сразу как спокойный домашний завтрак.'
              : 'Финально добавь $startersText, чтобы вкус стал завершённым.',
        ];
      case ChefStepStyle.stew:
        return [
          'Подготовь $anchor${secondary.isEmpty ? '' : ', $secondary'} и начни тушить самые плотные продукты на слабом огне.',
          'Добавь остальные ингредиенты${support.isEmpty ? '' : ' и $support'}, периодически помешивая, пока текстура не станет густой.',
          startersText.isEmpty
              ? 'Сними с огня, когда рагу станет мягким и собранным.'
              : 'В конце добавь $startersText и дай блюду пару минут постоять перед подачей.',
        ];
    }
  }

  String _displayList(
    List<String> canonicals,
    _ChefInventory inventory, {
    required int limit,
  }) {
    if (canonicals.isEmpty) {
      return '';
    }
    final values = canonicals.take(limit).map(inventory.displayName).toList();
    if (values.length == 1) {
      return values.first;
    }
    if (values.length == 2) {
      return '${values.first} и ${values.last}';
    }
    return '${values.take(values.length - 1).join(', ')} и ${values.last}';
  }

  List<String> _buildCandidateReasons({
    required _ChefInventory inventory,
    required List<String> anchors,
    required _ResolvedStarters starters,
  }) {
    final reasons = <String>[];
    if (anchors.isNotEmpty) {
      reasons.add(
        'шеф берёт в основу ${anchors.take(2).map(inventory.displayName).join(', ')}',
      );
    }
    if (starters.missingCanonicals.isNotEmpty) {
      reasons.add(
        'из базовых вещей пригодятся ${starters.missingCanonicals.map(inventory.displayName).join(', ')}',
      );
    }
    return reasons;
  }

  List<T> _rotate<T>(List<T> values, int seed) {
    if (values.length < 2) {
      return List<T>.from(values);
    }
    final offset = seed.abs() % values.length;
    return [
      ...values.skip(offset),
      ...values.take(offset),
    ];
  }
}

class _ResolvedStarters {
  final List<String> includedCanonicals;
  final List<String> missingCanonicals;
  final List<String> availableCanonicals;
  final Set<String> supportCanonicals;

  const _ResolvedStarters({
    required this.includedCanonicals,
    required this.missingCanonicals,
    required this.availableCanonicals,
    required this.supportCanonicals,
  });
}

class _ChefInventory {
  final RecipeIngredientCanonicalizer canonicalizer;
  final Set<String> fridgeCanonicals;
  final Set<String> shelfCanonicals;
  final Set<String> shelfSupportCanonicals;
  final Map<String, String> displayByCanonical;
  final Map<String, double> priorityByCanonical;
  final Map<String, int> expiryByCanonical;
  final Map<String, PantryCatalogEntry> pantryByCanonical;

  const _ChefInventory({
    required this.canonicalizer,
    required this.fridgeCanonicals,
    required this.shelfCanonicals,
    required this.shelfSupportCanonicals,
    required this.displayByCanonical,
    required this.priorityByCanonical,
    required this.expiryByCanonical,
    required this.pantryByCanonical,
  });

  factory _ChefInventory.build({
    required List<FridgeItem> fridgeItems,
    required List<ShelfItem> shelfItems,
    required List<ProductCatalogEntry> productCatalog,
    required List<PantryCatalogEntry> pantryCatalog,
  }) {
    final canonicalizer = RecipeIngredientCanonicalizer(productCatalog);
    final fridgeCanonicals = <String>{};
    final shelfCanonicals = <String>{};
    final shelfSupportCanonicals = <String>{};
    final displayByCanonical = <String, String>{};
    final expiryByCanonical = <String, int>{};
    final pantryByCanonical = <String, PantryCatalogEntry>{};

    for (final entry in pantryCatalog) {
      final canonical = toPairingKey(entry.canonicalName);
      if (canonical.isEmpty) {
        continue;
      }
      pantryByCanonical.putIfAbsent(canonical, () => entry);
      displayByCanonical.putIfAbsent(canonical, () => entry.name);
    }

    for (final item in fridgeItems) {
      if (item.amount <= 0) {
        continue;
      }
      final canonical = canonicalizer.canonicalize(item.name);
      if (canonical.isEmpty) {
        continue;
      }
      fridgeCanonicals.add(canonical);
      displayByCanonical.putIfAbsent(canonical, () => item.name.trim());

      final expiry = _expiryScore(item.expiresAt);
      final existing = expiryByCanonical[canonical];
      if (existing == null || expiry > existing) {
        expiryByCanonical[canonical] = expiry;
      }
    }

    for (final item in shelfItems) {
      if (!item.inStock) {
        continue;
      }
      final canonical = toPairingKey(
        item.canonicalName.trim().isNotEmpty ? item.canonicalName : item.name,
      );
      if (canonical.isEmpty) {
        continue;
      }
      shelfCanonicals.add(canonical);
      displayByCanonical.putIfAbsent(canonical, () => item.name.trim());
      shelfSupportCanonicals.add(canonical);
      for (final support in item.supportCanonicals) {
        final normalized = toPairingKey(support);
        if (normalized.isNotEmpty) {
          shelfSupportCanonicals.add(normalized);
        }
      }
    }

    final allAvailable = {...fridgeCanonicals, ...shelfCanonicals};
    final priorityByCanonical = <String, double>{};
    for (final canonical in fridgeCanonicals) {
      final expiryWeight = (expiryByCanonical[canonical] ?? 1) / 5;
      final pairWeight = countKnownPairings(canonical, allAvailable) / 6;
      priorityByCanonical[canonical] =
          ((expiryWeight * 0.65) + (pairWeight * 0.35)).clamp(0.0, 1.0);
    }

    return _ChefInventory(
      canonicalizer: canonicalizer,
      fridgeCanonicals: fridgeCanonicals,
      shelfCanonicals: shelfCanonicals,
      shelfSupportCanonicals: shelfSupportCanonicals,
      displayByCanonical: displayByCanonical,
      priorityByCanonical: priorityByCanonical,
      expiryByCanonical: expiryByCanonical,
      pantryByCanonical: pantryByCanonical,
    );
  }

  bool hasAvailableCore(String canonical) => fridgeCanonicals.contains(canonical);

  bool hasShelfCanonical(String canonical) => shelfCanonicals.contains(canonical);

  bool isPantryStarter(String canonical) =>
      pantryByCanonical[canonical]?.isStarter ?? false;

  String displayName(String canonical) =>
      displayByCanonical[canonical] ?? _capitalize(canonical);

  Set<String> supportCanonicalsFor(String canonical) {
    final pantryEntry = pantryByCanonical[canonical];
    if (pantryEntry == null) {
      return canonical.trim().isEmpty ? const {} : {canonical};
    }
    return {
      canonical,
      ...pantryEntry.supportCanonicals
          .map(toPairingKey)
          .where((value) => value.isNotEmpty),
    };
  }

  RecipeIngredient ingredient(
    String canonical, {
    required double amount,
    required Unit unit,
    bool required = true,
  }) {
    return RecipeIngredient(
      name: displayName(canonical),
      amount: amount,
      unit: unit,
      required: required,
    );
  }
}

int _expiryScore(DateTime? expiresAt) {
  if (expiresAt == null) {
    return 1;
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expiry = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
  final days = expiry.difference(today).inDays;
  if (days <= 1) {
    return 5;
  }
  if (days <= 3) {
    return 4;
  }
  if (days <= 7) {
    return 2;
  }
  return 1;
}

String _recipeIdentity(
  Recipe recipe,
  RecipeIngredientCanonicalizer canonicalizer, {
  Set<String> ignoredCanonicals = const {},
}) {
  final profile = recipe.chefProfile?.trim().toLowerCase();
  final ingredients = recipe.ingredients
      .where((ingredient) => ingredient.required)
      .map((ingredient) => canonicalizer.canonicalize(ingredient.name))
      .where(
        (value) => value.isNotEmpty && !ignoredCanonicals.contains(value),
      )
      .toSet()
      .toList()
    ..sort();
  return '${profile ?? inferDishProfile(title: recipe.title, tags: recipe.tags, ingredientCanonicals: ingredients).name}|${ingredients.join('|')}';
}

String _buildRecipeId(
  String blueprintId,
  Set<String> usedCanonicals,
  List<String> starters,
) {
  final parts = [...usedCanonicals, ...starters]..sort();
  return 'chef_${blueprintId}_${parts.join('_')}';
}

String _capitalize(String value) {
  if (value.isEmpty) {
    return 'Ингредиент';
  }
  return value[0].toUpperCase() + value.substring(1);
}

double _defaultAmountFor(String canonical) {
  switch (canonical) {
    case 'яйцо':
      return 3;
    case 'картофель':
      return 4;
    case 'лук':
    case 'морковь':
    case 'яблоко':
    case 'банан':
    case 'апельсин':
      return 1;
    case 'помидор':
    case 'огурец':
      return 2;
    case 'перец сладкий':
    case 'кабачок':
      return 1;
    case 'сосиски':
      return 2;
    case 'тунец':
    case 'кукуруза':
    case 'фасоль':
      return 1;
    case 'чеснок':
      return 2;
    case 'молоко':
    case 'йогурт':
      return 200;
    case 'овсяные хлопья':
    case 'рис':
    case 'гречка':
    case 'макароны':
    case 'чечевица':
    case 'кускус':
    case 'грибы':
    case 'сыр':
    case 'курица':
    case 'рыба':
    case 'брокколи':
    case 'творог':
    case 'сметана':
    case 'фарш':
    case 'томатная паста':
      return 180;
    default:
      return 1;
  }
}

double _supportAmountFor(String canonical) {
  switch (canonical) {
    case 'соль':
    case 'перец':
    case 'паприка':
    case 'корица':
    case 'орегано':
    case 'базилик':
    case 'лавровый лист':
      return 1;
    case 'чеснок':
      return 6;
    case 'масло':
    case 'оливковое масло':
      return 10;
    case 'масло сливочное':
      return 15;
    case 'сахар':
      return 10;
    case 'укроп':
      return 12;
    default:
      return _defaultAmountFor(canonical);
  }
}

Unit _defaultUnitFor(String canonical) {
  switch (canonical) {
    case 'яйцо':
    case 'картофель':
    case 'лук':
    case 'морковь':
    case 'помидор':
    case 'огурец':
    case 'перец сладкий':
    case 'кабачок':
    case 'сосиски':
    case 'тунец':
    case 'кукуруза':
    case 'фасоль':
    case 'яблоко':
    case 'банан':
    case 'апельсин':
    case 'чеснок':
      return Unit.pcs;
    case 'молоко':
    case 'йогурт':
      return Unit.ml;
    default:
      return Unit.g;
  }
}

Unit _supportUnitFor(String canonical) {
  switch (canonical) {
    case 'масло':
    case 'оливковое масло':
      return Unit.ml;
    default:
      return Unit.g;
  }
}
