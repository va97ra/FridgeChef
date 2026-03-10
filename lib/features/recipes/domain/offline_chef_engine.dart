import '../../../core/utils/units.dart';
import '../../fridge/domain/fridge_item.dart';
import '../../fridge/domain/product_catalog_entry.dart';
import '../../shelf/domain/pantry_catalog_entry.dart';
import '../../shelf/domain/shelf_item.dart';
import 'chef_dish_validator.dart';
import 'chef_rules.dart';
import 'cook_filter.dart';
import 'ingredient_amount_converter.dart';
import 'ingredient_knowledge.dart';
import 'offline_chef_blueprints.dart';
import 'recipe.dart';
import 'recipe_ingredient.dart';
import 'recipe_ingredient_canonicalizer.dart';
import 'taste_profile.dart';

const _pairingNeutralCanonicals = {
  'соль',
  'перец',
  'сахар',
  'масло',
  'масло сливочное',
  'вода',
  'лавровый лист',
};

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

    final knownRecipeIdentities = {
      for (final recipe in request.baseRecipes)
        _recipeBroadIdentity(
          recipe,
          inventory.canonicalizer,
          ignoredCanonicals: inventory.pantryByCanonical.keys.toSet(),
        ),
    };
    final generated = <GeneratedRecipeCandidate>[];
    final generatedIdentities = <String>{};

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

      final broadIdentity = _recipeBroadIdentity(
        candidate.recipe,
        inventory.canonicalizer,
        ignoredCanonicals: inventory.pantryByCanonical.keys.toSet(),
      );
      if (knownRecipeIdentities.contains(broadIdentity)) {
        continue;
      }

      final identity = _recipeIdentity(
        candidate.recipe,
        inventory.canonicalizer,
        ignoredCanonicals: inventory.pantryByCanonical.keys.toSet(),
      );
      if (!generatedIdentities.add(identity)) {
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
    final pairingCanonicals = _pairingRelevantCanonicals(recipeCanonicals);
    if (!_passesPairingValidation(pairingCanonicals)) {
      return null;
    }
    final dishValidation = validateChefDish(
      blueprint: blueprint,
      recipe: recipe,
      recipeCanonicals: recipeCanonicals,
    );
    if (!dishValidation.isValid) {
      return null;
    }

    final chefAssessment = assessChefRules(
      profile: blueprint.profile,
      title: recipe.title,
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
            ((_pairScore(pairingCanonicals) * 0.12) +
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
      blueprint: blueprint,
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

  Set<String> _pairingRelevantCanonicals(Set<String> canonicals) {
    return canonicals
        .where((canonical) => !_pairingNeutralCanonicals.contains(canonical))
        .toSet();
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
    final anchorCanonicals =
        selectedBySlot[blueprint.anchorSlot] ?? const <String>[];
    final secondaryCanonicals =
        selectedBySlot[blueprint.secondaryAnchorSlot] ?? const <String>[];
    final supportCanonicals =
        selectedBySlot[blueprint.supportSlot] ?? const <String>[];
    final anchor = _displayList(
      anchorCanonicals,
      inventory,
      limit: 2,
    );
    final secondary = _displayList(
      secondaryCanonicals,
      inventory,
      limit: 3,
    );
    final support = _displayList(
      supportCanonicals,
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
    final panGreaseText = _displayList(
      [
        for (final canonical in starters.includedCanonicals)
          if (canonical == 'масло' || canonical == 'масло сливочное') canonical,
        for (final canonical in chefSupport.finishingCanonicals)
          if (canonical == 'масло' || canonical == 'масло сливочное') canonical,
      ],
      inventory,
      limit: 1,
    );
    final seasoningWithoutOilText = _displayList(
      [
        for (final canonical in [
          ...starters.includedCanonicals,
          ...chefSupport.seasoningCanonicals,
        ])
          if (canonical != 'масло' && canonical != 'масло сливочное') canonical,
      ],
      inventory,
      limit: 3,
    );

    switch (blueprint.stepStyle) {
      case ChefStepStyle.eggSkillet:
        return [
          'Подготовь $secondary${aromaticsText.isEmpty ? '' : ', а отдельно мелко нарежь $aromaticsText'}, прогрей сковороду и быстро дай добавкам схватиться за 3-4 минуты.',
          'Слегка взбей $anchor, затем влей массу и готовь её 2-3 минуты на умеренном огне, ведя лопаткой от краёв к центру, чтобы текстура осталась нежной.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Сними с огня, как только середина перестанет быть жидкой, и подавай сразу.'
              : 'В конце доведи вкус${seasoningText.isEmpty ? '' : ': $seasoningText'}${finishText.isEmpty ? '' : ', а перед подачей добавь $finishText'}, затем дай блюду 1 минуту стабилизироваться и подавай.',
        ];
      case ChefStepStyle.potatoSkillet:
        return [
          'Нарежь $anchor крупными кусочками${aromaticsText.isEmpty ? '' : ', а $aromaticsText подготовь для ароматной базы'} и обжаривай 12-14 минут, чтобы появилась уверенная золотистая корочка.',
          'Добавь $secondary, убавь огонь и доведи всё вместе ещё 6-8 минут до мягкости без лишней влаги.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Подавай горячим, когда картофель станет румяным и собранным по вкусу.'
              : 'В конце аккуратно добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши $finishText'}, чтобы вкус стал глубже и цельнее, затем дай блюду 1-2 минуты постоять.',
        ];
      case ChefStepStyle.freshSalad:
        return [
          'Подготовь и нарежь $anchor${secondary.isEmpty ? '' : ', $secondary'}${aromaticsText.isEmpty ? '' : ', а $aromaticsText используй как ароматный штрих'} удобными кусочками, отведя на нарезку 4-5 минут.',
          'Сложи всё в большую миску и аккуратно перемешивай около 1 минуты, чтобы текстуры остались разными.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Подавай сразу, пока блюдо остаётся свежим.'
              : 'Перед подачей заправь салат${seasoningText.isEmpty ? '' : ' через $seasoningText'}${finishText.isEmpty ? '' : ' и собери всё через $finishText'}, чтобы вкус стал цельным и свежим, затем дай ему 1 минуту собраться.',
        ];
      case ChefStepStyle.coldSoup:
        final coldBoiled = _displayList(
          secondaryCanonicals
              .where((canonical) =>
                  canonical == 'картофель' || canonical == 'яйцо')
              .toList(growable: false),
          inventory,
          limit: 2,
        );
        final coldFresh = _displayList(
          secondaryCanonicals
              .where((canonical) =>
                  canonical != 'картофель' && canonical != 'яйцо')
              .toList(growable: false),
          inventory,
          limit: 2,
        );
        final coldProtein = _displayList(
          selectedBySlot['protein'] ?? const <String>[],
          inventory,
          limit: 1,
        );
        return [
          'Отвари ${coldBoiled.isEmpty ? secondary : coldBoiled} 10-12 минут до готовности и полностью остуди 8-10 минут, чтобы холодная основа осталась чистой и собранной.',
          'Нарежь ${coldFresh.isEmpty ? secondary : coldFresh}${coldProtein.isEmpty ? '' : ', $coldProtein'}${support.isEmpty ? '' : ', а $support мелко поруби'} и сложи всё в большую миску.',
          'Влей $anchor, аккуратно доведи вкус${seasoningText.isEmpty ? '' : ' через $seasoningText'}${finishText.isEmpty ? '' : ', а перед подачей добавь $finishText'}, затем дай окрошке постоять в холоде 5-7 минут и подавай холодной.',
        ];
      case ChefStepStyle.grainPan:
        return [
          'Подготовь основу: $anchor, а отдельно нарежь $secondary${support.isEmpty ? '' : ' и $support'}${aromaticsText.isEmpty ? '' : ', плюс $aromaticsText для аромата'}. ${_grainCookTiming(anchorCanonicals)}',
          'Сначала прогрей добавки 4-5 минут, затем вмешай основу и собери блюдо на умеренном огне ещё 3-4 минуты, чтобы крупа впитала вкус.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Доведи до готовности и подавай как сытное домашнее блюдо.'
              : 'В конце доведи вкус${seasoningText.isEmpty ? '' : ': $seasoningText'}${finishText.isEmpty ? '' : ', а для мягкого финиша добавь $finishText'}, чтобы текстура и аромат стали собраннее, и дай блюду 1-2 минуты постоять.',
        ];
      case ChefStepStyle.pastaPan:
        return [
          'Отвари $anchor 8-10 минут до состояния al dente и параллельно подготовь $secondary${aromaticsText.isEmpty ? '' : ' вместе с $aromaticsText'}.',
          'Соедини основу с добавками на сковороде и быстро прогрей всё вместе 2-3 минуты, чтобы соус или соки покрыли пасту.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Оставь блюдо на минуту после выключения огня и подавай.'
              : 'Перед подачей добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши всё через $finishText'}, чтобы вкус стал ярче и мягче одновременно.',
        ];
      case ChefStepStyle.soup:
        final familySoupSteps = _buildStructuredSoupSteps(
          blueprint: blueprint,
          selectedBySlot: selectedBySlot,
          starters: starters,
          chefSupport: chefSupport,
          inventory: inventory,
          anchorCanonicals: anchorCanonicals,
          secondaryCanonicals: secondaryCanonicals,
          supportCanonicals: supportCanonicals,
          anchor: anchor,
          secondary: secondary,
          support: support,
          aromaticsText: aromaticsText,
          seasoningText: seasoningText,
          finishText: finishText,
        );
        if (familySoupSteps != null) {
          return familySoupSteps;
        }
        return [
          'Подготовь $anchor${secondary.isEmpty ? '' : ', $secondary'}${aromaticsText.isEmpty ? '' : ' и сначала мягко прогрей $aromaticsText 4-5 минут на спокойном огне'}.',
          _soupCookTiming(
            anchors: anchorCanonicals,
            secondary: secondaryCanonicals,
            support: supportCanonicals,
            supportText: support,
          ),
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Когда суп станет собранным по текстуре, сними с огня и дай ему постоять 3-4 минуты.'
              : 'В самом конце аккуратно добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши $finishText'}, затем дай супу настояться 3-4 минуты перед подачей.',
        ];
      case ChefStepStyle.bake:
        return [
          'Подготовь $anchor${secondary.isEmpty ? '' : ', $secondary'}${aromaticsText.isEmpty ? '' : ', а $aromaticsText вмешай для глубины вкуса'} и сложи всё в форму одним ровным слоем.',
          'Добавь связующие ингредиенты${support.isEmpty ? '' : ' и $support'}, чтобы блюдо держало форму и не пересохло в духовке, затем запекай ${_bakeCookTiming(anchorCanonicals)}.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Дай блюду постоять 3-4 минуты перед подачей, чтобы соки и текстура стабилизировались.'
              : 'Перед духовкой или в самом конце добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши $finishText'}, чтобы запекание дало более яркий аромат, а потом дай блюду 3-4 минуты отдохнуть.',
        ];
      case ChefStepStyle.breakfast:
        return [
          'Собери основу: $anchor${secondary.isEmpty ? '' : ', $secondary'}${aromaticsText.isEmpty ? '' : ', а $aromaticsText оставь как аккуратный ароматный акцент'} и добейся мягкой, ровной текстуры.',
          _breakfastCookTiming(anchorCanonicals),
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Подавай сразу как спокойный домашний завтрак.'
              : 'Финально добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и доведи текстуру через $finishText'}, чтобы вкус стал завершённым, затем дай блюду 1 минуту собраться.',
        ];
      case ChefStepStyle.panBatter:
        final addOns = _displayList(
          selectedBySlot['addons'] ?? const <String>[],
          inventory,
          limit: 2,
        );
        return [
          'Соедини $anchor, $secondary${support.isEmpty ? '' : ' и $support'}${addOns.isEmpty ? '' : ', добавь $addOns'} и размешай тесто 2-3 минуты до гладкости без комков.',
          'Дай тесту постоять 8-10 минут, затем разогрей${panGreaseText.isEmpty ? ' сухую' : ' слегка смазанную $panGreaseText'} сковороду и выпекай тонкие блины по 1-2 минуты с каждой стороны на умеренном огне.',
          seasoningWithoutOilText.isEmpty && finishText.isEmpty
              ? 'Складывай готовые блины стопкой и подавай сразу, пока они остаются мягкими.'
              : 'Перед первой партией доведи тесто${seasoningWithoutOilText.isEmpty ? '' : ' через $seasoningWithoutOilText'}${finishText.isEmpty ? '' : ', а готовые блины подай с $finishText'}, чтобы вкус остался ровным, а текстура мягкой.',
        ];
      case ChefStepStyle.fritterBatter:
        final fritterAddOns = _displayList(
          selectedBySlot['addons'] ?? const <String>[],
          inventory,
          limit: 2,
        );
        return [
          'Соедини $anchor, $secondary${support.isEmpty ? '' : ' и $support'}${fritterAddOns.isEmpty ? '' : ', добавь $fritterAddOns'} и размешай густое тесто 2-3 минуты, чтобы оно держало форму без комков.',
          'Дай тесту постоять 5-7 минут, затем выкладывай его ложкой небольшими порциями на${panGreaseText.isEmpty ? ' сухую' : ' слегка смазанную $panGreaseText'} сковороду и жарь оладьи по 2-3 минуты с каждой стороны.',
          seasoningWithoutOilText.isEmpty && finishText.isEmpty
              ? 'Подавай оладьи сразу, пока середина остаётся пышной, а края только успели схватиться.'
              : 'Перед подачей доведи вкус${seasoningWithoutOilText.isEmpty ? '' : ' через $seasoningWithoutOilText'}${finishText.isEmpty ? '' : ' и подай оладьи с $finishText'}, чтобы они остались мягкими внутри и не казались плоскими.',
        ];
      case ChefStepStyle.syrniki:
        return [
          'Соедини $anchor${secondary.isEmpty ? '' : ' с $secondary'}${support.isEmpty ? '' : ', а для мягкого акцента добавь $support'}, затем аккуратно собери плотную творожную массу без лишней влаги.',
          'Сформируй небольшие шайбы влажными руками и обжарь их на умеренно прогретой сковороде по 2-3 минуты с каждой стороны до уверенной румяной корочки.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Дай сырникам 1 минуту отдохнуть после сковороды и подавай тёплыми.'
              : 'Перед подачей добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши $finishText'}, чтобы сырники остались нежными внутри и собранными по вкусу.',
        ];
      case ChefStepStyle.draniki:
        return [
          'Натри $anchor${support.isEmpty ? '' : ', мелко нарежь $support'}${secondary.isEmpty ? '' : ' и вмешай $secondary'}, затем слегка отожми массу и быстро собери плотную картофельную основу без лишней влаги.',
          'Выкладывай небольшие порции на сковороду и обжарь драники по 3-4 минуты с каждой стороны до уверенной золотистой корочки.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Дай драникам 1 минуту стабилизироваться после сковороды и подавай горячими.'
              : 'В конце доведи вкус${seasoningText.isEmpty ? '' : ': $seasoningText'}${finishText.isEmpty ? '' : ' и подай со $finishText'}, чтобы драники остались хрустящими снаружи и мягкими внутри.',
        ];
      case ChefStepStyle.porridge:
        return [
          'Подготовь основу: $anchor${secondary.isEmpty ? '' : ', а рядом держи $secondary'}${support.isEmpty ? '' : ' и $support для мягкого финального акцента'}.',
          _porridgeCookTiming(anchorCanonicals),
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Дай каше 1-2 минуты под крышкой и подавай сразу, пока она остаётся нежной.'
              : 'В конце доведи вкус${seasoningText.isEmpty ? '' : ': $seasoningText'}${finishText.isEmpty ? '' : ', а перед подачей добавь $finishText'}, чтобы каша стала спокойной и собранной.',
        ];
      case ChefStepStyle.cutlets:
        final familyHomeCookingSteps = _buildStructuredHomeCookingSteps(
          blueprint: blueprint,
          selectedBySlot: selectedBySlot,
          starters: starters,
          chefSupport: chefSupport,
          inventory: inventory,
          anchorCanonicals: anchorCanonicals,
          secondaryCanonicals: secondaryCanonicals,
          supportCanonicals: supportCanonicals,
          anchor: anchor,
          secondary: secondary,
          support: support,
          aromaticsText: aromaticsText,
          seasoningText: seasoningText,
          finishText: finishText,
        );
        if (familyHomeCookingSteps != null) {
          return familyHomeCookingSteps;
        }
        return [
          'Соедини $anchor${support.isEmpty ? '' : ' с $support'}${secondary.isEmpty ? '' : ', а $secondary подготовь как домашний гарнир'}, затем собери плотную мясную массу.',
          'Сформируй котлеты и обжарь их по 4-5 минут с каждой стороны до уверенной корочки, после чего доведи до готовности ещё 6-8 минут на более мягком огне.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Подавай котлеты горячими вместе с гарниром, когда соки внутри успеют стабилизироваться за 1-2 минуты.'
              : 'Перед подачей добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши всё через $finishText'}, чтобы мясная часть и гарнир собрались в один домашний вкус.',
        ];
      // ─── MINIMALIST STEP GENERATORS ─────────────────────────────────────
      case ChefStepStyle.perfectOmelette:
        final omeletteFilling = secondary.isNotEmpty
            ? ', приготовь $secondary — обжарь или прогрей за 2-3 минуты и отложи, чтобы выложить внутрь'
            : '';
        final omeletteFinish =
            seasoningText.isNotEmpty ? ' и добавь $seasoningText' : '';
        return [
          'Разбей $anchor в миску, добавь щепотку соли$omeletteFinish, слегка взбей вилкой — не до пены, около 15-20 движений.'
              '${omeletteFilling.isNotEmpty ? ' $omeletteFilling.' : ''}',
          'Растопи кусочек сливочного масла на сковороде на среднем огне — масло должно пениться, но не темнеть. '
              'Влей яичную смесь и веди лопаткой по дну мелкими движениями непрерывно — 30-40 секунд.'
              '${secondary.isNotEmpty ? ' Выложи $secondary на одну половину.' : ''}',
          'Когда яйцо почти схватится, но середина ещё немного влажная, сверни омлет рулетом или пополам. '
              'Переверни на тарелку швом вниз. Подавай сразу — это блюдо не ждёт.'
              '${finishText.isNotEmpty ? ' При желании посыпь $finishText.' : ''}',
        ];

      case ChefStepStyle.butterEgg:
        final butterEggFinish =
            secondary.isNotEmpty ? ' Подавай с $secondary.' : '';
        return [
          'Растопи кусочек сливочного масла на сковороде на среднем огне. '
              'Дождись, пока масло начнёт пениться, но не станет коричневым — это момент.',
          'Разбей $anchor прямо в пенящееся масло. '
              'Немедленно убавь огонь до минимума и готовь 3-4 минуты, не трогая, '
              'пока белок станет непрозрачным, а желток — тёплым внутри, но текучим.'
              '${seasoningText.isNotEmpty ? ' Посоли и поперчи: $seasoningText.' : ' Посоли и поперчи по вкусу.'}',
          'Аккуратно сними со сковороды лопаткой.$butterEggFinish '
              'Хороший желток должен разливаться под хлебом — это и есть вкус.'
              '${finishText.isNotEmpty ? ' Финиш: $finishText.' : ''}',
        ];

      case ChefStepStyle.potatoPuree:
        final cream =
            secondary.isNotEmpty ? secondary : 'молоко и сливочное масло';
        return [
          'Очисти $anchor, нарежь равными кубиками 3-4 см — чтобы варились одинаково. '
              'Залей холодной подсоленной водой и вари 18-20 минут до полной мягкости.'
              '${seasoningText.isNotEmpty ? ' Подготовь $seasoningText.' : ''}',
          'Слей воду полностью. Верни кастрюлю на малый огонь на 30 секунд — '
              'лишняя влага уйдёт, и пюре получится плотнее. '
              'Разомни картофель толкушкой, пока горячий.',
          'Добавь $cream горячим (не холодным — иначе пюре станет клейким). '
              'Вмешивай круговыми движениями до шелковистой текстуры.'
              '${finishText.isNotEmpty ? ' Финиш: $finishText — это даст глубину и аромат.' : ' В конце посоли по вкусу.'}'
              ' Подавай сразу.',
        ];

      case ChefStepStyle.caramelizedOnion:
        final bread = secondary.isNotEmpty ? secondary : 'хлеб';
        return [
          'Нарежь $anchor тонкими полукольцами. '
              'Растопи кусочек сливочного масла на сковороде на среднем огне, '
              'добавь лук и перемешай. Убавь огонь до небольшого.'
              '${seasoningText.isNotEmpty ? ' Добавь $seasoningText.' : ''}',
          'Томи лук 18-20 минут, периодически помешивая — он должен постепенно темнеть '
              'и становиться янтарным, а не подгорать. '
              'На последних 2 минутах добавь щепотку сахара — это ускорит карамелизацию.'
              '${finishText.isNotEmpty ? ' Добавь $finishText для финального вкуса.' : ''}',
          'Поджарь $bread на сухой сковороде или в тостере. '
              'Выложи лук горкой сверху — он должен быть мягким и почти сладким. '
              'Ешь горячим, пока хлеб хрустит.',
        ];

      case ChefStepStyle.shakshuka:
        final sauce = anchor.isNotEmpty ? anchor : 'помидоры';
        final shakshukaEgg = secondary.isNotEmpty ? secondary : 'яйца';
        final extras = secondary.isNotEmpty &&
                (secondary.contains('лук') || secondary.contains('перец'))
            ? ', добавь $secondary и обжарь ещё 3 минуты'
            : '';
        return [
          'Разогрей масло на сковороде на среднем огне. '
              'Добавь паприку и чеснок, обжарь 30 секунд — до аромата, не до горечи. '
              'Добавь $sauce${extras.isNotEmpty ? extras : ''} и разомни лопаткой.'
              '${seasoningText.isNotEmpty ? ' Приправь: $seasoningText.' : ' Посоли.'}',
          'Туши соус 5-7 минут на среднем огне, пока он немного не загустеет. '
              'Сделай в соусе углубления ложкой и разбей в каждое по яйцу из $shakshukaEgg. '
              'Накрой крышкой.',
          'Готовь 4-5 минут — белок должен схватиться, желток остаться текучим. '
              'Снимай с огня до полной готовности желтка.'
              '${finishText.isNotEmpty ? ' Подавай с $finishText.' : ''} Ешь прямо из сковороды с хлебом.',
        ];

      case ChefStepStyle.breadEggSkillet:
        final bread = anchor.isNotEmpty ? anchor : 'хлеб';
        final egg = secondary.isNotEmpty ? secondary : 'яйцо';
        return [
          'Вырежи кружок диаметром 6-7 см в центре ломтя $bread '
              '(стаканом или ножом). Вырезанный кружок сохраняй — поджаришь отдельно.'
              '${seasoningText.isNotEmpty ? ' Приправь: $seasoningText.' : ''}',
          'Растопи кусочек сливочного масла на сковороде на среднем огне. '
              'Выложи хлеб и вырезанный кружок. Сразу разбей $egg прямо в отверстие.',
          'Готовь 2-3 минуты, пока белок схватится снизу. '
              'Перевёрни аккуратно и готовь ещё 1 минуту — желток должен остаться живым. '
              '${finishText.isNotEmpty ? 'Добавь $finishText. ' : ''}'
              'Подавай сразу, пока хлеб хрустит.',
        ];

      case ChefStepStyle.aglioEOlio:
        final pasta = anchor.isNotEmpty ? anchor : 'макароны';
        final garlic = secondary.isNotEmpty ? secondary : 'чеснок';
        return [
          'Вскипяти воду, посоли щедро. '
              'Вари $pasta по инструкции до al dente — сохрани 0.5 стакана воды от варки. '
              'Пока варится паста — тонко нарежь $garlic пластинками.'
              '${seasoningText.isNotEmpty ? ' Подготовь: $seasoningText.' : ''}',
          'На среднем огне прогрей масло со сковороды. '
              'Добавь чеснок и томи 2-3 минуты до золотистого — чуть янтарного, не коричневого. '
              'Это весь вкус блюда — не спеши.',
          'Переложи горячую пасту к чесноку прямо на сковороду. '
              'Добавь 3-4 ложки воды от варки и перемешивай интенсивно 1 минуту — '
              'соус загустеет и обволочёт каждую пасту.'
              '${finishText.isNotEmpty ? ' Финиш: $finishText.' : ''} Подавай немедленно.',
        ];

      case ChefStepStyle.cucumberSmetana:
        final dressing = secondary.isNotEmpty ? secondary : 'сметана';
        return [
          'Нарежь $anchor тонкими кружками или полукружками. '
              'Посоли и оставь на 5 минут — так огурец отдаст лишнюю воду.'
              '${seasoningText.isNotEmpty ? ' Приготовь: $seasoningText.' : ''}',
          'Слей лишнюю жидкость. '
              'Добавь $dressing и перемешай аккуратно.'
              '${finishText.isNotEmpty ? ' Добавь $finishText.' : ' Добавь укроп и чёрный перец — они здесь обязательны.'}',
          'Дай постоять 1-2 минуты и подавай. '
              'Это блюдо любит когда вкус самих огурцов слышен — '
              'не перебивай заправкой, только подчеркни.',
        ];

      case ChefStepStyle.potatoEggHash:
        final potato = anchor.isNotEmpty ? anchor : 'картофель';
        final egg = secondary.isNotEmpty ? secondary : 'яйца';
        final extras =
            support.isNotEmpty ? ', добавь $support и обжарь ещё 5 минут' : '';
        return [
          'Нарежь $potato кубиками 1.5 см — не мельчи, иначе не будет корочки. '
              'Прогрей масло на сковороде до горячего. '
              'Добавь картофель одним слоем и не трогай 4-5 минут.'
              '${seasoningText.isNotEmpty ? ' Приправь: $seasoningText.' : ' Посоли и добавь паприку.'}',
          'Переверни кубики и обжаривай ещё 6-7 минут${extras.isNotEmpty ? extras : ''}, '
              'пока со всех сторон не появится уверенная rumyянaya корочка.',
          'Сдвинь картофель к краям, разбей $egg в центр сковороды. '
              'Готовь яйца 3-4 минуты до желаемой степени — текучий желток или полностью. '
              '${finishText.isNotEmpty ? 'Добавь $finishText.' : ''} Подавай прямо со сковороды.',
        ];

      case ChefStepStyle.simpleRiceKasha:
        return [
          'Промой $anchor под холодной водой до чистой воды. '
              'Залей двойным объёмом воды, посоли.'
              '${seasoningText.isNotEmpty ? ' Добавь: $seasoningText.' : ''}',
          'Доведи до кипения на среднем огне, затем закрой крышкой и вари на минимуме '
              '18 минут. Не открывай крышку — пар нужен для правильной текстуры.',
          'Сними с огня, дай постоять под крышкой ещё 5 минут. '
              '${secondary.isNotEmpty ? 'Добавь $secondary.' : ''}'
              '${finishText.isNotEmpty ? ' Finиш: $finishText.' : ' Добавь кусочек масла и перемешай.'} Подавай горячим.',
        ];

      case ChefStepStyle.stew:
        final familyHomeCookingSteps = _buildStructuredHomeCookingSteps(
          blueprint: blueprint,
          selectedBySlot: selectedBySlot,
          starters: starters,
          chefSupport: chefSupport,
          inventory: inventory,
          anchorCanonicals: anchorCanonicals,
          secondaryCanonicals: secondaryCanonicals,
          supportCanonicals: supportCanonicals,
          anchor: anchor,
          secondary: secondary,
          support: support,
          aromaticsText: aromaticsText,
          seasoningText: seasoningText,
          finishText: finishText,
        );
        if (familyHomeCookingSteps != null) {
          return familyHomeCookingSteps;
        }
        return [
          'Подготовь $anchor${secondary.isEmpty ? '' : ', $secondary'}${aromaticsText.isEmpty ? '' : ', а $aromaticsText прогрей в самом начале 4-5 минут'} и начни тушить самые плотные продукты на слабом огне.',
          'Добавь остальные ингредиенты${support.isEmpty ? '' : ' и $support'}, периодически помешивая, и туши всё ещё ${_stewCookTiming(anchorCanonicals, secondaryCanonicals)}, пока текстура не станет густой и насыщенной.',
          seasoningText.isEmpty && finishText.isEmpty
              ? 'Сними с огня, когда рагу станет мягким и собранным.'
              : 'В конце добавь${seasoningText.isEmpty ? '' : ' $seasoningText'}${finishText.isEmpty ? '' : ' и заверши $finishText'}, затем дай блюду пару минут постоять перед подачей.',
        ];
    }
  }

  String _grainCookTiming(List<String> anchorCanonicals) {
    final anchor = _firstCanonical(anchorCanonicals);
    switch (anchor) {
      case 'рис':
        return 'Рис вари 14-16 минут под крышкой до мягкости, не переваривая.';
      case 'гречка':
        return 'Гречку вари 15-18 минут под крышкой, чтобы крупа осталась рассыпчатой.';
      case 'кускус':
        return 'Кускус залей кипятком и оставь под крышкой на 5 минут, затем распуши вилкой.';
      default:
        return 'Доведи основу до готовности за 10-15 минут, ориентируясь на мягкость зерна.';
    }
  }

  List<String>? _buildStructuredHomeCookingSteps({
    required ChefBlueprint blueprint,
    required Map<String, List<String>> selectedBySlot,
    required _ResolvedStarters starters,
    required _ResolvedChefSupport chefSupport,
    required _ChefInventory inventory,
    required List<String> anchorCanonicals,
    required List<String> secondaryCanonicals,
    required List<String> supportCanonicals,
    required String anchor,
    required String secondary,
    required String support,
    required String aromaticsText,
    required String seasoningText,
    required String finishText,
  }) {
    switch (blueprint.dishFamily) {
      case ChefDishFamily.lazyCabbageRollStew:
        final lazyVegetablesText = _sentenceIngredientText(
          _displayList(
            [
              for (final canonical in supportCanonicals)
                if (canonical == 'капуста' ||
                    canonical == 'лук' ||
                    canonical == 'морковь')
                  canonical,
            ],
            inventory,
            limit: 3,
          ),
        );
        final lazyTomatoText = _sentenceIngredientText(
          _displayList(
            [
              if (supportCanonicals.contains('томатная паста'))
                'томатная паста',
              if (starters.includedCanonicals.contains('томатная паста'))
                'томатная паста',
              if (chefSupport.seasoningCanonicals.contains('томатная паста'))
                'томатная паста',
            ],
            inventory,
            limit: 1,
          ),
        );
        final lazySeasoning = _sentenceIngredientText(seasoningText);
        final lazyFinish = _sentenceIngredientText(
          finishText.isNotEmpty
              ? finishText
              : _displayList(
                  [
                    for (final canonical in [
                      ...chefSupport.finishingCanonicals,
                      ...chefSupport.seasoningCanonicals,
                      ...starters.includedCanonicals,
                    ])
                      if (canonical == 'сметана' ||
                          canonical == 'лавровый лист')
                        canonical,
                  ],
                  inventory,
                  limit: 2,
                ),
        );
        final lazyAromatics = _sentenceIngredientText(
          aromaticsText.isNotEmpty
              ? aromaticsText
              : _displayList(
                  [
                    for (final canonical in supportCanonicals)
                      if (canonical == 'лук' || canonical == 'морковь')
                        canonical,
                  ],
                  inventory,
                  limit: 2,
                ),
        );
        return [
          'Подготовь ${lazyVegetablesText.isEmpty ? support : lazyVegetablesText}${lazyAromatics.isEmpty ? '' : ', а $lazyAromatics мягко прогрей 4-5 минут'}, затем соедини $anchor с $secondary${lazyVegetablesText.isEmpty ? '' : ' и $lazyVegetablesText'} в плотную основу для ленивых голубцов.',
          'Добавь${lazyTomatoText.isEmpty ? ' немного воды или бульона' : ' $lazyTomatoText'} и туши ленивые голубцы под крышкой 18-22 минуты на слабом огне, чтобы капуста смягчилась, а рис и мясо спокойно обменялись вкусом.',
          lazySeasoning.isEmpty && lazyFinish.isEmpty
              ? 'Дай блюду постоять 3-4 минуты и подавай горячим, когда томатная основа успеет собраться.'
              : 'В конце доведи вкус${lazySeasoning.isEmpty ? '' : ' через $lazySeasoning'}${lazyFinish.isEmpty ? '' : ', а подай со $lazyFinish'}, затем дай ленивым голубцам постоять 3-4 минуты.',
        ];
      case ChefDishFamily.tefteliSauceStew:
        final tefteliSauceBase = _sentenceIngredientText(
          _displayList(
            [
              for (final canonical in supportCanonicals)
                if (canonical == 'лук' || canonical == 'морковь') canonical,
            ],
            inventory,
            limit: 2,
          ),
        );
        final tefteliSauceText = _sentenceIngredientText(
          _displayList(
            [
              for (final canonical in [
                ...supportCanonicals,
                ...starters.includedCanonicals,
                ...chefSupport.seasoningCanonicals,
                ...chefSupport.finishingCanonicals,
              ])
                if (canonical == 'томатная паста' || canonical == 'сметана')
                  canonical,
            ],
            inventory,
            limit: 2,
          ),
        );
        final tefteliSeasoning = _sentenceIngredientText(seasoningText);
        final tefteliFinish = _sentenceIngredientText(
          finishText.isNotEmpty
              ? finishText
              : _displayList(
                  [
                    for (final canonical in [
                      ...chefSupport.finishingCanonicals,
                      ...chefSupport.seasoningCanonicals,
                      ...starters.includedCanonicals,
                    ])
                      if (canonical == 'сметана' ||
                          canonical == 'лавровый лист')
                        canonical,
                  ],
                  inventory,
                  limit: 2,
                ),
        );
        return [
          'Соедини $anchor с $secondary${tefteliSauceBase.isEmpty ? '' : ' и частью $tefteliSauceBase'}, затем сформируй небольшие тефтели влажными руками.',
          'Мягко прогрей ${tefteliSauceBase.isEmpty ? 'лук и морковь' : tefteliSauceBase} 4-5 минут${tefteliSauceText.isEmpty ? '' : ', вмешай $tefteliSauceText'}, после чего уложи тефтели в соус и туши их под крышкой 18-22 минуты на слабом огне, чтобы соус мягко обволакивал тефтели, а не оставался водянистым.',
          tefteliSeasoning.isEmpty && tefteliFinish.isEmpty
              ? 'Дай тефтелям постоять 2-3 минуты и подавай горячими, когда соус успеет собраться и мягко обволочь тефтели.'
              : 'В конце доведи соус${tefteliSeasoning.isEmpty ? '' : ' через $tefteliSeasoning'}${tefteliFinish.isEmpty ? '' : ' и заверши $tefteliFinish'}, затем дай тефтелям постоять 2-3 минуты, чтобы соус мягко обволакивал их.',
        ];
      case ChefDishFamily.homeCutletDinner:
        final sideCanonical = _firstCanonical(secondaryCanonicals);
        final cutletBaseText = anchorCanonicals.contains('фарш')
            ? 'фарш'
            : _sentenceIngredientText(anchor);
        final cutletAromatics = _sentenceIngredientText(
          aromaticsText.isNotEmpty
              ? aromaticsText
              : _displayList(
                  [
                    for (final canonical in supportCanonicals)
                      if (canonical == 'лук' || canonical == 'морковь')
                        canonical,
                  ],
                  inventory,
                  limit: 2,
                ),
        );
        final cutletSeasoning = _sentenceIngredientText(seasoningText);
        final cutletFinish = _sentenceIngredientText(
          finishText.isNotEmpty
              ? finishText
              : _displayList(
                  [
                    for (final canonical in [
                      ...chefSupport.finishingCanonicals,
                      ...chefSupport.seasoningCanonicals,
                      ...starters.includedCanonicals,
                    ])
                      if (canonical == 'сметана' || canonical == 'масло')
                        canonical,
                  ],
                  inventory,
                  limit: 2,
                ),
        );
        return [
          '${_homeCutletGarnishStep(sideCanonical, secondary)}${cutletAromatics.isEmpty ? '' : ' Одновременно мягко прогрей $cutletAromatics 4-5 минут, чтобы котлетная масса не вышла плоской.'}',
          'Соедини $cutletBaseText${support.isEmpty ? '' : ' с $support'} и собери плотную котлетную массу, затем сформируй котлеты и обжарь их по 4-5 минут с каждой стороны до уверенной корочки.',
          cutletSeasoning.isEmpty && cutletFinish.isEmpty
              ? 'Доведи котлеты до готовности ещё 6-8 минут на более мягком огне, дай им отдохнуть 1-2 минуты и подавай вместе с гарниром.'
              : 'Доведи котлеты до готовности ещё 6-8 минут на более мягком огне${cutletSeasoning.isEmpty ? '' : ', добавь $cutletSeasoning'}${cutletFinish.isEmpty ? '' : ' и подай с $cutletFinish'}, затем дай мясной части и гарниру собраться 1-2 минуты.',
        ];
      case ChefDishFamily.zrazyStuffedCutlets:
        final sideCanonical = _firstCanonical(secondaryCanonicals);
        final fillingCanonicals = selectedBySlot['filling'] ?? const <String>[];
        final zrazyVegCanonicals = selectedBySlot['veg'] ?? const <String>[];
        final zrazyFillingText = _sentenceIngredientText(
          _displayList(
            [...fillingCanonicals, ...zrazyVegCanonicals],
            inventory,
            limit: 3,
          ),
        );
        final zrazySeasoning = _sentenceIngredientText(seasoningText);
        final zrazyFinish = _sentenceIngredientText(
          finishText.isNotEmpty
              ? finishText
              : _displayList(
                  [
                    for (final canonical in [
                      ...chefSupport.finishingCanonicals,
                      ...chefSupport.seasoningCanonicals,
                      ...starters.includedCanonicals,
                    ])
                      if (canonical == 'сметана' || canonical == 'масло')
                        canonical,
                  ],
                  inventory,
                  limit: 2,
                ),
        );
        return [
          '${_homeCutletGarnishStep(sideCanonical, secondary)} ${_zrazyFillingPrepStep(
            fillingCanonicals: fillingCanonicals,
            vegCanonicals: zrazyVegCanonicals,
            inventory: inventory,
          )}',
          'Соедини фарш${aromaticsText.isEmpty ? '' : ' с $aromaticsText'} и собери плотную мясную массу, затем расплющи порции, уложи ${zrazyFillingText.isEmpty ? 'начинку' : zrazyFillingText} в центр, плотно закрой края и сформируй зразы.',
          zrazySeasoning.isEmpty && zrazyFinish.isEmpty
              ? 'Обжарь зразы по 4-5 минут с каждой стороны, доведи их ещё 6-8 минут на более мягком огне, дай 1-2 минуты отдохнуть и подавай вместе с гарниром.'
              : 'Обжарь зразы по 4-5 минут с каждой стороны, доведи их ещё 6-8 минут на более мягком огне${zrazySeasoning.isEmpty ? '' : ', добавь $zrazySeasoning'}${zrazyFinish.isEmpty ? '' : ' и подай с $zrazyFinish'}, затем дай начинке и мясной оболочке собраться 1-2 минуты.',
        ];
      case ChefDishFamily.bitochkiGravyCutlets:
        final sideCanonical = _firstCanonical(secondaryCanonicals);
        final bitochkiSauceBase = _sentenceIngredientText(
          _displayList(
            [
              ...(selectedBySlot['sauce'] ?? const <String>[]),
              for (final canonical in [
                ...starters.includedCanonicals,
                ...chefSupport.seasoningCanonicals,
                ...chefSupport.finishingCanonicals,
              ])
                if (canonical == 'сметана') canonical,
            ],
            inventory,
            limit: 3,
          ),
        );
        final bitochkiSeasoning = _sentenceIngredientText(seasoningText);
        final bitochkiFinish = _sentenceIngredientText(
          finishText.isNotEmpty
              ? finishText
              : _displayList(
                  [
                    for (final canonical in [
                      ...chefSupport.finishingCanonicals,
                      ...chefSupport.seasoningCanonicals,
                      ...starters.includedCanonicals,
                    ])
                      if (canonical == 'сметана' || canonical == 'масло')
                        canonical,
                  ],
                  inventory,
                  limit: 2,
                ),
        );
        return [
          '${_homeCutletGarnishStep(sideCanonical, secondary)} Одновременно мягко прогрей ${bitochkiSauceBase.isEmpty ? 'лук и морковь' : bitochkiSauceBase} 4-5 минут, чтобы подливка не вышла плоской.',
          'Соедини фарш${aromaticsText.isEmpty ? '' : ' с $aromaticsText'} и собери мягкую котлетную массу, затем сформируй круглые биточки и обжарь их по 3-4 минуты с каждой стороны, чтобы форма только схватилась.',
          bitochkiSeasoning.isEmpty && bitochkiFinish.isEmpty
              ? 'Верни биточки в подливку и держи их на мягком огне ещё 8-10 минут, пока она мягко не обволочёт мясо, затем подавай вместе с гарниром.'
              : 'Верни биточки в подливку и держи их на мягком огне ещё 8-10 минут${bitochkiSeasoning.isEmpty ? '' : ', добавь $bitochkiSeasoning'}${bitochkiFinish.isEmpty ? '' : ' и заверши $bitochkiFinish'}, пока подливка мягко не обволочёт мясо, затем подавай вместе с гарниром.',
        ];
      case ChefDishFamily.zharkoeStew:
        final zharkoeAromatics = _sentenceIngredientText(
          aromaticsText.isNotEmpty
              ? aromaticsText
              : _displayList(
                  [
                    for (final canonical in supportCanonicals)
                      if (canonical == 'лук' ||
                          canonical == 'морковь' ||
                          canonical == 'грибы')
                        canonical,
                  ],
                  inventory,
                  limit: 3,
                ),
        );
        final zharkoeSeasoning = _sentenceIngredientText(seasoningText);
        final zharkoeFinish = _sentenceIngredientText(
          finishText.isNotEmpty
              ? finishText
              : _displayList(
                  [
                    for (final canonical in [
                      ...chefSupport.finishingCanonicals,
                      ...chefSupport.seasoningCanonicals,
                      ...starters.includedCanonicals,
                    ])
                      if (canonical == 'сметана' ||
                          canonical == 'чеснок' ||
                          canonical == 'лавровый лист')
                        canonical,
                  ],
                  inventory,
                  limit: 2,
                ),
        );
        return [
          'Нарежь $anchor крупными кусками${support.isEmpty ? '' : ', подготовь $support'}${zharkoeAromatics.isEmpty ? '' : ', а $zharkoeAromatics прогрей 4-5 минут'}, после чего быстро обжарь $secondary ещё 5-6 минут, чтобы мясо взяло уверенный цвет.',
          'Верни картофельную основу${support.isEmpty ? '' : ' и $support'}, долей немного воды или бульона и туши жаркое под крышкой 22-26 минут, пока картофель не станет мягким, а соус не соберётся вокруг мяса.',
          zharkoeSeasoning.isEmpty && zharkoeFinish.isEmpty
              ? 'Сними жаркое с огня, дай ему постоять 3-4 минуты и подавай горячим.'
              : 'В конце доведи жаркое${zharkoeSeasoning.isEmpty ? '' : ' через $zharkoeSeasoning'}${zharkoeFinish.isEmpty ? '' : ' и заверши $zharkoeFinish'}, затем дай блюду постоять 3-4 минуты перед подачей.',
        ];
      case ChefDishFamily.goulashSauceStew:
        final goulashVegetables = _sentenceIngredientText(
          _displayList(
            [
              ...(selectedBySlot['aromatic'] ?? const <String>[]),
              ...(selectedBySlot['veg'] ?? const <String>[]),
            ],
            inventory,
            limit: 2,
          ),
        );
        final goulashSauceText = _sentenceIngredientText(
          _displayList(
            [
              ...(selectedBySlot['sauce'] ?? const <String>[]),
              for (final canonical in [
                ...starters.includedCanonicals,
                ...chefSupport.seasoningCanonicals,
              ])
                if (canonical == 'томатная паста' ||
                    canonical == 'паприка' ||
                    canonical == 'чеснок')
                  canonical,
            ],
            inventory,
            limit: 3,
          ),
        );
        final goulashSeasoning = _sentenceIngredientText(seasoningText);
        final goulashFinish = _sentenceIngredientText(
          finishText.isNotEmpty
              ? finishText
              : _displayList(
                  [
                    for (final canonical in [
                      ...chefSupport.finishingCanonicals,
                      ...chefSupport.seasoningCanonicals,
                      ...starters.includedCanonicals,
                    ])
                      if (canonical == 'лавровый лист' ||
                          canonical == 'сметана')
                        canonical,
                  ],
                  inventory,
                  limit: 2,
                ),
        );
        return [
          'Нарежь $anchor кусочками${goulashVegetables.isEmpty ? '' : ', а $goulashVegetables мягко прогрей 4-5 минут'}, затем обжарь мясо ещё 5-6 минут до уверенного цвета.',
          'Добавь${goulashSauceText.isEmpty ? ' паприку и немного воды или бульона' : ' $goulashSauceText'} и туши гуляш под крышкой 25-30 минут на спокойном огне, пока соус не станет гуще и глубже, а лишняя жидкость не выпарится.',
          goulashSeasoning.isEmpty && goulashFinish.isEmpty
              ? 'Сними гуляш с огня, дай ему постоять 3-4 минуты и подавай горячим.'
              : 'В конце доведи гуляш${goulashSeasoning.isEmpty ? '' : ' через $goulashSeasoning'}${goulashFinish.isEmpty ? '' : ' и заверши $goulashFinish'}, затем дай ему постоять 3-4 минуты.',
        ];
      case ChefDishFamily.stroganoffSauceStew:
        final stroganoffVegetables = _sentenceIngredientText(
          _displayList(
            [
              ...(selectedBySlot['aromatic'] ?? const <String>[]),
              ...(selectedBySlot['veg'] ?? const <String>[]),
            ],
            inventory,
            limit: 2,
          ),
        );
        final stroganoffSauceText = _sentenceIngredientText(
          _displayList(
            [
              ...(selectedBySlot['sauce'] ?? const <String>[]),
              for (final canonical in [
                ...starters.includedCanonicals,
                ...chefSupport.seasoningCanonicals,
                ...chefSupport.finishingCanonicals,
              ])
                if (canonical == 'сметана' ||
                    canonical == 'горчица' ||
                    canonical == 'мука')
                  canonical,
            ],
            inventory,
            limit: 3,
          ),
        );
        final stroganoffSeasoning = _sentenceIngredientText(seasoningText);
        final stroganoffFinish = _sentenceIngredientText(
          finishText.isNotEmpty
              ? finishText
              : _displayList(
                  [
                    for (final canonical in [
                      ...chefSupport.finishingCanonicals,
                      ...chefSupport.seasoningCanonicals,
                      ...starters.includedCanonicals,
                    ])
                      if (canonical == 'сметана' || canonical == 'горчица')
                        canonical,
                  ],
                  inventory,
                  limit: 2,
                ),
        );
        return [
          'Нарежь $anchor тонкими полосками${stroganoffVegetables.isEmpty ? '' : ', а $stroganoffVegetables подготовь отдельно для мягкой соусной базы'}.',
          'Быстро обжарь мясо 3-4 минуты, затем прогрей ${stroganoffVegetables.isEmpty ? 'лук' : stroganoffVegetables} 4-5 минут, добавь${stroganoffSauceText.isEmpty ? ' сметанный соус' : ' $stroganoffSauceText'} и держи бефстроганов на мягком огне ещё 5-7 минут, не давая соусу бурно кипеть, чтобы сметанный соус остался гладким.',
          stroganoffSeasoning.isEmpty && stroganoffFinish.isEmpty
              ? 'Сними бефстроганов с огня, дай ему 1-2 минуты собраться и подавай сразу, пока соус остаётся гладким.'
              : 'В конце доведи бефстроганов${stroganoffSeasoning.isEmpty ? '' : ' через $stroganoffSeasoning'}${stroganoffFinish.isEmpty ? '' : ' и заверши $stroganoffFinish'}, затем дай соусу спокойно собраться 1-2 минуты и остаться гладким.',
        ];
      case ChefDishFamily.eggSkillet:
      case ChefDishFamily.potatoSkillet:
      case ChefDishFamily.freshSalad:
      case ChefDishFamily.coldSoup:
      case ChefDishFamily.okroshkaColdSoup:
      case ChefDishFamily.okroshkaKvassColdSoup:
      case ChefDishFamily.olivierSalad:
      case ChefDishFamily.vinegretSalad:
      case ChefDishFamily.grainPan:
      case ChefDishFamily.pastaPan:
      case ChefDishFamily.navyPasta:
      case ChefDishFamily.soup:
      case ChefDishFamily.cabbageSoup:
      case ChefDishFamily.borschtSoup:
      case ChefDishFamily.fishSoup:
      case ChefDishFamily.pickleSoup:
      case ChefDishFamily.solyankaSoup:
      case ChefDishFamily.bake:
      case ChefDishFamily.curdBake:
      case ChefDishFamily.breakfast:
      case ChefDishFamily.panBatter:
      case ChefDishFamily.bliniPan:
      case ChefDishFamily.fritterBatter:
      case ChefDishFamily.oladyiFritter:
      case ChefDishFamily.curdFritter:
      case ChefDishFamily.potatoFritter:
      case ChefDishFamily.porridge:
      case ChefDishFamily.cutlets:
      case ChefDishFamily.stew:
      // Minimalist dish families — handled by their own ChefStepStyle generators
      case ChefDishFamily.perfectOmeletteSkillet:
      case ChefDishFamily.butterEggSkillet:
      case ChefDishFamily.potatoPureeSide:
      case ChefDishFamily.caramelizedOnionToast:
      case ChefDishFamily.shakshukaSkillet:
      case ChefDishFamily.breadEggSkillet:
      case ChefDishFamily.aglioEOlioPasta:
      case ChefDishFamily.cucumberSmetanaSalad:
      case ChefDishFamily.potatoEggHash:
      case ChefDishFamily.simpleRiceKasha:
        return null;
    }
  }

  String _homeCutletGarnishStep(String sideCanonical, String sideText) {
    switch (sideCanonical) {
      case 'гречка':
        return 'Промой $sideText и вари гарнир 15-18 минут под крышкой, чтобы гречка осталась рассыпчатой.';
      case 'рис':
        return 'Промой $sideText и вари гарнир 14-16 минут под крышкой, чтобы зёрна остались собранными.';
      case 'картофель':
        return 'Нарежь $sideText и доведи гарнир до мягкости за 15-18 минут, не разваривая его.';
      default:
        return 'Подготовь $sideText как спокойный домашний гарнир, чтобы он успел дойти к подаче котлет.';
    }
  }

  String _zrazyFillingPrepStep({
    required List<String> fillingCanonicals,
    required List<String> vegCanonicals,
    required _ChefInventory inventory,
  }) {
    final hasEgg = fillingCanonicals.contains('яйцо');
    final hasMushrooms = fillingCanonicals.contains('грибы');
    final hasOnion = vegCanonicals.contains('лук');
    if (hasEgg && hasMushrooms) {
      return 'Отвари яйца 8-9 минут, мелко наруби их${hasOnion ? ' с луком' : ''}, грибы прогрей 4-5 минут и собери плотную начинку для зраз.';
    }
    if (hasEgg) {
      return 'Отвари яйца 8-9 минут${hasOnion ? ', мелко наруби их с луком' : ' и мелко наруби'}, чтобы начинка для зраз осталась собранной.';
    }
    if (hasMushrooms) {
      return 'Мелко нарежь грибы${hasOnion ? ' и лук' : ''} и прогрей их 4-5 минут, чтобы начинка для зраз не дала лишнюю влагу.';
    }
    final fillingText = _sentenceIngredientText(
      _displayList([...fillingCanonicals, ...vegCanonicals], inventory,
          limit: 3),
    );
    return 'Подготовь ${fillingText.isEmpty ? 'начинку для зраз' : fillingText}, чтобы она оставалась собранной внутри мясной оболочки.';
  }

  List<String>? _buildStructuredSoupSteps({
    required ChefBlueprint blueprint,
    required Map<String, List<String>> selectedBySlot,
    required _ResolvedStarters starters,
    required _ResolvedChefSupport chefSupport,
    required _ChefInventory inventory,
    required List<String> anchorCanonicals,
    required List<String> secondaryCanonicals,
    required List<String> supportCanonicals,
    required String anchor,
    required String secondary,
    required String support,
    required String aromaticsText,
    required String seasoningText,
    required String finishText,
  }) {
    switch (blueprint.dishFamily) {
      case ChefDishFamily.cabbageSoup:
        final shchiHomeFinish = _sentenceIngredientText(
          finishText.isNotEmpty
              ? finishText
              : _displayList(
                  [
                    for (final canonical in [
                      ...chefSupport.finishingCanonicals,
                      ...chefSupport.seasoningCanonicals,
                      ...starters.includedCanonicals,
                    ])
                      if (canonical == 'сметана' ||
                          canonical == 'укроп' ||
                          canonical == 'лавровый лист')
                        canonical,
                  ],
                  inventory,
                  limit: 2,
                ),
        );
        final shchiSeasoning = _sentenceIngredientText(seasoningText);
        return [
          'Подготовь $anchor${support.isEmpty ? '' : ', $support'}${secondary.isEmpty ? '' : ', а $secondary держи для более сытной базы'}${aromaticsText.isEmpty ? '' : ', сначала мягко прогрей $aromaticsText 4-5 минут, чтобы щи не вышли плоскими'}.',
          'Влей воду, добавь капустную основу${secondary.isEmpty ? '' : ' и $secondary'}${support.isEmpty ? '' : ', затем вмешай $support'} и вари щи 18-22 минуты на спокойном огне, пока капуста и корнеплоды не станут мягкими.',
          shchiSeasoning.isEmpty && shchiHomeFinish.isEmpty
              ? 'Сними щи с огня, дай им постоять 3-4 минуты и подавай горячими.'
              : 'В конце аккуратно доведи вкус${shchiSeasoning.isEmpty ? '' : ' через $shchiSeasoning'}${shchiHomeFinish.isEmpty ? '' : ', а подай щи со $shchiHomeFinish'}, затем дай супу настояться 3-4 минуты.',
        ];
      case ChefDishFamily.borschtSoup:
        final borschtTomatoText = _sentenceIngredientText(
          _displayList(
            [
              ...(selectedBySlot['depth'] ?? const <String>[]),
              if (supportCanonicals.contains('томатная паста'))
                'томатная паста',
              if (starters.includedCanonicals.contains('томатная паста'))
                'томатная паста',
              if (chefSupport.seasoningCanonicals.contains('томатная паста'))
                'томатная паста',
            ],
            inventory,
            limit: 1,
          ),
        );
        final borschtHomeFinish = _sentenceIngredientText(
          finishText.isNotEmpty
              ? finishText
              : _displayList(
                  [
                    for (final canonical in [
                      ...chefSupport.finishingCanonicals,
                      ...chefSupport.seasoningCanonicals,
                      ...starters.includedCanonicals,
                    ])
                      if (canonical == 'сметана' || canonical == 'укроп')
                        canonical,
                  ],
                  inventory,
                  limit: 2,
                ),
        );
        final borschtSeasoning = _sentenceIngredientText(seasoningText);
        return [
          'Подготовь $anchor${support.isEmpty ? '' : ', $support'}${secondary.isEmpty ? '' : ', а $secondary держи для более сытной основы'}${aromaticsText.isEmpty ? '' : ', сначала мягко прогрей $aromaticsText 4-5 минут'}${borschtTomatoText.isEmpty ? '' : ' и вмешай $borschtTomatoText ещё на 1 минуту, чтобы свекольная база стала глубже'}.',
          'Влей воду, добавь капусту и корнеплоды${secondary.isEmpty ? '' : ', затем верни $secondary'} и вари борщ 20-25 минут до мягкости свеклы и овощей, не загоняя вкус в резкое кипение.',
          borschtSeasoning.isEmpty && borschtHomeFinish.isEmpty
              ? 'Сними борщ с огня, дай ему настояться 3-4 минуты и подавай горячим.'
              : 'В самом конце доведи борщ${borschtSeasoning.isEmpty ? '' : ' через $borschtSeasoning'}${borschtHomeFinish.isEmpty ? '' : ' и подай со $borschtHomeFinish'}, чтобы свекольная сладость получила мягкий домашний финиш, затем дай ему настояться 3-4 минуты.',
        ];
      case ChefDishFamily.solyankaSoup:
        final solyankaFinish = _sentenceIngredientText(
          _displayList(
            selectedBySlot['finish'] ?? const <String>[],
            inventory,
            limit: 2,
          ),
        );
        final solyankaBrightFinish = _sentenceIngredientText(
          _displayList(
            selectedBySlot['finish'] ?? const <String>[],
            inventory,
            limit: 2,
          ),
        );
        final solyankaBrightFinishFallback = _sentenceIngredientText(
          _displayList(
            [
              ...(selectedBySlot['finish'] ?? const <String>[]),
              for (final canonical in [
                ...secondaryCanonicals,
                ...supportCanonicals,
                ...starters.includedCanonicals,
                ...chefSupport.finishingCanonicals,
              ])
                if (canonical == 'оливки' || canonical == 'лимон') canonical,
            ],
            inventory,
            limit: 2,
          ),
        );
        final solyankaTomatoText = _sentenceIngredientText(
          _displayList(
            [
              if (supportCanonicals.contains('томатная паста'))
                'томатная паста',
              if (starters.includedCanonicals.contains('томатная паста'))
                'томатная паста',
            ],
            inventory,
            limit: 1,
          ),
        );
        final solyankaSeasoning = _sentenceIngredientText(seasoningText);
        final solyankaServeFinish = _sentenceIngredientText(
          finishText.isNotEmpty
              ? finishText
              : _displayList(
                  [
                    for (final canonical in [
                      ...chefSupport.finishingCanonicals,
                      ...starters.includedCanonicals,
                    ])
                      if (canonical == 'сметана') canonical,
                  ],
                  inventory,
                  limit: 1,
                ),
        );
        final solyankaBrightFinishText = solyankaFinish.isNotEmpty
            ? solyankaFinish
            : (solyankaBrightFinish.isNotEmpty
                ? solyankaBrightFinish
                : (solyankaBrightFinishFallback.isNotEmpty
                    ? solyankaBrightFinishFallback
                    : 'лимон или оливки'));
        return [
          'Подготовь $anchor${secondary.isEmpty ? '' : ', $secondary'}${support.isEmpty ? '' : ', а $support держи для соляно-томатной базы'}${aromaticsText.isEmpty ? '' : ', сначала мягко прогрей $aromaticsText 4-5 минут'}${solyankaTomatoText.isEmpty ? '' : ' и вмешай $solyankaTomatoText на 1 минуту для глубины'}.',
          'Влей воду, добавь мясную основу${secondary.isEmpty ? '' : ', солёный акцент через $secondary'}${support.isEmpty ? '' : ' и $support'}, затем вари солянку 14-16 минут на спокойном огне, чтобы бульон стал собранным и насыщенным.',
          'Доведи вкус${solyankaSeasoning.isEmpty ? '' : ' через $solyankaSeasoning'} и в конце добавь $solyankaBrightFinishText${solyankaServeFinish.isEmpty ? '' : ', а подавай солянку со $solyankaServeFinish'}, затем дай ей настояться 3-4 минуты перед подачей.',
        ];
      default:
        return null;
    }
  }

  String _sentenceIngredientText(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text.toLowerCase();
  }

  String _soupCookTiming({
    required List<String> anchors,
    required List<String> secondary,
    required List<String> support,
    required String supportText,
  }) {
    final anchor = _firstCanonical(anchors);
    final hasPickles =
        secondary.contains('огурец') || support.contains('огурец');
    switch (anchor) {
      case 'рыба':
        return 'Добавь овощи${supportText.isEmpty ? '' : ' и $supportText'}, влей воду и вари их 12-15 минут, затем добавь рыбу ещё на 8-10 минут, не давая вкусу распасться.';
      case 'перловка':
        return 'Добавь овощи${supportText.isEmpty ? '' : ' и $supportText'}, влей воду и вари основу 25-30 минут до мягкости, а солёный акцент вмешай за последние 5-6 минут.';
      case 'свекла':
        return 'Добавь овощи${supportText.isEmpty ? '' : ' и $supportText'}, влей воду и вари суп 20-25 минут до мягкости свеклы и корнеплодов.';
      case 'капуста':
        return 'Добавь овощи${supportText.isEmpty ? '' : ' и $supportText'}, влей воду и вари суп 18-22 минуты, пока капуста и корнеплоды не станут мягкими.';
      default:
        return 'Добавь овощи${supportText.isEmpty ? '' : ' и $supportText'}, влей воду и вари суп 18-24 минуты до мягкости ингредиентов.${hasPickles ? ' Солёный огурец лучше добавить в последние 5 минут.' : ''}';
    }
  }

  String _bakeCookTiming(List<String> anchorCanonicals) {
    final anchor = _firstCanonical(anchorCanonicals);
    switch (anchor) {
      case 'творог':
        return '28-32 минуты до спокойной румяной поверхности';
      case 'картофель':
      case 'фарш':
        return '26-30 минут до полной готовности и лёгкой корочки';
      default:
        return '24-28 минут до полной готовности и мягкой румяной поверхности';
    }
  }

  String _breakfastCookTiming(List<String> anchorCanonicals) {
    final anchor = _firstCanonical(anchorCanonicals);
    switch (anchor) {
      case 'овсяные хлопья':
        return 'Если основа овсяная, прогрей её 4-5 минут на слабом огне, постепенно вмешивая жидкую часть, чтобы сохранить лёгкость и нежность блюда.';
      case 'творог':
        return 'Если основа творожная, дай массе постоять 2-3 минуты перед подачей, чтобы она стала ровнее и мягче.';
      default:
        return 'Если нужно, слегка прогрей массу 2-3 минуты или оставь её свежей, чтобы сохранить лёгкость и нежность блюда.';
    }
  }

  String _porridgeCookTiming(List<String> anchorCanonicals) {
    final anchor = _firstCanonical(anchorCanonicals);
    switch (anchor) {
      case 'пшено':
        return 'Вари кашу на спокойном огне 18-20 минут, постепенно вмешивая жидкую или сливочную часть, чтобы текстура стала ровной и мягкой.';
      case 'рис':
        return 'Вари кашу на спокойном огне 20-22 минуты, постепенно вмешивая жидкую или сливочную часть, чтобы рис стал мягким, но не распался.';
      case 'манная крупа':
        return 'Вари кашу на спокойном огне 4-5 минут, всыпая манку тонкой струйкой и постоянно помешивая, чтобы не было комков.';
      default:
        return 'Вари кашу на спокойном огне 12-15 минут, постепенно вмешивая жидкую или сливочную часть, чтобы текстура стала ровной и мягкой.';
    }
  }

  String _stewCookTiming(
    List<String> anchorCanonicals,
    List<String> secondaryCanonicals,
  ) {
    final combined = {...anchorCanonicals, ...secondaryCanonicals};
    if (combined.contains('картофель') &&
        (combined.contains('говядина') ||
            combined.contains('свинина') ||
            combined.contains('курица'))) {
      return '22-28 минут';
    }
    if (combined.contains('капуста')) {
      return '18-22 минуты';
    }
    return '16-20 минут';
  }

  String _firstCanonical(List<String> canonicals) {
    if (canonicals.isEmpty) {
      return '';
    }
    return canonicals.first;
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
    required ChefBlueprint blueprint,
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
    final sauceReason = _buildSauceReason(blueprint.sauceStyle);
    if (sauceReason != null) {
      reasons.add(sauceReason);
    }
    final cutletReason = _buildCutletReason(blueprint.cutletStyle);
    if (cutletReason != null) {
      reasons.add(cutletReason);
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

  String? _buildSauceReason(ChefSauceStyle? sauceStyle) {
    switch (sauceStyle) {
      case ChefSauceStyle.tomatoSourCreamGravy:
        return 'шеф собирает мягкий томатно-сметанный соус, который обволакивает тефтели';
      case ChefSauceStyle.mildOnionGravy:
        return 'шеф ведёт биточки к мягкой подливке, которая не забивает мясо';
      case ChefSauceStyle.paprikaTomatoGravy:
        return 'шеф ведёт гуляш к густому папрично-томатному соусу без лишней воды';
      case ChefSauceStyle.sourCreamPanSauce:
        return 'шеф держит бефстроганов в гладком сметанном соусе без бурного кипения';
      case null:
        return null;
    }
  }

  String? _buildCutletReason(ChefCutletStyle? cutletStyle) {
    switch (cutletStyle) {
      case ChefCutletStyle.homeCutlets:
        return 'шеф держит мясную часть и гарнир раздельно, как у домашнего котлетного ужина';
      case ChefCutletStyle.stuffedZrazy:
        return 'шеф собирает зразы как мясную оболочку с отдельной начинкой внутри';
      case ChefCutletStyle.gravyBitochki:
        return 'шеф различает биточки и котлеты по мягкой подливке и более деликатной форме';
      case null:
        return null;
    }
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
  final titleIdentity = _recipeTitleIdentity(recipe.title);
  final ingredients = recipe.ingredients
      .where((ingredient) => ingredient.required)
      .map((ingredient) => canonicalizer.canonicalize(ingredient.name))
      .where(
        (value) => value.isNotEmpty && !ignoredCanonicals.contains(value),
      )
      .toSet()
      .toList()
    ..sort();
  return '${profile ?? inferDishProfile(title: recipe.title, tags: recipe.tags, ingredientCanonicals: ingredients).name}|$titleIdentity|${ingredients.join('|')}';
}

String _recipeBroadIdentity(
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

String _recipeTitleIdentity(String title) {
  final normalized = normalizeIngredientText(title);
  if (normalized.isEmpty) {
    return normalized;
  }
  return normalized.split(':').first.trim();
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
    case 'кефир':
      return 400;
    case 'квас':
      return 500;
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
    case 'укроп':
    case 'зелень':
      return 20;
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
    case 'зелень':
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
    case 'кефир':
    case 'квас':
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
        case 'зелень':
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
