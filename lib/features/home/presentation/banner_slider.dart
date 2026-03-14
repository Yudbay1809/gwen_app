import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BannerSlider extends StatefulWidget {
  final List<String> images;

  const BannerSlider({super.key, required this.images});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images.where((e) => e.trim().isNotEmpty).toList();
    if (images.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 160,
            color: Colors.grey.shade200,
            child: const Center(child: Icon(Icons.image, color: Colors.grey)),
          ),
        ),
      );
    }
    if (images.length == 1) {
      final url = images.first;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: url,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, _) => Container(color: Colors.grey.shade200),
            errorWidget: (context, _, _) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                CarouselSlider(
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
                          errorWidget: (context, url, error) => Container(
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
                    onPageChanged: (i, _) => setState(() => _index = i),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withAlpha(0),
                          Colors.black.withAlpha(120),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Row(
              key: ValueKey(_index),
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _index == i ? 20 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _index == i ? Colors.black87 : Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
