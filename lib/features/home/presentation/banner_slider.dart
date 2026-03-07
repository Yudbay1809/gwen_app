import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BannerSlider extends StatelessWidget {
  final List<String> images;

  const BannerSlider({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CarouselSlider(
          items: images
              .map(
                (url) => CachedNetworkImage(
                  imageUrl: url,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => Container(
                    color: Colors.grey.shade200,
                  ),
                  errorWidget: (context, _, __) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              )
              .toList(),
          options: CarouselOptions(
            height: 160,
            viewportFraction: 1,
            autoPlay: true,
            enlargeCenterPage: false,
          ),
        ),
      ),
    );
  }
}
