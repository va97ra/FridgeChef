import '../../../core/utils/units.dart';
import '../../fridge/domain/fridge_item.dart';
import '../../fridge/domain/product_catalog_entry.dart';
import '../../shelf/domain/pantry_catalog_entry.dart';
import '../../shelf/domain/shelf_item.dart';
import 'chef_rules.dart';
import 'cook_filter.dart';
import 'ingredient_amount_converter.dart';
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
        request: request,
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

    final coreRecipeCanonicals = usedCanonicals.toSet();
    final supportPlan = buildChefSupportPlan(
      profile: blueprint.profile,
      ingredientCanonicals: coreRecipeCanonicals,
      supportCanonicals: inventory.availableSupportCanonicals,
    );
    final starters = _resolveStarters(
      blueprint: blueprint,
      inventory: inventory,
      supportPlan: supportPlan,
      seed: request.seed + seedSalt,
    );
    final chefSupport = _resolveChefSupport(
      inventory: inventory,
      supportPlan: supportPlan,
      usedCanonicals: usedCanonicals,
      starters: starters,
      seed: request.seed + seedSalt,
    );
    final ingredients = _buildIngredients(
      blueprint: blueprint,
      selectedBySlot: selectedBySlot,
      starters: starters,
      chefSupport: chefSupport,
      inventory: inventory,
    );
    final recipe = Recipe(
      id: _buildRecipeId(
          blueprint.id, usedCanonicals, starters.includedCanonicals),
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
        chefSupport: chefSupport,
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

    final recipeCanonicals = coreRecipeCanonicals.toSet()
      ..addAll(starters.includedCanonicals)
      ..addAll(chefSupport.explicitCanonicals);
    if (!_passesPairingValidation(coreRecipeCanonicals)) {
      return null;
    }

    final chefAssessment = assessChefRules(
      profile: blueprint.profile,
      recipeCanonicals: recipeCanonicals,
      matchedCanonicals: {
        ...usedCanonicals,
        ...starters.includedCanonicals,
        ...chefSupport.availableCanonicals,
      },
      supportCanonicals: {
        ...inventory.shelfSupportCanonicals,
        ...starters.supportCanonicals,
        for (final canonical in chefSupport.supportCanonicals)
          ...inventory.supportCanonicalsFor(canonical),
      },
      displayByCanonical: {
        ...inventory.displayByCanonical,
        for (final canonical in recipeCanonicals)
          canonical: inventory.displayName(canonical),
      },
      steps: recipe.steps,
    );
    final russianClassic = blueprint.tags.contains('russian_classic');
    final minimumChefScore = russianClassic ? 0.28 : 0.45;
    final minimumFlavorScore = russianClassic ? 0.18 : 0.32;
    if (chefAssessment.score < minimumChefScore ||
        chefAssessment.flavorScore < minimumFlavorScore) {
      return null;
    }

    final tasteAnalysis = request.tasteProfile.analyzeRecipe(
      recipe: recipe,
      canonicalizer: inventory.canonicalizer,
    );
    final anchorUrgency = anchorCanonicals.isEmpty
        ? 0.0
        : anchorCanonicals
                .map((canonical) =>
                    (inventory.expiryByCanonical[canonical] ?? 1) / 5)
                .fold<double>(0.0, (sum, value) => sum + value) /
            anchorCanonicals.length;
    final anchorPriority = anchorCanonicals.isEmpty
        ? 0.0
        : anchorCanonicals
                .map((canonical) =>
                    inventory.priorityByCanonical[canonical] ?? 0.0)
                .fold<double>(0.0, (sum, value) => sum + value) /
            anchorCanonicals.length;
    final stockConfidence = usedCanonicals.isEmpty
        ? 0.0
        : usedCanonicals
                .map(
                  (canonical) => inventory.availabilityRatioFor(
                    canonical: canonical,
                    targetAmount: _defaultAmountFor(canonical),
                    targetUnit: _defaultUnitFor(canonical),
                  ),
                )
                .fold<double>(0.0, (sum, value) => sum + value) /
            usedCanonicals.length;
    final supportCoverage = _supportCoverage(
      supportPlan: supportPlan,
      starters: starters,
      chefSupport: chefSupport,
    );
    final profileAffinity =
        request.tasteProfile.profilePreference(blueprint.profile);
    final profileFatigue =
        request.tasteProfile.profileFatigue(blueprint.profile);
    final tagAffinity =
        request.tasteProfile.averageTagPreference(blueprint.tags);
    final pairAffinity =
        request.tasteProfile.averagePairPreference(coreRecipeCanonicals);
    final repetitionPenalty = request.tasteProfile.recipeFatigue(
      recipe: recipe,
      canonicalizer: inventory.canonicalizer,
    );
    final russianCuisineBias = russianClassic ? 0.08 : 0.0;
    final priorityScore = ((anchorPriority * 0.30) +
            (anchorUrgency * 0.20) +
            (stockConfidence * 0.14) +
            ((_pairScore(coreRecipeCanonicals) * 0.12) +
                ((pairAffinity.clamp(-1.0, 1.0) + 1) * 0.04)) +
            (chefAssessment.score * 0.10) +
            (supportCoverage * 0.10) +
            russianCuisineBias +
            (((profileAffinity.clamp(-1.0, 1.0) + 1) * 0.05)) +
            (((tagAffinity.clamp(-1.0, 1.0) + 1) * 0.03)) +
            (tasteAnalysis.score * 0.06) -
            (profileFatigue * 0.14) -
            (repetitionPenalty * 0.20) -
            (starters.missingCanonicals.length * 0.12))
        .clamp(0.0, 1.0);

    final candidateReasons = _buildCandidateReasons(
      inventory: inventory,
      anchors: anchorCanonicals,
      starters: starters,
      chefSupport: chefSupport,
      tasteAnalysis: tasteAnalysis,
      repetitionPenalty: repetitionPenalty,
    );

    return GeneratedRecipeCandidate(
      recipe: recipe.copyWith(
        chefPriorityScore: priorityScore,
        chefNotes: candidateReasons,
      ),
      anchorCanonicals: anchorCanonicals,
      implicitPantryStarters: starters.missingCanonicals,
      priorityScore: priorityScore,
      reasons: candidateReasons,
    );
  }

  List<String> _pickSlotItems({
    required ChefSlot slot,
    required OfflineChefRequest request,
    required Map<String, List<String>> selectedBySlot,
    required Set<String> usedCanonicals,
    required _ChefInventory inventory,
    required int seed,
  }) {
    final currentCanonicals = {
      for (final entry in selectedBySlot.values) ...entry,
    };
    final available = slot.candidates
        .where(
          (canonical) => inventory.hasEnoughCore(
            canonical,
            targetAmount: _defaultAmountFor(canonical),
            targetUnit: _defaultUnitFor(canonical),
            minimumRatio: slot.isAnchor ? 0.78 : 0.60,
          ),
        )
        .where((canonical) => !usedCanonicals.contains(canonical))
        .toList();
    if (available.isEmpty) {
      return const [];
    }

    available.sort((a, b) {
      final aScore = _slotScore(
        canonical: a,
        slot: slot,
        request: request,
        currentCanonicals: currentCanonicals,
        inventory: inventory,
      );
      final bScore = _slotScore(
        canonical: b,
        slot: slot,
        request: request,
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
    final maxAllowed =
        slot.maxCount < rotated.length ? slot.maxCount : rotated.length;
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
    required OfflineChefRequest request,
    required Set<String> currentCanonicals,
    required _ChefInventory inventory,
  }) {
    final priority = inventory.priorityByCanonical[canonical] ?? 0.0;
    final stockConfidence = inventory.availabilityRatioFor(
      canonical: canonical,
      targetAmount: _defaultAmountFor(canonical),
      targetUnit: _defaultUnitFor(canonical),
    );
    final tasteWeight = request.tasteProfile.ingredientPreference(canonical);
    final ingredientFatigue = request.tasteProfile.ingredientFatigue(canonical);
    final pairPreference = currentCanonicals.isEmpty
        ? 0.0
        : currentCanonicals
                .map((selected) =>
                    request.tasteProfile.pairPreference(canonical, selected))
                .fold<double>(0.0, (sum, value) => sum + value) /
            currentCanonicals.length;
    final stockBonus = (stockConfidence * (slot.isAnchor ? 0.28 : 0.18))
        .clamp(0.0, slot.isAnchor ? 0.28 : 0.18);
    final tasteBonus =
        (tasteWeight * (slot.isAnchor ? 0.22 : 0.14)).clamp(-0.22, 0.22);
    final pairBonus =
        (pairPreference * (slot.isAnchor ? 0.12 : 0.18)).clamp(-0.18, 0.18);
    final fatiguePenalty = (ingredientFatigue * (slot.isAnchor ? 0.24 : 0.14))
        .clamp(0.0, slot.isAnchor ? 0.24 : 0.14);
    if (slot.isAnchor) {
      return priority +
          (inventory.expiryByCanonical[canonical] ?? 0) * 0.12 +
          stockBonus +
          tasteBonus +
          pairBonus -
          fatiguePenalty;
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
      if (weaklyPairedIngredientsFor(canonical)
              .contains(toPairingKey(selected)) ||
          weaklyPairedIngredientsFor(selected)
              .contains(toPairingKey(canonical))) {
        synergy -= 0.15;
      }
    }
    return priority +
        synergy +
        stockBonus +
        tasteBonus +
        pairBonus -
        fatiguePenalty;
  }

  _ResolvedStarters _resolveStarters({
    required ChefBlueprint blueprint,
    required _ChefInventory inventory,
    required ChefSupportPlan supportPlan,
    required int seed,
  }) {
    final preferred = _dedupeCanonicals([
      ...blueprint.preferredStarters,
      ...supportPlan.seasoningCanonicals,
      ...supportPlan.finishingCanonicals.where(inventory.isPantryStarter),
    ]);
    final included = <String>[];
    final missing = <String>[];
    final available = <String>[];
    final support = <String>{};

    for (final canonical in preferred) {
      if (_hasCanonicalOverlap(canonical, included)) {
        continue;
      }
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

  _ResolvedChefSupport _resolveChefSupport({
    required _ChefInventory inventory,
    required ChefSupportPlan supportPlan,
    required Set<String> usedCanonicals,
    required _ResolvedStarters starters,
    required int seed,
  }) {
    final reserved = <String>{
      ...usedCanonicals,
      ...starters.includedCanonicals,
    };
    final aromatics = _pickChefSupports(
      candidates: _rotate(supportPlan.aromaticCanonicals, seed),
      role: _ChefSupportRole.aromatic,
      inventory: inventory,
      reserved: reserved,
      limit: 2,
    );
    reserved.addAll(aromatics.map((item) => item.canonical));
    final seasonings = _pickChefSupports(
      candidates: _rotate(supportPlan.seasoningCanonicals, seed + 1),
      role: _ChefSupportRole.seasoning,
      inventory: inventory,
      reserved: reserved,
      limit: 2,
    );
    reserved.addAll(seasonings.map((item) => item.canonical));
    final finishes = _pickChefSupports(
      candidates: _rotate(supportPlan.finishingCanonicals, seed + 2),
      role: _ChefSupportRole.finish,
      inventory: inventory,
      reserved: reserved,
      limit: 1,
    );

    return _ResolvedChefSupport(
      aromatics: aromatics,
      seasonings: seasonings,
      finishes: finishes,
    );
  }

  List<_ChefSupportSelection> _pickChefSupports({
    required List<String> candidates,
    required _ChefSupportRole role,
    required _ChefInventory inventory,
    required Set<String> reserved,
    required int limit,
  }) {
    final picked = <_ChefSupportSelection>[];
    for (final canonical in candidates) {
      if (_hasCanonicalOverlap(canonical, reserved)) {
        continue;
      }
      if (!inventory.hasAvailableSupport(
        canonical: canonical,
        targetAmount: _supportTargetAmountFor(canonical, role),
        targetUnit: _supportTargetUnitFor(canonical, role),
        minimumRatio: _supportMinimumRatioFor(role),
      )) {
        continue;
      }
      picked.add(
        _ChefSupportSelection(
          canonical: canonical,
          role: role,
        ),
      );
      reserved.add(canonical);
      if (picked.length >= limit) {
        break;
      }
    }
    return picked;
  }

  double _supportCoverage({
    required ChefSupportPlan supportPlan,
    required _ResolvedStarters starters,
    required _ResolvedChefSupport chefSupport,
  }) {
    final desired = _dedupeCanonicals([
      ...supportPlan.aromaticCanonicals,
      ...supportPlan.seasoningCanonicals.take(2),
      ...supportPlan.finishingCanonicals.take(1),
    ]);
    if (desired.isEmpty) {
      return 0.55;
    }
    final resolved = {
      ...starters.includedCanonicals,
      ...chefSupport.explicitCanonicals,
    };
    final matched = desired.where(resolved.contains).length;
    return (0.25 + ((matched / desired.length) * 0.75)).clamp(0.0, 1.0);
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
    required _ResolvedChefSupport chefSupport,
    required _ChefInventory inventory,
  }) {
    final ingredients = <RecipeIngredient>[];
    for (final slot in blueprint.slots) {
      for (final canonical in selectedBySlot[slot.key] ?? const <String>[]) {
        final defaultAmount = _defaultAmountFor(canonical);
        final defaultUnit = _defaultUnitFor(canonical);
        ingredients.add(
          inventory.ingredient(
            canonical,
            amount: inventory.suggestedCoreAmount(
              canonical: canonical,
              targetAmount: defaultAmount,
              targetUnit: defaultUnit,
              minimumRatio: slot.isAnchor ? 0.78 : 0.60,
            ),
            unit: defaultUnit,
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
    for (final selection in chefSupport.all) {
      final targetAmount = _supportTargetAmountFor(
        selection.canonical,
        selection.role,
      );
      final targetUnit = _supportTargetUnitFor(
        selection.canonical,
        selection.role,
      );
      final amount = inventory.suggestedSupportAmount(
        canonical: selection.canonical,
        targetAmount: targetAmount,
        targetUnit: targetUnit,
        minimumRatio: _supportMinimumRatioFor(selection.role),
      );
      ingredients.add(
        inventory.ingredient(
          selection.canonical,
          amount: amount,
          unit: targetUnit,
          required: selection.role == _ChefSupportRole.aromatic,
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
        if (anchor.isEmpty && secondary.isEmpty) {
          return blueprint.titlePrefix;
        }
        final focus = [
          if (anchor.isNotEmpty) anchor,
          if (secondary.isNotEmpty) secondary
        ].join(', ');
        return '${blueprint.titlePrefix}: $focus';
      case ChefTitleStyle.anchorWithFocus:
        if (anchor.isEmpty && secondary.isEmpty) {
          return blueprint.titlePrefix;
        }
        final focus = [
          if (anchor.isNotEmpty) anchor,
          if (secondary.isNotEmpty) secondary
        ].join(', ');
        return '${blueprint.titlePrefix}: $focus';
      case ChefTitleStyle.inventoryLead:
        final focus = _displayList(
          [
            ...(selectedBySlot[blueprint.anchorSlot] ?? const <String>[]),
            ...(selectedBySlot[blueprint.secondaryAnchorSlot] ??
                const <String>[]),
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
    required _ResolvedChefSupport chefSupport,
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
    final aromaticsText = _displayList(
      chefSupport.aromaticCanonicals,
      inventory,
      limit: 2,
    );
    final finishText = _displayList(
      chefSupport.finishingCanonicals,
      inventory,
      limit: 2,
    );
    final seasoningText = _displayList(
      [
        ...starters.includedCanonicals,
        ...chefSupport.seasoningCanonicals,
      ],
      inventory,
      limit: 3,
    );

    switch (blueprint.stepStyle) {
      case ChefStepStyle.eggSkillet:
        return [
          'Подготовь $secondary${aromaticsText.isEmpty ? '' : ', а отдельно мелко нарежь $aromaticsText'}, прогрей сковороду и быстро дай добавкам схватиться за 3-4 минуты.',
          'Слегка взбей $anchor, затем влей массу и веди её лопаткой от краёв к центру, чтобы текстура осталась нежной.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Сними с огня, как только середина перестанет быть жидкой, и подавай сразу.'
              : 'В конце доведи вкус${seasoningText.isEmpty ? '' : ': $seasoningText'}${finishText.isEmpty ? '' : ', а перед подачей добавь $finishText'}, затем дай блюду минуту стабилизироваться и подавай.',
        ];
      case ChefStepStyle.potatoSkillet:
        return [
          'Нарежь $anchor крупными кусочками${aromaticsText.isEmpty ? '' : ', а $aromaticsText подготовь для ароматной базы'} и начни обжаривать, чтобы появилась уверенная золотистая корочка.',
          'Добавь $secondary, убавь огонь и доведи всё вместе до мягкости без лишней влаги.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Подавай горячим, когда картофель станет румяным и собранным по вкусу.'
              : 'В конце аккуратно добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши $finishText'}, чтобы вкус стал глубже и цельнее.',
        ];
      case ChefStepStyle.freshSalad:
        return [
          'Подготовь и нарежь $anchor${secondary.isEmpty ? '' : ', $secondary'}${aromaticsText.isEmpty ? '' : ', а $aromaticsText используй как ароматный штрих'} удобными кусочками.',
          'Сложи всё в большую миску и аккуратно перемешай, чтобы текстуры остались разными.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Подавай сразу, пока блюдо остаётся свежим.'
              : 'Перед подачей заправь салат${seasoningText.isEmpty ? '' : ' через $seasoningText'}${finishText.isEmpty ? '' : ' и собери всё через $finishText'}, чтобы вкус стал цельным и свежим.',
        ];
      case ChefStepStyle.grainPan:
        return [
          'Подготовь основу: $anchor, а отдельно нарежь $secondary${support.isEmpty ? '' : ' и $support'}${aromaticsText.isEmpty ? '' : ', плюс $aromaticsText для аромата'}.',
          'Сначала прогрей добавки, затем вмешай основу и собери блюдо на умеренном огне, чтобы крупа впитала вкус.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Доведи до готовности и подавай как сытное домашнее блюдо.'
              : 'В конце доведи вкус${seasoningText.isEmpty ? '' : ': $seasoningText'}${finishText.isEmpty ? '' : ', а для мягкого финиша добавь $finishText'}, чтобы текстура и аромат стали собраннее.',
        ];
      case ChefStepStyle.pastaPan:
        return [
          'Отвари $anchor до состояния al dente и параллельно подготовь $secondary${aromaticsText.isEmpty ? '' : ' вместе с $aromaticsText'}.',
          'Соедини основу с добавками на сковороде и быстро прогрей всё вместе, чтобы соус или соки покрыли пасту.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Оставь блюдо на минуту после выключения огня и подавай.'
              : 'Перед подачей добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши всё через $finishText'}, чтобы вкус стал ярче и мягче одновременно.',
        ];
      case ChefStepStyle.soup:
        return [
          'Подготовь $anchor${secondary.isEmpty ? '' : ', $secondary'}${aromaticsText.isEmpty ? '' : ' и сначала мягко прогрей $aromaticsText'} на спокойном огне.',
          'Добавь овощи${support.isEmpty ? '' : ' и $support'}, влей воду и вари до мягкости ингредиентов, не давая вкусу распасться.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Когда суп станет собранным по текстуре, сними с огня и дай ему постоять пару минут.'
              : 'В самом конце аккуратно добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши $finishText'}, затем дай супу настояться перед подачей.',
        ];
      case ChefStepStyle.bake:
        return [
          'Подготовь $anchor${secondary.isEmpty ? '' : ', $secondary'}${aromaticsText.isEmpty ? '' : ', а $aromaticsText вмешай для глубины вкуса'} и сложи всё в форму одним ровным слоем.',
          'Добавь связующие ингредиенты${support.isEmpty ? '' : ' и $support'}, чтобы блюдо держало форму и не пересохло в духовке.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Запекай до румяной поверхности и дай блюду постоять 3-4 минуты перед подачей.'
              : 'Перед духовкой или в самом конце добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши $finishText'}, чтобы запекание дало более яркий аромат.',
        ];
      case ChefStepStyle.breakfast:
        return [
          'Собери основу: $anchor${secondary.isEmpty ? '' : ', $secondary'}${aromaticsText.isEmpty ? '' : ', а $aromaticsText оставь как аккуратный ароматный акцент'} и добейся мягкой, ровной текстуры.',
          'Если нужно, слегка прогрей массу или оставь её свежей, чтобы сохранить лёгкость и нежность блюда.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Подавай сразу как спокойный домашний завтрак.'
              : 'Финально добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и доведи текстуру через $finishText'}, чтобы вкус стал завершённым.',
        ];
      case ChefStepStyle.syrniki:
        return [
          'Соедини $anchor${secondary.isEmpty ? '' : ' с $secondary'}${support.isEmpty ? '' : ', а для мягкого акцента добавь $support'}, затем аккуратно собери плотную творожную массу.',
          'Сформируй небольшие шайбы и обжарь их на умеренном огне до уверенной румяной корочки с двух сторон.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Дай сырникам минуту отдохнуть после сковороды и подавай тёплыми.'
              : 'Перед подачей добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши $finishText'}, чтобы сырники остались нежными внутри и собранными по вкусу.',
        ];
      case ChefStepStyle.draniki:
        return [
          'Натри $anchor${support.isEmpty ? '' : ', мелко нарежь $support'}${secondary.isEmpty ? '' : ' и вмешай $secondary'}, затем быстро собери плотную картофельную массу без лишней влаги.',
          'Выкладывай небольшие порции на сковороду и обжарь драники с двух сторон до уверенной золотистой корочки.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Дай драникам минуту стабилизироваться после сковороды и подавай горячими.'
              : 'В конце доведи вкус${seasoningText.isEmpty ? '' : ': $seasoningText'}${finishText.isEmpty ? '' : ' и подай со $finishText'}, чтобы драники остались хрустящими снаружи и мягкими внутри.',
        ];
      case ChefStepStyle.porridge:
        return [
          'Подготовь основу: $anchor${secondary.isEmpty ? '' : ', а рядом держи $secondary'}${support.isEmpty ? '' : ' и $support для мягкого финального акцента'}.',
          'Вари кашу на спокойном огне, постепенно вмешивая жидкую или сливочную часть, чтобы текстура стала ровной и мягкой.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Дай каше минуту под крышкой и подавай сразу, пока она остаётся нежной.'
              : 'В конце доведи вкус${seasoningText.isEmpty ? '' : ': $seasoningText'}${finishText.isEmpty ? '' : ', а перед подачей добавь $finishText'}, чтобы каша стала спокойной и собранной.',
        ];
      case ChefStepStyle.cutlets:
        return [
          'Соедини $anchor${support.isEmpty ? '' : ' с $support'}${secondary.isEmpty ? '' : ', а $secondary подготовь как домашний гарнир'}, затем собери плотную мясную массу.',
          'Сформируй котлеты и обжарь их до уверенной корочки, после чего доведи до готовности на более мягком огне.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Подавай котлеты горячими вместе с гарниром, когда соки внутри успеют стабилизироваться.'
              : 'Перед подачей добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши всё через $finishText'}, чтобы мясная часть и гарнир собрались в один домашний вкус.',
        ];
      case ChefStepStyle.stew:
        return [
          'Подготовь $anchor${secondary.isEmpty ? '' : ', $secondary'}${aromaticsText.isEmpty ? '' : ', а $aromaticsText прогрей в самом начале'} и начни тушить самые плотные продукты на слабом огне.',
          'Добавь остальные ингредиенты${support.isEmpty ? '' : ' и $support'}, периодически помешивая, пока текстура не станет густой и насыщенной.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Сними с огня, когда рагу станет мягким и собранным.'
              : 'В конце добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши $finishText'}, затем дай блюду пару минут постоять перед подачей.',
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
    required _ResolvedChefSupport chefSupport,
    required TasteProfileAnalysis tasteAnalysis,
    required double repetitionPenalty,
  }) {
    final reasons = <String>[];
    if (anchors.isNotEmpty) {
      reasons.add(
        'шеф берёт в основу ${anchors.take(2).map(inventory.displayName).join(', ')}',
      );
    }
    final urgentAnchors = anchors
        .where(
            (canonical) => (inventory.expiryByCanonical[canonical] ?? 0) >= 4)
        .toList();
    if (urgentAnchors.isNotEmpty) {
      reasons.add(
        'лучше пустить в дело сейчас: ${urgentAnchors.take(2).map(inventory.displayName).join(', ')}',
      );
    }
    final supportHighlights = _dedupeEquivalentCanonicals([
      ...starters.availableCanonicals,
      ...chefSupport.aromaticCanonicals,
      ...chefSupport.seasoningCanonicals,
      ...chefSupport.finishingCanonicals,
    ]);
    if (supportHighlights.isNotEmpty) {
      reasons.add(
        'вкус собирают ${supportHighlights.take(3).map(inventory.displayName).join(', ')}',
      );
    }
    if (starters.missingCanonicals.isNotEmpty) {
      reasons.add(
        'из базовых вещей пригодятся ${starters.missingCanonicals.map(inventory.displayName).join(', ')}',
      );
    }
    if (tasteAnalysis.reasons.isNotEmpty) {
      reasons.add(tasteAnalysis.reasons.first);
    }
    if (repetitionPenalty <= 0.12 && reasons.length < 3) {
      reasons.add('не зацикливается на том, что было у тебя совсем недавно');
    }
    return reasons.take(3).toList();
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

enum _ChefSupportRole { aromatic, seasoning, finish }

class _ChefSupportSelection {
  final String canonical;
  final _ChefSupportRole role;

  const _ChefSupportSelection({
    required this.canonical,
    required this.role,
  });
}

class _ResolvedChefSupport {
  final List<_ChefSupportSelection> aromatics;
  final List<_ChefSupportSelection> seasonings;
  final List<_ChefSupportSelection> finishes;

  const _ResolvedChefSupport({
    this.aromatics = const [],
    this.seasonings = const [],
    this.finishes = const [],
  });

  List<_ChefSupportSelection> get all => [
        ...aromatics,
        ...seasonings,
        ...finishes,
      ];

  List<String> get aromaticCanonicals =>
      aromatics.map((item) => item.canonical).toList(growable: false);

  List<String> get seasoningCanonicals =>
      seasonings.map((item) => item.canonical).toList(growable: false);

  List<String> get finishingCanonicals =>
      finishes.map((item) => item.canonical).toList(growable: false);

  Set<String> get explicitCanonicals => {
        ...aromaticCanonicals,
        ...seasoningCanonicals,
        ...finishingCanonicals,
      };

  Set<String> get availableCanonicals => explicitCanonicals;

  Set<String> get supportCanonicals => explicitCanonicals;
}

class _ChefInventory {
  final RecipeIngredientCanonicalizer canonicalizer;
  final Set<String> fridgeCanonicals;
  final Map<String, List<_StoredChefAmount>> fridgeByCanonical;
  final Set<String> shelfCanonicals;
  final Set<String> shelfSupportCanonicals;
  final Map<String, String> displayByCanonical;
  final Map<String, double> priorityByCanonical;
  final Map<String, int> expiryByCanonical;
  final Map<String, PantryCatalogEntry> pantryByCanonical;

  const _ChefInventory({
    required this.canonicalizer,
    required this.fridgeCanonicals,
    required this.fridgeByCanonical,
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
    final fridgeByCanonical = <String, List<_StoredChefAmount>>{};
    final shelfCanonicals = <String>{};
    final shelfSupportCanonicals = <String>{};
    final displayByCanonical = <String, String>{};
    final expiryByCanonical = <String, int>{};
    final pantryByCanonical = <String, PantryCatalogEntry>{};

    for (final entry in pantryCatalog) {
      final canonical = normalizeIngredientText(entry.canonicalName);
      final pairingCanonical = toPairingKey(entry.canonicalName);
      if (canonical.isEmpty) {
        continue;
      }
      pantryByCanonical.putIfAbsent(canonical, () => entry);
      displayByCanonical.putIfAbsent(canonical, () => entry.name);
      if (pairingCanonical.isNotEmpty) {
        pantryByCanonical.putIfAbsent(pairingCanonical, () => entry);
        displayByCanonical.putIfAbsent(pairingCanonical, () => entry.name);
      }
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
      fridgeByCanonical.putIfAbsent(canonical, () => []).add(
            _StoredChefAmount(
              amount: item.amount,
              unit: item.unit,
            ),
          );
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
      final rawCanonical =
          item.canonicalName.trim().isNotEmpty ? item.canonicalName : item.name;
      final canonical = toPairingKey(rawCanonical);
      final normalizedCanonical = normalizeIngredientText(rawCanonical);
      if (canonical.isEmpty && normalizedCanonical.isEmpty) {
        continue;
      }
      if (normalizedCanonical.isNotEmpty) {
        shelfCanonicals.add(normalizedCanonical);
        displayByCanonical.putIfAbsent(
          normalizedCanonical,
          () => item.name.trim(),
        );
        shelfSupportCanonicals.add(normalizedCanonical);
      }
      if (canonical.isNotEmpty) {
        shelfCanonicals.add(canonical);
        displayByCanonical.putIfAbsent(canonical, () => item.name.trim());
        shelfSupportCanonicals.add(canonical);
      }
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
      fridgeByCanonical: fridgeByCanonical,
      shelfCanonicals: shelfCanonicals,
      shelfSupportCanonicals: shelfSupportCanonicals,
      displayByCanonical: displayByCanonical,
      priorityByCanonical: priorityByCanonical,
      expiryByCanonical: expiryByCanonical,
      pantryByCanonical: pantryByCanonical,
    );
  }

  Set<String> get availableSupportCanonicals => {
        ...fridgeCanonicals,
        ...shelfCanonicals,
        ...shelfSupportCanonicals,
        ...pantryByCanonical.entries
            .where((entry) => entry.value.isStarter)
            .map((entry) => entry.key),
      };

  bool hasEnoughCore(
    String canonical, {
    required double targetAmount,
    required Unit targetUnit,
    required double minimumRatio,
  }) {
    return availabilityRatioFor(
          canonical: canonical,
          targetAmount: targetAmount,
          targetUnit: targetUnit,
        ) >=
        minimumRatio;
  }

  double availabilityRatioFor({
    required String canonical,
    required double targetAmount,
    required Unit targetUnit,
  }) {
    if (targetAmount <= 0) {
      return fridgeCanonicals.contains(canonical) ? 1.0 : 0.0;
    }
    final available = availableAmountFor(
      canonical: canonical,
      targetUnit: targetUnit,
    );
    return (available / targetAmount).clamp(0.0, 1.0);
  }

  double availableAmountFor({
    required String canonical,
    required Unit targetUnit,
  }) {
    var total = 0.0;
    for (final candidateKey in compatibleIngredientKeysForMatching(canonical)) {
      final entries = fridgeByCanonical[candidateKey];
      if (entries == null || entries.isEmpty) {
        continue;
      }
      for (final entry in entries) {
        final converted = convertIngredientAmount(
          canonical: candidateKey,
          amount: entry.amount,
          from: entry.unit,
          to: targetUnit,
        );
        if (converted != null) {
          total += converted;
        }
      }
    }
    return total;
  }

  bool hasShelfCanonical(String canonical) =>
      shelfCanonicals.contains(canonical);

  bool hasAvailableSupport({
    required String canonical,
    required double targetAmount,
    required Unit targetUnit,
    required double minimumRatio,
  }) {
    if (hasShelfCanonical(canonical)) {
      return true;
    }
    return availabilityRatioFor(
          canonical: canonical,
          targetAmount: targetAmount,
          targetUnit: targetUnit,
        ) >=
        minimumRatio;
  }

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

  double suggestedCoreAmount({
    required String canonical,
    required double targetAmount,
    required Unit targetUnit,
    required double minimumRatio,
  }) {
    final available = availableAmountFor(
      canonical: canonical,
      targetUnit: targetUnit,
    );
    final minimumAmount = targetAmount * minimumRatio;
    final bounded = available <= 0
        ? targetAmount
        : available < targetAmount
            ? available
            : targetAmount;
    final normalized = bounded < minimumAmount ? minimumAmount : bounded;
    return _normalizeRecipeAmount(normalized, targetUnit);
  }

  double suggestedSupportAmount({
    required String canonical,
    required double targetAmount,
    required Unit targetUnit,
    required double minimumRatio,
  }) {
    if (hasShelfCanonical(canonical)) {
      return _normalizeRecipeAmount(targetAmount, targetUnit);
    }
    return suggestedCoreAmount(
      canonical: canonical,
      targetAmount: targetAmount,
      targetUnit: targetUnit,
      minimumRatio: minimumRatio,
    );
  }
}

class _StoredChefAmount {
  final double amount;
  final Unit unit;

  const _StoredChefAmount({
    required this.amount,
    required this.unit,
  });
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
    case 'капуста':
      return 400;
    case 'лук':
    case 'морковь':
    case 'свекла':
    case 'яблоко':
    case 'банан':
    case 'апельсин':
    case 'лимон':
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
    case 'горошек':
      return 160;
    case 'оливки':
      return 90;
    case 'майонез':
      return 60;
    case 'чеснок':
      return 2;
    case 'молоко':
    case 'йогурт':
      return 200;
    case 'овсяные хлопья':
    case 'рис':
    case 'гречка':
    case 'перловка':
    case 'пшено':
    case 'макароны':
    case 'чечевица':
    case 'кускус':
    case 'мука':
      return 120;
    case 'манная крупа':
      return 70;
    case 'грибы':
    case 'сыр':
    case 'колбаса':
    case 'курица':
    case 'индейка':
    case 'говядина':
    case 'свинина':
    case 'печень':
    case 'рыба':
    case 'брокколи':
    case 'творог':
    case 'сметана':
    case 'фарш':
      return 180;
    case 'томатная паста':
      return 70;
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
    case 'майонез':
      return 45;
    case 'сметана':
    case 'йогурт':
      return 60;
    case 'томатная паста':
      return 40;
    case 'уксус':
      return 10;
    case 'укроп':
      return 12;
    case 'лимон':
      return 1;
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
    case 'свекла':
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
    case 'лимон':
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
    case 'лимон':
      return Unit.pcs;
    default:
      return Unit.g;
  }
}

double _supportTargetAmountFor(String canonical, _ChefSupportRole role) {
  switch (role) {
    case _ChefSupportRole.aromatic:
      switch (canonical) {
        case 'лук':
        case 'морковь':
        case 'перец сладкий':
        case 'лимон':
          return 1;
        case 'чеснок':
          return 1;
        default:
          return (_defaultAmountFor(canonical) * 0.6).clamp(1.0, 120.0);
      }
    case _ChefSupportRole.seasoning:
      return _supportAmountFor(canonical);
    case _ChefSupportRole.finish:
      switch (canonical) {
        case 'сыр':
          return 40;
        case 'сметана':
        case 'йогурт':
          return 60;
        case 'лимон':
          return 1;
        case 'укроп':
          return 10;
        default:
          return _supportAmountFor(canonical);
      }
  }
}

Unit _supportTargetUnitFor(String canonical, _ChefSupportRole role) {
  switch (role) {
    case _ChefSupportRole.aromatic:
      return _defaultUnitFor(canonical);
    case _ChefSupportRole.seasoning:
      return _supportUnitFor(canonical);
    case _ChefSupportRole.finish:
      switch (canonical) {
        case 'лимон':
          return Unit.pcs;
        case 'сыр':
        case 'сметана':
          return Unit.g;
        case 'йогурт':
          return Unit.ml;
        default:
          return _supportUnitFor(canonical);
      }
  }
}

double _supportMinimumRatioFor(_ChefSupportRole role) {
  switch (role) {
    case _ChefSupportRole.aromatic:
      return 0.5;
    case _ChefSupportRole.seasoning:
      return 0.6;
    case _ChefSupportRole.finish:
      return 0.55;
  }
}

List<String> _dedupeCanonicals(List<String> values) {
  final unique = <String>[];
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isEmpty || unique.contains(normalized)) {
      continue;
    }
    unique.add(normalized);
  }
  return unique;
}

List<String> _dedupeEquivalentCanonicals(List<String> values) {
  final unique = <String>[];
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isEmpty || _hasCanonicalOverlap(normalized, unique)) {
      continue;
    }
    unique.add(normalized);
  }
  return unique;
}

bool _hasCanonicalOverlap(String canonical, Iterable<String> existing) {
  final candidateVariants = _canonicalVariants(canonical);
  for (final value in existing) {
    if (candidateVariants.intersection(_canonicalVariants(value)).isNotEmpty) {
      return true;
    }
  }
  return false;
}

Set<String> _canonicalVariants(String canonical) {
  return {
    canonical,
    normalizeIngredientText(canonical),
    toPairingKey(canonical),
    ...compatibleIngredientKeysForMatching(canonical),
  }.where((value) => value.trim().isNotEmpty).toSet();
}

double _normalizeRecipeAmount(double amount, Unit unit) {
  switch (unit) {
    case Unit.pcs:
      if (amount <= 1) {
        return 1;
      }
      return amount.roundToDouble();
    case Unit.g:
    case Unit.ml:
      if (amount <= 20) {
        return amount.roundToDouble();
      }
      final step = amount < 120 ? 10.0 : 20.0;
      return ((amount / step).round() * step).toDouble();
    case Unit.kg:
    case Unit.l:
      return ((amount * 10).round() / 10).toDouble();
  }
}
