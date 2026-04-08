import '../../../shared/models/product.dart';
import 'home_providers.dart';

enum HomeQuickFilter { none, priceLow, topRated, sensitive }

List<Product> applyHomeFilter(
  List<Product> items,
  HomeAllProductsFilter filter,
  String query,
  HomeQuickFilter quickFilter,
) {
  var filtered = items;
  final q = query.trim().toLowerCase();
  if (q.isNotEmpty) {
    filtered = filtered.where((p) => p.name.toLowerCase().contains(q)).toList();
  }
  if (filter == HomeAllProductsFilter.all) return filtered;
  if (filter == HomeAllProductsFilter.promo) {
    return filtered
        .where((p) => ((p.price - p.discountPrice) / p.price) >= 0.15)
        .toList();
  }
  if (filter == HomeAllProductsFilter.best) {
    filtered = filtered.where((p) => p.rating >= 4.6).toList();
  } else if (filter == HomeAllProductsFilter.newest) {
    filtered = filtered
        .where((p) => (p.id >= 300 && p.id < 400) || p.id % 5 == 0)
        .toList();
  }

  switch (quickFilter) {
    case HomeQuickFilter.none:
      return filtered;
    case HomeQuickFilter.priceLow:
      final list = [...filtered];
      list.sort((a, b) => a.discountPrice.compareTo(b.discountPrice));
      return list;
    case HomeQuickFilter.topRated:
      return filtered.where((p) => p.rating >= 4.7).toList();
    case HomeQuickFilter.sensitive:
      return filtered.where((p) => p.id % 2 == 0).toList();
  }
}

String homeFilterLabel(HomeAllProductsFilter filter) {
  switch (filter) {
    case HomeAllProductsFilter.all:
      return 'All products';
    case HomeAllProductsFilter.promo:
      return 'Promo deals';
    case HomeAllProductsFilter.best:
      return 'Best rated';
    case HomeAllProductsFilter.newest:
      return 'New arrivals';
  }
}

int calcProductMatchScore(Product product, String skinType) {
  var score = (product.rating * 18).round();
  score += (product.reviewCount ~/ 40).clamp(0, 8);
  final discountPct = ((product.price - product.discountPrice) / product.price)
      .clamp(0.0, 0.6);
  score += (discountPct * 12).round();
  if (product.stock <= 3) score -= 2;
  if (skinType.toLowerCase() == 'sensitive') {
    score += product.id.isEven ? 4 : 0;
  } else if (skinType.toLowerCase() == 'oily') {
    score += product.id % 3 == 0 ? 3 : 0;
  } else if (skinType.toLowerCase() == 'dry') {
    score += product.id % 5 == 0 ? 3 : 0;
  }
  if (score > 98) score = 98;
  if (score < 70) score = 70;
  return score;
}

List<Product> sortProductsByStock(List<Product> items) {
  final inStock = items.where((p) => p.stock > 0).toList();
  final outOfStock = items.where((p) => p.stock <= 0).toList();
  return [...inStock, ...outOfStock];
}
