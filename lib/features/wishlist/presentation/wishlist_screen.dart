import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/empty_state.dart';
import 'wishlist_providers.dart';
import 'wishlist_collections_provider.dart';
import 'create_collection_sheet.dart';
import '../../home/presentation/home_providers.dart';
import 'wishlist_price_alert_provider.dart';
import 'wishlist_price_history_provider.dart';
import 'wishlist_price_alert_settings_provider.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/brand.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  void _toggleSelection(Product product) {
    setState(() {
      if (_selectedIds.contains(product.id)) {
        _selectedIds.remove(product.id);
      } else {
        _selectedIds.add(product.id);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  void _enterSelection(Product product) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(product.id);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _removeSelected(List<Product> items) {
    final notifier = ref.read(wishlistProvider.notifier);
    final removed = <Product>[];
    for (final product in items.where((p) => _selectedIds.contains(p.id))) {
      notifier.remove(product);
      removed.add(product);
    }
    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Removed from wishlist'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            for (final product in removed) {
              notifier.toggle(product);
            }
          },
        ),
      ),
    );
  }

  Future<void> _moveSelected(List<Product> items) async {
    final controller = TextEditingController();
    final collections = ref.read(wishlistCollectionsProvider);
    final selected = items.where((p) => _selectedIds.contains(p.id)).toList();
    if (selected.isEmpty) return;

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Move to collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (collections.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose existing', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              ...collections.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.name),
                  onTap: () => Navigator.pop(context, c.name),
                ),
              ),
              const Divider(),
            ],
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'New collection name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;
    final collectionsNotifier = ref.read(wishlistCollectionsProvider.notifier);
    collectionsNotifier.createCollection(result);
    final wishlistNotifier = ref.read(wishlistProvider.notifier);
    final movedItems = <Product>[];
    for (final product in selected) {
      collectionsNotifier.addToCollection(result, product);
      wishlistNotifier.remove(product);
      movedItems.add(product);
    }
    _clearSelection();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved ${selected.length} item(s) to $result'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              for (final product in movedItems) {
                collectionsNotifier.removeFromCollection(result, product);
                wishlistNotifier.toggle(product);
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(wishlistProvider);
    final collections = ref.watch(wishlistCollectionsProvider);
    final collectionAnalytics = ref.watch(collectionAnalyticsProvider);
    final wishlistAnalytics = ref.watch(wishlistAnalyticsProvider);
    final priceAlerts = ref.watch(wishlistPriceAlertProvider);
    final priceAlertSettings = ref.watch(wishlistPriceAlertSettingsProvider);
    final priceHistory = ref.watch(wishlistPriceHistoryProvider);
    final allProducts = ref.watch(homeDataProvider).allProducts;
    final productsById = {for (final p in allProducts) p.id: p};
    final categories = ref.watch(homeDataProvider).categories;
    final brands = ref.watch(homeDataProvider).brands;
    final topIds = wishlistAnalytics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topProducts = topIds.take(4).map((e) => productsById[e.key]).whereType<Product>();
    final allSelected = items.isNotEmpty && _selectedIds.length == items.length;
    final priceDropItems = items
        .where((p) => priceHistory[p.id] != null && priceHistory[p.id]!.length >= 2)
        .map((p) {
          final history = priceHistory[p.id]!;
          final oldPrice = history.first;
          final newPrice = history.last;
          final drop = oldPrice - newPrice;
          return (product: p, oldPrice: oldPrice, newPrice: newPrice, drop: drop);
        })
        .where((e) => e.drop > 0)
        .toList()
      ..sort((a, b) => b.drop.compareTo(a.drop));

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? '${_selectedIds.length} selected' : 'Wishlist'),
        leading: _selectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection)
            : null,
        actions: [
          if (_selectionMode)
            IconButton(
              icon: Icon(allSelected ? Icons.select_all : Icons.check_box_outline_blank),
              onPressed: () {
                setState(() {
                  if (allSelected) {
                    _selectedIds.clear();
                    _selectionMode = false;
                  } else {
                    _selectedIds.addAll(items.map((e) => e.id));
                  }
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (_) => CreateCollectionSheet(
                  onCreate: (name) => ref.read(wishlistCollectionsProvider.notifier).createCollection(name),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (priceAlerts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active, size: 18),
                      const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${priceAlerts.length} price alerts active'
                      '${priceAlerts.isNotEmpty ? ' • next ${priceAlertSettings[priceAlerts.first]?.remindAt ?? 'Daily'}' : ''}',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final id = priceAlerts.first;
                      final product = productsById[id];
                      final setting = priceAlertSettings[id];
                      if (product == null || setting == null) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Alert: ${product.name} at Rp ${setting.targetPrice.toStringAsFixed(0)} (${setting.remindAt})',
                          ),
                        ),
                      );
                    },
                    child: const Text('Preview'),
                  ),
                  TextButton(
                    onPressed: () => ref.read(wishlistPriceAlertProvider.notifier).toggle(priceAlerts.first),
                    child: const Text('Disable one'),
                  ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...priceAlerts.take(2).map((id) {
                    final product = productsById[id];
                    final setting = priceAlertSettings[id];
                    if (product == null || setting == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('Rp ${setting.targetPrice.toStringAsFixed(0)}'),
                          const SizedBox(width: 6),
                          Text(setting.remindAt, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (priceDropItems.isNotEmpty) ...[
            const Text('Price Drop Timeline', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...priceDropItems.take(3).map(
              (e) => Card(
                child: ListTile(
                  leading: Image.network(e.product.image, width: 48, height: 48, fit: BoxFit.cover),
                  title: Text(e.product.name),
                  subtitle: Text(
                    'From Rp ${e.oldPrice.toStringAsFixed(0)} to Rp ${e.newPrice.toStringAsFixed(0)}',
                  ),
                  trailing: Text(
                    '-Rp ${e.drop.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_selectionMode) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${_selectedIds.length} item selected')),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (allSelected) {
                          _selectedIds.clear();
                          _selectionMode = false;
                        } else {
                          _selectedIds.addAll(items.map((e) => e.id));
                        }
                      });
                    },
                    child: Text(allSelected ? 'Clear all' : 'Select all'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (topProducts.isNotEmpty) ...[
            const Text('Most Wishlisted', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 210,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: topProducts
                    .map(
                      (product) => SizedBox(
                        width: 150,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ProductCard(
                            product: product,
                            onTap: () => context.go('/product/${product.id}'),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (collectionAnalytics.isNotEmpty) ...[
            const Text('Top Collections', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...collectionAnalytics.take(3).map(
                  (a) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.folder_open),
                    title: Text(a.name),
                    subtitle: Text('${a.itemCount} items'),
                    trailing: _GrowthBadge(value: a.growth),
                    onTap: () => context.go('/wishlist/collection/${a.name}'),
                  ),
                ),
            const SizedBox(height: 16),
          ],
          if (collections.isNotEmpty) ...[
            const Text('Collections', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: collections
                  .map(
                    (c) => GestureDetector(
                      onLongPress: () => _renameCollection(context, ref, c.name),
                      child: ActionChip(
                        label: Text('${c.name} (${c.items.length})'),
                        onPressed: () => context.go('/wishlist/collection/${c.name}'),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (items.isNotEmpty) ...[
            const Text('Smart Collections', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final groups = _buildSmartCollections(items, categories, brands);
                if (groups.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('No smart collections yet', style: TextStyle(color: Colors.grey)),
                  );
                }
                return Wrap(
                  spacing: 8,
                  children: groups
                      .map(
                        (group) => ActionChip(
                          avatar: Icon(group.isBrand ? Icons.local_offer : Icons.category, size: 16),
                          label: Text('${group.label} (${group.items.length})'),
                          onPressed: () => _createSmartCollection(ref, group),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                for (final group in _buildSmartCollections(items, categories, brands)) {
                  _createSmartCollection(ref, group);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Smart collections created')),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Create all smart collections'),
            ),
            const SizedBox(height: 16),
          ],
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  const EmptyState(
                    icon: Icons.favorite_border,
                    title: 'Wishlist is empty',
                    message: 'Save products you love to see them here.',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/shop'),
                    child: const Text('Browse products'),
                  ),
                ],
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _exportWishlist(context, items),
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Export wishlist'),
              ),
            ),
          if (items.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final product = items[index];
                final selected = _selectedIds.contains(product.id);
                final alertOn = priceAlerts.contains(product.id);
                final alertSetting = priceAlertSettings[product.id];
                return GestureDetector(
                  onLongPress: () => _enterSelection(product),
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelection(product);
                    } else {
                      context.go('/product/${product.id}');
                    }
                  },
                  child: Stack(
                    children: [
                      ProductCard(product: product),
                      if (priceHistory[product.id] != null)
                        Positioned(
                          left: 8,
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _openPriceHistorySheet(
                              context,
                              product,
                              priceHistory[product.id]!,
                            ),
                            child: _PriceTrendSparkline(values: priceHistory[product.id]!),
                          ),
                        ),
                      if (selected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(90),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.check_circle, color: Colors.white, size: 42),
                            ),
                          ),
                        ),
                      if (_selectionMode && !selected)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.check_box_outline_blank, size: 18),
                          ),
                        ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: GestureDetector(
                          onTap: () => _openPriceAlertSheet(context, ref, product, alertOn, alertSetting),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              alertOn ? Icons.notifications_active : Icons.notifications_none,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: _selectionMode
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ]),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectedIds.isEmpty ? null : () => _moveSelected(items),
                        icon: const Icon(Icons.folder),
                        label: const Text('Move'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedIds.isEmpty ? null : () => _removeSelected(items),
                        icon: const Icon(Icons.delete),
                        label: const Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _PriceTrendSparkline extends StatelessWidget {
  final List<double> values;

  const _PriceTrendSparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(
        painter: _SparklinePainter(values),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;

  _SparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final paint = Paint()
      ..color = Colors.pinkAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _GrowthBadge extends StatelessWidget {
  final int value;

  const _GrowthBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final isPositive = value >= 0;
    final color = isPositive ? Colors.green : Colors.redAccent;
    final text = isPositive ? '+$value' : '$value';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

void _exportWishlist(BuildContext context, List<Product> items) {
  final payload = items
      .map((p) => {
            'id': p.id,
            'name': p.name,
            'price': p.discountPrice,
          })
      .toList();
  final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Export Wishlist'),
      content: SingleChildScrollView(
        child: SelectableText(jsonText, style: const TextStyle(fontSize: 12)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: jsonText));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wishlist copied')),
            );
          },
          child: const Text('Copy'),
        ),
      ],
    ),
  );
}

Future<void> _openPriceAlertSheet(
  BuildContext context,
  WidgetRef ref,
  Product product,
  bool enabled,
  PriceAlertSetting? setting,
) async {
  final basePrice = product.discountPrice;
  final min = (product.discountPrice * 0.6).clamp(20000.0, product.price).toDouble();
  final max = product.price;
  var target = (setting?.targetPrice ?? (basePrice * 0.9)).toDouble();
  if (target < min) target = min;
  if (target > max) target = max;
  var remindAt = setting?.remindAt ?? 'Weekly';

  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Target price: Rp ${target.toStringAsFixed(0)}'),
              Slider(
                value: target,
                min: min,
                max: max,
                divisions: 10,
                label: target.toStringAsFixed(0),
                onChanged: (v) => setModalState(() => target = v),
              ),
              const SizedBox(height: 8),
              const Text('Reminder'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['Daily', 'Weekly', 'Monthly']
                    .map(
                      (r) => ChoiceChip(
                        label: Text(r),
                        selected: remindAt == r,
                        onSelected: (_) => setModalState(() => remindAt = r),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(wishlistPriceAlertProvider.notifier).toggle(product.id);
                        ref.read(wishlistPriceAlertSettingsProvider.notifier).remove(product.id);
                        Navigator.pop(context);
                      },
                      child: Text(enabled ? 'Disable' : 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (!enabled) {
                          ref.read(wishlistPriceAlertProvider.notifier).toggle(product.id);
                        }
                        ref.read(wishlistPriceAlertSettingsProvider.notifier).setSetting(
                              PriceAlertSetting(
                                productId: product.id,
                                targetPrice: target,
                                remindAt: remindAt,
                              ),
                            );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Price alert saved')),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

void _openPriceHistorySheet(BuildContext context, Product product, List<double> history) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _PriceTrendSparkline(values: history),
          const SizedBox(height: 12),
          ...history.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text('Day ${e.key + 1}', style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      Text('Rp ${e.value.toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}

class _SmartGroup {
  final String label;
  final String name;
  final List<Product> items;
  final bool isBrand;

  const _SmartGroup({
    required this.label,
    required this.name,
    required this.items,
    required this.isBrand,
  });
}

List<_SmartGroup> _buildSmartCollections(
  List<Product> items,
  List<Category> categories,
  List<Brand> brands,
) {
  final groups = <_SmartGroup>[];
  final byCategory = <int, List<Product>>{};
  final byBrand = <int, List<Product>>{};
  for (final item in items) {
    byCategory.putIfAbsent(item.categoryId, () => []).add(item);
    byBrand.putIfAbsent(item.brandId, () => []).add(item);
  }
  for (final entry in byCategory.entries) {
    final name = categories.firstWhere((c) => c.id == entry.key).name;
    groups.add(_SmartGroup(label: 'Category: $name', name: 'Cat $name', items: entry.value, isBrand: false));
  }
  for (final entry in byBrand.entries) {
    final name = brands.firstWhere((b) => b.id == entry.key).name;
    groups.add(_SmartGroup(label: 'Brand: $name', name: 'Brand $name', items: entry.value, isBrand: true));
  }
  groups.sort((a, b) => b.items.length.compareTo(a.items.length));
  return groups;
}

void _createSmartCollection(WidgetRef ref, _SmartGroup group) {
  final notifier = ref.read(wishlistCollectionsProvider.notifier);
  notifier.createCollection(group.name);
  for (final product in group.items) {
    notifier.addToCollection(group.name, product);
  }
}

Future<void> _renameCollection(BuildContext context, WidgetRef ref, String oldName) async {
  final controller = TextEditingController(text: oldName);
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Rename collection'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'New name'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
      ],
    ),
  );
  if (result == true) {
    final value = controller.text.trim();
    if (value.isNotEmpty) {
      ref.read(wishlistCollectionsProvider.notifier).renameCollection(oldName, value);
    }
  }
}
