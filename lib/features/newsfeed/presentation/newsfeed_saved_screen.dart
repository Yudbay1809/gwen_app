import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'newsfeed_providers.dart';
import 'article_saved_provider.dart';
import '../../../shared/widgets/motion.dart';

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
                MotionFadeSlide(
                  beginOffset: const Offset(0, 0.08),
                  child: _SavedHeroSummary(total: articles.length),
                ),
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
                      return MotionFadeSlide(
                        delay: Duration(milliseconds: 60 * (index % 6)),
                        beginOffset: const Offset(0, 0.06),
                        child: _SavedArticleCard(
                          article: article,
                          selected: selected,
                          selectMode: _selectMode,
                          onToggleSelect: () => _toggleSelect(article.id),
                          onRemove: () => ref.read(articleSavedProvider.notifier).toggle(article.id),
                          onOpen: () => context.go('/article/${article.id}'),
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

class _SavedHeroSummary extends StatelessWidget {
  final int total;

  const _SavedHeroSummary({required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.9),
            scheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark, size: 18),
          const SizedBox(width: 8),
          Text(
            '$total saved articles',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SavedArticleCard extends StatelessWidget {
  final ArticleItem article;
  final bool selected;
  final bool selectMode;
  final VoidCallback onToggleSelect;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  const _SavedArticleCard({
    required this.article,
    required this.selected,
    required this.selectMode,
    required this.onToggleSelect,
    required this.onRemove,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        onTap: selectMode ? onToggleSelect : onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(article.image, width: 72, height: 72, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (selectMode)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    selected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
