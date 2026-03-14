import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/presentation/home_providers.dart';
import '../../../shared/models/category.dart';

class CategoryBrowseScreen extends ConsumerStatefulWidget {
  final int? initialId;

  const CategoryBrowseScreen({super.key, this.initialId});

  @override
  ConsumerState<CategoryBrowseScreen> createState() => _CategoryBrowseScreenState();
}

class _CategoryBrowseScreenState extends ConsumerState<CategoryBrowseScreen> {
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialId;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = ref.watch(homeDataProvider);
    final categories = data.categories;
    if (_selectedId == null && categories.isNotEmpty) {
      _selectedId = categories.first.id;
    }
    final selected = categories.firstWhere(
      (c) => c.id == _selectedId,
      orElse: () => categories.first,
    );
    final subcats = _subcategoriesFor(selected);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop by Categories'),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 170,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primaryContainer,
                    scheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: categories.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: scheme.outline.withAlpha(120)),
                itemBuilder: (context, index) {
                  final c = categories[index];
                  final isSelected = c.id == selected.id;
                  final icon = _assetForCategory(c);
                  return InkWell(
                    onTap: () => setState(() => _selectedId = c.id),
                    child: Container(
                      color: isSelected ? scheme.primaryContainer : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Row(
                        children: [
                          _CategoryAvatar(category: c, asset: icon),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              c.name.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? scheme.primary : scheme.onSurface,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(
                  children: [
                    Text(
                      selected.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: Text('See all ${selected.name.toLowerCase()}'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...subcats.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: scheme.outline),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryAvatar extends StatelessWidget {
  final Category category;
  final String asset;

  const _CategoryAvatar({required this.category, required this.asset});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.primary.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => Text(
              category.name.characters.first.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

String _assetForCategory(Category category) {
  switch (category.name.toLowerCase()) {
    case 'makeup':
      return 'assets/icons/makeup.png';
    case 'skincare':
      return 'assets/icons/skincare.png';
    case 'haircare':
      return 'assets/icons/haircare.png';
    case 'body':
      return 'assets/icons/body.png';
    case 'fragrance':
      return 'assets/icons/fragrance.png';
    case 'tools':
      return 'assets/icons/tools.png';
    default:
      return 'assets/icons/makeup.png';
  }
}

List<String> _subcategoriesFor(Category category) {
  switch (category.name.toLowerCase()) {
    case 'makeup':
      return const [
        'Face',
        'Cushion',
        'Foundation',
        'BB & CC Cream',
        'Tinted Moisturizer',
        'Cake Foundation',
        'Loose Powder',
        'Pressed Powder',
        'Bronzer',
        'Blush',
        'Contour',
        'Concealer',
        'Highlighter',
        'Face Primer',
        'Setting Spray',
        'Face Palette',
      ];
    case 'skincare':
      return const [
        'Cleanser',
        'Toner',
        'Serum',
        'Moisturizer',
        'Sunscreen',
        'Mask',
        'Exfoliator',
      ];
    case 'haircare':
      return const ['Shampoo', 'Conditioner', 'Hair Mask', 'Scalp Care', 'Hair Oil'];
    case 'body':
      return const ['Body Wash', 'Body Lotion', 'Body Scrub', 'Hand Cream'];
    case 'fragrance':
      return const ['Eau de Parfum', 'Eau de Toilette', 'Body Mist', 'Home Fragrance'];
    default:
      return const ['Popular', 'New Arrivals', 'Best Sellers'];
  }
}
