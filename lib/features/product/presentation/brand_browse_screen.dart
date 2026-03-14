import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/presentation/home_providers.dart';
import '../../../shared/models/brand.dart';
import 'package:go_router/go_router.dart';

class BrandBrowseScreen extends ConsumerStatefulWidget {
  const BrandBrowseScreen({super.key});

  @override
  ConsumerState<BrandBrowseScreen> createState() => _BrandBrowseScreenState();
}

class _BrandBrowseScreenState extends ConsumerState<BrandBrowseScreen> {
  final Map<String, GlobalKey> _headerKeys = {};
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToLetter(String letter) {
    final key = _headerKeys[letter];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  void _scrollToFirstMatch(Map<String, List<Brand>> grouped) {
    if (grouped.isEmpty) return;
    final firstKey = grouped.keys.first;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLetter(firstKey));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brands = ref.watch(homeDataProvider).brands;
    final filteredBrands = _query.isEmpty
        ? brands
        : brands.where((b) => b.name.toLowerCase().contains(_query)).toList();
    final featured = brands.take(6).toList();
    final grouped = _groupBrands(filteredBrands);
    final entries = _flattenGroups(grouped);
    for (final letter in grouped.keys) {
      _headerKeys.putIfAbsent(letter, () => GlobalKey());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shop by Brands')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Featured Brand', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: featured.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => _FeaturedBrandCard(brand: featured[index]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TabChip(
                          label: 'Brand Name',
                          selected: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TabChip(
                          label: 'Brand Origins',
                          selected: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 220), () {
                        final next = value.trim().toLowerCase();
                        if (!mounted) return;
                        setState(() => _query = next);
                        _scrollToFirstMatch(_groupBrands(
                          next.isEmpty
                              ? brands
                              : brands.where((b) => b.name.toLowerCase().contains(next)).toList(),
                        ));
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search brand name...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                                _scrollToFirstMatch(_groupBrands(brands));
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: scheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: scheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: scheme.outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _letters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final letter = _letters[index];
                        final enabled = grouped.containsKey(letter);
                        return GestureDetector(
                          onTap: enabled ? () => _scrollToLetter(letter) : null,
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: enabled ? scheme.primary : scheme.onSurfaceVariant.withAlpha(120),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (entries.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No brands found for "$_query"',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = entries[index];
                  if (entry.isHeader) {
                    final key = _headerKeys[entry.header!] ?? GlobalKey();
                    _headerKeys[entry.header!] = key;
                    return Padding(
                      key: key,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Text(entry.header!, style: const TextStyle(fontWeight: FontWeight.w700)),
                    );
                  }
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Text(entry.brand!.name),
                    onTap: () => context.go('/products?brandId=${entry.brand!.id}'),
                  );
                },
                childCount: entries.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _FeaturedBrandCard extends StatelessWidget {
  final Brand brand;

  const _FeaturedBrandCard({required this.brand});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Center(
        child: Text(
          brand.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _TabChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? scheme.primary : scheme.outline),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _BrandEntry {
  final String? header;
  final Brand? brand;

  const _BrandEntry.header(this.header) : brand = null;
  const _BrandEntry.brand(this.brand) : header = null;

  bool get isHeader => header != null;
}

Map<String, List<Brand>> _groupBrands(List<Brand> brands) {
  final map = <String, List<Brand>>{};
  for (final brand in brands) {
    final letter = brand.name.isNotEmpty ? brand.name[0].toUpperCase() : '#';
    map.putIfAbsent(letter, () => []).add(brand);
  }
  for (final list in map.values) {
    list.sort((a, b) => a.name.compareTo(b.name));
  }
  final sortedKeys = map.keys.toList()..sort();
  return {for (final key in sortedKeys) key: map[key]!};
}

List<_BrandEntry> _flattenGroups(Map<String, List<Brand>> grouped) {
  final entries = <_BrandEntry>[];
  grouped.forEach((letter, list) {
    entries.add(_BrandEntry.header(letter));
    for (final brand in list) {
      entries.add(_BrandEntry.brand(brand));
    }
  });
  return entries;
}

const _letters = [
  '#',
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
];
