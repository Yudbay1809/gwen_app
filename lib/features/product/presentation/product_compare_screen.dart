import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_compare_provider.dart';

class ProductCompareScreen extends ConsumerWidget {
  const ProductCompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(productCompareProvider);
    final favoriteId = ref.watch(compareFavoriteProvider);

    if (list.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compare Products')),
        body: Center(child: Text('Select 2 products to compare')),
      );
    }

    final items = list.take(3).toList();
    final priceMin = items.map((e) => e.discountPrice).reduce((a, b) => a < b ? a : b);
    final ratingMax = items.map((e) => e.rating).reduce((a, b) => a > b ? a : b);
    final reviewsMax = items.map((e) => e.reviewCount).reduce((a, b) => a > b ? a : b);
    final stockMax = items.map((e) => e.stock).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Compare Products')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 64,
          columnSpacing: 24,
          columns: [
            const DataColumn(label: Text('')),
            ...items.map(
              (p) => DataColumn(
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('Rp ${p.discountPrice.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
          rows: [
            _row(
              'Pinned',
              items.map((p) => favoriteId == p.id ? 'Yes' : 'No').toList(),
              highlightValue: 'Yes',
            ),
            _row(
              'Price',
              items.map((p) => 'Rp ${p.discountPrice.toStringAsFixed(0)}').toList(),
              highlightValue: 'Rp ${priceMin.toStringAsFixed(0)}',
            ),
            _row(
              'Rating',
              items.map((p) => p.rating.toStringAsFixed(1)).toList(),
              highlightValue: ratingMax.toStringAsFixed(1),
            ),
            _row(
              'Reviews',
              items.map((p) => '${p.reviewCount}').toList(),
              highlightValue: '$reviewsMax',
            ),
            _row(
              'Stock',
              items.map((p) => p.stock > 0 ? '${p.stock} left' : 'Out').toList(),
              highlightValue: '$stockMax left',
            ),
            _row(
              'Discount',
              items
                  .map((p) => p.price <= 0
                      ? '0%'
                      : '${(((p.price - p.discountPrice) / p.price) * 100).round()}%')
                  .toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(productCompareProvider.notifier).clear(),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ref.read(compareFavoriteProvider.notifier).toggle(items.first.id),
                  icon: const Icon(Icons.push_pin),
                  label: const Text('Pin first'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

DataRow _row(String label, List<String> values, {String? highlightValue}) {
  return DataRow(
    cells: [
      DataCell(Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
      ...values.map(
        (value) => DataCell(
          Text(
            value,
            style: TextStyle(
              fontWeight: value == highlightValue ? FontWeight.w700 : FontWeight.w400,
              color: value == highlightValue ? Colors.green : Colors.black87,
            ),
          ),
        ),
      ),
    ],
  );
}
