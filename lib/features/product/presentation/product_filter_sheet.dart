import 'package:flutter/material.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/brand.dart';

enum ProductSort { recommended, newest, priceLow, priceHigh, rating, reviews }

class ProductFilter {
  final ProductSort sort;
  final RangeValues priceRange;
  final int? categoryId;
  final int? brandId;
  final double minRating;
  final int minReviews;
  final bool inStockOnly;
  final RangeValues discountRange;

  const ProductFilter({
    required this.sort,
    required this.priceRange,
    this.categoryId,
    this.brandId,
    required this.minRating,
    required this.minReviews,
    required this.inStockOnly,
    required this.discountRange,
  });

  ProductFilter copyWith({
    ProductSort? sort,
    RangeValues? priceRange,
    int? categoryId,
    int? brandId,
    double? minRating,
    int? minReviews,
    bool? inStockOnly,
    RangeValues? discountRange,
    bool clearCategory = false,
    bool clearBrand = false,
  }) {
    return ProductFilter(
      sort: sort ?? this.sort,
      priceRange: priceRange ?? this.priceRange,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      brandId: clearBrand ? null : (brandId ?? this.brandId),
      minRating: minRating ?? this.minRating,
      minReviews: minReviews ?? this.minReviews,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      discountRange: discountRange ?? this.discountRange,
    );
  }
}

class ProductFilterSheet extends StatefulWidget {
  final ProductFilter initial;
  final double minPrice;
  final double maxPrice;
  final List<Category> categories;
  final List<Brand> brands;
  final ValueChanged<ProductFilter> onApply;

  const ProductFilterSheet({
    super.key,
    required this.initial,
    required this.minPrice,
    required this.maxPrice,
    required this.categories,
    required this.brands,
    required this.onApply,
  });

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late ProductSort _sort;
  late RangeValues _range;
  int? _categoryId;
  int? _brandId;
  double _minRating = 0;
  int _minReviews = 0;
  bool _inStockOnly = false;
  late RangeValues _discountRange;

  @override
  void initState() {
    super.initState();
    _sort = widget.initial.sort;
    _range = widget.initial.priceRange;
    _categoryId = widget.initial.categoryId;
    _brandId = widget.initial.brandId;
    _minRating = widget.initial.minRating;
    _minReviews = widget.initial.minReviews;
    _inStockOnly = widget.initial.inStockOnly;
    _discountRange = widget.initial.discountRange;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sort by', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Recommended'),
                selected: _sort == ProductSort.recommended,
                onSelected: (_) => setState(() => _sort = ProductSort.recommended),
              ),
              ChoiceChip(
                label: const Text('Newest'),
                selected: _sort == ProductSort.newest,
                onSelected: (_) => setState(() => _sort = ProductSort.newest),
              ),
              ChoiceChip(
                label: const Text('Price Low'),
                selected: _sort == ProductSort.priceLow,
                onSelected: (_) => setState(() => _sort = ProductSort.priceLow),
              ),
              ChoiceChip(
                label: const Text('Price High'),
                selected: _sort == ProductSort.priceHigh,
                onSelected: (_) => setState(() => _sort = ProductSort.priceHigh),
              ),
              ChoiceChip(
                label: const Text('Rating'),
                selected: _sort == ProductSort.rating,
                onSelected: (_) => setState(() => _sort = ProductSort.rating),
              ),
              ChoiceChip(
                label: const Text('Most Reviews'),
                selected: _sort == ProductSort.reviews,
                onSelected: (_) => setState(() => _sort = ProductSort.reviews),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _categoryId == null,
                onSelected: (_) => setState(() => _categoryId = null),
              ),
              ...widget.categories.map(
                (c) => ChoiceChip(
                  label: Text(c.name),
                  selected: _categoryId == c.id,
                  onSelected: (_) => setState(() => _categoryId = c.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Brand', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _brandId == null,
                onSelected: (_) => setState(() => _brandId = null),
              ),
              ...widget.brands.map(
                (b) => ChoiceChip(
                  label: Text(b.name),
                  selected: _brandId == b.id,
                  onSelected: (_) => setState(() => _brandId = b.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Min rating', style: TextStyle(fontWeight: FontWeight.w700)),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            label: _minRating.toStringAsFixed(1),
            onChanged: (v) => setState(() => _minRating = v),
          ),
          const SizedBox(height: 8),
          const Text('Min reviews', style: TextStyle(fontWeight: FontWeight.w700)),
          Slider(
            value: _minReviews.toDouble(),
            min: 0,
            max: 300,
            divisions: 6,
            label: _minReviews.toString(),
            onChanged: (v) => setState(() => _minReviews = v.round()),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('In stock only'),
            value: _inStockOnly,
            onChanged: (v) => setState(() => _inStockOnly = v),
          ),
          const SizedBox(height: 8),
          const Text('Price range', style: TextStyle(fontWeight: FontWeight.w700)),
          RangeSlider(
            values: _range,
            min: widget.minPrice,
            max: widget.maxPrice,
            divisions: 6,
            labels: RangeLabels(
              _range.start.toStringAsFixed(0),
              _range.end.toStringAsFixed(0),
            ),
            onChanged: (v) => setState(() => _range = v),
          ),
          const SizedBox(height: 8),
          const Text('Discount range (%)', style: TextStyle(fontWeight: FontWeight.w700)),
          RangeSlider(
            values: _discountRange,
            min: 0,
            max: 70,
            divisions: 7,
            labels: RangeLabels(
              _discountRange.start.toStringAsFixed(0),
              _discountRange.end.toStringAsFixed(0),
            ),
            onChanged: (v) => setState(() => _discountRange = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(
                ProductFilter(
                  sort: _sort,
                  priceRange: _range,
                  categoryId: _categoryId,
                  brandId: _brandId,
                  minRating: _minRating,
                  minReviews: _minReviews,
                  inStockOnly: _inStockOnly,
                  discountRange: _discountRange,
                ),
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
