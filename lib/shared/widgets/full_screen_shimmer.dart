import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FullScreenShimmer extends StatelessWidget {
  const FullScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        color: Colors.grey.shade300,
      ),
    );
  }
}
