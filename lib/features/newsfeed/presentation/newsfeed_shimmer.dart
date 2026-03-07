import 'package:flutter/material.dart';
import '../../../shared/widgets/shimmer_loader.dart';

class NewsfeedShimmer extends StatelessWidget {
  const NewsfeedShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: ShimmerLoader(height: 140),
        );
      },
    );
  }
}
