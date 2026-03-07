import 'package:flutter/material.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/brand.dart';

enum ProductSort { recommended, priceLow, priceHigh, rating }

class ProductFilter {
  final ProductSort sort;
  final RangeValues priceRange;
  final int? categoryId;
  final int? brandId;

  const ProductFilter({
    required this.sort,
    required this.priceRange,
    this.categoryId,
    this.brandId,
  });

  ProductFilter copyWith({
    ProductSort? sort,
    RangeValues? priceRange,
    int? categoryId,
    int? brandId,
    bool clearCategory = false,
    bool clearBrand = false,
  }) {
    return ProductFilter(
      sort: sort ?? this.sort,
      priceRange: priceRange ?? this.priceRange,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      brandId: clearBrand ? null : (brandId ?? this.brandId),
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

  @override
  void initState() {
    super.initState();
    _sort = widget.initial.sort;
    _range = widget.initial.priceRange;
    _categoryId = widget.initial.categoryId;
    _brandId = widget.initial.brandId;
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(
                ProductFilter(
                  sort: _sort,
                  priceRange: _range,
                  categoryId: _categoryId,
                  brandId: _brandId,
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
