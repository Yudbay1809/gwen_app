import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/category.dart';
import 'section_header.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;

  const CategoryGrid({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionHeader(title: 'Categories')),
            TextButton(
              onPressed: () => context.go('/categories'),
              child: const Text('See all'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: categories
                .map(
                  (c) => InkWell(
                    onTap: () => context.go('/categories?initialId=${c.id}'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
