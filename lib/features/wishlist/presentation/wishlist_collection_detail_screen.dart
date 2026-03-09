import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/product_card.dart';
import 'wishlist_collections_provider.dart';
import 'wishlist_share_provider.dart';
import 'dart:convert';

class WishlistCollectionDetailScreen extends ConsumerWidget {
  final String name;

  const WishlistCollectionDetailScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(wishlistCollectionsProvider);
    final collection = collections.where((c) => c.name == name).firstOrNull;
    final link = ref.watch(wishlistShareProvider)[name] ??
        ref.read(wishlistShareProvider.notifier).getLink(name);

    if (collection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collection')),
        body: const Center(child: Text('Collection not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _exportCollection(context, collection),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _openShareSheet(context, link),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _renameCollection(context, ref, collection.name),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref.read(wishlistCollectionsProvider.notifier).deleteCollection(collection.name);
              context.pop();
            },
          ),
        ],
      ),
      body: collection.items.isEmpty
          ? const Center(child: Text('Collection is empty'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: collection.items.length,
              itemBuilder: (context, index) {
                final product = collection.items[index];
                return Stack(
                  children: [
                    ProductCard(
                      product: product,
                      onTap: () => context.go('/product/${product.id}'),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'remove') {
                            ref
                                .read(wishlistCollectionsProvider.notifier)
                                .removeFromCollection(collection.name, product);
                          } else if (value.startsWith('move:')) {
                            final target = value.replaceFirst('move:', '');
                            ref.read(wishlistCollectionsProvider.notifier).moveItem(
                                  collection.name,
                                  target,
                                  product,
                                );
                          }
                        },
                        itemBuilder: (context) {
                          final otherCollections =
                              collections.where((c) => c.name != collection.name).toList();
                          return [
                            const PopupMenuItem(value: 'remove', child: Text('Remove')),
                            if (otherCollections.isNotEmpty) const PopupMenuDivider(),
                            ...otherCollections.map(
                              (c) => PopupMenuItem(
                                value: 'move:${c.name}',
                                child: Text('Move to ${c.name}'),
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  void _renameCollection(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Collection'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(wishlistCollectionsProvider.notifier).renameCollection(current, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openShareSheet(BuildContext context, String link) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Share Collection', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(link, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy link'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: link));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share to apps'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening share options')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void _exportCollection(BuildContext context, WishlistCollection collection) {
  final items = collection.items;
  final jsonText = const JsonEncoder.withIndent('  ').convert(
    items
        .map((p) => {
              'id': p.id,
              'name': p.name,
              'price': p.price,
              'discountPrice': p.discountPrice,
            })
        .toList(),
  );
  final csv = StringBuffer('id,name,price,discountPrice\n');
  for (final p in items) {
    csv.writeln('${p.id},"${p.name.replaceAll('"', '""')}",${p.price},${p.discountPrice}');
  }
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Export Collection'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('JSON', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SelectableText(jsonText, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            const Text('CSV', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SelectableText(csv.toString(), style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: csv.toString()));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CSV copied')),
            );
          },
          child: const Text('Copy CSV'),
        ),
      ],
    ),
  );
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
