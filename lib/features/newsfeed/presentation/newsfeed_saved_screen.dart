import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'newsfeed_providers.dart';
import 'article_saved_provider.dart';

class NewsfeedSavedScreen extends ConsumerStatefulWidget {
  const NewsfeedSavedScreen({super.key});

  @override
  ConsumerState<NewsfeedSavedScreen> createState() => _NewsfeedSavedScreenState();
}

class _NewsfeedSavedScreenState extends ConsumerState<NewsfeedSavedScreen> {
  bool _selectMode = false;
  final Set<int> _selected = {};

  void _toggleSelect(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _export(List<ArticleItem> articles) {
    final payload = articles
        .map((a) => {
              'id': a.id,
              'title': a.title,
              'author': a.author,
              'category': a.category,
            })
        .toList();
    final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export Saved Articles'),
        content: SingleChildScrollView(child: SelectableText(jsonText, style: const TextStyle(fontSize: 12))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonText));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export copied')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedIds = ref.watch(articleSavedProvider);
    final articles = ref.watch(newsfeedProvider).where((a) => savedIds.contains(a.id)).toList();
    final allSelected = _selected.length == articles.length && articles.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Articles'),
        actions: [
          if (articles.isNotEmpty)
            TextButton(
              onPressed: () => _export(articles),
              child: const Text('Export', style: TextStyle(color: Colors.black87)),
            ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectMode = !_selectMode;
                if (!_selectMode) _selected.clear();
              });
            },
            child: Text(_selectMode ? 'Cancel' : 'Select', style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
      body: articles.isEmpty
          ? const Center(child: Text('No saved articles'))
          : Column(
              children: [
                if (_selectMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text('${_selected.length} selected'),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (allSelected) {
                                _selected.clear();
                              } else {
                                _selected.addAll(articles.map((e) => e.id));
                              }
                            });
                          },
                          child: Text(allSelected ? 'Clear all' : 'Select all'),
                        ),
                        TextButton(
                          onPressed: _selected.isEmpty
                              ? null
                              : () {
                                  for (final id in _selected) {
                                    ref.read(articleSavedProvider.notifier).toggle(id);
                                  }
                                  setState(() => _selected.clear());
                                },
                          child: const Text('Unsave'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      final selected = _selected.contains(article.id);
                      return Card(
                        child: _selectMode
                            ? CheckboxListTile(
                                value: selected,
                                onChanged: (_) => _toggleSelect(article.id),
                                title: Text(article.title),
                                subtitle: Text(article.excerpt, maxLines: 2, overflow: TextOverflow.ellipsis),
                                secondary: Image.network(article.image, width: 56, height: 56, fit: BoxFit.cover),
                              )
                            : ListTile(
                                leading: Image.network(article.image, width: 56, height: 56, fit: BoxFit.cover),
                                title: Text(article.title),
                                subtitle: Text(article.excerpt, maxLines: 2, overflow: TextOverflow.ellipsis),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => ref.read(articleSavedProvider.notifier).toggle(article.id),
                                ),
                                onTap: () => context.go('/article/${article.id}'),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
