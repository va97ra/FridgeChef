import 'recipe.dart';

enum CookFilter { upTo15Min, noOven, onePan }

bool matchesCookFilters(Recipe recipe, Set<CookFilter> filters) {
  if (filters.isEmpty) {
    return true;
  }

  final tags = recipe.tags.map((tag) => tag.toLowerCase()).toSet();

  if (filters.contains(CookFilter.upTo15Min) && recipe.timeMin > 15) {
    return false;
  }
  if (filters.contains(CookFilter.noOven) && !tags.contains('no_oven')) {
    return false;
  }
  if (filters.contains(CookFilter.onePan) && !tags.contains('one_pan')) {
    return false;
  }
  return true;
}
