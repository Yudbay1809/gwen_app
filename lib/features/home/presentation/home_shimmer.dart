import 'package:flutter/material.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import 'section_header.dart';

class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerLoader(height: 48),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerLoader(height: 160),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Flash Sale'),
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, __) => const SizedBox(width: 160, child: ShimmerLoader(height: 200)),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: 4,
            ),
          ),
          const SectionHeader(title: 'Best Seller'),
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, __) => const SizedBox(width: 160, child: ShimmerLoader(height: 200)),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: 4,
            ),
          ),
          const SectionHeader(title: 'Categories'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: List.generate(6, (_) => const ShimmerLoader(height: 48)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
