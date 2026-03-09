import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:help_to_cook/features/fridge/domain/product_catalog_entry.dart';
import 'package:help_to_cook/features/recipes/domain/ingredient_knowledge.dart';
import 'package:help_to_cook/features/recipes/domain/offline_chef_blueprints.dart';
import 'package:help_to_cook/features/recipes/domain/recipe_ingredient_canonicalizer.dart';
import 'package:help_to_cook/features/shelf/domain/pantry_catalog_entry.dart';

void main() {
  final products = _loadProducts();
  final pantry = _loadPantry();
  final canonicalizer = RecipeIngredientCanonicalizer(products);
  final productCanonicals = products
      .map((entry) => canonicalizer.canonicalize(entry.canonicalName))
      .toSet();
  final pantryStarters = pantry
      .where((entry) => entry.isStarter)
      .map((entry) => normalizeIngredientText(entry.canonicalName))
      .toSet();

  test('all blueprint candidates resolve to known product canonicals', () {
    for (final blueprint in chefBlueprints) {
      for (final slot in blueprint.slots) {
        for (final candidate in slot.candidates) {
          expect(
            productCanonicals.contains(candidate),
            isTrue,
            reason: 'Unknown candidate "$candidate" in blueprint "${blueprint.id}"',
          );
        }
      }
    }
  });

  test('all preferred pantry starters are backed by starter pantry entries', () {
    for (final blueprint in chefBlueprints) {
      for (final starter in blueprint.preferredStarters) {
        expect(
          pantryStarters.contains(starter),
          isTrue,
          reason: 'Unknown or non-starter pantry item "$starter" in "${blueprint.id}"',
        );
      }
    }
  });

  test('common colloquial aliases canonicalize to intended ingredients', () {
    expect(canonicalizer.canonicalize('Куриная грудка'), 'курица');
    expect(canonicalizer.canonicalize('Шампиньоны'), 'грибы');
    expect(canonicalizer.canonicalize('Греческий йогурт'), 'йогурт');
    expect(canonicalizer.canonicalize('Помидоры черри'), 'помидор');
    expect(canonicalizer.canonicalize('Рожки'), 'макароны');
  });
}

List<ProductCatalogEntry> _loadProducts() {
  final jsonText = File('assets/products/catalog_ru.json').readAsStringSync();
  final raw = jsonDecode(jsonText) as List<dynamic>;
  return raw
      .map((entry) => ProductCatalogEntry.fromJson(entry as Map<String, dynamic>))
      .toList();
}

List<PantryCatalogEntry> _loadPantry() {
  final jsonText = File('assets/pantry/catalog_ru.json').readAsStringSync();
  final raw = jsonDecode(jsonText) as List<dynamic>;
  return raw
      .map((entry) => PantryCatalogEntry.fromJson(entry as Map<String, dynamic>))
      .toList();
}
