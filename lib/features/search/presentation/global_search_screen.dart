import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home/presentation/home_providers.dart';
import '../../review/presentation/review_providers.dart';
import '../../newsfeed/presentation/newsfeed_providers.dart';
import 'search_history_provider.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  String _query = '';
  _SearchScope _scope = _SearchScope.all;
  Timer? _debounce;
  int _productPage = 1;
  int _reviewPage = 1;
  int _newsPage = 1;
  final _controller = TextEditingController();
  bool _loadedPrefs = false;
  List<String> _savedFilters = [];
  int? _brandId;
  RangeValues? _priceRange;
  final List<String> _trending = const [
    'Glow serum',
    'Sunscreen',
    'Lip tint',
    'Hydrating toner',
    'Retinol',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final scopeName = prefs.getString('global_search_scope') ?? 'all';
    _savedFilters = prefs.getStringList('global_search_saved_filters') ?? [];
    final scope = _SearchScope.values.firstWhere(
      (e) => e.name == scopeName,
      orElse: () => _SearchScope.all,
    );
    final query = prefs.getString('global_search_query_${scope.name}') ?? '';
    if (!mounted) return;
    setState(() {
      _scope = scope;
      _query = query;
      _controller.text = query;
      _loadedPrefs = true;
    });
  }

  Future<void> _saveCurrentFilter() async {
    final trimmed = _query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = '${_scope.name}|$trimmed';
    final next = [..._savedFilters];
    next.remove(key);
    next.insert(0, key);
    if (next.length > 8) {
      next.removeRange(8, next.length);
    }
    await prefs.setStringList('global_search_saved_filters', next);
    if (!mounted) return;
    setState(() => _savedFilters = next);
  }

  void _applySavedFilter(String value) {
    final parts = value.split('|');
    if (parts.length < 2) return;
    final scopeName = parts.first;
    final query = parts.sublist(1).join('|');
    final scope = _SearchScope.values.firstWhere(
      (e) => e.name == scopeName,
      orElse: () => _SearchScope.all,
    );
    setState(() {
      _scope = scope;
      _query = query;
      _controller.text = query;
      _productPage = 1;
      _reviewPage = 1;
      _newsPage = 1;
    });
    _saveScope(scope);
    _saveQuery(query);
  }

  Future<void> _saveScope(_SearchScope scope) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_search_scope', scope.name);
  }

  @override
  Widget build(BuildContext context) {
    final homeData = ref.watch(homeDataProvider);
    final products = homeData.allProducts;
    final brands = homeData.brands;
    final reviews = ref.watch(reviewFeedProvider);
    final articles = ref.watch(newsfeedProvider);
    final history = ref.watch(searchHistoryProvider);
    final q = _query.trim().toLowerCase();
    final terms = _expandQuery(q);
    final prices = products.map((p) => p.discountPrice).toList();
    final minPrice = prices.isEmpty ? 0.0 : prices.reduce((a, b) => a < b ? a : b);
    final rawMax = prices.isEmpty ? 0.0 : prices.reduce((a, b) => a > b ? a : b);
    final maxPrice = rawMax == minPrice ? minPrice + 1 : rawMax;
    _priceRange ??= RangeValues(minPrice, maxPrice);
    final filteredProducts = products.where((p) {
      if (_brandId != null && p.brandId != _brandId) return false;
      final range = _priceRange ?? RangeValues(minPrice, maxPrice);
      return p.discountPrice >= range.start && p.discountPrice <= range.end;
    }).toList();

    final productHits = q.isEmpty
        ? <dynamic>[]
        : _rankByQuery(
            filteredProducts.where((p) => _matchesAny(p.name, terms)).toList(),
            (p) => p.name,
            q,
          ).take(_productPage * 6).toList();
    final reviewHits = q.isEmpty
        ? <dynamic>[]
        : _rankByQuery(
            reviews
                .where((r) => _matchesAny('${r.productName} ${r.content}', terms))
                .toList(),
            (r) => '${r.productName} ${r.content}',
            q,
          ).take(_reviewPage * 4).toList();
    final articleHits = q.isEmpty
        ? <dynamic>[]
        : _rankByQuery(
            articles.where((a) => _matchesAny('${a.title} ${a.excerpt}', terms)).toList(),
            (a) => '${a.title} ${a.excerpt}',
            q,
          ).take(_newsPage * 4).toList();
    final hasResults = productHits.isNotEmpty || reviewHits.isNotEmpty || articleHits.isNotEmpty;
    final suggestion = q.isEmpty
        ? null
        : _suggestQuery(
            q,
            [
              ...products.map((e) => e.name),
              ...reviews.map((e) => e.productName),
              ...articles.map((e) => e.title),
            ],
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Global Search')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search products, reviews, articles...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.bookmark_add_outlined),
                onPressed: _saveCurrentFilter,
                tooltip: 'Save filter',
              ),
            ),
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 250), () {
                if (!mounted) return;
                setState(() {
                  _query = v;
                  _productPage = 1;
                  _reviewPage = 1;
                  _newsPage = 1;
                });
                if (v.trim().length >= 2) {
                  ref.read(searchHistoryProvider.notifier).add(v.trim());
                }
                _saveQuery(v);
              });
            },
          ),
          const SizedBox(height: 12),
          if (_savedFilters.isNotEmpty) ...[
            const Text('Saved filters', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _savedFilters
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(f.replaceFirst('|', ' - ')),
                          onPressed: () => _applySavedFilter(f),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_scope == _SearchScope.all || _scope == _SearchScope.products) ...[
            const Text('Product filters', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int?>(
                      initialValue: _brandId,
                      decoration: const InputDecoration(labelText: 'Brand'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All brands'),
                        ),
                        ...brands.map(
                          (b) => DropdownMenuItem<int?>(
                            value: b.id,
                            child: Text(b.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _brandId = v),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Price range: Rp ${_priceRange!.start.toStringAsFixed(0)} - Rp ${_priceRange!.end.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    RangeSlider(
                      values: _priceRange!,
                      min: minPrice,
                      max: maxPrice,
                      onChanged: (v) => setState(() => _priceRange = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (q.isEmpty && history.isNotEmpty) ...[
            Row(
              children: [
                const Text('Recent searches', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: () => ref.read(searchHistoryProvider.notifier).clear(),
                  child: const Text('Clear'),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: history
                  .map(
                    (h) => InputChip(
                      label: Text(h),
                      onPressed: () => _applyQuery(h),
                      onDeleted: () => ref.read(searchHistoryProvider.notifier).remove(h),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (q.isEmpty) ...[
            const Text('Trending', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: _trending
                  .map(
                    (t) => ActionChip(
                      label: Text(t),
                      onPressed: () => _applyQuery(t),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (q.isNotEmpty && !hasResults && suggestion != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: Text('Did you mean "$suggestion"?'),
                onTap: () => _applyQuery(suggestion),
              ),
            ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _scope == _SearchScope.all,
                onSelected: (_) => _setScope(_SearchScope.all),
              ),
              ChoiceChip(
                label: const Text('Products'),
                selected: _scope == _SearchScope.products,
                onSelected: (_) => _setScope(_SearchScope.products),
              ),
              ChoiceChip(
                label: const Text('Reviews'),
                selected: _scope == _SearchScope.reviews,
                onSelected: (_) => _setScope(_SearchScope.reviews),
              ),
              ChoiceChip(
                label: const Text('Newsfeed'),
                selected: _scope == _SearchScope.news,
                onSelected: (_) => _setScope(_SearchScope.news),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (q.isEmpty)
            const Text('Type to search across modules')
          else ...[
            if (_scope == _SearchScope.all || _scope == _SearchScope.products)
              _Section(
                title: 'Products',
                footer: productHits.length < products.where((p) => p.name.toLowerCase().contains(q)).length
                    ? TextButton(
                        onPressed: () => setState(() => _productPage += 1),
                        child: const Text('Load more'),
                      )
                    : null,
                children: productHits
                    .map(
                      (p) => ListTile(
                        leading: Image.network(p.image, width: 40, height: 40, fit: BoxFit.cover),
                        title: _highlightText(p.name, q),
                        subtitle: Text('Rp ${p.discountPrice.toStringAsFixed(0)}'),
                        onTap: () => context.go('/product/${p.id}'),
                      ),
                    )
                    .toList(),
              ),
            if (_scope == _SearchScope.all || _scope == _SearchScope.reviews)
              _Section(
                title: 'Reviews',
                footer: reviewHits.length <
                        reviews
                            .where((r) =>
                                r.content.toLowerCase().contains(q) || r.productName.toLowerCase().contains(q))
                            .length
                    ? TextButton(
                        onPressed: () => setState(() => _reviewPage += 1),
                        child: const Text('Load more'),
                      )
                    : null,
                children: reviewHits
                    .map(
                      (r) => ListTile(
                        leading: const Icon(Icons.rate_review_outlined),
                        title: _highlightText(r.productName, q),
                        subtitle: _highlightText(r.content, q, maxLines: 2),
                        onTap: () => context.go('/review/${r.id}'),
                      ),
                    )
                    .toList(),
              ),
            if (_scope == _SearchScope.all || _scope == _SearchScope.news)
              _Section(
                title: 'Newsfeed',
                footer: articleHits.length <
                        articles
                            .where((a) =>
                                a.title.toLowerCase().contains(q) || a.excerpt.toLowerCase().contains(q))
                            .length
                    ? TextButton(
                        onPressed: () => setState(() => _newsPage += 1),
                        child: const Text('Load more'),
                      )
                    : null,
                children: articleHits
                    .map(
                      (a) => ListTile(
                        leading: Image.network(a.image, width: 40, height: 40, fit: BoxFit.cover),
                        title: _highlightText(a.title, q),
                        subtitle: _highlightText(a.excerpt, q, maxLines: 2),
                        onTap: () => context.go('/article/${a.id}'),
                      ),
                    )
                    .toList(),
              ),
          ],
        ],
      ),
    );
  }

  void _applyQuery(String value) {
    setState(() {
      _query = value;
      _controller.text = value;
      _productPage = 1;
      _reviewPage = 1;
      _newsPage = 1;
    });
    if (value.trim().length >= 2) {
      ref.read(searchHistoryProvider.notifier).add(value.trim());
    }
    _saveQuery(value);
  }

  Future<void> _setScope(_SearchScope scope) async {
    setState(() => _scope = scope);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_search_scope', scope.name);
    final savedQuery = prefs.getString('global_search_query_${scope.name}') ?? '';
    setState(() {
      _query = savedQuery;
      _controller.text = savedQuery;
      _productPage = 1;
      _reviewPage = 1;
      _newsPage = 1;
    });
  }

  Future<void> _saveQuery(String value) async {
    if (!_loadedPrefs) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_search_query_${_scope.name}', value);
  }
}

enum _SearchScope { all, products, reviews, news }

List<String> _expandQuery(String query) {
  if (query.isEmpty) return [];
  final normalized = query.toLowerCase();
  final map = <String, List<String>>{
    'serum': ['essence', 'ampoule'],
    'essence': ['serum'],
    'sunscreen': ['spf', 'sunblock'],
    'toner': ['tonic'],
    'lip tint': ['tint', 'lipstain'],
    'cleanser': ['face wash'],
  };
  final terms = <String>{normalized};
  for (final entry in map.entries) {
    if (normalized.contains(entry.key)) {
      terms.addAll(entry.value);
    }
  }
  return terms.toList();
}

bool _matchesAny(String text, List<String> terms) {
  final lower = text.toLowerCase();
  for (final t in terms) {
    if (t.isEmpty) continue;
    if (lower.contains(t)) return true;
  }
  return false;
}

List<T> _rankByQuery<T>(List<T> items, String Function(T) textOf, String query) {
  final lower = query.toLowerCase();
  final scored = items
      .map(
        (item) => MapEntry(item, _score(textOf(item).toLowerCase(), lower)),
      )
      .toList();
  scored.sort((a, b) {
    final byScore = b.value.compareTo(a.value);
    if (byScore != 0) return byScore;
    return textOf(a.key).length.compareTo(textOf(b.key).length);
  });
  return scored.map((e) => e.key).toList();
}

int _score(String text, String query) {
  if (text == query) return 5;
  if (text.startsWith(query)) return 4;
  if (text.contains(query)) return 2;
  final distance = _minDistanceInText(text, query);
  if (distance <= 1) return 1;
  if (distance <= 2) return 0;
  return -1;
}

Widget _highlightText(String text, String query, {int maxLines = 1}) {
  if (query.isEmpty) {
    return Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
  final lower = text.toLowerCase();
  final q = query.toLowerCase();
  final index = lower.indexOf(q);
  if (index == -1) {
    return Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
  final before = text.substring(0, index);
  final match = text.substring(index, index + q.length);
  final after = text.substring(index + q.length);
  return RichText(
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    text: TextSpan(
      style: const TextStyle(color: Colors.black87),
      children: [
        TextSpan(text: before),
        TextSpan(
          text: match,
          style: const TextStyle(fontWeight: FontWeight.w700, backgroundColor: Color(0x33FFC107)),
        ),
        TextSpan(text: after),
      ],
    ),
  );
}

int _minDistanceInText(String text, String query) {
  if (query.isEmpty) return 999;
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  var best = _levenshtein(text, query);
  for (final w in words) {
    final d = _levenshtein(w, query);
    if (d < best) best = d;
  }
  return best;
}

int _levenshtein(String s, String t) {
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;
  final rows = s.length + 1;
  final cols = t.length + 1;
  final dist = List.generate(rows, (_) => List<int>.filled(cols, 0));
  for (var i = 0; i < rows; i++) {
    dist[i][0] = i;
  }
  for (var j = 0; j < cols; j++) {
    dist[0][j] = j;
  }
  for (var i = 1; i < rows; i++) {
    for (var j = 1; j < cols; j++) {
      final cost = s[i - 1] == t[j - 1] ? 0 : 1;
      dist[i][j] = [
        dist[i - 1][j] + 1,
        dist[i][j - 1] + 1,
        dist[i - 1][j - 1] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
  }
  return dist[s.length][t.length];
}

String? _suggestQuery(String query, List<String> candidates) {
  var best = '';
  var bestScore = 999;
  for (final c in candidates) {
    final d = _minDistanceInText(c.toLowerCase(), query.toLowerCase());
    if (d < bestScore) {
      bestScore = d;
      best = c;
    }
  }
  if (best.isEmpty || bestScore > 2) return null;
  return best;
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? footer;

  const _Section({required this.title, required this.children, this.footer});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...children,
          if (footer != null) ...[footer!],
        ],
      ),
    );
  }
}
