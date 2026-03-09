import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'store_data.dart';

class StoreDetailScreen extends StatelessWidget {
  final String id;

  const StoreDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final store = stores.where((s) => s.id == id).firstOrNull;
    if (store == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Store'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/stores');
              }
            },
          ),
        ),
        body: const Center(child: Text('Store not found')),
      );
    }
    final mapsUrl = 'https://maps.google.com/?q=${store.lat},${store.lng}';

    return Scaffold(
      appBar: AppBar(
        title: Text(store.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/stores');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Address', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(store.address),
          const SizedBox(height: 16),
          const Text('Opening Hours', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(store.hours),
          const SizedBox(height: 16),
          const Text('Contact', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(store.phone),
          const SizedBox(height: 16),
          const Text('Directions', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          SelectableText(mapsUrl, style: const TextStyle(color: Colors.blueGrey)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: mapsUrl));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Directions link copied')),
                );
              }
            },
            icon: const Icon(Icons.directions),
            label: const Text('Copy directions link'),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
